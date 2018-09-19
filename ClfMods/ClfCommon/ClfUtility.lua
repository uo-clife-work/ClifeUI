
ClfUtil = {}


ClfUtil.HOUR_IN_SECONDS = 60 * 60
ClfUtil.DAY_IN_SECONDS = ClfUtil.HOUR_IN_SECONDS * 24
ClfUtil.GAP_JST = ClfUtil.HOUR_IN_SECONDS * 9

ClfUtil.LOG_EXPORT_DIR = "clfExport/"

ClfUtil.IsHardcoreShard = false


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

	local hardcoreShards = {
		[12] = true,	-- Siege Perilous
		[18] = true,	-- Mugen
	}
	ClfUtil.IsHardcoreShard = ( hardcoreShards[ UserData.Settings.Login.lastShardSelected ] ~= nil )
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


-- php の empty と同じ様な感じでvalを判定
function ClfUtil.isEmpty( val )
	local notVal = not val
	if (
			notVal == true
			or val == 0
			or val == ""
			or val == L""
			or val == "0"
			or val == L"0"
		) then
		return true
	end
	if ( type( val ) == "table" ) then
		return ( next( val ) == nil )
	end
	return notVal
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


function ClfUtil.getClockString( sep, dSep, tSep, force )
	local Clock = Interface.Clock
	local Timestamp, YYYY, MM, DD, h, m, s
	local isEmpty = ClfUtil.isEmpty
	if ( not force and Clock and isEmpty( Clock.Timestamp ) == false and isEmpty( Clock.YYYY ) == false ) then
		YYYY, MM, DD, h, m, s = Clock.YYYY, Clock.MM, Clock.DD, Clock.h, Clock.m, Clock.s
	else
		Timestamp, YYYY, MM, DD, h, m, s = GetCurrentDateTime()
		YYYY = 1900 + YYYY
		MM = MM + 1
	end

	local tostring = tostring
	local format = string.format

	sep = sep and tostring( sep ) or "-"
	dSep = dSep and tostring( dSep ) or ""
	tSep = tSep and tostring( tSep ) or ""

	local clockstring = YYYY .. dSep .. format( "%02d", MM ) .. dSep .. format( "%02d", DD ) .. sep .. format( "%02d", h ) .. tSep .. format( "%02d", m ) .. tSep .. format( "%02d", s )

	return clockstring
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

	if ( type( str ) == "string" ) then
		str = StringToWString( str )
	end

	local filePath =  "logs/" .. dir ..fileName .. "_[" .. ClfUtil.getClockString() .. "]" .. suffix .. ".txt"
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



-- テキストファイルを読み込み（BOMがあればBOMを削除して）テキストを返す
function ClfUtil.loadTextFile( filePath )
	if ( not filePath ) then
		return
	end
	local txt = LoadTextFile( filePath )
	if ( not txt or type( txt ) ~= "wstring" ) then
		-- txtが取得出来なかった
		Debug.PrintToDebugConsole( L"ERROR: " .. towstring( filePath ) .. L"  can't load" )
		return
	end
	if ( txt == L"" ) then
		Debug.PrintToDebugConsole( L"ERROR: " .. towstring( filePath ) .. L"  is Empty" )
		return
	end

	local fe
	local wstring_sub = wstring.sub

	-- BOMのチェック。BOM付きなら取り除く
	local bom_utf8 = L"\239\187\191"
	--	local bom_utf16le = L"\255\254"
	if ( wstring_sub( txt, 1, 3 ) == bom_utf8 ) then
		Debug.PrintToDebugConsole( L"TEXT has UTF-8 BOM: " .. towstring( filePath ) )
		txt = wstring_sub( txt, 4 )
		fe = 'utf-8'
