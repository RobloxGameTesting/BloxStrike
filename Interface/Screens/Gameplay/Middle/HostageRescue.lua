local HostageRescue = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local v = {}
local parent = nil

local function UpdateTemplateState(p, state: string) -- 2 equivalent calls inferred from this helper
	p.Idle.Visible = state ~= "Carrying"
	p.Action.Visible = state == "Carrying"
end

local function ClearFrame(instance)
	for _, child in ipairs(instance:GetChildren()) do
		if not v[child] then
			continue
		end

		v[child]:Destroy()
		v[child] = nil
	end
end

local function UpdateTemplateSizes()
	local frames = {}

	for _, frame in ipairs(parent:GetChildren()) do
		if frame:IsA("Frame") then
			table.insert(frames, frame)
		end
	end

	for _, v2 in ipairs(frames) do
		v2.Size = UDim2.fromScale(1 / #frames, 1)
	end
end

local function UpdatePosition(p: number) -- 1 equivalent call inferred from this helper
	if not parent then
		return
	end

	local v2 = 240 - (200 - p * 200) + 50
	parent.Position = UDim2.new(0.029, 0, 0, v2)
end

local function UpdateVisibility() -- 1 equivalent call inferred from this helper
	if not parent then
		return
	end

	parent.Visible = workspace:GetAttribute("Gamemode") == "Hostage Rescue"
end

function HostageRescue.CreateTemplate(_)
	local clone = ReplicatedStorage.Assets.UI.HostageRescue.Template:Clone()
	clone.Parent = parent
	UpdateTemplateSizes()
	return clone
end

function HostageRescue.Initialize(_, p)
	parent = p
	DataController.CreateListener(LocalPlayer, "Settings.Game.Radar/Tablet.Radar Hud Size", UpdatePosition)
	UpdatePosition(DataController.Get(LocalPlayer, "Settings.Game.Radar/Tablet.Radar Hud Size") or 1) -- inferred equivalent call
	UpdateVisibility() -- inferred equivalent call
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(UpdateVisibility)
	GameState.ListenToState(function(_, p2)
		if p2 == "Buy Period" or p2 == "Warmup" then
			ClearFrame(parent)
		end
	end)
	Observers.observeTag("Hostage", function(instance)
		local maid = Janitor.new()
		maid:Add(UpdateTemplateSizes)
		local v2 = maid:Add(HostageRescue.CreateTemplate(instance))
		v[v2] = maid
		UpdateTemplateState(v2, instance:GetAttribute("State") or "Idle") -- inferred equivalent call
		maid:Add(instance:GetAttributeChangedSignal("State"):Connect(function()
			UpdateTemplateState(v2, instance:GetAttribute("State") or "Idle") -- inferred equivalent call
		end))
		return function()
			if v[v2] then
				v[v2]:Destroy()
				v[v2] = nil
			end
		end
	end)
end

return HostageRescue