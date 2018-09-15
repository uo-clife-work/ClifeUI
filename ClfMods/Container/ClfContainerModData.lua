
ClfContnrWinData = {}


local CONST_DATA = {

	-- プロパティ文字に付ける色の種類： 背景が明るい時用
	TxtColors_Dark = {
		default  = { r =   0, g =  15, b =  65 },
		note     = { r =  80, g =  85, b =  90 },
		caution  = { r = 160, g = 100, b =   5 },
		warn     = { r = 210, g =  65, b =  40 },
		blue     = { r =   0, g = 120, b = 255 },
		green    = { r =  50, g = 130, b =   0 },
		artifact = { r = 180, g =  30, b = 255 },
		artifLow = { r = 130, g =  60, b = 190 },
		antique  = { r = 160, g = 100, b =   5 },
		cursed   = { r = 210, g =  65, b =  40 },
		unwieldy = { r = 210, g =  65, b =  40 },
	},

	-- プロパティ文字に付ける色の種類： リストビュー＆背景が暗い時用
	TxtColors_Light = {
		default  = { r = 255, g = 255, b = 255 },
		note     = { r = 180, g = 185, b = 190 },
		caution  = { r = 210, g = 150, b =  50 },
		warn     = { r = 255, g =  80, b =  70 },
		blue     = { r =  70, g = 190, b = 255 },
		green    = { r = 125, g = 210, b =  75 },
		artifact = { r = 255, g = 105, b = 255 },
		artifLow = { r = 205, g = 135, b = 255 },
		antique  = { r = 210, g = 150, b =  50 },
		cursed   = { r = 255, g =  80, b =  70 },
		unwieldy = { r = 255, g =  80, b =  70 },
	},

	-- アイテムアイコンを着色するhueID
	HueTbl = {
		gold     = 1177,
		fire     = 1260,
		blaze    = 1174,
		ice      = 1152,
		blue     = 1165,
		pink     = 1166,
		green    = 1167,
		yellow   = 1169,
		purple   = 1170,
		mjBlue   = 1289,
		mjRed    = 1287,
		mjPurple = 1283,
		fadeBlue = 2066,
		bronze   = 2951,
		alabast  = 2962,
		jade     = 2965,
		grey     = 855,
	},

	-- tID（に紐付けたキー）の有無だけで判定するプロパティ
	UniqueCondTbl = {
		{	-- アーティファクト（低級
			key = "artifactLower", text = "Lwr AF", priority = 5000, doBreak = nil, color = "artifLow",
		},
		{	-- アーティファクト（中級
			key = "artifactMid", text = "Mid AF", priority = 5000, doBreak = nil, color = "artifLow",
		},
		{	-- アーティファクト（上級
			key = "artifactUpper", text = "Upr AF", priority = 5000, doBreak = nil, color = "artifact",
		},
		{	-- アーティファクト（伝説級
			key = "artifactLegend", text = "Legend AF", priority = 5000, doBreak = nil, color = "artifact", hue = "pink",
		},

		{	-- フルセット装備
			key = "fullSetProp", text = "SetEquip", priority = 0, doBreak = nil, color = "green",
		},

		{ 	-- ミナクスAFのアイテム名用tID
			key = "minaxAF", text = "MinaxAF", priority = 0, doBreak = true, color = "note",
		},
		{ 	-- ブラックソンAFのアイテム名用tID
			key = "blackthornAF", text = "BlackthornAF", priority = 0, doBreak = true, color = "note",
		},
		{ 	-- 特殊ヘアカラーのアイテム名用tID
			key = "splHairDye", text = nil, priority = 0, doBreak = true, useRawText = true, color = "note",
		},

		{	-- トレハン地図 Lv.1（解読前）
			key = "mapLv1", text = "L.1", priority = 0, doBreak = true, relation = "MapFacet", color = "note",
		},
		{	-- トレハン地図 Lv.2（解読前）
			key = "mapLv2", text = "L.2", priority = 0, doBreak = true, relation = "MapFacet", color = "note",
		},
		{	-- トレハン地図 Lv.3（解読前）
			key = "mapLv3", text = "L.3", priority = 0, doBreak = true, relation = "MapFacet", color = "note",
		},
		{	-- トレハン地図 Lv.4（解読前）
			key = "mapLv4", text = "L.4", priority = 0, doBreak = true, relation = "MapFacet", color = "note",
		},
		{	-- トレハン地図 Lv.5（解読前）
			key = "mapLv5", text = "L.5", priority = 0, doBreak = true, relation = "MapFacet", color = "note",
		},
		{	-- トレハン地図 Lv.6（解読前）
			key = "mapLv6", text = "L.6", priority = 0, doBreak = true, relation = "MapFacet", color = "artifLow",
		},
		{	-- トレハン地図 Lv.7（解読前）
			key = "mapLv7", text = "L.7", priority = 0, doBreak = true, relation = "MapFacet", color = "artifact",
		},

		{	-- トレハン地図 Lv.1（解読後）
			key = "mapLv1Decoded", text = "L.1", priority = 1, doBreak = nil, relation = "MapFacet", color = "caution",
		},
		{	-- トレハン地図 Lv.2（解読後）
			key = "mapLv2Decoded", text = "L.2", priority = 1, doBreak = nil, relation = "MapFacet", color = "caution",
		},
		{	-- トレハン地図 Lv.3（解読後）
			key = "mapLv3Decoded", text = "L.3", priority = 1, doBreak = nil, relation = "MapFacet", color = "caution",
		},
		{	-- トレハン地図 Lv.4（解読後）
			key = "mapLv4Decoded", text = "L.4", priority = 1, doBreak = nil, relation = "MapFacet", color = "caution",
		},
		{	-- トレハン地図 Lv.5（解読後）
			key = "mapLv5Decoded", text = "L.5", priority = 1, doBreak = nil, relation = "MapFacet", color = "caution",
		},
		{	-- トレハン地図 Lv.6（解読後）
			key = "mapLv6Decoded", text = "L.6", priority = 1, doBreak = nil, relation = "MapFacet", color = "caution",
		},
		{	-- トレハン地図 Lv.6（解読後）
			key = "mapLv7Decoded", text = "L.7", priority = 1, doBreak = nil, relation = "MapFacet", color = "caution",
		},

		{	-- トレハン地図 発掘者（解読後の発掘済み地図に付く）
			key = "excavator", text = nil, priority = 0, doBreak = true, useRawText = true, color = "caution",
		},

		{	-- 魔法のリンゴ（果樹園）のアイテム名用tID
			key = "magicApple", text = nil, priority = 0, doBreak = true, useRawText = true, color = nil,
		},
	},


	-- 条件判定に依って表示するプロパティ：アイテムの種類問わず
	CondTblAlways = {
		{ 	-- Cursed
			key = "cursed", priority = 99999,
			minVal =   nil, useRawText = true, prefix = "", suffix =  "", doBreak = nil, color = "cursed",
		},
		{ 	-- 短命
			key = "antique", priority = 99999,
			minVal =   nil, useRawText = true, prefix = "", suffix =  "", doBreak = nil, color = "antique",
		},
--		{ 	-- マナ回復
--			key = "manaRegene", priority = 5, hue = nil,
--			minVal =   4, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
--		},
		{ 	-- レアリティ
			key = "rarity", priority = 0, hue = nil,
			minVal =   0, useRawText = nil, prefix = "Rare:", suffix =  "", doBreak = true, color = nil,
		},
		{ 	-- 幸運
			key = "luck", priority = 10, hue = "gold",
			minVal = 120, useRawText = nil, prefix =  "Luc:", suffix =  "", doBreak = nil, color = nil,
		},
		{ 	-- 秘薬コスト
			key = "reagentCost", priority = 15, hue = nil,
			minVal = 21, useRawText = nil, prefix =  "LRC:", suffix =  "%", doBreak = nil, color = nil,
		},
		{ 	-- キャストリカバリ
			key = "cr", priority = 20, hue = nil,
			minVal = 4, useRawText = nil, prefix =  "CR:", suffix =  "", doBreak = nil, color = nil,
		},
	},

	-- 条件判定に依って表示するプロパティ：アイテムの種類別
	CondTblFor = {
		Acce = {	-- アクセサリーの時に判定するプロパティ
			{ 	--  速度増加
				key = "ssi", priority = 2, hue = "ice",
				minVal =   6, useRawText = nil, prefix = "SSI:", suffix = "%", doBreak = nil, color = "blue",
			},
			{ 	--  速度増加
				key = "ssi", priority = 3, hue = nil,
				minVal =   0, useRawText = nil, prefix = "SSI:", suffix = "%", doBreak = nil, color = "blue",
			},
			{ 	-- 命中
				key = "hci", priority = 15, hue = nil,
				minVal =   20, useRawText = nil, prefix = "HCI:", suffix = "%", doBreak = nil, color = nil
			},
			{ 	-- 回避
				key = "dci", priority = 17, hue = nil,
				minVal =   20, useRawText = nil, prefix = "DCI:", suffix = "%", doBreak = nil, color = nil
			},
			{ 	-- 武器ダメージ増加
				key = "damageInc", priority = 20, hue = nil,
				minVal =   26, useRawText = nil, prefix = "Dmg:", suffix = "%", doBreak = nil, color = nil,
			},

			{ 	-- 魔法ダメージ
				key = "spellDamage", priority = 21, hue = nil,
				minVal =   13, useRawText = nil, prefix = "MDm:", suffix = "%", doBreak = nil, color = nil,
			},

			{ 	-- スタミナ
				key = "stamina", priority = 22, hue = nil,
				minVal =   8, useRawText = nil, prefix = "Stm:", suffix = "", doBreak = nil, color = nil,
			},
			{ 	-- キャストリカバリ
				key = "cr", priority = 25, hue = nil,
				minVal = 3, useRawText = nil, prefix =  "CR:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- マナ回復
				key = "manaRegene", priority = 24, hue = nil,
				minVal =   3, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},

			{ 	-- 命中
				key = "hci", priority = 30, hue = nil,
				minVal =   15, useRawText = nil, prefix = "HCI:", suffix = "%", doBreak = nil, color = nil
			},
			{ 	-- 回避
				key = "dci", priority = 31, hue = nil,
				minVal =   15, useRawText = nil, prefix = "DCI:", suffix = "%", doBreak = nil, color = nil
			},
			{ 	-- 武器ダメージ増加
				key = "damageInc", priority = 32, hue = nil,
				minVal =   25, useRawText = nil, prefix = "Dmg:", suffix = "%", doBreak = nil, color = nil,
			},

			{ 	-- 魔法ダメージ
				key = "spellDamage", priority = 33, hue = nil,
				minVal =   12, useRawText = nil, prefix = "MDm:", suffix = "%", doBreak = nil, color = nil,
			},

			{ 	-- スキル グループ1 （魔法、音楽、メイス、ソード、フェンシング）
				key = "skillGroup1", priority = 101, hue = nil,
				minVal = 15, useRawText = true, prefix =  "", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- スキル グループ2 （Tac、テイム、格闘、扇動、霊話）
				key = "skillGroup2", priority = 102, hue = nil,
				minVal = 15, useRawText = true, prefix =  "", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- スキル グループ3 （受け流し、瞑想、動物学、フォーカス、ステルス、不調和）
				key = "skillGroup3", priority = 103, hue = nil,
				minVal = 15, useRawText = true, prefix =  "", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- スキル グループ4 （武士道、獣医学、EI、アナトミ、ネクロ、窃盗、神秘）
				key = "skillGroup4", priority = 104, hue = nil,
				minVal = 15, useRawText = true, prefix =  "", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- スキル グループ5 （騎士道、忍術、沈静化、包帯、弓術、投擲、耐性）
				key = "skillGroup5", priority = 100, hue = nil,
				minVal = 15, useRawText = true, prefix =  "", suffix =  "", doBreak = nil, color = nil,
			},
		},

		Talis = {	-- タリスマンの時に判定するプロパティ
			{ 	--  速度増加
				key = "ssi", priority = 2, hue = "ice",
				minVal =   0, useRawText = nil, prefix = "SSI:", suffix = "%", doBreak = nil, color = "blue",
			},
			{ 	-- 武器ダメージ増加
				key = "damageInc", priority = 10, hue = nil,
				minVal =   0, useRawText = nil, prefix = "Dmg:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 命中
				key = "hci", priority = 15, hue = nil,
				minVal =   4, useRawText = nil, prefix = "HCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 回避
				key = "dci", priority = 17, hue = nil,
				minVal =   4, useRawText = nil, prefix = "DCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナ回復
				key = "manaRegene", priority = 20, hue = nil,
				minVal =   1, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- マナコスト
				key = "manaCost", priority = 21, hue = nil,
				minVal =   1, useRawText = nil, prefix = "LMC:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- 高品質ボーナス
				key = "craftBonusHq", priority = 5, hue = nil,
				minVal =   20, useRawText = nil, prefix = "Hq:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- 成功ボーナス
				key = "craftBonus", priority = 6, hue = nil,
				minVal =   20, useRawText = nil, prefix = "Bns:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- 特効
				key = "slayer", priority = 1, hue = nil,
				minVal =   nil, useRawText = true, prefix = "", suffix =  "", doBreak = nil, color = nil,
			},

		},

		OneHand = {	-- 武器（片手用）の時に判定するプロパティ
			{ 	-- ライフリーチ
				key = "lifeLeach", priority = 11, hue = nil,
				minVal =   80, useRawText = nil, prefix = "HLL:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナリーチ
				key = "manaLeach", priority = 9, hue = nil,
				minVal =   80, useRawText = nil, prefix = "HML:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナダウン
				key = "manaDown", priority = 10, hue = nil,
				minVal =   60, useRawText = nil, prefix = "HMD:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 回避低下
				key = "hld", priority = 11, hue = nil,
				minVal =   50, useRawText = nil, prefix = "HLD:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 命中低下
				key = "hla", priority = 12, hue = nil,
				minVal =   50, useRawText = nil, prefix = "HLA:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナ回復
				key = "manaRegene", priority = 13, hue = nil,
				minVal =   6, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- 特効
				key = "slayer", priority = 15, hue = nil,
				minVal =   nil, useRawText = true, prefix = "", suffix =  "", doBreak = nil, color = nil,
			},
		},

		TwoHand = {	-- 武器（両手用）の時に判定するプロパティ
			{ 	-- ライフリーチ
				key = "lifeLeach", priority = 11, hue = nil,
				minVal =   80, useRawText = nil, prefix = "HLL:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナリーチ
				key = "manaLeach", priority = 9, hue = nil,
				minVal =   80, useRawText = nil, prefix = "HML:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナダウン
				key = "manaDown", priority = 10, hue = nil,
				minVal =   60, useRawText = nil, prefix = "HMD:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 回避低下
				key = "hld", priority = 11, hue = nil,
				minVal =   50, useRawText = nil, prefix = "HLD:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 命中低下
				key = "hla", priority = 12, hue = nil,
				minVal =   50, useRawText = nil, prefix = "HLA:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナ回復
				key = "manaRegene", priority = 13, hue = nil,
				minVal =   7, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- 特効
				key = "slayer", priority = 15, hue = nil,
				minVal =   nil, useRawText = true, prefix = "", suffix =  "", doBreak = nil, color = nil,
			},
		},

		Armor = {	-- 防具の時に判定するプロパティ
			{ 	--  速度増加
				key = "ssi", priority = 2, hue = "ice",
				minVal =   0, useRawText = nil, prefix = "SSI:", suffix = "%", doBreak = nil, color = "blue",
			},
			{ 	-- 武器ダメージ増加
				key = "damageInc", priority = 10, hue = nil,
				minVal =   0, useRawText = nil, prefix = "Dmg:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 命中
				key = "hci", priority = 15, hue = nil,
				minVal =   4, useRawText = nil, prefix = "HCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 回避
				key = "dci", priority = 20, hue = nil,
				minVal =   4, useRawText = nil, prefix = "DCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- ヒットポイント
				key = "hitPoint", priority = 11, hue = nil,
				minVal =   8, useRawText = nil, prefix = "HP:", suffix = "", doBreak = nil, color = nil,
			},
			{ 	-- STR
				key = "str", priority = 19, hue = nil,
				minVal =   5, useRawText = nil, prefix = "STR:", suffix = "", doBreak = nil, color = nil,
			},
			{ 	-- スタミナ
				key = "stamina", priority = 17, hue = nil,
				minVal =   8, useRawText = nil, prefix = "Stm:", suffix = "", doBreak = nil, color = nil,
			},
			{ 	-- DEX
				key = "dex", priority = 18, hue = nil,
				minVal =   5, useRawText = nil, prefix = "DEX:", suffix = "", doBreak = nil, color = nil,
			},
			{ 	-- マナ回復
				key = "manaRegene", priority = 5, hue = nil,
				minVal =   4, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},
		},

		Shield = {	-- シールドの時に判定するプロパティ
			{ 	-- 回避
				key = "dci", priority = 17, hue = nil,
				minVal =   15, useRawText = nil, prefix = "DCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナ回復
				key = "manaRegene", priority = 5, hue = nil,
				minVal =   4, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},
		},

		Equip = {	-- その他の装備品の時に判定するプロパティ
			{ 	--  速度増加
				key = "ssi", priority = 2, hue = "ice",
				minVal =   0, useRawText = nil, prefix = "SSI:", suffix = "%", doBreak = nil, color = "blue",
			},
			{ 	-- 武器ダメージ増加
				key = "damageInc", priority = 10, hue = nil,
				minVal =   0, useRawText = nil, prefix = "Dmg:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 命中
				key = "hci", priority = 15, hue = nil,
				minVal =   4, useRawText = nil, prefix = "HCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 回避
				key = "dci", priority = 17, hue = nil,
				minVal =   4, useRawText = nil, prefix = "DCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- マナ回復
				key = "manaRegene", priority = 5, hue = nil,
				minVal =   4, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},
		},

		Other = {	-- 上記以外の時に判定するプロパティ
			{ 	-- 特効
				key = "slayer", priority = 1, hue = nil,
				minVal =   nil, useRawText = true, prefix = "", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	--  速度増加
				key = "ssi", priority = 2, hue = "ice",
				minVal =   0, useRawText = nil, prefix = "SSI:", suffix = "%", doBreak = nil, color = "blue",
			},
			{ 	-- 武器ダメージ増加
				key = "damageInc", priority = 10, hue = nil,
				minVal =   0, useRawText = nil, prefix = "Dmg:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 命中
				key = "hci", priority = 15, hue = nil,
				minVal =   4, useRawText = nil, prefix = "HCI:", suffix = "%", doBreak = nil, color = nil,
			},
			{ 	-- 回避
				key = "dci", priority = 17, hue = nil,
				minVal =   4, useRawText = nil, prefix = "DCI:", suffix = "%", doBreak = nil, color = nil,
			},

			{ 	-- マナ回復
				key = "manaRegene", priority = 20, hue = nil,
				minVal =   1, useRawText = nil, prefix = "MnR:", suffix =  "", doBreak = nil, color = nil,
			},
			{ 	-- マナコスト
				key = "manaCost", priority = 21, hue = nil,
				minVal =   1, useRawText = nil, prefix = "LMC:", suffix =  "", doBreak = nil, color = nil,
			},

			{	-- 呪文数
				key = "numOfSpell", priority = 50,
				text = nil, useRawText = nil, prefix =  "(", suffix =  ")",  doBreak = true,  color = "note",
			},
			{	-- ［オン］：知識の水晶玉 etc
				key = "switchOn", priority = 52,
				text = nil, useRawText = true, prefix =  "", suffix =  "",  doBreak = nil,  color = "note",
			},
			{	-- ［オフ］：知識の水晶玉 etc
				key = "switchOff", priority = 51,
				text = nil, useRawText = true, prefix =  "", suffix =  "",  doBreak = nil,  color = "note",
			},
		},

	},

	RelationTable = {
		MapFacet = {
			{	-- ファセット : トランメル
				key = "mapfacetTrammel", text = "Trammel",
			},
			{	-- ファセット : フェルッカ
				key = "mapfacetFelucca", text = "Felucca",
			},
			{	-- ファセット : イルシェナー
				key = "mapfacetIlshenar", text = "ilshenar",
			},
			{	-- ファセット : マラス
				key = "mapfacetMalas", text = "Malas",
			},
			{	-- ファセット : 徳之諸島
				key = "mapfacetTokuno", text = "Tokuno",
			},
			{	-- ファセット : テルマー
				key = "mapfacetTermur", text = "TerMur",
			},
		},
	},

}


function ClfContnrWinData.getData( key )
	return CONST_DATA[ key ]
end

