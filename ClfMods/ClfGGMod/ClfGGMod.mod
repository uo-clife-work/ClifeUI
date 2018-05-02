<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfGGMod" version="1.0" date="05/02/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Dependencies>
			<Dependency name="ClfCommon" />
		</Dependencies>

		<Files>
			<File name="ClfGGMod.lua" />
			<File name="ClfALGump.lua" />
			<File name="ClfALGumpWindow.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfGGMod.initialize" />
			<CallFunction name="ClfALGump.initialize" />
		</OnInitialize>

	</UiMod>
</ModuleFile>
