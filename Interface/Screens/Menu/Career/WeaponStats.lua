local WeaponStats = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
require(script.Parent.Types)
local Format = require(script.Parent.Format)
local Derive = require(script.Parent.Derive)
local Selection = require(script.Parent.Selection)
local CareerData = require(script.Parent.CareerData)
local WeaponIcon = require(script.Parent.WeaponIcon)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Router = require(ReplicatedStorage.Database.Security.Router)
local WeaponCategories = require(ReplicatedStorage.Database.Custom.GameStats.WeaponCategories)
local frozen = table.freeze({ "Kills", "AllKills", "DamagePerMatch", "KillsPerMatch" })
local frozen2 = table.freeze({ Weapon = true, Filter = true })
local frozen3 = table.freeze({
	Rifle = "Rifle",
	SMG = "SMG",
	Pistols = "Pistol",
	Shotguns = "Shotgun",
	Snipers = "Sniper",
	Melee = "Melee",
	Special = "Special"
})
local color = Color3.fromRGB(66, 66, 66)
local color2 = Color3.new(1, 1, 1)
local color3 = Color3.fromRGB(32, 32, 32)
local color4 = Color3.fromRGB(158, 158, 158)
local frozen4 = table.freeze({
	Kills = 0,
	Damage = 0,
	Matches = 0,
	RoundsPlayed = 0,
	RoundsWon = 0,
	RankedRoundsPlayed = 0,
	RankedRoundsWon = 0,
	CrouchKills = 0,
	JumpKills = 0,
	BlindKills = 0,
	CrouchDamage = 0,
	JumpDamage = 0,
	BlindDamage = 0,
	Assists = 0,
	DeadAssists = 0,
	ShotsFired = 0,
	ShotsHit = 0,
	HeadshotHits = 0,
	Reloads = 0,
	Inspects = 0
})
local container = nil
local filters = nil
local v = nil
local stats = nil
local statsContainer = nil
local template = nil
local templateDrop = nil
local v2 = "Allweapons"
local v3 = nil
local v4 = {}
local buttonsByChildName = {}
local clones = {}

local function RoundGroup(label: string, p: string, p2: string)
	return {
		Label = label,
		Read = function(p3)
			return Format.Number(p3[p])
		end,
		Children = {
			{
				Label = "ROUNDS WON",
				Read = function(p3)
					return Format.Number(p3[p2])
				end
			},
			{
				Label = "ROUNDS LOST",
				Read = function(p3)
					return Format.Number((math.max(p3[p] - p3[p2], 0)))
				end
			},
			{
				Label = "WIN %",
				Read = function(p3)
					return Format.Percent(p3[p2], p3[p], 1)
				end
			}
		}
	}
end

