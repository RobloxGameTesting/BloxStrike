local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Sound = require(ReplicatedStorage.Classes.Sound)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local FlashEffect = require(ReplicatedStorage.Components.Common.VFXLibary.FlashEffect)
local MovementSounds = require(script.MovementSounds)
local CurrentCamera = Workspace.CurrentCamera
local _ = { WeaponSuppressed = 50, Weapon = 120, Melee = 50 }
local v = {}
local v2 = { "Knife", "Bayonet", "Karambit", "Daggers" }
local v3 = {
	Headshot = 1,
	Humiliation = 2,
	MultiKill = 3,
	KillSpree = 4,
	Rampage = 5,
	Dominating = 6,
	["Monster Kill"] = 7,
	LudicrusKill = 8,
	Unstoppable = 9,
	Godlike = 10
}
local v4 = {
	[2] = "MultiKill",
	[3] = "KillSpree",
	[4] = "Rampage",
	[5] = "Dominating",
	[6] = "Monster Kill",
	[7] = "LudicrusKill",
	[8] = "Unstoppable",
	[9] = "Godlike"
}
local count = 0
local v5 = nil
local v6 = 0
local v7 = nil

local function isMenuOpen() -- 3 equivalent calls inferred from this helper
	return MenuState.GetCurrentScreen() ~= nil
end

local function isKnifeWeapon(weapon: string)
	for _, v8 in ipairs(v2) do
		if string.find(weapon, v8) then
			return true
		end
	end

	return false
end

local function getSliderMultiplier(p: string) -- 7 equivalent calls inferred from this helper
	return (DataController.Get(LocalPlayer, p) or 50) / 50
end

local function getMasterMultiplier() -- 3 equivalent calls inferred from this helper
	return (DataController.Get(LocalPlayer, "Settings.Audio.Audio.Master Volume") or 100) / 100
end

local function storeBaseVolume(instance, p: number) -- 3 equivalent calls inferred from this helper
	local masterMultiplier = getMasterMultiplier() -- inferred equivalent call
	local volume = instance.Volume

	if p > 0 and masterMultiplier > 0 then
		volume = volume / (p * masterMultiplier) or volume
	end

	instance:SetAttribute("BaseVolume", volume)
	return volume
end

local function listenWhileAlive(instance, p: string, fn)
	local listener = DataController.CreateListener(LocalPlayer, p, fn)
	local listener2 = DataController.CreateListener(LocalPlayer, "Settings.Audio.Audio.Master Volume", fn)
	instance.Destroying:Once(function()
		DataController.RemoveListener(LocalPlayer, p, listener)
		DataController.RemoveListener(LocalPlayer, "Settings.Audio.Audio.Master Volume", listener2)
	end)
end

local function stopCurrentAccolade() -- 4 equivalent calls inferred from this helper
	if v5 then
		local v8 = v5
		v5 = nil
		v6 = 0

		if v8.Parent then
			v8:Stop()
			v8:Destroy()
		end
	end
end

local function pickAccolade(p)
	local v8 = v4[math.min(count, 9)]
	local v9 = not v8 and 0 or v3[v8] or 0

	if p.Headshot and v9 < 1 then
		v9 = 1
		v8 = "Headshot"
	end

	if p.Weapon and isKnifeWeapon(p.Weapon) and v9 < 2 then
		v8 = "Humiliation"
		v9 = 2
	end

	return v8, v9
end

local function stopBombPlantedMusic()
	if v7 then
		if v7.Parent then
			v7:Stop()
			v7:Destroy()
		end

		v7 = nil
	end
end

local function updateBombPlantedMusicVolume(p: number?)
	if v7 and v7.Parent then
		local v8 = (tonumber(p) or 50) / 50
		local v9 = (tonumber(DataController.Get(LocalPlayer, "Settings.Audio.Audio.Master Volume") or 100) or 100) / 100
		local baseVolume = v7:GetAttribute("BaseVolume")

		if typeof(baseVolume) ~= "number" then
			baseVolume = v7.Volume
		end

		v7.Volume = baseVolume * v8 * v9
	end
