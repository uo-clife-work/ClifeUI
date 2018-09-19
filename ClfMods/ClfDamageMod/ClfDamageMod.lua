
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfDamageMod", "ClfDamageWindow.xml", "ClfDamageWindow.xml" )

ClfDamageMod = {}

-- 記録する最小ダメージ（これ未満のダメージは記録しない）
ClfDamageMod.MIN_DAMAGE_TO_LOG = 2

-- ログの出力先ディレクトリ
ClfDamageMod.DAMAGE_LOG_DIR = "logs/damage"
-- ログ出力の実行間隔（秒）
ClfDamageMod.DAMAGE_LOG_INTERVAL = 60 * 3

-- データを間引く処理の実行間隔（秒）
ClfDamageMod.CLEAN_DATA_INTERVAL = 60 * 6
-- mobが死亡、データが取得出来なくなるなどしてからダメージ出力用データを保持する時間（秒）
-- ※場所を移動などしてmobデータが取れなくなる場合もあるので若干長めにしておいた方が良いかも
ClfDamageMod.DAMAGE_DATA_CACHE_TIME = 60 * 10


ClfDamageMod.DAMAGE_LOG_NAME = "clf_damage_log"
ClfDamageMod.DamageLogFile = nil

ClfDamageMod.Enable = true
ClfDamageMod.PrintChatEnable = true
ClfDamageMod.SaveLogEnable = true
ClfDamageMod.windowShow = true

ClfDamageMod.EnableNumEffect = true

ClfDamageMod.Damages = {}
ClfDamageMod.DamagedMobCount = 0
ClfDamageMod.LastUpdate = 0

-- オリジナルの DamageWindow.Init を保持する変数
ClfDamageMod.DamageInit_org = nil


function ClfDamageMod.initialize()
	local ClfDamageMod = ClfDamageMod
	local LoadBoolean = Interface.LoadBoolean
	ClfDamageMod.Enable          = LoadBoolean( "ClfDamageModEnable", ClfDamageMod.Enable )
	ClfDamageMod.PrintChatEnable = LoadBoolean( "ClfDamageModPrintChatEnable", ClfDamageMod.PrintChatEnable )
	ClfDamageMod.SaveLogEnable   = LoadBoolean( "ClfDamageModSaveLogEnable", ClfDamageMod.SaveLogEnable )
	ClfDamageMod.windowShow      = LoadBoolean( "ClfDamageModWindowShow", ClfDamageMod.windowShow )
	ClfDamageMod.EnableNumEffect = LoadBoolean( "ClfDamageNumEffect", ClfDamageMod.EnableNumEffect )

	if ( not ClfDamageMod.DamageInit_org ) then
		ClfDamageMod.DamageInit_org = DamageWindow.Init
		DamageWindow.Init = ClfDamageMod.onDamageInit_enable
	end

	ClfDamageMod.setEnable( ClfDamageMod.Enable )

	ClfDamageMod.DamagedMobCount = 0

	if ( ClfDamageMod.windowShow ) then
		ClfDamageWindow.showWindow()
	end

	DamageWindow.OverheadAlive = -150
	DamageWindow.OverheadMove = 2
	DamageWindow.ShiftYAmount = 16
	DamageWindow.MaxAnchorYOverlap = 15
	DamageWindow.OverheadMoveHalf = 1
end


function ClfDamageMod.shutdown()
	ClfDamageMod.autoExportDamages()

	local logName = ClfDamageMod.DAMAGE_LOG_NAME
	if ( TextLogGetEnabled( logName ) ) then
		TextLogDestroy( logName )
	end
end


-- 有効・無効の設定
function ClfDamageMod.setEnable( enable )
	ClfDamageMod.Enable = enable
	Interface.SaveBoolean( "ClfDamageModEnable", enable )
	local onOffStr = L"OFF"

	if ( enable ) then
		onOffStr = L"ON"
	end

	if ( ClfDamageWindow ) then
		ClfDamageWindow.checkSettingBtn( "DamageModEnable", enable )
	end

	Debug.PrintToChat( L"ClfDamageMod : " .. onOffStr )
end


