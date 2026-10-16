local Halftime = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script:WaitForChild("Types"))
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local v = nil
local count = 0

local function hideHalftime() -- 4 equivalent calls inferred from this helper
	count += 1
	v.Visible = false
end

local function normalizeTeam(p: string) -- 1 equivalent call inferred from this helper
	if p == "Counter-Terrorists" or p == "CT" then
		return "Counter-Terrorists"
	end

	if p == "Terrorists" or p == "T" then
		return "Terrorists"
	end

	return nil
end

local function getHeader() -- 1 equivalent call inferred from this helper
	local title = v and v:FindFirstChild("Title")
	return title and title:FindFirstChild("Header")
end

local function getContextLabel(header) -- 1 equivalent call inferred from this helper
	local context = header:FindFirstChild("Context")

	if context and context:IsA("TextLabel") then
		return context
	end

	return nil
end

local function updateHeaderTeamVisibility(header, team: string)
	local visible2 = team == "Counter-Terrorists"
	local visible3 = not visible2
	local v2 = false

	local function setVisibleIfGuiObject(childName: string, visible: boolean) -- 4 equivalent calls inferred from this helper
		local guiObject = header:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") then
			guiObject.Visible = visible
			v2 = true
		end
	end

	setVisibleIfGuiObject("CT", visible2) -- inferred equivalent call
	setVisibleIfGuiObject("T", visible3) -- inferred equivalent call
	setVisibleIfGuiObject("PlayingCT", visible2) -- inferred equivalent call
	setVisibleIfGuiObject("PlayingT", visible3) -- inferred equivalent call
	return v2
end

local function showHalftime(p: string, p2: number?)
	local team = normalizeTeam(p) -- inferred equivalent call

	if team then
		local text = "Playing as " .. team
		local header = getHeader() -- inferred equivalent call

		if header then
			local contextLabel = getContextLabel(header) -- inferred equivalent call

			if updateHeaderTeamVisibility(header, team) or contextLabel then
				if contextLabel then
					contextLabel.Text = text
				end

				count += 1
				local v2 = count
				v.Visible = true

				if p2 ~= nil then
					local v3 = math.max(tonumber(p2) or 0, 0)
					task.delay(v3, function()
						if v2 ~= count then
							return
						end

						v.Visible = false
					end)
				end

				return true
			else
				warn("[Halftime] Missing Title.Header CT/T + PlayingCT/PlayingT visuals and Context TextLabel")
				hideHalftime() -- inferred equivalent call
				return false
			end
		else
			warn("[Halftime] Missing Title.Header")
			hideHalftime() -- inferred equivalent call
			return false
		end
	else
		warn(("[Halftime] Unsupported NextTeam value: %s"):format((tostring(p))))
		hideHalftime() -- inferred equivalent call
		return false
	end
end

function Halftime.Show(p: string, p2: number?)
	if v then
		return (showHalftime(p, p2))
	end

	warn("[Halftime] Frame is not initialized")
	return false
end

function Halftime.Hide()
	if not v then
		return
	end

	hideHalftime() -- inferred equivalent call
end

function Halftime.Initialize(_, p)
	v = p
	v.Visible = false
	GameState.ListenToState(function(_, p2)
		if p2 == "Buy Period" or p2 == "Round In Progress" then
			count += 1
			v.Visible = false
		end
	end)
end

return Halftime