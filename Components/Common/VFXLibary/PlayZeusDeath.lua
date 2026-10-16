local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local other = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Other")

local function resolveVictimRagdoll(p: number)
	local playerByUserId = Players:GetPlayerByUserId(p)

	if not playerByUserId then
		return nil
	end

	local v = -1e999
	local v2 = nil

	for _, model in CollectionService:GetTagged("Ragdoll") do
		if not (model:IsA("Model") and model.Name == playerByUserId.Name and model:IsDescendantOf(workspace)) then
			continue
		end

		local ragdollCreatedAt = model:GetAttribute("RagdollCreatedAt")
		local v3 = typeof(ragdollCreatedAt) ~= "number" and 0 or ragdollCreatedAt

		if not (v < v3) then
			continue
		end

		v2 = model
		v = v3
	end

	return v2
end

return function(p)
	local v = tonumber(p)

	if not v then
		return
	end

	local zeusDeath = other:FindFirstChild("ZeusDeath")

	if not (zeusDeath and zeusDeath:IsA("ParticleEmitter")) then
		return
	end

	local victimRagdoll = resolveVictimRagdoll(v)

	if not victimRagdoll then
		local v2 = os.clock() + 0.5

		repeat
			task.wait(0.05)
			victimRagdoll = resolveVictimRagdoll(v)
		until victimRagdoll or v2 <= os.clock()
	end

	if not victimRagdoll then
		return
	end

	local humanoidRootPart = victimRagdoll:FindFirstChild("HumanoidRootPart")

	if not (humanoidRootPart and humanoidRootPart:IsA("BasePart")) then
		return
	end

	local clone = zeusDeath:Clone()
	clone.Enabled = false
	clone.Parent = humanoidRootPart
	local emitCount = clone:GetAttribute("EmitCount")

	if typeof(emitCount) == "number" and emitCount > 0 then
		clone:Emit(emitCount)
	else
		clone.Enabled = true
		task.delay(0.15, function()
			if clone and clone.Parent then
				clone.Enabled = false
			end
		end)
	end

	Debris:AddItem(clone, math.max(clone.Lifetime.Max, 1) + 1)
end