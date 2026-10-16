local Mobile = {}
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
Mobile.MIN_SIZE = 0.04
Mobile.MAX_SIZE = 0.4
Mobile.MIN_POSITION = -2
Mobile.MAX_POSITION = 2
Mobile.DEFAULT_TRANSPARENCY = 0
Mobile.MAX_TRANSPARENCY = 0.65
Mobile.DEFAULT_ENABLED = true
local v = { "Gameplay", "Middle", "MobileButtons" }
local v2 = {
	Position = { X = 0.5, Y = 0.5 },
	Size = { X = 0.1, Y = 0.1 },
	Transparency = Mobile.DEFAULT_TRANSPARENCY,
	Enabled = Mobile.DEFAULT_ENABLED
}
local v3 = nil
local v4 = nil

local function IsFiniteNumber(value)
	return typeof(value) == "number" and value == value and value ~= 1e999 and value ~= -1e999
end

local function CopyButtonLayout(data)
	return {
		Position = { X = data.Position.X, Y = data.Position.Y },
		Size = { X = data.Size.X, Y = data.Size.Y },
		Transparency = data.Transparency,
		Enabled = data.Enabled
	}
end

local function FindAuthoredMainGui()
	local mainGui = StarterGui:FindFirstChild("MainGui")

	if mainGui then
		return mainGui
	end

	if RunService:IsClient() then
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
		local mainGui2 = playerGui and playerGui:WaitForChild("MainGui", 10)

		if mainGui2 then
			task.wait()
		end

		return mainGui2
	else
		local assets = ReplicatedStorage:WaitForChild("Assets", 10)
		local assetsUi = assets and assets:WaitForChild("UI", 10)
		return assetsUi and assetsUi:WaitForChild("MainGui", 10)
	end
end

local function FindButtonsFrameUnder(child)
	for _, childName in ipairs(v) do
		if not child then
			return nil
		end

		child = child:FindFirstChild(childName)
	end

	return child
end

local function FindHostedButtonsFrame() -- 1 equivalent call inferred from this helper
	if not RunService:IsClient() then
		return nil
	end

	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local mobileControlsGui = playerGui and playerGui:FindFirstChild("MobileControlsGui")
	return mobileControlsGui and mobileControlsGui:FindFirstChild("MobileButtons")
end

local function FindAuthoredButtonsFrame(p)
	local v5 = p or FindAuthoredMainGui()
	local v6 = os.clock() + 10

	while true do
		local selected = FindHostedButtonsFrame() or FindButtonsFrameUnder(v5) -- inferred equivalent call

		if selected then
			return selected
		end

		if v6 <= os.clock() then
			return nil
		else
			task.wait(0.1)
		end
	end
end

local function IsConfigurableButton(button) -- 1 equivalent call inferred from this helper
	return button:IsA("TextButton")
end

local function BuildDefaultLayout(p)
	local result = {}
	local names = {}
	local authoredButtonsFrame = FindAuthoredButtonsFrame(p)

	if authoredButtonsFrame then
		for _, guiObject in ipairs(authoredButtonsFrame:GetChildren()) do
			if not (IsConfigurableButton(guiObject) and guiObject:IsA("GuiObject")) then -- inferred equivalent call
				continue
			end

			result[guiObject.Name] = {
				Position = { X = guiObject.Position.X.Scale, Y = guiObject.Position.Y.Scale },
				Size = { X = guiObject.Size.X.Scale, Y = guiObject.Size.Y.Scale },
				Transparency = Mobile.DEFAULT_TRANSPARENCY,
				Enabled = Mobile.DEFAULT_ENABLED
			}
			table.insert(names, guiObject.Name)
		end
	else
		warn("[MobileHUD] Authored MobileButtons frame not found; defaults are empty")
	end

	table.sort(names)
	return result, names
end

local function EnsureDefaults()
	if v3 and v4 then
		return v3, v4
	end

	local v5, v6 = BuildDefaultLayout()

	if #v6 > 0 then
		v3 = v5
		v4 = v6
	end

	return v5, v6
end

local function HasValidPositionAndSize(p)
	if typeof(p) ~= "table" then
		return false
	end

	local position = p.Position
	local size = p.Size

	if typeof(position) ~= "table" or typeof(size) ~= "table" then
		return false
	end

	local x = position.X
	local v5

	if typeof(x) == "number" and x == x and x ~= 1e999 then
		v5 = x ~= -1e999
	else
		v5 = false
	end

	if not v5 then
		return v5
	end

	local y = position.Y

	if typeof(y) == "number" and y == y and y ~= 1e999 then
		v5 = y ~= -1e999
	else
		v5 = false
	end

	if not v5 then
		return v5
	end

	local x2 = size.X

	if typeof(x2) == "number" and x2 == x2 and x2 ~= 1e999 then
		v5 = x2 ~= -1e999
	else
		v5 = false
	end

	if v5 then
		local y2 = size.Y

		if typeof(y2) == "number" and y2 == y2 and y2 ~= 1e999 then
			return y2 ~= -1e999
		else
			return false
		end
	end

	return v5
