local createVector = vector.create
local Freecam = {}
Freecam.__index = Freecam
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local CurrentCamera = workspace.CurrentCamera
local vector = Vector2.new(9.42477796076938, 5.497787143782138)
local vector2 = Vector2.new(4.71238898038469, 2.748893571891069)
local vector3 = Vector2.new(0.4, 1 / 3)
local vector4 = Vector2.new(3.839724354387525, 2.6179938779914944)

local function IsInMoveRegion(vector5: Vector3)
	local viewportSize = CurrentCamera.ViewportSize

	if viewportSize.X < viewportSize.Y then
		return vector5.Y >= viewportSize.Y * 0.6
	end

	return vector5.X <= viewportSize.X * vector3.X and vector5.Y >= viewportSize.Y * vector3.Y
end

local function ResolveTouchMoveVector(moveTouchStartPosition: Vector3, position: Vector3)
	local viewportSize = CurrentCamera.ViewportSize
	local v = math.min(viewportSize.X, viewportSize.Y) > 500 and 2 or 1
	local vector5 = Vector2.new(position.X - moveTouchStartPosition.X, position.Y - moveTouchStartPosition.Y)
	local magnitude = vector5.Magnitude

	if magnitude < v * 2 then
		return createVector(0, 0, 0)
	end

	local v2 = vector5.Unit * math.min(magnitude / (v * 20), 1)
	return (Vector3.new(v2.X, 0, v2.Y))
end

local function IsGamepadInput(input) -- 2 equivalent calls inferred from this helper
	return string.sub(input.UserInputType.Name, 1, 7) == "Gamepad"
end

local function ApplyDeadZone(point: Vector2) -- 2 equivalent calls inferred from this helper
	local magnitude = point.Magnitude

	if magnitude <= 0.15 then
		return Vector2.zero
	end

	return point.Unit * math.min((magnitude - 0.15) / 0.85, 1)
end

local function IsGamepadClaimedByUi() -- 1 equivalent call inferred from this helper
	return GuiService.SelectedObject ~= nil or GuiService.MenuIsOpen
end

local function GetTouchControlsGui() -- 1 equivalent call inferred from this helper
	if not UserInputService.TouchEnabled then
		return nil
	end

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

	if playerGui then
		return (playerGui:FindFirstChild("TouchGui"))
	end

	return nil
end

local function GetReplicationFocus() -- 1 equivalent call inferred from this helper
	local map = workspace:FindFirstChild("Map")
	local replicationFocus = map and map:FindFirstChild("ReplicationFocus")
	return replicationFocus and replicationFocus:FindFirstChild("Focus")
end

local function RemoveJanitorEntry(janitor, p: string) -- 5 equivalent calls inferred from this helper
	if janitor:Get(p) then
		janitor:Remove(p)
	end
end

function Freecam:UpdateMovement(p: number)
	local unit = createVector(0, 0, 0)

	if InputController.isActionActive("Move Forward") then
		unit += createVector(0, 0, -1)
	end

	if InputController.isActionActive("Move Backward") then
		unit += createVector(0, 0, 1)
	end

	if InputController.isActionActive("Move Left (Strafe)") then
		unit += createVector(-1, 0, 0)
	end

	if InputController.isActionActive("Move Right (Strafe)") then
		unit += createVector(1, 0, 0)
	end

	local v = 40 * (InputController.isActionActive("Walk") and 0.2 or 1)

	if unit ~= createVector(0, 0, 0) then
		unit = unit.Unit
	end

	local unit2 = unit + self.TouchMoveVector

	if GuiService.SelectedObject == nil and not GuiService.MenuIsOpen then
		local applyDeadZone = ApplyDeadZone(self.GamepadMove) -- inferred equivalent call
		unit2 += Vector3.new(applyDeadZone.X, self.GamepadRise - self.GamepadFall, -applyDeadZone.Y)
	end

	if unit2.Magnitude > 1 then
		unit2 = unit2.Unit
	end

	local cameraCFrame = self.CameraCFrame
	local lookVector = cameraCFrame.LookVector
	local v2 = cameraCFrame.RightVector * unit2.X + createVector(0, 1, 0) * unit2.Y + lookVector * -unit2.Z
	local v3 = self.CameraCFrame.Position + v2 * (v * p)
	self.CameraCFrame = CFrame.new(v3, v3 + lookVector)
	self:UpdateMouseWheel(p)
end

function Freecam:UpdateMouseWheel(_: number)
	local mouseWheelDelta = self.MouseWheelDelta

	if mouseWheelDelta == 0 then
		return
	end

	local cameraCFrame = self.CameraCFrame
	local lookVector = cameraCFrame.LookVector
	local v = 15 * (InputController.isActionActive("Walk") and 0.5 or 1)
	local v2 = lookVector * (mouseWheelDelta > 0 and v or -v)
	local v3 = cameraCFrame.Position + v2
	self.CameraCFrame = CFrame.new(v3, v3 + lookVector)
	self.MouseWheelDelta = 0
