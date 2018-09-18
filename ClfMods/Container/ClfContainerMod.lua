
-- コンテナ内のアイテムプロパティを表示させる

LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/Container", "ClfContainerMod.xml", "ClfContainerMod.xml" )


ClfContnrWin = {}

local DefaultTxtColor = { r =   0, g =  15, b =  65, }
local DefaultTxtColorLight = { r = 255, g = 255, b = 255, }

local ItemCache = {}
local PropTidsObjCache = {}
local KnownTreasureBox = {}

local SlayerStrPattern = L""

-- コンテナ内アイテムプロパティ表示をするか
ClfContnrWin.Enable = true
-- コンテナ内グリッドの背景をClifeUIで追加した白にする
ClfContnrWin.EnableWhiteGrid = false
-- コンテナ内アイテムプロパティ表示のテキスト色を暗くする
ClfContnrWin.EnableDarkGridText = false
-- コンテナ内アイテムをShift+右クリックでルートするか
ClfContnrWin.EnableShiftRhClkLoot = false

-- ClfContnrWinData から取得したデータを保持するテーブル
ClfContnrWin.DisplayCondTable = ClfContnrWin.DisplayCondTable or {}
ClfContnrWin.RelationTable = ClfContnrWin.RelationTable or {}
ClfContnrWin.ColorTbl = {}

ClfContnrWin.labelSetOptProp = _void
ClfContnrWin.fixSlayerString = _void
ClfContnrWin.fixSkillName = _void

-- objectTypeで判定するアイテム
local CondObjectTypes = {
	[8901]  = true, 	-- ルーンブック
	[39958] = true,	-- Runic Atlas
	[10289] = true,	-- レシピ
	[8794]  = true,	-- マスタリーの書
	[7714]  = true,	-- マスタリーの手引き
	[7956]  = true,	-- リコールルーン

	[5163]  = true,	-- ハードコート剤
	[11617] = true,	-- ハードワックス
	[19673] = true,	-- ハードメッキ
}

-- ContainerWindow標準の関数を保持
ClfContnrWin.UpdateObject_org = nil
ClfContnrWin.UpdateGridViewSockets_org = nil
ClfContnrWin.CreateGridViewSockets_org = nil
ClfContnrWin.Initialize_org = nil
ClfContnrWin.OnItemGet_org = nil



function ClfContnrWin.initialize()
	local ClfContnrWin = ClfContnrWin
	local ContainerWindow = ContainerWindow
	local I_LoadBoolean = Interface.LoadBoolean

	ClfContnrWin.Enable = I_LoadBoolean( "ClfContainerModEnable", ClfContnrWin.Enable )
	ClfContnrWin.EnableWhiteGrid = I_LoadBoolean( "ClfWhiteGrid", ClfContnrWin.EnableWhiteGrid )
	ClfContnrWin.EnableDarkGridText = I_LoadBoolean( "ClfDarkGridText", ClfContnrWin.EnableDarkGridText )
	ClfContnrWin.EnableShiftRhClkLoot = I_LoadBoolean( "ClfShitRhClkLoot", ClfContnrWin.EnableShiftRhClkLoot )

	ClfContnrWin.initData()

	if ( SystemData.Settings.Language.type == SystemData.Settings.Language.LANGUAGE_JPN ) then
		SlayerStrPattern = L"^" .. GetStringFromTid(1114263) .. L":%s+"
		ClfContnrWin.fixSlayerString = ClfContnrWin.fixSlayerString_JA
		ClfContnrWin.fixSkillName = ClfContnrWin.fixSkillName_JA
	else
		ClfContnrWin.fixSlayerString = ClfContnrWin.fixSlayerString_Other
		ClfContnrWin.fixSkillName = ClfContnrWin.fixSkillName_Other
	end

	local onOffStr = L"OFF"
	if ( ClfContnrWin.Enable ) then
		onOffStr = L"ON"
		ClfContnrWin.labelSetOptProp = ClfContnrWin.labelSetOptProp_enable
		ClfContnrWin.initEventHandleWindow( true )
	else
		ClfContnrWin.labelSetOptProp = ClfContnrWin.labelSetOptProp_disble
	end

	-- Override functions
	if ( not ClfContnrWin.UpdateGridViewSockets_org ) then
		ClfContnrWin.UpdateGridViewSockets_org = ContainerWindow.UpdateGridViewSockets
		ContainerWindow.UpdateGridViewSockets = ClfContnrWin.updateGridViewSockets
	end

	if ( not ClfContnrWin.UpdateObject_org ) then
		ClfContnrWin.UpdateObject_org = ContainerWindow.UpdateObject
		ContainerWindow.UpdateObject = ClfContnrWin.updateObject
	end

	if ( not ClfContnrWin.CreateGridViewSockets_org ) then
		ClfContnrWin.CreateGridViewSockets_org = ContainerWindow.CreateGridViewSockets
		ContainerWindow.CreateGridViewSockets = ClfContnrWin.createGridViewSockets
	end

	if ( not ClfContnrWin.Initialize_org ) then
		ClfContnrWin.Initialize_org = ContainerWindow.Initialize
		ContainerWindow.Initialize = ClfContnrWin.onWindowInitialize
	end

	if ( not ClfContnrWin.OnItemGet_org ) then
		ClfContnrWin.OnItemGet_org = ContainerWindow.OnItemGet
		ContainerWindow.OnItemGet = ClfContnrWin.onItemGet
	end

	ClfContnrSearch.initialize()

	Debug.PrintToChat( L"ClfContnrWin: " .. onOffStr )
end


-- プロパティ表示の有効・無効を切り替え
function ClfContnrWin.toggle( silent )
	local enable = not ClfContnrWin.Enable
	ClfContnrWin.Enable = enable
	ItemCache = {}

	Interface.SaveBoolean( "ClfContainerModEnable", enable )
	ClfContnrWin.initEventHandleWindow( enable )

	local onOffStr = L"OFF"
	local hue = 150

	if ( enable ) then
		ClfContnrWin.labelSetOptProp = ClfContnrWin.labelSetOptProp_enable
		onOffStr = L"ON"
		hue = 1152
	else
		ClfContnrWin.labelSetOptProp = ClfContnrWin.labelSetOptProp_disble
	end

	if ( not silent ) then
		WindowUtils.SendOverheadText( L"ClfContainerMod: " .. onOffStr, hue, true )
	end
end


-- グリッド背景の切り替え
function ClfContnrWin.toggleWhiteGrid( silent )
	local enable = not ClfContnrWin.EnableWhiteGrid
	ClfContnrWin.EnableWhiteGrid = enable
	Interface.SaveBoolean( "ClfWhiteGrid", enable )
	ClfContnrWin.setupGridTextColor()

	local onOffStr = L"OFF"
	local hue = 150
	if ( enable ) then
		onOffStr = L"ON"
		hue =1152
	end

	if ( not silent ) then
		WindowUtils.SendOverheadText( L"White Grid: " .. onOffStr, hue, true )

		-- 文字色を切り替えるダイアログを出す
		local dialogBody = L"Grid Bg is [ " .. ( enable and L"White" or L"Default" ) .. L" ]\n"

		local UO_StandardDialog = UO_StandardDialog
		local lightButton = {
			text = L"Light",
			callback = ClfContnrWin.onDialogOptionSelected,
			param = 1,
		}
		local darkButton = {
			text = L"Dark",
			callback = ClfContnrWin.onDialogOptionSelected,
			param = 2,
		}
		local cancelButton = {
			textTid = UO_StandardDialog.TID_CANCEL,
			callback = ClfContnrWin.onDialogOptionSelected,
			param = 0,
		}

		UO_StandardDialog.CreateDialog( {
				windowName   = "ClfDarkGridText_Select_Dialog",
				title        = L"Select Text Type",
				body         = dialogBody ..L"Select Grid Text Color Type.\n",
				buttons      = { lightButton, darkButton, cancelButton },
				hasScrollbar = false,
			} )
	end
end

-- グリッド背景切り替えダイアログコールバック
function ClfContnrWin.onDialogOptionSelected( param )
	if ( param == 1 ) then
		-- to Light Color text
		if ( ClfContnrWin.EnableDarkGridText ) then
			ClfContnrWin.toggleTxtColor( false, true )
		end
	elseif ( param == 2 ) then
		-- to Dark Color text
		if ( not ClfContnrWin.EnableDarkGridText ) then
			ClfContnrWin.toggleTxtColor( false, true )
		end
	end
end


