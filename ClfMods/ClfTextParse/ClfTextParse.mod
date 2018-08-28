<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfTextParse" version="1.1" date="08/27/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Dependencies>
			<Dependency name="ClfCommon" />
		</Dependencies>

		<Files>
			<File name="ClfTextParse.lua" />
			<File name="ClfYouSee.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfTextParse.initialize" />
		</OnInitialize>

	</UiMod>
</ModuleFile>
