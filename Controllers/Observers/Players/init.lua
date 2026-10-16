local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Observers = require(ReplicatedStorage.Packages.Observers)
local DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)
local LocalPlayer = Players.LocalPlayer
local CreateWeaponModel = require(script.Components.CreateWeaponModel)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local v = {}
local v2 = {}
local v3 = {}
local v4 = {}
local v5 = {}
local v6 = {}
local v7 = 1
local flag = false
local fn

local function profileScope(p: string, fn2) -- 6 equivalent calls inferred from this helper
	debug.profilebegin(p)
	local success, result = pcall(fn2)
	debug.profileend()

	if not success then
		error(result, 0)
	end

	return result
end

local function requestCharacterVisualRebuild(instance) -- 5 equivalent calls inferred from this helper
	if v5[instance] then
		return
	end

	v5[instance] = true
	table.insert(v6, instance)

	if flag then
		return
	end

	flag = true
	task.spawn(function()
		while v7 <= #v6 do
			RunService.Heartbeat:Wait()
			local v8 = v6[v7]
			v7 += 1

			if not v5[v8] then
				continue
			end

			v5[v8] = nil

			if v8.Parent == Players then
				task.spawn(function()
					local success, result = pcall(fn, v8)

					if not success then
						warn(`[ThirdPersonWeaponModels] {v8.Name} presentation rebuild failed: {result}`)
					end
				end)
			end
		end

		table.clear(v6)
		v7 = 1
		flag = false
	end)
end

local function cancelCharacterVisualRebuild(instance) -- 2 equivalent calls inferred from this helper
	v5[instance] = nil
end

local function waitForPresentationRig(playerCharacter)
	for _, childName in { "HumanoidRootPart", "UpperTorso", "LeftHand", "RightHand" } do
		local part = playerCharacter:FindFirstChild(childName) or playerCharacter:WaitForChild(childName, 10)

		if not (part and part:IsA("BasePart")) then
			return false
		end
	end

	return true
end

local function clearCurrentEquippedVisuals(instance)
	v[instance] = nil
	v2[instance] = nil
	local playerCharacter = CharacterResolver.getPlayerCharacter(instance)

	if playerCharacter then
		for _, folder in ipairs(playerCharacter:GetChildren()) do
			if folder:IsA("Folder") and (folder.Name == "WeaponAttachments" or folder.Name == "WeaponModel") then
				folder:ClearAllChildren()
			end
		end
	end

	CreateWeaponModel.ClearPlayerCache(instance)
end

local function buildInventorySlots(instance)
	local result = {}

	for i = 1, 3 do
		local attribute = instance:GetAttribute("Slot" .. i)

		if attribute then
			result[i] = HttpService:JSONDecode(attribute)
		end
	end

	return result
end

local function stickerSignature(stickers)
	if typeof(stickers) ~= "table" then
		return ""
	end

	local v8 = {}

	for i, v9 in ipairs(stickers) do
		if typeof(v9) == "table" then
			local position = v9.Position
			local v10 = typeof(position) ~= "table" and "" or position.Rotation or ""
			local v11 = typeof(position) ~= "table" and "" or position.X or ""
			local v12 = typeof(position) ~= "table" and "" or position.Y or ""
			v8[i] = string.format(
				"%s@%s,%s,%s",
				tostring(v9.Sticker or ""),
				tostring(v10),
				tostring(v11),
				(tostring(v12))
			)
		else
			v8[i] = tostring(v9)
		end
	end

	return table.concat(v8, ";")
end

local function visualSignature(data)
	if typeof(data) == "table" then
		return table.concat({
			tostring(data.Identifier or ""),
			tostring(data.Name or ""),
			tostring(data.Skin or ""),
			tostring(data.Float or ""),
			tostring(data.StatTrack or ""),
			tostring(data.NameTag or ""),
			stickerSignature(data.Stickers)
		}, "|")
	end

	return ""
end

local function getEquippedWeaponName(value) -- 2 equivalent calls inferred from this helper
	if typeof(value) == "string" then
		return string.match(value, "\"Name\"%s*:%s*\"([^\"]+)\"") or ""
	end

	return ""
end

