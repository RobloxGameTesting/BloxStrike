local createVector = vector.create
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local PartMultipliers = require(script.Parent.Configuration.PartMultipliers)
local RigConfiguration = require(script.Parent.Configuration.RigConfiguration)
local Rig = {}
local BodyParts = RigConfiguration.BodyParts
local JointOrder = RigConfiguration.JointOrder
local Joints = RigConfiguration.Joints
local Colliders = RigConfiguration.Colliders
local NoCollisionPairs = RigConfiguration.NoCollisionPairs
local object = setmetatable({}, { __mode = "k" })
local object2 = setmetatable({}, { __mode = "k" })

local function profileScope(p: string, fn) -- 11 equivalent calls inferred from this helper
	debug.profilebegin(p)
	local success, result = pcall(fn)
	debug.profileend()

	if not success then
		error(result, 0)
	end

	return result
end

local function isBodyMotor(folder, motor6D)
	local part0 = motor6D.Part0
	local part1 = motor6D.Part1
	local v

	if part0 == nil or part1 == nil or part0.Parent ~= folder or part1.Parent ~= folder then
		return false
	else
		v = not (part0:HasTag("CharacterAccessory") or part1:HasTag("CharacterAccessory"))

		if v then
			if part0.Name == "CameraPart" then
				return false
			else
				return part1.Name ~= "CameraPart"
			end
		end
	end

	return v
end

local function collectBodyMotors(folder)
	local motor6DsByName = {}

	for _, motor6D in folder:GetDescendants() do
		if not (motor6D:IsA("Motor6D") and Joints[motor6D.Name] ~= nil and motor6DsByName[motor6D.Name] == nil and isBodyMotor(folder, motor6D)) then
			continue
		end

		motor6DsByName[motor6D.Name] = motor6D
	end

	local result = {}

	for _, v in JointOrder do
		if not motor6DsByName[v] then
			table.insert(result, v)
		end
	end

	return motor6DsByName, result
end

local function resolveBodyMotors(p) -- 1 equivalent call inferred from this helper
	debug.profilebegin("Ragdoll.Prepare.ResolveMotors")
	local v, v2 = collectBodyMotors(p)
	debug.profileend()
	return v, v2
end

local function waitForBodyMotors(parent)
	local v = os.clock() + 3
	local bodyMotors, v2 = resolveBodyMotors(parent) -- inferred equivalent call

	while #v2 > 0 and parent.Parent and os.clock() < v do
		task.wait(0.05)
		debug.profilebegin("Ragdoll.Prepare.ResolveMotors")
		bodyMotors, v2 = collectBodyMotors(parent)
		debug.profileend()
	end

	return bodyMotors, v2
end

local function configurePreparedBodyPart(instance, instance2)
	local hasTag = instance2:HasTag("CharacterAccessory")
	local v = instance2.Name == "HumanoidRootPart" or instance2.Name == "CameraPart"
	local ragdollCollider = instance2:GetAttribute("RagdollCollider") == true
	local v2

	if instance2.Parent == instance then
		v2 = BodyParts[instance2.Name]
	end

	instance2.Anchored = instance2.Parent == instance and not hasTag
	instance2.CanCollide = false
	instance2.CanQuery = false
	instance2.CanTouch = false
	instance2.CollisionGroup = "Debris"

	if ragdollCollider or hasTag or v or v2 == nil then
		instance2.Massless = true
	else
		instance2.Massless = v2.Massless
	end

	if not ragdollCollider then
		if v2 == nil then
			ragdollCollider = false
		else
			ragdollCollider = v2.CanCollide and not hasTag and not v
		end
	end

	return ragdollCollider
end

local function getEntryMotor(instance) -- 2 equivalent calls inferred from this helper
	local motor = instance:FindFirstChild("Motor")
	local value

	if motor and motor:IsA("ObjectValue") then
		value = motor.Value
	end

	if value and value:IsA("Motor6D") then
		return value
	end

	return nil
end

