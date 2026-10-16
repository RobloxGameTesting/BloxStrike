local ServerBrowser = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local LocalPlayer = Players.LocalPlayer
local ServerBrowser2 = require(ReplicatedStorage.Database.Components.ServerBrowser)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Maps = ReplicatedStorage.Database.Custom.GameStats.Maps
local ServerTemplate = ReplicatedStorage.Assets.UI.ServerBrowser.ServerTemplate
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local color = Color3.fromRGB(120, 255, 127)
local frozen = table.freeze({
	Transparency = 0.25,
	BlurRadius = UDim.new(0, 14),
	Spread = UDim2.fromOffset(6, 6)
})
local frozen2 = table.freeze({
	Transparency = 1,
	BlurRadius = UDim.new(0, 0),
	Spread = UDim2.fromOffset(0, 0)
})
local frozen3 = table.freeze({ "Map", "Players", "Score", "Region", "ServerUptime", "ServerId" })
local frozen4 = table.freeze({
	casual = "CASUAL",
	competitive = "COMPETITIVE",
	deathmatch = "DEATHMATCH",
	trading = "TRADING"
})
local v = nil
local v2 = ""
local visible = false
local v3 = nil
local v4 = 0
local count = 0
local total = 0
local v5 = false
local v6 = {}
local v7 = {}
local usernamesById = {}
local userThumbnailAsyncsByUserId = {}
local iconsByChildName = {}
local connection = nil
local container = nil
local categories = nil
local title = nil
local v8 = nil

