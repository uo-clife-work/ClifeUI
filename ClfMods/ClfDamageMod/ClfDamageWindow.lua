ClfDamageWindow = {}

ClfDamageWindow.LIST_ROW_MAX = 10

ClfDamageWindow.WindowSizes = {
	default = { x = 560, y = 350 },
	middle  = { x = 365, y = 350 },
	min     = { x = 130, y = 26 },
}

ClfDamageWindow.LastUpdate = 0
ClfDamageWindow.UpdateDelta = 0

ClfDamageWindow.fontColors = {
	{ r = 170, g = 175, b= 180, },
	{ r = 255, g = 255, b= 255, },
}
ClfDamageWindow.fontColorDead = { r = 210, g = 135, b= 140, }
ClfDamageWindow.fontColorFarAway = { r = 145, g = 125, b= 170, }
ClfDamageWindow.fontColorVisualState = {
	false,		-- 1:Default
	{ r = 110, g = 235, b= 150, },	-- 2:Poison
	{ r = 235, g = 210, b= 35, },		-- 3:Curse
}

ClfDamageWindow.DamageModEnable = nil
ClfDamageWindow.ListUpdateEnable = nil
ClfDamageWindow.PrintChatEnable = nil
ClfDamageWindow.SaveLogEnable = nil

ClfDamageWindow.WindowName = "ClfDamageWindow"
ClfDamageWindow.CurrentWindowSize = "default"

ClfDamageWindow.ListRowIds = {}

ClfDamageWindow.onUpdate = function() end


function ClfDamageWindow.showWindow()
	local window = ClfDamageWindow.WindowName
	if ( not DoesWindowExist( window ) ) then
		CreateWindow( window, false )
		WindowUtils.RestoreWindowPosition( window )
	else
		ClfDamageWindow.setDimension( ClfDamageWindow.CurrentWindowSize )
	end
end


function ClfDamageWindow.initialize()
	local window = ClfDamageWindow.WindowName
	local listOutputEnable = Interface.LoadBoolean( "ClfDamageWindowListOutput", true )
	local size = Interface.LoadString( "ClfDamageWindowSize", ClfDamageWindow.CurrentWindowSize )

	ClfDamageWindow.DamageModEnable = ClfDamageMod.Enable
	ClfDamageWindow.PrintChatEnable = ClfDamageMod.PrintChatEnable
	ClfDamageWindow.SaveLogEnable   = ClfDamageMod.SaveLogEnable

	LabelSetText( window .. "Title", L"Damages" )

	ClfDamageWindow.setListUpdateEnable( listOutputEnable )
	ClfDamageWindow.initSettingBtns()
	ClfDamageWindow.hideSettings()

	WindowSetShowing( window, true )
	WindowUtils.RestoreWindowPosition( window )
	ClfDamageWindow.setDimension( size )
end


function ClfDamageWindow.initSettingBtns()
	local settingWrap = ClfDamageWindow.WindowName .. "SettingMenuCtt"

	if ( not DoesWindowExist( settingWrap ) ) then
		return
	end

	local checkTemplate = "ClfDamageWindowCheckTemplate"
	local checks = {
		{ name = "DamageModEnable",  title = L"Enable", },
		{ name = "ListUpdateEnable", title = L"UpdateList", },
		{ name = "PrintChatEnable",  title = L"PrintChat", },
		{ name = "SaveLogEnable",    title = L"SaveLog", },
	}

	local h = 0
	for i = 1, #checks do
		local check = checks[ i ]
		local win = settingWrap .. check.name

		if ( DoesWindowExist( win ) ) then
			DestroyWindow( win )
		end

		CreateWindowFromTemplateShow( win, checkTemplate, settingWrap, true )

		h = 15 + ( i - 1 ) * 30
		WindowAddAnchor( win, "topleft", settingWrap, "topleft", 20, h )

		local label = win .. "Label"
		LabelSetText( label, check.title )

		local button = win .. "Check"
		local lx = WindowGetDimensions( label )
		local bx = WindowGetDimensions( button )
		WindowSetDimensions( win, lx + bx + 5, 20 )

		if ( ClfDamageWindow[ check.name ] ) then
			ButtonSetStayDownFlag( button, true )
			ButtonSetPressedFlag( button, true )
		end
	end

	WindowSetDimensions( settingWrap, 210, h + 20 )
	WindowSetDimensions( ClfDamageWindow.WindowName .. "SettingMenu", 260, h + 40 )
