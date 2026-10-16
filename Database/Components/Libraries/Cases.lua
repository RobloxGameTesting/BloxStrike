local Cases = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
require(ReplicatedStorage.Database.Custom.Types)
local RemoveFromArray = require(ReplicatedStorage.Database.Components.Common.RemoveFromArray)
local Signal = require(ReplicatedStorage.Packages.Signal)
local onCasesUpdated = Signal.new()
Cases.OnCasesUpdated = onCasesUpdated
local isStudio = RunService:IsStudio()
local v = {}
local v2 = {}
local count = 0

local function ParseUnixTimestamp(p) -- 6 equivalent calls inferred from this helper
	if p == nil then
		return nil
	end

	local v3 = tonumber(p)

	if not v3 then
		local dateTime = DateTime.fromIsoDate(p)
		return dateTime and dateTime.UnixTimestamp
	end

	if v3 > 10000000000 then
		return (math.floor(v3 / 1000))
	end

	return (math.floor(v3))
end

local function GetCurrentUnixTimestamp() -- 3 equivalent calls inferred from this helper
	return (math.floor((Workspace:GetServerTimeNow())))
end

local function GetNextCaseBoundaryTimestamp()
	local currentUnixTimestamp = GetCurrentUnixTimestamp() -- inferred equivalent call
	local v3 = nil

	for _, v4 in ipairs(v) do
		local parseUnixTimestamp = ParseUnixTimestamp(v4.releaseDate) -- inferred equivalent call

		if
			parseUnixTimestamp
			and currentUnixTimestamp < parseUnixTimestamp
			and (v3 == nil or parseUnixTimestamp < v3)
		then
			v3 = parseUnixTimestamp
		end

		local parseUnixTimestamp2 = ParseUnixTimestamp(v4.discontinueDate) -- inferred equivalent call

		if
			parseUnixTimestamp2
			and currentUnixTimestamp < parseUnixTimestamp2
			and (v3 == nil or parseUnixTimestamp2 < v3)
		then
			v3 = parseUnixTimestamp2
		end
	end

	return v3
end

local function ScheduleCasesUpdateAtNextBoundary()
	if isStudio then
		return
	end

	count += 1
	local v3 = count
	local currentUnixTimestamp = GetCurrentUnixTimestamp() -- inferred equivalent call
	local nextCaseBoundaryTimestamp = GetNextCaseBoundaryTimestamp()

	if not nextCaseBoundaryTimestamp then
		return
	end

	local v4 = math.max(nextCaseBoundaryTimestamp - currentUnixTimestamp, 0)
	task.delay(v4, function()
		if v3 ~= count then
			return
		end

		if #onCasesUpdated:GetConnections() > 0 then
			onCasesUpdated:Fire(v)
		end

		ScheduleCasesUpdateAtNextBoundary()
	end)
end

local function IsCaseEnabled(data, flag: boolean?)
	local currentUnixTimestamp = GetCurrentUnixTimestamp() -- inferred equivalent call

	if isStudio and not flag then
		return true
	end

	if data.status == "inactive" or data.status == "discontinued" or not data.isEnabled then
		return false
	end

	local releaseDate = data.releaseDate

	if releaseDate then
		releaseDate = ParseUnixTimestamp(data.releaseDate) -- inferred equivalent call
	end

	if releaseDate and currentUnixTimestamp < releaseDate then
		return false
	end

	local discontinueDate = data.discontinueDate

	if discontinueDate then
		discontinueDate = ParseUnixTimestamp(data.discontinueDate) -- inferred equivalent call
	end

	return not (discontinueDate and discontinueDate <= currentUnixTimestamp)
end

local v3 = { ["Charm Capsule"] = true, Package = true, Console = true }

local function HasCaseModel(p)
	if v3[p.caseType] then
		return true
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local caseModels = assets and assets:FindFirstChild("CaseModels")
	return caseModels ~= nil and caseModels:FindFirstChild(p.name) ~= nil
end

local function SortByDisplayOrder(p, p2)
	if p.displayOrder == p2.displayOrder then
		return (v2[p] or 0) < (v2[p2] or 0)
	end

	return p.displayOrder < p2.displayOrder
end