end

local function GetRollOffDistance(p, rollOffMaxDistance: number)
	if p and p.Properties then
		rollOffMaxDistance = p.Properties.RollOffMaxDistance or rollOffMaxDistance
	end

	return rollOffMaxDistance
end

local function GetWeaponAudio(childName: string)
	if v[childName] then
		return v[childName]
	end

	local child = ReplicatedStorage.Database.Audio.Weapons:FindFirstChild(childName)

	if not child then
		return nil
	end

	local success, result = pcall(require, child)

	if success and result then
		v[childName] = result
		return result
	end

	return nil
end

local SoundController = {}
SoundController.SetBombPlantedMusicVolume = updateBombPlantedMusicVolume

function SoundController.GetWeaponShootRange(childName: string, flag: boolean?)
	local result

	if v[childName] then
		result = v[childName]
	else
		local child = ReplicatedStorage.Database.Audio.Weapons:FindFirstChild(childName)

		if child then
			local success
			success, result = pcall(require, child)

			if success and result then
				v[childName] = result
			else
				result = nil
			end
		end
	end

	if result then
		if flag and result.Silencer then
			local silencer = result.Silencer
			return silencer and silencer.Properties and silencer.Properties.RollOffMaxDistance or 50
		end

		local shoot = result.Shoot
		return shoot and shoot.Properties and shoot.Properties.RollOffMaxDistance or 120
	elseif flag then
		return 50
	else
		return 120
	end
end

function SoundController.GetMeleeRange(childName: string)
	local result

	if v[childName] then
		result = v[childName]
	else
		local child = ReplicatedStorage.Database.Audio.Weapons:FindFirstChild(childName)

		if child then
			local success
			success, result = pcall(require, child)

			if success and result then
				v[childName] = result
			else
				result = nil
			end
		end
	end

	if not result then
		return 50
	end

	local hitOne = result.HitOne
	return hitOne and hitOne.Properties and hitOne.Properties.RollOffMaxDistance or 50
end

