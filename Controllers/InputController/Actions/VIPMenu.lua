local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local v = nil
local v2 = 0
local bindPriority = Enum.ContextActionPriority.High.Value + 1

local function getVIPMenu()
	if v then
		return v
	end

	local success, result = pcall(function()
		return require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.VIPMenu)
	end)

	if success then
		v = result
		return v
	end

	warn(`Failed to load VIPMenu module: {tostring(result)}`)
	return nil
end

local function toggleVIPMenu()
	local now = os.clock()

	if now - v2 < 0.15 then
		return
	end

	v2 = now

	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		return
	end

	local v3

	if v then
		v3 = v
	else
		local success, result = pcall(function()
			return require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.VIPMenu)
		end)

		if success then
			v = result
			v3 = v
		else
			warn(`Failed to load VIPMenu module: {tostring(result)}`)
		end
	end

	if v3 then
		v3.toggleFrame()
	end
end

local function onInput(p, _)
	if p ~= Enum.UserInputState.Begin then
		return
	end

	local now = os.clock()

	if now - v2 < 0.15 then
		return
	end

	v2 = now

	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		return
	end

	local v3

	if v then
		v3 = v
	else
		local success, result = pcall(function()
			return require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.VIPMenu)
		end)

		if success then
			v = result
			v3 = v
		else
			warn(`Failed to load VIPMenu module: {tostring(result)}`)
		end
	end

	if v3 then
		v3.toggleFrame()
	end
end

return table.freeze({
	Name = "VIP Menu",
	Group = "Default",
	Category = "UI Keys",
	BindPriority = bindPriority,
	Callback = onInput
})