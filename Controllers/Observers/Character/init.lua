local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local CharacterHighlight = require(ReplicatedStorage.Classes.CharacterHighlight)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local Defuser = require(script.Components.Defuser)
local v = {
	["Counter-Terrorists"] = Color3.fromRGB(25, 80, 170),
	Terrorists = Color3.fromRGB(255, 215, 70)
}
local v2 = {}
local v3 = {}
local v4 = {}

local function AreNameTagsVisible() -- 2 equivalent calls inferred from this helper
	local player = SpectateController.GetPlayer()
	return (player == nil or player == LocalPlayer) and not BlackMarketSceneController.IsActive()
end

local function GetNameTagDisplayColor(instance, color: Color3)
	local competitivePlayerColor = instance and instance:GetAttribute("CompetitivePlayerColor")
	return competitivePlayerColor or color
end

local function ApplyNameTagTextColor(folder, competitivePlayerColor: Color3)
	for _, descendant in ipairs(folder:GetDescendants()) do
		if not (descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox")) then
			continue
		end

		descendant.TextColor3 = competitivePlayerColor
	end
end

local function RefreshNameTagArrowColors()
	for k, v5 in pairs(v4) do
		local team = k:GetAttribute("Team")
		local competitivePlayerColor

		if team then
			competitivePlayerColor = v[team]
		end

		if not competitivePlayerColor then
			continue
		end

		local character = Participants.Character(k)

		if character then
			competitivePlayerColor = character:GetAttribute("CompetitivePlayerColor") or competitivePlayerColor
		end

		if v5.Arrow.Parent then
			v5.Arrow.Arrow.ImageColor3 = competitivePlayerColor
		end

		if v5.NameTag.Parent then
			ApplyNameTagTextColor(v5.NameTag, competitivePlayerColor)
		end
	end
end

workspace:GetAttributeChangedSignal("ServerGamemode"):Connect(RefreshNameTagArrowColors)

local function CleanupNameTagJanitor(p) -- 9 equivalent calls inferred from this helper
	if v3[p] then
		v3[p]:Destroy()
		v3[p] = nil
		RefreshNameTagArrowColors()
	end
end

local function GetParticipantCharacter(player) -- 1 equivalent call inferred from this helper
	if player:IsA("Player") then
		return CharacterResolver.getPlayerCharacter(player)
	end

	return Participants.Character(player)
end

local function getCharacterHealthText(instance) -- 2 equivalent calls inferred from this helper
	return `{math.ceil(CharacterResolver.getHealth(instance) / math.max(CharacterResolver.getMaxHealth(instance), 1) * 100)}%`
end

local function CreateNameTag(instance, instance2, team)
	local v5 = v[team]

	if not v5 then
		return nil
	end

	local head = CharacterResolver.getHead(instance2)

	if not (head and instance2:IsDescendantOf(workspace)) then
		return nil
	end

	CleanupNameTagJanitor(instance) -- inferred equivalent call
	local maid = Janitor.new()
	local arrow = maid:Add(ReplicatedStorage.Assets.Other.Character.Arrow:Clone())
	local competitivePlayerColor

	if instance2 then
		competitivePlayerColor = instance2:GetAttribute("CompetitivePlayerColor") or v5
	else
		competitivePlayerColor = v5
	end

	arrow.Arrow.ImageColor3 = competitivePlayerColor
	arrow.Adornee = head
	arrow.Parent = PlayerGui
	local nameTag = maid:Add(ReplicatedStorage.Assets.Other.Character.NameTag:Clone())
	nameTag.Info.PlayerName.Text = `{Participants.DisplayName(instance)}`
	nameTag.Info.Weapons.Bomb.Visible = false
	nameTag.Adornee = head
	nameTag.Parent = PlayerGui
	nameTag.Info.Health.Text = getCharacterHealthText(instance2) -- inferred equivalent call
	ApplyNameTagTextColor(nameTag, competitivePlayerColor)
	maid:Add(instance2:GetAttributeChangedSignal("CompetitivePlayerColor"):Connect(function()
		local v6 = instance2
		local competitivePlayerColor2 = v5

		if v6 then
			competitivePlayerColor2 = v6:GetAttribute("CompetitivePlayerColor") or competitivePlayerColor2
		end

		if arrow.Parent and arrow:FindFirstChild("Arrow") then
			arrow.Arrow.ImageColor3 = competitivePlayerColor2
		end

		if nameTag.Parent then
			ApplyNameTagTextColor(nameTag, competitivePlayerColor2)
		end
	end))

	local function updateHealthText()
		if nameTag.Parent and nameTag:FindFirstChild("Info") then
			nameTag.Info.Health.Text = getCharacterHealthText(instance2) -- inferred equivalent call
		end
	end

	maid:Add(instance2:GetAttributeChangedSignal("Health"):Connect(updateHealthText))
	maid:Add(instance2:GetAttributeChangedSignal("MaxHealth"):Connect(updateHealthText))

	local function updateBombIcon(p, p2) -- 2 equivalent calls inferred from this helper
		local v6

		if p2 == nil then
			v6 = false
		else
			v6 = p2.Weapon == "C4"
		end

		local v7 = p ~= nil and p.Name == "C4"
		nameTag.Info.Weapons.Bomb.Visible = v6 and not v7
	end

	local function decodeAttribute(attributeName: string) -- 2 equivalent calls inferred from this helper
		local attribute = instance:GetAttribute(attributeName)

		if attribute then
			return (HttpService:JSONDecode(attribute))
		end

		return nil
	end

	maid:Add(Observers.observeAttribute(instance, "CurrentEquipped", function(value)
		if not (nameTag.Parent and nameTag:FindFirstChild("Info")) then
			return function() end
		end

		local jsonDecode = HttpService:JSONDecode(value or "[]")
		local gun = nameTag.Info.Weapons.Gun

		if jsonDecode and jsonDecode.Name then
			local weaponProperties = GetWeaponProperties(jsonDecode.Name)
			gun.Image = not weaponProperties and "" or weaponProperties.Icon or ""
			gun.Visible = weaponProperties or false
		else
			gun.Visible = false
		end

		updateBombIcon(jsonDecode, decodeAttribute("Slot5")) -- inferred equivalent call
		return function()
			if nameTag:FindFirstChild("Info") then
				nameTag.Info.Weapons.Gun.Visible = false
			end
		end
	end))
	maid:Add(Observers.observeAttribute(instance, "Slot5", function(value)
		if not (nameTag.Parent and nameTag:FindFirstChild("Info")) then
			return function() end
		end

		updateBombIcon(decodeAttribute("CurrentEquipped"), HttpService:JSONDecode(value or "[]")) -- inferred equivalent call
		return function()
			if nameTag:FindFirstChild("Info") then
				nameTag.Info.Weapons.Bomb.Visible = false
			end
		end
	end))
	v3[instance] = maid
	v4[instance] = { Arrow = arrow, NameTag = nameTag }
	local enabled = AreNameTagsVisible() -- inferred equivalent call
	arrow.Enabled = enabled
	nameTag.Enabled = enabled
	maid:Add(function()
		v4[instance] = nil
	end)

	local function cleanupIfCharacterBecameStale()
		local v6 = true

		if GetParticipantCharacter(instance) == instance2 then -- inferred equivalent call
			v6 = not (instance2:IsDescendantOf(workspace) and CharacterResolver.isAliveCharacter(instance2))
		end

		if v6 then
			CleanupNameTagJanitor(instance) -- inferred equivalent call
		end
	end

	maid:Add(instance2:GetAttributeChangedSignal("Dead"):Connect(cleanupIfCharacterBecameStale))
	maid:Add(instance2:GetAttributeChangedSignal("Health"):Connect(cleanupIfCharacterBecameStale))
	maid:Add(instance2.AncestryChanged:Connect(cleanupIfCharacterBecameStale))
	RefreshNameTagArrowColors()
	return maid
end

local function ReleaseCameraToMenu() -- 1 equivalent call inferred from this helper
	if SpectateController.IsTakingOverCamera() then
		return
	end

	CameraController.setPerspective(false, true)
end

local function characterAdded(maid)
	CameraController.setPerspective(true, false)
	maid:Add(ReleaseCameraToMenu)

	if not BlackMarketSceneController.IsActive() then
		InputController.enableGroup("Gameplay")
	end

	maid:Add(function()
		InputController.disableGroup("Gameplay")
	end)
end

local function RefreshNameTagVisibility()
	local enabled = AreNameTagsVisible() -- inferred equivalent call

	for _, v5 in pairs(v4) do
		v5.Arrow.Enabled = enabled
		v5.NameTag.Enabled = enabled
	end
end

SpectateController.ListenToSpectate:Connect(RefreshNameTagVisibility)
BlackMarketSceneController.OnActiveChanged:Connect(RefreshNameTagVisibility)

local function observeRemoteCharacter(player, instance, maid)
	local v5 = not player:IsA("Player")
	local team = player:GetAttribute("Team")
	local color = team == "Counter-Terrorists" and Color3.fromRGB(0, 75, 200)
		or team == "Terrorists" and Color3.fromRGB(255, 220, 50)
		or Color3.fromRGB(255, 255, 255)

	if not v5 then
		CharacterController.TrackCharacter(player, instance)
		maid:Add(function()
			CharacterController.UntrackCharacter(player, instance)
		end)
	end

	local gamemode = workspace:GetAttribute("Gamemode")
	local v6 = team == "Terrorists" or team == "Counter-Terrorists"
	local v7 = v6 and gamemode ~= "Deathmatch"
	local maid2 = Janitor.new()
	maid:Add(function()
		maid2:Destroy()
		CleanupNameTagJanitor(player) -- inferred equivalent call
	end)

	local function rebuildRemoteVisuals()
		maid2:Destroy()
		maid2 = Janitor.new()

		if instance:GetAttribute("Dead") == true or not CharacterResolver.isAliveCharacter(instance) then
			CleanupNameTagJanitor(player) -- inferred equivalent call
		else
			if not v5 then
				local v8 = Defuser.new(player, instance)
				maid2:Add(function()
					v8:Destroy()
				end)
			end

			if v6 then
				local depthMode

				if gamemode == "Deathmatch" then
					depthMode = Enum.HighlightDepthMode.Occluded
				else
					depthMode = Enum.HighlightDepthMode.AlwaysOnTop
				end

				local v8 = maid2:Add(CharacterHighlight.new(instance, {
					DepthMode = depthMode,
					FillColor = Color3.fromRGB(255, 255, 255),
					OutlineColor = color,
					OutlineTransparency = 0.4,
					FillTransparency = 0.7
				}))

				local function updateHighlightVisible()
					if not instance.Parent then
						return
					end

					local gamemode2 = workspace:GetAttribute("Gamemode")
					local gameState = workspace:GetAttribute("GameState")
					local team2 = player:GetAttribute("Team")
					local dead = instance:GetAttribute("Dead") == true
					local invincible = player:GetAttribute("Invincible") == true
					local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true
					local player2 = SpectateController.GetPlayer()
					local team3 = player2 and player2:GetAttribute("Team")
					local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
					local v9

					if currentSpectateInstance == nil then
						v9 = false
					else
						v9 = currentSpectateInstance.PerspectiveState == "First-Person"
					end

					local v10 = player2 == player
					local v11 = LocalPlayer:GetAttribute("Team") == team2
					local v12 = isSpectating and v9 and v10
					local v13

					if gamemode2 == "Deathmatch" then
						v13 = false
					elseif isSpectating then
						if team3 == team2 then
							v13 = not v12
						else
							v13 = false
						end
					else
						v13 = isSpectating
					end

					local v14 = v11 or isSpectating and team3 == team2
					local v15 = invincible and not v12 and (gamemode2 == "Deathmatch" or (gameState == "Warmup" or v14))
					local occluded

					if v15 and gameState == "Warmup" then
						occluded = Enum.HighlightDepthMode.Occluded
					elseif gamemode2 == "Deathmatch" then
						occluded = Enum.HighlightDepthMode.Occluded
					else
						occluded = Enum.HighlightDepthMode.AlwaysOnTop
					end

					if v8.Highlight and v8.Highlight.Parent then
						v8.Highlight.DepthMode = occluded
					end

					if dead or BlackMarketSceneController.IsActive() then
						v8.OutlineOnly = false
						v8:UpdateState(false)
					else
						v8.OutlineOnly = v13 and not v15
						v8:UpdateState(v15 or v13)
					end
				end

				updateHighlightVisible()
				maid2:Add(player:GetAttributeChangedSignal("Invincible"):Connect(updateHighlightVisible))
				maid2:Add(SpectateController.ListenToSpectate:Connect(function()
					updateHighlightVisible()
				end))
				maid2:Add(BlackMarketSceneController.OnActiveChanged:Connect(function()
					updateHighlightVisible()
				end))

				local function onHighlightInputChanged()
					updateHighlightVisible()
					return function() end
				end

				for _, v9 in {
					{ LocalPlayer, "IsSpectating" },
					{ LocalPlayer, "SpectatePerspective" },
					{ LocalPlayer, "Team" },
					{ player, "Team" },
					{ workspace, "GameState" }
				} do
					maid2:Add(Observers.observeAttribute(v9[1], v9[2], onHighlightInputChanged))
				end
			end

			if LocalPlayer:GetAttribute("Team") == team and v7 then
				CreateNameTag(player, instance, team)
				maid2:Add(function()
					CleanupNameTagJanitor(player) -- inferred equivalent call
				end)
			end
		end
	end

	rebuildRemoteVisuals()
	maid:Add(instance:GetAttributeChangedSignal("Dead"):Connect(rebuildRemoteVisuals))
	local isDescendant = instance:IsDescendantOf(workspace)
	maid:Add(instance.AncestryChanged:Connect(function()
		local isDescendant2 = instance:IsDescendantOf(workspace)

		if isDescendant2 ~= isDescendant then
			isDescendant = isDescendant2
			rebuildRemoteVisuals()
		end
	end))

	if LocalPlayer:GetAttribute("IsSpectating") and not SpectateController.GetCurrentSpectateInstance() then
		SpectateController.Next()
	end
end

local v5 = {}

local function GetBotDescriptor(model) -- 1 equivalent call inferred from this helper
	local combatants = ReplicatedStorage:FindFirstChild("Combatants")
	local combatantId = model:GetAttribute("CombatantId")

	if combatants and combatantId ~= nil then
		return (combatants:FindFirstChild((tostring(combatantId))))
	end

	return nil
end

local function BotShellRemoved(model) -- 1 equivalent call inferred from this helper
	local v6 = v5[model]

	if v6 then
		v5[model] = nil
		v6:Destroy()
	end
end

local function BotShellAdded(model)
	if not model:IsA("Model") or model:GetAttribute("Bot") ~= true then
		return
	end

	local botDescriptor = GetBotDescriptor(model) -- inferred equivalent call

	if not botDescriptor then
		return
	end

	BotShellRemoved(model) -- inferred equivalent call

	if v2[botDescriptor] then
		v2[botDescriptor]:Destroy()
	end

	local maid = Janitor.new()
	v5[model] = maid
	v2[botDescriptor] = maid
	maid:Add(function()
		if v2[botDescriptor] == maid then
			v2[botDescriptor] = nil
		end
	end)
	CleanupNameTagJanitor(botDescriptor) -- inferred equivalent call
	observeRemoteCharacter(botDescriptor, model, maid)
end

local flag = false

local function BindBotCharacters(instance)
	if flag then
		return
	end

	flag = true
	instance.ChildAdded:Connect(BotShellAdded)
	instance.ChildRemoved:Connect(BotShellRemoved)

	for _, child in instance:GetChildren() do
		task.spawn(BotShellAdded, child)
	end
end

local Characters = workspace:FindFirstChild("Characters")

if Characters then
	BindBotCharacters(Characters)
else
	local childAddedConnection = nil
	childAddedConnection = workspace.ChildAdded:Connect(function(child)
		if child.Name == "Characters" then
			BindBotCharacters(child)

			if childAddedConnection then
				childAddedConnection:Disconnect()
			end
		end
	end)
end

return Observers.observeCharacter(function(p, instance)
	if v2[p] then
		v2[p]:Destroy()
		v2[p] = nil
	end

	local maid = Janitor.new()
	v2[p] = maid
	CleanupNameTagJanitor(p) -- inferred equivalent call

	if LocalPlayer == p then
		characterAdded(maid)
		maid:Add(instance:GetAttributeChangedSignal("Dead"):Connect(function()
			if instance:GetAttribute("Dead") == true then
				ReleaseCameraToMenu() -- inferred equivalent call
				InputController.disableGroup("Gameplay")
			end
		end))

		for k in pairs(v3) do
			CleanupNameTagJanitor(k) -- inferred equivalent call
		end

		for _, v6 in ipairs(Participants.GetAll()) do
			if v6 == LocalPlayer then
				continue
			end

			local character = Participants.Character(v6)

			if not (character and character:IsDescendantOf(workspace)) then
				continue
			end

			local team = LocalPlayer:GetAttribute("Team")
			local team2 = v6:GetAttribute("Team")

			if not (team == team2 and (team2 == "Terrorists" or team2 == "Counter-Terrorists") and workspace:GetAttribute("Gamemode") ~= "Deathmatch") then
				continue
			end

			CreateNameTag(v6, character, team2)

			if not v2[v6] then
				continue
			end

			local v7 = v6
			v2[v6]:Add(function()
				CleanupNameTagJanitor(v7) -- inferred equivalent call
			end)
		end
	else
		observeRemoteCharacter(p, instance, maid)
	end

	return function()
		maid:Destroy()
	end
end)