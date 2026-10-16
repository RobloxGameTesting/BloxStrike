local Leaderboard = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local RemoveFromArray = require(ReplicatedStorage.Database.Components.Common.RemoveFromArray)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local GetBadgeIcon = require(ReplicatedStorage.Components.Common.GetBadgeIcon)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local GetTimerFormat = require(ReplicatedStorage.Components.Common.GetTimerFormat)
local ProfileInspect = require(script:WaitForChild("ProfileInspect"))
local v = { "Ping", "Money", "Kills", "Deaths", "Assists", "MVPs", "Score" }
local v2 = {
	CounterTerroristsPosition = UDim2.fromScale(0.582, 0.782),
	TerroristsPosition = UDim2.fromScale(0.582, 0.355),
	Size = UDim2.fromScale(0.762, 0.365),
	IsDeathmatch = false,
	Headers = {
		Ping = UDim2.fromScale(0.26958, 0.53351),
		Money = UDim2.fromScale(0.63825, 0.66217),
		Kills = UDim2.fromScale(0.70308, 0.66217),
		Deaths = UDim2.fromScale(0.75921, 0.66217),
		Assists = UDim2.fromScale(0.82029, 0.66217),
		MVPs = UDim2.fromScale(0.88294, 0.66217),
		Score = UDim2.fromScale(0.93732, 0.66217)
	}
}
local v3 = {
	Deathmatch = {
		CounterTerroristsPosition = UDim2.fromScale(0.503, 0.785),
		TerroristsPosition = UDim2.fromScale(0.503, 0.364),
		Size = UDim2.fromScale(0.921, 0.365),
		IsDeathmatch = true,
		Headers = {
			Ping = UDim2.fromScale(0.12539, 0.53351),
			Money = UDim2.fromScale(0.57099, 0.66217),
			Kills = UDim2.fromScale(0.64935, 0.66217),
			Deaths = UDim2.fromScale(0.71718, 0.66217),
			Assists = UDim2.fromScale(0.79102, 0.66217),
			MVPs = UDim2.fromScale(0.86673, 0.66217),
			Score = UDim2.fromScale(0.93246, 0.66217)
		}
	},
	["Bomb Defusal"] = v2,
	["Hostage Rescue"] = v2
}
local color = Color3.new(1, 1, 1)
local color2 = Color3.fromRGB(139, 128, 98)
local color3 = Color3.fromRGB(165, 183, 212)
local color4 = Color3.fromRGB(219, 199, 126)
local color5 = Color3.fromRGB(81, 81, 81)
local color6 = Color3.fromRGB(95, 95, 95)
local color7 = Color3.fromRGB(255, 255, 255)
local v4 = { "Team1", "Team2" }
local v5 = {
	BombDefuse = "rbxassetid://138772806705472",
	BombExplode = "rbxassetid://97682949239067",
	BombObjective = "rbxassetid://97682949239067",
	Elimination = "rbxassetid://70876442749327",
	TimeExpiration = "rbxassetid://96043369049959",
	HostageRescue = "rbxassetid://138772806705472"
}
local v6 = nil
local profileInspect = nil
local position = nil
local inputBeganConnection = nil
local v7 = false
local v8 = {}
local v9 = {}

local function commaNumber(p: number) -- 3 equivalent calls inferred from this helper
	return tostring(p):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function clearFrame(instance)
	for _, child in ipairs(instance:GetChildren()) do
		if child.ClassName == "Frame" then
			child:Destroy()
		end
	end
end

local function getPlayersOnTeam(p)
	local result = {}

	for _, v10 in ipairs((Participants.GetAll())) do
		if v10:GetAttribute("Team") == p then
			table.insert(result, v10)
		end
	end

	return result
end

local function lightenTowardWhite(backgroundColor3: Color3) -- 1 equivalent call inferred from this helper
	return backgroundColor3:Lerp(color, 0.2)
end

local function getMousePositionInLeaderboard()
	local mouseLocation = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset()
	local v10 = mouseLocation.X - guiInset.X
	local v11 = mouseLocation.Y - guiInset.Y
	local absolutePosition = v6.AbsolutePosition
	local absoluteSize = v6.AbsoluteSize
	return UDim2.fromScale((v10 - absolutePosition.X) / absoluteSize.X, (v11 - absolutePosition.Y) / absoluteSize.Y)
end

