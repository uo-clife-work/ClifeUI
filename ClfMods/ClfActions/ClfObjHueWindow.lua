

ClfObjHueWindow = {}

ClfObjHueWindow.TypeColors = {
	-- cu sidhe
	[10000277] = {
		[1447] = L"Copper (cu sidhe)",
		[2218] = L"Brown (cu sidhe)",
		[2424] = L"Dull (cu sidhe)",
		[2305] = L"Gray (cu sidhe)",
		[2220] = L"Sky Blue (cu sidhe)",	-- Spined leather
		[2426] = L"Agapite (cu sidhe)",	-- Rose (metal pigment)
		[1319] = L"Echo Blue (cu sidhe)",
		[1201] = L"Rose Pink (cu sidhe)",
		[1109] = L"Jet Black (cu sidhe)",	-- Shadow Dancer Black (Neon Pigment)
		[1652] = L"Wine Red (cu sidhe)",	-- Red (plant pigment)
		[1153] = L"Pure White (cu sidhe)",	-- Pure White (AOS Cloth)
		[1154] = L"Ice Blue (cu sidhe)",	-- Ice Blue (Cloth Lv5, plant pigment)
		-- and Valorite, Fire
	},
}


ClfObjHueWindow.WindowName = "ClfObjHueWin"

ClfObjHueWindow.CurrentData = nil;

function ClfObjHueWindow.onUpdateTarget()
	ClfObjHueWindow.showData( WindowData.CurrentTarget.TargetId )
end


function ClfObjHueWindow.showData( targetId )
	if ( not targetId or targetId == 0 ) then
		return
	end

	local data = WindowData.ObjectInfo[ targetId ]
	local regist = false
	if ( not data ) then
		RegisterWindowData( WindowData.ObjectInfo.Type, targetId )
		data = WindowData.ObjectInfo[ targetId ]
		regist = true
	end

	if ( data ) then
		local win = ClfObjHueWindow.WindowName
		local LabelSetText = LabelSetText
		local WindowSetShowing = WindowSetShowing

		WindowSetShowing( win, false )

		local name = data.name
		if ( type( name ) == "wstring" and name ~= L"" ) then
			name = towstring( wstring.trim( name ) )
		else
			name = L"(no name)"
		end
		LabelSetText( win .. "Name", name )

		local dataStr = "ID: " .. targetId .. "\nType: " .. data.objectType
		LabelSetText( win .. "Data", towstring( dataStr ) )

		local hueId = data.hueId
		local hue = data.hue
		local rgbSV = ClfUtil.rgbSV( hue )

		ClfObjHueWindow.CurrentData = {
			id = targetId,
			objectType = data.objectType,
			hueId = hueId,
			hue = hue,
		}

		local hueIdStr = string.format( "#%04x", hueId ) .. " (" .. hueId .. ")"
		LabelSetText( win .. "HueName", towstring( hueIdStr ) )
		LabelSetTextColor( win .. "HueName", hue.r, hue.g, hue.b )

		local bgHue
		if ( rgbSV.v < 65 or ( rgbSV.s < 0.2 and rgbSV.v < 95 ) ) then
			bgHue = 200
		else
			bgHue = 0
		end
		WindowSetTintColor( win .. "HueBG", bgHue, bgHue, bgHue )
		DynamicImageSetCustomShader(  win .. "HueImage", "UOSpriteUIShader", { hueId, 7939 } )

		WindowSetShowing( win, true )
	end

	if ( regist ) then
		UnregisterWindowData( WindowData.ObjectInfo.Type, targetId )
	end
end


function ClfObjHueWindow.clear()
	local win = ClfObjHueWindow.WindowName
	if ( DoesWindowExist( win ) ) then
		LabelSetText( win .. "Name", L"(Hue Window)" )
		LabelSetText( win .. "Data", L"" )
		DynamicImageSetCustomShader(  win .. "HueImage", "UOSpriteUIShader", { 0, 7939 } )
		WindowSetTintColor( win .. "HueBG", 0, 0, 0 )
	end
end

function ClfObjHueWindow.onInitialize()
	ClfObjHueWindow.clear()
	WindowRegisterEventHandler( ClfObjHueWindow.WindowName, WindowData.CurrentTarget.Event, "ClfObjHueWindow.onUpdateTarget" )
end

function ClfObjHueWindow.onShutdown()
	WindowUtils.SaveWindowPosition( ClfObjHueWindow.WindowName )
end

function ClfObjHueWindow.onDblClick()
	RequestTargetInfo()
	WindowRegisterEventHandler( "Root", SystemData.Events.TARGET_SEND_ID_CLIENT, "ClfObjHueWindow.onDblClickTargetReceived" )
end

function ClfObjHueWindow.onDblClickTargetReceived()
	local targetId = SystemData.RequestInfo.ObjectId
	WindowUnregisterEventHandler( "Root", SystemData.Events.TARGET_SEND_ID_CLIENT )
	if ( targetId and targetId > 0 ) then
		ClfObjHueWindow.showData( targetId )
	end
end


function ClfObjHueWindow.onHueBtnOver()
	local current = ClfObjHueWindow.CurrentData or {}
	local rgb = current.hue
	if ( not rgb ) then
		return
	end

	local rgbStr = towstring( "R:" .. rgb.r .. ", G:" .. rgb.g .. ", B:" .. rgb.b .. "\n" )
	local hueName

	local HueId = current.hueId
	if ( HueId ) then
		if ( HueId == 0 ) then
			hueName = L"Plane (Default)"
		else
			hueName = L"(unknown)"
			local objType = current.objectType
			local typeColors = objType and ClfObjHueWindow.TypeColors[ objType ] or {}
			local huesInfoDataName = HuesInfo.Data[ HueId ]

			if ( typeColors[ HueId ] ) then
				hueName = typeColors[ HueId ]
				if ( huesInfoDataName ) then
					hueName = hueName .. L", " .. huesInfoDataName
				end
			elseif ( huesInfoDataName ) then
				hueName = huesInfoDataName
			end
		end
	end

	local hueStr
	if ( hueName ) then
		hueStr = hueName .. L"\n\n" .. rgbStr
	else
		hueStr = rgbStr
	end

	local Tooltips = Tooltips
	Tooltips.CreateTextOnlyTooltip( SystemData.ActiveWindow.name, hueStr )
	Tooltips.SetTooltipFont( 1, 1, "MgenPlus_14", 18 )
	Tooltips.SetTooltipAlpha( 0.95 )
	Tooltips.Finalize()
	Tooltips.AnchorTooltip( Tooltips.ANCHOR_WINDOW_TOP )
end