local function enablePreparedConstraints(folder)
	for _, descendant in folder:GetDescendants() do
		if not (descendant:IsA("BallSocketConstraint") or descendant:IsA("HingeConstraint") or descendant:IsA("NoCollisionConstraint")) then
			continue
		end

		descendant.Enabled = true
	end
end

local function findBodyPart(instance, childName: string) -- 5 equivalent calls inferred from this helper
	local part = instance:FindFirstChild(childName)

	if part and part:IsA("BasePart") then
		return part
	end

	return nil
end

local function createAttachment(bodyPart, name: string, cframe: CFrame) -- 2 equivalent calls inferred from this helper
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.CFrame = cframe
	attachment.Parent = bodyPart
	return attachment
end

local function createConstraint(parent, folder, count: number, k: number, data)
	local bodyPart = findBodyPart(parent, data.Part0) -- inferred equivalent call
	local bodyPart2 = findBodyPart(parent, data.Part1) -- inferred equivalent call

	if not (bodyPart and bodyPart2) then
		return
	end

	local formatted = `Ragdoll_{count}_{k}`
	local attachment = createAttachment(bodyPart, `{formatted}_0`, data.Attachment0) -- inferred equivalent call
	local attachment2 = createAttachment(bodyPart2, `{formatted}_1`, data.Attachment1) -- inferred equivalent call
	local v = data.Kind == "BallSocket"
	local instance = Instance.new(v and "BallSocketConstraint" or "HingeConstraint")
	instance.Name = "Constraint"
	instance.Attachment0 = attachment
	instance.Attachment1 = attachment2
	instance.LimitsEnabled = data.LimitsEnabled

	if v then
		instance.UpperAngle = data.UpperAngle
		instance.TwistLimitsEnabled = data.TwistLimitsEnabled
		instance.TwistLowerAngle = data.TwistLowerAngle
		instance.TwistUpperAngle = data.TwistUpperAngle
		instance.MaxFrictionTorque = data.MaxFrictionTorque
	else
		instance.LowerAngle = data.LowerAngle
		instance.UpperAngle = data.UpperAngle
		instance.ActuatorType = data.ActuatorType
		instance.AngularResponsiveness = data.AngularResponsiveness
		instance.AngularSpeed = data.AngularSpeed
		instance.AngularVelocity = data.AngularVelocity
		instance.MotorMaxAcceleration = data.MotorMaxAcceleration
		instance.MotorMaxTorque = data.MotorMaxTorque
		instance.ServoMaxTorque = data.ServoMaxTorque
		instance.TargetAngle = data.TargetAngle
	end

	instance.Radius = data.Radius
	instance.Restitution = data.Restitution
	instance.Enabled = false
	instance.Parent = folder
end

local function createColliders(parent)
	local folder = Instance.new("Folder")
	folder.Name = "RagdollColliders"

	for k, collider in Colliders do
		local bodyPart = findBodyPart(parent, k) -- inferred equivalent call

		if not bodyPart then
			continue
		end

		local part = Instance.new("Part")
		part.Name = `Collider_{k}`
		part.Shape = Enum.PartType.Ball
		part.Size = RigConfiguration.ColliderSize
		part.Transparency = 1
		part.Anchored = false
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
		part.CFrame = bodyPart.CFrame * collider
		part:SetAttribute("RagdollCollider", true)
		part.Parent = folder
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Name = "Weld"
		weldConstraint.Part0 = part
		weldConstraint.Part1 = bodyPart
		weldConstraint.Parent = part
	end

	folder.Parent = parent
	return folder
end

local function createNoCollisionPairs(parent, parent2)
	local folder = Instance.new("Folder")
	folder.Name = "CollisionPairs"

	for k, noCollisionPair in NoCollisionPairs do
		local v = string.find(k, "|", 1, true)

		if not v then
			continue
		end

		local bodyPart = findBodyPart(parent, string.sub(k, 1, v - 1)) -- inferred equivalent call
		local bodyPart2 = findBodyPart(parent, string.sub(k, v + 1)) -- inferred equivalent call

		if not (bodyPart and bodyPart2) then
			continue
		end

		for i = 1, noCollisionPair do
			local noCollisionConstraint = Instance.new("NoCollisionConstraint")
			noCollisionConstraint.Name = `NoCollision_{i}`
			noCollisionConstraint.Part0 = bodyPart
			noCollisionConstraint.Part1 = bodyPart2
			noCollisionConstraint.Enabled = false
			noCollisionConstraint.Parent = folder
		end
	end

	folder.Parent = parent2
