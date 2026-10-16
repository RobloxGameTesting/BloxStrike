local Sound = {}
Sound.__index = Sound
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("DataController"))
require(script:WaitForChild("Types"))
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local ObjectPool = require(ReplicatedStorage.Shared.ObjectPool)
local sounds = ReplicatedStorage:FindFirstChild("Sounds") or Instance.new("Folder", ReplicatedStorage)
sounds.Name = "Sounds"
local Debris = workspace:WaitForChild("Debris")
local v = { Interface = true, ["Main Menu"] = true, Store = true, ArmsDealer = true }
local gameplaySoundGroup = SoundService:FindFirstChild("Gameplay")

if not gameplaySoundGroup then
	gameplaySoundGroup = Instance.new("SoundGroup")
	gameplaySoundGroup.Name = "Gameplay"
	gameplaySoundGroup.Parent = SoundService
end

local part = Instance.new("Part")
part.Size = vector.create(1, 1, 1)
part.CanCollide = false
part.CanTouch = false
part.CanQuery = false
part.CastShadow = false
part.Anchored = true
part.Transparency = 1
part.Name = "Sound"
local v2 = ObjectPool.new(part, {
	InitialSize = 8,
	MaxRetained = 32,
	Reset = function(p)
		p.CFrame = CFrame.identity
	end
})
local v3 = {}
local v4 = 1
local v5 = nil
local v6 = nil
local clones = {}
local v7 = {}

