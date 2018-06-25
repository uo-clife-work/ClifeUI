
--[[
	標準UIの関数をオーバーライドし最適化etc.
]]

LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfCommon", "ClfRefactor.xml", "ClfRefactor.xml" )

ClfRefactor = {}


ClfRefactor.Enable = true

-- デフォルトのオブハン表示用メソッドを保持
ClfRefactor.createObjectHandles_org = nil
-- デフォルトのオブハン削除用メソッドを保持
ClfRefactor.destroyObjectHandles_org = nil


function ClfRefactor.initialize()
	if ( not ClfRefactor.Enable ) then
		return
	end

	if ( not ClfRefactor.createObjectHandles_org ) then
		-- オブハン表示用メソッドをオーバーライド
		ClfRefactor.createObjectHandles_org = ObjectHandleWindow.CreateObjectHandles
		ObjectHandleWindow.CreateObjectHandles = ClfRefactor.createObjectHandles
	end
	if ( not ClfRefactor.destroyObjectHandles_org ) then
		-- オブハン削除用メソッドをオーバーライド
		ClfRefactor.destroyObjectHandles_org = ObjectHandleWindow.DestroyObjectHandles
		ObjectHandleWindow.DestroyObjectHandles = ClfRefactor.destroyObjectHandles
	end

end


