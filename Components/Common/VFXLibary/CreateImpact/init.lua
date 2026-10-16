local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local Sound = require(ReplicatedStorage.Classes.Sound)
local ObjectPool = require(ReplicatedStorage.Shared.ObjectPool)
local DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)
local FlashEffect = require(ReplicatedStorage.Components.Common.VFXLibary.FlashEffect)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local Materials = require(script.Components.Materials)
local impacts = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Impacts")
local Debris = workspace:WaitForChild("Debris")
local v = {}
local v2 = {}

local function hasParticleEmitter(folder)
	for _, emitter in ipairs(folder:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			return true
		end
	end

	return false
end

local function getImpactTemplates(instance)
	local v3 = v[instance]

	if v3 then
		return v3
	end

	local parts = {}

	for _, part in ipairs(instance:GetChildren()) do
		if part:IsA("BasePart") and hasParticleEmitter(part) then
			parts[#parts + 1] = part
		end
	end

	v[instance] = parts
	return parts
end

local function resetImpactMarker(folder)
	for _, emitter in ipairs(folder:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter:Clear()
		end
	end
end

local function getImpactPool(p)
	local v3 = v2[p]

	if v3 then
		return v3
	end

	local v4 = ObjectPool.new(p, { InitialSize = 2, MaxRetained = 60, Reset = resetImpactMarker })
	v2[p] = v4
	return v4
end

local function createImpactMarker(helmetHeadshot)
	debug.profilebegin("VFX.Impact.CreateImpactMarker")
	local impactTemplates = getImpactTemplates(helmetHeadshot)

	if #impactTemplates == 0 then
		debug.profileend()
		return nil, nil, nil
	end

	local impactTemplate = impactTemplates[math.random(1, #impactTemplates)]
	local selected = v2[impactTemplate]

	if not selected then
		selected = ObjectPool.new(impactTemplate, {
			InitialSize = 2,
			MaxRetained = 60,
			Reset = resetImpactMarker
		})
		v2[impactTemplate] = selected
	end

	local v3, v4 = selected:Acquire()
	v3.CollisionGroup = "Debris"
	v3.CanCollide = false
	v3.CanQuery = false
	v3.CanTouch = false
	v3.Anchored = true
	debug.profileend()
	return v3, selected, v4
end

local function IsHeadPart(part)
	if part and part:IsA("BasePart") then
		return string.find(string.lower(part.Name), "head", 1, true) ~= nil
	end

	return false
end

local function IsHeadImpact(part, p: string)
	local _

	if p ~= "Blood Splatter" then
		_ = false
		return false
	end

	if part and part:IsA("BasePart") then
		return string.find(string.lower(part.Name), "head", 1, true) ~= nil
	else
		return false
	end
end

local function decodeArmor(value)
	if typeof(value) ~= "string" or value == "" then
		return nil
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, value)

	if success and typeof(result) == "table" then
		return result
	end

	return nil
end

return function(part, p: string, vector: Vector3, vector2: Vector3, flag: boolean, flag2: boolean, flag3: boolean?, _: string?, flag4: boolean?, flag5: boolean?, flag6: boolean?, flag7: boolean?)
	debug.profilebegin("VFX.Impact")
	local v3 = p == "Blood Splatter" and Players.LocalPlayer:GetAttribute("SK") and "Blood Splatter_SK" or p
	local helmetHeadshot = impacts:FindFirstChild(Materials[v3] or v3)

	if helmetHeadshot then
		local v4

		if v3 == "Blood Splatter" and part and part:IsA("BasePart") then
			v4 = string.find(string.lower(part.Name), "head", 1, true) ~= nil
		else
			v4 = false
		end

		local v5 = v4 or flag5 ~= nil
		local v6 = flag5 == true
		debug.profilebegin("VFX.Impact.ResolveSound")
		local name = helmetHeadshot.Name

		if v5 then
			name = "Headshot"

			if part and not flag2 and flag5 == nil then
				local model = part:FindFirstAncestorOfClass("Model")
				local combatantId

				if model and model:GetAttribute("Bot") == true then
					combatantId = model:GetAttribute("CombatantId")
				end

				if typeof(combatantId) == "number" then
					local v7 = Participants.FromKey(Participants.BotKey(combatantId))
					local result

					if v7 then
						local armor = v7:GetAttribute("Armor")

						if typeof(armor) == "string" and armor ~= "" then
							local success
							success, result = pcall(HttpService.JSONDecode, HttpService, armor)

							if not success or typeof(result) ~= "table" then
								result = nil
							end
						end
					end

					if result == nil then
						v6 = false
					else
						v6 = result.Type == "Kevlar + Helmet"
					end
				elseif CharacterResolver.isPlayerCharacter(model) and model:IsDescendantOf(workspace) then
					local playerFromCharacter = CharacterResolver.getPlayerFromCharacter(model)

					if playerFromCharacter and playerFromCharacter:IsDescendantOf(Players) then
						local armor = playerFromCharacter:GetAttribute("Armor")
						local result

						if typeof(armor) == "string" and armor ~= "" then
							local success
							success, result = pcall(HttpService.JSONDecode, HttpService, armor)

							if not success or typeof(result) ~= "table" then
								result = nil
							end
						end

						if result == nil then
							v6 = false
						else
							v6 = result.Type == "Kevlar + Helmet"
						end
					end
				end
			end

			if v6 then
				name = "Helmet Headshot"
			end
		end

		local cutoutBoard = CharacterResolver.getCutoutBoard(part)

		if cutoutBoard then
			name = CharacterResolver.isCutoutHeadshot(cutoutBoard, vector) and "Helmet Headshot" or "Blood Splatter"
		end

		debug.profileend()

		if flag or flag7 == true then
			if DebugFlags.IsEnabled("WeaponFX") then
				warn(("[WeaponFX][Client][ImpactSound] skipped material=%s pos=%s exit=%s suppressed=%s"):format(
					tostring(v3),
					tostring(vector),
					tostring(flag),
					(tostring(flag7 == true))
				))
			end
		else
			debug.profilebegin("VFX.Impact.PlaySound")
			local isFlashed = FlashEffect.IsFlashed()
			local v7 = isFlashed and 0 or 1

			if DebugFlags.IsEnabled("WeaponFX") then
				warn(("[WeaponFX][Client][ImpactSound] play material=%s sound=%s pos=%s flashed=%s exit=%s melee=%s volumeMult=%s"):format(
					tostring(v3),
					tostring(name),
					tostring(vector),
					tostring(isFlashed),
					tostring(flag),
					tostring(flag2),
					(tostring(v7))
				))
			end

			Sound.new("Bullet"):PlaySoundAtPosition(
				{ Position = vector, Class = "Bullet", Name = name },
				nil,
				v7,
				flag3 == true,
				flag4 == true
			)
			debug.profileend()
		end

		if v3 == "Blood Splatter" and v6 then
			helmetHeadshot = impacts:FindFirstChild("Helmet Headshot") or helmetHeadshot
		end

		if (v3 == "Blood Splatter" or not flag2) and flag6 ~= true then
			local impactMarker, v7, v8 = createImpactMarker(helmetHeadshot)

			if not (impactMarker and v7 and v8) then
				debug.profileend()
				return
			end

			debug.profilebegin("VFX.Impact.ParentMarker")

			if v5 and v3 == "Blood Splatter" and part and part:IsA("BasePart") then
				impactMarker.CFrame = CFrame.new(part.Position, part.Position + createVector(0, 1, 0))
			else
				impactMarker.CFrame = CFrame.new(vector, vector + vector2) + vector2 * 0.1
			end

			impactMarker.Parent = Debris
			impactMarker.Transparency = 1
			debug.profileend()
			debug.profilebegin("VFX.Impact.EmitParticles")

			for _, emitter in ipairs(impactMarker:GetDescendants()) do
				if not emitter:IsA("ParticleEmitter") then
					continue
				end

				local emitDelay = emitter:GetAttribute("EmitDelay") or 0
				local emitCount = emitter:GetAttribute("EmitCount") or 1

				if emitDelay <= 0 then
					emitter:Emit(emitCount)
				else
					local v9 = emitter
					task.delay(emitDelay, function()
						if impactMarker.Parent and v9.Parent and v7:IsAcquired(impactMarker, v8) then
							v9:Emit(emitCount)
						end
					end)
				end
			end

			debug.profileend()
			task.delay(5, function()
				v7:Release(impactMarker, v8)
			end)
		end
	end

	debug.profileend()
end