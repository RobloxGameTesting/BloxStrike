local RbxScriptConnection = { Connected = true }
RbxScriptConnection.__index = RbxScriptConnection

function RbxScriptConnection:Disconnect()
	if self.Connected then
		self.Connected = false
		self.Connection:Disconnect()
	end
end

function RbxScriptConnection._new(connection)
	return (setmetatable({ Connection = connection }, RbxScriptConnection))
end

function RbxScriptConnection.__tostring(p)
	return "RbxScriptConnection<" .. tostring(p.Connected) .. ">"
end

return RbxScriptConnection