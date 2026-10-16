local Deathmatch = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local GetTimerFormat = require(ReplicatedStorage.Components.Common.GetTimerFormat)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local PlayerInfo = require(ReplicatedStorage.Interface.Screens.Gameplay.Top.PlayerInfo)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(165, 20, 20)
local v = nil
local v2 = nil
local v3 = {}
local v4 = {}

local function clearFrame(players)
	for _, child in ipairs(players:GetChildren()) do
		if child.ClassName == "Frame" and child.Name ~= "MorePlayers" then
			child:Destroy()
		end
	end
end

local function compareLayoutOrder(p, p2)
	return p.LayoutOrder < p2.LayoutOrder
end

local function updateFrameVisibility()
	if not (v and v2) then
		return
	end

	local gamemode = workspace:GetAttribute("Gamemode")
	v.Visible = gamemode == "Deathmatch" and not v2.Gameplay.Middle.TeamSelection.Visible

	if not v.Visible then
		return
	end

	local morePlayers = v.Players.MorePlayers
	local children = {}

	for _, child in ipairs(v.Players:GetChildren()) do
		if child.ClassName == "Frame" and child.Name ~= "MorePlayers" then
			table.insert(children, child)
		end
	end

	table.sort(children, compareLayoutOrder)

	for i, v5 in ipairs(children) do
		v5.Visible = i <= 5
	end

	local v5 = math.max(#children - 5, 0)
	morePlayers.Visible = v5 > 0
	morePlayers.Content.Amount.Text = `+{v5}`
end

function Deathmatch.createTemplate(instance)
	Profiler.scope("UI.Deathmatch.CreateTemplate", function()
		local gamemode = workspace:GetAttribute("Gamemode")
		local team = instance:GetAttribute("Team")

		if gamemode == "Deathmatch" and (team == "Terrorists" or team == "Counter-Terrorists") then
			Deathmatch.cleanupPlayerTemplate(instance)
			local template = PlayerInfo.createTemplate(instance, v.Players)

			if template then
				v3[instance] = template
			end

			updateFrameVisibility()
		end
	end)
end

function Deathmatch.cleanupPlayerTemplate(p)
	local v5 = v3[p]
	v3[p] = nil

	if v5 then
		PlayerInfo.cleanupTemplate(p)
		v5:Destroy()
		updateFrameVisibility()
	end
end

function Deathmatch.playerAdded(instance)
	local v5 = v4[instance]

	if v5 then
		v5:Destroy()
	end

	local maid = Janitor.new()
	v4[instance] = maid

	local function applyLifeStateToTemplate()
		local templateByUserId = PlayerInfo.getTemplateByUserId(Participants.Key(instance))

		if not templateByUserId then
			return
		end

		local v6 = not Participants.IsAlive(instance) or instance:GetAttribute("IsSpectating") == true
		PlayerInfo.applyTemplateLifeState(templateByUserId, v6)
	end

	local function handleTeamUpdate() -- 1 equivalent call inferred from this helper
		local team = instance:GetAttribute("Team")

		if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
			Deathmatch.cleanupPlayerTemplate(instance)
			return
		end

		Deathmatch.createTemplate(instance)
		applyLifeStateToTemplate()
	end

	maid:Add(instance:GetAttributeChangedSignal("Team"):Connect(handleTeamUpdate))
	maid:Add(instance:GetAttributeChangedSignal("IsSpectating"):Connect(applyLifeStateToTemplate))
	maid:Add(instance:GetAttributeChangedSignal("Dead"):Connect(applyLifeStateToTemplate))
	maid:Add(instance:GetAttributeChangedSignal("Health"):Connect(applyLifeStateToTemplate))
	maid:Add(instance:GetAttributeChangedSignal("Score"):Connect(function()
		task.defer(updateFrameVisibility)
	end))
	handleTeamUpdate() -- inferred equivalent call
end

function Deathmatch.Initialize(p, p2)
	v2 = p
	v = p2
	Observers.observeAttribute(workspace, "Timer", function(p3)
		local gamemode = workspace:GetAttribute("Gamemode")
		local gameState = workspace:GetAttribute("GameState")
		v.Time.Timer.TextColor3 = color
		v.Time.Timer.Text = GetTimerFormat(p3)

		if gamemode == "Deathmatch" and gameState ~= "Warmup" and p3 <= 10 then
			v.Time.Timer.TextColor3 = color2
			Router.broadcastRouter("PlayCountdownTimer")
		end
	end)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(updateFrameVisibility)
	v2.Gameplay.Middle.TeamSelection:GetPropertyChangedSignal("Visible"):Connect(updateFrameVisibility)
	updateFrameVisibility()
end

function Deathmatch.Start()
	clearFrame(v.Players)

	for _, v5 in Players:GetPlayers() do
		Deathmatch.playerAdded(v5)
	end

	Players.PlayerAdded:Connect(Deathmatch.playerAdded)

	local function removeParticipant(p) -- 1 equivalent call inferred from this helper
		local v5 = v4[p]
		v4[p] = nil

		if v5 then
			v5:Destroy()
		end

		Deathmatch.cleanupPlayerTemplate(p)
		updateFrameVisibility()
	end

	Players.PlayerRemoving:Connect(removeParticipant)
	Participants.Observe(function(p)
		if Participants.IsBot(p) then
			Deathmatch.playerAdded(p)
		end
	end, function(p)
		if Participants.IsBot(p) then
			removeParticipant(p) -- inferred equivalent call
		end
	end)
end

return Deathmatch