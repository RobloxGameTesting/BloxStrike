local Config = require(script.Parent.Config)
local Serial = require(script.Parent.Serial)
local v = {
	HistorySeconds = Config.PolicySeconds.PredictionReplay + 1
}
v.MaxPoints = math.ceil(v.HistorySeconds * Config.MaxSimulationHz) + 2

function v.new(flag: boolean?)
	return {
		Revision = 0,
		Initial = flag == true,
		Points = {}
	}
end

function v.isLockedAt(p, p2: number)
	if p == nil then
		return false
	end

	local points = p.Points

	for i = #points, 1, -1 do
		local point = points[i]

		if point.ServerTime <= p2 then
			return point.Locked
		end
	end

	return p.Initial
end

function v:record(serverTime: number, locked: boolean)
	local points = self.Points
	local point = points[#points]
	local v2

	if point == nil then
		v2 = self.Initial
	else
		v2 = point.Locked
	end

	if v2 == locked then
		return false
	end

	assert(point == nil or point.ServerTime <= serverTime, "action locks must follow the authority clock")

	if point == nil or serverTime ~= point.ServerTime then
		points[#points + 1] = { ServerTime = serverTime, Locked = locked }
	else
		point.Locked = locked
	end

	local v3 = serverTime - v.HistorySeconds

	while #points > 1 and points[2].ServerTime <= v3 do
		self.Initial = assert(table.remove(points, 1)).Locked
	end

	self.Revision = Serial.addUInt32(self.Revision, 1)
	assert(#points <= v.MaxPoints, "action locks must be coalesced once per world tick")
	return true
end

function v.validate(data)
	if type(data) ~= "table" or not Serial.isUInt32(data.Revision) or type(data.Initial) ~= "boolean" then
		return false
	end

	local points = data.Points

	if type(points) ~= "table" or #points > v.MaxPoints then
		return false
	end

	local v2 = -1e999

	for _, point in points do
		if type(point) ~= "table" or type(point.Locked) ~= "boolean" then
			return false
		end

		local serverTime = point.ServerTime

		if
			type(serverTime) ~= "number"
			or serverTime ~= serverTime
			or serverTime < 0
			or serverTime >= 1e999
			or serverTime <= v2
		then
			return false
		end

		v2 = serverTime
	end

	return true
end

return table.freeze(v)