local v5 = {
	RoundGroup("ROUNDS PLAYED", "RoundsPlayed", "RoundsWon"),
	RoundGroup("RANKED ROUNDS PLAYED", "RankedRoundsPlayed", "RankedRoundsWon"),
	{
		Label = "KILLS",
		Read = function(p)
			return Format.Number(p.Kills)
		end,
		Children = {
			{
				Label = "WHILE CROUCHING",
				Read = function(p)
					return Format.Number(p.CrouchKills)
				end
			},
			{
				Label = "WHILE JUMPING",
				Read = function(p)
					return Format.Number(p.JumpKills)
				end
			},
			{
				Label = "WHILE BLIND",
				Read = function(p)
					return Format.Number(p.BlindKills)
				end
			}
		}
	},
	{
		Label = "DAMAGE DEALT",
		Read = function(p)
			return Format.Number(p.Damage)
		end,
		Children = {
			{
				Label = "WHILE CROUCHING",
				Read = function(p)
					return Format.Number(p.CrouchDamage)
				end
			},
			{
				Label = "WHILE JUMPING",
				Read = function(p)
					return Format.Number(p.JumpDamage)
				end
			},
			{
				Label = "WHILE BLIND",
				Read = function(p)
					return Format.Number(p.BlindDamage)
				end
			}
		}
	},
	{
		Label = "ASSISTS",
		Read = function(p)
			return Format.Number(p.Assists)
		end,
		Children = {
			{
				Label = "WHILE DEAD",
				Read = function(p)
					return Format.Number(p.DeadAssists)
				end
			}
		}
	},
	{
		Label = "BULLETS SHOT",
		Read = function(p)
			return Format.Number(p.ShotsFired)
		end,
		Children = {
			{
				Label = "HITS",
				Read = function(p)
					return Format.Number(p.ShotsHit)
				end
			},
			{
				Label = "HIT %",
				Read = function(p)
					return Format.Percent(p.ShotsHit, p.ShotsFired, 1)
				end
			},
			{
				Label = "HEADSHOTS",
				Read = function(p)
					return Format.Number(p.HeadshotHits)
				end
			},
			{
				Label = "HEADSHOT %",
				Read = function(p)
					return Format.Percent(p.HeadshotHits, p.ShotsHit, 1)
				end
			}
		}
	},
	{
		Label = "INSPECTS",
		Read = function(p)
			return Format.Number(p.Inspects)
		end,
		Children = {}
	},
	{
		Label = "RELOADS",
		Read = function(p)
			return Format.Number(p.Reloads)
		end,
		Children = {}
	}
}

local function GetWeapon(p: string?) -- 1 equivalent call inferred from this helper
	if p then
		return CareerData.GetBucket(Selection.Get()).Weapons[p] or frozen4
	end

	return frozen4
end

local function GetWeaponOrder(bucket)
	local clone = table.clone(WeaponCategories.GetWeapons())
	local v6 = {}

	for _, v7 in ipairs(clone) do
		v6[v7] = true
	end

	local v7 = {}

	for k, weapon in pairs(bucket.Weapons) do
		if v6[k] or not (weapon.Kills > 0 or weapon.Damage > 0) then
			continue
		end

		table.insert(v7, k)
	end

	table.sort(v7)

	for _, v8 in ipairs(v7) do
		table.insert(clone, v8)
	end

	return clone
end

local function NameStatColumns(frame)
	local labels = {}

	for _, label in ipairs(frame:GetChildren()) do
		if not label:IsA("TextLabel") or frozen2[label.Name] then
			continue
		end

		table.insert(labels, label)
	end

	if #labels ~= #frozen then
		return
	end

	table.sort(labels, function(a, b)
		return a.Position.X.Scale < b.Position.X.Scale
	end)

	for i, v6 in ipairs(labels) do
		v6.Name = frozen[i]
	end
end

local function SetColumn(clone, childName: string, text: string) -- 8 equivalent calls inferred from this helper
	local label = clone:FindFirstChild(childName)

	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function PaintRow(p, flag: boolean) -- 2 equivalent calls inferred from this helper
	local backgroundColor

	if flag then
		backgroundColor = color
	else
		backgroundColor = color3
	end

	p.BackgroundColor3 = backgroundColor
	p.BackgroundTransparency = flag and 0.05 or 0.3
end

local function AddStatRow(instance, label: string, text: string, layoutOrder: number) -- 2 equivalent calls inferred from this helper
	local clone = instance:Clone()
	clone.Name = `Stat_{layoutOrder}`
	clone.LayoutOrder = layoutOrder
	clone.Visible = true
	SetColumn(clone, "SelectedOptionText", label) -- inferred equivalent call
	SetColumn(clone, "KillsPerMatch", text) -- inferred equivalent call
	clone.Parent = statsContainer
	return clone
end

local function ClearStatRows()
	for _, child in ipairs(statsContainer:GetChildren()) do
		if string.sub(child.Name, 1, 5) == "Stat_" then
			child:Destroy()
		end
	end
end

