local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local color = Color3.fromRGB(255, 70, 70)
local color2 = Color3.fromRGB(255, 255, 255)
local v = {}
local v2 = nil
local flag = false

local function isEnemy(instance)
	if instance == LocalPlayer or not Participants.IsAlive(instance) then
		return false
	end

	if Workspace:GetAttribute("Gamemode") == "Deathmatch" then
		return true
	end

	local team = instance:GetAttribute("Team")
	return (team == "Terrorists" or team == "Counter-Terrorists") and team ~= LocalPlayer:GetAttribute("Team")
end

local function getContainer() -- 1 equivalent call inferred from this helper
	if v2 and v2.Parent then
		return v2
	end

	local folder = Instance.new("Folder")
	folder.Name = "VIPESP"
	folder.Parent = Workspace.CurrentCamera
	v2 = folder
	return folder
end

local function clear() -- 2 equivalent calls inferred from this helper
	for _, v3 in v do
		v3:Destroy()
	end

	table.clear(v)
end

local function refresh()
	local v3 = {}

	for _, v4 in Participants.GetAll() do
		if not isEnemy(v4) then
			continue
		end

		local character = Participants.Character(v4)

		if character and character:IsDescendantOf(Workspace) then
			v3[character] = true
		end
	end

	for k, v4 in v do
		if v3[k] then
			continue
		end

		v4:Destroy()
		v[k] = nil
	end

	for k in v3 do
		if v[k] ~= nil then
			continue
		end

		local highlight = Instance.new("Highlight")
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = color
		highlight.FillTransparency = 0.55
		highlight.OutlineColor = color2
		highlight.OutlineTransparency = 0
		highlight.Adornee = k
		highlight.Parent = getContainer() -- inferred equivalent call
		v[k] = highlight
	end
end

local function run() -- 1 equivalent call inferred from this helper
	if flag then
		return
	end

	flag = true
	task.spawn(function()
		while LocalPlayer:GetAttribute("VIPESP") == true do
			refresh()
			task.wait(0.25)
		end

		clear() -- inferred equivalent call
		flag = false
	end)
end

return {
	Start = function()
		LocalPlayer:GetAttributeChangedSignal("VIPESP"):Connect(function()
			if LocalPlayer:GetAttribute("VIPESP") == true then
				if flag then
					return
				end

				flag = true
				task.spawn(function()
					while LocalPlayer:GetAttribute("VIPESP") == true do
						refresh()
						task.wait(0.25)
					end

					clear() -- inferred equivalent call
					flag = false
				end)
			end
		end)

		if LocalPlayer:GetAttribute("VIPESP") == true then
			run() -- inferred equivalent call
		end
	end
}