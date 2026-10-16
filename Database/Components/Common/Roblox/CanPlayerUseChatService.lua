local TextChatService = game:GetService("TextChatService")
return function(p)
	local success, result = pcall(function()
		return TextChatService:CanUserChatAsync(p.UserId)
	end)

	if success then
		return result
	end

	warn("[CanUserUseChat] Failed to check if user can use chat", result)
	return false
end