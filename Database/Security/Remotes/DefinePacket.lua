local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Network = require(ReplicatedStorage.Database.Security.Network)
return function(p, options)
	local v = options or {}
	return function(p2: string, p3: string)
		return Network.CreatePacket(p2, p3, p, v)
	end
end