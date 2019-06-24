

ClfCourseMap = {}


ClfCourseMap.EnableArrowX = false

ClfCourseMap.mapWindowInitialize_org = nil
ClfCourseMap.mapWindowShutdown_org = nil
ClfCourseMap.mapWindowUpdateState_org = nil
ClfCourseMap.mapWindowUpdatePoints_org = nil

ClfCourseMap.mapWindowMap_OnLButtonUp_org = nil
ClfCourseMap.mapWindowMap_OnLButtonDown_org = nil
ClfCourseMap.mapWindowPlotToggle_OnLButtonUp_org = nil
ClfCourseMap.mapWindowMapPoint_OnLButtonDown_org = nil

local MapScales = {}
local DisabledZoomMaps = {}

local CONST = {
	ZOOM_SCALES = {
		DEFAULT     = 1,
		ZOOM_IN     = 3.375,
		MIN         = 1,
		MAX         = 6,
		BTN_STEP    = 0.5,
		WHEEL_STEP  = 0.25,
		MIN_STEP    = 0.125,
	},
	WSTRINGS = {
		ZoomIn    = GetStringFromTid( 1079288 ),	-- ズームイン
		Reset     = GetStringFromTid( 1079290 ),	-- ズーム倍率リセット
		Completed = GetStringFromTid( 503014  ),	-- この財宝探しは完了しています。
	},
	FACET_TIDS = {
		[1041502] = true,	-- ファセット : フェルッカ
		[1041503] = true,	-- ファセット : トランメル
		[1060850] = true,	-- ファセット : イルシェナー
		[1060851] = true,	-- ファセット : マラス
		[1115645] = true,	-- ファセット : 徳之諸島
		[1115646] = true,	-- ファセット : テルマー
	},
	TID_COMPLETED = 1041507,	-- 発掘者 : ~1_val~
	MAP_TIDS = {
		-- Pub.105 以降の地図名称 tid
		[1158975] = 1,	-- ~1_TYPE~のへそくりのぼろぼろの宝の地図 (レベル1)
		[1158976] = 2,	-- ~1_TYPE~の配給品のぼろぼろの宝の地図 (レベル2)
		[1158977] = 3,	-- ~1_TYPE~の貯蔵品のぼろぼろの宝の地図 (レベル3)
		[1158978] = 4,	-- ~1_TYPE~の秘蔵品のぼろぼろの宝の地図 (レベル4)
		[1158979] = 5,	-- ~1_TYPE~の埋蔵品のぼろぼろの宝の地図 (レベル5)
		[1158980] = 1,	-- ~1_TYPE~のへそくりの宝の地図 (レベル1)
		[1158981] = 2,	-- ~1_TYPE~の配給品の宝の地図 (レベル2)
		[1158982] = 3,	-- ~1_TYPE~の貯蔵品の宝の地図 (レベル3)
		[1158983] = 4,	-- ~1_TYPE~の秘蔵品の宝の地図 (レベル4)
		[1158984] = 5,	-- ~1_TYPE~の埋蔵品の宝の地図 (レベル5)
	},
}