end

local function scheduleLocalSettle(instance) -- 1 equivalent call inferred from this helper
	task.delay(5, function()
		local total = 0
		local v = 0

		while instance.Parent and instance:GetAttribute("Ragdolled") == true do
			local v2 = RunService.Heartbeat:Wait()
			total += v2
			local v3 = true
			local v4 = false
			local v5 = false

			for _, v6 in instance:QueryDescendants("BasePart") do
				if v6.Anchored then
					continue
				end

				local magnitude = v6.AssemblyLinearVelocity.Magnitude

				if magnitude >= 0.13 or v6.AssemblyAngularVelocity.Magnitude >= 0.13 then
					v3 = false
				end

				v4 = magnitude >= 6 or v4

				if v6.Position.Y < -400 then
					v5 = true
				end
			end

			v = not v3 and 0 or v + v2

			if not (v >= 0.2 or total >= 2.5 and not v4 or v5) then
				continue
			end

			for _, v6 in instance:QueryDescendants("BasePart") do
				v6.Anchored = true
			end

			break
		end
	end)
end

function Rig.IsPrepared(instance)
	local ragdollJoints = instance:FindFirstChild("RagdollJoints")
	local ragdollColliders = instance:FindFirstChild("RagdollColliders")
	local v

	if instance:GetAttribute("RagdollReady") == true and ragdollJoints ~= nil then
		v = ragdollJoints:IsA("Folder")

		if v then
			if ragdollColliders == nil then
				return false
			else
				return (ragdollColliders:IsA("Folder"))
			end
		end
	else
		return false
	end

	return v
end

local function prepare(parent)
	if Rig.IsPrepared(parent) then
		return true
	end

	local v, v2 = waitForBodyMotors(parent)

	if #v2 > 0 then
		local joined = table.concat(v2, ", ")
		warn(`[Ragdoll] Skipping preparation for {parent:GetFullName()}; missing body motors: {joined}`)
		return false
	else
		local function fn()
			local function fn2()
				for _, childName in { "RagdollJoints", "RagdollColliders" } do
					local child = parent:FindFirstChild(childName)

					if child then
						child:Destroy()
					end
				end
			end

			profileScope("Ragdoll.Prepare.ClearStale", fn2) -- inferred equivalent call

			local function fn3()
				local folder = Instance.new("Folder")
				folder.Name = "RagdollJoints"
				folder.Parent = parent
				local count = 0

				for _, v3 in JointOrder do
					local v4 = v[v3]
					count += 1
					local folder2 = Instance.new("Folder")
					folder2.Name = string.format("%02d_%s", count, v4.Name)
					folder2.Parent = folder
					local objectValue = Instance.new("ObjectValue")
					objectValue.Name = "Motor"
					objectValue.Value = v4
					objectValue.Parent = folder2

					for k, v5 in Joints[v3] do
						createConstraint(parent, folder2, count, k, v5)
					end
				end

				return folder
			end

			local parent2 = profileScope("Ragdoll.Prepare.Joints", fn3) -- inferred equivalent call

			local function fn4()
				createNoCollisionPairs(parent, parent2)
			end

			profileScope("Ragdoll.Prepare.NoCollisionPairs", fn4) -- inferred equivalent call

			local function fn5()
				createColliders(parent)
			end

			profileScope("Ragdoll.Prepare.Colliders", fn5) -- inferred equivalent call

			local function fn6()
				parent:SetAttribute("RagdollReady", true)
			end

			profileScope("Ragdoll.Prepare.Finalize", fn6) -- inferred equivalent call
			return true
		end

		return profileScope("Ragdoll.Prepare.Construct", fn) -- inferred equivalent call
	end
end

