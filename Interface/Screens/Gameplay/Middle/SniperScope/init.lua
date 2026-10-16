local SniperScope = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Spring = require(ReplicatedStorage.Shared.Spring)
local v = Spring.new(1, 2.5, 1)
local v2 = Spring.new(0.85, 0.5, Vector2.zero)
local v3 = false
local now = 0
local v4 = nil
local bottom = nil
local top = nil

local function getMovementSpeed(instance) -- 2 equivalent calls inferred from this helper
	local velocity = RuntimeKinematics.getVelocity(instance, instance.PrimaryPart)
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude
end

local function isCharacterMoving(instance) -- 1 equivalent call inferred from this helper
	local velocity = RuntimeKinematics.getVelocity(instance, instance.PrimaryPart)
	return Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 0.1
end

local function isCharacterJumping(instance) -- 2 equivalent calls inferred from this helper
	return not RuntimeKinematics.isOnGround(instance)
end

function SniperScope.toggle(visible: boolean)
	v4.Visible = visible
	v4.Blur.Visible = true
	local zIndex = visible and 3 or 1
	local zIndex2 = visible and 4 or 2

	if bottom and bottom.Parent then
		bottom.ZIndex = zIndex
	end

	if top and top.Parent then
		top.ZIndex = zIndex2
	end

	if not visible then
		now = 0
		return
	end

	v:setPosition(1)
	v:setGoal(0)
	now = tick()
end

function SniperScope.updateMovementSharpness(instance, flag: boolean)
	local v5 = math.min(getMovementSpeed(instance), 3) / 3 -- inferred equivalent call
	local currentEquipped = InventoryController.getCurrentEquipped()
	local properties = currentEquipped and currentEquipped.Properties

	if properties then
		if
			currentEquipped.Properties.AimingOptions == "SniperScope"
			and currentEquipped.Properties.MuzzleType == "Sniper"
			and currentEquipped.Properties.Spread.Range.Min == 0
			and currentEquipped.Properties.Spread.PerShot == 0
		then
			properties = currentEquipped.Properties.Spread.MovementMultiplier == 2
		else
			properties = false
		end
	end

	local v6

	if properties and isCharacterJumping(instance) then -- inferred equivalent call
		v6 = math.abs(RuntimeKinematics.getVelocity(instance, instance.PrimaryPart).Y) <= 3
	else
		v6 = false
	end

	if flag then
		v:setPosition(1)
		v:setGoal(0)
		now = tick()
	elseif RuntimeKinematics.isOnGround(instance) then
		if v5 > 0.1 then
			v:setPosition(v5)
		elseif tick() - now > 1.2 then
			v:reset(0)
		end
	elseif properties and v6 then
		v:setPosition(0)
		v:setGoal(0)
	else
		v:setPosition(1)
	end
end

function SniperScope.updateScope(instance, _: number)
	if not CharacterResolver.isAliveCharacter(instance) then
		return
	end

	local characterJumping = isCharacterJumping(instance) -- inferred equivalent call
	local v5 = v3 and not characterJumping
	SniperScope.updateMovementSharpness(instance, v5)
	v3 = characterJumping

	if isCharacterMoving(instance) then -- inferred equivalent call
		local v6 = math.min(getMovementSpeed(instance), 3) -- inferred equivalent call
		local crouchState = CharacterController.GetCrouchState()
		local walkState = CharacterController.GetWalkState()
		local v7 = crouchState and 0.5 or walkState and 0.75 or 1
		v2:setPosition(Vector2.new(
			math.sin(tick() * 3.141592653589793 * 1.75 * v7),
			(math.sin(tick() * 3.141592653589793 * 2.75 * v7))
		) * v6 * 1.5)
		local position = v2:getPosition()
		v4.Position = UDim2.new(0.5, position.X, 0.5, position.Y)
	else
		v2:reset(Vector2.zero)
		v4.Position = UDim2.fromScale(0.5, 0.5)
	end

	v4.Blur.ImageTransparency = 1 - v:getPosition()
	v4.Sharp.ImageTransparency = v:getPosition()
end

function SniperScope.Initialize(_, p)
	v4 = p
	local parent = p.Parent and p.Parent.Parent

	if parent then
		bottom = parent:FindFirstChild("Bottom")
		top = parent:FindFirstChild("Top")

		if bottom then
			bottom.ZIndex = 1
		end

		if top then
			top.ZIndex = 2
		end
	end

	RunServiceController.BindToRenderStep("UI.SniperScope.Update", function(p2: number)
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true
		local character = LocalPlayer.Character

		if isSpectating or CharacterResolver.isAliveCharacter(character) then
			local currentEquipped = InventoryController.getCurrentEquipped()
			local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
			local v5 = false

			if isSpectating and currentSpectateInstance then
				if currentSpectateInstance.CurrentEquipped then
					local name = currentSpectateInstance.CurrentEquipped.Name

					if
						(name == "AWP" or name == "SSG 08")
						and currentSpectateInstance.PerspectiveState == "First-Person"
					then
						v5 = (currentSpectateInstance.Player:GetAttribute("ScopeIncrement") or 0) > 0
						character = currentSpectateInstance.Character
					end
				end
			else
				v5 = currentEquipped
					and currentEquipped.IsAiming
					and currentEquipped.Properties.AimingOptions == "SniperScope"
			end

			v:update(p2)
			v2:update(p2)

			if v5 and character then
				SniperScope.updateScope(character, p2)

				if not v4.Visible then
					SniperScope.toggle(true)
				end
			elseif v4.Visible then
				SniperScope.toggle(false)
			end
		elseif v4.Visible then
			SniperScope.toggle(false)
		end

		if not v4.Visible then
			if bottom and bottom.Parent then
				bottom.ZIndex = 1
			end

			if top and top.Parent then
				top.ZIndex = 2
			end
		end
	end)
end

return SniperScope