function ClfCourseMap.initialize()
	local ClfCourseMap = ClfCourseMap

	ClfCourseMap.EnableArrowX = Interface.LoadBoolean( "ClfMapArrowX", ClfCourseMap.EnableArrowX )

	if ( not ClfCourseMap.mapWindowInitialize_org ) then
		ClfCourseMap.mapWindowInitialize_org = CourseMapWindow.Initialize
		CourseMapWindow.Initialize = ClfCourseMap.onMapWindowInitialize
	end
	if ( not ClfCourseMap.mapWindowShutdown_org ) then
		ClfCourseMap.mapWindowShutdown_org = CourseMapWindow.Shutdown
		CourseMapWindow.Shutdown = ClfCourseMap.onMapWindowShutdown
	end
	if ( not ClfCourseMap.mapWindowUpdateState_org ) then
		ClfCourseMap.mapWindowUpdateState_org = CourseMapWindow.UpdateState
		CourseMapWindow.UpdateState = ClfCourseMap.onMapUpdateState
	end
	if ( not ClfCourseMap.mapWindowUpdatePoints_org ) then
		ClfCourseMap.mapWindowUpdatePoints_org = CourseMapWindow.UpdatePoints
		CourseMapWindow.UpdatePoints = ClfCourseMap.onUpdatePoints
	end

	if ( not ClfCourseMap.mapWindowMap_OnLButtonUp_org ) then
		ClfCourseMap.mapWindowMap_OnLButtonUp_org = CourseMapWindow.Map_OnLButtonUp
		CourseMapWindow.Map_OnLButtonUp = ClfCourseMap.onMap_OnLButtonUp
	end

	if ( not ClfCourseMap.mapWindowMap_OnLButtonDown_org ) then
		ClfCourseMap.mapWindowMap_OnLButtonDown_org = CourseMapWindow.Map_OnLButtonDown
		CourseMapWindow.Map_OnLButtonDown = ClfCourseMap.onMap_OnLButtonDown
	end

	if ( not ClfCourseMap.mapWindowPlotToggle_OnLButtonUp_org ) then
		ClfCourseMap.mapWindowPlotToggle_OnLButtonUp_org = CourseMapWindow.PlotToggle_OnLButtonUp
		CourseMapWindow.PlotToggle_OnLButtonUp = ClfCourseMap.onPlotToggle_OnLButtonUp
	end

	if ( not ClfCourseMap.mapWindowMapPoint_OnLButtonDown_org ) then
		ClfCourseMap.mapWindowMapPoint_OnLButtonDown_org = CourseMapWindow.MapPoint_OnLButtonDown
		CourseMapWindow.MapPoint_OnLButtonDown = ClfCourseMap.onMapPoint_OnLButtonDown
	end

	for k in pairs( CONST.MAP_TIDS ) do
		if ( nil == CourseMapWindow.TreasureMaps[ k ] ) then
			CourseMapWindow.TreasureMaps[ k ] = true
		end
	end
end


-- トレジャーマップのピン画像設定の切り替え
function ClfCourseMap.toggleMapX( silent )
	local enable = not ClfCourseMap.EnableArrowX
	ClfCourseMap.EnableArrowX = enable
	Interface.SaveBoolean( "ClfMapArrowX", enable )

	if ( not silent ) then
		local str
		local hue
		if ( enable ) then
			str = L"Arrow"
			hue = 1152
		else
			str = L"X"
			hue = 150
		end
		WindowUtils.SendOverheadText( L"TreasureMap Pin: " .. str, hue, true )
	end
end