-- ウィンドウ表示の切り替え
function ClfDamageMod.toggleWindow()
	local enable = not ClfDamageMod.windowShow
	ClfDamageMod.windowShow = enable
	Interface.SaveBoolean( "ClfDamageModWindowShow", enable )

	if ( enable ) then
		ClfDamageWindow.showWindow()
	else
		if ( ClfDamageWindow and DoesWindowExist( ClfDamageWindow.WindowName ) ) then
			DestroyWindow( ClfDamageWindow.WindowName )
		end
	end
end


-- チャットログ出力を切り替え
function ClfDamageMod.togglePrintChat( silent )
	local enable = not ClfDamageMod.PrintChatEnable
	ClfDamageMod.PrintChatEnable = enable
	Interface.SaveBoolean( "ClfDamageModPrintChatEnable", enable )

	local onOffStr = L"OFF"
	local hue = 150
	if ( enable ) then
		onOffStr = L"ON"
		hue = 1152
	end

	if ( not silent ) then
		WindowUtils.SendOverheadText( L"ClfDamageMod - PrintChat: " .. onOffStr, hue, false )
	else
		Debug.PrintToChat( L"ClfDamageMod - PrintChat: " .. onOffStr )
	end

	if ( ClfDamageWindow ) then
		ClfDamageWindow.checkSettingBtn( "PrintChatEnable", enable )
	end
end


-- ログファイル出力を切り替え
function ClfDamageMod.toggleSaveLog( silent )
	local enable = not ClfDamageMod.SaveLogEnable
	ClfDamageMod.SaveLogEnable = enable
	Interface.SaveBoolean( "ClfDamageModSaveLogEnable", enable )

	local onOffStr = L"OFF"
	local hue = 150
	if ( enable ) then
		onOffStr = L"ON"
		hue = 1152
	end

	if ( not silent ) then
		WindowUtils.SendOverheadText( L"ClfDamageMod - SaveLog: " .. onOffStr, hue, false )
	else
		Debug.PrintToChat( L"ClfDamageMod - SaveLog: " .. onOffStr )
	end

	if ( ClfDamageWindow ) then
		ClfDamageWindow.checkSettingBtn( "SaveLogEnable", enable )
	end

	if ( enable ) then
		-- 有効に切り替えた時は、即時にログを出力する
		ClfDamageWindow.LogExportDelta = 0
		ClfDamageMod.autoExportDamages()
	end
end


-- ダメージテキストアニメーションの切り替え
function ClfDamageMod.toggleNumEffect( silent )
	local enable = not ClfDamageMod.EnableNumEffect
	ClfDamageMod.EnableNumEffect = enable
	Interface.SaveBoolean( "ClfDamageNumEffect", enable )

	if ( not silent ) then
		local onOffStr = L"OFF"
		local hue = 150
		if ( enable ) then
			onOffStr = L"ON"
			hue = 1152
		end
		WindowUtils.SendOverheadText( L"Damage Num Effect: " .. onOffStr, hue, true )
	end
end


ClfDamageMod.LogExportDelta = 0
ClfDamageMod.CleanDataDelta = 0

function ClfDamageMod.onUpdate( timepassed )

	if ( ClfDamageMod.Enable ) then
		local T = ClfDamageMod

		if ( T.SaveLogEnable ) then
			T.LogExportDelta = T.LogExportDelta + timepassed
			if ( T.LogExportDelta >= T.DAMAGE_LOG_INTERVAL ) then
				T.autoExportDamages()
				T.LogExportDelta = 0
			end
		end

		T.CleanDataDelta = T.CleanDataDelta + timepassed
		if ( T.CleanDataDelta >= T.CLEAN_DATA_INTERVAL ) then
			T.cleanData()
			T.CleanDataDelta = 0
		end

		ClfDamageWindow.onUpdate( timepassed )
	end

end

function ClfDamageMod.onDamageInit_disable()
	-- オリジナルの DamageWindow.Init を実行
	ClfDamageMod.DamageInit_org()
end