end


function ClfDamageWindow.checkSettingBtn( name, enable )
	if ( not name ) then
		return
	end

	local button = ClfDamageWindow.WindowName .. "Settings" .. name .. "Check"
	if ( DoesWindowExist( button ) ) then
		ButtonSetStayDownFlag( button, enable )
		ButtonSetPressedFlag( button, enable )
	end
	if ( ClfDamageWindow[ name ] ~= nil ) then
		ClfDamageWindow[ name ] = enable
	end
end

function ClfDamageWindow.setDamageModEnable( enable )
	ClfDamageWindow.DamageModEnable = enable
	if ( ClfDamageMod.Enable ~= enable ) then
		ClfDamageMod.setEnable( enable )
	end
end

function ClfDamageWindow.setPrintChatEnable( enable )
	ClfDamageWindow.PrintChatEnable = enable
	if ( ClfDamageMod.PrintChatEnable ~= enable ) then
		ClfDamageMod.togglePrintChat( true )
	end
end

function ClfDamageWindow.setSaveLogEnable( enable )
	ClfDamageWindow.SaveLogEnable = enable
	if ( ClfDamageMod.SaveLogEnable ~= enable ) then
		ClfDamageMod.toggleSaveLog( true )
	end
end


function ClfDamageWindow.onCheckBtn()
	local parent = WindowGetParent( SystemData.ActiveWindow.name )
	local button = parent .. "Check"
	local enable = not ButtonGetPressedFlag( button )

	ButtonSetStayDownFlag( button, enable )
	ButtonSetPressedFlag( button, enable )

	local funcName = "set" .. string.gsub( parent, ClfDamageWindow.WindowName .. "SettingMenuCtt", "" )
	local func = ClfDamageWindow[ funcName ]

	if ( type( func ) == "function" ) then
		func ( enable )
	else
		Debug.DumpToConsole( "onSettingCheck:NoFunc", funcName )
	end
end


function ClfDamageWindow.toggle()
	local size = "default"
	ClfDamageWindow.hideSettings()

	if ( ClfDamageWindow.CurrentWindowSize == "default" ) then
		-- 中サイズに切替
		size = "middle"
		ClfDamageWindow.clearAllList()
	elseif ( ClfDamageWindow.CurrentWindowSize == "middle" ) then
		-- 小サイズに切替
		size = "min"
	else
		-- 普通サイズに切替
		size = "default"
		ClfDamageWindow.clearAllList()
	end

	ClfDamageWindow.setDimension( size )
end


function ClfDamageWindow.toggleListUpdate()
	ClfDamageWindow.setListUpdateEnable( not ClfDamageWindow.ListUpdateEnable )
end


function ClfDamageWindow.setListUpdateEnable( enable )
	enable = enable or false
	local window = ClfDamageWindow.WindowName
	local listWindow = window .. "List"

	if ( enable ~= ClfDamageWindow.ListUpdateEnable  ) then
		Interface.SaveBoolean( "ClfDamageWindowListOutput", enable )
	end

	if ( enable ) then
		ClfDamageWindow.onUpdate = ClfDamageWindow.onUpdate_enable
		WindowSetFontAlpha( listWindow, 1 )
	else
		ClfDamageWindow.onUpdate = ClfDamageWindow.onUpdate_disable
		WindowSetFontAlpha( listWindow, 0.55 )
	end

	ClfDamageWindow.ListUpdateEnable = enable
end


function ClfDamageWindow.onUpdate_enable( timepassed )
	ClfDamageWindow.UpdateDelta = ClfDamageWindow.UpdateDelta + timepassed
	if ( ClfDamageWindow.UpdateDelta >= 0.8 ) then
		-- 0.8秒ごとに描画更新
		ClfDamageWindow.updateList( false, ClfDamageWindow.CurrentWindowSize )
		ClfDamageWindow.UpdateDelta = 0
	end
end


function ClfDamageWindow.onUpdate_disable( timepassed )
end


