local MatchDetails = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Types)
local Format = require(script.Parent.Format)
local Derive = require(script.Parent.Derive)
local MapIcon = require(script.Parent.MapIcon)
local CareerData = require(script.Parent.CareerData)
local WeaponIcon = require(script.Parent.WeaponIcon)
local LocalPlayer = Players.LocalPlayer
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Router = require(ReplicatedStorage.Database.Security.Router)
local v = { Base = Color3.fromRGB(32, 108, 23), Cell = Color3.fromRGB(87, 255, 93) }
local v2 = { Base = Color3.fromRGB(89, 9, 9), Cell = Color3.fromRGB(255, 53, 53) }
local v3 = { Base = Color3.fromRGB(108, 95, 23), Cell = Color3.fromRGB(255, 236, 87) }
local frozen = table.freeze({ "CombatScore", "Econ", "Plants", "Kills", "Assists", "Assist" })
local color = Color3.fromRGB(165, 183, 212)
local color2 = Color3.fromRGB(219, 199, 126)
local color3 = Color3.fromRGB(95, 95, 95)
local color4 = Color3.fromRGB(88, 245, 82)
local color5 = Color3.fromRGB(195, 20, 20)
local frozen2 = table.freeze({ Kill = true, Death = true })
local color6 = Color3.new(1, 1, 1)
local color7 = Color3.fromRGB(158, 158, 158)
local color8 = Color3.fromRGB(219, 43, 43)
local color9 = Color3.new(1, 1, 1)
local frozen3 = table.freeze({
	BombDefuse = "rbxassetid://138772806705472",
	BombExplode = "rbxassetid://97682949239067",
	BombObjective = "rbxassetid://97682949239067",
	Elimination = "rbxassetid://70876442749327",
	TimeExpiration = "rbxassetid://96043369049959",
	HostageRescue = "rbxassetid://138772806705472"
})
local frozen4 = table.freeze({
	Sort_CombatScore = function(p)
		return Derive.Divide(p.CombatScore, p.RoundsPlayed)
	end,
	Sort_KDA = function(p)
		return p.Kills - p.Deaths
	end,
	Sort_Econ = function(p)
		return Derive.EconomyRating(p.DamageDealt, p.MoneySpent)
	end,
	Sort_FirstBloods = function(p)
		return p.FirstBloods
	end,
	Sort_Plants = function(p)
		return p.Plants
	end,
	Sort_Defuses = function(p, flag: boolean)
		if flag then
			return p.Rescues
		end

		return p.Defuses
	end
})
local details = nil
local v4 = nil
local scoreboard = nil
local timeline = nil
local peformance = nil
local filters = nil
local template = nil
local template2 = nil
local template3 = nil
local template4 = nil
local detailTemplate = nil
local fightTemplate = nil
local v5 = nil
local v6 = "Scoreboard"
local v7 = 1
local v8 = {}
local v9 = "Sort_CombatScore"
local v10 = true
local labelsByName = {}
local positionsByName = {}

local function TeamColor(winner: string) -- 1 equivalent call inferred from this helper
	if winner == "Counter-Terrorists" then
		return color
	end

	return color2
end

local function SetText(instance, childName: string, text: string) -- 22 equivalent calls inferred from this helper
	local label = instance and instance:FindFirstChild(childName)

	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function WeaponName(value: string?)
	if value == nil or value == "" then
		return ""
	end

	return string.upper(value)
end

local function SetAmount(instance, childName: string, text: string)
	local label = instance:FindFirstChild(childName)
	local amount = label and label:FindFirstChild("Amount")

	if amount and amount:IsA("TextLabel") then
		amount.Text = text
	elseif label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function ResolveAvatarUserId(p: number)
	local v11 = v5

	if v11 then
		for _, player in ipairs(v11.Players) do
			if player.UserId == p and player.AvatarUserId > 0 then
				return player.AvatarUserId
			end
		end
	end

	return p
end

local function ApplyAvatar(avatar, p: number)
	if not avatar then
		return
	end

	local avatarUserId = ResolveAvatarUserId(p)

	if not (avatar:IsA("ImageLabel") or avatar:IsA("ImageButton")) then
		avatar = avatar:FindFirstChild("Avatar") or avatar:FindFirstChildWhichIsA("ImageLabel", true)
	end

	if avatar and (avatar:IsA("ImageLabel") or avatar:IsA("ImageButton")) then
		avatar.Image = not (avatarUserId > 0) and "" or `rbxthumb://type=AvatarHeadShot&id={avatarUserId}&w=150&h=150`
	end
end

local function SetAvatar(instance, childName: string, userId: number) -- 3 equivalent calls inferred from this helper
	ApplyAvatar(instance:FindFirstChild(childName), userId)
end

