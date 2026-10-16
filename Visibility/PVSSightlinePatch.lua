local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PVSCodec = require(ReplicatedStorage.Visibility.PVSCodec)
local v = { 2.35, 1.7 }
local v2 = { 0.5, 2.7, 5.2 }

local function findBarrierRoot(instance)
	local barriers = instance:FindFirstChild("Barriers")

	if barriers then
		return barriers
	end

	return instance:FindFirstChild("Barriers", true)
end

local function regionsOfCell(p, cluster: number)
	local cell = p.cells[cluster]

	if cell.regions ~= nil and #cell.regions > 0 then
		return cell.regions
	end

	local result = {}

	for _, region in p.regions do
		if region.cluster == cell.id or region.cluster == cluster then
			result[#result + 1] = region
		end
	end

	if #result == 0 then
		local v3 = cell.size * 0.5
		result[1] = {
			cluster = cluster,
			minimum = cell.cframe.Position - v3,
			maximum = cell.cframe.Position + v3
		}
	end

	return result
end

return table.freeze({
	apply = function(instance, p, options)
		local v3 = options or {}
		local gridPerRegion = v3.gridPerRegion or 4
		local eyeHeights = v3.eyeHeights or v
		local targetHeights = v3.targetHeights or v2
		local yieldEveryRays = v3.yieldEveryRays or 4000
		local lastTime = os.clock()
		local barriers = instance:FindFirstChild("Barriers") or instance:FindFirstChild("Barriers", true)
		assert(barriers ~= nil, "PVSSightlinePatch: no Barriers folder")
		assert(instance:IsDescendantOf(workspace), "PVSSightlinePatch: the map must be in Workspace for raycasts")
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = { barriers }
		raycastParams.RespectCanCollide = false
		local overlapParams = OverlapParams.new()
		overlapParams.FilterType = Enum.RaycastFilterType.Include
		overlapParams.FilterDescendantsInstances = { barriers }
		local raycastParams2 = RaycastParams.new()
		raycastParams2.FilterType = Enum.RaycastFilterType.Include
		raycastParams2.FilterDescendantsInstances = { instance }
		raycastParams2.RespectCanCollide = true
		local result = {
			negativePairs = 0,
			leakingPairs = 0,
			rays = 0,
			rejectedInsideBarrier = 0,
			rejectedNoFloor = 0,
			seconds = 0
		}

		local function samples(i: number, items)
			local vectors = {}

			for _, v4 in regionsOfCell(p, i) do
				local v5 = v4.maximum - v4.minimum
				local v6 = math.clamp(math.ceil(v5.X / 5), 1, gridPerRegion)
				local v7 = math.clamp(math.ceil(v5.Z / 5), 1, gridPerRegion)

				for j = 1, v6 do
					local v8 = v4.minimum.X + (j - 0.5) * v5.X / v6

					for k = 1, v7 do
						local v9 = v4.minimum.Z + (k - 0.5) * v5.Z / v7

						for _, item in items do
							local vector = Vector3.new(v8, math.min(v4.minimum.Y + item, v4.maximum.Y - 0.1), v9)

							if #workspace:GetPartBoundsInBox(
								CFrame.new(vector),
								createVector(0.3, 0.3, 0.3),
								overlapParams
							) > 0 then
								result.rejectedInsideBarrier += 1
							elseif workspace:Raycast(vector, createVector(0, -8, 0), raycastParams2) == nil then
								result.rejectedNoFloor += 1
							else
								vectors[#vectors + 1] = vector
							end
						end
					end
				end
			end

			return vectors
		end

		local count = #p.cells
		local v4 = table.create(count)
		local v5 = table.create(count)

		for i = 1, count do
			v4[i] = samples(i, eyeHeights)
			v5[i] = samples(i, targetHeights)

			if i % 16 == 0 then
				task.wait()
			end
		end

		local rowStride = PVSCodec.getRowStride(count)
		local buf = buffer.fromstring(p.visibleBytes)

		local function clearRay(items, items2)
			for _, item in items do
				for _, item2 in items2 do
					result.rays += 1

					if result.rays % yieldEveryRays == 0 then
						task.wait()
					end

					if workspace:Raycast(item, item2 - item, raycastParams) == nil then
						return true
					end
				end
			end

			return false
		end

		local v6 = count * (count - 1) / 2
		local count2 = 0

		for i = 1, count do
			for j = i + 1, count do
				count2 += 1

				if PVSCodec.isVisible(p, i, j) or PVSCodec.isVisible(p, j, i) then
					continue
				end

				result.negativePairs += 1

				if not (clearRay(v4[i], v5[j]) or clearRay(v4[j], v5[i])) then
					continue
				end

				result.leakingPairs += 1
				PVSCodec.setVisible(buf, rowStride, i, j)
				PVSCodec.setVisible(buf, rowStride, j, i)
			end

			if v3.onProgress ~= nil then
				v3.onProgress(count2, v6, result.leakingPairs)
			end
		end

		local clone = table.clone(p)
		clone.visibleBytes = buffer.tostring(buf)
		result.seconds = os.clock() - lastTime
		return clone, result
	end
})