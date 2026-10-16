local createVector = vector.create
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CanonicalGeometry = require(script.Parent.CanonicalGeometry)
local HullPoints = require(script.Parent.HullPoints)
local Schema = require(script.Parent.Schema)
local WalkmeshCodec = require(script.Parent.WalkmeshCodec)
local v = {}

local function isUInt32(attribute) -- 2 equivalent calls inferred from this helper
	return typeof(attribute) == "number" and attribute % 1 == 0 and attribute >= 0 and attribute <= 4294967295
end

local function readUInt32Attribute(instance, attributeName: string, flag: boolean)
	local attribute = instance:GetAttribute(attributeName)

	if isUInt32(attribute) and (not flag or attribute ~= 0) then -- inferred equivalent call
		return attribute, nil
	end

	return
		nil,
		string.format("%s.%s must be %s", instance:GetFullName(), attributeName, flag and "a non-zero u32" or "a u32")
end

local function readBooleanAttribute(instance, attributeName: string)
	local attribute = instance:GetAttribute(attributeName)

	if attribute == nil then
		return false, nil
	end

	if typeof(attribute) == "boolean" then
		return attribute, nil
	end

	return nil, string.format("%s.%s must be a boolean when present", instance:GetFullName(), attributeName)
end

local function readManifest(folder)
	if folder:GetAttribute(Schema.Attributes.ManifestVersion) ~= Schema.ManifestVersion then
		return
			nil,
			string.format(
				"%s is not committed with collision manifest version %d",
				folder:GetFullName(),
				Schema.ManifestVersion
			)
	end

	local manifestEpoch = Schema.Attributes.ManifestEpoch
	local attribute = folder:GetAttribute(manifestEpoch)
	local v2

	if typeof(attribute) == "number" and attribute % 1 == 0 and attribute >= 0 then
		v2 = attribute <= 4294967295
	else
		v2 = false
	end

	local v3

	if not (v2 and attribute ~= 0) then
		v3 = string.format("%s.%s must be %s", folder:GetFullName(), manifestEpoch, "a non-zero u32")
		attribute = nil
	end

	if attribute == nil then
		return nil, v3
	end

	if Schema.MaxEpoch < attribute then
		return nil, "collision manifest epoch exceeds the u16 wire range"
	end

	local manifestFingerprint = Schema.Attributes.ManifestFingerprint
	local attribute2 = folder:GetAttribute(manifestFingerprint)
	local v4

	if typeof(attribute2) == "number" and attribute2 % 1 == 0 and attribute2 >= 0 then
		v4 = attribute2 <= 4294967295
	else
		v4 = false
	end

	local v5

	if not v4 then
		v5 = string.format("%s.%s must be %s", folder:GetFullName(), manifestFingerprint, "a u32")
		attribute2 = nil
	end

	if attribute2 == nil then
		return nil, v5
	end

	local manifestSourceCount = Schema.Attributes.ManifestSourceCount
	local attribute3 = folder:GetAttribute(manifestSourceCount)
	local v6

	if typeof(attribute3) == "number" and attribute3 % 1 == 0 and attribute3 >= 0 then
		v6 = attribute3 <= 4294967295
	else
		v6 = false
	end

	local v7

	if not v6 then
		v7 = string.format("%s.%s must be %s", folder:GetFullName(), manifestSourceCount, "a u32")
		attribute3 = nil
	end

	if attribute3 == nil then
		return nil, v7
	end

	if Schema.MaxSourceCount < attribute3 then
		return nil, string.format("collision manifest exceeds the %d-source limit", Schema.MaxSourceCount)
	end

	local manifestDestructibleCount = Schema.Attributes.ManifestDestructibleCount
	local attribute4 = folder:GetAttribute(manifestDestructibleCount)
	local v8

	if typeof(attribute4) == "number" and attribute4 % 1 == 0 and attribute4 >= 0 then
		v8 = attribute4 <= 4294967295
	else
		v8 = false
	end

	local v9

	if not v8 then
		v9 = string.format("%s.%s must be %s", folder:GetFullName(), manifestDestructibleCount, "a u32")
		attribute4 = nil
	end

	if attribute4 == nil then
		return nil, v9
	end

	if Schema.MaxDestructibleCount < attribute4 or attribute3 < attribute4 then
		return nil, "collision manifest has an invalid destructible count"
	end

	return table.freeze({
		Version = Schema.ManifestVersion,
		Epoch = attribute,
		Fingerprint = attribute2,
		SourceCount = attribute3,
		DestructibleCount = attribute4
	}), nil
