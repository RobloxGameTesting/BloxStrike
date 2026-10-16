local PlayerInfo = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local Colors = require(ReplicatedStorage.Database.Custom.GameStats.Settings.Colors)
require(ReplicatedStorage.Database.Custom.Types)
local tweenInfo = TweenInfo.new(0.66, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local v = { "Slot1", "Slot2", "Slot3" }
local v2 = {}
local v3 = {}
local grenadesByUserId = {}
local v4 = {}
local v5 = {}
local v6 = false
local LocalPlayer = Players.LocalPlayer

local function commaNumber(p: number) -- 1 equivalent call inferred from this helper
	return tostring(p):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function getItemProperties(childName: string, childName2: string)
	local folder = ReplicatedStorage.Database.Custom:FindFirstChild(childName)
		or ReplicatedStorage.Database.Custom.GameStats:FindFirstChild(childName)

	if not (folder and folder:IsA("Folder")) then
		return nil
	end

	local moduleScript = folder:FindFirstChild(childName2)

	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end

	local success, result = pcall(require, moduleScript)

	if success and result then
		return result
	end

	return nil
end

local function playerHasBomb(instance) -- 2 equivalent calls inferred from this helper
	local slot5 = instance:GetAttribute("Slot5")

	if not slot5 then
		return false
	end

	local jsonDecode = HttpService:JSONDecode(slot5)
	return jsonDecode and jsonDecode.Weapon == "C4"
end

local function decodeTableAttribute(json)
	if typeof(json) ~= "string" or json == "" then
		return nil
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(json)
	end)

	if success and typeof(result) == "table" then
		return result
	end

	return nil
end

local function parseArmorAttribute(armor) -- 2 equivalent calls inferred from this helper
	local result

	if typeof(armor) == "string" and armor ~= "" then
		local success
		success, result = pcall(function()
			return HttpService:JSONDecode(armor)
		end)

		if not success or typeof(result) ~= "table" then
			result = nil
		end
	end

	if result then
		return {
			Type = tostring(result.Type) or "",
			Health = tonumber(result.Health) or 0
		}
	end

	return nil
end

local function getWeaponNameFromSlotAttribute(json)
	local result

	if typeof(json) == "string" and json ~= "" then
		local success
		success, result = pcall(function()
			return HttpService:JSONDecode(json)
		end)

		if not success or typeof(result) ~= "table" then
			result = nil
		end
	end

	local weapon = result and result.Weapon

	if typeof(weapon) == "string" and weapon ~= "" then
		return weapon
	end

	return nil
end

local function setChildVisible(instance, childName: string, visible: boolean) -- 9 equivalent calls inferred from this helper
	local child = instance and instance:FindFirstChild(childName)

	if child then
		child.Visible = visible
	end
end

local function getTemplateHealthParts(instance) -- 3 equivalent calls inferred from this helper
	local health = instance:FindFirstChild("Health")
	return health, health and health:FindFirstChild("Bar")
end

local function setTemplateLifeState(instance, flag: boolean)
	local templateHealthParts, v7 = getTemplateHealthParts(instance) -- inferred equivalent call
	local playerBackground = instance:FindFirstChild("PlayerBackground")
	local player = playerBackground and playerBackground:FindFirstChild("Player")
	local x = player and player:FindFirstChild("X")
	local info = instance:FindFirstChild("Info")

	if flag then
		if v7 then
			v7.Size = UDim2.fromScale(0, 1)
		end

		if templateHealthParts then
			templateHealthParts.Visible = false
		end

		if player then
			player.ImageTransparency = 0.5
		end

		if x then
			x.Visible = true
		end

		if info then
			info.BackgroundTransparency = 0.75
			setChildVisible(info, "Weapon", false) -- inferred equivalent call
			setChildVisible(info, "Grenades", false) -- inferred equivalent call
			setChildVisible(info, "Items", false) -- inferred equivalent call
		end

		if playerBackground then
			playerBackground.Transparency = 0.5
			return templateHealthParts, v7
		end
	else
		if player then
			player.ImageTransparency = 0
		end

		if x then
			x.Visible = false
		end

		if info then
			info.BackgroundTransparency = 0
		end

		if playerBackground then
			playerBackground.Transparency = 0
		end
	end

	return templateHealthParts, v7
end

