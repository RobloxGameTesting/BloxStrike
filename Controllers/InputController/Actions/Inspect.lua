local ActionTemplates = require(script.Parent.Parent.ActionTemplates)
return ActionTemplates.useEquipped("Inspect", "Inspect", function(object)
	object:inspect()
end)