--!native
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local BarrierGeometry = require(script.Parent.BarrierGeometry)
local Constants = require(script.Parent.OBJGeometry.Constants)
local GeometryFingerprint = require(script.Parent.OBJGeometry.GeometryFingerprint)
local OccluderCatalog = require(script.Parent.OBJGeometry.OccluderCatalog)
local StaticOcclusionCodec = require(script.Parent.StaticOcclusionCodec)
local StaticOcclusionRuntime = require(script.Parent.StaticOcclusionRuntime)
local StaticOcclusionStorage = require(script.Parent.StaticOcclusionStorage)
local class = {}
class.__index = class
local NEGATIVE_AUTHORITY = Constants.NEGATIVE_AUTHORITY
local GEOMETRY_VERSION = Constants.GEOMETRY_VERSION

local function isFinite(p: number)
	return p == p and p > -1e999 and p < 1e999
end

local function isFiniteVector(vector: Vector3) -- 8 equivalent calls inferred from this helper
	local x = vector.X
	local v

	if x == x and x > -1e999 then
		v = x < 1e999
	else
		v = false
	end

	if not v then
		return v
	end

	local y = vector.Y

	if y == y and y > -1e999 then
		v = y < 1e999
	else
		v = false
	end

	if not v then
		return v
	end

	local z = vector.Z

	if z == z and z > -1e999 then
		return z < 1e999
	else
		return false
	end

	return v
end

local function vectorsClose(vector: Vector3, vector2: Vector3, BOUNDS_TOLERANCE: number) -- 2 equivalent calls inferred from this helper
	return math.abs(vector.X - vector2.X) <= BOUNDS_TOLERANCE
		and math.abs(vector.Y - vector2.Y) <= BOUNDS_TOLERANCE
		and math.abs(vector.Z - vector2.Z) <= BOUNDS_TOLERANCE
end

local function exactFingerprintBindsExport(value: string, pvsVisibilityGeometryExportFingerprint: string)
	local v, v2 = string.match(value, "^VGEOM1:([%da-fA-F]+):([%da-fA-F]+)$")
	return v ~= nil
		and v2 ~= nil
		and #v == 16
		and #v2 == 64
		and string.lower(v) == string.lower(pvsVisibilityGeometryExportFingerprint)
end

local function validateLiveGeometryRecipe(mapRoot, exactGeometryFingerprint: string)
	if mapRoot:GetAttribute("PVSVisibilityExportVersion") ~= Constants.EXPORT_VERSION then
		return "UnsupportedPVSVisibilityExportVersion"
	end

	if mapRoot:GetAttribute("PVSVisibilityExportTransform") ~= Constants.EXPORT_TRANSFORM then
		return "UnsupportedPVSVisibilityExportTransform"
	end

	local pvsVisibilityExportFingerprint = mapRoot:GetAttribute("PVSVisibilityExportFingerprint")
	local pvsVisibilityGeometryExportFingerprint = mapRoot:GetAttribute("PVSVisibilityGeometryExportFingerprint")
	local pvsVisibilityExportExpectedParts = mapRoot:GetAttribute("PVSVisibilityExportExpectedParts")
	local pvsVisibilityExportBoundsMin = mapRoot:GetAttribute("PVSVisibilityExportBoundsMin")
	local pvsVisibilityExportBoundsMax = mapRoot:GetAttribute("PVSVisibilityExportBoundsMax")

	if typeof(pvsVisibilityExportFingerprint) ~= "string" or #pvsVisibilityExportFingerprint == 0 then
		return "MissingPVSVisibilityExportFingerprint"
	end

	if typeof(pvsVisibilityGeometryExportFingerprint) ~= "string" or #pvsVisibilityGeometryExportFingerprint == 0 then
		return "MissingPVSVisibilityGeometryExportFingerprint"
	end

	if
		typeof(pvsVisibilityExportExpectedParts) ~= "number"
		or pvsVisibilityExportExpectedParts < 1
		or pvsVisibilityExportExpectedParts % 1 ~= 0
		or typeof(pvsVisibilityExportBoundsMin) ~= "Vector3"
		or typeof(pvsVisibilityExportBoundsMax) ~= "Vector3"
	then
		return "InvalidPVSVisibilityExportManifest"
	end

	if not (isFiniteVector(pvsVisibilityExportBoundsMin) and isFiniteVector(pvsVisibilityExportBoundsMax)) then -- inferred equivalent call
		return "InvalidPVSVisibilityExportManifest"
	end

	if string.lower(pvsVisibilityExportFingerprint) ~= string.lower(pvsVisibilityGeometryExportFingerprint) then
		return "PVSVisibilityGeometryExportFingerprintMismatch"
	end

	if not exactFingerprintBindsExport(exactGeometryFingerprint, pvsVisibilityGeometryExportFingerprint) then
		return "PVSVisibilityGeometryBindingMismatch"
	end

	local success, result = pcall(function()
		return OccluderCatalog.build(mapRoot, function(instance, tag: string)
			return CollectionService:HasTag(instance, tag)
		end)
	end)

	if not success then
		return `PVSVisibilityCatalogError:{tostring(result)}`
	end

	if #result.rejections > 0 then
		return `InvalidPVSVisibilityOccluderCatalog:{#result.rejections}`
	end

	if #result.parts == 0 then
		return "EmptyPVSVisibilityOccluderCatalog"
	end

	local success2, result2 = pcall(GeometryFingerprint.compute, mapRoot, result.parts)

	if not success2 then
		return `PVSVisibilityFingerprintError:{tostring(result2)}`
	end

	if string.lower(result2.fingerprint) ~= string.lower(pvsVisibilityExportFingerprint) then
		return "StalePVSVisibilityGeometryFingerprint"
	end

	if result2.partCount ~= pvsVisibilityExportExpectedParts then
		return "StalePVSVisibilityGeometryPartCount"
	end

	if not vectorsClose(result2.minimum, pvsVisibilityExportBoundsMin, Constants.BOUNDS_TOLERANCE) then -- inferred equivalent call
		return "StalePVSVisibilityGeometryBounds"
	end

	if vectorsClose(result2.maximum, pvsVisibilityExportBoundsMax, Constants.BOUNDS_TOLERANCE) then -- inferred equivalent call
		return nil
	end

	return "StalePVSVisibilityGeometryBounds"
