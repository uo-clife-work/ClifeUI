
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

-- 自動リストックの停止時や、重量・アイテム数のアラートを頭上にメッセージ表示するか
ClfSettings.EnableRestockMsg = true

-- ユーザー設定に保存されるコンテナのスクロール位置情報を自動で削除するか
ClfSettings.EnableCleanContScroll = false

-- 追加するチャットフィルターを、 [フィルター名] = id番号 として保持するテーブル
-- * 追加するフィルター名は CONST.ExtChatFilterKeys で定義しておく
ClfSettings.ExtChatFilters = {
	-- // ClfSettings.initExtChatFilterKeys() で SystemData.ChatLogFilters に設定されているindex以降を割り当て
	-- e.g. CLF_YOU_SEE = 17, ...
}

-- 追加するチャットフィルターの文字色： 初期値は CONST.ExtChatFilterVars[ {key} ].color
ClfSettings.ExtChatFilterColors = {
	-- // ClfSettings.initExtChatFilterKeys() で ClfSettings.ExtChatFilters と同時に定義する
	-- e.g. CLF_YOU_SEE    = { r = 190, g = 185, b = 188, }, ...
}


local CONST = {
	-- 追加するチャットフィルターのキー
	ExtChatFilterKeys = {
		"CLF_YOU_SEE",
		"CLF_YOU_SEE_BL",
		"CLF_YOU_SEE_GN",
		"CLF_YOU_SEE_RD",
		"CLF_YOU_SEE_OR",
		"CLF_YOU_SEE_YL",
		"CLF_YOU_SEE_PP",
		"CLF_DAMAGE",
		"CLF_DAMAGE_SELF",
		"CLF_DAMAGE_PET",
	},

	ExtChatFilterVars = {
		CLF_YOU_SEE     = {
			color  = { r = 190, g = 185, b = 188, },	-- フィルターのデフォルト文字色
			name   =  L"You see",	-- フィルターの表示名
			always = false,
		},
		CLF_YOU_SEE_BL  = {
			color  = { r = 128, g = 200, b = 255, },
			name   =  L"You see (blue)",
			always = false,
		},
		CLF_YOU_SEE_GN  = {
			color  = { r =   0 ,g = 180, b =   0, },
			name   = L"You see (green)",
			always = false,
		},
		CLF_YOU_SEE_RD  = {
			color  = { r = 255, g =  64, b =  64, },
			name   = L"You see (red)",
			always = false,
		},
		CLF_YOU_SEE_OR  = {
			color  = { r = 242, g = 159, b =  77, },
			name   = L"You see (orange)",
			always = false,
		},
		CLF_YOU_SEE_YL  = {
			color  = { r = 255, g = 255, b =   0, },
			name   = L"You see (yellow)",
			always = false,
		},
		CLF_YOU_SEE_PP  = {
			color  = { r = 220, g =  70, b = 255, },
			name   = L"You see (purple)",
			always = false,
		},
		CLF_DAMAGE      = {
			color  = { r = 255, g = 255, b =   0, },
			name   = L"Damage",
			always = false,
		},
		CLF_DAMAGE_SELF = {
			color  = { r = 255, g =   0, b =   0, },
			name   = L"Damage (self)",
			always = false,
		},
		CLF_DAMAGE_PET  = {
			color  = { r = 255, g =  80, b =   255, },
			name   = L"Damage (pet)",
			always = false,
		},
	},
}


function ClfSettings.initialize()
	local LoadBoolean = Interface.LoadBoolean
	local ClfSettings = ClfSettings

	ClfSettings.initExtChatFilterKeys()

	ClfSettings.EnableDropGoldToBP = LoadBoolean( "ClfDropGoldToBP", ClfSettings.EnableDropGoldToBP )
	ClfSettings.EnableCloseContainerOnVacuum = LoadBoolean( "ClfCloseContainerOnVacuum", ClfSettings.EnableCloseContainerOnVacuum )
	ClfSettings.EnableAbortVacuum = LoadBoolean( "ClfAbortVacuum", ClfSettings.EnableAbortVacuum )
	ClfSettings.EnableVacuumMsg = LoadBoolean( "ClfVacuumMsg", ClfSettings.EnableVacuumMsg )
	ClfSettings.EnableScavengeAll = LoadBoolean( "ClfScavengeAll", ClfSettings.EnableScavengeAll )
	ClfSettings.EnableRestockMsg = LoadBoolean( "ClfRestockMsg", ClfSettings.EnableRestockMsg )
	ClfSettings.EnableCleanContScroll = LoadBoolean( "ClfCleanContSc", ClfSettings.EnableCleanContScroll )
end


