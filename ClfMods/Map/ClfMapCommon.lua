

ClfMapCommon = {}


ClfMapCommon.DisableWaypoints = false
ClfMapCommon.DisablePlayerName = false
ClfMapCommon.DrawPlayer_org = nil
ClfMapCommon.CreatePartyWP_org = nil

ClfMapCommon.ATLAS_VisibleFunc_org = nil

-- Waypointフィルター時でも表示するWaypointのタイプ
local AlwaysVisibleTypes = {
	[1]  = true,	-- 1 corpse
	[2]  = true,	-- 2 party
	[4]  = true,	-- 4 quest giver
	[5]  = true,	-- 5 new player quest
	[6]  = true,	-- 6 wandering healer
	[12] = false,	-- 12 moongate
	[15] = false,	-- 15 custom
}


function ClfMapCommon.initialize()
	local ClfMapCommon = ClfMapCommon
	local MapCommon = MapCommon
	local I_LoadBoolean = Interface.LoadBoolean

	ClfMapCommon.DisablePlayerName = I_LoadBoolean( "ClfDisablePlayerName", ClfMapCommon.DisablePlayerName )
	ClfMapCommon.DisableWaypoints = I_LoadBoolean( "ClfDisableWaypoints", ClfMapCommon.DisableWaypoints )
	ClfMapCommon.initAlwaysVisibleTypes()
	ClfMapCommon.setPlayerWayptLabel()

	if ( not ClfMapCommon.DrawPlayer_org ) then
		ClfMapCommon.DrawPlayer_org = MapCommon.DrawPlayer
		MapCommon.DrawPlayer = ClfMapCommon.onDrawPlayer
	end

	if ( not ClfMapCommon.ATLAS_VisibleFunc_org ) then
		ClfMapCommon.ATLAS_VisibleFunc_org = MapCommon.WaypointViewInfo.ATLAS.VisibleFunc
		MapCommon.WaypointViewInfo.ATLAS.VisibleFunc = ClfMapCommon.atlasVisibleFunc
	end

	if ( not ClfMapCommon.CreatePartyWP_org ) then
		ClfMapCommon.CreatePartyWP_org = CreatePartyWP
		CreatePartyWP = ClfMapCommon.createPartyWP
	end

	ClfMapCommon.initMapWpFilterBtn()
end


