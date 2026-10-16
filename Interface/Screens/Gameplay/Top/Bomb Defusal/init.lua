local BombDefusal = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local GetTimerFormat = require(ReplicatedStorage.Components.Common.GetTimerFormat)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local PlayerInfo = require(ReplicatedStorage.Interface.Screens.Gameplay.Top.PlayerInfo)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local color = Color3.fromRGB(85, 255, 85)
local color2 = Color3.fromRGB(250, 31, 31)
local color3 = Color3.fromRGB(85, 255, 85)
local color4 = Color3.fromRGB(230, 36, 36)
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true)
local v = { "Counter-Terrorists", "Terrorists" }
local color5 = Color3.fromRGB(255, 255, 255)
local color6 = Color3.fromRGB(165, 20, 20)
local v2 = { "IsSpectating", "Dead", "Health" }
local v3 = {}
local v4 = {}
local v5 = {}
local v6 = {}
local v7 = {}
local v8 = { ["Counter-Terrorists"] = {}, Terrorists = {} }
local v9 = nil
local v10 = nil
local v11 = nil
local defusedChangedConnection = nil
local v12 = nil

local function clearFrame(instance)
	for _, child in instance:GetChildren() do
		if child.ClassName == "Frame" and child.Name ~= "MorePlayers" then
			child:Destroy()
		end
	end
end

local function IsPlayableTeam(p) -- 4 equivalent calls inferred from this helper
	return p == "Counter-Terrorists" or p == "Terrorists"
end

local function GetPlayerAlive(instance) -- 3 equivalent calls inferred from this helper
	return instance:GetAttribute("IsSpectating") ~= true and Participants.IsAlive(instance)
end

local function RefreshTeamHud(p)
	local v13 = v7[p]
	local v14 = v8[p]
	local count = 0

	for _, v15 in ipairs(v14) do
		if v5[v15] == true then
			count += 1
		end
	end

	v13.playerCountLabel.Text = tostring(count)
	local count2 = #v14
	local v15 = count2 > 10
	local v16 = not v15 and 0 or count2 - 9
	v13.morePlayersFrame.Visible = v16 > 0
	v13.morePlayersAmountLabel.Text = `+{v16}`
	local v17 = v15 and 9 or count2

	for i, v18 in ipairs(v14) do
		local templateByUserId = PlayerInfo.getTemplateByUserId(Participants.Key(v18))

		if templateByUserId and templateByUserId.Parent == v13.holder then
			templateByUserId.Visible = i <= v17
		end
	end
end

local function RefreshAllTeamHuds() -- 3 equivalent calls inferred from this helper
	for _, v13 in ipairs(v) do
		RefreshTeamHud(v13)
	end
end

local function RemovePlayerFromRoster(p)
	local v13 = v6[p]
	v6[p] = nil

	if not IsPlayableTeam(v13) then -- inferred equivalent call
		return nil
	end

	local v14 = v8[v13]

	for i, v15 in ipairs(v14) do
		if v15 ~= p then
			continue
		end

		table.remove(v14, i)
		return v13
	end

	return v13
end

local function SetPlayerRosterTeam(instance, team) -- 1 equivalent call inferred from this helper
	if v6[instance] == team then
		return nil
	end

	local removePlayerFromRoster = RemovePlayerFromRoster(instance)
	v6[instance] = team
	table.insert(v8[team], instance)
	return removePlayerFromRoster
end

local function SetPlayerAliveState(p, flag: boolean) -- 2 equivalent calls inferred from this helper
	if v5[p] == flag then
		return
	end

	v5[p] = flag
	local v13 = v6[p]

	if IsPlayableTeam(v13) then -- inferred equivalent call
		RefreshTeamHud(v13)
	end
end

local function RefreshPlayerAliveState(instance) -- 1 equivalent call inferred from this helper
	SetPlayerAliveState(instance, GetPlayerAlive(instance)) -- inferred equivalent call
end

local function ResetRosterState()
	for _, v13 in ipairs(v) do
		table.clear(v8[v13])
	end

	table.clear(v6)
	table.clear(v5)
	RefreshAllTeamHuds() -- inferred equivalent call
end

local function UpdateFrameVisibility() -- 1 equivalent call inferred from this helper
	local gamemode = workspace:GetAttribute("Gamemode")
	local v13 = gamemode == "Hostage Rescue" or gamemode == "Bomb Defusal"
	local v14 = not v10.Gameplay.Middle.TeamSelection.Visible
	v9.Visible = v13 and v14
