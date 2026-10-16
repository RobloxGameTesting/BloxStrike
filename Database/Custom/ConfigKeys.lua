local v = {
	Shared = table.freeze({
		MissionCreditRewardMultipliers = table.freeze({
			hourly = "HourlyMissionCreditRewardMultiplier",
			daily = "DailyMissionCreditRewardMultiplier",
			weekly = "WeeklyMissionCreditRewardMultiplier",
			monthly = "MonthlyMissionCreditRewardMultiplier"
		})
	}),
	ServerOnly = table.freeze({ GameplayCreditRewardMultiplier = "GameplayCreditRewardMultiplier" }),
	Defaults = table.freeze({
		GameplayCreditRewardMultiplier = 1,
		HourlyMissionCreditRewardMultiplier = 1,
		DailyMissionCreditRewardMultiplier = 1,
		WeeklyMissionCreditRewardMultiplier = 1,
		MonthlyMissionCreditRewardMultiplier = 1
	})
}
local function collectKeys(Shared, list)
	if typeof(Shared) == "string" then
		table.insert(list, Shared)
		return
	end

	if typeof(Shared) ~= "table" then
		return
	end

	for _, item in pairs(Shared) do
		collectKeys(item, list)
	end
end

function v.GetSharedKeys()
	local v2 = {}
	collectKeys(v.Shared, v2)
	return v2
end

return table.freeze(v)