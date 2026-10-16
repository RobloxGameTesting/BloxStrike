local Signal = require(script.Parent.Signal)
local Value = {}
Value.__index = Value

function Value.new(p)
	return (setmetatable({
		_value = p,
		_changed = Signal.new(),
		__tostring = function(p2)
			return "Value<" .. p2._value .. ">"
		end
	}, Value))
end

function Value:Observe(on_changed)
	on_changed(self._value)
	return self._changed:Connect(on_changed)
end

function Value:Subscribe(on_changed)
	return self._changed:Connect(on_changed)
end

function Value:Set(p, flag: boolean?)
	if not flag and p == self._value then
		return
	end

	self._value = p
	self._changed:Fire(p)
end

function Value:Get()
	return self._value
end

function Value:Destroy()
	self._changed:Destroy()
end

return Value