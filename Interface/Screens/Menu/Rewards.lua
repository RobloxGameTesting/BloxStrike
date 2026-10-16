local ExperienceNotificationService = game:GetService("ExperienceNotificationService")
local AvatarEditorService = game:GetService("AvatarEditorService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local AnimateDashboardCard = require(ReplicatedStorage.Components.Common.InterfaceAnimations.AnimateDashboardCard)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local LocalPlayer = Players.LocalPlayer
local v = nil
local v2 = nil
local flag = false
local color = Color3.fromRGB(120, 120, 120)
local v3 = {
	EnableNotifications = "Notifications",
	FavoriteGame = "FavoriteGame",
	InviteFriends = "InviteFriend",
	JoinGroup = "JoinGroup",
	LikeGame = "LikeGame"
}
local v4 = {
	{ "group", "JoinGroup" },
	{ "favorite", "FavoriteGame" },
	{ "notification", "Notifications" },
	{ "like", "LikeGame" }
}

local function centerButtonAnchor(state)
	local size = state.Size
	local position = state.Position
	local anchorPoint = state.AnchorPoint
	state.AnchorPoint = Vector2.new(0.5, 0.5)
	state.Position = UDim2.new(
		position.X.Scale + size.X.Scale * (0.5 - anchorPoint.X),
		position.X.Offset + size.X.Offset * (0.5 - anchorPoint.X),
		position.Y.Scale + size.Y.Scale * (0.5 - anchorPoint.Y),
		position.Y.Offset + size.Y.Offset * (0.5 - anchorPoint.Y)
	)
end

local function getRowButton(instance) -- 1 equivalent call inferred from this helper
	local redeem = instance:FindFirstChild("Redeem") or instance:FindFirstChild("Verify")

	if redeem and redeem:IsA("GuiButton") then
		return redeem
	end

	return nil
end

local function getRowTitle(instance) -- 1 equivalent call inferred from this helper
	local title = instance:FindFirstChild("Title")

	if title then
		return (string.lower(title.Text))
	end

	return ""
end

local function updateClaimedState(instance, rewardClaimed: boolean)
	local rewardTemplate = instance:FindFirstChild("RewardTemplate")

	if not rewardTemplate then
		return
	end

	local finish = rewardTemplate:FindFirstChild("Finish")
	local icon = rewardTemplate:FindFirstChild("Icon")
	local amount = rewardTemplate:FindFirstChild("Amount")

	if finish then
		finish.Visible = rewardClaimed
	end

	if icon then
		icon.Visible = not rewardClaimed
	end

	if amount then
		amount.Visible = not rewardClaimed
	end
end

local function isRewardClaimed(p: string) -- 4 equivalent calls inferred from this helper
	local promotionalRewards = DataController.Get(LocalPlayer, "PromotionalRewards")
	return typeof(promotionalRewards) == "table" and promotionalRewards[p] == true
end

local function hasReferredFriendInServer()
	for _, v5 in ipairs(Players:GetPlayers()) do
		if v5 ~= LocalPlayer and v5:GetAttribute("ReferredByPlayerId") == LocalPlayer.UserId then
			return true
		end
	end

	return false
end

local function canSendGameInvite()
	for i = 1, 2 do
		local success, result = pcall(function()
			return SocialService:CanSendGameInviteAsync(LocalPlayer)
		end)

		if success and typeof(result) == "boolean" then
			return true, result
		end

		if not success then
			warn(`Rewards invite availability check failed: {result}`)
		end

		if i < 2 then
			task.wait(0.35)
		end
	end

	return false, false
end

local function setupInviteRow(_, rowButton) -- 2 equivalent calls inferred from this helper
	rowButton.MouseButton1Click:Connect(function()
		if isRewardClaimed("InviteFriend") then -- inferred equivalent call
			Router.broadcastRouter("CreateMenuNotification", "Error", "You have already redeemed this reward.")
			return
		end

		if hasReferredFriendInServer() then
			Remotes.Dashboard.RedeemPromotionalReward.Send("InviteFriend")
			return
		end

		if flag then
			return
		end

		flag = true
		local v5, v6 = canSendGameInvite()

		if v5 and not v6 then
			flag = false
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				"Game invites aren't available for your account or device."
			)
		else
			local success, result = pcall(function()
				SocialService:PromptGameInvite(LocalPlayer)
			end)
			flag = false

			if not success then
				warn(`Rewards invite prompt failed: {result}`)
				Router.broadcastRouter(
					"CreateMenuNotification",
					"Error",
					"Game invites are unavailable right now. Please try again."
				)
			end
		end
	end)
