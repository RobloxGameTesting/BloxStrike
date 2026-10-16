local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Sift = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Sift"))
local frozen = table.freeze({ Reactor = -1 })
local frozen2 = table.freeze({ ["Sandy Brick"] = 0, IndoorWall = 0 })
local frozen3 = table.freeze({
	[Enum.Material.Asphalt] = 0,
	[Enum.Material.Basalt] = 0,
	[Enum.Material.Brick] = 0,
	[Enum.Material.Cobblestone] = 0,
	[Enum.Material.Concrete] = 0,
	[Enum.Material.CrackedLava] = 0,
	[Enum.Material.DiamondPlate] = 0,
	[Enum.Material.Foil] = 0,
	[Enum.Material.Glacier] = 0,
	[Enum.Material.Granite] = 0,
	[Enum.Material.Grass] = 0,
	[Enum.Material.Ground] = 0,
	[Enum.Material.Ice] = 0,
	[Enum.Material.LeafyGrass] = 0,
	[Enum.Material.Limestone] = 0,
	[Enum.Material.Marble] = 0,
	[Enum.Material.Metal] = 0,
	[Enum.Material.Mud] = 0,
	[Enum.Material.Pavement] = 0,
	[Enum.Material.Rock] = 0,
	[Enum.Material.Salt] = 0,
	[Enum.Material.Sand] = 0,
	[Enum.Material.Sandstone] = 0,
	[Enum.Material.Slate] = 0,
	[Enum.Material.Snow] = 0,
	[Enum.Material.ForceField] = 0,
	[Enum.Material.Neon] = 0,
	[Enum.Material.CorrodedMetal] = 0,
	[Enum.Material.Pebble] = 0,
	[Enum.Material.CeramicTiles] = 0,
	[Enum.Material.Plaster] = 0,
	[Enum.Material.Plastic] = 10,
	[Enum.Material.SmoothPlastic] = 10,
	[Enum.Material.Wood] = 10,
	[Enum.Material.WoodPlanks] = 10,
	[Enum.Material.Cardboard] = 10,
	[Enum.Material.Glass] = 25,
	[Enum.Material.Fabric] = 25
})

local function isPartFiltered(instance)
	return instance:FindFirstAncestorWhichIsA("Accessory") ~= nil
		or (instance:HasTag("CharacterAccessory") or instance.Name == "CollisionCapsule" or instance.Name == "HumanoidRootPart")
end

local function isPartWhitelisted(instance, instances)
	for _, ancestor in pairs(instances) do
		if instance == ancestor or instance:IsDescendantOf(ancestor) then
			return true
		end
	end

	return false
end

local function applyMapMinPenetration(p: number)
	if p ~= 0 then
		return p
	end

	local map = Workspace:GetAttribute("Map")

	if typeof(map) == "string" then
		return frozen[map] or p
	end

	return p
end

local function getPenetrationMaterial(instance)
	local parent = instance.Parent

	if parent and parent:HasTag("BreakableDoor") then
		return Enum.Material.Metal
	end

	return instance.Material
end

local function checkMaterialDepth(position: Vector3, unit: Vector3, instance, list, p, p2, p3: number)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.CollisionGroup = "Bullet"
	raycastParams.FilterDescendantsInstances = { instance }
	local v = position + unit * 1000
	local raycastResult = Workspace:Raycast(v, position - v, raycastParams)

	if not raycastResult then
		return position, true
	end

	local magnitude = (position - raycastResult.Position).Magnitude
	local materialVariant = raycastResult.Instance.MaterialVariant
	local v2, material

	if materialVariant == "" or frozen2[materialVariant] == nil then
		materialVariant = getPenetrationMaterial(raycastResult.Instance)
		v2 = frozen3[materialVariant]
		material = raycastResult.Material
	else
		v2 = frozen2[materialVariant]
		material = getPenetrationMaterial(raycastResult.Instance)
		p = p2
	end

	p[materialVariant] = (p[materialVariant] or 0) + magnitude
	local v3 = applyMapMinPenetration(v2 or 0)
	local v4 = p[materialVariant]

	if v3 + p3 < v4 then
		return raycastResult.Position, true
	end

	table.insert(list, {
		instance = raycastResult.Instance,
		position = raycastResult.Position,
		normal = raycastResult.Normal,
		material = material
	})
	return raycastResult.Position, false
