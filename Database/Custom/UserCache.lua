local UserService = game:GetService("UserService")
local v = utf8.char(57344)
local v2 = {}
return {
	Fetch = function(p: number)
		local v3 = v2[p]

		if v3 then
			return v3
		end

		local success, userInfosByUserIdsAsync = pcall(UserService.GetUserInfosByUserIdsAsync, UserService, { p })
		local v4

		if success and typeof(userInfosByUserIdsAsync) == "table" then
			v4 = userInfosByUserIdsAsync[1]
		end

		local v5

		if v4 then
			local hasVerifiedBadge = v4.HasVerifiedBadge == true
			v5 = { Username = v4.Username, DisplayName = 0, HasVerifiedBadge = 0 }
			local displayName

			if hasVerifiedBadge then
				displayName = `{v4.DisplayName} {v}`
			else
				displayName = v4.DisplayName
			end

			v5.DisplayName = displayName
			v5.HasVerifiedBadge = hasVerifiedBadge
		else
			v5 = {
				Username = "Unknown User",
				DisplayName = "Unknown User",
				HasVerifiedBadge = false
			}
		end

		v2[p] = v5
		return v5
	end
}