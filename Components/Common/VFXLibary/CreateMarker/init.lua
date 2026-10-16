local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local ObjectPool = require(ReplicatedStorage.Shared.ObjectPool)
local Other = Assets:WaitForChild("Other")
local Debris = workspace:WaitForChild("Debris")
local components = {
	Bullet = require(script.Components.Bullet),
	Melee = require(script.Components.Melee)
}
local HitMarker = Other:WaitForChild("HitMarker")
local v = ObjectPool.new(HitMarker, { InitialSize = 4, MaxRetained = 20 })
local object = setmetatable({}, { __mode = "k" })
local object2 = setmetatable({}, { __mode = "k" })
local releases = {}

local function initMarkerPart(folder)
	folder.CollisionGroup = "Debris"
	folder.CanCollide = false
	folder.CanQuery = false
	folder.CanTouch = false
	local decals = {}

	for _, decal in ipairs(folder:GetDescendants()) do
		if decal:IsA("Decal") then
			table.insert(decals, decal)
		end
	end

	object[folder] = decals
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Enabled = false
	weldConstraint.Part0 = folder
	weldConstraint.Parent = folder
	object2[folder] = weldConstraint
	return weldConstraint
end

return function(part, p: string, vector: Vector3, vector2: Vector3)
	if part ~= nil and part.ClassName == "Terrain" then
		return
	end

	local v2 = components[p]
	assert(v2, `{p} is not apart of library "MarkerInfo"`)
	debug.profilebegin("VFX.Marker")
	local v3 = #releases >= 20 and table.remove(releases, 1)

	if v3 then
		v3()
	end

	local v4, v5 = v:Acquire()
	local v6 = object2[v4] or initMarkerPart(v4)
	local sizeRange = v2.Properties.SizeRange()
	v4.Size = Vector3.new(sizeRange, sizeRange, 0.001)
	v4.CFrame = CFrame.new(vector, vector + vector2) * CFrame.Angles(
		0,
		0,
		v2.Properties.Rotation() * 3.141592653589793 / 180
	)

	for _, v7 in ipairs(object[v4]) do
		v7.Transparency = v2.Properties.Transparency()
		v7.Texture = v2.Images[math.random(1, #v2.Images)]
		v7.Color3 = v2.Properties.Color3
	end

	local v7

	if part == nil then
		v7 = false
	else
		v7 = part:IsA("BasePart") and not part.Anchored
	end

	v4.Anchored = true
	v4.Parent = Debris

	if v7 then
		v6.Part1 = part
		v6.Enabled = true
		v4.Anchored = false
	end

	local connections = {}
	local function release()
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		table.clear(connections)

		if v:IsAcquired(v4, v5) then
			v6.Enabled = false
			v6.Part1 = nil
			v:Release(v4, v5)
		end

		local index = table.find(releases, release)

		if index then
			table.remove(releases, index)
		end
	end

	table.insert(releases, release)

	if part ~= nil and part:IsA("BasePart") and part:IsDescendantOf(workspace) then
		table.insert(connections, part.Destroying:Once(release))
		table.insert(connections, part:GetPropertyChangedSignal("Transparency"):Connect(function()
			if part.Transparency == 1 then
				release()
			end
		end))
	end

	task.delay(15, release)
	debug.profileend()
end