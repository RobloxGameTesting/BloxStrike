local ActionTemplates = require(script.Parent.Parent.ActionTemplates)
return ActionTemplates.useEquipped("Reload", "Reload", function(object)
	object:reload()
end)