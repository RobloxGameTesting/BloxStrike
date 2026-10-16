local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local CareerData = require(script.CareerData)
local Selection = require(script.Selection)
local Overview = require(script.Overview)
local WeaponStats = require(script.WeaponStats)
local MatchHistory = require(script.MatchHistory)
local WeaponIcon = require(script.WeaponIcon)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local SetTabSelected = require(ReplicatedStorage.Components.Common.InterfaceAnimations.SetTabSelected)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local frozen = table.freeze({
	Overview = "Overview",
	MatchHistory = "Matchhistory",
	WeaponStats = "WeaponStats",
	Leaderboard = "Leaderboard"
})
local frozen2 = table.freeze({ "Overview", "MatchHistory", "WeaponStats", "Leaderboard" })
local v = nil
local pages = nil
local v2 = "Overview"
local buttonsByChildName = {}

local function GetPage(childName: string) -- 5 equivalent calls inferred from this helper
	local frame = pages:FindFirstChild(childName)

	if frame and frame:IsA("Frame") then
		return frame
	end

	return nil
end

local function UpdateTabButtons() -- 1 equivalent call inferred from this helper
	for k, v3 in pairs(buttonsByChildName) do
		SetTabSelected(v3, k == v2)
	end
end

local function ShowTab(p: string)
	v2 = p

	for k, v3 in pairs(frozen) do
		local page = GetPage(v3) -- inferred equivalent call

		if page then
			page.Visible = k == p
		end
	end

	if p ~= "MatchHistory" then
		MatchHistory.Close()
	end

	UpdateTabButtons() -- inferred equivalent call
	Overview.RefreshSelection()
end

local function SelectTab(p: string) -- 1 equivalent call inferred from this helper
	if v2 == p then
		return
	end

	Router.broadcastRouter("RunInterfaceSound", "UI Click")
	ShowTab(p)
end

local function Render() -- 3 equivalent calls inferred from this helper
	Overview.Render()
	WeaponStats.Render()
	MatchHistory.Render()
end

local Career = {}

function Career.Initialize(_, instance)
	v = instance
	pages = instance:WaitForChild("Pages")
	v.Visible = false
	local categories = instance:WaitForChild("Top"):WaitForChild("Categories")

	for childName in pairs(frozen) do
		local button = categories:FindFirstChild(childName)

		if not (button and button:IsA("GuiButton")) then
			continue
		end

		buttonsByChildName[childName] = button
		ActivateButton(button)
		local v3 = childName
		button.MouseButton1Click:Connect(function()
			SelectTab(v3) -- inferred equivalent call
		end)
	end

	local page = GetPage(frozen.Overview) -- inferred equivalent call

	if page then
		Overview.Bind(page)
		Overview.BindTab(buttonsByChildName.Overview)
	end

	local page2 = GetPage(frozen.WeaponStats) -- inferred equivalent call

	if page2 then
		WeaponStats.Bind(page2)
	end

	local page3 = GetPage(frozen.MatchHistory) -- inferred equivalent call

	if page3 then
		MatchHistory.Bind(page3)
	end

	MenuState.RegisterBumperOverride(v, function(flag: boolean)
		local nextBumperTab = MenuState.GetNextBumperTab(categories, frozen2, v2, flag)

		if nextBumperTab and v2 ~= nextBumperTab then
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			ShowTab(nextBumperTab)
		end

		local selectedObject = GuiService.SelectedObject
		local page4 = GetPage(frozen[v2]) -- inferred equivalent call
		local v3

		if selectedObject == nil then
			v3 = false
		else
			v3 = selectedObject:IsDescendantOf(categories)
		end

		local v4

		if selectedObject == nil then
			v4 = false
		else
			v4 = selectedObject:IsDescendantOf(pages)

			if v4 then
				v4 = not (page4 and selectedObject:IsDescendantOf(page4))
			end
		end

		if v3 or v4 then
			GuiService.SelectedObject = buttonsByChildName[v2]
		end

		return true
	end)
	ShowTab("Overview")
end

function Career.Start()
	CareerData.Listen()
	CareerData.Changed:Connect(Render)
	Selection.Changed:Connect(Render)
	WeaponIcon.Changed:Connect(function()
		if CareerData.IsLoaded() then
			Render() -- inferred equivalent call
		end
	end)
	MenuState.OnScreenChanged:Connect(function(_, p)
		if p == "Career" then
			ShowTab("Overview")
			CareerData.Request()
			Render() -- inferred equivalent call
		elseif v and not v.Visible then
			MatchHistory.Close()
		end
	end)

	if CareerData.IsLoaded() then
		Render() -- inferred equivalent call
	end
end

return Career