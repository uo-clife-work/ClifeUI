
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfCommon", "ClfIcons.xml", "ClfIcons.xml" )
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfCommon", "ClfTextures.xml", "ClfTextures.xml" )


ClfCommon = {}

function _void() end

function _return_false() return false end

function _return_true() return true end


function ClfCommon.initialize()
	ClfUtil.initialize()
	ClfSettings.initialize()
	ClfReActionsWindow.initialize()
	ClfRefactor.initialize()
end


function ClfCommon.onUpdate( timePassed )
	local pcall = pcall
	pcall( ClfActions.onUpdate, timePassed )
	pcall( ClfDamageMod.onUpdate, timePassed )

	pcall( ClfCommon.processListenersCheck )
end



local CheckListeners = {}


function ClfCommon.processListenersCheck()
	local CheckListeners = CheckListeners
	local now = Interface.TimeSinceLogin
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
end


--[[
** onUpdateごとに判定するオブジェクトを登録
* @param  {string} name      必須：オブジェクトのキーになる名前
* @param  {table}  listener  必須：
*         判定、完了、失敗時に実行する関数や、終了時にオブジェクトを取り除くか、判定の遅延、リミット時間（秒）を含めたtable
*         e.g. listener = {
*                 check  = function() { return exp },			-- 必須：判定用関数
*                 done   = function() {  },						-- 必須：判定用関数から真が返ったら実行する関数
*                 fail   = function() {  },						-- limit までに判定が完了しなかった時に実行
*                 begin  = Interface.TimeSinceLogin + 1,		-- いつから判定開始するか。指定しなければ次のプロセスから
*                 limit  = Interface.TimeSinceLogin + 10,	-- いつまで判定するか。指定しなければ 10秒後まで
*                 remove = true,										-- 判定完了時に取り除く。指定しなければ true
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

	listener.limit  = listener.limit or Interface.TimeSinceLogin + 10
	listener.remove = ( listener.remove == nil ) or not not listener.remove

	CheckListeners[ name ] = listener
end





