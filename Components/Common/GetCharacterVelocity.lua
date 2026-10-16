local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)

local function GetCharacterVelocity(instance)
	local humanoidRootPart = instance and instance:FindFirstChild("HumanoidRootPart")
	return RuntimeKinematics.getVelocity(instance, humanoidRootPart)
end

return GetCharacterVelocity