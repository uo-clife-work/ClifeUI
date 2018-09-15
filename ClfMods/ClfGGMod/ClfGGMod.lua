
LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfGGMod", "ClfGGMod.xml", "ClfGGMod.xml" )

ClfGGMod = {}



ClfGGMod.GUMP_IDS = {
	animalLore  = 475,
	petProgress = 999139,
}

ClfGGMod.GGManagerGGParseData_org = nil

ClfGGMod.Enables = {
	ClosePetProgress = false,
}

ClfGGMod.EnableRefact = true

ClfGGMod.DEBUG = false


-- デフォルトのgump表示時のメソッドを保持： 現状使用しないが一応。
ClfGGMod.genericGumpOnShown_org = nil
-- デフォルトのgump終了時のメソッドを保持： 現状使用しないが一応。
ClfGGMod.genericGumpShutdown_org = nil


function ClfGGMod.initialize()

	if ( not ClfGGMod.GGManagerGGParseData_org ) then
		-- オリジナルのメソッドを保持：オーバーライドしたメソッド内で実行
		ClfGGMod.GGManagerGGParseData_org = GGManager.GGParseData
		-- オーバーライド
		GGManager.GGParseData = ClfGGMod.GGParseData
	end

	-- 各機能の有効・無効を読み込み ＆ トグル用メソッドを設定
	local enables = ClfGGMod.Enables
	local setEnableType = ClfGGMod.setEnableType
	for k, v in pairs( enables ) do
		local enable = Interface.LoadBoolean( "ClfGGModEnable" .. k, v )
		setEnableType( enable, k, true )

		ClfGGMod[ "toggle" .. k ] = function()
			local enableType = k
			Debug.DumpToConsole( "enableType", ClfGGMod.Enables[ enableType ] )
			ClfGGMod.setEnableType( not ClfGGMod.Enables[ enableType ], enableType, false )
		end
	end


	if ( ClfGGMod.EnableRefact ) then
		-- Craftingユティリティーが動作するように対応する

		if ( not ClfGGMod.genericGumpOnShown_org ) then
			-- gump表示時のメソッドをオーバーライド：
			ClfGGMod.genericGumpOnShown_org = GenericGump.OnShown
			GenericGump.OnShown = ClfGGMod.onGenericGumpOnShown
		end

		if ( not ClfGGMod.genericGumpShutdown_org ) then
			-- gump終了時のメソッドをオーバーライド：
			ClfGGMod.genericGumpShutdown_org = GenericGump.Shutdown
			GenericGump.Shutdown = ClfGGMod.onGenericGumpShutdown
		end
	end

end


function ClfGGMod.setEnableType( enable, enableType, silent )
	if ( type( enableType ) ~= "string" and ClfGGMod.Enables[ enableType ] == nil ) then
		return
	end

	local onOffStr = L": OFF"
	local hue = 150
	if ( enable ) then
		onOffStr = L": ON"
		hue = 1152
	end

	ClfGGMod.Enables[ enableType ] = enable
	Interface.SaveBoolean( "ClfGGModEnable" .. enableType, enable )
	if ( not silent ) then
		WindowUtils.SendOverheadText( towstring( enableType ) .. onOffStr, hue, true )
	end
end


-- オリジナルの GGManager.GGParseData をオーバーライドするメソッド
function ClfGGMod.GGParseData()
	pcall( ClfGGMod.gumpDataParse, GumpData )

	ClfGGMod.GGManagerGGParseData_org()

	pcall( ClfjewelryBox.gumParse, GumpData )
end


function ClfGGMod.gumpDataParse( gumpData )
	if ( not gumpData or not gumpData.Gumps ) then
		return
	end

	if ( ClfGGMod.DEBUG ) then
		pcall( ClfGGMod.dumpGumpData, GumpData )
	end

	if ( ClfALGump.Enable ) then
		-- アニマルロアガンプ
		local gump = gumpData.Gumps[ ClfGGMod.GUMP_IDS.animalLore ]

		if ( gump ) then
			local closeOrg = ClfALGump.updateGumpData( gump )

			if ( closeOrg ) then
				local id =  WindowGetId( gump.windowName )
				if ( id  ) then
					GenericGumpOnRClicked( id )
				end
			end
		end
	end

	if ( ClfGGMod.Enables.ClosePetProgress ) then
		-- ペット訓練進行状況ガンプを閉じる
		local gump = gumpData.Gumps[ ClfGGMod.GUMP_IDS.petProgress ]
		if ( gump ) then
			local id =  WindowGetId( gump.windowName )
			if ( id  ) then
				GenericGumpOnRClicked( id )
			end
		end
	end

end


--[[
** OverRide: GenericGump.OnShown
*  ※ 意図は不明だが、デフォルトでは GumpsParsing.ParsedGumps[gumpID] 等にnilをセットしている（これが原因でCraftingユティリティーが動作しない）ので、Gumpのチェックだけ行う様に変更（initializeの時点でパースされるのでチェックは不要と思われるが念のため）
]]
function ClfGGMod.onGenericGumpOnShown()
	GumpsParsing.CheckGumpType(0)
end


ClfGGMod.AfterGGShutdownDelta = 0

-- OverRide: GenericGump.Shutdown
function ClfGGMod.onGenericGumpShutdown()
	local windowName = SystemData.ActiveWindow.name
	local gumpID = GenericGump.GumpsList[ windowName ]
	if ( gumpID ) then
		GumpsParsing.ParsedGumps[ gumpID ] = nil
		GumpsParsing.ToShow[ gumpID ] = nil
