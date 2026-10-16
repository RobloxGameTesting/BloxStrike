local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local CharacterActions = require(ReplicatedStorage.Database.Components.CharacterActions)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local LocalPlayer = Players.LocalPlayer
return function(p: string)
	local id = CharacterActions.ToId(p)

	if not id then
		return
	end

	local generation = CharacterGeneration.Get(LocalPlayer.Character)

	if generation == nil then
		return
	end

	Remotes.Character.Action.Send({ UserId = 0, Generation = generation, ActionId = id })
end