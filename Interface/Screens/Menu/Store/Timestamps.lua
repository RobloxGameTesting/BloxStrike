local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FormatDuration = require(ReplicatedStorage.Components.Common.FormatDuration)
local v = {}

local function NormalizeUnixTimestamp(unixTimestamp: number) -- 1 equivalent call inferred from this helper
	if unixTimestamp > 10000000000 then
		unixTimestamp /= 1000
	end

	return (math.floor(unixTimestamp))
end

local function ParseDateTimerTimestamp(value)
	local formatted = `{typeof(value)}:{value}`
	local v2 = v[formatted]

	if v2 == nil then
		local unixTimestamp = nil

		if typeof(value) == "number" then
			unixTimestamp = value
		else
			local v3 = tonumber(value)

			if v3 then
				unixTimestamp = v3
			else
				local success, result = pcall(function()
					return DateTime.fromIsoDate(value)
				end)

				if success and result then
					unixTimestamp = result.UnixTimestamp
				end
			end
		end

		if not unixTimestamp then
			v[formatted] = false
			return nil
		end

		local unixTimestamp2 = NormalizeUnixTimestamp(unixTimestamp) -- inferred equivalent call
		v[formatted] = unixTimestamp2
		return unixTimestamp2
	elseif v2 == false then
		return nil
	else
		return v2
	end
end

return {
	NormalizeUnixTimestamp = NormalizeUnixTimestamp,
	ConvertDateToTimer = function(p, p2: number?)
		local parseDateTimerTimestamp = ParseDateTimerTimestamp(p)

		if not parseDateTimerTimestamp then
			return "00:00:00:00"
		end

		local v2 = p2 or math.floor((workspace:GetServerTimeNow()))
		return FormatDuration(parseDateTimerTimestamp - math.floor(v2), "Always")
	end
}