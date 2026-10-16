local ProfileInspect = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetRankTitle = require(ReplicatedStorage.Components.Common.GetRankTitle)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
require(ReplicatedStorage.Database.Custom.Types)
local LevelsIcon = require(ReplicatedStorage.Database.Custom.GameStats.LevelsIcon)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local Settings = require(ReplicatedStorage.Interface.Screens.Menu.Settings)
local Report = require(script.Parent.Parent.Report)
local LocalPlayer = Players.LocalPlayer
local v = { ["Show Player Crosshairs"] = true, ["Show my crosshair when spectating bots"] = true }
local avatar = nil
local username = nil
local v2 = {}
local textLabel = nil
local rank = nil
local current = nil
local v3 = nil
local v4 = nil
local v5 = nil

local function getBadgeIconFromItem(data)
	if typeof(data) ~= "table" or data.Name ~= "Badge" then
		return ""
	end

	local skinInformation = Skins.GetSkinInformation(data.Name, data.Skin)

	if skinInformation then
		return Skins.GetWearImageForFloat(skinInformation, data.Float or 0.9999) or skinInformation.imageAssetId or ""
	end

	return ""
end

local function collectPinLabels(pins)
	local images = {}

	for _, image in pins:GetChildren() do
		if image:IsA("ImageLabel") and image.Name == "Pin" then
			table.insert(images, image)
		end
	end

	table.sort(images, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return images
end

local function getEquippedBadgeId(p, p2)
	if typeof(p2) ~= "table" or not p then
		return nil
	end

	local v6 = p2[p]

	if typeof(v6) ~= "table" or typeof(v6.Equipped) ~= "table" then
		return nil
	end

	local equippedBadge = v6.Equipped["Equipped Badge"]

	if typeof(equippedBadge) == "string" and equippedBadge ~= "" then
		return equippedBadge
	end

	return nil
end

local function populatePins(instance)
	local team = instance:GetAttribute("Team")
	local v6, v7 = DataController.Get(instance, "Loadout", "Inventory")
	local equippedBadge

	if typeof(v6) == "table" and team then
		local v8 = v6[team]

		if typeof(v8) == "table" and typeof(v8.Equipped) == "table" then
			equippedBadge = v8.Equipped["Equipped Badge"]

			if typeof(equippedBadge) ~= "string" or equippedBadge == "" then
				equippedBadge = nil
			end
		end
	end

	local skin = nil

	if equippedBadge and typeof(v7) == "table" then
		for _, v8 in ipairs(v7) do
			if not (typeof(v8) == "table" and v8._id == equippedBadge and v8.Name == "Badge" and typeof(v8.Skin) == "string") then
				continue
			end

			skin = v8.Skin
			break
		end
	end

	local v8 = nil
	local v9 = {}
	local v10 = {}

	if typeof(v7) == "table" then
		for _, v11 in ipairs(v7) do
			if not (typeof(v11) == "table" and v11.Name == "Badge" and typeof(v11.Skin) == "string" and v11.Skin ~= "") then
				continue
			end

			if v10[v11.Skin] then
				continue
			end

			local v12

			if typeof(v11) == "table" and v11.Name == "Badge" then
				local skinInformation = Skins.GetSkinInformation(v11.Name, v11.Skin)
				v12 = not skinInformation and ""
					or Skins.GetWearImageForFloat(skinInformation, v11.Float or 0.9999)
					or skinInformation.imageAssetId
					or ""
			else
				v12 = ""
			end

			if v12 == "" then
				continue
			end

			v10[v11.Skin] = true

			if skin and v11.Skin == skin then
				v8 = v12
			else
				table.insert(v9, v12)
			end
		end
	end

	for i, v11 in ipairs(v2) do
		local image

		if i == 1 then
			image = v8
		else
			image = v9[i - 1]
		end

		if image then
			v11.Image = image
			v11.Visible = true
		else
			v11.Visible = false
		end
	end
end

local function populateLevel(p)
	if not (textLabel and rank and current) then
		return
	end

	local level = DataController.Get(p, "Level")
	local level2, experience, nextExperienceRequirement

	if typeof(level) == "table" then
		level2 = level.Level or 1
		experience = level.Experience or 0
		nextExperienceRequirement = level.NextExperienceRequirement or 1000
	else
		level2 = 1
		nextExperienceRequirement = 1000
		experience = 0
	end

	textLabel.Text = `[{GetRankTitle(level2)} Rank {level2}]`
	rank.Image = LevelsIcon[tostring(level2)] or ""
	local v6 = math.clamp(experience / math.max(nextExperienceRequirement, 1), 0, 1)
	local y = current.Size.Y
	current.Size = UDim2.new(v6, 0, y.Scale, y.Offset)
end

local function updateActionButtons(p) -- 1 equivalent call inferred from this helper
	local isBot = Participants.IsBot(p)

	if v3 then
		v3.Active = p ~= nil and p ~= LocalPlayer and not isBot
	end

	if v4 then
		v4.Visible = not isBot
		v4.Active = p ~= nil and not isBot
	end
end

local function copyPlayerCrosshair(p)
	if p == LocalPlayer or Participants.IsBot(p) then
		return
	end

	local v6 = DataController.Get(p, "Settings.Game.Crosshair")

	if typeof(v6) ~= "table" then
		return
	end

	for k, v7 in pairs(v6) do
		if not v[k] then
			Settings.SettingChanged("Game", k, v7)
		end
	end
end

function ProfileInspect.Bind(instance)
	local info = instance:FindFirstChild("Info")
	local player = info and info:FindFirstChild("Player")
	local pins = info and info:FindFirstChild("Pins")
	local level = info and info:FindFirstChild("Level")
	local levelBar = level and level:FindFirstChild("LevelBar")
	avatar = player and player:FindFirstChild("Avatar")
	username = info and info:FindFirstChild("Username")
	textLabel = level and level:FindFirstChild("TextLabel")
	rank = level and level:FindFirstChild("Rank")
	current = levelBar and levelBar:FindFirstChild("Current")
	v2 = not (pins and pins:IsA("Frame")) and {} or collectPinLabels(pins)
	local copyCrosshair = instance:FindFirstChild("CopyCrosshair")

	if copyCrosshair and copyCrosshair:IsA("ImageButton") then
		v3 = copyCrosshair
		ActivateButton(copyCrosshair)
		copyCrosshair.MouseButton1Click:Connect(function()
			if v5 then
				copyPlayerCrosshair(v5)
			end
		end)
	end

	local report = instance:FindFirstChild("Report")

	if report and report:IsA("ImageButton") then
		v4 = report
		ActivateButton(report)
		report.MouseButton1Click:Connect(function()
			if v5 and v5 ~= LocalPlayer and not Participants.IsBot(v5) then
				Report.Open(v5)
			end
		end)
	end
end

local function clearAccountDetails() -- 2 equivalent calls inferred from this helper
	for _, v6 in v2 do
		v6.Visible = false
	end

	if textLabel then
		textLabel.Text = ""
	end

	if rank then
		rank.Image = ""
	end

	if current then
		local y = current.Size.Y
		current.Size = UDim2.new(0, 0, y.Scale, y.Offset)
	end
end

function ProfileInspect.Populate(p)
	v5 = p
	updateActionButtons(p) -- inferred equivalent call

	if avatar then
		avatar.Image = Participants.HeadshotImage(p)
	end

	if username then
		username.Text = Participants.Name(p)
	end

	if Participants.IsBot(p) then
		clearAccountDetails() -- inferred equivalent call

		if textLabel then
			textLabel.Text = "[Bot]"
		end
	else
		populatePins(p)
		populateLevel(p)
	end
end

function ProfileInspect.Reset()
	v5 = nil
	local isBot = Participants.IsBot(nil)

	if v3 then
		v3.Active = false
	end

	if v4 then
		v4.Visible = not isBot
		v4.Active = false
	end

	clearAccountDetails() -- inferred equivalent call

	if avatar then
		avatar.Image = ""
	end

	if username then
		username.Text = ""
	end
end

return ProfileInspect