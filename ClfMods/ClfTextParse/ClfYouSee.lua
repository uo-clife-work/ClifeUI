
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfTextParse", "ClfYouSeeWindow.xml", "ClfYouSeeWindow.xml" )


ClfYouSee = {}


local GREY = { r = 190, g = 185, b = 188, }

local CONST = {
	YouSeeDefaultChannels = {
		-- Notoriety: Name Color
		[1]  = false,	-- Grey/None - Unknown Mobile
		[2]  = "CLF_YOU_SEE_BL",	-- Blue
		[3]  = "CLF_YOU_SEE_GN",	-- Green
		[4]  = "CLF_YOU_SEE",	-- Grey/CanAttack
		[5]  = "CLF_YOU_SEE",	-- Grey/Criminal
		[6]  = "CLF_YOU_SEE_OR",	-- Orange
		[7]  = "CLF_YOU_SEE_RD",	-- Red
		[8]  = "CLF_YOU_SEE_YL",	-- Yellow
		-- Otherwise
		[9]  = "CLF_YOU_SEE",	-- Neutral Animal
		[10] = "CLF_YOU_SEE_PP",	-- Summon
		[11] = "CLF_YOU_SEE_GN",	-- My Pet
		[12] = "CLF_YOU_SEE_BL",	-- Other's Pet
	},

	YouSeeFilterLabels = {
		{
			index = 2,
			label = GetStringFromTid(1154822),	-- L"Innocent",
			color = { r = 128, g = 200, b = 255 },
		},
		{
			index = 3,
			label = GetStringFromTid(1078866),	-- L"Friend",
			color = { r = 0 , g = 180, b = 0 },
		},
		{
			index = 4,
			label = GetStringFromTid(1154823) .. L": grey",	-- L"Attackable: Grey",
			color = GREY,
		},
		{
			index = 5,
			label = GetStringFromTid(1153802) .. L": grey",	-- L"Criminal: Grey",
			color = GREY,
		},
		{
			index = 6,
			label = GetStringFromTid(1095164), -- L"Enemy",
			color = { r = 242, g = 159, b = 77 },
		},
		{
			index = 7,
			label = GetStringFromTid(1154824), -- L"Murderer",
			color = { r = 255, g = 64,  b = 64 },
		},
		{
			index = 8,
			label = GetStringFromTid(3000509), -- L"Invulnerable",
			color = { r = 255, g = 255, b = 0 },
		},
		{
			index = 9,
			label = GetStringFromTid(1154825), -- L"Neutral Animals",
			color = GREY,
		},
		{
			index = 10,
			label = GetStringFromTid(1154826), -- L"Summons",
			color = { r = 220, g = 70,  b = 255 },
		},
		{
			index = 11,
			label = L"My Pet",
			color = { r = 0 , g = 180, b = 150 },
		},
		{
			index = 12,
			label = L"Other's Pet",
			color = { r = 128, g = 200, b = 255 },
		},
		{
			index = 1,
			label = L"Unknown: grey",
			color = { r = 255, g = 255, b = 255 },
		},
	},

	ComboMenues = {
		{
			key    = "CLF_YOU_SEE", -- ClfSettings.ExtChatFilters.CLF_YOU_SEE
			label  = L"You See",
		},
		{
			key    = "CLF_YOU_SEE_BL", -- ClfSettings.ExtChatFilters.CLF_YOU_SEE_BL
			label  = L"You See (blue)",
		},
		{
			key    = "CLF_YOU_SEE_GN", -- ClfSettings.ExtChatFilters.CLF_YOU_SEE_GN
			label  = L"You See (green)",
		},
		{
			key    = "CLF_YOU_SEE_RD", -- ClfSettings.ExtChatFilters.CLF_YOU_SEE_RD
			label  = L"You See (red)",
		},
		{
			key    = "CLF_YOU_SEE_OR", -- ClfSettings.ExtChatFilters.CLF_YOU_SEE_OR
			label  = L"You See (orange)",
		},
		{
			key    = "CLF_YOU_SEE_YL", -- ClfSettings.ExtChatFilters.CLF_YOU_SEE_YL
			label  = L"You See (yellow)",
		},
		{
			key    = "CLF_YOU_SEE_PP", -- ClfSettings.ExtChatFilters.CLF_YOU_SEE_PP
			label  = L"You See (purple)",
		},
		{
			key    = "SYSTEM", -- SystemData.ChatLogFilters.SYSTEM
			label  = L"System",
		},
		{
			key    = "SAY", -- SystemData.ChatLogFilters.SAY
			label  = L"Say",
		},
		{
			key    = "PRIVATE", -- SystemData.ChatLogFilters.PRIVATE
			label  = L"Private",
		},
		{
			key    = "EMOTE", -- SystemData.ChatLogFilters.EMOTE
			label  = L"Emote",
		},
		{
			key    = "GESTURE", -- SystemData.ChatLogFilters.GESTURE
			label  = L"Gesture",
		},
		{
			key    = "WHISPER", -- SystemData.ChatLogFilters.WHISPER
			label  = L"Wisper",
		},
		{
			key    = "YELL", -- SystemData.ChatLogFilters.YELL
			label  = L"Yell",
		},
		{
			key    = "PARTY", -- SystemData.ChatLogFilters.PARTY
			label  = L"Party",
		},
		{
			key    = "GUILD", -- SystemData.ChatLogFilters.GUILD
			label  = L"Guild",
		},
		{
			key    = "ALLIANCE", -- SystemData.ChatLogFilters.ALLIANCE
			label  = L"Alliance",
		},
	},

	NOTO_FARM = {
		[1] = true,	-- Grey/None
		[4] = true,	-- Grey/CanAttack
	},
	NOTO_SUMMON = {
		[1] = true,	-- Grey/None
		[2] = true,	-- Blue
		[3] = true,	-- Green
		[4] = true,	-- Grey/CanAttack
		[5] = true,	-- Grey/Criminal
		[7] = true,	-- Red
	},
}


