local CollectionService = game:GetService("CollectionService")

function observeTag(tag: string, callback, items)
	local v = {}
	local v2 = {}
	local connection = nil

	local function IsGoodAncestor(instance)
		if items == nil then
			return true
		end

		for _, ancestor in items do
			if instance:IsDescendantOf(ancestor) then
				return true
			end
		end

		return false
	end

	local function AttemptStartup(instance) -- 1 equivalent call inferred from this helper
		v[instance] = "__inflight__"
		task.defer(function()
			if v[instance] ~= "__inflight__" then
				return
			end

			local success, result = xpcall(function(p)
				local v3 = callback(p)

				if v3 ~= nil then
					assert(typeof(v3) == "function", "callback must return a function or nil")
				end

				return v3
			end, debug.traceback, instance)

			if success then
				if v[instance] == "__inflight__" then
					v[instance] = result
				elseif result ~= nil then
					task.spawn(result)
				end
			else
				local v3 = string.split(result, "\n")[1]
				local v4 = string.find(v3, ": ")
				local v5 = not v4 and "" or v3:sub(v4 + 1)
				warn(`error while calling observeTag("{tag}") callback:{v5}\n{result}`)
			end
		end)
	end

	local function AttemptCleanup(p) -- 2 equivalent calls inferred from this helper
		local v3 = v[p]
		v[p] = "__dead__"

		if typeof(v3) == "function" then
			task.spawn(v3)
		end
	end

	local function OnAncestryChanged(instance) -- 2 equivalent calls inferred from this helper
		local flag

		if items == nil then
			flag = true
		else
			local flag2 = true

			for _, ancestor in items do
				if not instance:IsDescendantOf(ancestor) then
					continue
				end

				flag = true
				flag2 = false
				break
			end

			if flag2 then
				flag = false
			end
		end

		if flag then
			if v[instance] == "__dead__" then
				AttemptStartup(instance) -- inferred equivalent call
			end
		else
			AttemptCleanup(instance) -- inferred equivalent call
		end
	end

	local function OnInstanceAdded(instance)
		if not (connection.Connected and v[instance] == nil) then
			return
		end

		v[instance] = "__dead__"
		v2[instance] = instance.AncestryChanged:Connect(function()
			OnAncestryChanged(instance) -- inferred equivalent call
		end)
		OnAncestryChanged(instance) -- inferred equivalent call
	end

	local function OnInstanceRemoved(p) -- 1 equivalent call inferred from this helper
		AttemptCleanup(p) -- inferred equivalent call
		local connection2 = v2[p]

		if connection2 then
			connection2:Disconnect()
			v2[p] = nil
		end

		v[p] = nil
	end

	connection = CollectionService:GetInstanceAddedSignal(tag):Connect(OnInstanceAdded)
	local connection2 = CollectionService:GetInstanceRemovedSignal(tag):Connect(OnInstanceRemoved)
	task.defer(function()
		if not connection.Connected then
			return
		end

		for _, v3 in CollectionService:GetTagged(tag) do
			task.spawn(OnInstanceAdded, v3)
		end
	end)
	return function()
		connection:Disconnect()
		connection2:Disconnect()
		local v3 = next(v)

		while v3 do
			OnInstanceRemoved(v3) -- inferred equivalent call
			v3 = next(v)
		end
	end
end

return observeTag