local function PickSound(child) -- 2 equivalent calls inferred from this helper
	local children = child:GetChildren()
	return children[math.random(1, #children)]
end

local function GetPersistentSoundsFolder()
	if v6 and v6.Parent then
		return v6
	end

	local selected = SoundService:FindFirstChild("PersistentSounds")

	if not selected then
		selected = Instance.new("Folder")
		selected.Name = "PersistentSounds"
		selected.Parent = SoundService
	end

	v6 = selected
	return selected
end

local function GetPersistentInstance(instance)
	local v8 = clones[instance]

	if v8 and v8:IsDescendantOf(game) then
		return v8
	end

	if v8 then
		v7[v8] = nil
	end

	local clone = instance:Clone()
	local parent

	if v6 and v6.Parent then
		parent = v6
	else
		parent = SoundService:FindFirstChild("PersistentSounds")

		if not parent then
			parent = Instance.new("Folder")
			parent.Name = "PersistentSounds"
			parent.Parent = SoundService
		end

		v6 = parent
	end

	clone.Parent = parent
	clones[instance] = clone
	return clone
end

local function ClaimPersistentPlay(clone) -- 2 equivalent calls inferred from this helper
	local v8 = (v7[clone] or 0) + 1
	v7[clone] = v8
	return v8
end

local function TranslateSoundPath(path: string)
	local v8 = string.split(path, ".")
	local game2 = game

	for i = 2, #v8 do
		local v9 = v8[i]

		if game2 == game then
			local success, result = pcall(function()
				return game:GetService(v9)
			end)
			game2 = success and result or game:FindFirstChild(v9)
		else
			game2 = game2:FindFirstChild(v9)
		end

		if not game2 then
			error(`Path: "{path}" does not exist`)
		end
	end

	return game2
end

local function CreateSoundInstance(name: string, identifier: string, properties)
	local sound = Instance.new("Sound")
	sound.RollOffMaxDistance = properties.RollOffMaxDistance or 10000
	sound.RollOffMinDistance = properties.RollOffMinDistance or 10
	sound.TimePosition = properties.TimePosition or 0
	sound.RollOffMode = Enum.RollOffMode.Inverse
	sound.Looped = properties.Looped or false
	sound.SoundId = `rbxassetid://{identifier}`
	sound.Volume = properties.Volume or 0.5
	sound.Name = name
	local pitch = properties.Pitch

	if typeof(pitch) == "number" and pitch ~= 1 then
		local pitchShiftSoundEffect = Instance.new("PitchShiftSoundEffect")
		pitchShiftSoundEffect.Name = "PitchShift"
		pitchShiftSoundEffect.Octave = math.clamp(pitch, 0.5, 2)
		pitchShiftSoundEffect.Parent = sound
	end

	if properties.Persistent then
		sound:SetAttribute("Persistent", true)
	end

	return sound
end

local function GetMasterVolumeMultiplier() -- 1 equivalent call inferred from this helper
	return (tonumber(DataController.Get(LocalPlayer, "Settings.Audio.Audio.Master Volume") or 100) or 100) / 100
end

local function ApplyTrackedVolume(instance, p) -- 2 equivalent calls inferred from this helper
	instance.Volume = p.BaseVolume * v4 * p.OtherMultiplier
	instance:SetAttribute("MasterVolumeMultiplier", v4)
end

local function EnsureMasterVolumeListener() -- 1 equivalent call inferred from this helper
	if v5 then
		return
	end

	v4 = GetMasterVolumeMultiplier() -- inferred equivalent call
	v5 = DataController.CreateListener(LocalPlayer, "Settings.Audio.Audio.Master Volume", function(p)
		v4 = (tonumber(p) or 100) / 100

		for k, v8 in pairs(v3) do
			if k.Parent then
				ApplyTrackedVolume(k, v8) -- inferred equivalent call
			else
				v3[k] = nil
			end
		end
	end)
end

local function TrackMasterVolume(instance, volume: number, value: number?)
	local otherMultiplier = value or 1
	local v8 = { BaseVolume = volume, OtherMultiplier = otherMultiplier }
	EnsureMasterVolumeListener() -- inferred equivalent call
	local v9 = v3[instance] == nil
	v3[instance] = v8
	instance:SetAttribute("BaseVolume", volume)
	instance:SetAttribute("OtherVolumeMultiplier", otherMultiplier)
	ApplyTrackedVolume(instance, v8) -- inferred equivalent call

	if v9 then
		instance.Destroying:Once(function()
			v3[instance] = nil
		end)
	end
end

function Sound:play(instance, p: number?)
	assert(instance.Parent or instance.Path, `Sound couldn't locate sound parent for {instance.Name}`)

	if not self.Sounds then
		return nil
	end

	local child = self.Sounds:FindFirstChild(instance.Name)

	if not child then
		return
	end

	local guid = HttpService:GenerateGUID(false)
	local parent = instance.Parent

	if instance.Path and not parent then
		parent = TranslateSoundPath(instance.Path)
	end

	if not parent then
		return nil
	end

	local pickSound = PickSound(child) -- inferred equivalent call

	if pickSound:GetAttribute("Persistent") == true then
		local clone = clones[pickSound]

		if not (clone and clone:IsDescendantOf(game)) then
			if clone then
				v7[clone] = nil
			end

			clone = pickSound:Clone()
			local parent2

			if v6 and v6.Parent then
				parent2 = v6
			else
				parent2 = SoundService:FindFirstChild("PersistentSounds")

				if not parent2 then
					parent2 = Instance.new("Folder")
					parent2.Name = "PersistentSounds"
					parent2.Parent = SoundService
				end

				v6 = parent2
			end

			clone.Parent = parent2
			clones[pickSound] = clone
		end

		if not clone.IsPlaying then
			local claimPersistentPlay = ClaimPersistentPlay(clone) -- inferred equivalent call
			clone.Parent = parent
			clone.TimePosition = 0
			TrackMasterVolume(clone, pickSound.Volume, p)
			clone:Play()
			clone.Ended:Once(function()
				if v7[clone] == claimPersistentPlay then
					local v8 = clone
					local parent2

					if v6 and v6.Parent then
						parent2 = v6
					else
						parent2 = SoundService:FindFirstChild("PersistentSounds")

						if not parent2 then
							parent2 = Instance.new("Folder")
							parent2.Name = "PersistentSounds"
							parent2.Parent = SoundService
						end

						v6 = parent2
					end

					v8.Parent = parent2
				end
			end)
			return clone
		end
	end

	local clone = pickSound:Clone()
	clone.Parent = parent
	clone.Name = guid
	TrackMasterVolume(clone, clone.Volume, p)
	clone:Play()
	clone.Ended:Once(function()
		clone:Destroy()
	end)
	return clone
end

function Sound:playOneTime(p, p2: number?)
	return self:play(p, p2)
end

function Sound:PlaySoundAtPosition(p, duration: number?, p2: number?, flag: boolean?, flag2: boolean?)
	if self.IsDestroyed then
		return
	end

	local child = self.Sounds and self.Sounds:FindFirstChild(p.Name)

	if not child then
		self:destroy()
		return
	end

	local parent, v8 = v2:Acquire()
	self.Janitor:Add(function()
		v2:Release(parent, v8)
	end)
	parent.Position = p.Position
	parent.CollisionGroup = "Debris"
	parent.Parent = Debris
	local v9 = self.Janitor:Add(PickSound(child):Clone()) -- inferred equivalent call
	local volume = v9.Volume
	v9.Name = HttpService:GenerateGUID(false)
	v9.Parent = parent

	if (p.Name == "Headshot" or p.Name == "Helmet Headshot") and flag then
		v9.RollOffMode = Enum.RollOffMode.InverseTapered
		v9.RollOffMaxDistance = 10000
		v9.RollOffMinDistance = 10000

		if flag2 then
			volume *= 0
		end
	end

	TrackMasterVolume(v9, volume, p2)
	v9:Play()

	if v9.Looped and duration then
		self.Janitor:Add(task.delay(duration, function()
			self:destroy()
		end), true)
	else
		self.Janitor:Add(v9.Ended:Once(function()
			self:destroy()
		end))
	end

	self.Janitor:Add(v9.AncestryChanged:Connect(function()
		if not v9.Parent then
			self:destroy()
		end
	end))
end

Sound.GameplaySoundGroup = gameplaySoundGroup

function Sound.WarmPersistentSounds()
	for _, sound in sounds:GetDescendants() do
		if not (sound:IsA("Sound") and sound:GetAttribute("Persistent") == true) then
			continue
		end

		local clone = clones[sound]

		if not (clone and clone:IsDescendantOf(game)) then
			if clone then
				v7[clone] = nil
			end

			clone = sound:Clone()
			local parent

			if v6 and v6.Parent then
				parent = v6
			else
				parent = SoundService:FindFirstChild("PersistentSounds")

				if not parent then
					parent = Instance.new("Folder")
					parent.Name = "PersistentSounds"
					parent.Parent = SoundService
				end

				v6 = parent
			end

			clone.Parent = parent
			clones[sound] = clone
		end

		local claimPersistentPlay = ClaimPersistentPlay(clone) -- inferred equivalent call
		pcall(function()
			ContentProvider:PreloadAsync({ clone })
		end)

		if v7[clone] ~= claimPersistentPlay or clone.IsPlaying then
			continue
		end

		clone.Volume = 0
		clone:Play()
		local v8 = clone
		local v9 = sound
		task.delay(0.5, function()
			if v7[v8] == claimPersistentPlay then
				v8:Stop()
				v8.TimePosition = 0
				v8.Volume = v9.Volume
			end
		end)
	end
end

function Sound.createSoundGroup(moduleScript)
	local module = require(moduleScript)
	local folder = Instance.new("Folder", sounds)
	folder.Name = moduleScript.Name
	local soundGroup

	if not v[moduleScript.Name] then
		soundGroup = gameplaySoundGroup
	end

	for k, v8 in pairs(module) do
		if not (typeof(v8) == "table" and typeof(v8.Identifiers) == "table") then
			continue
		end

		local folder2 = Instance.new("Folder", folder)
		folder2.Name = k

		for i, identifier in ipairs(v8.Identifiers) do
			local soundInstance = CreateSoundInstance(i, identifier, v8.Properties)
			soundInstance.SoundGroup = soundGroup
			soundInstance.Parent = folder2
		end
	end
end

function Sound.new(soundGroupName: string)
	local self = setmetatable({}, Sound)
	self.Janitor = Janitor.new()
	self.IsDestroyed = false
	self.SoundGroupName = soundGroupName
	self.Sounds = sounds:WaitForChild(soundGroupName, 10)
	return self
end

function Sound:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true
	self.Janitor:Destroy()
	self.SoundGroupName = nil
	self.Janitor = nil
	self.Sounds = nil
end

return Sound