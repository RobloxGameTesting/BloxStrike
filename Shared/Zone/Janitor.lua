local RunService = game:GetService("RunService")
local Heartbeat = RunService.Heartbeat
local v = newproxy(true)

getmetatable(v).__tostring = function()
	return "IndicesReference"
end

local v2 = newproxy(true)

getmetatable(v2).__tostring = function()
	return "LinkToInstanceIndex"
end

local Janitor = {
	ClassName = "Janitor",
	__index = { CurrentlyCleaning = true, [v] = nil }
}
local v3 = { ["function"] = true, RBXScriptConnection = "Disconnect" }

function Janitor.new()
	return (setmetatable({ CurrentlyCleaning = false, [v] = nil }, Janitor))
end

function Janitor.Is(p)
	return type(p) == "table" and getmetatable(p) == Janitor
end

Janitor.is = Janitor.Is

function Janitor.__index:Add(callback, p, p2)
	if p2 == nil then
		p2 = newproxy(false)
	end

	if p2 then
		self:Remove(p2)
		local callbacks = self[v]

		if not callbacks then
			callbacks = {}
			self[v] = callbacks
		end

		callbacks[p2] = callback
	end

	local v4 = p or v3[typeof(callback)] or "Destroy"

	if type(callback) ~= "function" and not callback[v4] then
		warn(string.format(
			"Object %s doesn't have method %s, are you sure you want to add it? Traceback: %s",
			tostring(callback),
			tostring(v4),
			debug.traceback(nil, 2)
		))
	end

	self[callback] = v4
	return callback, p2
end

Janitor.__index.Give = Janitor.__index.Add

function Janitor.__index:AddObject(p)
	local v4 = newproxy(false)
	return self:Add(p, false, v4), v4
end

Janitor.__index.GiveObject = Janitor.__index.AddObject

function Janitor.__index:Remove(p)
	local v4 = self[v]
	local v5 = v4 and v4[p]

	if not v5 then
		return self
	end

	local v6 = self[v5]

	if v6 then
		if v6 == true then
			v5()
		else
			local v7 = v5[v6]

			if v7 then
				v7(v5)
			end
		end

		self[v5] = nil
	end

	v4[p] = nil
	return self
end

function Janitor.__index.Get(p, p2)
	local v4 = p[v]

	if v4 then
		return v4[p2]
	end
end

function Janitor.__index:Cleanup()
	if not self.CurrentlyCleaning then
		self.CurrentlyCleaning = nil

		for k, v4 in next, self do
			if k == v then
				continue
			end

			local typeName = type(k)

			if typeName ~= "string" and typeName ~= "number" then
				if v4 == true then
					k()
				else
					local v5 = k[v4]

					if v5 then
						v5(k)
					end
				end
			end

			self[k] = nil
		end

		local v4 = self[v]

		if v4 then
			for k in next, v4 do
				v4[k] = nil
			end

			self[v] = {}
		end

		self.CurrentlyCleaning = false
	end
end

Janitor.__index.Clean = Janitor.__index.Cleanup

function Janitor.__index:Destroy()
	self:Cleanup()
end

Janitor.__call = Janitor.__index.Cleanup
local v4 = { Connected = true }
v4.__index = v4

function v4:Disconnect()
	if self.Connected then
		self.Connected = false
		self.Connection:Disconnect()
	end
end

function v4.__tostring(p)
	return "Disconnect<" .. tostring(p.Connected) .. ">"
end

function Janitor.__index:LinkToInstance(instance, p)
	local ancestryChangedConnection = nil
	local v5 = p and newproxy(false) or v2
	local v6 = instance.Parent == nil
	local object = setmetatable({}, v4)

	local function ChangedFunction(_, parent) -- 1 equivalent call inferred from this helper
		if object.Connected then
			v6 = parent == nil

			if v6 then
				coroutine.wrap(function()
					Heartbeat:Wait()

					if not object.Connected then
						return
					end

					if not ancestryChangedConnection.Connected then
						self:Cleanup()
						return
					end

					while v6 and ancestryChangedConnection.Connected and object.Connected do
						Heartbeat:Wait()
					end

					if object.Connected and v6 then
						self:Cleanup()
					end
				end)()
			end
		end
	end

	ancestryChangedConnection = instance.AncestryChanged:Connect(ChangedFunction)
	object.Connection = ancestryChangedConnection

	if v6 then
		ChangedFunction(nil, instance.Parent) -- inferred equivalent call
	end

	return self:Add(object, "Disconnect", v5)
end

function Janitor.__index:LinkToInstances(...)
	local maid = Janitor.new()

	for _, v5 in ipairs({ ... }) do
		maid:Add(self:LinkToInstance(v5, true), "Disconnect")
	end

	return maid
end

for k, v5 in next, Janitor.__index do
	local v6 = string.sub(string.lower(k), 1, 1) .. string.sub(k, 2)
	Janitor.__index[v6] = v5
end

return Janitor