local function resetProfileInspect() -- 1 equivalent call inferred from this helper
	if not profileInspect then
		return
	end

	profileInspect.Visible = false

	if position then
		profileInspect.Position = position
	end

	ProfileInspect.Reset()
end

local function openProfileInspect(p) -- 1 equivalent call inferred from this helper
	if not profileInspect then
		return
	end

	profileInspect.Position = getMousePositionInLeaderboard()
	ProfileInspect.Populate(p)
	profileInspect.Visible = true
end

local function bindPlayerRowInteractions(clone, instance, maid)
	local backgroundColor3 = clone.BackgroundColor3
	local flag = false

	local function applyBackgroundColor() -- 2 equivalent calls inferred from this helper
		local v10 = clone
		local backgroundColor

		if flag then
			backgroundColor = lightenTowardWhite(backgroundColor3) -- inferred equivalent call
		else
			backgroundColor = backgroundColor3
		end

		v10.BackgroundColor3 = backgroundColor
	end

	clone.Active = true
	maid:Add(clone.MouseEnter:Connect(function()
		flag = true
		applyBackgroundColor() -- inferred equivalent call
	end))
	maid:Add(clone.MouseLeave:Connect(function()
		flag = false
		applyBackgroundColor() -- inferred equivalent call
	end))
	maid:Add(clone.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			openProfileInspect(instance) -- inferred equivalent call
		end
	end))
end

local function getCharactersAlive(p)
	return RemoveFromArray(p, function(_, p2)
		return not Participants.IsAlive(p2)
	end)
end

local function updateAliveCounts()
	if not v6 then
		return
	end

	local gamemode = workspace:GetAttribute("Gamemode")

	if gamemode ~= "Bomb Defusal" and gamemode ~= "Hostage Rescue" then
		return
	end

	local playersOnTeam = getPlayersOnTeam("Counter-Terrorists")
	local playersOnTeam2 = getPlayersOnTeam("Terrorists")
	local v10 = #playersOnTeam
	local v11 = #playersOnTeam2

	local function fn(_, p)
		return not Participants.IsAlive(p)
	end

	local removeFromArray = RemoveFromArray(playersOnTeam, fn)
	local removeFromArray2 = RemoveFromArray(playersOnTeam2, fn)
	v6.Team.CT.Alive.Text = `ALIVE {tostring(#removeFromArray)}/{tostring(v10)}`
	v6.Team.T.Alive.Text = `ALIVE {tostring(#removeFromArray2)}/{tostring(v11)}`
end

local function observeAliveCountPlayer(object)
	local v10 = v9[object]

	if v10 then
		v10:Destroy()
	end

	local maid = Janitor.new()
	v9[object] = maid
	maid:Add(object:GetAttributeChangedSignal("Team"):Connect(updateAliveCounts))
	maid:Add(object:GetAttributeChangedSignal("IsSpectating"):Connect(updateAliveCounts))
	maid:Add(object:GetAttributeChangedSignal("Dead"):Connect(updateAliveCounts))
	maid:Add(object:GetAttributeChangedSignal("Health"):Connect(updateAliveCounts))
	updateAliveCounts()
end

local function updateGamemode()
	local gamemode = workspace:GetAttribute("Gamemode")
	v6.Team.CT.Score.Visible = gamemode ~= "Deathmatch"
	v6.Team.T.Score.Visible = gamemode ~= "Deathmatch"
	local formatted = `{gamemode} | {workspace:GetAttribute("Map")}`
	v6.TopInfo.Gamemode.Text = formatted
	v6.Top.TopInfo.Gamemode.Text = formatted
	local v10 = v3[gamemode]

	if not v10 then
		return
	end

	v6["Counter-Terrorists"].Position = v10.CounterTerroristsPosition
	v6.Terrorists.Position = v10.TerroristsPosition
	local text = v6.Text

	for _, v11 in ipairs(v) do
		text[v11].Position = v10.Headers[v11]
	end

	v6["Counter-Terrorists"].Size = v10.Size
	v6.Terrorists.Size = v10.Size
	v6.DeathmatchDivider.Visible = v10.IsDeathmatch
	v6.Team.Visible = not v10.IsDeathmatch
end

