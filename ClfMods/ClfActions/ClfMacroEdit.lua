

ClfMacroEdit = {}

ClfMacroEdit.MacroPickerIconRow = 6
ClfMacroEdit.MacroPickerIconColumn = 6

local ICON_SIZE = 50
local ICON_ROW_MAX= 50
local ICON_COL_MAX= 20

ClfMacroEdit.MacroEditIcon_org = nil


function ClfMacroEdit.initialize()
	ClfMacroEdit.addMacroIcons()

	local iconRow = Interface.LoadNumber( "ClfMacroEditIconRow", ClfMacroEdit.MacroPickerIconRow )
	ClfMacroEdit.setIconRow( iconRow )

	local iconCol = Interface.LoadNumber( "ClfMacroEditIconColumn", ClfMacroEdit.MacroPickerIconColumn )
	ClfMacroEdit.setIconColumn( iconCol )

	if ( not ClfMacroEdit.MacroEditIcon_org ) then
		ClfMacroEdit.MacroEditIcon_org = MacroEditWindow.MacroEditIcon
		MacroEditWindow.MacroEditIcon = ClfMacroEdit.onMacroEditIcon
	end
end


-- マクロ編集画面のマクロ用アイコンリストの列数を設定
function ClfMacroEdit.setIconRow( row )
	local DEF_NUM = 4
	local num = row and tonumber( row ) or ClfMacroEdit.MacroPickerIconRow
	num = math.max( DEF_NUM, math.min( math.floor( num ), ICON_ROW_MAX ) )

	MacroPickerWindow.SetNumMacrosPerRow( num )
	ClfMacroEdit.MacroPickerIconRow = num
	Interface.SaveNumber( "ClfMacroEditIconRow", num )
end


-- マクロ編集画面のマクロ用アイコンリストの行数を設定
function ClfMacroEdit.setIconColumn( col )
	local DEF_NUM = 4
	local num = col and tonumber( col ) or ClfMacroEdit.MacroPickerIconColumn
	num = math.max( DEF_NUM, math.min( math.floor( num ), ICON_COL_MAX ) )

	ClfMacroEdit.MacroPickerIconColumn = num
	Interface.SaveNumber( "ClfMacroEditIconColumn", num )
end


function ClfMacroEdit.addMacroIcons()
	-- 追加するアイコンID
	local ICON_IDS = {
		{
			-- マスタリーアイコン
			st      = 01707,	-- 追加するID（開始）
			en      = 01745,	-- 追加するID（終了） 省略可 ※ 開始～終了のIDが連番になっている必要あり
			after   = 01706,	-- このIDの後ろに追加 省略可
		},
	}

	local MacroIcons = MacroPickerWindow.MacroIcons
	local isInArray = ClfUtil.isInArray
	local tInsert = table.insert
	for i = 1, #ICON_IDS do
		local ids = ICON_IDS[ i ]
		if ( not isInArray( ids.st, MacroIcons ) ) then
			local b, index
			if ( ids.after ) then
				b, index = isInArray( ids.after, MacroIcons )
			end
			index = b and index or #MacroIcons
			local id = ids.st
			local endId = ids.en or id
			while ( id <= endId ) do
				index = index + 1
				tInsert( MacroIcons, index, id )
				id = id + 1
			end
		end
	end
end


-- オリジナルの MacroEditWindow.MacroEditIcon をオーバーライドするメソッド
function ClfMacroEdit.onMacroEditIcon()
	local win = "MacroIconPickerWindow"
	if( DoesWindowNameExist( win ) == false ) then
		CreateWindowFromTemplate( win, "MacroPickerWindowTemplate", "Root" )

		local rowNum = ClfMacroEdit.MacroPickerIconRow
		local baseWidth = ICON_SIZE * rowNum
		local colNum = math.min( ClfMacroEdit.MacroPickerIconColumn, math.ceil( #MacroPickerWindow.MacroIcons / rowNum ) )
		local baseHight = ICON_SIZE * colNum

		WindowSetDimensions( win, baseWidth + 18, baseHight + 8 )
		WindowSetDimensions( win .. "View", baseWidth + 10, baseHight )
		WindowSetDimensions( win .. "ViewScrollChild", baseWidth , 0 )

		MacroPickerWindow.DrawMacroTable( win )
	end

	-- オリジナルのメソッドを実行
	ClfMacroEdit.MacroEditIcon_org()
end