local function PaintPlayerRow(guiObject, p)
	if guiObject:IsA("GuiObject") then
		guiObject.BackgroundColor3 = p.Base
	end

	for _, guiObject2 in ipairs(guiObject:GetChildren()) do
		if guiObject2.Name == "Frame" and guiObject2:IsA("GuiObject") and guiObject2.BackgroundTransparency < 1 then
			guiObject2.BackgroundColor3 = p.Base
		elseif guiObject2.Name == "Pattern" then
			if guiObject2:IsA("ImageLabel") then
				guiObject2.ImageColor3 = p.Base
			end

			for _, image in ipairs(guiObject2:GetDescendants()) do
				if image:IsA("ImageLabel") then
					image.ImageColor3 = p.Base
				end
			end
		end
	end

	for _, childName in ipairs(frozen) do
		local guiObject2 = guiObject:FindFirstChild(childName)

		if guiObject2 and guiObject2:IsA("GuiObject") and guiObject2.BackgroundTransparency < 1 then
			guiObject2.BackgroundColor3 = p.Cell
		end
	end
end

local function PaletteFor(userId: number, p: string, team: string) -- 2 equivalent calls inferred from this helper
	if userId == LocalPlayer.UserId then
		return v3
	end

	if p == team then
		return v
	end

	return v2
end

local function GetBadgeImage(p: string, p2: number)
	if p == "" then
		return ""
	end

	local skinInformation = Skins.GetSkinInformation("Badge", p)

	if skinInformation then
		return Skins.GetWearImageForFloat(skinInformation, p2) or skinInformation.imageAssetId or ""
	end

	return ""
end

local function ClearRows(instance)
	for _, child in ipairs(instance:GetChildren()) do
		if string.sub(child.Name, 1, 4) == "Row_" then
			child:Destroy()
		end
	end
end

local function CloneRow(instance, parent, layoutOrder: number) -- 5 equivalent calls inferred from this helper
	local clone = instance:Clone()
	clone.Name = `Row_{layoutOrder}`
	clone.LayoutOrder = layoutOrder
	clone.Visible = true
	clone.Parent = parent
	return clone
end

function MatchDetails:ApplyStatus(p: string)
	self.TextColor3 = Color3.new(1, 1, 1)
	local color10, color11

	if p == "Victory" then
		self.Text = "VICTORY"
		color10 = Color3.fromRGB(88, 245, 82)
		color11 = Color3.fromRGB(53, 213, 48)
	elseif p == "Defeat" then
		self.Text = "DEFEAT"
		color10 = Color3.fromRGB(255, 26, 26)
		color11 = Color3.fromRGB(255, 55, 55)
	else
		self.Text = "DRAW"
		color10 = Color3.fromRGB(224, 214, 148)
		color11 = Color3.fromRGB(176, 170, 138)
	end

	local uiGradient = self:FindFirstChildOfClass("UIGradient")

	if uiGradient then
		uiGradient.Color = ColorSequence.new(color10, color11)
	else
		self.TextColor3 = color10
	end
end

local function PopulateHeader(data)
	local v11 = data.Team == "Counter-Terrorists"
	local ctScore

	if v11 then
		ctScore = data.CTScore
	else
		ctScore = data.TScore
	end

	local tScore

	if v11 then
		tScore = data.TScore
	else
		tScore = data.CTScore
	end

	SetText(details, "YourScore", tostring(ctScore)) -- inferred equivalent call
	SetText(details, "EnemyScore", tostring(tScore)) -- inferred equivalent call
	SetText(details, "Timer", Format.Duration(data.Duration)) -- inferred equivalent call
	SetText(details, "Gamemode", `{data.ServerGamemode} | {data.Map}`) -- inferred equivalent call
	local icon = details:FindFirstChild("Icon")

	if icon and icon:IsA("ImageLabel") then
		icon.Image = MapIcon.Get(data.Map)
	end

	local imageButton = details:FindFirstChild("ImageButton")

	if imageButton and imageButton:IsA("ImageButton") then
		imageButton.Image = MapIcon.Get(data.Map)
	end

	local victory = details:FindFirstChild("Victory")
	local defeat = details:FindFirstChild("Defeat")
	local visible = data.Result == "Defeat"

	if victory then
		victory.Visible = not visible

		if not visible then
			MatchDetails.ApplyStatus(victory, data.Result)
		end
	end

	if defeat then
		defeat.Visible = visible

		if visible then
			MatchDetails.ApplyStatus(defeat, data.Result)
		end
	end
end

local function SortPlayers(p, flag: boolean) -- 1 equivalent call inferred from this helper
	local clone = table.clone(p.Players)
	local v11 = frozen4[v9]
	table.sort(clone, function(a, b)
		if v11 then
			local v12 = v11(a, flag)
			local v13 = v11(b, flag)

			if v12 == v13 then
				return a.Kills > b.Kills
			end

			if v10 then
				return v13 < v12
			end

			return v12 < v13
		else
			local displayName = string.lower(a.DisplayName)
			local displayName2 = string.lower(b.DisplayName)

			if displayName == displayName2 then
				return a.UserId < b.UserId
			end

			if v10 then
				return displayName2 < displayName
			end

			return displayName < displayName2
		end
	end)
	return clone
end

local function UpdateColumnHeadings() -- 2 equivalent calls inferred from this helper
	for k, v11 in pairs(labelsByName) do
		local textColor

		if k == v9 then
			textColor = color6
		else
			textColor = color7
		end

		v11.TextColor3 = textColor
	end
end

