

ClfSettingWindow = {}



-- You see:設定ウィンドウを表示
function ClfSettingWindow.showYouSeeFilters()
	local win = "ClfYouSeeFiltersWindow"
	if ( DoesWindowExist( win ) ) then
		WindowSetShowing( win, true )
	else
		CreateWindow( win, false )
	end

	WindowUtils.RestoreWindowPosition( win )
end

