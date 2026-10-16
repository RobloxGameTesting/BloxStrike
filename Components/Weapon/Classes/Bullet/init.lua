local createVector = vector.create
local Bullet = {}
Bullet.__index = Bullet
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local RunServiceController = require(ReplicatedStorage:WaitForChild("Controllers"):WaitForChild("RunServiceController"))
local LocalPlayer = Players.LocalPlayer
local GetRayIgnore = require(ReplicatedStorage.Components.Common.GetRayIgnore)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Raycast = require(ReplicatedStorage.Shared.Raycast)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Spring = require(ReplicatedStorage.Shared.Spring)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local castThroughDistance = Raycast.castThroughDistance
local CurrentCamera = workspace.CurrentCamera
local min = math.min
local rad = math.rad
local max = math.max
local abs = math.abs

local function getSpreadConfig(p) -- 11 equivalent calls inferred from this helper
	return p.ActiveSpreadConfig or p.Properties.Spread
end

local function getCharacterSpeedForSpread(p) -- 1 equivalent call inferred from this helper
	if p.CharacterSpeed >= 6.4 then
		return p.CharacterSpeed
	end

	return 0
end

local function getRawBaseSpread(p) -- 4 equivalent calls inferred from this helper
	local position = p.Spread:getPosition()

	if type(position) == "number" then
		return position
	end

	return 0
end

local function clampBaseSpreadForConfig(value: number, p) -- 2 equivalent calls inferred from this helper
	if p then
		return (math.clamp(value, p.Range.Min, p.Range.Max))
	end

	return value
end

local function getNoScopeMinSpread(p) -- 2 equivalent calls inferred from this helper
	local movementMultiplier = p and p.MovementMultiplier or 1

	if movementMultiplier == 2 then
		return 6
	elseif movementMultiplier == 3 then
		return 12
	end

	return 15
end

local function resetMovementSpreadState(p) -- 3 equivalent calls inferred from this helper
	p.CharacterSpeed = 0
	p.isInAir = false
	p.jumpStartSpeed = nil
	p.verticalVelocity = 0
	p.isAtJumpPeak = false
end

local function updateCharacterSpeed(state)
	local localCharacter = CharacterResolver.getLocalCharacter()

	if localCharacter then
		local primaryPart = localCharacter.PrimaryPart
		local resolved, _, characterSpeed, verticalVelocity, v = RuntimeKinematics.resolve(localCharacter, primaryPart)
		state.verticalVelocity = verticalVelocity
		local isInAir = state.isInAir
		state.isInAir = not v
		local properties = state.Properties
		local spreadConfig = getSpreadConfig(state) -- inferred equivalent call
		local range = spreadConfig and spreadConfig.Range
		local min2 = range and range.Min
		local perShot = spreadConfig and spreadConfig.PerShot
		local movementMultiplier = spreadConfig and spreadConfig.MovementMultiplier
		local v2

		if
			properties.AimingOptions == "SniperScope"
			and properties.MuzzleType == "Sniper"
			and min2 == 0
			and perShot == 0
		then
			v2 = movementMultiplier == 2
		else
			v2 = false
		end

		state.isAtJumpPeak = v2 and state.isInAir and math.abs(state.verticalVelocity) <= 3

		if state.isInAir and not isInAir then
			local jumpShotMinimum = spreadConfig and spreadConfig.JumpShotMinimum or 100
			state.jumpStartSpeed = resolved.Magnitude + jumpShotMinimum
		elseif not state.isInAir and isInAir then
			state.jumpStartSpeed = nil
			state.isAtJumpPeak = false
		end

		if not (state.isInAir and state.jumpStartSpeed) then
			state.CharacterSpeed = resolved.Magnitude
		elseif v2 and state.isAtJumpPeak then
			state.CharacterSpeed = characterSpeed
		else
			state.CharacterSpeed = state.jumpStartSpeed
		end
	else
		resetMovementSpreadState(state) -- inferred equivalent call
	end
end

local function isSpreadSettled(p)
	local position = p.Spread:getPosition()
	local goal = p.Spread:getGoal()
	local velocity = p.Spread:getVelocity()

	if type(position) ~= "number" or type(goal) ~= "number" or type(velocity) ~= "number" then
		return false
	end

	return math.abs(position - goal) <= 0.001 and math.abs(velocity) <= 0.001
