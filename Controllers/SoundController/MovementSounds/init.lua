local createVector = vector.create
local MovementSounds = {}
MovementSounds.__index = MovementSounds
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local Sound = require(ReplicatedStorage.Classes.Sound)
local Materials = require(ReplicatedStorage.Components.Common.VFXLibary.CreateImpact.Components.Materials)
local GetRayIgnore = require(ReplicatedStorage.Components.Common.GetRayIgnore)
local FlashEffect = require(ReplicatedStorage.Components.Common.VFXLibary.FlashEffect)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local v = {
	createVector(0, 0, 0),
	createVector(0.8, 0, 0),
	createVector(-0.8, 0, 0),
	createVector(0, 0, 0.8),
	createVector(0, 0, -0.8)
}
local v2 = {
	Concrete = "LandingConcrete",
	Brick = "LandingConcrete",
	Cobblestone = "LandingConcrete",
	Basalt = "LandingConcrete",
	Limestone = "LandingConcrete",
	Pavement = "LandingConcrete",
	Asphalt = "LandingConcrete",
	Rock = "LandingConcrete",
	Slate = "LandingConcrete",
	Granite = "LandingConcrete",
	Marble = "LandingConcrete",
	Pebble = "LandingConcrete",
	CeramicTiles = "LandingConcrete",
	Ground = "LandingDirt",
	Mud = "LandingDirt",
	Glass = "LandingGlass",
	Gravel = "LandingGravel",
	Rubber = "LandingRubber",
	Plastic = "LandingRubber",
	Sand = "LandingSand",
	Snow = "LandingSand",
	Grass = "LandingGrass",
	LeafyGrass = "LandingGrass",
	Metal = "LandingMetal",
	DiamondPlate = "LandingMetal",
	CorrodedMetal = "LandingMetal",
	["Corroded Metal"] = "LandingMetal",
	Wood = "Wood",
	WoodPlanks = "WoodPlanks",
	Fabric = "LandingDirt",
	Carpet = "LandingDirt",
	Cardboard = "LandingDirt"
}
local floorSounds = nil
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function GetFloorMaterial(p, position: Vector3, value: number?)
	local filterDescendantsInstances = GetRayIgnore()

	if not table.find(filterDescendantsInstances, p) then
		table.insert(filterDescendantsInstances, p)
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	local vector = Vector3.new(0, -(value or 3.1), 0)

	for _, v3 in ipairs(v) do
		local v4 = position + v3
		local raycastResult = workspace:Raycast(v4, vector, raycastParams)

		if raycastResult and raycastResult.Normal.Y > 0.7 then
			return raycastResult.Material.Name
		end
	end

	return "Air"
end

local function ResolveFloorMaterial(p, p2: string, flag: boolean, flag2: boolean)
	if p2 ~= "Air" then
		return p2
	end

	if not flag then
		return "Air"
	end

	if flag2 then
		local currentFloorMaterial = p.CurrentFloorMaterial

		if currentFloorMaterial and currentFloorMaterial ~= "" and currentFloorMaterial ~= "Air" then
			return currentFloorMaterial
		end
	end

	return "Concrete"
end

local function GetVolumeMultiplier(p, isCrouching: boolean?) -- 3 equivalent calls inferred from this helper
	return (isCrouching and 0.4 or 1) * (p.IsLocalPlayer and FlashEffect.GetAudioFadeMultiplier() or 1)
end

local function PlayFootstepSound(parent, childName: string, p: number)
	if not floorSounds or childName == "" or childName == "Air" then
		return nil
	end

	local name

	if floorSounds.Sounds and not floorSounds.Sounds:FindFirstChild(childName) then
		name = Materials[childName] or "Ground"
	else
		name = childName
	end

	if floorSounds.Sounds and not floorSounds.Sounds:FindFirstChild(name) then
		warn(string.format("[FloorSound] Missing sound for category: '%s' (material: %s)", name, childName))
		return nil
	else
		return floorSounds:play({ Parent = parent, Name = name }, p)
	end
end

local function StopFootstepSound(currentFootstepSound) -- 2 equivalent calls inferred from this helper
	if currentFootstepSound and currentFootstepSound.Playing then
		currentFootstepSound:Stop()
	end
end

local function ResetAirborneTracking(p) -- 3 equivalent calls inferred from this helper
	p.IsAirborne = false
	p.AirborneStartTime = 0
	p.PeakAirborneVelocityY = 0
end

local function BeginAirborneTracking(state, airborneStartTime: number, peakAirborneVelocityY: number)
	if state.IsAirborne then
		state.PeakAirborneVelocityY = math.min(state.PeakAirborneVelocityY, peakAirborneVelocityY)
		return
	end

	state.IsAirborne = true
	state.AirborneStartTime = airborneStartTime
	state.PeakAirborneVelocityY = peakAirborneVelocityY
end

local function ConsumeLandingWindow(player, now: number) -- 1 equivalent call inferred from this helper
	local v3 = not player.IsAirborne and 0 or now - player.AirborneStartTime
	local peakAirborneVelocityY = player.PeakAirborneVelocityY
	ResetAirborneTracking(player) -- inferred equivalent call
	return v3, peakAirborneVelocityY
end

local function PlayLandingSound(player, primaryPart, character, p: string?)
	local now = tick()

	if now - player.LastFloorSoundTime < 0.1 then
		return
	end

	player.LastFloorSoundTime = now
	local isCrouching = player.Player:GetAttribute("IsCrouching")
	local v3 = p or GetFloorMaterial(character, primaryPart.Position)
	local volumeMultiplier = GetVolumeMultiplier(player, isCrouching) -- inferred equivalent call
	PlayFootstepSound(primaryPart, v2[v3] or "LandingConcrete", volumeMultiplier)
