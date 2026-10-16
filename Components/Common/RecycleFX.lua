local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = workspace:WaitForChild("Debris")
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)

local function isPersistentDebris(child) -- 1 equivalent call inferred from this helper
	if not (child:GetAttribute("PersistentDebris") ~= true and string.sub(child.Name, -7) ~= "_Weapon") then
		return true
	end

	return string.find(child.Name, "_WeaponAttachments", 1, true) ~= nil
end

return function()
	local count = 0
	local count2 = 0

	for _, child in Debris:GetChildren() do
		if child:IsA("Folder") then
			continue
		end

		if isPersistentDebris(child) then -- inferred equivalent call
			count += 1
		elseif
			child:IsA("Model")
			and (child:GetAttribute("CharacterType") ~= nil or child:FindFirstChildOfClass("Humanoid") ~= nil)
		then
			count += 1
			Ragdoll.HideCharacterLocally(child)
		else
			count2 += 1

			if Players:FindFirstChild(child.Name) then
				local v = child
				task.delay(0.5, function()
					if v and v.Parent then
						v:Destroy()
					end
				end)
			else
				child:Destroy()
			end
		end
	end

	if DebugFlags.IsEnabled("DebrisCleanup") then
		warn(("[DebrisCleanup][Client] CleanupDebris received: destroyed=%d skipped=%d"):format(count2, count))
	end
end