local function RenderStats()
	if not (statsContainer and template and templateDrop) then
		return
	end

	ClearStatRows()
	local v6 = v3
	local weapon = GetWeapon(v6) -- inferred equivalent call
	local title = stats and stats:FindFirstChild("Title")
	local title2 = title and title:FindFirstChild("Title")

	if title2 then
		title2.Text = not v6 and "STATS" or `{string.upper(v6)} STATS`
	end

	local empty = statsContainer:FindFirstChild("Empty")

	if empty and empty:IsA("GuiObject") then
		empty.Visible = v6 == nil
	end

	if not v6 then
		return
	end

	local count = 0

	for _, v7 in ipairs(v5) do
		count += 1
		local visible = #v7.Children > 0
		local visible2 = visible and v4[v7.Label] == true
		local button = AddStatRow(templateDrop, v7.Label, v7.Read(weapon), count) -- inferred equivalent call
		local imageLabel = button:FindFirstChildWhichIsA("ImageLabel")

		if imageLabel then
			imageLabel.Visible = visible
			imageLabel.Rotation = visible2 and 0 or 180
		end

		if not visible then
			continue
		end

		for _, v8 in ipairs(v7.Children) do
			count += 1
			local addStatRow = AddStatRow(template, v8.Label, v8.Read(weapon), count) -- inferred equivalent call
			addStatRow.Visible = visible2
		end

		if not button:IsA("GuiButton") then
			continue
		end

		button.Active = true
		button.Selectable = true
		ActivateButton(button)
		local label = v7.Label
		button.Activated:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			v4[label] = v4[label] ~= true
			RenderStats()
		end)
	end
end

local function SelectWeapon(p: string) -- 2 equivalent calls inferred from this helper
	if v3 == p then
		return
	end

	local v6 = v3 and clones[v3]

	if v6 then
		v6.BackgroundColor3 = color3
		v6.BackgroundTransparency = 0.3
	end

	v3 = p
	local v7 = clones[p]

	if v7 then
		v7.BackgroundColor3 = color
		v7.BackgroundTransparency = 0.05
	end

	RenderStats()
end

local function FocusSelectedRow()
	if not UserInputService.GamepadEnabled or MenuState.IsNavigationSelectionHeld() then
		return
	end

	local v6 = v3

	if not v6 then
		return
	end

	local v7 = clones[v6]

	if not v7 then
		return
	end

	local hitbox = v7:FindFirstChild("Hitbox")

	if hitbox and hitbox:IsA("GuiButton") and hitbox.Selectable then
		GuiService.SelectedObject = hitbox
	end
end

local function BindRowSelection(clone, value: string)
	local function selectWeapon()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		SelectWeapon(value) -- inferred equivalent call
	end

	local hitbox = clone:FindFirstChild("Hitbox")
	local details = clone:FindFirstChild("Details")
	local v6 = nil

	if hitbox and hitbox:IsA("GuiButton") then
		v6 = hitbox
	elseif details and details:IsA("GuiButton") then
		v6 = details
	end

	if v6 then
		v6.Active = true
		v6.Selectable = true
		ActivateButton(v6)
		v6.Activated:Connect(selectWeapon)
	end

	if details and details:IsA("GuiButton") and details ~= v6 then
		details.Selectable = false
		details.Active = true
		ActivateButton(details)
		details.Activated:Connect(selectWeapon)
	end
end

local function CreateRow(value: string, data, kills: number, layoutOrder: number)
	local clone = v:Clone()
	clone.Name = `Weapon_{value}`
	clone.LayoutOrder = layoutOrder
	clone.Visible = true
	local itemIcon = clone:FindFirstChild("ItemIcon")

	if itemIcon then
		itemIcon.Image = WeaponIcon.Get(value)
	end

	local v6 = math.max(data.Matches, 0)
	SetColumn(clone, "Weapon", string.upper(value)) -- inferred equivalent call
	SetColumn(clone, "Filter", WeaponCategories.GetLabel(value)) -- inferred equivalent call
	SetColumn(clone, "Kills", Format.Number(data.Kills)) -- inferred equivalent call
	SetColumn(clone, "AllKills", Format.Percent(data.Kills, kills, 1)) -- inferred equivalent call
	SetColumn(clone, "DamagePerMatch", Format.Number((math.round((Derive.Divide(data.Damage, v6)))))) -- inferred equivalent call
	SetColumn(clone, "KillsPerMatch", Format.Decimal(Derive.Divide(data.Kills, v6), 1)) -- inferred equivalent call
	BindRowSelection(clone, value)
	PaintRow(clone, v3 == value) -- inferred equivalent call
	clones[value] = clone
	clone.Parent = container
