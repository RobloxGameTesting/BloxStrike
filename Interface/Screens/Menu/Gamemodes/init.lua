local Gamemodes = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
require(ReplicatedStorage.Database.Custom.Types)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local ServerBrowser = require(ReplicatedStorage.Database.Components.ServerBrowser)
local GetBrowserMaps = require(ReplicatedStorage.Database.Components.Common.GetBrowserMaps)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local SetTabSelected = require(ReplicatedStorage.Components.Common.InterfaceAnimations.SetTabSelected)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local GamepadNavigation = require(ReplicatedStorage.Interface.GamepadNavigation)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local ServerBrowser2 = require(script.ServerBrowser)
local v = { "Gamemodes", "ServerBrowser" }
local frozen = table.freeze({
	Defusal = { BrowserGamemode = "casual", TeleportMode = "Defusal" },
	Competitive = { BrowserGamemode = "competitive", TeleportMode = "UnrankedComp" },
	Deathmatch = { BrowserGamemode = "deathmatch", TeleportMode = "Deathmatch" },
	Trading = { BrowserGamemode = "trading", TeleportMode = "Trading" }
})
local frozen2 = table.freeze({
	Casual = "Defusal",
	Competitive = "Competitive",
	Deathmatch = "Deathmatch"
})
local frozen3 = table.freeze({
	["Bomb Defusal"] = "Defusal",
	["Hostage Rescue"] = "Defusal",
	Deathmatch = "Deathmatch"
})
local frozen4 = table.freeze({
	[Constants.GAMEMODE_PLACE_IDS.Casual] = "Defusal",
	[Constants.GAMEMODE_PLACE_IDS.Competitive] = "Competitive",
	[Constants.GAMEMODE_PLACE_IDS.Deathmatch] = "Deathmatch",
	[Constants.GAMEMODE_PLACE_IDS.Trading] = "Trading"
})
local v2 = "Gamemodes"
local v3 = 0
local total = 0
local v4 = false
local count = 0
local v5 = {}
local buttonsByName = {}
local images = {}
local v6 = {
	gameModes = {},
	regions = { "North America", "Europe", "Asia", "South America", "Oceania" },
	maps = GetBrowserMaps()
}
local v7 = {}
v7.competitive = 0
v7.deathmatch = 0
v7.trading = 0
v7.casual = 0
local connection = nil
local v8 = nil
local v9 = nil