function ClfDamageWindow.setDimension( size )
	local T = ClfDamageWindow
	size = size or T.CurrentWindowSize
	local dim = T.WindowSizes[ size ]
	if ( not dim ) then
		return
	end

	Interface.SaveString( "ClfDamageWindowSize", size )
	T.CurrentWindowSize = size
	local window = T.WindowName

	if ( not DoesWindowExist( window ) ) then
		return
	end

	local showChildsList = {
		default = {
			Background = true,
			List = true,
			Setting = true,
			Close = true,
		},
		middle = {
			Background = true,
			List = true,
			Setting = true,
			Close = true,
		},
		min = {
			Background = false,
			List = false,
			Setting = false,
			Close = false,
		},
	}

	childs = showChildsList[ size ] or showChildsList.default
	for k, v in pairs( childs ) do
		local childWin = window .. k
		WindowSetShowing( childWin, v )
	end

	WindowSetDimensions( window, dim.x, dim.y )
	if ( size ~= "min" ) then
		T.initListWindow( size )
		T.updateList( true, size )
	end
end


function ClfDamageWindow.initListWindow( size )
	if ( size == "min" ) then
		return
	end
	size = size or ClfDamageWindow.CurrentWindowSize

	local parent = "ClfDamageWindowList"
	local template = "ClfDamageListRowTemplate_" .. size

	-- リストのヘッダを作成
	local window = "ClfDamageListRowHeader"
	if ( DoesWindowExist( window ) ) then
		DestroyWindow( window )
	end

	CreateWindowFromTemplateShow( window, template, parent, true )

	DestroyWindow( window .. "Check" )

	local color = { r = 120, g = 160, b = 190, }
	local ls = WindowUtils.FONT_DEFAULT_TEXT_LINESPACING
	local labelNames
	if ( size == "middle" ) then
		labelNames = {
			{ name = "Name",    text = L"Mobiles", font = "Arial_Black_14", lineSpace = ls },
			{ name = "Minutes", text = L"sec",     font = "Arial_Black_14", lineSpace = ls },
			{ name = "Total",   text = L"Total",   font = "Arial_Black_14", lineSpace = ls },
		}
	else
		labelNames = {
			{ name = "Name",    text = L"Mobiles", font = "Arial_Black_14", lineSpace = ls },
			{ name = "Health",  text = L"Health",  font = "Arial_Black_14", lineSpace = ls },
			{ name = "Hit",     text = L"Hit",     font = "Arial_Black_14", lineSpace = ls },
			{ name = "Minutes", text = L"sec",     font = "Arial_Black_14", lineSpace = ls },
			{ name = "Avg",     text = L"DPS",     font = "Arial_Black_14", lineSpace = ls },
			{ name = "Total",   text = L"Total",   font = "Arial_Black_14", lineSpace = ls },
		}
	end

	for i = 1, #labelNames do
		local nameObj = labelNames[ i ]
		local winName = window .. nameObj.name

		LabelSetText( winName, nameObj.text )
		LabelSetFont( winName, nameObj.font, nameObj.lineSpace )
		LabelSetTextColor( winName, color.r, color.g, color.b )

		local point, relativePoint, relativeTo, xOffset, yOffset = WindowGetAnchor( winName, 1 )

		if ( i == 1 ) then
			WindowClearAnchors( winName )
			WindowAddAnchor( winName, point, relativeTo, relativePoint, xOffset, 5 )
		elseif ( yOffset ~= 0 ) then
			WindowClearAnchors( winName )
			WindowAddAnchor( winName, point, relativeTo, relativePoint, xOffset, 0 )
		end
	end

	WindowSetAlpha( window .. "Bg", 0.65 )

	local x, y = WindowGetDimensions( window )
	WindowSetDimensions( window, x, y + 4 )
end


function ClfDamageWindow.clearAllList()
	local ListRowIds = ClfDamageWindow.ListRowIds
	if ( ListRowIds ) then
		local removeListRow = ClfDamageWindow.removeListRow
		for id, _ in pairs( ListRowIds ) do
			removeListRow( id )
		end
	end
end


