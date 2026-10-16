local createVector = vector.create
local Constants = require(script.Parent.Constants)
local v = {
	supportsPart = function(instance)
		return instance:IsA("Part")
			or instance:IsA("WedgePart")
			or instance:IsA("CornerWedgePart")
			or instance:IsA("MeshPart")
			or instance:IsA("TrussPart")
			or instance:IsA("UnionOperation")
	end
}

local function canonicalNumber(p: number, value: number?) -- 2 equivalent calls inferred from this helper
	local v2 = math.round(p / (value or 0.0001))
	local v3 = v2 == 0 and 0 or v2
	return string.format("%d", v3)
end

local function vectorRecord(vector: Vector3)
	local v2 = canonicalNumber(vector.X) -- inferred equivalent call
	local v3 = math.round(vector.Y / 0.0001)
	local v4 = v3 == 0 and 0 or v3
	return table.concat({ v2, string.format("%d", v4), canonicalNumber(vector.Z) }, ",")
end

local function cframeRecord(cframe: CFrame)
	local v2 = { cframe:GetComponents() }
	local v3 = table.create(#v2)

	for k, v4 in v2 do
		v3[k] = canonicalNumber(v4, k <= 3 and 0.0001 or 1e-6) -- inferred equivalent call
	end

	return table.concat(v3, ",")
end

local function lengthPrefixed(list: string) -- 4 equivalent calls inferred from this helper
	return `{#list}:{list}`
end

local function assertInsideRoot(ancestor, instance) -- 1 equivalent call inferred from this helper
	assert(
		instance == ancestor or instance:IsDescendantOf(ancestor),
		"Visibility geometry is outside the selected map root"
	)
end

local function propertyString(p, p2: string)
	local success, result = pcall(function()
		return p[p2]
	end)

	if not success or result == nil then
		return ""
	end

	if typeof(result) == "Vector3" then
		return vectorRecord(result)
	end

	if typeof(result) == "CFrame" then
		return cframeRecord(result)
	end

	if typeof(result) == "number" then
		return canonicalNumber(result)
	end

	return (tostring(result))
end

local function meshChildrenRecord(instance)
	local values = {}

	for _, dataModelMesh in instance:GetChildren() do
		if not dataModelMesh:IsA("DataModelMesh") then
			continue
		end

		local v2 = {
			dataModelMesh.ClassName,
			propertyString(dataModelMesh, "MeshType"),
			propertyString(dataModelMesh, "MeshId"),
			propertyString(dataModelMesh, "MeshContent"),
			propertyString(dataModelMesh, "Scale"),
			propertyString(dataModelMesh, "Offset")
		}
		table.insert(values, table.concat(v2, "|"))
	end

	table.sort(values)
	return table.concat(values, ";")
end

local function unionRecord(instance)
	return table.concat(
		{
			"UnionOperationV2",
			`MeshSize={propertyString(instance, "MeshSize")}`,
			`RenderFidelity={propertyString(instance, "RenderFidelity")}`,
			`SmoothingAngle={propertyString(instance, "SmoothingAngle")}`,
			`TriangleCount={propertyString(instance, "TriangleCount")}`
		},
		"|"
	)
end

local function partRecord(ancestor, instance)
	assert(v.supportsPart(instance), `Unsupported visibility geometry class {instance.ClassName}`)
	local shape = ""

	if instance:IsA("TrussPart") then
		shape = propertyString(instance, "Style")
	elseif instance:IsA("Part") then
		shape = tostring(instance.Shape)
	elseif instance:IsA("MeshPart") then
		shape = table.concat(
			{
				propertyString(instance, "MeshId"),
				propertyString(instance, "MeshContent"),
				propertyString(instance, "MeshSize"),
				propertyString(instance, "RenderFidelity"),
				propertyString(instance, "DoubleSided")
			},
			"|"
		)
	elseif instance:IsA("UnionOperation") then
		shape = unionRecord(instance)
	end

	assertInsideRoot(ancestor, instance) -- inferred equivalent call
	local v2 = lengthPrefixed(instance.ClassName) -- inferred equivalent call
	local v3 = cframeRecord(instance.CFrame)
	local v4 = vectorRecord(instance.Size)
	local v5 = lengthPrefixed(shape) -- inferred equivalent call
	return table.concat({
		"PVSOCCLUDER2",
		v2,
		v3,
		v4,
		v5,
		lengthPrefixed(meshChildrenRecord(instance)) -- inferred equivalent call
	}, "|")
end

local function worldBounds(instance)
	local v2 = instance.Size * 0.5
	local cframe = instance.CFrame
	local rightVector = cframe.RightVector
	local upVector = cframe.UpVector
	local lookVector = cframe.LookVector
	local vector = Vector3.new(
		math.abs(rightVector.X) * v2.X + math.abs(upVector.X) * v2.Y + math.abs(lookVector.X) * v2.Z,
		math.abs(rightVector.Y) * v2.X + math.abs(upVector.Y) * v2.Y + math.abs(lookVector.Y) * v2.Z,
		math.abs(rightVector.Z) * v2.X + math.abs(upVector.Z) * v2.Y + math.abs(lookVector.Z) * v2.Z
	)
	return cframe.Position - vector, cframe.Position + vector
end

function v.hashStrings(items)
	local v2 = 5381
	local v3 = 2166136261

	for _, item in items do
		local v4 = lengthPrefixed(item) -- inferred equivalent call

		for i = 1, #v4 do
			local v5 = string.byte(v4, i)
			v2 = (v2 * 33 + v5) % 4294967296
			v3 = (v3 * 65599 + v5) % 4294967296
		end
	end

	return string.format("%08x%08x", v2, v3)
end

function v.compute(p, list)
	assert(#list > 0, "Cannot fingerprint an empty visibility catalog")
	local records = table.create(#list + 1)
	local minimum = createVector(1e999, 1e999, 1e999)
	local maximum = createVector(-1e999, -1e999, -1e999)

	for _, v2 in list do
		table.insert(records, partRecord(p, v2))
		local v3, v4 = worldBounds(v2)
		minimum = minimum:Min(v3)
		maximum = maximum:Max(v4)
	end

	table.sort(records)
	table.insert(
		records,
		1,
		`PVSVisibilityExportVersion={Constants.EXPORT_VERSION}|Transform={Constants.EXPORT_TRANSFORM}|PartCount={#list}`
	)
	return {
		fingerprint = v.hashStrings(records),
		minimum = minimum,
		maximum = maximum,
		partCount = #list,
		records = records
	}
end

return table.freeze(v)