
ClfUtil = {}


ClfUtil.HOUR_IN_SECONDS = 60 * 60
ClfUtil.DAY_IN_SECONDS = ClfUtil.HOUR_IN_SECONDS * 24
ClfUtil.GAP_JST = ClfUtil.HOUR_IN_SECONDS * 9

ClfUtil.LOG_EXPORT_DIR = "clfExport/"


-- プレイヤーが使役しているmobのプロパティに使われるtId
local WorkerMobileTids = {}
local CONST = {
	PetPropTids = {
		[502006]  = "pet",	-- "ペット"
		[1049608] = "petBonded",	-- "おきにいり"
	},
	SummonedPropTids = {
		[1049646] = "summon",	-- "召喚" （NPCが召喚したmobには付かないっぽい） ※ 一部の召喚mob（ネクロのSummon FamiliarやAnimate Deadなど）では付かない
	},
}



function ClfUtil.initialize()
	BuffDebuff.ShouldCreateNewBuff()

	-- WorkerMobileTids を生成
	if ( not next( WorkerMobileTids ) ) then
		local allTids = {
			[1] = CONST.PetPropTids,
			[2] = CONST.SummonedPropTids,
		}
		for i = 1, #allTids do
			local tids = allTids[ i ]
			for k, _ in pairs( tids ) do
				WorkerMobileTids[ k ] = i
			end
		end
	end
end


-- テーブルのマージ：連想配列用
-- ※ コピーでは無く、第一引数のテーブルを直接変更する。
-- 　 コピーしたい時は、第一引数を {} とし、第二引数（およびそれ以降）にマージするテーブルを順に指定すること。
function ClfUtil.mergeTable( t1, ... )
	local type = type

	if ( type( t1 ) ~= "table" ) then
		return t1
	end

	local tbls = { ... }

	local pairs = pairs
	local merge = ClfUtil.mergeTable

	for j = 1, #tbls do
		local t2 = tbls[ j ]
		if ( type( t2 ) == "table" ) then
			for k, v2 in pairs( t2 ) do
				local v
				if ( type( v2 ) == "table"  ) then
					local v1 = t1[ k ]
					if ( type( v1 ) ~= "table" ) then
						v1 = {}
					end
					v = merge( v1, v2 )
				else
					v = v2
				end
				t1[ k ] = v
			end
		end
	end

	return t1
end


