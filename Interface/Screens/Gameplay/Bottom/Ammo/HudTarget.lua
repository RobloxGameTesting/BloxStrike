local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local LocalPlayer = Players.LocalPlayer

local function currentTarget() -- 2 equivalent calls inferred from this helper
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

	if currentSpectateInstance then
		return currentSpectateInstance.Player
	end

	return LocalPlayer
end

local HudTarget = {}

function HudTarget:DisableInput()
	self.Active = false

	for _, guiObject in ipairs(self:GetDescendants()) do
		if guiObject:IsA("GuiObject") then
			guiObject.Active = false
		end
	end
end

function HudTarget.Follow(callback)
	LocalPlayer.CharacterAdded:Connect(function()
		callback(currentTarget()) -- inferred equivalent call
	end)
	SpectateController.ListenToSpectate:Connect(function(p)
		if p then
			callback(p)
		elseif not LocalPlayer:GetAttribute("IsSpectating") then
			callback(LocalPlayer)
		end
	end)
	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(function()
		if not LocalPlayer:GetAttribute("IsSpectating") then
			callback(LocalPlayer)
			return
		end

		local player = SpectateController.GetPlayer()

		if player then
			callback(player)
		end
	end)

	if LocalPlayer:GetAttribute("IsSpectating") then
		local player = SpectateController.GetPlayer()

		if player then
			callback(player)
		end
	else
		callback(LocalPlayer)
	end

	GameState.ListenToState(function(_, p)
		if p == "Buy Period" or p == "Round In Progress" then
			callback(currentTarget()) -- inferred equivalent call
		end
	end)
end

return HudTarget