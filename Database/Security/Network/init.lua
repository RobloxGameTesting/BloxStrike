local Network = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local BufferCodec = require(script.BufferCodec)
local isServer = RunService:IsServer()
local v = {}
local v2 = nil

local function logPacket(p: string, p2: string, p3, p4)
	if not DebugFlags.IsEnabled("NetworkPackets") then
		return
	end

	local success, result = pcall(function()
		return HttpService:JSONEncode(p3)
	end)
	local v3 = not success and "unknown" or string.format("%.3f KB", #result / 1024)
	local v4 = not p4 and "" or ` | Player: {p4.Name}`
	print(string.format(
		"%s %s %s | Size: %s%s | Data: %s",
		isServer and "[SERVER]" or "[CLIENT]",
		p,
		p2,
		v3,
		v4,
		not success and "{}" or result
	))
end

local function getPlayerPosition(p) -- 1 equivalent call inferred from this helper
	local v3 = assert(v2, "Network player position resolver has not been installed")(p)

	if typeof(v3) == "Vector3" then
		return v3
	end

	return nil
end

local function getPlayersInRange(position: Vector3, range: number)
	local result = {}

	for _, v3 in ipairs(Players:GetPlayers()) do
		local playerPosition = getPlayerPosition(v3) -- inferred equivalent call

		if playerPosition and (playerPosition - position).Magnitude <= range then
			table.insert(result, v3)
		end
	end

	return result
end

local function getChildFolder(parent, name: string) -- 2 equivalent calls inferred from this helper
	local folder = parent:FindFirstChild(name)

	if folder and folder:IsA("Folder") then
		return folder
	end

	if not isServer then
		return (parent:WaitForChild(name))
	end

	local folder2 = Instance.new("Folder")
	folder2.Name = name
	folder2.Parent = parent
	return folder2
end

local function getNamespaceFolder(name: string)
	local parent = ReplicatedStorage
	local v3 = parent:FindFirstChild("NetworkRemotes")

	if v3 and v3:IsA("Folder") then
		return getChildFolder(v3, name) -- inferred equivalent call
	end

	if isServer then
		v3 = Instance.new("Folder")
		v3.Name = "NetworkRemotes"
		v3.Parent = parent
	else
		v3 = parent:WaitForChild("NetworkRemotes")
	end

	return getChildFolder(v3, name) -- inferred equivalent call
end

local function expectedRemoteClassName(p: string?) -- 2 equivalent calls inferred from this helper
	if p == "Unreliable" then
		return "UnreliableRemoteEvent"
	end

	return "RemoteEvent"
end

local function createRemoteForReliability(name: string, p: string?) -- 1 equivalent call inferred from this helper
	local instance = Instance.new(expectedRemoteClassName(p)) -- inferred equivalent call
	instance.Name = name
	return instance
end

local function validateRemoteForReliability(instance, name: string, childName: string, p: string?) -- 3 equivalent calls inferred from this helper
	local v3 = expectedRemoteClassName(p) -- inferred equivalent call

	if instance.ClassName ~= v3 then
		error(
			`[Network] {name}.{childName} requires {v3}, found {instance.ClassName} at {instance:GetFullName()}; refusing to bind a mismatched transport`,
			3
		)
	end

	return instance
end

local function getPacketRemote(name: string, childName: string, p: string?)
	local parent = ReplicatedStorage
	local parent2 = parent:FindFirstChild("NetworkRemotes")

	if not (parent2 and parent2:IsA("Folder")) then
		if isServer then
			parent2 = Instance.new("Folder")
			parent2.Name = "NetworkRemotes"
			parent2.Parent = parent
		else
			parent2 = parent:WaitForChild("NetworkRemotes")
		end
	end

	local parent3 = parent2:FindFirstChild(name)

	if not (parent3 and parent3:IsA("Folder")) then
		if isServer then
			parent3 = Instance.new("Folder")
			parent3.Name = name
			parent3.Parent = parent2
		else
			parent3 = parent2:WaitForChild(name)
		end
	end

	local child = parent3:FindFirstChild(childName)

	if child then
		return validateRemoteForReliability(child, name, childName, p) -- inferred equivalent call
	elseif isServer then
		local remoteForReliability = createRemoteForReliability(childName, p) -- inferred equivalent call
		remoteForReliability.Parent = parent3
		return validateRemoteForReliability(remoteForReliability, name, childName, p) -- inferred equivalent call
	else
		return validateRemoteForReliability(parent3:WaitForChild(childName), name, childName, p) -- inferred equivalent call
	end
end

local function sendImmediatePacketRejectionFeedback(p: string, p2: string, player, p3, reason: string, p4: number?)
	if not isServer then
		return
	end

	if p == "Store" and (p2 == "OpenCase" or p2 == "OpenConsole") then
		local packetRemote = getPacketRemote("Store", "CaseOpenDenied", nil)
		local requestId

		if typeof(p3) == "table" and typeof(p3.RequestId) == "string" then
			requestId = p3.RequestId
		end

		local v3 = {
			Reason = reason,
			RequestId = requestId,
			RetryAfterMs = p4 and math.max(0, (math.round(p4 * 1000))) or nil
		}
		logPacket("OUTGOING", "Store.CaseOpenDenied", v3, player)
		local encoded, v4 = BufferCodec.Encode(v3)
		packetRemote:FireClient(player, encoded, v4)
	end
end

local function canPassRateLimit(p, name: string, p2)
	local maximum_requests_per_second = p2.maximum_requests_per_second or 10

	if maximum_requests_per_second <= 0 then
		return true, nil
	end

	local now = os.clock()
	local v3 = v[p]

	if not v3 then
		v3 = {}
		v[p] = v3
	end

	local v4 = v3[name]
	local tokens = math.max(1, maximum_requests_per_second)

	if not v4 then
		v4 = { tokens = tokens, lastRefill = now }
		v3[name] = v4
	end

	local v5 = now - v4.lastRefill

	if v5 > 0 then
		v4.tokens = math.min(tokens, v4.tokens + v5 * maximum_requests_per_second)
		v4.lastRefill = now
	end

	if v4.tokens < 1 then
		return false, (1 - v4.tokens) / maximum_requests_per_second
	end

	v4.tokens -= 1
	return true, nil
end

local function canPassMiddleware(p, p2, p3)
	local middleware = p.middleware
	return not (middleware and not middleware(p2, p3))
end

local function isFiniteNumber(value) -- 1 equivalent call inferred from this helper
	return typeof(value) == "number" and value == value and value ~= 1e999 and value ~= -1e999
end

local function isInteger(value) -- 1 equivalent call inferred from this helper
	return isFiniteNumber(value) and value == math.floor(value) -- inferred equivalent call
end

local function fn(_)
	return true
end

local v3 = {
	String = "string",
	Bool = "boolean",
	Instance = "Instance",
	CFrame = "CFrame",
	Vec3 = "Vector3",
	Vec2 = "Vector2"
}
local v4 = {
	Uint8 = { 0, 255 },
	Uint16 = { 0, 65535 },
	Uint32 = { 0, 4294967295 },
	Int8 = { -128, 127 },
	Int16 = { -32768, 32767 },
	Int32 = { -2147483648, 2147483647 }
}
local function compileValidator(value)
	if type(value) ~= "table" or value._kind == nil or value._kind == "Unknown" then
		return fn
	end

	local kind = value._kind

	if kind == "Nothing" then
		return function(p)
			return p == nil
		end
	end

	local v5 = v3[kind]

	if v5 then
		return function(p)
			return typeof(p) == v5
		end
	end

	if kind == "Float32" or kind == "Float64" then
		return isFiniteNumber
	end

	local v6 = v4[kind]

	if v6 then
		local v7 = v6[1]
		local v8 = v6[2]
		return function(p)
			local integer = isInteger(p) -- inferred equivalent call

			if integer then
				if v7 <= p then
					integer = p <= v8
				else
					integer = false
				end
			end

			return integer
		end
	else
		if kind == "Optional" then
			local v7 = compileValidator(value.value)
			return function(p)
				if p == nil then
					return true
				end

				return v7(p)
			end
		elseif kind == "Array" then
			local v7 = compileValidator(value.value)
			return function(list)
				if typeof(list) ~= "table" then
					return false
				end

				local count = #list

				for k, v8 in pairs(list) do
					if typeof(k) ~= "number" or k < 1 or count < k or k % 1 ~= 0 then
						return false
					end

					if not v7(v8) then
						return false
					end
				end

				for i = 1, count do
					if list[i] == nil then
						return false
					end
				end

				return true
			end
		end

		if kind == "Map" then
			local v7 = compileValidator(value.key)
			local v8 = compileValidator(value.value)
			return function(items)
				if typeof(items) ~= "table" then
					return false
				end

				for k, item in pairs(items) do
					if not (v7(k) and v8(item)) then
						return false
					end
				end

				return true
			end
		else
			if kind ~= "Struct" then
				return fn
			end

			local value2 = value.value

			if typeof(value2) ~= "table" then
				return function(p)
					return typeof(p) == "table"
				end
			end

			local v7 = {}
			local v8 = {}

			for k, v9 in pairs(value2) do
				if typeof(k) ~= "string" then
					continue
				end

				v7[k] = compileValidator(v9)
				v8[k] = type(v9) ~= "table" or v9._kind ~= "Optional"
			end

			return function(items)
				if typeof(items) ~= "table" then
					return false
				end

				for k, v9 in pairs(v7) do
					local item = items[k]

					if item == nil then
						if v8[k] then
							return false
						end
					elseif not v9(item) then
						return false
					end
				end

				for k, _ in pairs(items) do
					if typeof(k) ~= "string" or v7[k] == nil then
						return false
					end
				end

				return true
			end
		end
	end
end

function Network.DefinePacket(p)
	return p
end

function Network.DefineNamespace(_: string, callback)
	return callback()
end

function Network.SetPlayerPositionResolver(callback)
	if not isServer then
		return
	end

	v2 = callback
end

local function copyPacketValue(value)
	if typeof(value) == "table" then
		local result = {}

		for k, item in value do
			result[copyPacketValue(k)] = copyPacketValue(item)
		end

		return result
	else
		if typeof(value) ~= "buffer" then
			return value
		end

		local buf = buffer.create(buffer.len(value))
		buffer.copy(buf, 0, value)
		return buf
	end
end

function Network.CreatePacket(name2: string, name3: string, p, options)
	local v5 = options or {}
	local name

	if v5.name and v5.name ~= "" then
		name = v5.name
	else
		name = `{name2}.{name3}`
	end

	local formatted = `Network.Receive.{name}`
	local v6 = compileValidator(p and p.Value)
	local packetRemote = getPacketRemote(name2, name3, p.ReliabilityType)
	local v7 = {}
	local v8 = -1e999

	local function warnInvalidPayload(items)
		local now = os.clock()

		if now - v8 < 5 then
			return
		end

		v8 = now
		local v9 = {}

		if typeof(items) == "table" then
			for k, item in items do
				table.insert(v9, `{tostring(k)}={typeof(item)}`)
			end

			table.sort(v9)
		else
			table.insert(v9, (typeof(items)))
		end

		warn(`[Network] dropped {name}: payload does not match its schema ({table.concat(v9, ", ")})`)
	end

	local function encodeAfterValidation(p2)
		if v6(p2) then
			return BufferCodec.Encode(p2)
		end

		warnInvalidPayload(p2)
		return nil, nil
	end

	function v7.Send(p2)
		if isServer then
			return
		end

		local encoded, v9

		if v6(p2) then
			encoded, v9 = BufferCodec.Encode(p2)
		else
			warnInvalidPayload(p2)
		end

		if not encoded then
			return
		end

		logPacket("OUTGOING", name, p2, Players.LocalPlayer)
		packetRemote:FireServer(encoded, v9)
	end

	function v7.SendTo(p2, player)
		if not (isServer and player) then
			return
		end

		local encoded, v9

		if v6(p2) then
			encoded, v9 = BufferCodec.Encode(p2)
		else
			warnInvalidPayload(p2)
		end

		if not encoded then
			return
		end

		logPacket("OUTGOING", name, p2, player)
		packetRemote:FireClient(player, encoded, v9)
	end

	function v7.SendToAll(p2)
		if not isServer then
			return
		end

		local encoded, v9

		if v6(p2) then
			encoded, v9 = BufferCodec.Encode(p2)
		else
			warnInvalidPayload(p2)
		end

		if not encoded then
			return
		end

		logPacket("OUTGOING", name, p2, nil)
		packetRemote:FireAllClients(encoded, v9)
	end

	function v7.SendToAllExcept(p2, p3)
		if not isServer then
			return
		end

		local encoded, v9

		if v6(p2) then
			encoded, v9 = BufferCodec.Encode(p2)
		else
			warnInvalidPayload(p2)
		end

		if not encoded then
			return
		end

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= p3 then
				packetRemote:FireClient(player, encoded, v9)
			end
		end

		logPacket("OUTGOING", name, p2, nil)
	end

	function v7.SendToList(p2, list)
		if not isServer or (not list or #list == 0) then
			return
		end

		local encoded, v9

		if v6(p2) then
			encoded, v9 = BufferCodec.Encode(p2)
		else
			warnInvalidPayload(p2)
		end

		if not encoded then
			return
		end

		for _, player in ipairs(list) do
			if player then
				packetRemote:FireClient(player, encoded, v9)
			end
		end

		logPacket("OUTGOING", name, p2, nil)
	end

	function v7.SendToProximity(p2, p3)
		if not isServer then
			return
		end

		local encoded, v9

		if v6(p2) then
			encoded, v9 = BufferCodec.Encode(p2)
		else
			warnInvalidPayload(p2)
		end

		if not encoded then
			return
		end

		local position = p3.position
		local range = p3.range or 60
		local playersInRange = getPlayersInRange(position, range)

		for _, player in ipairs(playersInRange) do
			packetRemote:FireClient(player, encoded, v9)
		end

		if #playersInRange > 0 then
			logPacket("OUTGOING", name, p2, nil)
		end
	end

	local v9 = {}
	local onServerEventConnection = nil

	local function dispatch(p2, p3, p4, clone)
		if clone == nil then
			if p4 and p4.connected then
				task.spawn(p4.callback, p2, p3)
			end
		else
			for _, item in clone do
				if item.connected then
					task.spawn(item.callback, copyPacketValue(p2), p3)
				end
			end
		end
	end

	local function receive(p2, p3, p4)
		local v10 = v9[1]
		local clone

		if #v9 > 1 then
			clone = table.clone(v9)
		end

		local decoded, v11 = BufferCodec.Decode(p3, p4)

		if not decoded then
			return
		end

		if isServer then
			local v12, v13 = canPassRateLimit(p2, name, v5)

			if not v12 then
				sendImmediatePacketRejectionFeedback(name2, name3, p2, v11, "RateLimited", v13)
				return
			end
		end

		if not v6(v11) then
			return
		end

		if isServer then
			local middleware = v5.middleware

			if middleware and not middleware(v11, p2) then
				return
			end
		end

		logPacket("INCOMING", name, v11, p2)
		dispatch(v11, p2, v10, clone)
	end

	function v7.Listen(callback)
		local v10 = { callback = callback, connected = true }
		table.insert(v9, v10)

		if onServerEventConnection == nil then
			if isServer then
				onServerEventConnection = packetRemote.OnServerEvent:Connect(function(p2, p3, p4)
					Profiler.scope(formatted, receive, p2, p3, p4)
				end)
			else
				onServerEventConnection = packetRemote.OnClientEvent:Connect(function(p2, p3)
					Profiler.scope(formatted, receive, nil, p2, p3)
				end)
			end
		end

		return function()
			if not v10.connected then
				return
			end

			v10.connected = false
			table.remove(v9, (table.find(v9, v10)))

			if #v9 == 0 and onServerEventConnection ~= nil then
				onServerEventConnection:Disconnect()
				onServerEventConnection = nil
			end
		end
	end

	function v7:Connect()
		return v7.Listen(self)
	end

	function v7.Wait()
		if isServer then
			local v10, v11, v12 = packetRemote.OnServerEvent:Wait()
			local decoded, v13 = BufferCodec.Decode(v11, v12)

			if not decoded then
				v13 = nil
			end

			return v13, v10
		else
			local v10, v11 = packetRemote.OnClientEvent:Wait()
			local decoded, v12 = BufferCodec.Decode(v10, v11)

			if not decoded then
				v12 = nil
			end

			return v12, nil
		end
	end

	return v7
end

Network.Nothing = table.freeze({ _kind = "Nothing" })
Network.Unknown = table.freeze({ _kind = "Unknown" })
Network.String = table.freeze({ _kind = "String" })
Network.Bool = table.freeze({ _kind = "Bool" })
Network.Instance = table.freeze({ _kind = "Instance" })
Network.CFrame = table.freeze({ _kind = "CFrame" })
Network.Vec3 = table.freeze({ _kind = "Vec3" })
Network.Vec2 = table.freeze({ _kind = "Vec2" })
Network.Float32 = table.freeze({ _kind = "Float32" })
Network.Float64 = table.freeze({ _kind = "Float64" })
Network.Uint8 = table.freeze({ _kind = "Uint8" })
Network.Uint16 = table.freeze({ _kind = "Uint16" })
Network.Uint32 = table.freeze({ _kind = "Uint32" })
Network.Int8 = table.freeze({ _kind = "Int8" })
Network.Int16 = table.freeze({ _kind = "Int16" })
Network.Int32 = table.freeze({ _kind = "Int32" })

function Network.Array(p)
	return { _kind = "Array", value = p }
end

function Network.Map(p, p2)
	return { _kind = "Map", key = p, value = p2 }
end

function Network.Struct(p)
	return { _kind = "Struct", value = p }
end

function Network.Optional(p)
	return { _kind = "Optional", value = p }
end

if isServer then
	Players.PlayerRemoving:Connect(function(player)
		v[player] = nil
	end)
end

return Network