end

local function setupCodeRow(instance, rowButton)
	local textBox = instance:FindFirstChildWhichIsA("TextBox", true)

	if not textBox then
		warn("Rewards code row is missing its textbox.")
		return
	end

	local function submitCode()
		local v5 = string.gsub(textBox.Text, "%s+", "")

		if v5 == "" then
			Router.broadcastRouter("CreateMenuNotification", "Error", "Please enter a code first.")
			return
		end

		local level = DataController.Get(LocalPlayer, "Level")
		local level2

		if typeof(level) == "table" then
			level2 = level.Level
		end

		if typeof(level2) ~= "number" or level2 < 5 then
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				"You need to be at least level 5 to redeem codes."
			)
			return
		end

		Remotes.Dashboard.RedeemCode.Send(v5)
		textBox.Text = ""
	end

	rowButton.MouseButton1Click:Connect(submitCode)
	textBox.FocusLost:Connect(function(flag2: boolean)
		if flag2 then
			submitCode()
		end
	end)
end

local function trackClaimedState(instance, button, p: string)
	local rewardTemplate = instance:FindFirstChild("RewardTemplate")
	local amount = rewardTemplate and rewardTemplate:FindFirstChild("Amount")

	if amount then
		amount.Text = `x{Constants.PROMOTIONAL_REWARD_CREDITS[p] or 0}`
	end

	local title = button:FindFirstChild("Title")
	local v5 = not title and "" or title.Text
	local imageColor3

	if button:IsA("ImageButton") then
		imageColor3 = button.ImageColor3
	else
		imageColor3 = Color3.new(1, 1, 1)
	end

	local v6 = imageColor3

	local function refreshClaimedState()
		local rewardClaimed = isRewardClaimed(p) -- inferred equivalent call
		updateClaimedState(instance, rewardClaimed)
		button.Interactable = not rewardClaimed

		if button:IsA("ImageButton") then
			local v7 = button
			local imageColor

			if rewardClaimed then
				imageColor = color
			else
				imageColor = v6
			end

			v7.ImageColor3 = imageColor
		end

		if title then
			title.Text = rewardClaimed and "CLAIMED" or v5
		end
	end

	local rewardClaimed = isRewardClaimed(p) -- inferred equivalent call
	updateClaimedState(instance, rewardClaimed)
	button.Interactable = not rewardClaimed

	if button:IsA("ImageButton") then
		if rewardClaimed then
			imageColor3 = color
		end

		button.ImageColor3 = imageColor3
	end

	if title then
		title.Text = rewardClaimed and "CLAIMED" or v5
	end

	DataController.CreateListener(LocalPlayer, "PromotionalRewards", refreshClaimedState)
end

local function promptGroupJoin()
	local success, result = pcall(function()
		return LocalPlayer:IsInGroupAsync(33751825)
	end)

	if success and result then
		return false
	end

	local success2, result2 = pcall(function()
		return GroupService:PromptJoinAsync(33751825)
	end)

	if
		success2
		and (result2 == Enum.GroupMembershipStatus.Joined or result2 == Enum.GroupMembershipStatus.AlreadyMember)
		or not success2
	then
		return false
	end

	Router.broadcastRouter("CreateMenuNotification", "Error", "Join the group, then press join again to redeem.")
	return true
end

local function promptFavoriteGame()
	local success, result = pcall(function()
		return AvatarEditorService:GetFavoriteAsync(114234929420007, Enum.AvatarItemType.Asset)
	end)

	if success and result then
		return false
	end

	local v5 = nil
	local promptSetFavoriteCompletedConnection = AvatarEditorService.PromptSetFavoriteCompleted:Connect(function(p)
		v5 = p
	end)

	if not pcall(function()
		AvatarEditorService:PromptSetFavorite(114234929420007, Enum.AvatarItemType.Asset, true)
	end) then
		promptSetFavoriteCompletedConnection:Disconnect()
		return false
	end

	local v6 = os.clock() + 30

	while v5 == nil and os.clock() < v6 do
		task.wait(0.1)
	end

	promptSetFavoriteCompletedConnection:Disconnect()

	if v5 == Enum.AvatarPromptResult.Success then
		return false
	end

	Router.broadcastRouter("CreateMenuNotification", "Error", "Favorite the game to redeem this reward.")
	return true
