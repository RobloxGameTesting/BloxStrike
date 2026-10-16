local Animation = {}
Animation.__index = Animation
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local FlashEffect = require(ReplicatedStorage.Components.Common.VFXLibary.FlashEffect)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local v = { "7", "73", "735", "7355", "73556", "735560", "7355608" }
local v2 = {}

local function preloadClips(name: string)
	if v2[name] then
		return
	end

	v2[name] = true
	local weaponProperties = GetWeaponProperties(name)
	local cameraAnimations = weaponProperties and weaponProperties.CameraAnimations

	if typeof(cameraAnimations) ~= "Instance" then
		return
	end

	local animations = {}

	for _, animation in cameraAnimations:GetChildren() do
		if animation:IsA("Animation") then
			table.insert(animations, animation)
		end
	end

	task.spawn(ContentProvider.PreloadAsync, ContentProvider, animations)
end

local function isInspectVariantName(value: string) -- 1 equivalent call inferred from this helper
	return value == "Inspect" or string.match(value, "^Inspect%d+$") ~= nil
end

local function getVariantBaseName(value: string) -- 3 equivalent calls inferred from this helper
	local v3 = string.gsub(value, "%d+$", "")

	if v3 == "" then
		return value
	end

	return v3
end

local function shouldSkipDuplicateSoundEvent(instance, lastSoundEventName: string)
	local now = tick()
	local lastSoundEventName2 = instance:GetAttribute("LastSoundEventName")
	local lastSoundEventTick = instance:GetAttribute("LastSoundEventTick")

	if lastSoundEventName2 == lastSoundEventName and type(lastSoundEventTick) == "number" then
		local v3 = now - lastSoundEventTick

		if v3 >= 0 and v3 <= 0.02 then
			return true
		end
	end

	instance:SetAttribute("LastSoundEventName", lastSoundEventName)
	instance:SetAttribute("LastSoundEventTick", now)
	return false
end