local function UpdateAvailableCases(avaiableCases)
	v = HttpService:JSONDecode(avaiableCases)
	v2 = {}

	for i, v4 in ipairs(v) do
		v2[v4] = i
	end

	ScheduleCasesUpdateAtNextBoundary()

	if #onCasesUpdated:GetConnections() > 0 then
		onCasesUpdated:Fire(v)
	end
end

function Cases.GetCreationTimestamp(p)
	local unixTimestamp = ParseUnixTimestamp(p.createdAt) -- inferred equivalent call

	if unixTimestamp then
		return unixTimestamp
	end

	local releaseDate = p.releaseDate

	if releaseDate == nil then
		return nil
	end

	local v4 = tonumber(releaseDate)

	if v4 then
		if v4 > 10000000000 then
			return (math.floor(v4 / 1000))
		end

		return (math.floor(v4))
	else
		local dateTime = DateTime.fromIsoDate(releaseDate)
		unixTimestamp = dateTime and dateTime.UnixTimestamp
		return unixTimestamp
	end
end

function Cases.IsLimited(p)
	return ParseUnixTimestamp(p.discontinueDate) ~= nil -- inferred equivalent call
end

function Cases.GetBackendOrder(p)
	return v2[p] or 1e999
end

function Cases.IsCaseEnabled(p: string)
	local case = Cases.GetCase(p)
	return case ~= nil and IsCaseEnabled(case)
end

function Cases.IsCaseForSale(p: string)
	local case = Cases.GetCase(p)
	return case ~= nil and IsCaseEnabled(case, true)
end

function Cases.HasCaseModel(p: string)
	local case = Cases.GetCase(p)
	local _

	if case == nil then
		_ = false
		return false
	end

	if v3[case.caseType] then
		return true
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local caseModels = assets and assets:FindFirstChild("CaseModels")
	return caseModels ~= nil and caseModels:FindFirstChild(case.name) ~= nil
end

function Cases.GetCaseByName(p: string)
	if not v then
		return nil
	end

	for _, v4 in ipairs(v) do
		if v4.name == p then
			return v4
		end
	end

	return nil
end

function Cases.GetCase(p: string)
	if not v then
		return nil
	end

	for _, v4 in ipairs(v) do
		if v4.caseId == p then
			return v4
		end
	end

	return nil
end

function Cases.GetFeaturedCases(p: number)
	local result = {}

	for _, v4 in ipairs(v) do
		if not (v4.isFeatured and IsCaseEnabled(v4)) then
			continue
		end

		local v5

		if v3[v4.caseType] then
			v5 = true
		else
			local assets = ReplicatedStorage:FindFirstChild("Assets")
			local caseModels = assets and assets:FindFirstChild("CaseModels")

			if caseModels == nil then
				v5 = false
			else
				v5 = caseModels:FindFirstChild(v4.name) ~= nil
			end
		end

		if v5 then
			table.insert(result, v4)
		end
	end

	table.sort(result, SortByDisplayOrder)
	RemoveFromArray(result, function(p2, _)
		return p < p2
	end)
	return result
end

function Cases.GetCases()
	local result = {}

	for _, v4 in ipairs(v) do
		if not IsCaseEnabled(v4) then
			continue
		end

		local v5

		if v3[v4.caseType] then
			v5 = true
		else
			local assets = ReplicatedStorage:FindFirstChild("Assets")
			local caseModels = assets and assets:FindFirstChild("CaseModels")

			if caseModels == nil then
				v5 = false
			else
				v5 = caseModels:FindFirstChild(v4.name) ~= nil
			end
		end

		if v5 then
			table.insert(result, v4)
		end
	end

	table.sort(result, SortByDisplayOrder)
	return result
end

function Cases.ObserveAvailableCases(callback)
	local connection = onCasesUpdated:Connect(callback)

	if v then
		callback(v)
	end

	return function()
		connection:Disconnect()
	end
end

local function SyncAvailableCases() -- 1 equivalent call inferred from this helper
	local avaiableCases = ReplicatedStorage:GetAttribute("AvaiableCases")

	if avaiableCases then
		UpdateAvailableCases(avaiableCases)
	end
end

SyncAvailableCases() -- inferred equivalent call
ReplicatedStorage:GetAttributeChangedSignal("AvaiableCases"):Connect(SyncAvailableCases)
return Cases