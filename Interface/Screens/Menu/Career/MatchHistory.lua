local MatchHistory = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Types)
local Format = require(script.Parent.Format)
local MapIcon = require(script.Parent.MapIcon)
local CareerData = require(script.Parent.CareerData)
local MatchDetails = require(script.Parent.MatchDetails)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local Router = require(ReplicatedStorage.Database.Security.Router)
local frozen = table.freeze({ "Template", "ServerBrowserTemplate" })
local matchHistoryContainer = nil
local v = nil

local function SetText(clone, childName: string, text: string) -- 3 equivalent calls inferred from this helper
	local label = clone:FindFirstChild(childName)

	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

local function BindDetailsButton(clone, data)
	local function open()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		MatchDetails.Open(data)
	end

	local details = clone:FindFirstChild("Details")

	if details and details:IsA("GuiButton") then
		ActivateButton(details)
		details.MouseButton1Click:Connect(open)
		local tooltip = details:FindFirstChild("Tooltip")

		if tooltip then
			local title = tooltip:FindFirstChild("Title")
			local desc = tooltip:FindFirstChild("Desc")

			if title then
				title.Text = "MATCH DETAILS"
			end

			if desc then
				desc.Text = "Open the full scoreboard for this match."
			end
		end
	end

	local mapBackground = clone:FindFirstChild("MapBackground")
	local imageButton = mapBackground and mapBackground:FindFirstChild("ImageButton")

	if imageButton and imageButton:IsA("GuiButton") then
		imageButton.MouseButton1Click:Connect(open)
	end
end

local function CreateRow(match, layoutOrder: number)
	local clone = v:Clone()
	clone.Name = `Match_{layoutOrder}`
	clone.LayoutOrder = layoutOrder
	clone.Visible = true
	SetText(clone, "MapName", string.upper(match.Map)) -- inferred equivalent call
	SetText(clone, "Date", Format.DateTime(match.CompletedAt)) -- inferred equivalent call
	SetText(clone, "Gamemode", string.upper(match.ServerGamemode)) -- inferred equivalent call
	local score = clone:FindFirstChild("Score")

	if score then
		score.RichText = true
		score.Text = Format.MatchScore(match.Team, match.CTScore, match.TScore)
	end

	local status = clone:FindFirstChild("Status")

	if status then
		MatchDetails.ApplyStatus(status, match.Result)
	end

	local mapBackground = clone:FindFirstChild("MapBackground")
	local imageButton = mapBackground and mapBackground:FindFirstChild("ImageButton")

	if imageButton and imageButton:IsA("ImageButton") then
		imageButton.Image = MapIcon.Get(match.Map)
	end

	BindDetailsButton(clone, match)
	clone.Parent = matchHistoryContainer
end

local function ClearRows()
	for _, frame in ipairs(matchHistoryContainer:GetChildren()) do
		if not (frame:IsA("Frame") and string.sub(frame.Name, 1, 6) == "Match_") then
			continue
		end

		frame:Destroy()
	end
end

function MatchHistory.Bind(instance)
	local history = instance:FindFirstChild("History")
	local historyMain = history and history:FindFirstChild("Main")
	local matchHistory = historyMain and historyMain:FindFirstChild("MatchHistory")
	matchHistoryContainer = matchHistory and matchHistory:FindFirstChild("Container")

	if not matchHistoryContainer then
		return
	end

	if matchHistory and matchHistory:IsA("GuiObject") then
		matchHistory.Visible = true
	end

	for _, frame in ipairs(matchHistoryContainer:GetChildren()) do
		if not (frame:IsA("Frame") and table.find(frozen, frame.Name) ~= nil) then
			continue
		end

		if v then
			frame:Destroy()
		else
			v = frame
			v.Visible = false
		end
	end

	MatchDetails.Bind(instance)
end

function MatchHistory.Render()
	local v2 = CareerData.Get()

	if not (matchHistoryContainer and v and v2) then
		return
	end

	ClearRows()

	for i, match in ipairs(v2.Matches) do
		CreateRow(match, i)
	end

	local empty = matchHistoryContainer:FindFirstChild("Empty")

	if empty and empty:IsA("GuiObject") then
		empty.Visible = #v2.Matches == 0
	end
end

function MatchHistory.Close()
	MatchDetails.Close()
end

return MatchHistory