<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfDamageMod" version="1.1.1" date="04/30/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Dependencies>
			<Dependency name="ClfCommon" />
		</Dependencies>
		<Files>
			<File name="ClfDamageWindow.lua" />
			<File name="ClfDamageMod.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfDamageMod.initialize" />
		</OnInitialize>


		<OnShutdown>
			<CallFunction name="ClfDamageMod.shutdown" />
		</OnShutdown>

	</UiMod>
</ModuleFile>
