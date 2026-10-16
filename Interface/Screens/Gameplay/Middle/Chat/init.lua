local Chat = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local BuyMenu = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.BuyMenu)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local CanPlayerUseChatService = require(ReplicatedStorage.Database.Components.Common.Roblox.CanPlayerUseChatService)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local ChatModes = require(ReplicatedStorage.Database.Custom.GameStats.UI.Chat.ChatModes)
local Platforms = require(ReplicatedStorage.Database.Custom.GameStats.UI.Chat.Platforms)
local HTML = require(ReplicatedStorage.Database.Custom.GameStats.UI.Chat.HTML)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
require(script:WaitForChild("Types"))
local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear)
local template = nil
local v = nil
local v2 = { nil }
v2[1] = Platforms.PC
local All = ChatModes.Modes.All
local v3 = false
local v4 = false
local now = 0
local v5 = {}
local v6 = {}
local connection = nil

local function IsSystemChatMessagesEnabled() -- 2 equivalent calls inferred from this helper
	return DataController.Get(LocalPlayer, "Settings.Game.HUD.System Chat Messages") ~= false
end

local function EscapeRichText(value: string) -- 8 equivalent calls inferred from this helper
	return (value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function ColorToRGB(color: Color3) -- 1 equivalent call inferred from this helper
	local v7 = math.floor(color.R * 255 + 0.5)
	local v8 = math.floor(color.G * 255 + 0.5)
	local v9 = math.floor(color.B * 255 + 0.5)
	return string.format("rgb(%d,%d,%d)", v7, v8, v9)
end

local function IsCompetitiveServerGamemode() -- 2 equivalent calls inferred from this helper
	return workspace:GetAttribute("ServerGamemode") == "Competitive"
end

local function GetChatNameColorFormat(data) -- 1 equivalent call inferred from this helper
	return HTML.TeamColors[data.team] or ""
end

local function IsMobilePlatform() -- 2 equivalent calls inferred from this helper
	return table.find(v2, Platforms.Mobile) ~= nil
end

local function FormatAnnouncerName(team, displayName: string) -- 3 equivalent calls inferred from this helper
	local v7 = HTML.TeamColors[team] or ""
	local escapeRichText = EscapeRichText(displayName) -- inferred equivalent call

	if v7 == "" then
		return escapeRichText .. " "
	end

	return (string.format(v7, escapeRichText))
end

local function GetPlaceholderText()
	if IsMobilePlatform() then -- inferred equivalent call
		return "Tap to chat"
	end

	if table.find(v2, Platforms.Console) or table.find(v2, Platforms.VR) then
		return ""
	end

	return string.format(
		"Team Chat (%s) | All Chat (%s)",
		InputController.GetActionKeybind("Team Message") or "U",
		InputController.GetActionKeybind("Chat Message") or "Y"
	)
end

local function OpenChatFrame(state)
	Profiler.mark("UI.Chat.OpenChatFrame")

	if not (state.frame and state.frame.Parent) then
		return
	end

	if v4 or state.fadeConnection or state.frame.Message.TextTransparency >= 1 then
		return
	end

	local tween = TweenService:Create(state.frame.Message, tweenInfo, { TextTransparency = 1 })
	local fadeConnection = {
		Disconnect = function()
			tween:Cancel()
		end
	}
	tween.Completed:Once(function()
		if state.fadeConnection == fadeConnection then
			state.fadeConnection = nil
		end
	end)
	state.fadeConnection = fadeConnection
	tween:Play()
end

local function SetChatActive(flag: boolean)
	v4 = flag
	v.Chat.ScrollingFrame.ScrollBarImageTransparency = flag and 0 or 1
	v.Chat.BackgroundTransparency = flag and 0.55 or 1
	v.Type.BackgroundTransparency = flag and 0.55 or 1
	v.BackgroundTransparency = flag and 0.55 or 1
	v.Type.TextBox.PlaceholderColor3 = flag and Color3.fromRGB(141, 141, 141) or Color3.new(1, 1, 1)

	if not flag then
		v.Type.TextBox.PlaceholderText = GetPlaceholderText()
	end

	local now2 = os.clock()

	for _, v7 in ipairs(v5) do
		if flag then
			if v7.fadeConnection then
				v7.fadeConnection:Disconnect()
				v7.fadeConnection = nil
			end

			v7.frame.Message.TextTransparency = 0
		else
			local v8 = now2 - v7.timestamp

			if v8 > 10 then
				v7.frame.Message.TextTransparency = 1
			else
				task.delay(10 - v8, OpenChatFrame, v7)
			end
		end
	end
end

local function CloseChat()
	if not v4 then
		return
	end

	LocalPlayer:SetAttribute("IsPlayerChatting", nil)
	local menu = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
		and LocalPlayer.PlayerGui.MainGui:FindFirstChild("Menu")
	local visible = menu and menu.Visible
	local isCaseSceneActive = MenuState.IsCaseSceneActive()
	local isInspectActive = MenuState.IsInspectActive()

	if not (visible or isCaseSceneActive or isInspectActive) and table.find(v2, Platforms.Mobile) == nil then
		CameraController.setMouseEnabled(false)
	end

	v.Type.TextBox:ReleaseFocus()
	v.Type.TextBox.TextTransparency = 1
	v.Type.TextBox.Text = ""
	SetChatActive(false)
	now = os.clock()

	if IsMobilePlatform() then -- inferred equivalent call
		v.Visible = false
	end
end

local function AddMessageToUI(p)
	local v7 = #v5 >= 15 and v5[15]

	if v7 then
		v7.frame:Destroy()
		table.remove(v5, 15)
	end

	table.insert(v5, 1, p)

	for i, v8 in ipairs(v5) do
		v8.frame.LayoutOrder = #v5 - i
	end

	p.frame.Message.TextTransparency = 0

	if not v4 then
		task.delay(10, OpenChatFrame, p)
	end

	p.frame.Parent = v.Chat.ScrollingFrame
	Profiler.defer("UI.Chat.ScrollToBottomDeferred", function()
		v.Chat.ScrollingFrame.CanvasPosition = Vector2.new(0, v.Chat.ScrollingFrame.AbsoluteCanvasSize.Y)
	end)
end

local function ProcessMessageQueue()
	Profiler.mark("UI.Chat.ProcessMessageQueue")

	if v3 or #v6 == 0 then
		if #v6 == 0 and connection then
			connection:Disconnect()
			connection = nil
		end
	else
		local count = 0
		v3 = true

		while #v6 > 0 and count < 2 do
			local v7 = table.remove(v6, 1)

			if not v7 then
				continue
			end

			local clone = template:Clone()
			clone.Message.Text = v7.text
			AddMessageToUI({
				frame = clone,
				timestamp = v7.timestamp,
				text = v7.text,
				fadeConnection = nil
			})
			count += 1
		end

		v3 = false

		if #v6 == 0 and connection then
			connection:Disconnect()
			connection = nil
		elseif #v6 > 0 and not connection then
			connection = RunServiceController.BindToHeartbeat("UI.Chat.ProcessMessageQueue", function()
				Profiler.mark("UI.Chat.Heartbeat")
				ProcessMessageQueue()
			end)
		end
	end
end

local function QueueMessage(text: string)
	Profiler.mark("UI.Chat.QueueMessage")
	table.insert(v6, { text = text, timestamp = os.clock() })

	if not v3 then
		ProcessMessageQueue()
	end
end

function Chat.OpenChat(p)
	Profiler.mark("UI.Chat.OpenChat")

	if v4 or not CanPlayerUseChatService(LocalPlayer) then
		return
	end

	BuyMenu.closeFrame()
	All = p
	v.Visible = true
	v.Type.TextBox.PlaceholderText = ChatModes.Labels[p]
	v.Type.TextBox.TextTransparency = 0
	v.Type.TextBox.Text = ""
	SetChatActive(true)

	if table.find(v2, Platforms.Mobile) == nil then
		CameraController.setMouseEnabled(true)
	end

	LocalPlayer:SetAttribute("IsPlayerChatting", true)
	v.Type.TextBox:CaptureFocus()
	task.delay(0, function()
		v.Type.TextBox.Text = ""
	end)
end

function Chat.CloseChat()
	CloseChat()
end

function Chat.ToggleChat(p)
	if v4 or os.clock() - now < 0.25 then
		CloseChat()
	else
		Chat.OpenChat(p)
	end
end

function Chat.ProcessChatData(data, flag: boolean)
	Profiler.mark("UI.Chat.ProcessChatData")
	local v7 = not (data.role and HTML.Roles[data.role]) and "" or HTML.Roles[data.role]
	local all

	if flag then
		all = HTML.Prefixes[data.team] or HTML.Prefixes.All
	else
		all = HTML.Prefixes.All
	end

	QueueMessage(v7 .. all .. string.format(GetChatNameColorFormat(data), EscapeRichText(data.displayName)) .. (not data.verified and "" or HTML.Badges.Verified .. " ") .. (data.alive and "" or HTML.Suffixes.Dead) .. ": " .. data.message) -- inferred equivalent call
end

function Chat.ProcessTeamJoin(p: string, p2)
	local teamJoinMessage = HTML.TeamJoinMessages[p2]

	if not teamJoinMessage then
		return
	end

	QueueMessage(string.format(teamJoinMessage, p))
end

function Chat.ProcessPlayerLeave(p: string)
	QueueMessage(string.format(HTML.PlayerLeave, p))
end

function Chat.ProcessPlayerBanned(p: string)
	QueueMessage(string.format(HTML.PlayerBanned, p))
end

function Chat.ProcessSystemMessage(value: string)
	QueueMessage(string.format(HTML.SystemMessage, EscapeRichText(value))) -- inferred equivalent call
end

function Chat.ProcessTeamDamage(p)
	if p.messageType == "Warning" then
		QueueMessage(HTML.TeamDamageWarning)
	elseif p.messageType == "Announcement" then
		QueueMessage(string.format(HTML.TeamDamageAnnouncement, EscapeRichText(p.displayName))) -- inferred equivalent call
	end
end

function Chat.ProcessKillMessage(data)
	Profiler.mark("UI.Chat.ProcessKillMessage")

	if tostring(data.Killer) == tostring(LocalPlayer.UserId) then
		local points = data.Points or 11
		local v7 = points == 1 and "point" or "points"
		QueueMessage(string.format(HTML.Points.Deathmatch, points, v7, data.Weapon))
	end
end

function Chat.ProcessMoneyReward(data)
	local v7 = HTML.Money[data.source]

	if not v7 then
		return
	end

	local amount = tonumber(data.amount)

	if not amount then
		return
	end

	if data.source ~= "Kill" then
		QueueMessage(string.format(v7, (math.abs(amount))))
		return
	end

	local killWithWeapon = data.weaponName and HTML.Money.KillWithWeapon or HTML.Money.Kill
	QueueMessage(data.weaponName and string.format(killWithWeapon, amount, data.weaponName) or string.format(killWithWeapon, amount))
end

function Chat.ProcessDefuseStart(data)
	local formatAnnouncerName = FormatAnnouncerName(data.team, data.displayName) -- inferred equivalent call
	local v7 = HTML.Prefixes[data.team] or HTML.Prefixes.All
	local v8 = "Bombsite " .. (data.site or "?")
	QueueMessage(v7 .. formatAnnouncerName .. string.format(
		"<font color=\"%s\">@%s</font>",
		HTML.DefuseStartLocationColor,
		EscapeRichText(v8) -- inferred equivalent call
	) .. "<font color=\"rgb(255,255,255)\">: </font>" .. HTML.DefuseStartAction)
end

function Chat.ProcessGrenadeThrow(data)
	local formatAnnouncerName = FormatAnnouncerName(data.team, data.displayName) -- inferred equivalent call
	local v7 = HTML.Prefixes[data.team] or HTML.Prefixes.All
	local v8 = HTML.GrenadeDisplayNames[data.grenadeName] or data.grenadeName:gsub(" Grenade", "")
	local v9 = HTML.GrenadeColors[data.grenadeName] or "rgb(255,255,255)"
	QueueMessage(v7 .. formatAnnouncerName .. "<font color=\"rgb(255,255,255)\">: </font>" .. string.format(
		"<font color=\"%s\">%s!</font>",
		v9,
		EscapeRichText(v8) -- inferred equivalent call
	))
end

local function QueueItemAnnouncement(data, p: string)
	local formatAnnouncerName = FormatAnnouncerName(data.team, data.displayName) -- inferred equivalent call
	local colorToRGB = ColorToRGB((Rarities[data.rarity] or Rarities.Stock).Color) -- inferred equivalent call
	local escapeRichText = EscapeRichText(data.weaponName) -- inferred equivalent call
	local escapeRichText2 = EscapeRichText(data.skinName) -- inferred equivalent call
	local v7 = (data.statTrak and "KillTrak™ " or "") .. escapeRichText .. " | " .. escapeRichText2
	QueueMessage(formatAnnouncerName .. `<font color="rgb(255,255,255)">{p}</font>` .. string.format(
		"<font color=\"%s\">%s</font>",
		colorToRGB,
		v7
	))
end

function Chat.ProcessCaseOpened(p)
	Profiler.mark("UI.Chat.ProcessCaseOpened")
	QueueItemAnnouncement(p, "opened a case and found: ")
end

function Chat.ProcessTradeUp(p)
	Profiler.mark("UI.Chat.ProcessTradeUp")
	QueueItemAnnouncement(p, "traded up and crafted: ")
end

local v7 = { ["Show Player Crosshairs"] = true, ["Show my crosshair when spectating bots"] = true }

local function CopySpectatedCrosshair()
	local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
	local Settings = require(ReplicatedStorage.Interface.Screens.Menu.Settings)
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
	local player = currentSpectateInstance and currentSpectateInstance.Player

	if not player then
		Chat.ProcessSystemMessage("You must be spectating a player to use /cc.")
		return
	end

	if player == LocalPlayer then
		Chat.ProcessSystemMessage("You can't copy your own crosshair.")
		return
	end

	if not player:IsA("Player") then
		Chat.ProcessSystemMessage("Bots don't have a crosshair to copy.")
		return
	end

	local v8 = DataController.Get(player, "Settings.Game.Crosshair")

	if type(v8) ~= "table" then
		Chat.ProcessSystemMessage(`Couldn't read {player.DisplayName}'s crosshair.`)
		return
	end

	local flag = false

	for k, v9 in pairs(v8) do
		if v7[k] then
			continue
		end

		Settings.SettingChanged("Game", k, v9)
		flag = true
	end

	if flag then
		Chat.ProcessSystemMessage(`Copied {player.DisplayName}'s crosshair.`)
	end
end

local function ToggleDeveloperConsole() -- 1 equivalent call inferred from this helper
	local success, core = pcall(StarterGui.GetCore, StarterGui, "DevConsoleVisible")

	if not success then
		return
	end

	pcall(StarterGui.SetCore, StarterGui, "DevConsoleVisible", not core)
end

function Chat.HandleChatCommand(value: string)
	local v8 = string.lower(string.match(value, "^%s*(%S+)") or "")

	if v8 == "/cc" then
		CopySpectatedCrosshair()
		return true
	end

	if v8 ~= "/console" and v8 ~= "/newconsole" then
		return false
	end

	ToggleDeveloperConsole() -- inferred equivalent call
	return true
end

local function GetOutgoingChannelName()
	local alivePlayer = CharacterResolver.isAlivePlayer(LocalPlayer)
	local team = LocalPlayer:GetAttribute("Team")
	local v8 = not team or team == "Spectators"
	local competitiveServerGamemode = IsCompetitiveServerGamemode() -- inferred equivalent call

	if All == ChatModes.Modes.All then
		if alivePlayer or v8 or competitiveServerGamemode and not v8 then
			return "All"
		end

		return "AllDead"
	elseif alivePlayer or competitiveServerGamemode and not v8 then
		return "Team"
	else
		return "TeamDead"
	end
end

function Chat.Initialize(_, p)
	Profiler.mark("UI.Chat.Initialize")
	v = p
	v2 = GetUserPlatform()
	template = ReplicatedStorage.Assets.UI.Chat.Template
	template.Message.RichText = true

	for _, frame in ipairs(v.Chat.ScrollingFrame:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end

	v.Type.TextBox.ClearTextOnFocus = false
	v.Type.TextBox.Focused:Connect(function()
		if not v4 then
			v.Type.TextBox:ReleaseFocus()
			return
		end

		BuyMenu.closeFrame()
		LocalPlayer:SetAttribute("IsPlayerChatting", true)
		v.Type.TextBox.TextTransparency = 0
		SetChatActive(true)
		task.delay(0, function()
			debug.setmemorycategory("UI.Chat.ClearFocusedTextDeferred")
			Profiler.mark("UI.Chat.ClearFocusedTextDeferred")
			v.Type.TextBox.Text = ""
		end)

		if ChatModes.Labels[All] then
			v.Type.TextBox.PlaceholderText = ChatModes.Labels[All]
		end
	end)
	v.Type.TextBox.FocusLost:Connect(function(flag: boolean)
		local v8 = not (flag and string.len(v.Type.TextBox.Text) > 0) and "" or v.Type.TextBox.Text
		CloseChat()

		if not flag or #v8 == 0 or Chat.HandleChatCommand(v8) or #v8 > 100 then
			return
		end

		local child = TextChatService:FindFirstChild((GetOutgoingChannelName()))

		if child then
			child:SendAsync(v8)
		end
	end)
	SetChatActive(false)
	v.Visible = false

	if not CanPlayerUseChatService(LocalPlayer) then
		v:GetPropertyChangedSignal("Visible"):Connect(function()
			if v.Visible then
				v.Visible = false
			end
		end)
	end
end

function Chat.Start()
	debug.setmemorycategory("UI.Chat.Start")
	Profiler.mark("UI.Chat.Start.Begin")
	local v8 = {
		{ "All", false },
		{ "AllDead", false },
		{ "Team", true },
		{ "TeamDead", true }
	}
	local v9 = {}

	for _, v10 in v8 do
		v9[v10[1]] = TextChatService:WaitForChild(v10[1], 10)
	end

	local v10 = true

	local function updateLocalPlayerAliveStatus() -- 1 equivalent call inferred from this helper
		v10 = CharacterResolver.isAlivePlayer(LocalPlayer)
	end

	updateLocalPlayerAliveStatus() -- inferred equivalent call
	LocalPlayer:GetAttributeChangedSignal("Dead"):Connect(updateLocalPlayerAliveStatus)
	LocalPlayer:GetAttributeChangedSignal("Health"):Connect(updateLocalPlayerAliveStatus)

	local function getPlayerAliveStatus(userId: number) -- 1 equivalent call inferred from this helper
		local playerByUserId = Players:GetPlayerByUserId(userId)
		return playerByUserId ~= nil and CharacterResolver.isAlivePlayer(playerByUserId)
	end

	local v11 = {}

	local function processChannelMessage(data, p: string, flag: boolean)
		if data.Status ~= Enum.TextChatMessageStatus.Success then
			return
		end

		local messageId = data.MessageId

		if messageId and v11[messageId] then
			return
		end

		if messageId then
			v11[messageId] = true
			local count = 0

			for _ in v11 do
				count += 1
			end

			if count > 100 then
				v11 = { [messageId] = true }
			end
		end

		local textSource = data.TextSource

		if not textSource then
			return
		end

		local userId = textSource.UserId

		if not userId then
			return
		end

		local playerByUserId = Players:GetPlayerByUserId(userId)

		if not playerByUserId then
			return
		end

		local playerAliveStatus = getPlayerAliveStatus(userId) -- inferred equivalent call
		local team = playerByUserId:GetAttribute("Team")
		local team2 = LocalPlayer:GetAttribute("Team")
		local competitiveServerGamemode = IsCompetitiveServerGamemode() -- inferred equivalent call
		local v12 = v10 and not (playerAliveStatus or competitiveServerGamemode)

		if p == "All" and v12 or (p == "Team" or p == "TeamDead") and (team ~= team2 or p == "Team" and v12) then
			return
		end

		local success, result = pcall(function()
			return playerByUserId:GetRankInGroup(33751825)
		end)
		local v13 = {
			verified = playerByUserId.HasVerifiedBadge,
			userId = userId,
			displayName = playerByUserId.DisplayName,
			team = team or "Spectators",
			message = data.Text,
			alive = playerAliveStatus,
			role = success and result or 0
		}
		Chat.ProcessChatData(v13, flag)
	end

	for _, v12 in v8 do
		local v13 = v12[1]
		local v14 = v12[2]
		local v15 = v9[v13]

		if v15 then
			v15.OnIncomingMessage = function(p)
				processChannelMessage(p, v13, v14)
				return nil
			end
		end
	end

	local function listenSystemMessage(p, callback) -- 10 equivalent calls inferred from this helper
		p.Listen(function(p2)
			if IsSystemChatMessagesEnabled() then -- inferred equivalent call
				callback(p2)
			end
		end)
	end

	local function fn(p)
		Chat.ProcessTeamJoin(p.name, p.team)
	end

	Remotes.Chat.ChatTeamJoin.Listen(function(p)
		if IsSystemChatMessagesEnabled() then -- inferred equivalent call
			fn(p)
		end
	end)

	local function fn2(p)
		Chat.ProcessPlayerLeave(p.name)
	end

	listenSystemMessage(Remotes.Chat.ChatPlayerLeave, fn2) -- inferred equivalent call

	local function fn3(p)
		Chat.ProcessPlayerBanned(p.name)
	end

	listenSystemMessage(Remotes.Chat.ChatPlayerBanned, fn3) -- inferred equivalent call

	local function fn4(p)
		Chat.ProcessSystemMessage(p.message)
	end

	listenSystemMessage(Remotes.Chat.ChatSystemMessage, fn4) -- inferred equivalent call
	listenSystemMessage(Remotes.Chat.ChatTeamDamage, Chat.ProcessTeamDamage) -- inferred equivalent call
	listenSystemMessage(Remotes.Chat.ChatPlayerKilled, Chat.ProcessKillMessage) -- inferred equivalent call
	listenSystemMessage(Remotes.Chat.ChatMoneyReward, Chat.ProcessMoneyReward) -- inferred equivalent call
	listenSystemMessage(Remotes.Chat.ChatCaseOpened, Chat.ProcessCaseOpened) -- inferred equivalent call
	listenSystemMessage(Remotes.Chat.ChatTradeUp, Chat.ProcessTradeUp) -- inferred equivalent call
	listenSystemMessage(Remotes.Chat.ChatGrenadeThrow, Chat.ProcessGrenadeThrow) -- inferred equivalent call
	listenSystemMessage(Remotes.Chat.ChatDefuseStart, Chat.ProcessDefuseStart) -- inferred equivalent call
	UserInputService.InputBegan:Connect(function(input, gameProcessed: boolean)
		if
			not gameProcessed
			and input.UserInputType == Enum.UserInputType.Keyboard
			and input.KeyCode == Enum.KeyCode.Slash
		then
			Chat.OpenChat(ChatModes.Modes.All)
		end
	end)
end

return Chat