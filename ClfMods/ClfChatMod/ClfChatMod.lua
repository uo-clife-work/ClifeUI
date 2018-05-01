LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfChatMod", "ClfChatMod.xml", "ClfChatMod.xml" )

ClfChat = {}
ClfChat.GChatWinName = "ClfGChatWindow"
ClfChat.GChatEnable = false


function ClfChat.initialize()
	local enable = Interface.LoadBoolean( "ClfGChatEnable", ClfChat.GChatEnable )
	local onOffStr = enable and L"ON" or L"OFF"
	Debug.PrintToChat( L"ClfChat: " .. onOffStr )

	ClfChat.setGChatWinEnable( enable )
end


-- Window表示の切り替え
function ClfChat.toggle()
	ClfChat.setGChatWinEnable( not ClfChat.GChatEnable )
end


function ClfChat.setGChatWinEnable( enable )
	ClfChat.GChatEnable = enable
	Interface.SaveBoolean( "ClfGChatEnable", enable )

	local window = ClfChat.GChatWinName

	if ( enable ) then
		if ( not DoesWindowExist( window ) ) then
			CreateWindow( window, true )
			WindowUtils.RestoreWindowPosition( window )
		end
	elseif ( DoesWindowExist( window ) ) then
		DestroyWindow( window )
	end
end


-- ** EventHandle: ClfActionsWindow OnInitialize
function ClfChat.onGChatWinInitialize()
	local window = ClfChat.GChatWinName

--	WindowRegisterEventHandler( window, SystemData.Events.GHAT_ROSTER_UPDATE, "ClfChat.onGChatRosterUpdate")
	WindowRegisterEventHandler( window, SystemData.Events.GHAT_MY_PRESENCE_UPDATE, "ClfChat.onGChatPresenceUpdate")
	WindowRegisterEventHandler( window, SystemData.Events.GHAT_PRESENCE_UPDATE, "ClfChat.onUpdateFriendPresence")
	WindowRegisterEventHandler( window, SystemData.Events.TEXT_ARRIVED, "ClfChat.onTextAlive" )

	ClfChat.setBtnFlasg()
	ClfChat.setActiveFriendCount()
	ClfChat.setLastMsg( true )
end


-- ** EventHandle: SystemData.Events.GHAT_ROSTER_UPDATE
--function ClfChat.onGChatRosterUpdate()
--	Debug.PrintToChat( L"---- ClfChat.onGChatRosterUpdate ----" )
--	ClfChat.setLastMsg()
--end


-- ** EventHandle: SystemData.Events.GHAT_MY_PRESENCE_UPDATE
function ClfChat.onGChatPresenceUpdate()
	ClfChat.setBtnFlasg()
end


-- ** EventHandle: SystemData.Events.GHAT_PRESENCE_UPDATE
function ClfChat.onUpdateFriendPresence()
	ClfChat.setActiveFriendCount()
end


-- ** EventHandle: ClfActionsWindow OnShutdown
function ClfChat.onGChatWinShutdown()
	WindowUtils.SaveWindowPosition( ClfChat.GChatWinName )
end



ClfChat.GChatDatas = {}

