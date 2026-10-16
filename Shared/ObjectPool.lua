local ObjectPool = {}
local class = {}
class.__index = class

local function asInstance(p)
	return p
end

local function isPoolable(instance) -- 1 equivalent call inferred from this helper
	return typeof(instance) == "Instance" and (instance:IsA("BasePart") or instance:IsA("Model"))
end

local function destroy(p) -- 6 equivalent calls inferred from this helper
	pcall(p.Destroy, p)
end

local function unparent(p) -- 1 equivalent call inferred from this helper
	return pcall(function()
		p.Parent = nil
	end)
end

local function park(p, p2) -- 2 equivalent calls inferred from this helper
	return pcall(function()
		p2.Parent = p.Storage
	end)
end

local function clone(p) -- 2 equivalent calls inferred from this helper
	return (p.Template:Clone())
end

function class:Acquire()
	assert(not self.Destroyed, "Cannot acquire from a destroyed ObjectPool")
	local v = table.remove(self.Available)

	while v and (v.Parent ~= self.Storage or not (self.InPlace or unparent(v))) do -- inferred equivalent call
		destroy(v) -- inferred equivalent call
		v = table.remove(self.Available)
	end

	local selected = v or clone(self) -- inferred equivalent call
	self.NextLease += 1
	self.Active[selected] = self.NextLease
	return selected, self.NextLease
end

function class.Release(data, p, p2: number)
	if data.Destroyed or data.Active[p] ~= p2 then
		return false
	end

	data.Active[p] = nil

	if #data.Available >= data.MaxRetained then
		destroy(p) -- inferred equivalent call
		return true
	end

	if not park(data, p) then -- inferred equivalent call
		destroy(p) -- inferred equivalent call
		return true
	end

	if data.Reset then
		local success, result = pcall(data.Reset, p)

		if not success then
			warn(`ObjectPool reset failed; discarding object: {tostring(result)}`)
			destroy(p) -- inferred equivalent call
			return true
		end
	end

	table.insert(data.Available, p)
	return true
end

function class.IsAcquired(p, p2, p3: number)
	return not p.Destroyed and p.Active[p2] == p3
end

function class:Destroy()
	if self.Destroyed then
		return
	end

	self.Destroyed = true

	for k in pairs(self.Active) do
		destroy(k) -- inferred equivalent call
	end

	self.Storage:Destroy()
	table.clear(self.Available)
	table.clear(self.Active)
end

function ObjectPool.new(instance, options)
	assert(isPoolable(instance), "ObjectPool template must be a BasePart, MeshPart, or Model") -- inferred equivalent call
	local v = options or {}
	local maxRetained = math.max(0, (math.floor(v.MaxRetained or 32)))
	local v2 = math.clamp(math.floor(v.InitialSize or 0), 0, maxRetained)
	local folder = Instance.new("Folder")
	folder.Name = v.StorageName or "ObjectPool"

	if v.StorageParent then
		folder.Parent = v.StorageParent
	end

	local self = setmetatable({
		Template = instance,
		Storage = folder,
		Available = {},
		Active = {},
		NextLease = 0,
		MaxRetained = maxRetained,
		Reset = v.Reset,
		InPlace = v.InPlace == true,
		Destroyed = false
	}, class)

	for _ = 1, v2 do
		local v3 = clone(self) -- inferred equivalent call

		if park(self, v3) then -- inferred equivalent call
			table.insert(self.Available, v3)
		else
			destroy(v3) -- inferred equivalent call
		end
	end

	return self
end

return ObjectPool