--		GumpData.Gumps[ gumpID ] = nil	-- // この処理のせいで、生産ツールのガンプ表示時に新しく生産ツールのガンプが表示されるとガンプタイプのチェックが出来ない。何もしなくても抹消されるデータなので行削除。
	end
	GenericGump.GumpsList[ windowName ] = nil

	ClfGGMod.AfterGGShutdownDelta = 0
	if ( not DoesWindowExist( "ClfAfterGGShutdownProcess" ) ) then
		-- OnUpdate用のウィンドウを作る： ClfGGMod.afterGGShutdownOnUpdate を実行するウィンドウ
		CreateWindow( "ClfAfterGGShutdownProcess", true )
	end
end


--[[
** EventHandle: ClfAfterGGShutdownProcess.OnUpdate
*  GenericGumpが閉じてから ガンプタイプのチェックを一定時間実行
*  ※ 生産ツールgumpが開いている状態から生産ツールgumpが再表示されると生産メニュー種別が正常に取得出来ないため
]]
function ClfGGMod.afterGGShutdownOnUpdate( timePassed )
	local ClfGGMod = ClfGGMod
	local delta = ClfGGMod.AfterGGShutdownDelta + timePassed
	if ( delta > 3 ) then
		if ( DoesWindowExist( "ClfAfterGGShutdownProcess" ) ) then
			DestroyWindow( "ClfAfterGGShutdownProcess" )
			ClfGGMod.AfterGGShutdownDelta = 0
		end
	else
		ClfGGMod.AfterGGShutdownDelta = delta
		GumpsParsing.CheckGumpType( timePassed )
	end
end



-- ガンプ内の全てのアイテムプロパティを得る
function ClfGGMod.getItemPropsInGump( gumpId )
	local GumpData = GumpData
	if ( not GumpData ) then
		return
	end
	local gump = GumpData.Gumps[ gumpId ]
	if ( not gump or not gump.Buttons ) then
		return
	end

	local itemPropDatas = {}
	local windows = {}
	local WD_ItemProperties = WindowData.ItemProperties
	local WDI_Type = WD_ItemProperties.Type

	local RegisterWindowData = RegisterWindowData
	local GenericGumpGetItemPropertiesId = GenericGumpGetItemPropertiesId

	local getItemProps = function( id )
		local data = WD_ItemProperties[ id ]
		if ( not data ) then
			RegisterWindowData( WDI_Type, id )
			data = WD_ItemProperties[ id ]
		end
		return data
	end

	for id, btn in pairs( gump.Buttons ) do
		local objectId = GenericGumpGetItemPropertiesId( WindowGetId( btn ), btn )
		if ( not objectId or objectId == 0 ) then
			continue
		end
		local prop = getItemProps( objectId )
		if ( prop ) then
			itemPropDatas[ objectId ] = prop
			windows[ objectId ] = btn
		end
	end

	return itemPropDatas, windows
end


-- **** デバッグ用 ****
function ClfGGMod.dumpGumpData( gumpData )

	if ( not ClfDebug ) then
		return
	end

	local gumps = gumpData and gumpData.Gumps

	if ( gumps ) then

		for gumpId, data in pairs( gumps ) do

			local argName = "GumpData.Gumps[" .. tostring( gumpId ) .. "]"
			local op = ClfDebug.DumpToConsole( argName, data, nil, true, true )

			local itemProps = ClfGGMod.getItemPropsInGump( gumpId )
			if ( itemProps ) then
				op = op .. L"\r\n\r\n---------- Item property ----------\r\n\r\n"
				op = op .. ClfDebug.DumpToConsole( "ItemProperties", itemProps, nil, true, true )
				op = op .. L"\r\n"
			end

			local labels = data.Labels
			if ( labels and #labels > 0 ) then
				op = op .. L"\r\n\r\n---------- Lables.tid ----------\r\n\r\n"

				for i = 1, #labels do
					local lab = labels[ i ]
					if ( lab and lab.tid ) then
						local ttl = GetStringFromTid( lab.tid )
						if ( ttl ) then
							op = op ..  towstring( lab.tid ) .. L": " .. ttl .. L" "
							local params = lab.tidParms
							if ( params and #params > 0 ) then
								op = op .. L"\t\tPrams:"
								for k = 1, #params do
									local parm = params[ k ]
									if ( type( parm ) == "wstring" ) then
										op = op .. L"\t" .. parm

										if ( wstring.match( parm, L"^#" ) ) then
											local pTid = string.gsub( tostring( parm ), "^#", "" )
											pTid = tonumber( pTid )

											if ( pTid and pTid > 0 ) then
												local pTtl = GetStringFromTid( pTid )
												if ( pTtl ) then
													op = op .. L" << " .. pTtl .. L" >>"
												end
											end
										end

									end
								end
							end
							op = op .. L"\r\n"
						end
					end
				end
			end

			ClfUtil.exportStr( L"\r\n\r\n" .. op, "ggdump__" .. argName, nil, "x_ggdbug" )
		end
	end

--	if ( WindowData.GG_Core ) then
--		local op = ClfDebug.DumpToConsole( "WindowData.GG_Core", WindowData.GG_Core, nil, true )
--		ClfUtil.exportStr( L"\r\n\r\n" .. op, "ggdump__WindowData.GG_Core", nil, "x_ggdbug" )
--	end

end