end

function Mobile.CaptureDefaults(p)
	local v5, v6 = BuildDefaultLayout(p)

	if #v6 > 0 then
		v3 = v5
		v4 = v6
	end
end

function Mobile.GetButtonNames()
	local v5

	if v3 and v4 then
		v5 = v4
	else
		local v6
		v6, v5 = BuildDefaultLayout()

		if #v5 > 0 then
			v3 = v6
			v4 = v5
		end
	end

	return table.clone(v5)
end

function Mobile.GetDefaultLayout()
	local v5

	if v3 and v4 then
		v5 = v3
	else
		local v6
		v5, v6 = BuildDefaultLayout()

		if #v6 > 0 then
			v3 = v5
			v4 = v6
		end
	end

	local result = {}

	for k, v6 in pairs(v5) do
		result[k] = CopyButtonLayout(v6)
	end

	return result
end

function Mobile.GetDefaultButtonLayout(p: string)
	local v5

	if v3 and v4 then
		v5 = v3
	else
		local v6
		v5, v6 = BuildDefaultLayout()

		if #v6 > 0 then
			v3 = v5
			v4 = v6
		end
	end

	local v6 = v5[p]

	if v6 then
		return (CopyButtonLayout(v6))
	end

	return (CopyButtonLayout(v2))
end

function Mobile.IsKnownButton(p: string)
	local v5

	if v3 and v4 then
		v5 = v3
	else
		local v6
		v5, v6 = BuildDefaultLayout()

		if #v6 > 0 then
			v3 = v5
			v4 = v6
		end
	end

	return v5[p] ~= nil
end

function Mobile.ClampButtonLayout(data)
	return {
		Position = {
			X = math.clamp(data.Position.X, Mobile.MIN_POSITION, Mobile.MAX_POSITION),
			Y = math.clamp(data.Position.Y, Mobile.MIN_POSITION, Mobile.MAX_POSITION)
		},
		Size = {
			X = math.clamp(data.Size.X, Mobile.MIN_SIZE, Mobile.MAX_SIZE),
			Y = math.clamp(data.Size.Y, Mobile.MIN_SIZE, Mobile.MAX_SIZE)
		},
		Transparency = math.clamp(data.Transparency, 0, Mobile.MAX_TRANSPARENCY),
		Enabled = data.Enabled == true
	}
end

function Mobile.SanitizeLayout(p)
	local defaultLayout = Mobile.GetDefaultLayout()

	if typeof(p) ~= "table" then
		return defaultLayout
	end

	for k, v5 in pairs(defaultLayout) do
		local v6 = p[k]

		if not HasValidPositionAndSize(v6) then
			continue
		end

		local clampButtonLayout = Mobile.ClampButtonLayout
		local v7 = {
			Position = { X = v6.Position.X, Y = v6.Position.Y },
			Size = { X = v6.Size.X, Y = v6.Size.Y },
			Transparency = 0,
			Enabled = 0
		}
		local transparency = v6.Transparency
		local v8

		if typeof(transparency) == "number" and transparency == transparency and transparency ~= 1e999 then
			v8 = transparency ~= -1e999
		else
			v8 = false
		end

		local transparency2

		if v8 then
			transparency2 = v6.Transparency
		else
			transparency2 = v5.Transparency
		end

		v7.Transparency = transparency2
		local enabled

		if typeof(v6.Enabled) == "boolean" then
			enabled = v6.Enabled
		else
			enabled = v5.Enabled
		end

		v7.Enabled = enabled
		defaultLayout[k] = clampButtonLayout(v7)
	end

	return defaultLayout
end

function Mobile.AreButtonLayoutsEqual(data, data2)
	return data.Position.X == data2.Position.X
		and data.Position.Y == data2.Position.Y
		and data.Size.X == data2.Size.X
		and data.Size.Y == data2.Size.Y
		and data.Transparency == data2.Transparency
		and data.Enabled == data2.Enabled
end

function Mobile.AreLayoutsEqual(p, p2)
	for _, v5 in ipairs(Mobile.GetButtonNames()) do
		local v6 = p[v5] or Mobile.GetDefaultButtonLayout(v5)
		local v7 = p2[v5] or Mobile.GetDefaultButtonLayout(v5)

		if not Mobile.AreButtonLayoutsEqual(v6, v7) then
			return false
		end
	end

	return true
end

return Mobile