end

function class.new(mapRoot, p)
	local self = setmetatable({
		MapRoot = mapRoot,
		StorageRoot = p or mapRoot,
		ExactGeometryDeclared = false,
		ExactGeometryComplete = false
	}, class)
	self:Refresh()
	return self
end

function class:Refresh()
	self.Catalog = nil
	self.RaycastParams = nil
	self.Fingerprint = nil
	self.LoadError = nil
	self.StaticOcclusion = nil
	self.EncodedStaticOcclusion = nil
	self.EncodedProofs = nil
	self.ProofError = nil
	self.StaticOcclusionError = nil
	self.ExactGeometryDeclared = false
	self.ExactGeometryComplete = false
	self.ExactGeometryFingerprint = nil
	self.ExactGeometryError = nil

	if self.MapRoot ~= Workspace and not self.MapRoot:IsDescendantOf(Workspace) then
		self.LoadError = "MapNotInWorkspace"
		return false
	end

	local pvsNegativeAuthority = self.MapRoot:GetAttribute("PVSNegativeAuthority")
	local pvsVisibilityGeometryVersion = self.MapRoot:GetAttribute("PVSVisibilityGeometryVersion")
	local pvsVisibilityGeometryComplete = self.MapRoot:GetAttribute("PVSVisibilityGeometryComplete")
	local pvsVisibilityGeometryFingerprint = self.MapRoot:GetAttribute("PVSVisibilityGeometryFingerprint")
	self.ExactGeometryDeclared = pvsNegativeAuthority ~= nil
		or pvsVisibilityGeometryVersion ~= nil
		or pvsVisibilityGeometryComplete ~= nil
		or pvsVisibilityGeometryFingerprint ~= nil

	if self.ExactGeometryDeclared then
		if pvsNegativeAuthority == NEGATIVE_AUTHORITY then
			if pvsVisibilityGeometryVersion == GEOMETRY_VERSION then
				if pvsVisibilityGeometryComplete == true then
					if
						typeof(pvsVisibilityGeometryFingerprint) == "string"
						and #pvsVisibilityGeometryFingerprint ~= 0
					then
						self.ExactGeometryFingerprint = pvsVisibilityGeometryFingerprint
					else
						self.ExactGeometryError = "MissingPVSVisibilityGeometryFingerprint"
					end
				else
					self.ExactGeometryError = "IncompletePVSVisibilityGeometry"
				end
			else
				self.ExactGeometryError = "UnsupportedPVSVisibilityGeometryVersion"
			end
		else
			self.ExactGeometryError = "UnsupportedPVSNegativeAuthority"
		end
	end

	if self.ExactGeometryDeclared then
		local exactGeometryFingerprint = self.ExactGeometryFingerprint

		if self.ExactGeometryError == nil and exactGeometryFingerprint ~= nil then
			local v = validateLiveGeometryRecipe(self.MapRoot, exactGeometryFingerprint)

			if v == nil then
				local lastTime = os.clock()

				local function startupCheckpoint()
					if os.clock() - lastTime >= 0.008 then
						task.wait()
						lastTime = os.clock()
					end
				end

				local encodedStaticOcclusion, v2 = StaticOcclusionStorage.read(
					self.StorageRoot,
					exactGeometryFingerprint,
					startupCheckpoint
				)

				if encodedStaticOcclusion == nil then
					self.LoadError = v2 or "MissingExactPVSStaticOcclusion"
					self.StaticOcclusionError = self.LoadError
					self.ExactGeometryError = self.LoadError
					return false
				else
					local success, result = pcall(
						StaticOcclusionRuntime.new,
						encodedStaticOcclusion,
						exactGeometryFingerprint,
						startupCheckpoint
					)

					if success then
						local v3, v4 = StaticOcclusionCodec.validateExactGeometry(result.Data)

						if v3 then
							self.StaticOcclusion = result
							self.EncodedStaticOcclusion = encodedStaticOcclusion
							local success2, result2, proofError = pcall(
								StaticOcclusionStorage.readProofs,
								self.StorageRoot,
								exactGeometryFingerprint,
								startupCheckpoint
							)

							if not success2 then
								proofError = tostring(result2)
								result2 = nil
							end

							self.ProofError = proofError

							if result2 ~= nil then
								local v5, proofError2 = result:InstallProofs(result2, startupCheckpoint)

								if v5 then
									self.EncodedProofs = result2
								else
									self.ProofError = proofError2
								end
							end

							self.Fingerprint = exactGeometryFingerprint
							self.ExactGeometryComplete = true
							self.LoadError = nil
							return true
						else
							self.LoadError = v4 or "InvalidExactPVBVHProfile"
							self.StaticOcclusionError = self.LoadError
							self.ExactGeometryError = self.LoadError
							return false
						end
					else
						self.LoadError = `ExactPVSStaticOcclusionError:{tostring(result)}`
						self.StaticOcclusionError = self.LoadError
						self.ExactGeometryError = self.LoadError
						return false
					end
				end
			else
				self.LoadError = v
				self.StaticOcclusionError = v
				self.ExactGeometryError = v
				return false
			end
		else
			self.LoadError = self.ExactGeometryError or "InvalidPVSVisibilityGeometryContract"
			self.StaticOcclusionError = self.LoadError
			return false
		end
	else
		local success, result, v = pcall(BarrierGeometry.collect, self.MapRoot)

		if success and result ~= nil then
			local pvsBarrierFingerprint = self.MapRoot:GetAttribute("PVSBarrierFingerprint")

			if typeof(pvsBarrierFingerprint) == "string" and result.fingerprint ~= pvsBarrierFingerprint then
				self.LoadError = "StaleBarrierGeometry"
			else
				self.Catalog = result
			end
		else
			self.LoadError = success and (v or "MissingBarrierCatalog") or `BarrierCatalogError:{tostring(result)}`
		end

		local catalog = self.Catalog

		if catalog == nil then
			return false
		end

		self.RaycastParams = BarrierGeometry.buildRaycastParams(catalog)
		self.Fingerprint = catalog.fingerprint
		local encodedStaticOcclusion, staticOcclusionError = StaticOcclusionStorage.read(
			self.StorageRoot,
			catalog.fingerprint
		)

		if encodedStaticOcclusion == nil then
			self.StaticOcclusionError = staticOcclusionError
		else
			local success2, result2 = pcall(StaticOcclusionRuntime.new, encodedStaticOcclusion, catalog.fingerprint)

			if success2 then
				self.StaticOcclusion = result2
				self.EncodedStaticOcclusion = encodedStaticOcclusion
			else
				self.StaticOcclusionError = tostring(result2)
			end
		end

		return true
	end
