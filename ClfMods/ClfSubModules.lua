
LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/Map", "ClfCourseMap.xml", "ClfCourseMap.xml" )
LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/Map", "ClfMapWindow.xml", "ClfMapWindow.xml" )


ClfSubModules = {}

ClfSubModules.Initialized = false


function ClfSubModules.initialize()
	local pcall = pcall
	local errorTracker = Interface.ErrorTracker

	ok, err = pcall( ClfCourseMap.initialize )
	errorTracker( ok, err )

	ok, err = pcall( ClfMapCommon.initialize )
	errorTracker( ok, err )

	Debug.PrintToChat( L"ClfSubModules : initialized" )
	ClfSubModules.Initialized = true
end