-- 配列の結合
function ClfUtil.joinArray( ... )
	local ret = {}
	local arrs = {...}
	local merge = ClfUtil.mergeTable
	local type = type

	for j = 1, #arrs do
		local arr = arrs[ j ]
		if ( type( arr ) == "table" ) then
			for i = 1, #arr do
				local v = arr[ i ]
				if ( type( v ) == "table" ) then
					v = merge( {}, v )
				end
				ret[ #ret + 1 ] = v
			end
		end
	end

	return ret
end


-- テーブルに値があるかチェックする：連想配列用
function ClfUtil.isInTable( val, t )
	local ret = false
	if ( type( t ) ~= "table" ) then
		return ret
	end

	for k, v in pairs( t ) do
		if ( val == v ) then
			ret = true
			break
		end
	end

	return ret
end


-- 配列に値があるかチェックする
function ClfUtil.isInArray( val, t )
	local ret = false
	if ( type( t ) ~= "table" ) then
		return ret
	end

	local index = false
	for i = 1, #t do
		if ( val == t[ i ] ) then
			ret = true
			index = i
			break
		end
	end

	return ret, index
end


-- テーブルが空かどうかの判定
-- 引数にtable以外を渡した場合も「空」とみなす。
function ClfUtil.tableEmpty( tbl )
	if ( type( tbl ) ~= "table" ) then
		return true
	end
	return not next( tbl )
end


-- テーブルに実際に存在する要素数(=num of elements)
-- 「#」や「table.getn」「table.maxn」では連想配列テーブルの要素数は調べられない
function ClfUtil.tableElemn( t )
	local n = 0
	for _ in pairs( t ) do
		n = n + 1
	end
	return n
end


-- 文字列をセパレータで分割したテーブルを返す： テーブル内の各文字列はwstring型になる
-- （numStrToNumを指定すると、セル内の文字列が数字だけならNumber型にする）
-- **
-- * div [Wstring or String] : セパレータ
-- * str [Wstring or String] : 分割する文字列
-- * usePattern [bool] : セパレータにパターンを使うか
-- * numStrToNum [bool] : 分割後の文字列が数字だけだった場合に Number型に変換するか
function ClfUtil.explode( div, str, usePattern, numStrToNum )
	if ( not div or div == L"" or div == "" ) then
		return { str }
	end

	local isPlain = not usePattern

	local find = wstring.find
	local sub = wstring.sub
	local towstring = towstring
	local type = type
	local tonumber = tonumber
	local tostring = tostring
	local string_match
	local numFunc

	if ( numStrToNum ) then
		string_match = string.match
		numFunc = function( s )
			local ts = tostring( s )
			local num = tonumber( ts )
			if ( num and string_match( ts, "^[%-%+]?[.]?%d+[.]?%d*$" ) ) then
				s = num
			end
			return s
		end
	else
		numFunc = function( s ) return s end
	end

	if ( type( div ) ~= "wstring" ) then
		div = towstring( div )
	end
	if ( type( str ) ~= "wstring" ) then
		str = towstring( str )
	end
	local pos, arr = 0, {}

	for st, sp in function() return find( str, div, pos, isPlain ) end do
		arr[ #arr + 1 ] = numFunc( sub( str, pos, st - 1 ) ) -- Attach chars left of current divider
		pos = sp + 1 -- Jump past current divider
	end
	arr[ #arr + 1 ] = numFunc( sub( str, pos ) ) -- Attach chars right of last divider

	return arr
end


-- rgb値の連想配列から明度を求める
function ClfUtil.rgbIMax( rgb )
	if ( type( rgb ) ~= "table" ) then
		return 0
	end
	local iMax = 0
	local mathMax = math.max
	local rgbKeys = { "r", "g", "b" }
	for i = 1, #rgbKeys do
		local v = rgb[ rgbKeys[ i ] ]
		if ( type( v ) == "number" ) then
			iMax = mathMax( iMax, v )
		end
	end
	return math.min( iMax, 255 )
end


-- rgb値の連想配列から明度・彩度を求める
function ClfUtil.rgbSV( rgb )
	local sv = { v = 0, s = 0 }
	if ( type( rgb ) ~= "table" ) then
		return sv
	end
	local iMax = 0
	local iMin = 255
	local mathMax = math.max
	local mathMin = math.min
	local rgbKeys = { "r", "g", "b" }
	for i = 1, #rgbKeys do
		local v = rgb[ rgbKeys[ i ] ]
		if ( type( v ) == "number" ) then
			iMax = mathMax( iMax, v )
			iMin = mathMin( iMin, v )
		end
	end
	iMax = mathMin( iMax, 255 )
	iMin = mathMax( iMin, 0 )
	sv.v = iMax
	if ( iMax <= 0 ) then
		sv.s = 0
	else
		sv.s = ( iMax - iMin ) / iMax
	end
	return sv
end


-- タイムスタンプから、時、分、秒 の配列を返す
function ClfUtil.getTimeArrByTimestamp( timestamp )
	if ( timestamp and timestamp > 0 ) then
		local dis = ClfUtil.DAY_IN_SECONDS
		-- 冗長な計算になっているが、timestampに加算すると正常な値が返ってこない事が多い為
		local time = ( timestamp % dis + ClfUtil.GAP_JST ) % dis
		local floor = math.floor
		local his = ClfUtil.HOUR_IN_SECONDS
		local h = floor( time / his )
		local m = floor( time % his / 60 )
		local s = floor( time % 60 )

		return { h, m, s }
	end
end


-- str文字列をlogディレクトリ内にテキストファイルとして出力する
function ClfUtil.exportStr( str, fileName, suffix, dir, silent )

	local tostring = tostring
	fileName = fileName and tostring( fileName ) or "_export"

	if ( not str or str == L"" or str == "" ) then
		WindowUtils.ChatPrint( towstring( fileName ) .. L" is Blank. Not export " , SystemData.ChatLogFilters.SYSTEM )
		return
	end

	suffix = suffix and tostring( suffix ) or ""
	dir = dir and tostring( dir ) .. "/" or ClfUtil.LOG_EXPORT_DIR

	local format = string.format

	if ( type( str ) == "string" ) then
		str = StringToWString( str )
	end

	local Clock = Interface.Clock

	local clockstring = Clock.YYYY .. format( "%02d", Clock.MM ) .. format( "%02d", Clock.DD ) .. "-" .. format( "%02d", Clock.h ) .. format( "%02d", Clock.m ) .. format( "%02d", Clock.s )

	local filePath =  "logs/" .. dir ..fileName .. "_[" .. clockstring .. "]" .. suffix .. ".txt"

	local logName = "clfExportStr"

	TextLogCreate( logName, 1 )
	TextLogSetEnabled( logName, true )
	TextLogClear( logName )
	TextLogSetIncrementalSaving( logName, true, filePath )

	TextLogAddEntry( logName, 1, str )
	TextLogDestroy( logName )

	if ( not silent ) then
		WindowUtils.ChatPrint( towstring( "File Exported: " .. filePath ) , SystemData.ChatLogFilters.SYSTEM )
	end
end



local NeutralMobNames = {
	[L"a cat"]               = true,
	[L"a dog"]               = true,
	[L"a rat"]               = true,
	[L"a rabbit"]            = true,
	[L"a jack rabbit"]       = true,

	-- farm
	[L"a pig"]               = true,
	[L"a boar"]              = true,
	[L"a hind"]              = true,
	[L"a great hart"]        = true,
	[L"a cow"]               = true,
	[L"a bull"]              = true,
	[L"a chicken"]           = true,
	[L"a greater chicken"]   = true,
	[L"a sheep"]             = true,

	[L"a goat"]              = true,
	[L"a mountain goat"]     = true,

	-- ferret
	[L"a ferret"]            = true,
	[L"a squirrel"]          = true,

	-- catamount
	[L"a cougar"]            = true,
	[L"a panther"]           = true,
	[L"a snow leopard"]      = true,

	-- bear
	[L"a brown bear"]        = true,
	[L"a black bear"]        = true,
	[L"a grizzly bear"]      = true,
	[L"a polar bear"]        = true,

	-- wolf
	[L"a grey wolf"]         = true,
	[L"a timber wolf"]       = true,
	[L"a white wolf"]        = true,

	[L"a walrus"]            = true,

	[L"a gorilla"]           = true,

	[L"a horse"]             = true,
	[L"a llama"]             = true,
	[L"a ridable llama"]     = true,
	[L"a forest ostard"]     = true,
	[L"a desert ostard"]     = true,
	[L"a swamp dragon"]      = true,

	-- bird
	[L"a bird"]              = true,
	[L"a canary"]            = true,
	[L"a chickadee"]         = true,
	[L"a crossbill"]         = true,
	[L"a crow"]              = true,
	[L"a cuckoo"]            = true,
	[L"a dove"]              = true,
	[L"a finch"]             = true,
	[L"a hawk"]              = true,
	[L"a kingfisher"]        = true,
	[L"a lapwing"]           = true,
	[L"a magpie"]            = true,
	[L"mister gobbles"]      = true,
	[L"a nightingale"]       = true,
	[L"a nuthatch"]          = true,
	[L"a plover"]            = true,
	[L"a raven"]             = true,
	[L"a shrike"]            = true,
	[L"a skylark"]           = true,
	[L"a sparrow"]           = true,
	[L"a starling"]          = true,
	[L"a swallow"]           = true,
	[L"a swift"]             = true,
	[L"a tern"]              = true,
	[L"a thrush"]            = true,
	[L"a towhee"]            = true,
	[L"a tropical bird"]     = true,
	[L"a turkey"]            = true,
	[L"a warbler"]           = true,
	[L"a woodpecker"]        = true,
	[L"a wren"]              = true,
	[L"an eagle"]            = true,

	-- malas
	[L"a skittering hopper"] = true,

	-- tokuno
	[L"a crane"]             = true,
	[L"a gaman"]             = true,

}


function ClfUtil.isNeutralMobileName( mobileId, mobName )
	local type = type
	if ( mobName and type( mobName ) == "wstring" and mobName ~= L"" ) then
		mobName = wstring.trim( mobName )
	end
	if ( type( mobName ) ~= "wstring" or mobName == L"" ) then
		mobName = ClfUtil.getMobName( mobileId )
	end

	if ( mobName and type( mobName ) == "wstring" and mobName ~= L"" ) then
		mobName = wstring.lower( mobName )
		if ( NeutralMobNames[ mobName ] == true ) then
			return true
		end
	end

	return false
end


local MobNames = {}
local LastMobNameCleanTime = 0

function ClfUtil.getMobName( mobileId )
	if ( not mobileId or mobileId < 1 ) then
		return
	end

	local time = Interface.TimeSinceLogin
	if ( LastMobNameCleanTime + 360 < time ) then
		ClfUtil.cleanMobNames( false )
	end

	local lastNameObj = MobNames[ mobileId ]
	if ( lastNameObj ) then
		if ( lastNameObj.time + 60 < time ) then
			return lastNameObj.name
		else
			MobNames[ mobileId ] = nil
		end
	end

	local wTrim = wstring.trim
	local nameFunc = function ( str )
		if ( type( str ) ~= "wstring" or str == L"" ) then
			return false
		end
		local n = wTrim( str )
		if ( type( n ) == "wstring" and n ~= L"" ) then
			return n
		end
	end

	local name = false
	local mobileName = WindowData.MobileName[ mobileId ]
	if ( mobileName and mobileName.MobName ) then
		name = nameFunc( mobileName.MobName )
	end
	if ( not name and IsMobile( mobileId ) ) then
		local mobData = Interface.GetMobileData( mobileId, true )
		if ( mobileData and mobileData.MobName ) then
			name = nameFunc( mobileData.MobName )
		end
		if ( not name ) then
			local props = ItemProperties.GetObjectPropertiesArray( mobileId, "ClfUtil.getMobName" )
			if ( props and props.PropertiesList ) then
				name = nameFunc( props.PropertiesList[1] )
			end
		end
	end

	if ( name ) then
		MobNames[ mobileId ] = {
			name = name,
			time = time,
		}
	end

	return name
end

function ClfUtil.cleanMobNames( force )
	local time = Interface.TimeSinceLogin
	LastMobNameCleanTime = time
	local MobNames = MobNames
	local limit

	local cleanFunc
	if ( force ) then
		cleanFunc = function( id, obj )
			MobNames[ id ] = nil
		end
	else
		limit = time - 360
		cleanFunc = function( id, obj )
			if ( obj and obj.time and obj.time < limit ) then
				MobNames[ id ] = nil
			end
		end
	end

	for id, obj in pairs( MobNames ) do
		cleanFunc( id, obj )
	end
end



function ClfUtil.filterMobileNameData( mobileNameData, mobileId, allowCorpse )
	local name = mobileNameData and mobileNameData.MobName
	if ( name ) then
		if ( type( name ) ~= "wstring" or name == L"" ) then
			return nil
		end

		if ( mobileId and mobileNameData.Notoriety == 0 ) then
			local WindowData = WindowData
			local mobStat = WindowData.MobileStatus[ mobileId ] or {}
			local MobName = mobStat.MobName
			if ( MobName and MobName ~= L"" ) then
				return nil
			end

			if ( allowCorpse ) then
				local contData = WindowData.ContainerWindow[ mobileId ]
				if ( not contData ) then
					RegisterWindowData( WindowData.ContainerWindow.Type, mobileId )
					contData = WindowData.ContainerWindow[ mobileId ]
				end
				if ( contData ) then
					if ( contData.isCorpse ) then
						return mobileNameData
					else
						return nil
					end
				end
			end
		end
	end

	return mobileNameData
end


local WorkerMobileIds = {}
local LastWorkerMobCleanTime = 0

--[[
* mobileIdから、ペット・召喚生物かどうかを返す
* @param  {integer}         mobileId
* @param  {integer|boolean} [mobileType = nil] オプション - 指定無し or false： 全て、 2:召喚生物のみ、 その他:ペットのみ
* @return {boolean}
]]--
function ClfUtil.isWorkerMobile( mobileId, mobileType )
	if ( not mobileId or mobileId < 1 or mobileId == WindowData.PlayerStatus.PlayerId ) then
		return
	end

	local time = Interface.TimeSinceLogin
	if ( LastWorkerMobCleanTime + 180 < time ) then
		WorkerMobileIds = {}
		LastWorkerMobCleanTime = time
	end

	local workerType = nil

	if ( WorkerMobileIds[ mobileId ] ~= nil ) then
		workerType = WorkerMobileIds[ mobileId ]
	else
		workerType = false
		local props = WindowData.ItemProperties[ mobileId ]
		if ( not props ) then
			RegisterWindowData( WindowData.ItemProperties.Type, mobileId )
			props = WindowData.ItemProperties[ mobileId ]
		end

		local tids = props and props.PropertiesTids

		if ( tids and #tids > 1 ) then
			local WorkerMobileTids = WorkerMobileTids

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

			WorkerMobileIds[ mobileId ] = workerType
		end
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



-- EOF
