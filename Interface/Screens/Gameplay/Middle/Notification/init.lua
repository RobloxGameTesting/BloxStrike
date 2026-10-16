local Notification = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
require(script:WaitForChild("Types"))
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local LocalPlayer = Players.LocalPlayer
local udim = UDim2.fromScale(0.9, 0.2)
local udim2 = UDim2.fromScale(0.9, 0.12)
local color = Color3.fromRGB(230, 36, 36)
local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local notification = ReplicatedStorage.Assets.UI.Notification
local v = {
	Invulnerable = notification:FindFirstChild("Invulnerable"),
	Default = notification:FindFirstChild("Default"),
	Keybind = notification:FindFirstChild("Keybind")
}
local parent = nil

local function collectFadeTargets(folder)
	local v2 = {}

	local function collect(instance)
		local function add(property: string) -- 5 equivalent calls inferred from this helper
			local v3 = instance[property]

			if typeof(v3) == "number" and v3 < 1 then
				table.insert(v2, { Instance = instance, Property = property, Value = v3 })
			end
		end

		if instance:IsA("GuiObject") then
			add("BackgroundTransparency") -- inferred equivalent call
		end

		if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
			add("ImageTransparency") -- inferred equivalent call
		end

		if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
			add("TextTransparency") -- inferred equivalent call
			add("TextStrokeTransparency") -- inferred equivalent call
		end

		if instance:IsA("UIStroke") then
			add("Transparency") -- inferred equivalent call
		end
	end

	collect(folder)

	for _, descendant in folder:GetDescendants() do
		collect(descendant)
	end

	return v2
end

local function cleanupNotificationTemplate(instance)
	for _, v2 in collectFadeTargets(instance) do
		TweenService:Create(v2.Instance, tweenInfo, { [v2.Property] = 1 }):Play()
	end

	Debris:AddItem(instance, 0.35)
end

local function destroyNotification(childName: string) -- 4 equivalent calls inferred from this helper
	local child = parent and parent:FindFirstChild(childName)

	if child then
		child:Destroy()
	end
end

local function getSpawnCardHeader() -- 1 equivalent call inferred from this helper
	local deathmatchInvincibility = parent and parent:FindFirstChild("Deathmatch Invincibility")
	local deathmatchInvincibilityContainer = deathmatchInvincibility
		and deathmatchInvincibility:FindFirstChild("Container")
	local header = deathmatchInvincibilityContainer and deathmatchInvincibilityContainer:FindFirstChild("Header")

	if not (header and header:IsA("TextLabel") and header) then
		header = nil
	end

	return header
end

local function getHeaderText(flag: boolean)
	local invulnerable = v.Invulnerable
	local invulnerableContainer = invulnerable and invulnerable:FindFirstChild("Container")
	local header = invulnerableContainer and invulnerableContainer:FindFirstChild("Header")
	local text = header and header:IsA("TextLabel") and header.Text or "Invulnerable"

	if flag then
		return text
	end

	local v2 = string.match(text, "^[Ii][Nn](.+)$")

	if v2 then
		return string.upper((string.sub(v2, 1, 1))) .. string.sub(v2, 2)
	end

	return "Vulnerable"
end

local function setSpawnCardInvulnerable(invincible: boolean) -- 1 equivalent call inferred from this helper
	local spawnCardHeader = getSpawnCardHeader() -- inferred equivalent call

	if spawnCardHeader then
		spawnCardHeader.Text = getHeaderText(invincible)
		spawnCardHeader.TextColor3 = invincible and GetPreferenceColor() or color
	end
end

local function clearSpawnCard() -- 1 equivalent call inferred from this helper
	destroyNotification("Deathmatch Invincibility") -- inferred equivalent call

	if workspace:GetAttribute("GameState") == "Warmup" then
		Notification.createNotification("Default", "GameState", "Warmup", 1)
	end
end

local function onCleanup(instance, duration: number) -- 1 equivalent call inferred from this helper
	if duration <= tick() - instance:GetAttribute("Timestamp") then
		cleanupNotificationTemplate(instance)
	end
end

local function scheduleCleanup(instance, duration: number) -- 2 equivalent calls inferred from this helper
	task.delay(duration, function()
		if instance and instance.Parent then
			onCleanup(instance, duration) -- inferred equivalent call
		end
	end)
end

