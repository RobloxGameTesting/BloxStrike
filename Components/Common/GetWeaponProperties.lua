local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return function(childName: string)
	local child = ReplicatedStorage.Database.Custom.Weapons:FindFirstChild(childName)

	if child then
		return require(child)
	end

	return nil
end