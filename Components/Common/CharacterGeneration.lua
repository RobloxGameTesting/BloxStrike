local v = { AttributeName = "CharacterGeneration", MaxValue = 65535 }

function v.IsValid(value)
	return typeof(value) == "number" and value % 1 == 0 and value >= 1 and value <= v.MaxValue
end

function v.Get(instance)
	if instance == nil then
		return nil
	end

	local attribute = instance:GetAttribute(v.AttributeName)

	if v.IsValid(attribute) then
		return attribute
	end

	return nil
end

function v.Set(instance, p: number)
	assert(v.IsValid(p), "character generation must be a non-zero u16")
	instance:SetAttribute(v.AttributeName, p)
end

function v.Next(p: number?)
	if v.IsValid(p) and p ~= v.MaxValue then
		return p + 1
	end

	return 1
end

function v.Matches(p, p2: number)
	return v.Get(p) == p2
end

return table.freeze(v)