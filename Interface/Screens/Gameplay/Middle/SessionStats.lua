local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local Observers = require(ReplicatedStorage.Packages.Observers)
local v = table.find(GetUserPlatform(), "Mobile") ~= nil
local now = os.clock()
local v2 = 0
local v3 = 0
local v4 = false
local v5 = false
local v6 = {}
local connection = nil
local v7 = nil

local function UpdateServerStats(p) -- 1 equivalent call inferred from this helper
	v7.Server.Text = `Location: {p}, Version: {Constants.VERSION}`
end

local function IsFiniteNumber(value)
	return typeof(value) == "number" and value == value and value ~= 1e999 and value ~= -1e999
end

local function GetDisplayedPing() -- 4 equivalent calls inferred from this helper
	return tonumber((LocalPlayer:GetAttribute("Ping"))) or 999
end

local function UpdatePlayerText(p: number)
	local v8 = {}

	if v5 then
		local v9 = v3

		if #v6 > 0 then
			local total = 0
			local count = 0

			for _, v10 in ipairs(v6) do
				local v11

				if typeof(v10) == "number" and v10 == v10 and v10 ~= 1e999 then
					v11 = v10 ~= -1e999
				else
					v11 = false
				end

				if not v11 then
					continue
				end

				total += v10
				count += 1
			end

			if count > 0 then
				v9 = math.round(total / count)
			end
		end

		table.insert(v8, `Fps: {tostring(v9)}`)
	end

	if v4 then
		table.insert(v8, `Ping: {p}ms`)
	end

	v7.Player.Text = table.concat(v8, ", ")
	v7.Player.Visible = #v8 > 0
end

local function UpdatePlayerStats(value: number, p: number)
	local now2 = os.clock()
	local v8

	if typeof(value) == "number" and value == value and value ~= 1e999 then
		v8 = value ~= -1e999
	else
		v8 = false
	end

	if not v8 then
		value = v3
	end

	table.insert(v6, value)
	v2 = p
	v3 = value

	if now2 - now >= 1 then
		now = now2
		UpdatePlayerText(p)
		table.clear(v6)
	end
end

local function StopStatsUpdate() -- 7 equivalent calls inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function RunStatsUpdate(p: number)
	if v7.Visible and (v5 or v4) then
		local displayedPing = GetDisplayedPing() -- inferred equivalent call
		local v8 = v3

		if p > 0 then
			v8 = math.round(1 / p)
		end

		local v9

		if typeof(v8) == "number" and v8 == v8 and v8 ~= 1e999 then
			v9 = v8 ~= -1e999
		else
			v9 = false
		end

		if not v9 then
			v8 = v3
		end

		UpdatePlayerStats(v8, displayedPing)
	else
		StopStatsUpdate() -- inferred equivalent call
	end
end

local function SyncStatsUpdate()
	if v or not v7 then
		return
	end

	if v7.Visible and (v5 or v4) then
		if connection then
			return
		end

		now = os.clock()
		connection = RunServiceController.BindToHeartbeat("UI.SessionStats.UpdatePlayerStats", RunStatsUpdate)

		if v7.Visible and (v5 or v4) then
			local displayedPing = GetDisplayedPing() -- inferred equivalent call
			local v8 = v3
			local v9

			if typeof(v8) == "number" and v8 == v8 and v8 ~= 1e999 then
				v9 = v8 ~= -1e999
			else
				v9 = false
			end

			if not v9 then
				v8 = v3
			end

			UpdatePlayerStats(v8, displayedPing)
		else
			StopStatsUpdate() -- inferred equivalent call
		end
	else
		StopStatsUpdate() -- inferred equivalent call
	end
end

return {
	Initialize = function(_, p)
		v7 = p
		v7.Visible = false

		if v then
			v7:GetPropertyChangedSignal("Visible"):Connect(function()
				if v7.Visible then
					v7.Visible = false
				end
			end)
			return
		end

		v4 = DataController.Get(LocalPlayer, "Settings.Game.Other.Show Ping") == true
		v5 = DataController.Get(LocalPlayer, "Settings.Game.Other.Show FPS") == true
		v7.Server.Text = `Location: Unknown, Version: {Constants.VERSION}`

		local function onStatSettingChanged() -- 2 equivalent calls inferred from this helper
			if v7.Visible then
				UpdatePlayerText(v2)
			end

			if not v then
				if not v7 then
					return
				end

				if v7.Visible and (v5 or v4) then
					if connection then
						return
					end

					now = os.clock()
					connection = RunServiceController.BindToHeartbeat(
						"UI.SessionStats.UpdatePlayerStats",
						RunStatsUpdate
					)

					if v7.Visible and (v5 or v4) then
						local displayedPing = GetDisplayedPing() -- inferred equivalent call
						local v8 = v3
						local v9

						if typeof(v8) == "number" and v8 == v8 and v8 ~= 1e999 then
							v9 = v8 ~= -1e999
						else
							v9 = false
						end

						if not v9 then
							v8 = v3
						end

						UpdatePlayerStats(v8, displayedPing)
					else
						StopStatsUpdate() -- inferred equivalent call
					end
				else
					StopStatsUpdate() -- inferred equivalent call
				end
			end
		end

		DataController.CreateListener(LocalPlayer, "Settings.Game.Other.Show FPS", function(p2)
			v5 = p2 == true
			onStatSettingChanged() -- inferred equivalent call
		end)
		DataController.CreateListener(LocalPlayer, "Settings.Game.Other.Show Ping", function(p2)
			v4 = p2 == true
			onStatSettingChanged() -- inferred equivalent call
		end)
		v7:GetPropertyChangedSignal("Visible"):Connect(SyncStatsUpdate)

		if not v and v7 then
			if v7.Visible and (v5 or v4) then
				if not connection then
					now = os.clock()
					connection = RunServiceController.BindToHeartbeat(
						"UI.SessionStats.UpdatePlayerStats",
						RunStatsUpdate
					)

					if v7.Visible and (v5 or v4) then
						local displayedPing = GetDisplayedPing() -- inferred equivalent call
						local v8 = v3
						local v9

						if typeof(v8) == "number" and v8 == v8 and v8 ~= 1e999 then
							v9 = v8 ~= -1e999
						else
							v9 = false
						end

						if not v9 then
							v8 = v3
						end

						UpdatePlayerStats(v8, displayedPing)
					else
						StopStatsUpdate() -- inferred equivalent call
					end
				end
			else
				StopStatsUpdate() -- inferred equivalent call
			end
		end

		Observers.observeAttribute(workspace, "Timezone", function(p2)
			UpdateServerStats(p2) -- inferred equivalent call
			return function()
				v7.Server.Text = `Location: Unknown, Version: {Constants.VERSION}`
			end
		end)
	end
}