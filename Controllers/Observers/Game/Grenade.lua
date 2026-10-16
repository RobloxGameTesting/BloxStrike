local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GrenadeSimulator = require(ReplicatedStorage.Shared.GrenadeSimulator)
local Sound = require(ReplicatedStorage.Classes.Sound)
local Debris = workspace:WaitForChild("Debris")
local v = {}

local function hideAsDebris(folder)
	for _, part in ipairs(folder:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = "Debris"
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
	end
end

local function destroyAfter(instance, duration: number) -- 4 equivalent calls inferred from this helper
	task.delay(duration, function()
		if instance.Parent then
			instance:Destroy()
		end
	end)
end

local function spawnImpactParticles(maid, instance, position: Vector3, p: string?)
	local folder = maid:Add(instance:Clone())
	folder.CFrame = CFrame.new(position)
	folder.Parent = Debris
	folder.Anchored = true

	if p then
		Sound.new(p):playOneTime({ Parent = folder, Name = "Explode" })
	end

	for _, emitter in ipairs(folder:GetDescendants()) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		local v2 = emitter
		task.delay(emitter:GetAttribute("EmitDelay") or 0, function()
			v2:Emit(v2:GetAttribute("EmitCount") or 1)
		end)
	end
end

local v2 = {
	["Decoy Grenade"] = function(_, _, instance)
		hideAsDebris(instance)
		destroyAfter(instance, 0.5) -- inferred equivalent call
	end,
	Flashbang = function(p, p2, instance)
		hideAsDebris(instance)
		local flashbang = ReplicatedStorage.Assets.GrenadeParticles:FindFirstChild("Flashbang")

		if flashbang then
			spawnImpactParticles(p, flashbang, p2, nil)
		end

		destroyAfter(instance, 3) -- inferred equivalent call
	end,
	["HE Grenade"] = function(p, p2, instance)
		hideAsDebris(instance)
		spawnImpactParticles(p, ReplicatedStorage.Assets.GrenadeParticles["HE Grenade"], p2, "HE Grenade")
		destroyAfter(instance, 3) -- inferred equivalent call
	end
}

local function createRaycastParams(clone, collisionGroup: string?)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local localCharacters = { clone, Debris }
	local localCharacter = CharacterResolver.getLocalCharacter()

	if localCharacter then
		table.insert(localCharacters, localCharacter)
	end

	raycastParams.FilterDescendantsInstances = localCharacters
	raycastParams.RespectCanCollide = false
	raycastParams.IgnoreWater = true

	if collisionGroup then
		raycastParams.CollisionGroup = collisionGroup
	end

	return raycastParams
end

local function startClientPrediction(state) -- 1 equivalent call inferred from this helper
	local connection = nil
	connection = RunServiceController.BindToRenderStep(`Observers.Game.Grenade.{state.id}.Predict`, function(p)
		if state.isResolved then
			connection:Disconnect()
		elseif state.model.Parent then
			state.state = GrenadeSimulator.simulate(state.state, state.config, state.raycastParams, p).state
			local v3 = math.min(1, p * 20)
			state.visualPosition = state.visualPosition:Lerp(state.state.position, v3)
			local magnitude = state.state.velocity.Magnitude

			if magnitude < 2 then
				state.angularVelocity *= math.max(0, 1 - p * 8)
			elseif magnitude < 5 then
				state.angularVelocity *= math.max(0, 1 - p * 3)
			end

			if state.angularVelocity.Magnitude > 0.01 then
				local angularVelocity = state.angularVelocity
				local cframe = CFrame.fromAxisAngle(angularVelocity.Unit, angularVelocity.Magnitude * p)
				state.visualRotation *= cframe
			end

			if state.model.PrimaryPart then
				state.model:PivotTo(CFrame.new(state.visualPosition) * state.visualRotation)
			end
		else
			connection:Disconnect()
			state.isResolved = true
		end
	end)
	state.janitor:Add(connection, "Disconnect")
end

local function reconcileState(p, position: Vector3, velocity: Vector3)
	local magnitude = (p.state.position - position).Magnitude

	if magnitude > 8 then
		p.state.position = position
		p.state.velocity = velocity
		p.visualPosition = position
	elseif magnitude > 2 then
		p.state.position = p.state.position:Lerp(position, 0.08)
		p.state.velocity = p.state.velocity:Lerp(velocity, 0.08)
	end
end

Remotes.Projectile.Spawn.Listen(function(data)
	local id = data.Id
	local state = data.State
	local physics = data.Physics
	task.defer(function()
		local child = ReplicatedStorage.Assets.Weapons:FindFirstChild(data.Weapon)
		local character = child and child:FindFirstChild("Character")

		if not character then
			warn("[Client Grenade] Base model not found for:", data.Weapon)
			return
		end

		local clone = character:Clone()
		clone.Name = id
		clone:PivotTo(CFrame.new(state.Position))
		clone:SetAttribute("GrenadeName", data.Weapon)
		clone:AddTag("Grenade")
		clone.Parent = Debris

		for _, part in clone:GetDescendants() do
			if not part:IsA("BasePart") then
				continue
			end

			part.Anchored = true
			part.CanCollide = false
		end

		local janitor = Janitor.new()
		janitor:Add(clone, "Destroy")
		local state2 = {
			position = state.Position,
			velocity = state.Velocity,
			angularVelocity = createVector(0, 0, 0),
			timestamp = state.StartTime or workspace:GetServerTimeNow(),
			simulationTime = 0,
			bounceCount = 0,
			isGrounded = false,
			isAtRest = false,
			hasTouched = false,
			accumulatedTime = 0,
			isJumpThrow = state.IsJumpThrow or false
		}
		local v3 = data.Weapon == "Molotov" or data.Weapon == "Incendiary Grenade"
		local config = {
			radius = physics.Radius,
			restitution = physics.Restitution,
			maxBounces = physics.MaxBounces,
			fuseTime = 0,
			minimumFuseTime = 0,
			explodeOnFloorImpact = 0,
			rangeScale = 1,
			isNearThrow = false
		}
		local fuseTime

		if physics.FuseTime > 0 then
			fuseTime = physics.FuseTime
		end

		config.fuseTime = fuseTime
		config.minimumFuseTime = v3 and 0.1 or nil
		config.explodeOnFloorImpact = v3 and true or nil
		local velocity = state.Velocity
		local angularVelocity

		if velocity.Magnitude > 1 then
			local cross = velocity:Cross(createVector(0, 1, 0))
			angularVelocity = (not (cross.Magnitude > 0.1) and createVector(1, 0, 0) or cross.Unit) * velocity.Magnitude * 0.5
		else
			angularVelocity = createVector(0, 0, 0)
		end

		local v4 = {
			id = id,
			model = clone,
			state = state2,
			config = config,
			raycastParams = createRaycastParams(clone, physics.CollisionGroup),
			visualPosition = state.Position,
			visualRotation = CFrame.identity,
			angularVelocity = angularVelocity,
			isResolved = false,
			janitor = janitor
		}
		v[id] = v4
		startClientPrediction(v4) -- inferred equivalent call
	end)
end)
Remotes.Projectile.Bounce.Listen(function(data)
	local v3 = v[data.Id]

	if not v3 then
		return
	end

	reconcileState(v3, data.Position, data.Velocity)
	v3.state.bounceCount = data.BounceIndex
	v3.state.hasTouched = true
	local velocity = data.Velocity
	local vector = velocity - v3.state.velocity

	if vector.Magnitude > 1 then
		local cross = vector:Cross(velocity)
		local unit

		if cross.Magnitude > 0.1 then
			unit = cross.Unit
		else
			local cross2 = velocity:Cross(createVector(0, 1, 0))
			unit = not (cross2.Magnitude > 0.1) and createVector(1, 0, 0) or cross2.Unit
		end

		local v4 = unit * vector.Magnitude * 0.5
		v3.angularVelocity += v4
	end
end)
Remotes.Projectile.Resolve.Listen(function(p)
	local v3 = v[p.Id]

	if not v3 then
		return
	end

	v3.state.position = p.Position
	v3.state.isAtRest = true
	v3.isResolved = true
	v3.angularVelocity = createVector(0, 0, 0)

	if v3.model.PrimaryPart then
		v3.model:PivotTo(CFrame.new(p.Position) * v3.visualRotation)
	end

	v3.model:SetAttribute("SimulationFinished", true)
	v[p.Id] = nil
end)
return Observers.observeTag("Grenade", function(folder)
	local grenadeName = folder:GetAttribute("GrenadeName")

	if not grenadeName then
		return
	end

	local v3 = v2[grenadeName]
	local maid = Janitor.new()
	maid:Add(folder:GetAttributeChangedSignal("SimulationFinished"):Connect(function()
		local primaryPart = folder.PrimaryPart

		if not (primaryPart and folder:GetAttribute("SimulationFinished")) then
			return
		end

		if v3 then
			v3(maid, primaryPart.Position, folder)
			return
		end

		for _, part in folder:GetDescendants() do
			if not part:IsA("BasePart") then
				continue
			end

			part.Transparency = 1
			part.CanCollide = false
		end

		destroyAfter(folder, 0.5) -- inferred equivalent call
	end))
	return function()
		local v4 = v[folder.Name]

		if v4 then
			v4.isResolved = true
			v[folder.Name] = nil
		end

		maid:Destroy()
	end
end)