end

local function StopBombGlow() -- 2 equivalent calls inferred from this helper
	if v12 then
		v12:Cancel()
		v12 = nil
	end

	v9.Time.Bomb.Glow.ImageTransparency = 0.75
end

local function StartBombGlow()
	if v12 then
		return
	end

	v9.Time.Bomb.Glow.ImageTransparency = 0.75
	v12 = TweenService:Create(v9.Time.Bomb.Glow, tweenInfo, { ImageTransparency = 0 })
	v12:Play()
end

local function UpdateBombDisplay()
	local v13 = v11

	if v13 then
		v9.Time.Timer.Visible = false
		v9.Time.Bomb.Visible = true
		local defused = v13:GetAttribute("Defused") == true
		v9.Time.Bomb.Glow.ImageColor3 = defused and color or color2
		v9.Time.Bomb.ImageColor3 = defused and color3 or color4

		if not defused then
			StartBombGlow()
			return
		end

		StopBombGlow() -- inferred equivalent call
	else
		StopBombGlow() -- inferred equivalent call
		v9.Time.Bomb.Glow.ImageColor3 = color2
		v9.Time.Bomb.ImageColor3 = color4
		v9.Time.Timer.Visible = true
		v9.Time.Bomb.Visible = false
	end
end

local function SetCurrentBomb(p) -- 2 equivalent calls inferred from this helper
	if defusedChangedConnection then
		defusedChangedConnection:Disconnect()
		defusedChangedConnection = nil
	end

	v11 = p

	if v11 then
		defusedChangedConnection = v11:GetAttributeChangedSignal("Defused"):Connect(UpdateBombDisplay)
	end

	UpdateBombDisplay()
end

function BombDefusal.CreateTemplate(instance)
	Profiler.scope("UI.BombDefusal.CreateTemplate", function()
		local gamemode = workspace:GetAttribute("Gamemode")
		local team = instance:GetAttribute("Team")

		if gamemode == "Bomb Defusal" or gamemode == "Hostage Rescue" then
			BombDefusal.CleanupTemplate(instance)
			local template = PlayerInfo.createTemplate(instance, v9[team])

			if template then
				v3[instance] = template
			end
		end
	end)
end

function BombDefusal.CleanupTemplate(p)
	local v13 = v3[p]
	v3[p] = nil

	if v13 then
		PlayerInfo.cleanupTemplate(p)
		v13:Destroy()
	end
end

function BombDefusal.PlayerAdded(instance)
	local v13 = v4[instance]

	if v13 then
		v13:Destroy()
	end

	local maid = Janitor.new()
	v4[instance] = maid

	local function handleTeamUpdate()
		local team = instance:GetAttribute("Team")

		if IsPlayableTeam(team) then -- inferred equivalent call
			local setPlayerRosterTeam = SetPlayerRosterTeam(instance, team) -- inferred equivalent call
			v5[instance] = GetPlayerAlive(instance) -- inferred equivalent call
			BombDefusal.CreateTemplate(instance)

			if setPlayerRosterTeam then
				RefreshTeamHud(setPlayerRosterTeam)
			end

			RefreshTeamHud(team)

			if instance == LocalPlayer then
				for _, v14 in Participants.GetAll(), nil, nil do
					if v14 == LocalPlayer then
						continue
					end

					if IsPlayableTeam(v14:GetAttribute("Team")) then -- inferred equivalent call
						BombDefusal.CreateTemplate(v14)
					else
						BombDefusal.CleanupTemplate(v14)
					end
				end

				RefreshAllTeamHuds() -- inferred equivalent call
			end

			PlayerInfo.refreshCompetitiveColors()
		else
			local removePlayerFromRoster = RemovePlayerFromRoster(instance)
			v5[instance] = nil
			BombDefusal.CleanupTemplate(instance)

			if removePlayerFromRoster then
				RefreshTeamHud(removePlayerFromRoster)
			end
		end
	end

	maid:Add(instance:GetAttributeChangedSignal("Team"):Connect(handleTeamUpdate))

	for _, v14 in ipairs(v2) do
		maid:Add(instance:GetAttributeChangedSignal(v14):Connect(function()
			RefreshPlayerAliveState(instance) -- inferred equivalent call
		end))
	end

	maid:Add(function()
		local removePlayerFromRoster = RemovePlayerFromRoster(instance)
		v5[instance] = nil

		if removePlayerFromRoster then
			RefreshTeamHud(removePlayerFromRoster)
		end
	end)
	handleTeamUpdate()
