local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoiceChat2 = require(ReplicatedStorage.Controllers.InputController.Actions.VoiceChat)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Colors = require(ReplicatedStorage.Database.Custom.GameStats.Settings.Colors)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local v = { "IsSpectating", "Team", "CompetitivePlayerColor", "Dead", "Health" }
local parent = nil
local v2 = nil
local v3 = {}
local connection = nil

local function compareVisibleEntries(data, data2)
	if data.IsSpeaking ~= data2.IsSpeaking then
		return data.IsSpeaking
	end

	if data.LastSpokeAt == data2.LastSpokeAt then
		return data.Player.UserId < data2.Player.UserId
	end

	return data.LastSpokeAt > data2.LastSpokeAt
end

local function updateVisibleTemplates(now: number)
	local v4 = {}

	for _, v5 in pairs(v3) do
		local isSpeaking = v5.IsSpeaking

		if not isSpeaking and v5.StoppedAt then
			isSpeaking = now - v5.StoppedAt < 2.85
		end

		if isSpeaking then
			table.insert(v4, v5)
		else
			v5.Alpha = 1
			v5.Frame.Visible = false
		end
	end

	table.sort(v4, compareVisibleEntries)
	local count = 0

	for i, v5 in ipairs(v4) do
		local visible = i <= 3
		v5.Frame.LayoutOrder = i
		v5.Frame.Visible = visible

		if not visible then
			continue
		end

		count += 1

		if v5.IsSpeaking or not v5.StoppedAt then
			v5.Alpha = 0
		else
			v5.Alpha = math.clamp((now - v5.StoppedAt - 2.5) / 0.35, 0, 1)
		end

		for k, v6 in pairs(v5.OriginalTransparency) do
			if not k.Parent then
				continue
			end

			for k2, v7 in pairs(v6) do
				k[k2] = v7 + (1 - v7) * v5.Alpha
			end
		end
	end

	if parent then
		parent.Visible = count > 0
	end

	if #v4 == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function ensureRenderConnection()
	if connection then
		return
	end

	connection = RunServiceController.BindToHeartbeat("UI.VoiceChat.UpdateVisibleTemplates", function()
		updateVisibleTemplates(os.clock())
	end)
end

local function updateEntry(data, visible: boolean?)
	local team = data.Player:GetAttribute("Team")
	local competitivePlayerColor = data.Player:GetAttribute("CompetitivePlayerColor")

	if not competitivePlayerColor and team then
		competitivePlayerColor = Colors["Team Color"][team]
	end

	if visible ~= nil then
		data.SpeakingIcon.Visible = visible
		data.NotSpeakingIcon.Visible = not visible
	end

	local v4 = data.Player:GetAttribute("IsSpectating") == true or data.Player:GetAttribute("Team") == "Spectators"
	data.DeadFrame.Visible = v4 or not CharacterResolver.isAlivePlayer(data.Player)

	if competitivePlayerColor then
		data.ColorGraphic.BackgroundColor3 = competitivePlayerColor
	end
end

local function createEntry(player)
	if v3[player] then
		return v3[player]
	end

	if not (v2 and parent) then
		return nil
	end

	local clone = v2:Clone()
	clone.Name = tostring(player.UserId)
	clone.Visible = false
	clone.Parent = parent
	local displayName = clone.DisplayName
	local profile = clone.Profile
	displayName.Text = player.DisplayName
	profile.Image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=150&h=150`
	local v4 = {
		Alpha = 1,
		ColorGraphic = clone.ColorDot.Graphic,
		Connections = {},
		DeadFrame = profile.IsKilled,
		Frame = clone,
		IsSpeaking = false,
		LastSpokeAt = 0,
		NotSpeakingIcon = clone.IsNotSpeaking,
		OriginalTransparency = {},
		Player = player,
		SpeakingIcon = clone.IsSpeaking,
		StoppedAt = nil
	}
	local descendants = { clone }

	for _, descendant in ipairs(clone:GetDescendants()) do
		table.insert(descendants, descendant)
	end

	for _, instance in ipairs(descendants) do
		local v5 = {}

		if instance:IsA("GuiObject") then
			v5.BackgroundTransparency = instance.BackgroundTransparency
		end

		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			v5.TextTransparency = instance.TextTransparency
			v5.TextStrokeTransparency = instance.TextStrokeTransparency
		end

		if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			v5.ImageTransparency = instance.ImageTransparency
		end

		if instance:IsA("UIStroke") then
			v5.Transparency = instance.Transparency
		end

		if next(v5) then
			v4.OriginalTransparency[instance] = v5
		end
	end

	for _, v5 in ipairs(v) do
		table.insert(v4.Connections, player:GetAttributeChangedSignal(v5):Connect(function()
			updateEntry(v4)
		end))
	end

	v3[player] = v4
	updateEntry(v4, false)
	return v4
end

local function destroyEntry(p)
	local v4 = v3[p]

	if not v4 then
		return
	end

	v3[p] = nil

	for _, connection2 in ipairs(v4.Connections) do
		connection2:Disconnect()
	end

	table.clear(v4.Connections)
	v4.Frame:Destroy()
	updateVisibleTemplates(os.clock())
end

local function setPlayerSpeaking(player, isSpeaking: boolean)
	local v4 = v3[player] or createEntry(player)

	if not v4 then
		return
	end

	v4.IsSpeaking = isSpeaking

	if isSpeaking then
		v4.Alpha = 0
		v4.LastSpokeAt = os.clock()
		v4.StoppedAt = nil
	else
		v4.StoppedAt = os.clock()
	end

	updateEntry(v4, isSpeaking)
	updateVisibleTemplates(os.clock())

	if connection then
		return
	end

	connection = RunServiceController.BindToHeartbeat("UI.VoiceChat.UpdateVisibleTemplates", function()
		updateVisibleTemplates(os.clock())
	end)
end

local VoiceChat = {}

function VoiceChat.Initialize(_, p)
	local template = p.Template
	parent = p
	v2 = template
	template.Visible = false
	parent.Visible = false
end

function VoiceChat.Start()
	if not v2 then
		return
	end

	VoiceChat2.SpeakingChanged:Connect(setPlayerSpeaking)
	Players.PlayerAdded:Connect(createEntry)
	Players.PlayerRemoving:Connect(destroyEntry)

	for _, v4 in ipairs(Players:GetPlayers()) do
		createEntry(v4)

		if not VoiceChat2.IsPlayerSpeaking(v4) then
			continue
		end

		local v5 = v3[v4] or createEntry(v4)

		if not v5 then
			continue
		end

		v5.IsSpeaking = true
		v5.Alpha = 0
		v5.LastSpokeAt = os.clock()
		v5.StoppedAt = nil
		updateEntry(v5, true)
		updateVisibleTemplates(os.clock())

		if not connection then
			connection = RunServiceController.BindToHeartbeat("UI.VoiceChat.UpdateVisibleTemplates", function()
				updateVisibleTemplates(os.clock())
			end)
		end
	end

	updateVisibleTemplates(os.clock())
end

return VoiceChat