local function isCompetitiveRoundsMode() -- 2 equivalent calls inferred from this helper
	if workspace:GetAttribute("ServerGamemode") ~= "Competitive" then
		return false
	end

	local gamemode = workspace:GetAttribute("Gamemode")
	return gamemode == "Bomb Defusal" or gamemode == "Hostage Rescue"
end

local function getRoundFrame(p: number) -- 2 equivalent calls inferred from this helper
	if not v6 then
		return nil
	end

	local child = v6:FindFirstChild(p <= 12 and "Results1" or "Results2")
	return child and child:FindFirstChild((tostring(p))) or nil
end

local function isPostHalftime()
	local halftimeRound = workspace:GetAttribute("HalftimeRound")
	local currentRound = workspace:GetAttribute("CurrentRound")
	return halftimeRound ~= nil and currentRound ~= nil and halftimeRound < currentRound
end

local function teamColor(p: string) -- 3 equivalent calls inferred from this helper
	if p == "Counter-Terrorists" then
		return color3
	end

	return color4
end

local function getTeamSlotName(p: number, p2: string) -- 2 equivalent calls inferred from this helper
	local v10 = p2 == "Terrorists"
	local v11

	if p <= 12 then
		local halftimeRound = workspace:GetAttribute("HalftimeRound")
		local currentRound = workspace:GetAttribute("CurrentRound")

		if halftimeRound == nil or currentRound == nil then
			v11 = false
		else
			v11 = halftimeRound < currentRound
		end
	else
		v11 = false
	end

	if v11 then
		v10 = not v10
	end

	if v10 then
		return "Team1"
	end

	return "Team2"
end

local function decodeRoundResults()
	local roundResults = workspace:GetAttribute("RoundResults")

	if typeof(roundResults) ~= "string" or roundResults == "" then
		return {}
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, roundResults)

	if success and typeof(result) == "table" then
		return result
	end

	return {}
end

local function applyLossBonusVisibility()
	if not v6 then
		return
	end

	local competitiveRoundsMode = isCompetitiveRoundsMode() -- inferred equivalent call

	for _, childName in ipairs({ "LossBonus", "Results1", "Results2", "Spilter" }) do
		local child = v6:FindFirstChild(childName)

		if child then
			child.Visible = competitiveRoundsMode
		end
	end
end

local function paintLossBar(instance, value: number, color8: Color3)
	if not instance then
		return
	end

	local v10 = math.clamp(value, 0, 4)

	for i = 1, 4 do
		local child = instance:FindFirstChild((tostring(i)))

		if child then
			child.BackgroundColor3 = i <= v10 and color8 or color5
		end
	end
end

local function applyLossBars()
	if not v6 then
		return
	end

	local lossBonus = v6:FindFirstChild("LossBonus")

	if not lossBonus then
		return
	end

	local tLossStreak = workspace:GetAttribute("TLossStreak") or 0
	local ctLossStreak = workspace:GetAttribute("CTLossStreak") or 0
	paintLossBar(lossBonus:FindFirstChild("Bar1"), tLossStreak, color4)
	paintLossBar(lossBonus:FindFirstChild("Bar2"), ctLossStreak, color3)
end

local function resetRoundFrame(child)
	child.BackgroundColor3 = color6

	for _, childName in ipairs(v4) do
		local child2 = child:FindFirstChild(childName)

		if not child2 then
			continue
		end

		child2.Visible = false
		child2.BackgroundTransparency = 0
		local icon = child2:FindFirstChild("Icon")

		if not icon then
			continue
		end

		icon.Image = ""
		icon.ImageTransparency = 0
	end
end

local function paintRoundResult(roundFrame, winner: string, winType: string, round: number)
	roundFrame.BackgroundColor3 = teamColor(winner) -- inferred equivalent call
	local teamSlotName = getTeamSlotName(round, winner) -- inferred equivalent call
	local child = roundFrame:FindFirstChild(teamSlotName)
	local child2 = roundFrame:FindFirstChild(teamSlotName == "Team1" and "Team2" or "Team1")

	if child then
		child.Visible = true
		child.BackgroundTransparency = 0
		child.BackgroundColor3 = teamColor(winner) -- inferred equivalent call
		local icon = child:FindFirstChild("Icon")

		if icon then
			icon.Image = v5[winType] or "rbxassetid://70876442749327"
			icon.ImageColor3 = teamColor(winner) -- inferred equivalent call
			icon.ImageTransparency = 0
		end
	end

	if child2 then
		child2.Visible = false
	end
