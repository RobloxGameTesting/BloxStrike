local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.ConsoleTypes)
local v2 = {
	Blue = 1,
	Purple = 2,
	Pink = 3,
	Red = 4,
	Special = 5
}
local v3 = {
	[8] = {
		ArrowCountOptions = {
			{ 5 },
			{ 3, 4, 4, 4 },
			{ 3, 4 },
			{ 3, 3, 3, 4 },
			{ 3 },
			{ 2, 2, 3, 3, 3 },
			{ 2 },
			{ 1 }
		},
		MinimumArrowCounts = { 5, 3, 3, 3, 3, 2, 2, 1 },
		SurvivingRowOptions = {
			{ 5 },
			{ 4 },
			{ 2, 2, 2, 3, 3 },
			{ 2, 2, 2, 2, 3 },
			{ 2, 2, 2, 2, 3 },
			{ 1, 2, 2, 2, 2 },
			{ 1, 1, 2, 2, 2 },
			{ 1 }
		},
		MinimumSurvivingRowsBeforeMiss = { 5, 4, 2, 2, 2, 2, 1, 1 }
	},
	[10] = {
		ArrowCountOptions = {
			{ 5 },
			{ 3, 4, 4, 4 },
			{ 3, 4 },
			{ 3, 4 },
			{ 3, 3, 3, 4 },
			{ 3 },
			{ 2, 2, 3, 3, 3 },
			{ 2 },
			{ 1, 2 },
			{ 1 }
		},
		MinimumArrowCounts = {
			5,
			3,
			3,
			3,
			3,
			3,
			2,
			2,
			1,
			1
		},
		SurvivingRowOptions = {
			{ 5 },
			{ 4 },
			{ 2, 2, 2, 3, 3 },
			{ 2, 2, 2, 2, 3 },
			{ 2, 2, 2, 2, 3 },
			{ 2, 2, 2, 2, 3 },
			{ 1, 2, 2, 2, 2 },
			{ 1, 1, 2, 2, 2 },
			{ 1, 1, 1, 2 },
			{ 1 }
		},
		MinimumSurvivingRowsBeforeMiss = {
			5,
			4,
			2,
			2,
			2,
			2,
			2,
			1,
			1,
			1
		}
	}
}

local function createAllRows() -- 2 equivalent calls inferred from this helper
	return {
		[0] = true,
		[1] = true,
		[2] = true,
		[3] = true,
		[4] = true
	}
end

local function countRows(items) -- 1 equivalent call inferred from this helper
	local count = 0

	for _ in items do
		count += 1
	end

	return count
end

