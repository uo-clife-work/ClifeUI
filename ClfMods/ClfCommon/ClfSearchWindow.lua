

LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfCommon", "ClfSearchWindow.xml", "ClfSearchWindow.xml" )


ClfSearchWindow = {}


local DEFAULT_PARAM = {
--	window        = "",	-- インスタンス生成時に指定した windowName を保持する
	title         = GetStringFromTid(1156592),	-- 「フィルター」
	isSingleQuery = false,	-- truwを指定すると検索文字を最後に入力した文字だけにする（通常は入力するごとに検索条件を追加する）
	clearOnEnter  = true,	-- 検索開始時に文字入力フィールドを空にする
	focusOnInit   = true,	-- ウィンドウ作成時に入力フィールドのフォーカスを外したい時はfalse
	query         = {},		-- 検索文字を保持する配列。通常はカラのテーブルを指定
	onSearch      = false,	-- 検索開始時：以下、関数を設定するときに、関数への参照を指定する
	onReset       = false,	-- 検索文字リセット時
	onChange      = false,	-- 文字入力フィールドの文字が変更された時
	onInitialize  = false,	-- 検索ウィンドウが生成された時
	onShutdown    = false,	-- 検索ウィンドウが閉じた時
}


ClfSearchWindow.Instances = {}




--[[
* ウィンドウ名を指定して、検索テキスト入力ウィンドウのインタンス（windowNameに基づいたウィンドウ用の各データを保持したテーブル）を得る
* @param  {wstring} [windowName]
* @param  {table} [descHealth = nil]  オプション
*                  第3引数 parent と同時に指定すると、既存のインスタンスが無い場合は、新規にインスタンスを生成する
*                  ※ テーブルの値は DEFAULT_PARAM に params をマージして使用される。
* @param  {wstring} [parent    = nil]    オプション
*                  第2引数 params と同時に指定するとインスタンスが無い場合は、新規にインスタンスを生成する
* @return {table|nil}   検索テキスト入力ウィンドウ用データ
]]--
function ClfSearchWindow.getInstance( windowName, params, parent, showing )
	if ( not windowName ) then
		return
	end
	if ( ClfSearchWindow.Instances[ windowName ] ~= nil ) then
		return ClfSearchWindow.Instances[ windowName ]
	end
	if ( parent and params ) then
		return ClfSearchWindow.setInstance( windowName, params, parent, showing )
	end
end


function ClfSearchWindow.setInstance( windowName, params, parent, showing )
	local type = type
	if ( type( windowName ) ~= "string" or windowName == "" ) then
		return
	end

	if ( ClfSearchWindow.Instances[ windowName ] ~= nil ) then
		-- return Defined instance
		return ClfSearchWindow.Instances[ windowName ]
	end

	if ( not params ) then
		return
	end

	-- Define New instance
	local instance = ClfUtil.mergeTable( {}, DEFAULT_PARAM, params )
	instance.window = windowName

	local find = string.find

	-- パラメータ中の on*** が関数ではない場合はnilにする
	for k, v in pairs( instance ) do
		if ( type( k ) == "string" and find( k, "^on[A-Z][a-zA-Z]+$" ) ) then
			if ( type( v ) ~= "function" ) then
				instance[ k ] = nil
			end
		end
	end

	ClfSearchWindow.Instances[ windowName ] = instance

	ClfSearchWindow.createWindow( windowName, parent, showing )

	return ClfSearchWindow.Instances[ windowName ]
end


-- getInstance, setInstance ともに、新規インスタンス生成時のみウィンドウの作成・表示を行うので、
-- 既存インスタンスのウィンドウを表示したい時にこのメソッドを実行する
function ClfSearchWindow.createWindow( windowName, parent, showing )
	local instance = ClfSearchWindow.getInstance( windowName )
	if ( not instance ) then
		return
	end
	if ( not parent or not DoesWindowExist( parent ) ) then
		return
	end

	showing = ( showing == nil ) or showing and true or false

	if ( not DoesWindowExist( windowName ) ) then
		CreateWindowFromTemplateShow( windowName, "ClfSearchWindow", parent, showing )
	else
		local shown = WindowGetShowing( windowName )
		if ( shown ~= showing ) then
			if ( showing ) then
				ClfSearchWindow.setPartsCondition( windowName, instance )
			end
			WindowSetShowing( windowName, showing )
		end
	end
end


function ClfSearchWindow.destroy( windowName )
	local instance = ClfSearchWindow.getInstance( windowName )
	if ( instance ) then
		ClfSearchWindow.Instances[ windowName ] = nil
	end

	if ( DoesWindowExist( windowName ) ) then
		DestroyWindow( windowName )
	end
end


function ClfSearchWindow.initialize()
	local win = SystemData.ActiveWindow.name

	local instance = ClfSearchWindow.getInstance( win )
	if ( not instance ) then
		return
	end
	if ( not instance.focusOnInit ) then
		WindowAssignFocus( win .. "Input", false )
	end

	ClfSearchWindow.setPartsCondition( win, instance )

	if ( instance.onInitialize ) then
		instance.onInitialize( instance )
	end
