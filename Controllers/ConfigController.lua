local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ConfigKeys = require(ReplicatedStorage.Database.Custom.ConfigKeys)
local isServer = RunService:IsServer()
local isStudio = RunService:IsStudio()
local LocalPlayer = Players.LocalPlayer
local ConfigController = {}
local v = nil

local function getSnapshot()
	if not isServer then
		return nil
	end

	if v then
		return v
	end

	local success, result = pcall(function()
		local ConfigService = game:GetService("ConfigService")
		return ConfigService:GetConfigAsync()
	end)

	if success and result then
		v = result
		result.UpdateAvailable:Connect(function()
			pcall(result.Refresh, result)
		end)
		return v
	else
		return nil
	end
end

function ConfigController.Get(attributeName: string)
	if isStudio and ConfigKeys.Defaults[attributeName] ~= nil then
		return ConfigKeys.Defaults[attributeName]
	end

	if not isServer then
		return LocalPlayer:GetAttribute(attributeName)
	end

	local snapshot = getSnapshot()

	if not snapshot then
		return nil
	end

	local success, value = pcall(snapshot.GetValue, snapshot, attributeName)

	if success then
		return value
	end

	return nil
end

function ConfigController.GetRewardMultiplier(p: string)
	return (math.max(0, tonumber(ConfigController.Get(p)) or ConfigKeys.Defaults[p] or 1))
end

function ConfigController.OnChanged(attributeName: string, callback)
	if not isServer then
		return LocalPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
			callback(LocalPlayer:GetAttribute(attributeName))
		end)
	end

	local snapshot = getSnapshot()

	if not snapshot then
		return nil
	end

	local success, valueChangedSignal = pcall(snapshot.GetValueChangedSignal, snapshot, attributeName)

	if success and valueChangedSignal then
		return valueChangedSignal:Connect(function()
			local success2, value = pcall(snapshot.GetValue, snapshot, attributeName)

			if not success2 then
				value = nil
			end

			callback(value)
		end)
	end

	return nil
end

return ConfigController