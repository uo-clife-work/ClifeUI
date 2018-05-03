ClfALGumpWindow = {}


local SKILL_KEYS = {
	-- 左側の列
	{ "wrestling", "tactics", "anatomy", "resspell", "healing", "poisoning", "parrying", "bushido", "ninjitsu", "chivalry", },
	-- 右側の列
	{ "magery", "evalint", "meditation", "necromancy", "spiritspeak", "mysticism", "focus", "spellweaving", "discordance", "hiding", "detecting" }
}


ClfALGumpWindow.WindowName = "ClfAnimalLoreWindow"

ClfALGumpWindow.defaultGray = { r = 175, g = 180, b =185 }

ClfALGumpWindow.TrainingMax = {
	TOTAL_REGIST = 365,
}

ClfALGumpWindow.WINDOW_WIDTH = 530
ClfALGumpWindow.WINDOW_PADDING = 15
ClfALGumpWindow.INNER_WIDTH = ClfALGumpWindow.WINDOW_WIDTH - ( ClfALGumpWindow.WINDOW_PADDING * 2 )
ClfALGumpWindow.COMBO_MAX = 20

ClfALGumpWindow.SkillWinHeight = 241
ClfALGumpWindow.StatsWinHeight = 10 + 40 + 10 + 40 + 10 + 80 + 20

ClfALGumpWindow.SkillTitles = nil

ClfALGumpWindow.ComboItems = {}

ClfALGumpWindow.StickyId = false

ClfALGumpWindow.WindowSize = "default"

ClfALGumpWindow.StatusHide = false
ClfALGumpWindow.SkillHide = false

ClfALGumpWindow.ShowManaRecov = true

ClfALGumpWindow.CloseOrgGump = false

ClfALGumpWindow.ManaRecovWindowName = ClfALGumpWindow.WindowName .. "ManaRecovery"


function ClfALGumpWindow.initialize()

	local window = ClfALGumpWindow.WindowName
	WindowSetShowing( window .. "Expand", false )
	WindowUtils.RestoreWindowPosition( window )

	ClfALGumpWindow.setStatusHide( ClfALGumpWindow.StatusHide )
	ClfALGumpWindow.setSkillHide( ClfALGumpWindow.SkillHide )

	ClfALGumpWindow.updateCombo()

	-- CloseOrg
	LabelSetText( window .. "HeaderCloseOrgLabel", L"Close def Gump" )

	-- Skill
	LabelSetText( window .. "SkillTitle", L"SKILL :" )

	-- Close Org
	ClfALGumpWindow.setEnableCloseOrgGump( Interface.LoadBoolean( "ClfALGumpWindowCloseOrg", false ) )

	if ( not ClfALGumpWindow.SkillTitles ) then
		ClfALGumpWindow.SkillTitles = {}
		local skillsKeyColumns = SKILL_KEYS
		local skillTids = ClfALGump.SkillTids
		local isJPN = ( SystemData.Settings.Language.type == SystemData.Settings.Language.LANGUAGE_JPN )
		local gSub = wstring.gsub
		local GetStringFromTid = GetStringFromTid
		for j = 1, #skillsKeyColumns do
			local skillKeys = skillsKeyColumns[ j ]
			for i = 1, #skillKeys do
				local key = skillKeys[ i ]
				if ( key and skillTids[ key ] ) then
					local title = GetStringFromTid( skillTids[ key ] ) or L"???"
					if ( isJPN ) then
						-- スキル値の日本語名部分を削除
						title = gSub( title, L"%s*%[.-%]%s*$", L"" )
					end
					ClfALGumpWindow.SkillTitles[ key ] = title
				end
			end
		end
	end

	ClfALGumpWindow.adjustWindowSize()
end


function ClfALGumpWindow.shutdown()
	WindowUtils.SaveWindowPosition( ClfALGumpWindow.WindowName )
end



function ClfALGumpWindow.show()
end

function ClfALGumpWindow.hide()
	local window = ClfALGumpWindow.WindowName
	if ( DoesWindowExist( window ) ) then
		DestroyWindow( window )
	end
end


function ClfALGumpWindow.contract()
	local size = "contract"
	local oldSize = ClfALGumpWindow.WindowSize

	ClfALGumpWindow.WindowSize = size

	WindowSetShowing( ClfALGumpWindow.WindowName .. "Expand", true )

	if ( oldSize ~= size ) then
		ClfALGumpWindow.adjustWindowSize()
	end
end


function ClfALGumpWindow.expand()
	local size = "default"
	local oldSize = ClfALGumpWindow.WindowSize

	ClfALGumpWindow.WindowSize = size

	WindowSetShowing( ClfALGumpWindow.WindowName .. "Expand", false )

	if ( oldSize ~= size ) then
		ClfALGumpWindow.adjustWindowSize()
	end
end