local function CommaNumber(p: number) -- 1 equivalent call inferred from this helper
	return (tostring((math.max(math.floor(p), 0))):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function GetCurrentCardName()
	local serverGamemode = workspace:GetAttribute("ServerGamemode")

	if typeof(serverGamemode) == "string" and frozen2[serverGamemode] then
		return frozen2[serverGamemode]
	end

	local gamemode = workspace:GetAttribute("Gamemode")

	if typeof(gamemode) == "string" and frozen3[gamemode] then
		return frozen3[gamemode]
	end

	return frozen4[game.PlaceId]
end

local function RefreshCurrentCard() -- 2 equivalent calls inferred from this helper
	local currentCardName = GetCurrentCardName()

	for k, v10 in v5 do
		if v10.Badge then
			v10.Badge.Visible = k == currentCardName
		end
	end
end

local function RefreshPlayerCounts()
	for k, v10 in v5 do
		local v11 = frozen[k]

		if not (v11 and v7[v11.BrowserGamemode]) then
			continue
		end

		local v12 = v7[v11.BrowserGamemode] or 0
		v10.PlayerCount.Text = `{CommaNumber(v12)} Online` -- inferred equivalent call
	end
end

local function TrackOnlineTag(image) -- 1 equivalent call inferred from this helper
	if image:IsA("ImageLabel") and not table.find(images, image) then
		table.insert(images, image)
	end
end

local function UntrackOnlineTag(p)
	local index = table.find(images, p)

	if index then
		table.remove(images, index)
	end
end

local function StepOnlineBlink(p: number)
	total += p
	local imageTransparency = math.sin(total * 3.141592653589793) * 0.25 + 0.25

	for _, v10 in images do
		v10.ImageTransparency = imageTransparency
	end
end

local function SetOnlineBlinkEnabled(flag: boolean)
	if flag == (connection ~= nil) then
		return
	end

	if flag then
		connection = RunServiceController.BindToHeartbeat("UI.Gamemodes.OnlineBlink", StepOnlineBlink)
	elseif connection then
		connection:Disconnect()
		connection = nil
	end
end

local function SyncCategorySelection(p: string, p2: string, flag: boolean)
	local v10 = v6[p]

	if not v10 then
		return
	end

	local index = table.find(v10, p2)

	if index and not flag then
		table.remove(v10, index)
	elseif not index and flag then
		table.insert(v10, p2)
	end
end

local function BuildMapCheckboxes(maps)
	local v10 = nil

	for _, frame in maps:GetChildren() do
		if not frame:IsA("Frame") then
			continue
		end

		frame.Parent = nil
		v10 = v10 or frame
	end

	if not v10 then
		warn("[Gamemodes] No map checkbox template in the filters, map filtering is disabled")
		return
	end

	for k, map in v6.maps do
		local clone = v10:Clone()
		clone.Name = map
		clone.LayoutOrder = k
		clone.Info.Text = map
		clone.Button.ImageLabel.Visible = true
		clone.Parent = maps
	end

	v10:Destroy()
end

local function FitCategoryRows(list)
	local function countRows(instance)
		local count2 = 0

		for _, frame in instance:GetChildren() do
			if frame:IsA("Frame") then
				count2 += 1
			end
		end

		return count2
	end

	local regions = list:FindFirstChild("regions")
	local v10 = countRows(regions)

	if v10 == 0 then
		return
	end

	local v11 = regions.Size.Y.Scale / v10
	local total2 = 0
	local total3 = 0

	for _, guiObject in list:GetChildren() do
		if not guiObject:IsA("GuiObject") then
			continue
		end

		total2 += guiObject.Size.Y.Scale

		if guiObject:IsA("Frame") then
			guiObject.Size = UDim2.new(guiObject.Size.X, UDim.new(countRows(guiObject) * v11, 0))
		end

		total3 += guiObject.Size.Y.Scale
	end

	local v12 = total3 / total2
	local parent = list.Parent
	parent.Size = UDim2.new(parent.Size.X, UDim.new(parent.Size.Y.Scale * v12, parent.Size.Y.Offset))

	for _, guiObject in list:GetChildren() do
		if guiObject:IsA("GuiObject") then
			guiObject.Size = UDim2.new(
				guiObject.Size.X,
				UDim.new(guiObject.Size.Y.Scale / v12, guiObject.Size.Y.Offset)
			)
		end
	end
end

local function FiltersChanged() -- 2 equivalent calls inferred from this helper
	ServerBrowser2.SetCategoryFilters(v6)
	count += 1
	local v10 = count
	task.delay(1, function()
		if v10 ~= count then
			return
		end

		Remotes.Modes.FetchServers.Send(v6)
	end)
end

local function VisibilityUpdated()
	local visible = v8.Visible == true

	if visible ~= (connection ~= nil) then
		if visible then
			connection = RunServiceController.BindToHeartbeat("UI.Gamemodes.OnlineBlink", StepOnlineBlink)
		elseif connection then
			connection:Disconnect()
			connection = nil
		end
	end

	if visible then
		RefreshCurrentCard() -- inferred equivalent call
		Remotes.Modes.FetchServers.Send(v6)
		Remotes.Modes.FetchPlayerCounts.Send()
		RefreshPlayerCounts()
	end

	ServerBrowser2.SetActive(visible and v2 == "ServerBrowser")
end

function Gamemodes.InitializeGamemodeTemplate(instance)
	local v10 = frozen[instance.Name]

	if not v10 then
		warn(`[Gamemodes] Unknown gamemode card "{instance.Name}"`)
		return
	end

	local activePlayerCount = instance:FindFirstChild("ActivePlayerCount")
	local youAreHere = instance:FindFirstChild("YouAreHere")
	local v11 = v5
	local name = instance.Name
	local v12 = { Card = instance, Badge = 0, PlayerCount = 0 }

	if not (youAreHere and youAreHere:IsA("GuiObject") and youAreHere) then
		youAreHere = nil
	end

	v12.Badge = youAreHere

	if not (activePlayerCount and activePlayerCount:IsA("TextLabel") and activePlayerCount) then
		activePlayerCount = nil
	end

	v12.PlayerCount = activePlayerCount
	v11[name] = v12
	ActivateButton(instance)
	instance.MouseButton1Click:Connect(function()
		if GetCurrentCardName() == instance.Name then
			return
		end

		v9 = v10
		v8.Gamemodes.Prompt.Visible = true
		v8.Gamemodes.Prompt.TextLabel.Text = `Are you sure you want to join {v10.BrowserGamemode}?`
	end)
end

function Gamemodes.OpenGamemodesFrame(p: string)
	v2 = p
	v8.ServerBrowser.Main.Frame.Top.Filters.Categories.Visible = false

	for _, child in v8:GetChildren() do
		if child:GetAttribute("ButtonFrame") then
			child.Visible = child.Name == p
		end
	end

	for k, v10 in buttonsByName do
		SetTabSelected(v10, k == p)
	end

	ServerBrowser2.SetActive(v8.Visible == true and p == "ServerBrowser")
end

function Gamemodes.Initialize(_, p)
	v8 = p

	for _, guiObject in v8.Gamemodes:GetChildren() do
		if not guiObject:IsA("GuiObject") then
			continue
		end

		for _, button in guiObject:GetChildren() do
			if button:IsA("ImageButton") and button:FindFirstChild("ActivePlayerCount") then
				Gamemodes.InitializeGamemodeTemplate(button)
			end
		end
	end

	for _, button in v8.Buttons:GetChildren() do
		if not button:IsA("ImageButton") then
			continue
		end

		buttonsByName[button.Name] = button
		ActivateButton(button)
		local v10 = button
		button.MouseButton1Click:Connect(function()
			Gamemodes.OpenGamemodesFrame(v10.Name)
		end)
	end

	MenuState.RegisterBumperOverride(v8, function(flag: boolean)
		local nextBumperTab = MenuState.GetNextBumperTab(v8.Buttons, v, v2, flag)

		if nextBumperTab and nextBumperTab ~= v2 then
			Gamemodes.OpenGamemodesFrame(nextBumperTab)
		end

		local guiObject = v8.Buttons:FindFirstChild(v2)

		if guiObject and guiObject:IsA("GuiObject") then
			GuiService.SelectedObject = guiObject
		end

		return true
	end, v8, v8.Buttons)
	ActivateButton(v8.Gamemodes.Prompt.Buttons.Buttons.Yes)
	ActivateButton(v8.Gamemodes.Prompt.Buttons.Buttons.No)
	v8.Gamemodes.Prompt.Buttons.Buttons.Yes.MouseButton1Click:Connect(function()
		ActivateButton(v8.Gamemodes.Prompt.Buttons.Buttons.Yes)

		if not v9 then
			return
		end

		local now = os.clock()

		if now - v3 < 0.75 then
			return
		end

		v3 = now
		Remotes.Modes.SelectGamemode.Send(v9.TeleportMode)
	end)
	v8.Gamemodes.Prompt.Buttons.Buttons.No.MouseButton1Click:Connect(function()
		v9 = nil
		v8.Gamemodes.Prompt.Visible = false
	end)
	ServerBrowser2.Initialize(v8.ServerBrowser)
	Gamemodes.OpenGamemodesFrame("Gamemodes")
	local search = v8.ServerBrowser.Main.Frame.Top:FindFirstChild("Search")

	if search and search:IsA("GuiButton") then
		local title = search:FindFirstChild("Title")
		ActivateButton(search)
		search.MouseButton1Click:Connect(function()
			if not v4 then
				v4 = true
				search.Active = false
				Remotes.Modes.FetchServers.Send(v6)

				for i = 10, 0, -1 do
					if title and title:IsA("TextLabel") then
						title.Text = `Search ({i})`
					end

					if i > 0 then
						task.wait(1)
					end
				end

				if title and title:IsA("TextLabel") then
					title.Text = "Search"
				end

				search.Active = true
				v4 = false
			end
		end)
	end

	local filters = v8.ServerBrowser.Main.Frame.Top.Filters
	local categories = filters.Categories
	filters.MouseButton1Click:Connect(function()
		categories.Visible = not categories.Visible
	end)
	categories.Active = true
	categories.SelectionGroup = true
	categories:GetPropertyChangedSignal("Visible"):Connect(function()
		if categories.Visible then
			task.defer(function()
				if categories.Visible then
					GamepadNavigation.Focus(categories)
				end
			end)
			return
		end

		local selectedObject = GuiService.SelectedObject

		if selectedObject == nil or selectedObject:IsDescendantOf(categories) then
			GamepadNavigation.Focus(filters)
		end
	end)
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local selectedObject = GuiService.SelectedObject

		if
			categories.Visible
			and selectedObject
			and selectedObject ~= filters
			and not selectedObject:IsDescendantOf(categories)
		then
			categories.Visible = false
		end
	end)
	CloseButtonRegistry.Add(categories, nil, function()
		categories.Visible = false
	end)
	BuildMapCheckboxes(categories.Maps.List.maps)
	FitCategoryRows(categories.Maps.List)

	for _, frame in categories.Maps.List:GetChildren() do
		if not frame:IsA("Frame") then
			continue
		end

		for _, frame2 in frame:GetChildren() do
			if not frame2:IsA("Frame") then
				continue
			end

			ActivateButton(frame2.Button)
			local name = frame.Name
			local name2 = frame2.Name
			local visible = frame2.Button.ImageLabel.Visible
			local names = v6[name]

			if names then
				local index = table.find(names, name2)

				if index and not visible then
					table.remove(names, index)
				elseif not index and visible then
					table.insert(names, name2)
				end
			end

			local v10 = frame2
			local v11 = frame
			frame2.Button.MouseButton1Click:Connect(function()
				v10.Button.ImageLabel.Visible = not v10.Button.ImageLabel.Visible
				local name3 = v11.Name
				local name4 = v10.Name
				local visible2 = v10.Button.ImageLabel.Visible
				local names2 = v6[name3]

				if names2 then
					local index = table.find(names2, name4)

					if index and not visible2 then
						table.remove(names2, index)
					elseif not index and visible2 then
						table.insert(names2, name4)
					end
				end

				FiltersChanged() -- inferred equivalent call
			end)
		end

		local v10 = frame
		frame.Parent[`{frame.Name}Header`].MouseButton1Click:Connect(function()
			v10.Parent[`{v10.Name}Header`].Icon.Rotation = v10.Visible and 180 or 0
			v10.Visible = not v10.Visible
		end)
	end

	ServerBrowser2.SetCategoryFilters(v6)
	Remotes.Modes.SendPlayerCounts.Listen(function(p2)
		if p2 then
			v7 = p2
			RefreshPlayerCounts()
		end
	end)
end

function Gamemodes.Start()
	for _, v10 in CollectionService:GetTagged("Gamemodes_OnlineTag") do
		TrackOnlineTag(v10) -- inferred equivalent call
	end

	CollectionService:GetInstanceAddedSignal("Gamemodes_OnlineTag"):Connect(TrackOnlineTag)
	CollectionService:GetInstanceRemovedSignal("Gamemodes_OnlineTag"):Connect(UntrackOnlineTag)
	workspace:GetAttributeChangedSignal("ServerGamemode"):Connect(RefreshCurrentCard)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(RefreshCurrentCard)
	ServerBrowser.OnServerBrowserUpdated:Connect(RefreshPlayerCounts)
	local serverGamemode = workspace:GetAttribute("ServerGamemode")
	table.insert(v6.gameModes, serverGamemode and serverGamemode:lower() or "casual")
	FiltersChanged() -- inferred equivalent call
	v8:GetPropertyChangedSignal("Visible"):Connect(VisibilityUpdated)
	RefreshCurrentCard() -- inferred equivalent call
	RefreshPlayerCounts()
	VisibilityUpdated()
	ServerBrowser2.Start()
end

return Gamemodes