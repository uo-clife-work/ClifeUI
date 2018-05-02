ClfGGMod = {}



ClfGGMod.GUMP_IDS = {
	animalLore  = 475,
	petProgress = 999139,
}

ClfGGMod.GGManagerGGParseData_org = nil

ClfGGMod.Enables = {
	ClosePetProgress = false,
}


ClfGGMod.DEBUG = false


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

	if ( ClfGGMod.DEBUG ) then
		local ok, err = pcall( ClfGGMod.dumpGumpData, GumpData )
	end

	local ok, err = pcall( ClfGGMod.gumpDataParse, GumpData )
	Interface.ErrorTracker(ok, err)

	ClfGGMod.GGManagerGGParseData_org()
end


function ClfGGMod.gumpDataParse( gumpData )
	if ( not gumpData or not gumpData.Gumps ) then
		return
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




-- **** デバッグ用 ****
function ClfGGMod.dumpGumpData( gumpData )

	if ( not ClfDebug or not ClfUtil ) then
		return
	end

	local gumps = gumpData and gumpData.Gumps

	if ( gumps ) then

		for gumpId, data in pairs( gumps ) do

			local argName = "GumpData.Gumps[" .. tostring( gumpId ) .. "]"
			local op = ClfDebug.DumpToConsole( argName, data, nil, true )

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

	if ( WindowData.GG_Core ) then
		local op = ClfDebug.DumpToConsole( "WindowData.GG_Core", WindowData.GG_Core, nil, true )
		ClfUtil.exportStr( L"\r\n\r\n" .. op, "ggdump__WindowData.GG_Core", nil, "x_ggdbug" )
	end

end
