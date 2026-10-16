local SpectateController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local ClientCharacterPresentation = require(ReplicatedStorage.Components.Common.ClientCharacterPresentation)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local RemoteCharacters = require(ReplicatedStorage.Controllers.CharacterController.RemoteCharacters)
local IsPlayingTeam = require(ReplicatedStorage.Components.Common.IsPlayingTeam)
local CharacterActions = require(ReplicatedStorage.Database.Components.CharacterActions)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Spectate = require(ReplicatedStorage.Classes.Spectate)
local Freecam = require(ReplicatedStorage.Classes.Freecam)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Promise = require(ReplicatedStorage.Shared.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local CurrentCamera = workspace.CurrentCamera
local listenToSpectate = Signal.new()
SpectateController.ListenToSpectate = listenToSpectate
local listenToFreecam = Signal.new()
SpectateController.ListenToFreecam = listenToFreecam
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local v = { "TeamSelection", "BuyMenu", "Leaderboard", "Votekick", "VIPMenu" }
local v2 = "First-Person"
local v3 = {}
local total = 0
local flag = false
local v4 = 1
local v5 = 1
local v6 = 0
local v7 = 0
local v8 = nil
local now = 0
local v9 = nil
local v10 = nil
local v11 = { "First-Person", "Third-Person", "Free-Cam" }
local v12 = nil
local v13 = nil

local function GetCurrentGamemode() -- 1 equivalent call inferred from this helper
	local serverGamemode = workspace:GetAttribute("ServerGamemode")

	if serverGamemode == "Competitive" or serverGamemode == "Deathmatch" then
		return serverGamemode
	end

	return "Casual"
end

local function IsOnPlayingTeam(instance) -- 14 equivalent calls inferred from this helper
	return IsPlayingTeam(instance:GetAttribute("Team"))
end

local function HasAliveCharacterReplicated(instance) -- 12 equivalent calls inferred from this helper
	if Participants.IsBot(instance) then
		return Participants.IsAlive(instance)
	end

	return CharacterResolver.isAlivePlayer(instance)
end

local function IsCharacterAlive(instance)
	if not IsOnPlayingTeam(instance) or instance == LocalPlayer and flag then -- inferred equivalent call
		return false
	end

	return HasAliveCharacterReplicated(instance)
end

local function IsCompetitiveRestrictedLocalSpectate() -- 6 equivalent calls inferred from this helper
	local serverGamemode = workspace:GetAttribute("ServerGamemode")
	local v14

	if (serverGamemode ~= "Competitive" and serverGamemode ~= "Deathmatch" and "Casual" or serverGamemode) == "Competitive" then
		v14 = IsOnPlayingTeam(LocalPlayer) -- inferred equivalent call

		if v14 then
			local v15 = LocalPlayer
			local v16

			if IsOnPlayingTeam(v15) and (v15 ~= LocalPlayer or not flag) then -- inferred equivalent call
				v16 = HasAliveCharacterReplicated(v15) -- inferred equivalent call
			else
				v16 = false
			end

			return not v16
		end
	else
		return false
	end

	return v14
end

local function DestroyFreecam() -- 5 equivalent calls inferred from this helper
	if v13 then
		v13:Destroy()
		v13 = nil
	end
end

local function ResetSpectatePerspective() -- 3 equivalent calls inferred from this helper
	v2 = "First-Person"
	v4 = 1
end

local function EnforceCompetitiveSpectatePerspective() -- 1 equivalent call inferred from this helper
	if not IsCompetitiveRestrictedLocalSpectate() then -- inferred equivalent call
		return
	end

	ResetSpectatePerspective() -- inferred equivalent call

	if v12 and v12.PerspectiveState ~= "First-Person" then
		v12:Switch("First-Person")
	end

	DestroyFreecam() -- inferred equivalent call
end

local function IsValidSpectateTargetForLocalPlayer(instance) -- 3 equivalent calls inferred from this helper
	if instance == LocalPlayer then
		return false
	end

	local v14

	if IsOnPlayingTeam(instance) and (instance ~= LocalPlayer or not flag) then -- inferred equivalent call
		v14 = HasAliveCharacterReplicated(instance) -- inferred equivalent call
	else
		v14 = false
	end

	if v14 then
		return not IsCompetitiveRestrictedLocalSpectate() -- inferred equivalent call
			or LocalPlayer:GetAttribute("Team") == instance:GetAttribute("Team")
	end

	return false
end

local function GetSpectateBombModel()
	for _, model in ipairs(CollectionService:GetTagged("Bomb")) do
		if model:IsA("Model") and model.PrimaryPart and model:IsDescendantOf(workspace) then
			return model
		end
	end

	return nil
end

local function StopBombSpectate() -- 8 equivalent calls inferred from this helper
	if v10 and LocalPlayer.ReplicationFocus == v10 then
		LocalPlayer.ReplicationFocus = nil
	end

	v9 = nil
	v10 = nil
end

local function RenderBombSpectate() -- 1 equivalent call inferred from this helper
	local v14 = v9

	if not (v14 and v14.Parent) then
		return false
	end

	local primaryPart = v14.PrimaryPart

	if not primaryPart then
		return false
	end

	if v10 ~= primaryPart then
		v10 = primaryPart
		LocalPlayer.ReplicationFocus = primaryPart
	end

	CurrentCamera.CameraType = Enum.CameraType.Follow
	CurrentCamera.CameraSubject = primaryPart
	return true
end

local function GetKillerPlayer()
	local lastKiller = LocalPlayer:GetAttribute("LastKiller")
	local lastKillerKey = LocalPlayer:GetAttribute("LastKillerKey")

	if lastKiller or lastKillerKey then
		LocalPlayer:SetAttribute("LastKiller", nil)
		LocalPlayer:SetAttribute("LastKillerKey", nil)
		local v14 = Participants.FromKey(lastKillerKey) or lastKiller and Participants.FromName(lastKiller)

		if v14 and IsValidSpectateTargetForLocalPlayer(v14) then -- inferred equivalent call
			return v14
		end
	end

	return nil
end

local function IsReturningToMainMenu()
	if not MenuState.WantsMainMenu() then
		return false
	end

	local menuFrame = MenuState.GetMenuFrame()
	return menuFrame ~= nil and menuFrame.Visible == true
end

local function ShouldBeSpectating()
	if MenuState.IsCaseSceneActive() then
		return false
	end

	local v14

	if MenuState.WantsMainMenu() then
		local menuFrame = MenuState.GetMenuFrame()

		if menuFrame == nil then
			v14 = false
		else
			v14 = menuFrame.Visible == true
		end
	else
		v14 = false
	end

	if v14 then
		return false
	end

	local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)

	if EndScreenController.IsActive() then
		return false
	end

	local v15 = LocalPlayer
	local v16

	if IsOnPlayingTeam(v15) and (v15 ~= LocalPlayer or not flag) then -- inferred equivalent call
		v16 = HasAliveCharacterReplicated(v15) -- inferred equivalent call
	else
		v16 = false
	end

	if v16 or not IsOnPlayingTeam(LocalPlayer) then -- inferred equivalent call
		return false
	end

	local GameState = require(ReplicatedStorage.Database.Components.GameState)
	local state = GameState.GetState()
	return state ~= "Game Ending" and state ~= "Map Voting"
