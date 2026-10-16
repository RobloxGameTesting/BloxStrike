local KillFeed = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
require(script:WaitForChild("Types"))
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local udim = UDim2.new(0.99, 0, 0.18, 0)
local udim2 = UDim2.new(0.99, 0, 0.068, 0)
local udim3 = UDim.new(0, 5)
local color = Color3.fromRGB(255, 0, 0)
local color2 = Color3.fromRGB(165, 183, 212)
local color3 = Color3.fromRGB(219, 199, 126)
local color4 = Color3.fromRGB(255, 255, 255)
local LocalPlayer = Players.LocalPlayer
local parent = nil
local v = {}
local v2 = {
	[2] = "got a Multi Kill",
	[3] = "is on a Killing Spree",
	[4] = "is on a Rampage",
	[5] = "is Dominating",
	[6] = "got a M-M-Monster Kill",
	[7] = "is going Ludicrus",
	[8] = "is Unstoppable",
	[9] = "is Godlike"
}
local v3 = {
	"Weapon",
	"Headshot",
	"NoScope",
	"Smoke",
	"Wallbang",
	"Blind",
	"Jump",
	"FlashAssist",
	"Addition",
	"Assistor",
	"Enemy"
}

local function applyParticipantLabel(p, p2, instance, p3: number) -- 1 equivalent call inferred from this helper
	local team = instance:GetAttribute("Team")
	p2.Text = Participants.DisplayName(instance)
	p2.Visible = true

	if LocalPlayer.UserId == p3 then
		p.UIStroke.Color = color
	end

	if team == "Counter-Terrorists" then
		p2.TextColor3 = color2
	elseif team == "Terrorists" then
		p2.TextColor3 = color3
	end
end

local function convertTextLabel(p, p2, p3: number?)
	if not p3 then
		return
	end

	local v4 = Participants.FromKey(p3)

	if v4 and v4.Parent then
		applyParticipantLabel(p, p2, v4, p3) -- inferred equivalent call
	else
		p2.Visible = false
	end
end

local function applyContentPadding(contents) -- 2 equivalent calls inferred from this helper
	local v4 = contents:FindFirstChild("UIPadding")

	if not v4 then
		v4 = Instance.new("UIPadding")
		v4.Parent = contents
	end

	v4.PaddingLeft = udim3
	v4.PaddingRight = udim3
end

local function scheduleFadeOut(clone) -- 2 equivalent calls inferred from this helper
	task.delay(5, function()
		TweenService:Create(clone, TweenInfo.new(1), { GroupTransparency = 1 }):Play()
		TweenService:Create(clone.UIStroke, TweenInfo.new(1), { Transparency = 1 }):Play()
		Debris:AddItem(clone, 1)
	end)
end

local function createStreakTemplate(p: number, text: string)
	local clone = ReplicatedStorage.Assets.UI.KillFeed.Kill:Clone()
	local contents = clone.Contents

	for _, v4 in ipairs(v3) do
		contents[v4].Visible = false
	end

	applyContentPadding(contents) -- inferred equivalent call
	local player = contents.Player
	local v4 = Participants.FromKey(p)

	if not (v4 and v4.Parent) then
		Debris:AddItem(clone, 0)
		return
	end

	local team = v4:GetAttribute("Team")
	player.Text = Participants.DisplayName(v4)
	player.Visible = true

	if LocalPlayer.UserId == p then
		clone.UIStroke.Color = color
	end

	if team == "Counter-Terrorists" then
		player.TextColor3 = color2
	elseif team == "Terrorists" then
		player.TextColor3 = color3
	end

	local enemy = contents.Enemy
	enemy.Text = text
	enemy.TextColor3 = color4
	enemy.Visible = true
	player.LayoutOrder = 0
	enemy.LayoutOrder = 1
	clone.Visible = true
	clone.Parent = parent
	scheduleFadeOut(clone) -- inferred equivalent call
end

