
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfCommon", "ClfIcons.xml", "ClfIcons.xml" )
LoadResources( "./UserInterface/"..SystemData.Settings.Interface.customUiName.."/ClfMods/ClfCommon", "ClfTextures.xml", "ClfTextures.xml" )


ClfCommon = {}


ClfCommon.actionsWindowInitActionData_org = nil

function ClfCommon.initialize()
	ClfUtil.initialize()
	ClfSettings.initialize()
	ClfReActionsWindow.initialize()
	ClfRefactor.initialize()
end


function ClfCommon.onUpdate( timePassed )
	local pcall = pcall
	pcall( ClfActions.onUpdate, timePassed )
	pcall( ClfDamageMod.onUpdate, timePassed )
end