end

local function SpectateKillerOrNext() -- 2 equivalent calls inferred from this helper
	local killerPlayer = GetKillerPlayer()

	if killerPlayer then
		SpectateController.SetNextPlayer(killerPlayer)
	else
		SpectateController.Next()
	end
end

local function StartSpectatingOnDeath()
	if not ShouldBeSpectating() then
		return
	end

	local localCharacter = CharacterResolver.getLocalCharacter()

	if localCharacter then
		Ragdoll.HideCharacterLocally(localCharacter)
	end

	if v12 or v13 then
		return
	end

	CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	CameraController.setPerspective(true, false)
	SpectateKillerOrNext() -- inferred equivalent call
end

local function UpdateCharacters()
	local v14 = GetCurrentGamemode() == "Competitive" -- inferred equivalent call
	local team = LocalPlayer:GetAttribute("Team")
	table.clear(v3)

	for _, v15 in ipairs((Participants.GetAll())) do
		if not ((not v14 or team == "Spectators" or v15:GetAttribute("Team") == team) and v15 ~= LocalPlayer) then
			continue
		end

		local v16

		if IsOnPlayingTeam(v15) and (v15 ~= LocalPlayer or not flag) then -- inferred equivalent call
			v16 = HasAliveCharacterReplicated(v15) -- inferred equivalent call
		else
			v16 = false
		end

		if v16 then
			table.insert(v3, v15)
		end
	end