function ClfCourseMap.onMapWindowInitialize()
	local mapId = SystemData.ActiveObject.Id

	ClfCourseMap.mapWindowInitialize_org()

	if ( CourseMapWindow.isTmap or ClfCourseMap.isTmapByTid( mapId ) ) then
		WindowUtils.RestoreWindowPosition( SystemData.ActiveWindow.name )
		CourseMapWindow.isTmap = true
		MapScales[ mapId ] = ClfCourseMap.getZoom( mapId )

		local windowName = "CourseMapWindow" .. mapId
		local plotToggle = windowName .. "PlotToggle"
		local CONST = CONST
		LabelSetText( plotToggle, CONST.WSTRINGS.ZoomIn )
		WindowSetShowing( plotToggle, true )

		local clearCourse =  windowName .. "ClearCourse"
		WindowSetHandleInput( clearCourse, false )
		WindowSetLayer( clearCourse, Window.Layers.BACKGROUND )
		WindowSetFontAlpha( clearCourse, 0 )

		local zoomBtns = windowName .. "ClfZoomBtns"
		if ( not DoesWindowExist( zoomBtns ) ) then
			local RegisterWindowData = RegisterWindowData
			local WindowAddAnchor = WindowAddAnchor
			local WindowSetId = WindowSetId

			CreateWindowFromTemplateShow( zoomBtns, "ClfTmapZoomBtnTemplate", windowName, true )
			WindowAddAnchor( zoomBtns, "topleft", windowName, "topleft", 0, 45 )
			WindowAddAnchor( zoomBtns, "bottomright", windowName, "bottomright", 0, 0 )
			WindowSetId( zoomBtns, mapId )
			WindowSetId( zoomBtns .. "ZoomIn", 1 )
			WindowSetId( zoomBtns .. "ZoomOut", -1 )

			local facetStr
			local lvStr
			local themeStr
			local completed = false

			local WD_ItemProperties = WindowData.ItemProperties
			RegisterWindowData( WD_ItemProperties.Type, mapId, true )
			local itemProps = WD_ItemProperties[ mapId ]
			if ( not itemProps ) then
				RegisterWindowData( WD_ItemProperties.Type, mapId )
				itemProps = WD_ItemProperties[ mapId ]
			end

			if ( itemProps and itemProps.PropertiesTids and itemProps.PropertiesList ) then
				local currentMapTid

				if ( itemProps.PropertiesTids and itemProps.PropertiesList ) then
					local MAP_TIDS = CONST.MAP_TIDS
					local FACET_TIDS = CONST.FACET_TIDS
					local TID_COMPLETED = CONST.TID_COMPLETED

					for idx, tid in pairs( itemProps.PropertiesTids ) do
						if ( MAP_TIDS[ tid ] ) then
							currentMapTid = tid
							lvStr = towstring( 'Lv.' .. MAP_TIDS[ tid ] )
						elseif ( FACET_TIDS[ tid ] ) then
							facetStr = itemProps.PropertiesList[ idx ]
						elseif ( tid == TID_COMPLETED ) then
							completed = true
						end
					end
				end

				if ( currentMapTid and itemProps.PropertiesTidsParams ) then
					local wSub = wstring.sub

					local PropTidsParams = itemProps.PropertiesTidsParams
					local mapTidParam = towstring( '@' .. currentMapTid )

					for idx, tidParam in pairs( PropTidsParams ) do
						if ( mapTidParam == tidParam ) then
							local subTidParam = PropTidsParams[ 1 + idx ]
							if ( "wstring" == type( subTidParam ) ) then
								local prefix = wSub( subTidParam, 1, 1 )
								if ( L"#" == prefix ) then
									local fixTid = tonumber( tostring( wSub( subTidParam, 2 ) ) )
									if ( fixTid and fixTid > 0 ) then
										local str = GetStringFromTid( fixTid )
										if ( "wstring" == type( str ) and L"MISSING STRING" ~= str and L"" ~= str ) then
											themeStr = str
											break
										end
									end
								end
							end
						end
					end
				end

			end

			local mapNamBtn = zoomBtns .. "MapName"

			ButtonSetDisabledFlag( mapNamBtn, completed )
			local labelStr
			if ( "wstring" == type( facetStr )  and L"" ~= facetStr  ) then
				labelStr = facetStr
			end
			if ( "wstring" == type( lvStr ) and L"" ~= lvStr ) then
				local prefix = labelStr and labelStr .. L" - " or L""
				labelStr = prefix .. lvStr
				if ( "wstring" ==type( themeStr ) and  L"" ~= themeStr ) then
					labelStr = labelStr .. L' [' .. themeStr .. L']'
				end
			else
				local WD_ObjectInfo = WindowData.ObjectInfo
				RegisterWindowData( WD_ObjectInfo.Type, mapId, true )
				local itemData = WD_ObjectInfo[ mapId ]
				if ( not itemData ) then
					RegisterWindowData( WD_ObjectInfo.Type, mapId )
					itemData = WD_ObjectInfo[ mapId ]
				end
				local mapName = itemData and itemData.name
				if ( "wstring" == type( mapName ) and  L"" ~= mapName ) then
					local prefix = labelStr and labelStr .. L" - " or L""
					labelStr = prefix .. mapName
				end
			end

			labelStr = labelStr or L"(Unknown Map)"
			ButtonSetText( mapNamBtn, labelStr )
			WindowSetId( mapNamBtn, mapId )
		end
	end
end