local function updateTemplateGrenades(instance, p: number)
	local info = instance:FindFirstChild("Info")

	if not info then
		return
	end

	local grenades = info:FindFirstChild("Grenades")

	if not grenades then
		return
	end

	local v7 = grenadesByUserId[p] or {}

	for i = 1, 4 do
		local child = grenades:FindFirstChild((tostring(i)))

		if not child then
			continue
		end

		local v8 = v7[i]

		if v8 then
			local itemProperties = getItemProperties("Weapons", v8)
			child.Image = itemProperties and itemProperties.Icon or ""
			child.Visible = true
		else
			child.Image = ""
			child.Visible = false
		end
	end

	grenades.Visible = true
end

local function isTeammate(instance) -- 6 equivalent calls inferred from this helper
	local team = LocalPlayer:GetAttribute("Team")

	if team then
		return team == instance:GetAttribute("Team")
	end

	return false
end

local function summarizeDamageArray(list)
	if not list or #list == 0 then
		return nil, nil
	end

	local v7 = #list
	local total = 0

	for _, v8 in list do
		total += v8
	end

	return total, v7
end

local function setDamageLabel(p, p2: number?, p3: number?) -- 2 equivalent calls inferred from this helper
	if not p then
		return
	end

	p.Text = not p2 and "" or `{math.min(p2, 100)} in {p3}`
	p.Visible = p2 ~= nil
end

local function updateDamageFromMatrix(instance, list, list2)
	if not (instance and instance.Parent) then
		return
	end

	local info = instance:FindFirstChild("Info")

	if not info then
		return
	end

	local damages = info:FindFirstChild("Damages")

	if not damages then
		return
	end

	local v7, v8

	if list and #list ~= 0 then
		v7 = #list
		v8 = 0

		for _, v9 in list do
			v8 += v9
		end
	end

	local v9, v10

	if list2 and #list2 ~= 0 then
		v9 = #list2
		v10 = 0

		for _, v11 in list2 do
			v10 += v11
		end
	end

	damages.Visible = v8 ~= nil or v10 ~= nil
	setDamageLabel(damages:FindFirstChild("Outgoing"), v8, v7) -- inferred equivalent call
	setDamageLabel(damages:FindFirstChild("Incoming"), v10, v9) -- inferred equivalent call
end

local function setTemplateKills(instance, p: number)
	local kills = instance:FindFirstChild("Kills")

	if not kills then
		return
	end

	for i = 1, 5 do
		local child = kills:FindFirstChild((tostring(i)))

		if child then
			child.Visible = i <= p
		end
	end
end

local function hideTeammateOnlyInfo(instance)
	setChildVisible(instance, "DefuseKit", false) -- inferred equivalent call
	setChildVisible(instance, "Bomb", false) -- inferred equivalent call
	local info = instance:FindFirstChild("Info")

	for _, v7 in ipairs({ "Weapon", "Cash", "Items", "Grenades" }) do
		setChildVisible(info, v7, false) -- inferred equivalent call
	end
end

local function getCompetitiveStroke(instance) -- 2 equivalent calls inferred from this helper
	local playerBackground = instance:FindFirstChild("PlayerBackground")
	return playerBackground and playerBackground:FindFirstChildOfClass("UIStroke")
end

local function ensureDefaultStrokeColor(competitiveStroke) -- 1 equivalent call inferred from this helper
	local defaultStrokeColor = competitiveStroke:GetAttribute("DefaultStrokeColor")

	if not defaultStrokeColor then
		defaultStrokeColor = competitiveStroke.Color
		competitiveStroke:SetAttribute("DefaultStrokeColor", defaultStrokeColor)
	end

	return defaultStrokeColor or competitiveStroke.Color
end

local function refreshCompetitiveStrokeColorForPlayer(instance)
	local v7 = v2[Participants.Key(instance)]

	if not (v7 and v7.Parent) then
		return
	end

	local competitiveStroke = getCompetitiveStroke(v7) -- inferred equivalent call

	if not competitiveStroke then
		return
	end

	local defaultStrokeColor = ensureDefaultStrokeColor(competitiveStroke) -- inferred equivalent call

	if isTeammate(instance) then -- inferred equivalent call
		competitiveStroke.Color = instance:GetAttribute("CompetitivePlayerColor") or defaultStrokeColor
	else
		competitiveStroke.Color = defaultStrokeColor
	end
end

