local Report = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local LocalPlayer = Players.LocalPlayer
local v = nil
local textLabel = nil
local v2 = nil
local v3 = nil
local v4 = {}
local flag = false
local v5 = {}

local function getReasonOption(p: string) -- 3 equivalent calls inferred from this helper
	for _, v6 in v4 do
		if v6.name == p then
			return v6
		end
	end

	return nil
end

local function setReasonChecked(p, visible: boolean) -- 3 equivalent calls inferred from this helper
	if p.icon then
		p.icon.Visible = visible
	end
end

local function clearOtherText() -- 2 equivalent calls inferred from this helper
	local reasonOption = getReasonOption("Other") -- inferred equivalent call

	if reasonOption and reasonOption.textBox then
		flag = true
		reasonOption.textBox.Text = ""
		flag = false
	end
end

local function clearSelection() -- 3 equivalent calls inferred from this helper
	v3 = nil

	for _, v6 in v4 do
		setReasonChecked(v6, false) -- inferred equivalent call
	end

	clearOtherText() -- inferred equivalent call
end

local function selectReason(p: string) -- 1 equivalent call inferred from this helper
	v3 = p

	for _, v6 in v4 do
		setReasonChecked(v6, v6.name == p) -- inferred equivalent call
	end

	if p ~= "Other" then
		clearOtherText() -- inferred equivalent call
	end
end

local function toggleReason(name: string) -- 1 equivalent call inferred from this helper
	if v3 == name then
		clearSelection() -- inferred equivalent call
	else
		selectReason(name) -- inferred equivalent call
	end
end

local function onOtherTextChanged(text: string)
	if flag then
		return
	end

	local v6 = utf8.len(text)

	if v6 and v6 > 100 then
		local v7 = utf8.offset(text, 101)
		local reasonOption = getReasonOption("Other") -- inferred equivalent call

		if v7 and reasonOption and reasonOption.textBox then
			text = string.sub(text, 1, v7 - 1)
			flag = true
			reasonOption.textBox.Text = text
			flag = false
		end
	end

	if text == "" then
		if v3 == "Other" then
			v3 = nil
		end
	else
		v3 = "Other"

		for _, v7 in v4 do
			if v7.name ~= "Other" and v7.icon then
				v7.icon.Visible = false
			end
		end
	end
end

local function bindReasonOption(frame)
	local name = frame.Name

	if name ~= "Toxicity" and name ~= "Bot" and name ~= "Cheating" and name ~= "Other" then
		return
	end

	local check = frame:FindFirstChild("Check")

	if not (check and check:IsA("ImageButton")) then
		return
	end

	local icon = check:FindFirstChild("Icon")
	local textBox = check:FindFirstChild("TextBox")
	local v6 = { name = name, checkButton = check, icon = 0, textBox = 0 }

	if not (icon and icon:IsA("ImageLabel")) then
		icon = nil
	end

	v6.icon = icon

	if not (textBox and textBox:IsA("TextBox")) then
		textBox = nil
	end

	v6.textBox = textBox
	setReasonChecked(v6, false) -- inferred equivalent call
	ActivateButton(check)

	if name == "Other" then
		check.MouseButton1Click:Connect(function()
			if v6.textBox then
				v6.textBox:CaptureFocus()
			end
		end)

		if v6.textBox then
			v6.textBox.ClearTextOnFocus = false
			v6.textBox.MultiLine = false
			v6.textBox.TextWrapped = false
			v6.textBox.TextXAlignment = Enum.TextXAlignment.Left
			v6.textBox.ClipsDescendants = true
			check.ClipsDescendants = true
			v6.textBox:GetPropertyChangedSignal("Text"):Connect(function()
				onOtherTextChanged(v6.textBox.Text)
			end)
		end
	else
		check.MouseButton1Click:Connect(function()
			toggleReason(name) -- inferred equivalent call
		end)
	end

	table.insert(v4, v6)
end

function Report.Close()
	if v then
		v.Visible = false
	end

	v2 = nil
	clearSelection() -- inferred equivalent call
	CameraController.setForceLockOverride("Report", false)
end

function Report.Open(p)
	if p == LocalPlayer then
		return
	end

	v2 = p
	clearSelection() -- inferred equivalent call

	if textLabel then
		textLabel.Text = `Reporting {p.Name}`
	end

	if v then
		v.Visible = true
	end

	CameraController.setForceLockOverride("Report", true)
end

function Report.Submit()
	local reportedPlayer = v2
	local reason = v3

	if not reportedPlayer or reportedPlayer == LocalPlayer or not reason then
		Report.Close()
		return
	end

	if v5[reportedPlayer.UserId] then
		Report.Close()
		return
	end

	v5[reportedPlayer.UserId] = true
	local detail

	if reason == "Other" then
		detail = Report.GetOtherReasonText()
	end

	Remotes.Player.SubmitPlayerReport.Send({
		ReportedPlayer = reportedPlayer,
		Reason = reason,
		Detail = detail
	})
	Report.Close()
end

function Report.GetOtherReasonText()
	local reasonOption = getReasonOption("Other") -- inferred equivalent call

	if reasonOption and reasonOption.textBox then
		return reasonOption.textBox.Text
	end

	return ""
end

function Report.Initialize(_, instance)
	v = instance
	v.Visible = false
	local main = instance:FindFirstChild("Main")
	local top = main and main:FindFirstChild("Top")
	local reason = main and main:FindFirstChild("Reason")
	local options = main and main:FindFirstChild("Options")
	textLabel = top and top:FindFirstChild("TextLabel")
	v4 = {}

	if reason then
		for _, frame in reason:GetChildren() do
			if frame:IsA("Frame") then
				bindReasonOption(frame)
			end
		end
	end

	if options then
		local close = options:FindFirstChild("Close")

		if close and close:IsA("ImageButton") then
			ActivateButton(close)
			close.MouseButton1Click:Connect(Report.Close)
		end

		local report = options:FindFirstChild("Report")

		if report and report:IsA("ImageButton") then
			ActivateButton(report)
			report.MouseButton1Click:Connect(Report.Submit)
		end
	end
end

return Report