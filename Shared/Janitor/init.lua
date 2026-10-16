local GetPromiseLibrary = require(script.GetPromiseLibrary)
local RbxScriptConnection = require(script.RbxScriptConnection)
local Symbol = require(script.Symbol)
local v, v2 = GetPromiseLibrary()
local symbol = Symbol("IndicesReference")
local symbol2 = Symbol("LinkToInstanceIndex")
local Janitor = {
	ClassName = "Janitor",
	CurrentlyCleaning = true,
	SuppressInstanceReDestroy = false,
	[symbol] = nil
}
Janitor.__index = Janitor
local v3 = { ["function"] = true, thread = true, RBXScriptConnection = "Disconnect" }

function Janitor.new()
	return (setmetatable({ CurrentlyCleaning = false, [symbol] = nil }, Janitor))
end

function Janitor.Is(p)
	return type(p) == "table" and getmetatable(p) == Janitor
end

function Janitor:Add(p, p2, p3)
	if p3 then
		self:Remove(p3)
		local v4 = self[symbol]

		if not v4 then
			v4 = {}
			self[symbol] = v4
		end

		v4[p3] = p
	end

	local typeName = typeof(p)
	local v4 = p2 or v3[typeName] or "Destroy"

	if typeName == "function" or typeName == "thread" then
		if v4 ~= true then
			warn(string.format(
				"Object is a %s and as such expected `true?` for the method name and instead got %s. Traceback: %s",
				typeName,
				tostring(v4),
				debug.traceback(nil, 2)
			))
		end
	elseif not p[v4] then
		warn(string.format(
			"Object %s doesn't have method %s, are you sure you want to add it? Traceback: %s",
			tostring(p),
			tostring(v4),
			debug.traceback(nil, 2)
		))
	end

	self[p] = v4
	return p
end

function Janitor:AddPromise(object)
	if not v then
		return object
	end

	if not v2.is(object) then
		error(string.format(
			"Invalid argument #1 to 'Janitor:AddPromise' (Promise expected, got %s (%s)) Traceback: %s",
			typeof(object),
			tostring(object),
			debug.traceback(nil, 2)
		))
	end

	if object:getStatus() ~= v2.Status.Started then
		return object
	end

	local v4 = newproxy(false)
	local v5 = self:Add(v2.new(function(callback, _, callback2)
		if callback2(function()
			object:cancel()
		end) then
			return
		end

		callback(object)
	end), "cancel", v4)
	v5:finallyCall(self.Remove, self, v4)
	return v5
end

function Janitor:Remove(p)
	local v4 = self[symbol]
	local v5 = v4 and v4[p]

	if not v5 then
		return self
	end

	local v6 = self[v5]

	if v6 then
		if v6 == true then
			if type(v5) == "function" then
				v5()
			else
				local v7

				if coroutine.running() ~= v5 then
					v7 = pcall(function()
						task.cancel(v5)
					end)
				end

				if not v7 then
					task.defer(function()
						if v5 then
							task.cancel(v5)
						end
					end)
				end
			end
		else
			local v7 = v5[v6]

			if v7 then
				if self.SuppressInstanceReDestroy and v6 == "Destroy" and typeof(v5) == "Instance" then
					pcall(v7, v5)
				else
					v7(v5)
				end
			end
		end

		self[v5] = nil
	end

	v4[p] = nil
	return self
end

function Janitor:RemoveNoClean(p)
	local v4 = self[symbol]

	if not v4 then
		return self
	end

	local v5 = v4[p]

	if v5 then
		self[v5] = nil
	end

	v4[p] = nil
	return self
end

function Janitor:RemoveList(...)
	if not self[symbol] then
		return self
	end

	local v4 = select("#", ...)

	if v4 == 1 then
		return self:Remove(...)
	end

	for i = 1, v4 do
		self:Remove(select(i, ...))
	end

	return self
end

function Janitor:RemoveListNoClean(...)
	local v4 = self[symbol]

	if not v4 then
		return self
	end

	local v5 = select("#", ...)

	if v5 == 1 then
		return self:RemoveNoClean(...)
	end

	for i = 1, v5 do
		local v6 = select(i, ...)
		local v7 = v4[v6]

		if v7 then
			self[v7] = nil
		end

		v4[v6] = nil
	end

	return self
end

function Janitor.Get(p, p2)
	local v4 = p[symbol]

	if v4 then
		return v4[p2]
	end

	return nil
end

function Janitor.GetAll(p)
	local v4 = p[symbol]

	if v4 then
		return (table.freeze(table.clone(v4)))
	end

	return {}
end

local function GetFenv(items) -- 1 equivalent call inferred from this helper
	return function()
		for k, item in next, items do
			if k ~= symbol then
				return k, item
			end
		end
	end
end

function Janitor:Cleanup()
	if not self.CurrentlyCleaning then
		self.CurrentlyCleaning = nil
		local fenv = GetFenv(self) -- inferred equivalent call
		local v4, v5 = fenv()

		while v4 and v5 do
			if v5 == true then
				if type(v4) == "function" then
					v4()
				else
					local v6

					if coroutine.running() ~= v4 then
						v6 = pcall(function()
							task.cancel(v4)
						end)
					end

					if not v6 then
						task.defer(function()
							if v4 then
								task.cancel(v4)
							end
						end)
					end
				end
			else
				local v6 = v4[v5]

				if v6 then
					if self.SuppressInstanceReDestroy and v5 == "Destroy" and typeof(v4) == "Instance" then
						pcall(v6, v4)
					else
						v6(v4)
					end
				end
			end

			self[v4] = nil
			local v6
			v6, v5 = fenv()
			v4 = v6
		end

		local v6 = self[symbol]

		if v6 then
			table.clear(v6)
			self[symbol] = {}
		end

		self.CurrentlyCleaning = false
	end
end

function Janitor:Destroy()
	self:Cleanup()
end

Janitor.__call = Janitor.Cleanup

function Janitor:LinkToInstance(instance, flag: boolean?)
	local v4 = flag and newproxy(false) or symbol2
	return self:Add(instance.Destroying:Connect(function()
		self:Cleanup()
	end), "Disconnect", v4)
end

function Janitor:LegacyLinkToInstance(instance, flag: boolean?)
	local ancestryChangedConnection = nil
	local v4 = flag and newproxy(false) or symbol2
	local v5 = instance.Parent == nil
	local object = setmetatable({}, RbxScriptConnection)

	local function ChangedFunction(_, parent) -- 1 equivalent call inferred from this helper
		if object.Connected then
			v5 = parent == nil

			if v5 then
				task.defer(function()
					if not object.Connected then
						return
					end

					if not ancestryChangedConnection.Connected then
						self:Cleanup()
						return
					end

					while v5 and ancestryChangedConnection.Connected and object.Connected do
						task.wait()
					end

					if object.Connected and v5 then
						self:Cleanup()
					end
				end)
			end
		end
	end

	ancestryChangedConnection = instance.AncestryChanged:Connect(ChangedFunction)
	object.Connection = ancestryChangedConnection

	if v5 then
		ChangedFunction(nil, instance.Parent) -- inferred equivalent call
	end

	return self:Add(object, "Disconnect", v4)
end

function Janitor:LinkToInstances(...)
	local maid = Janitor.new()

	for _, v4 in { ... } do
		maid:Add(self:LinkToInstance(v4, true), "Disconnect")
	end

	return maid
end

function Janitor.__tostring(_)
	return "Janitor"
end

table.freeze(Janitor)
return Janitor