end


function ClfSearchWindow.shutdown()
	local win = SystemData.ActiveWindow.name

	local instance = ClfSearchWindow.getInstance( win )
	if ( not instance or not instance.onShutdown ) then
		return
	end

	instance.onShutdown( instance )
end


function ClfSearchWindow.onInputChanged()
	local win = WindowGetParent( SystemData.ActiveWindow.name )
--	Debug.DumpToConsole( "SearchWindow.onInputChanged", win )

	local instance = ClfSearchWindow.getInstance( win )
	if ( not instance or not instance.onChange ) then
		return
	end

	instance.onChange( instance )
end


function ClfSearchWindow.searchStart()
	local win = WindowGetParent( SystemData.ActiveWindow.name )

	local instance = ClfSearchWindow.getInstance( win )
	if ( not instance ) then
		return
	end
--	Debug.DumpToConsole( "SearchWindow.searchStart", win )

	local editBox = win .. "Input"

	local text = TextEditBoxGetText( editBox )

	if ( text and text ~= L"" and text ~= "" ) then
		if ( instance.isSingleQuery ) then
			instance.query = { text }
		else
			if ( not instance.query ) then
				instance.query = {}
			end
			local query = instance.query

			local strings = ClfUtil.explode( L"|", text )
			for i = 1, #strings do
				local txt = strings[ i ]
				if ( not ClfUtil.isInArray( txt, query ) ) then
					query[ #query + 1 ] = txt
				end
			end
		end
	end

	ClfSearchWindow.setPartsCondition( win, instance )

	if ( instance.onSearch ) then
		instance.onSearch( instance )
	end

	if ( instance.clearOnEnter ) then
		TextEditBoxSetText( editBox, L"" )
	end

end


function ClfSearchWindow.getQueries( windowName )
	local instance = ClfSearchWindow.getInstance( windowName )
	if ( instance and instance.query ) then
		return instance.query
	end
end


function ClfSearchWindow.setPartsCondition( windowName, instance )
	windowName = windowName or instance and instance.window
	if ( not windowName or not DoesWindowExist( windowName ) ) then
		return
	end

	instance = instance or ClfSearchWindow.getInstance( windowName )
	if ( not instance ) then
		return
	end
	local label = windowName .. "Title"
	local qStr = ClfSearchWindow.getQueryString( windowName )
	str = qStr or instance.title or L""

--	Debug.DumpToConsole( "setPartsCondition", str )

	LabelSetText( label, str )

	local removeBtnShowing = qStr and true or false
	WindowSetShowing( windowName .. "CancelButton", removeBtnShowing )
end


function ClfSearchWindow.getQueryString( windowName, sep, prefix, suffix )
--	local instance = ClfSearchWindow.getInstance( windowName )
--	if ( not instance ) then
--		return
--	end
	local str
	local query = ClfSearchWindow.getQueries( windowName )

	if ( query and #query ~= 0 ) then
		sep = ( type( sep ) == "wstring" ) and sep or L", "
		prefix = ( type( prefix ) == "wstring" ) and prefix or L""
		suffix = ( type( suffix ) == "wstring" ) and suffix or L""
		str = L""
		local len = #query
		for i = 1, len do
			str =  str .. prefix .. query[ i ] .. suffix
			if ( i < len ) then
				str = str .. sep
			end
		end
	end
	return str
end


function ClfSearchWindow.searchReset()
	local win = WindowGetParent( SystemData.ActiveWindow.name )
	local instance = ClfSearchWindow.getInstance( win )
	if ( not instance ) then
		return
	end
	instance.query = {}
	ClfSearchWindow.setPartsCondition( win, instance )
	if ( instance.onReset ) then
		instance.onReset( instance )
	end
end


function ClfSearchWindow.searchTooltip()
	local Tooltips = Tooltips
	Tooltips.CreateTextOnlyTooltip( SystemData.ActiveWindow.name,  GetStringFromTid(1154641) ) -- search
	Tooltips.Finalize()
	Tooltips.AnchorTooltip( Tooltips.ANCHOR_WINDOW_TOP )
end


function ClfSearchWindow.removeFiltersTooltip()

	local win = WindowGetParent( SystemData.ActiveWindow.name )
	local qStr = ClfSearchWindow.getQueryString( win, L"\n", L"\"", L"\"" )

	local str = GetStringFromTid(1154792) -- Remove Filters
	if ( qStr ) then
		str =  str .. L":\n" .. qStr
	end

	local Tooltips = Tooltips
	Tooltips.CreateTextOnlyTooltip( SystemData.ActiveWindow.name, str )
	Tooltips.Finalize()
	Tooltips.AnchorTooltip( Tooltips.ANCHOR_WINDOW_TOP )
end
