<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfCommon" version="1.1" date="07/19/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Files>
			<File name="ClfSettings.lua" />
			<File name="ClfUtility.lua" />
			<File name="ClfRefactor.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfUtil.initialize"/>
		</OnInitialize>

		<OnUpdate>
			<CallFunction name="ClfUtil.onUpdate"/>
		</OnUpdate>

	</UiMod>
</ModuleFile>