local function shouldShowInfoForPlayer(instance)
	if workspace:GetAttribute("Gamemode") == "Deathmatch" then
		return true
	end

	if workspace:GetAttribute("GameState") == "Warmup" or not v6 then
		return false
	end

	if isTeammate(instance) then -- inferred equivalent call
		return true
	end

	local v7 = v4[Participants.Key(instance)] or 0
	local v8 = v5[Participants.Key(instance)] == true
	return v7 > 0 or v8
end

local function setTemplateInfoRevealed(instance, instance2, flag: boolean)
	if not (instance2 and instance2.Parent) then
		return
	end

	local info = instance2:FindFirstChild("Info")

	if not info then
		return
	end

	local formatted = `{flag}|{isTeammate(instance)}|{not Participants.IsAlive(instance)}|{instance:GetAttribute("IsSpectating") == true}` -- inferred equivalent call

	if info:GetAttribute("RevealKey") == formatted then
		return
	end

	info:SetAttribute("RevealKey", formatted)
	local maid = v3[info]

	if maid then
		maid:Cleanup()
	else
		maid = Janitor.new()
		maid:LinkToInstance(instance2)
		v3[info] = maid
	end

	local originalSize = info:GetAttribute("OriginalSize")

	if not originalSize then
		originalSize = info.Size
		info:SetAttribute("OriginalSize", originalSize)

		if not flag then
			info.Size = UDim2.fromScale(1, 0)
		end
	end

	if flag then
		if isTeammate(instance) then -- inferred equivalent call
			local isSpectating = instance:GetAttribute("IsSpectating") == true
			local visible = Participants.IsAlive(instance) and not isSpectating
			local weapon = info:FindFirstChild("Weapon")

			if weapon then
				local function updateEquippedWeaponImageFromSlots()
					local weapon2 = nil

					for _, attributeName in ipairs(v) do
						local attribute = instance:GetAttribute(attributeName)
						local result

						if typeof(attribute) == "string" and attribute ~= "" then
							local success
							success, result = pcall(function()
								return HttpService:JSONDecode(attribute)
							end)

							if not success or typeof(result) ~= "table" then
								result = nil
							end
						end

						weapon2 = result and result.Weapon

						if typeof(weapon2) ~= "string" or weapon2 == "" then
							weapon2 = nil
						end

						if weapon2 then
							break
						end
					end

					local v7 = weapon2 and getItemProperties("Weapons", weapon2)
					weapon.Image = v7 and v7.Icon or ""
				end

				for _, v7 in ipairs(v) do
					maid:Add(instance:GetAttributeChangedSignal(v7):Connect(updateEquippedWeaponImageFromSlots))
				end

				updateEquippedWeaponImageFromSlots()
				weapon.Visible = visible
			end

			local cash = info:FindFirstChild("Cash")

			if cash then
				maid:Add(Observers.observeAttribute(instance, "Money", function(p)
					cash.Text = p and `${commaNumber(p)}` or "" -- inferred equivalent call
					return nil
				end))
				cash.Visible = true
			end

			local items = info:FindFirstChild("Items")

			if items then
				local armor = items:FindFirstChild("Armor")

				if armor then
					local function updateArmor()
						local armorAttribute = parseArmorAttribute(instance:GetAttribute("Armor")) -- inferred equivalent call
						armor.Visible = armorAttribute ~= nil and armorAttribute.Health > 0
					end

					maid:Add(instance:GetAttributeChangedSignal("Armor"):Connect(updateArmor))
					local armorAttribute = parseArmorAttribute(instance:GetAttribute("Armor")) -- inferred equivalent call
					armor.Visible = armorAttribute ~= nil and armorAttribute.Health > 0
				end

				local bomb = items:FindFirstChild("Bomb")

				if bomb then
					maid:Add(instance:GetAttributeChangedSignal("Slot5"):Connect(function()
						bomb.Visible = playerHasBomb(instance) -- inferred equivalent call
					end))
					bomb.Visible = playerHasBomb(instance) -- inferred equivalent call
				end

				items.Visible = true
			end

			updateTemplateGrenades(instance2, Participants.Key(instance))
		else
			hideTeammateOnlyInfo(instance2)
		end

		info.Visible = true
		TweenService:Create(info, tweenInfo, { Size = originalSize }):Play()
	else
		local tween = TweenService:Create(info, tweenInfo, { Size = UDim2.fromScale(1, 0) })
		tween:Play()
		maid:Add(tween.Completed:Once(function(p)
			if p == Enum.PlaybackState.Completed then
				info.Visible = false
			end
		end))
	end
end

