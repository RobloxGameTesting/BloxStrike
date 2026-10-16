local Interface = {}
Interface.__index = Interface
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Sound = require(ReplicatedStorage.Classes.Sound)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Promise = require(ReplicatedStorage.Shared.Promise)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local MenuState = require(script.MenuState)
local GamepadNavigation = require(script.GamepadNavigation)
local Screens = script:WaitForChild("Screens")
local Mobile = require(ReplicatedStorage.Database.Custom.GameStats.UI.Mobile)
local mainGui = StarterGui:FindFirstChild("MainGui") or ReplicatedStorage.Assets.UI:FindFirstChild("MainGui")

if mainGui then
	Mobile.CaptureDefaults(mainGui)
end

local MainGui = PlayerGui:WaitForChild("MainGui", 1e999)

if not mainGui then
	Mobile.CaptureDefaults(MainGui)
end

local v = 1
local interface = nil
local store = nil
local armsDealer = nil
local v2 = { "Ammo", "Armor", "Health", "Inventory", "Money" }
local v3 = {
	["Screens.Gameplay.Middle.RoundWon"] = true,
	["Screens.Gameplay.Top.PlayerInfo"] = true,
	["Screens.Gameplay.Middle.TutorialDiaklogue"] = true
}
local now = 0
local count = 0

local function resetInterfaceLoadBudget() -- 2 equivalent calls inferred from this helper
	now = os.clock()
	count = 0
end

local function maybeYieldInterfaceLoad() -- 1 equivalent call inferred from this helper
	count += 1

	if count < 4 and os.clock() - now < 0.00125 then
		return
	end

	RunService.Heartbeat:Wait()
	resetInterfaceLoadBudget() -- inferred equivalent call
end

local function runInterfacePhase(p: string, p2: string, callback, ...)
	debug.setmemorycategory(`Interface.{p}`)
	Profiler.mark(`Interface.Module.{p}`)
	Profiler.mark(`Interface.Phase.{p2}`)
	return Profiler.scope(`Interface.Callback.{p2}`, callback, ...)
end

local function promiseRequire(p, p2: string) -- 1 equivalent call inferred from this helper
	return Promise.try(runInterfacePhase, p2, "Require", require, p):catch(warn)
end

local function loadInterfaceModule(child, instancePath: string, child2) -- 1 equivalent call inferred from this helper
	promiseRequire(child, instancePath):andThen(function(p) -- inferred equivalent call
		if typeof(p) ~= "table" then
			return
		end

		local v4

		if p.Initialize then
			v4 = Promise.try(runInterfacePhase, instancePath, "Initialize", p.Initialize, MainGui, child2)
		else
			v4 = Promise.resolve()
		end

		v4:andThen(function()
			if p.Start then
				return Promise.try(runInterfacePhase, instancePath, "Start", p.Start)
			end
		end):catch(warn)
	end)
end

local function loadInterfaceTree(screens, mainGui2)
	if not mainGui2 then
		warn(`Pointer: "{screens.Name}" is not apart of interface.`)
		return
	end

	for _, child in ipairs(screens:GetChildren()) do
		local child2 = mainGui2:FindFirstChild(child.Name)

		if child:IsA("Folder") then
			if child2 then
				loadInterfaceTree(child, child2)
			else
				warn(`Missing corresponding interface folder : "{string.lower(child:GetFullName())}"`)
			end
		elseif child:IsA("ModuleScript") then
			local instancePath = Profiler.getInstancePath(child, script)

			if not v3[instancePath] then
				if child2 then
					loadInterfaceModule(child, instancePath, child2) -- inferred equivalent call
					maybeYieldInterfaceLoad() -- inferred equivalent call
				elseif RunService:IsStudio() then
					warn(`Missing corresponding interface module for : "{string.lower(child:GetFullName())}"`)
				end
			end
		end
	end
end