end

function BombDefusal.Initialize(p, p2)
	v10 = p
	v9 = p2

	for _, v13 in ipairs(v) do
		local holder = v9[v13]
		v7[v13] = {
			holder = holder,
			playerCountLabel = v9.Time[v13].Players,
			morePlayersFrame = holder.MorePlayers,
			morePlayersAmountLabel = holder.MorePlayers.Amount
		}
	end

	Observers.observeAttribute(workspace, "CTScore", function(p3)
		v9.Time["Counter-Terrorists"].Score.Text = tostring(p3)
		return function() end
	end)
	Observers.observeAttribute(workspace, "TScore", function(p3)
		v9.Time.Terrorists.Score.Text = tostring(p3)
		return function() end
	end)
	Observers.observeAttribute(workspace, "ServerGamemode", function(_)
		PlayerInfo.refreshCompetitiveColors()
		return function() end
	end)
	Remotes.UI.UIPlayerKilled.Listen(function(p3)
		local victim = tonumber(p3.Victim)
		local v13 = Participants.FromKey(victim)

		if v13 then
			local templateByUserId = PlayerInfo.getTemplateByUserId(victim)

			if templateByUserId and templateByUserId.Parent then
				local isSpectating = v13:GetAttribute("IsSpectating") == true

				if not Participants.IsAlive(v13) or isSpectating then
					PlayerInfo.applyTemplateLifeState(templateByUserId, true)
				end
			end

			SetPlayerAliveState(v13, GetPlayerAlive(v13)) -- inferred equivalent call
		end

		local killer = tonumber(p3.Killer)

		if Participants.FromKey(killer) then
			PlayerInfo.incrementTemplateKills(killer)
		end
	end)
	Remotes.UI.RoundWinner.Listen(function(_)
		PlayerInfo.setTeammateInfoRevealed(true)
	end)
	GameState.ListenToState(function(p3: string?, p4: string)
		if p4 == "Buy Period" then
			PlayerInfo.setTeammateInfoRevealed(true)
		elseif p3 == "Buy Period" and p4 == "Round In Progress" then
			PlayerInfo.setTeammateInfoRevealed(false)
		end
	end)
	Observers.observeAttribute(workspace, "Timer", function(p3)
		local gamemode = workspace:GetAttribute("Gamemode")
		local gameState = workspace:GetAttribute("GameState")
		v9.Time.Timer.TextColor3 = color5
		v9.Time.Timer.Text = GetTimerFormat(p3)

		if (gamemode == "Hostage Rescue" or gamemode == "Bomb Defusal") and gameState ~= "Warmup" and p3 <= 10 then
			v9.Time.Timer.TextColor3 = color6
		end

		return function() end
	end, function(value)
		return typeof(value) == "number"
	end)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(UpdateFrameVisibility)
	v10.Gameplay.Middle.TeamSelection:GetPropertyChangedSignal("Visible"):Connect(UpdateFrameVisibility)
	CollectionService:GetInstanceAddedSignal("Bomb"):Connect(SetCurrentBomb)
	CollectionService:GetInstanceRemovedSignal("Bomb"):Connect(function(p3)
		if p3 == v11 then
			SetCurrentBomb(nil) -- inferred equivalent call
		end
	end)
	UpdateFrameVisibility() -- inferred equivalent call
	SetCurrentBomb(CollectionService:GetTagged("Bomb")[1]) -- inferred equivalent call
	RefreshAllTeamHuds() -- inferred equivalent call
end

function BombDefusal.Start()
	clearFrame(v9["Counter-Terrorists"])
	clearFrame(v9.Terrorists)
	ResetRosterState()

	for _, v13 in Players:GetPlayers() do
		BombDefusal.PlayerAdded(v13)
	end

	Players.PlayerAdded:Connect(BombDefusal.PlayerAdded)

	local function removeParticipant(p) -- 1 equivalent call inferred from this helper
		local v13 = v4[p]
		v4[p] = nil

		if v13 then
			v13:Destroy()
		end

		BombDefusal.CleanupTemplate(p)
	end

	Players.PlayerRemoving:Connect(removeParticipant)
	Participants.Observe(function(p)
		if Participants.IsBot(p) then
			BombDefusal.PlayerAdded(p)
		end
	end, function(p)
		if Participants.IsBot(p) then
			removeParticipant(p) -- inferred equivalent call
		end
	end)
end

return BombDefusal