end

local function promptNotificationsOptIn()
	local success, result = pcall(function()
		return ExperienceNotificationService:CanPromptOptInAsync()
	end)

	if not (success and result) then
		return false
	end

	local v5 = pcall(function()
		ExperienceNotificationService:PromptOptIn()
	end)

	if v5 then
		Router.broadcastRouter(
			"CreateMenuNotification",
			"Error",
			"Turn on notifications, then press verify again to redeem."
		)
	end

	return v5
end

local v5 = {
	Notifications = promptNotificationsOptIn,
	FavoriteGame = promptFavoriteGame,
	JoinGroup = promptGroupJoin
}

local function setupPromotionalRow(_, rowButton, p: string) -- 2 equivalent calls inferred from this helper
	rowButton.MouseButton1Click:Connect(function()
		if isRewardClaimed(p) then -- inferred equivalent call
			Router.broadcastRouter("CreateMenuNotification", "Error", "You have already redeemed this reward.")
			return
		end

		local v6 = v5[p]

		if v6 and v6() then
			return
		end

		Remotes.Dashboard.RedeemPromotionalReward.Send(p)
	end)
end

local function setupRewardRow(frame)
	local rowButton = getRowButton(frame) -- inferred equivalent call

	if not rowButton then
		return
	end

	centerButtonAnchor(rowButton)
	ActivateButton(rowButton)
	local v6 = v3[frame.Name]

	if v6 then
		trackClaimedState(frame, rowButton, v6)

		if v6 == "InviteFriend" then
			setupInviteRow(nil, rowButton) -- inferred equivalent call
		else
			setupPromotionalRow(nil, rowButton, v6) -- inferred equivalent call
		end
	else
		local rowTitle = getRowTitle(frame) -- inferred equivalent call

		if frame:FindFirstChildWhichIsA("TextBox", true) then
			setupCodeRow(frame, rowButton)
		elseif string.find(rowTitle, "invite") then
			trackClaimedState(frame, rowButton, "InviteFriend")
			setupInviteRow(nil, rowButton) -- inferred equivalent call
		else
			for _, v7 in v4 do
				if not string.find(rowTitle, v7[1]) then
					continue
				end

				trackClaimedState(frame, rowButton, v7[2])
				setupPromotionalRow(nil, rowButton, v7[2]) -- inferred equivalent call
				return
			end

			warn(`Rewards row "{rowTitle}" has no matching reward.`)
		end
	end
end

local Rewards = {}

function Rewards.Initialize(p, p2)
	v = p
	v2 = p2
	v2.Visible = false
	v2.Active = true
	local container = v2:FindFirstChild("Container")

	if container then
		for _, frame in ipairs(container:GetChildren()) do
			if frame:IsA("Frame") then
				setupRewardRow(frame)
			end
		end
	end

	local title = v2:FindFirstChild("Title")
	local close = title and title:FindFirstChild("Close")

	if close then
		centerButtonAnchor(close)
		ActivateButton(close)
		close.MouseButton1Click:Connect(function()
			v2.Visible = false
		end)
	end
end

function Rewards.Start()
	local menu = v:FindFirstChild("Menu")
	local dashboard = menu and menu:FindFirstChild("Dashboard")
	local rewards = dashboard and dashboard:FindFirstChild("Rewards")
	local button = rewards and rewards:FindFirstChild("Button")

	if not button then
		warn("Rewards is missing its dashboard button.")
		return
	end

	AnimateDashboardCard(rewards, button)
	button.MouseButton1Click:Connect(function()
		v2.Visible = not v2.Visible
	end)
	MenuState.OnScreenChanged:Connect(function(_, p)
		if p ~= nil and p ~= "Dashboard" then
			v2.Visible = false
		end
	end)
end

return Rewards