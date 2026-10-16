local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Bomb = require(script.Bomb)
return Observers.observeTag("Bomb", function(p)
	local v = Bomb.new(p)
	return function()
		v:destroy()
	end
end)