end

local function findBarriersRoot(folder)
	if string.lower(folder.Name) == Schema.BarriersNameLower then
		return folder, nil
	end

	local v2 = nil

	for _, child in ipairs(folder:GetChildren()) do
		if string.lower(child.Name) ~= Schema.BarriersNameLower then
			continue
		end

		if v2 ~= nil then
			return nil, string.format("%s has multiple case-insensitive Barriers roots", folder:GetFullName())
		end

		v2 = child
	end

	return v2, nil
end

local function isInside(instance, ancestor)
	return ancestor ~= nil and (instance == ancestor or instance:IsDescendantOf(ancestor))
end

local function hasPublishedSourceAttribute(instance)
	return instance:GetAttribute(Schema.Attributes.SourceId) ~= nil
		or instance:GetAttribute(Schema.Attributes.SourceKind) ~= nil
		or instance:GetAttribute(Schema.Attributes.DestructibleIndex) ~= nil
		or instance:GetAttribute(Schema.Attributes.CanonicalGeometry) ~= nil
end

local function classify(part, barriersRoot)
	local hasTag = CollectionService:HasTag(part, Schema.Tags.Destructible)
	local hasTag2 = CollectionService:HasTag(part, Schema.Tags.Walkmesh)
	local isA = part:IsA("BasePart")

	if isA then
		if barriersRoot == nil then
			isA = false
		else
			isA = part == barriersRoot or part:IsDescendantOf(barriersRoot)
		end
	end

	if hasTag then
		return Schema.SourceKind.Destructible, hasTag, hasTag2, isA
	end

	if hasTag2 then
		return Schema.SourceKind.Walkmesh, hasTag, hasTag2, isA
	end

	if isA or part:IsA("BasePart") and CollectionService:HasTag(part, Schema.Tags.LadderMetadata) then
		return Schema.SourceKind.Barrier, hasTag, hasTag2, isA
	end

	return nil, hasTag, hasTag2, isA
end

local function getShape(instance)
	if instance:IsA("WedgePart") then
		return Enum.PartType.Wedge.Name
	end

	if instance:IsA("CornerWedgePart") then
		return Enum.PartType.CornerWedge.Name
	end

	if instance:IsA("Part") then
		return instance.Shape.Name
	end

	if instance:IsA("BasePart") then
		return Enum.PartType.Block.Name
	end

	return "Walkmesh"
end

