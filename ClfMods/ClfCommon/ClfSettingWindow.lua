

ClfSettingWindow = {}



local GRAY = { r = 200, g = 200, b = 200, }

local CONST = {
	YouSeeFilterLabels = {
		{
			key = 2,
			label = GetStringFromTid(1154822),	-- L"Innocent",
			color = { r = 128, g = 200, b = 255 },
		},
		{
			key = 3,
			label = GetStringFromTid(1078866),	-- L"Friend",
			color = { r = 0 , g = 180, b = 0 },
		},
		{
			key = 4,
			label = GetStringFromTid(1154823) .. L": grey",	-- L"Attackable: Grey",
			color = GRAY,
		},
		{
			key = 5,
			label = GetStringFromTid(1153802) .. L": grey",	-- L"Criminal: Grey",
			color = GRAY,
		},
		{
			key = 6,
			label = GetStringFromTid(1095164), -- L"Enemy",
			color = { r = 242, g = 159, b = 77 },
		},
		{
			key = 7,
			label = GetStringFromTid(1154824), -- L"Murderer",
			color = { r = 255, g = 64,  b = 64 },
		},
		{
			key = 8,
			label = GetStringFromTid(3000509), -- L"Invulnerable",
			color = { r = 255, g = 255, b = 0 },
		},
		{
			key = 9,
			label = GetStringFromTid(1154825), -- L"Neutral Animals",
			color = GRAY,
		},
		{
			key = 10,
			label = GetStringFromTid(1154826), -- L"Summons",
			color = { r = 200, g = 60,  b = 255 },
		},
		{
			key = 11,
			label = L"My Pet",
			color = { r = 0 , g = 180, b = 150 },
		},
		{
			key = 12,
			label = L"Other's Pet",
			color = { r = 128, g = 200, b = 255 },
		},
		{
			key = 1,
			label = L"Unknown: grey",
			color = { r = 255, g = 255, b = 255 },
		},
	},

	ComboMenues = {
		{
			label = L"System", -- SystemData.ChatLogFilters.SYSTEM
			key = "SYSTEM",
		},
		{
			label = L"Say", -- SystemData.ChatLogFilters.SAY
			key = "SAY",
		},
		{
			label = L"Private", -- SystemData.ChatLogFilters.PRIVATE
			key = "PRIVATE",
		},
		{
			label = L"Emote", -- SystemData.ChatLogFilters.EMOTE
			key = "EMOTE",
		},
		{
			label = L"Gesture", -- SystemData.ChatLogFilters.GESTURE
			key = "GESTURE",
		},
		{
			label = L"Wisper", -- SystemData.ChatLogFilters.WHISPER
			key = "WHISPER",
		},
		{
			label = L"Yell", -- SystemData.ChatLogFilters.YELL
			key = "YELL",
		},
		{
			label = L"Party", -- SystemData.ChatLogFilters.PARTY
			key = "PARTY",
		},
		{
			label = L"Guild", -- SystemData.ChatLogFilters.GUILD
			key = "GUILD",
		},
		{
			label = L"Alliance", -- SystemData.ChatLogFilters.ALLIANCE
			key = "ALLIANCE",
		},
	},

}


-- You see:設定ウィンドウを表示
function ClfSettingWindow.showYouSeeFilters()
	local win = "ClfYouSeeFiltersWindow"
	if ( DoesWindowExist( win ) ) then
		WindowSetShowing( win, true )
	else
		CreateWindow( win, false )
	end

	WindowUtils.RestoreWindowPosition( win )
end


-- Window[name="ClfYouSeeFiltersWindow"].OnInitialize
function ClfSettingWindow.initYouSeeFilterWin()
	local win = WindowUtils.GetActiveDialog()
	Interface.DestroyWindowOnClose[ win ] = true

	LabelSetText( win .. "Chrome_UO_TitleBar_WindowTitle", L"You See Filter" )
	ButtonSetText( win .. "AcceptButton", GetStringFromTid( 3000093 ) )

	LabelSetText( win .. "HeaderFilter", L"You See:" )
	LabelSetText( win .. "HeaderChannel", L"Chat Filter" )

	ClfSettingWindow.initYouSeeFilterList()
end


