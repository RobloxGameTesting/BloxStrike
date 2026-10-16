local DefuseBomb = {}
DefuseBomb.__index = DefuseBomb
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
require(script:WaitForChild("Types"))
local RadialProgress = require(script:WaitForChild("RadialProgress"))
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)
local LocalPlayer = Players.LocalPlayer
local v = table.find(GetUserPlatform(), "Mobile") and #GetUserPlatform() <= 1
local v2 = nil
local now = 0
local now2 = 0
local count = 0
local vector = Vector2.new(0.5, 0.45)
local v3 = nil
local v4 = nil

local function getBombModel() -- 5 equivalent calls inferred from this helper
	return CollectionService:GetTagged("Bomb")[1]
end

local function isBombResolvedState(instance) -- 5 equivalent calls inferred from this helper
	if instance then
		return instance:GetAttribute("Defused") == true
			or instance:GetAttribute("Exploding") == true
			or instance:GetAttribute("Exploded") == true
	end

	return false
end

local function getSyncedDefuseStartTime(instance, defuseTime: number) -- 2 equivalent calls inferred from this helper
	local defuseStartTime = instance:GetAttribute("DefuseStartTime")

	if typeof(defuseStartTime) ~= "number" then
		return nil
	end

	local serverTimeNow = workspace:GetServerTimeNow()
	local v5 = serverTimeNow - defuseStartTime

	if defuseStartTime <= serverTimeNow and v5 >= 0 and v5 <= math.max(defuseTime, 12) then
		return defuseStartTime
	end

	return nil
end

local function isSpectatingOtherDefuse(instance) -- 2 equivalent calls inferred from this helper
	local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
	return isSpectating and currentSpectateInstance and instance.PlayerName ~= LocalPlayer.Name
end

local function resolveFromBombState(object, bombModel) -- 4 equivalent calls inferred from this helper
	if bombModel and bombModel:GetAttribute("Defused") == true then
		object:FinishDefuse(true)
	else
		object:CancelDefuse(true)
	end
end

local function getHoldToDefuseMessage() -- 1 equivalent call inferred from this helper
	if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		return "Keep holding the <b>Interact</b> button until the defuse finishes"
	end

	local actionKeyText = Tips.GetActionKeyText("Use")

	if actionKeyText then
		return `Keep holding <b>{actionKeyText}</b> until the defuse finishes`
	end

	return "Keep holding the use button until the defuse finishes"
end

local function notifyTutorialDefuseCancelled(data, p: string?)
	if not IsTutorialMode() or not data.IsDefusing or data.HasSentDefuseRequest then
		return
	end

	local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

	if
		(not isSpectating or not currentSpectateInstance or data.PlayerName == LocalPlayer.Name)
		and not isBombResolvedState(getBombModel()) -- inferred equivalent call
	then
		if os.clock() - now2 < 2 then
			return
		end

		now2 = os.clock()
		local broadcastRouter = Router.broadcastRouter

		if not p then
			p = getHoldToDefuseMessage() -- inferred equivalent call
		end

		broadcastRouter("CreateNotification", "Defuse Cancelled", p, 3)
	end
end

function DefuseBomb:InitializeProgressBar()
	RadialProgress.Initialize(self, "DefuseBomb")
end

function DefuseBomb:UpdateProgressBar(p: number)
	RadialProgress.Update(self, p, "Bomb", vector)
end

function DefuseBomb:UpdateTimer(p: number)
	RadialProgress.SetTimer(self.Frame, p)
end

function DefuseBomb:UpdateTitle()
	RadialProgress.SetTitle(
		self.Frame,
		string.format("%s is defusing the bomb %s a kit.", self.PlayerName, self.HasDefuseKit and "with" or "without")
	)
end

