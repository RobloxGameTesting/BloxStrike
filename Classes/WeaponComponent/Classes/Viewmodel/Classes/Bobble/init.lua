local createVector = vector.create
local Bobble = {}
Bobble.__index = Bobble
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script:WaitForChild("Types"))
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Spring = require(ReplicatedStorage.Shared.Spring)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local CurrentCamera = workspace.CurrentCamera
local v = Vector2.new(0.02, 0.015) / 50

local function removeY(vector: Vector3) -- 2 equivalent calls inferred from this helper
	return vector * createVector(1, 0, 1)
end

local function toVector3(point: Vector2) -- 2 equivalent calls inferred from this helper
	return (Vector3.new(point.X, point.Y, 0))
end

local function toggleScopeVisibility(folder, enabled: boolean)
	for _, descendant in pairs(folder:GetDescendants()) do
		if descendant:IsA("MeshPart") then
			descendant.Transparency = enabled == true and 0 or 1
		elseif descendant:IsA("SurfaceGui") then
			descendant.Enabled = enabled
		end
	end
end

local function applySkinToScope(instance, weapon)
	if instance.ClassName ~= "Model" or weapon.ClassName ~= "Model" then
		return
	end

	local function clearSurfaceAppearances(child)
		for _, child2 in pairs(child:GetChildren()) do
			if child2.ClassName == "SurfaceAppearance" then
				child2:Destroy()
			end
		end
	end

	for _, child in pairs(instance:GetChildren()) do
		local child2 = weapon:FindFirstChild(child.Name)

		if not child2 then
			continue
		end

		local surfaceAppearance = child2:FindFirstChildWhichIsA("SurfaceAppearance")

		if not surfaceAppearance then
			continue
		end

		local clone = surfaceAppearance:Clone()
		clone.Name = child2.Name
		clearSurfaceAppearances(child)
		clone.Parent = child
	end
end

function Bobble.addScopeKick(p)
	if p.IsDestroyed or not p.ScopeSpring then
		return
	end

	p.ScopeSpring:impulse(Vector2.new(5, 1))
end

function Bobble:getMovementVelocity()
	local character = self.Character

	if not character then
		self.IsInAir = false
		return createVector(0, 0, 0), createVector(0, 0, 0)
	end

	local resolved, _, _, _, v2 = RuntimeKinematics.resolve(character, character.PrimaryPart)
	self.IsInAir = not v2

	if resolved.Magnitude > 0.1 then
		local v3 = resolved.Unit * math.min(resolved.Magnitude, 50)
		return v3, CurrentCamera.CFrame:VectorToObjectSpace(v3)
	else
		return createVector(0, 0, 0), createVector(0, 0, 0)
	end
end

function Bobble:getNextCFrame(p: number)
	if self.IsDestroyed then
		return CFrame.identity, createVector(0, 0, 0), createVector(0, 0, 0)
	end

	local v2 = (p <= 0 or p ~= p) and 1 / 60 or p
	local movementVelocity, v3 = self:getMovementVelocity()
	local v4 = removeY(movementVelocity) -- inferred equivalent call
	local v5 = removeY(v3) -- inferred equivalent call
	local magnitude = movementVelocity.Magnitude
	local magnitude2 = v4.Magnitude
	local cframe = CurrentCamera.CFrame
	local orientation, v6, _ = cframe:ToObjectSpace(self.LastCameraCFrame):ToOrientation()
	local v7 = Vector2.new(orientation, v6) / v2
	local v8 = v2 * magnitude * 0.1
	local renderTime = self.RenderTime + v8
	local v9 = createVector(0.0011111111, 0.0011111111, 0) * Vector3.new(v7.Y, -v7.X, 0)
	local v10 = v9 ~= v9 and createVector(0, 0, 0) or v9
	local v11 = createVector(0.0004, 0.0007, 0.0011) * Vector3.new(
		v5.X,
		-magnitude2,
		(math.max(math.abs(v5.X), (math.abs(v3.Z))))
	)
	local v12 = Vector2.new(
		math.sin(renderTime * 3.141592653589793 * 2),
		(math.sin(renderTime * 3.141592653589793 * 4))
	) * (v * 0.5) * magnitude2

	if self.IsInAir then
		v11 += createVector(0, -0.02, 0)
		v12 *= 0.3
	end

	self.MovementShiftSpring:setGoal(v11)
	self.CameraShiftSpring:setGoal(v10)
	self.BobbleSpring:setGoal(v12)
	self.ScopeSpring:setGoal(Vector2.zero)
	self.MovementShiftSpring:update(v2)
	self.CameraShiftSpring:update(v2)
	self.BobbleSpring:update(v2)
	self.ScopeSpring:update(v2)
	self.LastCameraCFrame = cframe
	self.RenderTime = renderTime
	local position = self.MovementShiftSpring:getPosition()
	local position2 = self.CameraShiftSpring:getPosition()
	local vector3 = toVector3(self.BobbleSpring:getPosition()) -- inferred equivalent call
	local position3 = self.ScopeSpring:getPosition()
	local v13 = math.rad(-position.X * 250)
	local v14

	if self.IsAiming then
		v14 = 0.08726646259971647
		v13 = 0
	else
		v14 = 0
	end

	local v15 = position + position2 + vector3
	local v16 = vector3 + position
	local vector3_2 = toVector3(position3) -- inferred equivalent call
	return CFrame.new(v15) * CFrame.Angles(0, v14, v13), v16, vector3_2