function ClfCourseMap.onMapWindowShutdown()
	if ( CourseMapWindow.isTmap ) then
		local win = SystemData.ActiveWindow.name
		local mapId = WindowGetId( win )
		WindowUtils.SaveWindowPosition( win )
	end
	ClfCourseMap.mapWindowShutdown_org()
end


function ClfCourseMap.onUpdatePoints()
	local mapId = SystemData.ActiveObject.Id
	local ClfCourseMap = ClfCourseMap
	if ( ClfCourseMap.isTmapId( mapId ) ) then
		CourseMapWindow.isTmap = true
	end
	ClfCourseMap.mapWindowUpdatePoints_org()

	if ( CourseMapWindow.isTmap ) then
		local points = CourseMapWindow.MapPoints[ mapId ] or {}
		if ( ClfUtil.tableElemn( points ) ~= 1 ) then
			-- 現状、ポイントが2個以上の場合に対応していないのでズームしないフラグを立てて終了
			DisabledZoomMaps[ mapId ] = true
			return
		else
			DisabledZoomMaps[ mapId ] = nil
		end
		if ( ClfCourseMap.EnableArrowX ) then
			local windowName = "CourseMapWindow" .. mapId
			for id in pairs( points ) do
				local pointName = windowName .. mapId .. "Point" .. id
				local img = pointName .. "Point"
				WindowSetShowing( img, false )

				local clfPoint = pointName .. "ClfPoint"
				if ( not DoesWindowExist( clfPoint ) ) then
					CreateWindowFromTemplateShow( clfPoint, "ClfMapPointImage", pointName, true )
					WindowSetId( pointName, 0 )
				end

				WindowSetLayer( pointName, Window.Layers.SECONDARY )
			end
		end

		ClfCourseMap.zoomMap( mapId, ClfCourseMap.getZoom( mapId ) )
	end
end


function ClfCourseMap.onMapUpdateState()
	local mapId = SystemData.ActiveObject.Id
	if ( ClfCourseMap.isTmapId( mapId ) ) then
		CourseMapWindow.isTmap = true
	end
	ClfCourseMap.mapWindowUpdateState_org()

	if ( CourseMapWindow.isTmap ) then
		local mapId = SystemData.ActiveObject.Id
		local windowName = "CourseMapWindow" .. mapId
		if ( ClfCourseMap.getZoom( mapId ) > 1 ) then
			LabelSetText( windowName.."PlotToggle", CONST.WSTRINGS.Reset )
			LabelSetTextColor( windowName.."PlotToggle", 50, 0, 0 )
		else
			LabelSetText( windowName.."PlotToggle", CONST.WSTRINGS.ZoomIn )
			LabelSetTextColor(windowName.."PlotToggle", 0, 50, 0)
			WindowSetShowing( windowName.."ClearCourse", false )
		end
	end
end


function ClfCourseMap.getZoom( mapId )
	return MapScales[ mapId ] or 1
end


function ClfCourseMap.isTmapId( mapId )
	return ( MapScales[ mapId ] ~= nil )
end


function ClfCourseMap.isTmapByTid( mapId )
	local WindowData_ItemProperties = WindowData.ItemProperties
	if ( not WindowData_ItemProperties[ mapId ] ) then
		RegisterWindowData( WindowData_ItemProperties.Type, mapId )
	end
	if ( WindowData_ItemProperties[ mapId ] and WindowData_ItemProperties[ mapId ].PropertiesTids ) then
		local tid = WindowData.ItemProperties[ mapId ].PropertiesTids[1]
		if ( CONST.MAP_TIDS[ tid ] ) then
			return true
		end
	end
	return false
end


local function btnDisabled( btn )
	WindowSetAlpha( btn, 0.5 )
	WindowSetTintColor( btn, 255, 205, 125 )
	WindowSetHandleInput( btn, false )
end

local function btnEenabled( btn )
	WindowSetAlpha( btn, 1 )
	WindowSetTintColor( btn, 255, 255, 255 )
	WindowSetHandleInput( btn, true )
end


