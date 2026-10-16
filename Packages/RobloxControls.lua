local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Promise = require(script.Parent.Promise)
local bindableEvent = Instance.new("BindableEvent")
local v = { nil }
v[1] = Enum.CoreGuiType.All
local v2 = { Public = {}, Private = {} }

function v2.Private.OnRespawnCharacterRequested()
	local character = Players.LocalPlayer.Character

	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	humanoid.Health = 0
end

function v2.Public:SetCoreAsync(...)
	local v3 = { ... }
	return Promise.new(function(callback)
		local success = nil

		while not success do
			local result
			success, result = pcall(StarterGui.SetCore, StarterGui, table.unpack(v3))

			if not success then
				warn(result)
			end

			task.wait(0.5)
		end

		return callback()
	end)
end

function v2.Public.GetCoreAsync(_, ...)
	local v3 = { ... }
	return Promise.new(function(callback)
		local success = nil
		local result = nil

		while not success do
			success, result = pcall(StarterGui.SetCore, StarterGui, table.unpack(v3))

			if not success then
				warn(result)
			end

			task.wait(0.5)
		end

		return callback(result)
	end)
end

function v2.Public.SetRespawnCallback(_, onRespawnCharacterRequested)
	v2.Private.OnRespawnCharacterRequested = onRespawnCharacterRequested
end

function v2.Public:DisableRespawning()
	self:SetCoreAsync("ResetButtonCallback", false)
end

function v2.Public:EnableRespawning()
	self:SetCoreAsync("ResetButtonCallback", bindableEvent)
end

local function SetDefaultCoreGui(_, ...)
	v = { ... }
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

	for _, v3 in v do
		StarterGui:SetCoreGuiEnabled(v3, true)
	end
end

v2.Public.SetDefaultCoreGui = SetDefaultCoreGui

local function EnableCoreGui(_)
	for _, v3 in v do
		StarterGui:SetCoreGuiEnabled(v3, true)
	end
end

v2.Public.EnableCoreGui = EnableCoreGui

local function DisableCoreGui(_)
	for _, v3 in v do
		StarterGui:SetCoreGuiEnabled(v3, false)
	end
end

v2.Public.DisableCoreGui = DisableCoreGui

function v2.Public.DisableCharacterInput(_)
	ContextActionService:BindAction("RobloxControls-FreezeAction", function()
		return Enum.ContextActionResult.Sink
	end, false, table.unpack(Enum.PlayerActions:GetEnumItems()))
end

function v2.Public.EnableCharacterInput(_)
	ContextActionService:UnbindAction("RobloxControls-FreezeAction")
end

v2.Public:DisableRespawning()
bindableEvent.Event:Connect(function()
	v2.Private.OnRespawnCharacterRequested()
end)
return v2.Public