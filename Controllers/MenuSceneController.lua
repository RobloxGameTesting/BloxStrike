local MenuSceneController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneLighting = require(ReplicatedStorage.Components.Common.SceneLighting)
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
MenuSceneController.MenuCharacterChanged = Signal.new()
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local v = nil
local Sound = require(ReplicatedStorage.Classes.Sound)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CurrentCamera = workspace.CurrentCamera
local menuScenes = nil
local lighting = ReplicatedStorage.Assets.Lighting
local Characters = ReplicatedStorage.Assets.Characters
local v2 = {
	CT = { Entrance = "rbxassetid://96240248165206", Idle = "rbxassetid://77870220857645" },
	T = { Entrance = "rbxassetid://100747011940776", Idle = "rbxassetid://99540873384647" }
}
local v3 = {
	CT = { Character = "IDF", Weapon = "M4A1-S", Glove = "CT Glove" },
	T = { Character = "Anarchist", Weapon = "AK-47", Glove = "T Glove" }
}
local v4 = {
	{
		Team = "CT",
		TeamName = "Counter-Terrorists",
		MarkerPart = "CounterTerroristPart",
		Animation = "rbxassetid://81456769299241",
		HighlightColor = Color3.fromRGB(0, 75, 200),
		Weapon = "USP-S"
	},
	{
		Team = "T",
		TeamName = "Terrorists",
		MarkerPart = "TerroristPart",
		Animation = "rbxassetid://128548863350369",
		HighlightColor = Color3.fromRGB(255, 220, 50),
		Weapon = "Glock-18"
	}
}
local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local v5 = { "IDF", "Anarchist" }
local AttachGlovesToCharacter = require(ReplicatedStorage.Database.Components.Common.AttachGlovesToCharacter)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local v6 = nil
local v7 = nil
local v8 = nil
local v9 = nil
local maid = Janitor.new()
local flag = false
local maid2 = Janitor.new()
local maid3 = Janitor.new()
local flag2 = false
local v10 = {}
local v11 = nil
local v12 = nil
local v13 = nil
local v14 = 1
local v15 = nil
local v16 = nil

local function applyGlobalShadowsSetting()
	SceneLighting.ApplyGlobalShadows(v16)
end

local function applyMapLighting() -- 4 equivalent calls inferred from this helper
	v16 = SceneLighting.RestoreMap(nil, v16)
end

local function applySceneLighting(name: string) -- 2 equivalent calls inferred from this helper
	local child = lighting:FindFirstChild(name)

	if child then
		v16 = SceneLighting.ApplyScene(name, child)
	else
		warn(`[MenuSceneController]: No lighting found for scene "{name}"`)
	end
end

local function excludeTeamSelectPlaceholders(menuScenes2)
	for _, child in ipairs(menuScenes2:GetChildren()) do
		local teamSelect = child:FindFirstChild("TeamSelect")

		if not teamSelect then
			continue
		end

		for _, childName in ipairs(v5) do
			local child2 = teamSelect:FindFirstChild(childName)

			if child2 then
				child2.Archivable = false
			end
		end
	end
end

local function getMenuScenesFolder() -- 2 equivalent calls inferred from this helper
	if menuScenes then
		return menuScenes
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")

	if assets then
		menuScenes = assets:WaitForChild("MenuScenes", 10)

		if menuScenes then
			excludeTeamSelectPlaceholders(menuScenes)
		end
	end

	return menuScenes
end

