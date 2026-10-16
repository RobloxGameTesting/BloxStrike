local DiagnosticProtocol = require(script.Parent.Parent.DiagnosticProtocol)
local class = {}
class.__index = class

local function splitLine(value: string)
	if value == "" then
		return { "" }
	end

	local result = {}
	local v = 1

	if pcall(function()
		for k in utf8.codes(value) do
			if not (k - v >= 512) then
				continue
			end

			result[#result + 1] = string.sub(value, v, k - 1)
			v = k
		end
	end) then
		result[#result + 1] = string.sub(value, v)
		return result
	end

	table.clear(result)

	for i = 1, #value, 512 do
		result[#result + 1] = string.sub(value, i, i + 512 - 1)
	end

	return result
end

local function appendDetailRecords(list, correlationId: string, p: string, value: string)
	local v = string.split(value, "\n")
	local v2 = #v

	for k, v3 in v do
		if string.sub(v3, -1) == "\r" then
			v3 = string.sub(v3, 1, -2)
		end

		local v4 = splitLine(v3)
		local v5 = #v4

		for k2, v6 in v4 do
			list[#list + 1] = string.format(
				"[MovementV2.DiagnosticDetail] incident=%s section=%s line=%d/%d part=%d/%d data=%s",
				correlationId,
				p,
				k,
				v2,
				k2,
				v5,
				v6
			)
		end
	end
end

local function advanceQueueHead(list, p: number, p2: number)
	local v = p + 1

	if #list < v then
		table.clear(list)
		return list, 1
	end

	if not (p2 <= v) then
		return list, v
	end

	local result = {}

	for i = v, #list do
		result[#result + 1] = list[i]
	end

	return result, 1
end

function class.new()
	return (setmetatable({
		_deliveries = {},
		_deliveryHead = 1,
		_deliveriesDropped = 0,
		_records = {},
		_recordHead = 1,
		_nextOutputAt = 0
	}, class))
end

function class:clear()
	table.clear(self._deliveries)
	self._deliveryHead = 1
	self._deliveriesDropped = 0
	table.clear(self._records)
	self._recordHead = 1
	self._nextOutputAt = 0
end

function class:queue(p)
	local deliveries = self._deliveries

	if #deliveries - self._deliveryHead + 1 >= 128 then
		self._deliveriesDropped += 1
	else
		deliveries[#deliveries + 1] = p
	end
end

function class:_stage(data)
	local v = {}
	appendDetailRecords(v, data.CorrelationId, "CLIENT", data.ClientLog)
	appendDetailRecords(v, data.CorrelationId, "SERVER", data.ServerLog)
	local records = self._records
	local v2 = 2048 - math.max(#records - self._recordHead + 1, 0)
	local v3 = math.min(#v, (math.max(v2 - 1, 0)))

	if v2 > 0 then
		records[#records + 1] = string.format(
			"[MovementV2.Diagnostic] incident=%s kind=%s reporter=%s display=%s userId=%d receivedServerTime=%.6f detailRecords=%d queued=%d dropped=%d deliveryQueueDropped=%d",
			data.CorrelationId,
			data.Kind,
			data.ReporterName,
			data.ReporterDisplayName,
			data.ReporterUserId,
			data.ReceivedServerTime,
			#v,
			v3,
			#v - v3,
			self._deliveriesDropped
		)
		self._deliveriesDropped = 0
	end

	for i = 1, v3 do
		records[#records + 1] = v[i]
	end
end

function class:drain()
	if #self._records - self._recordHead + 1 < 1536 then
		local deliveries = self._deliveries
		local delivery = deliveries[self._deliveryHead]

		if delivery ~= nil then
			self:_stage(delivery)
			local deliveries2, deliveryHead = advanceQueueHead(deliveries, self._deliveryHead, 64)
			self._deliveries = deliveries2
			self._deliveryHead = deliveryHead
		end
	end

	local now = os.clock()

	if now < self._nextOutputAt then
		return
	end

	local records = self._records
	local recordHead = self._recordHead
	local record = records[recordHead]

	if record == nil then
		return
	end

	DiagnosticProtocol.output(record)
	self._nextOutputAt = now + 1 / 30
	local records2, recordHead2 = advanceQueueHead(records, recordHead, 128)
	self._records = records2
	self._recordHead = recordHead2
end

return table.freeze(class)