local RescueHostage = {}
RescueHostage.__index = RescueHostage
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local RadialProgress = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.DefuseBomb.RadialProgress)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local LocalPlayer = Players.LocalPlayer
local vector = Vector2.new(0.85, 0.85)
local v = nil
local v2 = nil

local function isSpectatingOtherRescue(instance) -- 2 equivalent calls inferred from this helper
	local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
	return isSpectating and currentSpectateInstance and instance.PlayerName ~= LocalPlayer.Name
end

function RescueHostage:InitializeProgressBar()
	RadialProgress.Initialize(self, "RescueHostage")
end

function RescueHostage:UpdateProgressBar(p: number)
	RadialProgress.Update(self, p, "Hostage", vector)
end

function RescueHostage:UpdateTimer(p: number)
	RadialProgress.SetTimer(self.Frame, p)
end

function RescueHostage:UpdateTitle()
	RadialProgress.SetTitle(
		self.Frame,
		string.format(
			"%s is rescuing the hostage %s a kit.",
			self.PlayerName,
			self.HasRescueKit and "with" or "without"
		)
	)
end

function RescueHostage:StartRescue(p)
	if self.IsRescuing then
		return
	end

	local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
	local v3 = p or isSpectating and currentSpectateInstance and currentSpectateInstance.Player or LocalPlayer
	self.HasRescueKit = v3:GetAttribute("HasRescueKit")
	self.PlayerName = Participants.Name(v3)
	self.RescueTime = self.HasRescueKit and 1 or 4
	local rescueStartTime = v3:GetAttribute("RescueStartTime")

	if rescueStartTime and (isSpectating or v3 ~= LocalPlayer) then
		local now = tick()

		if rescueStartTime <= now and now - rescueStartTime <= self.RescueTime then
			self.RescueStartTime = rescueStartTime
		else
			self.RescueStartTime = now
		end
	else
		self.RescueStartTime = tick()
	end

	self.RescueProgress = 0
	self.IsRescuing = true

	if self.Frame then
		self.Frame.Visible = true
	end

	self:UpdateProgressBar(0)
	self:UpdateTimer(self.RescueTime)
	self:UpdateTitle()
	self.Janitor:Add(RunServiceController.BindToHeartbeat("UI.RescueHostage.UpdateProgress", function()
		if not self.IsRescuing or self.IsFinished then
			return
		end

		local isSpectating2 = LocalPlayer:GetAttribute("IsSpectating")
		local currentSpectateInstance2 = SpectateController.GetCurrentSpectateInstance()
		local v4 = isSpectating2 and currentSpectateInstance2 and self.PlayerName ~= LocalPlayer.Name

		if v4 and currentSpectateInstance2 then
			local player = currentSpectateInstance2.Player

			if player:GetAttribute("IsRescuingHostage") then
				local rescueStartTime2 = player:GetAttribute("RescueStartTime")

				if rescueStartTime2 then
					local now = tick()

					if
						rescueStartTime2 < self.RescueStartTime
						and rescueStartTime2 <= now
						and now - rescueStartTime2 <= self.RescueTime
					then
						self.RescueStartTime = rescueStartTime2
					end
				end
			else
				if self.RescueProgress >= 0.95 then
					self:FinishRescue()
				else
					self:CancelRescue()
				end

				return
			end
		end

		local v5 = tick() - self.RescueStartTime
		self.RescueProgress = math.min(v5 / self.RescueTime, 1)
		self:UpdateProgressBar(self.RescueProgress)
		self:UpdateTimer((math.max(self.RescueTime - v5, 0)))

		if self.RescueProgress >= 1 and not (self.IsFinished or v4) then
			self:FinishRescue()
		end
	end), "Disconnect", "ProgressConnection")

	if not isSpectating or v3 == LocalPlayer then
		Remotes.Hostage.StartRescue.Send()
	end

	self.RescueStarted:Fire()
end

function RescueHostage:CancelRescue()
	if not self.IsRescuing then
		return
	end

	local spectatingOtherRescue = isSpectatingOtherRescue(self) -- inferred equivalent call
	self.IsRescuing = false
	self.IsFinished = true
	self:UpdateProgressBar(0)

	if self.Frame then
		self.Frame.Visible = false
	end

	if not spectatingOtherRescue then
		Remotes.Hostage.CancelRescue.Send()
	end

	self.RescueCancelled:Fire()
	task.defer(function()
		self:Destroy()
	end)
end

function RescueHostage:FinishRescue()
	if not self.IsRescuing or self.IsFinished then
		return
	end

	local spectatingOtherRescue = isSpectatingOtherRescue(self) -- inferred equivalent call
	self.IsFinished = true
	self.IsRescuing = false

	if not spectatingOtherRescue then
		Remotes.Hostage.PickedUp.Send()
	end

	self.RescueFinished:Fire()
	task.delay(0.5, function()
		self:Destroy()
	end)
end

function RescueHostage.new(frame)
	local self = setmetatable({}, RescueHostage)
	self.Janitor = Janitor.new()
	self.Frame = frame
	self.RescueTime = 4
	self.HasRescueKit = false
	self.RescueStartTime = 0
	self.RescueProgress = 0
	self.IsRescuing = false
	self.IsFinished = false
	self.PlayerName = ""
	self.RescueCancelled = self.Janitor:Add(Signal.new())
	self.RescueFinished = self.Janitor:Add(Signal.new())
	self.RescueStarted = self.Janitor:Add(Signal.new())

	if self.Frame then
		self.Frame.Visible = false
	end

	self:InitializeProgressBar()
	return self
end

function RescueHostage:Destroy()
	if v2 == self then
		v2 = nil
	end

	if self.Frame then
		self.Frame.Visible = false
	end

	self.Janitor:Destroy()
end

function RescueHostage.Initialize(_, p)
	v = p
	GameState.ListenToState(function(_, p2)
		if (p2 == "Buy Period" or p2 == "Warmup") and v2 then
			v2:Destroy()
			v2 = nil
		end
	end)
	Router.observerRouter("Start Rescue Hostage", function()
		if not v2 then
			v2 = RescueHostage.new(v)
		end

		v2:StartRescue()
		return nil
	end)
	Router.observerRouter("Cancel Rescue Hostage", function()
		if v2 then
			v2:CancelRescue()
			v2 = nil
		end

		return nil
	end)
	local isRescuingHostageChangedConnection = nil

	local function updateSpectateRescue()
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
		local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

		if isSpectating and currentSpectateInstance then
			local player = currentSpectateInstance.Player

			if player:GetAttribute("IsRescuingHostage") then
				if not v2 then
					v2 = RescueHostage.new(v)
				end

				v2:StartRescue(player)
			elseif v2 then
				v2:CancelRescue()
				v2 = nil
			end
		elseif v2 and not LocalPlayer:GetAttribute("IsRescuingHostage") then
			v2:CancelRescue()
			v2 = nil
		end
	end

	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(updateSpectateRescue)

	local function setupSpectateRescueListener() -- 1 equivalent call inferred from this helper
		if isRescuingHostageChangedConnection then
			isRescuingHostageChangedConnection:Disconnect()
			isRescuingHostageChangedConnection = nil
		end

		local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

		if currentSpectateInstance then
			isRescuingHostageChangedConnection = currentSpectateInstance.Player:GetAttributeChangedSignal("IsRescuingHostage"):Connect(updateSpectateRescue)
			updateSpectateRescue()
		end
	end

	SpectateController.ListenToSpectate:Connect(setupSpectateRescueListener)
	task.wait(0.1)
	setupSpectateRescueListener() -- inferred equivalent call
end

return RescueHostage