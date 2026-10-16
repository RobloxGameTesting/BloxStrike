local Overview = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Types)
local Format = require(script.Parent.Format)
local Derive = require(script.Parent.Derive)
local Resolve = require(script.Parent.Resolve)
local Selection = require(script.Parent.Selection)
local CareerData = require(script.Parent.CareerData)
local WeaponIcon = require(script.Parent.WeaponIcon)
local LocalPlayer = Players.LocalPlayer
local GetRankTitle = require(ReplicatedStorage.Components.Common.GetRankTitle)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local LevelsIcon = require(ReplicatedStorage.Database.Custom.GameStats.LevelsIcon)
local frozen = table.freeze({ "Counter-Terrorists", "Terrorists" })
local color = Color3.fromRGB(219, 43, 43)
local color2 = Color3.new(1, 1, 1)
local frozen2 = table.freeze({
	Pistol = "1ST ROUND",
	Eco = "$0-999",
	Semi = "$1000-3899",
	Full = "$3900+"
})
local frozen3 = table.freeze({ "LOADOUT", "K/D", "ADR", "KAST", "WIN %", "KILLS", "DEATHS" })
local v = nil
local profile = nil
local accuracy = nil
local lifetimeStats = nil
local team = nil
local killStats = nil
local loadout = nil
local filter = nil
local nextSelectionDown = nil
local v2 = nil
local images = {}

local function GetOrderedLabels(instance)
	local left = instance:FindFirstChild("Left") or instance
	local labels = {}

	for _, label in ipairs(left:GetChildren()) do
		if label:IsA("TextLabel") then
			table.insert(labels, label)
		end
	end

	table.sort(labels, function(a, b)
		return a.Position.X.Scale < b.Position.X.Scale
	end)
	return labels
end

local function GetBadgeIconFromItem(data)
	if typeof(data) ~= "table" or data.Name ~= "Badge" or typeof(data.Skin) ~= "string" then
		return ""
	end

	local skinInformation = Skins.GetSkinInformation(data.Name, data.Skin)

	if not skinInformation then
		return ""
	end

	local v3 = typeof(data.Float) ~= "number" and 0.9999 or data.Float
	return Skins.GetWearImageForFloat(skinInformation, v3) or skinInformation.imageAssetId or ""
end

local function PopulatePins()
	if #images == 0 then
		return
	end

	local v3, v4 = DataController.Get(LocalPlayer, "Inventory", "Loadout")
	local v5 = {}
	local v6 = {}

	for _, v7 in ipairs(frozen) do
		local v8

		if typeof(v4) == "table" then
			v8 = v4[v7]
		else
			v8 = false
		end

		local equipped

		if typeof(v8) == "table" then
			equipped = v8.Equipped
		else
			equipped = false
		end

		local equippedBadge

		if typeof(equipped) == "table" then
			equippedBadge = equipped["Equipped Badge"]
		else
			equippedBadge = false
		end

		if not (typeof(equippedBadge) == "string" and equippedBadge ~= "" and typeof(v3) == "table") then
			continue
		end

		for _, v9 in ipairs(v3) do
			if not (typeof(v9) == "table" and v9._id == equippedBadge) then
				continue
			end

			local v10 = typeof(v9.Skin) ~= "string" and "" or v9.Skin

			if not (v10 ~= "" and not v5[v10]) then
				break
			end

			local badgeIconFromItem = GetBadgeIconFromItem(v9)

			if badgeIconFromItem ~= "" then
				v5[v10] = true
				table.insert(v6, badgeIconFromItem)
			end

			break
		end
	end

	for i, v7 in ipairs(images) do
		local v8 = v6[i]
		v7.Image = v8 or ""
		v7.Visible = v8 ~= nil
	end
end