end

local function hasRoundResult(list, p: number) -- 2 equivalent calls inferred from this helper
	for _, v10 in ipairs(list) do
		if v10.round == p then
			return true
		end
	end

	return false
end

local function applyTrophy(team: string?, list)
	if not v6 then
		return
	end

	local roundsToWin = workspace:GetAttribute("RoundsToWin")

	if not roundsToWin or team ~= "Counter-Terrorists" and team ~= "Terrorists" then
		return
	end

	local ctScore = workspace:GetAttribute("CTScore") or 0
	local tScore = workspace:GetAttribute("TScore") or 0
	local v10 = team == "Counter-Terrorists" and ctScore or tScore
	local v11 = ctScore + tScore + (roundsToWin - v10)

	if v11 < 1 or v11 > 24 then
		return
	end

	local child

	if v6 then
		local child2 = v6:FindFirstChild(v11 <= 12 and "Results1" or "Results2")

		if child2 then
			child = child2:FindFirstChild((tostring(v11))) or nil
		end
	end

	if not child or hasRoundResult(list, v11) then -- inferred equivalent call
		return
	end

	local child2 = child:FindFirstChild(getTeamSlotName(v11, team)) -- inferred equivalent call

	if not child2 then
		return
	end

	child2.Visible = true
	child2.BackgroundTransparency = 1
	local icon = child2:FindFirstChild("Icon")

	if icon then
		icon.Image = "rbxassetid://4857633530"
		icon.ImageColor3 = color
		icon.ImageTransparency = 0
	end
end

local function refreshResults()
	if not (v6 and isCompetitiveRoundsMode()) then -- inferred equivalent call
		return
	end

	for i = 1, 24 do
		local child

		if v6 then
			local child2 = v6:FindFirstChild(i <= 12 and "Results1" or "Results2")

			if child2 then
				child = child2:FindFirstChild((tostring(i))) or nil
			end
		end

		if child then
			resetRoundFrame(child)
		end
	end

	local v10 = decodeRoundResults()

	for _, v11 in ipairs(v10) do
		local roundFrame = getRoundFrame(v11.round) -- inferred equivalent call

		if roundFrame then
			paintRoundResult(roundFrame, v11.winner, v11.winType, v11.round)
		end
	end

	local currentRound = workspace:GetAttribute("CurrentRound")

	if currentRound and currentRound >= 1 and currentRound <= 24 and not hasRoundResult(v10, currentRound) then -- inferred equivalent call
		local roundFrame = getRoundFrame(currentRound) -- inferred equivalent call

		if roundFrame then
			roundFrame.BackgroundColor3 = color7
		end
	end

	applyTrophy(LocalPlayer:GetAttribute("Team"), v10)
end

local function isTextObject(guiObject) -- 3 equivalent calls inferred from this helper
	return guiObject:IsA("TextLabel") or guiObject:IsA("TextButton")
end

local function isImageObject(guiObject) -- 3 equivalent calls inferred from this helper
	return guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton")
end

local function storeTransparencyRecursive(frame, p)
	if frame:IsA("Frame") then
		p[frame] = { BackgroundTransparency = frame.BackgroundTransparency }
	elseif isTextObject(frame) then -- inferred equivalent call
		p[frame] = {
			BackgroundTransparency = frame.BackgroundTransparency,
			TextTransparency = frame.TextTransparency
		}
	elseif isImageObject(frame) then -- inferred equivalent call
		p[frame] = {
			BackgroundTransparency = frame.BackgroundTransparency,
			ImageTransparency = frame.ImageTransparency
		}
	end

	for _, child in frame:GetChildren() do
		storeTransparencyRecursive(child, p)
	end
end

local function setDeadTransparencyRecursive(frame)
	if frame:IsA("Frame") then
		frame.BackgroundTransparency = 1
	elseif isTextObject(frame) then -- inferred equivalent call
		frame.TextTransparency = 0.5
		frame.BackgroundTransparency = 1
	elseif isImageObject(frame) then -- inferred equivalent call
		frame.ImageTransparency = 0.5
		frame.BackgroundTransparency = 1
	end

	for _, child in ipairs(frame:GetChildren()) do
		setDeadTransparencyRecursive(child)
	end
end