function SoundController.Initialize()
	for _, moduleScript in ipairs(ReplicatedStorage.Database.Audio:GetDescendants()) do
		if moduleScript:IsA("ModuleScript") then
			Sound.createSoundGroup(moduleScript)
		end
	end

	task.spawn(Sound.WarmPersistentSounds)
	Router.observerRouter("RunRoundSound", function(name: string)
		if isMenuOpen() then -- inferred equivalent call
			return
		else
			return Sound.new("Round"):playOneTime({ Parent = CurrentCamera, Name = name })
		end
	end)
	Router.observerRouter("PlayCountdownTimer", function()
		local v8 = (DataController.Get(LocalPlayer, "Settings.Audio.Music.Main Menu Volume") or 100) / 100

		if MenuState.GetCurrentScreen() == nil and v8 > 0 then
			Sound.new("Interface"):playOneTime({
				Parent = LocalPlayer.PlayerGui,
				Name = "Countdown Timer"
			}, v8)
		end

		return nil
	end)
	local v8 = nil
	local connection = nil
	local lastTime = nil

	local function getBuyPhaseFadeMultiplier(p: number) -- 3 equivalent calls inferred from this helper
		if p < 6 then
			return 1
		end

		return (math.max(0, 1 - (p - 6) * 0.2))
	end

	local function disconnectBuyPhaseFade() -- 3 equivalent calls inferred from this helper
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	local function stopBuyPhaseSound() -- 2 equivalent calls inferred from this helper
		if v8 then
			disconnectBuyPhaseFade() -- inferred equivalent call

			if v8.Parent then
				v8:Stop()
				v8:Destroy()
			end

			v8 = nil
			lastTime = nil
		end
	end

	local function updateBuyPhaseVolume(flag: boolean?)
		if not (v8 and v8.Parent) then
			return
		end

		local sliderMultiplier = getSliderMultiplier("Settings.Audio.Music.Round Start Volume") -- inferred equivalent call
		local masterMultiplier = getMasterMultiplier() -- inferred equivalent call
		local baseVolume = v8:GetAttribute("BaseVolume") or v8.Volume
		local v9

		if flag and lastTime then
			v9 = getBuyPhaseFadeMultiplier(tick() - lastTime) -- inferred equivalent call
		else
			v9 = 1
		end

		v8.Volume = baseVolume * sliderMultiplier * masterMultiplier * v9

		if flag and lastTime and getBuyPhaseFadeMultiplier(tick() - lastTime) <= 0 and v8 then -- inferred equivalent call
			disconnectBuyPhaseFade() -- inferred equivalent call

			if v8.Parent then
				v8:Stop()
				v8:Destroy()
			end

			v8 = nil
			lastTime = nil
		end
	end

	local function playBuyPhaseSound()
		local team = LocalPlayer:GetAttribute("Team")

		if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
			return
		end

		stopBuyPhaseSound() -- inferred equivalent call
		local sliderMultiplier = getSliderMultiplier("Settings.Audio.Music.Round Start Volume") -- inferred equivalent call
		v8 = Sound.new("Round"):play({ Parent = CurrentCamera, Name = "Buy Phase" }, sliderMultiplier)

		if not v8 then
			return
		end

		local v9 = v8
		v9.Destroying:Once(function()
			if v8 == v9 then
				v8 = nil
				lastTime = nil
			end
		end)
		storeBaseVolume(v9, sliderMultiplier) -- inferred equivalent call
		lastTime = tick()
		task.spawn(function()
			connection = RunServiceController.BindToHeartbeat("SoundController.BuyPhaseFade", function()
				if v8 and v8.Parent then
					if not lastTime then
						return
					end

					local v10 = tick() - lastTime
					local v11 = v10 >= 6
					updateBuyPhaseVolume(v11)

					if v11 and (not (v8 and v8.Parent) or getBuyPhaseFadeMultiplier(v10) <= 0) and connection then -- inferred equivalent call
						connection:Disconnect()
						connection = nil
					end
				else
					disconnectBuyPhaseFade() -- inferred equivalent call
				end
			end)
		end)
	end

	GameState.ListenToState(function(_, p)
		if p == "Buy Period" then
			playBuyPhaseSound()
			return
		end

		stopBuyPhaseSound() -- inferred equivalent call
	end)

	local function onBuyPhaseSettingChanged()
		updateBuyPhaseVolume(connection ~= nil)
	end

	DataController.CreateListener(LocalPlayer, "Settings.Audio.Music.Round Start Volume", onBuyPhaseSettingChanged)
	DataController.CreateListener(LocalPlayer, "Settings.Audio.Audio.Master Volume", onBuyPhaseSettingChanged)
	Remotes.Sound.ReplicateSound.Listen(function(instance)
		local audioFadeMultiplier = FlashEffect.GetAudioFadeMultiplier()

		if DebugFlags.IsEnabled("WeaponFX") then
			local v9 = not (instance and instance.Name) and "" or tostring(instance.Name) or ""
			local v10 = not (instance and instance.Class) and "" or tostring(instance.Class) or ""
			local v11 = string.lower(v9)

			if string.find(v11, "shoot", 1, true) or string.find(v11, "fire", 1, true) then
				warn(("[WeaponFX][Client][Sound] recv class=%s name=%s flashed=%s parent=%s position=%s path=%s"):format(
					v10,
					v9,
					tostring(FlashEffect.IsFlashed()),
					tostring(instance and instance.Parent),
					tostring(instance and instance.Position),
					(tostring(instance and instance.Path))
				))
			end
		end

		local v9

		if instance.Name == "Bomb Planted Music" then
			v9 = instance.Class == "Counter-Terrorists"
		else
			v9 = false
		end

		if v9 and v7 then
			if v7.Parent then
				v7:Stop()
				v7:Destroy()
			end

			v7 = nil
		end

		if instance.Position then
			Sound.new(instance.Class):PlaySoundAtPosition(
				{ Position = instance.Position, Class = instance.Class, Name = instance.Name },
				tonumber(instance.Duration),
				audioFadeMultiplier
			)
			return
		end

		if not (instance.Parent or instance.Path) then
			return
		end

		local parent = instance.Parent

		if parent and parent:IsA("BasePart") and parent.Name == "Head" then
			local parent2 = parent.Parent

			if
				parent2
				and parent2:IsA("Model")
				and parent2:IsDescendantOf(workspace)
				and CharacterResolver.getPlayerFromCharacter(parent2) == LocalPlayer
			then
				if DebugFlags.IsEnabled("WeaponFX") then
					warn(("[WeaponFX][Client][Sound] skipped local duplicate head sound name=%s class=%s"):format(
						tostring(instance.Name),
						(tostring(instance.Class))
					))
				end

				return
			end
		end

		if
			(instance.Name == "Bomb Planted" or instance.Name == "Bomb Defused" or instance.Name == "Hostage Rescued")
			and isMenuOpen() -- inferred equivalent call
		then
			return
		end

		local v10

		if instance.Name == "Counter-Terrorists Win" or instance.Name == "Terrorists Win" then
			v10 = instance.Class == "Round"
		else
			v10 = false
		end

		if v9 then
			if GameState.GetState() ~= "Round In Progress" or MenuState.GetCurrentScreen() ~= nil then
				return
			end

			audioFadeMultiplier *= getSliderMultiplier("Settings.Audio.Music.Bomb/Hostage Volume") -- inferred equivalent call
		elseif v10 then
			if isMenuOpen() then -- inferred equivalent call
				return
			else
				audioFadeMultiplier *= getSliderMultiplier("Settings.Audio.Music.Round End Volume") -- inferred equivalent call
			end
		end

		local v11 = Sound.new(instance.Class):playOneTime(
			{ Parent = instance.Parent, Name = instance.Name, Path = instance.Path },
			audioFadeMultiplier
		)

		if not v11 then
			return
		end

		if v10 then
			local volume = storeBaseVolume(v11, getSliderMultiplier("Settings.Audio.Music.Round End Volume")) -- inferred equivalent call
			listenWhileAlive(v11, "Settings.Audio.Music.Round End Volume", function()
				if v11 and v11.Parent then
					local sliderMultiplier = getSliderMultiplier("Settings.Audio.Music.Round End Volume") -- inferred equivalent call
					local masterMultiplier = getMasterMultiplier() -- inferred equivalent call
					local baseVolume = v11:GetAttribute("BaseVolume") or volume
					v11.Volume = baseVolume * sliderMultiplier * masterMultiplier
				end
			end)
		elseif v9 then
			v7 = v11
			storeBaseVolume(v11, getSliderMultiplier("Settings.Audio.Music.Bomb/Hostage Volume")) -- inferred equivalent call
			listenWhileAlive(v11, "Settings.Audio.Music.Bomb/Hostage Volume", function()
				if v7 and v7.Parent then
					updateBombPlantedMusicVolume(DataController.Get(
						LocalPlayer,
						"Settings.Audio.Music.Bomb/Hostage Volume"
					) or 50)
				end
			end)
		end
	end)

	local function setupBombDefuseListener()
		local v9 = CollectionService:GetTagged("Bomb")[1]

		if v9 and v9:IsDescendantOf(workspace) then
			local defusedChangedConnection = nil
			defusedChangedConnection = v9:GetAttributeChangedSignal("Defused"):Connect(function()
				if v9:GetAttribute("Defused") then
					if v7 then
						if v7.Parent then
							v7:Stop()
							v7:Destroy()
						end

						v7 = nil
					end

					if defusedChangedConnection then
						defusedChangedConnection:Disconnect()
					end
				end
			end)
		end
	end

	CollectionService:GetInstanceAddedSignal("Bomb"):Connect(function()
		setupBombDefuseListener()
	end)
	task.defer(setupBombDefuseListener)
	GameState.ListenToState(function(_, p)
		if p ~= "Round In Progress" and v7 then
			if v7.Parent then
				v7:Stop()
				v7:Destroy()
			end

			v7 = nil
		end
	end)
	Remotes.UI.UIPlayerKilled.Listen(function(data)
		if workspace:GetAttribute("Gamemode") ~= "Deathmatch" then
			return
		end

		local userId = tostring(LocalPlayer.UserId)

		if data.Victim == userId then
			count = 0
			stopCurrentAccolade() -- inferred equivalent call
		else
			if data.Killer ~= userId then
				return
			end

			count += 1
			local name = v4[math.min(count, 9)]
			local headshot = not name and 0 or v3[name] or 0

			if data.Headshot and headshot < v3.Headshot then
				headshot = v3.Headshot
				name = "Headshot"
			end

			if data.Weapon and isKnifeWeapon(data.Weapon) and headshot < v3.Humiliation then
				headshot = v3.Humiliation
				name = "Humiliation"
			end

			if not name or headshot < v6 then
				return
			end

			stopCurrentAccolade() -- inferred equivalent call
			task.delay(0.2, function()
				if headshot < v6 then
					return
				end

				stopCurrentAccolade() -- inferred equivalent call
				local v9 = Sound.new("Deathmatch"):play({
					Parent = LocalPlayer.PlayerGui,
					Name = name
				})

				if v9 then
					v5 = v9
					v6 = headshot

					local function clearIfCurrent()
						if v5 == v9 then
							v5 = nil
							v6 = 0
						end
					end

					v9.Ended:Once(clearIfCurrent)
					v9.Destroying:Once(clearIfCurrent)
				end
			end)
		end
	end)
	Remotes.Sound.StopSoundAtPosition.Listen(function(p)
		local debris = workspace:FindFirstChild("Debris")

		if not debris then
			return
		end

		for _, part in ipairs(debris:GetChildren()) do
			if not (part.Name == "Sound" and part:IsA("BasePart") and (part.Position - p.Position).Magnitude <= p.Radius) then
				continue
			end

			part:Destroy()
		end
	end)
	Router.observerRouter("UpdatePlayerNoiseCone", function()
		return nil
	end)