local function PopulateLevel()
	local level = profile.Info:FindFirstChild("Level")

	if not level then
		return
	end

	local level2 = DataController.Get(LocalPlayer, "Level")
	local level3, experience, nextExperienceRequirement

	if typeof(level2) == "table" then
		level3 = level2.Level or 1
		experience = level2.Experience or 0
		nextExperienceRequirement = level2.NextExperienceRequirement or 1000
	else
		level3 = 1
		nextExperienceRequirement = 1000
		experience = 0
	end

	local textLabel = level:FindFirstChild("TextLabel")

	if textLabel then
		textLabel.Text = `[{GetRankTitle(level3)} Rank {level3}]`
	end

	local rank = level:FindFirstChild("Rank")

	if rank then
		rank.Image = LevelsIcon[tostring(level3)] or ""
	end

	local levelBar = level:FindFirstChild("LevelBar")
	local current = levelBar and levelBar:FindFirstChild("Current")

	if current then
		local v3 = math.clamp(experience / math.max(nextExperienceRequirement, 1), 0, 1)
		local y = current.Size.Y
		current.Size = UDim2.new(v3, 0, y.Scale, y.Offset)
	end
end

local function PopulateProfile(bucket)
	local player = profile.Info:FindFirstChild("Player")
	local avatar = player and player:FindFirstChild("Avatar")

	if avatar then
		avatar.Image = `rbxthumb://type=AvatarHeadShot&id={LocalPlayer.UserId}&w=150&h=150`
	end

	local username = profile.Info:FindFirstChild("Username")

	if username then
		username.Text = LocalPlayer.Name
	end

	local verified = profile.Info:FindFirstChild("Verified")

	if verified then
		verified.Visible = LocalPlayer.HasVerifiedBadge
	end

	PopulatePins()
	PopulateLevel()
	local basicInfo = profile:FindFirstChild("BasicInfo")

	if not basicInfo then
		return
	end

	Resolve.SetRow(basicInfo, "Timeplayed", "TIME PLAYED", Format.TimePlayed(bucket.SecondsPlayed))
	Resolve.SetRow(basicInfo, "Kd", "K/D RATIO", Format.Decimal(Derive.KillDeath(bucket), 2))
	Resolve.SetRow(basicInfo, "Winrate", "WIN RATE", Format.Percent(bucket.MatchesWon, bucket.MatchesPlayed))
end

local function PaintBodyZone(childName: string, p: number, shotsFired: number) -- 3 equivalent calls inferred from this helper
	local body = accuracy:FindFirstChild("Body")
	local child = body and body:FindFirstChild(childName)

	if not child then
		return
	end

	child.ImageColor3 = color2:Lerp(color, Derive.HeatWeight(p, shotsFired))
end

local function PopulateAccuracy(bucket)
	local accuracy2 = bucket.Accuracy
	local info = accuracy:FindFirstChild("Info")

	if info then
		local shotsHit = accuracy2.ShotsHit
		Resolve.SetRow(info, "Average", "AVERAGE", Format.Percent(shotsHit, accuracy2.ShotsFired, 1))
		Resolve.SetRow(info, "Head", "HEAD", Format.Percent(accuracy2.HeadHits, shotsHit, 1))
		Resolve.SetRow(info, "Body", "BODY", Format.Percent(accuracy2.BodyHits, shotsHit, 1))
		Resolve.SetRow(info, "Legs", "LEGS", Format.Percent(accuracy2.LegHits, shotsHit, 1))
	end

	PaintBodyZone("Head", accuracy2.HeadHits, accuracy2.ShotsFired) -- inferred equivalent call
	PaintBodyZone("Torso", accuracy2.BodyHits, accuracy2.ShotsFired) -- inferred equivalent call
	PaintBodyZone("Legs", accuracy2.LegHits, accuracy2.ShotsFired) -- inferred equivalent call
end

local function PopulateSide(bucket, childName: string, p: string)
	local child = team and team:FindFirstChild(childName)

	if not child then
		return
	end

	local side = bucket.Sides[p]

	if not side then
		return
	end

	local info = child:FindFirstChild("Info")

	if info then
		Resolve.SetRow(info, "Kd", "K/D RATIO", Format.Ratio(side.Kills, side.Deaths))
		Resolve.SetRow(info, "Win", "WIN %", Format.Percent(side.RoundsWon, side.RoundsPlayed))
		Resolve.SetRow(
			info,
			"Kills/Round",
			"KILLS/ROUND",
			Format.Decimal(Derive.Divide(side.Kills, side.RoundsPlayed), 1)
		)
	end

	local favoriteGun = child:FindFirstChild("FavoriteGun")

	if not favoriteGun then
		return
	end

	local favouriteWeapon, v3 = Derive.FavouriteWeapon(bucket, p)
	local itemIcon = favoriteGun:FindFirstChild("ItemIcon")

	if itemIcon then
		itemIcon.Image = not favouriteWeapon and "" or WeaponIcon.Get(favouriteWeapon, p)
	end

	local header = favoriteGun:FindFirstChild("Header")
	local title = header and header:FindFirstChild("Title")

	if title then
		title.Text = not favouriteWeapon and "FAVORITE WEAPON" or `FAVORITE WEAPON: {string.upper(favouriteWeapon)}`
	end

	local title2 = favoriteGun:FindFirstChild("Title")

	if title2 then
		title2.Text = `KILLS: {Format.Number(v3)}`
	end