function ClfCourseMap.zoomMap( mapId, zoom )
	if ( not mapId ) then
		return
	end
	local ClfCourseMap = ClfCourseMap
	if ( not CourseMapWindow.isTmap ) then
		if ( ClfCourseMap.isTmapId( mapId ) ) then
			CourseMapWindow.isTmap = true
		else
			return
		end
	end
	if ( DisabledZoomMaps[ mapId ] ) then
		return
	end

	local width, height, textureWidth, textureHeight, textureScale = GetCourseMapWindowDimensions( mapId )

	if ( width ~= nil and height ~= nil
			and textureWidth ~= nil and textureHeight ~= nil
		) then
		local CONST = CONST
		local ZOOM_SCALES = CONST.ZOOM_SCALES

		local windowName = "CourseMapWindow" .. mapId
		local zoomScale
		if ( type( zoom ) == "number" ) then
			zoomScale =  zoom
		else
			local inc = zoom and 1 or -1
			zoomScale = ClfCourseMap.getZoom( mapId ) + inc * ZOOM_SCALES.BTN_STEP
		end
		zoomScale = zoomScale - zoomScale % ZOOM_SCALES.MIN_STEP
		zoomScale = math.min( ZOOM_SCALES.MAX, math.max( ZOOM_SCALES.MIN, zoomScale ) )

		MapScales[ mapId ] = zoomScale

		local label = windowName .. "PlotToggle"
		if ( zoomScale > 1 ) then
			LabelSetText( label, CONST.WSTRINGS.Reset )
			LabelSetTextColor( label, 50, 0, 0)
		else
			LabelSetText( label, CONST.WSTRINGS.ZoomIn )
			LabelSetTextColor( label, 0, 50, 0)
		end

		local string_format = string.format
		local tonumber = tonumber
		local math_round = function( num )
			return tonumber( string_format( "%.0f", num ) )
		end

		local texWin = windowName .. "Texture"
		DynamicImageSetTextureDimensions( texWin, math_round( textureWidth / zoomScale ), math_round( textureHeight / zoomScale ) )

		-- ズーム時にマップのマークを合わせる為のオフセット量を算出
		local pointGapX = 0
		local pointGapY = 0
		local mapPoint = CourseMapWindow.MapPoints[ mapId ][1]

		if ( mapPoint ) then
			pointGapX = mapPoint.x - ( width * 0.5 )
			pointGapY = mapPoint.y - ( height * 0.5 )
		end

		local offsetX = width - math_round( width / zoomScale )
		local offsetY = height - math_round( height / zoomScale )
		offsetX = offsetX + 2 * ( pointGapX * zoomScale - pointGapX ) / zoomScale
		offsetY = offsetY + 2 * ( pointGapY * zoomScale - pointGapY ) / zoomScale

		DynamicImageSetTexture( texWin, "CourseMap" .. mapId, math_round( offsetX ), math_round( offsetY ) )

		local zoomInBtn  = windowName .. "ClfZoomBtnsZoomIn"
		local zoomOutBtn = windowName .. "ClfZoomBtnsZoomOut"

		if ( zoomScale <= ZOOM_SCALES.MIN ) then
			btnDisabled( zoomOutBtn )
			btnEenabled( zoomInBtn )
		elseif ( zoomScale >= ZOOM_SCALES.MAX ) then
			btnDisabled( zoomInBtn )
			btnEenabled( zoomOutBtn )
		else
			btnEenabled( zoomInBtn )
			btnEenabled( zoomOutBtn )
		end
	end
end


function ClfCourseMap.reversePointImg( pointName )
	if ( ClfCourseMap.EnableArrowX and DoesWindowExist( pointName ) ) then
		local id = WindowGetId( pointName ) or 0
		id = ( id == 0 ) and 0 or 1
		local newId = 1 - id
		local deg = newId * 180
		DynamicImageSetRotation( pointName, deg )
		WindowSetId( pointName, newId )
	end
end


function ClfCourseMap.onMap_OnLButtonDown()
	local parentWindow = WindowGetParent( SystemData.ActiveWindow.name )
	local mapId = WindowGetId( parentWindow )
	CourseMapWindow.isTmap = ClfCourseMap.isTmapId( mapId )
	if ( CourseMapWindow.isTmap ) then
		WindowSetMoving( parentWindow, true )
		return
	end
	ClfCourseMap.mapWindowMap_OnLButtonDown_org()