local function PopulateScoreboard(p)
	local main = scoreboard and scoreboard:FindFirstChild("Main")
	local main2 = main and main:FindFirstChild("Main")

	if not (main2 and template) then
		return
	end

	ClearRows(main2)
	local v11 = p.Gamemode == "Hostage Rescue"
	local sortPlayers = SortPlayers(p, v11) -- inferred equivalent call

	for i, v12 in ipairs(sortPlayers) do
		local row = CloneRow(template, main2, i) -- inferred equivalent call
		local formatted = `{v12.DisplayName} (@{v12.Username})`

		if v12.Disconnected then
			formatted = `{formatted} (LEFT)`
		end

		SetText(row, "PlayerName", formatted) -- inferred equivalent call
		SetAvatar(row, "Player", v12.UserId) -- inferred equivalent call
		local badge = row:FindFirstChild("Badge")

		if badge then
			local badgeSkin = v12.BadgeSkin
			local badgeFloat = v12.BadgeFloat
			local image

			if badgeSkin == "" then
				image = ""
			else
				local skinInformation = Skins.GetSkinInformation("Badge", badgeSkin)
				image = not skinInformation and ""
					or Skins.GetWearImageForFloat(skinInformation, badgeFloat)
					or skinInformation.imageAssetId
					or ""
			end

			badge.Image = image
			badge.Visible = image ~= ""
		end

		local formatted2 = `{v12.Kills}/{v12.Deaths}/{v12.Assists}`
		local kda = row:FindFirstChild("KDA")
		local amount = kda and kda:FindFirstChild("Amount")

		if amount and amount:IsA("TextLabel") then
			amount.Text = formatted2
		elseif kda and kda:IsA("TextLabel") then
			kda.Text = formatted2
		end

		local number = Format.Number(Derive.Divide(v12.CombatScore, v12.RoundsPlayed))
		local combatScore = row:FindFirstChild("CombatScore")
		local amount2 = combatScore and combatScore:FindFirstChild("Amount")

		if amount2 and amount2:IsA("TextLabel") then
			amount2.Text = number
		elseif combatScore and combatScore:IsA("TextLabel") then
			combatScore.Text = number
		end

		local number2 = Format.Number(Derive.EconomyRating(v12.DamageDealt, v12.MoneySpent))
		local econ = row:FindFirstChild("Econ")
		local amount3 = econ and econ:FindFirstChild("Amount")

		if amount3 and amount3:IsA("TextLabel") then
			amount3.Text = number2
		elseif econ and econ:IsA("TextLabel") then
			econ.Text = number2
		end

		local number3 = Format.Number(v12.FirstBloods)
		local firstBloods = row:FindFirstChild("FirstBloods")
		local amount4 = firstBloods and firstBloods:FindFirstChild("Amount")

		if amount4 and amount4:IsA("TextLabel") then
			amount4.Text = number3
		elseif firstBloods and firstBloods:IsA("TextLabel") then
			firstBloods.Text = number3
		end

		local number4 = Format.Number(v12.Plants)
		local plants = row:FindFirstChild("Plants")
		local amount5 = plants and plants:FindFirstChild("Amount")

		if amount5 and amount5:IsA("TextLabel") then
			amount5.Text = number4
		elseif plants and plants:IsA("TextLabel") then
			plants.Text = number4
		end

		local number5 = Format.Number
		local v13

		if v11 then
			v13 = v12.Rescues
		else
			v13 = v12.Defuses
		end

		local text = number5(v13)
		local defuses = row:FindFirstChild("Defuses")
		local amount6 = defuses and defuses:FindFirstChild("Amount")

		if amount6 and amount6:IsA("TextLabel") then
			amount6.Text = text
		elseif defuses and defuses:IsA("TextLabel") then
			defuses.Text = text
		end

		for _, childName in ipairs({ "Bomb", "Dead" }) do
			local guiObject = row:FindFirstChild(childName)

			if guiObject and guiObject:IsA("GuiObject") then
				guiObject.Visible = false
			end
		end

		PaintPlayerRow(row, PaletteFor(v12.UserId, v12.Team, p.Team)) -- inferred equivalent call
	end
end

local function BindColumnHeadings()
	local header = scoreboard and scoreboard:FindFirstChild("Header")

	if not header then
		return
	end

	for _, label in ipairs(header:GetChildren()) do
		if not (label:IsA("TextLabel") and (label.Name == "Sort_Player" or frozen4[label.Name] ~= nil)) then
			continue
		end

		local name = label.Name
		labelsByName[name] = label
		local hitbox = label:FindFirstChild("Hitbox")

		if not (hitbox and hitbox:IsA("GuiButton")) then
			continue
		end

		hitbox.Active = true
		hitbox.Activated:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")

			if v9 == name then
				v10 = not v10
			else
				v9 = name
				v10 = name ~= "Sort_Player"
			end

			UpdateColumnHeadings() -- inferred equivalent call
			local v11 = v5

			if v11 then
				PopulateScoreboard(v11)
			end
		end)
	end

	UpdateColumnHeadings() -- inferred equivalent call
end

