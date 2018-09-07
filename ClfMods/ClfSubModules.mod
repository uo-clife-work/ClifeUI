<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfSubModules" version="1.0" date="09/06/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Dependencies>
			<Dependency name="ClfCommon" />
		</Dependencies>

		<Files>
			<File name="ClfCourseMap/ClfCourseMap.lua" />
			<File name="ClfSubModules.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfSubModules.initialize" />
		</OnInitialize>

	</UiMod>
</ModuleFile>