function ClfDamageMod.onDamageInit_enable()
	local Damage = Damage
	local mobileId = Damage and Damage.mobileId
	if ( mobileId == nil ) then
		return
	end
	local ClfDamageMod = ClfDamageMod
	local DamageWindow = DamageWindow
	local Interface = Interface
	local WindowData = WindowData
	local PlayerId = WindowData.PlayerStatus.PlayerId

	-- // start Original DamageWindow.Init
	if ( DamageWindow.waitSpecialDamage ) then
		DamageWindow.AddText( mobileId, DamageWindow.waitSpecialDamage )
		DamageWindow.waitSpecialDamage = nil
		DamageWindow.lastSpecialWaiting = nil
	end

	local damageNum = Damage.damageNumber

	local numWindow = DamageWindow.GetNextId()
	local windowName = "DamageWindow" .. numWindow
	local labelName = windowName .. "Text"
	local DW_DefaultAnchorY = DamageWindow.DefaultAnchorY
	local color
	local isPet = IsObjectIdPet( mobileId )
	if ( isPet ) then
		color = DamageWindow.PETGETDAMAGE_COLOR
	elseif ( mobileId == PlayerId ) then
		color = DamageWindow.YOUGETAMAGE_COLOR
	else
		color = DamageWindow.OTHERGETDAMAGE_COLOR
	end

	CreateWindowFromTemplateShow( windowName, "ClfDamageNumTemplate", "Root", false )

	WindowAddAnchor( labelName, "bottom", windowName, "bottom", 0, DW_DefaultAnchorY )
	WindowSetScale( windowName, Interface.OverhedTextSize )

	if ( color ~= nil ) then
		LabelSetTextColor( labelName, color.r, color.g, color.b )
	else
		LabelSetTextColor( labelName, Damage.red, Damage.green, Damage.blue )
	end

	--Shifts the previous damage numbers up if its too close to the new damage numbers
	--this way the damage numbers would not cover each other up
	DamageWindow.ShiftYWindowUp()

	DamageWindow.AttachedId[ numWindow ] = mobileId
	DamageWindow.AnchorY[ numWindow ] = DW_DefaultAnchorY
	LabelSetFont( labelName, FontSelector.Fonts[ OverheadText.DamageFontIndex ].fontName, 20 )
	AttachWindowToWorldObject( mobileId, windowName )

	if ( ClfDamageMod.EnableNumEffect and damageNum > 50 ) then
		local labelScale = 1 + ( damageNum - 50 ) * 0.003
		labelScale = ( labelScale > 1.6 ) and 1.6 or labelScale
		WindowStartScaleAnimation( labelName, Window.AnimationType.EASE_OUT, labelScale, 1, 0.45, false, 0, 0 )
		ClfCommon.setTimeout( "DamagePop_" .. labelName , {
				done = function()
					if ( DoesWindowExist( labelName ) ) then
						WindowStopScaleAnimation( labelName )
					end
				end,
				timeout = ClfCommon.TimeSinceLogin + 0.5,
			} )
	end

	LabelSetText( labelName, towstring( damageNum ) )

	local now = Interface.TimeSinceLogin
	Interface.IsFighting = true
	Interface.IsFightingLastTime = now + 10
	Interface.CanLogout = now + 120

	PaperdollWindow.GotDamage =  true
	-- // End Original DamageWindow.Init

	if ( ClfDamageMod.Enable and damageNum and damageNum >= ClfDamageMod.MIN_DAMAGE_TO_LOG ) then
		local damObj = ClfDamageMod.Damages[ mobileId ]
		local mobileData = WindowData.MobileStatus[ mobileId ]
		if ( not mobileData ) then
			RegisterWindowData( WindowData.MobileStatus.Type, mobileId )
			mobileData = WindowData.MobileStatus[ mobileId ]
		end

		local time = Interface.Clock.Timestamp or 0
		local sec  = ClfCommon.TimeSinceLogin

		if ( not damObj ) then
			-- 最初のダメージ
			local isPlayer
			local count
			local mobData = WindowData.MobileName[ mobileId ]
			local isUnknown = false
			local name = mobData and mobData.MobName or mobileData and mobileData.MobName
			if ( name and name ~= L"" ) then
				name = wstring.gsub( name, L"^%s*", L"" )
				name = wstring.lower( name )
			else
				isUnknown = true
				name = L"???"
			end

			mobileData = mobileData or Interface.GetMobileData( mobileId, true )

			if ( isPet ) then
				count = 0
			elseif ( mobileId == PlayerId ) then
				isPlayer = true
				count = 0
			else
				count = ClfDamageMod.DamagedMobCount + 1
				ClfDamageMod.DamagedMobCount = count
			end

			damObj = {
				name        = name,
				id          = mobileId,
				totalDamage = damageNum,
				lastDamage  = damageNum,
				maxDamage   = damageNum,
				isPet       = isPet,
				isPlayer    = isPlayer,
				isDead      = false,
				start       = time,
				update      = time,
				startSec    = sec,
				lastSec     = sec,
				count       = count,
				hit         = 1,
				isUnknown   = isUnknown,
				pets        = ClfDamageMod.getPetsName(),
			}

			if ( mobileData ) then
				damObj.isDead         = mobileData.IsDead
				damObj.CurrentHealth  = mobileData.CurrentHealth
				damObj.MaxHealth      = mobileData.MaxHealth
			end

			ClfDamageMod.Damages[ mobileId ] = damObj
		else
			-- 2回目以降
			local name = damObj.name
			if ( not name or name == L"???" ) then
				local mobData = WindowData.MobileName[ mobileId ]

				name = mobData and mobData.MobName or mobileData and mobileData.MobName
				if ( not name or name == L"" ) then
					local md = Interface.GetMobileData( mobileId, true )
					name = md and md.MobName
				end
				name = name and wstring.lower( wstring.gsub( name, L"^%s*", L"" ) ) or L"???"
				damObj.name = name
			end
			if ( damObj.start == 0 ) then
				damObj.start = time - 1
			end
			damObj.totalDamage = damObj.totalDamage + damageNum
			damObj.lastDamage  = damageNum
			damObj.update      = time
			damObj.hit         = damObj.hit + 1
			damObj.isPet       = isPet
			damObj.lastSec     = sec

			if ( damageNum > damObj.maxDamage ) then
				damObj.maxDamage = damageNum
			end

			if ( mobileData ) then
				damObj.isDead         = mobileData.IsDead
				damObj.CurrentHealth  = mobileData.CurrentHealth
				damObj.MaxHealth      = mobileData.MaxHealth
			end
		end

		ClfDamageMod.LastUpdate = time
		if ( ClfDamageMod.PrintChatEnable ) then
			ClfDamageMod.printChat( damObj )
		end
	end
