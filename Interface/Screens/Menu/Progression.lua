local Progression = {}
local ContentProvider = game:GetService("ContentProvider")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local FormatDuration = require(ReplicatedStorage.Components.Common.FormatDuration)
local ConfigController = require(ReplicatedStorage.Controllers.ConfigController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local ConfigKeys = require(ReplicatedStorage.Database.Custom.ConfigKeys)
require(ReplicatedStorage.Database.Custom.Types)
local DevProducts = require(ReplicatedStorage.Database.Custom.GameStats.Monetization.DevProducts)
local MissionStars = require(ReplicatedStorage.Database.Custom.GameStats.MissionStars)
local MissionIcons = require(ReplicatedStorage.Database.Custom.GameStats.MissionIcons)
local Missions = require(ReplicatedStorage.Database.Custom.GameStats.Missions)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local LocalPlayer = Players.LocalPlayer
local v = nil
local v2 = nil
local missions = nil
local missionsTab = nil
local clone = nil
local v3 = "hourly"
local v4 = nil
local v5 = {}
local v6 = { "hourly", "daily", "weekly", "monthly" }
local colorSequence = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 89)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 220, 116))
})
local colorSequence2 = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 236, 160)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 216, 141))
})
local colorSequence3 = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(125, 125, 125)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(65, 65, 65))
})

local function isMissionStarRewardClaimed(rewards, p: number) -- 3 equivalent calls inferred from this helper
	return rewards ~= nil and rewards[tostring(p)] == true
end

