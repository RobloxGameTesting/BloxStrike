local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local ConfigController = require(ReplicatedStorage.Controllers.ConfigController)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Missions = require(ReplicatedStorage.Database.Custom.GameStats.Missions)
local ConfigKeys = require(ReplicatedStorage.Database.Custom.ConfigKeys)
require(ReplicatedStorage.Database.Custom.Types)
local color = Color3.fromRGB(255, 255, 255)
local udim = UDim2.fromScale(0.5, -1.5)
local udim2 = UDim2.fromScale(0.1, 1)
local udim3 = UDim2.fromScale(0.5, -0.25)
local udim4 = UDim2.fromScale(8, 1)
local v = {
	hourly = Color3.fromRGB(208, 182, 68),
	daily = Color3.fromRGB(21, 208, 11),
	weekly = Color3.fromRGB(76, 154, 255),
	monthly = Color3.fromRGB(160, 68, 191)
}
local color2 = Color3.fromRGB(255, 255, 255)
local v2 = {
	hourly = "HOURLY MISSION",
	daily = "DAILY MISSION",
	weekly = "WEEKLY MISSION",
	monthly = "MONTHLY MISSION"
}
local MissionCompleted = {}
local v3 = nil
local frame = nil
local title = nil
local objective = nil
local icon = nil
local v4 = nil
local amount = nil
local tweens = {}
local v5 = {}
local v6 = false
local v7 = {}
local flag = false
local ProcessQueue
local FinishDisplay

