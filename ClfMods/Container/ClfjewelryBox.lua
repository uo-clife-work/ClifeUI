
ClfjewelryBox = {}


local JBOX_GUMP_ID = 999143

-- ガンプデータが更新された時に呼び出される
function ClfjewelryBox.gumParse( gumpData )
	if ( not gumpData or not gumpData.Gumps ) then
		return
	end

	local JewelryBoxGump = gumpData.Gumps[ JBOX_GUMP_ID ]
	if ( not JewelryBoxGump ) then
		return
	end

	-- 検索ウィンドウ
	local JewelryBoxWin = JewelryBoxGump.windowName
	if ( DoesWindowExist( JewelryBoxWin ) ~= true ) then
		return
	end

	local searchWin = "ClfJewelryBoxSearch"
	local searchObj = ClfSearchWindow.getInstance( searchWin, {
			title = GetStringFromTid(1157695) .. L" " .. GetStringFromTid(1157694),
			onSearch = ClfjewelryBox.searchJewelryBox,
			onReset  = ClfjewelryBox.resetSearch,
		}, JewelryBoxWin )

	ClfSearchWindow.createWindow( searchWin, JewelryBoxWin )
	WindowClearAnchors( searchWin )
	WindowAddAnchor( searchWin, "bottom", JewelryBoxWin, "bottom", 0, -10 )
	ClfjewelryBox.searchJewelryBox( searchObj )

	if ( ClfContnrWin.Enable ) then
		-- アイテムプロパティ表示
		local found = ClfjewelryBox.dispItemProp()
		if ( found == false ) then
			-- ログイン後最初に開けた時は情報を取得出来ない場合が多いので、少しの間情報取得を試みる
			ClfCommon.addCheckListener( "PropDisp" .. JewelryBoxWin, {
					begin = ClfCommon.TimeSinceLogin + 0.15,
					limit = ClfCommon.TimeSinceLogin + 0.6,
					check = function()
						return ( true == ClfjewelryBox.dispItemProp() )
					end,
					done = function()
						ClfjewelryBox.searchJewelryBox( searchObj )
					end,
				} )
		else
			-- キャッシュにより一部だけ取得出来ている場合もあるので、一度だけ再実行してみる
			ClfCommon.setTimeout( "PropDisp" .. JewelryBoxWin, {
					timeout = ClfCommon.TimeSinceLogin + 0.2,
					done = function()
						ClfjewelryBox.dispItemProp()
						ClfjewelryBox.searchJewelryBox( searchObj )
					end,
				} )
		end
	end
end


function ClfjewelryBox.dispItemProp()
	if ( not ClfContnrWin.Enable ) then
		return nil
	end
	local itemProps, windows = ClfGGMod.getItemPropsInGump( JBOX_GUMP_ID )

	if ( windows ) then
		local colorTbl = ClfContnrWin.TxtColorsLight
		local defColor = DefaultTxtColorLight

		local DoesWindowExist = DoesWindowExist
		local CreateWindowFromTemplateShow = CreateWindowFromTemplateShow
		local WindowSetShowing = WindowSetShowing
		local LabelSetText = LabelSetText
		local LabelSetTextColor = LabelSetTextColor
		local ClfContnrWin_getInterestPropObj = ClfContnrWin.getInterestPropObj

		local found = false
		for id, win in pairs( windows ) do
			if ( not DoesWindowExist( win ) ) then
				continue
			end
			local newWin = "ClfJewelryBoxProp" .. id
			local propObj = ClfContnrWin_getInterestPropObj( id, nil, true )

			if ( propObj and propObj.text ) then
				if ( not DoesWindowExist( newWin ) ) then
					CreateWindowFromTemplateShow( newWin, "ClfJewelryBoxProp", win, false )
				end
				local label = newWin .. "Label"
				LabelSetText( label, propObj.text )

				local color = propObj.color and colorTbl[ propObj.color ] or defColor
				if ( color ) then
					LabelSetTextColor( label, color.r, color.g, color.b)
				end

				WindowSetShowing( newWin, true )
				found = true
			end
		end

		return found
	end
	return false
end



ClfjewelryBox.FilterItemsBg = {}

function ClfjewelryBox.searchJewelryBox( searchObj )

	local query = searchObj and searchObj.query
	local queryLen = query and #query or 0

	if ( queryLen > 0 ) then
		local itemProps, windows = ClfGGMod.getItemPropsInGump( JBOX_GUMP_ID )

		local DoesWindowExist = DoesWindowExist
		local CreateWindowFromTemplate = CreateWindowFromTemplate
		local WindowSetShowing = WindowSetShowing

		local wGsub = wstring.gsub
		local wFind = wstring.find
		local ClfUtil_tableElemn = ClfUtil.tableElemn

		ClfjewelryBox.removeSearchItemBg()

		local JewelryBoxFilterItemBg = ClfjewelryBox.FilterItemsBg

		for id, win in pairs( windows ) do
			local propData = itemProps[ id ]
			local prop = propData and propData.PropertiesList
			if ( not prop or not DoesWindowExist( win ) ) then
				continue
			end

			local founds = {}
			local isMatch = false
			for i = 1, #prop do
				local str = prop[ i ]
				for k = 1, queryLen do
					if ( wFind( str, query[ k ], 1, true ) ) then
						-- フィルターワードがプロパティ文字列中にあった。フィルターワードのインデックスをキーにしてfoundsに追加
						founds[ k ] = str
					end
				end
				if ( ClfUtil_tableElemn( founds ) == queryLen ) then
					-- foundsの配列長がフィルターワードの数と同じになった。OK
					isMatch = true
					break
				end
			end

			if ( isMatch ) then
				local itemBg = win .. "ClfItemBG"
				if ( not DoesWindowExist( itemBg ) ) then
					JewelryBoxFilterItemBg[ #JewelryBoxFilterItemBg + 1 ] = itemBg
					CreateWindowFromTemplate( itemBg, "ClfJBoxFilterItemBG", win )
				end
			end
		end

	end
end


function ClfjewelryBox.resetSearch( searchObj )
	ClfjewelryBox.removeSearchItemBg()
end


function ClfjewelryBox.removeSearchItemBg()
	local JewelryBoxFilterItemBg = ClfjewelryBox.FilterItemsBg
	if ( not JewelryBoxFilterItemBg ) then
		return
	end
	for i = 1, #JewelryBoxFilterItemBg do
		local win = JewelryBoxFilterItemBg[ i ]
		if ( DoesWindowExist( win ) ) then
			DestroyWindow( win )
		end
	end
	JewelryBoxFilterItemBg = {}
end


-- EOF
