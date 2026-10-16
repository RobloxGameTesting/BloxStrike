local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
require(script:WaitForChild("Types"))
local Rig = require(script:WaitForChild("Rig"))
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Ragdoll = {}
Ragdoll.__index = Ragdoll
local Debris = workspace:WaitForChild("Debris")
local v = math.clamp(Players.MaxPlayers * 2, 4, 24)
local cframe = CFrame.new(0, -100, 0)
local v2 = {}
local v3 = {}
local v4 = {}
local v5 = {}
local v6 = {}
local v7 = {}
local object = setmetatable({}, { __mode = "k" })
local v8 = {}
local v9 = 1
local flag = false
local object2 = setmetatable({}, { __mode = "k" })
local object3 = setmetatable({}, { __mode = "k" })
local v10 = {}
local v11 = {}
local v12 = {}
local v13 = {}
local object4 = setmetatable({}, { __mode = "k" })
local v14 = {}
local v15 = 0
local count = 0
local v16 = true
local fn
local v17 = {
	AnimationController = true,
	CharacterModel = true,
	WeaponAttachments = true,
	WeaponModel = true
}
local v18 = { RagdollReady = true, RagdollStaged = true }
local v19 = {
	Dead = true,
	Ragdolled = true,
	RagdollCreatedAt = true,
	PreparedRagdoll = true,
	ClientRagdoll = true
}

local function profileScope(p: string, fn2) -- 14 equivalent calls inferred from this helper
	debug.profilebegin(p)
	local success, result = pcall(fn2)
	debug.profileend()

	if not success then
		error(result, 0)
	end

	return result
end

local function startPreparationStageWorker() -- 1 equivalent call inferred from this helper
	if flag then
		return
	end

	flag = true
	task.spawn(function()
		while v9 <= #v8 do
			RunService.Heartbeat:Wait()
			local v20 = v8[v9]
			v9 += 1
			local success, result = pcall(v20.Callback)
			v20.Succeeded = success
			v20.Result = result
			v20.Completed = true
		end

		table.clear(v8)
		v9 = 1
		flag = false
	end)
end

local function runPreparationStage(fn2)
	local v20 = { Callback = fn2, Completed = false, Succeeded = false, Result = nil }
	table.insert(v8, v20)
	startPreparationStageWorker() -- inferred equivalent call

	while not v20.Completed do
		RunService.Heartbeat:Wait()
	end

	if not v20.Succeeded then
		error(v20.Result, 0)
	end

	return v20.Result
end

local function isVisualEffect(descendant)
	return descendant:IsA("ParticleEmitter")
		or descendant:IsA("Trail")
		or descendant:IsA("Beam")
		or descendant:IsA("Fire")
		or descendant:IsA("Smoke")
		or descendant:IsA("Sparkles")
end

local function isExcludedRagdollContent(descendant)
	return v17[descendant.Name] == true
		or (descendant:IsA("AnimationController") or descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ModuleScript") or descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") or descendant:IsA("Highlight") or descendant:IsA("ProximityPrompt") or descendant:IsA("ClickDetector"))
end

local function markNonArchivableRagdollContent(folder) -- 3 equivalent calls inferred from this helper
	for _, descendant in folder:GetDescendants() do
		if isExcludedRagdollContent(descendant) then
			descendant.Archivable = false
		end
	end

	object3[folder] = true
end

local function getRagdollLifetime() -- 2 equivalent calls inferred from this helper
	local v20

	if GameState.GetState() == "Warmup" then
		v20 = workspace:GetAttribute("Gamemode") == "Deathmatch"
	else
		v20 = false
	end

	if v20 then
		return 10
	end

	return 15
end

local function cleanupAttachments(instance) -- 3 equivalent calls inferred from this helper
	local characterModel = instance:FindFirstChild("CharacterModel")

	if characterModel then
		characterModel:Destroy()
	end
end

local function getSourceCharacter(p) -- 2 equivalent calls inferred from this helper
	return v4[p] or p
end

