
ClfUtil = {}


-- UI初期化時のタイムスタンプ：未使用
ClfUtil.InitialTimeStamp = 0
-- UIを初期化してからの経過時間：未使用
--ClfUtil.TimePassed = 0

ClfUtil.HOUR_IN_SECONDS = 60 * 60
ClfUtil.DAY_IN_SECONDS = ClfUtil.HOUR_IN_SECONDS * 24
ClfUtil.GAP_JST = ClfUtil.HOUR_IN_SECONDS * 9

ClfUtil.LOG_EXPORT_DIR = "clfExport/"


function ClfUtil.initialize()
	ClfUtil.InitialTimeStamp = GetCurrentDateTime()
end

function ClfUtil.onUpdate( timePassed )
	pcall( ClfActions.onUpdate, timePassed )
	pcall( ClfDamageMod.onUpdate, timePassed )
end


-- テーブルのマージ：連想配列用
function ClfUtil.mergeTable( t1, t2 )
	local type = type
	local pairs = pairs
	local merge = ClfUtil.mergeTable

	if ( type( t2 ) == "table" ) then
		for k, v in pairs( t2 ) do
			if ( type( v ) == "table"  ) then
				local v1 = t1[ k ]
				if ( type( v1 ) ~= "table" ) then
					v1 = {}
				else
					v1 = merge( {}, v1 )
				end
				v = merge( v1, v )
			end
			t1[ k ] = v
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

	for i = 1, #t do
		if ( val == t[ i ] ) then
			ret = true
			break
		end
	end

	return ret
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
	local numFunc

	if ( numStrToNum ) then
		numFunc = function( s )
			num = tonumber( s )
			if ( num and wstring.match( s, L"^[.]?%d+[.]?%d*$" ) ) then
				-- ここの判定が適当なので、そのうち修正・・・
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
	local tonumber = tonumber
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
	local tonumber = tonumber
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
	sv.s = ( iMax - iMin ) / iMax
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

