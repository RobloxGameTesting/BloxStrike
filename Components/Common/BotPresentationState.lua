local function integer(value, p: number)
	return type(value) == "number" and value >= 1 and value <= p and value % 1 == 0
end

return table.freeze({
	validate = function(data)
		local v

		if type(data) == "table" then
			local combatantId = data.CombatantId

			if type(combatantId) == "number" and combatantId >= 1 and combatantId <= 9007199254740991 then
				v = combatantId % 1 == 0
			else
				v = false
			end

			if v then
				local actorId = data.ActorId

				if type(actorId) == "number" and actorId >= 1 and actorId <= 4294967295 then
					v = actorId % 1 == 0
				else
					v = false
				end

				if v then
					local generation = data.Generation

					if type(generation) == "number" and generation >= 1 and generation <= 65535 then
						v = generation % 1 == 0
					else
						v = false
					end

					if v then
						if
							type(data.DisplayName) == "string"
							and type(data.Team) == "string"
							and type(data.CharacterName) == "string"
							and data.CharacterName ~= ""
							and type(data.Health) == "number"
							and data.Health >= 0
							and type(data.MaxHealth) == "number"
							and data.MaxHealth > 0
							and data.MaxHealth < 1e999
							and data.Health <= data.MaxHealth
						then
							return type(data.Dead) == "boolean"
						else
							return false
						end
					end
				end
			end
		else
			return false
		end

		return v
	end,
	sameLife = function(data, data2)
		return data.CombatantId == data2.CombatantId
			and data.ActorId == data2.ActorId
			and data.Generation == data2.Generation
	end,
	decide = function(data, data2)
		if data == nil or data.Dead or data.Health <= 0 then
			return "Destroy"
		end

		if
			data2 == nil
			or (data2.UserId ~= 0 or data2.ActorId ~= data.ActorId or data2.Generation ~= data.Generation)
		then
			return "Hide"
		end

		local renderPose = data2.RenderPose

		if renderPose == nil then
			return "Hold"
		end

		if
			renderPose.UserId == 0
			and renderPose.ActorId == data.ActorId
			and renderPose.Generation == data.Generation
		then
			return "Present"
		end

		return "Hide"
	end
})