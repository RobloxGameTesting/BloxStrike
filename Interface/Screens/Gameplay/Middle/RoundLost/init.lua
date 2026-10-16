local RoundLost = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local LocalPlayer = Players.LocalPlayer
local v = nil

function RoundLost.Initialize(_, p)
	v = p
	GameState.ListenToState(function(p2, p3)
		if p2 == "Intermission" and p3 == "Buy Period" or p3 == "Round In Progress" then
			v.Visible = false
		end
	end)
	Remotes.UI.RoundWinner.Listen(function(p2)
		if LocalPlayer:GetAttribute("Team") ~= p2 then
			v.Visible = true
		end
	end)
end

return RoundLost