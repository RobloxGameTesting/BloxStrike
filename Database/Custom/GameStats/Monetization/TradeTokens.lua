local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Router = require(ReplicatedStorage.Database.Security.Router)
local isServer = RunService:IsServer()

local function TokenPurchase(p: string, p2: number?) -- 15 equivalent calls inferred from this helper
	return function(p3, p4: number)
		assert(isServer, "This function should only be called on the server.")

		if p2 == nil then
			return Router.broadcastRouter(p, p3, p4)
		end

		return Router.broadcastRouter(p, p3, p2, p4)
	end
end

local function DisabledPurchase(_, _: number)
	assert(isServer, "This function should only be called on the server.")
	return false
end

return table.freeze({
	["Credits Starter Pack"] = {
		Price = 57,
		OnPurchased = TokenPurchase("Purchase Credits Starter Pack With Tokens", nil) -- inferred equivalent call
	},
	["+ 400 Credits"] = {
		Price = 229,
		OnPurchased = TokenPurchase("Purchase Credits With Tokens", 400) -- inferred equivalent call
	},
	["+ 950 Credits"] = {
		Price = 517,
		OnPurchased = TokenPurchase("Purchase Credits With Tokens", 950) -- inferred equivalent call
	},
	["+ 3,100 Credits"] = {
		Price = 1437,
		OnPurchased = TokenPurchase("Purchase Credits With Tokens", 3100) -- inferred equivalent call
	},
	["+ 6,500 Credits"] = {
		Price = 2874,
		OnPurchased = TokenPurchase("Purchase Credits With Tokens", 6500) -- inferred equivalent call
	},
	["+ 13,250 Credits"] = {
		Price = 5749,
		OnPurchased = TokenPurchase("Purchase Credits With Tokens", 13250) -- inferred equivalent call
	},
	["+ 27,000 Credits"] = {
		Price = 11499,
		OnPurchased = TokenPurchase("Purchase Credits With Tokens", 27000) -- inferred equivalent call
	},
	["+ 67,500 Credits"] = {
		Price = 28749,
		OnPurchased = TokenPurchase("Purchase Credits With Tokens", 67500) -- inferred equivalent call
	},
	["Gift + 400 Credits"] = {
		Price = 229,
		OnPurchased = TokenPurchase("Gift Credits With Tokens", 400) -- inferred equivalent call
	},
	["Gift + 950 Credits"] = {
		Price = 517,
		OnPurchased = TokenPurchase("Gift Credits With Tokens", 950) -- inferred equivalent call
	},
	["Gift + 3,100 Credits"] = {
		Price = 1437,
		OnPurchased = TokenPurchase("Gift Credits With Tokens", 3100) -- inferred equivalent call
	},
	["Gift + 6,500 Credits"] = {
		Price = 2874,
		OnPurchased = TokenPurchase("Gift Credits With Tokens", 6500) -- inferred equivalent call
	},
	["Gift + 13,250 Credits"] = {
		Price = 5749,
		OnPurchased = TokenPurchase("Gift Credits With Tokens", 13250) -- inferred equivalent call
	},
	["Gift + 27,000 Credits"] = {
		Price = 11499,
		OnPurchased = TokenPurchase("Gift Credits With Tokens", 27000) -- inferred equivalent call
	},
	["Gift + 67,500 Credits"] = {
		Price = 28749,
		OnPurchased = TokenPurchase("Gift Credits With Tokens", 67500) -- inferred equivalent call
	},
	["Purchase Featured Bundle"] = { Price = 1149, OnPurchased = DisabledPurchase },
	["Gift Featured Bundle"] = { Price = 1149, OnPurchased = DisabledPurchase },
	["M4A4 | Freedom"] = { Price = 689, OnPurchased = DisabledPurchase },
	["AWP | Freedom"] = { Price = 459, OnPurchased = DisabledPurchase },
	["Desert Eagle | Freedom"] = { Price = 574, OnPurchased = DisabledPurchase },
	["Gift M4A4 | Freedom"] = { Price = 689, OnPurchased = DisabledPurchase },
	["Gift AWP | Freedom"] = { Price = 459, OnPurchased = DisabledPurchase },
	["Gift Desert Eagle | Freedom"] = { Price = 574, OnPurchased = DisabledPurchase }
})