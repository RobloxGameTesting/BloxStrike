local HttpService = game:GetService("HttpService")
local random = Random.new()

local function Copy(p, flag: boolean?) -- 4 equivalent calls inferred from this helper
	if not flag then
		return (table.clone(p))
	end

	local function DeepCopy(p2)
		local clone = table.clone(p2)

		for k, v in clone do
			if type(v) == "table" then
				clone[k] = DeepCopy(v)
			end
		end

		return clone
	end

	return (DeepCopy(p))
end

local function Sync(p, item)
	assert(type(p) == "table", "First argument must be a table")
	assert(type(item) == "table", "Second argument must be a table")
	local clone = table.clone(p)

	for k, v in pairs(clone) do
		local item2 = item[k]

		if item2 == nil then
			clone[k] = nil
		elseif type(v) == type(item2) then
			if type(v) == "table" then
				clone[k] = Sync(v, item2)
			end
		elseif type(item2) == "table" then
			clone[k] = Copy(item2, true) -- inferred equivalent call
		else
			clone[k] = item2
		end
	end

	for k, item2 in pairs(item) do
		if clone[k] ~= nil then
			continue
		end

		if type(item2) == "table" then
			clone[k] = Copy(item2, true) -- inferred equivalent call
		else
			clone[k] = item2
		end
	end

	return clone
end

local function Reconcile(p, item)
	assert(type(p) == "table", "First argument must be a table")
	assert(type(item) == "table", "Second argument must be a table")
	local clone = table.clone(p)

	for k, item2 in item do
		local v = p[k]

		if v == nil then
			if type(item2) == "table" then
				clone[k] = Copy(item2, true) -- inferred equivalent call
			else
				clone[k] = item2
			end
		elseif type(v) == "table" then
			if type(item2) == "table" then
				clone[k] = Reconcile(v, item2)
			else
				clone[k] = Copy(v, true) -- inferred equivalent call
			end
		end
	end

	return clone
end

local function SwapRemove(list, index: number) -- 1 equivalent call inferred from this helper
	local count = #list
	list[index] = list[count]
	list[count] = nil
end