end

function Freecam:UpdateRotation(p: number)
	local zero

	if self.MoveTouch ~= nil or self.LookTouch ~= nil then
		zero = Vector2.zero
	else
		zero = UserInputService:GetMouseDelta()
	end

	local v = InputController.isActionActive("Walk") and 0.5 or 1
	local viewportSize = CurrentCamera.ViewportSize
	local v2 = zero.X / viewportSize.X * (vector.X * v)
	local v3 = zero.Y / viewportSize.Y * (vector.Y * v)
	local touchLookDelta = self.TouchLookDelta

	if touchLookDelta ~= Vector2.zero then
		self.TouchLookDelta = Vector2.zero
		v2 += touchLookDelta.X / viewportSize.X * (vector2.X * v)
		v3 += touchLookDelta.Y / viewportSize.Y * (vector2.Y * v)
	end

	local zero2

	if IsGamepadClaimedByUi() then -- inferred equivalent call
		zero2 = Vector2.zero
	else
		zero2 = ApplyDeadZone(self.GamepadLook) -- inferred equivalent call
	end

	if zero2 ~= Vector2.zero then
		local v4 = zero2.Unit * zero2.Magnitude ^ 2
		v2 += v4.X * vector4.X * v * p
		v3 -= v4.Y * vector4.Y * v * p
	end

	local cameraCFrame = self.CameraCFrame
	local position = cameraCFrame.Position
	local lookVector = cameraCFrame.LookVector
	local v4 = math.clamp(math.asin(lookVector.Y) - v3, -1.3962634015954636, 1.3962634015954636)
	local vector5 = Vector3.new(lookVector.X, 0, lookVector.Z)
	local magnitude = vector5.Magnitude
	local v5 = magnitude < 0.001 and createVector(0, 0, -1) or vector5 / magnitude
	local v6 = math.atan2(-v5.X, -v5.Z) - v2
	local v7 = math.cos(v4)
	local vector6 = Vector3.new(-math.sin(v6) * v7, math.sin(v4), -math.cos(v6) * v7)
	self.CameraCFrame = CFrame.new(position, position + vector6)
end

function Freecam:ReleaseEndedTouches()
	local moveTouch = self.MoveTouch

	if moveTouch and moveTouch.UserInputState == Enum.UserInputState.End then
		self.MoveTouch = nil
		self.TouchMoveVector = createVector(0, 0, 0)
	end

	local lookTouch = self.LookTouch

	if lookTouch and lookTouch.UserInputState == Enum.UserInputState.End then
		self.LookTouch = nil
	end
end

function Freecam:ResetTouchInput()
	self.TouchLookDelta = Vector2.zero
	self.TouchMoveVector = createVector(0, 0, 0)
	self.MoveTouch = nil
	self.MoveTouchStartPosition = createVector(0, 0, 0)
	self.LookTouch = nil
end

function Freecam:ResetGamepadInput()
	self.GamepadMove = Vector2.zero
	self.GamepadLook = Vector2.zero
	self.GamepadRise = 0
	self.GamepadFall = 0
end

function Freecam:ShowTouchControls()
	local touchControlsGui = GetTouchControlsGui() -- inferred equivalent call

	if not touchControlsGui then
		return
	end

	local function applyVisibility() -- 1 equivalent call inferred from this helper
		touchControlsGui.Enabled = self.IsActive and GuiService.TouchControlsEnabled
	end

	applyVisibility() -- inferred equivalent call
	self.Janitor:Add(
		touchControlsGui:GetPropertyChangedSignal("Enabled"):Connect(applyVisibility),
		"Disconnect",
		"TouchControlsEnabledGuard"
	)
	self.Janitor:Add(
		GuiService:GetPropertyChangedSignal("TouchControlsEnabled"):Connect(applyVisibility),
		"Disconnect",
		"TouchControlsSettingGuard"
	)
	self.Janitor:Add(function()
		touchControlsGui.Enabled = LocalPlayer.Character ~= nil and GuiService.TouchControlsEnabled
	end, true, "RestoreTouchControls")
end

function Freecam:Render(p: number)
	self:ReleaseEndedTouches()
	self:UpdateMovement(p)
	self:UpdateRotation(p)
	CurrentCamera.CFrame = self.CameraCFrame
end

function Freecam:Start()
	if self.IsActive then
		return
	end

	self.IsActive = true
	self.CameraCFrame = CurrentCamera.CFrame
	self.MouseWheelDelta = 0
	self:ResetTouchInput()
	self:ResetGamepadInput()
	self:ShowTouchControls()
	CurrentCamera.CameraType = Enum.CameraType.Scriptable
	CameraController.setMouseEnabled(false)
	self.Janitor:Add(UserInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
		if self.IsActive and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		end
	end), "Disconnect", "EnforceMouseBehavior")
	RunServiceController.BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value + 10, function(p: number)
		if self.IsActive then
			self:Render(p)
		end
	end)
	local replicationFocus = GetReplicationFocus() -- inferred equivalent call

	if replicationFocus then
		LocalPlayer.ReplicationFocus = replicationFocus
		self.Janitor:Add(function()
			LocalPlayer.ReplicationFocus = nil
		end, true, "ReplicationFocus")
	end

	self.Janitor:Add(function()
		RunServiceController.UnbindFromRenderStep("Freecam")
	end, true)
