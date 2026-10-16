local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Shared = ReplicatedStorage:WaitForChild("Shared")
require(Shared:WaitForChild("Janitor"))
require(Shared:WaitForChild("Promise"))
require(Packages:WaitForChild("Signal"))
require(ReplicatedStorage:WaitForChild("Database"):WaitForChild("Custom"):WaitForChild("GameStats"):WaitForChild("NumberSlots"))
return {}