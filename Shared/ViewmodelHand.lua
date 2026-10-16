local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local v = false
local v2 = {
	Changed = Signal.new(),
	IsLeftHanded = function()
		return v
	end,
	IsPlayerLeftHanded = function(instance)
		if instance == Players.LocalPlayer then
			return v
		end

		return instance ~= nil and instance:GetAttribute("ViewmodelLeftHanded") == true
	end
}

function v2.SetLeftHanded(flag: boolean)
	if v ~= flag then
		v = flag
		v2.Changed:Fire(flag)
		local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
		Remotes.Player.SetViewmodelHand.Send(flag)
	end
end

function v2.Toggle()
	v2.SetLeftHanded(not v)
end

return table.freeze(v2)