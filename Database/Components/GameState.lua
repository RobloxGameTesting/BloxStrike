local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
require(ReplicatedStorage.Database.Custom.Types)
local Observers = require(ReplicatedStorage.Packages.Observers)
local v = {
	"Map Voting",
	"Game Ending",
	"Warmup",
	"Round In Progress",
	"Buy Period",
	"Intermission"
}

local function isValidState(p: string) -- 2 equivalent calls inferred from this helper
	assert(table.find(v, p), `"{p}" is not a valid state!`)
	return true
end

local GameState = {}

function GameState.GetState()
	return (workspace:GetAttribute("GameState"))
end

function GameState.GetStateAtTime(value: number?)
	local gameState = workspace:GetAttribute("GameState")
	local scheduledGameState = workspace:GetAttribute("ScheduledGameState")
	local scheduledGameStateServerTime = workspace:GetAttribute("ScheduledGameStateServerTime")

	if
		typeof(value) == "number"
		and value == value
		and typeof(scheduledGameStateServerTime) == "number"
		and scheduledGameStateServerTime <= value
		and typeof(scheduledGameState) == "string"
		and table.find(v, scheduledGameState) ~= nil
	then
		return scheduledGameState
	end

	local gameStateTransitionServerTime = workspace:GetAttribute("GameStateTransitionServerTime")
	local previousGameState = workspace:GetAttribute("PreviousGameState")

	if
		typeof(value) == "number"
		and value == value
		and typeof(gameStateTransitionServerTime) == "number"
		and value < gameStateTransitionServerTime
		and typeof(previousGameState) == "string"
		and table.find(v, previousGameState) ~= nil
	then
		return previousGameState
	end

	return gameState
end

function GameState.SetState(gameState)
	assert(RunService:IsServer(), "This method is only available to the server.")

	if isValidState(gameState) then -- inferred equivalent call
		local gameState2 = workspace:GetAttribute("GameState")

		if gameState2 == gameState then
			return
		end

		local scheduledGameState = workspace:GetAttribute("ScheduledGameState")
		local scheduledGameStateServerTime = workspace:GetAttribute("ScheduledGameStateServerTime")

		if scheduledGameState ~= gameState or typeof(scheduledGameStateServerTime) ~= "number" then
			scheduledGameStateServerTime = workspace:GetServerTimeNow()
		end

		workspace:SetAttribute("PreviousGameState", gameState2)
		workspace:SetAttribute("GameStateTransitionServerTime", scheduledGameStateServerTime)
		workspace:SetAttribute("GameState", gameState)
		workspace:SetAttribute("ScheduledGameState", nil)
		workspace:SetAttribute("ScheduledGameStateServerTime", nil)
	end
end

function GameState.ScheduleState(scheduledGameState, scheduledGameStateServerTime: number)
	assert(RunService:IsServer(), "This method is only available to the server.")
	local v2 = scheduledGameStateServerTime == scheduledGameStateServerTime
		and scheduledGameStateServerTime > -1e999
		and scheduledGameStateServerTime < 1e999
	assert(v2)

	if isValidState(scheduledGameState) then -- inferred equivalent call
		workspace:SetAttribute("ScheduledGameStateServerTime", scheduledGameStateServerTime)
		workspace:SetAttribute("ScheduledGameState", scheduledGameState)
	end
end

function GameState.CancelScheduledState()
	assert(RunService:IsServer(), "This method is only available to the server.")
	workspace:SetAttribute("ScheduledGameState", nil)
	workspace:SetAttribute("ScheduledGameStateServerTime", nil)
end

function GameState.ListenToState(callback)
	local v2 = nil
	return Observers.observeAttribute(workspace, "GameState", function(p)
		callback(v2, p)
		v2 = p
	end)
end

return GameState