local function destroyLocalCorpse(p) -- 4 equivalent calls inferred from this helper
	local v20 = v3[p]
	v3[p] = nil

	if v20 then
		v4[v20] = nil
		fn(v20)
	end
end

local function destroyPreparedCorpse(p) -- 3 equivalent calls inferred from this helper
	local v20 = v7[p]
	v7[p] = nil

	if v20 then
		v20.Cancelled = true
		local corpse = v20.Corpse
		v20.Corpse = nil

		if corpse then
			fn(corpse)
		end
	end

	local v21 = v5[p]
	v5[p] = nil

	if v21 then
		fn(v21)
	end
end

local function disconnectPreparationCleanup(p) -- 6 equivalent calls inferred from this helper
	local connection = v6[p]
	v6[p] = nil

	if connection then
		connection:Disconnect()
	end
end

local function clearCorpseDeathState(instance)
	instance:SetAttribute("PreparedRagdoll", true)
	instance:SetAttribute("Dead", nil)
	instance:SetAttribute("Ragdolled", nil)
	instance:SetAttribute("RagdollCreatedAt", nil)
	CollectionService:RemoveTag(instance, "Ragdoll")
end

local function markCorpseAsPrepared(p, instance) -- 2 equivalent calls inferred from this helper
	instance.Name = `__PreparedRagdoll_{p.Name}`
	instance:SetAttribute("ClientRagdoll", true)
	clearCorpseDeathState(instance)
end

local function configureCorpseClone(instance, folder)
	markCorpseAsPrepared(instance, folder) -- inferred equivalent call
	local descendants = {}
	local effects = {}

	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.LocalTransparencyModifier = 1
			table.insert(descendants, descendant)
		elseif isVisualEffect(descendant) or descendant:IsA("Light") then
			table.insert(effects, { Instance = descendant, Enabled = descendant.Enabled })
			descendant.Enabled = false
		end

		if descendant:IsA("Motor6D") or descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
			local part0 = descendant.Part0
			local part1 = descendant.Part1

			if part0 and not part0:IsDescendantOf(folder) or part1 and not part1:IsDescendantOf(folder) then
				descendant:Destroy()
			end
		elseif descendant:IsA("Highlight") then
			descendant:Destroy()
		end
	end

	object[folder] = { Effects = effects, Renderables = descendants }
end

local function setCorpseVisible(p, flag2: boolean)
	local v20 = object[p]

	if not v20 then
		return
	end

	local localTransparencyModifier = flag2 and 0 or 1

	for _, renderable in v20.Renderables do
		if renderable.Parent then
			renderable.LocalTransparencyModifier = localTransparencyModifier
		end
	end

	for _, effect in v20.Effects do
		if effect.Instance.Parent then
			effect.Instance.Enabled = flag2 and effect.Enabled
		end
	end
end

local function getCorpsePoolKey(instance)
	local playerFromCharacter = CharacterResolver.getPlayerFromCharacter(instance)
	local userId

	if playerFromCharacter then
		userId = tostring(playerFromCharacter.UserId)
	else
		userId = instance.Name
	end

	local characterName = instance:GetAttribute("CharacterName")
	local equippedGloves = instance:GetAttribute("EquippedGloves")
	return table.concat({ userId, tostring(characterName or ""), (tostring(equippedGloves or "")) }, "\0")
end

local function syncCorpseAppearance(instance, instance2)
	for _, child in instance:GetChildren() do
		local instance3 = instance2:FindFirstChild(child.Name)

		if child:IsA("BasePart") and instance3 and instance3:IsA("BasePart") then
			if instance3.Color ~= child.Color then
				instance3.Color = child.Color
			end
		elseif child:IsA("BodyColors") and instance3 and instance3:IsA("BodyColors") then
			instance3.HeadColor3 = child.HeadColor3
			instance3.LeftArmColor3 = child.LeftArmColor3
			instance3.LeftLegColor3 = child.LeftLegColor3
			instance3.RightArmColor3 = child.RightArmColor3
			instance3.RightLegColor3 = child.RightLegColor3
			instance3.TorsoColor3 = child.TorsoColor3
		end
	end

	for k in instance2:GetAttributes() do
		if not v18[k] then
			instance2:SetAttribute(k, nil)
		end
	end

	for k, v20 in instance:GetAttributes() do
		if not (v18[k] or v19[k]) then
			instance2:SetAttribute(k, v20)
		end
	end

	markCorpseAsPrepared(instance, instance2) -- inferred equivalent call
