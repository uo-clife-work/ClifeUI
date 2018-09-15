<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	<UiMod name="ClfContainerMod" version="1.0" date="09/14/2018">

		<Author name="uo.clife.work" />
		<Description text="https://uo.clife.work/uosa-custom-ui-clifeui/" />

		<Dependencies>
			<Dependency name="ClfCommon" />
		</Dependencies>

		<Files>
			<File name="ClfContainerModData.lua" />
			<File name="ClfContainerMod.lua" />
			<File name="ClfContainerSearch.lua" />
			<File name="ClfjewelryBox.lua" />
		</Files>

		<OnInitialize>
			<CallFunction name="ClfContnrWin.initialize" />
		</OnInitialize>

		<SavedVariables>
			<SavedVariable name="ClfContnrWin.LastInitTime" />
			<SavedVariable name="ClfContnrWin.TxtColorsLight" />
			<SavedVariable name="ClfContnrWin.TxtColorsDark" />
			<SavedVariable name="ClfContnrWin.HueTbl" />
			<SavedVariable name="ClfContnrWin.UniqueCondTable" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.Acce" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.Armor" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.OneHand" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.TwoHand" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.Shield" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.Equip" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.Talis" />
			<SavedVariable name="ClfContnrWin.DisplayCondTable.Other" />
			<SavedVariable name="ClfContnrWin.RelationTable" />
		</SavedVariables>

	</UiMod>
</ModuleFile>
