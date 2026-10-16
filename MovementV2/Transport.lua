local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local frozen = table.freeze({
	Commands = "UnreliableRemoteEvent",
	OwnerSnapshot = "UnreliableRemoteEvent",
	RemoteSnapshot = "UnreliableRemoteEvent",
	BotCombat = "UnreliableRemoteEvent",
	Control = "RemoteEvent",
	Trace = "RemoteEvent",
	Diagnostics = "RemoteEvent"
})

local function validateRemote(instance, childName: string, p: string) -- 2 equivalent calls inferred from this helper
	if instance.ClassName ~= p then
		error(`MovementV2 transport {childName} must be {p}, found {instance.ClassName}`, 3)
	end

	return instance
end

local function getOrCreateServerFolder()
	local movementV2Remotes = ReplicatedStorage:FindFirstChild("MovementV2Remotes")

	if movementV2Remotes ~= nil then
		assert(movementV2Remotes:IsA("Folder"), "ReplicatedStorage.MovementV2Remotes must be a Folder")
		return movementV2Remotes
	end

	local folder = Instance.new("Folder")
	folder.Name = "MovementV2Remotes"
	folder.Parent = ReplicatedStorage
	return folder
end

local function resolveServerChannels()
	assert(RunService:IsServer(), "Transport.getServerChannels is server-only")
	local parent = ReplicatedStorage:FindFirstChild("MovementV2Remotes")

	if parent == nil then
		parent = Instance.new("Folder")
		parent.Name = "MovementV2Remotes"
		parent.Parent = ReplicatedStorage
	else
		assert(parent:IsA("Folder"), "ReplicatedStorage.MovementV2Remotes must be a Folder")
	end

	local v = {}

	for childName, className in frozen do
		local instance = parent:FindFirstChild(childName)

		if instance == nil then
			instance = Instance.new(className)
			instance.Name = childName
			instance.Parent = parent
		end

		v[childName] = validateRemote(instance, childName, className) -- inferred equivalent call
	end

	return (table.freeze(v))
end

local function resolveClientChannels()
	assert(RunService:IsClient(), "Transport.getClientChannels is client-only")
	local movementV2Remotes = ReplicatedStorage:WaitForChild("MovementV2Remotes")
	assert(movementV2Remotes:IsA("Folder"), "ReplicatedStorage.MovementV2Remotes must be a Folder")
	local v = {}

	for childName, v2 in frozen do
		v[childName] = validateRemote(movementV2Remotes:WaitForChild(childName), childName, v2) -- inferred equivalent call
	end

	return (table.freeze(v))
end

local v2 = nil
local v3 = nil
local v = {
	getServerChannels = function()
		if v2 == nil then
			v2 = resolveServerChannels()
		end

		return v2
	end,
	getClientChannels = function()
		if v3 == nil then
			v3 = resolveClientChannels()
		end

		return v3
	end
}
return table.freeze(v)