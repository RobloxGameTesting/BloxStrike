local UserInputService = game:GetService("UserInputService")

local function IsGamepadKeyCode(p) -- 1 equivalent call inferred from this helper
	local name = p.Name
	return string.match(name, "^Button") ~= nil
		or string.match(name, "^DPad") ~= nil
		or string.match(name, "^Thumbstick") ~= nil
end

return function(p)
	if p == nil or p.EnumType ~= Enum.KeyCode or not IsGamepadKeyCode(p) then -- inferred equivalent call
		return nil
	end

	local imageForKeyCode = UserInputService:GetImageForKeyCode(p)

	if imageForKeyCode == "" then
		return nil
	end

	return imageForKeyCode
end