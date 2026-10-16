local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataController = require(ReplicatedStorage.Controllers.DataController)

local function isEquipped(p, p2: string)
	if not p then
		return false
	end

	for _, v in p.Loadout or {} do
		if v and v.Options and table.find(v.Options, p2) then
			return true
		end
	end

	for _, v in p.Equipped or {} do
		if v == p2 then
			return true
		end
	end

	return false
end

local ItemEquipment = {}

function ItemEquipment.IsEquippedOnTeam(p: string, p2: string)
	local loadout = DataController.Get(Players.LocalPlayer, "Loadout")
	return (isEquipped(loadout and loadout[p2], p))
end

function ItemEquipment.UpdateStatusFrame(instance, p: string)
	local status = instance:FindFirstChild("Status")

	if not status then
		return
	end

	local counterTerrorists = status:FindFirstChild("Counter-Terrorists")
	local terrorists = status:FindFirstChild("Terrorists")

	if counterTerrorists and terrorists then
		local loadout = DataController.Get(Players.LocalPlayer, "Loadout")
		counterTerrorists.Visible = isEquipped(loadout and loadout["Counter-Terrorists"], p)
		terrorists.Visible = isEquipped(loadout and loadout.Terrorists, p)
	end
end

return ItemEquipment