-- You seeフィルター項目の作成
function ClfSettingWindow.initYouSeeFilterList()
	local win = "ClfYouSeeFiltersWindow"
	local btnWrap = win .."List"
	if ( not DoesWindowExist( btnWrap ) ) then
		return
	end

	local YouSeeFilters = ClfSettings.YouSeeFilters
	local YouSeeChannels = ClfSettings.YouSeeChannels
	local YouSeeFilterLabels = CONST.YouSeeFilterLabels
	local ComboMenues = CONST.ComboMenues

	local DoesWindowExist = DoesWindowExist
	local CreateWindowFromTemplate = CreateWindowFromTemplate
	local WindowClearAnchors = WindowClearAnchors
	local WindowAddAnchor = WindowAddAnchor
	local ButtonSetPressedFlag = ButtonSetPressedFlag
	local LabelSetText = LabelSetText
	local LabelSetTextColor = LabelSetTextColor
	local setupComboColor = ClfSettingWindow.setupComboColor

	local ChatLogFilters = SystemData.ChatLogFilters
	local systemFilter = ChatLogFilters.SYSTEM

	local comboMenuesReverse = {}
	for i = 1, #ComboMenues do
		local obj = ComboMenues[ i ]
		local key = ChatLogFilters[ obj.key ]
		if ( key ) then
			comboMenuesReverse[ key ] = i
		end
	end

	for i = 1, #YouSeeFilterLabels do
		local filter = YouSeeFilterLabels[ i ]
		local key = filter.key
		local btn = btnWrap .. "Btn_" .. key
		if ( not DoesWindowExist( btn ) ) then
			CreateWindowFromTemplate( btn, "ClfTemplateYouSeeFilterRow", btnWrap )
			WindowSetId( btn, key )
		end
		WindowClearAnchors( btn )
		WindowAddAnchor( btn, "topleft", btnWrap, "topleft", 0, i * 30 - 30 )

		local checkBox = btn .. "CheckBox"
		ButtonSetPressedFlag( checkBox, YouSeeFilters[ key ] )

		local label = btn .. "FilterName"
		local color = filter.color
		LabelSetText( label, filter.label )
		LabelSetTextColor( label, color.r, color.g, color.b )

		local comboRow = win .. "Combo_" .. key
		if ( not DoesWindowExist( comboRow ) ) then
			CreateWindowFromTemplate( comboRow, "ClfTemplateClfTemplateYouSeeChannelComboRow", btnWrap )
			WindowSetId( comboRow, key )
		end
		WindowClearAnchors( comboRow )
		WindowAddAnchor( comboRow, "right", btn, "left", 0, 0 )

		local combo = comboRow .. "Combo"

		ComboBoxClearMenuItems( combo )
		for j = 1, #ComboMenues do
			ComboBoxAddMenuItem( combo, ComboMenues[ j ].label )
		end

		local combo = win .. "Combo_" .. key .. "Combo"
		local channel = YouSeeChannels[ key ] or systemFilter
		local index = comboMenuesReverse[ channel ] or 1
		ComboBoxSetSelectedMenuItem( combo, index )
		setupComboColor( comboRow )
	end

	WindowSetShowing( win, true )
end


-- Window[name="ClfYouSeeFiltersWindow"].OnShutdown
function ClfSettingWindow.shutdownYouSeeFilterWin()
	local win = WindowUtils.GetActiveDialog()
	WindowUtils.SaveWindowPosition( win )
end


-- Button.OnLButtonUp
function ClfSettingWindow.onToggleYouseeFilter()
	local btn = SystemData.ActiveWindow.name
	local checkBox = btn .. "CheckBox"
	local enable = not ButtonGetPressedFlag( checkBox )
	ButtonSetPressedFlag( checkBox, enable )
end


-- Combo.OnSelChanged
function ClfSettingWindow.onComboChangedYouSeeChannel()
	local comboWin = WindowGetParent( SystemData.ActiveWindow.name )
	ClfSettingWindow.setupComboColor( comboWin )
end


-- You seeフィルター 文字色の表示
function ClfSettingWindow.setupComboColor( comboWin )
	if ( not DoesWindowExist( comboWin ) ) then
		return
	end
	local combo = comboWin .. "Combo"
	local index = ComboBoxGetSelectedMenuItem( combo )
	local channelData = CONST.ComboMenues[ index ] or {}
	local channelId = SystemData.ChatLogFilters[ channelData.key ] or SystemData.ChatLogFilters.SYSTEM
	local color = ChatSettings.ChannelColors[ channelId ] or { r = 255, g = 255, b = 255, }
	local img = WindowGetParent( combo ) .. "Image"

	WindowSetTintColor( img, color.r, color.g, color.b )
end


-- AcceptButton.OnLButtonUp
function ClfSettingWindow.submitYouSeeFilter()
	local win = "ClfYouSeeFiltersWindow"
	local btnWrap = win .."List"
	if ( not DoesWindowExist( btnWrap ) ) then
		return
	end

	local filters = {}
	local channels = {}

	local ComboMenues = CONST.ComboMenues
	local ChatLogFilters = SystemData.ChatLogFilters

	local ButtonGetPressedFlag = ButtonGetPressedFlag
	local ComboBoxGetSelectedMenuItem = ComboBoxGetSelectedMenuItem

	local YouSeeFilterLabels = CONST.YouSeeFilterLabels
	for i = 1, #YouSeeFilterLabels do
		-- Filters
		local filter = YouSeeFilterLabels[ i ]
		local key = filter.key
		local checkBox = btnWrap .. "Btn_" .. key .. "CheckBox"
		local enable = ButtonGetPressedFlag( checkBox )
		filters[ key ] = enable

		-- Channels
		local combo = win .. "Combo_" .. key .. "Combo"
		local combIndex = ComboBoxGetSelectedMenuItem( combo )
		local channelData = ComboMenues[ combIndex ] or {}
		local channelId = ChatLogFilters[ channelData.key ] or ChatLogFilters.SYSTEM
		channels[ key ] = channelId
	end

	ClfSettings.setupYouSeeFilter( filters, channels )
	DestroyWindow( win )
end

