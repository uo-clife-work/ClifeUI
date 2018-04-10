ClfTextParse = {}

-- ペット訓練状況の頭上テキストを非表示にするか
ClfTextParse.DisablePetProgressMsg = false

-- 自分、ペット、パーティメンバー以外の毒状態頭上テキストを非表示にするか
ClfTextParse.DisablePoisonMsg = false


-- ペット訓練状況のtextID
ClfTextParse.TID_PET_PROGRESS = {
	[1157564] = true,	-- "*それは訓練にならないようです*"
	[1157565] = true,	-- "*ペットの経験値が少しだけ増加しました！*"
	[1157573] = true,	-- "*ペットの経験値がそこそこ増加しました！*"
	[1157574] = true,	-- "*ペットの経験値が大幅に増加しました！*"
}

-- 自分以外の毒状態メッセージのtextID
ClfTextParse.TID_POISON_MSG = {
	[1042858] = true,	-- "*~1_PLAYER_NAME~ は少し気分が悪くなってきた！*"	Lv.1
	[1042860] = true,	-- "* ~1_PLAYER_NAME~ は吐き気がしてきた！！ *"	Lv.2
	[1042862] = true,	-- "* ~1_PLAYER_NAME~ は全身が痛い！！！ *"	Lv.3
	[1042864] = true,	-- "* ~1_PLAYER_NAME~ に耐え難い痛み！！！！ *"	Lv.4
	[1042866] = true,	-- "* ~1_PLAYER_NAME~ が！！！！！*"	Lv.5
	[1042867] = true,	-- "* ~1_PLAYER_NAME~ に吐き気！！ *"	Lv.2
	[1042868] = true,	-- "* ~1_PLAYER_NAME~ に全身痛！！！ *"	Lv.3
	[1042869] = true,	-- "* ~1_PLAYER_NAME~ に大激痛！！！！ *"	Lv.4
	[1042870] = true,	-- "* ~1_PLAYER_NAME~ が！！！！！*"	Lv.5
}

-- オリジナルの OverheadText.ShowOverheadText を保持する （オーバーライドしたメソッド内で実行する）
ClfTextParse.showOverheadText_Org = nil


function ClfTextParse.initialize()
	if ( not ClfTextParse.showOverheadText_Org ) then
		ClfTextParse.showOverheadText_Org = OverheadText.ShowOverheadText
		OverheadText.ShowOverheadText = ClfTextParse.preShowOverheadText
	end

	ClfTextParse.DisablePetProgressMsg = Interface.LoadBoolean( "ClfDisablePetProgressMsg", ClfTextParse.DisablePetProgressMsg )
	if ( ClfTextParse.DisablePetProgressMsg ) then
		Debug.PrintToChat( L"Pet Progress Msg: OFF" )
	end

	ClfTextParse.DisablePoisonMsg = Interface.LoadBoolean( "ClfDisablePoisonMsg", ClfTextParse.DisablePoisonMsg )
	if ( ClfTextParse.DisablePoisonMsg ) then
		Debug.PrintToChat( L"Other Poison Msg: OFF" )
	end
end

-- ペット訓練状況の頭上テキスト表示・非表示を切替
function ClfTextParse.togglePetProgressMsg()
	local enable = not ClfTextParse.DisablePetProgressMsg
	ClfTextParse.DisablePetProgressMsg = enable
	Interface.SaveBoolean( "ClfDisablePetProgressMsg", enable )

	local onOffStr = L"ON"
	local hue = 1152

	if ( enable ) then
		onOffStr = L"OFF"
		hue = 150
	end

	WindowUtils.SendOverheadText( L"Pet Progress Msg: " .. onOffStr, hue, true )
end

-- 毒状態メッセージ頭上テキスト表示・非表示を切替
function ClfTextParse.togglePoisonMsg()
	local enable = not ClfTextParse.DisablePoisonMsg
	ClfTextParse.DisablePoisonMsg = enable
	Interface.SaveBoolean( "ClfDisablePoisonMsg", enable )

	local onOffStr = L"ON"
	local hue = 1152

	if ( enable ) then
		onOffStr = L"OFF"
		hue = 150
	end

	WindowUtils.SendOverheadText( L"Other Poison Msg: " .. onOffStr, hue, true )
end


-- OverheadText.ShowOverheadText をオーバーライドするメソッド
function ClfTextParse.preShowOverheadText()
	local textId = SystemData.TextID
	local mobileId = SystemData.TextSourceID

	if ( ClfTextParse.DisablePetProgressMsg ) then
		-- ペット訓練状況の頭上テキストを非表示にする
		if ( textId and ClfTextParse.TID_PET_PROGRESS[ textId ] ) then
			if ( mobileId and IsObjectIdPet( mobileId ) ) then
				return
			end
		end
	end

	if ( ClfTextParse.DisablePoisonMsg ) then
		-- 自分、ペット、パーティメンバー以外の毒状態頭上テキストを非表示にする
		if ( textId and ClfTextParse.TID_POISON_MSG[ textId ] ) then
			local FiendlyIds = ClfActions and ClfActions.FiendlyIds or {}
			if (
					not mobileId
					or not (
						IsObjectIdPet( mobileId )
						or IsPartyMember( mobileId )
						or FiendlyIds[ mobileId ]
					)
				) then
				return
			end
		end
	end

	-- オリジナルの ShowOverheadText を実行
	ClfTextParse.showOverheadText_Org()
end

