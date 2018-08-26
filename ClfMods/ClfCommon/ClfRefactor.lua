
--[[
	標準UIの関数をオーバーライドし最適化、機能追加etc.
]]

LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfCommon", "ClfRefactor.xml", "ClfRefactor.xml" )

ClfRefactor = {}


ClfRefactor.Enable = true

-- デフォルトのオブハン表示用メソッドを保持
ClfRefactor.createObjectHandles_org = nil
-- デフォルトのオブハン削除用メソッドを保持
ClfRefactor.destroyObjectHandles_org = nil
-- デフォルトのオブハンonUpdateメソッドを保持： 現状使用しないが一応。
ClfRefactor.objectHandleWindowOnUpdate_org = nil
-- デフォルトのVacuum開始メソッドを保持： 現状使用しないが一応。
ClfRefactor.massOrganizerStart_org = nil
-- デフォルトのVacuum用onUpdateメソッドを保持： 現状使用しないが一応。
ClfRefactor.massOrganizer_org = nil


function ClfRefactor.initialize()
	local ClfRefactor = ClfRefactor
	if ( not ClfRefactor.Enable ) then
		return
	end

	local ObjectHandleWindow = ObjectHandleWindow
	local Actions = Actions

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
	if ( not ClfRefactor.objectHandleWindowOnUpdate_org ) then
		-- オブハンonUpdateメソッドをオーバーライド
		ClfRefactor.objectHandleWindowOnUpdate_org = ObjectHandleWindow.OnUpdate
		ObjectHandleWindow.OnUpdate = ClfRefactor.objectHandleWindowOnUpdate
	end
	if ( not ClfRefactor.massOrganizerStart_org ) then
		-- Vacuum用onUpdateメソッドをオーバーライド
		ClfRefactor.massOrganizerStart_org = Actions.MassOrganizerStart
		Actions.MassOrganizerStart = ClfRefactor.onVacuumStart
	end
	if ( not ClfRefactor.massOrganizer_org ) then
		-- Vacuum用onUpdateメソッドをオーバーライド
		ClfRefactor.massOrganizer_org = Actions.MassOrganizer
		Actions.MassOrganizer = ClfRefactor.onMassOrganizer
	end

end


local CONST = {
	honorColor    = { r = 163, g =  73, b = 164 },
	lostItemColor = { r = 146, g = 245, b = 153 },
}

-- オブハン表示時に、オブジェクトのIDを保持するテーブル
ClfRefactor.FieldObjectIds = {}