end

local function removePoolMembership(instance)
	v13[instance] = nil
	local v20 = v10[instance]
	v10[instance] = nil

	if not v20 then
		return
	end

	local v21 = v12[v20]

	if v21 then
		for i = #v21, 1, -1 do
			if v21[i] == instance then
				table.remove(v21, i)
			end
		end

		if #v21 == 0 then
			v12[v20] = nil
		end
	end

	local v22 = (v11[v20] or 1) - 1
	local v23 = v11

	if not (v22 > 0) then
		v22 = nil
	end

	v23[v20] = v22
	v15 = math.max(0, v15 - 1)
end

local function fn2(instance)
	removePoolMembership(instance)
	object4[instance] = nil
	v4[instance] = nil
	object[instance] = nil
	CollectionService:RemoveTag(instance, "Ragdoll")
	instance:Destroy()
end

local function registerPoolMember(p, p2: string)
	local v20 = v10[p]

	if v20 then
		return v20 == p2
	end

	if (v11[p2] or 0) >= 2 or v <= v15 then
		return false
	end

	v10[p] = p2
	v11[p2] = (v11[p2] or 0) + 1
	v15 += 1
	return true
end

local function parkCorpse(instance) -- 4 equivalent calls inferred from this helper
	local function fn3()
		instance:PivotTo(cframe)
	end

	profileScope("Ragdoll.Pool.Park", fn3) -- inferred equivalent call
end

fn = function(instance)
	if object4[instance] or not v10[instance] or instance.Parent ~= Debris or not Rig.ResetPrepared(instance) then
		fn2(instance)
		return
	end

	if v13[instance] then
		return
	end

	setCorpseVisible(instance, false)
	instance.Name = "__PooledRagdoll"
	clearCorpseDeathState(instance)
	parkCorpse(instance) -- inferred equivalent call
	local v20 = v10[instance]
	local v21 = v12[v20]

	if not v21 then
		v21 = {}
		v12[v20] = v21
	end

	v13[instance] = true
	table.insert(v21, instance)
end

local function acquirePooledCorpse(p, corpsePoolKey: string)
	local v20 = v12[corpsePoolKey]

	while v20 and #v20 > 0 do
		local v21 = table.remove(v20)

		if #v20 == 0 then
			v12[corpsePoolKey] = nil
		end

		if not v13[v21] then
			continue
		end

		v13[v21] = nil

		if v21.Parent == Debris and v10[v21] == corpsePoolKey and not object4[v21] and Rig.ResetPrepared(v21) then
			syncCorpseAppearance(p, v21)
			setCorpseVisible(v21, false)
			parkCorpse(v21) -- inferred equivalent call
			return v21
		else
			fn2(v21)
		end
	end

	return nil
end

local function ensurePreparationCleanup(instance) -- 2 equivalent calls inferred from this helper
	if v6[instance] then
		return
	end

	v6[instance] = instance.AncestryChanged:Connect(function(_, parent)
		if parent ~= nil then
			return
		end

		destroyPreparedCorpse(instance) -- inferred equivalent call
		disconnectPreparationCleanup(instance) -- inferred equivalent call
	end)
end

local function canPrepareSource(instance) -- 4 equivalent calls inferred from this helper
	local v20 = v16

	if v20 then
		if
			instance.Parent == nil
			or instance:GetAttribute("ClientRagdoll") == true
			or instance:GetAttribute("Dead") == true
		then
			return false
		else
			return not object2[instance]
		end
	end

	return v20
end

local function canPrewarmReserve() -- 3 equivalent calls inferred from this helper
	local state = GameState.GetState()
	return v16 and (state == "Warmup" or state == "Buy Period")
end

