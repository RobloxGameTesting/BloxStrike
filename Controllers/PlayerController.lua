local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local now = tick()
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)

local function ReportPlayerState()
	debug.profilebegin("PlayerController.HandleNextFrame")
	local now2 = tick()
	Remotes.Player.BlankRequest.Send(now2)

	if now2 - now >= 900 then
		Remotes.Player.AFKTeleport.Send()
		now = now2
	end

	debug.profileend()
end

local PlayerController = {}

function PlayerController.Initialize()
	UserInputService.InputBegan:Connect(function()
		now = tick()
	end)
	UserInputService.InputChanged:Connect(function()
		now = tick()
	end)
	Remotes.Player.BlankRequest.Listen(function(p: number)
		Remotes.Player.ReportPlayerConnect.Send((tostring((math.floor((tick() - p) * 1000)))))
	end)
end

function PlayerController.Start()
	task.delay(5, function()
		local userPlatform = GetUserPlatform()

		if userPlatform and #userPlatform > 0 then
			Remotes.Player.SubmitUserPlatformAnalytics.Send(userPlatform[1])
		end
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			ReportPlayerState()
		end
	end)
end

return PlayerController