end

local function PopulateKillStats(bucket)
	local winRate = killStats and killStats:FindFirstChild("WinRate")

	if winRate then
		Resolve.SetRow(winRate, "Header", "WINS RATE", Format.Percent(bucket.MatchesWon, bucket.MatchesPlayed))
		local moreInfo = winRate:FindFirstChild("MoreInfo")
		local info = moreInfo and moreInfo:FindFirstChild("Info")

		if info then
			Resolve.SetRow(info, "Played", "PLAYED", Format.Number(bucket.MatchesPlayed))
			Resolve.SetRow(info, "Won", "WON", Format.Number(bucket.MatchesWon))
			Resolve.SetRow(info, "Lost", "LOST", Format.Number(bucket.MatchesLost))
			Resolve.SetRow(info, "Tied", "TIED", Format.Number(bucket.MatchesTied))
			Resolve.SetRow(info, "Clutch", "CLUTCHES 1V1", Format.Number(bucket.Clutches))
			Resolve.SetRow(info, "FlawlessRounds", "FLAWLESS ROUNDS", Format.Number(bucket.FlawlessRounds))
			Resolve.SetRow(info, "MVP", "MVPS", Format.Number(bucket.RoundMVPs))
			Resolve.SetRow(info, "Ace", "ACE ROUNDS", Format.Number(bucket.AceRounds))
			Resolve.SetRow(info, "OvertimeWins", "OVERTIME WINS", Format.Number(bucket.OvertimeWins))
		end
	end

	local kd = killStats and killStats:FindFirstChild("KD")

	if kd then
		Resolve.SetRow(kd, "Header", "K/D RATIO", Format.Decimal(Derive.KillDeath(bucket), 2))
		local moreInfo = kd:FindFirstChild("MoreInfo")
		local info = moreInfo and moreInfo:FindFirstChild("Info")

		if info then
			Resolve.SetRow(info, "Kills", "KILLS", Format.Number(bucket.Kills))
			Resolve.SetRow(info, "Deaths", "DEATHS", Format.Number(bucket.Deaths))
			Resolve.SetRow(info, "Assists", "ASSISTS", Format.Number(bucket.Assists))
			Resolve.SetRow(info, "HeadshotKills", "HEADSHOT KILLS", Format.Number(bucket.HeadshotKills))
			Resolve.SetRow(info, "Kast", "KAST", Format.Share(Derive.Kast(bucket), 1))
			Resolve.SetRow(info, "ACS", "ACS", Format.Decimal(Derive.CombatScore(bucket), 1))
			Resolve.SetRow(info, "ADR", "ADR", Format.Decimal(Derive.AverageDamage(bucket), 1))
			Resolve.SetRow(info, "DamageDelta", "DAMAGE DELTA TOTAL", Format.Signed(Derive.DamageDelta(bucket), 1))
			Resolve.SetRow(
				info,
				"Kill/Round",
				"KILL/ROUND",
				Format.Decimal(Derive.Divide(bucket.Kills, bucket.RoundsPlayed), 2)
			)
		end
	end
end

