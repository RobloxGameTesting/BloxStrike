local RunService = game:GetService("RunService")
local isStudio = RunService:IsStudio()
local v = not RunService:IsServer() and 0 or game.PrivateServerOwnerId
local frozen = table.freeze({
	UnrankedComp = 89844875164241,
	Deathmatch = 107028954108065,
	Defusal = 100334860793031,
	Tutorial = 0
})
local frozen2 = table.freeze({
	UnrankedComp = 108194354348181,
	Deathmatch = 135434213652028,
	Defusal = 114234929420007,
	Tutorial = 135154320945903
})
local frozen3 = table.freeze({
	Mobile = table.freeze({
		UnrankedComp = 128037611684480,
		Deathmatch = 103953226898816,
		Defusal = 75364289796924
	}),
	Console = table.freeze({
		UnrankedComp = 132331296438894,
		Deathmatch = 122102693569834,
		Defusal = 86299871106535
	})
})

local function isInGamemodeSubplaceSet(p, items) -- 4 equivalent calls inferred from this helper
	for _, item in pairs(items) do
		if item == p then
			return true
		end
	end

	return false
end

local function getDevicePlatform(p) -- 2 equivalent calls inferred from this helper
	if isInGamemodeSubplaceSet(p, frozen3.Mobile) then -- inferred equivalent call
		return "Mobile"
	end

	if isInGamemodeSubplaceSet(p, frozen3.Console) then -- inferred equivalent call
		return "Console"
	end

	return nil
end

local function getActivePlaceEnvironment(placeId) -- 1 equivalent call inferred from this helper
	if
		isInGamemodeSubplaceSet(placeId, frozen) -- inferred equivalent call
		or not isInGamemodeSubplaceSet(placeId, frozen2) -- inferred equivalent call
		and getDevicePlatform(placeId) == nil -- inferred equivalent call
		and game.GameId ~= 7633926880
	then
		return "Dev"
	end

	return "Prod"
end

local function getActiveGamemodeSubplaceIds(activePlaceEnvironment: string, devicePlatform: string?)
	if activePlaceEnvironment == "Dev" then
		return frozen
	end

	if not devicePlatform then
		return frozen2
	end

	local v2 = frozen3[devicePlatform]
	return table.freeze({
		UnrankedComp = v2.UnrankedComp,
		Deathmatch = v2.Deathmatch,
		Defusal = v2.Defusal,
		Tutorial = frozen2.Tutorial
	})
end

local function getDeviceServerPlaceId(p: string, p2: number)
	local v2 = frozen3[p]

	if not v2 then
		return nil
	end

	for k, v3 in pairs(frozen2) do
		if v3 == p2 and v2[k] then
			return v2[k]
		end
	end

	return nil
end

local devicePlatform = getDevicePlatform(game.PlaceId) -- inferred equivalent call
local activePlaceEnvironment = getActivePlaceEnvironment(game.PlaceId) -- inferred equivalent call
local activeGamemodeSubplaceIds = getActiveGamemodeSubplaceIds(activePlaceEnvironment, devicePlatform)
local defusal = activeGamemodeSubplaceIds.Defusal
local unrankedComp = activeGamemodeSubplaceIds.UnrankedComp
local competitive = (unrankedComp == defusal or not unrankedComp) and 0 or unrankedComp

local function getActiveGamemode(placeId)
	if placeId == 101836176558619 then
		return "trading"
	end

	if placeId == activeGamemodeSubplaceIds.Deathmatch then
		return "deathmatch"
	end

	if placeId == activeGamemodeSubplaceIds.Defusal then
		return "casual"
	end

	if competitive ~= 0 and placeId == competitive then
		return "competitive"
	end

	if activeGamemodeSubplaceIds.Tutorial ~= 0 and placeId == activeGamemodeSubplaceIds.Tutorial then
		return "tutorial"
	end

	for _, v2 in { frozen, frozen2 } do
		if placeId == v2.Deathmatch then
			return "deathmatch"
		end

		if placeId == v2.Defusal then
			return "casual"
		end

		if v2.UnrankedComp ~= v2.Defusal and placeId == v2.UnrankedComp then
			return "competitive"
		end

		if v2.Tutorial ~= 0 and placeId == v2.Tutorial then
			return "tutorial"
		end
	end

	return "casual"
end

local frozen4 = table.freeze({
	Competitive = "competitive",
	Deathmatch = "deathmatch",
	Casual = "casual"
})

local function getGamemodeFromServerGamemode(value)
	if typeof(value) == "string" and frozen4[value] then
		return frozen4[value]
	end

	return (getActiveGamemode(game.PlaceId))
