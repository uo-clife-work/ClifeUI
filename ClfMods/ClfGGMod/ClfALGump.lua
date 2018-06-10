
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfGGMod", "ClfALGumpWindow.xml", "ClfALGumpWindow.xml" )

ClfALGump = {}


ClfALGump.LoreDatas = {}

ClfALGump.Enable = true

-- ロアデータをログ出力するか
ClfALGump.SaveLogEnable = true

-- ロアデータのログ出力間隔（前回書き出しから下記秒経過するまでは再度書き出ししない）
-- ※ 最大ステータス値or現在スキル値が変動した時は間隔に関係無く出力される
ClfALGump.EXPORT_DELTA = 60 * 60


ClfALGump.PetSlotTid = 1115783
ClfALGump.BaseDamageTid = 1076750

-- ステータス名のtid： キーをCreaturesDBに合わせておく
ClfALGump.StatusTids = {
	hits    = 1049578,
	stamina = 1049579,
	mana    = 1049580,
	str     = 1028335,
	dex     = 3000113,
	int     = 3000112,
}
-- ステータス回復名のtid：
ClfALGump.StatsRegeneTids = {
	regeneHits    = 1075627,
	regeneStamina = 1079411,
	regeneMana    = 1079410,
}
-- 属性抵抗名のtid： キーをCreaturesDBに合わせておく
ClfALGump.RegistTids = {
	physical = 1061646,
	fire     = 1061647,
	cold     = 1061648,
	poison   = 1061649,
	energy   = 1061650,
}
-- ダメージ属性名のtid
ClfALGump.DamageTids = {
	physical = 1061646,
	fire     = 1061647,
	cold     = 1061648,
	poison   = 1061649,
	energy   = 1061650,
}
-- スキル名のtid： キーをCreaturesDBに合わせておく
ClfALGump.SkillTids = {
	wrestling  = 1044103,
	tactics    = 1044087,
	resspell   = 1044086,
	anatomy    = 1044061,
	healing    = 1002082,
	poisoning  = 1002122,
	magery     = 1044085,
	evalint    = 1044076,
	meditation = 1044106,
	-- ここまで CreaturesDB に最低・最大値があるスキル

	parrying     = 1002118,
	necromancy   = 1044109,
	spiritspeak  = 1002140,
	mysticism    = 1044115,
	focus        = 1044110,
	spellweaving = 1044114,
	discordance  = 1044075,
	bushido      = 1044112,
	ninjitsu     = 1044113,
	chivalry     = 1044111,

	detecting    = 1002065,
	hiding       = 1002088,
}

ClfALGump.OtherTids = {
	fidelity    = 1049594,	-- 忠誠度
	wild        = 1061643,	-- 野生（忠誠度）
	needSkillLv = 1157600,	-- 要スキル: ~1_val~
	petProgress = 1157491,	-- ペット訓練進行状況
}

ClfALGump.TidKeys = nil

-- objectType
ClfALGump.ANIMAL_TYPES = nil
local ANIMAL_TYPE_ARRAY = {
	{ objectType = 10000292, name = "pack llama", },	-- hueId 0
	{ objectType = 10000106, name = "shadow wyrm", },	-- hueId 0
	{ objectType = 10000277, name = "cu sidhe", },
	{ objectType = 10000122, name = "unicorn", },
	{ objectType = 10000132, name = "ki-rin", },
	-- ナイトメア： SAクラだと色・姿の違いは無い（objectTypeは違う） レア色はhueIdが違う
	{ objectType = 10000116, name = "nightmare", },	-- hueId 0, 1910	// モヒカン（薄）
	{ objectType = 10000177, name = "nightmare", },	-- hueId 0, 1910	// モヒカン（濃）
	{ objectType = 10000178, name = "nightmare", },	-- hueId 0, 1910	// ロン毛
	{ objectType = 10000179, name = "nightmare", },	-- hueId 0, 1910	// 漆黒

	{ objectType = 10000190, name = "fire steed",   hueId = { 1161, }, },
	{ objectType = 10000794, name = "swamp dragon", hueId = { 34980, }, },	-- hueId 34980
	{ objectType = 10000794, name = "bane dragon",  hueId = { 33943, }, },	-- swamp dragonとhueId違い（ hueId 33943 ）
	{ objectType = 10001289, name = "najasaurus", },	-- hueId 0
	{ objectType = 10000276, name = "reptalon", },	-- hueId 0
	{ objectType = 10000791, name = "giant beetle", },	-- hueId 0
	{ objectType = 10000169, name = "fire beetle", },	-- hueId 1161
	{ objectType = 10000244, name = "rune beetle", },	-- hueId 0
	{ objectType = 10001291, name = "saurosaurus", },	-- hueId 0
	{ objectType = 10001425, name = "ossein ram", },	-- hueId 0
	{ objectType = 10000180, name = "white wyrm", },	-- hueId 0, 1150, ...
	{ objectType = 10000243, name = "lesser hiryu", },	-- 普通の飛龍も同じIDだけど、まぁいいか。。。
	{ objectType = 10000060, name = "cold drake",   excHueId = { 0, }, },	-- hueId 1317, 1350,
	{ objectType = 10000060, name = "drake",        hueId = { 0, }, },
	{ objectType = 10000061, name = "cold drake",   excHueId = { 0, }, },	-- hueId 1302, 1305, 1313, 1324, 1342, 1343, 1347,  etc.
}

local FIDELITY_RATES = {
	[1061643] = 0.5,	-- 野生

	[1049595] = 0,    -- 最悪
	[1049596] = 0.1,  -- 非常に低い
	[1049597] = 0.2,  -- 低い
	[1049598] = 0.25, -- やや低い
	[1049599] = 0.3,  -- 普通だが少し低い
	[1049600] = 0.35, -- 普通
	[1049601] = 0.4,  -- 普通だが少し高い
	[1049602] = 0.5,  -- やや高い
	[1049603] = 0.6,  -- 高い
	[1049604] = 0.8,  -- 非常に高い
	[1049605] = 1,    -- 最高
	[1049606] = 1,    -- Euphoric
}

local TRAINING_COSTS = {
	hits    = 3,
	stamina = 0.5,
	mana    = 0.5,
	str     = 3,
	dex     = 0.1,
	int     = 0.5,
	regists = 3,
}

local STATS_RAISING_CAP = 125