local function getRandomMenuScene()
	local menuScenesFolder = getMenuScenesFolder() -- inferred equivalent call
	local v17 = not menuScenesFolder and {} or menuScenesFolder:GetChildren()

	if #v17 > 0 then
		return v17[math.random(1, #v17)]
	end

	return nil
end

local function isCharacterAlive() -- 6 equivalent calls inferred from this helper
	return CharacterResolver.isAliveCharacter(CharacterResolver.getLocalCharacter())
end

local function isTeamSelectionActive()
	local mainGui = PlayerGui:FindFirstChild("MainGui")

	if not mainGui then
		return false
	end

	local menu = mainGui:FindFirstChild("Menu")
	local gameplay = mainGui:FindFirstChild("Gameplay")
	local middle = gameplay and gameplay:FindFirstChild("Middle")
	local bottom = gameplay and gameplay:FindFirstChild("Bottom")
	local teamSelection = middle and middle:FindFirstChild("TeamSelection")
	local visible

	if menu == nil then
		visible = false
	else
		visible = not menu.Visible

		if visible then
			if bottom == nil then
				visible = false
			else
				visible = not bottom.Visible

				if visible then
					if teamSelection == nil then
						visible = false
					else
						visible = teamSelection.Visible
					end
				end
			end
		end
	end

	return visible
end

local function shouldShowMenuScene()
	local MenuState = require(ReplicatedStorage.Interface.MenuState)

	if
		v and v.IsActive()
		or MenuState.IsInspectActive()
		or workspace:FindFirstChild("InspectScene")
		or isTeamSelectionActive()
	then
		return false
	end

	local team = LocalPlayer:GetAttribute("Team")

	if team == "Counter-Terrorists" or team == "Terrorists" then
		return false
	end

	local GameState = require(ReplicatedStorage.Database.Components.GameState)
	local state = GameState.GetState()

	if state == "Game Ending" or state == "Map Voting" then
		return not isCharacterAlive() -- inferred equivalent call
	end

	return not (isCharacterAlive() or LocalPlayer:GetAttribute("IsSpectating")) -- inferred equivalent call
end

local function getTeamLoadout(p: string) -- 2 equivalent calls inferred from this helper
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local v17

	if type(loadout) == "table" then
		v17 = loadout[p == "CT" and "Counter-Terrorists" or "Terrorists"]
	else
		v17 = false
	end

	if type(v17) == "table" then
		return v17
	end

	return nil
end

local function attachGlovesToCharacter(parent, p: string, flag3: boolean)
	local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
	local name = nil
	local skin = nil
	local float = nil

	if flag3 then
		DataController.WaitForDataLoaded(LocalPlayer)
		local teamLoadout = getTeamLoadout(p) -- inferred equivalent call
		local equippedGloves = teamLoadout and teamLoadout.Equipped and teamLoadout.Equipped["Equipped Gloves"]
		local inventory

		if type(equippedGloves) == "string" and equippedGloves ~= "" then
			inventory = DataController.Get(LocalPlayer, "Inventory")
		else
			inventory = false
		end

		if type(inventory) == "table" then
			for _, v17 in ipairs(inventory) do
				if not (v17 and v17._id == equippedGloves) then
					continue
				end

				name = v17.Name
				skin = v17.Skin
				float = v17.Float
				local HttpService = game:GetService("HttpService")
				parent:SetAttribute("EquippedGloves", HttpService:JSONEncode({
					SkinIdentifier = equippedGloves
				}))
				break
			end
		end
	end

	local v17 = name or v3[p].Glove
	local v18

	if skin and float and v17 then
		v18 = Skins.GetGloves(v17, skin, float)
	end

	local child

	if not v18 then
		child = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Weapons"):FindFirstChild(v17)

		if not child then
			warn(`[MenuSceneController]: Glove folder not found for "{v17}"`)
			return
		end
	end

	local v19 = parent:FindFirstChild("CharacterArmor")

	if not v19 then
		v19 = Instance.new("Folder")
		v19.Name = "CharacterArmor"
		v19.Parent = parent
	end

	AttachGlovesToCharacter((v18 or child):GetChildren(), parent, v19)

	if v18 and v18.Name == "" then
		v18:Destroy()
	end
end

local function attachWeaponToCharacter(parent, p: string, flag3: boolean, p2: string?, value: string?)
	local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
	local name = nil
	local skin = nil
	local float = nil
	local nameTag = nil
	local v17 = p2 or v3[p].Weapon

	if flag3 then
		DataController.WaitForDataLoaded(LocalPlayer)
		local teamLoadout = getTeamLoadout(p) -- inferred equivalent call
		local inventory = DataController.Get(LocalPlayer, "Inventory")
		local v18 = teamLoadout and teamLoadout.Loadout and teamLoadout.Loadout[value or "Rifles"]

		if v18 and type(v18.Options) == "table" and type(inventory) == "table" then
			for _, option in ipairs(v18.Options) do
				if not (type(option) == "string" and option ~= "") then
					continue
				end

				for _, v19 in ipairs(inventory) do
					if not (v19 and v19._id == option and v19.Name == v17) then
						continue
					end

					name = v19.Name
					skin = v19.Skin
					float = v19.Float
					nameTag = v19.NameTag
					break
				end

				if name then
					break
				end
			end
		end
	end

	local name2 = name or v17
	local v18

	if skin and typeof(skin) == "string" and skin ~= "" then
		v18 = Skins.GetCharacterModel(name2, skin, float, nil, nameTag)
	end

	local folder = v18 or Skins.GetBaseWeaponModel(name2, "Character")

	if not folder then
		warn(`[MenuSceneController]: Failed to get weapon model for "{name2}"`)
		return
	end

	folder.Name = name2
	local rightHand = parent:FindFirstChild("RightHand")

	if rightHand then
		if not folder.PrimaryPart then
			local weapon = folder:FindFirstChild("Weapon")
			local insert = weapon and weapon:FindFirstChild("Insert")

			if insert then
				folder.PrimaryPart = insert
			else
				warn("[MenuSceneController]: Weapon model has no PrimaryPart or Insert")
				folder:Destroy()
				return
			end
		end

		for _, part in ipairs(folder:GetDescendants()) do
			if not part:IsA("BasePart") then
				continue
			end

			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Anchored = false
			part.Massless = true
		end

		folder.Parent = parent
		local motor6D = Instance.new("Motor6D")
		motor6D.Name = "WeaponAttachment"
		motor6D.Part0 = rightHand
		motor6D.Part1 = folder.PrimaryPart
		motor6D.Parent = rightHand

		if name2 == "AK-47" then
			motor6D.C0 = CFrame.new(-0.251, 0.806, -0.406) * CFrame.Angles(0, -1.5707963267948966, 1.5707963267948966)
			return folder
		end

		local properties = folder:FindFirstChild("Properties")

		if not properties then
			return folder
		end

		local c0 = properties:FindFirstChild("C0")

		if c0 then
			motor6D.C0 = c0.Value
		end

		local c1 = properties:FindFirstChild("C1")

		if c1 then
			motor6D.C1 = c1.Value
		end

		return folder
	else
		warn("[MenuSceneController]: Character missing RightHand")
		folder:Destroy()
	end
end

local function configureMenuDisplayCharacter(folder)
	local rootPart = CharacterResolver.getRootPart(folder)

	for _, part in ipairs(folder:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Massless = true
	end

	if rootPart then
		rootPart.Anchored = true
	end
end

local function getTeamSelectStaging(instance)
	local teamSelect = instance:FindFirstChild("TeamSelect")
	local camPart = teamSelect and teamSelect:FindFirstChild("CamPart")

	if teamSelect and camPart and camPart:IsA("BasePart") then
		return teamSelect, camPart
	end

	return nil, nil
end

local function prepareTeamSelectScene(clone)
	local teamSelect = clone:FindFirstChild("TeamSelect")

	if not teamSelect then
		return
	end

	for _, v17 in ipairs(v4) do
		local part = teamSelect:FindFirstChild(v17.MarkerPart)

		if not (part and part:IsA("BasePart")) then
			continue
		end

		part.Transparency = 1
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
	end
end

local function ensureSceneLoaded(instance)
	local v17 = v6

	if v17 and v17.Parent then
		return v17
	end

	if not instance then
		return nil
	end

	local clone = instance:Clone()
	clone.Parent = workspace
	v6 = clone
	applySceneLighting(instance.Name) -- inferred equivalent call
	prepareTeamSelectScene(clone)
	maid2:Add(function()
		if v6 then
			v6:Destroy()
			v6 = nil
		end
	end, true, "MenuSceneCleanup")
	return clone
end

local function releaseSceneIfUnused() -- 2 equivalent calls inferred from this helper
	if flag or flag2 then
		return
	end

	maid2:Cleanup()
end

local function getStagedMenuScene()
	local menuScenesFolder = getMenuScenesFolder() -- inferred equivalent call

	if not menuScenesFolder then
		return nil
	end

	local models = {}

	for _, model in ipairs(menuScenesFolder:GetChildren()) do
		if not model:IsA("Model") then
			continue
		end

		local teamSelect = model:FindFirstChild("TeamSelect")
		local camPart = teamSelect and teamSelect:FindFirstChild("CamPart")

		if not (teamSelect and camPart and camPart:IsA("BasePart")) then
			teamSelect = nil
		end

		if teamSelect then
			table.insert(models, model)
		end
	end

	if #models == 0 then
		return nil
	end

	return models[math.random(1, #models)]
end

local function spawnMenuCharacter(sceneLoaded)
	local playerPart = sceneLoaded:FindFirstChild("PlayerPart")

	if not playerPart then
		return
	end

	local v17 = math.random(1, 2) == 1 and "CT" or "T"
	local v18 = v3[v17]
	local v19 = v2[v17]
	local child = Characters:FindFirstChild(v18.Character)

	if not child then
		warn(`[MenuSceneController]: Character "{v18.Character}" not found`)
		return
	end

	local clone = child:Clone()
	clone.Name = "MenuCharacter"
	v7 = clone
	v8 = v17
	MenuSceneController.MenuCharacterChanged:Fire(MenuSceneController.GetMenuCharacterTeam())
	v9 = attachWeaponToCharacter(clone, v17, true)
	attachGlovesToCharacter(clone, v17, true)
	configureMenuDisplayCharacter(clone)
	clone.Parent = sceneLoaded
	clone:PivotTo(playerPart.CFrame)
	local animator = CharacterResolver.getOrCreateAnimator(clone)

	if not animator then
		warn("[MenuSceneController]: Character missing Animator")
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = v19.Entrance
	local animation2 = Instance.new("Animation")
	animation2.AnimationId = v19.Idle
	local track = animator:LoadAnimation(animation)
	local track2 = animator:LoadAnimation(animation2)
	maid:Add(animation, "Destroy", "EntranceAnimation")
	maid:Add(animation2, "Destroy", "IdleAnimation")
	maid:Add(track, "Stop", "EntranceTrack")
	maid:Add(track2, "Stop", "IdleTrack")
	track.Priority = Enum.AnimationPriority.Action
	track:Play()
	track.Stopped:Once(function()
		if flag and track2 then
			track2.Looped = true
			track2.Priority = Enum.AnimationPriority.Idle
			track2:Play()
		end
	end)
	maid:Add(function()
		if v7 then
			v7:Destroy()
			v7 = nil
			v8 = nil
			v9 = nil
			MenuSceneController.MenuCharacterChanged:Fire(nil)
		end
	end, true, "MenuCharacterCleanup")
end

local function spawnTeamSelectCharacter(teamSelect, data)
	local child = teamSelect:FindFirstChild(data.MarkerPart)

	if not child then
		warn(`[MenuSceneController]: TeamSelect is missing "{data.MarkerPart}"`)
		return
	end

	local v17 = v3[data.Team]
	local child2 = Characters:FindFirstChild(v17.Character)

	if not child2 then
		warn(`[MenuSceneController]: Character "{v17.Character}" not found`)
		return
	end

	local clone = child2:Clone()
	clone.Name = `TeamSelectCharacter{data.Team}`
	attachWeaponToCharacter(clone, data.Team, true, data.Weapon, "Pistols")
	attachGlovesToCharacter(clone, data.Team, true)
	configureMenuDisplayCharacter(clone)
	clone.Parent = teamSelect
	clone:PivotTo(child.CFrame)
	maid3:Add(clone, "Destroy", `Character{data.Team}`)
	local highlight = Instance.new("Highlight")
	highlight.Name = "HoverHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.OutlineColor = data.HighlightColor
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
	highlight.Adornee = clone
	highlight.Parent = clone
	v10[data.Team] = highlight
	maid3:Add(function()
		v10[data.Team] = nil
	end, true, `Highlight{data.Team}`)
	local animator = CharacterResolver.getOrCreateAnimator(clone)

	if not animator then
		warn(`[MenuSceneController]: TeamSelect character "{data.Team}" is missing an Animator`)
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = data.Animation
	maid3:Add(animation, "Destroy", `Animation{data.Team}`)
	local track = animator:LoadAnimation(animation)
	maid3:Add(track, "Stop", `Track{data.Team}`)
	track.Looped = true
	track.Priority = Enum.AnimationPriority.Idle
	track:Play()
end

local function getVolumeMultipliers() -- 2 equivalent calls inferred from this helper
	local v17 = DataController.Get(LocalPlayer, "Settings.Audio.Audio.Main Menu Ambience Volume") or 100
	local v18 = DataController.Get(LocalPlayer, "Settings.Audio.Audio.Master Volume") or 100
	return v17 / 100, v18 / 100
end

local function updateMenuMusicVolume()
	if not (v13 and v13.Parent) then
		return
	end

	local volumeMultipliers, v17 = getVolumeMultipliers() -- inferred equivalent call
	local baseVolume = v13:GetAttribute("BaseVolume") or v13.Volume
	v13.Volume = baseVolume * volumeMultipliers * v17 * v14
end

function MenuSceneController.ShowMenuScene()
	if isCharacterAlive() or flag2 then -- inferred equivalent call
		return
	end

	if flag then
		CameraController.setFOVLock("MenuScene", true, 50)
		CameraController.setMouseEnabled(true)
	else
		if workspace:FindFirstChild("InspectScene") then
			return
		end

		local MenuState = require(ReplicatedStorage.Interface.MenuState)

		if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() then
			return
		end

		local sceneLoaded = ensureSceneLoaded(getRandomMenuScene())

		if not sceneLoaded then
			CameraController.setMouseEnabled(true)
			return
		end

		local camPart = sceneLoaded:FindFirstChild("CamPart")

		if camPart then
			CurrentCamera.CameraType = Enum.CameraType.Scriptable
			CurrentCamera.CFrame = camPart.CFrame
			CurrentCamera.Focus = camPart.CFrame
			CameraController.setFOVLock("MenuScene", true, 50)
			CameraController.setMouseEnabled(true)
			maid:Add(RunServiceController.BindToRenderStep("MenuSceneController.CameraUpdate", function()
				if v6 and camPart then
					CurrentCamera.CFrame = camPart.CFrame
					CurrentCamera.Focus = camPart.CFrame
				end
			end), "Disconnect", "CameraUpdate")
			flag = true
			maid:Add(RunServiceController.BindToHeartbeat("MenuSceneController.AliveGuard", function()
				if isCharacterAlive() then -- inferred equivalent call
					MenuSceneController.HideMenuScene()
				end
			end), "Disconnect", "AliveGuard")
			spawnMenuCharacter(sceneLoaded)

			if not (v13 and v13.IsPlaying) then
				local v17 = (DataController.Get(LocalPlayer, "Settings.Audio.Audio.Main Menu Ambience Volume") or 100) / 100
				local mainMenu = Sound.new("Main Menu")
				v12 = mainMenu
				local v18 = mainMenu:play({ Name = "Main Menu Music", Parent = PlayerGui }, v17)
				v13 = v18

				if v18 then
					local v19 = (DataController.Get(LocalPlayer, "Settings.Audio.Audio.Master Volume") or 100) / 100
					local volume = v18.Volume

					if v17 > 0 and v19 > 0 then
						volume = volume / (v17 * v19) or volume
					end

					v18:SetAttribute("BaseVolume", volume)
					v18:SetAttribute("AmbienceVolumeMultiplier", v17)

					if v14 ~= 1 then
						v18.Volume *= v14
					end

					v18.Destroying:Once(function()
						if v13 == v18 then
							v13 = nil
						end
					end)
				end
			end
		else
			warn("[MenuSceneController]: Menu scene missing CamPart")
			maid2:Cleanup()
			applyMapLighting() -- inferred equivalent call
		end
	end
end

function MenuSceneController.HideMenuScene(flag3: boolean?, flag4: boolean?, flag5: boolean?)
	if not flag then
		return
	end

	local MenuState = require(ReplicatedStorage.Interface.MenuState)

	if MenuState.IsInspectActive() or workspace:FindFirstChild("InspectScene") then
		flag4 = true
		flag3 = true
	end

	maid:Cleanup()
	flag = false

	if not (flag5 or flag or flag2) then
		maid2:Cleanup()
	end

	CameraController.setFOVLock("MenuScene", false)

	if not (flag4 or flag5) then
		applyMapLighting() -- inferred equivalent call
		CurrentCamera.CameraType = Enum.CameraType.Custom
		CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	end

	if not flag3 then
		MenuSceneController.StopMenuMusic()
	end
end

function MenuSceneController.IsActive()
	return flag
end

function MenuSceneController.IsTeamSelectSceneActive()
	return flag2
end

function MenuSceneController.SetTeamSelectHighlight(p: string, flag3: boolean)
	if flag3 then
		v11 = p
	elseif v11 == p then
		v11 = nil
	else
		return
	end

	for _, v17 in ipairs(v4) do
		local v18 = v10[v17.Team]

		if v18 then
			TweenService:Create(v18, tweenInfo, {
				OutlineTransparency = v11 == v17.TeamName and 0 or 1
			}):Play()
		end
	end
end

function MenuSceneController.ShowTeamSelectScene()
	if isCharacterAlive() or LocalPlayer:GetAttribute("IsSpectating") then -- inferred equivalent call
		return false
	end

	if flag2 then
		CameraController.setFOVLock("TeamSelectScene", true, 70)
		CameraController.setMouseEnabled(true)
		return true
	else
		if flag then
			MenuSceneController.HideMenuScene(true, true, true)
		end

		local sceneLoaded = ensureSceneLoaded(getStagedMenuScene())
		local teamSelect, camPart

		if sceneLoaded then
			teamSelect = sceneLoaded:FindFirstChild("TeamSelect")
			camPart = teamSelect and teamSelect:FindFirstChild("CamPart")

			if not (teamSelect and camPart and camPart:IsA("BasePart")) then
				teamSelect = nil
				camPart = nil
			end
		else
			camPart = nil
		end

		if teamSelect and camPart then
			flag2 = true
			CurrentCamera.CameraType = Enum.CameraType.Scriptable
			CurrentCamera.CameraSubject = nil
			CurrentCamera.CFrame = camPart.CFrame
			CurrentCamera.Focus = camPart.CFrame
			CameraController.setFOVLock("TeamSelectScene", true, 70)
			CameraController.setMouseEnabled(true)
			maid3:Add(RunServiceController.BindToRenderStep("MenuSceneController.TeamSelectCameraUpdate", function()
				CurrentCamera.CFrame = camPart.CFrame
				CurrentCamera.Focus = camPart.CFrame
			end), "Disconnect", "TeamSelectCameraUpdate")

			for _, v17 in ipairs(v4) do
				spawnTeamSelectCharacter(teamSelect, v17)
			end

			local total = 0
			maid3:Add(RunServiceController.BindToHeartbeat("MenuSceneController.TeamSelectGuard", function(p: number)
				total += p

				if total < 0.25 then
					return
				end

				total = 0

				if isCharacterAlive() or not isTeamSelectionActive() then -- inferred equivalent call
					MenuSceneController.HideTeamSelectScene()
				end
			end), "Disconnect", "TeamSelectGuard")
			return true
		else
			releaseSceneIfUnused() -- inferred equivalent call

			if not v6 then
				applyMapLighting() -- inferred equivalent call
			end

			return false
		end
	end
end

function MenuSceneController.HideTeamSelectScene()
	if not flag2 then
		return
	end

	maid3:Cleanup()
	CameraController.setFOVLock("TeamSelectScene", false)
	flag2 = false
	v11 = nil
	releaseSceneIfUnused() -- inferred equivalent call

	if not v6 then
		applyMapLighting() -- inferred equivalent call
		CurrentCamera.CameraType = Enum.CameraType.Custom
	end
end

function MenuSceneController.StopMenuMusic()
	if v13 then
		v13:Stop()
		v13 = nil
	end

	if v12 then
		v12:destroy()
		v12 = nil
	end
end

function MenuSceneController.SetMusicVolumeMultiplier(p: number, duration: number?)
	v14 = p

	if not v13 then
		return
	end

	if v15 then
		v15:Cancel()
		v15 = nil
	end

	local baseVolume = v13:GetAttribute("BaseVolume") or 0.1
	local volumeMultipliers, v17 = getVolumeMultipliers() -- inferred equivalent call
	local volume = baseVolume * volumeMultipliers * v17 * v14

	if not (duration and duration > 0) then
		v13.Volume = volume
		return
	end

	local tween = TweenService:Create(v13, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Volume = volume
	})
	v15 = tween
	tween:Play()
end

MenuSceneController.ApplyMapLighting = applyMapLighting

function MenuSceneController.ApplyMenuSceneLighting()
	local randomMenuScene = getRandomMenuScene()

	if randomMenuScene then
		applySceneLighting(randomMenuScene.Name) -- inferred equivalent call
		Lighting.GlobalShadows = true
	end
end

function MenuSceneController.GetMenuCharacterTeam()
	if v8 == "CT" then
		return "Counter-Terrorists"
	elseif v8 == "T" then
		return "Terrorists"
	end

	return nil
end

function MenuSceneController.CreateStandaloneCharacter(p: string?)
	local v17 = p or math.random(1, 2) == 1 and "CT" or "T"
	local v18 = v3[v17]
	local child = Characters:FindFirstChild(v18.Character)

	if not child then
		warn(`[MenuSceneController]: Character "{v18.Character}" not found`)
		return nil
	end

	local clone = child:Clone()
	clone.Name = "StandaloneCharacter"
	clone.Parent = ReplicatedStorage
	attachGlovesToCharacter(clone, v17, true)
	return clone
end

local function showIfNeeded() -- 4 equivalent calls inferred from this helper
	if shouldShowMenuScene() then
		MenuSceneController.ShowMenuScene()
	end
end

local function recheckLater() -- 2 equivalent calls inferred from this helper
	task.delay(0.1, showIfNeeded)
end

function MenuSceneController.Initialize()
	DataController.CreateListener(LocalPlayer, "Settings.Video.Presets.Global Shadows", applyGlobalShadowsSetting)
	DataController.CreateListener(LocalPlayer, "Settings.Audio.Audio.Main Menu Ambience Volume", updateMenuMusicVolume)
	DataController.CreateListener(LocalPlayer, "Settings.Audio.Audio.Master Volume", updateMenuMusicVolume)
	showIfNeeded() -- inferred equivalent call
	task.defer(function()
		if not v then
			local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)
			v = EndScreenController
		end
	end)
	CharacterResolver.observeCharacter(LocalPlayer, function(instance, p)
		if p and p ~= instance then
			recheckLater() -- inferred equivalent call
		end

		if not instance then
			return function() end
		end

		if shouldShowMenuScene() then
			MenuSceneController.ShowMenuScene()
		else
			MenuSceneController.StopMenuMusic()
			MenuSceneController.HideMenuScene()
		end

		local deadChangedConnection = instance:GetAttributeChangedSignal("Dead"):Connect(function()
			if instance:GetAttribute("Dead") == true then
				recheckLater() -- inferred equivalent call
			end
		end)
		return function()
			deadChangedConnection:Disconnect()
		end
	end)
	Observers.observeAttribute(LocalPlayer, "IsSpectating", function(p)
		if p then
			MenuSceneController.HideMenuScene()
		else
			showIfNeeded() -- inferred equivalent call
		end

		return showIfNeeded
	end)
	Observers.observeAttribute(LocalPlayer, "Team", function(p)
		if p == "Counter-Terrorists" or p == "Terrorists" then
			MenuSceneController.HideMenuScene()
		else
			showIfNeeded() -- inferred equivalent call
		end

		return recheckLater
	end)

	local function updateMenuCharacterLoadout()
		if not (v7 and v8) then
			return
		end

		if v9 and v9.Parent then
			v9:Destroy()
			v9 = nil
		end

		local rightHand = v7:FindFirstChild("RightHand")
		local weaponAttachment = rightHand and rightHand:FindFirstChild("WeaponAttachment")

		if weaponAttachment then
			weaponAttachment:Destroy()
		end

		local characterArmor = v7:FindFirstChild("CharacterArmor")

		if characterArmor then
			for _, part in ipairs(characterArmor:GetChildren()) do
				if part:IsA("BasePart") and part:FindFirstChild("GloveAttachment") then
					part:Destroy()
				end
			end
		end

		v9 = attachWeaponToCharacter(v7, v8, true)
		attachGlovesToCharacter(v7, v8, true)
		configureMenuDisplayCharacter(v7)
	end

	local listener = DataController.CreateListener(LocalPlayer, "Loadout", updateMenuCharacterLoadout)
	maid:Add(function()
		DataController.RemoveListener(LocalPlayer, "Loadout", listener)
	end, true, "LoadoutListener")
	local GameState = require(ReplicatedStorage.Database.Components.GameState)
	local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
	GameState.ListenToState(function(_, p)
		if p == "Game Ending" or p == "Map Voting" then
			if LocalPlayer:GetAttribute("IsSpectating") then
				SpectateController.Stop(false, true)
			end

			showIfNeeded() -- inferred equivalent call
		end
	end)
end

function MenuSceneController.Start() end

return MenuSceneController