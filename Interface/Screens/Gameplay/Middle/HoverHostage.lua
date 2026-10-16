local HoverHostage = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local InputController = require(ReplicatedStorage.Controllers.InputController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local CenterScreenRaycast = require(ReplicatedStorage.Components.Common.CenterScreenRaycast)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local v = nil
local deadChangedConnection = nil
local childAddedConnection = nil
local connection = nil

local function FormatKeybind(value: string?)
	if value then
		return value:gsub("Enum%.KeyCode%.", ""):gsub("Enum%.UserInputType%.", ""):gsub("Enum%.CustomInputType%.", "")
	end

	return "E"
end

local function IsCharacterAlive(localPlayer) -- 1 equivalent call inferred from this helper
	return CharacterResolver.isAliveCharacter(localPlayer.Character)
end

local function ShouldRunUpdate() -- 4 equivalent calls inferred from this helper
	return workspace:GetAttribute("Gamemode") == "Hostage Rescue" and IsCharacterAlive(LocalPlayer) -- inferred equivalent call
end

local function StopUpdateConnection() -- 4 equivalent calls inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function SyncUpdateConnection() -- 2 equivalent calls inferred from this helper
	if ShouldRunUpdate() then -- inferred equivalent call
		if connection then
			return
		end

		connection = RunServiceController.BindToHeartbeat("UI.HoverHostage.Update", function(_)
			if ShouldRunUpdate() then -- inferred equivalent call
				local hoverState = HoverHostage.GetHoverState()
				v.Visible = hoverState
			else
				v.Visible = false
				StopUpdateConnection() -- inferred equivalent call
			end
		end)
	else
		v.Visible = false
		StopUpdateConnection() -- inferred equivalent call
	end
end

local function TrackCharacter(character)
	if deadChangedConnection then
		deadChangedConnection:Disconnect()
		deadChangedConnection = nil
	end

	if childAddedConnection then
		childAddedConnection:Disconnect()
		childAddedConnection = nil
	end

	if character then
		deadChangedConnection = character:GetAttributeChangedSignal("Dead"):Connect(SyncUpdateConnection)
		childAddedConnection = character.ChildAdded:Connect(function(humanoid)
			if humanoid:IsA("Humanoid") then
				if ShouldRunUpdate() then -- inferred equivalent call
					if connection then
						return
					end

					connection = RunServiceController.BindToHeartbeat("UI.HoverHostage.Update", function(_)
						if ShouldRunUpdate() then -- inferred equivalent call
							local hoverState = HoverHostage.GetHoverState()
							v.Visible = hoverState
						else
							v.Visible = false
							StopUpdateConnection() -- inferred equivalent call
						end
					end)
				else
					v.Visible = false
					StopUpdateConnection() -- inferred equivalent call
				end
			end
		end)
	end

	SyncUpdateConnection() -- inferred equivalent call
end

function HoverHostage.GetHoverState()
	return CenterScreenRaycast.GetHoveredHostage(5) ~= nil
end

function HoverHostage.Initialize(_, p)
	v = p

	local function UpdateFrameText() -- 1 equivalent call inferred from this helper
		local actionKeybind = InputController.GetActionKeybind("Use")
		v.Text = `[{not actionKeybind and "E" or actionKeybind:gsub("Enum%.KeyCode%.", ""):gsub("Enum%.UserInputType%.", ""):gsub("Enum%.CustomInputType%.", "")}] Pick Up Hostage`
	end

	UpdateFrameText() -- inferred equivalent call
	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", function(p2)
		if not p2 then
			return
		end

		task.defer(UpdateFrameText)
	end)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(SyncUpdateConnection)
	LocalPlayer.CharacterAdded:Connect(TrackCharacter)
	LocalPlayer.CharacterRemoving:Connect(function()
		if deadChangedConnection then
			deadChangedConnection:Disconnect()
			deadChangedConnection = nil
		end

		if childAddedConnection then
			childAddedConnection:Disconnect()
			childAddedConnection = nil
		end

		SyncUpdateConnection() -- inferred equivalent call
	end)
	TrackCharacter(LocalPlayer.Character)
end

return HoverHostage