--	elseif ( wstring_sub( txt, 1, 2 ) == bom_utf16le ) then
--		-- BOMのチェックは可能だが、テキストを正常に取得出来ない様なのでヤメ
--		Debug.PrintToDebugConsole( L"TEXT has UTF-16LE BOM: " .. towstring( filePath ) )
--		txt = wstring_sub( txt, 3 )
--		fe = 'utf-16-le'
	end

	return txt, fe
end


-- CSVの読み込み
-- ** 注意：csvの標準書式とは若干異なり、以下の制限がある。
-- *  行頭、行末、カンマ前後、の空白文字は無視する（空白文字は無くても良い）
-- *  ダブルコーテーション内であっても値の中で改行、半角カンマは許可しない（正常に展開出来ない）
-- *  行末は1バイト文字で終了する事（2バイト文字+改行だと、正常に展開出来ない場合がある）
-- *  エンコードはutf-8のみ（BOMの有無は問わないが、無い方が良いかも）。
-- *  改行コードはCRLFのみ。
function ClfUtil.loadCSVtoArray( filePath )

	--	local csv = LoadTextFile( filePath )
	local csv = ClfUtil.loadTextFile( filePath )
	if ( not csv ) then
		-- csvが取得出来なかった
		--		Debug.PrintToChat( L"ERROR: " .. towstring( filePath ) .. L" - can't load" )
		return
	end

	local tbl = {}

	local type = type
	local gsub = wstring.gsub
	local explode = ClfUtil.explode

	--	 -- 空白行を削除
	--	csv = gsub( csv, L"^%s*\r\n", L"" )
	-- 一旦、各行毎の配列を作る
	local csvLines = explode( L"\r\n", csv )
	local diviser = L"[\"']?%s*,%s*[\"']?"
	for i = 1, #csvLines do
		local line = csvLines[ i ]
		-- 行頭の空白（およびダブルコーテーション）を削除
		line = gsub( line, L"^%s*[\"]?", L"" )
		if ( type( line ) == "wstring" and line ~= L"" ) then
			-- 行末の空白（およびダブルコーテーション）を削除
			--			line = gsub( line, L"^%s*[\"']?", L"" )
			line = gsub( line, L"[\"']?%s*$", L"" )
			-- 行を diviser で分割した配列にする
			tbl[ #tbl + 1 ] =  explode( diviser, line, true, true )
		end
	end

	return tbl
end



--[[
* CSVの読み込み： 各行の1列目の値をキーにしたテーブルを返す。子のテーブル内の各値にはcsv1行目の各キーを割り当てる
* 注意：csvの標準書式とは若干異なり、以下の制限がある。
*   行頭、行末、カンマ前後、の空白文字は無視する （空白文字は無くても良い）
*   ダブルコーテーション内であっても値の中で改行、半角カンマは許可しない （正常に展開出来ない）
*   行末は1バイト文字で終了する事 （2バイト文字+改行だと、正常に展開出来ない場合がある）
*   エンコードは UTF-8のみ（BOMの有無は問わないが、無い方が良いかも）。
*   改行コードはCRLFのみ。
*
* @param  {string} filePath              読み込むファイルへのパス
* @param  {array}  [requireKeys = nil]   オプション - csvから取得するデータのキーを列挙した配列。 1列目のキーは指定しなくてもOK。
*                                        これを指定すると、指定したキーに対応した値のみテーブルにセットする。
* @param  {table}  [opt         = {}]    オプション - 下記の各オプションを設定するテーブル
*                  e.g. opt = {
*                     toStrKeys   = { "keyName1", ... },
*                     numOnlyKeys = { "keyName2", ... },
*                     nilOrTrueKeys = { "keyName3", ... },
*                  }
*            {array}  [opt.toStrKeys   = nil]   取得した値を string型に変換するキーを列挙した配列
*            {array}  [opt.numOnlyKeys = nil]   number型のみ許可するキーを列挙した配列。
*                                               指定したキーの値がカラ文字や数字以外の時はnilにする。（0にはしない）
*            {array}  [opt.nilOrTrueKeys = nil]
*
* @return {table|nil}  csvからデータを取得出来た時は下記の様なテーブルが返る。 有効なデータが無いor正常に取得出来なかった時は nil
*            e.g. ret = {
*               [ col2_row1 ] = { csvhead_row2 = c2_r2, csvhead_row3 = c2_r3, ... },
*               [ col3_row1 ] = { csvhead_row2 = c3_r2, csvhead_row3 = c3_r3, ...  },
*               ...
*            }
]]
function ClfUtil.loadCSVtoTable( filePath, requireKeys, opt )

	--	local csv = LoadTextFile( filePath )
	local csv = ClfUtil.loadTextFile( filePath )
	if ( not csv ) then
		-- csvが取得出来なかった
		--		Debug.PrintToChat( L"ERROR: " .. towstring( filePath ) .. L" - can't load" )
		return
	end

	local type = type
	local gsub = wstring.gsub
	local explode = ClfUtil.explode

	--	-- 空白行を削除
	--	csv = gsub( csv, L"^%s*\r\n", L"" )
	-- 一旦、各行毎の配列を作る
	local csvLines = explode( L"\r\n", csv )
	-- 各行の文字列を区切るパターン
	local diviser = L"[\"]?%s*,%s*[\"]?"

	local tostring = tostring
	local tonumber = tonumber

	-- データ用デーブルに必要なキーが指定されていれば判定用のテーブルを作る
	local reqKeys
	if ( type( requireKeys ) == "table" and #requireKeys ~= 0 ) then
		reqKeys = {}
		for i = 1, #requireKeys do
			reqKeys[ requireKeys[ i ] ] = true
		end
	end

	-- ヘッダー行からキーの取得開始
	local csvHeader		-- ヘッダ行内の各列名を保持する（各行のデータ用テーブルのキーとして使用する）
	local headerCol = 1	-- ヘッダ行のインデックスを保持する: 通常なら1のままになるはず（先頭行がカラのCSVでもデータを取得出来る様にしている）
	local headerNum = 0	-- ヘッダ行の列数を保持する
	for i = headerCol, #csvLines do
		local line = csvLines[ i ]
		if ( line == L"" ) then
			continue
		end
		-- 行頭の空白（およびダブルコーテーション）を削除
		line = gsub( line, L"^%s*[\"]?", L"" )
		if ( type( line ) ~= "wstring" or line == L"" ) then
			continue
		end
		-- 行末の空白（およびダブルコーテーション）を削除
		line = gsub( line, L"[\"]?%s*$", L"" )
		-- 行を diviserで分割した配列にする
		local arr = explode( diviser, line, true, false )
		headerNum = arr and #arr or 0
		if ( headerNum > 1 ) then
			csvHeader = arr
			for j = 1, #csvHeader do
				-- 各キーは"string"型にする
				local keyName = tostring( csvHeader[ j ] )
				if ( not keyName or keyName == "" ) then
					-- キー名がカラならfalseとして保持
					keyName = false
				end
				if ( j ~= 1 and reqKeys and not reqKeys[ keyName ] ) then
					-- 必要なキーが指定されていれば、それ以外のキーはfalseとして保持
					-- 1列目は返却するテーブルのキーにするので必ず登録（falseにしない）
					keyName = false
				end
				csvHeader[ j ] = keyName
			end
			headerCol = i
			break
		end
	end

	if ( not csvHeader or headerNum < 2 or #csvLines <= headerCol ) then
		-- キーとなる配列が取得出来なかった or キーが1個以下だった（データのテーブル用キーが無い） or ヘッダ行のみのcsvだった
		Debug.PrintToChat( L"ERROR: " .. towstring( filePath ) .. L" - empty data" )
		return
	end

	opt = ( type( opt ) == "table" ) and opt or {}
	local toStrKeys   = opt.toStrKeys
	local numOnlyKeys = opt.numOnlyKeys
	local nilOrTrueKeys = opt.nilOrTrueKeys

	-- 返却するテーブル
	local retTbl = {}

	-- string型にする値のキー判定用テーブルを作る
	local stringDataKeys = {}
	if ( type( toStrKeys ) == "table" ) then
		for i = 1, #toStrKeys do
			stringDataKeys[ toStrKeys[ i ] ] = true
		end
	end

	-- number型以外は許可しない値のキー判定用テーブルを作る
	local numberDataKeys = {}
	if ( type( numOnlyKeys ) == "table" ) then
		for i = 1, #numOnlyKeys do
			numberDataKeys[ numOnlyKeys[ i ] ] = true
		end
	end

	-- nilかtrueにする値のキー判定用テーブルを作る
	local boolDataKeys = {}
	if ( type( nilOrTrueKeys ) == "table" ) then
		for i = 1, #nilOrTrueKeys do
			boolDataKeys[ nilOrTrueKeys[ i ] ] = true
		end
	end

	local next = next

	-- データをnumber型に変換するメソッド
	local convToNum = function( data )
		if ( type( data ) == "number" ) then
			return data
		end
		if ( not data or data == L"" or data == "" ) then
			-- 値がカラならnil
			return nil
		end
		-- wstringをtonumberすると、数字文字列以外でもnilにならない事が多いのでstring型にしてから
		return tonumber( tostring( data ) )
	end

	-- データをtrueに変換するメソッド（falseの場合はnil）
	local convToBool = function( data )
		local notData = not data
		if ( notData or data == L"" or data == "" or data == 0 or data == L"0" or data == "0" or data == 0 ) then
			-- 値がカラならnil
			return nil
		end
		return not notData
	end

	local headerKey1 = csvHeader[1]
	-- データのキーを変換するメソッド
	local sanitizeDataKey
	if ( numberDataKeys[ headerKey1 ] ) then
		sanitizeDataKey = function( k )
			return convToNum( k )
		end
	elseif ( stringDataKeys[ headerKey1 ] ) then
		sanitizeDataKey = function( k )
			k = k and tostring( k )
			return k
		end
	else
		sanitizeDataKey = function( k )
			return k
		end
	end

	-- 各行のデータ取得開始
	for i = headerCol + 1, #csvLines do
		local line = csvLines[ i ]
		if ( line == L"" ) then
			continue
		end
		-- 行頭の空白（およびダブルコーテーション）を削除
		line = gsub( line, L"^%s*[\"]?", L"" )
		if ( type( line ) ~= "wstring" or line == L"" ) then
			-- wstring.gsubの結果文字列がカラになると（？）string型になってしまうようなので、タイプチェックもする
			continue
		end
		-- 行末の空白（およびダブルコーテーション）を削除
		line = gsub( line, L"[\"]?%s*$", L"" )
		-- 行を diviser で分割した配列にする
		local arr = explode( diviser, line, true, true )
		if ( #arr <= 1 ) then
			continue
		end

		-- データのキーを取得： 行の1列目
		local key = sanitizeDataKey( arr[ 1 ] )
		if ( not key or key == "" or key == L"" ) then
			continue
		end

		-- 行のデータ用テーブルを生成： 1列目はキーになるので2列目から
		local tbl = {}
		for idx = 2, headerNum do
			local cKey = csvHeader[ idx ]
			if ( not cKey ) then
				continue
			end

			local data = arr[ idx ]
			if ( data ~= nil ) then
				if ( boolDataKeys[ cKey ] ) then
					data = convToBool( data )
				elseif ( numberDataKeys[ cKey ] ) then
					data = convToNum( data )
				elseif ( stringDataKeys[ cKey ] ) then
					data = tostring( data )
				end

				tbl[ cKey ] = data
			end
		end

		if ( not next( tbl ) ) then
			-- データ用テーブルが空： 何もしないでループ継続
			continue
		end

		-- DEBUG用
--		tbl.csvRow = i

		-- 返却用テーブルにデータを保持
		retTbl[ key ] = tbl
	end

	if ( not next( retTbl ) ) then
		-- 返却用テーブルがカラ： nil を返す
		return nil
	end
	return retTbl
end


local ContextMenuItems = {}

local CleanContextMenuDelta = 0

local function CleanContextMenuItems()
	local now = ClfCommon.TimeSinceLogin
	if ( CleanContextMenuDelta >= now ) then
		return
	end

	local ContextMenuItems = ContextMenuItems
	for objectId, data in pairs( ContextMenuItems ) do
		local time = data and data.time or 0
		if ( time < now ) then
			ContextMenuItems[ objectId ] = nil
		end
	end
	CleanContextMenuDelta = now + 60
end


function ClfUtil.requestContextMenuItemData( objectId, callback )
	if ( not objectId or objectId == 0 ) then
		return
	end

	callback = ( type( callback ) == "function" ) and callback or nil

	local ret
	local now = ClfCommon.TimeSinceLogin
	local cache = ContextMenuItems[ objectId ]
	if ( cache ) then
		if ( cache.time >= now and cache.menuItems ) then
			ret = cache.menuItems
		else
			ContextMenuItems[ objectId ] = nil
		end
	end

	if ( not ret ) then
		if ( WindowData.ContextMenu ) then
			WindowData.ContextMenu.objectId = nil
			WindowData.ContextMenu.menuItems = nil
			WindowData.ContextMenu.hideMenu = 1
		end

		-- // MEMO: RequestContextMenu は activeWindowが無い時に呼び出すと（動作はするが）エラーが出る
		-- RequestContextMenu( objectId, false )
		Interface.org_RequestContextMenu( objectId )
		if ( DoesWindowExist( "ContextMenu" ) ) then
			WindowSetOffsetFromParent("ContextMenu", -9999, -9999 )
			WindowSetShowing( "ContextMenu", false )
		end

		local menuItems = ClfUtil._getContextItems( objectId )
		if ( not menuItems or next( menuItems ) == nil ) then
			ClfCommon.addCheckListener( "ContextMenuItemCheck" .. objectId, {
					check  = function()
						local WD_ContextMenu = WindowData.ContextMenu
						if ( WD_ContextMenu and WD_ContextMenu.menuItems and #WD_ContextMenu.menuItems ~= 0 ) then
							local menuItems = ClfUtil._getContextItems( objectId )
							return ( menuItems and #menuItems > 0 )
						end
						return false
					end,
					done = function()
						if ( callback ) then
							callback( ClfUtil._getContextItems( objectId ), objectId )
						end
					end,
					fail = function()
						if ( callback ) then
							callback( false, objectId )
						end
					end,
					limit  = ClfCommon.TimeSinceLogin + 1,
					remove = true,
				} )
		else
			ret = menuItems
		end
	end

	if ( ret and callback ) then
		callback( ret, objectId )
	end

	CleanContextMenuItems()
	return ret
end



function ClfUtil._getContextItems( objectId )
	local cache = ContextMenuItems[ objectId ]
	local now = ClfCommon.TimeSinceLogin
	if ( cache ) then
		if ( cache.time >= now and cache.menuItems ) then
			return cache.menuItems
		else
			ContextMenuItems[ objectId ] = nil
		end
	end
	local data = WindowData.ContextMenu or {}
	local ret
	local menuItems = data.menuItems
	if ( menuItems and data.objectId == objectId and  #menuItems > 0 ) then
		if ( menuItems[1].returnCode or menuItems[1].tid ) then
			ret = ClfUtil.mergeTable( {}, menuItems )
		end
		ContextMenuItems[ objectId ] = {
			menuItems = ret,
			time = now + 30,
		}

		ContextMenu.Hide()
	end
	return ret
end



-- EOF