end

local function stopSpreadRecovery(p) -- 2 equivalent calls inferred from this helper
	if p.SpreadRecoveryConnection then
		p.SpreadRecoveryConnection:Disconnect()
		p.SpreadRecoveryConnection = nil
	end
end

local function ensureSpreadRecovery(object) -- 1 equivalent call inferred from this helper
	if object.IsDestroyed or object.SpreadRecoveryConnection then
		return
	end

	object.SpreadRecoveryConnection = RunServiceController.BindToStepped(
		`{object.BindingName}.SpreadRecovery`,
		function(_: number, p: number)
			object:updateSpread(p)
		end
	)
end

function Bullet:_performRaycast(p: number)
	local rayIgnore = GetRayIgnore()
	local v = CurrentCamera.ViewportSize * 0.5
	local viewportPointToRay = CurrentCamera:ViewportPointToRay(v.X, v.Y)
	local v2 = min(p, 69)
	local v3 = math.floor(os.clock() * 1000000 % 2147483647)
	local random = Random.new(v3)
	local v4 = {
		Theta = random:NextNumber(-3.141592653589793, 3.141592653589793),
		Phi = random:NextNumber(0, (rad(v2 * 0.5)))
	}
	local direction = viewportPointToRay.Direction
	local unit = direction.Magnitude > 0 and direction.Unit or createVector(0, 0, 1)
	local v5 = abs(unit.Y) > 0.9999 and createVector(1, 0, 0) or createVector(0, 1, 0)
	local cframe = CFrame.lookAlong(createVector(0, 0, 0), unit, v5)
	local cframe2 = CFrame.Angles(0, 0, v4.Theta)
	local cframe3 = CFrame.Angles(v4.Phi, 0, 0)
	local lookVector = (cframe * cframe2 * cframe3).LookVector
	local origin = viewportPointToRay.Origin
	local penetration = self.Properties.Penetration or 0
	local range = self.Properties.Range or 500
	local v6 = { Origin = origin, Direction = lookVector, Distance = 0, Hits = {} }
	local v7 = castThroughDistance(origin, lookVector * range, penetration, rayIgnore)
	local v8 = v7[1]

	if not v8 then
		v6.Distance = range
		return v6
	end

	v6.Distance = (v8.position - origin).Magnitude
	local hits = v6.Hits

	for i = 1, #v7 do
		local v9 = v7[i]

		if v9.instance and v9.material then
			hits[#hits + 1] = {
				Position = v9.position,
				Instance = v9.instance,
				Material = v9.material.Name,
				Normal = v9.normal or createVector(0, 0, 0),
				Exit = i % 2 == 0
			}
		end
	end

	return v6
end

function Bullet:setSpreadConfig(activeSpreadConfig)
	local spreadConfig = getSpreadConfig(self) -- inferred equivalent call
	self.ActiveSpreadConfig = activeSpreadConfig
	local spreadConfig2 = getSpreadConfig(self) -- inferred equivalent call
	assert(spreadConfig2, "Weapon properties missing spread configuration")
	self.Spread:setFrequency(spreadConfig2.RecoverySpeed)

	if spreadConfig == spreadConfig2 then
		return
	end

	local v = math.clamp(getRawBaseSpread(self), spreadConfig2.Range.Min, spreadConfig2.Range.Max) -- inferred equivalent call
	self.Spread:reset(v)
	self.Spread:setGoal(spreadConfig2.Range.Min)
end

function Bullet:create(p: string?, flag: boolean?)
	self.LastShotTick = tick()

	if p == "SniperScope" and not flag then
		local noScopeMinSpread = getNoScopeMinSpread(getSpreadConfig(self)) -- inferred equivalent call

		if getRawBaseSpread(self) < noScopeMinSpread then -- inferred equivalent call
			self.Spread:setPosition(noScopeMinSpread)
		end
	end

	local weapon = self.Weapon
	local v

	if p == "SniperScope" and flag and weapon.Name == "AWP" and tick() - (weapon.ScopeStartTick or 0) < 0.2 then
		v = false
	else
		v = flag
	end

	local trueSpread = self:getTrueSpread()

	if flag and not v then
		trueSpread = max(trueSpread, getNoScopeMinSpread(getSpreadConfig(self))) -- inferred equivalent call
	end

	self:_updateShotSpread(p, v)
	return self:_performRaycast(trueSpread)