local function choose(list) -- 2 equivalent calls inferred from this helper
	return list[math.random(1, #list)]
end

local function randomSubset(items, p: number)
	local v = {}

	for k in items do
		table.insert(v, k)
	end

	local result = {}

	for _ = 1, p do
		local v4 = math.random(1, #v)
		result[table.remove(v, v4)] = true
	end

	return result
end

local function landingRows(clone, items, p: number)
	local clone2 = table.clone(items)
	local v = {}

	if not clone[0] then
		table.insert(v, 0)
	end

	if not clone[1] then
		table.insert(v, 1)
	end

	if not clone[2] then
		table.insert(v, 2)
	end

	if not clone[3] then
		table.insert(v, 3)
	end

	if not clone[4] then
		table.insert(v, 4)
	end

	local count = countRows(items) -- inferred equivalent call

	for _ = 1, math.min(math.max(p - count, 0), #v) do
		local v4 = math.random(1, #v)
		clone2[table.remove(v, v4)] = true
	end

	return clone2
end

local function getLayout(p: number) -- 2 equivalent calls inferred from this helper
	return assert(v3[p], `[ConsoleBoardPlanner] No layout for {p} columns`)
end

local function cloneRowsByColumn(list, p: number)
	local clones = {}

	for i = 0, p - 1 do
		clones[i] = table.clone(list[i])
	end

	return clones
end

local function fitUpcomingMiss(layout, rowsByColumn, columnIndex: number, columnIndex2: number, count: number, p: number)
	local v = 0

	for _ in rowsByColumn[columnIndex2] do
		v += 1
	end

	local v4 = layout.MinimumArrowCounts[columnIndex + 1] - (5 - count)
	local v5 = 5 - math.min(count, (math.max(layout.MinimumSurvivingRowsBeforeMiss[columnIndex + 1], v4)))

	if v5 < v then
		rowsByColumn[columnIndex2] = randomSubset(createAllRows(), v5) -- inferred equivalent call
		v = v5
	end

	local v6 = math.min(count, p, 5 - v)
	return math.min(p, 5 - count + v6), v6
end

local function chooseSurvivorCount(layout, columnIndex: number, count: number, p: number, p2: number) -- 1 equivalent call inferred from this helper
	local v = math.max(1, p - (5 - count))
	local v4 = math.max(v, (math.min(p2, p)))
	return (math.clamp(choose(layout.SurvivingRowOptions[columnIndex + 1]), v, v4)) -- inferred equivalent call
end

local v = { ROW_COUNT = 5 }
v.createAllRows = createAllRows

function v.createInitialSpinRows(p: number)
	local layout = getLayout(p) -- inferred equivalent call
	local allRows = createAllRows() -- inferred equivalent call
	local result = {}

	for i = 0, p - 1 do
		result[i] = randomSubset(allRows, choose(layout.ArrowCountOptions[i + 1])) -- inferred equivalent call
	end

	return result
end

function v.prepare(p, p2, items, p3: number)
	local layout = getLayout(p3) -- inferred equivalent call
	local rowsByColumn = cloneRowsByColumn(p, p3)
	local clone = table.clone(p2)
	local survivingRows = {}
	local plannedRows = {}

	for k, item in items do
		local columnIndex = item.columnIndex
		local count = 0

		for _ in clone do
			count += 1
		end

		local v4 = 0

		for _ in rowsByColumn[columnIndex] do
			v4 += 1
		end

		local v5 = 0

		if item.result == "hit" then
			local item2 = items[k + 1]
			local v6 = math.min(count, v4)

			if item2 and item2.result == "miss" then
				v4, v6 = fitUpcomingMiss(layout, rowsByColumn, columnIndex, item2.columnIndex, count, v4)
			end

			v5 = chooseSurvivorCount(layout, columnIndex, count, v4, v6) -- inferred equivalent call
		else
			v4 = math.min(v4, 5 - count)
		end

		local v6 = randomSubset(clone, v5)
		local v7 = landingRows(clone, v6, v4)
		survivingRows[columnIndex] = v6
		plannedRows[columnIndex] = v7
		rowsByColumn[columnIndex] = v7

		if item.result == "miss" then
			break
		else
			clone = v6
		end
	end

	for i = 0, p3 - 1 do
		plannedRows[i] = plannedRows[i] or table.clone(rowsByColumn[i])
	end

	return { SpinRows = rowsByColumn, SurvivingRows = survivingRows, PlannedRows = plannedRows }
end

function v.getDisplaySteps(p)
	local v4 = nil

	for _, v5 in p.path do
		if not (v5.result == "miss" and v5.columnIndex < 3) then
			continue
		end

		v4 = v5
		break
	end

	if not v4 or v4.columnIndex ~= 2 then
		return p.path
	end

	local v5

	if v4.rarity then
		v5 = v2[v4.rarity]
	end

	if v5 and v2[p.finalRarity] < v5 then
		return p.path
	end

	local result = {}

	for _, v6 in p.path do
		if v6 == v4 then
			break
		else
			table.insert(result, v6)
		end
	end

	local clone = table.clone(v4)
	clone.hitRows = { 0, 1, 2, 3, 4 }
	clone.result = "hit"
	table.insert(result, clone)
	table.insert(result, {
		columnIndex = 3,
		kind = "bridge",
		rarity = nil,
		hitRows = {},
		result = "miss"
	})
	return result
end

return table.freeze(v)