-- You see: 表示：非表示フィルター
ClfYouSee.Filters = {
	-- Notoriety: Name Color
	[1]  = false,	-- Grey/None - Unknown Objects
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

-- You Seeを表示するか（全てのフィルターがfalseの時、falseになる）
ClfYouSee.Enable = true

-- You Seeの各フィルターで使用するチャットログフィルター（チャンネル）
ClfYouSee.Channels = {}


function ClfYouSee.initialize()
	ClfYouSee.setupFilters( nil, nil )
end


-- 各You seeのON/OFF、使用するチャットフィルターを設定
function ClfYouSee.setupFilters( filters, channelKeys )
	filters  = ( filters and type( filters ) == "table" ) and filters or {}
	channelKeys = ( channelKeys and type( channelKeys ) == "table" ) and channelKeys or {}
	local YouSeeFilters = ClfYouSee.Filters
	local YouSeeChannels = ClfYouSee.Channels

	local Interface = Interface
	local LoadBoolean = Interface.LoadBoolean
	local SaveBoolean = Interface.SaveBoolean
	local LoadNumber = Interface.LoadNumber

	local I_LoadString = Interface.LoadString
	local I_SaveString = Interface.SaveString

	local ClfSettings_ExtChatFilters  = ClfSettings.ExtChatFilters
	local SD_ChatLogFilters  = SystemData.ChatLogFilters
	local youSeeDefaultChannels  = CONST.YouSeeDefaultChannels

	-- 以前のVerの設定（保存したチャンネルのindex番号）をキー名に変換する（フォールバック用）： ある程度Verが進んだら処理をやめる（キー名を保存するように変更した）
	local convChNumToKey = function( idx )
		local saveChKey = "ClfYouSeeChannel_" .. idx
		local num =  LoadNumber( saveChKey, 0 )
		if ( num ~= 0 ) then
			Interface.DeleteSetting( saveChKey )
		end
		if ( num > 1 ) then
			for k, v in pairs( SD_ChatLogFilters ) do
				if ( v == num ) then
					return k
				end
			end
		end
		return nil
	end

	local enableYouSee = false
	for idx, enable in pairs( YouSeeFilters ) do
		-- You see ON/OFF
		local saveKey = "ClfYouSee_" .. idx
		local enabled
		if ( filters[ idx ] ~= nil ) then
			enabled = not not filters[ idx ]
		else
			enabled = LoadBoolean( saveKey, enable )
		end
		enableYouSee = enableYouSee or enabled

		if ( YouSeeFilters[ idx ] ~= enabled ) then
			SaveBoolean( saveKey, enabled )
		end
		YouSeeFilters[ idx ] = enabled

		-- Chat channel
		local channelKey
		local saveChKeyName = "ClfYouSeeChannelKey_" .. idx

		if ( type( channelKeys[ idx ] ) == "string" ) then
			channelKey = channelKeys[ idx ]
		else
			local defChKey = youSeeDefaultChannels[ idx ] or "SYSTEM"
			-- フォールバック
			channelKey = convChNumToKey( idx ) or I_LoadString( saveChKeyName, defChKey )
			-- /フォールバック

			-- channelKey = I_LoadString( saveChKeyName, "CLF_YOU_SEE" )
		end

		local channel = ClfSettings_ExtChatFilters[ channelKey ] or SD_ChatLogFilters[ channelKey ] or SD_ChatLogFilters.SYSTEM

		if ( YouSeeChannels[ idx ] ~= channel ) then
			I_SaveString( saveChKeyName, channelKey )
		end
		YouSeeChannels[ idx ] = channel
	end

	ClfYouSee.Enable = enableYouSee
end


-- mobileIdを元にチャットログに You see: *** を追加
function ClfYouSee.output( mobileId )
	if ( not ClfYouSee.Enable or OverheadText.LastSeeName[ mobileId ] ) then
		return
	end

	if ( mobileId == WindowData.PlayerStatus.PlayerId ) then
		OverheadText.LastSeeName[ mobileId ] = true
		return
	end

	-- Start You see:
	local mobileNameData = WindowData.MobileName[ mobileId ] or {}
	local mobileName = mobileNameData.MobName

	if ( not mobileName or mobileName == L"" ) then
		return
	end

	local YouSeeFilters = ClfYouSee.Filters
	local YouSeeChannels = ClfYouSee.Channels

	local noto = mobileNameData.Notoriety
	noto = noto and noto + 1
	local enable = YouSeeFilters[ noto ]
	local channel = YouSeeChannels[ noto ]
	local data = { mobileId = mobileId, noto = noto }

	if ( noto == 8 ) then
		-- Yellow
		if ( not enable ) then
			return
		end
		local lwrName = string.lower( tostring( mobileName ) )
		local string_match = string.match
		if ( string_match( lwrName, ".-%sthe parrot$" ) ) then
			return
		end
		if ( string_match( lwrName, "^%s+a mannequin%s+$" ) ) then
			return
		end
	else
		-- not Yellow
		local isWorkerMobile = ClfUtil.isWorkerMobile

		local isSummon = CONST.NOTO_SUMMON[ noto ] and ( MobilesOnScreen.IsSummon( mobileName, mobileId ) or isWorkerMobile( mobileId, 2 ) )

		if ( isSummon ) then
			-- Summons
			enable = YouSeeFilters[10]
			channel = YouSeeChannels[10]
			data.isSummon = true
		elseif ( IsObjectIdPet( mobileId ) ) then
			-- My Pet
			enable = YouSeeFilters[11]
			channel = YouSeeChannels[11]
			data.isPet = true
		elseif ( isWorkerMobile( mobileId, 1 ) ) then
			-- Other's Pets
			enable = YouSeeFilters[12]
			channel = YouSeeChannels[12]
			data.isWorker = true
		elseif ( CONST.NOTO_FARM[ noto ] and MobilesOnScreen.IsFarm( mobileName ) ) then
			-- Farm Animals
			enable = YouSeeFilters[9]
			channel = YouSeeChannels[9]
			data.isFarm = true
		end
	end

	channel = channel or SystemData.ChatLogFilters.SYSTEM
	OverheadText.LastSeeName[ mobileId ] = enable or nil
	ClfTextParse.printChat( L"You see: " .. mobileName, channel, enable, data )
end



--[[
----------------------------------------------------
---------- Setting Window function -----------------
----------------------------------------------------
]]


-- Window[name="ClfYouSeeFiltersWindow"].OnInitialize
function ClfYouSee.initFilterWin()
	local win = WindowUtils.GetActiveDialog()
	Interface.DestroyWindowOnClose[ win ] = true

	LabelSetText( win .. "Chrome_UO_TitleBar_WindowTitle", L"You See Filter" )
	ButtonSetText( win .. "AcceptButton", GetStringFromTid( 3000093 ) )
	ButtonSetText( win .. "ApplyButton", GetStringFromTid( 3000090 ) )

	LabelSetText( win .. "HeaderFilter", L"You See:" )
	LabelSetText( win .. "HeaderChannel", L"Chat Filter" )

	ClfYouSee.initFilterListWin()
end


-- フィルター項目の作成
function ClfYouSee.initFilterListWin()
	local win = "ClfYouSeeFiltersWindow"
	local btnWrap = win .."List"
	if ( not DoesWindowExist( btnWrap ) ) then
		return
	end

	local YouSeeFilters = ClfYouSee.Filters
	local YouSeeChannels = ClfYouSee.Channels
	local YouSeeFilterLabels = CONST.YouSeeFilterLabels
	local ComboMenues = CONST.ComboMenues
	local SD_ChatLogFilters = SystemData.ChatLogFilters
	local ClfSettings_ExtChatFilters = ClfSettings.ExtChatFilters

	local DoesWindowExist = DoesWindowExist
	local CreateWindowFromTemplate = CreateWindowFromTemplate
	local WindowClearAnchors = WindowClearAnchors
	local WindowAddAnchor = WindowAddAnchor
	local ButtonSetPressedFlag = ButtonSetPressedFlag
	local LabelSetText = LabelSetText
	local LabelSetTextColor = LabelSetTextColor
	local ComboBoxClearMenuItems = ComboBoxClearMenuItems
	local ComboBoxAddMenuItem = ComboBoxAddMenuItem
	local ComboBoxSetSelectedMenuItem = ComboBoxSetSelectedMenuItem
	local setupComboColor = ClfYouSee.setupComboColor

	local comboMenuesReverse = {}
	for i = 1, #ComboMenues do
		local obj = ComboMenues[ i ]
		local channel = ClfSettings_ExtChatFilters[ obj.key ] or SD_ChatLogFilters[ obj.key ]
		if ( channel ) then
			comboMenuesReverse[ channel ] = i
		end
	end

	for i = 1, #YouSeeFilterLabels do
		local filter = YouSeeFilterLabels[ i ]
		local idx = filter.index
		-- You see ON/OFF
		local btn = btnWrap .. "Btn_" .. idx
		if ( not DoesWindowExist( btn ) ) then
			CreateWindowFromTemplate( btn, "ClfTemplateYouSeeFilterRow", btnWrap )
			WindowSetId( btn, idx )
		end
		WindowClearAnchors( btn )
		WindowAddAnchor( btn, "topleft", btnWrap, "topleft", 0, i * 30 - 30 )

		local checkBox = btn .. "CheckBox"
		ButtonSetPressedFlag( checkBox, YouSeeFilters[ idx ] )

		local label = btn .. "FilterName"
		local color = filter.color
		LabelSetText( label, filter.label )
		LabelSetTextColor( label, color.r, color.g, color.b )

		-- Chat channel
		local comboRow = btnWrap .. "Combo_" .. idx
		if ( not DoesWindowExist( comboRow ) ) then
			CreateWindowFromTemplate( comboRow, "ClfTemplateYouSeeChannelRow", btnWrap )
			WindowSetId( comboRow, idx )
		end
		WindowClearAnchors( comboRow )
		WindowAddAnchor( comboRow, "right", btn, "left", 0, 0 )

		local combo = comboRow .. "Combo"

		ComboBoxClearMenuItems( combo )
		for j = 1, #ComboMenues do
			ComboBoxAddMenuItem( combo, ComboMenues[ j ].label )
		end

		local channel = YouSeeChannels[ idx ] or ClfSettings_ExtChatFilters.CLF_YOU_SEE or SD_ChatLogFilters.SYSTEM
		local index = comboMenuesReverse[ channel ] or 1
		ComboBoxSetSelectedMenuItem( combo, index )
		setupComboColor( comboRow )
	end

	WindowSetShowing( win, true )
end


-- Window[name="ClfYouSeeFiltersWindow"].OnShutdown
function ClfYouSee.shutdownFilterWin()
	local win = WindowUtils.GetActiveDialog()
	WindowUtils.SaveWindowPosition( win )
end


-- ListButton.OnLButtonUp
function ClfYouSee.onToggleYouseeFilter()
	local btn = SystemData.ActiveWindow.name
	local checkBox = btn .. "CheckBox"
	local enable = not ButtonGetPressedFlag( checkBox )
	ButtonSetPressedFlag( checkBox, enable )
end


-- Combo.OnSelChanged
function ClfYouSee.onComboChanged()
	local comboWin = WindowGetParent( SystemData.ActiveWindow.name )
	ClfYouSee.setupComboColor( comboWin )
end


-- フィルター文字色のサンプルを表示
function ClfYouSee.setupComboColor( comboWin )
	if ( not DoesWindowExist( comboWin ) ) then
		return
	end
	local combo = comboWin .. "Combo"
	local index = ComboBoxGetSelectedMenuItem( combo )
	local channelData = CONST.ComboMenues[ index ] or {}
	local channelId = SystemData.ChatLogFilters[ channelData.key ] or ClfSettings.ExtChatFilters[ channelData.key ] or SystemData.ChatLogFilters.SYSTEM
	local color = ChatSettings.ChannelColors[ channelId ] or ClfSettings.ExtChatFilterColors[ channelData.key ] or { r = 255, g = 255, b = 255, }

	WindowSetTintColor( comboWin .. "Image", color.r, color.g, color.b )
end


-- AcceptButton.OnLButtonUp
function ClfYouSee.onAcceptBtnLup()
	local win = ClfYouSee.submitYouSeeFilter()
	if ( win ) then
		DestroyWindow( win )
	end
end


-- ApplyButton.OnLButtonUp
function ClfYouSee.submitYouSeeFilter()
	local win = WindowGetParent( SystemData.ActiveWindow.name )
	local btnWrap = win .."List"
	if ( not DoesWindowExist( btnWrap ) ) then
		return
	end

	local filters = {}
	local channelKeys = {}

	local ComboMenues = CONST.ComboMenues
	local YouSeeFilterLabels = CONST.YouSeeFilterLabels
	local SD_ChatLogFilters = SystemData.ChatLogFilters

	local ButtonGetPressedFlag = ButtonGetPressedFlag
	local ComboBoxGetSelectedMenuItem = ComboBoxGetSelectedMenuItem

	for i = 1, #YouSeeFilterLabels do
		-- Filters
		local filter = YouSeeFilterLabels[ i ]
		local idx = filter.index
		local checkBox = btnWrap .. "Btn_" .. idx .. "CheckBox"
		local enable = ButtonGetPressedFlag( checkBox )
		filters[ idx ] = enable

		-- Channels
		local combo = btnWrap .. "Combo_" .. idx .. "Combo"
		local combIndex = ComboBoxGetSelectedMenuItem( combo )
		local channelData = ComboMenues[ combIndex ] or {}
--		local channelId = SD_ChatLogFilters[ channelData.idx ] or SD_ChatLogFilters.SYSTEM

		-- channelKeys
		channelKeys[ idx ] = channelData.key or "CLF_YOU_SEE"
	end

	ClfYouSee.setupFilters( filters, channelKeys )
	return win
end