-- チャットチャンネルを追加、文字色を定義する
-- システムで用意されるチャンネルが増えた時に対応出来る様に、追加するキーにシステムのindex番号以降を割り当てる処理
function ClfSettings.initExtChatFilterKeys()
	local ChatLogFilters = SystemData.ChatLogFilters
	-- // MEMO: TextParsing.ColorizeText で ( SystemData.TextChannelID == 16 ) の条件判定で「独り言：」に割り当てられている
	-- // 余裕を持たせ、最低を 20 としておく
	local maxChannel = 20
	local math_max = math.max
	for key, channel in pairs( ChatLogFilters ) do
		maxChannel = math_max( maxChannel, channel )
	end

	ClfSettings.ExtChatFilters = {}
	ClfSettings.ExtChatFilterColors = ClfSettings.ExtChatFilterColors or {}
	local ClfS_ExtChatFilters = ClfSettings.ExtChatFilters
	local ClfS_ExtChatFilterColors = ClfSettings.ExtChatFilterColors
	local CS_ChannelColors = ChatSettings and ChatSettings.ChannelColors or {}
	local ExtChatFilterKeys = CONST.ExtChatFilterKeys
	local ExtChatFilterVars = CONST.ExtChatFilterVars
	local GREY = { r = 200, g = 200, b = 200, }

	for i = 1, #ExtChatFilterKeys do
		local key = ExtChatFilterKeys[ i ]
		local idx = maxChannel + i
		local OPT = ExtChatFilterVars[ key ] or {}
		ClfS_ExtChatFilters[ key ] = idx

		ClfS_ExtChatFilterColors[ key ] = CS_ChannelColors[ idx ] or ClfS_ExtChatFilterColors[ key ] or OPT.color or GREY
		-- SystemData.ChatLogFilters[ key ] = idx
	end

	if (
			ChatOptionsWindow and ChatSettings and ChatWindow
			and ChatSettings.ChannelColors and ChatWindow.Windows
			and #ChatSettings.ChannelColors > 0 and #ChatWindow.Windows > 0
		) then
		ClfSettings.setupExtChatChannelColor()
	else
		ClfCommon.addCheckListener( "addExtChatChannelColor", {
				check  = function()
					return (
						ChatOptionsWindow and ChatSettings and ChatWindow
						and ChatSettings.ChannelColors and ChatWindow.Windows
						and #ChatSettings.ChannelColors > 0 and #ChatWindow.Windows > 0
					)
				end,
				done   = ClfSettings.setupExtChatChannelColor,
				begin  = false,
				limit  = ClfCommon.TimeSinceLogin + 100,
			} )
	end
end


