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


ClfDamageMod.Damages = {}
ClfDamageMod.DamagedMobCount = 0
ClfDamageMod.LastUpdate = 0

ClfDamageMod.DAY_IN_SECONDS = 24 * 60 * 60

-- オリジナルの DamageWindow.Init を保持する変数
ClfDamageMod.DamageInit_org = nil


function ClfDamageMod.initialize()
	ClfDamageMod.Enable = Interface.LoadBoolean( "ClfDamageModEnable", ClfDamageMod.Enable )
	ClfDamageMod.PrintChatEnable = Interface.LoadBoolean( "ClfDamageModPrintChatEnable", ClfDamageMod.PrintChatEnable )
	ClfDamageMod.SaveLogEnable = Interface.LoadBoolean( "ClfDamageModSaveLogEnable", ClfDamageMod.SaveLogEnable )
	ClfDamageMod.windowShow = Interface.LoadBoolean( "ClfDamageModWindowShow", ClfDamageMod.windowShow )

	if ( not ClfDamageMod.DamageInit_org ) then
		ClfDamageMod.DamageInit_org = DamageWindow.Init
	end

	ClfDamageMod.setEnable( ClfDamageMod.Enable )

	ClfDamageMod.DamagedMobCount = 0

	if ( ClfDamageMod.Enable and ClfDamageMod.windowShow ) then
		ClfDamageWindow.showWindow()
	end
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
		DamageWindow.Init = ClfDamageMod.onDamageInit_enable
		onOffStr = L"ON"
	else
		DamageWindow.Init = ClfDamageMod.onDamageInit_disable
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

		pcall( ClfDamageWindow.onUpdate, timepassed )
	end

end

function ClfDamageMod.onDamageInit_disable()
	-- オリジナルの DamageWindow.Init を実行
	ClfDamageMod.DamageInit_org()
end

function ClfDamageMod.onDamageInit_enable()
	local T = ClfDamageMod

	-- オリジナルの DamageWindow.Init を実行
	T.DamageInit_org()

	if ( Damage and Damage.mobileId and Damage.damageNumber ) then
		local id = Damage.mobileId
		local damageNum = Damage.damageNumber

		if ( damageNum >= T.MIN_DAMAGE_TO_LOG ) then
			local damObj = T.Damages[ id ]
			local mobileData = Interface.GetMobileData( id, false )
			local time = Interface.Clock.Timestamp

			if ( not damObj ) then
				-- 最初のダメージ
				local isPet = nil
				local isPlayer = nil
				local count
				local mobData = WindowData.MobileName[ id ]
				local isUnknown = false
				local name = mobData and mobData.MobName or mobileData and mobileData.MobName
				if ( name and wstring.len( name ) > 0 ) then
					name = wstring.gsub( name, L"^%s*", L"" )
					name = wstring.lower( name )
				else
					isUnknown = true
					name = L"???"
				end

				mobileData = mobileData or Interface.GetMobileData( id, true )

				if ( mobileData and mobileData.MyPet ) then
					isPet = true
					count = 0
				elseif ( id == WindowData.PlayerStatus.PlayerId ) then
					isPlayer = true
					count = 0
				else
					count = T.DamagedMobCount + 1
					T.DamagedMobCount = count
				end

				damObj = {
					name = name,
					id = id,
					totalDamage = damageNum,
					lastDamage = damageNum,
					maxDamage = damageNum,
					isPlayer = isPlayer,
					isDead = false,
					start = time,
					update = time,
					count = count,
					hit = 1,
					isUnknown = isUnknown,
					pets = T.getPetsName(),
				}

				if ( mobileData ) then
					damObj.isPet = isPet
					damObj.isDead = mobileData.IsDead
					damObj.CurrentHealth = mobileData.CurrentHealth
					damObj.MaxHealth = mobileData.MaxHealth
				end

				T.Damages[ id ] = damObj
			else
				-- 2回目以降
				local name = damObj.name
				if ( not name or name == L"???" ) then
					local mobData = WindowData.MobileName[ id ]

					name = mobData and mobData.MobName or mobileData and mobileData.MobName
					if ( not name or wstring.len( name ) <= 0 ) then
						local md = Interface.GetMobileData( id, true )
						name = md and md.MobName
					end
					name = name and wstring.lower( wstring.gsub( name, L"^%s*", L"" ) ) or L"???"
				end
				if ( not damObj.start or damObj.start < 1 ) then
					damObj.start = time - 1
				end
				damObj.name = name
				damObj.totalDamage = damObj.totalDamage + damageNum
				damObj.lastDamage = damageNum
				damObj.update = time
				damObj.hit = damObj.hit + 1

				if ( damageNum > damObj.maxDamage ) then
					damObj.maxDamage = damageNum
				end

				if ( mobileData ) then
					damObj.isPet = mobileData.MyPet
					damObj.isDead = mobileData.IsDead
					damObj.CurrentHealth = mobileData.CurrentHealth
					damObj.MaxHealth = mobileData.MaxHealth
				end
			end

			T.LastUpdate = time
			if ( ClfDamageMod.PrintChatEnable ) then
				T.printChat( damObj )
			end
		end
	end
end


