local v = { Attribute = "MovementHullPoints", MinPoints = 4, MaxPoints = 256 }
local v2 = {}

local function isFinite(p: number?) -- 3 equivalent calls inferred from this helper
	return p ~= nil and p == p and p > -1e999 and p < 1e999
end

function v.Decode(value)
	if typeof(value) ~= "string" then
		return nil, "hull points must be a string"
	end

	local v3 = v2[value]

	if v3 ~= nil then
		return v3, nil
	end

	local vectors = {}

	for _, v4 in string.split(value, ";") do
		local v5 = string.split(v4, ",")
		local v6 = tonumber(v5[1])
		local v7 = tonumber(v5[2])
		local v8 = tonumber(v5[3])

		if #v5 ~= 3 then
			return nil, "hull points must be finite x,y,z triples"
		end

		if isFinite(v6) and isFinite(v7) and isFinite(v8) then -- inferred equivalent call
			vectors[#vectors + 1] = Vector3.new(v6, v7, v8)
			continue
		end

		return nil, "hull points must be finite x,y,z triples"
	end

	if #vectors < v.MinPoints or #vectors > v.MaxPoints then
		return nil, string.format("hull points need %d-%d points", v.MinPoints, v.MaxPoints)
	end

	table.freeze(vectors)
	v2[value] = vectors
	return vectors, nil
end

function v.Read(instance)
	local attribute = instance:GetAttribute(v.Attribute)

	if attribute == nil then
		return nil
	end

	return (v.Decode(attribute))
end

return table.freeze(v)