end


function ClfDamageMod.printChat( damObj )
	if ( not damObj ) then
		return
	end

	local T = ClfDamageMod
	local ClfS_ExtChatFilters = ClfSettings.ExtChatFilters or {}

	local towstring = towstring
	local wstring_rep = wstring.rep
	local wstring_len = wstring.len

	local filter
	local nameStr
	local prefix
	if ( damObj.isPet ) then
		filter = ClfS_ExtChatFilters.CLF_DAMAGE_PET or SystemData.ChatLogFilters.SYSTEM
		nameStr = damObj.name
		prefix = L"damage "
	elseif ( damObj.isPlayer ) then
		filter = ClfS_ExtChatFilters.CLF_DAMAGE_SELF or SystemData.ChatLogFilters.SYSTEM
		nameStr = damObj.name
		prefix = L"damage "
	else
		filter = ClfS_ExtChatFilters.CLF_DAMAGE or SystemData.ChatLogFilters.SYSTEM
		local count = damObj.count or 1
		local wstring_format = wstring.format
		count = wstring_format( L"%02d", count )
		nameStr = damObj.name .. L" : " .. count
		prefix = L"hit " .. wstring_format( L"%02d", damObj.hit ) .. L" "
	end

	local healthPerc = L""
	if ( damObj.CurrentHealth and damObj.MaxHealth and damObj.MaxHealth > 0 ) then
		healthPerc = towstring( math.ceil( 100 * damObj.CurrentHealth / damObj.MaxHealth ) )
		healthPerc = wstring_rep( L" ", 4 - wstring_len( healthPerc ) ) .. healthPerc .. L"% -"
	end

	local lastDamage = towstring( damObj.lastDamage )
	lastDamage = wstring_rep( L" ", 4 - wstring_len( lastDamage ) ) .. lastDamage

	local text = prefix .. L"[" .. nameStr .. L"]" .. healthPerc .. lastDamage .. L", total: " .. towstring( damObj.totalDamage )

	TextLogAddEntry( "Chat", filter, text )