-- テキストカラーの切り替え
function ClfContnrWin.toggleTxtColor( silent )
	local enable = not ClfContnrWin.EnableDarkGridText
	ClfContnrWin.EnableDarkGridText = enable
	Interface.SaveBoolean( "ClfDarkGridText", enable )
	ClfContnrWin.setupGridTextColor()

	if ( not silent ) then
		local onOffStr = L"Light"
		local hue = 1152
		if ( enable ) then
			onOffStr = L"Dark"
		end
		WindowUtils.SendOverheadText( L"Grid Text: " .. onOffStr, hue, true )
	end
end


-- 表示判定用等のデータをデフォルトに戻す： SavedVariablesから読み込んだデータを破棄
function ClfContnrWin.resetData()
	ClfContnrWin.initData( true )
end



-- コンテナ内アイテムをShift+右クリックでルートするかを切り替え
function ClfContnrWin.toggleShiftRhClkLoot( silent )
	enable = not ClfContnrWin.EnableShiftRhClkLoot
	ClfContnrWin.EnableShiftRhClkLoot = enable
	Interface.SaveBoolean( "ClfShitRhClkLoot", enable )

	if ( not silent ) then
		local str
		local hue
		if ( enable ) then
			str = L"ON"
			hue = 1152
		else
			str = L"OFF"
			hue = 150
		end
		WindowUtils.SendOverheadText( L"Shift + Rh-click Loot: " .. str, hue, true )
	end
end


function ClfContnrWin.initEventHandleWindow( enable )
	local newWin = "ClfContnrWinEvetHandleWindow"

	if ( enable ) then
		if ( not DoesWindowExist( newWin ) ) then
			CreateWindowFromTemplateShow( newWin, "ClfEmptyWindow", "Root", true )
			-- アイテムのプロパティが更新された時に発生するイベント： アイテムをドラッグ・ドロップでも発生する
			WindowRegisterEventHandler( newWin, WindowData.ObjectInfo.Event, "ClfContnrWin.onObjectInfoEvent" )
		end
	else
		if ( DoesWindowExist( newWin ) ) then
			DestroyWindow( newWin )
		end
	end
end


function ClfContnrWin.setupGridTextColor()
	local ClfContnrWin = ClfContnrWin
	if ( ClfContnrWin.EnableDarkGridText ) then
		ClfContnrWin.ColorTbl =  ClfUtil.mergeTable( {}, ClfContnrWin.TxtColorsDark )
	else
		ClfContnrWin.ColorTbl =  ClfUtil.mergeTable( {}, ClfContnrWin.TxtColorsLight )
	end
end


function ClfContnrWin.initData( force )
	local ClfContnrWin = ClfContnrWin
	local getData = ClfContnrWinData.getData
	local pairs = pairs
	local next = next
	local mergeTable = ClfUtil.mergeTable
	local joinArray = ClfUtil.joinArray

	ItemCache = {}

	if ( force or not ClfContnrWin.TxtColorsDark or next( ClfContnrWin.TxtColorsDark ) == nil ) then
		ClfContnrWin.TxtColorsDark = mergeTable( {}, getData( "TxtColors_Dark" ) )
	end

	if ( force or not ClfContnrWin.TxtColorsLight or next( ClfContnrWin.TxtColorsLight ) == nil ) then
		ClfContnrWin.TxtColorsLight = mergeTable( {}, getData( "TxtColors_Light" ) )
	end

	ClfContnrWin.setupGridTextColor()

	if ( force or not ClfContnrWin.HueTbl or next( ClfContnrWin.HueTbl ) == nil ) then
		ClfContnrWin.HueTbl = mergeTable( {}, getData( "HueTbl" ) )
	end

	if ( force or not ClfContnrWin.DisplayCondTable or next( ClfContnrWin.DisplayCondTable ) == nil ) then
		local condAlways = getData( "CondTblAlways" )
		local TblFor = getData( "CondTblFor" )

		ClfContnrWin.DisplayCondTable = {}

		-- 各アイテム種別毎の判定用テーブルを生成
		for itemType, tbl in pairs( TblFor ) do
			ClfContnrWin.DisplayCondTable[ itemType ] = joinArray( condAlways, tbl )
		end
	end

	if ( force or not ClfContnrWin.UniqueCondTable ) then
		ClfContnrWin.UniqueCondTable = joinArray( getData( "UniqueCondTbl" ) )
	end

	if ( force or not ClfContnrWin.RelationTable or next( ClfContnrWin.RelationTable ) == nil ) then
		ClfContnrWin.RelationTable = mergeTable( {}, getData( "RelationTable" ) )
	end

	local lastInitTime = ClfContnrWin.LastInitTime
	local IF_lastInitTime = Interface.LoadString( "ClfContnrDataLastInit", "" )
	IF_lastInitTime = ( IF_lastInitTime ~= "" ) and IF_lastInitTime or false

	if ( not force and IF_lastInitTime and not lastInitTime ) then
		-- Interfaceに保存した日時Stringはあるが、ClfContnrWin.LastInitTimeが読み込まれない
		-- SavedVariables.lua が壊れていると思われるので、データを初期化したアラートを出す
		Debug.PrintToChat( L"ClfContnrWin: Data is Broken!!! Data reset to default" )

		UO_StandardDialog.CreateDialog( {
				windowName   = "ClfContnrWinData_Warning",
				title        = L"Notice",
				body         = ClfTxt.getString( 1000 ) .. L"\n",
				hasScrollbar = false,
			} )
	end

	local nowDateTime = ClfUtil.getClockString( "-", "/", ":" )
	local fixedTime = force and nowDateTime or lastInitTime or IF_lastInitTime or nowDateTime
	ClfContnrWin.LastInitTime = fixedTime
	Interface.SaveString( "ClfContnrDataLastInit", fixedTime )

	if ( force ) then
		Debug.PrintToChat( L"ClfContnrWin: Force Reset Data complete" )
	end
end


-- 特効プロパティの「特効: 」を削除する
function ClfContnrWin.fixSlayerString_JA( str )
	if ( type( str ) == "wstring" ) then
		str = wstring.gsub( str, SlayerStrPattern, L"" )
	end
	return str
end

function ClfContnrWin.fixSlayerString_Other( str )
	return str
end


-- スキル値追加プロパティから、日本語のスキル名と上昇値（または下降値）だけを抜き出す
function ClfContnrWin.fixSkillName_JA( str )
	if ( type( str ) == "wstring" ) then
		local skillEn, skillJA, skillInc = wstring.match( str, L"^([^[]+)%[([^]]+)%]%s+([%+%-].+)" )
		if ( skillJA and skillInc ) then
			str = skillJA .. skillInc
		end
	end
	return str
end

function ClfContnrWin.fixSkillName_Other( str )
	return str
end


function ClfContnrWin.labelSetOptProp_disble( labelName, itemID, elementIcon, item, viewMode, prefix, charge )
	charge = charge or L""
	LabelSetText( labelName, charge )
end