-- Scavenger用アイテム判定に使うtable
local ScvItemTypesHues = false

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
		local wLower = wstring.lower
		local wFind =  wstring.find
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
		ClfRefactor.FieldObjectIds = {}
		local FieldObjectIds = ClfRefactor.FieldObjectIds
		local ObjectHandleWindow_ObjectsData_ObjectId = ObjectHandleWindow.ObjectsData.ObjectId
		local ObjectHandleWindow_ObjectsData_Names = ObjectHandleWindow.ObjectsData.Names
		local ObjectHandleWindow_ObjectsData_IsMobile = ObjectHandleWindow.ObjectsData.IsMobile
		local ObjectHandleWindow_ObjectsData_Notoriety = ObjectHandleWindow.ObjectsData.Notoriety
		local ObjectHandleWindow_ReverseObjectLookUp = ObjectHandleWindow.ReverseObjectLookUp
		local ObjectHandleWindow_hasWindow = ObjectHandleWindow.hasWindow
		local ObjectHandleWindow_CurrentFilter = ObjectHandleWindow.CurrentFilter
		local ObjectHandleWindow_ObjectHandleScale = ObjectHandleWindow.ObjectHandleScale
		local ObjectHandleWindow_ObjectHandleAlpha = ObjectHandleWindow.ObjectHandleAlpha
		local PlayerId = WindowData.PlayerStatus.PlayerId
		local CurrentHonor = Interface.CurrentHonor
		local WindowData_ContainerWindow = WindowData.ContainerWindow
		local WindowData_ContainerWindow_Type = WindowData_ContainerWindow.Type
		local WD_ItemProperties = WindowData.ItemProperties
		local WD_ItemProperties_Type = WD_ItemProperties.Type

		local grayColor = ObjectHandleWindow.grayColor
		local TextColors = ObjectHandleWindow.TextColors

		local objectHandleFilter = SystemData.Settings.GameOptions.objectHandleFilter
		local SSO = SystemData.Settings.ObjectHandleFilter
		local isItemsOnly = ( objectHandleFilter == SSO.eItemsOnlyFilter )
		local isLostItemsOnly = ( objectHandleFilter == SSO.eLostItemsOnlyFilter )
		local isItemsOrLostItemsFilter = isItemsOnly or isLostItemsOnly

		-- define local variables
		local ignoreItemIds = {}
		local ContainerWindow_IgnoreItems = ContainerWindow.IgnoreItems
		for j = 1, #ContainerWindow_IgnoreItems do
			local id = ContainerWindow_IgnoreItems[ j ] and ContainerWindow_IgnoreItems[ j ].id
			if ( id ) then
				ignoreItemIds[ id ] = true
			end
		end

		-- 文字フィルターの配列
		local filterStrings
		-- 文字フィルターチェック用関数： 通常（文字フィルターが無い時）は必ず true を返す
		local isNamePassedFilter = _return_true

		if ( type( ObjectHandleWindow_CurrentFilter ) == "wstring" and ObjectHandleWindow_CurrentFilter ~= L"" ) then
			filterStrings = {}
			for cf in wstring.gmatch( ObjectHandleWindow_CurrentFilter, L"[^|]+" ) do
				local cfFix = wLower( cf )
				if ( cfFix ~= L"" and type( cfFix ) == "wstring" ) then
					filterStrings[ #filterStrings + 1 ] = cfFix
				end
			end
			if ( #filterStrings ~= 0 ) then
				isNamePassedFilter = function( name )
					if ( type( name ) == "wstring" ) then
						local nameFix = wLower( name )
						for k = 1, #filterStrings do
							if ( wFind( nameFix, filterStrings[ k ] ) ) then
								return true
							end
						end
					end
					return false
				end
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

			local name = ObjectHandleWindow_ObjectsData_Names[ i ]
			if ( not name or name == L"" or name == L"Treasure Sand" ) then
				continue
			end
			if ( isNamePassedFilter( name ) == false ) then
				continue
			end

			local ObjectDataIsMobile = ObjectHandleWindow_ObjectsData_IsMobile[ i ]
			if ( not ObjectDataIsMobile ) then
				FieldObjectIds[ #FieldObjectIds + 1 ] = objectId
			end

			if ( isItemsOrLostItemsFilter ) then
				if ( ObjectDataIsMobile ) then
					continue
				end

				local containerData = WindowData_ContainerWindow[ objectId ]
				if ( not containerData ) then
					RegisterWindowData( WindowData_ContainerWindow_Type, objectId )
					containerData = WindowData_ContainerWindow[ objectId ]
				end
				if ( containerData and containerData.isCorpse ) then
					continue
				end
			end

			-- Lost Item check
			local lostItem = false
			if ( not ObjectDataIsMobile ) then
				local propData = WD_ItemProperties[ objectId ]
				if ( not propData ) then
					RegisterWindowData( WD_ItemProperties_Type, objectId )
					propData = WD_ItemProperties[ objectId ]
				end
				local tids = propData and propData.PropertiesTids or {}

				for j = 1, #tids do
					if ( tids[ j ] == 1151520 ) then
						-- 1151520: 遺失物（返却すると誠実さを獲得）
						lostItem = true
						break
					end
				end
			end

			if ( isLostItemsOnly and not lostItem ) then
				continue
			end

			local hue
			if ( ObjectDataIsMobile ) then
				if ( objectId == CurrentHonor ) then
					hue = CONST.honorColor
				else
					hue = TextColors[ ObjectHandleWindow_ObjectsData_Notoriety[ i ] + 1 ]
				end
			else
				if ( lostItem ) then
					hue = CONST.lostItemColor
				else
					hue = grayColor
				end
			end

			-- Create Object handle window
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

		-- Scavenger用アイテム判定に使うtableを生成
		if ( objectHandleFilter ~= SSO.eDynamicFilter and not isItemsOrLostItemsFilter ) then
			-- オブハンフィルターがアイテムを表示しないタイプになっている。tableを定義しない
			ScvItemTypesHues = false
		else
			local Organizer_ActiveScavenger  = Organizer.ActiveScavenger
			local activeScavengers_Items = Organizer.Scavengers_Items[ Organizer_ActiveScavenger ]
			if ( ClfSettings.EnableScavengeAll ) then
				-- 全て拾う設定になっている。tableの定義だけしておく。
				ScvItemTypesHues = {}
			elseif ( activeScavengers_Items > 0 ) then
				-- Scavenger用アイテムが登録されている。tebleを生成
				ScvItemTypesHues = {}
				local scvItemTypesHues = ScvItemTypesHues
				local activeScavenger = Organizer.Scavenger[ Organizer_ActiveScavenger ]
				for j = 1, activeScavengers_Items do
					local itemL = activeScavenger[ j ]
					local itemL_type = itemL.type
					if ( scvItemTypesHues[ itemL_type ] == nil ) then
						scvItemTypesHues[ itemL_type ] = {}
					end
					scvItemTypesHues[ itemL_type ][ itemL.hue ] = true
				end
				if ( not next( ScvItemTypesHues ) ) then
					ScvItemTypesHues = false
				end
			else
				-- Scavenger用アイテムが登録されていない。tableを定義しない
				ScvItemTypesHues = false
			end
		end

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


local ScvObjectIds = {}

-- OverRide: ObjectHandleWindow.OnUpdate
function ClfRefactor.objectHandleWindowOnUpdate( timePassed )
	local ObjectHandle = ObjectHandle
	local ObjectHandleWindow = ObjectHandleWindow
	if ( ObjectHandleWindow.ForceIgnore ) then
		ObjectHandle.DestroyObjectWindow( ObjectHandleWindow.ForceIgnore )
		ObjectHandleWindow.ForceIgnore = nil
	end

	local IsValidObject = IsValidObject

	if ( ObjectHandleWindow.RefreshTimer > ObjectHandleWindow.REFRESH_DELAY ) then
		ObjectHandleWindow.RefreshTimer = 0
		local DoesPlayerHaveItem = DoesPlayerHaveItem
		local ObjectHandle_DestroyObjectWindow = ObjectHandle.DestroyObjectWindow

		for objectId in pairs( ObjectHandleWindow.hasWindow ) do
			if ( not IsValidObject( objectId ) or DoesPlayerHaveItem( objectId ) ) then
				ObjectHandle_DestroyObjectWindow( objectId )
			end
		end
	end

	-- ここから Scavengerの処理
	local SystemData_DragItem = SystemData.DragItem
	if (
			ScvItemTypesHues == false
			or ContainerWindow.CanPickUp ~= true
			or SystemData_DragItem.DragType == SystemData_DragItem.TYPE_ITEM
		) then
		-- アイテム判定用tableが定義されていない or アイテムをドラッグ出来る状態ではない： 終了
		return
	end

	ScvObjectIds = ScvObjectIds or {}
	local ScvObjectIds = ScvObjectIds

	local RegisterWindowData = RegisterWindowData
	local UnregisterWindowData = UnregisterWindowData

	local ContainerWindow = ContainerWindow
	local WindowData_ObjectInfo = WindowData.ObjectInfo
	local ObjectInfo_Type = WindowData_ObjectInfo.Type

	if ( #ScvObjectIds == 0 ) then
		local IsMobile = IsMobile
		local GetDistanceFromPlayer = GetDistanceFromPlayer

		local scvItemTypesHues = ScvItemTypesHues
		local WindowData_ContainerWindow
		local WindowData_ContainerWindow_Type
		local ContainerWindow_OpenContainers

		-- 対象が拾うアイテムならテーブルに追加するメソッド： 設定に依って振り分け
		local setScavengeItem
		if ( ClfSettings.EnableScavengeAll ) then
			-- 全て拾う
			WindowData_ContainerWindow = WindowData.ContainerWindow
			WindowData_ContainerWindow_Type = WindowData_ContainerWindow.Type
			ContainerWindow_OpenContainers = ContainerWindow.OpenContainers
			setScavengeItem = function( itemData, objectId )
				if ( not itemData ) then
					-- 対象のアイテムデータが無い。追加しない。
					return false
				end
				-- 死体かどうか判定
				local containerData = WindowData_ContainerWindow[ objectId ]
				if ( not containerData ) then
					RegisterWindowData( WindowData_ContainerWindow_Type, objectId )
					containerData = WindowData_ContainerWindow[ objectId ]
				end
				if ( containerData and containerData.isCorpse ) then
					-- 対象が死体だった。追加しない。
					return false
				end
				ScvObjectIds[ #ScvObjectIds + 1 ] = objectId
				return true
			end
		else
			-- 通常のScavenger
			setScavengeItem = function( itemData, objectId )
				if ( not itemData ) then
					return false
				end
				-- Scavengerに登録してあるアイテムか判定
				if ( scvItemTypesHues[ itemData.objectType ] and scvItemTypesHues[ itemData.objectType ][ itemData.hueId ] ) then
					ScvObjectIds[ #ScvObjectIds + 1 ] = objectId
					return true
				end
				return false
			end
		end

		for objectId in pairs( ObjectHandleWindow.hasWindow ) do
			if ( IsMobile( objectId ) ) then
				continue
			end

			if ( IsValidObject( objectId ) and GetDistanceFromPlayer( objectId ) <= 2 ) then
				local itemData = WindowData_ObjectInfo[ objectId ]
				if ( not itemData ) then
					RegisterWindowData( ObjectInfo_Type, objectId )
					itemData = WindowData_ObjectInfo[ objectId ]
				end

				setScavengeItem( itemData, objectId )
			end
		end
	end

	if ( #ScvObjectIds > 0 ) then
		local OrganizeBag = Organizer.Scavengers_Cont[ Organizer.ActiveScavenger ]
		if ( not OrganizeBag or OrganizeBag == 0 ) then
			OrganizeBag = ContainerWindow.PlayerBackpack
		end

		local objectId, itemData
		local table_remove = table.remove
		repeat
			local len = #ScvObjectIds
			objectId = ScvObjectIds[ len ]
			itemData = WindowData_ObjectInfo[ objectId ]
			table_remove( ScvObjectIds, len )
			if ( not itemData ) then
				RegisterWindowData( ObjectInfo_Type, objectId )
				itemData = WindowData_ObjectInfo[ objectId ]
				if ( not itemData ) then
					if ( #ScvObjectIds == 0 ) then
						ObjectHandleWindow.lastItem = 0
						return
					end
				else
					break
				end
			else
				break
			end
		until ( itemData )

		if ( itemData ) then
			if ( objectId ~= ObjectHandleWindow.lastItem and itemData.containerId == 0 ) then
				ContainerWindow.TimePassedSincePickUp = 0
				ContainerWindow.CanPickUp = false
				ObjectHandleWindow.lastItem = objectId

				local dropContainerId
				if ( itemData.objectType == 3821 and ClfSettings.EnableDropGoldToBP ) then
					-- アイテムがゴールドの時は第一階層にドロップする
					dropContainerId = MoveItemToContainer( objectId, itemData.quantity, ContainerWindow.PlayerBackpack )
				else
					dropContainerId = MoveItemToContainer( objectId, itemData.quantity, OrganizeBag )
				end
				if ( dropContainerId == nil ) then
					-- ドラッグ出来ないアイテムだった
					ContainerWindow.CanPickUp = true
				end
			end
		end

		if ( #ScvObjectIds == 0 ) then
			ScvObjectIds = {}
			ObjectHandleWindow.lastItem = 0
		end
	end
end


-- Vacuum実行中に重量・アイテム数オーバーの警告を発したフラグ
local DoesVacuumAlert = false

-- Organizerアイテム判定用のtable
local OrganizeItemTypesHues = {}
local OrganizeItemIds = {}

-- OverRide: Actions.MassOrganizerStart
function ClfRefactor.onVacuumStart()
	local Actions = Actions
	if ( Actions.MassOrganize == false ) then
		OrganizeItemTypesHues = false
		OrganizeItemIds = false
		Actions.VacuumObjects = Actions.VacuumObjects or {}
		local Organizer = Organizer
		local Organizer_ActiveOrganizer = Organizer.ActiveOrganizer
		local activeOrganizerCont = Organizer.Organizers_Cont[ Organizer_ActiveOrganizer ]
		if ( activeOrganizerCont ) then
			ContainerWindow.Organize = false
			ContainerWindow.OrganizeBag = activeOrganizerCont
			local ext = ClfOrganizer and ClfOrganizer.onOrganizerStart( Organizer_ActiveOrganizer )

			-- Organizerアイテムtype/id判定に使うtableを生成
			local activeOrganizerItemDatas = Organizer.Organizer[ Organizer_ActiveOrganizer ]
			if ( activeOrganizerItemDatas ) then
				OrganizeItemTypesHues = {}
				OrganizeItemIds = {}
				local organizeItemTypesHues = OrganizeItemTypesHues
				local organizeItemIds = OrganizeItemIds
				local activeOrganizerItemNum = Organizer.Organizers_Items[ Organizer_ActiveOrganizer ]
				for j = 1, activeOrganizerItemNum do
					local itemL = activeOrganizerItemDatas[ j ]
					local itemL_type = itemL.type
					if ( itemL_type > 0 ) then
						if ( organizeItemTypesHues[ itemL_type ] == nil ) then
							organizeItemTypesHues[ itemL_type ] = {}
						end
						organizeItemTypesHues[ itemL_type ][ itemL.hue ] = true
					elseif ( itemL.id > 0 ) then
						organizeItemIds[ itemL.id ] = true
					end
				end
			end
			DoesVacuumAlert = not ClfSettings.EnableVacuumMsg
			Actions.MassOrganize = true
		end
--	else
--		Actions.MassOrganize = false
--		Actions.VacuumObjects = {}
--		if ( ClfSettings.EnableVacuumMsg ) then
--			WindowUtils.SendOverheadText( L"=== Stop Vacuum ===" , 46, true )
--		end
	end
end


-- OverRide: Actions.MassOrganizer
function ClfRefactor.onMassOrganizer( timePassed )
	if ( Actions.MassOrganize ~= true ) then
		return
	end
	local ContainerWindow = ContainerWindow
	local SystemData_DragItem = SystemData.DragItem
	if (
			ContainerWindow.CanPickUp == true
			and SystemData_DragItem.DragType ~= SystemData_DragItem.TYPE_ITEM
		) then
		local ClfSettings = ClfSettings
		local Actions = Actions
		Actions.VacuumObjects = Actions.VacuumObjects or {}
		local Actions_VacuumObjects = Actions.VacuumObjects
		local WindowData_ObjectInfo = WindowData.ObjectInfo
		local ObjectInfo_Type = WindowData_ObjectInfo.Type
		local ContainerWindow_PlayerBackpack = ContainerWindow.PlayerBackpack
		local ContainerWindow_OrganizeBag = ContainerWindow.OrganizeBag

		local RegisterWindowData = RegisterWindowData
		local UnregisterWindowData = UnregisterWindowData

		if ( #Actions_VacuumObjects == 0 ) then
			-- Vacuum対象のアイテムがテーブルに保持されていない
			local organizeItemTypesHues = OrganizeItemTypesHues
			if ( organizeItemTypesHues ) then
				-- Organizerアイテムtype/id判定用のtableがある
				local organizeItemIds = OrganizeItemIds

				local DoesWindowExist = DoesWindowExist
				local addExtOrganizerItem = ClfOrganizer and ClfOrganizer.organizerAddItem or _return_false

				-- コンテナ内のアイテムがルート対象ならテーブルに追加するメソッド
				local setVacuumObject = function( itemData, objectId, containerId )
					if ( not itemData ) then
						return false
					end
					if ( organizeItemTypesHues[ itemData.objectType ] and organizeItemTypesHues[ itemData.objectType ][ itemData.hueId ] ) then
						Actions_VacuumObjects[ #Actions_VacuumObjects + 1 ] = objectId
						return true
					elseif ( organizeItemIds[ objectId ] == true ) then
						Actions_VacuumObjects[ #Actions_VacuumObjects + 1 ] = objectId
						return true
					end
					return addExtOrganizerItem( objectId, itemData, containerId )
				end

				-- 棺桶コンテナ内にルート対象が無くなったらコンテナを閉じるメソッド： 設定に依って振り分け
				local closeContainerWin
				local Organizer = Organizer
				if ( ClfSettings.EnableCloseContainerOnVacuum and Organizer.Organizers_CloseCont[ Organizer.ActiveOrganizer ] ) then
					closeContainerWin = function( containerId, addFromCont, containerData )
						if ( not addFromCont and containerData.isCorpse ) then
							DestroyWindow( "ContainerWindow_" .. containerId )
						end
					end
				else
					closeContainerWin = _void
				end

				local WindowData_ContainerWindow = WindowData.ContainerWindow

				-- 全コンテナ内のアイテムチェック開始
				for id in pairs( ContainerWindow.OpenContainers ) do
					if (
							DoesWindowExist( "ContainerWindow_" .. id )
							and id ~= ContainerWindow_PlayerBackpack
							and id ~= ContainerWindow_OrganizeBag
						) then

						local containerData = WindowData_ContainerWindow[ id ]
						local numItems = containerData.numItems
						local containedItems = containerData.ContainedItems
						local addFromCont = false

						for i = 1, numItems do
							local registItem = false
							local item = containedItems[ i ]
							local objectId = item.objectId
							local itemData = WindowData_ObjectInfo[ objectId ]
							if ( not itemData and objectId ) then
								RegisterWindowData( ObjectInfo_Type, objectId )
								itemData = WindowData_ObjectInfo[ objectId ]
								registItem = true
							end

							local added = setVacuumObject( itemData, objectId, id )
							addFromCont = addFromCont or added

							if ( registItem and not added ) then
								UnregisterWindowData( ObjectInfo_Type, objectId )
							end
						end
						closeContainerWin( id, addFromCont, containerData )
					end
				end
			end
		end

		if ( #Actions_VacuumObjects > 0 ) then
			-- Vacuum対象のアイテムがある。データチェック開始
			local objectId, itemData
			local table_remove = table.remove
			repeat
				local len = #Actions_VacuumObjects
				objectId = Actions_VacuumObjects[ len ]
				itemData = WindowData_ObjectInfo[ objectId ]
				table_remove( Actions_VacuumObjects, len )
				if ( not itemData ) then
					RegisterWindowData( ObjectInfo_Type, objectId )
					itemData = WindowData_ObjectInfo[ objectId ]
					if ( not itemData ) then
						if ( #Actions_VacuumObjects == 0 ) then
							return
						end
					else
						break
					end
				else
					break
				end
			until ( itemData )

			-- アイテムをドロップするbagがプレイヤーが保持している物か
			local organizeBagIsInBP
			if ( not ContainerWindow_OrganizeBag or ContainerWindow_OrganizeBag == 0 ) then
				ContainerWindow_OrganizeBag = ContainerWindow_PlayerBackpack
				organizeBagIsInBP = true
			else
				organizeBagIsInBP = IsInPlayerBackPack( ContainerWindow_OrganizeBag )
			end

			local quantity = itemData.quantity or 1
			local dropContainerId

			ContainerWindow.TimePassedSincePickUp = 0
			ContainerWindow.CanPickUp = false
			ObjectHandleWindow.lastItem = objectId

			if ( itemData.objectType == 3821 and organizeBagIsInBP and ClfSettings.EnableDropGoldToBP ) then
				-- オーガナイザーbagが自分のBP内にあり、アイテムがゴールドの時は第一階層にドロップする
				dropContainerId = MoveItemToContainer( objectId, quantity, ContainerWindow_PlayerBackpack )
			else
				dropContainerId = MoveItemToContainer( objectId, quantity, ContainerWindow_OrganizeBag )
			end

			if ( organizeBagIsInBP ) then
				local playersItemNum = Interface.BackPackItems and #Interface.BackPackItems or 0
				local EnableVacuumMsg = ClfSettings.EnableVacuumMsg
				if ( playersItemNum >= 125 ) then
					-- 持てるアイテム数を超えた： Vacuumを停止する
					Actions.MassOrganize = false
					Actions_VacuumObjects = {}
					if ( EnableVacuumMsg ) then
						WindowUtils.SendOverheadText( L"=== STOP Vacuum: ItemNum Limit ===" , 33, true )
					end
					return
				elseif ( EnableVacuumMsg or ClfSettings.EnableAbortVacuum ) then
					local playerWeight = WindowData.PlayerStatus.Weight
					local playerMaxWeight = WindowData.PlayerStatus.MaxWeight

					if ( playerWeight >= playerMaxWeight and ClfSettings.EnableAbortVacuum ) then
						-- 持ち運べる重量を超えた： Vacuumを停止する
						Actions.MassOrganize = false
						Actions_VacuumObjects = {}
						if ( EnableVacuumMsg ) then
							WindowUtils.SendOverheadText( L"=== STOP Vacuum: Weight Over ===" , 33, true )
						end
						return
					elseif ( EnableVacuumMsg and not DoesVacuumAlert ) then
						local isAlertItemNum = ( playersItemNum >= 110 )
						local isAlertWeight = ( playerWeight > playerMaxWeight * 0.88 )
						if ( isAlertItemNum or isAlertWeight ) then
							-- 間もなく重量 or アイテム数リミットの警告
							if ( isAlertItemNum ) then
								WindowUtils.SendOverheadText( L"=== Alert, ItemNum: " .. StringToWString( playersItemNum .. " / 125" ) .. L" ===" , 46, true )
							end
							if ( isAlertWeight ) then
								WindowUtils.SendOverheadText( L"=== Alert, Weight: " .. StringToWString( playerWeight .. " / " .. playerMaxWeight ) .. L" ===" , 46, true )
							end
							DoesVacuumAlert = true
						end
					end
				end
			end

			if ( dropContainerId == nil ) then
				-- ドラッグ出来ないアイテムだった（コンテナから離れた、誰かがドラッグした、etc.）
				ContainerWindow.CanPickUp = true
				local str = L"Can't Drag: "
				if ( itemData.name ) then
					str = str .. itemData.name
				else
					str = str .. L"ID:"  ..towstring( objectId )
				end
				WindowUtils.ChatPrint( str, SystemData.ChatLogFilters.SYSTEM )
				return
			end
		else
			-- Vacuum対象のアイテムが無くなったので終了
			Actions.MassOrganize = false
			if ( ClfSettings.EnableVacuumMsg ) then
				WindowUtils.SendOverheadText( L"=== END Vacuum ===" , 255, true )
			end
			return
		end

	end
end