-- ** EventHandle: SystemData.Events.TEXT_ARRIVED
function ClfChat.onTextAlive()
	if ( SystemData.TextChannelID == SystemData.ChatLogFilters.GLOBAL_CHAT ) then
		local SourceName = SystemData.SourceName
		if ( "wstring" == type( SourceName ) and wstring.len( SourceName ) > 0 ) then
			if ( not wstring.find( SourceName, L"->", 2, true ) ) then
				local Clock = Interface.Clock
				time = towstring( Clock.h ) .. L":" .. wstring.format( L"%02d", Clock.m )
				local data = {
					time = time,
					name = SystemData.SourceName,
					text = SystemData.Text,
				}
				ClfChat.GChatDatas[ #ClfChat.GChatDatas + 1 ] = data
				ClfChat.setLastMsg( false )
			end
		end
	end
end


-- 最新のメッセージを表示
function ClfChat.setLastMsg( clearMsg )
	local window = ClfChat.GChatWinName
	local nameLabel = window .. "FrName"
	local msgLabel = window .. "Msg"
	local name = L"---"
	local msg = L""
	local datas = ClfChat.GChatDatas

	if ( not clearMsg and datas and #datas > 0 ) then
		local data = datas[ #datas ]
		msg = data.text or msg
		if ( data.text and data.time ) then
			msg = L"[" .. data.time .. L"]" .. data.text
		end
		name = data.name or name
	end

	LabelSetText( nameLabel, name )
	LabelSetText( msgLabel, msg )
end


-- 自分の状態をボタン表示に反映する
function ClfChat.setBtnFlasg()
	local win = ClfChat.GChatWinName
	local btn = win .. "Btn"
	local btnBg = win .. "BtnBG"
	if ( WindowData.GChatMyPresence == WindowData.GChat.GC_SHOW_CHAT ) then
		-- OnLine
		ButtonSetText( btn, L"Online" )
		WindowSetTintColor( btnBg, 100, 150, 215 )
	else
		-- OffLine
		ButtonSetText( btn, L"Offline" )
		WindowSetTintColor( btnBg, 112, 112, 126 )
	end
end


ClfChat.ActiveFriendNum = nil
ClfChat.ActiveFriendNames = {}

-- オンラインのフレンド数をカウントして表示
function ClfChat.setActiveFriendCount()
	local presenceList = WindowData.GChatPresenceList
	local nameList = WindowData.GChatNameList
	local num = 0
	local active = WindowData.GChat.GC_SHOW_CHAT
	ClfChat.ActiveFriendNames = {}
	for i = 1, #presenceList do
		if ( active == presenceList[ i ] ) then
			num = num + 1
			ClfChat.ActiveFriendNames[ #ClfChat.ActiveFriendNames + 1 ] = nameList[ i ]
		end
	end

	if ( num ~= ClfChat.ActiveFriendNum ) then
		ClfChat.ActiveFriendNum = num
		local win = ClfChat.GChatWinName .. "FrActNum"
		WindowStartAlphaAnimation( win, Window.AnimationType.SINGLE, 0, 1, 0.5, true, 0.1, 0 )
		LabelSetText( win, towstring( num ) )
		if ( num > 0 ) then
			LabelSetTextColor( win, 100, 150, 215 )
		else
			LabelSetTextColor( win, 112, 112, 126 )
		end
	end
end


-- ** EventHandle: ClfGChatWindow OnLButtonDblClk
-- グローバルチャットウィンドウを表示
function ClfChat.onGChatWinDblClick()
	local win = "GChatRoster"
	if( not DoesWindowExist( win ) ) then
		CreateWindow( win, true )
		WindowUtils.RestoreWindowPosition( win )
	end
end

-- ** EventHandle: ClfGChatWindow OnRButtonUp
-- 最新メッセージの表示をクリア
function ClfChat.onGChatWinRbtnUp()
	ClfChat.setLastMsg( true )
end


-- ** EventHandle: ClfGChatWindowBtn OnLButtonUp
-- GChatオンライン・オフライン切り替え
function ClfChat.onStatusBtn()
	BroadcastEvent( SystemData.Events.TOGGLE_GLOBAL_CHAT_PRESENCE )
end


-- ** EventHandle: ClfGChatWindowFrActNum OnMouseOver
-- オンラインのフレンド名をツールチップで表示
function ClfChat.onFrNumBtnOver()
	if ( not ClfChat.ActiveFriendNum or ClfChat.ActiveFriendNum < 1 ) then
		return
	end
	local buttonName = SystemData.ActiveWindow.name
	local font = "Arial_Black_14"
	local text = towstring( table.concat( ClfChat.ActiveFriendNames, "\n" ) .. "\n" )

	Tooltips.CreateTextOnlyTooltip( buttonName, text )
	Tooltips.SetTooltipFont( 1, 1, font, 16 )
	Tooltips.SetTooltipAlpha( 0.95 )
	Tooltips.Finalize()
	Tooltips.AnchorTooltip( Tooltips.ANCHOR_WINDOW_RIGHT )
end


-- ** EventHandle: ClfGChatWindowMsg OnMouseOver
-- 最新10件までのメッセージをツールチップで表示
function ClfChat.onMsgOver()
	local datas = ClfChat.GChatDatas
	local len = #datas
	if ( not datas or len < 1 ) then
		return
	end
	local buttonName = SystemData.ActiveWindow.name
	local stIdx = math.max( 1, len - 9 )

	local count = 0
	local op = L""
	for i = len, stIdx, -1 do
		local data = datas[ i ]
		op = op .. L"--  " .. data.name .. L"  ---------\n" ..
		towstring( i ) .. L". [" .. data.time .. L"] " .. data.text .. L"\n\n"

	end

	local Tooltips = Tooltips
	Tooltips.CreateTextOnlyTooltip( buttonName, op )
	Tooltips.SetTooltipFont( 1, 1, "MgenPlus_14", 18 )
	Tooltips.SetTooltipAlpha( 0.95 )
	Tooltips.Finalize()
	Tooltips.AnchorTooltip( Tooltips.ANCHOR_WINDOW_BOTTOM )
end