local function isPreparationCurrent(instance, p) -- 4 equivalent calls inferred from this helper
	local v20

	if v7[instance] == p then
		v20 = not p.Cancelled and v16

		if v20 then
			if
				instance.Parent == nil
				or instance:GetAttribute("ClientRagdoll") == true
				or instance:GetAttribute("Dead") == true
			then
				return false
			else
				return not object2[instance]
			end
		end
	else
		return false
	end

	return v20
end

local function cloneCorpse(instance, p: string, p2: string)
	if not instance.Parent or instance:GetAttribute("ClientRagdoll") == true then
		return nil
	end

	instance.Archivable = true
	debug.profilebegin(p)
	local success, result = pcall(function()
		return instance:Clone()
	end)
	debug.profileend()

	if not success then
		error(result, 0)
	end

	local function fn3()
		configureCorpseClone(instance, result)
	end

	profileScope(p2, fn3) -- inferred equivalent call
	return result
end

local function scheduleReservePrewarm(folder, p: string)
	if not canPrewarmReserve() or (v11[p] or 0) >= 2 or v14[p] ~= nil then -- inferred equivalent call
		return
	end

	local v20 = count
	v14[p] = v20
	local playerFromCharacter = CharacterResolver.getPlayerFromCharacter(folder)

	local function isStale() -- 4 equivalent calls inferred from this helper
		return v20 ~= count
			or playerFromCharacter ~= nil and playerFromCharacter.Parent ~= Players
			or not canPrewarmReserve() -- inferred equivalent call
	end

	task.spawn(function()
		local v21 = nil
		local success, result = pcall(function()
			runPreparationStage(function()
				if not isStale() and canPrepareSource(folder) then -- inferred equivalent call
					if not object3[folder] then
						markNonArchivableRagdollContent(folder) -- inferred equivalent call
					end

					v21 = cloneCorpse(folder, "Ragdoll.Pool.CloneReserve", "Ragdoll.Pool.ConfigureReserve")
				end
			end)

			if v21 and not isStale() then -- inferred equivalent call
				local v22 = v21

				if runPreparationStage(function()
					if not isStale() and canPrepareSource(folder) then -- inferred equivalent call
						return Rig.Prepare(v22) and Rig.StagePrepared(v22)
					end

					return false
				end) == true and v20 == count and canPrewarmReserve() then -- inferred equivalent call
					runPreparationStage(function()
						if isStale() or (v11[p] or 0) >= 2 then -- inferred equivalent call
							return false
						end

						parkCorpse(v22) -- inferred equivalent call
						local v23 = v22
						local v24 = p
						local v25 = v10[v23]
						local v26

						if v25 then
							v26 = v25 == v24
						elseif (v11[v24] or 0) >= 2 or v <= v15 then
							v26 = false
						else
							v10[v23] = v24
							v11[v24] = (v11[v24] or 0) + 1
							v15 += 1
							v26 = true
						end

						if not v26 then
							return false
						end

						local function fn3()
							v22.Parent = Debris
						end

						profileScope("Ragdoll.Pool.ParentReserve", fn3) -- inferred equivalent call
						fn(v22)
						v21 = nil
						return true
					end)
				end
			end
		end)

		if v21 then
			fn2(v21)
		end

		if v14[p] == v20 then
			v14[p] = nil
		end

		if not success then
			warn(`[Ragdoll] Reserve prewarm failed: {result}`)
		end
	end)
end

local function takePreparedCorpse(p) -- 1 equivalent call inferred from this helper
	local corpse = v5[p]
	v5[p] = nil
	local v20 = v7[p]
	v7[p] = nil

	if v20 then
		v20.Cancelled = true

		if corpse then
			if v20.Corpse then
				fn(v20.Corpse)
				v20.Corpse = nil
			end
		else
			corpse = v20.Corpse
			v20.Corpse = nil
		end
	end

	disconnectPreparationCleanup(p) -- inferred equivalent call
	return corpse
end