local function handleAnimationSoundEvent(instance, object, value: string, childName: string, sound, sounds, player)
	if instance.IsDestroyed then
		return
	end

	local child = sounds and sounds:FindFirstChild(childName)

	if not child or not (#child:GetChildren() > 0) or shouldSkipDuplicateSoundEvent(object, childName) then
		return
	end

	local inspectVariantName = isInspectVariantName(value) -- inferred equivalent call

	if not inspectVariantName then
		inspectVariantName = getVariantBaseName(value) == "Equip" -- inferred equivalent call
	end

	if player == LocalPlayer or inspectVariantName then
		local v3 = sound:play({ Parent = PlayerGui, Name = childName }, (FlashEffect.GetAudioFadeMultiplier()))

		if v3 then
			instance.ActiveSounds[v3] = value
			v3.Ended:Once(function()
				if not instance.IsDestroyed then
					instance.ActiveSounds[v3] = nil
				end
			end)
		end
	end

	if
		inspectVariantName
		or LocalPlayer ~= player
		or childName == "Prepare" and sound.SoundGroupName == "R8 Revolver"
	then
		return
	end

	Remotes.Sound.ReplicateSound.Send({ Class = sound.SoundGroupName, Name = childName })
end

local function connectTrackSoundEvents(instance, result, p: string)
	local sound = instance.Sound
	local sounds = sound.Sounds
	local player = instance.Player
	local connections = {}
	local object = setmetatable({}, { __mode = "v" })
	object.instance = instance

	local function onSoundEvent(name: string) -- 1 equivalent call inferred from this helper
		local instance2 = object.instance

		if not instance2 then
			return
		end

		handleAnimationSoundEvent(instance2, result, p, name, sound, sounds, player)
	end

	table.insert(connections, result.KeyframeReached:Connect(onSoundEvent))

	if sounds then
		for _, folder in ipairs(sounds:GetChildren()) do
			if not folder:IsA("Folder") then
				continue
			end

			local name = folder.Name
			table.insert(connections, result:GetMarkerReachedSignal(name):Connect(function()
				onSoundEvent(name) -- inferred equivalent call
			end))
		end
	end

	return function()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		table.clear(connections)
	end
end

function Animation:getAnimation(p: string)
	self:ensureLoaded()
	return self.Animations[p]
end

function Animation:hasInspectAnimation()
	self:ensureLoaded()
	local inspect = self.VariantGroups.Inspect

	if inspect and #inspect > 0 then
		return true
	end

	return self.Animations.Inspect ~= nil
end

local function computeVariantProbabilities(list)
	local count = #list
	local total = 0
	local count2 = 0
	local result = {}

	for _, v3 in ipairs(list) do
		if v3.weight == nil then
			count2 += 1
		else
			total += math.max(v3.weight, 0)
		end
	end

	local v3 = math.max(0, 1 - count2 / count)
	local v4 = count - count2

	for i, v5 in ipairs(list) do
		if v5.weight == nil then
			result[i] = 1 / count
		elseif total > 0 then
			result[i] = v3 * (math.max(v5.weight, 0) / total)
		else
			result[i] = v3 / v4
		end
	end

	return result
end

local function rollVariant(list, p: string)
	if not list or #list == 0 then
		return p
	end

	if #list == 1 then
		return list[1].name
	end

	local v3 = computeVariantProbabilities(list)
	local v4 = math.random()
	local total = 0

	for i, v5 in ipairs(list) do
		total += v3[i]

		if v4 < total then
			return v5.name
		end
	end

	return list[#list].name
end

function Animation:pickVariant(p: string)
	self:ensureLoaded()
	return (rollVariant(self.VariantGroups[p], p))
end

function Animation:pickInspectVariant()
	self:ensureLoaded()
	local now = os.clock()

	if
		self.LastInspectVariant
		and self.LastInspectCancelTime
		and now - self.LastInspectCancelTime <= 1
		and self.Animations[self.LastInspectVariant]
	then
		return self.LastInspectVariant
	end

	local lastInspectVariant = rollVariant(self.VariantGroups.Inspect, "Inspect")
	self.LastInspectVariant = lastInspectVariant
	return lastInspectVariant
end

function Animation:markInspectCancel()
	self.LastInspectCancelTime = os.clock()
end

function Animation:adjustAnimationSpeed(p: string, p2: number)
	local animation = self:getAnimation(p)

	if animation then
		animation:AdjustSpeed(animation.Length / p2)
	end
end

function Animation:play(p: string, ...)
	local animation = self:getAnimation(p)

	if animation then
		animation:Play(...)
	end

	return animation
end

function Animation.stop(p, p2: string, value: number?)
	local animation = p.Animations[p2]

	if animation and animation.IsPlaying then
		animation:Stop(value or 0)
	end
end

local function hermiteEaseOut(p: number) -- 2 equivalent calls inferred from this helper
	return p * 3 * p - p * 2 * p * p
end

function Animation:cancelCrossfade()
	if self.CrossfadeConnection then
		self.CrossfadeConnection:Disconnect()
		self.CrossfadeConnection = nil
	end

	if self.CrossfadeTempTrack then
		self.CrossfadeTempTrack:Stop(0)
		self.CrossfadeTempTrack:Destroy()
		self.CrossfadeTempTrack = nil
	end
end

function Animation:crossfadeRestart(value: string, value2: number?)
	local v3 = value2 or 0.25
	self:cancelCrossfade()
	local variantGroup = self.VariantGroups[getVariantBaseName(value)] -- inferred equivalent call

	if variantGroup then
		for _, v4 in ipairs(variantGroup) do
			if v4.name == value then
				continue
			end

			local animation = self.Animations[v4.name]

			if animation and animation.IsPlaying then
				animation:Stop(0)
			end
		end
	end

	local animation = self:getAnimation(value)

	if not animation then
		return nil
	end

	if not animation.IsPlaying then
		animation:Play(0, 1, 1)
		return animation
	end

	local v4 = math.max(animation.WeightCurrent, 0.5)
	local animation2 = animation.Animation
	local success, result

	if animation2 then
		success, result = pcall(function()
			return self.Animator:LoadAnimation(animation2)
		end)
	else
		success = false
		result = nil
	end

	if success and result then
		local v5 = connectTrackSoundEvents(self, result, value)
		result:Play(0, 0.01, 1)
		result.TimePosition = 0
		self.CrossfadeTempTrack = result
		local lastTime = tick()
		local bindingName = RunServiceController.CreateBindingName("Classes.Viewmodel.Animation.Crossfade")
		self.CrossfadeConnection = RunServiceController.BindToRenderStep(bindingName, function()
			if self.IsDestroyed then
				v5()
				self:cancelCrossfade()
			else
				local v6 = math.clamp((tick() - lastTime) / v3, 0, 1)
				local v7 = hermiteEaseOut(v6) -- inferred equivalent call
				animation:AdjustWeight(v4 * (1 - v7), 0)
				result:AdjustWeight(math.max(v7, 0.01), 0)

				if v6 >= 1 then
					v5()
					local timePosition = result.TimePosition
					animation:Stop(0)
					animation:Play(0, 1, 1)
					animation.TimePosition = timePosition
					animation:AdjustWeight(1, 0)
					self:cancelCrossfade()
				end
			end
		end)
		return animation
	else
		animation:Stop(0)
		animation:Play(0, 1, 1)
		return animation
	end
end

function Animation:crossfadeTo(p: string, value: number?)
	self:cancelCrossfade()
	local v3 = {}
	local v4 = value or 0.25

	for k, animation in pairs(self.Animations) do
		if animation.IsPlaying and k ~= "Idle" and k ~= p then
			table.insert(v3, { track = animation, startWeight = animation.WeightCurrent })
		end
	end

	local animation = self:getAnimation(p)
	local v5 = p == "Idle"

	if not (animation or v5) then
		return nil
	end

	if not v5 then
		animation:Play(0, 0, 1)
	end

	local lastTime = tick()
	local bindingName = RunServiceController.CreateBindingName("Classes.Viewmodel.Animation.Crossfade")
	self.CrossfadeConnection = RunServiceController.BindToRenderStep(bindingName, function()
		if self.IsDestroyed then
			self:cancelCrossfade()
			return
		end

		local v6 = math.clamp((tick() - lastTime) / v4, 0, 1)
		local v7 = hermiteEaseOut(1 - v6) -- inferred equivalent call

		for _, v8 in ipairs(v3) do
			v8.track:AdjustWeight(v8.startWeight * v7, 0)
		end

		if not v5 then
			animation:AdjustWeight(1 - v7, 0)
		end

		if v6 >= 1 then
			for _, v8 in ipairs(v3) do
				if v8.track.IsPlaying then
					v8.track:Stop(0)
				end
			end

			if v5 and animation then
				animation:Play(0, 1, 1)
			elseif animation then
				animation:AdjustWeight(1, 0)
			end

			self:cancelCrossfade()
		end
	end)
	return animation
end

function Animation:stopAnimations(value: number?)
	self:cancelCrossfade()

	for _, animation in pairs(self.Animations) do
		if animation.IsPlaying then
			animation:Stop(value or 0)
		end
	end

	self:stopSounds()
end

function Animation:stopSounds()
	for k, activeSound in pairs(self.ActiveSounds) do
		if not (not activeSound or string.find(activeSound, "Shoot") == nil) then
			continue
		end

		self.ActiveSounds[k] = nil

		if k and k.Parent then
			k:Destroy()
		end
	end
end

function Animation:unregister(p: string)
	local animation = self.Animations[p]

	if not animation then
		return
	end

	self.Janitor:Remove("AnimationSoundConnections_" .. p)
	self.Janitor:RemoveNoClean("AnimationCleanup_" .. p)
	self.Animations[p] = nil

	if animation.IsPlaying then
		animation:Stop()
	end

	animation:Destroy()
end

function Animation:register(p: string, animation)
	self:unregister(p)
	local success, result = pcall(function()
		return self.Animator:LoadAnimation(animation)
	end)

	if success then
		self.Animations[p] = result
		local object = setmetatable({}, { __mode = "v" })
		object.instance = self
		self.Janitor:Add(function()
			local instance = object.instance

			if instance and not instance.IsDestroyed then
				instance:unregister(p)
			end
		end, true, "AnimationCleanup_" .. p)
		self.Janitor:Add(connectTrackSoundEvents(self, result, p), true, "AnimationSoundConnections_" .. p)
	end
end

function Animation:construct()
	local weaponProperties = GetWeaponProperties(self.Animation)

	if not weaponProperties then
		return
	end

	local cameraAnimations = weaponProperties.CameraAnimations

	if typeof(cameraAnimations) ~= "Instance" or not cameraAnimations:IsA("Folder") then
		return
	end

	self.VariantGroups = {}

	for _, animation in ipairs(cameraAnimations:GetChildren()) do
		if not animation:IsA("Animation") then
			continue
		end

		self:register(animation.Name, animation)

		if not self.Animations[animation.Name] then
			continue
		end

		local variantBaseName = getVariantBaseName(animation.Name) -- inferred equivalent call
		local intValue = animation:FindFirstChildWhichIsA("IntValue") or animation:FindFirstChildWhichIsA("NumberValue")
		local variantGroup = self.VariantGroups[variantBaseName]

		if not variantGroup then
			variantGroup = {}
			self.VariantGroups[variantBaseName] = variantGroup
		end

		local v3 = { name = animation.Name, weight = 0 }
		local weight

		if intValue then
			weight = intValue.Value
		end

		v3.weight = weight
		table.insert(variantGroup, v3)
	end
end

function Animation:setModel(model)
	if not model then
		return
	end

	self.Animation = model.Name
	self.Model = model
	self.Animator = model:WaitForChild("AnimationController"):WaitForChild("Animator")
	self:stopAnimations()

	for k in table.clone(self.Animations) do
		self:unregister(k)
	end

	self.VariantGroups = {}
	self.Loaded = false
	preloadClips(model.Name)

	if self.Animation == "C4" then
		local interactive = model:FindFirstChild("Weapon") and model.Weapon:FindFirstChild("Interactive")

		if interactive and interactive:FindFirstChild("SurfaceGui") then
			interactive.SurfaceGui.TextLabel.Text = "*******"
		end
	end
end

function Animation:ensureLoaded()
	local model = self.Model

	if self.Loaded or self.IsDestroyed or not (model and self.Animator) then
		return
	end

	self.Loaded = true
	local v3 = not model:IsDescendantOf(game)
	local parent = model.Parent

	if v3 then
		model.Parent = ReplicatedFirst
	end

	self:construct()

	if v3 then
		model.Parent = parent
	end

	if self.Animation == "C4" then
		local interactive = model:FindFirstChild("Weapon") and model.Weapon:FindFirstChild("Interactive")

		for _, animation in pairs(self.Animations) do
			self.Janitor:Add(animation.KeyframeReached:Connect(function(name)
				if table.find(v, name) then
					if interactive and interactive:FindFirstChild("SurfaceGui") then
						interactive.SurfaceGui.TextLabel.Text = string.rep("*", 7 - #name) .. name
					end

					self.Sound:play({ Parent = LocalPlayer.PlayerGui, Name = name })
				end
			end))
		end
	end
end

function Animation.new(player, sound)
	local self = setmetatable({}, Animation)
	self.Janitor = Janitor.new()
	self.IsDestroyed = false
	self.Player = player
	self.ActiveSounds = {}
	self.Animations = {}
	self.VariantGroups = {}
	self.Sound = sound
	return self
end

function Animation:destroy()
	if not self.IsDestroyed then
		self.IsDestroyed = true
		self:stopAnimations()

		for k in pairs(self.Animations) do
			self:unregister(k)
		end

		self:stopSounds()
		table.clear(self.ActiveSounds)
		table.clear(self.Animations)
		table.clear(self.VariantGroups)
		self.Animation = nil
		self.Animator = nil
		self.Player = nil
		self.Sound = nil
		self.Janitor:Destroy()
		self.Janitor = nil
	end
end

return Animation