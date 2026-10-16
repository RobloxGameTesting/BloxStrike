local RunService = game:GetService("RunService")
local v = newproxy()
local v2 = newproxy()
local frozen = table.freeze({ "Destroy", "Disconnect", "destroy", "disconnect" })

local function GetObjectCleanupFunction(p, p2: string?)
	local typeName = typeof(p)

	if typeName == "function" then
		return v
	elseif typeName == "thread" then
		return v2
	end

	if p2 then
		return p2
	end

	if typeName == "Instance" then
		return "Destroy"
	elseif typeName == "RBXScriptConnection" then
		return "Disconnect"
	end

	if typeName == "table" then
		for _, v3 in frozen do
			if typeof(p[v3]) == "function" then
				return v3
			end
		end
	end

	error(`failed to get cleanup function for object {typeName}: {p}`, 3)
end

local function AssertPromiseLike(object) -- 1 equivalent call inferred from this helper
	if
		typeof(object) ~= "table"
		or typeof(object.getStatus) ~= "function"
		or typeof(object.finally) ~= "function"
		or typeof(object.cancel) ~= "function"
	then
		error("did not receive a promise as an argument", 3)
	end
end

local class = {}
class.__index = class

function class.new()
	local self = setmetatable({}, class)
	self._objects = {}
	self._cleaning = false
	return self
end

function class:Add(p, p2: string?)
	if self._cleaning then
		error("cannot call trove:Add() while cleaning", 2)
	end

	local v3 = { p, (GetObjectCleanupFunction(p, p2)) }
	table.insert(self._objects, v3)
	return p
end

function class:Clone(instance)
	if self._cleaning then
		error("cannot call trove:Clone() while cleaning", 2)
	end

	return self:Add(instance:Clone())
end

function class:Construct(callback, ...)
	if self._cleaning then
		error("Cannot call trove:Construct() while cleaning", 2)
	end

	local v3 = nil
	local typeName = type(callback)

	if typeName == "table" then
		v3 = callback.new(...)
	elseif typeName == "function" then
		v3 = callback(...)
	end

	return self:Add(v3)
end

function class:Connect(object, callback)
	if self._cleaning then
		error("Cannot call trove:Connect() while cleaning", 2)
	end

	return self:Add(object:Connect(callback))
end

function class:BindToRenderStep(p: string, p2: number, callback)
	if self._cleaning then
		error("cannot call trove:BindToRenderStep() while cleaning", 2)
	end

	RunService:BindToRenderStep(p, p2, callback)
	self:Add(function()
		RunService:UnbindFromRenderStep(p)
	end)
end

function class:AddPromise(object)
	if self._cleaning then
		error("cannot call trove:AddPromise() while cleaning", 2)
	end

	AssertPromiseLike(object) -- inferred equivalent call

	if object:getStatus() == "Started" then
		object:finally(function()
			if self._cleaning then
				return
			end

			self:_findAndRemoveFromObjects(object, false)
		end)
		self:Add(object, "cancel")
	end

	return object
end

function class:Remove(p)
	if self._cleaning then
		error("cannot call trove:Remove() while cleaning", 2)
	end

	return self:_findAndRemoveFromObjects(p, true)
end

function class:Extend()
	if self._cleaning then
		error("cannot call trove:Extend() while cleaning", 2)
	end

	return self:Construct(class)
end

function class:Clean()
	if self._cleaning then
		return
	end

	self._cleaning = true

	for _, object in self._objects do
		self:_cleanupObject(object[1], object[2])
	end

	table.clear(self._objects)
	self._cleaning = false
end

function class:WrapClean()
	return function()
		self:Clean()
	end
end

function class:_findAndRemoveFromObjects(p, flag: boolean)
	local objects = self._objects

	for k, object in objects do
		if object[1] ~= p then
			continue
		end

		local count = #objects
		objects[k] = objects[count]
		objects[count] = nil

		if flag then
			self:_cleanupObject(object[1], object[2])
		end

		return true
	end

	return false
end

function class:_cleanupObject(callback, p: string?)
	if p == v then
		task.spawn(callback)
	elseif p == v2 then
		pcall(task.cancel, callback)
	else
		callback[p](callback)
	end
end

function class:AttachToInstance(instance)
	if self._cleaning then
		error("cannot call trove:AttachToInstance() while cleaning", 2)
	elseif not instance:IsDescendantOf(game) then
		error("instance is not a descendant of the game hierarchy", 2)
	end

	return self:Connect(instance.Destroying, function()
		self:Destroy()
	end)
end

function class:Destroy()
	self:Clean()
end

return { new = class.new }