local function restoreTransparencyRecursive(frame, p)
	local v10 = p[frame]

	if v10 then
		if frame:IsA("Frame") then
			frame.BackgroundTransparency = v10.BackgroundTransparency
		elseif isTextObject(frame) then -- inferred equivalent call
			frame.TextTransparency = v10.TextTransparency
			frame.BackgroundTransparency = v10.BackgroundTransparency
		elseif isImageObject(frame) then -- inferred equivalent call
			frame.ImageTransparency = v10.ImageTransparency
			frame.BackgroundTransparency = v10.BackgroundTransparency
		end
	end

	for _, child in ipairs(frame:GetChildren()) do
		restoreTransparencyRecursive(child, p)
	end
end

local function releaseParticipant(p) -- 2 equivalent calls inferred from this helper
	local v10 = v9[p]
	v9[p] = nil

	if v10 then
		v10:Destroy()
	end

	Leaderboard.cleanup(p)
	updateAliveCounts()
end

function Leaderboard.createTemplate(instance, p, maid)
	local clone = ReplicatedStorage.Assets.UI.Leaderboard[p]:Clone()
	clone.Player.Image = Participants.HeadshotImage(instance)
	clone.PlayerName.Text = `{Participants.DisplayName(instance)} (@{Participants.Name(instance)})`
	local image = GetBadgeIcon(instance, p)
	clone.Badge.Visible = image ~= ""
	clone.Badge.Image = image
	clone.Assists.Amount.Text = "0"
	clone.Deaths.Amount.Text = "0"
	clone.Score.Amount.Text = "0"
	clone.Kills.Amount.Text = "0"
	clone.MVPs.Amount.Text = "0"
	clone.Money.Amount.Text = ""
	clone.LayoutOrder = 1
	clone.Ping.Text = "0"
	local v10 = {
		[clone] = { BackgroundTransparency = clone.BackgroundTransparency }
	}

	for _, child in clone:GetChildren() do
		storeTransparencyRecursive(child, v10)
	end

	if instance == LocalPlayer then
		clone.BackgroundColor3 = color2
	end

	bindPlayerRowInteractions(clone, instance, maid)

	local function isTeammate() -- 2 equivalent calls inferred from this helper
		local team = instance:GetAttribute("Team")
		return LocalPlayer:GetAttribute("Team") == team
	end

	local function updateMoneyVisibility()
		local gamemode = workspace:GetAttribute("Gamemode")

		if not isTeammate() and gamemode ~= "Deathmatch" then -- inferred equivalent call
			clone.Money.Amount.Text = ""
			return
		end

		local money = instance:GetAttribute("Money")
		clone.Money.Amount.Text = money == nil and "" or `${commaNumber(money)}` or "" -- inferred equivalent call
	end

	maid:Add(Observers.observeAttribute(instance, "Money", updateMoneyVisibility))
	updateMoneyVisibility()
	local uiStroke = clone.Player:FindFirstChildOfClass("UIStroke")

	local function updateTeamColors() -- 1 equivalent call inferred from this helper
		if not uiStroke then
			return
		end

		local team = instance:GetAttribute("Team")

		if LocalPlayer:GetAttribute("Team") ~= team then
			uiStroke.Enabled = false
			return
		end

		local competitivePlayerColor = instance:GetAttribute("CompetitivePlayerColor")

		if not competitivePlayerColor then
			uiStroke.Enabled = false
			return
		end

		uiStroke.Color = competitivePlayerColor
		uiStroke.Enabled = true
	end

	if uiStroke then
		if isTeammate() then -- inferred equivalent call
			local competitivePlayerColor = instance:GetAttribute("CompetitivePlayerColor")

			if competitivePlayerColor then
				uiStroke.Color = competitivePlayerColor
				uiStroke.Enabled = true
			else
				uiStroke.Enabled = false
			end
		else
			uiStroke.Enabled = false
		end
	end

	local function updateTeamDependentState()
		updateMoneyVisibility()
		updateTeamColors() -- inferred equivalent call
	end

	maid:Add(Observers.observeAttribute(LocalPlayer, "Team", updateTeamDependentState))
	maid:Add(Observers.observeAttribute(instance, "Team", updateTeamDependentState))
	maid:Add(Observers.observeAttribute(instance, "CompetitivePlayerColor", updateTeamColors))
	maid:Add(Observers.observeAttribute(instance, "Kills", function(p2)
		clone.Kills.Amount.Text = commaNumber(p2) -- inferred equivalent call
		clone.LayoutOrder = -p2
	end))

	for _, v11 in ipairs({ "Deaths", "Assists", "Score", "MVPs" }) do
		local v12 = v11
		maid:Add(Observers.observeAttribute(instance, v11, function(p2)
			clone[v12].Amount.Text = commaNumber(p2) -- inferred equivalent call
		end))
	end

	maid:Add(Observers.observeAttribute(instance, "Ping", function(text)
		clone.Ping.Text = text
	end))

	local function updateDeadSymbol()
		local isSpectating = instance:GetAttribute("IsSpectating") == true
		local visible = not Participants.IsAlive(instance) or isSpectating

		if clone:FindFirstChild("Dead") then
			clone.Dead.Visible = visible
		end

		if visible then
			if clone:FindFirstChild("Bomb") then
				clone.Bomb.Visible = false
			end

			if clone:FindFirstChild("DefuseKit") then
				clone.DefuseKit.Visible = false
			end

			clone.BackgroundTransparency = 1

			for _, child in ipairs(clone:GetChildren()) do
				setDeadTransparencyRecursive(child)
			end
		else
			local v11 = v10[clone]

			if v11 then
				clone.BackgroundTransparency = v11.BackgroundTransparency
			end

			for _, child in ipairs(clone:GetChildren()) do
				restoreTransparencyRecursive(child, v10)
			end
		end
	end

	local fn
	maid:Add(Observers.observeAttribute(instance, "IsSpectating", updateDeadSymbol))

	local function updateLifeState()
		updateDeadSymbol()

		if fn then
			fn()
		end
	end

	maid:Add(instance:GetAttributeChangedSignal("Dead"):Connect(updateLifeState))
	maid:Add(instance:GetAttributeChangedSignal("Health"):Connect(updateLifeState))
	maid:Add(instance:GetAttributeChangedSignal("CompetitivePlayerColor"):Connect(updateTeamColors))
	updateDeadSymbol()

	if not Participants.IsBot(instance) then
		local listener = DataController.CreateListener(instance, `Loadout.{p}.Equipped.Equipped Badge`, function()
			local image2 = GetBadgeIcon(instance, p)
			clone.Badge.Image = image2
			clone.Badge.Visible = image2 ~= ""
		end)
		maid:Add(function()
			DataController.RemoveListener(instance, `Loadout.{p}.Equipped.Equipped Badge`, listener)
		end)
	end

	fn = function()
		local v11 = instance:GetAttribute("Team") == LocalPlayer:GetAttribute("Team")
		local isSpectating = instance:GetAttribute("IsSpectating") == true
		local v12 = Participants.IsAlive(instance) and not isSpectating

		if p == "Terrorists" then
			local bomb = clone:FindFirstChild("Bomb")

			if bomb then
				local slot5 = instance:GetAttribute("Slot5")

				if not slot5 then
					bomb.Visible = false
					return
				end

				local jsonDecode = HttpService:JSONDecode(slot5)
				bomb.Visible = v11 and v12 and jsonDecode and jsonDecode.Weapon == "C4"
			end
		else
			local defuseKit = p == "Counter-Terrorists" and clone:FindFirstChild("DefuseKit")

			if defuseKit then
				local hasDefuseKit = instance:GetAttribute("HasDefuseKit")
				defuseKit.Visible = v11 and v12 and hasDefuseKit == true
			end
		end
	end

	if p == "Terrorists" then
		maid:Add(Observers.observeAttribute(instance, "Slot5", function()
			fn()
			return function()
				if clone:FindFirstChild("Bomb") then
					clone.Bomb.Visible = false
				end
			end
		end))
	elseif p == "Counter-Terrorists" then
		maid:Add(Observers.observeAttribute(instance, "HasDefuseKit", function()
			fn()
			return function()
				if clone:FindFirstChild("DefuseKit") then
					clone.DefuseKit.Visible = false
				end
			end
		end))
	end

	maid:Add(Observers.observeAttribute(LocalPlayer, "Team", fn))
	fn()
	return clone
