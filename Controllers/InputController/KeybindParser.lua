return {
	parse = function(value: string)
		local v = string.split(value, ".")

		if value == "" or #v ~= 3 then
			return nil
		end

		local success, result = pcall(function()
			if v[2] == "KeyCode" then
				return Enum.KeyCode[v[3]]
			end

			if v[2] == "UserInputType" then
				return Enum.UserInputType[v[3]]
			end

			if v[2] == "CustomInputType" and (v[3] == "ScrollWheelUp" or v[3] == "ScrollWheelDown") then
				return v[3]
			end

			return nil
		end)
		return success and result or nil
	end
}