end

local function PlayJumpSound(player, primaryPart, currentFloorMaterial: string)
	local now = tick()

	if now - player.LastFloorSoundTime < 0.1 then
		return
	end

	StopFootstepSound(player.CurrentFootstepSound) -- inferred equivalent call
	player.CurrentFootstepSound = nil
	player.LastFloorSoundTime = now
	local volumeMultiplier = GetVolumeMultiplier(player, player.Player:GetAttribute("IsCrouching")) -- inferred equivalent call
	PlayFootstepSound(primaryPart, "Jump", volumeMultiplier)
	PlayFootstepSound(primaryPart, currentFloorMaterial, volumeMultiplier)
end

function MovementSounds:SetCharacter(character)
	if character then
		local rootPart = CharacterResolver.getRootPart(character)

		if not (rootPart and character.Parent) then
			return
		end

		self.PrimaryPart = rootPart
		self.Character = character
		self.TimePassed = 0.25
		local _, _, _, v3, v4 = RuntimeKinematics.resolve(character, rootPart)
		self.IsAirborne = not v4
		self.AirborneStartTime = not self.IsAirborne and 0 or tick()
		self.PeakAirborneVelocityY = not self.IsAirborne and 0 or v3
	else
		StopFootstepSound(self.CurrentFootstepSound) -- inferred equivalent call
		self.CurrentFootstepSound = nil
		self.CurrentFloorMaterial = nil
		self.PrimaryPart = nil
		self.TimePassed = 0.25
		self.Character = nil
		ResetAirborneTracking(self) -- inferred equivalent call
	end
end

function MovementSounds:Update(p: number, _: Vector3?)
	local primaryPart = self.PrimaryPart
	local character = self.Character
	local player = self.Player

	if not (primaryPart and character and character.Parent and CharacterResolver.isAliveCharacter(character)) then
		return
	end

	local now = tick()
	local resolved, _, v3, _, v4 = RuntimeKinematics.resolve(character, primaryPart)

	if v4 then
		if self.IsAirborne then
			local position, v5 = RuntimeKinematics.getPosition(character, primaryPart)
			local floorMaterial = GetFloorMaterial(character, position, v5 and 3.1 or 6.2)
			local currentFloorMaterial = floorMaterial == "Air" and "Concrete" or floorMaterial
			self.CurrentFloorMaterial = currentFloorMaterial
			local v6, peakAirborneVelocityY = ConsumeLandingWindow(self, now) -- inferred equivalent call

			if v6 >= 0.08 and peakAirborneVelocityY <= -2.5 then
				PlayLandingSound(self, primaryPart, character, currentFloorMaterial)
			end
		end
	else
		if not self.IsAirborne and resolved.Y > 2 then
			local currentFloorMaterial = GetFloorMaterial(character, primaryPart.Position, 6.2)

			if currentFloorMaterial == "Air" then
				currentFloorMaterial = self.CurrentFloorMaterial or "Concrete"
			end

			PlayJumpSound(self, primaryPart, currentFloorMaterial)
		end

		local y = resolved.Y

		if self.IsAirborne then
			self.PeakAirborneVelocityY = math.min(self.PeakAirborneVelocityY, y)
		else
			self.IsAirborne = true
			self.AirborneStartTime = now
			self.PeakAirborneVelocityY = y
		end
	end

	local isCrouching = player:GetAttribute("IsCrouching")

	if player:GetAttribute("IsWalking") or isCrouching or player:GetAttribute("IsSniperScoped") == true then
		return
	end

	local v5 = isCrouching and 3.5 or 7.5
	local v6 = isCrouching and 0.55 or 0.3
	self.TimePassed += p

	if v6 <= self.TimePassed then
		self.TimePassed -= v6

		if now - self.LastFloorSoundTime < 0.1 then
			return
		end

		if v5 <= v3 then
			local currentFloorMaterial2 = GetFloorMaterial(character, primaryPart.Position, 3.1)

			if currentFloorMaterial2 == "Air" then
				if v4 then
					local currentFloorMaterial = self.CurrentFloorMaterial
					currentFloorMaterial2 = (not currentFloorMaterial or currentFloorMaterial == "" or currentFloorMaterial == "Air")
						and "Concrete"
						or currentFloorMaterial
				else
					currentFloorMaterial2 = "Air"
				end
			end

			if v4 then
				self.CurrentFloorMaterial = currentFloorMaterial2
			end

			self.LastFloorSoundTime = now
			self.CurrentFootstepSound = PlayFootstepSound(
				primaryPart,
				currentFloorMaterial2,
				GetVolumeMultiplier(self, isCrouching) -- inferred equivalent call
			)
		end
	end
end

function MovementSounds.new(player)
	local self = setmetatable({}, MovementSounds)
	self.IsLocalPlayer = player == LocalPlayer
	self.Player = player
	self.PrimaryPart = nil
	self.Character = nil
	self.TimePassed = 0.25
	self.CurrentFootstepSound = nil
	self.CurrentFloorMaterial = nil
	self.LastFloorSoundTime = 0
	ResetAirborneTracking(self) -- inferred equivalent call

	if not floorSounds then
		floorSounds = Sound.new("FloorSounds")
	end

	return self
end

return MovementSounds