-- 追加したチャンネルをログ画面等に反映させる
function ClfSettings.setupExtChatChannelColor()

	local ChatSettings = ChatSettings
	local ChatWindow = ChatWindow
	local ClfS_ExtChatFilterColors = ClfSettings.ExtChatFilterColors
	local ClfS_ExtChatFilters = ClfSettings.ExtChatFilters
	local CS_ChannelColors = ChatSettings.ChannelColors
	local CS_Ordering = ChatSettings.Ordering
	local CW_Windows = ChatWindow.Windows
	local CW_S_Chat = ChatWindow.Settings.Chat
	local CW_S_Chat_Windows = CW_S_Chat.Windows

	local ExtChatFilterKeys = CONST.ExtChatFilterKeys
	local ExtChatFilterVars = CONST.ExtChatFilterVars

	local pairs = pairs
	local TextLogAddFilterType = TextLogAddFilterType
	local LogDisplaySetFilterColor = LogDisplaySetFilterColor
	local LogDisplaySetFilterState = LogDisplaySetFilterState
	local mergeTable = ClfUtil.mergeTable

	-- // 下2行をコメントアウトすると SYSTEMフィルターの設定が出来る様になる（OFFにしても再ログインでONに戻ってしまうけど、文字色は保持される）
	-- ChatSettings.Channels[ SystemData.ChatLogFilters.SYSTEM ].isOnAlways = false
	-- table.insert( ChatSettings.Ordering, SystemData.ChatLogFilters.SYSTEM, 1 )

	local GREY = { r = 200, g = 200, b = 200, }
	local DEFAULT_DATA = {
		-- id  = 1,
		-- name  = "System",
		logName      = "Chat",
		defaultColor = GREY,
		isOnAlways   = false,
		isOnChat     = true,
		isOnJournal  = true,
	}

	for i = 1, #ExtChatFilterKeys do
		local channelKey = ExtChatFilterKeys[ i ]
		local OPT = ExtChatFilterVars[ channelKey ]
		if ( OPT == nil ) then
			continue
		end
		local channelId =  ClfS_ExtChatFilters[ channelKey ]
		local channelData = mergeTable( {}, DEFAULT_DATA, {
				id = channelId,
				name = OPT.name or L"(not set)",
				logName = OPT.logName,
				isOnAlways = not not OPT.always,
			} )
		ChatSettings.Channels[ channelId ] = channelData
		if ( not OPT.always ) then
			CS_Ordering[ #CS_Ordering + 1 ] = channelId
		end

		-- チャットログに、追加したフィルターIDを反映させる
		local logName = channelData.logName
		TextLogAddFilterType( logName, channelId, L"" )
		-- チャットログ画面の各タブに、追加したフィルターの文字色を定義
		local color = CS_ChannelColors[ channelId ] or ClfS_ExtChatFilterColors[ channelKey ] or GREY
		local r, g, b = color.r, color.g, color.b
		for _, wnd in pairs( CW_Windows ) do
			for _, tab in pairs( wnd.Tabs ) do
				LogDisplaySetFilterColor( tab.tabWindow, logName, channelId, r, g, b )
			end
		end

		CS_ChannelColors[ channelId ] = color
		ClfS_ExtChatFilterColors[ channelKey ] = color

		-- SavedVariablesに保存されたフィルター状態をチャットログ画面の各タブに反映させる
		-- ※ 他のUIに切り替えると設定が消えてしまうので、その場合はONにする。とりあえずそういう仕様ということで。。。
		for savedWndIdx, savedWnd in pairs( CW_S_Chat_Windows ) do
			if ( savedWndIdx > CW_S_Chat.numWindows ) then
				continue
			end
			local winName = savedWnd.windowName

			for savedTabIdx, savedTab in pairs( savedWnd.Tabs ) do
				if ( savedTabIdx > savedWnd.numTabs ) then
					continue
				end
				local savedFilter = savedTab.Filters and savedTab.Filters[ channelId ]
				local enabled = channelData.isOnAlways or ( savedFilter == nil ) or savedFilter
				LogDisplaySetFilterState( winName .. "ChatLogDisplay", logName, channelId, enabled )
			end
		end
	end

	-- チャットフィルター設定画面に反映させる
	if ( DoesWindowExist( "ChatFiltersWindow" ) ) then
		local show = WindowGetShowing( "ChatFiltersWindow" )
		local x, y = WindowGetDimensions( "ChatFiltersWindow" )
		DestroyWindow( "ChatFiltersWindow" )
		CreateWindow( "ChatFiltersWindow", show )
		local rows = #ChatSettings.Ordering - 1
		y = math.max( y, 135 + rows * 28 )
		ListBoxSetVisibleRowCount( "ChatFiltersWindowList", rows )
		WindowSetDimensions( "ChatFiltersWindow", x, y )
	end

	-- チャットフィルター文字色設定画面に反映させる
	ChatOptionsWindow.UpdateChatOptionRow = function()
		if ( ChatOptionsWindowList.PopulatorIndices ~= nil ) then
			local activeWin = ChatWindow.Windows[ ChatWindow.activeWindow ].Tabs[1].tabWindow
			local COW_SpeechHueIndex = ChatOptionsWindow.SpeechHueIndex
			local COW_channelListData = ChatOptionsWindow.channelListData
			local LogDisplayGetFilterColor = LogDisplayGetFilterColor
			local LabelSetTextColor = LabelSetTextColor
			local tab = ChatWindow.GetMenuTab()
			for rowIndex, dataIndex in pairs( ChatOptionsWindowList.PopulatorIndices ) do
				local r,g,b
				local labelName = "ChatOptionsWindowListRow" .. rowIndex .. "ChannelName"
				if( dataIndex == COW_SpeechHueIndex ) then
					-- 標準UIでは rowIndexと比較しているが、dataIndexと比較しないと意味が無いので条件判定を修正
					r, g, b = HueRGBAValue( SystemData.Settings.Interface.SpeechHue )
				else
					local listData = COW_channelListData[ dataIndex ]
					r, g, b = LogDisplayGetFilterColor( activeWin, listData.logName, listData.channelID )
				end
				LabelSetTextColor( labelName, r, g, b )
			end
		end
	end

	-- 自分の発言色の分があるので、文字色の設定項目数はチャンネル数 +1 になる
	local listNum = ClfUtil.tableElemn( ChatSettings.Channels ) + 1
	ChatOptionsWindow.SpeechHueIndex = listNum

	if ( DoesWindowExist( "ChatOptionsWindow" ) ) then
		local show = WindowGetShowing( "ChatOptionsWindow" )
		local x, y = WindowGetDimensions( "ChatOptionsWindow" )
		y = math.max( y, 140 + listNum * 28 )
		DestroyWindow( "ChatOptionsWindow" )
		CreateWindow( "ChatOptionsWindow", show )
		WindowSetDimensions( "ChatOptionsWindow", x, y )
		ChatOptionsWindow.SpeechHueIndex = listNum
		ListBoxSetVisibleRowCount( "ChatOptionsWindowList", listNum )
	end

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


-- 自動リストックの完了・停止時に頭上メッセージ表示するかを切り替え
function ClfSettings.toggleRestockMsg( silent )
	enable = not ClfSettings.EnableRestockMsg
	ClfSettings.EnableRestockMsg = enable
	Interface.SaveBoolean( "ClfRestockMsg", enable )

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
		WindowUtils.SendOverheadText( L"Restoc Msg: " .. str, hue, true )
	end
end


-- コンテナのスクロール位置情報を自動で削除するかを切り替え
function ClfSettings.toggleCleanContScroll( silent )
	enable = not ClfSettings.EnableCleanContScroll
	ClfSettings.EnableCleanContScroll = enable
	Interface.SaveBoolean( "ClfCleanContSc", enable )

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
		WindowUtils.SendOverheadText( L"Clean Container scroll data: " .. str, hue, true )
	end
end