local function sourceFingerprintKey(data)
	local v2 = data.Walkmesh == nil and "" or string.format("%08x", data.Walkmesh.Fingerprint)
	local hullPoints = {
		tostring(data.SourceId),
		tostring(data.Kind),
		data.Geometry.Descriptor,
		data.Instance.ClassName,
		data.Shape,
		data.Climbable and "1" or "0",
		data.PreciseCylinder and "1" or "0",
		data.ConvexGroup or "",
		data.DisableSeamMerge and "1" or "0",
		tostring(data.DestructibleIndex or 0),
		v2
	}

	if data.HullPoints ~= nil then
		hullPoints[#hullPoints + 1] = data.HullPoints
	end

	return table.concat(hullPoints, "\0")
end

local function readSource(instance, kind: number, p, warnCatalog)
	if kind == Schema.SourceKind.Destructible and not instance:IsA("BasePart") then
		return nil, string.format("%s has the destructible tag but is not a BasePart", instance:GetFullName())
	end

	if kind == Schema.SourceKind.Walkmesh and not (instance:IsA("BasePart") or instance:IsA("Model")) then
		return nil, string.format("%s has the walkmesh tag but is not a BasePart or Model", instance:GetFullName())
	end

	local sourceId = Schema.Attributes.SourceId
	local attribute = instance:GetAttribute(sourceId)
	local v2

	if typeof(attribute) == "number" and attribute % 1 == 0 and attribute >= 0 then
		v2 = attribute <= 4294967295
	else
		v2 = false
	end

	local v3

	if not (v2 and attribute ~= 0) then
		v3 = string.format("%s.%s must be %s", instance:GetFullName(), sourceId, "a non-zero u32")
		attribute = nil
	end

	if attribute == nil then
		return nil, v3
	end

	local sourceKind = Schema.Attributes.SourceKind
	local attribute2 = instance:GetAttribute(sourceKind)
	local v4

	if typeof(attribute2) == "number" and attribute2 % 1 == 0 and attribute2 >= 0 then
		v4 = attribute2 <= 4294967295
	else
		v4 = false
	end

	local v5

	if not (v4 and attribute2 ~= 0) then
		v5 = string.format("%s.%s must be %s", instance:GetFullName(), sourceKind, "a non-zero u32")
		attribute2 = nil
	end

	if attribute2 == nil then
		return nil, v5
	end

	if attribute2 ~= kind then
		return
			nil,
			string.format(
				"%s published source kind %d but scans as %s",
				instance:GetFullName(),
				attribute2,
				Schema.GetSourceKindName(kind) or "unknown"
			)
	end

	local published, v6 = CanonicalGeometry.ReadPublished(instance)

	if published == nil then
		return nil, v6
	end

	if instance:IsA("BasePart") and (published.Size.X <= 0 or published.Size.Y <= 0 or published.Size.Z <= 0) then
		return nil, string.format("%s published a non-positive BasePart size", instance:GetFullName())
	end

	if instance:IsA("Model") and published.Size ~= createVector(0, 0, 0) then
		return nil, string.format("%s published a non-zero Model size", instance:GetFullName())
	end

	local shape = getShape(instance)
	local destructibleIndex = nil
	local attribute3 = instance:GetAttribute(Schema.Attributes.DestructibleIndex)

	if kind == Schema.SourceKind.Destructible then
		if not isUInt32(attribute3) or attribute3 == 0 or p.DestructibleCount < attribute3 then -- inferred equivalent call
			return
				nil,
				string.format(
					"%s.%s must be in [1, %d]",
					instance:GetFullName(),
					Schema.Attributes.DestructibleIndex,
					p.DestructibleCount
				)
		end

		destructibleIndex = attribute3
	elseif attribute3 ~= nil then
		return
			nil,
			string.format(
				"%s has %s but is not a destructible source",
				instance:GetFullName(),
				Schema.Attributes.DestructibleIndex
			)
	end

	local climbable = Schema.Attributes.Climbable
	local attribute4 = instance:GetAttribute(climbable)
	local v7

	if attribute4 == nil then
		attribute4 = false
	elseif typeof(attribute4) ~= "boolean" then
		v7 = string.format("%s.%s must be a boolean when present", instance:GetFullName(), climbable)
		attribute4 = nil
	end

	if attribute4 == nil then
		return nil, v7
	end

	local hasTag = CollectionService:HasTag(instance, Schema.Tags.LadderMetadata)
	local climbable2 = attribute4 or hasTag
	local preciseCylinder = Schema.Attributes.PreciseCylinder
	local attribute5 = instance:GetAttribute(preciseCylinder)
	local v8

	if attribute5 == nil then
		attribute5 = false
	elseif typeof(attribute5) ~= "boolean" then
		v8 = string.format("%s.%s must be a boolean when present", instance:GetFullName(), preciseCylinder)
		attribute5 = nil
	end

	if attribute5 == nil then
		return nil, v8
	end

	if attribute5 and shape ~= Enum.PartType.Cylinder.Name then
		return nil, string.format("%s has precise-cylinder metadata but is not a Cylinder", instance:GetFullName())
	end

	local attribute6 = instance:GetAttribute(Schema.Attributes.ConvexGroup)
	local convexGroup = nil

	if typeof(attribute6) == "string" and attribute6 ~= "" then
		convexGroup = attribute6
	elseif typeof(attribute6) == "number" then
		convexGroup = tostring(attribute6)
	elseif attribute6 ~= nil and attribute6 ~= "" then
		return
			nil,
			string.format("%s.%s must be a string or number", instance:GetFullName(), Schema.Attributes.ConvexGroup)
	end

	local disableSeamMerge = Schema.Attributes.DisableSeamMerge
	local attribute7 = instance:GetAttribute(disableSeamMerge)
	local v9

	if attribute7 == nil then
		attribute7 = false
	elseif typeof(attribute7) ~= "boolean" then
		v9 = string.format("%s.%s must be a boolean when present", instance:GetFullName(), disableSeamMerge)
		attribute7 = nil
	end

	if attribute7 == nil then
		return nil, v9
	end

	local attribute8 = instance:GetAttribute(HullPoints.Attribute)

	if attribute8 == nil then
		attribute8 = nil
	else
		local _, v10 = HullPoints.Decode(attribute8)

		if v10 ~= nil then
			return nil, string.format("%s.%s: %s", instance:GetFullName(), HullPoints.Attribute, v10)
		end

		if not instance:IsA("Part") or shape ~= Enum.PartType.Block.Name then
			return nil, string.format("%s has %s but is not a block Part", instance:GetFullName(), HullPoints.Attribute)
		end
	end

	local walkmesh

	if kind ~= Schema.SourceKind.Walkmesh then
		return table.freeze({
			Kind = kind,
			SourceId = attribute,
			Instance = instance,
			Geometry = published,
			Shape = shape,
			Climbable = climbable2,
			PreciseCylinder = attribute5,
			ConvexGroup = convexGroup,
			DisableSeamMerge = attribute7,
			HullPoints = attribute8,
			DestructibleIndex = destructibleIndex,
			Walkmesh = walkmesh
		}), nil
	end

	if climbable2 then
		warnCatalog(string.format("%s has ladder/climbable metadata; V2 ignores it on Walkmesh", instance:GetFullName()))
		climbable2 = false
	end

	local v10
	walkmesh, v10 = WalkmeshCodec.ReadPublished(instance)

	if walkmesh == nil then
		return nil, v10
	end

	return table.freeze({
		Kind = kind,
		SourceId = attribute,
		Instance = instance,
		Geometry = published,
		Shape = shape,
		Climbable = climbable2,
		PreciseCylinder = attribute5,
		ConvexGroup = convexGroup,
		DisableSeamMerge = attribute7,
		HullPoints = attribute8,
		DestructibleIndex = destructibleIndex,
		Walkmesh = walkmesh
	}), nil
end

function v.ComputeFingerprint(list)
	local v2 = table.create(#list)

	for i, v3 in ipairs(list) do
		v2[i] = sourceFingerprintKey(v3)
	end

	return CanonicalGeometry.HashStrings(v2)
end

function v.ReadPublished(folder, callback, callback2)
	assert(typeof(folder) == "Instance", "map root must be an Instance")
	local manifest, v2 = readManifest(folder)

	if manifest == nil then
		return nil, v2
	end

	local barriersRoot, v3 = findBarriersRoot(folder)

	if v3 ~= nil then
		return nil, v3
	end

	local warnings = {}

	local function warnCatalog(p: string) -- 2 equivalent calls inferred from this helper
		warnings[#warnings + 1] = p

		if callback ~= nil then
			callback(p)
		end
	end

	local descendants = folder:GetDescendants()
	local v4 = table.create(#descendants + 1)
	v4[1] = folder

	for _, descendant in ipairs(descendants) do
		v4[#v4 + 1] = descendant
	end

	local sourcesById = {}
	local sources = {}
	local destructiblesByIndex = {}
	local count = 0

	for _, v5 in ipairs(v4) do
		if callback2 ~= nil then
			callback2()
		end

		if CollectionService:HasTag(v5, Schema.Tags.UnsupportedFloorGrid) then
			return
				nil,
				string.format(
					"%s uses unsupported CustomFloorGrid authoring; V2 accepts Barrier (including tagged Ladder), Destructible, and Walkmesh",
					v5:GetFullName()
				)
		end

		local ignore = Schema.Attributes.Ignore
		local attribute = v5:GetAttribute(ignore)
		local v6

		if attribute == nil then
			attribute = false
		elseif typeof(attribute) ~= "boolean" then
			v6 = string.format("%s.%s must be a boolean when present", v5:GetFullName(), ignore)
			attribute = nil
		end

		if attribute == nil then
			return nil, v6
		end

		local kind, v7, v8, _ = classify(v5, barriersRoot)
		local attribute2 = v5:GetAttribute(Schema.Attributes.Climbable)

		if attribute2 ~= nil and typeof(attribute2) ~= "boolean" then
			return
				nil,
				string.format("%s.%s must be a boolean when present", v5:GetFullName(), Schema.Attributes.Climbable)
		end

		if attribute then
			if v7 or v8 or hasPublishedSourceAttribute(v5) then
				return
					nil,
					string.format("%s is both an ignored and published/tagged collision source", v5:GetFullName())
			end
		elseif kind == nil then
			if hasPublishedSourceAttribute(v5) then
				return nil, string.format("%s has V2 source attributes but is not a supported source", v5:GetFullName())
			end

			if attribute2 == true then
				warnCatalog(string.format( -- inferred equivalent call
					"%s has standalone Climbable metadata but is not under Barriers or tagged Ladder",
					v5:GetFullName()
				))
			end
		else
			if v7 and v8 then
				warnCatalog(string.format( -- inferred equivalent call
					"%s is both Destructible and Walkmesh; Destructible takes precedence",
					v5:GetFullName()
				))
			end

			local v9, v10 = readSource(v5, kind, manifest, warnCatalog)

			if v9 == nil then
				return nil, v10
			end

			if sourcesById[v9.SourceId] ~= nil then
				return nil, string.format("duplicate MovementV2SourceId %d", v9.SourceId)
			end

			sourcesById[v9.SourceId] = v9
			sources[#sources + 1] = v9

			if v9.DestructibleIndex ~= nil then
				if destructiblesByIndex[v9.DestructibleIndex] ~= nil then
					return nil, string.format("duplicate MovementV2DestructibleIndex %d", v9.DestructibleIndex)
				end

				destructiblesByIndex[v9.DestructibleIndex] = v9
				count += 1
			end
		end
	end

	if #sources ~= manifest.SourceCount then
		return
			nil,
			string.format("collision manifest declares %d sources but scan found %d", manifest.SourceCount, #sources)
	end

	if count ~= manifest.DestructibleCount then
		return
			nil,
			string.format(
				"collision manifest declares %d destructibles but scan found %d",
				manifest.DestructibleCount,
				count
			)
	end

	for i = 1, manifest.DestructibleCount do
		if destructiblesByIndex[i] == nil then
			return nil, string.format("destructible indices are not dense at index %d", i)
		end
	end

	table.sort(sources, function(a, b)
		return a.SourceId < b.SourceId
	end)
	local fingerprint = v.ComputeFingerprint(sources)

	if fingerprint ~= manifest.Fingerprint then
		return
			nil,
			string.format(
				"collision manifest fingerprint mismatch: published=%08x computed=%08x",
				manifest.Fingerprint,
				fingerprint
			)
	end

	table.freeze(sources)
	table.freeze(sourcesById)
	table.freeze(destructiblesByIndex)
	table.freeze(warnings)
	return table.freeze({
		MapRoot = folder,
		BarriersRoot = barriersRoot,
		Manifest = manifest,
		Sources = sources,
		SourcesById = sourcesById,
		DestructiblesByIndex = destructiblesByIndex,
		Warnings = warnings
	}), nil
end

function v.FindReplica(p: number, p2: number)
	local child = ReplicatedStorage:FindFirstChild(Schema.ReplicaContainerName)

	if child == nil then
		return nil
	end

	for _, child2 in ipairs(child:GetChildren()) do
		if
			child2:GetAttribute(Schema.Attributes.ManifestVersion) == Schema.ManifestVersion
			and child2:GetAttribute(Schema.Attributes.ManifestEpoch) == p
			and child2:GetAttribute(Schema.Attributes.ManifestFingerprint) == p2
		then
			return child2
		end
	end

	return nil
end

return table.freeze(v)