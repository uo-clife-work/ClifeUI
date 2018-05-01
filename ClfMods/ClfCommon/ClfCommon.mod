<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfCommon" version="1.0" date="04/30/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Files>
			<File name="ClfUtility.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfUtil.initialize"/>
		</OnInitialize>

		<OnUpdate>
			<CallFunction name="ClfUtil.onUpdate"/>
		</OnUpdate>

	</UiMod>
</ModuleFile>
