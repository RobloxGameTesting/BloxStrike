local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Weapon = require(script.Weapon)
return Observers.observeTag("WeaponDropped", function(p)
	local v = Weapon.new(p)
	return function()
		v:destroy()
	end
end)