local function PopulateLoadout(bucket)
	if not loadout then
		return
	end

	local header = loadout:FindFirstChild("Header")

	if header then
		local orderedLabels = GetOrderedLabels(header)

		for i, text in ipairs(frozen3) do
			local v3 = orderedLabels[i]

			if v3 then
				v3.Text = text
			end
		end
	end

	local moreInfo = loadout:FindFirstChild("MoreInfo")
	local info = moreInfo and moreInfo:FindFirstChild("Info")

	if not info then
		return
	end

	for _, economyTier in ipairs(CareerData.EconomyTiers) do
		local row = Resolve.Row(info, economyTier, string.upper(economyTier))

		if not row then
			continue
		end

		local v3 = bucket.Economy[economyTier]

		if not v3 then
			continue
		end

		local orderedLabels = GetOrderedLabels(row)
		local v4 = {
			string.upper(economyTier),
			frozen2[economyTier] or "",
			Format.Ratio(v3.Kills, v3.Deaths),
			Format.Decimal(Derive.Divide(v3.DamageDealt, v3.RoundsPlayed), 1),
			Format.Percent(v3.KastRounds, v3.RoundsPlayed, 1),
			Format.Percent(v3.RoundsWon, v3.RoundsPlayed),
			Format.Number(v3.Kills),
			Format.Number(v3.Deaths)
		}

		for i, text in ipairs(v4) do
			local v5 = orderedLabels[i]

			if v5 then
				v5.Text = text
			end
		end
	end
end

local function IsShown(parent)
	while parent and parent ~= lifetimeStats do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		else
			parent = parent.Parent
		end
	end

	return true
end

local function GetHeaderIcon(instance) -- 2 equivalent calls inferred from this helper
	local header = instance and instance:FindFirstChild("Header")
	local icon = header and header:FindFirstChild("Icon")

	if icon and icon:IsA("GuiButton") then
		return icon
	end

	return nil
end

local function SetSelectionLink(p, p2: string, p3)
	if p then
		p[p2] = p3
	end
end