function ClfALGumpWindow.updateCombo()
	local T = ClfALGumpWindow
	local window = T.WindowName

	if ( not DoesWindowExist( window ) ) then
		return
	end

	local combo = window .. "HeaderMobCombo"

	local LoreDatas = ClfALGump.LoreDatas
	local Datas = {}

	-- ソート出来る様にデータを配列に格納
	for tid, obj in pairs( LoreDatas ) do
		Datas[ #Datas + 1 ] = obj
	end

	local selectIndex = 1
	local stickId = T.StickyId
	local currentId = WindowGetId( window )

	ComboBoxClearMenuItems( combo )
	T.ComboItems = {}

	if ( #Datas == 0 ) then
		return
	end

	table.sort(
		Datas,
		function( a, b )
			return a.time > b.time
		end
	)

	local COMBO_MAX = T.COMBO_MAX
	local len = math.min( COMBO_MAX, #Datas )
	local maxChars = 26
	local wstringLen = wstring.len
	local wstringSub = wstring.sub
	local wstringGsub = wstring.gsub
	local ComboBoxAddMenuItem = ComboBoxAddMenuItem
	local hasStickId = false

	for i = 1, len do
		local data = Datas[ i ]
		if ( stickId and i == COMBO_MAX and not hasStickId ) then
			data = LoreDatas[ stickId ] or data
		end

		local text = data.name
		if ( data.IsTamed or data.MyPet ) then
			if ( data.MyPet ) then
				text = L"[Pet] " .. text
			elseif ( data.IsTamed ) then
				text = L"[Tamed] " .. text
			end
			if ( data.hasMobDB and data.creatureName ) then
				local crName = towstring( data.creatureName )
				if ( not wstring.find( data.name, crName, 1, true )  ) then
					text = text .. L" (" .. crName .. L")"
				end
			end
		end

		if ( stickId == data.id ) then
			text = L"* " .. text
			hasStickId = true
		end

		if ( currentId == data.id ) then
			selectIndex = i
		end

		if ( wstringLen( text ) > maxChars ) then
			text = wstringSub( text, 1, maxChars - 3 )
			text = wstringGsub( text, L"%s*$", L"" )
			text = text .. L"..."
		end

		T.ComboItems[ i ] = data.id
		ComboBoxAddMenuItem( combo, text )
	end

	ComboBoxSetSelectedMenuItem( combo, selectIndex )
end



function ClfALGumpWindow.onSelectMobCombo()
	local index = ComboBoxGetSelectedMenuItem( ClfALGumpWindow.WindowName .. "HeaderMobCombo" )
	if ( not index or index < 1 ) then
		return
	end
	id = ClfALGumpWindow.ComboItems[ index ]
	if ( id ) then
		ClfALGumpWindow.showData( id )
		ClfALGumpWindow.expand()
	end
end


function ClfALGumpWindow.updateData( id )
	if ( not id or id < 1 ) then
		return
	end

	if ( not ClfALGumpWindow.StickyId or ClfALGumpWindow.StickyId == id ) then
		ClfALGumpWindow.showData( id )
		ClfALGumpWindow.expand()
	end
	ClfALGumpWindow.updateCombo()
end


local statsKeys1 = { "hits", "stamina", "mana", }
local statsAtts1 = { hits = L"Hits", stamina = L"Stam", mana = L"Mana"  }

local statsKeys2 = { "str", "dex", "int", }
local statsAtts2 = { str = L"STR", dex = L"DEX", int = L"INT"  }

local registKeys = { "physical", "fire", "cold", "poison", "energy", "total" }
local registAtts = {
	physical = { ttl = L"AR",    col = { r = 191, g = 191, b = 191, }, },
	fire     = { ttl = L"FR",    col = { r = 250, g = 120, b =  83, }, },
	cold     = { ttl = L"CR",    col = { r = 151, g = 182, b = 232, }, },
	poison   = { ttl = L"PR",    col = { r = 102, g = 179, b = 102, }, },
	energy   = { ttl = L"ER",    col = { r = 217, g = 179, b = 255, }, },
	total    = { ttl = L"Total", col = { r = 255, g = 255, b = 255, }, },
}

local damageKeys = { "physical", "fire", "cold", "poison", "energy" }
local damageAtts = {
	physical = { col = { r = 204, g = 204, b = 204, }, bg = { r =  89, g =  86, b =  86, }, },
	fire     = { col = { r = 250, g = 140, b = 117, }, bg = { r = 120, g =  50, b =  37, }, },
	cold     = { col = { r = 172, g = 197, b = 237, }, bg = { r =  68, g =  82, b = 105, }, },
	poison   = { col = { r = 133, g = 194, b = 133, }, bg = { r =  46, g =  81, b =  46, }, },
	energy   = { col = { r = 225, g = 194, b = 255, }, bg = { r =  98, g =  81, b = 115, }, },
}


function ClfALGumpWindow.showData( id )
	local T = ClfALGumpWindow

	local Data = ClfALGump.LoreDatas[ id ]

	if ( not Data or not Data.Status or not Data.Skill ) then
		return
	end

	-- set global to local
	local DoesWindowExist = DoesWindowExist
	local LabelSetText = LabelSetText
	local LabelSetTextColor = LabelSetTextColor
	local CreateWindowFromTemplateShow = CreateWindowFromTemplateShow
	local WindowAddAnchor = WindowAddAnchor
	local type = type
	local tonumber = tonumber
	local tostring = tostring
	local towstring = towstring
	local mathFloor = math.floor
	local mathMax = math.max
	local mathMin = math.min
	local stringFormat = string.format
	local stringUpper = string.upper

	local getRate = T.getRate
	local getRateColor = T.getRateColor


	local window = T.WindowName
	local Gray = T.defaultGray

	if ( not DoesWindowExist( window ) ) then
		CreateWindow( window, false )
	else
		WindowSetShowing( window, false )
	end

	local hasMobDB = Data.hasMobDB
	local tamable = Data.Tamable
	local halfstat = Data.Halfstat
	local isTamed = Data.IsTamed
	local isRleased = Data.IsRleased
	local beforeHalfStat = ( halfstat and tamable and not isTamed and not isRleased )

	WindowSetId( window, id )

	-- 名前
	LabelSetText( window .. "Title", Data.name .. L" [ID: " .. towstring( id ) .. L"]" )

	-- 訓練進行状況
	if ( Data.petProgress and Data.petProgress.text ) then
		local text = Data.petProgress.title .. L" " .. Data.petProgress.text
		LabelSetText( window .. "HeaderPetProgress", text )
	else
		if ( hasMobDB and Data.creatureName ) then
			local creatureName = towstring( Data.creatureName )
			if ( isRleased ) then
				creatureName = creatureName .. L" (Maybe Released)"
			end
			LabelSetText( window .. "HeaderPetProgress", creatureName )
		else
			LabelSetText( window .. "HeaderPetProgress", L"" )
		end
	end

	-- スロット
	local petSlot = Data.PetSlot or L"(none)"
	petSlot = L"SLOT : " .. petSlot
	LabelSetText( window .. "StatusPetSlot", petSlot )
	if ( tamable ) then
		LabelSetTextColor( window .. "StatusPetSlot", 255, 255, 255 )
	else
		LabelSetTextColor( window .. "StatusPetSlot", Gray.r, Gray.g, Gray.b )
	end

	-- HueID
	local hueId = Data.hueId or 0
	local hueIdStr = stringFormat( "#%04x", hueId ) .. " (" .. hueId .. ")"
	LabelSetText( window .. "HeaderHueName", towstring( hueIdStr ) )
	local hue = Data.hue or { r = 255, g = 255, b = 255 }
	LabelSetTextColor( window .. "HeaderHueName", hue.r, hue.g, hue.b )

	local iMax = Data.hueIMax or 255
	local bgHue
	if ( iMax > 65 ) then
		bgHue = 0
	else
		bgHue = 160
	end

	WindowSetTintColor( window .. "HeaderHueBG", bgHue, bgHue, bgHue )
	DynamicImageSetCustomShader(  window .. "HeaderHueImage", "UOSpriteUIShader", { hueId, Data.objectType } )

	-- 忠誠度
	local fidelity =  Data.Fidelity or L"???"
	LabelSetText( window .. "HeaderFidelity", fidelity )
	if ( Data.FidelityRate ) then
		local color = getRateColor( Data.FidelityRate ) or { r = 210, g = 210, b = 210 }
		LabelSetTextColor( window .. "HeaderFidelity", color.r, color.g, color.b )
	else
		LabelSetTextColor( window .. "HeaderFidelity", 210, 210, 210 )
	end

	local parent

	-- ステータス 1段目 （ hits, stm, mana ）
	parent = window .. "StatusListUpr"
	local keys = statsKeys1

	for i = 1, #keys do
		local key = keys[ i ]
		local newWin = parent .. key
		local d = Data.Status[ key ]

		if ( not DoesWindowExist( newWin ) ) then
			CreateWindowFromTemplateShow( newWin, "ClfALTmplateStatusExt", parent, true )
			WindowAddAnchor( newWin, "topleft", parent, "topleft", ( i - 1 ) * 170, 0)
			LabelSetText( newWin .. "Title", statsAtts1[ key ] )
		end

		local val = d.val

		if ( hasMobDB ) then
			local dbLwr = d.lwr
			local dbUpr = d.upr
			local range = "(---)"
			local percVal = "---"
			local color = T.defaultGray

			if ( type( dbLwr ) == "number" and type( dbUpr ) == "number" ) then
				range = "(" .. dbLwr .. "~" .. dbUpr .. ")"

				if ( dbUpr > 0 and type( val ) == "number" ) then
					if ( tamable ) then
						range = stringFormat( "%+d ", val - dbUpr ) .. range
					end

					local perc = getRate( val, dbLwr, dbUpr )

					if ( perc > 0 and perc <= 1 ) then
						percVal = mathFloor( perc * 1000 ) * 0.1
						percVal = tonumber( stringFormat( "%.1f", percVal ) )  .. "%"
					else
						if ( perc > 1 ) then
							percVal = val - dbUpr
						else
							percVal = val - dbLwr
						end
						percVal =  stringFormat( "%+d ", percVal )
					end

					color = getRateColor( perc, val, dbLwr, dbUpr )
				end
			end

			LabelSetText( newWin .. "Range", towstring( range ) )
			LabelSetText( newWin .. "Delta", towstring( percVal  ) )
			LabelSetTextColor( newWin .. "Delta", color.r, color.g, color.b )
		else
			LabelSetText( newWin .. "Delta", L"" )
			LabelSetText( newWin .. "Range", L"" )
		end

		if ( key ~= "mana" and beforeHalfStat and type( val ) == "number" ) then
			local after = mathFloor( val * 0.5 )
			LabelSetText( newWin .. "After", towstring( ">" .. after ) )
		else
			LabelSetText( newWin .. "After", L"" )
		end

		local current = d.current
		local valStr = ""
		local sep = ""

		if ( val ) then
			if ( type( val ) == "number" and val < 10000 ) then
				sep = " / "
				valStr = val
			elseif ( type( val ) == "wstring" ) then
				sep = " / "
				valStr = tostring( val )
			else
				sep = "/"
				valStr = val
			end
		end

		if ( current ) then
			if ( type( current ) == "number" ) then
				valStr = current .. sep .. valStr
			else
				current = tostring( current )
				if ( #current > 0 ) then
					valStr = current .. sep .. valStr
				end
			end
		end

		LabelSetText( newWin .. "Value", towstring( valStr ) )
	end


	-- マナ回復ゲージ
	local manaRecovWin = T.ManaRecovWindowName
	T.ManaRecoveryData = nil

	if ( DoesWindowExist( manaRecovWin ) ) then
		DestroyWindow( manaRecovWin )
	end

	if ( T.ShowManaRecov ) then
		local secManaRege, manaRegeVal = ClfALGumpWindow.getManaRecoveryTime( id, Data )

		if ( manaRegeVal and secManaRege and secManaRege > 1 ) then
			local manaData = Data.Status.mana
			T.ManaRecoveryData = {
				start = Data.time or 0,
				mana = manaData.current,
				manaMax = manaData.val,
				manaRegeVal = manaRegeVal,
				secManaRege = secManaRege,
			}
			CreateWindowFromTemplate( manaRecovWin, "ClfALTmplateManaRecovery", parent )
			WindowAddAnchor( manaRecovWin, "topleft", parent .. "mana", "bottomleft", 0, -2 )
			T.setManaRecovGauge()
		end
	end


	-- ステータス 2段目 （ str, dex, int ）
	parent = window .. "StatusListLwr"
	local keys = statsKeys2

	for i = 1, #keys do
		local key = keys[ i ]
		local newWin = parent .. key
		local d = Data.Status[ key ]

		if ( not DoesWindowExist( newWin ) ) then
			CreateWindowFromTemplateShow( newWin, "ClfALTmplateStatusExt", parent, true )
			WindowAddAnchor( newWin, "topleft", parent, "topleft", ( i - 1 ) * 170, 0)
			LabelSetText( newWin .. "Title", statsAtts2[ key ] )
		end

		local val = d.val or 0

		if ( hasMobDB ) then
			local dbLwr = d.lwr
			local dbUpr = d.upr
			local percVal = "---"
			local range = "(---)"
			local color = T.defaultGray

			if ( type( dbLwr ) == "number" and type( dbUpr ) == "number" ) then
				range = "(" .. d.lwr .. "~" .. d.upr .. ")"

				if ( dbUpr > 0 and type( val ) == "number" ) then
					if ( tamable ) then
						range = stringFormat( "%+d ", val - dbUpr ) .. range
					end

					local perc = getRate( val, dbLwr, dbUpr )

					if ( perc > 0 and perc <= 1 ) then
						percVal = mathFloor( perc * 1000 ) * 0.1
						percVal = tonumber( stringFormat( "%.1f", percVal ) )  .. "%"
					else
						if ( perc > 1 ) then
							percVal = val - dbUpr
						else
							percVal = val - dbLwr
						end
						percVal =  stringFormat( "%+d ", percVal )
					end

					color = getRateColor( perc, val, dbLwr, dbUpr )
				end
			end

			LabelSetText( newWin .. "Range", towstring( range ) )
			LabelSetText( newWin .. "Delta", towstring( percVal ) )
			LabelSetTextColor( newWin .. "Delta", color.r, color.g, color.b )
		else
			LabelSetText( newWin .. "Delta", L"" )
			LabelSetText( newWin .. "Range", L"" )
		end

		if ( key ~= "int" and beforeHalfStat and type( val ) == "number" ) then
			local after = mathFloor( val * 0.5 )
			LabelSetText( newWin .. "After", towstring( ">" .. after ) )
		else
			LabelSetText( newWin .. "After", L"" )
		end

		LabelSetText( newWin .. "Value", towstring( val ) )
	end

	-- ステータス 属性抵抗
	parent = window .. "StatusListRegist"
	local keys = registKeys
	local titleArg = registAtts
	local totalVal = 0
	local totalLwr = 0
	local totalUpr = 0

	for i = 1, #keys do
		local key = keys[ i ]
		local newWin = parent .. key
		local d = Data.Regist[ key ] or {}

		if ( not DoesWindowExist( newWin ) ) then
			CreateWindowFromTemplateShow( newWin, "ClfALTmplateRegistExt", parent, true )
			WindowAddAnchor( newWin, "topleft", parent, "topleft", ( i - 1 ) * 84, 0)

			local arg = titleArg[ key ]
			LabelSetText( newWin .. "Title", arg.ttl )
			local col = arg.col
			LabelSetTextColor( newWin .. "Title", col.r, col.g, col.b )
		end

		local val = d.val or 0
		if ( type( val ) == "number" ) then
			totalVal = totalVal + val
		end

		if ( hasMobDB ) then
			local dbLwr = d.lwr
			local dbUpr = d.upr

			if ( type( dbLwr ) == "number" and not dbUpr ) then
				dbUpr = dbLwr
			end

			local range = "(---)"
			local percVal = "---"
			local color = T.defaultGray

			if ( key ~= "total" ) then
				if ( type( dbLwr ) == "number" and type( dbUpr ) == "number" ) then
					totalLwr = totalLwr + dbLwr
					totalUpr = totalUpr + dbUpr
					range = "(" .. dbLwr .. "~" .. dbUpr .. ")"

					if ( dbUpr > 0 and type( val ) == "number" ) then

						if ( tamable ) then
							range = stringFormat( "%+d ", val - dbUpr ) .. range
						end

						local perc = getRate( val, dbLwr, dbUpr )

						if ( val < dbLwr ) then
							percVal = "-" .. tostring( dbLwr - val )
						elseif ( val > dbUpr ) then
							percVal = "+" .. tostring( val - dbUpr )
						else
							percVal = mathFloor( perc * 1000 ) * 0.1
							percVal = tonumber( stringFormat( "%.1f", percVal ) ) .. "%"
						end

						color = getRateColor( perc, val, dbLwr, dbUpr )
					end
				end
			else
				if ( totalUpr > 0 and totalVal > 0 ) then
					local perc = getRate( totalVal, totalLwr, totalUpr )
					percVal = mathFloor( perc * 1000 ) * 0.1
					percVal = tonumber( stringFormat( "%.1f", percVal ) ) .. "%"

					range = "(" .. totalLwr .. "~" .. totalUpr.. ")"
					if ( tamable ) then
						range = stringFormat( "%+d ", totalVal - totalUpr ) .. range
					end

					color = getRateColor( perc, totalVal, totalLwr, totalUpr )
				end
			end

			LabelSetTextColor( newWin .. "Delta", color.r, color.g, color.b )
			LabelSetText( newWin .. "Delta", towstring( percVal ) )
			LabelSetText( newWin .. "Range", towstring( range ) )
		else
			LabelSetText( newWin .. "Delta", L"" )
			LabelSetText( newWin .. "Range", L"" )
		end

		local valStr = val
		if ( key == "total" ) then
			valStr = totalVal
			if ( tamable ) then
				valStr = valStr .. " (" .. stringFormat( "%+d", ( totalVal - T.TrainingMax.TOTAL_REGIST ) ) .. ")"
			end
		end

		LabelSetText( newWin .. "Value", towstring( valStr ) )
	end

	-- Status title
	local trPts = Data.TrainingPoints
	if ( trPts and trPts.Total ) then
		LabelSetText( window .. "StatusTitle", L"STATUS : " .. towstring( trPts.Total ) .. L"pt" )
	else
		LabelSetText( window .. "StatusTitle", L"STATUS :" )
	end

	-- ステータス： ベースダメージ＆ダメージ属性
	local damageData = Data.Damage

	local damageWin = window .. "StatusListDamage"
	LabelSetText( damageWin .. "Title", L"Damage:" )

	local baseDmg = damageData and damageData.baseDamage or L""
	LabelSetText( damageWin .. "Baseval", baseDmg )

	parent = damageWin .. "Gauge"
	local keys = damageKeys
	local keyAttr = damageAtts

	local dmgWidth = 0
	local wrapWidth = 380
	local mathRound = function( num )
		return mathFloor( num + 0.5 )
	end

	for i = 1, #keys do
		local key = keys[ i ]
		local newWin = parent .. key

		if ( DoesWindowExist( newWin ) ) then
			DestroyWindow( newWin )
		end

		local d = damageData[ key ]
		local val = d and d.val

		if ( val and val > 0 ) then
			local w = mathMin( mathRound( wrapWidth * d.val * 0.01 ), wrapWidth - dmgWidth )
			local col = keyAttr[ key ].col
			local bg = keyAttr[ key ].bg
			local label = newWin .. "Val"
			CreateWindowFromTemplateShow( newWin, "ClfALTmplateDamageAttr", parent, true )
			WindowSetTintColor( newWin, bg.r, bg.g, bg.b )
			LabelSetTextColor( label, col.r, col.g, col.b )
			WindowAddAnchor( newWin, "topleft", parent, "topleft", dmgWidth + 1, 0)
			WindowSetDimensions( newWin, w - 2, 10 )
			LabelSetText( label, towstring( val ) .. L"%" )
			dmgWidth = dmgWidth + w
		end
	end


	-- スキル
	parent = window .. "SkillList"
	local skillTitles = T.SkillTitles
	local skillsKeyColumns = SKILL_KEYS
	local DefaultColor = { r = 255, g = 255, b = 255 }
	local skillWinH = 0
	for j = 1, #skillsKeyColumns do
		local skillKeys = skillsKeyColumns[ j ]
		local ancX = ( j - 1 ) * 257
		local ancY =0

		for i = 1, #skillKeys do
			local key = skillKeys[ i ]
			local newWin = parent .. key
			local d = Data.Skill[ key ] or {}
			ancY = ( i - 1 ) * 22
			skillWinH = mathMax( skillWinH, ancY )

			if ( not DoesWindowExist( newWin ) ) then
				CreateWindowFromTemplateShow( newWin, "ClfALTmplateSkillExt", parent, true )
				LabelSetText( newWin .. "Title", skillTitles[ key ] )
				WindowAddAnchor( newWin, "topleft", parent, "topleft", ancX, ancY)

			end

			local val = d.val
			local current = d.current
			local valStr
			local currentStr
			local deltaStr = ""
			local rangeStr = ""
			local col = DefaultColor

			if ( type( current ) == "number" ) then
				currentStr = stringFormat( "%.1f", current )

				if ( tamable and not isTamed and not isRleased ) then
					local delta =  mathFloor( current * 9 ) * 0.1
					deltaStr = ">" .. tonumber( stringFormat( "%.1f", delta ) )
				end

			else
				currentStr = tostring( current )
			end

			if ( type( val ) == "number" ) then
				valStr = stringFormat( "%.1f", val )
			elseif ( val ) then
				valStr = tostring( val )
			end


			if ( hasMobDB ) then
				local dbLwr = d.lwr
				local dbUpr = d.upr
				if ( type( dbUpr ) == "number" and dbUpr > 0 ) then
					rangeStr = "(" .. dbUpr .. ")"
					if ( type( current ) == "number" and type( dbLwr ) == "number" ) then
						col = getRateColor( nil, current, dbLwr, dbUpr )
					end
				end
			end

			local valLabelText = currentStr

			if ( tamable and not isTamed ) then
				valLabelText = currentStr
			elseif ( valStr ) then
				valLabelText = currentStr .. "/" .. valStr
			end

			LabelSetText( newWin .. "Value", towstring( valLabelText ) )
			LabelSetTextColor( newWin .. "Value", col.r, col.g, col.b )
			LabelSetText( newWin .. "Delta", towstring( deltaStr ) )
			LabelSetText( newWin .. "Range", towstring( rangeStr ) )
		end
	end

	ClfALGumpWindow.SkillWinHeight = skillWinH + 21

	ClfALGumpWindow.adjustWindowSize()
	WindowSetShowing( window, true )
end


function ClfALGumpWindow.onStatusContractBtn()
	ClfALGumpWindow.setStatusHide( true )
	ClfALGumpWindow.adjustWindowSize()
end


function ClfALGumpWindow.onStatusExpandBtn()
	ClfALGumpWindow.setStatusHide( false )
	ClfALGumpWindow.adjustWindowSize()
end

function ClfALGumpWindow.setStatusHide( hide )
	local window = ClfALGumpWindow.WindowName .. "Status"
	ClfALGumpWindow.StatusHide = hide

	WindowSetShowing( window .. "BtnExpand", hide )
	WindowSetShowing( window .. "BtnContract", not hide )
end


function ClfALGumpWindow.onStatusTitleOver()
	local id = WindowGetId( ClfALGumpWindow.WindowName )
	local Data = id and ClfALGump.LoreDatas[ id ] or nil
	if ( Data ) then
		local TrainingPoints = Data.TrainingPoints
		if ( type( TrainingPoints ) == "table" ) then
			local win = SystemData.ActiveWindow.name
			local keys = {
				{ key = "Stats1", title = "Hits,Stam,Mana", maxVal = 3300 },
				{ key = "Stats2", title = "STR, DEX, INT ", maxVal = 2300 },
				{ key = "Regist", title = "Regists       ", maxVal = 1095 },
			}
			local stringFormat = string.format
			local mathFloor = math.floor
			local tonumber = tonumber

			local str = ""
			for i = 1, #keys do
				local v = keys[ i ]
				local dt = TrainingPoints[ v.key ]
				local d = dt and dt.Total
				if ( d ) then
					if ( v.maxVal ) then
						local delta = tonumber( stringFormat( "%.1f", d - v.maxVal ) )
						local fmt = "%+.1f"
						if ( delta == mathFloor( delta ) ) then
							fmt = "%+d"
						end
						str = str .. v.title .. " : " .. d .. "pt (" .. stringFormat( fmt, delta )  .. ")\n\n"
					else
						str = str .. v.title .. " : " .. d .. "pt\n\n"
					end
				end
			end

			local TrainingPointsHalf = Data.TrainingPointsHalf
			if ( type( TrainingPointsHalf ) == "table" ) then
				local keysHalf = {
					{ key = "Total",  title = "Total         "  },
					{ key = "Stats1", title = "Hits,Stam,Mana", maxVal = 3300 },
					{ key = "Stats2", title = "STR, DEX, INT ", maxVal = 2300 },
				}
				local strHalf = ""
				for i = 1, #keysHalf do
					local v = keysHalf[ i ]
					local dt = TrainingPointsHalf[ v.key ]
					local d = ( type( dt ) == "table" ) and dt.Total or dt and tonumber( dt )
					if ( d ) then
						if ( v.maxVal ) then
							local delta = tonumber( stringFormat( "%.1f", d - v.maxVal ) )
							local fmt = "%+.1f"
							if ( delta == mathFloor( delta ) ) then
								fmt = "%+d"
							end
							strHalf = strHalf .. v.title .. " : " .. d .. "pt (" .. stringFormat( fmt, delta )  .. ")\n\n"
						else
							strHalf = strHalf .. v.title .. " : " .. d .. "pt\n\n"
						end
					end
				end

				if ( strHalf ~= "" ) then
					str = str .. "\n===== After status halving =====\n\n" .. strHalf
				end
			end

			if ( str ~= "" ) then
				str = string.gsub( str, "\n$", "" )
				local Tooltips = Tooltips
				Tooltips.CreateTextOnlyTooltip( win, towstring( str ) )
				Tooltips.SetTooltipFont( 1, 1, "MyriadPro_14", 18 )
				Tooltips.Finalize()
				Tooltips.AnchorTooltip( Tooltips.ANCHOR_WINDOW_TOP )
			end
		end
	end
end


function ClfALGumpWindow.onSkillContractBtn()
	ClfALGumpWindow.setSkillHide( true )
	ClfALGumpWindow.adjustWindowSize()
end


function ClfALGumpWindow.onSkillExpandBtn()
	ClfALGumpWindow.setSkillHide( false )
	ClfALGumpWindow.adjustWindowSize()
end


function ClfALGumpWindow.setSkillHide( hide )
	local window = ClfALGumpWindow.WindowName .. "Skill"
	ClfALGumpWindow.SkillHide = hide

	WindowSetShowing( window .. "BtnExpand", hide )
	WindowSetShowing( window .. "BtnContract", not hide )
end


-- 現在のウィンドウサイズ設定（ステータス・スキルの表示・非表示）に合わせてウィンドウをリサイズ
function ClfALGumpWindow.adjustWindowSize()

	local window = ClfALGumpWindow.WindowName

	local WIDTH = ClfALGumpWindow.WINDOW_WIDTH
	local PAD = ClfALGumpWindow.WINDOW_PADDING
	local INNER_WIDTH = ClfALGumpWindow.INNER_WIDTH

	local WindowSetDimensions = WindowSetDimensions
	local WindowSetShowing = WindowSetShowing

	WindowSetDimensions( window .. "BG", 0, 0 )

	if ( ClfALGumpWindow.WindowSize == "contract" ) then
		WindowSetShowing( window .. "Status", false )
		WindowSetShowing( window .. "Skill", false )
		WindowSetDimensions( window, WIDTH, 70 )
		WindowSetDimensions( window .. "BG", WIDTH, 70 )

	else
		WindowSetShowing( window .. "Status", true )
		WindowSetShowing( window .. "Skill", true )

		local statsH = 20

		if ( ClfALGumpWindow.StatusHide ) then
			WindowSetShowing( window .. "StatusList", false )
			WindowSetDimensions( window .. "Status", INNER_WIDTH, statsH )
		else
			local win = window .. "Status"
			WindowSetShowing( win .. "List", true )
			statsH = ClfALGumpWindow.StatsWinHeight + 20
			WindowSetDimensions( win, INNER_WIDTH, statsH )
		end

		local skillsH = 20

		if ( ClfALGumpWindow.SkillHide ) then
			WindowSetShowing( window .. "SkillList", false )
			WindowSetDimensions( window .. "SkillList", 0, 0 )
			WindowSetDimensions( window .. "Skill", INNER_WIDTH, skillsH )
		else
			local win = window .. "Skill"
			WindowSetShowing( win .. "List", true )
			skillsH = ClfALGumpWindow.SkillWinHeight + 20
			WindowSetDimensions( win, INNER_WIDTH, skillsH )
		end

		WindowResizeOnChildren( window, false, PAD )
		local x, y = WindowGetDimensions( window )
		WindowSetDimensions( window, WIDTH, y )
		WindowSetDimensions( window .. "BG", WIDTH, y )
	end

end


ClfALGumpWindow.ManaRecovUpdateDelta = 0

-- ** EventHandle: Window[name="ClfAnimalLoreWindowManaRecovery"].OnUpdate
function ClfALGumpWindow.onManaRecovUpdate( timepassed  )
	local delta = ClfALGumpWindow.ManaRecovUpdateDelta + timepassed
	if ( delta >= 1 ) then
		ClfALGumpWindow.ManaRecovUpdateDelta = 0
		ClfALGumpWindow.setManaRecovGauge()
	else
		ClfALGumpWindow.ManaRecovUpdateDelta = delta
	end
end


-- 現在マナの予想値ｊからマナ回復ゲージを描画
function ClfALGumpWindow.setManaRecovGauge()
	local recovData = ClfALGumpWindow.ManaRecoveryData
	if ( not recovData ) then
		return
	end
	local time = Interface.TimeSinceLogin
	local win = ClfALGumpWindow.ManaRecovWindowName
	-- 現在マナの予想値
	local expCurMana
	local width
	local manaMax = recovData.manaMax
	local secDelta = math.max( 0, time - recovData.start )
	local restSecStr = ""
	if ( secDelta < recovData.secManaRege ) then
		expCurMana = math.floor( recovData.mana + ( secDelta * recovData.manaRegeVal * 0.1 ) )
		scale = math.min( 1, expCurMana / manaMax )
		width = math.floor( 160 * scale )
		restSecStr = " (" ..  tostring( math.ceil( recovData.secManaRege - secDelta ) ) .. "s)"
	else
		if ( DoesWindowExist( win ) ) then
			DestroyWindow( win )
		end
		return
	end

	WindowSetDimensions( win .. "Gauge", width, 4 )
	LabelSetText( win .. "Val", towstring( expCurMana .. restSecStr ) )
end


-- rateから、もしくは上限、下限値からvalのパーセントを求め、0:赤→ 0.5:白→ 1.0:青 の色を返す
function ClfALGumpWindow.getRateColor( rate, val, lwr, upr )
	local r = 255
	local g = 255
	local b = 255

	if ( rate or val and val > 0 ) then
		rate = rate or ClfALGumpWindow.getRate( val, lwr, upr )
		rate = math.min( 1, math.max( 0, rate ) )

		if ( rate < 0.5 ) then
			local cRate = rate * 2
			g = 20 + math.floor( 230 * cRate )
			b = g
		elseif ( rate > 0.5 ) then
			local cRate = ( rate - 0.5 ) * 2
			r = 250 - math.floor( 235 * cRate )
	--		g = 235
		end
	end

	return { r = r, g = g, b = b }
end


function ClfALGumpWindow.getRate( val, lwr, upr )
	if ( not tonumber( val ) or not tonumber( lwr ) or not tonumber( upr )) then
		return 0
	end

	if ( upr > 0 and val >= upr ) then
		return val / upr
	elseif ( val > 0 and val <= lwr ) then
		return ( -1 * lwr / val ) + 1
	end

	local range = upr - lwr
	local delta = val - lwr

	if ( range < 0 ) then
		if ( delta >= 0 ) then
			return 1
		else
			return 0
		end
	elseif ( upr > 0 and range == 0 ) then
		return val / upr
	end

	return delta / range
end


-- mobileId または LoreDataからロア時点のマナ回復量、全回復までの時間（秒）を得る
-- 計算式は UO職人の部屋  http://www.geocities.co.jp/Playtown-Yoyo/4812/  から。
function ClfALGumpWindow.getManaRecoveryTime( id, Data )
	Data = Data or id and ClfALGump.LoreDatas[ id ]

	if ( not Data or not Data.Skill or not Data.Status ) then
		return nil
	end

	local stat_mana_curr = Data.Status.mana.current
	local stat_mana_max = Data.Status.mana.val

	if ( type( stat_mana_curr ) ~= "number" or type( stat_mana_max ) ~= "number" or stat_mana_max <= 0 ) then
		return nil
	elseif ( stat_mana_max <= stat_mana_curr ) then
		return 0
	end

	local mathFloor = math.floor
	local mathMax = math.max
	local mathCeil = math.ceil
	local mathSqrt = math.sqrt
	local mathRound = function( num )
		return mathFloor( num + 0.5 )
	end

	local mana_delta = stat_mana_max - stat_mana_curr

	local skill_focus = Data.Skill.focus
	skill_focus = skill_focus.current and tonumber( skill_focus.current ) or 0

	local skill_meditation = Data.Skill.meditation
	skill_meditation = skill_meditation.current and tonumber( skill_meditation.current ) or 0

	local stat_int = Data.Status.int
	stat_int = stat_int.val or 0

	local stat_manaregen = Data.Status.regeneMana
	stat_manaregen = stat_manaregen.val or 0

	local k_medi_skill = ( skill_meditation >= 100 ) and 1.1 or 1
	local k_skill_total = ( 2 * skill_meditation + skill_focus ) / 360

	local rege_val_focus = mathRound( 100 * skill_focus / 20.0 ) / 100
	local rege_val_medi = mathRound( 100 * k_medi_skill * ( 3 * skill_meditation +  stat_int ) / 40 ) / 100
	local rege_val_ability = mathMax( 0, mathRound( 100 * ( mathSqrt( stat_manaregen ) * ( 2.35 + 0.65 * k_skill_total ) - ( 1.35 + 0.65 * k_skill_total ) ) ) / 100 )

	local rege_val_total = mathFloor( rege_val_focus + rege_val_medi + rege_val_ability + 2 )

	local sec_mana_recover = mathCeil( 100 * 10 * mana_delta / rege_val_total ) / 100

	return sec_mana_recover, rege_val_total
end



function ClfALGumpWindow.onHueBtnLUp()
	local name = SystemData.ActiveWindow.name
	local parent = WindowGetParent( WindowGetParent( name ) )
	local mobileId = WindowGetId( parent )

	if ( mobileId and mobileId > 0 ) then
		HandleSingleLeftClkTarget( mobileId )
	end
end


function ClfALGumpWindow.onHueBtnLDbl()
	local name = SystemData.ActiveWindow.name
	local parent = WindowGetParent( WindowGetParent( name ) )
	local mobileId = WindowGetId( parent )

	if ( mobileId and mobileId > 0 ) then
		HandleSingleLeftClkTarget( mobileId )
		UserActionUseSkill( 2 )	-- animal lore
	end
end


function ClfALGumpWindow.onHueBtnOver()
	local parent = WindowGetParent( WindowGetParent( SystemData.ActiveWindow.name ) )
	local mobileId = WindowGetId( parent )

	if( mobileId and mobileId > 0 and not MobileHealthBar.windowDisabled[ mobileId ] and MobileHealthBar.hasWindow[ mobileId ] ) then
		MobileHealthBar.mouseOverId = mobileId
		local itemData = {
			windowName = SystemData.ActiveWindow.name,
			itemId = mobileId,
			itemType = WindowData.ItemProperties.TYPE_ITEM,
		}
		ItemProperties.SetActiveItem( itemData )
	end
end


function ClfALGumpWindow.onHueBtnOverEnd()
	ItemProperties.ClearMouseOverItem()
	MobileHealthBar.mouseOverId = 0
	if ( DoesWindowNameExist("MobileArrow") ) then
		DestroyWindow("MobileArrow")
	end
end


function ClfALGumpWindow.onStickyCheckBtn()
	local name = SystemData.ActiveWindow.name
	local enable = not ButtonGetPressedFlag( name )
	local parent = WindowGetParent( name )
	local mobileId = WindowGetId( parent )

	ButtonSetStayDownFlag( name, enable )
	ButtonSetPressedFlag( name, enable )

	ClfALGumpWindow.StickyId = enable and mobileId
	ClfALGumpWindow.updateCombo()
end


function ClfALGumpWindow.onCloseOrgCheckBtn()

	local name = SystemData.ActiveWindow.name
	local enable = not ButtonGetPressedFlag( name )

	ClfALGumpWindow.setEnableCloseOrgGump( enable, name )
end


function ClfALGumpWindow.setEnableCloseOrgGump( enable, name )
	name = name or ClfALGumpWindow.WindowName .. "HeaderCloseOrgCheck"

	ButtonSetStayDownFlag( name, enable )
	ButtonSetPressedFlag( name, enable )

	Interface.SaveBoolean( "ClfALGumpWindowCloseOrg", enable )
	ClfALGumpWindow.CloseOrgGump = enable
end