end

local function castThroughMaterials(vector: Vector3, vector2: Vector3, p: number, raycastParams, p2: number?)
	local unit = vector2.Unit
	local v = vector
	local result = {}
	local v2 = {}
	local v3 = {}

	for _ = 1, 100 do
		local v4

		if p2 == nil then
			v4 = 1000
		else
			v4 = p2 - math.max((v - vector):Dot(unit), 0)

			if v4 <= 0 then
				break
			end
		end

		local raycastResult = Workspace:Raycast(v, unit * v4, raycastParams)

		if not raycastResult then
			break
		end

		if isPartFiltered(raycastResult.Instance) then
			raycastParams:AddToFilter(raycastResult.Instance)
		else
			raycastParams:AddToFilter(raycastResult.Instance)
			table.insert(result, {
				instance = raycastResult.Instance,
				position = raycastResult.Position,
				normal = raycastResult.Normal,
				material = getPenetrationMaterial(raycastResult.Instance)
			})
			local v5 = #result
			local v6
			v, v6 = checkMaterialDepth(raycastResult.Position, unit, raycastResult.Instance, result, v2, v3, p)

			if p2 == nil or not (p2 < (v - vector):Dot(unit)) then
				if v6 then
					break
				end
			else
				while v5 < #result do
					table.remove(result)
				end

				break
			end
		end
	end

	return result
end

local Raycast = {}

function Raycast.cast(vector: Vector3, vector2: Vector3, raycastParams, p, callback)
	local instances = not p and {} or Sift.Array.copy(p)

	if not raycastParams then
		raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.IgnoreWater = false
		raycastParams.CollisionGroup = "Bullet"
	end

	raycastParams.FilterDescendantsInstances = instances

	for i = 1, 10 do
		if not debug.info(i, "f") then
			break
		end

		local v = getfenv(i)

		if v.getgenv or v.hookfunction then
			Raycast = {}
		end
	end

	while true do
		local raycastResult = Workspace:Raycast(vector, vector2, raycastParams)

		if not raycastResult then
			break
		end

		local v

		if callback == nil then
			if raycastParams.FilterType == Enum.RaycastFilterType.Include then
				v = not isPartWhitelisted(raycastResult.Instance, instances)
			else
				v = isPartFiltered(raycastResult.Instance)
			end
		else
			v = callback(raycastResult.Instance)
		end

		if not v then
			return {
				instance = raycastResult.Instance,
				position = raycastResult.Position,
				normal = raycastResult.Normal,
				material = raycastResult.Material
			}
		end

		table.insert(instances, raycastResult.Instance)
		raycastParams.FilterDescendantsInstances = instances
	end

	return {
		position = vector + vector2
	}
end

function Raycast.castThrough(vector: Vector3, vector2: Vector3, p: number, filterDescendantsInstances)
	local raycastParams = RaycastParams.new()
	raycastParams.CollisionGroup = "Bullet"

	for i = 1, 10 do
		if not debug.info(i, "f") then
			break
		end

		local v = getfenv(i)

		if v.getgenv or v.hookfunction then
			Raycast = {}
		end
	end

	if filterDescendantsInstances then
		raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	end

	return castThroughMaterials(vector, vector2, p, raycastParams, nil)
end

function Raycast.castThroughDistance(vector: Vector3, vector2: Vector3, p: number, filterDescendantsInstances)
	if vector2.Magnitude <= 0 then
		return {}
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.CollisionGroup = "Bullet"

	if filterDescendantsInstances then
		raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	end

	return castThroughMaterials(vector, vector2, p, raycastParams, vector2.Magnitude)
end

return Raycast