end


function ClfCourseMap.onMap_OnLButtonUp( flags, x, y )
	local parentWindow = WindowGetParent( SystemData.ActiveWindow.name )
	local mapId = WindowGetId( parentWindow )
	CourseMapWindow.isTmap = ClfCourseMap.isTmapId( mapId )
	if ( CourseMapWindow.isTmap ) then
		return
	end
	ClfCourseMap.mapWindowMap_OnLButtonUp_org( flags, x, y )
end


function ClfCourseMap.onPlotToggle_OnLButtonUp()
	local parentWindow = WindowGetParent( SystemData.ActiveWindow.name )
	local mapId = WindowGetId( parentWindow )

	CourseMapWindow.isTmap = ClfCourseMap.isTmapId( mapId )
	ClfCourseMap.mapWindowPlotToggle_OnLButtonUp_org()

	if ( CourseMapWindow.isTmap ) then
		local ZOOM_SCALES = CONST.ZOOM_SCALES
		local zScale = ( ClfCourseMap.getZoom( mapId ) > ZOOM_SCALES.DEFAULT ) and ZOOM_SCALES.DEFAULT or ZOOM_SCALES.ZOOM_IN
		ClfCourseMap.zoomMap( mapId, zScale )
	end
end


function ClfCourseMap.onMapPoint_OnLButtonDown()
	local parentWindow = WindowGetParent( WindowGetParent( SystemData.ActiveWindow.name ) )
	local mapId = WindowGetId( parentWindow )
	CourseMapWindow.isTmap = ClfCourseMap.isTmapId( mapId )
	if ( CourseMapWindow.isTmap ) then
		ClfCourseMap.reversePointImg( SystemData.ActiveWindow.name )
		return
	end
	ClfCourseMap.mapWindowMapPoint_OnLButtonDown_org()
end


function ClfCourseMap.zoomBtnOnLButtonUp()
	CourseMapWindow.isTmap = true
	local btn = SystemData.ActiveWindow.name
	local mapId = WindowGetId( WindowGetParent( btn ) )
	local btnId = WindowGetId( btn )
	ClfCourseMap.zoomMap( mapId, ( btnId == 1 ) )
end


function ClfCourseMap.onMouseWheel( x, y, delta )
	local mapId = WindowGetId( SystemData.ActiveWindow.name )
	local zScale = ClfCourseMap.getZoom( mapId ) + delta * CONST.ZOOM_SCALES.WHEEL_STEP
	ClfCourseMap.zoomMap( mapId, zScale )
end


function ClfCourseMap.onMapNameOver()
	local windowName = SystemData.ActiveWindow.name
	local mapId = WindowGetId( windowName )
	if( mapId and mapId > 0 ) then
		local itemData = {
			windowName = windowName,
			itemId = mapId,
			itemType = WindowData.ItemProperties.TYPE_ITEM,
		}
		ItemProperties.SetActiveItem( itemData )
	end
end


function ClfCourseMap.onMapNameOverEnd()
	ItemProperties.ClearMouseOverItem()
end


function ClfCourseMap.onMapNameOnBtnLUp()
	CourseMapWindow.isTmap = true
	local btn = SystemData.ActiveWindow.name
	if ( not ButtonGetDisabledFlag( btn ) ) then
		local mapId = WindowGetId( btn )
		if ( mapId and mapId > 0 ) then
			-- 財宝を掘る
			ContextMenu.RequestContextAction( mapId, 305 )
		end
	else
		TextLogAddEntry( "Chat", SystemData.ChatLogFilters.SYSTEM, CONST.WSTRINGS.Completed )
	end
end


function ClfCourseMap.onMapNameOnBtnRUp()
	CourseMapWindow.isTmap = true
	local mapId = WindowGetId( SystemData.ActiveWindow.name )
	if ( mapId and mapId > 0 ) then
--		RequestContextMenu( mapId )
		HandleSingleLeftClkTarget( mapId )
	end
end