local function GetResultsRow(p: number) -- 8 equivalent calls inferred from this helper
	local frame = timeline and timeline:FindFirstChild(`Results{p}`)

	if frame and frame:IsA("Frame") then
		return frame
	end

	return nil
end

local function GetRoundFrame(p: number)
	local resultsRow = GetResultsRow(p <= 12 and 1 or 2) -- inferred equivalent call

	if not resultsRow then
		return nil
	end

	local guiObject = resultsRow:FindFirstChild((tostring(p)))

	if guiObject and guiObject:IsA("GuiObject") then
		return guiObject
	end

	return nil
end

local function LayoutRounds(roundCount: number)
	local resultsRow = GetResultsRow(1) -- inferred equivalent call
	local resultsRow2 = GetResultsRow(2) -- inferred equivalent call

	if not (resultsRow and resultsRow2) then
		return
	end

	local v11 = positionsByName[resultsRow.Name]
	local v12 = positionsByName[resultsRow2.Name]
	local _1 = resultsRow:FindFirstChild("1")
	local uiListLayout = resultsRow:FindFirstChildOfClass("UIListLayout")

	if not (v11 and v12 and _1 and uiListLayout) then
		return
	end

	local v13 = math.clamp(roundCount, 1, 24)
	local v14 = math.min(v13, 12)
	local v15 = v13 - v14

	for i = 1, 24 do
		local resultsRow3 = GetResultsRow(i <= 12 and 1 or 2) -- inferred equivalent call
		local guiObject

		if resultsRow3 then
			guiObject = resultsRow3:FindFirstChild((tostring(i)))

			if not (guiObject and guiObject:IsA("GuiObject")) then
				guiObject = nil
			end
		end

		if guiObject then
			guiObject.Visible = i <= v13
		end
	end

	resultsRow2.Visible = v15 > 0
	local scale = resultsRow.Size.X.Scale
	local v16 = uiListLayout.Padding.Scale * scale
	local v17 = _1.Size.X.Scale * scale + v16
	local v18 = v11.X.Scale - scale / 2
	local v19 = v18 + (v12.X.Scale - v11.X.Scale)
	local v20 = v19 + 12 * v17 - v16
	local v21

	if v15 > 0 then
		v21 = v19 + v15 * v17 - v16
	else
		v21 = v18 + v14 * v17 - v16
	end

	local v22 = (v20 - v21) / 2
	resultsRow.Position = UDim2.new(v11.X.Scale + v22, v11.X.Offset, v11.Y.Scale, v11.Y.Offset)
	resultsRow2.Position = UDim2.new(v12.X.Scale + v22, v12.X.Offset, v12.Y.Scale, v12.Y.Offset)
	local v23 = {
		Previous = v18 - 0.014,
		Next = v21 + 0.014
	}

	for childName, v24 in pairs(v23) do
		local guiObject = timeline:FindFirstChild(childName)

		if not (guiObject and guiObject:IsA("GuiObject")) then
			continue
		end

		local position = guiObject.Position
		guiObject.Position = UDim2.new(v24 + v22, position.X.Offset, position.Y.Scale, position.Y.Offset)
	end
end

local function PaintRound(guiObject, p, visible: boolean)
	local selected = guiObject:FindFirstChild("Selected")

	if selected and selected:IsA("GuiObject") then
		selected.Visible = visible
	end

	if p then
		local v11 = TeamColor(p.Winner) -- inferred equivalent call
		guiObject.BackgroundColor3 = v11
		local v12 = p.Winner == "Terrorists" and "Team1" or "Team2"

		for _, childName in ipairs({ "Team1", "Team2" }) do
			local child = guiObject:FindFirstChild(childName)

			if not child then
				continue
			end

			local visible2 = childName == v12
			child.Visible = visible2

			if not visible2 then
				continue
			end

			child.BackgroundTransparency = 0
			child.BackgroundColor3 = v11
			local icon = child:FindFirstChild("Icon")

			if not icon then
				continue
			end

			icon.Image = frozen3[p.WinType] or "rbxassetid://70876442749327"
			icon.ImageColor3 = v11
			icon.ImageTransparency = 0
		end
	else
		guiObject.BackgroundColor3 = color3

		for _, childName in ipairs({ "Team1", "Team2" }) do
			local guiObject2 = guiObject:FindFirstChild(childName)

			if guiObject2 and guiObject2:IsA("GuiObject") then
				guiObject2.Visible = false
			end
		end
	end
end

local function GetRound(p, p2: number) -- 1 equivalent call inferred from this helper
	for _, round in ipairs(p.Rounds) do
		if round.Round == p2 then
			return round
		end
	end

	return nil
end