function ClfDamageWindow.updateList( forceUpdate, size )
	local T = ClfDamageWindow

	if (
			not forceUpdate
			and ( not ClfDamageMod.Enable or not T.ListUpdateEnable )
		) then

		return
	end

	size = size or T.CurrentWindowSize
	if ( "min" == size ) then
		return
	end

	local time = Interface.Clock.Timestamp
	local damages = ClfDamageMod.Damages
	local OldLastUpdate = T.LastUpdate

	if ( not forceUpdate
			and ( not damages or ( OldLastUpdate > ClfDamageMod.LastUpdate and time - OldLastUpdate < 5 ) )
		) then
		-- ダメージが更新されていない場合は、5秒経たなければ表示を更新しない
		return
	end

	local pairs = pairs

	function pairsByTime( t, f )
		local tmp = {}
		for id, damObj in pairs( t ) do
			tmp[ #tmp + 1 ] = { key = id, v = damObj }
		end
		f = f or function( t1, t2 )
			local a = t1.v
			local b = t2.v
			if ( a.sticky or b.sticky ) then
				-- どちらか（もしくは両方）に固定表示の指定がある
				-- sticky: 固定表示を設定した時のタイム or 指定していなければ nil
				local aStick = a.sticky or -1
				local bStick = b.sticky or -1
				-- 後から固定表示を設定した方を前にする
				return ( aStick > bStick )

			elseif ( a.update ~= b.update ) then
				-- ダメージ更新が新しい順にする
				return ( a.update > b.update )
			end
			-- ダメージ更新時間が同じ

			if ( a.totalDamage ~= b.totalDamage ) then
				-- トータルダメージが大きい順にする
				return ( a.totalDamage > b.totalDamage )
			elseif ( a.hit ~= b.hit  ) then
				-- hit数が多い順にする
				return ( a.hit > b.hit )
			end
			-- ダメージ更新時間、totalダメージ、hit数も同じなら、新しい（後にヒットした）順にする
			return ( a.count > b.count )
		end
		table.sort( tmp, f )
		local i = 0
		local iter = function()
			i = i + 1
			local k = tmp[ i ]
			if k == nil then
				return nil
			else
				k = k.key
				return k, t[ k ]
			end
		end
		return iter
	end

	local parentWindow = ClfDamageWindow.WindowName .. "List"
	local colors = T.fontColors
	local visualStatecolors = T.fontColorVisualState
	local fontColorDead = T.fontColorDead
	local fontColorFarAway = T.fontColorFarAway
	local listRowMax = T.LIST_ROW_MAX
	local ListRowIds = T.ListRowIds

	local mathMax = math.max
	local mathMin = math.min
	local mathFloor = math.floor
	local mathCeil = math.ceil
	local towstring = towstring
	local wstringFormat = wstring.format
	local WindowGetId = WindowGetId
	local LabelSetText = LabelSetText
	local WindowSetAlpha = WindowSetAlpha
	local WindowSetId = WindowSetId
	local LabelSetTextColor = LabelSetTextColor
	local WindowClearAnchors = WindowClearAnchors
	local WindowAddAnchor = WindowAddAnchor
	local GetMobileData = Interface.GetMobileData
	local GetDistanceFromPlayer = GetDistanceFromPlayer
	local FitTextToLabel = WindowUtils.FitTextToLabel
	local HealthBarColor = WindowData.HealthBarColor
	local createListRow = T.createListRow
	local removeListRow = T.removeListRow

	local listRowFunc

	if ( "middle" == size ) then
		listRowFunc = function( id, damObj, i )
			local window = "ClfDamageListRow" .. id
			local mobileData = GetMobileData( id, false )
			local odd = i % 2
			local color = colors[ odd + 1 ]
			local disColor = color
			local isDead = false
			local isUnknown = false
			local isFarAway = false
			local visualStateId = HealthBarColor[ id ] and HealthBarColor[ id ].VisualStateId or 0
			visualStateId = visualStateId + 1

			if ( mobileData ) then
				isDead = mobileData.IsDead
				if ( isDead ~= damObj.isDead ) then
					ClfDamageMod.addDamageData( id, { isDead = isDead } )
				end
				if ( not isDead ) then
					local dist = GetDistanceFromPlayer( id )
					if ( not dist or dist < 0 ) then
						isFarAway = true
					end
				end
			else
				isUnknown = true
				isDead = damObj.isDead
			end

			local creating = false
			if ( not ListRowIds[ id ] ) then
				-- 該当idの行が無い
				createListRow( id, true, size )
				creating = true

				LabelSetText( window .. "Name", damObj.name )
				FitTextToLabel( window .."Name", damObj.name )
				LabelSetText( window .. "Count", towstring( damObj.count ) )

				local checkBtn = window .. "Check"
				WindowSetId( checkBtn, id )
				if ( damObj.sticky ) then
					ButtonSetStayDownFlag( checkBtn, true )
					ButtonSetPressedFlag( checkBtn, true )
				end
			end

			WindowSetAlpha( window .. "Bg", ( 1 - odd ) * 0.3 )
			local sec = mathMin( ClfDamageMod.DAY_IN_SECONDS, mathMax( 1, damObj.update - damObj.start ) )
			local total = damObj.totalDamage

			if ( creating or damObj.update >= OldLastUpdate ) then
				-- 初回、もしくは前回の描画以降にダメージが更新された
				if ( isUnknown ) then
					disColor = fontColorDead
				elseif ( isDead ) then
					disColor = fontColorDead
				else
					if ( isFarAway ) then
						disColor = fontColorFarAway
					elseif ( visualStatecolors[ visualStateId ] ) then
						disColor = visualStatecolors[ visualStateId ]
					end
				end

				if ( damObj.isUnknown and damObj.name and damObj.name ~= L"???" ) then
					ClfDamageMod.addDamageData( id, { isUnknown = false } )
					LabelSetText( window .. "Name", damObj.name )
					FitTextToLabel( window .."Name", damObj.name )
				end

				LabelSetText( window .. "Minutes", wstringFormat( L"%d:%02d", mathFloor( sec / 60 ) , mathFloor( sec % 60 * 100 ) / 100 ) )
				LabelSetText( window .. "Total", towstring( total ) )
			elseif ( OldLastUpdate - damObj.update >= 4 ) then
				-- 前回更新から4秒以上なら、再描画
				if ( isUnknown ) then
					disColor = fontColorDead
				elseif ( isDead ) then
					disColor = fontColorDead
				else
					LabelSetText( window .. "Minutes", wstringFormat( L"%d:%02d", mathFloor( sec / 60 ) , mathFloor( sec % 60 * 100 ) / 100 ) )
					if ( isFarAway ) then
						disColor = fontColorFarAway
					elseif ( visualStatecolors[ visualStateId ] ) then
						disColor = visualStatecolors[ visualStateId ]
					end
				end
			elseif ( isDead or isUnknown or isFarAway ) then
				disColor = fontColorDead
			elseif ( visualStatecolors[ visualStateId ] ) then
				disColor = visualStatecolors[ visualStateId ]
			end

			LabelSetTextColor( window .. "Count",   disColor.r, disColor.g, disColor.b )
			LabelSetTextColor( window .. "Name",    color.r, color.g, color.b )
			LabelSetTextColor( window .. "Minutes", color.r, color.g, color.b )
			LabelSetTextColor( window .. "Total",   color.r, color.g, color.b )

			WindowClearAnchors( window )
			local y = 29 * ( i - 1) + 33
			WindowAddAnchor( window, "topleft", parentWindow, "topleft", 0, y )

		end
	else
		listRowFunc = function( id, damObj, i )
			local window = "ClfDamageListRow" .. id
			local mobileData = GetMobileData( id, false )
			local odd = i % 2
			local color = colors[ odd + 1 ]
			local disColor = color
			local curHealth
			local maxHealth
			local isDead = false
			local isUnknown = false
			local isFarAway = false
			local visualStateId = HealthBarColor[ id ] and HealthBarColor[ id ].VisualStateId or 0
			visualStateId = visualStateId + 1

			if ( mobileData ) then
				curHealth = mobileData.CurrentHealth
				maxHealth = mobileData.MaxHealth
				isDead = mobileData.IsDead
				if ( isDead ~= damObj.isDead ) then
					ClfDamageMod.addDamageData( id, { isDead = isDead } )
				end
				if ( not isDead ) then
					local dist = GetDistanceFromPlayer( id )
					if ( not dist or dist < 0 ) then
						isFarAway = true
					end
				end
			else
				isUnknown = true
				curHealth = damObj.CurrentHealth or 25
				maxHealth = damObj.MaxHealth or 25
				isDead = damObj.isDead
			end

			if ( maxHealth == 0 ) then
				maxHealth = huge
			end

			local creating = false
			if ( not ListRowIds[ id ] ) then
				-- 該当idの行が無い
				createListRow( id, true, size )
				creating = true

				LabelSetText( window .. "Name", damObj.name )
				FitTextToLabel( window .."Name", damObj.name )
				LabelSetText( window .. "Count", towstring( damObj.count ) )

				local checkBtn = window .. "Check"
				WindowSetId( checkBtn, id )
				if ( damObj.sticky ) then
					ButtonSetStayDownFlag( checkBtn, true )
					ButtonSetPressedFlag( checkBtn, true )
				end
			end

			WindowSetAlpha( window .. "Bg", ( 1 - odd ) * 0.3 )

			local sec = mathMin( ClfDamageMod.DAY_IN_SECONDS, mathMax( 1, damObj.update - damObj.start ) )
			local total = damObj.totalDamage

			if ( creating or damObj.update >= OldLastUpdate ) then
				-- 初回、もしくは前回の描画以降にダメージが更新された
				local health
				local dps = total / sec
				if ( isUnknown ) then
					health = L"---"
					disColor = fontColorDead
				elseif ( isDead ) then
					health = L"0%"
					disColor = fontColorDead
				else
					local perc = 0
					if ( maxHealth and maxHealth > 0 ) then
						perc = mathMin( 1,  curHealth / maxHealth )
					end
					health = towstring( mathCeil( 100 * perc ) ) .. L"%"
					if ( isFarAway ) then
						disColor = fontColorFarAway
					elseif ( visualStatecolors[ visualStateId ] ) then
						disColor = visualStatecolors[ visualStateId ]
					end
				end

				if ( damObj.isUnknown and damObj.name and damObj.name ~= L"???" ) then
					ClfDamageMod.addDamageData( id, { isUnknown = false } )
					LabelSetText( window .. "Name", damObj.name )
					FitTextToLabel( window .."Name", damObj.name )
				end

				LabelSetText( window .. "Health", health)
				LabelSetText( window .. "Hit", towstring( damObj.hit ) )
				LabelSetText( window .. "Minutes", wstringFormat( L"%d:%02d", mathFloor( sec / 60 ) , mathFloor( sec % 60 * 100 ) / 100 ) )
				LabelSetText( window .. "Avg", wstringFormat( L"%.2f", dps ))
				LabelSetText( window .. "Total", towstring( total ) )
			elseif ( OldLastUpdate - damObj.update >= 4 ) then
				-- 前回更新から4秒以上なら、再描画
				if ( isUnknown ) then
					LabelSetText( window .. "Health", L"---" )
					disColor = fontColorDead
				elseif ( isDead ) then
					LabelSetText( window .. "Health", L"0%" )
					disColor = fontColorDead
				else
					local health = towstring( mathCeil( 100 * curHealth / maxHealth ) ) .. L"%"
					LabelSetText( window .. "Health", towstring( health ) )
					LabelSetText( window .. "Minutes", wstringFormat( L"%d:%02d", mathFloor( sec / 60 ) , mathFloor( sec % 60 * 100 ) / 100 ) )
					if ( isFarAway ) then
						disColor = fontColorFarAway
					elseif ( visualStatecolors[ visualStateId ] ) then
						disColor = visualStatecolors[ visualStateId ]
					end
				end
			elseif ( isDead or isUnknown ) then
				disColor = fontColorDead
			elseif ( isFarAway ) then
				disColor = fontColorFarAway
			elseif ( visualStatecolors[ visualStateId ] ) then
				disColor = visualStatecolors[ visualStateId ]
			end

			LabelSetTextColor( window .. "Count",   disColor.r, disColor.g, disColor.b )
			LabelSetTextColor( window .. "Name",    color.r, color.g, color.b )
			LabelSetTextColor( window .. "Health",  disColor.r, disColor.g, disColor.b )
			LabelSetTextColor( window .. "Hit",     color.r, color.g, color.b )
			LabelSetTextColor( window .. "Minutes", color.r, color.g, color.b )
			LabelSetTextColor( window .. "Avg",     color.r, color.g, color.b )
			LabelSetTextColor( window .. "Total",   color.r, color.g, color.b )

			WindowClearAnchors( window )
			local y = 29 * ( i - 1) + 33
			WindowAddAnchor( window, "topleft", parentWindow, "topleft", 0, y )
		end
	end

	T.LastUpdate = time

	local i = 0
	for id, damObj in pairsByTime( damages ) do
		if ( damObj.isPet or damObj.isPlayer ) then
			removeListRow( id )
			continue
		end
		if ( i < listRowMax ) then
			i = i + 1
			listRowFunc( id, damObj, i )
		else
			-- 表示列以降
			removeListRow( id )
		end
	end
end


-- mobileIDからリスト行のwindowを作る
function ClfDamageWindow.createListRow( id, show, size )
	local window = "ClfDamageListRow" .. id

	size = size or "default"

	ClfDamageWindow.ListRowIds[ id ] = true
	CreateWindowFromTemplateShow(
		window,
		"ClfDamageListRowTemplate_" .. size,
		ClfDamageWindow.WindowName .. "List",
		show
	)
	WindowSetId( window, id )
end

-- mobileIDを指定してリスト行のwindowを取り除く
function ClfDamageWindow.removeListRow( id )
	local win = "ClfDamageListRow" .. id
	ClfDamageWindow.ListRowIds[ id ] = nil
	if ( DoesWindowExist( win ) ) then
		DestroyWindow( "ClfDamageListRow" .. id )
	end
end


function ClfDamageWindow.shutdown()
	WindowUtils.SaveWindowPosition( ClfDamageWindow.WindowName )
end


function ClfDamageWindow.show()
	ClfDamageWindow.setDimension( "default" )
end


function ClfDamageWindow.hide()
	ClfDamageWindow.setDimension( "min" )
end

function ClfDamageWindow.showSettings()
	local setting = ClfDamageWindow.WindowName .. "Setting"
	local settingMenu = setting .. "Menu"
	local btnUp = setting .. "Up"
	local btnDown = setting .. "Down"
	local size = ClfDamageWindow.WindowSizes[ ClfDamageWindow.CurrentWindowSize ]

	WindowSetShowing( settingMenu, true )
	WindowSetShowing( btnUp, true )
	WindowSetShowing( btnDown, false )

	WindowSetDimensions( setting, size.x, size.y )
end

function ClfDamageWindow.hideSettings()
	local setting = ClfDamageWindow.WindowName .. "Setting"
	local settingMenu = setting .. "Menu"
	local btnUp = setting .. "Up"
	local btnDown = setting .. "Down"

	WindowSetShowing( settingMenu, false )
	WindowSetShowing( btnUp, false )
	WindowSetShowing( btnDown, true )

	WindowSetDimensions( setting, 30, 30 )
end


function ClfDamageWindow.onMobileNameBtn()
	local parent = WindowGetParent(SystemData.ActiveWindow.name)
	local mobileId = WindowGetId( parent )

	if ( mobileId and mobileId > 0 ) then
		HandleSingleLeftClkTarget(mobileId)
	end
end

function ClfDamageWindow.onMobileNameBtnOver()
	local parent = WindowGetParent( SystemData.ActiveWindow.name )
	local mobileId = WindowGetId( parent )

	if( mobileId and mobileId > 0 and not MobileHealthBar.windowDisabled[ mobileId ] and MobileHealthBar.hasWindow[ mobileId ] ) then
		MobileHealthBar.mouseOverId = mobileId
		local itemData = {
			windowName = SystemData.ActiveWindow.name,
			itemId = mobileId,
			itemType = WindowData.ItemProperties.TYPE_ITEM,
		}
		ItemProperties.SetActiveItem( itemData )
	end
end

function ClfDamageWindow.onMobileNameBtnOverEnd()
	ItemProperties.ClearMouseOverItem()
	MobileHealthBar.mouseOverId = 0
	if ( DoesWindowNameExist("MobileArrow") ) then
		DestroyWindow("MobileArrow")
	end
end

function ClfDamageWindow.onMobileCheckBtn()
	local btn = SystemData.ActiveWindow.name
	local enable = not ButtonGetPressedFlag( btn )
	local mobileId = WindowGetId( btn )

	ButtonSetStayDownFlag( btn, enable )
	ButtonSetPressedFlag( btn, enable )

	ClfDamageMod.setSticky( mobileId, enable )

	if ( enable ) then
		ClfDamageWindow.updateList( true, nil )
	end
end

function ClfDamageWindow.closeWindow()
	if ( ClfDamageMod.windowShow ) then
		ClfDamageMod.toggleWindow()
	end
end

