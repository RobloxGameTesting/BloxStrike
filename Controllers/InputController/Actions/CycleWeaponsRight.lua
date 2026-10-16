local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActionTemplates = require(script.Parent.Parent.ActionTemplates)
local EquipSlotRight = require(ReplicatedStorage.Components.Common.UserInput.EquipSlotRight)
return ActionTemplates.cycleWeapons("Cycle Weapons Right", EquipSlotRight)