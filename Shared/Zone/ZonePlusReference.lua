local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZonePlusReference = {}

function ZonePlusReference.addToReplicatedStorage()
	if ReplicatedStorage:FindFirstChild(script.Name) then
		return false
	end

	local objectValue = Instance.new("ObjectValue")
	objectValue.Name = script.Name
	objectValue.Value = script.Parent
	objectValue.Parent = ReplicatedStorage
	local boolValue = Instance.new("BoolValue")
	local RunService = game:GetService("RunService")
	boolValue.Name = RunService:IsClient() and "Client" or "Server"
	boolValue.Value = true
	boolValue.Parent = objectValue
	return objectValue
end

function ZonePlusReference.getObject()
	local child = ReplicatedStorage:FindFirstChild(script.Name)
	return child or false
end

return ZonePlusReference