function Ragdoll.HideCharacterLocally(folder)
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = 1
			descendant.CanCollide = false
			descendant.CanQuery = false
		elseif descendant:IsA("Decal") then
			descendant.LocalTransparencyModifier = 1
		elseif
			isVisualEffect(descendant)
			or descendant:IsA("BillboardGui")
			or descendant:IsA("SurfaceGui")
			or descendant:IsA("Highlight")
		then
			descendant.Enabled = false
		end
	end
end

function Ragdoll.PrepareCharacter(p)
	if v5[p] then
		return true
	end

	if not canPrepareSource(p) then -- inferred equivalent call
		return false
	end

	local v20 = v7[p]

	if v20 then
		while v7[p] == v20 do
			if not canPrepareSource(p) then -- inferred equivalent call
				break
			end

			RunService.Heartbeat:Wait()
		end

		return v5[p] ~= nil
	else
		local corpsePoolKey = getCorpsePoolKey(p)
		local v21 = acquirePooledCorpse(p, corpsePoolKey)

		if v21 then
			v5[p] = v21
			ensurePreparationCleanup(p) -- inferred equivalent call
			scheduleReservePrewarm(p, corpsePoolKey)
			return true
		else
			local v22 = { Corpse = nil, Cancelled = false }
			v7[p] = v22
			ensurePreparationCleanup(p) -- inferred equivalent call
			local success, result = pcall(function()
				runPreparationStage(function()
					if not isPreparationCurrent(p, v22) then -- inferred equivalent call
						return
					end

					if not object3[p] then
						local function fn3()
							markNonArchivableRagdollContent(p) -- inferred equivalent call
						end

						profileScope("Ragdoll.Prepare.MarkNonArchivable", fn3) -- inferred equivalent call
					end

					local corpse = cloneCorpse(p, "Ragdoll.Prepare.Clone", "Ragdoll.Prepare.ConfigureClone")

					if not corpse then
						return
					end

					if isPreparationCurrent(p, v22) then -- inferred equivalent call
						v22.Corpse = corpse
					else
						fn2(corpse)
					end
				end)
				local corpse = v22.Corpse

				if not corpse then
					return false
				end

				if not isPreparationCurrent(p, v22) then -- inferred equivalent call
					return false
				end

				local function isCorpseCurrent() -- 4 equivalent calls inferred from this helper
					return isPreparationCurrent(p, v22) and v22.Corpse == corpse -- inferred equivalent call
				end

				if runPreparationStage(function()
					if isCorpseCurrent() then -- inferred equivalent call
						return Rig.Prepare(corpse) and Rig.StagePrepared(corpse)
					end

					return false
				end) ~= true then
					return false
				end

				if not isCorpseCurrent() then -- inferred equivalent call
					return false
				end

				if runPreparationStage(function()
					if not isCorpseCurrent() then -- inferred equivalent call
						return false
					end

					parkCorpse(corpse) -- inferred equivalent call
					local v23 = corpse
					local v24 = corpsePoolKey
					local v25 = v10[v23]

					if v25 then
						local _ = v25 == v24
					elseif not ((v11[v24] or 0) >= 2 or v <= v15) then
						v10[v23] = v24
						v11[v24] = (v11[v24] or 0) + 1
						v15 += 1
					end

					local function fn3()
						corpse.Parent = Debris
					end

					profileScope("Ragdoll.Prepare.ParentInitialPoolSlot", fn3) -- inferred equivalent call
					return true
				end) ~= true then
					return false
				end

				if not isCorpseCurrent() then -- inferred equivalent call
					return false
				end

				v5[p] = corpse
				v22.Corpse = nil
				v7[p] = nil
				scheduleReservePrewarm(p, corpsePoolKey)
				return true
			end)

			if v7[p] == v22 then
				v7[p] = nil
			end

			if v22.Corpse then
				fn(v22.Corpse)
				v22.Corpse = nil
			end

			if not success then
				disconnectPreparationCleanup(p) -- inferred equivalent call
				error(result, 0)
			end

			if result ~= true and not v5[p] then
				disconnectPreparationCleanup(p) -- inferred equivalent call
			end

			return result == true
		end
	end
end

