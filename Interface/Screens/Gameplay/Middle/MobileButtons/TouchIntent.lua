local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local CameraInput = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("CameraInput"))
local v = {}
local v2 = {}

local function toVector2(position: Vector3) -- 2 equivalent calls inferred from this helper
	return Vector2.new(position.X, position.Y)
end

local function getDragDistance() -- 1 equivalent call inferred from this helper
	local currentCamera = Workspace.CurrentCamera

	if not currentCamera then
		return 8
	end

	local viewportSize = currentCamera.ViewportSize
	return (math.max(8, math.min(viewportSize.X, viewportSize.Y) * 0.03))
end

local function isInCore(button, startPosition: Vector2) -- 1 equivalent call inferred from this helper
	local halfAbsoluteSize = button.AbsoluteSize / 2
	local v3 = startPosition - (button.AbsolutePosition + halfAbsoluteSize)
	local v4 = halfAbsoluteSize * 0.6
	return math.abs(v3.X) <= v4.X and math.abs(v3.Y) <= v4.Y
end

local function firePendingTap(input) -- 1 equivalent call inferred from this helper
	local v3 = v[input]

	if not v3 or v3.isDrag or not v3.pendingTap then
		return
	end

	local pendingTap = v3.pendingTap
	v3.pendingTap = nil
	pendingTap()
end

local function promoteToDrag(input, state, point: Vector2) -- 1 equivalent call inferred from this helper
	state.isDrag = true
	state.pendingTap = nil
	v2[state.button] = true

	if state.onDrag then
		state.onDrag(input)
	end

	CameraInput.addTouchMove(point)
end

UserInputService.InputChanged:Connect(function(input)
	local v3 = v[input]

	if not v3 then
		return
	end

	if v3.isDrag then
		CameraInput.addTouchMove(Vector2.new(input.Delta.X, input.Delta.Y))
		return
	end

	local v4 = toVector2(input.Position) - v3.startPosition -- inferred equivalent call
	local magnitude = v4.Magnitude

	if getDragDistance() < magnitude then -- inferred equivalent call
		promoteToDrag(input, v3, v4) -- inferred equivalent call
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if not v[input] then
		return
	end

	firePendingTap(input) -- inferred equivalent call
	task.defer(function()
		v[input] = nil
	end)
end)
local TouchIntent = {}

function TouchIntent.track(p, button, onDrag)
	if p.UserInputType ~= Enum.UserInputType.Touch or v[p] then
		return
	end

	v[p] = {
		button = button,
		startPosition = toVector2(p.Position), -- inferred equivalent call
		isDrag = false,
		onDrag = onDrag,
		pendingTap = nil
	}
	v2[button] = false
end

function TouchIntent.onTap(p, pendingTap)
	local v3 = v[p]

	if v3 and not isInCore(v3.button, v3.startPosition) then -- inferred equivalent call
		v3.pendingTap = pendingTap
		task.delay(0.07, firePendingTap, p)
		return
	end

	pendingTap()
end

function TouchIntent.lastTouchWasDrag(p)
	return v2[p] == true
end

return TouchIntent