end

local function IncrementSpectateIndex(p: number) -- 2 equivalent calls inferred from this helper
	UpdateCharacters()

	if #v3 > 0 then
		local v14 = v8 or v12 and v12.Player
		local index = v14 and table.find(v3, v14)

		if index then
			v5 = index
		end

		v5 += p

		if v5 <= 0 then
			v5 = #v3
		elseif v5 > #v3 then
			v5 = 1
		end
	end
end

local function IsSpectateInputBlockedByUi()
	if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() ~= nil then
		return true
	end

	local menuFrame = MenuState.GetMenuFrame()

	if menuFrame and menuFrame.Visible then
		return true
	end

	local mainGui = MenuState.GetMainGui()

	if not mainGui then
		return false
	end

	local gameplay = mainGui:FindFirstChild("Gameplay")
	local middle = gameplay and gameplay:FindFirstChild("Middle")

	if not middle then
		return false
	end

	for _, childName in v do
		local guiObject = middle:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") and guiObject.Visible then
			return true
		end
	end

	return false
end

local function ReleaseMenuMouseLock() -- 1 equivalent call inferred from this helper
	if IsSpectateInputBlockedByUi() or MenuState.IsCaseSceneActive() or MenuState.IsInspectActive() then
		return
	end

	CameraController.resetForceLockOverride()
end

function SpectateController.GetCurrentSpectateInstance()
	return v12
end

function SpectateController.IsLocalPlayerDead()
	return flag
end

function SpectateController.IsTakingOverCamera()
	local v14

	if MenuState.WantsMainMenu() then
		local menuFrame = MenuState.GetMenuFrame()

		if menuFrame == nil then
			v14 = false
		else
			v14 = menuFrame.Visible == true
		end
	else
		v14 = false
	end

	return not v14 and (ShouldBeSpectating() or LocalPlayer:GetAttribute("IsSpectating") == true)
end

function SpectateController.IsFreecamActive()
	if v13 == nil then
		if v12 == nil then
			return false
		else
			return v12.FreecamInstance ~= nil
		end
	else
		return true
	end
end

function SpectateController.CanSwitchPerspective()
	return v12 ~= nil and not IsCompetitiveRestrictedLocalSpectate() -- inferred equivalent call
end

function SpectateController.IsSpectatingNow()
	return v12 ~= nil or v13 ~= nil or LocalPlayer:GetAttribute("IsSpectating") == true
end

function SpectateController.GetPlayer()
	local v14 = LocalPlayer
	local v15

	if IsOnPlayingTeam(v14) and (v14 ~= LocalPlayer or not flag) then -- inferred equivalent call
		v15 = HasAliveCharacterReplicated(v14) -- inferred equivalent call
	else
		v15 = false
	end

	if v15 then
		return LocalPlayer
	end

	if v12 then
		return v12.Player
	end

	return nil
end

