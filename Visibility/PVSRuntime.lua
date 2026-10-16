--!native
local PVSCodec = require(script.Parent.PVSCodec)
local Constants = require(script.Parent.OBJGeometry.Constants)
local StaticGeometryRuntime = require(script.Parent.StaticGeometryRuntime)
local class = {}
class.__index = class
local MATRIX_POLICY = Constants.MATRIX_POLICY
local AUDITED_MATRIX_POLICY = Constants.AUDITED_MATRIX_POLICY

local function bucketKey(p: number, p2: number, p3: number) -- 3 equivalent calls inferred from this helper
	return ((p + 65536) * 131072 + (p2 + 65536)) * 131072 + (p3 + 65536)
end

local function buildSpatialBuckets(result, p: number)
	local result2 = {}

	for i, region in ipairs(result.regions) do
		for j = math.floor(region.minimum.X / p), math.floor(region.maximum.X / p) do
			for k = math.floor(region.minimum.Y / p), math.floor(region.maximum.Y / p) do
				for i2 = math.floor(region.minimum.Z / p), math.floor(region.maximum.Z / p) do
					local v = bucketKey(j, k, i2) -- inferred equivalent call
					local v2 = result2[v]

					if v2 == nil then
						v2 = {}
						result2[v] = v2
					end

					v2[#v2 + 1] = i
				end
			end
		end
	end

	return result2
end

function class.new(mapRoot, p)
	local self = setmetatable({
		MapRoot = mapRoot,
		StorageRoot = p or mapRoot,
		TrustedNegatives = false,
		SpatialBuckets = {},
		SnapCaches = {},
		SnapCacheCount = 0,
		SnapInterned = {},
		SpatialBucketSize = 64,
		SelectionPadding = 8,
		StaticGeometry = StaticGeometryRuntime.new(mapRoot, p)
	}, class)
	self:Refresh(true)
	return self
end

function class:Refresh(flag: boolean?)
	self.Data = nil
	self.DecodeError = nil
	self.TrustedNegatives = false
	self.SpatialBuckets = {}
	self.SnapCaches = {}
	self.SnapCacheCount = 0
	self.SnapInterned = {}
	local v

	if flag then
		v = self.StaticGeometry:IsReady()
	else
		v = self.StaticGeometry:Refresh()
	end

	local pvsSelectionPadding = self.MapRoot:GetAttribute("PVSSelectionPadding")

	if typeof(pvsSelectionPadding) == "number" and pvsSelectionPadding == pvsSelectionPadding then
		self.SelectionPadding = math.clamp(pvsSelectionPadding, 0, 512)
	else
		self.SelectionPadding = 8
	end

	self.VerticalSelectionPadding = nil
	local pvsLayerHeight = self.MapRoot:GetAttribute("PVSLayerHeight")

	if typeof(pvsLayerHeight) == "number" and pvsLayerHeight >= 1 and pvsLayerHeight <= 64 then
		self.VerticalSelectionPadding = 0.25
	end

	local pvsAdaptiveCellSize = self.MapRoot:GetAttribute("PVSAdaptiveCellSize")

	if typeof(pvsAdaptiveCellSize) == "number" and pvsAdaptiveCellSize >= 1 and pvsAdaptiveCellSize <= 64 then
		self.VerticalSelectionPadding = 0.25
	end

	local pvsData = self.StorageRoot:GetAttribute("PVSData")

	if typeof(pvsData) ~= "string" then
		self.DecodeError = "MissingPVSData"
		return false
	end

	local lastTime = os.clock()

	local function startupCheckpoint()
		if os.clock() - lastTime >= 0.008 then
			task.wait()
			lastTime = os.clock()
		end
	end

	local success, result = pcall(PVSCodec.decode, pvsData, startupCheckpoint)

	if not success then
		self.DecodeError = tostring(result)
		return false
	end

	local pvsBarrierFingerprint = self.MapRoot:GetAttribute("PVSBarrierFingerprint")
	local pvsBakerVersion = self.MapRoot:GetAttribute("PVSBakerVersion")

	if typeof(pvsBakerVersion) == "number" and pvsBakerVersion >= 19 then
		local pvsMatrixPolicy = self.MapRoot:GetAttribute("PVSMatrixPolicy")

		if pvsMatrixPolicy ~= MATRIX_POLICY and pvsMatrixPolicy ~= AUDITED_MATRIX_POLICY then
			self.DecodeError = "UnsupportedPVSMatrixPolicy"
			return false
		end

		if self.MapRoot:GetAttribute("PVSMatrixMutual") ~= true then
			self.DecodeError = "MissingMutualVisibilityGuarantee"
			return false
		end
	end

	if not self.StaticGeometry:IsExactGeometryComplete() then
		if typeof(pvsBarrierFingerprint) == "string" then
			if not v then
				self.DecodeError = `BarrierFingerprintError:{self.StaticGeometry:GetLoadError() or "Unavailable"}`
				return false
			end
		elseif typeof(pvsBakerVersion) == "number" and pvsBakerVersion >= 14 then
			self.DecodeError = "MissingBarrierFingerprint"
			return false
		end
	end

	self.Data = result
	self.TrustedNegatives = self.MapRoot:GetAttribute("PVSMatrixPolicy") == AUDITED_MATRIX_POLICY
		and self.MapRoot:GetAttribute("PVSMatrixMutual") == true
		and self.StaticGeometry:IsExactGeometryComplete()
	local spatialBucketSize

	if #result.regions > 2048 then
		spatialBucketSize = 8
	else
		spatialBucketSize = 64
	end

	while true do
		local total = 0

		for _, region in result.regions do
			total += (math.floor(region.maximum.X / spatialBucketSize) - math.floor(region.minimum.X / spatialBucketSize) + 1) * (math.floor(region.maximum.Y / spatialBucketSize) - math.floor(region.minimum.Y / spatialBucketSize) + 1) * (math.floor(region.maximum.Z / spatialBucketSize) - math.floor(region.minimum.Z / spatialBucketSize) + 1)
		end

		if total <= math.max(#result.regions * 16, 65536) then
			self.SpatialBucketSize = spatialBucketSize
			self.SpatialBuckets = buildSpatialBuckets(result, spatialBucketSize)
			return true
		else
			spatialBucketSize *= 2
		end
	end
end

function class:IsReady()
	return self.Data ~= nil
end

function class.TrustsNegatives(p)
	return p.Data ~= nil and p.TrustedNegatives
end

function class.GetDecodeError(p)
	return p.DecodeError
end

function class.GetStaticGeometry(p)
	return p.StaticGeometry
end

function class.ClipStaticOrigin(p, vector: Vector3, vector2: Vector3, p2: number?)
	return p.StaticGeometry:ClipOrigin(vector, vector2, p2)
end

function class:FindCells(vector: Vector3, selectionPadding: number?, value: number?, value2: number?)
	local data = self.Data

	if data == nil then
		return {}
	end

	if selectionPadding == nil then
		selectionPadding = self.SelectionPadding
	end

	local v = math.clamp(selectionPadding, 0, 512)
	local v2

	if self.VerticalSelectionPadding == nil then
		v2 = v
	else
		v2 = math.min(v, self.VerticalSelectionPadding)
	end

	local v3 = v + math.max(value or 0, 0)
	local v4 = v2 + math.max(value2 or 0, 0)
	local spatialBucketSize = self.SpatialBucketSize
	local v5 = math.floor((vector.X - v3) / spatialBucketSize)
	local v6 = math.floor((vector.X + v3) / spatialBucketSize)
	local v7 = math.floor((vector.Y - v4) / spatialBucketSize)
	local v8 = math.floor((vector.Y + v4) / spatialBucketSize)
	local v9 = math.floor((vector.Z - v3) / spatialBucketSize)
	local v10 = math.floor((vector.Z + v3) / spatialBucketSize)

	if (v6 - v5 + 1) * (v8 - v7 + 1) * (v10 - v9 + 1) > #data.regions then
		local v11 = {}
		local clusters = {}

		for _, region in data.regions do
			if
				v11[region.cluster]
				or not (vector.X >= region.minimum.X - v3)
				or not (vector.X <= region.maximum.X + v3)
				or not (vector.Y >= region.minimum.Y - v4)
			then
				continue
			end

			if not (vector.Y <= region.maximum.Y + v4 and vector.Z >= region.minimum.Z - v3 and vector.Z <= region.maximum.Z + v3) then
				continue
			end

			v11[region.cluster] = true
			clusters[#clusters + 1] = region.cluster
		end

		table.sort(clusters)
		return clusters
	else
		local v11 = {}
		local v12 = {}
		local clusters = {}

		for i = v5, v6 do
			for j = v7, v8 do
				for k = v9, v10 do
					local spatialBucket = self.SpatialBuckets[bucketKey(i, j, k)] -- inferred equivalent call

					if spatialBucket == nil then
						continue
					end

					for _, v13 in spatialBucket do
						if v11[v13] then
							continue
						end

						v11[v13] = true
						local region = data.regions[v13]
						local v14

						if
							vector.X >= region.minimum.X - v3
							and vector.X <= region.maximum.X + v3
							and vector.Y >= region.minimum.Y - v4
							and vector.Y <= region.maximum.Y + v4
							and vector.Z >= region.minimum.Z - v3
						then
							v14 = vector.Z <= region.maximum.Z + v3
						else
							v14 = false
						end

						if v12[region.cluster] or not v14 then
							continue
						end

						v12[region.cluster] = true
						clusters[#clusters + 1] = region.cluster
					end
				end
			end
		end

		table.sort(clusters)
		return clusters
	end
end

function class:SnapKey(vector: Vector3)
	local v = math.floor(vector.X / 1)
	local v2 = math.floor(vector.Y / 0.5)
	local v3 = math.floor(vector.Z / 1)

	if math.max(math.abs(v), math.abs(v2), (math.abs(v3))) >= 65536 or v ~= v or v2 ~= v2 or v3 ~= v3 then
		return nil
	end

	return bucketKey(v, v2, v3) -- inferred equivalent call
end

function class:SnapCells(vector: Vector3, p: number?)
	local snapKey = self:SnapKey(vector)

	if snapKey == nil then
		return self:FindCells(vector, p, 1, 0.5)
	end

	local v = p == nil and -1 or p
	local snapCach = self.SnapCaches[v]

	if snapCach == nil then
		snapCach = {}
		self.SnapCaches[v] = snapCach
	end

	local v2 = snapCach[snapKey]

	if v2 ~= nil then
		return v2
	end

	if self.SnapCacheCount >= 65536 then
		table.clear(self.SnapCaches)
		table.clear(self.SnapInterned)
		self.SnapCacheCount = 0
		snapCach = {}
		self.SnapCaches[v] = snapCach
	end

	local cells = self:FindCells(
		Vector3.new(
			(math.floor(vector.X / 1) + 0.5) * 1,
			(math.floor(vector.Y / 0.5) + 0.5) * 0.5,
			(math.floor(vector.Z / 1) + 0.5) * 1
		),
		p,
		0.5,
		0.25
	)
	local joined = table.concat(cells, ",")
	local frozen = self.SnapInterned[joined]

	if frozen == nil then
		frozen = table.freeze(cells)
		self.SnapInterned[joined] = frozen
	end

	snapCach[snapKey] = frozen
	self.SnapCacheCount += 1
	return frozen
end

local function validCells(list, p: number)
	for _, item in list do
		if item ~= item or item % 1 ~= 0 or item < 1 or p < item then
			return false
		end
	end

	return true
end

function class:CouldCellsSee(list, list2)
	local data = self.Data

	if data == nil or #list == 0 or #list2 == 0 then
		return true
	end

	if not (validCells(list, #data.cells) and validCells(list2, #data.cells)) then
		return true
	end

	for _, v in ipairs(list) do
		for _, v2 in ipairs(list2) do
			if PVSCodec.isVisible(data, v, v2) then
				return true
			end
		end
	end

	return false
end

function class:ClassifyCells(p, p2)
	if self:CouldCellsSee(p, p2) then
		return "VisibleWithoutRuntimeProof"
	end

	return "NeedsRuntimeOcclusionProof"
end

return table.freeze(class)