function DefuseBomb:StartDefuse(p)
	local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
	local v5 = p or isSpectating and currentSpectateInstance and currentSpectateInstance.Player or LocalPlayer

	if self.IsDefusing and self.PlayerName == Participants.Name(v5) or isBombResolvedState(getBombModel()) then -- inferred equivalent call
		return
	end

	if v5 == LocalPlayer then
		LocalPlayer:SetAttribute("IsLocallyDefusingBomb", true)
	end

	self.HasDefuseKit = v5:GetAttribute("HasDefuseKit") == true
	self.PlayerName = Participants.Name(v5)
	self.DefuseTime = self.HasDefuseKit and 5 or 10
	self.DefuseStartTime = getSyncedDefuseStartTime(v5, self.DefuseTime) or workspace:GetServerTimeNow() -- inferred equivalent call
	self.DefuseProgress = 0
	self.IsDefusing = true
	self.IsFinished = false
	self.HasSentDefuseRequest = false
	self.HasReceivedServerStartAck = false
	self.DefuseSessionId = nil

	if self.Frame then
		self.Frame.Visible = true
	end

	self:UpdateProgressBar(0)
	self:UpdateTimer(self.DefuseTime)
	self:UpdateTitle()
	self.Janitor:Add(RunServiceController.BindToHeartbeat("UI.DefuseBomb.UpdateProgress", function()
		if not self.IsDefusing or self.IsFinished then
			return
		end

		local bombModel = getBombModel() -- inferred equivalent call

		if isBombResolvedState(bombModel) then -- inferred equivalent call
			resolveFromBombState(self, bombModel) -- inferred equivalent call
		else
			local isSpectating2 = LocalPlayer:GetAttribute("IsSpectating")
			local currentSpectateInstance2 = SpectateController.GetCurrentSpectateInstance()
			local v6 = isSpectating2 and currentSpectateInstance2 and self.PlayerName ~= LocalPlayer.Name
			local syncedDefuseStartTime = getSyncedDefuseStartTime( -- inferred equivalent call
				v6 and currentSpectateInstance2 and currentSpectateInstance2.Player or LocalPlayer,
				self.DefuseTime
			)

			if syncedDefuseStartTime and math.abs(syncedDefuseStartTime - self.DefuseStartTime) > 0.001 then
				self.DefuseStartTime = syncedDefuseStartTime
			end

			if v6 and currentSpectateInstance2 then
				if not currentSpectateInstance2.Player:GetAttribute("IsDefusingBomb") then
					resolveFromBombState(self, bombModel) -- inferred equivalent call
					return
				end
			else
				local character = LocalPlayer.Character

				if
					character
					and character.PrimaryPart
					and bombModel
					and bombModel.PrimaryPart
					and (character.PrimaryPart.Position - bombModel.PrimaryPart.Position).Magnitude > 10
				then
					notifyTutorialDefuseCancelled(self, "Stay next to the bomb until the defuse finishes")
					self:CancelDefuse(false)
					return
				elseif not (v or InputController.isActionActive("Use")) then
					notifyTutorialDefuseCancelled(self)
					self:CancelDefuse(false)
					return
				end
			end

			local v7

			if v6 then
				v7 = false
			else
				v7 = LocalPlayer:GetAttribute("IsDefusingBomb") == true

				if v7 then
					self.HasReceivedServerStartAck = true
				end

				if not v7 and (self.HasReceivedServerStartAck or self.HasSentDefuseRequest) then
					notifyTutorialDefuseCancelled(self, "Stand still next to the bomb until the defuse finishes")
					resolveFromBombState(self, bombModel) -- inferred equivalent call
					return
				end
			end

			local v8 = workspace:GetServerTimeNow() - self.DefuseStartTime
			self.DefuseProgress = math.min(v8 / self.DefuseTime, 1)
			self:UpdateProgressBar(self.DefuseProgress)
			self:UpdateTimer((math.max(self.DefuseTime - v8, 0)))

			if v6 or not (self.DefuseProgress >= 1) or self.HasSentDefuseRequest or not v7 then
				return
			end

			self.HasSentDefuseRequest = true
			Remotes.C4.Defused.Send()
		end
	end), "Disconnect", "ProgressConnection")

	if not isSpectating or v5 == LocalPlayer then
		count += 1
		self.DefuseSessionId = count
		Remotes.C4.StartDefuse.Send({ SessionId = self.DefuseSessionId })
	end

	self.DefuseStarted:Fire()
end

function DefuseBomb:CancelDefuse(flag: boolean?)
	if not self.IsDefusing then
		return
	end

	local spectatingOtherDefuse = isSpectatingOtherDefuse(self) -- inferred equivalent call
	self.IsDefusing = false
	self.IsFinished = true

	if not spectatingOtherDefuse then
		LocalPlayer:SetAttribute("IsLocallyDefusingBomb", nil)
	end

	if v4 == self then
		v4 = nil
	end

	self:UpdateProgressBar(0)

	if self.Frame then
		self.Frame.Visible = false
	end

	if not (flag or spectatingOtherDefuse) then
		Remotes.C4.CancelDefuse.Send({ SessionId = self.DefuseSessionId })
	end

	self.DefuseCancelled:Fire()
	task.defer(function()
		self:Destroy()
	end)
end

