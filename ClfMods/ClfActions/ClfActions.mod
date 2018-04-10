<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfActions" version="1.0.1" date="04/10/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/about-my-ui_mods-and-macros/" />

		<Files>
			<File name="ClfActions.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfActions.initialize" />
		</OnInitialize>

		<OnUpdate>
			<CallFunction name="ClfActions.onUpdate"/>
		</OnUpdate>

	</UiMod>
</ModuleFile>