end

function Bobble:setIsAiming(isAiming: boolean)
	self.IsAiming = isAiming
	toggleScopeVisibility(self.Scope, isAiming)
	toggleScopeVisibility(self.ScopeReticlePart, isAiming)
end

function Bobble:setModel(instance)
	if not instance then
		return
	end

	if self.Scope then
		self.Scope:Destroy()
		self.Scope = nil
	end

	if self.ScopeReticlePart then
		self.ScopeReticlePart:Destroy()
		self.ScopeReticlePart = nil
	end

	local name = instance.Name

	if name == "AUG" or name == "SG 553" then
		local weapon = instance:FindFirstChild("Weapon")

		if weapon and weapon:FindFirstChild("ScopeSplit") then
			local scopeSplit = weapon.ScopeSplit
			local part = scopeSplit:FindFirstChild("Part")

			if part then
				self.ScopeReticlePart = self.Janitor:Add(part:Clone())
				self.ScopeReticlePart.Parent = CurrentCamera
			end

			local scope = self.Janitor:Add(scopeSplit:Clone())
			self.Scope = scope
			scope.Parent = CurrentCamera
			toggleScopeVisibility(scope, false)

			if name == "AUG" then
				local part2 = scope:FindFirstChild("Part")
				local surfaceGui = part2 and part2:FindFirstChild("SurfaceGui")
				local surfaceGuiFrame = surfaceGui and surfaceGui:FindFirstChild("Frame")

				if surfaceGuiFrame then
					surfaceGuiFrame.Visible = false
				end
			end

			applySkinToScope(scope, weapon)
			scopeSplit:Destroy()
		end
	end
end

function Bobble.new(player)
	local object = setmetatable({}, Bobble)
	object.Janitor = Janitor.new()
	object.IsDestroyed = false
	object.Character = player.Character or CharacterResolver.getPlayerCharacter(player.Player)
	object.IsAiming = false
	object.CameraShiftSpring = Spring.new(0.7, 18, createVector(0, 0, 0))
	object.MovementShiftSpring = Spring.new(1, 15, createVector(0, 0, 0))
	object.BobbleSpring = Spring.new(1, 20, Vector2.zero)
	object.ScopeSpring = Spring.new(1, 20, Vector2.zero)
	object.LastCameraCFrame = CurrentCamera.CFrame
	object.RenderTime = 0
	object.IsInAir = false

	if not player.Character then
		object.Janitor:Add(CharacterResolver.observeCharacter(player.Player, function(character)
			object.Character = character
			return function() end
		end))
	end

	return object
end

function Bobble:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true
	self.Janitor:Destroy()
	self.Janitor = nil
	self.CameraShiftSpring = nil
	self.MovementShiftSpring = nil
	self.BobbleSpring = nil
	self.ScopeSpring = nil
	self.Character = nil
	self.Scope = nil
	self.ScopeReticlePart = nil
end

return Bobble