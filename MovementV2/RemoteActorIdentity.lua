return table.freeze({
	key = function(p)
		if p.UserId == 0 then
			return `bot:{p.ActorId}`
		end

		return p.UserId
	end,
	keyLess = function(value, value2)
		if type(value) == "number" then
			return type(value2) ~= "number" or value < value2
		else
			return type(value2) ~= "number" and value < value2
		end
	end,
	wireLess = function(p, p2)
		if p.UserId == 0 and p2.UserId == 0 then
			return p.ActorId < p2.ActorId
		end

		return p.UserId < p2.UserId
	end
})