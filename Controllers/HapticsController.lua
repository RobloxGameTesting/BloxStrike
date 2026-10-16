local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HapticService = game:GetService("HapticService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local v = {}
local connection = nil

local function IsVibrationsEnabled() -- 1 equivalent call inferred from this helper
	local v2 = UserInputService:GetLastInputType() == Enum.UserInputType.Touch and "Mobile" or "Controller"
	local v3 = DataController.Get(LocalPlayer, "Settings.Game.Other." .. v2 .. " Haptics/Vibrations")
	return v3 ~= nil and v3 ~= false
end

local function updateQueue(p: number)
	for k, v2 in pairs(v) do
		v2.Length -= p

		if HapticService:IsMotorSupported(v2.InputMotor, k) then
			HapticService:SetMotor(v2.InputMotor, k, v2.Intensity)
		end

		if not (v2.Length <= 0) then
			continue
		end

		HapticService:SetMotor(v2.InputMotor, k, 0)
		v[k] = nil
	end

	if next(v) == nil and connection then
		connection:Disconnect()
		connection = nil
	end
end

return {
	vibrate = function(p, intensity: number, length: number)
		if not IsVibrationsEnabled() then -- inferred equivalent call
			return
		end

		local gamepad1 = Enum.UserInputType.Gamepad1
		local v2 = v[p]

		if v2 then
			v2.InputMotor = gamepad1

			if v2.Length < length then
				v2.Length = length
			end

			if v2.Intensity < intensity then
				v2.Intensity = intensity
			end
		else
			v[p] = { InputMotor = gamepad1, Intensity = intensity, Length = length }
		end

		if not connection then
			connection = RunServiceController.BindToRenderStep("HapticsController.UpdateQueue", updateQueue)
		end
	end
}