end

function class.IsReady(p)
	return p.ExactGeometryComplete or p.RaycastParams ~= nil
end

function class.GetLoadError(p)
	return p.LoadError
end

function class.GetFingerprint(p)
	return p.Fingerprint
end

function class.GetStaticOcclusion(p)
	return p.StaticOcclusion
end

function class.GetEncodedStaticOcclusion(p)
	return p.EncodedStaticOcclusion
end

function class.GetStaticOcclusionError(p)
	return p.StaticOcclusionError
end

function class.IsExactGeometryComplete(p)
	return p.ExactGeometryComplete
end

function class:RaycastSegment(vector: Vector3, vector2: Vector3)
	if self.ExactGeometryDeclared then
		return nil, false
	end

	local raycastParams = self.RaycastParams

	if raycastParams == nil then
		return nil, false
	end

	if isFiniteVector(vector) and isFiniteVector(vector2) then -- inferred equivalent call
		local vector3 = vector2 - vector

		if vector3.Magnitude <= 0.001 then
			return nil, true
		end

		local success, result = pcall(Workspace.Raycast, Workspace, vector, vector3, raycastParams)

		if success then
			return result, true
		end

		return nil, false
	end

	return nil, false
end

function class:SegmentBlocked(vector: Vector3, vector2: Vector3)
	if not isFiniteVector(vector) then -- inferred equivalent call
		return false, false, nil, false, false
	end

	if not isFiniteVector(vector2) then -- inferred equivalent call
		return false, false, nil, false, false
	end

	local staticOcclusion = self.StaticOcclusion
	local catalog = self.Catalog
	local flag = false

	if self.ExactGeometryDeclared then
		if not self.ExactGeometryComplete or staticOcclusion == nil then
			return false, false, nil, false, false
		end

		local success, result = pcall(staticOcclusion.SegmentBlocked, staticOcclusion, vector, vector2, nil)

		if success then
			return result == true, true, nil, true, false
		end

		return false, false, nil, true, false
	else
		if staticOcclusion ~= nil and catalog ~= nil then
			local success, result, v = pcall(staticOcclusion.SegmentBlocked, staticOcclusion, vector, vector2, nil)

			if success and result == true then
				local v2

				if typeof(v) == "number" then
					v2 = catalog.parts[v]
				end

				return true, true, v2, true, false
			else
				flag = true
			end
		end

		local raycastSegment, v = self:RaycastSegment(vector, vector2)
		local v2

		if not (raycastSegment == nil or not raycastSegment.Instance:IsA("BasePart")) then
			v2 = raycastSegment.Instance
		end

		return v and raycastSegment ~= nil, v, v2, flag, true
	end

	return false, false, nil, false, false
