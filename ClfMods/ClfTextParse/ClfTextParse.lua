ClfTextParse = {}

-- ペット訓練状況の頭上テキストを非表示にするか
ClfTextParse.DisablePetProgressMsg = false

-- 自分、ペット、パーティメンバー以外の毒状態頭上テキストを非表示にするか
ClfTextParse.DisablePoisonMsg = false


local CONST = {
	TID_PET_PROGRESS = {
		-- ペット訓練状況のtextID
		[1157564] = true,	-- "*それは訓練にならないようです*"
		[1157565] = true,	-- "*ペットの経験値が少しだけ増加しました！*"
		[1157573] = true,	-- "*ペットの経験値がそこそこ増加しました！*"
		[1157574] = true,	-- "*ペットの経験値が大幅に増加しました！*"
	},
	TID_POISON_MSG = {
		-- 自分以外の毒状態メッセージのtextID
		[1042858] = true,	-- "*~1_PLAYER_NAME~ は少し気分が悪くなってきた！*"	Lv.1
		[1042860] = true,	-- "* ~1_PLAYER_NAME~ は吐き気がしてきた！！ *"	Lv.2
		[1042862] = true,	-- "* ~1_PLAYER_NAME~ は全身が痛い！！！ *"	Lv.3
		[1042864] = true,	-- "* ~1_PLAYER_NAME~ に耐え難い痛み！！！！ *"	Lv.4
		[1042866] = true,	-- "* ~1_PLAYER_NAME~ が！！！！！*"	Lv.5
		[1042867] = true,	-- "* ~1_PLAYER_NAME~ に吐き気！！ *"	Lv.2
		[1042868] = true,	-- "* ~1_PLAYER_NAME~ に全身痛！！！ *"	Lv.3
		[1042869] = true,	-- "* ~1_PLAYER_NAME~ に大激痛！！！！ *"	Lv.4
		[1042870] = true,	-- "* ~1_PLAYER_NAME~ が！！！！！*"	Lv.5
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


-- オリジナルの OverheadText.ShowOverheadText を保持する （オーバーライドしたメソッド内で実行する）
ClfTextParse.showOverheadText_Org = nil

-- オリジナルの Override OverheadText.UpdateName を保持する （オーバーライドしたメソッド内で実行する）
ClfTextParse.overheadTextUpdateName_org = nil


function ClfTextParse.initialize()
	ClfYouSee.initialize()

	if ( not ClfTextParse.showOverheadText_Org ) then
		ClfTextParse.showOverheadText_Org = OverheadText.ShowOverheadText
		OverheadText.ShowOverheadText = ClfTextParse.preShowOverheadText
	end

	if ( ClfTextParse.overheadTextUpdateName_org == nil ) then
		ClfTextParse.overheadTextUpdateName_org = OverheadText.UpdateName
		OverheadText.UpdateName = ClfTextParse.overheadTextOnUpdateName
	end

	ClfTextParse.DisablePetProgressMsg = Interface.LoadBoolean( "ClfDisablePetProgressMsg", ClfTextParse.DisablePetProgressMsg )
	if ( ClfTextParse.DisablePetProgressMsg ) then
		Debug.PrintToChat( L"Pet Progress Msg: OFF" )
	end

	ClfTextParse.DisablePoisonMsg = Interface.LoadBoolean( "ClfDisablePoisonMsg", ClfTextParse.DisablePoisonMsg )
	if ( ClfTextParse.DisablePoisonMsg ) then
		Debug.PrintToChat( L"Other Poison Msg: OFF" )
	end


	if ( ClfTextParse.DUMP_TEXT ) then
		ClfTextParse.initDumpTextLog()
		RegisterEventHandler( SystemData.Events.TEXT_ARRIVED, "ClfTextParse.onTextAlive" )
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


-- ** Override OverheadText.UpdateName
function ClfTextParse.overheadTextOnUpdateName( mobileId )
	--[[
	MEMO:
	死体の名前が表示出来ない事が多い（一旦画面外に出る前or共有棺桶になる前は表示出来ない）
	※ 2018.08.11 標準UIでも同様だった。そんな動作だったっけ？？
	]]
	local chatData = OverheadText.ChatData[ mobileId ]
	if ( chatData == nil or chatData.showName == false ) then
		return
	end

	local windowName = "OverheadTextWindow_" .. mobileId
	if ( DoesWindowExist( windowName ) == false ) then
		return
	end

	WindowSetShowing( windowName, false )

	if ( ClfUtil.filterMobileNameData( WindowData.MobileName[ mobileId ], mobileId, true ) ) then
		ClfTextParse.overheadTextUpdateNameCheked( mobileId )
		return
	else
		ClfCommon.addCheckListener(
			"overheadTextUpdateName" .. mobileId,
			{
				check = function()
					return ( ClfUtil.filterMobileNameData( WindowData.MobileName[ mobileId ], mobileId, false ) ~= nil )
				end,
				done = function( name )
					ClfTextParse.overheadTextUpdateNameCheked( mobileId )
				end,
				fail = function( name )
					ClfTextParse.overheadTextUpdateNameCheked( mobileId )
				end,
				begin = false,
				limit = ClfCommon.TimeSinceLogin + 8
			}
		)
	end
end



function ClfTextParse.overheadTextUpdateNameCheked( mobileId )
	-- オリジナルの OverheadText.UpdateName を実行
	ClfTextParse.overheadTextUpdateName_org( mobileId )

	-- add You see:
	ClfYouSee.output( mobileId )
end


function ClfTextParse.printChat( text, channel, enable, data )
	if ( enable ) then
		PrintWStringToChatWindow( text, channel )
	end
end


-- OverheadText.ShowOverheadText をオーバーライドするメソッド
function ClfTextParse.preShowOverheadText()
	local textId = SystemData.TextID
	local mobileId = SystemData.TextSourceID

	if ( ClfTextParse.DisablePetProgressMsg ) then
		-- ペット訓練状況の頭上テキストを非表示にする
		if ( textId and CONST.TID_PET_PROGRESS[ textId ] ) then
			if ( mobileId and IsObjectIdPet( mobileId ) ) then
				return
			end
		end
	end

	if ( ClfTextParse.DisablePoisonMsg ) then
		-- 自分、ペット、パーティメンバー以外の毒状態頭上テキストを非表示にする
		if ( textId and CONST.TID_POISON_MSG[ textId ] ) then
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

