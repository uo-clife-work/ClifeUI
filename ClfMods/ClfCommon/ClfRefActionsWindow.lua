
--[[
行動メニューにClifeUIのアクションを追加するためのmod。
ActionsWindowのメソッドをオーバーライドしてデータの追加等を行う。
]]



ClfReActionsWindow = {}


function ClfReActionsWindow.initialize()
	ClfReActionsWindow.initFuncAndDatas()
end


ClfReActionsWindow.initActionData_org = nil

-- ActionDataを追加するメソッド： ActionsWindow.InitActionDataをオーバーライド
function ClfReActionsWindow.onInitActionData()
	-- // オリジナルの ActionsWindow.InitActionData を実行
	ClfReActionsWindow.initActionData_org()

	-- // 以下、ClifeUIのActionを追加
	local ActionsWindow = ActionsWindow
	local AW_ActionData = ActionsWindow.ActionData
	local SPEECH_USER_CMD = SystemData.UserAction.TYPE_SPEECH_USER_COMMAND
	local ClfTxt_getString = ClfTxt.getString

	-- // 追加するActionDataを定義
	-- Craftingユーティリティ
	AW_ActionData[6007] = {
		-- 再練成
		type            = SPEECH_USER_CMD,
		iconId          = 876007,
		nameString      = ClfTxt_getString( 3000 ),
		detailString    = ClfTxt_getString( 4000 ),
		callback        = L"script Actions.ReimbueLast()",
		inActionWindow  = true,
	}
	AW_ActionData[6008] = {
		-- 容器内全抽出
		type            = SPEECH_USER_CMD,
		iconId          = 876008,
		nameString      = ClfTxt_getString( 3001 ),
		detailString    = ClfTxt_getString( 4001 ),
		callback        = L"script Actions.UnravelContainer()",
		inActionWindow  = true,
	}

	-- // 定義したActionDataをAction groupに追加
	local AW_Groups = ActionsWindow.Groups
	-- Craftingユーティリティ
	local group = AW_Groups[23] or {}
	local gIndexes = group.index or {}
	if ( #gIndexes > 1 ) then
		local adds = { 6007, 6008 }
		for i = 1, #adds do
			gIndexes[ #gIndexes + 1 ] = adds[ i ]
		end
	end

end


-- 追加するActionを行動ウィンドウに表示させる為の前処理等
function ClfReActionsWindow.initFuncAndDatas()

	if ( not ClfReActionsWindow.initActionData_org ) then

		-- // ActionsWindow.InitActionData をオーバーライド： このメソッドでActionの追加を行う
		ClfReActionsWindow.initActionData_org = ActionsWindow.InitActionData
		ActionsWindow.InitActionData = ClfReActionsWindow.onInitActionData

		-- // ActionsWindowが既にあれば作り直す
		-- ※ ActionDataの追加用メソッドを定義してからWindowを再作成する事で追加したデータを反映させる
		if ( DoesWindowExist( "ActionsWindow" ) ) then
			local showing = WindowGetShowing( "ActionsWindow" )
			DestroyWindow( "ActionsWindow" )
			CreateWindow( "ActionsWindow", showing )
		end

		-- // 追加Action用アイコンをホットバーに反映させる （modで追加したアイコンが、ログイン直後には反映されない為）
		local HS_RegisteredSpellIcons = HotbarSystem.RegisteredSpellIcons
		local AW_ActionData =  ActionsWindow.ActionData
		local SPEECH_USER_CMD = SystemData.UserAction.TYPE_SPEECH_USER_COMMAND

		local DoesWindowExist = DoesWindowExist
		local WindowGetId = WindowGetId
		local WindowGetParent = WindowGetParent
		local UserActionGetType = UserActionGetType
		local HS_SetHotbarIcon = HotbarSystem.SetHotbarIcon

		for elm, v in pairs( HS_RegisteredSpellIcons ) do
			if ( v < 5000 or not DoesWindowExist( elm ) ) then
				continue
			end
			local actionData = AW_ActionData[ v ]
			local iconId = actionData and actionData.iconId or 0
			if ( iconId > 870000 ) then
				local slot = WindowGetId( elm )
				local hotbarId = WindowGetId( WindowGetParent( elm ) )
				local actionType = UserActionGetType( hotbarId, slot, 0 )
				if ( actionType == SPEECH_USER_CMD ) then
					HS_SetHotbarIcon( elm, iconId )
				end
			end
		end
	end
end