local function PopulateEventLog(p)
	local eventLog = timeline and timeline:FindFirstChild("EventLog")

	if not (eventLog and template2) then
		return
	end

	ClearRows(eventLog)
	local header = timeline:FindFirstChild("header") or timeline:FindFirstChild("Header")
	local left = header and header:FindFirstChild("Left")
	local label = left and left:FindFirstChild("Label")

	if label then
		label.Text = not p and "EVENT LOG" or `EVENT LOG | ROUND {p.Round}`
	end

	if not p then
		return
	end

	for i, event in ipairs(p.Events) do
		local row = CloneRow(template2, eventLog, i) -- inferred equivalent call
		SetText(row, "Time", Format.Duration(event.Time)) -- inferred equivalent call
		SetText(row, "Meter", `{math.floor(event.Distance + 0.5)}m`) -- inferred equivalent call
		local itemIcon = row:FindFirstChild("ItemIcon")

		if itemIcon and itemIcon:IsA("ImageLabel") then
			itemIcon.Image = WeaponIcon.Get(event.Weapon)
		end

		local guiObjects = {}

		for _, guiObject in ipairs(row:GetChildren()) do
			if guiObject:IsA("GuiObject") and guiObject.Name == "Player" then
				table.insert(guiObjects, guiObject)
			end
		end

		table.sort(guiObjects, function(a, b)
			return a.Position.X.Scale < b.Position.X.Scale
		end)

		for j, v11 in ipairs({ event.Killer, event.Victim }) do
			ApplyAvatar(guiObjects[j], v11)
		end
	end
end

local function PopulateRoundPlayers(p, p2)
	local player = timeline and timeline:FindFirstChild("Player")

	if not (player and template3) then
		return
	end

	ClearRows(player)

	if not p2 then
		return
	end

	local playersByUserId = {}

	for _, player2 in ipairs(p.Players) do
		playersByUserId[player2.UserId] = player2
	end

	local function TeamOf(p3) -- 3 equivalent calls inferred from this helper
		local v11 = playersByUserId[p3.UserId]

		if v11 then
			return v11.Team
		end

		return ""
	end

	local clone = table.clone(p2.Players)
	table.sort(clone, function(a, b)
		local v11 = TeamOf(a) == p.Team -- inferred equivalent call

		if v11 == (TeamOf(b) == p.Team) then -- inferred equivalent call
			return a.CombatScore > b.CombatScore
		end

		return v11
	end)

	for i, v11 in ipairs(clone) do
		local row = CloneRow(template3, player, i) -- inferred equivalent call
		local v12 = playersByUserId[v11.UserId]
		PaintPlayerRow(row, PaletteFor(v11.UserId, TeamOf(v11), p.Team)) -- inferred equivalent call
		local v13

		if v12 then
			v13 = v12.DisplayName
		else
			v13 = tostring(v11.UserId)
		end

		SetText(row, "PlayerName", v13) -- inferred equivalent call
		SetAvatar(row, "Player", v11.UserId) -- inferred equivalent call
		local number = Format.Number(v11.CombatScore)
		local combatScore = row:FindFirstChild("CombatScore")
		local amount = combatScore and combatScore:FindFirstChild("Amount")

		if amount and amount:IsA("TextLabel") then
			amount.Text = number
		elseif combatScore and combatScore:IsA("TextLabel") then
			combatScore.Text = number
		end

		local money = Format.Money(v11.MoneySpent)
		local econ = row:FindFirstChild("Econ")
		local amount2 = econ and econ:FindFirstChild("Amount")

		if amount2 and amount2:IsA("TextLabel") then
			amount2.Text = money
		elseif econ and econ:IsA("TextLabel") then
			econ.Text = money
		end

		local number2 = Format.Number(v11.Kills)
		local kills = row:FindFirstChild("Kills")
		local amount3 = kills and kills:FindFirstChild("Amount")

		if amount3 and amount3:IsA("TextLabel") then
			amount3.Text = number2
		elseif kills and kills:IsA("TextLabel") then
			kills.Text = number2
		end

		local number3 = Format.Number(v11.Assists)
		local assist = row:FindFirstChild("Assist")
		local amount4 = assist and assist:FindFirstChild("Amount")

		if amount4 and amount4:IsA("TextLabel") then
			amount4.Text = number3
		elseif assist and assist:IsA("TextLabel") then
			assist.Text = number3
		end

		local equip = row:FindFirstChild("Equip")

		if not equip then
			continue
		end

		local v14

		if v11.Equip == "" then
			v14 = "NONE"
		else
			local equip2 = v11.Equip
			v14 = (equip2 == nil or equip2 == "") and "" or string.upper(equip2)
		end

		SetText(equip, "Gun", v14) -- inferred equivalent call
		SetText(equip, "Armor", v11.Armor) -- inferred equivalent call
	end
end