function ClfMapCommon.initAlwaysVisibleTypes()
	local hash = Interface.LoadString( "ClfAlwaysVisibleTypeHash", "" )
	if ( hash ~= "" ) then
		local explode = ClfUtil.explode
		local hashes = explode( ",", hash, false )
		for i = 1, #hashes do
			local setting = explode( ":", hashes[ i ], false, true )
			if ( #setting == 2 ) then
				local key = setting[1]
				if ( AlwaysVisibleTypes[ key ] ~= nil ) then
					AlwaysVisibleTypes[ key ] = ( setting[2] == 1 )
				end
			end
		end
	end
end


function ClfMapCommon.saveAlwaysVisibleTypes()
	local hashes = {}
	for idx, enabled in pairs( AlwaysVisibleTypes ) do
		hashes[ #hashes + 1 ] = idx .. ":" .. ( enabled and "1" or "0" )
	end
	local hash = table.concat( hashes, "," )
	Interface.SaveString( "ClfAlwaysVisibleTypeHash", hash )
end


function ClfMapCommon.initMapWpFilterBtn()
	local mapWin = "MapWindow"
	if ( DoesWindowExist( mapWin ) ) then
		local newWin = mapWin .. "ClfMaWpFilter"
		if ( not DoesWindowExist( newWin ) ) then
			CreateWindowFromTemplate( newWin, "ClfMapWindowWpFilter", mapWin )
			WindowAddAnchor( newWin, "bottomright", "Map", "bottomright", 0, 10 )
		end
		LabelSetText( newWin .. "Label", L"Waypoint Filter" )
		local btn = newWin .. "Check"
		ButtonSetCheckButtonFlag( btn, true )
		ButtonSetPressedFlag( btn, ClfMapCommon.DisableWaypoints )
	end
end


function ClfMapCommon.atlasVisibleFunc( wtype, wx, wy )
	if (
			ClfMapCommon.DisableWaypoints
			and wtype ~= MapCommon.WaypointPlayerType
			and AlwaysVisibleTypes[ wtype ] ~= true
		) then
		return false
	end

	return ClfMapCommon.ATLAS_VisibleFunc_org( wtype, wx, wy )
end


function ClfMapCommon.setPlayerWayptLabel()
	if ( not MapCommon or not MapCommon.ActiveView ) then
		return
	end

	local windowName = "Waypoint" .. MapCommon.WaypointPlayerId .. MapCommon.ActiveView
	local label = windowName .. "Text"
	if ( DoesWindowExist( label ) ) then
		WindowSetShowing( label, not ClfMapCommon.DisablePlayerName )
	end
end


function ClfMapCommon.onDrawPlayer( displayMode, visibleFunc, parentWindow )
	local physicalFacet = UOGetPhysicalRadarFacet()

	local MapCommon = MapCommon
	local WindowData = WindowData
	local WD_PlayerLocation = WindowData.PlayerLocation
	local MC_WaypointPlayerId = MapCommon.WaypointPlayerId
	local MC_WaypointPlayerType = MapCommon.WaypointPlayerType
	local wpViewInfo = MapCommon.WaypointViewInfo[ displayMode ]

	local windowName = "Waypoint".. MC_WaypointPlayerId .. displayMode
	local isWindowExist = DoesWindowExist( windowName )
	local playerVisible = ( WD_PlayerLocation.facet == physicalFacet ) and visibleFunc( MC_WaypointPlayerType, WD_PlayerLocation.x, WD_PlayerLocation.y )


	if ( playerVisible ~= wpViewInfo.PlayerVisible ) then
		if ( isWindowExist ) then
			WindowSetShowing( windowName, playerVisible )
		end
		wpViewInfo.PlayerVisible = playerVisible
	end

	if ( playerVisible ) then
		if ( isWindowExist ~= true ) then
			CreateWindowFromTemplate( windowName, "WaypointIconTemplate", parentWindow )
			local label = windowName .. "Text"
			CreateWindowFromTemplate( label, "WPText", windowName )
			WindowAddAnchor( label, "top", windowName, "bottom", 0, -5 )
			LabelSetText( label, GetStringFromTid(1154864) )
			WindowSetShowing( label, not ClfMapCommon.DisablePlayerName )
			WindowSetId( windowName, MC_WaypointPlayerId )
		end

		local playerX, playerY = UOGetWorldPosToRadar( WD_PlayerLocation.x, WD_PlayerLocation.y )
		WindowClearAnchors( windowName )
		WindowAddAnchor( windowName, "topleft", parentWindow, "center", playerX, playerY )
		local iconId = WindowData.WaypointDisplay.displayTypes[ displayMode ][ MC_WaypointPlayerType ].iconId
		MapCommon.UpdateWaypointIcon( iconId, windowName, displayMode )
	end
end


function ClfMapCommon.createPartyWP( windowName, wname )
	local name = wstring.gsub( wname, L"\"", L"" )
	local nameLabel = windowName .. "Text"

	local CreateWindowFromTemplate = CreateWindowFromTemplate

	CreateWindowFromTemplate( nameLabel, "WPText", windowName )
	WindowAddAnchor( nameLabel, "top", windowName, "bottom", 0, -10 )
	LabelSetText( nameLabel, name )

	local wstring = wstring
	local wstring_len = wstring.len
	local wstring_lower = wstring.lower
	local wstring_gsub = wstring.gsub

	local nameLwr = wstring_lower( name )
	local pData
	local pid = 0

	for mobileId, data in pairs( PartyHealthBar.PartyMembers ) do
		local pname = data.name
		pname = pname and wstring_gsub( wstring_lower( pname ), L"^%s*", L"" )
		pname = pname and wstring_gsub( towstring( pname ), L"%s*$", L"" )

		if ( pname and wstring_len( pname ) > 3 ) then
			if ( pname == nameLwr or wstring.find( pname, nameLwr, 1, true ) ) then
				pid = mobileId
				pData = data
				break
			end
		end
	end

	if ( pData ) then
		local curHealth = pData.CurrentHealth
		local maxHealth = pData.MaxHealth
		local hpbWin = windowName .. "HealthBar"

		if ( maxHealth > 0 ) then
			if ( not DoesWindowExist( hpbWin ) ) then
				CreateWindowFromTemplate( hpbWin, "WPHealthBar", windowName )
				WindowAddAnchor( hpbWin, "bottom", nameLabel, "top", 0, 5 )
				WindowSetScale( hpbWin, 0.4)
				WindowSetTintColor( hpbWin, 255, 0, 0)
			else
				WindowSetShowing( hpbWin, true )
			end
			StatusBarSetMaximumValue( hpbWin, maxHealth )
			StatusBarSetCurrentValue( hpbWin, curHealth )
		elseif ( DoesWindowExist( hpbWin ) ) then
			WindowSetShowing( hpbWin, false )
		end
	end
end


function ClfMapCommon.wpFilterOnLbtnUp()
	local enable = ButtonGetPressedFlag( SystemData.ActiveWindow.name )
	ClfMapCommon.DisableWaypoints = enable
	Interface.SaveBoolean( "ClfDisableWaypoints", ClfMapCommon.DisableWaypoints )

	MapCommon.ForcedUpdate = true
	MapWindow.UpdateWaypoints()
end


function ClfMapCommon.wpFilterLabelOnLbtnUp()
	local filterWin = "ClfWpFiltersWindow"
	if ( not DoesWindowExist( filterWin ) ) then
		CreateWindow( filterWin, false )
		WindowUtils.RestoreWindowPosition( filterWin )
	else
		WindowSetShowing( filterWin, true )
	end
end


function ClfMapCommon.initFilterWin()
	local win = SystemData.ActiveWindow.name
	Interface.DestroyWindowOnClose[ win ] = true

	LabelSetText( win .. "Chrome_UO_TitleBar_WindowTitle", L"Waypoint Filter" )
	ButtonSetText( win .. "AcceptButton", GetStringFromTid( 3000093 ) )
	ClfMapCommon.initFilterListWin( win )
end



local FilterLabels = {
	{
		label = L"Hide Player label",
		hidePlayerLabel = true,
	},
	{
		label = L"Corpse",
		visibleType = 1,
	},
	{
		label = L"Party member",
		visibleType = 2,
	},
	{
		label = L"Quest giver",
		visibleType = 4,
	},
	{
		label = L"New player quest",
		visibleType = 5,
	},
	{
		label = L"Healer",
		visibleType = 6,
	},
	{
		label = L"Moongate",
		visibleType = 12,
	},
	{
		label = L"Custom",
		visibleType = 15,
	},
}


-- フィルター項目の作成
function ClfMapCommon.initFilterListWin( win )
--	local win = "ClfYouSeeFiltersWindow"
	local btnWrap = win .."List"
	if ( not DoesWindowExist( btnWrap ) ) then
		return
	end

	local AlwaysVisibleTypes = AlwaysVisibleTypes

	local DoesWindowExist = DoesWindowExist
	local CreateWindowFromTemplate = CreateWindowFromTemplate
	local WindowClearAnchors = WindowClearAnchors
	local WindowAddAnchor = WindowAddAnchor
	local ButtonSetPressedFlag = ButtonSetPressedFlag
	local LabelSetText = LabelSetText

	local filterLen = #FilterLabels
	for i = 1, filterLen do
		local obj = FilterLabels[ i ]
		local idx = obj.visibleType or 1000 + i
		local btn = btnWrap .. "Btn_" .. idx
		if ( not DoesWindowExist( btn ) ) then
			CreateWindowFromTemplate( btn, "ClfWpFiltersWindowRowTemplate", btnWrap )
			WindowSetId( btn, idx )
		else
			WindowClearAnchors( btn )
		end
		WindowAddAnchor( btn, "topleft", btnWrap, "topleft", 0, i * 30 - 30 )

		local checkBox = btn .. "CheckBox"
		local flag
		if ( obj.hidePlayerLabel ) then
			flag = ClfMapCommon.DisablePlayerName
		else
			flag = AlwaysVisibleTypes[ idx ]
		end
		ButtonSetPressedFlag( checkBox, flag )

		local label = btn .. "FilterName"
		LabelSetText( label, obj.label )
	end

	local x, y = WindowGetDimensions( win )
	WindowSetDimensions( win, x, 30 * filterLen + 100 )
	WindowSetShowing( win, true )
end


function ClfMapCommon.onAcceptBtnLup()
	local win = WindowGetParent( SystemData.ActiveWindow.name )
	local btnWrap = win .."List"
	for i = 1, #FilterLabels do
		local obj = FilterLabels[ i ]
		local idx = obj.visibleType or 1000 + i
		local btn = btnWrap .. "Btn_" .. idx
		local checkBox = btn .. "CheckBox"
		if ( DoesWindowExist( checkBox ) ) then
			local enable = ButtonGetPressedFlag( checkBox )
			if ( obj.hidePlayerLabel ) then
				ClfMapCommon.DisablePlayerName = enable
				ClfMapCommon.setPlayerWayptLabel()
				Interface.SaveBoolean( "ClfDisablePlayerName", enable )
			else
				AlwaysVisibleTypes[ idx ] = enable
			end
		end
	end

	ClfMapCommon.saveAlwaysVisibleTypes()
	DestroyWindow( win )
	MapCommon.ForcedUpdate = true
	MapWindow.UpdateWaypoints()
end


function ClfMapCommon.shutdownFilterWin()
	local win = WindowUtils.GetActiveDialog()
	WindowUtils.SaveWindowPosition( win )
end


function ClfMapCommon.onToggleWpFilter()
	local btn = SystemData.ActiveWindow.name
	local checkBox = btn .. "CheckBox"
	local enable = not ButtonGetPressedFlag( checkBox )
	ButtonSetPressedFlag( checkBox, enable )
end