local function createInventoryListener(instance) -- 1 equivalent call inferred from this helper
	return Observers.observeAttribute(instance, "CurrentEquipped", function(json)
		if DebugFlags.IsEnabled("ThirdPersonWeaponModels") then
			warn(("[ThirdPersonWeaponModels] %s CurrentEquipped changed (%s bytes JSON)"):format(
				instance.Name,
				(tostring(typeof(json) ~= "string" and -1 or #json or -1))
			))
		end

		if json then
			local jsonDecode = HttpService:JSONDecode(json)
			local v8 = visualSignature(jsonDecode)

			if v8 == "" or v[instance] ~= v8 then
				v[instance] = v8
				v2[instance] = jsonDecode.IsSuppressed == true
				requestCharacterVisualRebuild(instance) -- inferred equivalent call
				return function()
					if instance:GetAttribute("CurrentEquipped") ~= nil then
						return
					end

					clearCurrentEquippedVisuals(instance)
				end
			else
				local isSuppressed = jsonDecode.IsSuppressed == true

				if v2[instance] ~= isSuppressed then
					v2[instance] = isSuppressed

					local function fn2()
						return CreateWeaponModel.RefreshSuppressorState(instance, jsonDecode)
					end

					if not profileScope("Observers.Players.RefreshSuppressorState", fn2) then -- inferred equivalent call
						requestCharacterVisualRebuild(instance) -- inferred equivalent call
					end
				end

				return function() end
			end
		else
			cancelCharacterVisualRebuild(instance) -- inferred equivalent call
			clearCurrentEquippedVisuals(instance)
			return function() end
		end
	end)
end

local function refreshHolster(p, p2: string) -- 2 equivalent calls inferred from this helper
	local success, result = pcall(CreateWeaponModel[p2], p)

	if DebugFlags.IsEnabled("ThirdPersonWeaponModels") and not success then
		warn(("[ThirdPersonWeaponModels] %s %s failed: %s"):format(p.Name, p2, (tostring(result))))
	end
end

local function refreshObjectiveKitHolster(instance) -- 1 equivalent call inferred from this helper
	refreshHolster(instance, "RefreshObjectiveKitHolster") -- inferred equivalent call
end

local function refreshBombHolster(instance) -- 1 equivalent call inferred from this helper
	debug.profilebegin("Observers.Players.RefreshBombHolster")
	refreshHolster(instance, "RefreshBombHolster") -- inferred equivalent call
	debug.profileend()
end

local function scheduleHolsterRefresh(object, p, refreshObjectiveKitHolster2) -- 1 equivalent call inferred from this helper
	if v5[object] or p[object] then
		return
	end

	p[object] = true
	task.defer(function()
		p[object] = nil

		if object.Parent == Players and not v5[object] then
			refreshObjectiveKitHolster2(object)
		end
	end)
end

local function createObjectiveKitListener(object)
	local function onKitChanged()
		scheduleHolsterRefresh(object, v3, refreshObjectiveKitHolster) -- inferred equivalent call
		return function() end
	end

	local v8 = Observers.observeAttribute(object, "HasDefuseKit", onKitChanged)
	local v9 = Observers.observeAttribute(object, "HasRescueKit", onKitChanged)
	local teamChangedConnection = object:GetAttributeChangedSignal("Team"):Connect(onKitChanged)
	return function()
		v8()
		v9()
		teamChangedConnection:Disconnect()
	end
end

local function createBombHolsterListener(instance)
	local equippedWeaponName = getEquippedWeaponName(instance:GetAttribute("CurrentEquipped")) -- inferred equivalent call
	local slot5ChangedConnection = instance:GetAttributeChangedSignal("Slot5"):Connect(function()
		local v8 = instance
		local v9 = v4
		local v10 = refreshBombHolster

		if not v5[v8] then
			if v9[v8] then
				return
			end

			v9[v8] = true
			task.defer(function()
				v9[v8] = nil

				if v8.Parent == Players and not v5[v8] then
					v10(v8)
				end
			end)
		end
	end)
	local v8 = Observers.observeAttribute(instance, "CurrentEquipped", function(value)
		local equippedWeaponName2 = getEquippedWeaponName(value) -- inferred equivalent call

		if equippedWeaponName2 == equippedWeaponName then
			return function() end
		end

		equippedWeaponName = equippedWeaponName2
		requestCharacterVisualRebuild(instance) -- inferred equivalent call
		return function() end
	end)
	return function()
		slot5ChangedConnection:Disconnect()
		v8()
	end
end

fn = function(instance)
	local playerCharacter = CharacterResolver.getPlayerCharacter(instance)

	if playerCharacter and playerCharacter:GetAttribute("Dead") ~= true then
		if not waitForPresentationRig(playerCharacter) then
			CreateWeaponModel.ClearPlayerCache(instance)
			return
		end

		local function fn2()
			if
				CharacterResolver.getPlayerCharacter(instance) == playerCharacter
				and playerCharacter:GetAttribute("Dead") ~= true
			then
				local v8 = false
				local currentEquipped = instance:GetAttribute("CurrentEquipped")

				if currentEquipped then
					local success, result = pcall(function()
						return HttpService:JSONDecode(currentEquipped)
					end)

					if success and typeof(result) == "table" then
						v[instance] = visualSignature(result)
						v2[instance] = result.IsSuppressed == true

						local function fn3()
							CreateWeaponModel(instance, result, (buildInventorySlots(instance)))
						end

						profileScope("Observers.Players.RebuildCharacterVisuals.Weapon", fn3) -- inferred equivalent call
						v8 = true
					end
				end

				if not v8 then
					local function fn3()
						refreshObjectiveKitHolster(instance) -- inferred equivalent call
					end

					profileScope("Observers.Players.RebuildCharacterVisuals.ObjectiveKit", fn3) -- inferred equivalent call

					local function fn4()
						refreshBombHolster(instance) -- inferred equivalent call
					end

					profileScope("Observers.Players.RebuildCharacterVisuals.BombHolster", fn4) -- inferred equivalent call
				end
			else
				requestCharacterVisualRebuild(instance) -- inferred equivalent call
			end
		end

		profileScope("Observers.Players.RebuildCharacterVisuals", fn2) -- inferred equivalent call
	else
		local function fn2()
			CreateWeaponModel.ClearPlayerCache(instance)
		end

		profileScope("Observers.Players.RebuildCharacterVisuals.ClearCache", fn2) -- inferred equivalent call
	end
end

return Observers.observePlayer(function(instance)
	if instance == LocalPlayer then
		return function() end
	end

	local inventoryListener = createInventoryListener(instance) -- inferred equivalent call
	local objectiveKitListener = createObjectiveKitListener(instance)
	local bombHolsterListener = createBombHolsterListener(instance)
	local v8 = CharacterResolver.observeCharacter(instance, function()
		requestCharacterVisualRebuild(instance) -- inferred equivalent call
		return function() end
	end)
	return function()
		inventoryListener()
		objectiveKitListener()
		bombHolsterListener()
		v8()
		v3[instance] = nil
		v4[instance] = nil
		cancelCharacterVisualRebuild(instance) -- inferred equivalent call
		CreateWeaponModel.ClearPlayerCache(instance)
		v[instance] = nil
		v2[instance] = nil
	end
end)