function SpectateController.SetNextPlayer(instance)
	local player = v12 and v12.Player
	v8 = nil

	if not IsValidSpectateTargetForLocalPlayer(instance) then -- inferred equivalent call
		SpectateController.Next()
		return
	end

	local isBot = Participants.IsBot(instance)
	local send = Remotes.Spectate.SpectatePlayer.Send
	local v14

	if isBot then
		v14 = tostring(Participants.Key(instance))
	else
		v14 = instance.Name
	end

	send(v14)
	local v15

	if isBot then
		v15 = Participants.Character(instance)
	else
		v15 = CharacterResolver.getPlayerCharacter(instance)
	end

	if isBot and not CharacterResolver.isAliveCharacter(v15) then
		v8 = instance
		now = os.clock()
	else
		local v16 = player == instance
		local v17 = v12 and v12.Character == v15
		local v18

		if IsOnPlayingTeam(instance) and (instance ~= LocalPlayer or not flag) then -- inferred equivalent call
			v18 = HasAliveCharacterReplicated(instance) -- inferred equivalent call
		else
			v18 = false
		end

		if v16 and v17 and v18 then
			if not isBot then
				RemoteCharacters.SetPinnedPlayer(instance)
			end
		else
			SpectateController.Stop(false, true)

			if not isBot then
				RemoteCharacters.SetPinnedPlayer(instance)
				local attribute = instance:GetAttribute(CharacterGeneration.AttributeName)

				if typeof(attribute) == "number" then
					ClientCharacterPresentation.Create(instance, attribute)
				end

				v15 = CharacterResolver.getPlayerCharacter(instance)
			end

			if v15 and v18 and CharacterResolver.resolve(v15) then
				local v19 = IsCompetitiveRestrictedLocalSpectate() and "First-Person" or v2 -- inferred equivalent call
				local v20

				if isBot then
					v20 = Spectate.newBot(instance, v15, v19)
				else
					v20 = Spectate.new(instance, v15, v19)
				end

				v12 = v20

				if v2 ~= "First-Person" then
					v20:Switch(v2)
				end

				SpectateController.ListenToSpectate:Fire(instance)
				v20.StopSpectating:Once(function()
					SpectateController.Stop(false, true)
					SpectateController.Next()
				end)
			else
				RemoteCharacters.SetPinnedPlayer(nil)
				SpectateController.Next()
			end
		end
	end
end

function SpectateController.Switch()
	if IsCompetitiveRestrictedLocalSpectate() then -- inferred equivalent call
		ResetSpectatePerspective() -- inferred equivalent call

		if v12 then
			v12:Switch("First-Person")
		end

		DestroyFreecam() -- inferred equivalent call
	else
		v4 = v4 + 1 > #v11 and 1 or v4 + 1
		v2 = v11[v4]

		if v12 then
			v12:Switch(v2)
		end
	end
end

function SpectateController.UpdateIndex(p: number)
	IncrementSpectateIndex(p) -- inferred equivalent call
	return Promise.new(function(callback, callback2)
		local v14 = v3[v5]

		if v14 then
			local v15

			if IsOnPlayingTeam(v14) and (v14 ~= LocalPlayer or not flag) then -- inferred equivalent call
				v15 = HasAliveCharacterReplicated(v14) -- inferred equivalent call
			else
				v15 = false
			end

			if v15 then
				callback(v14)
				return
			end
		end

		UpdateCharacters()

		if #v3 > 0 then
			v5 = 1
			callback(v3[1])
		else
			SpectateController.Stop(false, false)
			callback2("No players alive to spectate")
		end
	end)
end

local function SpectateByOffset(p: number)
	return SpectateController.UpdateIndex(p):andThen(function(p2)
		SpectateController.SetNextPlayer(p2)
	end):catch(function() end)
end

function SpectateController.Next()
	return SpectateByOffset(1)
end

function SpectateController.Previous()
	return SpectateByOffset(-1)
end

function SpectateController.IsControllerPress(p)
	if string.match(p.UserInputType.Name, "^Gamepad%d+$") then
		return true
	end

	for _, v14 in UserInputService:GetConnectedGamepads() do
		for _, v15 in UserInputService:GetGamepadState(v14) do
			if
				(v15.KeyCode == Enum.KeyCode.ButtonR2 or v15.KeyCode == Enum.KeyCode.ButtonL2)
				and v15.Position.Z > 0.1
			then
				return true
			end
		end
	end

	return false
