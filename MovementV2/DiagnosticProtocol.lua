local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local v = {
	Version = 1,
	TargetName = "MaloniPepperoni",
	MaxClientLogBytes = 12000,
	MaxServerLogBytes = 12000,
	ClientOutputEnabled = false,
	StudioOutputForAllClients = false,
	OwnerTraceEnabled = false,
	DeterminismTraceEnabled = false,
	VerboseGroundTraceEnabled = false,
	AirStrafeTraceEnabled = false,
	PlayerContactOutputEnabled = false
}

function v.shouldOutputForPlayer(p)
	local clientOutputEnabled = v.ClientOutputEnabled

	if clientOutputEnabled then
		if p == nil then
			clientOutputEnabled = false
		else
			clientOutputEnabled = RunService:IsStudio() and v.StudioOutputForAllClients or p.Name == v.TargetName
		end
	end

	return clientOutputEnabled
end

function v.shouldReport(p)
	if not v.ClientOutputEnabled then
		return false
	end

	if v.shouldOutputForPlayer(p) then
		return true
	end

	local player = Players:FindFirstChild(v.TargetName)
	return player ~= nil and player:IsA("Player")
end

function v.output(p: string)
	if v.shouldOutputForPlayer(Players.LocalPlayer) then
		print(p)
	end
end

function v.outputWarning(p: string)
	if v.shouldOutputForPlayer(Players.LocalPlayer) then
		warn(p)
	end
end

local frozen = table.freeze({
	OwnerCorrection = true,
	Reconciliation = true,
	TraceComparison = true,
	PredictionHitch = true,
	RuntimeWarning = true,
	NetcodeSummary = true
})

local function isFiniteNumber(value) -- 3 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function isUInt32(value)
	return typeof(value) == "number" and value % 1 == 0 and value >= 0 and value <= 4294967295
end

local function isOptionalUInt32(value) -- 5 equivalent calls inferred from this helper
	if value == nil then
		return true
	elseif typeof(value) == "number" and value % 1 == 0 and value >= 0 then
		return value <= 4294967295
	else
		return false
	end
end

local function validLog(value, p: number) -- 3 equivalent calls inferred from this helper
	return typeof(value) == "string" and #value > 0 and #value <= p and string.find(value, "\0", 1, true) == nil
end

function v.isKind(value)
	return typeof(value) == "string" and frozen[value] == true
end

function v.decodeClientReport(data)
	if typeof(data) ~= "table" or (data.Version ~= v.Version or not v.isKind(data.Kind)) then
		return nil
	end

	if not isOptionalUInt32(data.Generation) then -- inferred equivalent call
		return nil
	end

	if
		isOptionalUInt32(data.ActorId) -- inferred equivalent call
		and isOptionalUInt32(data.Sequence) -- inferred equivalent call
		and isOptionalUInt32(data.CommandNumber) -- inferred equivalent call
		and isOptionalUInt32(data.ServerTick) -- inferred equivalent call
		and isFiniteNumber(data.ClientServerTime) -- inferred equivalent call
		and validLog(data.ClientLog, v.MaxClientLogBytes) -- inferred equivalent call
	then
		return (table.freeze({
			Version = v.Version,
			Kind = data.Kind,
			Generation = data.Generation,
			ActorId = data.ActorId,
			Sequence = data.Sequence,
			CommandNumber = data.CommandNumber,
			ServerTick = data.ServerTick,
			ClientServerTime = data.ClientServerTime,
			ClientLog = data.ClientLog
		}))
	end

	return nil
end

function v.decodeDelivery(data)
	if typeof(data) ~= "table" or (data.Version ~= v.Version or not v.isKind(data.Kind)) then
		return nil
	end

	if
		type(data.CorrelationId) ~= "string"
		or #data.CorrelationId == 0
		or #data.CorrelationId > 160
		or type(data.ReporterName) ~= "string"
		or #data.ReporterName == 0
		or #data.ReporterName > 20
		or type(data.ReporterDisplayName) ~= "string"
		or #data.ReporterDisplayName == 0
		or #data.ReporterDisplayName > 50
	then
		return nil
	end

	if
		isFiniteNumber(data.ReporterUserId) -- inferred equivalent call
		and isFiniteNumber(data.ReceivedServerTime) -- inferred equivalent call
		and validLog(data.ClientLog, v.MaxClientLogBytes) -- inferred equivalent call
		and validLog(data.ServerLog, v.MaxServerLogBytes) -- inferred equivalent call
	then
		return (table.freeze({
			Version = v.Version,
			CorrelationId = data.CorrelationId,
			Kind = data.Kind,
			ReporterName = data.ReporterName,
			ReporterDisplayName = data.ReporterDisplayName,
			ReporterUserId = data.ReporterUserId,
			ReceivedServerTime = data.ReceivedServerTime,
			ClientLog = data.ClientLog,
			ServerLog = data.ServerLog
		}))
	end

	return nil
end

return table.freeze(v)