local function RenderTimeline()
	local v11 = v5

	if not (v11 and timeline) then
		return
	end

	local map = timeline:FindFirstChild("Map")

	if map and map:IsA("ImageLabel") then
		local radar, v12 = MapIcon.GetRadar(v11.Map)
		map.Image = radar
		map.ImageTransparency = 0
		map.ImageRectOffset = v12.Min
		map.ImageRectSize = Vector2.new(v12.Width, v12.Height)
		map.Rotation = 90
		map.ScaleType = Enum.ScaleType.Fit
		map.BackgroundTransparency = 1
	end

	local matchDetails = CareerData.GetMatchDetails(v11.MatchId)
	local v12

	if matchDetails then
		local v13 = v7

		for _, round in ipairs(matchDetails.Rounds) do
			if round.Round ~= v13 then
				continue
			end

			v12 = round
			break
		end
	else
		v12 = matchDetails
	end

	local roundCount = v11.RoundCount

	if roundCount <= 0 then
		roundCount = matchDetails and #matchDetails.Rounds or 0
	end

	LayoutRounds(roundCount)

	for i = 1, 24 do
		local resultsRow = GetResultsRow(i <= 12 and 1 or 2) -- inferred equivalent call
		local guiObject

		if resultsRow then
			guiObject = resultsRow:FindFirstChild((tostring(i)))

			if not (guiObject and guiObject:IsA("GuiObject")) then
				guiObject = nil
			end
		end

		if not guiObject then
			continue
		end

		local v13

		if matchDetails then
			for _, round in ipairs(matchDetails.Rounds) do
				if round.Round ~= i then
					continue
				end

				v13 = round
				break
			end
		else
			local round = matchDetails
			v13 = round
		end

		PaintRound(guiObject, v13, i == v7)
	end

	PopulateEventLog(v12)
	PopulateRoundPlayers(v11, v12)
end

local function SelectRound(p: number) -- 2 equivalent calls inferred from this helper
	local v11 = v5
	local v12 = v11 and CareerData.GetMatchDetails(v11.MatchId)

	if not v12 then
		return false
	end

	if not GetRound(v12, p) then -- inferred equivalent call
		return false
	end

	Router.broadcastRouter("RunInterfaceSound", "UI Click")
	v7 = p
	RenderTimeline()
	return true
end

local function BindRoundButtons()
	for i = 1, 24 do
		local resultsRow = GetResultsRow(i <= 12 and 1 or 2) -- inferred equivalent call
		local guiObject

		if resultsRow then
			guiObject = resultsRow:FindFirstChild((tostring(i)))

			if not (guiObject and guiObject:IsA("GuiObject")) then
				guiObject = nil
			end
		end

		if not guiObject then
			continue
		end

		local v11 = i

		local function Select()
			SelectRound(v11) -- inferred equivalent call
		end

		local hitbox = guiObject:FindFirstChild("Hitbox")
		local v12 = nil

		if hitbox and hitbox:IsA("GuiButton") then
			v12 = hitbox
		elseif guiObject:IsA("GuiButton") then
			v12 = guiObject
		end

		if v12 then
			v12.Active = true
			v12.Selectable = true
			ActivateButton(v12)
			v12.Activated:Connect(Select)
		end

		if not (guiObject:IsA("GuiButton") and guiObject ~= v12) then
			continue
		end

		guiObject.Selectable = false
		guiObject.Active = true
		guiObject.Activated:Connect(Select)
	end
end

local function BindRoundArrows()
	for childName, v11 in pairs({ Previous = -1, Next = 1 }) do
		local button = timeline and timeline:FindFirstChild(childName)

		if not (button and button:IsA("GuiButton")) then
			continue
		end

		button.Active = true
		button.Selectable = true
		ActivateButton(button)
		local v12 = v11
		button.Activated:Connect(function()
			local v13 = v7 + v12

			while v13 >= 1 and v13 <= 24 do
				if SelectRound(v13) then -- inferred equivalent call
					break
				else
					v13 += v12
				end
			end
		end)
	end
end

local function PaintDamageBlock(instance, data)
	if not instance then
		return
	end

	local v11 = data.Head + data.Body + data.Legs
	SetText(instance, "Total", Format.Number(v11)) -- inferred equivalent call
	local dealtNumbers = instance:FindFirstChild("DealtNumbers")

	if dealtNumbers then
		SetText(dealtNumbers, "Head", Format.Number(data.Head)) -- inferred equivalent call
		SetText(dealtNumbers, "Body", Format.Number(data.Body)) -- inferred equivalent call
		SetText(dealtNumbers, "Legs", Format.Number(data.Legs)) -- inferred equivalent call
	end

	local body = instance:FindFirstChild("Body")

	if not body then
		return
	end

	local v12 = { Head = data.Head, Torso = data.Body, Legs = data.Legs }

	for childName, v13 in pairs(v12) do
		local image = body:FindFirstChild(childName)

		if image and image:IsA("ImageLabel") then
			image.ImageColor3 = color9:Lerp(color8, (math.clamp(Derive.Divide(v13, v11), 0, 1)))
		end
	end
end

local function TintLabel(instance, childName: string, textColor: Color3)
	local label = instance:FindFirstChild(childName)

	if not (label and label:IsA("TextLabel")) then
		return
	end

	local uiGradient = label:FindFirstChildOfClass("UIGradient")

	if not uiGradient then
		label.TextColor3 = textColor
		return
	end

	uiGradient.Color = ColorSequence.new(textColor)
	label.TextColor3 = Color3.new(1, 1, 1)
end

