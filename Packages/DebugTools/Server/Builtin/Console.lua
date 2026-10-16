local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local Module = require(script.Parent.Parent.Module)
local Networking = require(script.Parent.Parent.Networking)
local console = Module.new("Console")
local v = { MessagesHistory = {} }

function v.sendMessagesHistory(p)
	for _, v2 in v.MessagesHistory do
		Networking:SendMessageToPlayer(p, "console_messages", v2.MessageType, v2.Message, v2.Timestamp)
	end
end

function console.Init(_)
	if RunService:IsStudio() then
		return
	end

	LogService.MessageOut:Connect(function(message: string, messageType)
		local timestamp = math.floor(os.clock() * 1000) / 1000
		Networking:SendMessage("console_messages", messageType, message, timestamp)
		table.insert(v.MessagesHistory, {
			Message = message,
			MessageType = messageType,
			Timestamp = timestamp
		})

		if #v.MessagesHistory > 100 then
			table.remove(v.MessagesHistory, 1)
		end
	end)

	for _, v2 in Networking:GetNetworkTargets() do
		v.sendMessagesHistory(v2)
	end

	Networking.NetworkTargetAdded:Connect(function(p)
		v.sendMessagesHistory(p)
	end)
end

return console