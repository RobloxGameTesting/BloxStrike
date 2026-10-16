local DataController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local Stock = require(ReplicatedStorage.Database.Components.Libraries.Stock)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Promise = require(ReplicatedStorage.Shared.Promise)
local Sift = require(ReplicatedStorage.Packages.Sift)
local v = { "Serial", "Pattern" }
local v2 = { "OriginalOwner", "Owner" }
local v3 = {}
local v4 = {}

local function FireListeners(p, p2: string, items)
	local v5 = DataController.Get(p, p2)

	for _, item in pairs(items) do
		Promise.try(item, v5)
	end
end

local function ExecuteListeners(p, list)
	local v5 = v4[p]

	if not v5 then
		return
	end

	local v6 = ""

	for i, v7 in ipairs(list) do
		if i <= 1 then
			v6 = v7
		else
			v6 = `{v6}.{v7}`
		end

		local v8 = v5[v6]

		if v8 then
			FireListeners(p, v6, v8)
		end
	end
end

local function DenormalizeInventoryItemFromRemote(p)
	local result = Sift.Dictionary.copyDeep(p)

	for _, v5 in v do
		if result[v5] ~= nil and typeof(result[v5]) == "string" then
			result[v5] = tonumber(result[v5]) or result[v5]
		end
	end

	if result.MetaData and typeof(result.MetaData) == "table" then
		for _, v5 in v2 do
			if result.MetaData[v5] ~= nil and typeof(result.MetaData[v5]) == "string" then
				result.MetaData[v5] = tonumber(result.MetaData[v5]) or result.MetaData[v5]
			end
		end
	end

	return result
end

local function ShouldDenormalizeInventoryItem(data)
	if typeof(data) ~= "table" then
		return false
	end

	local metaData = data.MetaData
	local v5 = typeof(metaData) == "table"
	return (typeof(data.Serial) == "string" or typeof(data.Pattern) == "string" or v5 and typeof(metaData.OriginalOwner) == "string")
		and true
		or v5 and typeof(metaData.Owner) == "string"
end

function DataController.ApplyInventoryDelta(p, list, list2)
	local v5 = v3[p]

	if not (v5 and v5.Inventory) then
		return
	end

	local flag = false

	if list2 then
		local v6 = {}

		for _, v7 in ipairs(list2) do
			v6[v7] = true
		end

		for i = #v5.Inventory, 1, -1 do
			local v7 = v5.Inventory[i]

			if not (v7 and v7._id and v6[v7._id]) then
				continue
			end

			table.remove(v5.Inventory, i)
			flag = true
		end
	end

	local v6 = {}

	for _, v7 in ipairs(v5.Inventory) do
		if v7 and v7._id then
			v6[v7._id] = true
		end
	end

	for _, v7 in ipairs(list) do
		if ShouldDenormalizeInventoryItem(v7) then
			v7 = DenormalizeInventoryItemFromRemote(v7)
		end

		if not v7 or not v7._id or v6[v7._id] then
			continue
		end

		table.insert(v5.Inventory, v7)
		v6[v7._id] = true
		flag = true
	end

	if flag then
		ExecuteListeners(p, { "Inventory" })
	end
end

function DataController.IsDataLoaded(p)
	return v3[p] ~= nil
end

function DataController.WaitForDataLoaded(p)
	local total = 0

	while not v3[p] do
		total += task.wait()

		if total >= 60 then
			error(`[DataController] Failed to load player profile for {p.Name} after {60} seconds`)
		end
	end

	return v3[p]
end

function DataController.Get(p, ...)
	local v5 = v3[p]

	if not v5 then
		return nil
	end

	local v6 = {}

	for _, v7 in table.pack(...) do
		local v8 = v5

		for _, v9 in string.split(v7, ".") do
			v8 = v8[v9]

			if not v8 then
				break
			end
		end

		table.insert(v6, v8)
	end

	return table.unpack(v6)
end

function DataController.RemoveListener(p, p2: string, p3: string)
	if v4[p] and v4[p][p2] then
		v4[p][p2][p3] = nil

		if next(v4[p][p2]) == nil then
			v4[p][p2] = nil
		end
	end
end

function DataController.CreateListener(p, p2: string, callback)
	local guid = HttpService:GenerateGUID(false)
	v4[p] = v4[p] or {}
	v4[p][p2] = v4[p][p2] or {}
	v4[p][p2][guid] = callback
	local v5 = DataController.Get(p, p2)

	if v5 ~= nil then
		Promise.try(callback, v5)
	end

	return guid
end

function DataController.Initialize()
	Remotes.PlayerData.PlayerDataEvent.Listen(function(p)
		local v5 = v4[p.Player]

		if p.Data and p.Data.Inventory then
			Stock.InjectStockItems(p.Data.Inventory)
		end

		v3[p.Player] = p.Data

		if v5 then
			for k, v6 in pairs(v5) do
				FireListeners(p.Player, k, v6)
			end
		end
	end)
	Remotes.PlayerData.PlayerDataChanged.Listen(function(p)
		local player = p.Player
		local v5 = v3[player]

		if not v5 then
			warn(`[DataController] Received data change for {player.Name} but profile not loaded yet. Requesting full profile.`)
			return
		end

		for k, v6 in pairs(p.Data) do
			local v7 = string.split(k, ".")
			local v8 = v5

			for i = 1, #v7 - 1 do
				local v9 = v7[i]

				if typeof(v8[v9]) ~= "table" then
					v8[v9] = {}
				end

				v8 = v8[v9]
			end

			v8[v7[#v7]] = v6
			ExecuteListeners(player, v7)
		end
	end)
end

function DataController.Start()
	Remotes.PlayerData.RetrieveAllPlayerData.Send()
	Remotes.Store.NewInventoryItem.Listen(function(data)
		local player = tonumber(data.Player)

		if not player then
			return
		end

		local playerByUserId = Players:GetPlayerByUserId(player)

		if playerByUserId and playerByUserId:IsDescendantOf(Players) then
			DataController.ApplyInventoryDelta(playerByUserId, data.Items, data.DeletedItemIds)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		v4[player] = nil
		v3[player] = nil
	end)
end

return DataController