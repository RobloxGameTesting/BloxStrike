local v = {
	MIN_LEVEL = 3,
	MINIMUM_ACTIVE_PLAYERS = 4,
	PETITION_RATIO = 0.5,
	PETITION_EXTRA_YES_VOTES = 1,
	GetActiveTeam = function(p)
		if p == "Counter-Terrorists" or p == "Terrorists" then
			return p
		end

		return nil
	end
}

function v.GetRequiredYesVotes(p: number)
	return math.ceil(p * v.PETITION_RATIO) + v.PETITION_EXTRA_YES_VOTES
end

return table.freeze(v)