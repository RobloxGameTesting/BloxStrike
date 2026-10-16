local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	Icon = "rbxassetid://77199368053431",
	Gamemode = { Deathmatch = false, Competitive = false, Casual = false, Surf = "Surf" },
	Characters = { ["Counter-Terrorists"] = "IDF", Terrorists = "Anarchist" },
	Lighting = {
		Properties = require(script:WaitForChild("Properties")),
		Assets = ReplicatedStorage.Assets.Lighting.Skyline
	},
	Terrain = {
		Position = vector.create(0, 0, 0),
		["Terrain"] = nil,
		Resolution = 0,
		Properties = {
			WaterColor = Color3.fromRGB(12, 84, 92),
			WaterTransparency = 0.3,
			WaterReflectance = 1,
			WaterWaveSpeed = 10,
			WaterWaveSize = 0.15,
			Decoration = false,
			MaterialColors = {}
		}
	}
})