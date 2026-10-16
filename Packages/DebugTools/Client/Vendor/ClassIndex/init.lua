local generatedapidump = require(script["generated-api-dump"])
local spritesheetdata = require(script["spritesheet-data"])
local v = { Public = {}, Private = {} }
v.Private.SpritesheetClassMap = {}

function v.Public.FetchApiDump()
	return generatedapidump
end

function v.Public.FetchAllClasses()
	local result = {}

	for k in generatedapidump.Classes do
		table.insert(result, k)
	end

	return result
end

function v.Public.IsClassRegistered(p: string)
	if generatedapidump.Classes[p] then
		return true
	end

	return false
end

function v.Public.FetchClassMembers(p: string, value: string?, flag: boolean?)
	local v2 = value or "None"
	local result = {}

	for k, member in generatedapidump.Classes[p].Members do
		if not (not member.Tags.NotScriptable or flag) then
			continue
		end

		if type(member.Security) == "string" then
			if member.Security ~= v2 then
				continue
			end
		elseif member.Security.Read ~= v2 then
			continue
		end

		table.insert(result, k)
	end

	return result
end

function v.Public.FetchClassIcon(p: string)
	local v2 = spritesheetdata.Content[p] or spritesheetdata.Content.File
	return {
		Image = "http://www.roblox.com/asset/?id=16231724441",
		ImageRectOffset = Vector2.new(v2.x, v2.y),
		ImageRectSize = Vector2.new(v2.w, v2.h)
	}
end

function v.Public.FetchClassMemberType(p: string, p2: string)
	return generatedapidump.Classes[p].Members[p2].MemberType
end

function v.Public.FetchClassMemberTags(p: string, p2: string)
	local tags = {}

	for k, tag in generatedapidump.Classes[p].Members[p2].Tags do
		tags[k] = tag
	end

	return tags
end

function v.Public.FetchClassMemberSecurity(p: string, p2: string)
	local member = generatedapidump.Classes[p].Members[p2]
	local result = {}

	if type(member.Security) == "table" then
		for k, v2 in member.Security do
			result[k] = v2
		end
	else
		result.Read = member.Security
		result.Write = member.Security
	end

	return result
end

function v.Public.FetchClassMemberThreadSafety(p: string, p2: string)
	return generatedapidump.Classes[p].Members[p2].ThreadSafety
end

function v.Public.FetchClassSuperclass(p: string)
	return generatedapidump.Classes[p].Superclass
end

function v.Public.FetchClassSuperclasses(p: string)
	local class = generatedapidump.Classes[p]
	local superclasses = {}

	while class do
		table.insert(superclasses, class.Superclass)
		class = generatedapidump.Classes[class.Superclass]
	end

	return superclasses
end

return v.Public