local function refreshTemplateInfoVisibilityForPlayer(instance) -- 2 equivalent calls inferred from this helper
	local v7 = v2[Participants.Key(instance)]

	if v7 and v7.Parent then
		setTemplateInfoRevealed(instance, v7, shouldShowInfoForPlayer(instance))
	end
end

local function refreshAllTemplateInfoVisibility()
	for k, v7 in v2 do
		local v8 = Participants.FromKey(k)

		if not (v8 and v7 and v7.Parent) then
			continue
		end

		local v9 = v2[Participants.Key(v8)]

		if v9 and v9.Parent then
			setTemplateInfoRevealed(v8, v9, shouldShowInfoForPlayer(v8))
		end
	end
end

local function setupBombDefusalTemplate(maid, clone, instance)
	local team = instance:GetAttribute("Team")
	local gamemode = workspace:GetAttribute("Gamemode")

	local function fn() end

	local function getPlayerHealthRatio() -- 2 equivalent calls inferred from this helper
		local health = instance:GetAttribute("Health")
		local maxHealth = instance:GetAttribute("MaxHealth")

		if typeof(health) == "number" and typeof(maxHealth) == "number" and not (maxHealth <= 0) then
			return (math.clamp(math.floor(health) / maxHealth, 0, 1))
		end

		return 0
	end

	local function updateHealthBar(flag: boolean)
		local templateHealthParts, v7 = getTemplateHealthParts(clone) -- inferred equivalent call

		if
			Participants.IsAlive(instance)
			and instance:GetAttribute("IsSpectating") ~= true
			and isTeammate(instance) -- inferred equivalent call
			and templateHealthParts
			and v7
		then
			templateHealthParts.Visible = true
			local udim = UDim2.fromScale(getPlayerHealthRatio(), 1) -- inferred equivalent call

			if flag then
				TweenService:Create(v7, TweenInfo.new(0.25), { Size = udim }):Play()
			else
				v7.Size = udim
			end
		end
	end

	local function updateLifeState()
		if not clone.Parent then
			return
		end

		local isSpectating = instance:GetAttribute("IsSpectating") == true
		local v7 = not Participants.IsAlive(instance) or isSpectating
		setTemplateLifeState(clone, v7)

		if not v7 and v6 then
			refreshTemplateInfoVisibilityForPlayer(instance) -- inferred equivalent call
		end

		local templateHealthParts, v8 = getTemplateHealthParts(clone) -- inferred equivalent call

		if
			Participants.IsAlive(instance)
			and instance:GetAttribute("IsSpectating") ~= true
			and isTeammate(instance) -- inferred equivalent call
			and templateHealthParts
			and v8
		then
			templateHealthParts.Visible = true
			v8.Size = UDim2.fromScale(getPlayerHealthRatio(), 1) -- inferred equivalent call
		end

		refreshCompetitiveStrokeColorForPlayer(instance)
		fn()
	end

	maid:Add(instance:GetAttributeChangedSignal("Health"):Connect(function()
		updateLifeState()
		updateHealthBar(true)
	end))
	maid:Add(instance:GetAttributeChangedSignal("MaxHealth"):Connect(updateLifeState))
	maid:Add(instance:GetAttributeChangedSignal("Dead"):Connect(updateLifeState))
	maid:Add(instance:GetAttributeChangedSignal("IsSpectating"):Connect(updateLifeState))
	maid:Add(instance:GetAttributeChangedSignal("CompetitivePlayerColor"):Connect(function()
		refreshCompetitiveStrokeColorForPlayer(instance)
	end))
	updateLifeState()

	if team == "Terrorists" then
		fn = function()
			local team2 = instance:GetAttribute("Team")
			local team3 = LocalPlayer:GetAttribute("Team")
			local jsonDecode = HttpService:JSONDecode(instance:GetAttribute("Slot5") or "[]")
			local bomb = clone:FindFirstChild("Bomb")

			if bomb then
				local isAlive = Participants.IsAlive(instance)

				if isAlive then
					if team2 == team3 then
						isAlive = jsonDecode and jsonDecode.Weapon == "C4"
					else
						isAlive = false
					end
				end

				bomb.Visible = isAlive
			end
		end

		maid:Add(Observers.observeAttribute(instance, "Slot5", function(_)
			fn()
			return function()
				setChildVisible(clone, "Bomb", false) -- inferred equivalent call
			end
		end))
		fn()
	elseif team == "Counter-Terrorists" then
		fn = function()
			local team2 = LocalPlayer:GetAttribute("Team")
			local team3 = instance:GetAttribute("Team")
			local v7

			if gamemode == "Hostage Rescue" then
				v7 = instance:GetAttribute("HasRescueKit") == true
			else
				v7 = instance:GetAttribute("HasDefuseKit") == true
			end

			local defuseKit = clone:FindFirstChild("DefuseKit")

			if defuseKit then
				defuseKit.Visible = Participants.IsAlive(instance) and v7 and team3 == team2
			end
		end

		local function hideObjectiveKits()
			setChildVisible(clone, "DefuseKit", false) -- inferred equivalent call
		end

		maid:Add(Observers.observeAttribute(instance, "HasDefuseKit", function(_)
			fn()
			return hideObjectiveKits
		end))
		maid:Add(Observers.observeAttribute(instance, "HasRescueKit", function(_)
			fn()
			return hideObjectiveKits
		end))
		fn()
	end