local function CommaNumber(creditAmount: number) -- 1 equivalent call inferred from this helper
	return (tostring(creditAmount):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function ColorToHex(color3: Color3) -- 1 equivalent call inferred from this helper
	return string.format(
		"#%02X%02X%02X",
		math.round(color3.R * 255),
		math.round(color3.G * 255),
		(math.round(color3.B * 255))
	)
end

local function GetMissionKey(p) -- 1 equivalent call inferred from this helper
	return `{p.MissionId}:{p.CreatedAt}`
end

local function GetCreditRewardAmount(kind, amount2: number) -- 1 equivalent call inferred from this helper
	local missionCreditRewardMultiplier = ConfigKeys.Shared.MissionCreditRewardMultipliers[kind]
	return (math.round(amount2 * (not missionCreditRewardMultiplier and 1 or ConfigController.GetRewardMultiplier(missionCreditRewardMultiplier))))
end

local function CancelActiveTweens() -- 2 equivalent calls inferred from this helper
	for _, v8 in tweens do
		v8:Cancel()
	end

	table.clear(tweens)
end

local function PlayTween(p, tweenInfo, p2) -- 1 equivalent call inferred from this helper
	local tween = TweenService:Create(p, tweenInfo, p2)
	table.insert(tweens, tween)
	tween:Play()
	return tween
end

local function SetTextLabelTransparent(p, flag2: boolean) -- 2 equivalent calls inferred from this helper
	local v8 = flag2 and 1 or 0
	p.TextTransparency = v8
	p.TextStrokeTransparency = v8
end

local function SetImageLabelTransparent(p, flag2: boolean)
	p.ImageTransparency = flag2 and 1 or 0
end

local function SetContentTransparent(flag2: boolean)
	if title then
		SetTextLabelTransparent(title, flag2) -- inferred equivalent call
	end

	if objective then
		SetTextLabelTransparent(objective, flag2) -- inferred equivalent call
	end

	if icon then
		icon.ImageTransparency = flag2 and 1 or 0
	end

	if v4 then
		v4.ImageTransparency = flag2 and 1 or 0
	end
end

local function ResetFramePresentation() -- 2 equivalent calls inferred from this helper
	CancelActiveTweens() -- inferred equivalent call

	if frame then
		frame.Position = udim
		frame.Size = udim2
	end

	if title then
		local v8 = title
		v8.TextTransparency = 1
		v8.TextStrokeTransparency = 1
	end

	if objective then
		local v8 = objective
		v8.TextTransparency = 1
		v8.TextStrokeTransparency = 1
	end

	if icon then
		icon.ImageTransparency = 1
	end

	if v4 then
		v4.ImageTransparency = 1
	end
end

local function HidePopup() -- 2 equivalent calls inferred from this helper
	if v3 then
		v3.Visible = false
		ResetFramePresentation() -- inferred equivalent call
	end
end

local function ApplyHUDColor() -- 1 equivalent call inferred from this helper
	if frame then
		frame.BackgroundColor3 = GetPreferenceColor()
	end
end

local function IsMissionsNotificationsEnabled() -- 1 equivalent call inferred from this helper
	return DataController.Get(LocalPlayer, "Settings.Game.HUD.Enable Missions Notifications") ~= false
end

local function ShowEntry(data, fn)
	if not (v3 and frame and title and objective and icon) then
		return
	end

	CancelActiveTweens() -- inferred equivalent call
	title.RichText = true
	title.TextColor3 = color
	title.Text = `<font color="{data.colorHex}">{data.typeLabel}</font> COMPLETED`
	objective.Text = data.objective

	if data.creditAmount then
		icon.Image = "rbxassetid://129921992230064"

		if amount then
			amount.Text = `x{CommaNumber(data.creditAmount)}` -- inferred equivalent call
		end
	end

	icon.Visible = data.creditAmount ~= nil

	if v4 then
		v4.Visible = data.creditAmount ~= nil
	end

	ApplyHUDColor() -- inferred equivalent call
	frame.Position = udim
	frame.Size = udim2

	if title then
		local v8 = title
		v8.TextTransparency = 1
		v8.TextStrokeTransparency = 1
	end

	if objective then
		local v8 = objective
		v8.TextTransparency = 1
		v8.TextStrokeTransparency = 1
	end

	if icon then
		icon.ImageTransparency = 1
	end

	if v4 then
		v4.ImageTransparency = 1
	end

	v3.Visible = true
	Router.broadcastRouter("RunInterfaceSound", "Mission Completed")
	PlayTween(frame, TweenInfo.new(0.3, Enum.EasingStyle.Linear), { Position = udim3 }).Completed:Once(function(p) -- inferred equivalent call
		if p == Enum.PlaybackState.Completed then
			task.delay(0.1, function()
				if not (v3 and v3.Visible and frame) then
					FinishDisplay()
					return
				end

				local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
				local tween = TweenService:Create(frame, tweenInfo, { Size = udim4 })
				table.insert(tweens, tween)
				tween:Play()

				if title then
					local tween2 = TweenService:Create(title, tweenInfo, {
						TextTransparency = 0,
						TextStrokeTransparency = 0
					})
					table.insert(tweens, tween2)
					tween2:Play()
				end

				if objective then
					local tween2 = TweenService:Create(objective, tweenInfo, {
						TextTransparency = 0,
						TextStrokeTransparency = 0
					})
					table.insert(tweens, tween2)
					tween2:Play()
				end

				if icon then
					local tween2 = TweenService:Create(icon, tweenInfo, { ImageTransparency = 0 })
					table.insert(tweens, tween2)
					tween2:Play()
				end

				if v4 then
					local tween2 = TweenService:Create(v4, tweenInfo, { ImageTransparency = 0 })
					table.insert(tweens, tween2)
					tween2:Play()
				end

				task.delay(0.5, fn)
			end)
		else
			FinishDisplay()
		end
	end)
end

FinishDisplay = function()
	table.remove(v7, 1)
	flag = false

	if #v7 > 0 then
		ProcessQueue()
		return
	end

	HidePopup() -- inferred equivalent call
end

ProcessQueue = function()
	if flag then
		return
	end

	local v8 = v7[1]

	if v8 then
		flag = true
		ShowEntry(v8, function()
			task.delay(3, FinishDisplay)
		end)
	else
		HidePopup() -- inferred equivalent call
	end
end

local function BuildEntry(p)
	local missionDefinition = Missions.GetMissionDefinition(p.MissionId)

	if not missionDefinition then
		return nil
	end

	local kind = missionDefinition.Type
	local v8 = missionDefinition.Rewards and missionDefinition.Rewards[1]
	local creditAmount

	if v8 and v8.type == "Credits" and typeof(v8.amount) == "number" then
		creditAmount = GetCreditRewardAmount(kind, v8.amount) -- inferred equivalent call
	end

	return {
		typeLabel = v2[kind] or "MISSION",
		colorHex = ColorToHex(v[kind] or color2), -- inferred equivalent call
		objective = missionDefinition.DisplayName or missionDefinition.MissionId,
		creditAmount = creditAmount
	}
end

local function EnqueueDisplayEntry(p) -- 1 equivalent call inferred from this helper
	table.insert(v7, p)
	ProcessQueue()
end

local function OnMissionsChanged(list)
	if typeof(list) ~= "table" then
		return
	end

	local v8 = {}

	for _, v9 in ipairs(list) do
		if not (typeof(v9) == "table" and typeof(v9.MissionId) == "string") then
			continue
		end

		local missionKey = GetMissionKey(v9) -- inferred equivalent call
		v8[missionKey] = true

		if not ((v9.Progress or 0) >= (v9.Target or 1e999)) or (v9.IsClaimed or v5[missionKey]) then
			continue
		end

		v5[missionKey] = true

		if not (v6 and IsMissionsNotificationsEnabled()) then -- inferred equivalent call
			continue
		end

		local entry = BuildEntry(v9)

		if entry then
			EnqueueDisplayEntry(entry) -- inferred equivalent call
		end
	end

	for k in pairs(v5) do
		if not v8[k] then
			v5[k] = nil
		end
	end

	v6 = true
end

function MissionCompleted.Initialize(_, instance)
	v3 = instance
	frame = instance:FindFirstChild("Frame")
	local frameContainer = frame and frame:FindFirstChild("Container")
	local info = frameContainer and frameContainer:FindFirstChild("Info")
	local reward = frameContainer and frameContainer:FindFirstChild("Reward")
	title = info and info:FindFirstChild("Title")
	objective = info and info:FindFirstChild("Objective")
	icon = reward and reward:FindFirstChild("Icon")
	amount = icon and icon:FindFirstChild("Amount")

	if frameContainer then
		for _, image in frameContainer:GetDescendants() do
			if not (image:IsA("ImageLabel") and image ~= icon) then
				continue
			end

			v4 = image
			break
		end
	end

	if not (frame and title and objective and icon) then
		warn("[MissionCompleted] Missing expected UI elements; popup disabled.")
		return
	end

	instance.Visible = false
	ResetFramePresentation() -- inferred equivalent call

	local function refreshHUDColor()
		if v3 and v3.Visible and frame then
			frame.BackgroundColor3 = GetPreferenceColor()
		end
	end

	DataController.CreateListener(LocalPlayer, "Missions", OnMissionsChanged)
	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", refreshHUDColor)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshHUDColor)
end

return MissionCompleted