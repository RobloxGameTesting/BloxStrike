local HintController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local hints = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("Hints")
hints:WaitForChild("Static")
hints:WaitForChild("Ranged")
Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui", 1e999):WaitForChild("Gameplay"):WaitForChild("Middle")

function HintController.createHint(_, _: string, _, _: string?, _: string?, _: boolean?) end

function HintController.clearHint(_, _: string?) end

Remotes.Hints.BombSiteEntered.Listen(function() end)
Remotes.Hints.ClearHint.Listen(function() end)
return HintController