end

local function setupDeathmatchTemplate(maid, clone, instance)
	local team = instance:GetAttribute("Team")
	local info = clone:FindFirstChild("Info")

	if info then
		local uiStroke = info:FindFirstChild("UIStroke")

		if uiStroke then
			uiStroke.Color = Colors["Team Color"][team]
		end

		local amount = info:FindFirstChild("Amount")

		if amount then
			amount.Text = "0"
		end
	end

	local uiStroke = clone:FindFirstChild("UIStroke")

	if uiStroke then
		uiStroke.Color = Colors["Team Color"][team]
	end

	maid:Add(Observers.observeAttribute(instance, "Score", function(p)
		local info2 = clone:FindFirstChild("Info")
		local amount = info2 and info2:FindFirstChild("Amount")

		if amount then
			amount.Text = tostring(p)
		end

		clone.LayoutOrder = -p
		return nil
	end))
end

local function refreshCompetitiveStrokeColors()
	for k, v7 in v2 do
		local v8 = Participants.FromKey(k)

		if v8 and v7 and v7.Parent then
			refreshCompetitiveStrokeColorForPlayer(v8)
		end
	end
end

local function destroyCachedTemplate(p: number) -- 2 equivalent calls inferred from this helper
	local v7 = v2[p]

	if not v7 then
		return
	end

	local info = v7:FindFirstChild("Info")
	local v8 = info and v3[info]

	if v8 then
		v8:Destroy()
		v3[info] = nil
	end

	if v7.Parent then
		v7:Destroy()
	end

	v2[p] = nil
end

function PlayerInfo.createTemplate(instance, parent)
	destroyCachedTemplate(Participants.Key(instance)) -- inferred equivalent call
	local gamemode = workspace:GetAttribute("Gamemode")
	local team = instance:GetAttribute("Team")

	if team ~= "Terrorists" and team ~= "Counter-Terrorists" then
		return nil
	end

	local maid = Janitor.new()
	local clone

	if gamemode == "Deathmatch" then
		clone = ReplicatedStorage.Assets.UI.Deathmatch.PlayerTemplate:Clone()
	else
		if gamemode ~= "Bomb Defusal" and gamemode ~= "Hostage Rescue" then
			maid:Destroy()
			return nil
		end

		local child = ReplicatedStorage.Assets.UI.BombDefusal:FindFirstChild(team)

		if child then
			clone = child:Clone()
		else
			warn(`[PlayerInfo]: Missing player template for team {team}`)
			maid:Destroy()
			return nil
		end
	end

	if not clone then
		maid:Destroy()
		return nil
	end

	setChildVisible(clone, "Bomb", false) -- inferred equivalent call
	local info = clone:FindFirstChild("Info")

	if info then
		local originalSize = info:GetAttribute("OriginalSize")
		local size = originalSize or info.Size

		if not originalSize then
			info:SetAttribute("OriginalSize", size)
		end

		if gamemode == "Deathmatch" then
			info.Size = size
			info.Visible = true
		else
			info.Size = UDim2.fromScale(1, 0)
			info.Visible = false
		end

		info:SetAttribute("RevealKey", nil)
	end

	local playerBackground = clone:FindFirstChild("PlayerBackground")
	local player = playerBackground and playerBackground:FindFirstChild("Player")

	if player and player:IsA("ImageLabel") then
		player.Image = Participants.HeadshotImage(instance, 420)
	end

	clone.Parent = parent
	v2[Participants.Key(instance)] = clone
	local competitiveStroke = getCompetitiveStroke(clone) -- inferred equivalent call

	if competitiveStroke then
		local defaultStrokeColor = competitiveStroke:GetAttribute("DefaultStrokeColor")

		if not defaultStrokeColor then
			defaultStrokeColor = competitiveStroke.Color
			competitiveStroke:SetAttribute("DefaultStrokeColor", defaultStrokeColor)
		end

		if not defaultStrokeColor then
			local _color = competitiveStroke.Color
		end
	end

	if gamemode == "Deathmatch" then
		setupDeathmatchTemplate(maid, clone, instance)
	else
		local health = clone:FindFirstChild("Health")

		if health then
			health.Visible = LocalPlayer:GetAttribute("Team") == team
		end

		setupBombDefusalTemplate(maid, clone, instance)
		refreshCompetitiveStrokeColors()
		refreshTemplateInfoVisibilityForPlayer(instance) -- inferred equivalent call
	end

	maid:Add(function()
		clone:Destroy()
	end)
	return maid
