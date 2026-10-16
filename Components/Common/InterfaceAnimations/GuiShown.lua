local v = {
	IsShown = function(parent)
		while parent and parent:IsA("GuiObject") do
			if not parent.Visible then
				return false
			end

			parent = parent.Parent
		end

		return true
	end
}

function v.Observe(p, callback)
	local isShown = v.IsShown(p)
	local parent = p
	local connections = {}

	while parent and parent:IsA("GuiObject") do
		table.insert(connections, parent:GetPropertyChangedSignal("Visible"):Connect(function()
			local isShown2 = v.IsShown(p)

			if isShown2 ~= isShown then
				isShown = isShown2
				callback(isShown)
			end
		end))
		parent = parent.Parent
	end

	callback(isShown)
	return function()
		for _, connection in connections do
			connection:Disconnect()
		end

		table.clear(connections)
	end
end

return table.freeze(v)