end

function SpectateController.RequestSwitch(p: number)
	if not SpectateController.IsSpectatingNow() then
		return
	end

	local v14 = LocalPlayer
	local v15

	if IsOnPlayingTeam(v14) and (v14 ~= LocalPlayer or not flag) then -- inferred equivalent call
		v15 = HasAliveCharacterReplicated(v14) -- inferred equivalent call
	else
		v15 = false
	end

	if v15 and v12 == nil and v13 == nil then
		return
	end

	local now2 = os.clock()

	if now2 - v7 < 0.15 then
		return
	end

	v7 = now2

	if p < 0 then
		SpectateController.Previous()
	else
		SpectateController.Next()
	end
end

function SpectateController.Stop(flag2: boolean, flag3: boolean)
	StopBombSpectate() -- inferred equivalent call
	RemoteCharacters.SetPinnedPlayer(nil)
	v8 = nil

	if v12 then
		v12:Destroy()
		v12 = nil
	end

	if flag2 and LocalPlayer:GetAttribute("IsSpectating") then
		Remotes.Spectate.StopSpectating.Send()
	end

	if flag3 and v13 then
		v13:Destroy()
		v13 = nil
	end

	listenToSpectate:Fire()
end

function SpectateController.Broadcast()
	local spectators = LocalPlayer:GetAttribute("Spectators")
	local v14 = spectators and spectators > 0 and 1 / 60 or 0.2

	if v14 <= v6 then
		local currentEquipped = InventoryController.getCurrentEquipped()
		v6 -= v14

		if currentEquipped then
			local menu = LocalPlayer.PlayerGui:FindFirstChild("MainGui")
				and LocalPlayer.PlayerGui.MainGui:FindFirstChild("Menu")
			local inspect = menu and menu:FindFirstChild("Inspect")

			if
				inspect and inspect.Visible
				or MenuState.IsCaseSceneActive()
				or BlackMarketSceneController.IsActive()
			then
				return
			else
				Remotes.Spectate.UpdateCameraCFrame.Send({
					CameraCFrame = CurrentCamera.CFrame,
					UserId = LocalPlayer.UserId
				})
			end
		end
	end
end

local function UpdatePendingBotTarget()
	local v14 = v8

	if not v14 then
		return
	end

	if CharacterResolver.isAliveCharacter(Participants.Character(v14)) then
		SpectateController.SetNextPlayer(v14)
	elseif not IsValidSpectateTargetForLocalPlayer(v14) or os.clock() - now > 1.5 then -- inferred equivalent call
		v8 = nil

		if v12 then
			SpectateController.SetNextPlayer(v12.Player)
		end
	end
end

