local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Base64 = require(script.Parent:WaitForChild("Base64"))
local isStudio = RunService:IsStudio()

local function debugPrint(...)
	if isStudio then
		print("[MedalClipper]", ...)
	end
end

return {
	TriggerClip = function(_, eventId: string, eventName: string, options)
		local v = options or {}
		debugPrint(
			"TriggerClip",
			`eventId={eventId}`,
			`eventName={eventName}`,
			`duration={v.duration or 30}`,
			`captureDelayMs={v.captureDelayMs or 0}`
		)
		local gameEvent = {
			eventId = eventId,
			eventName = eventName,
			triggerActions = { "SaveClip" },
			clipOptions = {
				duration = v.duration or 30,
				captureDelayMs = v.captureDelayMs
			}
		}

		if v.contextTags and next(v.contextTags) then
			gameEvent.contextTags = v.contextTags
		end

		local v2 = { gameEvent = gameEvent, universeId = game.GameId }
		print("[_MAPIEvent][v1/event/invoke]", Base64.ToBase64(HttpService:JSONEncode(v2)))
	end
}