end

function Freecam:Stop()
	if not self.IsActive then
		return
	end

	self.IsActive = false
	RunServiceController.UnbindFromRenderStep("Freecam")
	self:ResetTouchInput()
	self:ResetGamepadInput()
	RemoveJanitorEntry(self.Janitor, "TouchControlsEnabledGuard") -- inferred equivalent call
	RemoveJanitorEntry(self.Janitor, "TouchControlsSettingGuard") -- inferred equivalent call
	RemoveJanitorEntry(self.Janitor, "RestoreTouchControls") -- inferred equivalent call
	CurrentCamera.CameraType = Enum.CameraType.Custom
	RemoveJanitorEntry(self.Janitor, "EnforceMouseBehavior") -- inferred equivalent call
	RemoveJanitorEntry(self.Janitor, "ReplicationFocus") -- inferred equivalent call
end

function Freecam.new()
	local object = setmetatable({}, Freecam)
	object.Janitor = Janitor.new()
	object.CameraCFrame = CFrame.identity
	object.MouseWheelDelta = 0
	object.TouchLookDelta = Vector2.zero
	object.TouchMoveVector = createVector(0, 0, 0)
	object.MoveTouchStartPosition = createVector(0, 0, 0)
	object.GamepadMove = Vector2.zero
	object.GamepadLook = Vector2.zero
	object.GamepadRise = 0
	object.GamepadFall = 0
	object.IsActive = false
	object.Janitor:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not object.IsActive or input.UserInputType ~= Enum.UserInputType.Touch or gameProcessed then
			return
		end

		if not object.MoveTouch then
			local position = input.Position
			local viewportSize = CurrentCamera.ViewportSize
			local v

			if viewportSize.X < viewportSize.Y then
				v = position.Y >= viewportSize.Y * 0.6
			elseif position.X <= viewportSize.X * vector3.X then
				v = position.Y >= viewportSize.Y * vector3.Y
			else
				v = false
			end

			if v then
				object.MoveTouch = input
				object.MoveTouchStartPosition = input.Position
				object.TouchMoveVector = createVector(0, 0, 0)
				return
			end
		end

		if not object.LookTouch then
			object.LookTouch = input
		end
	end), "Disconnect")
	object.Janitor:Add(UserInputService.InputChanged:Connect(function(input, gameProcessed)
		if not object.IsActive then
			return
		end

		if IsGamepadInput(input) then -- inferred equivalent call
			local keyCode = input.KeyCode

			if keyCode == Enum.KeyCode.Thumbstick1 then
				object.GamepadMove = Vector2.new(input.Position.X, input.Position.Y)
			elseif keyCode == Enum.KeyCode.Thumbstick2 then
				object.GamepadLook = Vector2.new(input.Position.X, input.Position.Y)
			elseif keyCode == Enum.KeyCode.ButtonR2 then
				object.GamepadRise = input.Position.Z
			elseif keyCode == Enum.KeyCode.ButtonL2 then
				object.GamepadFall = input.Position.Z
			end
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			if not gameProcessed then
				object.MouseWheelDelta = input.Position.Z
			end
		else
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if input == object.MoveTouch then
				object.TouchMoveVector = ResolveTouchMoveVector(object.MoveTouchStartPosition, input.Position)
			elseif input == object.LookTouch then
				object.TouchLookDelta += Vector2.new(input.Delta.X, input.Delta.Y)
			end
		end
	end), "Disconnect")
	object.Janitor:Add(UserInputService.InputEnded:Connect(function(input)
		if IsGamepadInput(input) then -- inferred equivalent call
			local keyCode = input.KeyCode

			if keyCode == Enum.KeyCode.Thumbstick1 then
				object.GamepadMove = Vector2.zero
			elseif keyCode == Enum.KeyCode.Thumbstick2 then
				object.GamepadLook = Vector2.zero
			elseif keyCode == Enum.KeyCode.ButtonR2 then
				object.GamepadRise = 0
			elseif keyCode == Enum.KeyCode.ButtonL2 then
				object.GamepadFall = 0
			end
		else
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if input == object.MoveTouch then
				object.MoveTouch = nil
				object.TouchMoveVector = createVector(0, 0, 0)
			elseif input == object.LookTouch then
				object.LookTouch = nil
			end
		end
	end), "Disconnect")
	object.Janitor:Add(function()
		if object.IsActive then
			object:Stop()
		end
	end)
	return object
end

function Freecam:Destroy()
	self.Janitor:Destroy()
end

return Freecam