function Notification.createNotification(p, name: string, text: string, value: number?)
	if not parent then
		return
	end

	local clone = parent:FindFirstChild(name)

	if not LocalPlayer:GetAttribute("Team") then
		return
	end

	if not clone then
		local v2 = v[p]

		if not v2 then
			warn(`[Notification]: ReplicatedStorage.Assets.UI.Notification has no "{p}" template`)
			return nil
		end

		local size = p == "Invulnerable" and udim or udim2
		clone = v2:Clone()
		clone.Size = size
		clone.LayoutOrder = -(value or 1)
		clone.Name = name
		local v3 = collectFadeTargets(clone)

		for _, v4 in v3 do
			v4.Instance[v4.Property] = 1
		end

		clone.Parent = parent

		for _, v4 in v3 do
			TweenService:Create(v4.Instance, tweenInfo, { [v4.Property] = v4.Value }):Play()
		end
	end

	clone:SetAttribute("Timestamp", tick())
	clone.Right.BackgroundColor3 = GetPreferenceColor()
	clone.Left.BackgroundColor3 = GetPreferenceColor()

	if clone:FindFirstChild("TextLabel") then
		clone.TextLabel.Text = text
	end

	if p == "Invulnerable" then
		local v2 = InputController.GetActionKeybind("Buy Menu") or "B"
		clone.Container.Context.Text = `[{v2}] Open the Buy Menu`
		clone.Container.Header.TextColor3 = GetPreferenceColor()
	end

	return clone
end

function Notification.removeNotification(childName: string)
	destroyNotification(childName) -- inferred equivalent call
end

function Notification.Initialize(_, p)
	parent = p

	local function updateDeathmatchSpawnCard()
		if workspace:GetAttribute("Gamemode") ~= "Deathmatch" then
			return
		end

		local invincible = LocalPlayer:GetAttribute("Invincible") == true

		if invincible or LocalPlayer:GetAttribute("BuyMenu") then
			local gameState = parent:FindFirstChild("GameState")
			Notification.createNotification("Invulnerable", "Deathmatch Invincibility", "", 0)
			setSpawnCardInvulnerable(invincible) -- inferred equivalent call

			if gameState then
				gameState:Destroy()
			end
		else
			clearSpawnCard() -- inferred equivalent call
		end
	end

	LocalPlayer:GetAttributeChangedSignal("BuyMenu"):Connect(function()
		local gamemode = workspace:GetAttribute("Gamemode")

		if not LocalPlayer:GetAttribute("BuyMenu") and gamemode == "Deathmatch" then
			if not LocalPlayer:GetAttribute("Invincible") then
				local deathmatchInvincibility = parent and parent:FindFirstChild("Deathmatch Invincibility")

				if deathmatchInvincibility then
					deathmatchInvincibility:Destroy()
				end

				if workspace:GetAttribute("GameState") == "Warmup" then
					Notification.createNotification("Default", "GameState", "Warmup", 1)
				end
			end

			local notification2 = Notification.createNotification(
				"Default",
				"Your buy period has expired",
				"Your buy period has expired",
				2
			)
			task.delay(2, function()
				if notification2 and notification2.Parent then
					cleanupNotificationTemplate(notification2)
				end
			end)
		end
	end)
	LocalPlayer:GetAttributeChangedSignal("Invincible"):Connect(updateDeathmatchSpawnCard)
	LocalPlayer.CharacterAdded:Connect(function()
		local gameState = workspace:GetAttribute("GameState")

		if workspace:GetAttribute("Gamemode") == "Deathmatch" then
			updateDeathmatchSpawnCard()
			return
		end

		destroyNotification("Deathmatch Invincibility") -- inferred equivalent call

		if gameState == "Warmup" then
			Notification.createNotification("Default", "GameState", "Warmup", 1)
			return
		end

		destroyNotification("GameState") -- inferred equivalent call
	end)
	LocalPlayer.CharacterRemoving:Connect(function()
		local deathmatchInvincibility = parent and parent:FindFirstChild("Deathmatch Invincibility")

		if deathmatchInvincibility then
			deathmatchInvincibility:Destroy()
		end
	end)
	GameState.ListenToState(function(p2)
		local gameState = p2 == "Warmup" and parent and parent:FindFirstChild("GameState")

		if gameState then
			gameState:Destroy()
		end
	end)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(function()
		local deathmatchInvincibility = workspace:GetAttribute("Gamemode") ~= "Deathmatch"
			and parent
			and parent:FindFirstChild("Deathmatch Invincibility")

		if deathmatchInvincibility then
			deathmatchInvincibility:Destroy()
		end
	end)

	local function refreshOpenNotifications()
		local backgroundColor = GetPreferenceColor()

		for _, frame in ipairs(parent:GetChildren()) do
			if not frame:IsA("Frame") then
				continue
			end

			frame.Right.BackgroundColor3 = backgroundColor
			frame.Left.BackgroundColor3 = backgroundColor
		end
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", refreshOpenNotifications)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshOpenNotifications)
end

function Notification.Start()
	Remotes.UI.ShowNotification.Listen(function(data)
		scheduleCleanup(Notification.createNotification("Default", data.header, data.message, 2), data.timeLength) -- inferred equivalent call
	end)
	Router.observerRouter("CreateNotification", function(p: string, p2: string, duration: number)
		scheduleCleanup(Notification.createNotification("Default", p, p2, 2), duration) -- inferred equivalent call
	end)
end

return Notification