end

function Leaderboard.openFrame()
	if EndScreenController.IsActive() or GameState.GetState() == "Map Voting" then
		if v6 and v6.Visible then
			Leaderboard.closeFrame()
		end
	else
		v7 = false
		v6.Visible = true
	end
end

function Leaderboard.IsOpen()
	return v6 ~= nil and v6.Visible
end

function Leaderboard.closeFrame()
	v6.Visible = false
	v7 = false
	resetProfileInspect() -- inferred equivalent call
	CameraController.setForceLockOverride("Leaderboard", false)
end

function Leaderboard.IsRightClickUnlockActive()
	return v7
end

function Leaderboard.characterAdded(p, childName)
	Profiler.scope("UI.Leaderboard.CharacterAdded", function()
		local maid = Janitor.new()
		Leaderboard.cleanup(p)
		local template = Leaderboard.createTemplate(p, childName, maid)
		template.Parent = v6:FindFirstChild(childName)
		maid:Add(function()
			template:Destroy()
		end)
		v8[p] = maid
	end)
end

function Leaderboard.observePlayer(p)
	Observers.observeAttribute(p, "Team", function(p2)
		if p2 == "Terrorists" or p2 == "Counter-Terrorists" then
			Leaderboard.characterAdded(p, p2)
		end

		return function()
			Leaderboard.cleanup(p)
		end
	end)