function SpectateController.Render(p: number)
	total += p
	v6 += p
	local competitiveRestrictedLocalSpectate = IsCompetitiveRestrictedLocalSpectate() -- inferred equivalent call

	if competitiveRestrictedLocalSpectate then
		EnforceCompetitiveSpectatePerspective() -- inferred equivalent call
	end

	if flag and HasAliveCharacterReplicated(LocalPlayer) then -- inferred equivalent call
		flag = false
	end

	local v14 = LocalPlayer
	local v15

	if IsOnPlayingTeam(v14) and (v14 ~= LocalPlayer or not flag) then -- inferred equivalent call
		v15 = HasAliveCharacterReplicated(v14) -- inferred equivalent call
	else
		v15 = false
	end

	if v15 then
		SpectateController.Broadcast()
		StopBombSpectate() -- inferred equivalent call

		if v12 then
			SpectateController.Stop(true, true)
		end

		DestroyFreecam() -- inferred equivalent call
		local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)
		local v16 = LocalPlayer
		local v17

		if IsOnPlayingTeam(v16) and (v16 ~= LocalPlayer or not flag) then -- inferred equivalent call
			v17 = HasAliveCharacterReplicated(v16) -- inferred equivalent call
		else
			v17 = false
		end

		if not v17 or BlackMarketSceneController.IsActive() or EndScreenController.IsActive() then
			return
		end

		local localCharacter = CharacterResolver.getLocalCharacter()
		local cameraSubject = CharacterResolver.getCameraPart(localCharacter)
			or CharacterResolver.getRootPart(localCharacter)

		if cameraSubject then
			CurrentCamera.CameraType = Enum.CameraType.Custom
			CurrentCamera.CameraSubject = cameraSubject
		end

		CameraController.setPerspective(true, false)
	else
		if ShouldBeSpectating() or LocalPlayer:GetAttribute("IsSpectating") then
			local v16

			if MenuState.WantsMainMenu() then
				local menuFrame = MenuState.GetMenuFrame()

				if menuFrame == nil then
					v16 = false
				else
					v16 = menuFrame.Visible == true
				end
			else
				v16 = false
			end

			if not v16 then
				if MenuState.IsCaseSceneActive() or BlackMarketSceneController.IsActive() then
					return
				end

				if
					UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter
					and not (IsSpectateInputBlockedByUi() or MenuState.IsCaseSceneActive() or MenuState.IsInspectActive())
				then
					CameraController.resetForceLockOverride()
				end

				UpdatePendingBotTarget()

				if v12 then
					StopBombSpectate() -- inferred equivalent call

					if Router.broadcastRouter("IsInspectActive") then
						return
					end

					v12:Render(p)
					DestroyFreecam() -- inferred equivalent call
				else
					if total >= 0.2 then
						total = 0
						IncrementSpectateIndex(1) -- inferred equivalent call
					end

					if v8 then
						return
					end

					if v3[v5] then
						StopBombSpectate() -- inferred equivalent call
						SpectateController.Next()
						return
					elseif competitiveRestrictedLocalSpectate then
						if not (v9 and v9.Parent) then
							v9 = GetSpectateBombModel()

							if v9 then
								CameraController.setPerspective(false, false)
								CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
							end
						end

						if v9 then
							if not RenderBombSpectate() then -- inferred equivalent call
								StopBombSpectate() -- inferred equivalent call
							end
						else
							StopBombSpectate() -- inferred equivalent call
						end

						DestroyFreecam() -- inferred equivalent call
						return
					else
						StopBombSpectate() -- inferred equivalent call

						if not v13 then
							local v17 = Freecam.new()
							v13 = v17
							v17:Start()
							listenToFreecam:Fire(true)
							return
						end
					end
				end

				return
			end
		end

		if v12 then
			SpectateController.Stop(false, true)
			return
		end

		StopBombSpectate() -- inferred equivalent call
	end
end