-- アイテムプロパティの追加表示を行う
function ClfContnrWin.labelSetOptProp_enable( labelName, itemID, elementIcon, item, viewMode, prefix, charge )
	if ( labelName ~= nil and itemID ~= nil ) then
		local ClfContnrWin = ClfContnrWin
		local propObj = ClfContnrWin.getInterestPropObj( itemID, charge )
		local colorTbl = ClfContnrWin.ColorTbl
		local defColor = colorTbl.default or DefaultTxtColor

		if ( charge ) then
			prefix = charge
		else
			prefix = prefix or L""
		end

		if ( viewMode == "list" ) then
			-- list viewの時
			local tProp = nil
			local tmpTxt = nil
			local txtLong = L""
			colorTbl = ClfContnrWin.TxtColorsLight
			defColor =  colorTbl.default or DefaultTxtColorLight

			local objs = propObj.objs
			if ( objs and #objs > 1 ) then
				local type = type
				local StringToWString = StringToWString
				local usedKeys = {}

				for i = 1, #objs, 1 do
					local obj = objs[ i ]
					if ( type( obj ) == "table" ) then
						if ( not obj.propKey or not usedKeys[ obj.propKey ] ) then
							if ( obj.rawText ) then
								txtLong = txtLong .. obj.rawText .. L", "
							elseif ( obj.text ) then
								tmpTxt = obj.text
								if ( type( obj.text ) ~= "wstring" ) then
									tmpTxt = StringToWString( tmpTxt )
								end
								txtLong = txtLong .. tmpTxt .. L", "
							end
							if ( obj.propKey ) then
								usedKeys[ obj.propKey ] = 1
							end
						end
					end
				end
			end

			if ( wstring.len( txtLong ) > 2 ) then
				txtLong = wstring.sub( txtLong, 1, -3 )
				LabelSetText(labelName, prefix .. txtLong)
			elseif ( propObj.text ) then
				if ( charge ) then
					prefix = prefix .. L", "
				end
				LabelSetText(labelName, prefix .. propObj.text)
			elseif ( charge ) then
				LabelSetText(labelName, charge )
			end
			if ( propObj.color == "note" ) then
				propObj.color = nil
			end
		else
			-- list view以外の時（grid view）
			if ( propObj.text ) then
				LabelSetText( labelName, propObj.text )
			elseif ( charge ) then
				LabelSetText( labelName, charge )
			else
				LabelSetText( labelName, L"" )
			end
		end

		local color = propObj.color and colorTbl[ propObj.color ] or defColor
		LabelSetTextColor( labelName, color.r, color.g, color.b )

		-- アイテムアイコンに色を付ける
		if ( elementIcon and propObj.hue and item and item.objectType  ) then
			hue = ClfContnrWin.HueTbl[ propObj.hue ]
			if ( hue ) then
				DynamicImageSetCustomShader( elementIcon, "UOSpriteUIShader", { hue, item.objectType } )
			end
		end

	end
end



function ClfContnrWin.cacheingItemProp( id, propObj, forced )
	propObj = propObj or {}
	if ( not id or id < 1 ) then
		return propObj
	end
	if ( not forced ) then
		ItemCache[ id ] = propObj
	end
	return propObj
end


--[[
* アイテムIDから重要なプロパティの文字列等を得る
* @param  {integer} [id]     選択する距離範囲
* @param  {wstring} [charge = nil]  オプション - アイテムのチャージ数文字列
* @param  {boolean} [force = nil]  オプション - objectTypeが取得出来なくてもプロパティの取得を行う： ガンプ内のアイテムだと取得出来ない事が多い為
* @return {table}   プロパティを納めたテーブル： 表示するべきプロパティが無い場合はカラのテーブル
]]--
function ClfContnrWin.getInterestPropObj( id, charge, force )
	if ( ItemCache[ id ] ~= nil ) then
		return ItemCache[ id ]
	end

	local ClfContnrWin = ClfContnrWin
	local WindowData = WindowData
	local itemData = WindowData.ObjectInfo[ id ]
	if ( not itemData ) then
		RegisterWindowData( WindowData.ObjectInfo.Type, id )
		itemData = WindowData.ObjectInfo[ id ] or {}
	end

	if ( force or itemData.objectType ) then
		local objectType = itemData.objectType
		if ( objectType and objectType ~= 0 ) then
			force = false
		end

		local props = WindowData.ItemProperties[ id ]
		if ( not props ) then
			RegisterWindowData( WindowData.ItemProperties.Type, id )
			props = WindowData.ItemProperties[ id ]
		end

		local isTalis = ClfContnrWin.isTalisman( itemData, props )
		if ( isTalis == false and charge ) then
			return ClfContnrWin.cacheingItemProp( id, nil, force )
		end

		if ( props ~= nil ) then
			local propTids = props.PropertiesTids
			local propLen = #propTids
--			if ( propLen <= 2 ) then
--				-- プロパティ数が2以下の時は装備品orバッグではない（アイテム名と重量のみ：マジックプロパティが無い）
--				return ClfContnrWin.cacheingItemProp( id, nil, force )
--			end

			local hueId = itemData.hueId
			local propsValues = ClfContnrWin.getPropTidsObj( id, props )

			local wstring_gsub = wstring.gsub

			-- objectTypeで判定するアイテム
			if ( CondObjectTypes[ objectType ] ) then
				if ( objectType == 8901 or objectType == 39958 ) then
					-- ルーンブック:8901, Runic Atlas:39958
					local propTid = 1070722
					local text = propsValues[ propTid ] and propsValues[ propTid ].text
					local obj
					if ( text ~= nil ) then
						obj = {
							text = text,
							color = "note",
						}
					end
					return ClfContnrWin.cacheingItemProp( id, obj, force )
				elseif ( objectType == 10289 and hueId == 0 ) then
					-- レシピ
					local propTid = 1049644
					local propVals = propsValues[ propTid ]
					local text
					if ( propVals.childTid ) then
						text = GetStringFromTid( propVals.childTid )
					elseif ( propVals.text ) then
						text = wstring.sub( propVals.text, 2, -2 )
					end

					local obj
					if ( text ~= nil ) then
						obj = {
							text = text,
							color = "note",
						}
					end
					return ClfContnrWin.cacheingItemProp( id, obj, force )
				elseif ( objectType == 8794 and hueId == 0 ) then
					-- マスタリーの書
					local obj = {}
					if ( #props.PropertiesList >= 4 ) then
						local text = props.PropertiesList[3]
						if ( text ~= nil ) then
							obj = {
								text = text,
								color = "note",
							}
						end
					end
					return ClfContnrWin.cacheingItemProp( id, obj, force )
				elseif ( objectType == 7714 and hueId == 0 ) then
					-- マスタリーの手引き
					local val = propsValues[ 1155883 ]
					local text = val and val.raw
					local skillTid = propsValues[ 1155882 ] and propsValues[ 1155882 ].childTid
					local obj
					if ( skillTid ) then
						local ttl = GetStringFromTid( skillTid )
						text = text .. L" " .. ttl
					end
					if ( text ~= nil ) then
						obj = {
							text = text,
							color = "note",
						}
					end
					return ClfContnrWin.cacheingItemProp( id, obj, force )
				elseif ( objectType == 7956 ) then
					-- リコールルーン: ファセットでtidが異なる様（で面倒）なので最後の値を表示。。。
					local obj
					local tidPrms = props.PropertiesTidsParams
					if ( tidPrms ~= nil ) then
						local tidPrmsLen = #tidPrms
						if ( tidPrmsLen > 2 ) then
							local text = tidPrms[ tidPrmsLen ]
							if ( text ~= nil ) then
								if ( wstring.match(text, L"^#%d+") ~= nil ) then
									text = L"ship"
								else
									text = wstring_gsub(text, L"^a recall rune for ", L"")
								end
								if ( text and text ~= "" and text ~= L"" ) then
									obj = {
										text = text,
										color = "note",
									}
									return ClfContnrWin.cacheingItemProp( id, obj, force )
								end
							end
						end
					end
					return {}
				elseif ( objectType == 5163 or objectType == 11617 or objectType == 19673 ) then
					-- ハードコート剤, ハードワックス, ハードメッキ
					local tidPrms = props.PropertiesTidsParams
					if ( tidPrms ~= nil and #tidPrms == 9 ) then
						local str = L""
						local indexes = { 7, 3 }
						for i = 1, #indexes do
							local tid = tidPrms[ indexes[ i ] ]
							if ( type( tid ) == "wstring" and wstring.match( tid, L"^#%d+" ) ) then
								tid = tonumber( wstring.sub( tid, 2 ) )
								local tidStr = tid and GetStringFromTid( tid )
								if ( tidStr and tidStr ~= L"MISSING STRING" ) then
									str = str .. tidStr
								end
							end
						end
						if ( str ~= L"" ) then
							local obj = {
								text = str,
								color = "note",
							}
							return ClfContnrWin.cacheingItemProp( id, obj, force )
						end
					end
				end
			end

			local _clfd = ClfD
			local RefMagicPropTids = _clfd.MagicTids or {}
			local RefSkillGroupTids = _clfd.SkillGroupTids or {}
			local RefNoMagicTids = _clfd.NonMagicTids or {}
			local RefRegistPropTids = _clfd.RegistTypeTids or {}
			local RefDamagePropTids = _clfd.DamageTypeTids or {}
			local RefUniqueNameTids = _clfd.UniqueNameTids or {}
			local RefSlayerTids = _clfd.SlayerTids or {}
			_clfd = nil

			local registPropLen = 0
			local magicPropLen = -1	-- アイテム名もプロパティとしてカウントされるので -1 から開始
			local hasUniqueName = false

			-- プロパティのtIdに紐付けたキーを添え字として、プロパティ値、テキストなどのオブジェクトを保持するテーブル
			local itemPropKeys = {}

			for i = 1, propLen, 1 do
				local tId = propTids[ i ]
				local vals = propsValues[ tId ] or {}

				if ( RefMagicPropTids[ tId ] ~= nil ) then
					local key = RefMagicPropTids[ tId ].key
					itemPropKeys[ key ] = vals
					magicPropLen = magicPropLen + 1
				elseif ( RefSkillGroupTids[ tId ] ~= nil ) then
					local key = RefSkillGroupTids[ tId ].key
					vals.text = ClfContnrWin.fixSkillName( vals.text )
					itemPropKeys[ key ] = vals
					magicPropLen = magicPropLen + 1
				elseif ( RefNoMagicTids[ tId ] ~= nil ) then
					local key = RefNoMagicTids[ tId ].key
					itemPropKeys[ key ] = vals
				elseif ( RefRegistPropTids[ tId ] ~= nil ) then
					local key = RefRegistPropTids[ tId ].key
					itemPropKeys[ key ] = vals
					registPropLen = registPropLen + 1
				elseif ( RefDamagePropTids[ tId ] ~= nil ) then
					local key = RefDamagePropTids[ tId ].key
					itemPropKeys[ key ] = vals
				elseif ( RefSlayerTids[ tId ] ~= nil ) then
					local key = RefSlayerTids[ tId ].key
					vals.text = ClfContnrWin.fixSlayerString( vals.text )
					itemPropKeys[ key ] = vals
					magicPropLen = magicPropLen + 1
				elseif ( RefUniqueNameTids[ tId ] ~= nil ) then
					local key = RefUniqueNameTids[ tId ].key
					itemPropKeys[ key ] = vals
					hasUniqueName = true
					-- -1 から開始しているので、名前のtIdはマジックプロパティ数に足す
					magicPropLen = magicPropLen + 1
				else
					-- どのプロパティにも該当しなかったので、とりあえずマジックプロパティとしてカウント
					magicPropLen = magicPropLen + 1
				end
			end

			if ( isTalis and ( itemPropKeys.craftBonusHq or itemPropKeys.craftBonus ) ) then
				-- タリスマンで生産ボーナスがある場合は通常と異なる表示をさせる（チャージ数より優先）
				-- ※ 他に表示すべきプロパティがある時はそちらを優先する
				local hasOtherProp = false
				local talisCond = ClfContnrWin.DisplayCondTable.Talis or {}
				local skipKeys = { ["craftBonusHq"] = true, ["craftBonus"] = true, }
				for i = 1, #talisCond do
					local key = talisCond[ i ].key
					if ( itemPropKeys[ key ] ~= nil and skipKeys[ key ] == nil ) then
						hasOtherProp = true
						break
					end
				end

				if ( hasOtherProp == false ) then
					-- 生産ボーナスが minVal 以上の時のみ表示
					local talisProps = {}
					local minVal = 15

					if ( itemPropKeys.craftBonusHq ) then
						local vals = itemPropKeys.craftBonusHq
						local str = L""
						talisProps.hqNum = vals.num
						if ( vals.childTid ) then
							local skillName = GetStringFromTid( vals.childTid )
							skillName = wstring_gsub( skillName, L"^[^[]+%[", L"" )
							skillName = wstring_gsub( skillName, L"%].*$", L"" )
							talisProps.skillName = skillName
						end
					end
					if ( itemPropKeys.craftBonus ) then
						local vals = itemPropKeys.craftBonus
						local str = L""
						talisProps.boNum = vals.num
						if ( vals.childTid ) then
							local skillName = GetStringFromTid( vals.childTid )
							skillName = wstring_gsub( skillName, L"^[^[]+%[", L"" )
							skillName = wstring_gsub( skillName, L"%].*$", L"" )
							talisProps.skillName = skillName
						end
					end
					if ( talisProps.skillName ) then
						local hqNum = talisProps.hqNum or 0
						local boNum = talisProps.boNum or 0
						if ( hqNum >= minVal or boNum >= minVal ) then
							-- どちらかのボーナスがminVal以上
							local text = towstring( talisProps.skillName ) .. L":" .. towstring( hqNum ) .. L"-" .. towstring( boNum )
							local obj = {
								text = text,
								color = "note",
							}
							return ClfContnrWin.cacheingItemProp( id, obj, force )
						end
					end
					-- END タリスマン生産ボーナス表示
				end
			end

			-- 矢筒かをチェック
			if ( itemPropKeys.contentsNumArrow or itemPropKeys.contentsNumXbow ) then
				local key = itemPropKeys.contentsNumXbow and "contentsNumXbow" or "contentsNumArrow"
				local num = itemPropKeys[ key ].num
				if ( num ) then
					local suffix = ""
					if ( num > 0 ) then
						-- 矢が入っている時は矢の種類を追記する
						local suffixTbl = {
							contentsNumXbow = " Xb",
							contentsNumArrow = " Ar",
						}
						suffix = suffixTbl[ key ] or ""
					end
					local obj = {}
					obj.text = towstring( "(" .. num .. ")" .. suffix )
					obj.color = "note"
					return ClfContnrWin.cacheingItemProp( id, obj, force )
				end
			end

			-- バッグ（コンテナ）かをチェック
			if ( itemPropKeys.contentsNum and itemPropKeys.contentsNum.num ) then
				-- 内容物個数がある。バッグ類
				local obj = {}
				local num = itemPropKeys.contentsNum.num
				local text = towstring( "(" .. num .. ")" )
				if ( itemPropKeys.carvedSeal and itemPropKeys.carvedSeal.raw ) then
					-- 刻印があれば追記
					text = text .. towstring( itemPropKeys.carvedSeal.raw  )
				end
				obj.text = text
				if ( num >= 95 ) then
					obj.color = "warn"
				else
					obj.color = "note"
				end
				return ClfContnrWin.cacheingItemProp( id, obj, force )
			end

			-- アイテムの重量をチェック
			if ( itemPropKeys.weight and itemPropKeys.weight.num == 50 ) then
				-- 重量が50ならキャッシュに保持して、ここで終了
				local obj = {}
				obj.text = itemPropKeys.weight.text
				obj.color = "unwieldy"
				return ClfContnrWin.cacheingItemProp( id, obj, force )
			end

			local condKey = "Other"

			if ( isTalis ) then
				-- タリスマン
				condKey = "Talis"
				magicPropLen = magicPropLen + registPropLen
			elseif ( ClfContnrWin.isAccessory( itemData, props ) ) then
				condKey = "Acce"
				-- アクセの時は属性抵抗プロパティもマジックプロパティとして数える
				magicPropLen = magicPropLen + registPropLen
			elseif ( itemPropKeys.wearableStr or itemPropKeys.lowerRequirements ) then
				-- 装備STRプロパティ or 装備条件軽減がある：何らかの装備品
				condKey = "Equip"
				if ( itemPropKeys.oneHand ) then
					-- 片手武器
					condKey = "OneHand"
					-- 武器の時は属性抵抗プロパティもマジックプロパティとして数える
					magicPropLen = magicPropLen + registPropLen
				elseif ( itemPropKeys.twoHand ) then
					-- 両手武器
					condKey = "TwoHand"
					-- 武器の時は属性抵抗プロパティもマジックプロパティとして数える
					magicPropLen = magicPropLen + registPropLen
				else
					-- 防具かどうかを判定
					if ( not itemPropKeys.spellChanneling and ( registPropLen >= 4 and magicPropLen >= 1 ) ) then
						-- 詠唱可がついておらず、属性抵抗プロパティが4個以上でマジックプロパティがある： 多分防具。。。
						condKey = "Armor"
					elseif ( registPropLen >= 1 and ( itemPropKeys.spellChanneling or magicPropLen >= 1) ) then
						-- 属性抵抗が1つ以上でマジックプロパティがある： 多分シールド。。。
						condKey = "Shield"
					end
				end
			elseif ( ClfContnrWin.isGargEquip( itemData ) ) then
				-- ガーゴ用の首輪、イヤリング ※防具扱いだが装備STRが無い
				condKey = "Armor"
			end

			local condTable = ClfContnrWin.DisplayCondTable[ condKey ] or {}

			-- 返却する為のプロパティ用オブジェクトを配列にして格納
			local retObjs = {}
			local doBreak = false

			-- tIDの有無だけで判定するプロパティ
			local uniqueCondTable = ClfContnrWin.UniqueCondTable or {}
			local RefRelationTable = ClfContnrWin.RelationTable
			for i = 1, #uniqueCondTable, 1 do
				local cond = uniqueCondTable[ i ]
				local key = cond.key
				if ( itemPropKeys[ key ] ) then
					local text = cond.text
					-- 関連情報の設定をチェック
					local relation = cond.relation
					if ( relation and RefRelationTable[ relation ] ~= nil ) then
						local relTbl = RefRelationTable[ relation ]
						for r = 1, #relTbl, 1 do
							local rCond = relTbl[ r ]
							if ( itemPropKeys[ rCond.key ] ) then
								if ( text ~= nil ) then
									text = text .. " -" .. rCond.text
								else
									text = rCond.text
								end
								break
							end
						end
					end
					local obj = {
						priority = cond.priority or 99999,
						propKey = cond.key or "any",
						hue = cond.hue,
						text = text,
						color = cond.color,
					}
					if ( cond.useRawText ) then
						local valTbl = itemPropKeys[ key ]
						obj.rawText = valTbl.text
					end
					retObjs[ #retObjs + 1 ] = obj
					doBreak = doBreak or cond.doBreak
					if ( doBreak ) then
						break
					end
				end
			end

			if ( not doBreak  ) then
				local tostring = tostring
				-- 表示するプロパティの条件を走査
				for i = 1, #condTable, 1 do
					local cond = condTable[ i ]
					local key = cond.key
					if ( itemPropKeys[ key ] ) then
						local valTbl = itemPropKeys[ key ]
						-- 条件付きで表示するプロパティがあった
						itemPropKeys[ key ].color = cond.color
						val = valTbl.num or 0
						if (
								( not cond.minVal and not cond.maxVal )
								or ( cond.minVal and val >= cond.minVal )
								or ( cond.maxVal and val <= cond.maxVal )
							) then
							local priority = cond.priority or 99999
							local propKey = cond.key or "any"
							local text = cond.text
							if ( text == nil ) then
								local prefix = cond.prefix or ""
								local suffix = cond.suffix or ""
								text = prefix .. tostring( val ) .. suffix
							end
							local obj = {
								propKey = propKey,
								hue = cond.hue,
								color = cond.color,
								val = val,
								priority = priority,
								text = text,
							}
							if ( cond.useRawText ) then
								obj.rawText = valTbl.text
							end
							retObjs[ #retObjs + 1 ] = obj
							doBreak = doBreak or cond.doBreak
							if ( doBreak ) then
								break
							end
						end
					end
				end
			end

			-- プロパティのpriority順にソート （priorityが同じならプロパティ値が大きい順）
			if ( #retObjs > 1 ) then
				local function sortFunc( a, b )
					local pa = a.priority
					local pb = b.priority
					if ( pa and pb ) then
						if ( pa == pb ) then
							local va = a.val
							local vb = b.val
							if ( va or vb ) then
								if ( va == nil ) then
									return false
								elseif ( vb == nil ) then
									return true
								end
								return ( va > vb )
							end
						end
						return ( pa < pb )
					elseif ( pa ) then
						return true
					else
						return false
					end
				end
				table.sort( retObjs, sortFunc )
			end

			-- プロパティの配列から、priority順にテキスト・文字色などを取り出す
			local retText
			local retColor
			local retHue
			if ( #retObjs > 0 ) then
				for i = 1, #retObjs, 1 do
					local v = retObjs[ i ]
					retColor = retColor or v.color
					retText = retText or v.rawText or v.text
					retHue = retHue or v.hue
					if ( retColor and retText and retHue ) then
						break
					end
				end
			end

			-- カースドまたは短命の場合は、priorityに関わらずその文字色を優先する
			if ( itemPropKeys.cursed ) then
				retColor = itemPropKeys.cursed.color or retColor
			elseif ( itemPropKeys.antique  ) then
				retColor = itemPropKeys.antique.color or retColor
			end

			if ( retText and type( retText ) ~= "wstring" ) then
				retText = towstring( retText );
			end

			local retObj = {
				text = retText,
				color = retColor,
				hue = retHue,
				objs = retObjs,
			}

			if ( retObjs and #retObjs > 0 ) then
				return ClfContnrWin.cacheingItemProp( id, retObj, force )
			end

			return ClfContnrWin.cacheingItemProp( id, nil, force )
		end	-- /END ( props and props.PropertiesTids and props.PropertiesList )

	end

	return {}
end


function ClfContnrWin.onObjectInfoEvent()
	local objectId = WindowData.UpdateInstanceId
	ItemCache[ objectId ] = nil
	PropTidsObjCache[ objectId ] = nil
end


function ClfContnrWin.cachingPropTidsObj( propTidsObj, id )
	if ( not id or id < 1 ) then
		return
	end
	PropTidsObjCache[ id ] = propTidsObj
end


-- アイテムプロパティから、tidとその情報を対にしたテーブルを得る
--[[**
* @return
* ret = { [tid:Number] = {
* 		tId = Number,
* 		text = Wstring,
* 		val = Number,
* 		raw = Wstring,	// props.PropertiesListに入っている文字列
* 		childTid = childTid:Number,
* 		childTids = { childTid:Number, ... },
* 		props = { { val=Num, raw=Wstr }, ... },
* 	}, ...
* }
**]]--
function ClfContnrWin.getPropTidsObj( id, props )
	if ( PropTidsObjCache[ id ] ~= nil ) then
		return PropTidsObjCache[ id ]
	end

	local ret = {}

	if ( not props ) then
		if ( id ) then
			props = WindowData.ItemProperties[ id ]
			if ( not props ) then
				RegisterWindowData( WindowData.ItemProperties.Type, id )
				props = WindowData.ItemProperties[ id ]
				if ( not props ) then
					return ret
				end
			end
		else
			return ret
		end
	end

	-- まず、tIdとそのテキストを対にしたテーブルを作る
	local tids = props.PropertiesTids
	local names = props.PropertiesList
	if ( tids == nil or names == nil ) then
		return ret
	end
	for i = 1, #tids, 1 do
		local tid = tids[ i ]
		ret[ tid ] = {
			text = names[ i ],
			tId = tid,
		}
	end

	-- テーブルのtId行にその値を追加する
	local tidsParams = props.PropertiesTidsParams
	if ( tidsParams ~= nil ) then
		local tidsParams = props.PropertiesTidsParams
		local tId
		local childTid
		local tonumber = tonumber
		local wstring_match = wstring.match

		for i = 1, #tidsParams, 1 do
			v = tidsParams[ i ]
			local parentTid = wstring_match( v, L"^@(%d+)$" )
			if ( parentTid ) then
				-- 親のtId
				tId = tonumber( parentTid )
				if ( not ret[ tId ] ) then
					ret[ tId ] = { tId = tId }
				end
			elseif ( ret[ tId ] ) then
				local ret_tId = ret[ tId ]
				local childTid = wstring_match( v, L"^#(%d+)$" )
				if ( childTid ) then
					-- 子のtId（スキル増加プロパティのスキル種類、タリスマンのボーナススキル種類など）
					local cTid = tonumber( childTid )
					-- テーブル直下のchildTidには最初に取得できた値を保持
					ret_tId.childTid = ret_tId.childTid or cTid
					-- childTidsに、取得出来た子tId全てを配列として保持
					if ( ret_tId.childTids == nil ) then
						ret_tId.childTids = {}
					end
					ret_tId.childTids[ #ret_tId.childTids + 1 ] = cTid
				else
					-- プロパティ値
					local numVal = tonumber( v )
					-- テーブル直下のnum, rawには最初に取得できた値を保持
					ret_tId.num = ret_tId.num or numVal
					ret_tId.raw = ret_tId.raw or v
					-- propValsに、取得出来た値を配列として保持
					if ( ret_tId.propVals == nil ) then
						ret_tId.propVals = {}
					end
					ret_tId.propVals[ #ret_tId.propVals + 1 ] = {
						num = numVal,
						raw = v,
					}
				end
			end
		end
	end

	ClfContnrWin.cachingPropTidsObj( ret, id )
	return ret
end


local ACCE_NAME_TID = {
	[1024234] = true,	-- 指輪
	[1027945] = true,	-- 指輪
	[1024230] = true,	-- ブレスレット
	[1027942] = true,	-- ブレスレット
	[1024231] = true,	-- イヤリング
	[1024229] = true,	-- ネックレス
	[1024232] = true,	-- ネックレス
	[1024233] = true,	-- ネックレス
	[1095786] = true,	-- ガーゴイルリング
	[1095785] = true,	-- ガーゴイルブレスレット

	[L"#1024234"] = true,	-- 指輪
	[L"#1027945"] = true,	-- 指輪
	[L"#1024230"] = true,	-- ブレスレット
	[L"#1027942"] = true,	-- ブレスレット
	[L"#1024231"] = true,	-- イヤリング
	[L"#1024229"] = true,	-- ネックレス
	[L"#1024232"] = true,	-- ネックレス
	[L"#1024233"] = true,	-- ネックレス
	[L"#1095786"] = true,	-- ガーゴイルリング
	[L"#1095785"] = true,	-- ガーゴイルブレスレット
}

-- itemDataからアクセサリーかどうかを返す
function ClfContnrWin.isAccessory( itemData, props )
	if ( ( not itemData or not itemData.objectType ) and props ) then
		local nameTids = ACCE_NAME_TID
		local tids_1 = props.PropertiesTids and props.PropertiesTids[1]
		if ( tids_1 and nameTids[ tids_1 ] ) then
			return true
		else
			local tidParams = props.PropertiesTidsParams
			if ( tidParams and #tidParams >= 4 ) then
				for i = 2, 4 do
					if ( nameTids[ tidParams[ i ] ] ) then
						return true
					end
				end
			end
		end
	end
	return ClfContnrWin.isItemType( itemData, "Accessory" )
end


-- itemDataからタリスマンかどうかを返す
function ClfContnrWin.isTalisman( itemData, props )
	if ( ( not itemData or not itemData.objectType ) and props ) then
		local tids_1 = props.PropertiesTids and props.PropertiesTids[1]
		if ( tids_1 and ClfD.TalisNameTids[ tids_1 ] ) then
			return true
		end
	end
	return ClfContnrWin.isItemType( itemData, "Talisman" )
end

-- itemDataからGargoyle用首輪、イヤリングかどうかを返す ※防具扱いだが装備STRが無い
function ClfContnrWin.isGargEquip( itemData )
	return ClfContnrWin.isItemType( itemData, "gargEquip" )
end


-- itemDataからitemTypeかどうかを返す
function ClfContnrWin.isItemType( itemData, itemType )
	if ( not itemData or not itemType ) then
		return
	end
	local isType = false
	local objectType = itemData.objectType
	if ( objectType) then
		local RefObjectType = ClfD.ObjectTypes[ objectType ] or {}
		isType = ( RefObjectType.typeName == itemType )
	end
	return isType
end



--local SummnBallStr = wstring.lower( GetStringFromTid(1054131) )

-- Override: ContainerWindow.UpdateObject
function ClfContnrWin.updateObject( windowName, updateId )
	if ( not DoesWindowExist( windowName ) ) then
		return
	end

	local WindowData = WindowData
	if ( WindowData.ObjectInfo[ updateId ] == nil ) then
		RegisterWindowData( WindowData.ObjectInfo.Type, updateId )
	end

	if ( WindowData.ObjectInfo[ updateId ] ~= nil ) then

		local DoesWindowExist = DoesWindowExist

		local containerId = WindowData.ObjectInfo[updateId].containerId
		local viewMode = ContainerWindow.ViewModes[containerId]
		local gridIndex
		-- if this object is in my container
		if( containerId == WindowGetId( windowName ) ) then
			-- find the slot index
			local containedItems = WindowData.ContainerWindow[ containerId ].ContainedItems
			local numItems = WindowData.ContainerWindow[ containerId ].numItems
			local listIndex = 0
			for i = 1, numItems, 1 do
				if ( containedItems[ i ].objectId == updateId ) then
					listIndex = i
					gridIndex = containedItems[ i ].gridIndex
					break
				end
			end
			local item = WindowData.ObjectInfo[ updateId ]

			if ( viewMode == "List" )then
				-- Name
				local ElementName = windowName .. "ListViewScrollChildItem" .. listIndex .. "Name"
				local scl = WindowGetScale( windowName )
				local isElementNameWinExist = DoesWindowExist( ElementName )
				if (
						isElementNameWinExist and ContainerWindow.ViewModes[WindowGetId(windowName)] ~= "Freeform"
					) then
					WindowSetScale( ElementName, scl )
				end

				local name =  Shopkeeper.stripFirstNumber( item.name )

				-- ちゃんと動かない処理が入っているので省略
--				local summBall
--				if ( wstring.find( SummnBallStr, L":") ) then
--					summBall = wstring.sub( SummnBallStr, 1, wstring.find( SummnBallStr, L":") - 1 )
--				end
--				if ( summBall and ( name and type( name ) ~= "string" and type( summBall ) ~= "wstring") ) then
--					if ( wstring.find( wstring.lower( name ), summBall) ) then
--						name = summBall
--					end
--				end

				if ( name and name ~= "" and item.quantity > 1 ) then
					local commaQ = WindowUtils.AddCommasToNumber( item.quantity )
					if ( commaQ ) then
						name = commaQ .. L" " .. name
					end
				end

				if ( name and name ~= "" and isElementNameWinExist ) then
					local wstring_lower = wstring.lower
					local GetStringFromTid = GetStringFromTid
					local nameLower = wstring_lower( name )

					if ( nameLower == wstring_lower( GetStringFromTid(1041361) ) ) then -- a bank check
						local prop = ItemProperties.GetObjectProperties( updateId, 4, "Container Window - Update Object - Bank Check" )
						LabelSetText( ElementName, FormatProperly( name .. L"\n   " .. prop ) )
					elseif ( nameLower == wstring_lower( GetStringFromTid(1078604) ) ) then -- scroll of alacrity
						local prop = ItemProperties.GetObjectPropertiesTidParams( updateId, 4, "Container Window - Update Object - Scroll of alacrity" )
						local skill = tostring( wstring.gsub( prop[1], L"#", L"" ) )
						skill = tonumber( skill )
						if ( skill ~= nil )then
							prop = GetStringFromTid(1149921) .. L" " .. GetStringFromTid( skill )
							LabelSetText( ElementName, FormatProperly( name .. L"\n   " .. prop ) )
						end
					elseif ( nameLower == wstring_lower( GetStringFromTid(1094934) ) ) then -- scroll of transcendence
						local prop = ItemProperties.GetObjectPropertiesTidParams( updateId, 4, "Container Window - Update Object - scroll of transcendence" )
						local skill = tostring( wstring.gsub( prop[1], L"#", L"") )
						skill = tonumber( skill )
						if ( skill ~= nil ) then
							prop = GetStringFromTid(1149921) .. L" " .. GetStringFromTid( skill )
							LabelSetText( ElementName, FormatProperly( name .. L"\n   " .. prop ) )
						end
					else
						LabelSetText( ElementName, FormatProperly( name ) )
					end
				end

				if ( isElementNameWinExist ) then
					ItemProperties.GetCharges( updateId )
					local uses = ContainerWindow.GetUses( updateId, containerId )
					if ( uses ~= nil ) then
						local charge = FormatProperly( name .. L"\n  " .. uses[1] )
						ClfContnrWin.labelSetOptProp( ElementName, updateId, nil, item, "list", nil, charge )
					else
						local prefix = name .. L"\n  "
						ClfContnrWin.labelSetOptProp( ElementName, updateId, nil, item, "list", prefix )
					end
					WindowSetShowing( ElementName, true )
				end

				-- Icon
				local elementIcon = windowName .. "ListViewScrollChildItem" .. listIndex .. "Icon"
				if( item.iconName ~= "" ) then
					if ( Interface.TrapBoxID == 0 and Interface.oldTrapBoxID == updateId ) then
						Interface.oldTrapBoxID = 0
					end
					if ( Interface.LootBoxID == 0 and Interface.oldLootBoxID == updateId ) then
						Interface.oldLootBoxID = 0
					end
					item.id = updateId
					EquipmentData.UpdateItemIcon( elementIcon, item )

					parent = WindowGetParent( elementIcon )
					WindowClearAnchors( elementIcon )
					WindowAddAnchor( elementIcon, "topleft", parent, "topleft", 15+((45-item.newWidth)/2), 15+((45-item.newHeight) / 2) )

					WindowSetShowing( elementIcon, true )
				else
					WindowSetShowing( elementIcon, false )
				end
			end	-- /end if listView

			if ( item.iconName ~= "" ) then
				local socketName = windowName .. "GridViewSocket" .. gridIndex
				local elementIcon = socketName .. "Icon"
				local elementIconMulti = elementIcon .. "Multi"

				if ( DoesWindowExist( elementIcon ) ) then
					item.id = updateId
					EquipmentData.UpdateItemIcon( elementIcon, item )

					local gridViewItemLabel = socketName .. "Quantity"

					if ( item.quantity ~= nil and item.quantity > 1 ) then
						LabelSetText( gridViewItemLabel, Knumber( item.quantity ) )
						local color =  ClfContnrWin.ColorTbl.default or DefaultTxtColor
						LabelSetTextColor( gridViewItemLabel, color.r, color.g, color.b )
					else
						ItemProperties.GetCharges( updateId )
						local uses = ContainerWindow.GetUses( updateId, containerId )
						if ( uses ~= nil ) then
							ClfContnrWin.labelSetOptProp( gridViewItemLabel, updateId, elementIcon, item, "grid", nil, Knumber( uses[2] ) )
						else
							ClfContnrWin.labelSetOptProp( gridViewItemLabel, updateId, elementIcon, item, "grid" )
						end
					end
				end

				if ( DoesWindowExist( elementIconMulti ) ) then
					if ( item.quantity > 1 and item.objectType ~= 3821 and item.objectType ~= 3824 ) then
						EquipmentData.UpdateItemIcon( elementIconMulti, item )
						WindowSetShowing( elementIconMulti, true )
					else
						WindowSetShowing( elementIconMulti, false )
						DynamicImageSetTexture( elementIconMulti, "", 0, 0 )
					end
				end

			end
		end
	end
end


-- Override: ContainerWindow.UpdateGridViewSockets
function ClfContnrWin.updateGridViewSockets( id )
	local windowName = "ContainerWindow_" .. id
	if ( DoesWindowExist( windowName ) ~= true ) then
		return
	end

	local WindowData = WindowData
	local ContainerWindow = ContainerWindow
	local CW_Grid = ContainerWindow.Grid
	local CW_Grid_SocketSize = CW_Grid.SocketSize

	local math_floor = math.floor
	local math_ceil = math.ceil
	local DoesWindowExist = DoesWindowExist
	local WindowClearAnchors = WindowClearAnchors
	local WindowSetScale = WindowSetScale
	local WindowAddAnchor = WindowAddAnchor
	local WindowSetShowing = WindowSetShowing

	local data = WindowData.ContainerWindow[ id ]

	local gridViewName = windowName .. "GridView"
	local scrollViewChildName = gridViewName .. "ScrollChild"

	-- determine the grid dimensions based on window width and height
	local windowWidth, windowHeight = WindowGetDimensions( windowName )
	local GRID_WIDTH = math_floor( ( windowWidth - ( CW_Grid.PaddingLeft + CW_Grid.PaddingRight ) ) / CW_Grid_SocketSize + 0.5 )
	local GRID_HEIGHT = math_floor( ( windowHeight - ( CW_Grid.PaddingTop + CW_Grid.PaddingBottom ) ) / CW_Grid_SocketSize + 0.5 )
	local numSockets = GRID_WIDTH * GRID_HEIGHT
	local isNotBankBox = true
	local bankData = WindowData.PlayerEquipmentSlot[ EquipmentData.EQPOS_BANK ]
	if ( bankData and id == bankData.objectId )then
		isNotBankBox = false
	end
	if ( isNotBankBox and numSockets > ContainerWindow.MAX_INVENTORY_SLOTS ) then
		numSockets = ContainerWindow.MAX_INVENTORY_SLOTS
	end

	local allSocketsVisible = numSockets >= data.maxSlots

	-- if numSockets is less than 125, we need additional rows to provide at least 125 sockets.
	if ( allSocketsVisible == false ) then
		GRID_HEIGHT = math_ceil( data.maxSlots / GRID_WIDTH )
		numSockets = GRID_WIDTH * GRID_HEIGHT
		if ( isNotBankBox and numSockets > ContainerWindow.MAX_INVENTORY_SLOTS ) then
			numSockets = ContainerWindow.MAX_INVENTORY_SLOTS
		end
	end

	if ( not data.numGridSockets ) then
		ContainerWindow.CreateGridViewSockets( windowName, 1, numSockets )
	else
		-- create additional padding sockets if needed or destroy extra ones from the last resize
		if ( data.numGridSockets > numSockets ) then
			ContainerWindow.DestroyGridViewSockets( windowName, numSockets + 1, data.numGridSockets )
		elseif ( data.numGridSockets < numSockets ) then
			ContainerWindow.CreateGridViewSockets( windowName, data.numGridSockets + 1, numSockets )
		end
	end

	local scl = WindowGetScale( windowName )
	data.numGridSockets = numSockets

	-- position and anchor the sockets
	local socketNameBase = windowName .. "GridViewSocket"
	local prevSocketName

	for i = 1, data.numGridSockets, 1 do
		local socketName = socketNameBase .. i
		if ( DoesWindowExist( socketName ) ) then
			WindowClearAnchors( socketName )
		end
		WindowSetScale( socketName, scl )
		if ( i == 1 ) then
			WindowAddAnchor( socketName, "topleft", scrollViewChildName, "topleft", 0, 0 )
		elseif ( i % GRID_WIDTH ) == 1 then
			WindowAddAnchor( socketName, "bottomleft", socketNameBase .. ( i - GRID_WIDTH ), "topleft", 0, 1 )
		else
			WindowAddAnchor( socketName, "topright", prevSocketName, "topleft", 1, 0 )
		end
		prevSocketName = socketName
		-- //ここではグリッドを整列するだけなので、multiアイコンの非表示は不要と思われる
		-- // ContainerWindow.UpdateObject にて表示・非表示を切り分けている
--		if ( DoesWindowExist( socketName .. "IconMulti" ) ) then
--			WindowSetShowing( socketName .. "IconMulti", false )
--		end
		WindowSetShowing( socketName, true )
	end

	-- dimensions for the entire grid view with GRID_WIDTH x GRID_HEIGHT dimensions
	local newGridWidth = GRID_WIDTH * CW_Grid_SocketSize + CW_Grid.PaddingLeft
	local newGridHeight = GRID_HEIGHT * CW_Grid_SocketSize + CW_Grid.PaddingTop

	-- fit the window width to the grid width
	local newWindowWidth = newGridWidth + CW_Grid.PaddingRight
	local newWindowHeight = windowHeight

	-- if we can see every slot in the container, snap the window height to the grid and hide the void created
	-- by the missing scrollbar
	if ( allSocketsVisible ) then
		newWindowHeight = newGridHeight + CW_Grid.PaddingBottom
		newWindowWidth = newWindowWidth - ContainerWindow.ScrollbarWidth
	else
		newWindowHeight = windowHeight
		newGridHeight = windowHeight - ( CW_Grid.PaddingBottom + CW_Grid.PaddingTop )
	end
	WindowSetDimensions( windowName, newWindowWidth, newWindowHeight )
	WindowSetDimensions( gridViewName, newGridWidth, newGridHeight )

	local openContData = ContainerWindow.OpenContainers[ id ]
	if ( openContData ) then
		openContData.slotsWide = GRID_WIDTH
		openContData.slotsHigh = GRID_HEIGHT
		local staticGridWidth = math_floor( ( windowWidth - ( CW_Grid.PaddingLeft + CW_Grid.PaddingRight ) ) / CW_Grid_SocketSize + 0.5 )
		local staticGridHeight = math_ceil( data.maxSlots / staticGridWidth )
		openContData.windowWidth = staticGridWidth * CW_Grid_SocketSize + CW_Grid.PaddingLeft
		openContData.windowHeight = staticGridHeight * CW_Grid_SocketSize + CW_Grid.PaddingTop
		WindowSetDimensions( scrollViewChildName, openContData.windowWidth, openContData.windowHeight )
	end

	WindowSetShowing( gridViewName, true )
	ScrollWindowUpdateScrollRect( gridViewName )
	ContainerWindow.UpdateGridItemSlots( id )
end


-- Override: ContainerWindow.CreateGridViewSockets
function ClfContnrWin.createGridViewSockets( dialog, lower, upper )
	local id = WindowGetId( dialog )
	local data = WindowData.ContainerWindow[ id ]

	if ( not data ) then
		return
	end
	local ContainerWindow = ContainerWindow
	local Interface = Interface

	lower = lower or 1

	local maxSlots = data.maxSlots

	if ( not upper ) then
		upper = maxSlots
		if ( upper > ContainerWindow.MaxSlotsPerGrid ) then
			upper = ContainerWindow.MaxSlotsPerGrid
		end
	end

	local parent = dialog .. "GridViewScrollChild"
	local socketNameBase = dialog .. "GridViewSocket"
	local legacyContainersMode = SystemData.Settings.Interface.LegacyContainers

	local DoesWindowExist = DoesWindowExist
	local DestroyWindow = DestroyWindow
	local CreateWindowFromTemplateShow = CreateWindowFromTemplateShow
	local WindowSetTintColor = WindowSetTintColor
	local WindowSetId = WindowSetId
	local WindowSetAlpha = WindowSetAlpha
	local WindowSetShowing = WindowSetShowing

	local CW_BaseGridColor = ContainerWindow.BaseGridColor
	local baseR, baseG, baseB = CW_BaseGridColor.r, CW_BaseGridColor.g, CW_BaseGridColor.b

	-- AlternateGrid flag
	local color = false
	local altR, altG, altB

	-- local functions
	local setGridTintColor = _void
	local getSocketTemplateName

	if ( legacyContainersMode == true ) then
		getSocketTemplateName = function()
			return "GridViewSocketLegacyTemplate"
		end
	elseif ( Interface.EnableContainerGrid ) then
		-- Enable Grid On Containers チェック時
		if ( ClfContnrWin.EnableWhiteGrid ) then
			-- ClifeUIで追加した白背景のグリッド
			getSocketTemplateName = function( index )
				if ( index > maxSlots ) then
					return "GridViewSocketBaseTemplate"
				end
				return "ClfWhiteGridViewSocketTemplate"
			end
		elseif ( Interface.ExtraBrightContainers ) then
			-- Enable Extra Bright Background チェック時
			getSocketTemplateName = function( index )
				if ( index > maxSlots ) then
					return "GridViewSocketBaseTemplate"
				end
				return "ClfColoredGridViewSocketTemplate"
			end
		else
			getSocketTemplateName = function( index )
				if ( index > maxSlots ) then
					return "GridViewSocketBaseTemplate"
				end
				return "ClfGridViewSocketTemplate"
			end
		end

		if ( Interface.AlternateGrid ) then
			local CW_AlternateBackpack = ContainerWindow.AlternateBackpack
			altR, altG, altB = CW_AlternateBackpack.r, CW_AlternateBackpack.g, CW_AlternateBackpack.b
			setGridTintColor = function( socketName, baseR, baseG, baseB )
				if ( color == true ) then
					WindowSetTintColor( socketName, altR, altG, altB )
				else
					WindowSetTintColor( socketName, baseR, baseG, baseB )
				end
				color = not color
			end
		else
			setGridTintColor = WindowSetTintColor
		end
	else
		-- 背景無し: not Interface.EnableContainerGrid
		getSocketTemplateName = function( index )
			if ( index > maxSlots ) then
				return "GridViewSocketBaseTemplate"
			end
			return "ClfClearGridViewSocketTemplate"
		end
	end

	for i = lower, upper, 1 do
		local socketName = socketNameBase .. i
		local socketTemplate = getSocketTemplateName( i )

		if ( DoesWindowExist( socketName ) ) then
			DestroyWindow( socketName )
		end
		CreateWindowFromTemplateShow( socketName, socketTemplate, parent, false )
		WindowSetId( socketName, i )

		if ( i > maxSlots ) then
			WindowSetAlpha( socketName, 0.5 )
			WindowSetTintColor( socketName, 10, 10, 10 )
		else
			setGridTintColor( socketName, baseR, baseG, baseB )
		end
	end
end


-- override: ContainerWindow.Initialize （コンテナウィンドウが開いた時）
function ClfContnrWin.onWindowInitialize()
	local containerId = SystemData.DynamicWindowId
	--	local win = SystemData.ActiveWindow.name
	if ( not containerId ) then
		return
	end
	ClfContnrWin.setupContent( containerId )
	-- オリジナルの ContainerWindow.Initialize を実行
	ClfContnrWin.Initialize_org()

	-- トレハンの箱か判定開始
	ClfContnrWin.checkIsTreasureBox( containerId )
end


-- コンテナウィンドウ下部の容量表記をアウトライン有りのフォントに変更
function ClfContnrWin.setupContent( containerId )
	local contentLabel = "ContainerWindow_" .. containerId .. "Content"
	if ( DoesWindowExist( contentLabel ) ) then
		LabelSetFont( contentLabel, "UO_Default_Outline_Text", 20 )
	end
end


-- コンテナIDを指定してトレハンの箱か判定
function ClfContnrWin.checkIsTreasureBox( id )
	if ( id == nil or id == 0 ) then
		return
	end

	local WindowData = WindowData
	local containerData = WindowData.ContainerWindow[ id ]
	if ( containerData and containerData.isCorpse ) then
		-- 棺桶コンテナ
		KnownTreasureBox[ id ] = nil
		return
	end

	if ( IsInPlayerBackPack( id ) ) then
		-- プレイヤーが所持しているコンテナ
		KnownTreasureBox[ id ] = nil
		return
	end

	local itemData = WindowData.ObjectInfo[ id ]
	local registItemData = false
	if ( itemData == nil ) then
		RegisterWindowData( WindowData.ObjectInfo.Type, id )
		registItemData = true
		itemData = WindowData.ObjectInfo[ id ]
	end
	if ( itemData and itemData.containerId and itemData.containerId ~= 0 ) then
		-- 親コンテナがあるコンテナ
		KnownTreasureBox[ id ] = nil
		if ( registItemData == true ) then
			UnregisterWindowData( WindowData.ObjectInfo.Type, id )
		end
		return
	end

	-- 対象のコンテナのコンテキストメニューを調べる
	ClfUtil.requestContextMenuItemData( id, ClfContnrWin.contextMenuItemDataReceived )
end


-- コンテナのコンテキストメニュー判定コールバック
function ClfContnrWin.contextMenuItemDataReceived( menuItems, id )
	local isTreBox = false

	if ( menuItems and id ) then
		for i = 1, #menuItems do
			local item = menuItems[ i ]
			-- 3006149: 宝箱をどける
			if ( item.returnCode == 306 or item.tid == 3006149 ) then
				KnownTreasureBox[ id ] = true
				isTreBox = true
				break
			end
		end

		if ( isTreBox ~= true ) then
			KnownTreasureBox[ id ] = nil
		end
	end
end


function ClfContnrWin.isTreasureBox( containerId )
	return ( KnownTreasureBox[ containerId ] == true )
end


-- override: ContainerWindow.OnItemGet （コンテナ内アイテム右クリック時）
function ClfContnrWin.onItemGet( flags )
	local ContainerWindow = ContainerWindow

	local index = WindowGetId( SystemData.ActiveWindow.name )
	local containerId = WindowGetId( WindowUtils.GetActiveDialog() )
	local slotNum = ContainerWindow.GetSlotNumFromGridIndex( containerId, index )

	if ( slotNum ~= nil ) then
		local ContainerData = WindowData.ContainerWindow[ containerId ]
		local objectId = ContainerData.ContainedItems[ slotNum ].objectId

		if ( objectId ~= nil and objectId ~= 0  ) then
			local itemData = WindowData.ObjectInfo[ objectId ]
			local SD_ButtonFlags = SystemData.ButtonFlags
			if ( flags == SD_ButtonFlags.CONTROL and itemData and itemData.quantity > 1 ) then
				ContainerWindow.DragOne = true
				ContainerWindow.HoldShiftBackup = SystemData.Settings.GameOptions.holdShiftToUnstack
				SystemData.Settings.GameOptions.holdShiftToUnstack = false
				UserSettingsChanged()
				DragSlotSetObjectMouseClickData( objectId, SystemData.DragSource.SOURCETYPE_CONTAINER )
				ContainerWindow.GetContentDelta[ containerId ] = 0
				ContainerWindow.ReleaseRegisteredObjectsByID( objectId, containerId )
				ContainerWindow.UpdateContents( containerId )
				return
			end

			-- If player is trying to get objects from a container that is not from the players backpack have it dropped
			-- into the players backpack
			if (
					ContainerData.isCorpse == true
					or ( flags == SD_ButtonFlags.SHIFT and ClfContnrWin.EnableShiftRhClkLoot == true )
					or ClfContnrWin.isTreasureBox( containerId ) == true
				) then
				if ( ContainerWindow.CanPickUp == true ) then
					if ( itemData ) then
						local dropContainer
						if ( itemData.objectType == 3821 and ClfContnrWin.isTreasureBox( containerId ) ~= true ) then
--							DragSlotAutoPickupObject( objectId )
							dropContainer = MoveItemToContainer( objectId, itemData.quantity, ContainerWindow.PlayerBackpack )
						else
							local lootBag = ( Interface.LootBoxID ~= 0 ) and Interface.LootBoxID or ContainerWindow.PlayerBackpack
							dropContainer = MoveItemToContainer( objectId, itemData.quantity, lootBag )
						end

						ContainerWindow.GetContentDelta[ containerId ] = 0
						ContainerWindow.ReleaseRegisteredObjectsByID( objectId, containerId )
						ContainerWindow.UpdateContents( containerId )
						if ( dropContainer ~= nil ) then
							ContainerWindow.TimePassedSincePickUp = 0
							ContainerWindow.CanPickUp = false
						end
					end

				else
					PrintTidToChatWindow( 1045157, 1 )
				end
			else
				RequestContextMenu( objectId )
			end
		end
	end
end



-- LootAll用バッグを設定
function ClfContnrWin.targetLootAllBag()
	WindowUtils.SendOverheadText( L"Target Container LootAll", 1152, true)
	RequestTargetInfo()
	WindowRegisterEventHandler( "Root", SystemData.Events.TARGET_SEND_ID_CLIENT, "ClfContnrWin.targetLootAllBagReceived" )
end

function ClfContnrWin.targetLootAllBagReceived()
	local id = SystemData.RequestInfo.ObjectId
	local bagId

	WindowUnregisterEventHandler( "Root", SystemData.Events.TARGET_SEND_ID_CLIENT )

	if ( id and id > 0 ) then
		local itemData = WindowData.ObjectInfo[ id ]
		if ( not itemData ) then
			RegisterWindowData( WindowData.ObjectInfo.Type, id )
			itemData = WindowData.ObjectInfo[ id ]
		end

		if ( IsContainer( id ) ) then
			local name = itemData and itemData.name or towstring( id )

			Interface.LootBoxID = id
			WindowUtils.SendOverheadText( L"set AllLootBag: \"" .. name .. L"\"", 255, true)
		end
	end
end



-- EOF
