local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionTemplates = require(script.Parent.Parent.ActionTemplates)
local EquipSlotLeft = require(ReplicatedStorage.Components.Common.UserInput.EquipSlotLeft)
return ActionTemplates.cycleWeapons("Cycle Weapons Left", EquipSlotLeft)