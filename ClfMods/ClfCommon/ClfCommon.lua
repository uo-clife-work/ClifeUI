
LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfCommon", "ClfIcons.xml", "ClfIcons.xml" )
LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfCommon", "ClfTextures.xml", "ClfTextures.xml" )
LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfCommon", "ClfWindowTemplate.xml", "ClfWindowTemplate.xml" )


ClfCommon = {}

function _void() end

function _return_false() return false end

function _return_true() return true end

-- UI初期化時のタイムスタンプ：未使用
ClfCommon.InitialTimeStamp = 0
ClfCommon.TimeSinceLogin = 0

function ClfCommon.initialize()
	ClfCommon.InitialTimeStamp = GetCurrentDateTime()
	ClfCommon.TimeSinceLogin = Interface.TimeSinceLogin

	ClfUtil.initialize()
	ClfSettings.initialize()
	ClfDataFuncs.initialize()
	ClfReActionsWindow.initialize()
	ClfRefactor.initialize()
end


function ClfCommon.onUpdate( timePassed )
	ClfCommon.TimeSinceLogin = ClfCommon.TimeSinceLogin + timePassed

	local pcall = pcall
	pcall( ClfActions.onUpdate, timePassed )
	pcall( ClfDamageMod.onUpdate, timePassed )

	pcall( ClfCommon.processListenersCheck )
end



local CheckListeners = {}
local TimeoutListeners = {}

function ClfCommon.processListenersCheck()
	local pairs = pairs
	local pcall = pcall
	local CheckListeners = CheckListeners
	local now = ClfCommon.TimeSinceLogin
	for name, listener in pairs( CheckListeners ) do
		if ( listener.begin and listener.begin > now ) then
			continue
		end

		local ok, success = pcall( listener.check )

		if ( success and ok ) then
			pcall( listener.done, name )

			if ( listener.remove ) then
				CheckListeners[ name ] = nil
			end
		elseif ( listener.limit <= now ) then
			if ( listener.fail ) then
				pcall( listener.fail, name )
			end
			CheckListeners[ name ] = nil
		end
	end

	local TimeoutListeners = TimeoutListeners
	for name, listener in pairs( TimeoutListeners ) do
		if ( listener.timeout > now ) then
			continue
		end
		pcall( listener.done, name )
		TimeoutListeners[ name ] = nil
	end
end


--[[
** onUpdateごとに判定するオブジェクトを登録
* @param  {string} name      必須：オブジェクトのキーになる名前
* @param  {table}  listener  必須：
*         判定、完了、失敗時に実行する関数や、終了時にオブジェクトを取り除くか、判定の遅延、リミット時間（秒）を含めたtable
*         e.g. listener = {
*                 check  = function() return exp end,			-- 必須：判定用関数
*                 done   = function() something end,			-- 必須：判定用関数から真が返ったら実行する関数
*                 fail   = function() something end,			-- limit までに判定が完了しなかった時に実行
*                 begin  = ClfCommon.TimeSinceLogin + 1,		-- いつから判定開始するか。指定しなければ次のプロセスから
*                 limit  = ClfCommon.TimeSinceLogin + 10,	-- いつまで判定するか。指定しなければ 10秒後まで
*                 remove = false,									-- 判定完了時に取り除くか。指定しなければ true
*              }
]]
function ClfCommon.addCheckListener( name, listener )
	if ( not name
			or CheckListeners[ name ]
			or not listener
			or not listener.check
			or not listener.done
		) then
		return
	end
	listener.limit  = listener.limit or ClfCommon.TimeSinceLogin + 10
	listener.remove = ( listener.remove == nil ) or not not listener.remove

	CheckListeners[ name ] = listener
end



function ClfCommon.setTimeout( name, listener )
	if ( not name
			or TimeoutListeners[ name ]
			or not listener
			or not listener.done
		) then
		return
	end
	listener.timeout = listener.timeout or ClfCommon.TimeSinceLogin + 1

	TimeoutListeners[ name ] = listener
end



-- EOF

