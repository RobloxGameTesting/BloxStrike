local Constants = require(script.Parent.Constants)
local GeometryFingerprint = require(script.Parent.GeometryFingerprint)
local MaterialService = game:GetService("MaterialService")
local frozen = table.freeze({
	barriers = true,
	pvscells = true,
	pvsvolumes = true,
	pvsstaticocclusion = true,
	pvsvisibilitygeometry = true
})
local frozen2 = table.freeze({
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.ForceField] = true
})

local function hasTrueAttribute(parent, attributeName: string) -- 1 equivalent call inferred from this helper
	return parent:GetAttribute(attributeName) == true
end

local function hasMarkerOnPath(p, parent, attributeName: string, callback)
	while parent ~= nil do
		if hasTrueAttribute(parent, attributeName) or callback(parent, attributeName) then -- inferred equivalent call
			return true
		end

		if parent == p then
			break
		else
			parent = parent.Parent
		end
	end

	return false
end

local function hasDynamicTagOnPath(p, parent, callback)
	while parent ~= nil do
		for _, v in Constants.DYNAMIC_TAGS do
			if callback(parent, v) then
				return true
			end
		end

		if parent == p then
			break
		else
			parent = parent.Parent
		end
	end

	return false
end

local function collectParts(part)
	local parts = {}

	if part:IsA("BasePart") then
		table.insert(parts, part)
	end

	for _, part2 in part:GetDescendants() do
		if part2:IsA("BasePart") then
			table.insert(parts, part2)
		end
	end

	return parts
end

local function isInReservedSubtree(p, parent)
	while parent ~= nil do
		local name = string.lower(parent.Name)

		if frozen[name] == true or string.sub(name, 1, 24) == "__pvsvisibilityobjstage_" then
			return true
		end

		if parent == p then
			break
		else
			parent = parent.Parent
		end
	end

	return false
end

local function stableInstancePath(p, parent)
	local v = {}

	while parent ~= nil do
		table.insert(v, 1, `{parent.ClassName}:{parent.Name}`)

		if parent == p then
			break
		else
			parent = parent.Parent
		end
	end

	return table.concat(v, "/")
end

local function contentSourceName(result)
	local success, result2 = pcall(function()
		return result.SourceType
	end)

	if not success or result2 == nil then
		return nil
	end

	local success2, result3 = pcall(function()
		return result2.Name
	end)

	if success2 and typeof(result3) == "string" then
		return result3
	end

	return string.match(tostring(result2), "([%w_]+)$")
end

local function meshProviderIssue(p)
	local success, result = pcall(function()
		return p.MeshContent
	end)
	local result2

	if success then
		if result == nil then
			return "UnverifiableMeshContent"
		end

		local v = contentSourceName(result)

		if v == "Uri" then
			local success2
			success2, result2 = pcall(function()
				return result.Uri
			end)

			if not success2 or typeof(result2) ~= "string" or result2 == "" then
				return "UnverifiableMeshContent"
			end
		elseif v == nil then
			return "UnverifiableMeshContent"
		else
			return `NonUriMeshContent:{v}`
		end
	end

	if result2 == nil then
		local success2, result3 = pcall(function()
			return p.MeshId
		end)

		if not success2 or result3 == nil or tostring(result3) == "" then
			return "UnverifiableMeshContent"
		end
	end

	return nil
end

local function immutableMeshIssue(part)
	if part:IsA("MeshPart") then
		local v = meshProviderIssue(part)

		if v ~= nil then
			return v
		end
	end

	local count = 0

	for _, child in part:GetChildren() do
		if child:IsA("DataModelMesh") then
			count += 1

			if count > 1 then
				return "MultipleMeshChildren"
			end

			if not child.Archivable then
				return "NonArchivableMeshChild"
			end
		end

		local isA = child:IsA("FileMesh")

		if child:IsA("SpecialMesh") then
			isA = child.MeshType == Enum.MeshType.FileMesh
		end

		if not isA then
			continue
		end

		local v = meshProviderIssue(child)

		if v ~= nil then
			return v
		end
	end

	return nil
end

