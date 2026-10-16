local GamepadTrigger = {}
local UserInputService = game:GetService("UserInputService")
local frozen = table.freeze({
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true,
	[Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true,
	[Enum.UserInputType.Gamepad8] = true
})

function GamepadTrigger.getInputBinding(p)
	if p.KeyCode and p.KeyCode ~= Enum.KeyCode.Unknown then
		return p.KeyCode
	end

	if
		p.UserInputType == Enum.UserInputType.MouseButton1
		or p.UserInputType == Enum.UserInputType.MouseButton2
		or p.UserInputType == Enum.UserInputType.MouseButton3
	then
		return p.UserInputType
	end

	return nil
end

function GamepadTrigger.isGamepadInput(p)
	return frozen[p.UserInputType] == true
end

function GamepadTrigger.isTrigger(p, p2)
	return frozen[p.UserInputType] == true and p2[p.KeyCode] == true
end

function GamepadTrigger.isStillPressed(p, p2)
	if not GamepadTrigger.isTrigger(p, p2) then
		return false
	end

	local keyCode = p.KeyCode

	for _, v in ipairs(UserInputService:GetGamepadState(p.UserInputType)) do
		if v.KeyCode == keyCode then
			return v.Position.Z > 0.3
		end
	end

	return false
end

return GamepadTrigger