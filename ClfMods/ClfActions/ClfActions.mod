<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfActions" version="1.0.2" date="07/08/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Dependencies>
			<Dependency name="ClfCommon" />
		</Dependencies>

		<Files>
			<File name="ClfActions.lua" />
			<File name="ClfMacroEdit.lua" />
			<File name="ClfObjHueWindow.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfActions.initialize" />
			<CallFunction name="ClfMacroEdit.initialize" />
		</OnInitialize>

	</UiMod>
</ModuleFile>
