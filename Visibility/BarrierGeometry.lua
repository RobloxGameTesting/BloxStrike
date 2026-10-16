local CollectionService = game:GetService("CollectionService")
local frozen = table.freeze({ "BreakableDoor", "BreakableGlass", "Garage", "Market Window", "Vent" })

local function findBarrierRoot(instance)
	local barriers = instance:FindFirstChild("Barriers")

	if barriers then
		return barriers
	end

	return instance:FindFirstChild("Barriers", true)
end

local function shouldIgnore(parent, barriers)
	while parent do
		if parent:GetAttribute("PVSIgnore") == true then
			return true
		end

		for _, tag in ipairs(frozen) do
			if CollectionService:HasTag(parent, tag) then
				return true
			end
		end

		if parent == barriers then
			break
		else
			parent = parent.Parent
		end
	end

	return false
end

local function supportedKind(instance)
	if instance:IsA("WedgePart") then
		return "Wedge"
	end

	if instance:IsA("CornerWedgePart") then
		return "CornerWedge"
	end

	if not instance:IsA("Part") then
		return nil
	end

	if instance.Shape == Enum.PartType.Block then
		return "Block"
	end

	if instance.Shape == Enum.PartType.Cylinder then
		return "Cylinder"
	end

	if instance.Shape == Enum.PartType.Ball then
		return "Ball"
	end

	if instance.Shape == Enum.PartType.Wedge then
		return "Wedge"
	end

	if instance.Shape == Enum.PartType.CornerWedge then
		return "CornerWedge"
	end

	return nil
end

local function relativePath(parent, p)
	local v = {}

	while parent and parent ~= p do
		table.insert(v, 1, parent.Name)
		parent = parent.Parent
	end

	return table.concat(v, "/")
end

local function geometryKey(instance, barriers, p: string)
	local v = { instance.CFrame:GetComponents() }
	local v2 = table.create(#v + 3)

	for _, v3 in ipairs(v) do
		v2[#v2 + 1] = string.format("%.9g", v3)
	end

	v2[#v2 + 1] = string.format("%.9g", instance.Size.X)
	v2[#v2 + 1] = string.format("%.9g", instance.Size.Y)
	v2[#v2 + 1] = string.format("%.9g", instance.Size.Z)
	return `{relativePath(instance, barriers)}|{p}|{table.concat(v2, ",")}`
end

local function fingerprint(list)
	local v = 5381

	for _, v2 in ipairs(list) do
		for i = 1, #v2 do
			v = bit32.band(v * 33 + string.byte(v2, i), 4294967295)
		end

		v = bit32.band(v * 33 + 10, 4294967295)
	end

	return string.format("BPR1-%08x-%d", v, #list)
end

return table.freeze({
	collect = function(instance)
		local barriers = instance:FindFirstChild("Barriers") or instance:FindFirstChild("Barriers", true)

		if barriers == nil then
			return nil, "MissingBarriers"
		end

		local parts = {}
		local v = {}
		local unsupportedClasses = {}
		local count = 0
		local count2 = 0
		local count3 = 0
		local count4 = 0
		local v2 = {}

		if barriers:IsA("BasePart") then
			v2[#v2 + 1] = barriers
		end

		for _, part in ipairs(barriers:GetDescendants()) do
			if part:IsA("BasePart") then
				v2[#v2 + 1] = part
			end
		end

		for _, v3 in ipairs(v2) do
			count += 1

			if shouldIgnore(v3, barriers) then
				count2 += 1
			else
				local v4 = supportedKind(v3)

				if v4 == nil then
					count3 += 1
					unsupportedClasses[v3.ClassName] = (unsupportedClasses[v3.ClassName] or 0) + 1
				elseif v3.CanQuery then
					parts[#parts + 1] = v3
					v[#v + 1] = geometryKey(v3, barriers, v4)
				else
					count4 += 1
				end
			end
		end

		if #parts == 0 then
			return nil, "NoSupportedBarrierPrimitives"
		end

		table.sort(parts, function(a, b)
			return relativePath(a, barriers) < relativePath(b, barriers)
		end)
		table.sort(v)
		return {
			root = barriers,
			parts = parts,
			fingerprint = fingerprint(v),
			totalParts = count,
			ignoredParts = count2,
			unsupportedParts = count3,
			unqueryableParts = count4,
			unsupportedClasses = unsupportedClasses
		}, nil
	end,
	buildRaycastParams = function(p)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = p.parts
		raycastParams.IgnoreWater = true
		raycastParams.RespectCanCollide = false
		return raycastParams
	end,
	describeUnsupported = function(p)
		local v = {}

		for k, unsupportedClass in pairs(p.unsupportedClasses) do
			v[#v + 1] = `{k}={unsupportedClass}`
		end

		table.sort(v)
		return table.concat(v, ", ")
	end
})