end

function Leaderboard.cleanup(p)
	local v10 = v8[p]
	v8[p] = nil

	if v10 then
		v10:Destroy()
	end
end

function Leaderboard.Initialize(_, instance)
	v6 = instance
	profileInspect = instance:FindFirstChild("ProfileInspect")

	if profileInspect then
		position = profileInspect.Position
		profileInspect.Visible = false
		ProfileInspect.Bind(profileInspect)
	end

	if inputBeganConnection then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end

	inputBeganConnection = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and v6 and v6.Visible then
			v7 = true
			CameraController.setForceLockOverride("Leaderboard", true)
		end
	end)
	Observers.observeAttribute(workspace, "Gamemode", function()
		updateGamemode()
		updateAliveCounts()
		applyLossBonusVisibility()
		applyLossBars()
		refreshResults()
	end)
	Observers.observeAttribute(workspace, "Map", updateGamemode)
	Observers.observeAttribute(workspace, "ServerGamemode", function()
		applyLossBonusVisibility()
		applyLossBars()
		refreshResults()
	end)
	Observers.observeAttribute(workspace, "GameState", function(p: string?)
		if p == "Map Voting" then
			Leaderboard.closeFrame()
		end

		updateAliveCounts()
	end)
	Observers.observeAttribute(workspace, "CTScore", function(p)
		v6.Team.CT.Score.Text = tostring(p)
		refreshResults()
		return function()
			v6.Team.CT.Score.Text = ""
		end
	end)
	Observers.observeAttribute(workspace, "TScore", function(p)
		v6.Team.T.Score.Text = tostring(p)
		refreshResults()
		return function()
			v6.Team.T.Score.Text = ""
		end
	end)
	Observers.observeAttribute(workspace, "RoundResults", refreshResults)
	Observers.observeAttribute(workspace, "CurrentRound", refreshResults)
	Observers.observeAttribute(workspace, "RoundsToWin", refreshResults)
	Observers.observeAttribute(workspace, "HalftimeRound", refreshResults)
	Observers.observeAttribute(workspace, "CTLossStreak", applyLossBars)
	Observers.observeAttribute(workspace, "TLossStreak", applyLossBars)
	Observers.observeAttribute(LocalPlayer, "Team", refreshResults)
	applyLossBonusVisibility()
	applyLossBars()
	refreshResults()
	Observers.observeAttribute(workspace, "Timer", function(p)
		local text = GetTimerFormat(p)
		v6.TopInfo.Timer.Text = text
		v6.Top.TopInfo.Timer.Text = text
	end)
	Observers.observePlayer(function(p)
		Leaderboard.observePlayer(p)
		observeAliveCountPlayer(p)
		return function()
			releaseParticipant(p) -- inferred equivalent call
		end
	end)
	Participants.Observe(function(p)
		if Participants.IsBot(p) then
			Leaderboard.observePlayer(p)
			observeAliveCountPlayer(p)
		end
	end, function(p)
		if Participants.IsBot(p) then
			releaseParticipant(p) -- inferred equivalent call
		end
	end)
end

function Leaderboard.Start()
	clearFrame(v6:WaitForChild("Counter-Terrorists"))
	clearFrame(v6:WaitForChild("Terrorists"))
	updateAliveCounts()
end

return Leaderboard