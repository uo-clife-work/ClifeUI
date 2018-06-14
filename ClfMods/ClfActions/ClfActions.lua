
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfActions", "ClfActions.xml", "ClfActions.xml" )


ClfActions = {}

ClfActions.DistWindowEnable = nil
ClfActions.DistWindowName = "ClfDistanceWindow"
ClfActions.DistColors = {
	{ r =  80, g = 255, b = 255 },
	{ r = 180, g = 250, b = 255 },
	{ r = 240, g = 245, b = 245 },
	{ r = 160, g = 150, b = 140 },
}

ClfActions.FiendlyIds = {}

-- プレイヤーが使役しているmobのプロパティに使われるtId
ClfActions.WorkerMobileTids = nil
ClfActions.PetPropTids = {
	[502006]  = "pet",	-- "ペット"
	[1049608] = "petFavorite",	-- "おきにいり"
}
ClfActions.SummonedPropTids = {
	[1049646] = "summon",	-- "召喚" （NPCが召喚したmobには付かないっぽい） ※ 一部の召喚mob（ネクロのSummon FamiliarやAnimate Deadなど）では付かない
}

-- spellIdをキーにしたSpellsDataを保持するテーブル
ClfActions.SpellIdsData = nil


function ClfActions.initialize()

	ClfActions.setDistWindowEnable( Interface.LoadBoolean( "ClfDistWindowEnable", true ) )

	if ( not ClfActions.WorkerMobileTids ) then
		-- WorkerMobileTids を生成
		ClfActions.WorkerMobileTids = {}
		local allTids = {
			[1] = ClfActions.PetPropTids,
			[2] = ClfActions.SummonedPropTids,
		}
		for i = 1, #allTids do
			local tids = allTids[ i ]
			for k, _ in pairs( tids ) do
				ClfActions.WorkerMobileTids[ k ] = i
			end
		end
	end


	if ( not ClfActions.SpellIdsData ) then
		-- SpellIdsData： SpellsInfo.SpellsDataからspellIdをキーにしたテーブルを生成
		ClfActions.SpellIdsData = {}
		local spellsData = SpellsInfo.SpellsData
		for word, data in pairs( spellsData ) do
			local spellId = data.id
			if ( not spellId and spellId > 0 and not ClfActions.SpellIdsData[ id ] ) then
				ClfActions.SpellIdsData[ id ] = data
			end
		end
	end
end



-- ** EventHandle: mod.OnUpdate
function ClfActions.onUpdate( timePassed )
	if ( ClfActions.DistWindowEnable ) then
		ClfActions.p_dispTargetDist( timePassed )
	end

	if ( ClfActions.AFKmode ) then
		ClfActions.p_massAFKmode( timePassed )
	end

	if ( ClfActions.LoadFukiyaEnable ) then
		ClfActions.p_autoLoadFukiya( timePassed )
	end
end


-- mob頭上の距離表示・非表示を切り替え
function ClfActions.toggleDistWindow()
	ClfActions.setDistWindowEnable( not ClfActions.DistWindowEnable )
end

function ClfActions.setDistWindowEnable( enable )
	local template = "ClfActionsWindow"
	local mainWin = template .. "Dist"
	local onOffStr = L"OFF"
	local hue = 150

	if ( enable ) then
		if ( not DoesWindowExist( mainWin ) ) then
			CreateWindowFromTemplateShow( mainWin, template, "Root", false )
			WindowRegisterEventHandler( mainWin, WindowData.CurrentTarget.Event, "ClfActions.p_onUpdateTarget" )
		end
		ClfActions.p_onUpdateTarget()
		onOffStr = L"ON"
		hue = 1152
	else
		if ( DoesWindowExist( mainWin ) ) then
			DestroyWindow( mainWin )
		end
		ClfActions.p_cleanDistData( true )
	end
	ClfActions.DistWindowEnable = enable
	Interface.SaveBoolean( "ClfDistWindowEnable", enable )
	if ( ChatSettings ) then
		WindowUtils.SendOverheadText( L"ClfDistWindow: " .. onOffStr, hue, true )
	end
end


ClfActions.DistWindows = {}
ClfActions.CurrentDistId = 0
ClfActions.DistCleanDelta = 0
function ClfActions.p_dispTargetDist( timePassed )
	local targetId = WindowData.CurrentTarget.TargetId
	local newWin = ClfActions.DistWindows[ targetId ]

	if ( newWin ) then
		local dist = GetDistanceFromPlayer( targetId ) or -1
		if ( dist >= 0 ) then
			local color
			if ( dist <= 3 ) then
				color = ClfActions.DistColors[1]
			elseif ( dist <= 7 ) then
				color = ClfActions.DistColors[2]
			elseif ( dist <= 10 ) then
				color = ClfActions.DistColors[3]
			else
				color = ClfActions.DistColors[4]
			end
			local label = newWin .. "Num"
			LabelSetText( label, towstring( dist ) )
			LabelSetTextColor( label, color.r, color.g, color.b )
			WindowSetFontAlpha( newWin, 0.85 )
		else
			WindowSetFontAlpha( newWin, 0 )
		end
	end

	local delta = ClfActions.DistCleanDelta + timePassed
	ClfActions.DistCleanDelta = delta
	if ( delta > 120 ) then
		ClfActions.p_cleanDistData()
		ClfActions.DistCleanDelta = 0
	end
end


function ClfActions.p_cleanDistData( forceClean )
	local targetId = WindowData.CurrentTarget.TargetId
	local data = ClfActions.DistWindows
	for id, win in pairs( data ) do
		if ( forceClean or targetId ~= id ) then
			ClfActions.DistWindows[ id ] = nil
			DestroyWindow( win )
		end
	end
