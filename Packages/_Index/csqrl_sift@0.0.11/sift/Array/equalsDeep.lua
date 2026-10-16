local parent = script.Parent.Parent
local Util = require(parent.Util)
local function compareDeep(list, list2)
	if type(list) ~= "table" or type(list2) ~= "table" then
		return list == list2
	end

	local count = #list

	if #list2 ~= count then
		return false
	end

	for i = 1, count do
		if not compareDeep(list[i], list2[i]) then
			return false
		end
	end

	return true
end

local function equalsDeep(...)
	if Util.equalObjects(...) then
		return true
	end

	local v = select("#", ...)
	local v2 = select(1, ...)

	for i = 2, v do
		if not compareDeep(v2, (select(i, ...))) then
			return false
		end
	end

	return true
end

return equalsDeep