local function PopulateFight(parent, fight, layoutOrder: number)
	local clone = fightTemplate:Clone()
	clone.Name = `Row_{layoutOrder}`
	clone.LayoutOrder = layoutOrder
	clone.Visible = true
	local outcome = clone:FindFirstChild("Outcome")
	local visible = frozen2[fight.Outcome] == true

	if outcome and outcome:IsA("TextLabel") then
		outcome.Visible = visible

		if visible then
			outcome.TextTransparency = 0
		end
	end

	SetText(clone, "Outcome", string.upper(fight.Outcome)) -- inferred equivalent call
	SetText(clone, "Status", fight.RoundWon and "WON" or "LOST") -- inferred equivalent call
	local v11

	if fight.Outcome == "Kill" then
		v11 = color4
	else
		v11 = color5
	end

	TintLabel(clone, "Outcome", v11)
	local v12

	if fight.RoundWon then
		v12 = color4
	else
		v12 = color5
	end

	TintLabel(clone, "Status", v12)
	SetText(clone, "Title", tostring(fight.Round)) -- inferred equivalent call
	local yourWeapon = fight.YourWeapon
	SetText(clone, "YourWeaponName", (yourWeapon == nil or yourWeapon == "") and "" or string.upper(yourWeapon)) -- inferred equivalent call
	local enemyWeapon = fight.EnemyWeapon
	SetText(clone, "EnemyWeaponName", (enemyWeapon == nil or enemyWeapon == "") and "" or string.upper(enemyWeapon)) -- inferred equivalent call
	SetText(clone, "Range", `{math.floor(fight.Distance + 0.5)}m`) -- inferred equivalent call

	for _, v13 in {
		{ "YourWeapon", fight.YourWeapon },
		{ "EnemyWeapon", fight.EnemyWeapon }
	} do
		local image = clone:FindFirstChild(v13[1])

		if image and image:IsA("ImageLabel") then
			image.Image = WeaponIcon.Get(v13[2])
		end
	end

	PaintDamageBlock(clone:FindFirstChild("DamageDealt"), fight.DamageDealt)
	PaintDamageBlock(clone:FindFirstChild("DamageTaken"), fight.DamageTaken)
	clone.Parent = parent
end

local function ScaleFightPanel(guiObject, p: number)
	if not guiObject:IsA("GuiObject") or p <= 1 then
		return
	end

	local size = detailTemplate.Size
	guiObject.Size = UDim2.new(size.X.Scale, size.X.Offset, size.Y.Scale * p, size.Y.Offset * p)

	for _, guiObject2 in ipairs(guiObject:GetChildren()) do
		if not (string.sub(guiObject2.Name, 1, 4) == "Row_" and guiObject2:IsA("GuiObject")) then
			continue
		end

		local size2 = guiObject2.Size
		guiObject2.Size = UDim2.new(size2.X.Scale, size2.X.Offset, size2.Y.Scale / p, size2.Y.Offset)
	end

	local uiListLayout = guiObject:FindFirstChildOfClass("UIListLayout")

	if uiListLayout then
		local padding = uiListLayout.Padding
		uiListLayout.Padding = UDim.new(padding.Scale / p, padding.Offset)
	end
end

local function RenderPerformance()
	local v11 = v5
	local frame = peformance and peformance:FindFirstChild("Frame")

	if not (v11 and frame and template4) then
		return
	end

	ClearRows(frame)
	local matchDetails = CareerData.GetMatchDetails(v11.MatchId)

	if not matchDetails then
		return
	end

	local total = 0

	for _, duel in ipairs(matchDetails.Duels) do
		total += 10
		local row = CloneRow(template4, frame, total) -- inferred equivalent call
		local yourStats = row:FindFirstChild("YourStats")

		if yourStats then
			local number = Format.Number(duel.Kills)
			local kills = yourStats:FindFirstChild("Kills")
			local amount = kills and kills:FindFirstChild("Amount")

			if amount and amount:IsA("TextLabel") then
				amount.Text = number
			elseif kills and kills:IsA("TextLabel") then
				kills.Text = number
			end

			local number2 = Format.Number(duel.Deaths)
			local deaths = yourStats:FindFirstChild("Deaths")
			local amount2 = deaths and deaths:FindFirstChild("Amount")

			if amount2 and amount2:IsA("TextLabel") then
				amount2.Text = number2
			elseif deaths and deaths:IsA("TextLabel") then
				deaths.Text = number2
			end

			local number3 = Format.Number(duel.Assists)
			local assists = yourStats:FindFirstChild("Assists")
			local amount3 = assists and assists:FindFirstChild("Amount")

			if amount3 and amount3:IsA("TextLabel") then
				amount3.Text = number3
			elseif assists and assists:IsA("TextLabel") then
				assists.Text = number3
			end
		end

		local enemy = row:FindFirstChild("Enemy") or row
		SetText(enemy, "PlayerName", `{duel.DisplayName} (@{duel.Username})`) -- inferred equivalent call
		SetAvatar(enemy, "Player", duel.UserId) -- inferred equivalent call
		local v12 = v8[duel.UserId] == true

		if v12 and detailTemplate and fightTemplate then
			local parent = CloneRow(detailTemplate, frame, total + 1) -- inferred equivalent call
			local child = parent:FindFirstChild(fightTemplate.Name)

			if child then
				child:Destroy()
			end

			for i, fight in ipairs(duel.Fights) do
				PopulateFight(parent, fight, i)
			end

			ScaleFightPanel(parent, #duel.Fights)
		end

		local details2 = enemy:FindFirstChild("Details")

		if not (details2 and details2:IsA("GuiButton")) then
			continue
		end

		ActivateButton(details2)
		SetText(details2, "SelectedOptionText", v12 and "CLOSE" or "DETAILS") -- inferred equivalent call
		local userId = duel.UserId
		details2.Activated:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			v8[userId] = v8[userId] ~= true
			RenderPerformance()
		end)
	end