local function hasDailyStarToClaim(p)
	if not p then
		return false
	end

	for i = 1, math.clamp(p.CurrentStreak, 0, #MissionStars) do
		if not isMissionStarRewardClaimed(p.Rewards, i) then -- inferred equivalent call
			return true
		end
	end

	return false
end

local function hasClaimableMissions(list)
	if not list then
		return false
	end

	for _, v7 in ipairs(list) do
		if v7.Progress >= v7.Target and not v7.IsClaimed then
			return true
		end
	end

	return false
end

local function getAlertFingerprint(list, p)
	local v7 = {}

	if list then
		for _, v8 in ipairs(list) do
			table.insert(v7, `{v8.MissionId}:{v8.Progress}:{tostring(v8.IsClaimed)}`)
		end
	end

	if not p then
		return table.concat(v7, "|")
	end

	for i = 1, math.clamp(p.CurrentStreak, 0, #MissionStars) do
		if not isMissionStarRewardClaimed(p.Rewards, i) then -- inferred equivalent call
			table.insert(v7, `star:{i}`)
		end
	end

	return table.concat(v7, "|")
end

local function updateProgressionAlert(p, p2)
	if not v then
		return
	end

	local alert = v.Menu.Top.Bottom.Buttons.Progression:FindFirstChild("Alert")

	if not (alert and alert:IsA("GuiObject")) then
		return
	end

	local v7 = p2 or DataController.Get(LocalPlayer, "Missions")
	local v8 = p or DataController.Get(LocalPlayer, "MissionStars")
	local alertFingerprint = getAlertFingerprint(v7, v8)
	local v9 = hasClaimableMissions(v7) or hasDailyStarToClaim(v8)

	if v2 and v2.Visible then
		v4 = alertFingerprint
		alert.Visible = false
	else
		alert.Visible = v9 and alertFingerprint ~= v4
	end

	local textLabel = alert:FindFirstChild("TextLabel")

	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = "!"
	end
end

local function getMissionFromId(p: string)
	local missions2 = DataController.Get(LocalPlayer, "Missions")

	if not missions2 then
		return nil
	end

	for _, mission in ipairs(missions2) do
		if mission.MissionId == p then
			return mission
		end
	end

	return nil
end

local function getMissionCreditRewardAmount(p) -- 2 equivalent calls inferred from this helper
	local reward = p.Rewards[1]

	if not reward or reward.type ~= "Credits" or typeof(reward.amount) ~= "number" then
		return 0
	end

	local missionCreditRewardMultiplier = ConfigKeys.Shared.MissionCreditRewardMultipliers[p.Type]
	local v7 = not missionCreditRewardMultiplier and 1
		or ConfigController.GetRewardMultiplier(missionCreditRewardMultiplier)
	return (math.round(reward.amount * v7))
end

local function canonicalizeFilter(button) -- 2 equivalent calls inferred from this helper
	local index = table.find(v6, button.Name)

	if index then
		return v6[index]
	end

	return nil
end

local function getEarliestExpirationTime(p)
	local missions2 = DataController.Get(LocalPlayer, "Missions")

	if not missions2 then
		return nil
	end

	local v7 = os.time() * 1000
	local expiresAt = nil

	for _, mission in ipairs(missions2) do
		local missionDefinition = Missions.GetMissionDefinition(mission.MissionId)

		if
			missionDefinition
			and missionDefinition.Type == p
			and v7 < mission.ExpiresAt
			and (not expiresAt or mission.ExpiresAt < expiresAt)
		then
			expiresAt = mission.ExpiresAt
		end
	end

	return expiresAt
end

local function updateMissionHeader()
	local earliestExpirationTime = getEarliestExpirationTime(v3)
	local v7 = not earliestExpirationTime and 0
		or math.max(0, (math.floor((earliestExpirationTime - os.time() * 1000) / 1000)))
	missions.MissionHeader.Title.Text = `{string.upper(v3)} MISSIONS`
	missions.MissionHeader.Timer.Text = FormatDuration(v7, "IfNeeded")
end

local function setReward(state, data) -- 1 equivalent call inferred from this helper
	local missionCreditRewardAmount = getMissionCreditRewardAmount(data) -- inferred equivalent call
	state.ItemTemplate.Amount.Text = `x{CommaNumber(missionCreditRewardAmount)}`
	state.RewardTemplate.Amount.Text = `x{CommaNumber(missionCreditRewardAmount)}`
	state.RewardTemplate.Icon.Image = "rbxassetid://129921992230064"
end

local function getMissionFingerprint(missionDefinition, data, count: number)
	local missionId = data.MissionId
	local displayName = missionDefinition.DisplayName or missionDefinition.MissionId
	local progress = tostring(data.Progress)
	local target = tostring(data.Target)
	local isClaimed = tostring(data.IsClaimed)
	local missionCreditRewardAmount = getMissionCreditRewardAmount(missionDefinition) -- inferred equivalent call
	return table.concat(
		{
			missionId,
			displayName,
			progress,
			target,
			isClaimed,
			tostring(missionCreditRewardAmount),
			(tostring(count))
		},
		"|"
	)
end

local function updateMissionTemplate(clone2, data, data2, layoutOrder: number)
	clone2.LayoutOrder = layoutOrder
	local v7 = math.max(data2.Target, 1)
	local v8 = data2.Progress >= data2.Target
	clone2.Title.Text = data.DisplayName or data.MissionId
	clone2.Progress.Text = `{CommaNumber(data2.Progress)}/{CommaNumber(data2.Target)}`
	clone2.Bar.Progress.Size = UDim2.fromScale(math.clamp(data2.Progress / v7, 0, 1), 1)
	clone2.GlowEffect.Visible = v8 and not data2.IsClaimed
	clone2.RewardTemplate.Finish.Visible = data2.IsClaimed
	clone2.ItemTemplate.Icon.Image = MissionIcons[data.Category] or MissionIcons.Default
	setReward(clone2, data) -- inferred equivalent call
end

local function createMissionTemplate(p, p2, layoutOrder: number)
	local clone2 = clone:Clone()
	clone2.Name = p2.MissionId
	clone2.Visible = true
	clone2.Active = true
	clone2:SetAttribute("GeneratedMission", true)
	updateMissionTemplate(clone2, p, p2, layoutOrder)
	clone2.Parent = missionsTab
	local missionId = p2.MissionId
	clone2.InputEnded:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local missionId2 = missionId
		local missions2 = DataController.Get(LocalPlayer, "Missions")
		local v7

		if missions2 then
			for _, mission in ipairs(missions2) do
				if mission.MissionId ~= missionId2 then
					continue
				end

				v7 = mission
				break
			end
		end

		if v7 and v7.Progress >= v7.Target and not v7.IsClaimed then
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			Remotes.Dashboard.MissionCompleted.Send(missionId)
		end
	end)
	return clone2
end

local function reconcileMissions(list) -- 2 equivalent calls inferred from this helper
	Profiler.scope("UI.Progression.ReconcileMissions", function()
		local framesByName = {}

		for _, frame in ipairs(missionsTab:GetChildren()) do
			if frame:IsA("Frame") and frame:GetAttribute("GeneratedMission") then
				framesByName[frame.Name] = frame
			end
		end

		local v7 = {}
		local count = 0

		if list then
			for _, v8 in ipairs(list) do
				local missionDefinition = Missions.GetMissionDefinition(v8.MissionId)

				if not (missionDefinition and missionDefinition.Type == v3) then
					continue
				end

				count += 1
				local missionId = v8.MissionId
				local missionFingerprint = getMissionFingerprint(missionDefinition, v8, count)
				local v9 = framesByName[missionId]
				v7[missionId] = true

				if v9 then
					if v5[missionId] ~= missionFingerprint then
						Profiler.scope(
							"UI.Progression.UpdateMissionRow",
							updateMissionTemplate,
							v9,
							missionDefinition,
							v8,
							count
						)
					end
				else
					Profiler.scope(
						"UI.Progression.CreateMissionRow",
						createMissionTemplate,
						missionDefinition,
						v8,
						count
					)
				end

				v5[missionId] = missionFingerprint
			end
		end

		for k, v8 in pairs(framesByName) do
			if v7[k] then
				continue
			end

			local v9 = v8
			Profiler.scope("UI.Progression.DestroyMissionRow", function()
				v9:Destroy()
			end)
			v5[k] = nil
		end

		updateMissionHeader()
	end)
end

local function renderMissions() -- 3 equivalent calls inferred from this helper
	reconcileMissions(DataController.Get(LocalPlayer, "Missions")) -- inferred equivalent call
end

local function updateFilterButtons()
	for _, button in ipairs(missions.ChangeMissionTimes:GetChildren()) do
		if not button:IsA("GuiButton") then
			continue
		end

		local v7 = canonicalizeFilter(button) -- inferred equivalent call
		button.GlowEffect.Visible = v7 == v3
	end
end

local function openMissionFilter(p) -- 1 equivalent call inferred from this helper
	v3 = p
	updateFilterButtons()
	renderMissions() -- inferred equivalent call
end

local function setupMissionFilters()
	local v7 = {}

	for _, button in ipairs(missions.ChangeMissionTimes:GetChildren()) do
		if not button:IsA("GuiButton") then
			continue
		end

		local v8 = canonicalizeFilter(button) -- inferred equivalent call

		if not v8 or v7[v8] then
			continue
		end

		v7[v8] = true
		ActivateButton(button)
		button.MouseButton1Click:Connect(function()
			openMissionFilter(v8) -- inferred equivalent call
		end)
	end

	for _, v8 in ipairs(v6) do
		assert(v7[v8], `Progression is missing its {v8} mission filter`)
	end

	updateFilterButtons()
end

local function attemptStarClaim(p: number)
	local missionStars = DataController.Get(LocalPlayer, "MissionStars")

	if not missionStars then
		Router.broadcastRouter("CreateMenuNotification", "Error", "Mission stars are still loading.")
		return
	end

	if isMissionStarRewardClaimed(missionStars.Rewards, p) then -- inferred equivalent call
		Router.broadcastRouter("CreateMenuNotification", "Error", "Star reward already claimed.")
		return
	end

	if missionStars.CurrentStreak < p then
		Router.broadcastRouter("CreateMenuNotification", "Error", `Reach streak day {p} to claim this reward.`)
		return
	end

	Router.broadcastRouter("RunInterfaceSound", "UI Click")
	Remotes.Dashboard.ClaimStarReward.Send(p)
end

local function updateMissionStars(p)
	updateProgressionAlert(p)
	local v7 = not p and 0 or math.clamp(p.CurrentStreak, 0, #MissionStars)
	local dailyStars = missions.DailyStars
	local progress = dailyStars.Bar.Progress
	local udim = UDim2.fromScale(v7 / math.max(#MissionStars, 1), 1)

	if v2.Visible then
		TweenService:Create(progress, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Size = udim }):Play()
	else
		progress.Size = udim
	end

	missions.StarHeader.Streak.Streak.Text = tostring(v7)

	for i, missionStar in ipairs(MissionStars) do
		local child = dailyStars.Container:FindFirstChild(`Template{i}`)
		assert(child, `Progression is missing star template {i}`)
		local v8

		if p == nil then
			v8 = false
		else
			local rewards = p.Rewards

			if rewards == nil then
				v8 = false
			else
				v8 = rewards[tostring(i)] == true
			end
		end

		local visible = i <= v7
		child.ItemTemplate.Amount.Text = `x{CommaNumber(missionStar)}`
		child.Title.Text = v8 and "CLAIMED" or visible and "CLAIM" or tostring(i)
		child.Star.Glow.Visible = visible
		local color

		if v8 then
			color = colorSequence2
		elseif visible then
			color = colorSequence
		else
			color = colorSequence3
		end

		child.Star.Icon.UIGradient.Color = color
		child.Title.UIGradient.Color = color
		child.Star.Glow.UIGradient.Color = color
	end
end

local function setupMissionStars()
	for i = 1, #MissionStars do
		local child = missions.DailyStars.Container:FindFirstChild(`Template{i}`)
		assert(child, `Progression is missing star template {i}`)
		ActivateButton(child)
		local v7 = i
		child.MouseButton1Click:Connect(function()
			attemptStarClaim(v7)
		end)
	end

	updateMissionStars(DataController.Get(LocalPlayer, "MissionStars"))
end

local function setupRefreshButtons()
	local more = missions.MissionHeader.More
	ActivateButton(more)
	more.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, DevProducts["Refresh Missions"].DevProductId)
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end)
end

local function visibilityUpdated(visible: boolean) -- 1 equivalent call inferred from this helper
	local missionStars = DataController.Get(LocalPlayer, "MissionStars")
	updateProgressionAlert(missionStars, DataController.Get(LocalPlayer, "Missions"))

	if visible then
		renderMissions() -- inferred equivalent call
		updateMissionStars(missionStars)
	end
end

function Progression.Initialize(p, p2)
	v = p
	v2 = p2
	missions = p2.Missions
	missionsTab = missions.MissionsTab
	clone = missionsTab.MissionTemplate:Clone()
	clone.Parent = nil
	missionsTab.MissionTemplate:Destroy()
	local missionIcons = {}

	for _, missionIcon in MissionIcons do
		if not table.find(missionIcons, missionIcon) then
			table.insert(missionIcons, missionIcon)
		end
	end

	task.spawn(function()
		ContentProvider:PreloadAsync(missionIcons)
	end)
	setupMissionFilters()
	setupMissionStars()
	local more = missions.MissionHeader.More
	ActivateButton(more)
	more.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, DevProducts["Refresh Missions"].DevProductId)
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end)
	renderMissions() -- inferred equivalent call
	updateProgressionAlert(DataController.Get(LocalPlayer, "MissionStars"), DataController.Get(LocalPlayer, "Missions"))
	DataController.CreateListener(LocalPlayer, "Missions", function(list)
		Profiler.scope("UI.Progression.MissionsChanged", function()
			if v2.Visible then
				reconcileMissions(list) -- inferred equivalent call
			end

			updateProgressionAlert(nil, list)
		end)
	end)
	DataController.CreateListener(LocalPlayer, "MissionStars", function(p3)
		updateMissionStars(p3)
	end)

	for _, missionCreditRewardMultiplier in pairs(ConfigKeys.Shared.MissionCreditRewardMultipliers) do
		ConfigController.OnChanged(missionCreditRewardMultiplier, renderMissions)
	end
end

function Progression.Start()
	local total = 0
	RunService.Heartbeat:Connect(function(dt: number)
		if not v2.Visible then
			return
		end

		total += dt

		if total >= 1 then
			total = 0
			updateMissionHeader()
		end
	end)
	v2:GetPropertyChangedSignal("Visible"):Connect(function()
		visibilityUpdated(v2.Visible) -- inferred equivalent call
	end)
end

return Progression