function KillFeed.createTemplate(data)
	local module = require(ReplicatedStorage.Database.Custom.Weapons[data.Weapon])
	parent.Visible = true
	local clone = ReplicatedStorage.Assets.UI.KillFeed.Kill:Clone()
	applyContentPadding(clone.Contents) -- inferred equivalent call
	local player = clone.Contents.Player
	local killer = tonumber(data.Killer)

	if killer then
		local v4 = Participants.FromKey(killer)

		if v4 and v4.Parent then
			local team = v4:GetAttribute("Team")
			player.Text = Participants.DisplayName(v4)
			player.Visible = true

			if LocalPlayer.UserId == killer then
				clone.UIStroke.Color = color
			end

			if team == "Counter-Terrorists" then
				player.TextColor3 = color2
			elseif team == "Terrorists" then
				player.TextColor3 = color3
			end
		else
			player.Visible = false
		end
	end

	local enemy = clone.Contents.Enemy
	local victim = tonumber(data.Victim)

	if victim then
		local v4 = Participants.FromKey(victim)

		if v4 and v4.Parent then
			local team = v4:GetAttribute("Team")
			enemy.Text = Participants.DisplayName(v4)
			enemy.Visible = true

			if LocalPlayer.UserId == victim then
				clone.UIStroke.Color = color
			end

			if team == "Counter-Terrorists" then
				enemy.TextColor3 = color2
			elseif team == "Terrorists" then
				enemy.TextColor3 = color3
			end
		else
			enemy.Visible = false
		end
	end

	if data.Assistor then
		local assistor = clone.Contents.Assistor
		local assistor2 = tonumber(data.Assistor)

		if assistor2 then
			local v4 = Participants.FromKey(assistor2)

			if v4 and v4.Parent then
				local team = v4:GetAttribute("Team")
				assistor.Text = Participants.DisplayName(v4)
				assistor.Visible = true

				if LocalPlayer.UserId == assistor2 then
					clone.UIStroke.Color = color
				end

				if team == "Counter-Terrorists" then
					assistor.TextColor3 = color2
				elseif team == "Terrorists" then
					assistor.TextColor3 = color3
				end
			else
				assistor.Visible = false
			end
		end

		clone.Contents.Addition.Visible = true
		clone.Contents.FlashAssist.Visible = data.FlashAssist == true
	else
		clone.Contents.Assistor.Visible = false
		clone.Contents.Addition.Visible = false
		clone.Contents.FlashAssist.Visible = false
	end

	clone.Contents.Weapon.Image = module.ReverseIcon
	clone.Contents.Headshot.Visible = data.Headshot
	clone.Contents.NoScope.Visible = data.NoScope == true
	clone.Contents.Smoke.Visible = data.Smoke == true
	clone.Contents.Blind.Visible = data.Blind == true
	clone.Contents.Wallbang.Visible = data.Wallbang == true
	clone.Contents.Jump.Visible = data.Jump == true

	local function updateIconSizes()
		local player2 = clone.Contents.Player

		if player2 and player2.AbsoluteSize.Y > 0 then
			local v4 = player2.AbsoluteSize.Y * 0.84 * 1.67
			clone.Contents.Headshot.Size = UDim2.new(0, v4, 0, v4)
			clone.Contents.NoScope.Size = UDim2.new(0, v4 * (5 / 6), 0, v4 * (5 / 6))
			clone.Contents.Smoke.Size = UDim2.new(0, v4 * (10 / 9), 0, v4 * (7 / 9))
			clone.Contents.Wallbang.Size = UDim2.new(0, v4 * (10 / 9), 0, v4 * (10 / 9))
			clone.Contents.Blind.Size = UDim2.new(0, v4 * (5 / 6), 0, v4 * (5 / 6))
			clone.Contents.Jump.Size = UDim2.new(0, v4, 0, v4)
			clone.Contents.FlashAssist.Size = UDim2.new(0, v4, 0, v4)
		end
	end

	clone.Contents:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateIconSizes)
	local contents = clone.Contents
	local count = 0

	local function placeNext(p) -- 8 equivalent calls inferred from this helper
		p.LayoutOrder = count
		count += 1
	end

	if data.Blind == true then
		placeNext(contents.Blind) -- inferred equivalent call
	end

	placeNext(contents.Player) -- inferred equivalent call

	if data.Assistor then
		placeNext(contents.Addition) -- inferred equivalent call

		if data.FlashAssist == true then
			placeNext(contents.FlashAssist) -- inferred equivalent call
		end

		placeNext(contents.Assistor) -- inferred equivalent call
	end

	if data.Jump == true then
		placeNext(contents.Jump) -- inferred equivalent call
	end

	placeNext(contents.Weapon) -- inferred equivalent call

	for _, v4 in ipairs({ "NoScope", "Smoke", "Wallbang", "Headshot" }) do
		if data[v4] == true then
			placeNext(contents[v4]) -- inferred equivalent call
		end
	end

	contents.Enemy.LayoutOrder = count
	clone.Visible = true
	clone.Parent = parent
	scheduleFadeOut(clone) -- inferred equivalent call
end

function KillFeed.Initialize(_, p)
	parent = p
	local v4 = table.find(GetUserPlatform(), "Mobile") ~= nil
	local v5 = parent
	local position

	if v4 then
		position = udim
	else
		position = udim2
	end

	v5.Position = position
	local kill = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("KillFeed"):WaitForChild("Kill")
	kill.AutoLocalize = false

	for _, guiBase2d in kill:GetDescendants() do
		if guiBase2d:IsA("GuiBase2d") then
			guiBase2d.AutoLocalize = false
		end
	end

	Remotes.UI.UIPlayerKilled.Listen(function(data)
		local v6 = nil

		if workspace:GetAttribute("Gamemode") == "Deathmatch" then
			local killer = data.Killer
			local victim = data.Victim
			v[victim] = 0

			if killer ~= victim and tonumber(killer) ~= -1 then
				local v7 = (v[killer] or 0) + 1
				v[killer] = v7
				v6 = v2[math.min(v7, 9)]
			end
		end

		local success, result = pcall(KillFeed.createTemplate, data)

		if not success then
			warn(`[KillFeed] could not draw {data.Killer} -> {data.Victim} ({data.Weapon}): {result}`)
		end

		if v6 then
			local success2, result2 = pcall(createStreakTemplate, tonumber(data.Killer), v6)

			if not success2 then
				warn(`[KillFeed] could not draw streak for {data.Killer}: {result2}`)
			end
		end
	end)
	GameState.ListenToState(function()
		table.clear(v)
	end)
	LocalPlayer.CharacterAdded:Connect(function()
		v[tostring(LocalPlayer.UserId)] = nil
	end)
end

return KillFeed