local function Map(list, callback)
	assert(type(list) == "table", "First argument must be a table")
	assert(type(callback) == "function", "Second argument must be a function")
	local result = table.create(#list)

	for k, v in list do
		result[k] = callback(v, k, list)
	end

	return result
end

local TableUtil = {}
TableUtil.Copy = Copy
TableUtil.Sync = Sync
TableUtil.Reconcile = Reconcile
TableUtil.SwapRemove = SwapRemove

function TableUtil.SwapRemoveFirstValue(list, p)
	local index = table.find(list, p)

	if index then
		SwapRemove(list, index) -- inferred equivalent call
	end

	return index
end

TableUtil.Map = Map

function TableUtil.Filter(list, callback)
	assert(type(list) == "table", "First argument must be a table")
	assert(type(callback) == "function", "Second argument must be a function")
	local result = table.create(#list)

	if #list > 0 then
		local count = 0

		for k, v in list do
			if not callback(v, k, list) then
				continue
			end

			count += 1
			result[count] = v
		end

		return result
	else
		for k, v in list do
			if callback(v, k, list) then
				result[k] = v
			end
		end

		return result
	end
end

function TableUtil.Reduce(list, callback, p)
	assert(type(list) == "table", "First argument must be a table")
	assert(type(callback) == "function", "Second argument must be a function")

	if #list > 0 then
		local v

		if p == nil then
			p = list[1]
			v = 2
		else
			v = 1
		end

		for i = v, #list do
			p = callback(p, list[i], i, list)
		end

		return p
	else
		local v

		if p == nil then
			v = next(list)
			p = v
		end

		for k, v2 in next, list, v do
			p = callback(p, v2, k, list)
		end

		return p
	end
end

function TableUtil.Assign(p, ...)
	local clone = table.clone(p)

	for _, v in { ... } do
		for k, v2 in v do
			clone[k] = v2
		end
	end

	return clone
end

function TableUtil.Extend(p, items)
	local clone = table.clone(p)

	for _, item in items do
		table.insert(clone, item)
	end

	return clone
end

function TableUtil.Reverse(list)
	local count = #list
	local result = table.create(count)

	for i = 1, count do
		result[i] = list[count - i + 1]
	end

	return result
end

function TableUtil.Shuffle(list, object)
	assert(type(list) == "table", "First argument must be a table")
	local clone = table.clone(list)

	if typeof(object) ~= "Random" then
		object = random
	end

	for i = #list, 2, -1 do
		local integer = object:NextInteger(1, i)
		local v = clone[integer]
		local v2 = clone[i]
		clone[i] = v
		clone[integer] = v2
	end

	return clone
end

function TableUtil.Sample(list, value: number, object)
	assert(type(list) == "table", "First argument must be a table")
	assert(type(value) == "number", "Second argument must be a number")
	local count = #list

	if count == 0 then
		return {}
	end

	local clone = table.clone(list)
	local v = table.create(value)

	if typeof(object) ~= "Random" then
		object = random
	end

	local v2 = math.clamp(value, 1, count)

	for i = 1, v2 do
		local integer = object:NextInteger(i, count)
		local v3 = clone[integer]
		local v4 = clone[i]
		clone[i] = v3
		clone[integer] = v4
	end

	table.move(clone, 1, v2, 1, v)
	return v
end

function TableUtil.Flat(list, value: number?)
	local v = type(value) ~= "number" and 1 or value
	local result = table.create(#list)
	local function Scan(items, p: number)
		for _, item in items do
			if type(item) == "table" and p < v then
				Scan(item, p + 1)
			else
				table.insert(result, item)
			end
		end
	end

	Scan(list, 0)
	return result
end

function TableUtil.FlatMap(p, callback)
	local map = Map(p, callback)
	local result = table.create(#map)
	local v = 1
	local function Scan(items, p2: number)
		for _, item in items do
			if type(item) == "table" and p2 < v then
				Scan(item, p2 + 1)
			else
				table.insert(result, item)
			end
		end
	end

	Scan(map, 0)
	return result
end

function TableUtil.Keys(list)
	local result = table.create(#list)

	for k in list do
		table.insert(result, k)
	end

	return result
end

function TableUtil.Values(list)
	local result = table.create(#list)

	for _, v in list do
		table.insert(result, v)
	end

	return result
end

function TableUtil.Find(items, callback)
	for k, item in items do
		if callback(item, k, items) then
			return item, k
		end
	end

	return nil, nil
end

function TableUtil.Every(items, callback)
	for k, item in items do
		if not callback(item, k, items) then
			return false
		end
	end

	return true
end

function TableUtil.Some(items, callback)
	for k, item in items do
		if callback(item, k, items) then
			return true
		end
	end

	return false
end

function TableUtil.Truncate(list, value: number)
	local count = #list
	local v = math.clamp(value, 1, count)

	if v == count then
		return (table.clone(list))
	end

	return (table.move(list, 1, v, 1, table.create(v)))
end

function TableUtil.Zip(...)
	assert(select("#", ...) > 0, "Must supply at least 1 table")

	local function ZipIteratorArray(items, p: number)
		local v = p + 1
		local result = {}

		for k, item in items do
			local v2 = item[v]

			if v2 == nil then
				return nil, nil
			else
				result[k] = v2
			end
		end

		return v, result
	end

	local function ZipIteratorMap(items, p)
		local result = {}

		for k, item in items do
			local v = next(item, p)

			if v == nil then
				return nil, nil
			else
				result[k] = v
			end
		end

		return p, result
	end

	local v = { ... }

	if #v[1] > 0 then
		return ZipIteratorArray, v, 0
	end

	return ZipIteratorMap, v, nil
end

function TableUtil.Lock(p)
	local function Freeze(list)
		for k, v in pairs(list) do
			if type(v) == "table" then
				list[k] = Freeze(v)
			end
		end

		return table.freeze(list)
	end

	return Freeze(p)
end

function TableUtil.IsEmpty(items)
	return next(items) == nil
end

function TableUtil.EncodeJSON(p)
	return HttpService:JSONEncode(p)
end

function TableUtil.DecodeJSON(json: string)
	return HttpService:JSONDecode(json)
end

return TableUtil