end


-- ** EventHandle: WindowData.CurrentTarget.Event
function ClfActions.p_onUpdateTarget()
	if ( ClfActions.DistWindowEnable ) then

		local targetId = WindowData.CurrentTarget.TargetId

		local oldId = ClfActions.CurrentDistId
		local oldWin = ClfActions.DistWindows[ oldId ]
		if ( oldWin and targetId ~= oldId ) then
			ClfActions.DistWindows[ oldId ] = nil
			DestroyWindow( oldWin )
		end

		if ( targetId and targetId > 0 and targetId ~= WindowData.PlayerStatus.PlayerId ) then

			if ( IsMobile( targetId ) ) then
				if ( not ClfActions.DistWindows[ targetId ] ) then
					local newWin = ClfActions.DistWindowName .. targetId
					CreateWindowFromTemplateShow( newWin, ClfActions.DistWindowName, "Root", true )
					ClfActions.DistWindows[ targetId ] = newWin
					ClfActions.CurrentDistId = targetId
					AttachWindowToWorldObject( targetId, newWin )
					WindowSetFontAlpha( newWin .. "Num", 0.85 )

					local mobileData = WindowData.MobileName[ targetId ] or Interface.GetMobileData( targetId, false ) or {}
					if ( type( mobileData.MobName ) == "wstring" ) then
						local label = newWin .. "Label"
						local name = wstring.lower( mobileData.MobName )
						name = wstring.gsub( towstring( name ), L"^%s*an?%s+", L"" )
						LabelSetText( label, name )
						WindowSetFontAlpha( label, 0.7 )
						local noto = mobileData.Notoriety and mobileData.Notoriety + 1
						local col = noto and NameColor.TextColors[ noto ]
						if ( col ) then
							LabelSetTextColor( label, col.r, col.g, col.b )
						end
					end
				end
			end

		end

	end

end


-- ラストターゲットをクリックする（カレントターゲットにする）。 ※プレイヤー自身は含まない
function ClfActions.clickLastTarget( mobileOnly )
	local targetId = WindowData.Cursor and WindowData.Cursor.lastTarget
	if ( targetId and targetId > 0 and targetId ~= WindowData.PlayerStatus.PlayerId ) then
		if ( not mobileOnly or IsMobile( targetId ) ) then
			HandleSingleLeftClkTarget( targetId )
		end
	end
end


-- カレントターゲットを使う直前にこのメソッドを呼出すと、ContainerWindow.OpenedCorpseにカレントターゲットのIDを登録する
-- ※ 一度開いた棺桶のオブハンを非表示にするオプション設定時に、カレントターゲットのIDがignoreに含まれる様になる
-- ※ メソッド呼出し時に棺桶が開かない場合を考慮していないので、開かなかった時もオブハンが非表示になってしまう？ と思ったけど、コンテナが開いた時点でignoreとして登録されるので問題ないはず
function ClfActions.setOpenedCorpse()
	ContainerWindow.OpenedCorpse = WindowData.CurrentTarget.TargetId
end


--[[
* カレントターゲットが敵性mob以外なら、近くの敵をカレントターゲットにする（敵性だった時はクリックする）
* @param  {integer} [orderNum = 1] オプション - ターゲットを変更する場合は{orderNum}番目に近い敵をターゲットする
* @param  {integer} [range      = 255]    オプション - ターゲットを変更する場合に選択する距離範囲
* @param  {boolean} [descHealth = false]  オプション - ターゲットを変更する場合は同距離の時は体力の残りが大きい順にする
]]--
function ClfActions.convTargetToEnemy( orderNum, range, descHealth )

	local targetId = WindowData.CurrentTarget and WindowData.CurrentTarget.TargetId
	local changeTarg = true
	if ( targetId and targetId > 0 ) then
		if (
				targetId == WindowData.PlayerStatus.PlayerId
				or ClfActions.FiendlyIds[ targetId ]
				or IsPartyMember( targetId )
				or IsObjectIdPet( targetId )
			) then
			-- 自分、パーティメンバー、ペットなので変更
			changeTarg = true

		elseif ( IsMobile( targetId ) ) then
			local mobName = WindowData.MobileName[ targetId ] or {}
			local noto = mobName.Notoriety
			if ( not noto ) then
				local mobileData = Interface.GetMobileData( targetId, false ) or {}
				noto = mobileData.Notoriety
			end
			noto = noto and noto + 1
			if (
					noto == 3	-- 緑
					or noto == 8	-- 黄
					or ClfActions.p_isWorkerMobile( targetId )
				) then
				-- 緑、黄色、ペット、召喚
				changeTarg = true

			else
				changeTarg = false
				HandleSingleLeftClkTarget( targetId )
			end
		end
	end

	if ( changeTarg ) then
		ClfActions.nearTarget( orderNum, descHealth, range )
	end

end


--[[
* 近くの敵をターゲットする（PCのペット・召喚生物と判定出来るmobは除く）
* @param  {integer} [orderNum = 1] オプション - {orderNum}番目に近い敵をターゲットする
* @param  {integer} [range      = 255]      オプション - 選択する距離範囲
* @param  {boolean} [descHealth = false]  オプション - 同距離の時は体力の残りが大きい順にする
]]--
function ClfActions.nearTarget( orderNum, range, descHealth )
	local tgMobs = ClfActions.p_getDistSortTargetArray( range, descHealth )

	if ( tgMobs ) then

		if ( not orderNum or type( orderNum ) ~= "number" or orderNum <= 1 ) then
			orderNum = 1
		else
			orderNum = math.ceil( orderNum )
			local tgMobsNum = #tgMobs
			if ( orderNum > tgMobsNum ) then
				orderNum = orderNum % tgMobsNum
				if ( orderNum == 0 ) then
					orderNum = tgMobsNum
				end
			end
		end

		HandleSingleLeftClkTarget( tgMobs[ orderNum ].id )
	end
