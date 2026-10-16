local v = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Signal = require(ReplicatedStorage.Packages.Signal)
local LocalPlayer = Players.LocalPlayer
local v2 = {
	disabled = "Disabled",
	off = "Disabled",
	["push to talk"] = "Push To Talk",
	pushtotalk = "Push To Talk",
	ptt = "Push To Talk",
	["open mic"] = "Open Microphone",
	openmic = "Open Microphone",
	["open microphone"] = "Open Microphone",
	openmicrophone = "Open Microphone"
}
local speakingChanged = Signal.new()
local v3 = {
	IsPushToTalkHeld = false,
	IsVoiceInputRefreshQueued = false,
	LastVoiceInputScanTime = 0,
	PlayerConnections = {},
	SpeakingPlayers = {},
	ShouldRecreateVoiceInputs = false,
	Trackers = {},
	VoiceActivityConnection = nil,
	VoiceMode = "Disabled"
}
v.Name = "Voice Chat"
v.Group = "Default"
v.Category = "Communication Options"
v.SpeakingChanged = speakingChanged

function v.GetVoiceMode(value)
	if typeof(value) ~= "string" then
		return "Disabled"
	end

	local v4 = string.lower(value)
	local v5 = string.gsub(v4, "[%s_%-%./]+", " ")
	local v6 = string.gsub(v5, "^%s+", "")
	local v7 = string.gsub(v6, "%s+$", "")
	local v8 = string.gsub(v7, "%s+", "")
	return v2[v7] or v2[v8] or "Disabled"
end

function v.SetVoiceMode(p)
	v3.VoiceMode = v.GetVoiceMode(p)
	v3.IsPushToTalkHeld = false
	v.SyncVoiceMuted()
	v.SyncVoiceActivity()
end

function v.SetPushToTalkHeld(isPushToTalkHeld: boolean)
	v3.IsPushToTalkHeld = isPushToTalkHeld
	v.SyncVoiceMuted()
	v.SyncVoiceActivity()
end

function v.IsVoiceTransmitting()
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		return false
	end

	return v3.VoiceMode == "Open Microphone" or v3.VoiceMode == "Push To Talk" and v3.IsPushToTalkHeld
end

function v.IsPlayerSpeaking(p)
	return v3.SpeakingPlayers[p] == true
end

function v.SetPlayerSpeaking(p, flag: boolean)
	if v.IsPlayerSpeaking(p) == flag then
		return
	end

	v3.SpeakingPlayers[p] = flag and true or nil
	speakingChanged:Fire(p, flag)
end

function v.GetVoiceInput(p)
	return ((p or LocalPlayer):FindFirstChildWhichIsA("AudioDeviceInput"))
end

function v.CanLocalPlayerHear(p)
	local success, userIdAccessList = pcall(p.GetUserIdAccessList, p)

	if not success then
		return nil
	end

	local selected = table.find(userIdAccessList, LocalPlayer.UserId) ~= nil

	if p.AccessType == Enum.AccessModifierType.Deny then
		return not selected
	end

	return selected
end

function v.SetVoiceMuted(muted: boolean)
	local voiceInput = v.GetVoiceInput()

	if voiceInput then
		voiceInput.Muted = muted
	end
end

function v.DestroyTracker(p)
	local tracker = v3.Trackers[p]

	if not tracker then
		return
	end

	tracker.Wire:Destroy()
	tracker.Analyzer:Destroy()
	v3.Trackers[p] = nil
	v.SetPlayerSpeaking(p, false)
end

function v.QueueVoiceInputRefresh(flag: boolean?, flag2: boolean?)
	v3.ShouldRecreateVoiceInputs = v3.ShouldRecreateVoiceInputs or flag == true

	if flag2 then
		task.delay(0.25, function()
			v.QueueVoiceInputRefresh(true)
		end)
	end

	if v3.IsVoiceInputRefreshQueued then
		return
	end

	v3.IsVoiceInputRefreshQueued = true
	task.defer(function()
		local shouldRecreateVoiceInputs = v3.ShouldRecreateVoiceInputs
		v3.IsVoiceInputRefreshQueued = false
		v3.ShouldRecreateVoiceInputs = false

		if shouldRecreateVoiceInputs then
			local v4 = {}

			for k, tracker in pairs(v3.Trackers) do
				local canLocalPlayerHear = v.CanLocalPlayerHear(tracker.Input)

				if canLocalPlayerHear == nil or canLocalPlayerHear ~= tracker.CanHear then
					table.insert(v4, k)
				end
			end

			for _, v5 in ipairs(v4) do
				v.DestroyTracker(v5)
			end
		end

		v.SyncVoiceInputs(true)
		v.SyncVoiceActivity()
	end)
end

function v.TrackVoiceInput(p, sourceInstance)
	local tracker = v3.Trackers[p]

	if tracker and tracker.Input == sourceInstance then
		return
	end

	v.DestroyTracker(p)
	local audioAnalyzer = Instance.new("AudioAnalyzer")
	audioAnalyzer.Name = `{p.Name}VoiceChatAnalyzer`
	audioAnalyzer.SpectrumEnabled = false
	audioAnalyzer.Parent = LocalPlayer
	local wire = Instance.new("Wire")
	wire.Name = "VoiceChatAnalyzerWire"
	wire.SourceInstance = sourceInstance
	wire.SourceName = "Output"
	wire.TargetInstance = audioAnalyzer
	wire.TargetName = "Input"
	wire.Parent = audioAnalyzer
	v3.Trackers[p] = {
		Analyzer = audioAnalyzer,
		CanHear = v.CanLocalPlayerHear(sourceInstance),
		Input = sourceInstance,
		LastVoiceActivityTime = 0,
		Wire = wire
	}

	if p == LocalPlayer then
		v.SyncVoiceMuted()
	end
