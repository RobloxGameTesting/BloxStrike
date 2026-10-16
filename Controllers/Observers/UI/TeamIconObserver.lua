local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Observers = require(ReplicatedStorage.Packages.Observers)
local v = {
	["Counter-Terrorists"] = "rbxassetid://72938147057400",
	Terrorists = "rbxassetid://73218600485628"
}
return Observers.observeTag("TeamIcon", function(instance)
	local teamName = instance:GetAttribute("TeamName")
	local image = teamName and v[teamName] or nil

	if image then
		instance.Image = image
	end

	return function() end
end)