function DefuseBomb:FinishDefuse(flag: boolean?)
	if not self.IsDefusing or self.IsFinished then
		return
	end

	local spectatingOtherDefuse = isSpectatingOtherDefuse(self) -- inferred equivalent call
	self.IsFinished = true
	self.IsDefusing = false

	if not spectatingOtherDefuse then
		LocalPlayer:SetAttribute("IsLocallyDefusingBomb", nil)
	end

	if v4 == self then
		v4 = nil
	end

	if not (flag or spectatingOtherDefuse) then
		Remotes.C4.Defused.Send()
	end

	self.DefuseFinished:Fire()

	local function destroy()
		self:Destroy()
	end

	if flag then
		task.defer(destroy)
	else
		task.delay(0.5, destroy)
	end
end

function DefuseBomb.new(frame)
	local self = setmetatable({}, DefuseBomb)
	self.Janitor = Janitor.new()
	self.Frame = frame
	self.DefuseTime = 10
	self.HasDefuseKit = false
	self.DefuseStartTime = 0
	self.DefuseProgress = 0
	self.IsDefusing = false
	self.IsFinished = false
	self.HasSentDefuseRequest = false
	self.HasReceivedServerStartAck = false
	self.PlayerName = ""
	self.DefuseCancelled = self.Janitor:Add(Signal.new())
	self.DefuseFinished = self.Janitor:Add(Signal.new())
	self.DefuseStarted = self.Janitor:Add(Signal.new())

	if self.Frame then
		self.Frame.Visible = false
	end

	self:InitializeProgressBar()
	return self
end

function DefuseBomb:Destroy()
	local v5

	if v4 == nil then
		v5 = false
	else
		v5 = v4 ~= self
	end

	if self.PlayerName == LocalPlayer.Name and not v5 then
		LocalPlayer:SetAttribute("IsLocallyDefusingBomb", nil)
	end

	if v4 == self then
		v4 = nil
	end

	if self.Frame and not v5 then
		self.Frame.Visible = false
	end

	self.Janitor:Destroy()
end

function DefuseBomb.Initialize(_, p)
	v3 = p
	Router.observerRouter("Start Defuse Bomb", function()
		if v2 and workspace:GetServerTimeNow() < v2 then
			return nil
		end

		if IsTutorialMode() and LocalPlayer:GetAttribute("TutorialStep") ~= "DefuseB" then
			if os.clock() - now > 2 then
				now = os.clock()
				Router.broadcastRouter(
					"CreateNotification",
					"Not Yet",
					"Eliminate all the Terrorists before defusing the bomb",
					2.5
				)
			end
		else
			if isBombResolvedState(getBombModel()) then -- inferred equivalent call
				return nil
			end

			if not v4 then
				v4 = DefuseBomb.new(v3)
			end

			v4:StartDefuse()
		end

		return nil
	end)
	Router.observerRouter("Cancel Defuse Bomb", function()
		local v5 = v4

		if v5 then
			notifyTutorialDefuseCancelled(v5)
			v5:CancelDefuse(false)
			v4 = nil
		end

		return nil
	end)
	local isDefusingBombChangedConnection = nil

	local function updateSpectateDefuse()
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
		local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

		if isSpectating and currentSpectateInstance then
			local player = currentSpectateInstance.Player
			local isDefusingBomb = player:GetAttribute("IsDefusingBomb")
			local bombModel = getBombModel() -- inferred equivalent call

			if isBombResolvedState(bombModel) then -- inferred equivalent call
				if v4 then
					resolveFromBombState(v4, bombModel) -- inferred equivalent call
					v4 = nil
				end
			elseif isDefusingBomb then
				if not v4 then
					v4 = DefuseBomb.new(v3)
				end

				v4:StartDefuse(player)
			elseif v4 then
				v4:CancelDefuse(false)
				v4 = nil
			end
		elseif v4 and not LocalPlayer:GetAttribute("IsDefusingBomb") then
			v4:CancelDefuse(false)
			v4 = nil
		end
	end

	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(updateSpectateDefuse)

	local function setupSpectateDefuseListener() -- 1 equivalent call inferred from this helper
		if isDefusingBombChangedConnection then
			isDefusingBombChangedConnection:Disconnect()
			isDefusingBombChangedConnection = nil
		end

		local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

		if currentSpectateInstance then
			isDefusingBombChangedConnection = currentSpectateInstance.Player:GetAttributeChangedSignal("IsDefusingBomb"):Connect(updateSpectateDefuse)
			updateSpectateDefuse()
		end
	end

	SpectateController.ListenToSpectate:Connect(setupSpectateDefuseListener)
	task.wait(0.1)
	setupSpectateDefuseListener() -- inferred equivalent call
end

function DefuseBomb.SetDefuseBlockedUntil(p: number)
	v2 = p
end

return DefuseBomb