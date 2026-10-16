local function line(sound: string, p: number) -- 22 equivalent calls inferred from this helper
	return table.freeze({ Sound = sound, Animation = `rbxassetid://{p}` })
end

local v = {
	SOUND_GROUP = "ArmsDealer",
	IDLE_ANIMATION = "rbxassetid://127680394246389",
	INTRO_ANIMATION = "rbxassetid://95003386452387",
	Open = table.freeze({
		line("Open 1", 108820213143581), -- inferred equivalent call
		line("Open 3", 79434798599791), -- inferred equivalent call
		line("Open 4", 131035732599957), -- inferred equivalent call
		line("Open 5", 100695883001427), -- inferred equivalent call
		line("Open 6", 128685469059709)
	}),
	Rarity = table.freeze({
		Blue = table.freeze({ line("Blue 1", 114988568340900), line("Blue 2", 94131440299691) }), -- inferred equivalent call
		Purple = table.freeze({ line("Purple 2", 70665452356574) }),
		Pink = table.freeze({ line("Pink 1", 70685214815664), line("Pink 2", 108640008269911) }), -- inferred equivalent call
		Red = table.freeze({ line("Red 1", 97498387726202), line("Red 2", 130623891787655) }), -- inferred equivalent call
		Special = table.freeze({ line("Gold 1", 85665191583665), line("Gold 3", 138367858596446) }) -- inferred equivalent call
	}),
	Purchase = table.freeze({
		line("Purchase 1", 90216929714117), -- inferred equivalent call
		line("Purchase 3", 109862435497094), -- inferred equivalent call
		line("Purchase 4", 113255847772841), -- inferred equivalent call
		line("Purchase 5", 125620695537467), -- inferred equivalent call
		line("Purchase 6", 74929276364047)
	}),
	Declined = table.freeze({
		line("Declined 1", 129610298959912), -- inferred equivalent call
		line("Declined 2", 132955562823743), -- inferred equivalent call
		line("Declined 3", 122535234265641), -- inferred equivalent call
		line("Declined 5", 77965099110387)
	}),
	Refresh = table.freeze({
		line("Refresh 1", 76033652919780), -- inferred equivalent call
		line("Refresh 2", 110165533270896), -- inferred equivalent call
		line("Refresh 3", 88608508842745), -- inferred equivalent call
		line("Refresh 4", 123025404949952), -- inferred equivalent call
		line("Refresh 5", 109491615847472), -- inferred equivalent call
		line("Refresh 6", 84677609075487)
	}),
	Discontinued = table.freeze({
		line("Discontinued 1", 123062898010154), -- inferred equivalent call
		line("Discontinued 2", 120236879337679), -- inferred equivalent call
		line("Discontinued 3", 103547167570421)
	}),
	Pick = function(list)
		if list and #list ~= 0 then
			return list[math.random(1, #list)]
		end

		return nil
	end
}
return table.freeze(v)