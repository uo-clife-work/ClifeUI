<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfCommon" version="1.2" date="07/26/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Files>
			<File name="ClfCommon.lua" />
			<File name="ClfTexts.lua" />
			<File name="ClfSettings.lua" />
			<File name="ClfUtility.lua" />
			<File name="ClfRefActionsWindow.lua" />
			<File name="ClfRefactor.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfCommon.initialize"/>
		</OnInitialize>

		<OnUpdate>
			<CallFunction name="ClfCommon.onUpdate"/>
		</OnUpdate>

	</UiMod>
</ModuleFile>
