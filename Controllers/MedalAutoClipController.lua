local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MedalClipper = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MedalClipper"))
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local isStudio = RunService:IsStudio()

local function triggerMedalClip(data)
	if isStudio then
		print(
			"[MedalAutoClipController]",
			"Received clip request",
			`eventId={data.EventId}`,
			`eventName={data.EventName}`,
			`duration={data.Duration}`,
			`captureDelayMs={data.CaptureDelayMs or 0}`
		)
	end

	local success, result = pcall(MedalClipper.TriggerClip, MedalClipper, data.EventId, data.EventName, {
		duration = data.Duration,
		captureDelayMs = data.CaptureDelayMs,
		contextTags = data.ContextTags
	})

	if not success then
		warn(`[MedalAutoClipController] Failed to trigger Medal clip: {result}`)
	elseif isStudio then
		print("[MedalAutoClipController]", "Medal TriggerClip completed", data.EventName)
	end
end

return {
	Initialize = function()
		Remotes.Collaborations.MedalAutoClip.Listen(triggerMedalClip)
	end
}