local function defaultGuard(_)
	return true
end

local function observeAttribute(instance, attributeName: string, callback, callback2)
	local v = nil
	local connection = nil
	local count = 0

	if callback2 == nil then
		callback2 = defaultGuard
	end

	local function OnAttributeChanged()
		if v ~= nil then
			task.spawn(v)
			v = nil
		end

		count += 1
		local v2 = count
		local attribute = instance:GetAttribute(attributeName)

		if attribute ~= nil and callback2(attribute) then
			task.spawn(function()
				local v3 = callback(attribute)

				if v2 == count and connection.Connected then
					v = v3
				else
					task.spawn(v3)
				end
			end)
		end
	end

	connection = instance:GetAttributeChangedSignal(attributeName):Connect(OnAttributeChanged)
	task.defer(function()
		if not connection.Connected then
			return
		end

		OnAttributeChanged()
	end)
	return function()
		connection:Disconnect()

		if v ~= nil then
			task.spawn(v)
			v = nil
		end
	end
end

return observeAttribute