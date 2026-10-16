local enums = {}
local Enum2 = {
	enums = enums,
	createEnum = function(value, items)
		assert(typeof(value) == "string", "bad argument #1 - enums must be created using a string name!")
		assert(typeof(items) == "table", "bad argument #2 - enums must be created using a table!")
		assert(not enums[value], ("enum '%s' already exists!"):format(value))
		local v = {}
		local v2 = {}
		local v3 = {}
		local v4 = {
			getName = function(p)
				local v4 = tostring(p)
				local v5 = v2[v4] or v3[v4]

				if v5 then
					return items[v5][1]
				end
			end,
			getValue = function(p)
				local v4 = tostring(p)
				local v5 = v[v4] or v3[v4]

				if v5 then
					return items[v5][2]
				end
			end,
			getProperty = function(p)
				local v4 = tostring(p)
				local v5 = v[v4] or v2[v4]

				if v5 then
					return items[v5][3]
				end
			end
		}
		local result = {}

		for k, item in pairs(items) do
			assert(
				typeof(item) == "table",
				("bad argument #2.%s - details must only be comprised of tables!"):format(k)
			)
			local v5 = item[1]
			assert(typeof(v5) == "string", ("bad argument #2.%s.1 - detail name must be a string!"):format(k))
			assert(typeof(not v[v5]), ("bad argument #2.%s.1 - the detail name '%s' already exists!"):format(k, v5))
			assert(typeof(not v4[v5]), ("bad argument #2.%s.1 - that name is reserved."):format(k, v5))
			v[tostring(v5)] = k
			local v6 = item[2]
			local v7 = tostring(v6)
			assert(typeof(not v2[v7]), ("bad argument #2.%s.2 - the detail value '%s' already exists!"):format(k, v7))
			v2[v7] = k
			local v8 = item[3]

			if v8 then
				assert(
					typeof(not v3[v8]),
					("bad argument #2.%s.3 - the detail property '%s' already exists!"):format(k, (tostring(v8)))
				)
				v3[tostring(v8)] = k
			end

			result[v5] = v6
			setmetatable(result, {
				__index = function(_, p)
					return v4[p]
				end
			})
		end

		enums[value] = result
		return result
	end,
	getEnums = function()
		return enums
	end
}
local createEnum = Enum2.createEnum

for _, moduleScript in pairs(script:GetChildren()) do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end

	local module = require(moduleScript)
	createEnum(moduleScript.Name, module)
end

return Enum2