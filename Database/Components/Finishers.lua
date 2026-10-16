local Finishers = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local ClientCharacterPresentation = require(ReplicatedStorage.Components.Common.ClientCharacterPresentation)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local LocalPlayer = Players.LocalPlayer
local v = {}
local v2 = {}
local modulesByName = {}

local function GetFinisherModule(p) -- 2 equivalent calls inferred from this helper
	local v3 = modulesByName[p.Finisher]
	assert(v3, `"{p.Finisher}" is not a valid member of database.custom.finishers`)
	return v3
end

local function findTutorialDummy(victim: number)
	if not IsTutorialMode() then
		return nil
	end

	for _, folder in workspace:GetChildren() do
		if not (folder.Name == "Debris" or folder:IsA("Folder") and string.sub(folder.Name, 1, 8) == "Tutorial") then
			continue
		end

		for _, model in folder:GetChildren() do
			if
				model:IsA("Model")
				and model:GetAttribute("TutorialDummy") == true
				and model:GetAttribute("DummyUserId") == victim
			then
				return model
			end
		end
	end

	return nil
end

function Finishers.ResolveVictimCharacter(data)
	if data.Generation == 0 then
		return (findTutorialDummy(data.Victim))
	end

	local v3

	if data.Victim <= -1000 then
		local BotCharacters = require(ReplicatedStorage.Controllers.CharacterController.BotCharacters)
		v3 = BotCharacters.TakeCorpse(-data.Victim - 1000, data.Generation, data.Position, data.LookYaw)
	else
		local playerByUserId = Players:GetPlayerByUserId(data.Victim)

		if playerByUserId == nil then
			return nil
		else
			v3 = ClientCharacterPresentation.Create(playerByUserId, data.Generation)
		end
	end

	if v3 == nil or not CharacterGeneration.Matches(v3, data.Generation) then
		return nil
	end

	v3:PivotTo(CFrame.new(data.Position) * CFrame.Angles(0, data.LookYaw, 0))
	v3:SetAttribute("Health", 0)
	v3:SetAttribute("Dead", true)
	return v3
end

function Finishers.IsFinisherValidForReplication(p)
	local finisherModule = GetFinisherModule(p) -- inferred equivalent call
	local userId = LocalPlayer.UserId
	return finisherModule.Replication == "Killer" and p.Killer == userId
		or (finisherModule.Replication == "Victim" and p.Victim == userId or (finisherModule.Replication == "Both" and (p.Killer == userId or p.Victim == userId) or finisherModule.Replication == "All"))
end

function Finishers.ExecuteFinisher(p)
	if not Finishers.IsFinisherValidForReplication(p) then
		return
	end

	local finisherModule = GetFinisherModule(p) -- inferred equivalent call
	local success, result = pcall(function()
		local victimCharacter = Finishers.ResolveVictimCharacter(p)

		if not victimCharacter then
			warn(`Failed to execute finisher "{p.Finisher}": missing victim character "{p.Victim}"`)
			return nil
		end

		victimCharacter.Archivable = true
		local victim = tostring(p.Victim)
		local v3 = v2[victim]

		if v3 then
			v3.Destroy()
		end

		while #v >= 8 do
			local v4 = table.remove(v, 1)

			if v4 then
				v4.Destroy()
			end
		end

		local finisher = finisherModule.Finisher(victimCharacter, p)
		local v4 = {
			Name = victim,
			Destroy = function()
				v2[victim] = nil
				finisher.Destroy()
			end
		}
		v2[victim] = finisher
		table.insert(v, v4)
		finisher.OnDestroy:Once(function()
			local index = table.find(v, v4)

			if index then
				table.remove(v, index)
			end
		end)
	end)

	if not success then
		warn(`Failed to execute finisher "{p.Finisher}": {result}`)
	end
end

for _, moduleScript in ipairs(ReplicatedStorage.Database.Custom.Finishers:GetChildren()) do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end

	local name = moduleScript.Name
	local module = require(moduleScript)
	modulesByName[name] = module
end

return Finishers