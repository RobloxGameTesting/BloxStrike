local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureService = game:GetService("CaptureService")
local Promise = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Promise"))
return {
	CaptureScreenshot = function(callback)
		return Promise.new(function(callback2, callback3)
			local success, result = pcall(CaptureService.CaptureScreenshot, CaptureService, function(p: string)
				if callback then
					callback(p)
				end

				callback2(p)
			end)

			if not success then
				callback3(result)
			end
		end)
	end
}