local function CommaNumber(p: number) -- 2 equivalent calls inferred from this helper
	return (tostring((math.max(math.floor(p), 0))):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function GetGamemodeLabel(p) -- 3 equivalent calls inferred from this helper
	return frozen4[p.GameMode] or string.upper((tostring(p.GameMode)))
end

local function GetMapName(p) -- 3 equivalent calls inferred from this helper
	local gameModeData = p.GameModeData
	return gameModeData and gameModeData.MapName or ""
end

local function GetMapIcon(childName: string)
	if childName == "" then
		return nil
	end

	local v9 = iconsByChildName[childName]

	if v9 then
		return v9
	end

	local moduleScript = Maps:FindFirstChild(childName)
	local icon = nil

	if moduleScript and moduleScript:IsA("ModuleScript") then
		local success, result = pcall(require, moduleScript)

		if success and typeof(result) == "table" then
			icon = result.Icon
		end
	end

	if icon then
		iconsByChildName[childName] = icon
	end

	return icon
end

local function FormatScore(p) -- 2 equivalent calls inferred from this helper
	local gameModeData = p.GameModeData
	local scores = gameModeData and gameModeData.Scores

	if scores then
		return `<font color="rgb(219,199,126)">{scores.T or 0}</font> - <font color="rgb(165,183,212)">{scores.CT or 0}</font>`
	end

	return "--"
end

local function FormatUptime(startedAt: string?)
	if not startedAt or startedAt == "" then
		return "--"
	end

	local success, result = pcall(DateTime.fromIsoDate, startedAt)

	if success and result then
		local v9 = math.max(DateTime.now().UnixTimestamp - result.UnixTimestamp, 0)
		return string.format("%02d:%02d:%02d", v9 // 3600, v9 % 3600 // 60, v9 % 60)
	else
		return "--"
	end
end

local function GetFriendInServer(p)
	for _, player in p.Players do
		local v9 = usernamesById[player.UserId]

		if v9 then
			return v9
		end
	end

	return nil
end

local function IsCategorySelected(p: string, value: string)
	local v9 = v3 and v3[p]

	if not v9 then
		return true
	end

	local v10 = string.lower(value)

	for _, v11 in v9 do
		if string.lower(v11) == v10 then
			return true
		end
	end

	return false
end

local function MatchesFilters(activeGameServer)
	if not IsCategorySelected("gameModes", tostring(activeGameServer.GameMode)) then
		return false
	end

	local mapName = GetMapName(activeGameServer) -- inferred equivalent call

	if mapName ~= "" and not IsCategorySelected("maps", mapName) then
		return false
	end

	if visible then
		local flag = true
		local v9

		for _, player in activeGameServer.Players do
			v9 = usernamesById[player.UserId]

			if not v9 then
				continue
			end

			flag = false
			break
		end

		if flag then
			v9 = nil
		end

		if not v9 then
			return false
		end
	end

	if v2 == "" then
		return true
	end

	local serverName = ServerBrowser2.GetServerNameFromMatchId(activeGameServer.MatchId)
	local gameModeData = activeGameServer.GameModeData
	local v9 = string.lower(table.concat({
		serverName,
		gameModeData and gameModeData.MapName or "",
		activeGameServer.Region or "",
		GetGamemodeLabel(activeGameServer) -- inferred equivalent call
	}, " "))
	return string.find(v9, v2, 1, true) ~= nil
end

local function RequestTeleport(p: string) -- 1 equivalent call inferred from this helper
	local now = os.clock()

	if now - v4 < 1.1 then
		return
	end

	v4 = now
	Remotes.ServerBrowser.Teleport.Send(p)
end

local function SetDetailValue(p: string, text: string) -- 7 equivalent calls inferred from this helper
	local v9 = v7[p]

	if v9 then
		v9.Text = text
	end
end

local function RefreshFriendTag(server)
	local friendTag = categories.FriendTag
	local v9 = nil

	for _, player in server.Players do
		if not usernamesById[player.UserId] then
			continue
		end

		v9 = player
		break
	end

	count += 1
	local v10 = count

	if not v9 then
		friendTag.Visible = false
		return
	end

	friendTag.Visible = true
	friendTag.Username.Text = `{v9.Username} in Server`
	local avatar = friendTag.Player.Avatar
	local image = userThumbnailAsyncsByUserId[v9.UserId]

	if image then
		avatar.Image = image
		return
	end

	avatar.Image = ""
	task.spawn(function()
		local success, userThumbnailAsync = pcall(
			Players.GetUserThumbnailAsync,
			Players,
			v9.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size150x150
		)

		if not (success and userThumbnailAsync) then
			return
		end

		userThumbnailAsyncsByUserId[v9.UserId] = userThumbnailAsync

		if v10 == count then
			avatar.Image = userThumbnailAsync
		end
	end)
end

local function GetSelectionShadow(clone) -- 1 equivalent call inferred from this helper
	local selectionShadow = clone:FindFirstChild("SelectionShadow")

	if selectionShadow and selectionShadow:IsA("UIShadow") then
		return selectionShadow
	end

	local uiShadow = Instance.new("UIShadow")
	uiShadow.Name = "SelectionShadow"
	uiShadow.Color = color
	uiShadow.Transparency = frozen2.Transparency
	uiShadow.BlurRadius = frozen2.BlurRadius
	uiShadow.Spread = frozen2.Spread
	uiShadow.Parent = clone
	return uiShadow
end

local function TweenRowSelection(parent, flag: boolean) -- 1 equivalent call inferred from this helper
	local v9 = parent:FindFirstChild("SelectionShadow")

	if not (v9 and v9:IsA("UIShadow")) then
		v9 = Instance.new("UIShadow")
		v9.Name = "SelectionShadow"
		v9.Color = color
		v9.Transparency = frozen2.Transparency
		v9.BlurRadius = frozen2.BlurRadius
		v9.Spread = frozen2.Spread
		v9.Parent = parent
	end

	local v10

	if flag then
		v10 = frozen
	else
		v10 = frozen2
	end

	TweenService:Create(v9, tweenInfo, v10):Play()
end

local function ClearSelection() -- 2 equivalent calls inferred from this helper
	v = nil
	categories.Visible = false

	for _, parent in v6 do
		local v9 = parent:FindFirstChild("SelectionShadow")

		if not (v9 and v9:IsA("UIShadow")) then
			v9 = Instance.new("UIShadow")
			v9.Name = "SelectionShadow"
			v9.Color = color
			v9.Transparency = frozen2.Transparency
			v9.BlurRadius = frozen2.BlurRadius
			v9.Spread = frozen2.Spread
			v9.Parent = parent
		end

		TweenService:Create(v9, tweenInfo, frozen2):Play()
	end
end

local function RefreshDetails()
	if not v then
		categories.Visible = false
		return
	end

	local server = ServerBrowser2.GetServerByMatchId(v)

	if server then
		local mapName = GetMapName(server) -- inferred equivalent call
		local gamemodeLabel = GetGamemodeLabel(server) -- inferred equivalent call
		categories.Visible = true
		categories.Title.Title.Text = `{string.upper(mapName)} | {gamemodeLabel}`
		categories.Map.Map.Image = GetMapIcon(mapName) or "rbxassetid://111859813726258"
		categories.Scroll.Score.Label.Text = server.GameMode == "trading" and "RAP" or "SCORE"
		categories.Scroll.Map.Visible = server.GameMode ~= "trading"
		SetDetailValue("Map", string.upper(mapName)) -- inferred equivalent call
		SetDetailValue("Players", `{#server.Players}/{server.MaxPlayers}`) -- inferred equivalent call
		local v9 = server.GameMode == "trading"
			and server.GameModeData.Score
			and CommaNumber(math.floor(server.GameModeData.Score)) -- inferred equivalent call

		if not v9 then
			v9 = FormatScore(server) -- inferred equivalent call
		end

		SetDetailValue("Score", v9) -- inferred equivalent call
		SetDetailValue("Region", server.Region or "--") -- inferred equivalent call
		SetDetailValue("ServerUptime", FormatUptime(server.StartedAt)) -- inferred equivalent call
		SetDetailValue("ServerId", server.MatchId) -- inferred equivalent call
		RefreshFriendTag(server)
	else
		ClearSelection() -- inferred equivalent call
	end
end

local function SelectServer(p: string) -- 2 equivalent calls inferred from this helper
	v = p
	RefreshDetails()

	for k, v9 in v6 do
		TweenRowSelection(v9, k == p) -- inferred equivalent call
	end
end

local function ApplyServerToRow(data, data2)
	local mapName = GetMapName(data2) -- inferred equivalent call
	data.ServerId.Text = ServerBrowser2.GetServerNameFromMatchId(data2.MatchId)
	data.MapName.Text = string.upper(mapName)
	data.PlayerCount.Text = `{#data2.Players}/{data2.MaxPlayers}`
	local score = data.Score
	score.Text = FormatScore(data2) -- inferred equivalent call
	data.Region.Text = data2.Region or "--"
	data.Gamemode.Text = GetGamemodeLabel(data2) -- inferred equivalent call
	data.MapBackground.ImageButton.Image = GetMapIcon(mapName) or ""
end

local function CreateRow(matchId: string)
	local clone = ServerTemplate:Clone()
	clone.Name = matchId
	GetSelectionShadow(clone) -- inferred equivalent call
	local join = clone:FindFirstChild("Join")

	for _, button in { join, clone:FindFirstChild("Select"), clone.MapBackground:FindFirstChild("ImageButton") } do
		if not (button and button:IsA("GuiButton")) then
			continue
		end

		if button == join then
			ActivateButton(button)
		end

		button.MouseButton1Click:Connect(function()
			SelectServer(matchId) -- inferred equivalent call
		end)
	end

	clone.Parent = container
	return clone
end

local function RefreshList()
	local activeGameServers = ServerBrowser2.GetActiveGameServers()
	local activeGameServers2 = {}

	for _, activeGameServer in activeGameServers do
		if MatchesFilters(activeGameServer) then
			table.insert(activeGameServers2, activeGameServer)
		end
	end

	table.sort(activeGameServers2, function(a, b)
		if #a.Players == #b.Players then
			return a.MatchId < b.MatchId
		end

		return #a.Players > #b.Players
	end)

	local function formatRap(items)
		local count2 = 0
		local total2 = 0

		for _, item in items do
			count2 += 1
			total2 += item
		end

		return total2 / count2
	end

	local v9 = {}

	for k, v10 in activeGameServers2 do
		v9[v10.MatchId] = true
		local v11 = v6[v10.MatchId]

		if not v11 then
			if v10.GameMode == "trading" then
				local gameModeData = v10.GameModeData
				local count2 = 0
				local total2 = 0

				for _, inventoryValue in v10.GameModeData.InventoryValues do
					count2 += 1
					total2 += inventoryValue
				end

				gameModeData.Score = total2 / count2
			end

			v11 = CreateRow(v10.MatchId)
			v6[v10.MatchId] = v11
		end

		v11.LayoutOrder = k
		ApplyServerToRow(v11, v10)

		if k == 1 then
			SelectServer(v10.MatchId) -- inferred equivalent call
		end
	end

	for k, v10 in v6 do
		if v9[k] then
			continue
		end

		v10:Destroy()
		v6[k] = nil
	end

	title.Text = `{CommaNumber(#activeGameServers2)} Servers` -- inferred equivalent call

	if not v or v9[v] then
		RefreshDetails()
		return
	end

	ClearSelection() -- inferred equivalent call
end

local function StepUptime(p: number)
	total += p

	if total < 1 then
		return
	end

	total = 0

	if not v then
		return
	end

	local server = ServerBrowser2.GetServerByMatchId(v)

	if server then
		SetDetailValue("ServerUptime", FormatUptime(server.StartedAt)) -- inferred equivalent call
	end
end

local function LoadFriends()
	local success, friendsAsync = pcall(Players.GetFriendsAsync, Players, LocalPlayer.UserId)

	if not (success and friendsAsync) then
		return
	end

	repeat
		for _, v9 in friendsAsync:GetCurrentPage() do
			usernamesById[v9.Id] = v9.Username
		end
	until friendsAsync.IsFinished or not pcall(function()
		friendsAsync:AdvanceToNextPageAsync()
	end)

	if v5 then
		RefreshList()
	end
end

local function ToggleFriendsOnly()
	visible = not visible

	if v8 then
		v8.Visible = visible
	end

	RefreshList()
end

function ServerBrowser.SetCategoryFilters(p)
	v3 = p

	if v5 then
		RefreshList()
	end
end

function ServerBrowser.SetActive(flag: boolean)
	if flag == v5 then
		return
	end

	v5 = flag

	if flag then
		total = 0
		connection = RunServiceController.BindToHeartbeat("UI.ServerBrowser.Uptime", StepUptime)
		RefreshList()
	elseif connection then
		connection:Disconnect()
		connection = nil
	end
end

function ServerBrowser.Initialize(p)
	local main = p.Main
	local frame = main.Frame
	container = frame.Container
	title = frame.Top.Title
	categories = main.Categories

	for _, guiObject in container:GetChildren() do
		if guiObject:IsA("GuiObject") then
			guiObject:Destroy()
		end
	end

	for _, childName in frozen3 do
		local child = categories.Scroll:FindFirstChild(childName)
		local value = child and child:FindFirstChild("Value")

		if value and value:IsA("TextLabel") then
			v7[childName] = value
		else
			warn(`[ServerBrowser] Missing "{childName}.Value" label in the details panel`)
		end
	end

	categories.Visible = false
	local searchBar = frame.Top.SearchBar
	local textBox = searchBar:FindFirstChildWhichIsA("TextBox", true)

	if textBox then
		searchBar.MouseButton1Click:Connect(function()
			textBox:CaptureFocus()
		end)
		textBox:GetPropertyChangedSignal("Text"):Connect(function()
			v2 = string.lower((string.gsub(textBox.Text, "^%s*(.-)%s*$", "%1")))
			RefreshList()
		end)
	else
		warn("[ServerBrowser] No search TextBox found, searching is disabled")
	end

	local friends = frame.Top.Friends
	local button = friends:FindFirstChild("Button")
	local check = button and button:FindFirstChild("Check")

	if check and check:IsA("GuiObject") then
		v8 = check
		check.Visible = visible
		friends.MouseButton1Click:Connect(ToggleFriendsOnly)

		if button and button:IsA("GuiButton") then
			button.MouseButton1Click:Connect(ToggleFriendsOnly)
		end
	else
		warn("[ServerBrowser] No \"Friends.Button.Check\" mark found, the friends only filter is disabled")
	end

	ActivateButton(categories.Join)
	categories.Join.MouseButton1Click:Connect(function()
		if v then
			main.Prompt.Visible = true
		end
	end)
	ActivateButton(main.Prompt.Buttons.Buttons.Yes)
	main.Prompt.Buttons.Buttons.Yes.MouseButton1Click:Connect(function()
		if v then
			RequestTeleport(v) -- inferred equivalent call
		end
	end)
	ActivateButton(main.Prompt.Buttons.Buttons.No)
	main.Prompt.Buttons.Buttons.No.MouseButton1Click:Connect(function()
		main.Prompt.Visible = false
	end)
end

function ServerBrowser.Start()
	task.spawn(LoadFriends)
	ServerBrowser2.OnServerBrowserUpdated:Connect(function()
		if v5 then
			RefreshList()
		end
	end)
end

return ServerBrowser