end

local function ClearRows()
	table.clear(clones)

	for _, frame in ipairs(container:GetChildren()) do
		if not (frame:IsA("Frame") and string.sub(frame.Name, 1, 7) == "Weapon_") then
			continue
		end

		frame:Destroy()
	end
end

local function UpdateFilterButtons()
	for k, v6 in pairs(buttonsByChildName) do
		local v7 = k == v2
		PaintRow(v6, v7) -- inferred equivalent call
		local selectedOptionText = v6:FindFirstChild("SelectedOptionText")

		if not selectedOptionText then
			continue
		end

		local textColor

		if v7 then
			textColor = color2
		else
			textColor = color4
		end

		selectedOptionText.TextColor3 = textColor
	end
end

local function RenderRows()
	if not (container and v) then
		return
	end

	ClearRows()
	local bucket = CareerData.GetBucket(Selection.Get())
	local v6 = frozen3[v2]
	local kills = bucket.Kills

	if kills <= 0 then
		for _, weapon in pairs(bucket.Weapons) do
			kills += weapon.Kills
		end
	end

	local count = 0
	local v7 = nil

	for _, v8 in ipairs((GetWeaponOrder(bucket))) do
		if not (not v6 or WeaponCategories.GetCategory(v8) == v6) then
			continue
		end

		count += 1
		CreateRow(v8, bucket.Weapons[v8] or frozen4, kills, count)
		v7 = v7 or v8
	end

	if v3 == nil or not clones[v3] then
		v3 = nil

		if v7 then
			SelectWeapon(v7) -- inferred equivalent call
			FocusSelectedRow()
			return
		end
	end

	RenderStats()
	FocusSelectedRow()
end

local function SelectFilter(p: string) -- 1 equivalent call inferred from this helper
	if v2 == p then
		return
	end

	v2 = p
	UpdateFilterButtons()
	RenderRows()
end

function WeaponStats.Bind(instance)
	local weaponStats = instance:FindFirstChild("WeaponStats")

	if not weaponStats then
		return
	end

	container = weaponStats:FindFirstChild("Container")
	filters = weaponStats:FindFirstChild("Filters")

	if not (container and filters) then
		return
	end

	for _, frame in ipairs(container:GetChildren()) do
		if not (frame:IsA("Frame") and frame.Name == "Template") then
			continue
		end

		if v then
			frame:Destroy()
		else
			v = frame
			frame.Visible = false
			NameStatColumns(frame)
		end
	end

	stats = instance:FindFirstChild("Stats")
	statsContainer = stats and stats:FindFirstChild("Container")

	if statsContainer then
		template = statsContainer:FindFirstChild("Template")
		templateDrop = statsContainer:FindFirstChild("TemplateDrop")

		if template then
			template.Visible = false
		end

		if templateDrop then
			templateDrop.Visible = false
		end
	end

	for childName in pairs(frozen3) do
		local button = filters:FindFirstChild(childName)

		if button and button:IsA("GuiButton") then
			buttonsByChildName[childName] = button
		end
	end

	local allweapons = filters:FindFirstChild("Allweapons")

	if allweapons and allweapons:IsA("GuiButton") then
		buttonsByChildName.Allweapons = allweapons
	end

	for k, v6 in pairs(buttonsByChildName) do
		ActivateButton(v6)
		v6.Selectable = true
		local v7 = k
		v6.Activated:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			SelectFilter(v7) -- inferred equivalent call
		end)
	end

	UpdateFilterButtons()
end

function WeaponStats.Render()
	RenderRows()
end

return WeaponStats