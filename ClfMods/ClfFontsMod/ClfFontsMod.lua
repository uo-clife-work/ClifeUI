ClfFonts = {}

-- OverHead Text に追加するフォント
ClfFonts.OverHeadFonts = {
	-- Name to be shown, Name of font
	{ "UoClassic",   "Classic_20" },
	{ "Arial Black", "Arial_Black_Shadow_18" },
	{ "Mgen", "MgenPlus_Shadow_18" },
	{ "GenKaku", "MyriadPro_Shadow_18" },
}

-- チャットログ画面に追加するフォント
ClfFonts.ChatFonts = {
	-- Name to be shown, Name of font
	{ "GenKaku - x-small", "MyriadPro_12" },
	{ "GenKaku - small",   "MyriadPro_15" },
	{ "GenKaku - Medium",  "MyriadPro_18" },

	{ "UoClassic - x-small",   "Classic_std_14" },
	{ "UoClassic - small",   "Classic_std_17" },
	{ "UoClassic - Medium",   "Classic_std_20" },
}


function ClfFonts.initialize()
	if ( FontSelector and FontSelector.Fonts and ClfFonts.OverHeadFonts ) then
		FontSelector.Fonts = ClfFonts.getFontsList( FontSelector.Fonts, ClfFonts.OverHeadFonts ) or FontSelector.Fonts
	end

	if ( ChatSettings and ChatSettings.Fonts and ClfFonts.ChatFonts ) then
		ChatSettings.Fonts = ClfFonts.getFontsList( ChatSettings.Fonts, ClfFonts.ChatFonts ) or ChatSettings.Fonts
	end
end


function ClfFonts.getFontsList( tblOrg, tblAdd )
	local ret = nil
	if ( 'table' == type( tblOrg ) and 'table' == type( tblAdd ) and #tblAdd > 0 ) then
		-- 日本語環境だと ChatSettings.Fonts が歯抜けの配列なので、インデックスを振り直す
		ret = {}
		for k, v in pairs( tblOrg ) do
			ret[ #ret + 1 ] = v
		end
		for i = 1, #tblAdd do
			local font = tblAdd[ i ]
			if ( "table" == type( font ) and #font > 1 ) then
				ret[ #ret + 1 ] = {
					fontName = font[2],
					id = 1,
					isDefault = false,
					shownName = font[1],
				}
			end
		end
	end

	return ret
end