function Rig.Prepare(p)
	if Rig.IsPrepared(p) then
		return true
	end

	while object[p] do
		task.wait()

		if Rig.IsPrepared(p) then
			return true
		end

		if not p.Parent then
			return false
		end
	end

	object[p] = true
	local success, result = pcall(prepare, p)
	object[p] = nil

	if not success then
		error(result, 0)
	end

	return result
end

function Rig.CapturePose(instance)
	local cframesByName = {}

	for _, part in instance:GetChildren() do
		if not part:IsA("BasePart") or part:HasTag("CharacterAccessory") then
			continue
		end

		cframesByName[part.Name] = part.CFrame
	end

	return cframesByName
end

function Rig.StagePrepared(instance)
	if not Rig.IsPrepared(instance) then
		return false
	end

	if instance:GetAttribute("RagdollStaged") == true and object2[instance] then
		return true
	end

	local bodyParts = {}
	local collidingParts = {}

	local function fn()
		for _, v in instance:QueryDescendants("BasePart") do
			local v2 = configurePreparedBodyPart(instance, v)
			v.AssemblyLinearVelocity = createVector(0, 0, 0)
			v.AssemblyAngularVelocity = createVector(0, 0, 0)

			if v2 then
				table.insert(collidingParts, v)
			end

			if v.Parent ~= instance or v:HasTag("CharacterAccessory") then
				continue
			end

			table.insert(bodyParts, v)
		end
	end

	profileScope("Ragdoll.Prepare.StageParts", fn) -- inferred equivalent call
	local cframes = {}
	local entryMotors = {}

	for k, v in bodyParts do
		cframes[k] = v.CFrame
	end

	local function fn2()
		local ragdollJoints = instance:FindFirstChild("RagdollJoints")

		for _, child in ragdollJoints:GetChildren() do
			local entryMotor = getEntryMotor(child) -- inferred equivalent call

			if entryMotor then
				table.insert(entryMotors, entryMotor)
			end
		end

		enablePreparedConstraints(ragdollJoints)
	end

	profileScope("Ragdoll.Prepare.EnableConstraints", fn2) -- inferred equivalent call
	object2[instance] = {
		BodyParts = bodyParts,
		CollidingParts = collidingParts,
		Motors = entryMotors,
		PoseCFrames = cframes
	}
	instance:SetAttribute("RagdollStaged", true)
	return true
end

function Rig.ResetPrepared(instance)
	if not (Rig.IsPrepared(instance) and (object2[instance] or Rig.StagePrepared(instance))) then
		return false
	end

	local v = object2[instance]

	local function fn()
		for _, v2 in instance:QueryDescendants("BasePart") do
			configurePreparedBodyPart(instance, v2)
			v2.AssemblyLinearVelocity = createVector(0, 0, 0)
			v2.AssemblyAngularVelocity = createVector(0, 0, 0)
		end
	end

	profileScope("Ragdoll.Pool.ResetParts", fn) -- inferred equivalent call

	local function fn2()
		for _, motor in v.Motors do
			if motor.Parent then
				motor.Enabled = true
			end
		end

		local ragdollJoints = instance:FindFirstChild("RagdollJoints")

		if ragdollJoints and ragdollJoints:IsA("Folder") then
			enablePreparedConstraints(ragdollJoints)
		end
	end

	profileScope("Ragdoll.Pool.ResetJoints", fn2) -- inferred equivalent call
	return true
end