function SpectateController.Initialize()
	Observers.observeAttribute(LocalPlayer, "IsSpectating", function(p)
		if p then
			LocalPlayer:SetAttribute("PendingSpectateRequestAt", nil)

			if not MenuState.IsCaseSceneActive() then
				local v14

				if MenuState.WantsMainMenu() then
					local menuFrame = MenuState.GetMenuFrame()

					if menuFrame == nil then
						v14 = false
					else
						v14 = menuFrame.Visible == true
					end
				else
					v14 = false
				end

				if not v14 then
					ReleaseMenuMouseLock() -- inferred equivalent call
					CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
					CameraController.setPerspective(true, false)

					if not v12 then
						SpectateKillerOrNext() -- inferred equivalent call
					end
				end
			end
		end

		return function()
			SpectateController.Stop(false, true)
		end
	end)
	Remotes.Character.CharacterDied.Listen(function()
		if HasAliveCharacterReplicated(LocalPlayer) then -- inferred equivalent call
			flag = false
			return
		end

		flag = true
		StartSpectatingOnDeath()
	end)
	LocalPlayer.CharacterAdded:Connect(function(character)
		flag = false
		local onPlayingTeam = IsOnPlayingTeam(LocalPlayer) -- inferred equivalent call
		local aliveCharacter = CharacterResolver.isAliveCharacter(character)
		local pendingSpectateRequestAt = LocalPlayer:GetAttribute("PendingSpectateRequestAt")
		local v14

		if pendingSpectateRequestAt == nil then
			v14 = false
		else
			v14 = os.clock() - pendingSpectateRequestAt < 3
		end

		if onPlayingTeam and aliveCharacter then
			MenuState.SetWantsMainMenu(false)
			ResetSpectatePerspective() -- inferred equivalent call
			SpectateController.Stop(not v14, true)

			if not v14 and LocalPlayer:GetAttribute("IsSpectating") then
				Remotes.Spectate.StopSpectating.Send()
			end
		elseif v12 and v12.Player then
			local send = Remotes.Spectate.SpectatePlayer.Send
			local v15

			if v12.IsBot then
				v15 = tostring(Participants.Key(v12.Player))
			else
				v15 = v12.Player.Name
			end

			send(v15)
		end

		local deadChangedConnection = character:GetAttributeChangedSignal("Dead"):Connect(function()
			if character:GetAttribute("Dead") then
				StartSpectatingOnDeath()
			end
		end)
		local ancestryChangedConnection = nil
		ancestryChangedConnection = character.AncestryChanged:Connect(function(_, parent)
			if not parent then
				deadChangedConnection:Disconnect()
				ancestryChangedConnection:Disconnect()
			end
		end)
	end)
	local GameState = require(ReplicatedStorage.Database.Components.GameState)
	GameState.ListenToState(function(_, p)
		if p == "Game Ending" or p == "Map Voting" then
			SpectateController.Stop(false, true)
		end
	end)
	RunServiceController.BindToRenderStep("SpectateController.Render", function(p: number)
		SpectateController.Render(p)
	end)
end

function SpectateController.Start()
	Remotes.Character.Action.Listen(function(data)
		if not v12 or typeof(data) ~= "table" then
			return
		end

		local playerByUserId

		if typeof(data.UserId) == "number" then
			playerByUserId = Players:GetPlayerByUserId(data.UserId)
		end

		if
			not playerByUserId
			or playerByUserId ~= v12.Player
			or CharacterGeneration.Get(playerByUserId.Character) ~= data.Generation
		then
			return
		end

		local name = CharacterActions.ToName(data.ActionId)

		if name then
			v12:AddSpectateEvent(name)
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if LocalPlayer:GetAttribute("IsPlayerChatting") or not SpectateController.IsSpectatingNow() then
			return
		end

		if input.KeyCode == Enum.KeyCode.Space then
			SpectateController.Switch()
		elseif input.KeyCode == Enum.KeyCode.ButtonA then
			if not IsSpectateInputBlockedByUi() and GuiService.SelectedObject == nil then
				SpectateController.Switch()
			end
		else
			local v14 = input.KeyCode == Enum.KeyCode.ButtonL1

			if v14 or input.KeyCode == Enum.KeyCode.ButtonR1 then
				if not IsSpectateInputBlockedByUi() then
					SpectateController.RequestSwitch(v14 and -1 or 1)
				end
			else
				local v15 = input.UserInputType == Enum.UserInputType.MouseButton1
				local v16 = input.UserInputType == Enum.UserInputType.MouseButton2

				if
					not (v15 or v16)
					or (IsSpectateInputBlockedByUi() or SpectateController.IsControllerPress(input))
				then
					return
				end

				SpectateController.RequestSwitch(v15 and -1 or 1)
			end
		end
	end)

	if UserInputService.TouchEnabled then
		UserInputService.TouchStarted:Connect(function(p, flag2: boolean)
			if flag2 or LocalPlayer:GetAttribute("IsPlayerChatting") then
				return
			end

			SpectateController.RequestSwitch(p.Position.X < CurrentCamera.ViewportSize.X / 2 and -1 or 1)
		end)
	end
end

return SpectateController