-- テイム後のステータス上限値 ※テイム時にステータスがこの値まで下げられる
ClfALGump.TAMED_STATS_CAPS = {
	stamina = 150,
}


ClfALGump.DEBUG_MODE = false

function ClfALGump.initialize()

	-- 標準UIの CreaturesDB のデータを追加・マージする
	local type = type
	local mergeTable = ClfUtil.mergeTable
	local creatures = ClfALGump.getClfCreaturesDB()
	local CreaturesDB = CreaturesDB
	for cName, data in pairs( creatures ) do
		local orgDB = CreaturesDB[ cName ] or {}
		if ( type( orgDB ) == "table" ) then
			CreaturesDB[ cName ] = mergeTable( orgDB, data )
		end
	end

	local enable = Interface.LoadBoolean( "ClfALGumpEnable", ClfALGump.Enable )
	ClfALGump.setEnable( enable, true )
end


-- 追加アニマルロアガンプの有効・無効の切り替え
function ClfALGump.toggle()
	ClfALGump.setEnable( not ClfALGump.Enable, false )
end


function ClfALGump.setEnable( enable, silent )
	local onOffStr = L"OFF"
	local hue = 150

	if ( enable ) then
		onOffStr = L"ON"
		hue = 1152

		if ( not ClfALGump.ANIMAL_TYPES ) then
			ClfALGump.ANIMAL_TYPES = {}
			local typeArr = ANIMAL_TYPE_ARRAY
			for i = 1, #typeArr do
				ClfALGump.ANIMAL_TYPES[ typeArr[ i ].objectType ] = true
			end
		end

		if ( not ClfALGump.TidKeys ) then
			ClfALGump.TidKeys = {}
			local tidsKeys = { "StatusTids", "RegistTids", "SkillTids" }
			for i = 1, #tidsKeys do
				local tids = ClfALGump[ tidsKeys[ i ] ]
				for key, tid in pairs( tids ) do
					ClfALGump.TidKeys[ tid ] = key
				end
			end
		end
	end

	ClfALGump.Enable = enable
	Interface.SaveBoolean( "ClfALGumpEnable", enable )
	if ( not silent ) then
		WindowUtils.SendOverheadText( L"ClfALGump " .. onOffStr, hue, true )
	end
end