end

local function SelectTab(p: string)
	v6 = p
	local v11 = v5
	local visible

	if v11 == nil then
		visible = false
	else
		visible = v11.Gamemode ~= "Deathmatch"
	end

	if scoreboard then
		scoreboard.Visible = p == "Scoreboard"
	end

	if timeline then
		timeline.Visible = p == "Timeline" and visible
	end

	if peformance then
		peformance.Visible = p == "Performance" and visible
	end

	if filters then
		for _, button in ipairs(filters:GetChildren()) do
			if not button:IsA("GuiButton") then
				continue
			end

			local selectedOptionText = button:FindFirstChild("SelectedOptionText")

			if selectedOptionText then
				local textColor

				if button.Name == p then
					textColor = Color3.new(1, 1, 1)
				else
					textColor = Color3.fromRGB(158, 158, 158)
				end

				selectedOptionText.TextColor3 = textColor
			end

			if button.Name == "Timeline" or button.Name == "Performance" then
				button.Visible = visible
			end
		end
	end

	if p == "Timeline" then
		RenderTimeline()
	elseif p == "Performance" then
		RenderPerformance()
	end
end

function MatchDetails.Bind(instance)
	details = instance:FindFirstChild("Details")

	if not details then
		return
	end

	local inputBlocker = instance:FindFirstChild("InputBlocker")

	if inputBlocker and inputBlocker:IsA("GuiButton") then
		inputBlocker.Active = true
		inputBlocker.Visible = false
		v4 = inputBlocker
	end

	scoreboard = details:FindFirstChild("Scoreboard")
	timeline = details:FindFirstChild("Timeline")
	peformance = details:FindFirstChild("Peformance") or details:FindFirstChild("Performance")
	filters = details:FindFirstChild("Filters")
	local scoreboardMain = scoreboard and scoreboard:FindFirstChild("Main")
	local main = scoreboardMain and scoreboardMain:FindFirstChild("Main")
	template = main and main:FindFirstChild("Template")
	local eventLog = timeline and timeline:FindFirstChild("EventLog")
	template2 = eventLog and eventLog:FindFirstChild("Template")
	local player = timeline and timeline:FindFirstChild("Player")
	template3 = player and player:FindFirstChild("Template")
	local peformanceFrame = peformance and peformance:FindFirstChild("Frame")
	template4 = peformanceFrame and peformanceFrame:FindFirstChild("Template")
	detailTemplate = peformanceFrame and peformanceFrame:FindFirstChild("DetailTemplate")
	fightTemplate = detailTemplate and detailTemplate:FindFirstChild("FightTemplate")
	local v11 = { template, template2, template3, template4, detailTemplate, fightTemplate }

	for _, guiObject in ipairs(v11) do
		if guiObject and guiObject:IsA("GuiObject") then
			guiObject.Visible = false
		end
	end

	if filters then
		for _, button in ipairs(filters:GetChildren()) do
			if not button:IsA("GuiButton") then
				continue
			end

			local name = button.Name
			ActivateButton(button)
			button.Activated:Connect(function()
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				SelectTab(name)
			end)
		end
	end

	local close = details:FindFirstChild("Close")

	if close and close:IsA("GuiButton") then
		ActivateButton(close)
		close.Activated:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			MatchDetails.Close()
		end)
	end

	local resultsRow = GetResultsRow(1) -- inferred equivalent call

	if resultsRow then
		positionsByName[resultsRow.Name] = resultsRow.Position
	end

	local resultsRow2 = GetResultsRow(2) -- inferred equivalent call

	if resultsRow2 then
		positionsByName[resultsRow2.Name] = resultsRow2.Position
	end

	BindColumnHeadings()
	BindRoundButtons()
	BindRoundArrows()
	CareerData.MatchLoaded:Connect(function(p)
		if not MatchDetails.IsOpen() or v5 == nil or p.MatchId ~= v5.MatchId then
			return
		end

		v7 = not (#p.Rounds > 0) and 1 or p.Rounds[1].Round

		if v6 == "Timeline" then
			RenderTimeline()
		elseif v6 == "Performance" then
			RenderPerformance()
		end
	end)
	details.Visible = false
end

function MatchDetails.Open(p)
	if not details then
		return
	end

	v5 = p
	v7 = 1
	table.clear(v8)
	PopulateHeader(p)
	PopulateScoreboard(p)
	SelectTab("Scoreboard")
	CareerData.RequestMatchDetails(p.MatchId)

	if v4 then
		v4.Visible = true
	end

	details.Visible = true
end

function MatchDetails.Close()
	if details then
		details.Visible = false
	end

	if v4 then
		v4.Visible = false
	end

	v5 = nil
end

function MatchDetails.IsOpen()
	return details ~= nil and details.Visible
end

return MatchDetails