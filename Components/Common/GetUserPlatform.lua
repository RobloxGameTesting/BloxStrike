local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
return function()
	local v = {}

	if UserInputService.GamepadEnabled then
		table.insert(v, "Console")
	end

	if UserInputService.VREnabled then
		table.insert(v, "VR")
	end

	local v2 = RunService:IsStudio() and UserInputService.PreferredInput == Enum.PreferredInput.Touch

	if (UserInputService.MouseEnabled or UserInputService.KeyboardEnabled) and not v2 then
		table.insert(v, "PC")
	end

	if UserInputService.TouchEnabled and not table.find(v, "PC") then
		table.insert(v, "Mobile")
	end

	return v
end