end


--[[
* 敵性mob（PCのペット・召喚生物と判定出来るmobは除く）情報を距離が近い順に格納した配列を得る
* @param  {integer} [range      = 255]    オプション - 選択する距離範囲
* @param  {boolean} [descHealth = false]  オプション - 同距離の時は体力の残りが大きい順にする
* @return {array|nil}   敵性mobが取得出来なかった時は nil
]]--
function ClfActions.p_getDistSortTargetArray( range, descHealth )

	local tgMobs = {}
	local mobiles = MobilesOnScreen.MobilesSort or {}

	local FiendlyIds = ClfActions.FiendlyIds
	local p_isWorkerMobile = ClfActions.p_isWorkerMobile
	local IsPartyMember = IsPartyMember
	local GetDistanceFromPlayer = GetDistanceFromPlayer
	local GetMobileData = Interface.GetMobileData
	local MobileName = WindowData.MobileName
	local TargetAllowed = Actions.TargetAllowed
	local maxRange = tonumber( range )
	if ( not maxRange ) then
		maxRange = 255
	else
		maxRange = math.max( maxRange, 0 )
	end

	for i = 0, #mobiles do
		local mobileId = mobiles[ i ]
		if ( mobileId and mobileId > 0 and IsMobile( mobileId ) and TargetAllowed( mobileId ) ) then
			local mobileName = MobileName[ mobileId ] or {}
			local noto = mobileName.Notoriety
			noto = noto and noto + 1
			if (
					not FiendlyIds[ targetId ]
					and noto
					and noto ~= 2
					and noto ~= 3
					and noto ~= 8
					and not IsPartyMember( mobileId )
				) then
				-- 青、緑、黄色、パーティメンバー以外 // TargetAllowed でこれらは返ってこないハズだけど念のため

				if ( not p_isWorkerMobile( mobileId ) ) then
					-- ペット、召喚では無い
					local dist = GetDistanceFromPlayer( mobileId ) or -1
					if ( dist >= 0 and dist <= maxRange ) then
						local index = #tgMobs + 1
						local mobileData = GetMobileData( mobileId, false ) or { CurrentHealth = 99999 }
						tgMobs[ index ] = {
							index = index,
							dist = dist,
							id = mobileId,
							CurrentHealth = mobileData.CurrentHealth,
						}
					end
				end

			end
		end
	end

	if ( #tgMobs > 0 ) then
		if ( descHealth ) then
			table.sort(
				tgMobs,
				function( a, b )
					if ( a.dist ~= b.dist ) then
						return ( a.dist < b.dist )
					end
					if ( a.CurrentHealth ~= b.CurrentHealth ) then
						return ( a.CurrentHealth > b.CurrentHealth )
					end
					return ( a.index > b.index )
				end
			)
		else
		table.sort(
			tgMobs,
			function( a, b )
				if ( a.dist ~= b.dist ) then
					return ( a.dist < b.dist )
				end
				if ( a.CurrentHealth ~= b.CurrentHealth ) then
					return ( a.CurrentHealth < b.CurrentHealth )
				end
				return ( a.index < b.index )
			end
		)
		end
		return tgMobs
	end

	return nil
end



ClfActions.WorkerMobileIds = {}
--[[
* mobileIdから、ペット・召喚生物かどうかを返す
* @param  {integer}         mobileId
* @param  {integer|boolean} [mobileType = nil] オプション - 指定無し or false： 全て、 2:召喚生物のみ、 その他:ペットのみ
* @return {boolean}
]]--
function ClfActions.p_isWorkerMobile( mobileId, mobileType )

	if ( not mobileId or mobileId < 1 ) then
		return
	end

	local workerType = nil

	if ( ClfActions.WorkerMobileIds[ mobileId ] ~= nil ) then
		workerType = ClfActions.WorkerMobileIds[ mobileId ]
	else
		workerType = false

		local props = ItemProperties.GetObjectPropertiesArray( mobileId, "ClfActions.p_isWorkerMobile" )
		local tids = props and props.PropertiesTids

		if ( tids and #tids > 1 ) then

			local WorkerMobileTids = ClfActions.WorkerMobileTids

			-- プロパティにペット、召喚のtIdがあるかチェック
			-- ※ 「召喚」のプロパティが無い召喚mob（ネクロのSummon FamiliarやAnimate Deadなど）もいるが、とりあえずはコレで.
			-- 1番目プロパティは名前なので、2から
			for i = 2, #tids do
				local tId = tids[ i ]
				if ( WorkerMobileTids[ tId ] ) then
					workerType = WorkerMobileTids[ tId ]
					break
				end
			end
		end

		ClfActions.WorkerMobileIds[ mobileId ] = workerType
	end

	if ( not mobileType ) then
		if ( workerType ) then
			return true
		else
			return false
		end
	elseif ( mobileType == 2 ) then
		return ( workerType == 2 )
	else
		return ( workerType == 1 )
	end

	return false
end


-- 指定したレンジ内にカレントターゲットがある時だけターゲットする
-- とりあえず作ってみたヤツ。 ClfActions.waitTargetRange を使った方が良いかも
function ClfActions.targetInRange( range )
	range = range or ClfActions.p_getSpellRange() or 10
	local id = WindowData.CurrentTarget and WindowData.CurrentTarget.TargetId
	if ( id ) then
		local dist = GetDistanceFromPlayer( id )
		if ( dist and dist >= 0 ) then
			if ( dist <= range ) then
				HandleSingleLeftClkTarget( id )
			else
				WindowUtils.SendOverheadText( L"=== Out of range: " .. towstring( dist ) .. L" ===" , 46, true)
			end
		end
	end
end


ClfActions.TargetRangeMax = nil
ClfActions.TargetRangeMin = nil
ClfActions.WaitTargetId = nil
ClfActions.WaitTargetLastSpell = nil
ClfActions.WaitTargetIsCastSpell = nil

--[[
* 詠唱した呪文の射程に対象（実行時点のカレントターゲット）が入るまでターゲット解放を待つ
* @param  {integer} [range]  オプション - ターゲット解放最大距離（射程距離）
*                            指定が無い場合、notCastSpellがtrue以外なら最後に唱えた呪文の射程を SpellsInfo.SpellsData から得る。射程が取得出来ないorその他の場合は10
* @param  {integer} [minRange     = 0]   オプション - ターゲット解放最小距離
* @param  {boolean} [notCastSpell = nil] オプション - 呪文では無い場合
]]--
function ClfActions.waitTargetRange( range, minRange, notCastSpell )
	local id = WindowData.CurrentTarget and WindowData.CurrentTarget.TargetId
	local win = "ClfDelayTarget"
	if ( DoesWindowExist( win ) ) then
		DestroyWindow( win )
	end

	if ( id and id > 0 ) then
		ClfActions.WaitTargetId = id

		local isCastSpell = not notCastSpell
		ClfActions.WaitTargetIsCastSpell = isCastSpell

		local lastSpell = Interface.LastSpell
		ClfActions.WaitTargetLastSpell = lastSpell
		ClfActions.WaitTargetDelta = 0
		ClfActions.WaitTargetTxtDelta = 0
		ClfActions.TargetRangeMax = range and tonumber( range ) or isCastSpell and ClfActions.p_getSpellRange( lastSpell ) or 10
		minRange = minRange and tonumber( minRange ) or 0
		ClfActions.TargetRangeMin = math.min( math.max( 0, minRange ), ClfActions.TargetRangeMax )

		ClfActions.WaitTargetEnable = true

		CreateWindow( win, true )
		AttachWindowToWorldObject( WindowData.PlayerStatus.PlayerId, win )
	else
		ClfActions.WaitTargetId = nil
		WindowUtils.SendOverheadText( L"Failure: None Target", 33, true )
	end
end


ClfActions.WaitTargetEnable = false
ClfActions.WaitTargetDelta = 0
ClfActions.WaitTargetTxtDelta = 0

-- ** EventHandle: Window[name="ClfDelayTarget"].OnUpdate
function ClfActions.DelayTargetWinUpdate( timePassed )
	if ( ClfActions.WaitTargetEnable ) then
		ClfActions.p_massWaitTarget( timePassed )
	else
		ClfActions.p_endWaitTarget( timePassed )
	end
end

function ClfActions.p_massWaitTarget( timePassed )
	local T = ClfActions
	local win = "ClfDelayTarget"
	local label = "ClfDelayTargetLabel"

	local delta = T.WaitTargetDelta + timePassed
	T.WaitTargetDelta = delta

	-- テキスト更新を一定間隔に抑える
	local txtDelta = T.WaitTargetTxtDelta + timePassed
	T.WaitTargetTxtDelta = txtDelta

	local currentSpell = Interface.CurrentSpell or {}
	local cursor = WindowData.Cursor or {}

	if ( T.WaitTargetIsCastSpell and T.WaitTargetLastSpell ~= Interface.LastSpell ) then
		-- 最後に詠唱した魔法が、waitTargetRange実行時の魔法と違う： 終了
		T.WaitTargetDelta = 0
		T.WaitTargetEnable = false
		LabelSetTextColor( label, 255, 70, 80 )
		LabelSetText( label, L"Spell Changed! - END Wait targ" )

		WindowStartAlphaAnimation( win, Window.AnimationType.SINGLE_NO_RESET, 1, 0, 1, false, 0.8, 0 )

	elseif ( cursor.target ) then
		-- ターゲットカーソル状態： 待機時間をリセット
		T.WaitTargetDelta = 0

		local currentTargetId = WindowData.CurrentTarget and WindowData.CurrentTarget.TargetId
		local id = ClfActions.WaitTargetId

		if ( currentTargetId and currentTargetId > 0 and currentTargetId ~= id ) then
			-- 実行時のターゲットから現在ターゲットが変更された： 終了
			T.WaitTargetEnable = false
			LabelSetTextColor( label, 255, 70, 80 )
			LabelSetText( label, L"Target Changed! - END Wait targ" )

			WindowStartAlphaAnimation( win, Window.AnimationType.SINGLE_NO_RESET, 1, 0, 1, false, 0.8, 0 )

		elseif ( id and id > 0 ) then
			local dist = GetDistanceFromPlayer( id )
			if ( not dist or dist < 0 ) then
				if ( txtDelta > 0.1 ) then
					LabelSetText( label, L"wait (Unavailability)" )
					T.WaitTargetTxtDelta = 0
				end
			elseif ( dist ) then
				if ( dist >= T.TargetRangeMin and dist <= T.TargetRangeMax ) then
					-- 射程に入った： ターゲットして終了
					T.WaitTargetDelta = 0
					T.WaitTargetEnable = false
					HandleSingleLeftClkTarget( id )
					LabelSetTextColor( label, 30, 220, 255 )
					LabelSetText( label, L"Shoot!" )
					WindowStartAlphaAnimation( win, Window.AnimationType.SINGLE_NO_RESET, 1, 0, 1, false, 0.8, 0 )
					local targId = WindowData.CurrentTarget and WindowData.CurrentTarget.TargetId
					if ( targId ~= id ) then
						HandleSingleLeftClkTarget( id )
					end
				elseif ( txtDelta > 0.03 ) then
					-- ターゲット待機
					LabelSetText( label, L"wait target: " .. towstring( T.TargetRangeMax ) .. L" < " .. towstring( dist ) )
					T.WaitTargetTxtDelta = 0
				end
			elseif ( txtDelta > 0.1 ) then
				LabelSetText( label, L"wait target" )
				T.WaitTargetTxtDelta = 0
			end
		elseif ( txtDelta > 0.1 ) then
			LabelSetText( label, L"wait (none target)" )
			T.WaitTargetTxtDelta = 0
		end

	elseif ( ClfActions.WaitTargetIsCastSpell and currentSpell.casting ) then
		-- 詠唱中： 待機時間をリセット
		T.WaitTargetDelta = 0

	elseif ( delta >= 0.6 or IsPlayerDead() ) then
		-- 詠唱中では無い＆ターゲットカーソル状態では無い状態が0.6秒以上経過 or 自分が死んでいる： 終了
		T.WaitTargetDelta = 0
		T.WaitTargetEnable = false
		LabelSetTextColor( label, 255, 160, 70 )
		LabelSetText( label, L"TimeOut - END Wait targ" )

		WindowStartAlphaAnimation( win, Window.AnimationType.SINGLE_NO_RESET, 1, 0, 1, false, 0.8, 0 )
	end
end

function ClfActions.p_endWaitTarget( timePassed )
	if ( not ClfActions.WaitTargetEnable ) then
		local win = "ClfDelayTarget"
		local alpha = WindowGetFontAlpha( win )

		if ( alpha <= 0 ) then
			DestroyWindow( win )
		end
	end
end


--[[
* spellIdから呪文の射程距離を得る
* @param  {integer}  [range = Interface.LastSpell]  オプション
* @return {integer|nil}  射程距離 or 取得出来なかった場合は nil
]]--
function ClfActions.p_getSpellRange( spellId )
	local dist
	spellId = spellId or Interface.LastSpell
	if ( spellId and spellId > 0 ) then
		local data = ClfActions.SpellIdsData[ spellId ]
		if ( data and data.distance ) then
			dist = data.distance
			if ( dist > 10 ) then
				-- 10マスのはずなのにSpellsDataでは12になっているスペルがあるので、10以上なら-2する
				-- ※SAクラの距離表示はマス目では無く距離なので（例えば10マスなら 11～14 でも届いたり届かなかったりするので）10マスを基準にしておく
				dist = math.max( 10, dist - 2 )
			end
		end
	end
	return dist
end


--[[
* 最もダメージを受けている友好的なmob（ペット、緑ネーム、パーティメンバー）をターゲットする
* @param  {boolean} [includeBlue      = false]  オプション - 青ネームのmobも含む
* @param  {boolean} [includePoisoned  = false]  オプション - 毒状態のmobも含む
* @param  {boolean} [includeCursed    = false]  オプション - カース状態のmobも含む
* @param  {boolean} [excludeParty     = false]  オプション - パーティメンバーを除外する
* @param  {boolean} [excludeOthersPet = false]  オプション - 青ネームの他人のペットを含めない ※includeBlue がtrueの場合はこの指定は無効
* @param  {boolean} [excludeDead      = false]  オプション - 死亡しているmobを含めない ※死亡していなくても体力が0%だと死亡扱いになる事が殆どなので注意
* @param  {integer} [range            = 255]  オプション - 選択するmobの距離範囲
]]--
function ClfActions.injuredFriendly( includeBlue, includePoisoned, includeCursed, excludeParty, excludeOthersPet, excludeDead, range )
	local fMobs = ClfActions.p_getFriendlyMobArray( includeBlue, not includePoisoned, not includeCursed, excludeParty, false, excludeOthersPet, excludeDead, range )
--	Debug.DumpToConsole( "fMobs", fMobs )

	if ( #fMobs > 0 ) then
		local poisonState = 2

		if ( includePoisoned ) then
			table.sort(
				fMobs,
				function( a, b )
					if ( a.perc ~= b.perc ) then
						return ( a.perc < b.perc )
					end

					if ( a.visualState == poisonState or b.visualState == poisonState ) then
						if ( b.visualState ~= poisonState ) then
							return true
						elseif ( a.visualState ~= poisonState ) then
							return false
						end
					end

					if ( a.dist ~= b.dist ) then
						return ( a.dist < b.dist )
					end
					return ( a.index < b.index )
				end
			)

		else
			table.sort(
				fMobs,
				function( a, b )
					if ( a.perc ~= b.perc ) then
						return ( a.perc < b.perc )
					end
					if ( a.dist ~= b.dist ) then
						return ( a.dist < b.dist )
					end
					return ( a.index < b.index )
				end
			)
		end

		local mob = fMobs[1]
		if ( mob.perc < 1 or ( includePoisoned and mob.visualState == poisonState ) ) then
			HandleSingleLeftClkTarget( mob.id )
		end

--		Debug.DumpToConsole( "fMobs", fMobs )
	end

end


--[[
* 毒を受けている友好的なmob（ペット、緑ネーム、パーティメンバー）をターゲットする
* ※ 毒を受けているmobが無い場合は、最もダメージを受けているmobをターゲットする
* @param  {boolean} [includeBlue      = false]  オプション - 青ネームのmobも含む
* @param  {boolean} [excludeParty     = false]  オプション - パーティメンバーを除外する
* @param  {boolean} [myPetOnly        = false]  オプション - 自分のペットだけを選択する
* @param  {boolean} [excludeOthersPet = false]  オプション - 青ネームの他人のペットを含めない ※includeBlue がtrueの場合はこの指定は無効
* @param  {boolean} [excludeDead      = false]  オプション - 死亡しているmobを含めない ※死亡していなくても体力が0%だと死亡扱いになる事が殆どなので注意
* @param  {integer} [range            = 255]  オプション - 選択するmobの距離範囲
]]--
function ClfActions.poisonedFriendly( includeBlue, excludeParty, myPetOnly, excludeOthersPet, excludeDead, range )
	local fMobs = ClfActions.p_getFriendlyMobArray( includeBlue, false, true, excludeParty, myPetOnly, excludeOthersPet, excludeDead, range )
	local poisonState = 2

	if ( #fMobs > 0 ) then
		table.sort(
			fMobs,
			function( a, b )
				if ( a.visualState == poisonState or b.visualState == poisonState ) then
					if ( b.visualState ~= poisonState ) then
						return true
					elseif ( a.visualState ~= poisonState ) then
						return false
					end
				end
				if ( a.perc ~= b.perc ) then
					return ( a.perc < b.perc )
				end
				if ( a.dist ~= b.dist ) then
					return ( a.dist < b.dist )
				end
				return ( a.index < b.index )

			end
		)

		local mob = fMobs[1]
		if ( mob.visualState == poisonState or mob.perc < 1 ) then
			HandleSingleLeftClkTarget( mob.id )
		end
	end
end


--[[
* 友好的なmob情報オブジェクトの配列を返す
* @param  {boolean} [includeBlue      = false]  オプション - 青ネームのmobも含む
* @param  {boolean} [excludePoisoned  = false]  オプション - 毒状態のmobを除外する
* @param  {boolean} [excludeCursed    = false]  オプション - カース状態のmobを除外する
* @param  {boolean} [excludeParty     = false]  オプション - パーティメンバーを除外する
* @param  {boolean} [myPetOnly        = false]  オプション - 自分のペットだけを選択する
* @param  {boolean} [excludeOthersPet = false]  オプション - 青ネームの他人のペットを含めない ※includeBlue がtrueの場合はこの指定は無効
* @param  {boolean} [excludeDead      = false]  オプション - 死亡しているmobを含めない ※死亡していなくても体力が0%だと死亡扱いになる事が殆どなので注意
* @param  {integer} [range            = 255]  オプション - 選択するmobの距離範囲
* @return {array}   mob情報オブジェクト{id,perc,dist,visualState}の配列
]]--
function ClfActions.p_getFriendlyMobArray( includeBlue, excludePoisoned, excludeCursed, excludeParty, myPetOnly, excludeOthersPet, excludeDead, range )
	local allMobiles = {}
	allMobiles[1] = PetWindow.SortedPet or {}
	if ( not myPetOnly ) then
		allMobiles[2] = MobilesOnScreen.MobilesSort or {}
	end

	local fMobs = {}
	local fMobIds = {}
	local includePoisoned = not excludePoisoned
	local includeCursed = not excludeCursed
	local includeDead = not excludeDead
	local poisonState = 2
	local cursedState = 3
	local maxRange = tonumber( range )
	if ( not maxRange ) then
		maxRange = 255
	else
		maxRange = math.max( 0, maxRange )
	end

	local pairs = pairs
	local GetDistanceFromPlayer = GetDistanceFromPlayer
	local GetMobileData = Interface.GetMobileData
	local IsPartyMember = IsPartyMember
	local HealthBarColor = WindowData.HealthBarColor
	local MobileName = WindowData.MobileName
	local p_isWorkerMobile = ClfActions.p_isWorkerMobile

	local setFMobs = function( mobileData, mobileId )
		if ( not mobileId or mobileId < 1 ) then
			return
		end
		local curHealth = mobileData.CurrentHealth or 25
		local maxHealth = mobileData.MaxHealth or 25
		local perc
		if ( maxHealth <= 0 ) then
			perc = 1
		else
			perc = curHealth / maxHealth
		end

		local visualStateId = HealthBarColor[ mobileId ] and HealthBarColor[ mobileId ].VisualStateId or 0
		visualStateId = visualStateId + 1

		local dist = GetDistanceFromPlayer( mobileId ) or -1
		if (
				dist >= 0 and
				dist <= maxRange and
				( includePoisoned or visualStateId ~= poisonState ) and
				( includeCursed or visualStateId ~= cursedState ) and
				( includeDead or not mobileData.IsDead )
			) then
			local index = #fMobs + 1
			fMobs[ index ] = {
				perc = perc,
				dist = dist,
				id = mobileId,
				visualState = visualStateId,
				index = index,
			}
			fMobIds[ mobileId ] = true
		end
	end


	local FiendlyIds = ClfActions.FiendlyIds
	for j = 1, #allMobiles do
		local mobiles = allMobiles[ j ]
		for i, mobileId in pairs( mobiles ) do
			if ( fMobIds[ mobileId ] ) then
				continue
			end
			local mobileData = GetMobileData( mobileId, true )
			if ( mobileData ) then
				local mobName = MobileName[ mobileId ] or {}
				local noto = mobName.Notoriety or mobileData.Notoriety

				if (
						FiendlyIds[ mobileId ] or
						mobileData.MyPet or
						noto == 2 or
						IsPartyMember( mobileId ) or
						( noto == 1 and ( includeBlue or ( not excludeOthersPet and p_isWorkerMobile( mobileId, 1 ) ) ) )
					) then
					setFMobs( mobileData, mobileId )
				end

			end
		end
	end

	if ( not excludeParty and not myPetOnly ) then
		local PartyMember = WindowData.PartyMember
		local partyNum = PartyMember and PartyMember.NUM_PARTY_MEMBERS
		if ( partyNum and partyNum > 0 ) then
			for i = 1, partyNum do
				if ( fMobIds[ mobileId ] ) then
					continue
				end
				local mobileId = PartyMember[ i ].memberId
				if ( mobileId and mobileId > 0 ) then
					local mobileData = GetMobileData( mobileId, true )
					if ( mobileData ) then

						setFMobs( mobileData, mobileId )

					end
				end
			end
		end
	end

	return fMobs
end


-- オーガナイザーとスカベンジャー用のbagを一時的に変更する
-- ※ 再ログインやカスタムUIのリロードをすると、元の設定に戻る
function ClfActions.setActiveOrganizeBag()
	WindowUtils.SendOverheadText( L"Target Organize&Scavenge Bag", 1152, true )
	RequestTargetInfo()
	WindowRegisterEventHandler("Root", SystemData.Events.TARGET_SEND_ID_CLIENT, "ClfActions.p_organizebagTargetReceived")
end

function ClfActions.p_organizebagTargetReceived()
	local backpackId = WindowData.PlayerEquipmentSlot[ EquipmentData.EQPOS_BACKPACK ].objectId
	local objectId = SystemData.RequestInfo.ObjectId
	WindowUnregisterEventHandler( "Root", SystemData.Events.TARGET_SEND_ID_CLIENT )

	if not IsContainer( objectId ) then
		WindowUtils.SendOverheadText( GetStringFromTid(1155159), 33, true )
		return
	end

	if ( objectId ~= backpackId and objectId ~= 0 ) then
		Organizer.Organizers_Cont[ Organizer.ActiveOrganizer ] = objectId
		Organizer.Scavengers_Cont[ Organizer.ActiveScavenger ] = objectId
		WindowUtils.SendOverheadText( L"Organizer & Scavenger bag Set!", 1152, true )
	else
		WindowUtils.SendOverheadText( GetStringFromTid(1155156), 33, true )
	end
end


-- ユーザー設定 → オプション → ターゲット自動攻撃（戦闘モード中） の設定を切り替える
function ClfActions.toggleAlwaysAttack( silent )
	local atk = not SystemData.Settings.GameOptions.alwaysAttack
	SystemData.Settings.GameOptions.alwaysAttack = atk
	UserSettingsChanged()

	if ( not silent ) then
		local str
		local hue
		if ( atk ) then
			str = L"ON"
			hue = 1152
		else
			str = L"OFF"
			hue = 150
		end
		WindowUtils.SendOverheadText( L"AlwaysAttack: " .. str, hue, true )
	end
end


-- ユーザー設定 → オプション → ターゲット自動攻撃（戦闘モード中） の設定を有効にする
function ClfActions.enableAlwaysAttack()
	if ( not SystemData.Settings.GameOptions.alwaysAttack ) then
		ClfActions.toggleAlwaysAttack( true )
	end
end


-- ユーザー設定 → オプション → ターゲット自動攻撃（戦闘モード中） の設定を無効にする
function ClfActions.disableAlwaysAttack()
	if ( SystemData.Settings.GameOptions.alwaysAttack ) then
		ClfActions.toggleAlwaysAttack( true )
	end
end


--[[
* バックパック第一階層にある一番大きいゴールドをターゲットする
* @param  {boolean} [ascend = false]  オプション - これを指定すると一番小さいゴールドをターゲットする
]]--
function ClfActions.targetGold( ascend )
	local backpackId = ContainerWindow.PlayerBackpack
	if ( not backpackId or backpackId < 1 ) then
		return
	end

	local cont = WindowData.ContainerWindow[ backpackId ]
	if ( not cont ) then
		return
	end

	local GOLD_TYPE = 3821
	local GOLD_HUE = 0
	local numItems = cont.numItems
	local items = cont.ContainedItems
	local targId = nil
	local qt
	local sFunc
	if ( ascend ) then
		qt = math.huge
		sFunc = function( quantity, id )
			if ( quantity and quantity < qt ) then
				targId = id
				qt = quantity
			end
		end
	else
		qt = 0
		sFunc = function( quantity, id )
			if ( quantity and quantity > qt ) then
				targId = id
				qt = quantity
			end
		end
	end

	for i = 1, numItems do
		local item = items[ i ]
		local id = item and item.objectId
		if ( id and id > 0 ) then
			RegisterWindowData( WindowData.ObjectInfo.Type, id )
			local data = WindowData.ObjectInfo[ id ]
			if ( data and data.objectType == GOLD_TYPE and data.hueId == GOLD_HUE ) then
				sFunc( data.quantity, id )
			end
			UnregisterWindowData( WindowData.ObjectInfo.Type, id )
		end
	end

	if ( targId ) then
		HandleSingleLeftClkTarget( targId )
	end
end


ClfActions.LoadFukiyaEnable = false
ClfActions.LoadFukiyaMsgEnable = true

--[[
** （サブコンテナを含む）バックパック内の吹き矢全てに吹き矢針を装填する
* @param  {boolean} [silent = false]  オプション - これを指定すると開始・終了時のメッセージを出力しない
]]--
function ClfActions.loadFukiya( silent )
	local msgEnable = not silent
	ClfActions.LoadFukiyaMsgEnable = msgEnable
	local fukiyaArr, needleArr = ClfActions.p_getFukiyaAndNeedles()
	if ( fukiyaArr and needleArr and #fukiyaArr > 0 and #needleArr > 0 ) then
		ClfActions.LoadFukiyaDelta = 0
		ClfActions.LoadFukiyaEnable = true
		if ( msgEnable ) then
			WindowUtils.SendOverheadText( L"loadFukiya: start", 1152, true )
		end
		return
	end

	ClfActions.LoadFukiyaEnable = false
	if ( msgEnable ) then
		WindowUtils.SendOverheadText( L"No Fukiya or Needle", 46, true )
	end
end

function ClfActions.p_getFukiyaAndNeedles()
	local allItems = ContainerWindow.ScanQuantities( ContainerWindow.PlayerBackpack, true )
	if ( type( allItems ) ~= "table" or #allItems < 1 ) then
		return
	end

	local FUKIYA_TYPE = 10154
	local NEEDLE_TYPE = 10246
	local fukiyaArr = {}
	local needleArr = {}
	local ObjectInfo = WindowData.ObjectInfo
	local GetCharges = ItemProperties.GetCharges
	local foundFukiya = false
	local foundNeedle = false

	for i = 1, #allItems do
		local id = allItems[ i ]
		if ( id and id > 0 ) then
			local data = ObjectInfo[ id ]
			if ( not data ) then
				RegisterWindowData( ObjectInfo.Type, id )
				data = ObjectInfo[ id ]
			end
			local objType = data and data.objectType

			if ( objType == FUKIYA_TYPE ) then
				local charges = GetCharges( id )
				if ( type( charges ) == "table" and #charges > 1 ) then
					local charge = charges[2]
					if ( type( charge ) == "number" and charge < 10 ) then
						fukiyaArr[ #fukiyaArr + 1 ] = id
						foundFukiya = true
					end
				end
			elseif ( objType == NEEDLE_TYPE ) then
				local charges = GetCharges( id )
				if ( type( charges ) == "table" and #charges > 1 ) then
					local charge = charges[2]
					if ( type( charge ) == "number" and charge > 0 ) then
						needleArr[ #needleArr + 1 ] = id
						foundNeedle = true
					end
				end
			end
		end
		if ( foundFukiya and foundNeedle ) then
			return fukiyaArr, needleArr
		end
	end

	return false
end

ClfActions.LoadFukiyaDelta = 0
function ClfActions.p_autoLoadFukiya( timePassed )
	if ( ClfActions.LoadFukiyaEnable ) then
		local delta = ClfActions.LoadFukiyaDelta + timePassed
		local duration = 0.35
		if ( delta >= duration ) then
			local fukiyaArr, needleArr = ClfActions.p_getFukiyaAndNeedles()

			if ( not fukiyaArr or not needleArr or #fukiyaArr < 1 or #needleArr < 1 ) then
				ClfActions.LoadFukiyaEnable = false
				ClfActions.LoadFukiyaDelta = 0
				HandleSingleLeftClkTarget(0)
				if ( ClfActions.LoadFukiyaMsgEnable ) then
					WindowUtils.SendOverheadText( L"loadFukiya: END", 150, true )
				end
				return
			end

			if ( WindowData.Cursor and WindowData.Cursor.target == true ) then
				HandleSingleLeftClkTarget( needleArr[1] )
				ClfActions.LoadFukiyaDelta = 0
			else
				-- 装填
				ContextMenu.RequestContextAction( fukiyaArr[1], 703 )
				ClfActions.LoadFukiyaDelta = duration - 0.1
			end
		else
			ClfActions.LoadFukiyaDelta = delta
		end
	end
end



function ClfActions.toggleAFKmode()
	ClfActions.AFKmode = not ClfActions.AFKmode
	local onOffStr = L"OFF"
	local hue = 150
	local win = "ClfAFKmodeWin"
	if ( ClfActions.AFKmode ) then
		if ( not DoesWindowExist( win ) ) then
			CreateWindow( win, true )
		end
		AttachWindowToWorldObject( WindowData.PlayerStatus.PlayerId, win )
		LabelSetText( win .. "Label", L"AFKmode" )
		onOffStr = L"ON"
		hue = 1152
	else
		if ( DoesWindowExist( win ) ) then
			DestroyWindow( win )
		end
	end
	WindowUtils.SendOverheadText( L"AFKmode: " .. onOffStr, hue, true )
end

ClfActions.AFKmode = false
ClfActions.AFKmodeDelta = 300
function ClfActions.p_massAFKmode( timePassed )
	if ( ClfActions.AFKmode ) then
		ClfActions.AFKmodeDelta = ClfActions.AFKmodeDelta + timePassed
		if ( ClfActions.AFKmodeDelta >= 300 ) then
			ClfActions.AFKmodeDelta = 0 + math.random(60)
			local speaks = { L",", L"*", L"_", L"-", L"?" }
			local speak = speaks[ math.random( #speaks + 1 ) ] or L"."
			SendChat( L"/say", L"; " .. speak )
		end
	end
end

