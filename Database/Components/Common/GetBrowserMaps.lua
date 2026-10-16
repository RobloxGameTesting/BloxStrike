local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameStats = ReplicatedStorage.Database.Custom.GameStats
local frozen = table.freeze({ "Casual", "Competitive", "Deathmatch" })
return function()
	local childNames = {}

	for _, childName in frozen do
		local module = require((GameStats.Gamemodes:FindFirstChild(childName)))

		for _, childName2 in module.Maps do
			if table.find(childNames, childName2) then
				continue
			end

			local moduleScript = GameStats.Maps:FindFirstChild(childName2)

			if not (moduleScript and moduleScript:IsA("ModuleScript")) then
				continue
			end

			local success, result = pcall(require, moduleScript)

			if not success or typeof(result) ~= "table" or result.Hidden ~= true then
				table.insert(childNames, childName2)
			end
		end
	end

	return childNames
end