function Ragdoll.ActivateCharacter(instance, vector: Vector3?)
	if instance:GetAttribute("ClientRagdoll") == true then
		return instance
	end

	local v20 = v3[instance]

	if v20 and v20.Parent then
		return v20
	end

	if object2[instance] then
		Ragdoll.HideCharacterLocally(instance)
		return instance
	end

	if not object3[instance] then
		local function fn3()
			markNonArchivableRagdollContent(instance) -- inferred equivalent call
		end

		profileScope("Ragdoll.Activate.MarkNonArchivable", fn3) -- inferred equivalent call
	end

	local function fn3()
		return Rig.CapturePose(instance)
	end

	local result = profileScope("Ragdoll.Activate.CapturePose", fn3) -- inferred equivalent call

	local function fn4()
		return takePreparedCorpse(instance) -- inferred equivalent call
	end

	local v21 = profileScope("Ragdoll.Activate.TakePrepared", fn4) -- inferred equivalent call
		or cloneCorpse(instance, "Ragdoll.Activate.Clone", "Ragdoll.Activate.ConfigureFallbackClone")

	if not v21 then
		return instance
	end

	if not Rig.IsPrepared(v21) then
		local function fn5()
			return Rig.Prepare(v21)
		end

		if profileScope("Ragdoll.Activate.CompletePreparation", fn5) ~= true then -- inferred equivalent call
			fn2(v21)
			return instance
		end
	end

	if not v10[v21] then
		local corpsePoolKey = getCorpsePoolKey(instance)
		local v22 = v10[v21]

		if v22 then
			local _ = v22 == corpsePoolKey
		elseif not ((v11[corpsePoolKey] or 0) >= 2 or v <= v15) then
			v10[v21] = corpsePoolKey
			v11[corpsePoolKey] = (v11[corpsePoolKey] or 0) + 1
			v15 += 1
		end
	end

	local function fn5()
		v21.Name = instance.Name
		v21:SetAttribute("PreparedRagdoll", nil)
		v21:SetAttribute("Dead", true)
		v3[instance] = v21
		v4[v21] = instance
	end

	profileScope("Ragdoll.Activate.ConfigureClone", fn5) -- inferred equivalent call

	local function fn6()
		Rig.Activate(v21, result, vector)
	end

	profileScope("Ragdoll.Activate.Rig", fn6) -- inferred equivalent call

	local function fn7()
		setCorpseVisible(v21, true)
	end

	profileScope("Ragdoll.Activate.Reveal", fn7) -- inferred equivalent call

	local function fn8()
		if v21.Parent ~= Debris then
			v21.Parent = Debris
		end
	end

	profileScope("Ragdoll.Activate.Parent", fn8) -- inferred equivalent call

	local function fn9()
		cleanupAttachments(instance) -- inferred equivalent call
		cleanupAttachments(v21) -- inferred equivalent call
		Ragdoll.HideCharacterLocally(instance)
	end

	profileScope("Ragdoll.Activate.Cleanup", fn9) -- inferred equivalent call
	task.delay(getRagdollLifetime(), function() -- inferred equivalent call
		if v3[instance] == v21 then
			destroyLocalCorpse(instance) -- inferred equivalent call
		end
	end)
	return v21
end

local function markPreparedCorpsesNonReusable(p) -- 2 equivalent calls inferred from this helper
	local v20 = v5[p]

	if v20 then
		object4[v20] = true
	end

	local v21 = v7[p]

	if v21 and v21.Corpse then
		object4[v21.Corpse] = true
	end
end

function Ragdoll.RetireCorpseLocally(p)
	task.defer(function()
		local sourceCharacter = getSourceCharacter(p) -- inferred equivalent call
		object2[sourceCharacter] = true
		local v20 = v3[sourceCharacter]

		if v20 then
			object4[v20] = true
		end

		markPreparedCorpsesNonReusable(sourceCharacter) -- inferred equivalent call
		destroyPreparedCorpse(sourceCharacter) -- inferred equivalent call
		disconnectPreparationCleanup(sourceCharacter) -- inferred equivalent call
		destroyLocalCorpse(sourceCharacter) -- inferred equivalent call

		if sourceCharacter.Parent then
			cleanupAttachments(sourceCharacter) -- inferred equivalent call
			Ragdoll.HideCharacterLocally(sourceCharacter)
		end
	end)