end

function SoundController.Start()
	local v8 = MovementSounds.new(LocalPlayer)
	CharacterResolver.observeCharacter(LocalPlayer, function(p)
		if p then
			count = 0
			stopCurrentAccolade() -- inferred equivalent call
		end

		v8:SetCharacter(p)
		return function()
			v8:SetCharacter(nil)
		end
	end)
	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
	local v9 = { IsActive = MenuSceneController.IsTeamSelectSceneActive }
	local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
	local InspectController = require(ReplicatedStorage.Controllers.InspectController)
	local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
	local v10 = {
		MenuSceneController,
		v9,
		CaseSceneController,
		InspectController,
		BlackMarketSceneController
	}
	local gameplaySoundGroup = Sound.GameplaySoundGroup
	local v11 = false

	local function isAnySceneActive() -- 1 equivalent call inferred from this helper
		for _, v12 in v10 do
			if v12.IsActive() then
				return true
			end
		end

		return false
	end

	RunServiceController.BindToHeartbeat("SoundController.MovementSounds", function(p: number)
		v8:Update(p)
		local anySceneActive = isAnySceneActive() -- inferred equivalent call

		if anySceneActive ~= v11 then
			v11 = anySceneActive
			gameplaySoundGroup.Volume = anySceneActive and 0 or 1
		end
	end)
end

return SoundController