-- OverRide: ObjectHandleWindow.CreateObjectHandles
function ClfRefactor.createObjectHandles()
	local ObjectHandleWindow = ObjectHandleWindow
	ObjectHandleWindow.Active = true

	local objectsData = {}

	if ( ObjectHandleWindow.retrieveObjectsData( objectsData ) ) then
		if ( not objectsData or not objectsData.Names ) then
			return
		end

		ObjectHandleWindow.ObjectsData = objectsData

		-- set global to local
		-- functions
		local DoesPlayerHaveItem = DoesPlayerHaveItem
		local RegisterWindowData = RegisterWindowData
		local UnregisterWindowData = UnregisterWindowData
		local IsMobile = IsMobile
		local wLower = wstring.lower
		local ItemProperties_GetObjectPropertiesArray = ItemProperties.GetObjectPropertiesArray
		local CreateWindowFromTemplateShow = CreateWindowFromTemplateShow
		local WindowSetScale = WindowSetScale
		local WindowSetAlpha = WindowSetAlpha
		local WindowSetId = WindowSetId
		local LabelSetText = LabelSetText
		local WindowSetTintColor = WindowSetTintColor
		local AttachWindowToWorldObject = AttachWindowToWorldObject
		local WindowSetShowing = WindowSetShowing

		-- variables
		local ObjectHandleWindow_ObjectsData = ObjectHandleWindow.ObjectsData
		local ObjectHandleWindow_ObjectsData_ObjectId = ObjectHandleWindow_ObjectsData.ObjectId
		local ObjectHandleWindow_ReverseObjectLookUp = ObjectHandleWindow.ReverseObjectLookUp
		local ObjectHandleWindow_hasWindow = ObjectHandleWindow.hasWindow
		local ObjectHandleWindow_CurrentFilter = ObjectHandleWindow.CurrentFilter
		local ObjectHandleWindow_ObjectHandleScale = ObjectHandleWindow.ObjectHandleScale
		local ObjectHandleWindow_ObjectHandleAlpha = ObjectHandleWindow.ObjectHandleAlpha
		local PlayerId = WindowData.PlayerStatus.PlayerId
		local CurrentHonor = Interface.CurrentHonor
		local WindowData_ContainerWindow = WindowData.ContainerWindow
		local WindowData_ContainerWindow_Type = WindowData_ContainerWindow.Type
		local ContainerWindow_OpenContainers = ContainerWindow.OpenContainers

		local isItemsOnly = ( SystemData.Settings.GameOptions.objectHandleFilter == SystemData.Settings.ObjectHandleFilter.eItemsOnlyFilter )
		local isLostItemsOnly = ( SystemData.Settings.GameOptions.objectHandleFilter == SystemData.Settings.ObjectHandleFilter.eLostItemsOnlyFilter )

		local grayColor = ObjectHandleWindow.grayColor
		local TextColors = ObjectHandleWindow.TextColors

		-- define local function
		local filterNames = nil
		local isNamePassedFilter
		if ( ObjectHandleWindow_CurrentFilter and ObjectHandleWindow_CurrentFilter ~= "" and ObjectHandleWindow_CurrentFilter ~= L"" ) then
			filterNames = {}
			for cf in wstring.gmatch( ObjectHandleWindow_CurrentFilter, L"[^|]+" ) do
				local cfFix = wLower( cf )
				if ( cfFix ~= L"" and type( cfFix ) == "wstring" ) then
					filterNames[ #filterNames + 1 ] = cfFix
				end
			end
			isNamePassedFilter = function( name )
				local nameFix = wLower( name )
				if ( nameFix ~= L"" and type( nameFix ) == "wstring" ) then
					local wFind =  wstring.find
					for k = 1, #filterNames do
						if ( wFind( nameFix, filterNames[ k ] ) ) then
							return true
						end
					end
				end
				return false
			end
		else
			isNamePassedFilter = function( name )
				return true
			end
		end

		-- define local variables
		local honorColor    = { r = 163, g =  73, b = 164 }
		local lostItemColor = { r = 146, g = 245, b = 153 }
		local ignoreItemIds = {}
		local ContainerWindow_IgnoreItems = ContainerWindow.IgnoreItems
		for j = 1, #ContainerWindow_IgnoreItems do
			local id = ContainerWindow_IgnoreItems[ j ] and ContainerWindow_IgnoreItems[ j ].id
			if ( id ) then
				ignoreItemIds[ id ] = true
			end
		end

		-- loop start
		for i = 1, #ObjectHandleWindow_ObjectsData_ObjectId do
			local objectId = ObjectHandleWindow_ObjectsData_ObjectId[ i ]
			if ( objectId == PlayerId ) then
				continue
			end
			if ( ObjectHandleWindow_hasWindow[ objectId ] ) then
				continue
			end
			if ( ignoreItemIds[ objectId ] ) then
				continue
			end
			if ( DoesPlayerHaveItem( objectId ) ) then
				continue
			end

			local name = ObjectHandleWindow_ObjectsData.Names[ i ]
			if ( not name or name == L"" or name == L"Treasure Sand" ) then
				continue
			end
			if ( not isNamePassedFilter( name ) ) then
				continue
			end

			local lostItem = false
			if ( not IsMobile( objectId ) ) then
				local tids = ItemProperties_GetObjectPropertiesArray( objectId, "Object Handle - check lost item" )
				tids = tids and tids.PropertiesTids or {}

				for i = 1, #tids do
					if ( tids[ i ] == 1151520 ) then
						-- 1151520: 遺失物（返却すると誠実さを獲得）
						lostItem = true
						break
					end
				end
			end

			local ObjectDataIsMobile = ObjectHandleWindow_ObjectsData.IsMobile[ i ]
			if ( isLostItemsOnly and not lostItem ) then
				continue
			elseif ( isItemsOnly ) then
				if ( ObjectDataIsMobile ) then
					continue
				end

				local removeOnComplete = false
				if ( not WindowData_ContainerWindow[ objectId ] ) then
					RegisterWindowData( WindowData_ContainerWindow_Type, objectId )
					removeOnComplete = true
				end

				if ( WindowData_ContainerWindow[ objectId ] and WindowData_ContainerWindow[ objectId ].isCorpse ) then
					continue
				end

				if ( removeOnComplete and ContainerWindow_OpenContainers[ objectId ] == nil ) then
					UnregisterWindowData( WindowData_ContainerWindow_Type, objectId )
				end
			end

			local hue
			if ( ObjectDataIsMobile ) then
				if ( objectId == CurrentHonor ) then
					hue = honorColor
				else
					hue = TextColors[ ObjectHandleWindow_ObjectsData.Notoriety[ i ] + 1 ]
				end
			else
				if ( lostItem ) then
					hue = lostItemColor
				else
					hue = grayColor
				end
			end

			-- Create Object handle
			local windowName     = "ObjectHandleWindow" .. objectId
			local windowTintName = windowName .. "Tint"
			local labelName      = windowName .. "TintName"
			local labelBGName    = windowName .. "TintNameBG"

			CreateWindowFromTemplateShow( windowName, "ClfObjectHandleWindow", "Root", false )
			WindowSetScale( windowName, ObjectHandleWindow_ObjectHandleScale )
			WindowSetAlpha( windowName, ObjectHandleWindow_ObjectHandleAlpha )
			WindowSetId( windowName, objectId )
			LabelSetText( labelName, name )
			LabelSetText( labelBGName, name )
			WindowSetTintColor( windowTintName, hue.r, hue.g, hue.b )
			AttachWindowToWorldObject( objectId, windowName )
			WindowSetShowing( windowName, true )

			ObjectHandleWindow_hasWindow[ objectId ] = true
			ObjectHandleWindow_ReverseObjectLookUp[ objectId ] = i
		end
		-- loop end

		-- Create OnUpdate Eventhandle window
		if ( not DoesWindowExist( "ClfObjectHandleProcess" ) ) then
			CreateWindow( "ClfObjectHandleProcess", true )
		end
	end
end


-- OverRide: ObjectHandleWindow.DestroyObjectHandles
function ClfRefactor.destroyObjectHandles()
	if ( DoesWindowExist( "ClfObjectHandleProcess" ) ) then
		DestroyWindow( "ClfObjectHandleProcess" )
	end
	ClfRefactor.destroyObjectHandles_org()
end