end

function Ragdoll.RecycleAll()
	local v20 = {}

	for k in v2 do
		table.insert(v20, k)
	end

	for _, v21 in v20 do
		v21:Destroy()
	end

	local v21 = {}

	for k in v3 do
		table.insert(v21, k)
	end

	for _, v22 in v21 do
		destroyLocalCorpse(v22) -- inferred equivalent call
	end
end

function Ragdoll.DestroyAll()
	count += 1
	Ragdoll.RecycleAll()
	local v20 = {}

	for k in v5 do
		v20[k] = true
	end

	for k in v7 do
		v20[k] = true
	end

	for k in v20 do
		markPreparedCorpsesNonReusable(k) -- inferred equivalent call
		destroyPreparedCorpse(k) -- inferred equivalent call
		disconnectPreparationCleanup(k) -- inferred equivalent call
	end

	local v21 = {}

	for k in v10 do
		table.insert(v21, k)
	end

	for _, v22 in v21 do
		fn2(v22)
	end

	table.clear(v12)
	table.clear(v13)
	table.clear(v11)
	table.clear(v14)
	v15 = 0
end

function Ragdoll.SetEnabled(flag2: boolean)
	if v16 == flag2 then
		return
	end

	v16 = flag2

	if not flag2 then
		Ragdoll.DestroyAll()
		return
	end

	for _, v20 in Players:GetPlayers() do
		local character = v20.Character

		if character then
			task.spawn(function()
				local success, result = pcall(Ragdoll.PrepareCharacter, character)

				if not success then
					warn(`[Ragdoll] Re-enabled prewarm failed: {result}`)
				end
			end)
		end
	end
end

function Ragdoll.OnceAppearanceReady(_, callback)
	callback()
end

function Ragdoll.SetupCharacterAppearance(_) end

function Ragdoll.new(p, p2)
	local object5 = setmetatable({}, Ragdoll)
	object5.Janitor = Janitor.new()
	object5.SourceCharacter = getSourceCharacter(p) -- inferred equivalent call
	object5.CharacterModel = Ragdoll.ActivateCharacter(object5.SourceCharacter, p2.Velocity)

	if p2.Finisher == "Charred" or p2.Finisher == "Gold" or p2.Finisher == "Melted" then
		object4[object5.CharacterModel] = true
	end

	object5.OnDestroy = object5.Janitor:Add(Signal.new())
	object5.OnAppearanceBuilt = object5.Janitor:Add(Signal.new())
	object5.IsAppearanceBuilt = true
	object5.IsDestroyed = false
	Rig.ApplyImpulse(object5.CharacterModel, p2)
	object5.Janitor:Add(object5.CharacterModel.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			object5:Destroy()
		end
	end))
	v2[object5] = true
	task.delay(getRagdollLifetime(), function() -- inferred equivalent call
		object5:Destroy()
	end)
	return object5
end

function Ragdoll:Destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true
	v2[self] = nil
	self.OnDestroy:Fire()
	destroyLocalCorpse(self.SourceCharacter) -- inferred equivalent call
	task.defer(self.Janitor.Destroy, self.Janitor)
end

GameState.ListenToState(function(_, p)
	if p == "Buy Period" then
		Ragdoll.RecycleAll()
	end

	if p ~= "Warmup" and p ~= "Buy Period" then
		return
	end

	for k in v5 do
		scheduleReservePrewarm(k, getCorpsePoolKey(k))
	end
end)
Players.PlayerRemoving:Connect(function(player)
	local formatted = ("%*\0"):format(player.UserId)
	local v20 = {}

	for k, v21 in v10 do
		if string.sub(v21, 1, #formatted) == formatted then
			table.insert(v20, k)
		end
	end

	for _, v21 in v20 do
		if v13[v21] then
			fn2(v21)
		else
			object4[v21] = true
		end
	end
end)
Ragdoll.Rig = Rig
return Ragdoll