local function LinkSelection()
	local v3 = {}

	local function AddRow(...)
		local guiObjects = {}

		for i = 1, select("#", ...) do
			local guiObject = select(i, ...)

			if not (guiObject and guiObject:IsA("GuiObject")) then
				continue
			end

			local selectable = IsShown(guiObject)
			guiObject.Selectable = selectable

			if selectable then
				table.insert(guiObjects, guiObject)
			end
		end

		if #guiObjects > 0 then
			table.insert(v3, guiObjects)
		end
	end

	AddRow(killStats and killStats:FindFirstChild("WinRate"), killStats and killStats:FindFirstChild("KD"))
	AddRow(team and team:FindFirstChild("CT"), team and team:FindFirstChild("T"))
	local moreInfo = loadout and loadout:FindFirstChild("MoreInfo")
	local info = moreInfo and moreInfo:FindFirstChild("Info")

	if info then
		for _, economyTier in ipairs(CareerData.EconomyTiers) do
			AddRow(Resolve.Row(info, economyTier, string.upper(economyTier)))
		end
	end

	for i, list in ipairs(v3) do
		local v4 = v3[i - 1]
		local v5 = v3[i + 1]

		for j, v6 in ipairs(list) do
			v6.NextSelectionLeft = list[j - 1]
			v6.NextSelectionRight = list[j + 1]
			v6.NextSelectionUp = v4 and v4[math.min(j, #v4)]
			v6.NextSelectionDown = v5 and v5[math.min(j, #v5)]
		end
	end

	local v4 = v3[1]
	nextSelectionDown = v4 and v4[1]
	local headerIcon = GetHeaderIcon(profile) -- inferred equivalent call
	local headerIcon2 = GetHeaderIcon(accuracy) -- inferred equivalent call
	local v5 = nextSelectionDown

	if v5 then
		if headerIcon then
			headerIcon.NextSelectionRight = v5
		end

		if headerIcon2 then
			headerIcon2.NextSelectionRight = v5
		end

		if filter and filter:IsA("GuiObject") then
			v5.NextSelectionUp = filter
		end
	end

	for i, v6 in ipairs(v3) do
		local nextSelectionLeft

		if i == 1 then
			nextSelectionLeft = headerIcon
		else
			nextSelectionLeft = headerIcon2 or headerIcon
		end

		if nextSelectionLeft then
			v6[1].NextSelectionLeft = nextSelectionLeft
		end
	end

	local visible

	if v == nil then
		visible = false
	else
		visible = v.Visible
	end

	local v6 = v2

	if not visible then
		v5 = nil
	end

	if v6 then
		v6.NextSelectionDown = v5
	end

	local v7 = filter
	local nextSelectionUp = v2

	if v7 then
		v7.NextSelectionUp = nextSelectionUp
	end

	local dropdownContent = filter and filter:FindFirstChild("DropdownContent")
	local visible2 = dropdownContent and dropdownContent:IsA("GuiObject") and dropdownContent.Visible

	if filter and filter:IsA("GuiObject") and not visible2 then
		filter.NextSelectionDown = nextSelectionDown
	end
end

local function SetDropdownOpen(visible: boolean)
	local dropdownContent = filter and filter:FindFirstChild("DropdownContent")

	if dropdownContent and dropdownContent:IsA("GuiObject") then
		dropdownContent.Visible = visible
	end

	local reverse = filter
		and filter:FindFirstChild("Container")
		and filter.Container:FindFirstChild("Left")
		and filter.Container.Left:FindFirstChild("Reverse")

	if reverse and reverse:IsA("GuiObject") then
		reverse.Rotation = visible and 180 or 0
	end

	if filter and filter:IsA("GuiObject") then
		local v3 = filter
		local nextSelectionDown2

		if not visible then
			nextSelectionDown2 = nextSelectionDown
		end

		v3.NextSelectionDown = nextSelectionDown2
	end
end

local function BindDropdown()
	if not filter then
		return
	end

	local dropdownContent = filter:FindFirstChild("DropdownContent")
	local scroll = dropdownContent and dropdownContent:FindFirstChild("Scroll")

	if not scroll then
		return
	end

	SetDropdownOpen(false)

	if filter:IsA("GuiButton") then
		filter.Activated:Connect(function()
			local visible = dropdownContent:IsA("GuiObject") and dropdownContent.Visible
			SetDropdownOpen(not visible)
		end)
	end

	for _, button in ipairs(scroll:GetChildren()) do
		if not button:IsA("GuiButton") then
			continue
		end

		local name = button.Name

		if Selection.Names[name] ~= nil then
			button.Activated:Connect(function()
				SetDropdownOpen(false)
				Selection.Set(name)
			end)
		end
	end
end

function Overview.Bind(instance)
	v = instance
	profile = instance:FindFirstChild("Profile")
	accuracy = instance:FindFirstChild("Accuracy")
	lifetimeStats = instance:FindFirstChild("LifetimeStats")
	local lifetimeStatsContainer = lifetimeStats and lifetimeStats:FindFirstChild("Container")
	local teamStats = lifetimeStatsContainer and lifetimeStatsContainer:FindFirstChild("TeamStats")
	team = teamStats and teamStats:FindFirstChild("Team")
	killStats = lifetimeStatsContainer and lifetimeStatsContainer:FindFirstChild("KillStats")
	loadout = lifetimeStatsContainer and lifetimeStatsContainer:FindFirstChild("Loadout")
	filter = lifetimeStats and lifetimeStats:FindFirstChild("Filter")
	images = {}
	local pins = profile and profile.Info:FindFirstChild("Pins")

	if pins then
		for _, image in ipairs(pins:GetChildren()) do
			if image:IsA("ImageLabel") then
				table.insert(images, image)
			end
		end

		table.sort(images, function(a, b)
			return a.Position.X.Scale < b.Position.X.Scale
		end)
	end

	BindDropdown()
end

function Overview.BindTab(p)
	v2 = p
	LinkSelection()
end

function Overview.RefreshSelection()
	LinkSelection()
end

function Overview.Render()
	local v3 = Selection.Get()
	local bucket = CareerData.GetBucket(v3)

	if lifetimeStats then
		local title = lifetimeStats:FindFirstChild("Title")
		local title2 = title and title:FindFirstChild("Title")

		if title2 then
			title2.Text = Selection.Headings[v3] or "LIFETIME STATS"
		end

		local title3 = filter
			and filter:FindFirstChild("Container")
			and filter.Container:FindFirstChild("Left")
			and filter.Container.Left:FindFirstChild("Title")

		if title3 then
			title3.Text = Selection.Names[v3] or "All Gamemodes"
		end
	end

	if profile then
		PopulateProfile(bucket)
	end

	if accuracy then
		PopulateAccuracy(bucket)
	end

	local hasRounds = Selection.HasRounds(v3)
	local parent = team and team.Parent

	if parent then
		parent.Visible = hasRounds
	end

	if loadout then
		loadout.Visible = hasRounds
	end

	if hasRounds then
		PopulateSide(bucket, "CT", "Counter-Terrorists")
		PopulateSide(bucket, "T", "Terrorists")
		PopulateLoadout(bucket)
	end

	PopulateKillStats(bucket)
	LinkSelection()
end

return Overview