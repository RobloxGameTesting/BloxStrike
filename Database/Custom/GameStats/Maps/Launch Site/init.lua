local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	Hidden = false,
	Icon = "rbxassetid://135143875195195",
	Radar = "rbxassetid://106995237093828",
	Gamemode = { Competitive = "Bomb Defusal", Deathmatch = "Deathmatch", Casual = "Bomb Defusal" },
	Characters = { ["Counter-Terrorists"] = "IDF", Terrorists = "Anarchist" },
	Lighting = {
		Properties = require(script:WaitForChild("Properties")),
		Assets = ReplicatedStorage.Assets.Lighting["Launch Site"]
	},
	Terrain = {
		Resolution = 4,
		Properties = {
			WaterColor = Color3.fromRGB(12.000001184642315, 84.00000259280205, 92.00000211596489),
			WaterTransparency = 0.6,
			WaterReflectance = 0.25,
			WaterWaveSpeed = 7,
			WaterWaveSize = 0.35,
			Decoration = true,
			MaterialColors = {
				WoodPlanks = Color3.fromRGB(172.00000494718552, 148.000006377697, 108.00000116229057),
				Slate = Color3.fromRGB(88.00000235438347, 89.00000229477882, 86.00000247359276),
				Concrete = Color3.fromRGB(152.0000061392784, 152.0000061392784, 152.0000061392784),
				Brick = Color3.fromRGB(138.00000697374344, 97.00000181794167, 73.00000324845314),
				Cobblestone = Color3.fromRGB(134.00000721216202, 134.00000721216202, 118.00000056624413),
				Rock = Color3.fromRGB(99.00000169873238, 100.00000163912773, 102.00000151991844),
				Sandstone = Color3.fromRGB(148.000006377697, 124.00000020861626, 95.00000193715096),
				Basalt = Color3.fromRGB(75.00000312924385, 74.0000031888485, 74.0000031888485),
				CrackedLava = Color3.fromRGB(255, 24.000000469386578, 67.00000360608101),
				Limestone = Color3.fromRGB(255, 243.00000071525574, 192.00000375509262),
				Pavement = Color3.fromRGB(143.00000667572021, 144.00000661611557, 135.00000715255737),
				Grass = Color3.fromRGB(105.00000134110451, 112.000000923872, 71.00000336766243),
				LeafyGrass = Color3.fromRGB(92.00000211596489, 98.00000175833702, 62.00000010430813),
				Sand = Color3.fromRGB(207.00000286102295, 203.00000309944153, 167.00000524520874),
				Snow = Color3.fromRGB(235.0000011920929, 253.0000001192093, 255),
				Mud = Color3.fromRGB(121.00000038743019, 112.000000923872, 98.00000175833702),
				Ground = Color3.fromRGB(188.0000039935112, 178.00000458955765, 164.00000542402267),
				Asphalt = Color3.fromRGB(113.00000086426735, 111.00000098347664, 108.00000116229057),
				Salt = Color3.fromRGB(255, 255, 254.00000005960464),
				Ice = Color3.fromRGB(204.00000303983688, 210.00000268220901, 223.00000190734863),
				Glacier = Color3.fromRGB(221.00000202655792, 228.0000016093254, 229.00000154972076)
			}
		}
	}
})