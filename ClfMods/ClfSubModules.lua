
LoadResources( "./UserInterface/" .. SystemData.Settings.Interface.customUiName .. "/ClfMods/ClfCourseMap", "ClfCourseMap.xml", "ClfCourseMap.xml" )



ClfSubModules = {}

ClfSubModules.Initialized = false


function ClfSubModules.initialize()
	local pcall = pcall
	local errorTracker = Interface.ErrorTracker

	ok, err = pcall( ClfCourseMap.initialize )
	errorTracker( ok, err )

	Debug.PrintToChat( L"ClfSubModules : initialized" )
	ClfSubModules.Initialized = true
end