-- データ更新 （アニマルロアガンプ表示時に ClfGGMod からコール）
function ClfALGump.updateGumpData( gumpData )
	if ( not ClfALGump.Enable or not gumpData or not gumpData.Labels ) then
		return false
	end

	local id = WindowData.Cursor and WindowData.Cursor.lastTarget
	if ( not id or not IsMobile( id ) ) then
		return false
	end

	local mobileData = Interface.GetMobileData( id, false )
	local mobName = mobileData and mobileData.MobName
	local texts = gumpData.Labels[1] and gumpData.Labels[1].text

	if ( not mobName or not texts or #texts < 1 ) then
		return
	end

	local DumpToConsole
	local devDump
	local devStr
	local deb
	if ( ClfALGump.DEBUG_MODE and ClfDebug ) then
		DumpToConsole = ClfDebug.DumpToConsole
		deb = L"\r\n\r\n"
		devDump = function( name, arg )
			deb = deb .. DumpToConsole( name, arg, nil, true )
		end
		devStr = function( str )
			deb = deb .. str
		end
	else
		DumpToConsole = function() return L"" end
		devDump = function() end
		devStr = function() end
	end

	local T = ClfALGump
	local gSub = wstring.gsub
	local wstrLower = wstring.lower

	local loreName = texts[1]
	loreName = loreName and gSub( loreName, L"<.->", L"" )
	if ( not loreName ) then
		return
	end

	RegisterWindowData( WindowData.ObjectInfo.Type, id )
	local objectData = WindowData.ObjectInfo[ id ] or {}
	local objectType = objectData.objectType
	local objectName = objectData.name or L""
	local hueId = objectData.hueId
	local hue = objectData.hue
	UnregisterWindowData( WindowData.ObjectInfo.Type, id )

	-- 動物ブローカーから「調べる」でロアガンプを開いた時など、idとgumpDataが一致しないので、各データから得た名前を比較
	-- mobileDataから取得した名前
	mobName = gSub( mobName, L"^%s*", L"" )
	if ( type( mobName ) == "wstring" ) then
		mobName = gSub( mobName, L"%s*$", L"" )
	else
		mobName = L""
	end
	-- gumpDataから取得した名前
	loreName = gSub( loreName, L"^%s*", L"" )
	if ( type( loreName ) == "wstring" ) then
		loreName = gSub( loreName, L"%s*$", L"" )
	else
		loreName = L""
	end
	-- objectDataから取得した名前
	objectName = gSub( objectName, L"^%s*", L"" )
	if ( type( objectName ) == "wstring" ) then
		objectName = gSub( objectName, L"%s*$", L"" )
	else
		objectName = L""
	end

	if ( wstrLower( mobName ) ~= wstrLower( loreName ) and wstrLower( objectName ) ~= wstrLower( loreName ) ) then
		-- ラストターゲットとアニマルロアの名前が一致しない： 何もせずに終了
		Debug.DumpToConsole( "mobName", mobName )
		Debug.DumpToConsole( "loreName", loreName )
		Debug.DumpToConsole( "objectName", objectName )
		return
	end


	devDump( "mobileData", mobileData )
	devStr( L" ------ \r\n")
	devDump( "AnimalLoreGumpData", gumpData )
	devStr( L" ------ \r\n")


	local GetStringFromTid = GetStringFromTid
	local type = type

	-- tId毎にテキストを紐付けたテーブルを作成
	local labels = gumpData.Labels
	local index = 0
	local textIndex = 1
	local labelsObjTbl = {}
	local tidsTbl = {}

	for i = 1, #labels do
		local label = labels[ i ]
		local tid = label.tid
		if ( tid ) then
			index = index +1
			local obj = {
				tid = tid,
				labelId = label.id,
			}

			if ( label.tidParms and #label.tidParms > 0 ) then
				obj.params = label.tidParms
			end

			local nextLabel = labels[ i + 1 ]
			if ( nextLabel ) then
				if ( nextLabel.text ) then
					textIndex = textIndex + 1

					local text = nextLabel.text[ textIndex ]
					if ( type( text ) == "wstring" ) then
						-- ガンプデータ中のテキストからタグを取り除く
						text = gSub( text, L"<[/a-zA-Z].->", L"" )
					end
					obj.text = text
				elseif ( nextLabel.tid ) then
					obj.relTid = nextLabel.tid
					local relTids = {}
					local nextId = i + 1
					while ( labels[ nextId ] ) do
						local nxt = labels[ nextId ]
						if ( nxt.tid ) then
							relTids[ #relTids + 1 ] = nxt.tid
							nextId = nextId + 1
						else
							break
						end
					end
					obj.relTids = relTids
				end
			end

			local tblIndex = #labelsObjTbl + 1
			if ( tidsTbl[ tid ] ) then
				tidsTbl[ tid ][ #tidsTbl[ tid ] + 1 ] = tblIndex
			else
				tidsTbl[ tid ] = { tblIndex }
			end
			labelsObjTbl[ tblIndex ] = obj

			devDump( "label[" .. i .. "].tid@".. label.tid , ttl )
		end
	end

	local explode = ClfUtil.explode
	local tonumber = tonumber
	local tostring = tostring
	local stringFormat = string.format
	local pairs = pairs
	local mathFloor = math.floor
	local mathMax = math.max
	local mathMin = math.min

	-- ClfALGump.LoreDatas に格納するデータ
	local loreData = {
		name = loreName,
		id = id,
		objectType = objectType,
		time = Interface.TimeSinceLogin or 0,
		hueId = hueId,
		hue = hue,
		hueSV = ClfUtil.rgbSV( hue ),
	}

	-- 自分のペットか
	local myPet = IsObjectIdPet( id )
	loreData.MyPet = myPet

	-- ペットスロット
	local petSlot = nil
	if ( tidsTbl[ T.PetSlotTid ] ) then
		local tIndex = tidsTbl[ T.PetSlotTid ][1]
		if ( tIndex ) then
			petSlot = labelsObjTbl[ tIndex ].text
		end
	end
	loreData.PetSlot = petSlot
	if ( petSlot ) then
		local petSlotVals = explode( L" => ", petSlot, false, true )
		if ( petSlotVals and #petSlotVals == 2 ) then
			loreData.PetSlotVals = {
				current = petSlotVals[ 1 ],
				max = petSlotVals[ 2 ],
			}
		end
	end

	-- 忠誠度
	local fidelity
	local fidelityRate
	local fidelityStateTid
	if ( tidsTbl[ T.OtherTids.fidelity ] ) then
		local tIndex = tidsTbl[ T.OtherTids.fidelity ][1]
		if ( tIndex ) then
			fidelityStateTid = labelsObjTbl[ tIndex ].relTid
			if ( fidelityStateTid ) then
				fidelity = GetStringFromTid( fidelityStateTid )
				fidelityRate = FIDELITY_RATES[ fidelityStateTid ]
			end
		end
	end

	-- テイム可能か、テイム後か判定
	local tamable = myPet
	local isTamed = myPet
	if ( myPet or petSlot or tidsTbl[ T.OtherTids.needSkillLv ]  ) then
		-- ペットスロット or 要スキルがある： テイム可能
		tamable = true
		if ( myPet or fidelityStateTid ~= T.OtherTids.wild ) then
			-- 忠誠度が野生では無い： テイム後
			isTamed = true
		end
	end
	loreData.Tamable = tamable
	loreData.IsTamed = isTamed
	loreData.Fidelity = fidelity
	loreData.FidelityRate = fidelityRate

	-- CreaturesDB にデータがあるか
	local creatureName, noMobDB = T.getName( objectData, id, isTamed )
	local mobDB = {}
	local hasMobDB = false
	local isRleased = false
	if ( creatureName and type( CreaturesDB[ creatureName ] ) == "table" ) then
		mobDB = CreaturesDB[ creatureName ]
		hasMobDB = true
		if ( noMobDB and not isTamed ) then
			-- 元の名前でDBが無かったにも関わらず、DBがあった。 → 恐らくリリースされたmob
			isRleased = true
		end
	end
	loreData.creatureName = creatureName
	loreData.hasMobDB = hasMobDB
	loreData.IsRleased = isRleased

	-- テイム後ステータス半減するか
	local doHalfstat = mobDB.halfstat
	loreData.Halfstat = doHalfstat

	-- ステータス半減前か
	local beforeHalfStat = ( doHalfstat and tamable and not isTamed and not isRleased )


	-- 訓練進行状況
	local petProgress
	if ( myPet and tidsTbl[ T.OtherTids.petProgress ] ) then
		local tIndex = tidsTbl[ T.OtherTids.petProgress ][1]
		if ( tIndex ) then
			local text = labelsObjTbl[ tIndex ].text
			local title = GetStringFromTid( T.OtherTids.petProgress )
			if ( text and title ) then
				petProgress = {
					title = title,
					text = text,
				}
			end
		end
	end
	loreData.petProgress = petProgress

	-- 訓練ポイントを保持
	local TrainingPoints = {
		Stats1 = {},
		Stats2 = {},
		Regist = {},
	}
	local TrainingPointsHalf = {
		Stats1 = {},
		Stats2 = {},
		Regist = {},
	}

	local statsCaps = tamable and ClfALGump.TAMED_STATS_CAPS or {}

	local status = {}
	-- ステータス： HP, Stamina, Mana
	local keys = { "hits", "stamina", "mana", }
	for i = 1, #keys do
		local key = keys[ i ]
		local tid = T.StatusTids[ key ]
		local tIndex = tidsTbl[ tid ] and tidsTbl[ tid ][1]
		local data = {}
		if ( tIndex ) then
			data = labelsObjTbl[ tIndex ].text
			data = data and explode( L"/", data, false, true ) or {}
		end

		local dbData = {}
		if ( mobDB[ key ] ) then
			dbData = explode( L" - ", mobDB[ key ], false, true )
			if ( doHalfstat and ( isTamed or isRleased ) and key ~= "mana" and dbData and #dbData >= 2 ) then
				dbData[1] = mathFloor( dbData[1] * 0.5 )
				dbData[2] = mathFloor( dbData[2] * 0.5 )
			end
		end

		local val = data[2] and tonumber( data[2] )
		status[ key ] = {
			val = val,
			max = data[2],
			current = data[1],
			lwr = dbData[1],
			upr = dbData[2],
		}

		-- 訓練ポイントを計算・保持
		if ( val ) then
			-- テイム可能な生物は、テイム後の上限までのポイントを算出
			local statCap = statsCaps[ key ]
			local tmpVal = statCap and mathMin( statCap, val ) or val
			TrainingPoints.Stats1[ key ] = tmpVal * TRAINING_COSTS[ key ] or nil
			if ( beforeHalfStat ) then
				-- ステータス半減後の訓練ポイント
				local sk = ( key ~= "mana" ) and 0.5 or 1
				tmpVal = mathFloor( val * sk )
				tmpVal = statCap and mathMin( statCap, tmpVal ) or tmpVal
				TrainingPointsHalf.Stats1[ key ] = tmpVal * TRAINING_COSTS[ key ]
			end
		end

	end

	-- ステータス： STR, DEX, INT
	keys = { "str", "dex", "int", }
	local pairStatKeys = { str = "hits", dex = "stamina", int = "mana", }

	for i = 1, #keys do
		local key = keys[ i ]
		local tid = T.StatusTids[ key ]
		local tIndex = tidsTbl[ tid ] and tidsTbl[ tid ][1]
		local data = nil
		if ( tIndex ) then
			data = labelsObjTbl[ tIndex ].text
			data = data and tonumber( data )
		end

		local dbData = {}
		if ( mobDB[ key ] ) then
			dbData = explode( L" - ", mobDB[ key ], false, true )
			if ( doHalfstat and ( isTamed or isRleased ) and key ~= "int" and dbData and #dbData >= 2 ) then
				dbData[1] = mathFloor( dbData[1] * 0.5 )
				dbData[2] = mathFloor( dbData[2] * 0.5 )
			end
		end

		status[ key ] = {
			val = data,
			lwr = dbData[1],
			upr = dbData[2],
		}

		-- 訓練ポイントを計算・保持
		if ( data ) then
			local delta = STATS_RAISING_CAP - data
			local pairStatKey = pairStatKeys[ key ]
			local pairStatVal = status[ pairStatKey ] and status[ pairStatKey ].val or 0
			if ( delta > 0 ) then
				-- 育成の伸びしろがある場合（ステータスキャップ未満の場合）は、育成後のポイントで計算
				TrainingPoints.Stats2[ key ] = STATS_RAISING_CAP * TRAINING_COSTS[ key ]
				-- hp,stam,manaも再計算
				local pairStatCap = pairStatVal + delta
				TrainingPoints.Stats1[ pairStatKey ] = pairStatCap * TRAINING_COSTS[ pairStatKey ]
			else
				TrainingPoints.Stats2[ key ] = data * TRAINING_COSTS[ key ]
			end

			if ( beforeHalfStat ) then
				-- ステータス半減後の訓練ポイント
				local sk = ( key ~= "int" ) and 0.5 or 1
				local halfVal = mathFloor( data * sk )
				local deltaHalf = STATS_RAISING_CAP - halfVal
				if ( deltaHalf > 0 ) then
					-- 育成の伸びしろがある場合
					TrainingPointsHalf.Stats2[ key ] = STATS_RAISING_CAP * TRAINING_COSTS[ key ]
					-- hp,stam,manaも再計算
					local tmpVal = mathFloor( pairStatVal * sk ) + deltaHalf
					-- テイム可能な生物は、テイム後の上限までのポイントを算出
					local statCap = statsCaps[ pairStatKey ]
					local pairStatCap = statCap and mathMin( tmpVal, statCap ) or tmpVal
					TrainingPointsHalf.Stats1[ pairStatKey ] = pairStatCap * TRAINING_COSTS[ pairStatKey ]
				else
					TrainingPointsHalf.Stats2[ key ] = halfVal * TRAINING_COSTS[ key ]
				end
			end
		end

	end

	-- ステータス： 回復
	keys = { "regeneHits", "regeneStamina", "regeneMana", }
	for i = 1, #keys do
		local key = keys[ i ]
		local tid = T.StatsRegeneTids[ key ]
		local tIndex = tidsTbl[ tid ] and tidsTbl[ tid ][1]
		local data = nil
		--		local title
		if ( tIndex ) then
			data = labelsObjTbl[ tIndex ].text
			data = data and tonumber( data )
		end

		status[ key ] = {
			val = data,
		}
	end

	loreData.Status = status


	-- 抵抗
	regist = {}
	keys = { "physical", "fire", "cold", "poison", "energy", }
	local RegistTids = T.RegistTids
	for i = 1, #keys do
		local key = keys[ i ]
		local tid = RegistTids[ key ]
		local tIndex = tidsTbl[ tid ] and tidsTbl[ tid ][1]
		local data = nil
		local text
		if ( tIndex ) then
			text = labelsObjTbl[ tIndex ].text
			data = text and tonumber( tostring( gSub( text, L"%%$", L"" ) ) )
		end

		local dbData = {}
		if ( mobDB[ key ] ) then
			dbData = explode( L" - ", mobDB[ key ], false, true )
		end

		regist[ key ] = {
			text = text,
			val = data,
			lwr = dbData[1],
			upr = dbData[2],
		}

		-- 訓練ポイントを計算・保持
		if ( data ) then
			local trPt = data * TRAINING_COSTS.regists
			TrainingPoints.Regist[ key ] = trPt
			TrainingPointsHalf.Regist[ key ] = trPt
		end
	end
	loreData.Regist = regist

	-- 訓練ポイントのトータルを計算
	local trPtsTotal = 0
	for gpKey, tbl in pairs( TrainingPoints ) do
		local grpTotal = 0
		for key, val in pairs( tbl ) do
			trPtsTotal = trPtsTotal + val
			grpTotal = grpTotal + val
		end
		TrainingPoints[ gpKey ].Total = tonumber( stringFormat( "%.1f", grpTotal ) )
	end
	trPtsTotal = tonumber( stringFormat( "%.1f", trPtsTotal ) )
	TrainingPoints.Total = trPtsTotal
	loreData.TrainingPoints = TrainingPoints

	if ( beforeHalfStat ) then
		local trPtsHalfTotal = 0
		for gpKey, tbl in pairs( TrainingPointsHalf ) do
			local grpTotal = 0
			for key, val in pairs( tbl ) do
				trPtsHalfTotal = trPtsHalfTotal + val
				grpTotal = grpTotal + val
			end
			TrainingPointsHalf[ gpKey ].Total = tonumber( stringFormat( "%.1f", grpTotal ) )
		end
		trPtsHalfTotal = tonumber( stringFormat( "%.1f", trPtsHalfTotal ) )
		TrainingPointsHalf.Total = trPtsHalfTotal
		loreData.TrainingPointsHalf = TrainingPointsHalf
	end

	-- ベースダメージ
	damage = {}
	local baseDamage = nil
	if ( tidsTbl[ T.BaseDamageTid ] ) then
		local tIndex = tidsTbl[ T.BaseDamageTid ][1]
		if ( tIndex ) then
			baseDamage = labelsObjTbl[ tIndex ].text
		end
	end
	damage.baseDamage = baseDamage
	-- ダメージ属性
	keys = { "physical", "fire", "cold", "poison", "energy", }
	local DamageTids = T.DamageTids
	for i = 1, #keys do
		local key = keys[ i ]
		local tid = DamageTids[ key ]
		local tIndex = tidsTbl[ tid ] and tidsTbl[ tid ][2]
		local data = nil
		local text
		if ( tIndex ) then
			text = labelsObjTbl[ tIndex ].text
			data = text and tonumber( tostring( gSub( text, L"%%$", L"" ) ) )
		end

		damage[ key ] = {
			text = text,
			val = data,
		}
	end
	loreData.Damage = damage


	-- スキル
	skill = {}
	local SkillTids = T.SkillTids
	local isJPN = ( SystemData.Settings.Language.type == SystemData.Settings.Language.LANGUAGE_JPN )
	for key, tid in pairs( SkillTids ) do
		local tIndex = tidsTbl[ tid ] and tidsTbl[ tid ][1]
		local data = {}
		local text
		if ( tIndex ) then

			text = labelsObjTbl[ tIndex ].text
			data = text and explode( L"/", text, false, true ) or {}
		end

		local dbData = {}
		if ( mobDB[ key ] ) then
			dbData = explode( L" - ", mobDB[ key ], false, true )
			if ( #dbData == 2 and ( isTamed or isRleased ) ) then
				dbData[1] = mathFloor( dbData[1] * 9 ) * 0.1
				dbData[2] = mathFloor( dbData[2] * 9 ) * 0.1
				dbData[1] = tonumber( stringFormat( "%.1f", dbData[1] ) )
				dbData[2] = tonumber( stringFormat( "%.1f", dbData[2] ) )
			end
		end

		skill[ key ] = {
			text = text,
			val = data[2],
			current = data[1],
			lwr = dbData[1],
			upr = dbData[2],
		}
	end
	loreData.Skill = skill


	-- データ保持前に、ステータス・スキルに変更があったかを判定しておく
	local forceExport = T.SaveLogEnable and T.isUpdateData( T.LoreDatas[ id ], loreData )
	-- データを保持
	T.LoreDatas[ id ] = loreData

	-- ウィンドウを表示
	ClfALGumpWindow.updateData( id )

	-- ログ出力
	T.exportData( id, labelsObjTbl, objectData, mobileData, mobDB, forceExport )

	-- **** for debug ****
	if ( T.DEBUG_MODE and ClfDebug and ClfUtil ) then
		devStr( L" ------ \r\n")
		devDump( "mobDB", mobDB )
		devStr( L" ------ \r\n")
		devDump( "labelsObjTbl", labelsObjTbl )
		devStr( L" ------ \r\n")
		devDump( "tidsTbl", tidsTbl )
		devStr( L" ------ \r\n")
		devDump( "loreData", loreData )
		devStr( L" ------ \r\n")
		local name =  gSub( loreName, L"[^%s%w]", L"" )
		if ( name and name ~= "" ) then
			name = "_" .. tostring( name )
		else
			name = ""
		end
		ClfUtil.exportStr( deb, "AnimalLoreGumpData" .. name )
	end

	return ClfALGumpWindow.CloseOrgGump
end


-- アニマルロアの結果から、前回のデータと変化があるかどうか
function ClfALGump.isUpdateData( oldData, newData )
	local type = type
	if ( "table" ~= type( newData ) ) then
		return false
	elseif ( "table" ~= type( oldData ) ) then
		return true
	end

	local oldStats = oldData.Status
	local newStats = newData.Status
	if ( "table" == type( newStats ) ) then
		if ( "table" ~= type( oldStats ) ) then
			return true
		else
			for k, v in pairs( newStats ) do
				local newVal = v.val
				local oldVal = oldStats[ k ] and oldStats[ k ].val
				if ( newVal and oldVal ~= newVal ) then
					return true
				end
			end
		end
	end

	local oldSkills = oldData.Skill
	local newSkills = newData.Skill
	if ( "table" == type( newSkills ) ) then
		if ( "table" ~= type( oldSkills ) ) then
			return true
		else
			for k, v in pairs( newSkills ) do
				local newVal = v.current
				local oldVal = oldSkills[ k ] and oldSkills[ k ].current
				if ( newVal and oldVal ~= newVal ) then
					return true
				end
			end
		end
	end

	return false
end



-- アニマルロアの見出し的な項目のtId
local TITLE_TIDS = {
	[1157487] = true,		-- "ペット訓練を開始",
	[1157491] = true,		-- "ペット訓練進行状況",
	[1157492] = true,		-- "訓練メニュー",
	[1049593] = "Status",	-- "ステータス",
	[1070793] = true,		-- "バードスキル難度",
	[1049594] = true,		-- "忠誠度",
	[1061645] = "Regist",	-- "抵抗",
	[1017319] = true,		-- "ダメージ",
	[1076750] = true,		-- "ベースダメージ",
	[3001030] = "Skill",	-- "Combat Ratings",
	[3001032] = "Skill",	-- "Lore & Knowledge",
	[1049563] = true,		-- "食べ物の好み",
	[1049569] = true,		-- "グループパワー",
	[1115783] = true,		-- "ペットスロット",
	[1157600] = true,		-- "要スキル: ~1_val~",
	[1157505] = true,		-- "ペットの進化",
}


ClfALGump.ExportTimes = {}

-- ロアデータのログ出力
function ClfALGump.exportData( id, labelsObjTbl, objectData, mobileData, mobDB, force )

	if ( not force and not ClfALGump.SaveLogEnable ) then
		return
	end

	local op = L""
	local prevTime = ClfALGump.ExportTimes[ id ]
	local TimeSinceLogin = Interface.TimeSinceLogin or 0

	if ( not force and prevTime and TimeSinceLogin - prevTime < ClfALGump.EXPORT_DELTA ) then
		-- 前回書き出しから{ClfALGump.EXPORT_DELTA}秒経ってなければ何もしない
		return
	else
		ClfALGump.ExportTimes[ id ] = TimeSinceLogin
	end


	local Data = ClfALGump.LoreDatas[ id ]
	local catCounts = {}
	local currentCat = ""
	local TidKeys = ClfALGump.TidKeys

	local GetStringFromTid = GetStringFromTid
	local type = type
	local towstring = towstring
	local wstringFind = wstring.find

	for i = 1, #labelsObjTbl do
		local obj = labelsObjTbl[ i ]
		local str
		local tid = obj.tid

		if ( tid ) then
			local ttl = GetStringFromTid( tid )
			if ( ttl ) then
				if ( obj.text ) then
					str = ttl .. L" : \t" .. obj.text
					local key = TidKeys[ tid ]
					if ( key ) then
						local curData = Data[ currentCat ] and Data[ currentCat ][ key ]
						if ( curData and curData.lwr ) then
							local count = catCounts[ currentCat ] or 0
							if ( count < 3 ) then
								str = str .. L"\t(" .. towstring( curData.lwr )
								if ( curData.upr ) then
									str = str .. L" - " .. towstring( curData.upr ) .. L")"
								end
							end
						end
					end
					str = str .. L"\r\n"
				elseif ( obj.params and obj.params[1]  ) then
					local pat = L"~1_val~"
					if ( wstringFind( ttl, pat, 1, true ) ) then
						str = wstring.gsub( ttl, pat, towstring( obj.params[1] ) ) .. L"\r\n"
					else
						str = ttl .. L" : \t" .. towstring( obj.params[1] ) .. L"\r\n"
					end
				else
					str = ttl .. L"\r\n"
				end

				local ttlTid = TITLE_TIDS[ tid ]

				if ( ttlTid ) then
					if ( type( ttlTid ) == "string" ) then
						currentCat = ttlTid
						catCounts[ ttlTid ] = catCounts[ ttlTid ] and catCounts[ ttlTid ] + 1 or 1
					end
					str = L"\r\n" .. str
				else
					str = L"\t" .. str
				end
				op = op .. str
			end
		end
	end

	if ( Data and op ~= L"" ) then
		local gsub = string.gsub
		local tostring = tostring
		local header =  L"\r\n\r\n" .. Data.name

		if ( Data.IsTamed and Data.creatureName ) then
			header = header .. L" (" .. towstring( Data.creatureName ) .. L")"
		end

		header = header .. L"\r\n\r\nID: " .. towstring( id ) .. L"\r\n"

		if ( objectData and objectData.objectType ) then
			header = header .. L"objectType: " .. towstring( objectData.objectType ) .. L"\r\n"
		end

		if ( Data.hueId ) then
			local hueIdStr = string.format( "#%04x", Data.hueId ) .. " (" .. Data.hueId .. ")"
			header = header .. L"hueId: " .. towstring( hueIdStr ) .. L"\r\n"
		end

		if ( Data.Tamable ) then
			header = header .. L"\r\n"
			local tamedStr = Data.IsTamed and L"true" or L"false"
			header = header .. L"Tamed: " .. tamedStr .. L"\r\n"

			if ( not Data.IsTamed ) then
				local releasedStr = Data.IsRleased and L"true" or L"false"
				header = header .. L"Maybe Rleased: " .. releasedStr .. L"\r\n"
			end
		end

		local trPts = Data.TrainingPoints

		if ( type( trPts ) == "table" ) then
			local trPtStr = L""

			if ( trPts.Total ) then
				trPtStr = L"\r\nTraining pt Calculated from Stats\r\n" .. L"\tTotal            : " .. towstring( trPts.Total ) .. L"pt\r\n"
				local keys = {
					{ key = "Stats1", title = "- Hits,Stam,Mana", maxVal = 3300 },
					{ key = "Stats2", title = "- STR, DEX, INT ", maxVal = 2300 },
					{ key = "Regist", title = "- Regists       ", maxVal = 1095 },
				}
				local stringFormat = string.format
				local mathFloor = math.floor
				local tonumber = tonumber
				local str = ""

				for i = 1, #keys do
					local v = keys[ i ]
					local dt = trPts[ v.key ]
					local d = dt and dt.Total
					if ( d ) then
						if ( v.maxVal ) then
							local delta = tonumber( stringFormat( "%.1f", d - v.maxVal ) )
							local fmt = "%+.1f"
							if ( delta == mathFloor( delta ) ) then
								fmt = "%+d"
							end
							str = str .. "\t" .. v.title .. " : " .. d .. "pt (" .. stringFormat( fmt, delta )  .. ")\r\n"
						else
							str = str .. "\t" .. v.title .. " : " .. d .. "pt\r\n"
						end
					end
				end

				local trPtsHalf = Data.TrainingPointsHalf

				if ( type( trPtsHalf ) == "table" ) then
					if ( trPtsHalf.Total ) then
						local keysHalf = {
							{ key = "Total",  title = "Total           "  },
							{ key = "Stats1", title = "- Hits,Stam,Mana", maxVal = 3300 },
							{ key = "Stats2", title = "- STR, DEX, INT ", maxVal = 2300 },
						}
						local strHalf = ""
						for i = 1, #keysHalf do
							local v = keysHalf[ i ]
							local dt = trPtsHalf[ v.key ]
							local d = ( type( dt ) == "table" ) and dt.Total or dt and tonumber( dt )
							if ( d ) then
								if ( v.maxVal ) then
									local delta = tonumber( stringFormat( "%.1f", d - v.maxVal ) )
									local fmt = "%+.1f"
									if ( delta == mathFloor( delta ) ) then
										fmt = "%+d"
									end
									strHalf = strHalf .. "\t" .. v.title .. " : " .. d .. "pt (" .. stringFormat( fmt, delta )  .. ")\r\n"
								else
									strHalf = strHalf .. "\t" .. v.title .. " : " .. d .. "pt\r\n"
								end
							end
						end
						if ( strHalf ~= "" ) then
							str = str .. "\t----- After status halving -----\r\n" .. strHalf
						end
					end
				end

				if ( #str > 0 ) then
					trPtStr = trPtStr .. towstring( str )
				end

				header = header .. trPtStr
			end
		end

		op = header .. L"\r\n---------- \r\n\r\n" .. op .. L"\r\n"

		local DumpToConsole = ClfDebug and ClfDebug.DumpToConsole
		if ( DumpToConsole ) then
			if ( objectData ) then
				op = op .. L"\r\n---------- objectData ----------\r\n" .. DumpToConsole( "objectData", objectData, nil, true )
			end

			if ( mobileData ) then
				op = op .. L"\r\n---------- mobileData ----------\r\n" .. DumpToConsole( "mobileData", mobileData, nil, true )
			end

			if ( mobDB ) then
				local title = L"CreaturesDB"
				if ( Data.creatureName ) then
					title = title .. L"[\"" .. towstring( Data.creatureName ) .. L"\"]"
				end
				op = op .. L"\r\n---------- " .. title .. L" ----------\r\n" .. DumpToConsole( "mobDB", mobDB, nil, true )
			end
		end

		local filename = gsub( tostring( Data.name ), "[^%s%w%-%._]", "" ) .. " [" .. tostring( id ) .. "]"
		local suffix
		if ( Data.MyPet ) then
			local mobName = WindowData.MobileName[ WindowData.PlayerStatus.PlayerId ]
			local playerName
			if ( mobName and mobName.MobName ) then
				playerName = gsub( string.lower( tostring( mobName.MobName ) ), "^%s*(.-)%s*$", "%1" )
				if ( playerName and playerName ~= "" ) then
					playerName =  gsub( playerName, "^lady ", "" )
					playerName =  gsub( playerName, "^lord ", "" )
					playerName = gsub( playerName, "[^%s%w%.%-_]", "" )
					if ( playerName and playerName ~= "" ) then
						playerName = "[" .. playerName .. "]"
					end
				end
			end
			if ( type( playerName ) ~= "string" ) then
				playerName = ""
			end
			suffix = "_pet" .. playerName
		elseif ( Data.IsTamed ) then
			suffix = "_tamed"
		else
			suffix = "_wild"
		end

		ClfUtil.exportStr( op, filename, suffix, "animalLore", false )
	end

end


-- CreaturesDB からデータを取得する為のmob名を得る
function ClfALGump.getName( objectData, id, isTamed )
	local cdbName = CreaturesDB.GetName( id )
	local noData = ( type( CreaturesDB[ cdbName ] ) ~= "table" )

	if ( isTamed or noData ) then
		local objectType = objectData and objectData.objectType

		if ( objectType ) then
			if ( ClfALGump.ANIMAL_TYPES[ objectType ] ) then
				local typeArr = ANIMAL_TYPE_ARRAY

				for i = 1, #typeArr do
					local obj = typeArr[ i ]
					if ( objectType == obj.objectType ) then

						local matchHue = false
						local mobHueId = objectData.hueId

						local hueIds = obj.hueId
						if ( hueIds and #hueIds > 0 ) then
							for j = 1, #hueIds do
								if ( mobHueId == hueIds[ j ] ) then
									matchHue = true
									break
								end
							end
						else
							matchHue = true
						end

						local excHueId = obj.excHueId
						if ( excHueId and #excHueId > 0 ) then
							for j = 1, #excHueId do
								if ( mobHueId == excHueId[ j ] ) then
									matchHue = false
									break
								end
							end
						end

						if ( matchHue ) then
							-- オブジェクトIDから取得した名前と併せて、元の名前でDBが無かったかを返す
							return obj.name, noData
						end

					end
				end
			end
		end
	end

	return cdbName, nil
end


-- 標準UIの CreaturesDB にマージするデータ
function ClfALGump.getClfCreaturesDB()
	local db = {

		["cu sidhe"] = {
			slayers = L"Fey",
			oppositeslayers = L"Demon",
			barddiff   = L"126,9",
			physical   = L"50 - 65",
			fire       = L"25 - 45",
			cold       = L"70 - 85",
			poison     = L"30 - 50",
			energy     = L"70 - 85",
			hits       = L"1010 - 1200",
			stamina    = L"150 - 170",
			mana       = L"250 - 290",
			str        = L"1200 - 1225",
			dex        = L"150 - 170",
			int        = L"250 - 290",
			wrestling  = L"90 - 100",
			tactics    = L"90 - 100",
			resspell   = L"75 - 90",
			anatomy    = L"65 - 100",
			poisoning  = L"0 - 0",
			healing    = L"70 - 100",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
			tamable    = 101.1,
			halfstat   = true,
		},

		["frost dragon"] = {
			slayers = L"Reptile, Dragon",
			oppositeslayers = L"Arachnid",
			barddiff   = L"160",
			physical   = L"70 - 95",
			fire       = L"60 - 70",
			cold       = L"80 - 95",
			poison     = L"60 - 70",
			energy     = L"55 - 75",
			hits       = L"1490 - 2430",
			stamina    = L"95 - 125",
			mana       = L"680 - 780",
			str        = L"1280 - 1360",
			dex        = L"95 - 125",
			int        = L"680 - 780",
			wrestling  = L"120 - 135",
			tactics    = L"120 - 135",
			resspell   = L"110 - 135",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"115 - 135",
			evalint    = L"45 - 60",
			meditation = L"0 - 35",
			halfstat   = true,
		},

		["cold drake"] = {
			slayers = L"Reptile, Dragon",
			oppositeslayers = L"Arachnid",
			barddiff   = L"105.9",
			physical   = L"55 - 65",
			fire       = L"30 - 40",
			cold       = L"75 - 90",
			poison     = L"45 - 60",
			energy     = L"40 - 50",
			hits       = L"400 - 500",
			stamina    = L"130 - 152",
			mana       = L"300 - 360",
			str        = L"600 - 670",
			dex        = L"135 - 152",
			int        = L"150 - 200",
			wrestling  = L"115 - 130",
			tactics    = L"115 - 140",
			resspell   = L"95 - 110",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
		},

		["platinum drake"] = {
			slayers = L"Reptile, Dragon",
			oppositeslayers = L"Arachnid",
			barddiff   = L"80,6",
			physical   = L"30 - 50",
			fire       = L"30 - 50",
			cold       = L"30 - 50",
			poison     = L"30 - 50",
			energy     = L"30 - 50",
			hits       = L"240 - 260",
			stamina    = L"130 - 155",
			mana       = L"100 - 140",
			str        = L"400 - 430",
			dex        = L"130 - 155",
			int        = L"100 - 140",
			wrestling  = L"65 - 80",
			tactics    = L"65 - 90",
			resspell   = L"65 - 80",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
		},

		["crimson drake"] = {
			slayers = L"Reptile, Dragon",
			oppositeslayers = L"Arachnid",
			barddiff   = L"80,6",
			physical   = L"30 - 50",
			fire       = L"30 - 50",
			cold       = L"30 - 50",
			poison     = L"30 - 50",
			energy     = L"30 - 50",
			hits       = L"240 - 260",
			stamina    = L"130 - 155",
			mana       = L"100 - 140",
			str        = L"400 - 430",
			dex        = L"130 - 155",
			int        = L"100 - 140",
			wrestling  = L"65 - 80",
			tactics    = L"65 - 90",
			resspell   = L"65 - 80",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
		},

		["stygian drake"] = {
			slayers = L"Reptile, Dragon",
			oppositeslayers = L"Arachnid",
			barddiff   = L"80,6",
			physical   = L"55 - 65",
			fire       = L"60 - 70",
			cold       = L"35 - 45",
			poison     = L"25 - 35",
			energy     = L"60 - 70",
			hits       = L"450 - 500",
			stamina    = L"85 - 105",
			mana       = L"430 - 475",
			str        = L"790 - 825",
			dex        = L"85 - 105",
			int        = L"455 - 475",
			wrestling  = L"80 - 100",
			tactics    = L"80 - 100",
			resspell   = L"80 - 100",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"90 - 100",
			evalint    = L"90 - 105",
			meditation = L"0 - 0",
		},

		["dimetrosaur"] = {
			slayers = L"Dinosaur, Eodon",
			oppositeslayers = L"Myrmidex",
			barddiff   = L"160",
			physical   = L"80 - 90",
			fire       = L"60 - 70",
			cold       = L"60 - 70",
			poison     = L"60 - 70",
			energy     = L"60 - 70",
			hits       = L"45 - 60",
			stamina    = L"45 - 65",
			mana       = L"0 - 0",
			str        = L"75 - 100",
			dex        = L"5 - 25",
			int        = L"10 - 20",
			wrestling  = L"40 - 60",
			tactics    = L"40 - 60",
			resspell   = L"25 - 40",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
		},

		["najasaurus"] = {
			slayers = L"Dinosaur, Eodon",
			oppositeslayers = L"Myrmidex",
			barddiff   = L"160",
			physical   = L"40 - 55",
			fire       = L"50 - 60",
			cold       = L"45 - 60",
			poison     = L"100 - 100",
			energy     = L"35 - 45",
			hits       = L"740 - 850",
			stamina    = L"150 - 220",
			mana       = L"20 - 40",
			str        = L"150 - 350",
			dex        = L"150 - 220",
			int        = L"20 - 40",
			wrestling  = L"80 - 100",
			tactics    = L"80 - 100",
			resspell   = L"150 - 190",
			anatomy    = L"0 - 0",
			poisoning  = L"90 - 100",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
		},


		["nightmare"] = {
			slayers = L"None",
			oppositeslayers = L"None",
			barddiff   = L"85,2",
			physical   = L"55 - 65",
			fire       = L"30 - 40",
			cold       = L"30 - 40",
			poison     = L"30 - 40",
			energy     = L"20 - 30",
			hits       = L"295 - 315",
			stamina    = L"85 - 105",
			mana       = L"85 - 125",
			str        = L"250 - 525",
			dex        = L"85 - 105",
			int        = L"85 - 125",
			wrestling  = L"80 - 95",
			tactics    = L"95 - 100",
			resspell   = L"85 - 100",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"10 - 50",
			evalint    = L"30 - 50",
			meditation = L"0 - 0",
			tamable = 95.1,
		},

		["saurosaurus"] = {
			slayers = L"Dinosaur, Eodon",
			oppositeslayers = L"Myrmidex",
			barddiff   = L"160",
			physical   = L"75 - 85",
			fire       = L"80 - 90",
			cold       = L"45 - 60",
			poison     = L"35 - 50",
			energy     = L"40 - 55",
			hits       = L"1300 - 1450",
			stamina    = L"200 - 220",
			mana       = L"400 - 440",
			str        = L"800 - 830",
			dex        = L"200 - 220",
			int        = L"400 - 440",
			wrestling  = L"110 - 130",
			tactics    = L"110 - 120",
			resspell   = L"75 - 90",
			anatomy    = L"55 - 60",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
			halfstat   = true,
		},

		["wild tiger"] = {
			slayers = L"",
			oppositeslayers = L"",
			barddiff   = L"70",
			physical   = L"55 - 75",
			fire       = L"20 - 40",
			cold       = L"55 - 65",
			poison     = L"30 - 40",
			energy     = L"25 - 35",
			hits       = L"350 - 450",
			stamina    = L"85 - 125",
			mana       = L"85 - 165",
			str        = L"500 - 555",
			dex        = L"85 - 125",
			int        = L"85 - 165",
			wrestling  = L"85 - 95",
			tactics    = L"100 - 105",
			resspell   = L"85 - 100",
			anatomy    = L"0 - 0",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
			halfstat   = false,
		},

		["ossein ram"] = {
			slayers = L"",
			oppositeslayers = L"",
			barddiff   = L"95",
			physical   = L"50 - 60",
			fire       = L"10 - 20",
			cold       = L"40 - 50",
			poison     = L"30 - 40",
			energy     = L"40 - 50",
			hits       = L"450 - 530",
			stamina    = L"80 - 115",
			mana       = L"100 - 145",
			str        = L"300 - 450",
			dex        = L"85 - 115",
			int        = L"100 - 145",
			wrestling  = L"90 - 100",
			tactics    = L"80 - 90",
			resspell   = L"70 - 80",
			anatomy    = L"80 - 90",
			poisoning  = L"0 - 0",
			healing    = L"0 - 0",
			magery     = L"0 - 0",
			evalint    = L"0 - 0",
			meditation = L"0 - 0",
		},

	}	-- /end db

	return db
end