end

function v.SyncVoiceInputs(flag: boolean?)
	local now = os.clock()

	if not flag and now - v3.LastVoiceInputScanTime < 0.2 then
		return
	end

	v3.LastVoiceInputScanTime = now

	for k in pairs(v3.Trackers) do
		if not k.Parent then
			v.DestroyTracker(k)
		end
	end

	for _, v4 in ipairs(Players:GetPlayers()) do
		local tracker = v3.Trackers[v4]
		local voiceInput = v.GetVoiceInput(v4)

		if voiceInput then
			v.TrackVoiceInput(v4, voiceInput)
		elseif tracker then
			v.DestroyTracker(v4)
		end
	end
end

function v.ObservePlayer(instance)
	if v3.PlayerConnections[instance] then
		return
	end

	local connections = {}
	v3.PlayerConnections[instance] = connections

	local function refreshVoiceAccess()
		v.QueueVoiceInputRefresh(true, true)
	end

	local function refreshVoiceInput(audioDeviceInput)
		if audioDeviceInput:IsA("AudioDeviceInput") then
			v.QueueVoiceInputRefresh()
		end
	end

	table.insert(connections, instance:GetAttributeChangedSignal("Team"):Connect(refreshVoiceAccess))
	table.insert(connections, instance:GetAttributeChangedSignal("IsSpectating"):Connect(refreshVoiceAccess))
	table.insert(connections, instance.ChildAdded:Connect(refreshVoiceInput))
	table.insert(connections, instance.ChildRemoved:Connect(refreshVoiceInput))
	v.QueueVoiceInputRefresh()
end

function v.UnobservePlayer(p)
	local playerConnection = v3.PlayerConnections[p]

	if not playerConnection then
		v.DestroyTracker(p)
		return
	end

	v3.PlayerConnections[p] = nil

	for _, connection in ipairs(playerConnection) do
		connection:Disconnect()
	end

	table.clear(playerConnection)
	v.DestroyTracker(p)
end

function v.SyncPlayerVoiceActivity(p, state)
	if p == LocalPlayer and not v.IsVoiceTransmitting() then
		state.LastVoiceActivityTime = 0
		v.SetPlayerSpeaking(p, false)
	else
		local now = os.clock()
		local v4 = math.max(state.Analyzer.RmsLevel, state.Analyzer.PeakLevel)

		if v.IsPlayerSpeaking(p) then
			if v4 >= 0.0005 then
				state.LastVoiceActivityTime = now
			elseif now - state.LastVoiceActivityTime >= 0.7 then
				v.SetPlayerSpeaking(p, false)
			end
		elseif v4 >= 0.0008 then
			state.LastVoiceActivityTime = now
			v.SetPlayerSpeaking(p, true)
		end
	end
end

function v.SyncVoiceActivity()
	v.SyncVoiceInputs()

	for k, tracker in pairs(v3.Trackers) do
		v.SyncPlayerVoiceActivity(k, tracker)
	end
end

function v.StartVoiceActivityLoop()
	if not v3.VoiceActivityConnection then
		v3.VoiceActivityConnection = RunServiceController.BindToPostSimulation(
			"InputController.VoiceChat.SyncVoiceActivity",
			v.SyncVoiceActivity
		)
	end
end

function v.SyncVoiceMuted()
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		v.SetVoiceMuted(true)
	elseif v3.VoiceMode == "Open Microphone" then
		v.SetVoiceMuted(false)
	else
		v.SetVoiceMuted(v3.VoiceMode ~= "Push To Talk" or not v3.IsPushToTalkHeld)
	end
end

function v.OnInput(p, _)
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		v.SetPushToTalkHeld(false)
	elseif v3.VoiceMode ~= "Push To Talk" then
		v.SyncVoiceMuted()
	elseif p == Enum.UserInputState.Begin then
		v.SetPushToTalkHeld(true)
	elseif p == Enum.UserInputState.End or p == Enum.UserInputState.Cancel then
		v.SetPushToTalkHeld(false)
	end
end

Players.PlayerAdded:Connect(v.ObservePlayer)
Players.PlayerRemoving:Connect(v.UnobservePlayer)
workspace:GetAttributeChangedSignal("VoiceAccessRevision"):Connect(function()
	v.QueueVoiceInputRefresh(true, true)
end)

for _, v4 in ipairs(Players:GetPlayers()) do
	v.ObservePlayer(v4)
end

LocalPlayer:GetAttributeChangedSignal("IsPlayerChatting"):Connect(function()
	v.SyncVoiceMuted()
	v.SyncVoiceActivity()
end)
DataController.CreateListener(LocalPlayer, "Settings.Audio.Voice Chat.Voice Chat Activation Mode", v.SetVoiceMode)
v.StartVoiceActivityLoop()
v.SyncVoiceMuted()
v.SyncVoiceInputs(true)
v.SyncVoiceActivity()
v.Callback = v.OnInput
return table.freeze(v)