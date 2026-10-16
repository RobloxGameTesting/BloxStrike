local RunService = game:GetService("RunService")
local parent = script.Parent
local cframe = parent.CFrame
local Angles = CFrame.Angles
RunService.Heartbeat:Connect(function()
	if not parent:IsDescendantOf(workspace) then
		return
	end

	parent.CFrame = cframe * Angles(0, 0, 0.17453292519943295 * time() % 6.283185307179586)
end)