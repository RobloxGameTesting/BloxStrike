local Votekick = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local v = nil
local v2 = nil
local count = 0
local flag = false

local function ShouldAutoCloseForState(p: string?) -- 2 equivalent calls inferred from this helper
	return p == "Game Ending" or p == "Map Voting"
end

function Votekick.UpdateAmount(value: string, p: number, p2: string)
	v.Option[value].Amount.Text = `{p}`

	if LocalPlayer.UserId == tonumber(p2) then
		local v3 = value == "Yes" and "rgb(90, 186, 55)" or "rgb(255,49,49)"
		v.Result.TextLabel.Text = `You voted: <font color="{v3}">{string.upper(value)}</font>`
		v.Result.Visible = true
	end
end

function Votekick.UpdateFrame(p: number, p2: number)
	local playerByUserId = Players:GetPlayerByUserId(p)
	local playerByUserId2 = Players:GetPlayerByUserId(p2)

	if playerByUserId then
		v.Player.Text = `Kick player: {playerByUserId.Name}? `
		v.Frame.Title.Text = `Vote By: {playerByUserId2 and playerByUserId2.Name or "Unknown"}`
		v.Option.Yes.Amount.Text = "0"
		v.Option.No.Amount.Text = "0"
	end
end

function Votekick.OpenFrame(p: number)
	v.Position = UDim2.fromScale(-0.08, 0.525)
	v:SetAttribute("IsVoteKickActive", true)
	v.Result.Visible = false
	v2 = p
	v.Visible = true
	flag = false
	count += 1
	local v3 = count

	if LocalPlayer.UserId == p then
		v.Result.TextLabel.Text = "You are being vote kicked."
		v.Result.Visible = true
	end

	TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.08, 0.525)
	}):Play()
	task.delay(30, function()
		if count == v3 then
			Votekick.CloseFrame()
		end
	end)
end

function Votekick.CloseFrame()
	count += 1
	local v3 = count
	v:SetAttribute("IsVoteKickActive", false)
	v.Result.Visible = false
	v2 = nil
	flag = false

	if not v.Visible then
		v.Position = UDim2.fromScale(-0.08, 0.525)
		return
	end

	local tween = TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(-0.08, 0.525)
	})
	tween.Completed:Once(function()
		if count == v3 then
			v.Visible = false
		end
	end)
	tween:Play()
end

function Votekick.CastVote(p: string)
	if v2 and LocalPlayer.UserId == v2 or flag then
		return
	end

	local voteYes = p == "Yes" and Remotes.VoteKick.VoteYes or Remotes.VoteKick.VoteNo
	flag = true
	return voteYes.Send({ Voter = tostring(LocalPlayer.UserId), Amount = 0 })
end

function Votekick.Initialize(_, p)
	v = p
	v:SetAttribute("IsVoteKickActive", false)
	v.Visible = false
	local visible = table.find(GetUserPlatform(), "Mobile") ~= nil
	local keybinds = v:FindFirstChild("Keybinds")
	local mobileNoButton = v:FindFirstChild("MobileNoButton")
	local mobileYesButton = v:FindFirstChild("MobileYesButton")

	if keybinds then
		keybinds.Visible = not visible
	end

	if mobileNoButton then
		mobileNoButton.Visible = visible
	end

	if mobileYesButton then
		mobileYesButton.Visible = visible
	end

	Remotes.VoteKick.VoteNoUpdate.Listen(function(p2)
		Votekick.UpdateAmount("No", p2.Amount, p2.Voter)
	end)
	Remotes.VoteKick.VoteYesUpdate.Listen(function(p2)
		Votekick.UpdateAmount("Yes", p2.Amount, p2.Voter)
	end)
	Remotes.VoteKick.StartVote.Listen(function(p2)
		if ShouldAutoCloseForState(GameState.GetState()) then -- inferred equivalent call
			return
		end

		local targetUserId = tonumber(p2.TargetUserId)
		local voterUserId = tonumber(p2.VoterUserId)
		Votekick.UpdateFrame(targetUserId, voterUserId)
		Votekick.OpenFrame(targetUserId)
	end)
	Remotes.VoteKick.EndVote.Listen(function()
		Votekick.CloseFrame()
	end)
	GameState.ListenToState(function(_, p2)
		if ShouldAutoCloseForState(p2) then -- inferred equivalent call
			Votekick.CloseFrame()
		end
	end)

	if not (visible and mobileNoButton and mobileYesButton) then
		UserInputService.InputBegan:Connect(function(input, gameProcessed: boolean)
			if
				gameProcessed
				or not v.Visible
				or UserInputService:GetFocusedTextBox()
				or input.UserInputType ~= Enum.UserInputType.Keyboard
			then
				return
			end

			if input.KeyCode == Enum.KeyCode.K then
				Votekick.CastVote("Yes")
			elseif input.KeyCode == Enum.KeyCode.L then
				Votekick.CastVote("No")
			end
		end)
		return
	end

	ActivateButton(mobileNoButton)
	ActivateButton(mobileYesButton)
	mobileNoButton.Activated:Connect(function()
		Votekick.CastVote("No")
	end)
	mobileYesButton.Activated:Connect(function()
		Votekick.CastVote("Yes")
	end)
end

return Votekick