end


-- ダメージデータに値を追加する
function ClfDamageMod.addDamageData( id, tbl )
	local damages = ClfDamageMod.Damages
	if ( damages[ id ] ) then
		for k, v in pairs( tbl ) do
			damages[ id ][ k ] = v
		end
	end
end


-- ダメージデータにsticky値を追加： 一覧で固定表示する
function ClfDamageMod.setSticky( id, enable )
	local damages = ClfDamageMod.Damages
	if ( damages[ id ] ) then
		local stickNum = enable and GetCurrentDateTime() or nil
		damages[ id ].sticky = stickNum
	end
end


-- ダメージのデータを整理する（不要になったデータを間引く）
function ClfDamageMod.cleanData()
	local ClfDamageMod = ClfDamageMod
	local time = Interface.Clock.Timestamp
	local damages = ClfDamageMod.Damages

	-- 整理した後に残すデータ数の最小値
	local minLen = ClfDamageWindow.LIST_ROW_MAX or 10
	-- 現在のデータ長
	local dataLen = ClfUtil.tableElemn( damages )
	if ( dataLen <= minLen ) then
		return
	end

	ClfDamageMod.autoExportDamages()
	ClfDamageMod.LogExportDelta = 0

	local WD_MobileStatus = WindowData.MobileStatus
	local PlayerId = WindowData.PlayerStatus.PlayerId
	local timeLimit = ClfDamageMod.DAMAGE_DATA_CACHE_TIME
	local removeRow = ClfDamageWindow.removeListRow or _void
	local ListRowIds = ClfDamageWindow.ListRowIds or {}
	local listWindowActive = false
	if ( ClfDamageWindow.CurrentWindowSize ~= "min" ) then
		listWindowActive = true
	end
	local GetDistanceFromPlayer = GetDistanceFromPlayer
	local pairsByTime = ClfDamageMod.pairsByTime

	for id, damObj in pairsByTime( damages ) do
		if ( id == PlayerId or damObj.isPet ) then
			minLen = minLen + 1
			if ( dataLen <= minLen ) then
				break
			end
		elseif (
			not ( ListRowIds[ id ] and listWindowActive )
			and not damObj.sticky
			and time - damObj.update >= timeLimit
		) then

			if ( damObj.isDead ) then
				removeRow( id )
				damages[ id ] = nil
				dataLen = dataLen - 1
				if ( dataLen <= minLen ) then
					break
				end
			else
				local mobileData = WD_MobileStatus[ id ]
				if ( not mobileData ) then
					RegisterWindowData( WD_MobileStatus.Type, id )
					mobileData = WD_MobileStatus[ id ]
				end
				if ( not mobileData or ( not mobileData.MyPet and mobileData.IsDead ) ) then
					removeRow( id )
					damages[ id ] = nil
					dataLen = dataLen - 1
					if ( dataLen <= minLen ) then
						break
					end
				else
					local dist = GetDistanceFromPlayer( id ) or -1
					if ( dist < 0 ) then
						removeRow( id )
						damages[ id ] = nil
						dataLen = dataLen - 1
						if ( dataLen <= minLen ) then
							break
						end
					end
				end
			end
		end
	end
end