end

function PlayerInfo.cleanupTemplate(p)
	local key = Participants.Key(p)
	destroyCachedTemplate(key) -- inferred equivalent call
	v2[key] = nil
	v4[key] = nil
	v5[key] = nil
	refreshCompetitiveStrokeColors()
end

function PlayerInfo.refreshCompetitiveColors()
	refreshCompetitiveStrokeColors()
end

function PlayerInfo.applyTemplateLifeState(p, flag: boolean)
	return setTemplateLifeState(p, flag)
end

function PlayerInfo.setTeammateInfoRevealed(flag: boolean)
	if workspace:GetAttribute("ServerGamemode") ~= "Competitive" then
		flag = false
	end

	v6 = flag
	refreshAllTemplateInfoVisibility()
end

function PlayerInfo.updateTeammateGrenades(items)
	for _, item in items do
		local userId = tonumber(item.userId)

		if not userId then
			continue
		end

		grenadesByUserId[userId] = item.grenades or {}
		local v7 = Participants.FromKey(userId)
		local v8 = v2[userId]

		if v7 and v8 and v8.Parent then
			updateTemplateGrenades(v8, userId)
		end
	end
end

function PlayerInfo.incrementTemplateKills(p: number)
	if GameState.GetState() == "Warmup" then
		return
	end

	v4[p] = (v4[p] or 0) + 1
	local v7 = v2[p]

	if v7 and v7.Parent then
		setTemplateKills(v7, v4[p])
	end

	local v8 = Participants.FromKey(p)
	local v9 = v8 and v2[Participants.Key(v8)]

	if v9 then
		if not v9.Parent then
			return
		end

		setTemplateInfoRevealed(v8, v9, shouldShowInfoForPlayer(v8))
	end
end

function PlayerInfo.updateRoundDamageMatrix(p)
	local outgoing = p.outgoing or {}
	local incoming = p.incoming or {}

	for _, v7 in Participants.GetAll() do
		local key = Participants.Key(v7)
		local v8 = tostring(key)
		local v9 = outgoing[v8] or nil
		local v10 = incoming[v8] or nil
		local v11

		if v9 == nil then
			v11 = false
		else
			v11 = #v9 > 0
		end

		local v12

		if v10 == nil then
			v12 = false
		else
			v12 = #v10 > 0
		end

		local v13 = v5[key] == true
		local v14 = v11 or v12
		v5[key] = v14
		updateDamageFromMatrix(v2[key], v9, v10)

		if v13 == v14 then
			continue
		end

		local v15 = v2[Participants.Key(v7)]

		if v15 and v15.Parent then
			setTemplateInfoRevealed(v7, v15, shouldShowInfoForPlayer(v7))
		end
	end
end

function PlayerInfo.getTemplateByUserId(p: number)
	return v2[p]
end

Remotes.UI.TeammateGrenades.Listen(PlayerInfo.updateTeammateGrenades)
Remotes.UI.RoundDamageMatrix.Listen(PlayerInfo.updateRoundDamageMatrix)
GameState.ListenToState(function(p: string?, p2: string)
	if p == "Buy Period" and p2 ~= "Buy Period" then
		for k, v7 in v2 do
			v4[k] = nil
			v5[k] = nil

			if v7 and v7.Parent then
				setTemplateKills(v7, 0)
			end
		end
	end

	refreshAllTemplateInfoVisibility()
end)
Players.PlayerRemoving:Connect(function(player)
	PlayerInfo.cleanupTemplate(player)
end)
return PlayerInfo