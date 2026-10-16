local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Sound = require(ReplicatedStorage.Classes.Sound)
local v = {}
local connection = nil
local total = 0

local function isPointInsideZone(position: Vector3, p) -- 1 equivalent call inferred from this helper
	local pointToObjectSpace = p.BoundsCFrame:PointToObjectSpace(position)
	local halfSize = p.HalfSize
	return math.abs(pointToObjectSpace.X) <= halfSize.X
		and math.abs(pointToObjectSpace.Y) <= halfSize.Y
		and math.abs(pointToObjectSpace.Z) <= halfSize.Z
end

local function stopHeartbeatIfIdle() -- 2 equivalent calls inferred from this helper
	if next(v) == nil then
		if connection then
			connection:Disconnect()
			connection = nil
		end

		total = 0
	end
end

local function stepZones(p: number)
	total += p

	if total < 1 / 15 then
		return
	end

	local v2 = total
	total = 0
	local currentCamera = Workspace.CurrentCamera
	local position = currentCamera and currentCamera.CFrame.Position

	if not position then
		return
	end

	local v3 = math.min(1, v2 * 3)

	for k, v4 in pairs(v) do
		if k:IsDescendantOf(Workspace) then
			local pointInsideZone = isPointInsideZone(position, v4) -- inferred equivalent call

			for _, v5 in ipairs(v4.SoundDataList) do
				local v6 = not pointInsideZone and 0 or v5.MaximumVolume or 0
				local currentVolume = v5.CurrentVolume
				local v7 = v6 - currentVolume

				if v6 > 0 and not v5.Playing then
					v5.GlobalSound:Resume()
					v5.Playing = true
				end

				if math.abs(v7) <= 0.002 then
					if currentVolume ~= v6 then
						v5.GlobalSound.Volume = v6
					end

					v5.CurrentVolume = v6

					if v6 == 0 and v5.Playing then
						v5.GlobalSound:Pause()
						v5.Playing = false
					end
				else
					local v8 = currentVolume + v7 * v3
					v5.GlobalSound.Volume = v8
					v5.CurrentVolume = v8
				end
			end
		else
			v[k] = nil
		end
	end

	stopHeartbeatIfIdle() -- inferred equivalent call
end

local function ensureHeartbeat() -- 1 equivalent call inferred from this helper
	if connection then
		return
	end

	connection = RunServiceController.BindToHeartbeat("Observers.Game.AmbiencePart.UpdateZones", stepZones)
end

return Observers.observeTag("AmbiencePart", function(instance)
	if not instance:IsDescendantOf(workspace) then
		return function() end
	end

	local sounds = {}

	for _, sound in instance:GetChildren() do
		if sound:IsA("Sound") then
			table.insert(sounds, sound)
		end
	end

	if #sounds <= 0 then
		return function() end
	end

	local maid = Janitor.new()
	local soundDataList = {}

	for _, v2 in sounds do
		local globalSound = maid:Add(v2:Clone())
		globalSound.RollOffMode = Enum.RollOffMode.Inverse
		globalSound.RollOffMaxDistance = 10000
		globalSound.RollOffMinDistance = 10000
		globalSound.SoundGroup = Sound.GameplaySoundGroup
		globalSound.Parent = SoundService
		globalSound.PlayOnRemove = false
		globalSound.Volume = 0
		table.insert(soundDataList, {
			MaximumVolume = v2.Volume > 0 and v2.Volume or 1,
			GlobalSound = globalSound,
			CurrentVolume = 0,
			Playing = false
		})
	end

	local v2 = {
		SoundDataList = soundDataList,
		BoundsCFrame = instance.CFrame,
		HalfSize = instance.Size / 2
	}
	v[instance] = v2
	maid:Add(instance:GetPropertyChangedSignal("CFrame"):Connect(function()
		v2.BoundsCFrame = instance.CFrame
	end))
	maid:Add(instance:GetPropertyChangedSignal("Size"):Connect(function()
		v2.HalfSize = instance.Size / 2
	end))
	ensureHeartbeat() -- inferred equivalent call
	maid:Add(function()
		v[instance] = nil
		stopHeartbeatIfIdle() -- inferred equivalent call
	end)
	return function()
		maid:Cleanup()
	end
end)