-- ペットの名前を取得
function ClfDamageMod.getPetsName()
	local petIds = WindowData.Pets and WindowData.Pets.PetId
	local pets
	if ( petIds and #petIds > 0 ) then
		local petNames = {}
		for i = 1, #petIds do
			local mobileName = WindowData.MobileName[ petIds[ i ] ]
			if ( mobileName and type( mobileName.MobName ) == "wstring" ) then
				petNames[ #petNames + 1 ] = string.gsub( tostring( mobileName.MobName ), "^%s*(.-)%s*$", "%1" )
			end
		end
		if ( #petNames > 0 ) then
			pets = towstring( table.concat( petNames, ", " ) )
		end
	end
	return pets
end


-- ダメージデータ用テーブルを古い順に巡回する為の関数
function ClfDamageMod.pairsByTime( t, f )
	local tmp = {}
	for id, damObj in pairs( t ) do
		tmp[ #tmp + 1 ] = { key = id, v = damObj }
	end
	f = f or function( t1, t2 )
		local a = t1.v
		local b = t2.v
		if ( a.lastSec ~= b.lastSec ) then
			-- ダメージ更新が古い順にする
			return ( a.lastSec < b.lastSec )
		end
		return ( a.count < b.count )
	end
	table.sort( tmp, f )
	local i = 0
	local iter = function()
		i = i + 1
		local k = tmp[ i ]
		if k == nil then
			return nil
		else
			k = k.key
			return k, t[ k ]
		end
	end
	return iter
end


-- ダメージ書き出し用ログを初期化
function ClfDamageMod.initDamageLog()
	if ( ClfDamageMod.SaveLogEnable ) then
		if ( not ClfDamageMod.DamageLogFile ) then
			local format = string.format
			local timestamp, YYYY, MM, DD, h, m, s = GetCurrentDateTime()
			YYYY = 1900 + YYYY
			MM = 1 + MM
			local dateStr = YYYY .. format( "%02d", MM ) .. format( "%02d", DD ) .. "-" .. format( "%02d", h ) .. format( "%02d", m ) .. format( "%02d", s )
			local prefix = "." .. format( "%04x", math.random(0xffff) )
			local op = nil
			if ( Interface.TimeSinceLogin >= 2 ) then
				local playerId = WindowData.PlayerStatus.PlayerId
				if ( playerId and playerId > 0 ) then
					local playerName = WindowData.MobileName[ playerId ]
					playerName = playerName and playerName.MobName
					if ( playerName and wstring.len( playerName ) > 1 ) then
						playerName = string.gsub( tostring( playerName ), "^%s*(.-)%s*$", "%1" )
						op = L"\r\n\r\nPlayer: " .. towstring( playerName ) .. L"\r\n\r\n"
						playerName = string.gsub( playerName, "^Lord ", "" )
						playerName = string.gsub( playerName, "^Lady ", "" )
						playerName = string.gsub( playerName, "[^0-9a-zA-Z%.%,%[%]%-%+%!%^%&%%%$%(%)%'~=#;]", "_" )
						if ( #playerName > 2 ) then
							prefix = prefix .. "." .. playerName
						end
					end
				end
			end
			local logName = ClfDamageMod.DAMAGE_LOG_NAME
			ClfDamageMod.DamageLogFile = ClfDamageMod.DAMAGE_LOG_DIR .. "/damages." .. dateStr .. prefix .. ".txt"

			TextLogCreate( logName, 1 )
			TextLogSetEnabled( logName, true )
			TextLogClear( logName )
			TextLogSetIncrementalSaving( logName, true, ClfDamageMod.DamageLogFile )
			if ( op ) then
				TextLogAddEntry( logName, 1, op )
			end
		end
	end
end


ClfDamageMod.LastExportTime = 0

-- ダメージ情報をログに追加
function ClfDamageMod.addEntryDamageLog()
	local ClfDamageMod = ClfDamageMod
	local damages = ClfDamageMod.Damages
	local op = L"\r\n\r\n"
	local time = Interface.Clock.Timestamp

	local WD_MobileStatus = WindowData.MobileStatus
	local mathMax = math.max
	local mathMin = math.min
	local mathFloor = math.floor
	local mathCeil = math.ceil
	local concat = table.concat
	local stringFormat = string.format
	local towstring = towstring
	local wstringFormat = wstring.format
	local wstringGsub = wstring.gsub
	local DAY_IN_SECONDS = ClfUtil.DAY_IN_SECONDS
	local getTimeArrByTimestamp = ClfUtil.getTimeArrByTimestamp
	local pairsByTime = ClfDamageMod.pairsByTime

	local i = 0

	for id, damObj in pairsByTime( damages ) do
		if ( damObj.isPet or damObj.isPlayer ) then
			continue
		end
		if ( damObj.lastExport and ( damObj.lastExport > damObj.update ) ) then
			continue
		end

		i = i + 1

		local mobileData = WD_MobileStatus[ id ]
		if ( not mobileData ) then
			RegisterWindowData( WD_MobileStatus.Type, id )
			mobileData = WD_MobileStatus[ id ]
		end

		local name = damObj.name
		local count = towstring( damObj.count )
		local hit = mathMax( 1, damObj.hit )
		local curHealth
		local maxHealth
		local isDead = false
		local isUnknown = false

		if ( mobileData ) then
			if ( name == L"???" and mobileData.MobName ) then
				name = mobileData.MobName
				name = wstringGsub( name, L"^%s*", L"" )
			end
			curHealth = mobileData.CurrentHealth
			maxHealth = mobileData.MaxHealth
			isDead = mobileData.IsDead
		else
			isUnknown = true
			curHealth = damObj.CurrentHealth or 25
			maxHealth = damObj.MaxHealth or 25
			isDead = damObj.isDead
		end

		local sec = mathMin( DAY_IN_SECONDS, mathMax( 1, damObj.lastSec - damObj.startSec ) )
		local total = damObj.totalDamage
		local dps = total / sec
		local dph = total / hit
		local health

		if ( isUnknown ) then
			health = L"---"
		elseif ( isDead or maxHealth == 0 ) then
			health = L"0%"
		else
			health = towstring( mathCeil( 100 * mathMin( 1, curHealth / maxHealth ) ) ) .. L"%"
		end

		local timeStart = getTimeArrByTimestamp( damObj.start )

		local timeStr
		if ( timeStart ) then
			timeStrArr = {}
			for j = 1, #timeStart do
				timeStrArr[ j ] = stringFormat( "%02d", timeStart[ j ] )
			end
			timeStr = concat( timeStrArr, ":" )

			local timeUpdate = getTimeArrByTimestamp( damObj.update )
			if ( timeUpdate ) then
				timeStrArr = {}
				for j = 1, #timeUpdate do
					timeStrArr[ j ] = stringFormat( "%02d", timeUpdate[ j ] )
				end
				timeStr = timeStr .. " -> " .. concat( timeStrArr, ":" )
			end

			timeStr = L" [ " .. towstring( timeStr ) .. L" ]"
		else
			timeStr = L""
		end

		damObj.lastExport = time

		op = op .. L"========== " .. wstringFormat( L"%02d", count ) .. timeStr .. L" ==========\r\n" ..
		name .. L" [" .. towstring( id ) .. L"]\r\n\t\r\n" ..
		L"\tTotal Damage: " .. towstring( total ) .. L"\r\n" ..
		L"\tDamage/sec: " .. wstringFormat( L"%.2f", dps ) .. L"\r\n" ..
		L"\tDamage/hit: " .. wstringFormat( L"%.2f", dph ) .. L"\r\n" ..
		L"\tMax Damage: " .. towstring( damObj.maxDamage ) .. L"\r\n" ..
		L"\tHit: " .. towstring( hit ) .. L"\r\n" ..
		L"\tSec: " .. wstringFormat( L"%d:%06.3f", mathFloor( sec / 60 ), sec % 60 ) .. L"\r\n" ..
		L"\tHealth: " .. health .. L"\r\n"

		if ( damObj.pets ) then
			op = op .. L"\t\r\n\tPet: " .. damObj.pets .. L"\r\n"
		end
		op = op .. L"\r\n"
	end

	if ( i < 1 ) then
		return
	end

	if ( not ClfDamageMod.DamageLogFile ) then
		ClfDamageMod.initDamageLog()
	end
	ClfDamageMod.LastExportTime = time
	TextLogAddEntry( ClfDamageMod.DAMAGE_LOG_NAME, 1, op )
end


function ClfDamageMod.autoExportDamages()
	local ClfDamageMod = ClfDamageMod
	if ( ClfDamageMod.SaveLogEnable and ClfDamageMod.LastUpdate >= ClfDamageMod.LastExportTime ) then
		ClfDamageMod.addEntryDamageLog()
	end
end


function DamageWindow.GetNextId()
	local numWindow = 1
	local DW_AttachedId = DamageWindow.AttachedId
	local DoesWindowExist = DoesWindowExist
	while (
		DW_AttachedId[ numWindow ] ~= nil
		or DoesWindowExist( "DamageWindow" .. numWindow ) == true
	) do
		numWindow = numWindow + 1
	end
	return numWindow
end


function DamageWindow.ShiftYWindowUp()
	if ( DamageWindow.IsOverlap() ) then
		local DamageWindow = DamageWindow
		local DW_AnchorY = DamageWindow.AnchorY
		local DW_ShiftYAmount = DamageWindow.ShiftYAmount

		local WindowClearAnchors = WindowClearAnchors
		local WindowAddAnchor = WindowAddAnchor
		for i in pairs( DamageWindow.AttachedId ) do
			local ancY = DW_AnchorY[ i ] - DW_ShiftYAmount
			local windowName = "DamageWindow" .. i
			local labelName = windowName .. "Text"
			WindowClearAnchors( labelName )
			WindowAddAnchor( labelName, "bottomleft", windowName, "bottomleft", 0, ancY )
			DW_AnchorY[ i ] = ancY
		end
	end
end


function DamageWindow.IsOverlap()
	local DamageWindow = DamageWindow
	local DW_AnchorY = DamageWindow.AnchorY
	local DW_MaxAnchorYOverlap = DamageWindow.MaxAnchorYOverlap

	for i in pairs( DamageWindow.AttachedId ) do
		if ( DW_AnchorY[ i ] > DW_MaxAnchorYOverlap ) then
			return true
		end
	end
	return false
end


function DamageWindow.UpdateTime()
	if ( next( DamageWindow.AttachedId ) ~= nil ) then
		local DamageWindow        = DamageWindow
		local DW_AnchorY          = DamageWindow.AnchorY
		local DW_AttachedId       = DamageWindow.AttachedId
		local DW_OverheadAlive    = DamageWindow.OverheadAlive
		local DW_OverheadMove     = DamageWindow.OverheadMove
		local DW_OverheadMoveHalf = DamageWindow.OverheadMoveHalf

		local _windowGetFontAlpha
		local _windowSetFontAlpha
		local WindowClearAnchors = WindowClearAnchors
		local WindowAddAnchor = WindowAddAnchor
		local DestroyWindow = DestroyWindow

		local onWindowAlivedTop
		if ( ClfDamageMod.EnableNumEffect ) then
			_windowGetFontAlpha = WindowGetFontAlpha
			_windowSetFontAlpha = WindowSetFontAlpha
			onWindowAlivedTop = function( i, windowName, ancY )
				local alpha = _windowGetFontAlpha( windowName )
				alpha = alpha - ( 1.6 - alpha ) * 0.04
				if ( alpha <= 0 ) then
					DestroyWindow( windowName )
					DW_AnchorY[ i ] = 0
					DW_AttachedId[ i ] = nil
				else
					local labelName = windowName .. "Text"
					ancY = ancY - DW_OverheadMoveHalf
					_windowSetFontAlpha( windowName, alpha )
					WindowClearAnchors( labelName )
					WindowAddAnchor( labelName, "bottom", windowName ,"bottom", 0, ancY )
					DW_AnchorY[ i ] = ancY
				end
			end
		else
			onWindowAlivedTop = function( i, windowName, ancY )
				DestroyWindow( windowName )
				DW_AnchorY[ i ] = 0
				DW_AttachedId[ i ] = nil
			end
		end

		local count = 0
		for i in pairs( DW_AttachedId ) do
			local ancY = DW_AnchorY[ i ] - DW_OverheadMove

			local windowName = "DamageWindow" .. i
			if ( ancY < DW_OverheadAlive ) then
				onWindowAlivedTop( i, windowName, ancY )
			else
				local labelName = windowName .. "Text"
				WindowClearAnchors( labelName )
				WindowAddAnchor( labelName, "bottom", windowName ,"bottom", 0, ancY )
				DW_AnchorY[ i ] = ancY
			end
			count = count + 1
		end

		--If count is zero reset the numWindow to 1
		if ( count == 0 ) then
			Damage.numWindow = 0
		end
	end
end