function ClfDamageMod.printChat( damObj )
	if ( not damObj ) then
		return
	end

	local T = ClfDamageMod

	local filter
	local nameStr
	local prefix
	if ( damObj.isPet ) then
		filter = SystemData.ChatLogFilters.PRIVATE
		nameStr = damObj.name
		prefix = L"damage "
	elseif ( damObj.isPlayer ) then
		filter = SystemData.ChatLogFilters.YELL
		nameStr = damObj.name
		prefix = L"damage "
	else
		filter = SystemData.ChatLogFilters.GESTURE
		local count = damObj.count or 1
		count = wstring.format( L"%02d", count )
		nameStr = damObj.name .. L" : " .. count
		prefix = L"hit " .. wstring.format( L"%02d", damObj.hit ) .. L" "

	end

	local healthPerc = L""
	if ( damObj.CurrentHealth and damObj.MaxHealth and damObj.MaxHealth > 0 ) then
		healthPerc = math.ceil( 100 * damObj.CurrentHealth / damObj.MaxHealth )
		healthPerc = towstring( healthPerc )
		healthPerc = wstring.rep( L" ", 4 - wstring.len( healthPerc ) ) .. healthPerc .. L"% -"
	end

	local lastDamage = towstring( damObj.lastDamage )
	lastDamage = wstring.rep( L" ", 4 - wstring.len( lastDamage ) ) .. lastDamage

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


function ClfDamageMod.tableElemn( t )
	local n = 0
	for v in pairs( t ) do
		n = n + 1
	end
	return n
end


-- ダメージのデータを整理する（不要になったデータを間引く）
function ClfDamageMod.cleanData()
	local time = Interface.Clock.Timestamp
	local damages = ClfDamageMod.Damages

	-- 整理した後に残すデータ数の最小値
	local minLen = ClfDamageWindow and ClfDamageWindow.LIST_ROW_MAX or 10
	-- 現在のデータ長
	local dataLen = ClfDamageMod.tableElemn( damages )
	if ( dataLen <= minLen ) then
		return
	end

	ClfDamageMod.autoExportDamages()
	ClfDamageMod.LogExportDelta = 0

	local timeLimit = ClfDamageMod.DAMAGE_DATA_CACHE_TIME
	local PlayerId = WindowData.PlayerStatus.PlayerId
	local removeRow = ClfDamageWindow and ClfDamageWindow.removeListRow or function() end
	local ListRowIds = ClfDamageWindow and ClfDamageWindow.ListRowIds or {}
	local listWindowActive = false
	if ( ClfDamageWindow and ClfDamageWindow.CurrentWindowSize ~= "min" ) then
		listWindowActive = true
	end
	local GetMobileData = Interface.GetMobileData
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
				local mobileData = GetMobileData( id, false )
				if ( not mobileData or ( not mobileData.MyPet and mobileData.IsDead ) ) then
					removeRow( id )
					damages[ id ] = nil
					dataLen = dataLen - 1
					if ( dataLen <= minLen ) then
						break
					end
				else
					local dist = GetDistanceFromPlayer( id )
					if ( not dist or dist < 0 ) then
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


-- タイムスタンプから、JSTでの 時、分、秒 の配列を返す
function ClfDamageMod.getTimeArrByTimestamp( timestamp )
	if ( timestamp and timestamp > 0 ) then
		local dis = 86400
		local his = 3600
		-- 冗長な計算になっているが、timestampにそのまま加算すると正常な値が返ってこない事が多い為
		local time = ( timestamp % dis + 32400 ) % dis
		local floor = math.floor
		local h = floor( time / his )
		local m = floor( time % his / 60 )
		local s = floor( time % 60 )

		return { h, m, s }
	end
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
		if ( a.update ~= b.update ) then
			-- ダメージ更新が古い順にする
			return ( a.update < b.update )
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
			local timestamp, YYYY, MM, DD, h, m, s  = GetCurrentDateTime()
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
						playerName = string.gsub( tostring( playerName ) , "^%s*(.-)%s*$", "%1" )
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
	local damages = ClfDamageMod.Damages
	local op = L"\r\n\r\n"
	local time = Interface.Clock.Timestamp

	local GetMobileData = Interface.GetMobileData
	local mathMax = math.max
	local mathMin = math.min
	local mathFloor = math.floor
	local mathCeil = math.ceil
	local concat = table.concat
	local stringFormat = string.format
	local towstring = towstring
	local wstringFormat = wstring.format
	local wstringGsub = wstring.gsub
	local DAY_IN_SECONDS = ClfDamageMod.DAY_IN_SECONDS
	local getTimeArrByTimestamp = ClfDamageMod.getTimeArrByTimestamp
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

		local mobileData = GetMobileData( id, false )
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

		local sec = mathMin( DAY_IN_SECONDS, mathMax( 1, damObj.update - damObj.start ) )
		local total = damObj.totalDamage
		local dps = total / sec
		local dph = total / hit
		local health

		if ( isUnknown ) then
			health = L"---"
		elseif ( isDead or maxHealth == 0  ) then
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
		L"\tSec: " .. wstringFormat( L"%d:%02d", mathFloor( sec / 60 ), mathFloor( sec % 60 * 100 ) / 100 ) .. L"\r\n" ..
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
	if ( ClfDamageMod.SaveLogEnable and ClfDamageMod.LastUpdate >= ClfDamageMod.LastExportTime ) then
		ClfDamageMod.addEntryDamageLog()
	end
end