local function getInterfaceSoundGroup(p: string)
	if p == "Interface" then
		if not (interface and interface.Sounds) then
			interface = Sound.new("Interface")
		end

		return interface
	elseif p == "ArmsDealer" then
		if not (armsDealer and armsDealer.Sounds) then
			armsDealer = Sound.new("ArmsDealer")
		end

		return armsDealer
	else
		if not (store and store.Sounds) then
			store = Sound.new("Store")
		end

		return store
	end
end

local function playInterfaceSound(p: string, name: string)
	local interfaceSoundGroup = getInterfaceSoundGroup(p)

	if interfaceSoundGroup then
		return interfaceSoundGroup:playOneTime({ Parent = PlayerGui, Name = name }, v)
	end
end

function Interface.guarantee(callback)
	local result = nil

	for i = 1, 15 do
		local success
		success, result = pcall(callback)

		if success then
			return true
		end

		if i < 15 then
			task.wait(0.1)
		end
	end

	warn(`[Interface] Core GUI initialization failed after 15 attempts: {tostring(result)}`)
	return false, result
end

function Interface.Initialize()
	MenuState.Initialize(MainGui)
	GamepadNavigation.Initialize()
	Interface.guarantee(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		StarterGui:SetCore("ResetButtonCallback", false)
	end)
	local bottom = MainGui:WaitForChild("Gameplay"):WaitForChild("Bottom")
	local v4 = {}
	local v5 = table.find(GetUserPlatform(), "Mobile") ~= nil

	local function getOrCreateHUDScale(parent)
		local hudScale = parent:FindFirstChild("HUDScale")

		if hudScale and hudScale:IsA("UIScale") then
			return hudScale
		end

		local uiScale = parent:FindFirstChildOfClass("UIScale")

		if uiScale then
			uiScale.Name = "HUDScale"
			return uiScale
		end

		local uiScale2 = Instance.new("UIScale")
		uiScale2.Name = "HUDScale"
		uiScale2.Parent = parent
		return uiScale2
	end

	local function applyHUDScale(p: number) -- 1 equivalent call inferred from this helper
		local scale = v5 and 1 or p

		for _, v6 in ipairs(v4) do
			v6.Scale = scale
		end
	end

	Profiler.spawn("Interface.Initialize.HUDScale", function()
		task.wait(0.1)
		Profiler.mark("Interface.HUDScale.Setup")

		for _, childName in ipairs(v2) do
			local frame = bottom:FindFirstChild(childName)

			if not (frame and frame:IsA("Frame")) then
				continue
			end

			local v6 = frame:FindFirstChild("HUDScale")

			if not (v6 and v6:IsA("UIScale")) then
				v6 = frame:FindFirstChildOfClass("UIScale")

				if v6 then
					v6.Name = "HUDScale"
				else
					v6 = Instance.new("UIScale")
					v6.Name = "HUDScale"
					v6.Parent = frame
				end
			end

			table.insert(v4, v6)
		end

		applyHUDScale(DataController.Get(LocalPlayer, "Settings.Game.HUD.Scale") or 1) -- inferred equivalent call
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Scale", function(value: number)
		local scale = v5 and 1 or value or 1

		for _, v6 in ipairs(v4) do
			v6.Scale = scale
		end
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Audio.Music.Main Menu Volume", function(p: number?)
		v = (tonumber(p) or 100) / 100
	end)
	Router.observerRouter("RunInterfaceSound", function(name: string)
		if not (interface and interface.Sounds) then
			interface = Sound.new("Interface")
		end

		local v6 = interface

		if not v6 then
			return
		end

		v6:playOneTime({ Parent = PlayerGui, Name = name }, v)
	end)
	Router.observerRouter("RunStoreSound", function(name: string)
		return playInterfaceSound("Store", name)
	end)
	Router.observerRouter("RunArmsDealerSound", function(name: string)
		return playInterfaceSound("ArmsDealer", name)
	end)
end

function Interface.Start()
	resetInterfaceLoadBudget() -- inferred equivalent call
	loadInterfaceTree(Screens, MainGui)
end

return Interface