end

return table.freeze({
	SHOP_VERSION = "1.0.1",
	VERSION = "1.3.5",
	MINIMUM_CREDITS_FOR_SPECIAL_CREDITS_OPTION = 100000,
	MARKETPLACE_MAX_LISTING_PRICE = 100000000,
	MARKET_TAX_PERCENT = 5,
	ITEM_CATEGORIES = table.freeze({
		"All",
		"Pistol",
		"SMG",
		"Rifle",
		"Heavy",
		"Equipment",
		"Miscellaneous"
	}),
	MARKETPLACE_SORTING_OPTIONS = table.freeze({
		"Quality",
		"RAP",
		"Newest",
		"Alphabetical",
		"Collection",
		"Type",
		"Float"
	}),
	INVENTORY_SORTING_OPTIONS = table.freeze({
		"Quality",
		"RAP",
		"Newest",
		"Alphabetical",
		"Collection",
		"Equipped",
		"Type",
		"Float",
		"Serial"
	}),
	DEFAULT_CAMERA_FOV = 70,
	ACTIVE_EVENTS = { ["MEDAL.TV"] = false },
	EVENT_END_TIMES = {
		["MEDAL.TV"] = os.time({
			year = 2026,
			month = 3,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0
		})
	},
	GetGamemodeFromServerGamemode = getGamemodeFromServerGamemode,
	SESSION_DATA = {
		VIP_SERVER_OWNER = v > 0 and v or nil,
		PRIVATE_SERVER_ID = isStudio and "Studio" or game.PrivateServerId,
		JOB_ID = isStudio and "Studio" or game.JobId,
		GAMEMODE = getActiveGamemode(game.PlaceId),
		UNIVERSE_ID = game.GameId,
		PLACE_ID = game.PlaceId
	},
	VIP_MENU_PANEL_WHITELIST = {
		363101315,
		3659308968,
		1243042178,
		107643044,
		9236102964,
		38260227,
		40222641,
		3436218611,
		9678116347
	},
	AIM_ASSIST_CONFIGS = {
		PLAYER = {
			TargetSelection = { Enabled = true, MaxDistance = 125, MaxAngle = 0.5235987755982988 },
			Friction = {
				Enabled = true,
				BubbleRadius = 2.4,
				MinSensitivity = 0.5,
				MaxSensitivity = 1
			},
			Magnetism = {
				Enabled = true,
				MaxAngleHorizontal = 0.20943951023931956,
				MaxAngleVertical = 0.10471975511965978,
				PullStrength = 0.11344640137963143,
				StopThreshold = 0.008726646259971648,
				MaxDistance = 125
			},
			VerticalMagnetism = {
				Enabled = true,
				MaxAngleHorizontal = 0.20943951023931956,
				MaxAngleVertical = 0.10471975511965978,
				PullStrength = 0.11344640137963143,
				StopThreshold = 0.008726646259971648,
				MaxDistance = 125
			},
			RecoilAssist = {
				Enabled = true,
				ReductionAmount = 0.5,
				HorizontalReductionAmount = 0.85,
				RequiresTarget = false
			}
		}
	},
	PROMOTIONAL_REWARD_CREDITS = table.freeze({
		Notifications = 15,
		FavoriteGame = 15,
		InviteFriend = 15,
		JoinGroup = 15,
		LikeGame = 15
	}),
	PRODUCTION_UNIVERSE_ID = 7633926880,
	ACTIVE_PLACE_ENVIRONMENT = activePlaceEnvironment,
	GAMEMODE_SUBPLACE_IDS = { Prod = frozen2, Dev = frozen },
	ACTIVE_GAMEMODE_SUBPLACE_IDS = activeGamemodeSubplaceIds,
	GAMEMODE_PLACE_IDS = {
		Deathmatch = activeGamemodeSubplaceIds.Deathmatch,
		Casual = activeGamemodeSubplaceIds.Defusal,
		Competitive = competitive,
		Tutorial = activeGamemodeSubplaceIds.Tutorial,
		Trading = 101836176558619
	},
	TRADING_PLACE_ID = 101836176558619,
	DEVICE_GAMEMODE_SUBPLACE_IDS = frozen3,
	ACTIVE_DEVICE_PLATFORM = devicePlatform,
	IS_DEVICE_SERVER = devicePlatform ~= nil,
	GetDeviceServerPlaceId = getDeviceServerPlaceId,
	TUTORIAL_TELEPORT_ENABLED = false,
	BLACK_MARKET_ENABLED = true
})