local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GamepadNavigation = require(ReplicatedStorage.Interface.GamepadNavigation)
local v = nil
local v2 = nil

local function GetPromptPlatform()
	local userPlatform = GetUserPlatform()

	if table.find(userPlatform, "Mobile") then
		return "Mobile"
	end

	if table.find(userPlatform, "Console") and not table.find(userPlatform, "PC") then
		return "Console"
	end

	return nil
end

local SwitchServerPrompt = {}

function SwitchServerPrompt.Initialize(_, p)
	v = p
	v.Visible = false
	local buttons = v.Buttons.Buttons
	ActivateButton(buttons.Yes)
	ActivateButton(buttons.No)
	buttons.Yes.MouseButton1Click:Connect(function()
		v.Visible = false

		if v2 then
			Remotes.Modes.SelectGamemode.Send(`{v2}Server`)
		end
	end)
	buttons.No.MouseButton1Click:Connect(function()
		v.Visible = false
	end)
	GamepadNavigation.TrapPopup(v, function()
		return buttons.Yes
	end)
end

function SwitchServerPrompt.Start()
	local promptPlatform = GetPromptPlatform()

	if
		not promptPlatform
		or (Constants.IS_DEVICE_SERVER or not Constants.GetDeviceServerPlaceId(promptPlatform, game.PlaceId))
		or workspace:GetAttribute("IsVIPServer") == true
	then
		return
	end

	v2 = promptPlatform
	v.TextLabel.Text = `Do you want to join {promptPlatform} only servers?`
	v.Visible = true
end

return SwitchServerPrompt