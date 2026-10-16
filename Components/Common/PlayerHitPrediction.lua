local v = {}

local function prune(now: number)
	while v[1] and now - v[1].CreatedAt > 1 do
		table.remove(v, 1)
	end
end

return table.freeze({
	Record = function(shotSeq: number, victimUserId: number, hitPartName: string, vector: Vector3)
		local now = os.clock()
		prune(now)

		if #v >= 64 then
			table.remove(v, 1)
		end

		v[#v + 1] = {
			ShotSeq = shotSeq,
			VictimUserId = victimUserId,
			HitPartName = hitPartName,
			Position = vector,
			CreatedAt = now
		}
	end,
	Consume = function(p: number, p2: number, p3: string, vector: Vector3)
		prune(os.clock())

		for k, v2 in v do
			if not (v2.ShotSeq == p and v2.VictimUserId == p2 and v2.HitPartName == p3 and (v2.Position - vector).Magnitude <= 6) then
				continue
			end

			table.remove(v, k)
			return true
		end

		return false
	end
})