end

function class:ClipOrigin(vector: Vector3, vector2: Vector3, value: number?)
	if self.ExactGeometryDeclared then
		local staticOcclusion = self.StaticOcclusion

		if not self.ExactGeometryComplete or staticOcclusion == nil then
			return vector2
		end

		if not (isFiniteVector(vector) and isFiniteVector(vector2)) then -- inferred equivalent call
			return vector2
		end

		local vector3 = vector2 - vector
		local magnitude = vector3.Magnitude

		if magnitude <= 0.001 then
			return vector2
		end

		local success, result = pcall(staticOcclusion.NearestSegmentHit, staticOcclusion, vector, vector2)

		if not success or result == nil then
			return vector2
		end

		local v = math.clamp((math.ceil(result / 0.9999999 * 256) - 1) / 256, 0, 1)
		local v2 = math.clamp(value or 0.25, 0, 16)
		return vector + vector3.Unit * math.max(magnitude * v - v2, 0)
	else
		local vector3 = vector2 - vector

		if vector3.Magnitude <= 0.001 then
			return vector2
		end

		local segmentBlocked, v = self:SegmentBlocked(vector, vector2)

		if not (v and segmentBlocked) then
			return vector2
		end

		local v2 = math.clamp(value or 0.25, 0, 16)

		if v2 <= 0 then
			local v3 = vector2
			local v4 = vector

			for _ = 1, 8 do
				local vector4 = (v4 + v3) * 0.5
				local segmentBlocked2, v5 = self:SegmentBlocked(vector, vector4)

				if not v5 then
					return vector2
				end

				if segmentBlocked2 then
					v3 = vector4
				else
					v4 = vector4
				end
			end

			return v4
		else
			local raycastSegment, v3 = self:RaycastSegment(vector, vector2)

			if v3 and raycastSegment ~= nil then
				return vector + vector3.Unit * math.max(raycastSegment.Distance - v2, 0)
			end

			return vector2
		end
	end
end

return table.freeze(class)