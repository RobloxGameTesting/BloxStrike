local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CharacterResolver = require(script.Parent.CharacterResolver)
local v = {}

local function botFolder() -- 4 equivalent calls inferred from this helper
	return ReplicatedStorage:FindFirstChild("Combatants")
end

function v.IsBot(player)
	return player ~= nil and not player:IsA("Player")
end

function v.BotKey(p: number)
	return -(p + 1000)
end

function v.Key(player)
	if player:IsA("Player") then
		return player.UserId
	end

	return (player:GetAttribute("UserId"))
end

function v.FromKey(p)
	local v2 = tonumber(p)

	if v2 == nil or v2 == 0 then
		return nil
	end

	if v2 > -1000 then
		return Players:GetPlayerByUserId(v2)
	end

	local v3 = botFolder() -- inferred equivalent call

	if v3 then
		return (v3:FindFirstChild((tostring(-v2 - 1000))))
	end

	return nil
end

function v.Name(player)
	if player:IsA("Player") then
		return player.Name
	end

	local displayName = player:GetAttribute("DisplayName")

	if type(displayName) == "string" then
		return displayName
	end

	return player.Name
end

function v.DisplayName(player)
	if player:IsA("Player") then
		return player.DisplayName
	end

	return v.Name(player)
end

function v.AvatarUserId(player)
	if player:IsA("Player") then
		return player.UserId
	end

	local avatarUserId = player:GetAttribute("AvatarUserId")

	if type(avatarUserId) == "number" then
		return avatarUserId
	end

	return 1
end

function v.HeadshotImage(p, value: number?)
	local v2 = value or 150
	return `rbxthumb://type=AvatarHeadShot&id={v.AvatarUserId(p)}&w={v2}&h={v2}`
end

function v.IsAlive(player)
	if player == nil then
		return false
	end

	if player:IsA("Player") then
		return CharacterResolver.isAlivePlayer(player)
	end

	local health = player:GetAttribute("Health")
	return player:GetAttribute("Dead") ~= true and (type(health) ~= "number" or health > 0)
end

function v.FromName(childName: string)
	local player = Players:FindFirstChild(childName)

	if player and player:IsA("Player") then
		return player
	end

	local v2 = botFolder() -- inferred equivalent call

	if v2 then
		for _, child in v2:GetChildren() do
			if child:GetAttribute("DisplayName") == childName then
				return child
			end
		end
	end

	return nil
end

function v.GetAll()
	local result = {}

	for _, v2 in Players:GetPlayers() do
		result[#result + 1] = v2
	end

	local v2 = botFolder() -- inferred equivalent call

	if v2 then
		for _, folder in v2:GetChildren() do
			if folder:IsA("Folder") then
				result[#result + 1] = folder
			end
		end
	end

	return result
end

local modelsByCombatantId = {}
local v2 = nil
local v3 = true
local v4 = {}

local function markIndexDirty()
	v3 = true
end

local function shellIndex(characters)
	if characters ~= v2 then
		for _, connection in v4 do
			connection:Disconnect()
		end

		v4 = { characters.ChildAdded:Connect(markIndexDirty), characters.ChildRemoved:Connect(markIndexDirty) }
		v2 = characters
		v3 = true
	end

	if not v3 then
		return modelsByCombatantId
	end

	v3 = false
	table.clear(modelsByCombatantId)

	for _, model in characters:GetChildren() do
		if not (model:IsA("Model") and model:GetAttribute("Bot") == true) then
			continue
		end

		local combatantId = model:GetAttribute("CombatantId")

		if combatantId ~= nil and modelsByCombatantId[combatantId] == nil then
			modelsByCombatantId[combatantId] = model
		end
	end

	return modelsByCombatantId
end

function v.Character(player)
	if player == nil then
		return nil
	end

	if player:IsA("Player") then
		return player.Character
	end

	local combatantId = player:GetAttribute("CombatantId")
	local characters = Workspace:FindFirstChild("Characters")

	if not characters or combatantId == nil then
		return nil
	end

	local v5 = shellIndex(characters)[combatantId]

	if v5 ~= nil and v5.Parent ~= characters then
		v3 = true
		return shellIndex(characters)[combatantId]
	end

	return v5
end

function v.Observe(callback, callback2)
	local connections = {}
	local connections2 = {}

	local function add(instance) -- 2 equivalent calls inferred from this helper
		if instance:IsA("Player") or instance:IsA("Folder") then
			task.spawn(callback, instance)
		end
	end

	local function remove(instance)
		if callback2 and (instance:IsA("Player") or instance:IsA("Folder")) then
			task.spawn(callback2, instance)
		end
	end

	local function bindFolder(instance)
		for _, connection in connections2 do
			connection:Disconnect()
		end

		table.clear(connections2)
		connections2[#connections2 + 1] = instance.ChildAdded:Connect(add)
		connections2[#connections2 + 1] = instance.ChildRemoved:Connect(remove)

		for _, child in instance:GetChildren() do
			add(child) -- inferred equivalent call
		end
	end

	connections[#connections + 1] = Players.PlayerAdded:Connect(add)
	connections[#connections + 1] = Players.PlayerRemoving:Connect(remove)
	connections[#connections + 1] = ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "Combatants" then
			bindFolder(child)
		end
	end)

	for _, v5 in Players:GetPlayers() do
		add(v5) -- inferred equivalent call
	end

	local v5 = botFolder() -- inferred equivalent call

	if v5 then
		bindFolder(v5)
	end

	return function()
		for _, connection in connections do
			connection:Disconnect()
		end

		for _, connection in connections2 do
			connection:Disconnect()
		end
	end
end

return table.freeze(v)