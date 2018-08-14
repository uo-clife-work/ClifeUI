
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfCommon", "ClfSettingsWindow.xml", "ClfSettingWindow.xml" )


ClfSettings = {}

-- Agentでゴールドをドロップする対象をBP第一階層にするか
ClfSettings.EnableDropGoldToBP = true

-- Vacuume終了時にコンテナを閉じるか
ClfSettings.EnableCloseContainerOnVacuum = true

-- 所持重量が持ち運べる重量を超えたらVacuumを停止するか
ClfSettings.EnableAbortVacuum = true

-- Vacuumeの停止時や、重量・アイテム数のアラートを頭上にメッセージ表示するか
ClfSettings.EnableVacuumMsg = true

-- オブハン表示時にフィールド上のアイテム全てを拾うか
ClfSettings.EnableScavengeAll = false


-- You see: 表示：非表示フィルター
ClfSettings.YouSeeFilters = {
	-- Notoriety: Name Color
	[1]  = false,	-- Grey/None - Unknown Mobile
	[2]  = false,	-- Blue
	[3]  = false,	-- Green
	[4]  = false,	-- Grey/CanAttack
	[5]  = false,	-- Grey/Criminal
	[6]  = false,	-- Orange
	[7]  = false,	-- Red
	[8]  = false,	-- Yellow
	-- Otherwise
	[9]  = false,	-- Neutral Animal
	[10] = false,	-- Summon
	[11] = false,	-- My Pet
	[12] = false,	-- Other's Pet
}
-- You Seeを表示するか（全てのフィルターがfalseならfalseにセットされる）
ClfSettings.EnableYouSee = true
-- You Seeの各フィルターで使用するチャットログフィルター（チャンネル）
ClfSettings.YouSeeChannels = {}


function ClfSettings.initialize()

	ClfSettings.EnableDropGoldToBP = Interface.LoadBoolean( "ClfDropGoldToBP", ClfSettings.EnableDropGoldToBP )

	ClfSettings.EnableCloseContainerOnVacuum = Interface.LoadBoolean( "ClfCloseContainerOnVacuum", ClfSettings.EnableCloseContainerOnVacuum )

	ClfSettings.EnableAbortVacuum = Interface.LoadBoolean( "ClfAbortVacuum", ClfSettings.EnableAbortVacuum )

	ClfSettings.EnableVacuumMsg = Interface.LoadBoolean( "ClfVacuumMsg", ClfSettings.EnableVacuumMsg )

	ClfSettings.EnableScavengeAll = Interface.LoadBoolean( "ClfScavengeAll", ClfSettings.EnableScavengeAll )

	ClfSettings.setupYouSeeFilter()
end



function ClfSettings.setupYouSeeFilter( filters, channels )
	filters  = ( filters and type( filters ) == "table" ) and filters or {}
	channels = ( channels and type( channels ) == "table" ) and channels or {}
	local YouSeeFilters = ClfSettings.YouSeeFilters
	local YouSeeChannels = ClfSettings.YouSeeChannels

	local LoadBoolean = Interface.LoadBoolean
	local SaveBoolean = Interface.SaveBoolean
	local LoadNumber = Interface.LoadNumber
	local SaveNumber = Interface.SaveNumber

	local enableYouSee = false
	for key, enable in pairs( YouSeeFilters ) do
		-- You see filter
		local saveKey = "ClfYouSee_" .. key
		local enabled
		if ( filters[ key ] ~= nil ) then
			enabled = not not filters[ key ]
		else
			enabled = LoadBoolean( saveKey, enable )
		end
		enableYouSee = enableYouSee or enabled

		if ( YouSeeFilters[ key ] ~= enabled ) then
			SaveBoolean( saveKey, enabled )
		end
		YouSeeFilters[ key ] = enabled

		-- You see channel
		local saveChKey = "ClfYouSeeChannel_" .. key
		local channel
		if ( channels[ key ] and tonumber( channels[ key ] ) ) then
			channel = channels[ key ]
		else
			channel = LoadNumber( saveChKey, 1 )
		end

		if ( YouSeeChannels[ key ] ~= channel ) then
			SaveNumber( saveChKey, channel )
		end
		YouSeeChannels[ key ] = channel
	end

	ClfSettings.EnableYouSee = enableYouSee
end


-- Agentでゴールドをドロップする対象をBP第一階層にするかを切り替え
function ClfSettings.toggleDropGoldToBP( silent )
	enable = not ClfSettings.EnableDropGoldToBP
	ClfSettings.EnableDropGoldToBP = enable
	Interface.SaveBoolean( "ClfDropGoldToBP", enable )

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
		WindowUtils.SendOverheadText( L"Drop Gold to BP: " .. str, hue, true )
	end
end


-- Agentでゴールドをドロップする対象をBP第一階層にするかを切り替え
function ClfSettings.toggleCloseContainerOnVacuum( silent )
	enable = not ClfSettings.EnableCloseContainerOnVacuum
	ClfSettings.EnableCloseContainerOnVacuum = enable
	Interface.SaveBoolean( "ClfCloseContainerOnVacuum", enable )

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
		WindowUtils.SendOverheadText( L"Close Container on Vacuum: " .. str, hue, true )
	end
end


-- 所持重量が持ち運べる重量を超えたらVacuumを停止するかを切り替え
function ClfSettings.toggleAbortVacuum( silent )
	enable = not ClfSettings.EnableAbortVacuum
	ClfSettings.EnableAbortVacuum = enable
	Interface.SaveBoolean( "ClfAbortVacuum", enable )

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
		WindowUtils.SendOverheadText( L"Abort Vacuum: " .. str, hue, true )
	end
end


-- Vacuumeの停止時や、重量・アイテム数のアラートを頭上にメッセージ表示するかを切り替え
function ClfSettings.toggleVacuumMsg( silent )
	enable = not ClfSettings.EnableVacuumMsg
	ClfSettings.EnableVacuumMsg = enable
	Interface.SaveBoolean( "ClfVacuumMsg", enable )

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
		WindowUtils.SendOverheadText( L"Vacuum Msg: " .. str, hue, true )
	end
end


-- オブハン表示時にフィールド上のアイテム全てを拾うかを切り替え
function ClfSettings.toggleScavengeAll( silent )
	enable = not ClfSettings.EnableScavengeAll
	ClfSettings.EnableScavengeAll = enable
	Interface.SaveBoolean( "ClfScavengeAll", enable )

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
		WindowUtils.SendOverheadText( L"Scavenge All: " .. str, hue, true )
	end
end


