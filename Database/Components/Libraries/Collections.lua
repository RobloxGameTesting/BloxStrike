local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
require(ReplicatedStorage.Database.Custom.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local onAvailableCollectionsUpdated = Signal.new()
local Collections = { OnAvailableCollectionsUpdated = onAvailableCollectionsUpdated }
local v = {}
local flag = false

local function UpdateAvailableCollections(availableCollections: string) -- 1 equivalent call inferred from this helper
	v = HttpService:JSONDecode(availableCollections)
	flag = true
	onAvailableCollectionsUpdated:Fire(v)
end

function Collections.GetCollectionByName(p: string)
	for _, v2 in ipairs(v) do
		if v2.name == p then
			return v2
		end
	end

	return nil
end

function Collections.GetAllCollections()
	return v
end

function Collections.ObserveAvailableCollections(callback)
	local connection = onAvailableCollectionsUpdated:Connect(callback)

	if flag then
		callback(v)
	end

	return function()
		connection:Disconnect()
	end
end

local function SyncAvailableCollections() -- 1 equivalent call inferred from this helper
	local availableCollections = ReplicatedStorage:GetAttribute("AvailableCollections")

	if typeof(availableCollections) == "string" then
		UpdateAvailableCollections(availableCollections) -- inferred equivalent call
	end
end

SyncAvailableCollections() -- inferred equivalent call
ReplicatedStorage:GetAttributeChangedSignal("AvailableCollections"):Connect(SyncAvailableCollections)
return Collections