local function alphaTransparencyIssue(part)
	for _, surfaceAppearance in part:GetChildren() do
		if
			surfaceAppearance:IsA("SurfaceAppearance")
			and surfaceAppearance.AlphaMode == Enum.AlphaMode.Transparency
		then
			return "SurfaceAppearanceAlphaTransparency"
		end
	end

	local baseMaterialOverride = part.MaterialVariant

	if baseMaterialOverride == "" and frozen2[part.Material] then
		return nil
	end

	if baseMaterialOverride == "" then
		local success
		success, baseMaterialOverride = pcall(MaterialService.GetBaseMaterialOverride, MaterialService, part.Material)

		if not success or typeof(baseMaterialOverride) ~= "string" then
			return "UnverifiableMaterialVariant"
		end
	end

	if baseMaterialOverride == "" then
		return nil
	end

	local success, materialVariant = pcall(
		MaterialService.GetMaterialVariant,
		MaterialService,
		part.Material,
		baseMaterialOverride
	)

	if not success then
		return "UnverifiableMaterialVariant"
	end

	if materialVariant ~= nil and materialVariant.AlphaMode == Enum.AlphaMode.Transparency then
		return "MaterialVariantAlphaTransparency"
	end

	return nil
end

return table.freeze({
	build = function(root, callback)
		local count = 0
		local count2 = 0
		local count3 = 0
		local rejections = {}
		local parts = {}
		local count4 = 0

		for _, part in collectParts(root) do
			local markerOnPath = hasMarkerOnPath(root, part, Constants.OCCLUDER_MARKER, callback)

			if isInReservedSubtree(root, part) then
				if markerOnPath then
					count += 1
				end

				count2 += 1
				count3 += 1
			elseif markerOnPath then
				count += 1

				if
					hasMarkerOnPath(root, part, Constants.IGNORE_MARKER, callback)
					or hasMarkerOnPath(root, part, Constants.DYNAMIC_MARKER, callback)
					or hasDynamicTagOnPath(root, part, callback)
				then
					count2 += 1
				elseif GeometryFingerprint.supportsPart(part) then
					local reason = alphaTransparencyIssue(part)

					if reason == nil then
						if part:IsA("MeshPart") and part:FindFirstChildWhichIsA("Bone", true) ~= nil then
							table.insert(rejections, { part = part, reason = "SkinnedMesh" })
						elseif part:IsA("MeshPart") and part:FindFirstChildWhichIsA("BaseWrap", true) ~= nil then
							table.insert(rejections, { part = part, reason = "DeformedMesh" })
						else
							local reason2 = immutableMeshIssue(part)

							if reason2 == nil then
								if part.Anchored then
									if part.Material == Enum.Material.Glass then
										table.insert(rejections, {
											part = part,
											reason = "GlassMaterial"
										})
									elseif part.Material == Enum.Material.ForceField then
										table.insert(rejections, {
											part = part,
											reason = "ForceFieldMaterial"
										})
									elseif part.Transparency > Constants.OPAQUE_TRANSPARENCY_LIMIT then
										table.insert(rejections, {
											part = part,
											reason = "Transparent"
										})
									else
										table.insert(parts, part)
									end
								else
									table.insert(rejections, { part = part, reason = "NotAnchored" })
								end
							else
								table.insert(rejections, { part = part, reason = reason2 })
							end
						end
					else
						table.insert(rejections, { part = part, reason = reason })
					end
				else
					table.insert(rejections, {
						part = part,
						reason = `UnsupportedClass:{part.ClassName}`
					})
				end
			else
				count4 += 1
			end
		end

		local v = {}

		for _, v2 in parts do
			v[v2] = stableInstancePath(root, v2)
		end

		for _, v2 in rejections do
			v[v2.part] = stableInstancePath(root, v2.part)
		end

		table.sort(parts, function(a, b)
			local v2 = v[a]
			local v3 = v[b]

			if v2 ~= v3 then
				return v2 < v3
			end

			local position = a.Position
			local position2 = b.Position

			if position.X ~= position2.X then
				return position.X < position2.X
			end

			if position.Y ~= position2.Y then
				return position.Y < position2.Y
			end

			if position.Z == position2.Z then
				return tostring(a.Size) < tostring(b.Size)
			end

			return position.Z < position2.Z
		end)
		table.sort(rejections, function(a, b)
			return v[a.part] < v[b.part]
		end)
		return {
			root = root,
			parts = parts,
			rejections = rejections,
			explicitPartCount = count,
			untaggedPartCount = count4,
			excludedPartCount = count2,
			reservedPartCount = count3
		}
	end,
	path = function(p, p2)
		return stableInstancePath(p, p2)
	end
})