end

function Bullet:getTrueSpread()
	return self:getSpreadForConfig(getSpreadConfig(self)) -- inferred equivalent call
end

function Bullet.getBaseSpread(p)
	local position = p.Spread:getPosition()

	if type(position) == "number" then
		return position
	end

	return 0
end

function Bullet:getBaseSpreadForConfig(p)
	local v = p or getSpreadConfig(self) -- inferred equivalent call
	local rawBaseSpread = getRawBaseSpread(self) -- inferred equivalent call
	return clampBaseSpreadForConfig(rawBaseSpread, v) -- inferred equivalent call
end

function Bullet:getMovementSpreadForConfig(p)
	local characterSpeedForSpread = getCharacterSpeedForSpread(self) -- inferred equivalent call
	local v = p or getSpreadConfig(self) -- inferred equivalent call
	return characterSpeedForSpread * (not v and 1 or v.MovementMultiplier)
end

function Bullet:getSpreadForConfig(p)
	local v = p or getSpreadConfig(self) -- inferred equivalent call
	return self:getBaseSpreadForConfig(v) + self:getMovementSpreadForConfig(v)
end

function Bullet.setBaseSpreadForConfig(p, p2: number, p3)
	local v = p3 or getSpreadConfig(p) -- inferred equivalent call
	assert(v, "Weapon properties missing spread configuration")
	local spread = p.Spread
	p2 = clampBaseSpreadForConfig(p2, v) -- inferred equivalent call
	spread:setPosition(p2)
end

function Bullet:updateSpread(p: number)
	self.Spread:update(p)

	if not self.IsActive and isSpreadSettled(self) then
		self.Spread:reset(self.Spread:getGoal())
		stopSpreadRecovery(self) -- inferred equivalent call
	end
end

function Bullet:setActive(isActive: boolean)
	if self.IsDestroyed or self.IsActive == isActive then
		return
	end

	self.IsActive = isActive

	if isActive then
		updateCharacterSpeed(self)
		ensureSpreadRecovery(self) -- inferred equivalent call
		self.CharacterSpeedConnection = RunServiceController.BindToHeartbeat(
			`{self.BindingName}.CharacterSpeed`,
			function()
				updateCharacterSpeed(self)
			end
		)
	else
		if self.CharacterSpeedConnection then
			self.CharacterSpeedConnection:Disconnect()
			self.CharacterSpeedConnection = nil
		end

		resetMovementSpreadState(self) -- inferred equivalent call
	end
end

function Bullet:_updateShotSpread(p: string?, flag: boolean?)
	local spreadConfig = getSpreadConfig(self) -- inferred equivalent call
	assert(spreadConfig, "Weapon properties missing spread configuration")
	local range = spreadConfig.Range
	local min2 = range.Min
	local max2 = range.Max

	if p == "SniperScope" then
		if flag then
			min2 = 0
		else
			local v = not spreadConfig and 1 or spreadConfig.MovementMultiplier or 1
			min2 = v == 2 and 6 or v == 3 and 12 or 15
		end
	end

	local v = math.clamp(getRawBaseSpread(self) + spreadConfig.PerShot, min2, max2) -- inferred equivalent call
	self.Spread:setPosition(v)
end

function Bullet.new(weapon, properties)
	local self = setmetatable({}, Bullet)
	self.Janitor = Janitor.new()
	self.IsDestroyed = false
	self.Properties = properties
	self.Weapon = weapon
	resetMovementSpreadState(self) -- inferred equivalent call
	local spread = properties.Spread
	assert(spread, "Weapon properties missing spread configuration")
	self.Spread = Spring.new(1, spread.RecoverySpeed, spread.Range.Min)
	self.LastShotTick = 0
	self.IsActive = false
	self.BindingName = RunServiceController.CreateBindingName("Components.Bullet")
	return self
end

function Bullet:destroy()
	if self.IsDestroyed then
		return
	end

	self:setActive(false)
	stopSpreadRecovery(self) -- inferred equivalent call
	self.IsDestroyed = true
	self.Janitor:Destroy()
	self.Properties = nil
	self.Weapon = nil
	self.Spread = nil
	self.Janitor = nil
end

return Bullet