function Rig.Activate(instance, p, vector: Vector3?)
	if not (instance:GetAttribute("Ragdolled") ~= true and (Rig.IsPrepared(instance) or Rig.Prepare(instance))) then
		return false
	end

	if not (object2[instance] or Rig.StagePrepared(instance)) then
		return false
	end

	local v = object2[instance]
	local bodyParts = v.BodyParts
	debug.profilebegin("Ragdoll.Activate.DisableMotors")
	local success, result = pcall(function()
		for _, motor in v.Motors do
			motor.Enabled = false
		end
	end)
	debug.profileend()

	if not success then
		error(result, 0)
	end

	if p then
		debug.profilebegin("Ragdoll.Activate.ApplyPose")
		local success2, result2 = pcall(function()
			for k, bodyPart in bodyParts do
				v.PoseCFrames[k] = p[bodyPart.Name] or bodyPart.CFrame
			end

			if instance:IsDescendantOf(workspace) then
				workspace:BulkMoveTo(bodyParts, v.PoseCFrames, Enum.BulkMoveMode.FireCFrameChanged)
				return
			end

			for k, bodyPart in bodyParts do
				bodyPart.CFrame = v.PoseCFrames[k]
			end
		end)
		debug.profileend()

		if not success2 then
			error(result2, 0)
		end
	end

	debug.profilebegin("Ragdoll.Activate.ReleaseParts")
	local success2, result2 = pcall(function()
		for _, collidingPart in v.CollidingParts do
			collidingPart.CanCollide = true
		end

		for _, bodyPart in bodyParts do
			bodyPart.Anchored = false
		end
	end)
	debug.profileend()

	if not success2 then
		error(result2, 0)
	end

	debug.profilebegin("Ragdoll.Activate.ApplyVelocity")
	local success3, result3 = pcall(function()
		for _, bodyPart in bodyParts do
			bodyPart.AssemblyLinearVelocity = vector or createVector(0, 0, 0)
			bodyPart.AssemblyAngularVelocity = createVector(0, 0, 0)
		end
	end)
	debug.profileend()

	if not success3 then
		error(result3, 0)
	end

	local function fn()
		instance:SetAttribute("Ragdolled", true)
		instance:SetAttribute("RagdollCreatedAt", workspace:GetServerTimeNow())
		CollectionService:AddTag(instance, "Ragdoll")
		scheduleLocalSettle(instance) -- inferred equivalent call
	end

	profileScope("Ragdoll.Activate.Finalize", fn) -- inferred equivalent call
	return true
end

function Rig.ApplyImpulse(instance, data)
	local part = instance:FindFirstChild(data.Part)

	if not (part and part:IsA("BasePart")) then
		return
	end

	local weaponProperties = GetWeaponProperties(data.Weapon)

	if not weaponProperties then
		return
	end

	local direction = data.Direction
	local v = typeof(direction) ~= "Vector3" and 0 or direction.Magnitude
	local v2 = (v ~= v or v < 0.001) and createVector(-0, -1, -0) or direction / v
	local v3 = typeof(data.DirectionMultiplier) ~= "number" and 1 or data.DirectionMultiplier
	local v4 = (weaponProperties.RagdollMultiplier or 45) * v3
	local partMultiplier = PartMultipliers[part.Name]
	local v5

	if partMultiplier then
		v5 = v4 * (math.random(partMultiplier.Minimum, partMultiplier.Maximum) / 100)
	else
		v5 = v4
	end

	local v6 = (part.Name == "Head" and 1 or 0) + 2.5
	part.AssemblyLinearVelocity = (v2 * v5 + createVector(-0, -5, -0)) * v6
	local v7 = (v2 * v4 + createVector(-0, -5, -0)) * v6 * 0.1

	for _, part2 in instance:GetChildren() do
		if not (part2:IsA("BasePart") and part2 ~= part and BodyParts[part2.Name] ~= nil) then
			continue
		end

		if part2.Anchored or part2:HasTag("CharacterAccessory") then
			continue
		end

		part2.AssemblyLinearVelocity += v7
	end
end

function Rig.DisableJoint(instance, p: string)
	local ragdollJoints = instance:FindFirstChild("RagdollJoints")

	if not (ragdollJoints and ragdollJoints:IsA("Folder")) then
		return
	end

	for _, folder in ragdollJoints:GetChildren() do
		local entryMotor = getEntryMotor(folder) -- inferred equivalent call

		if not (entryMotor and entryMotor.Name == p) then
			continue
		end

		for _, descendant in folder:GetDescendants() do
			if descendant:IsA("BallSocketConstraint") or descendant:IsA("HingeConstraint") then
				descendant.Enabled = false
			end
		end

		break
	end
end

return Rig