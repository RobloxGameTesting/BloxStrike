local ServerScriptService = game:GetService("ServerScriptService")
require(ServerScriptService.TestRunner.Test)

local function AwaitCondition(fn, value: number?)
	local lastTime = os.clock()
	local v = value or 10

	while not fn() do
		if v < os.clock() - lastTime then
			return false
		else
			task.wait()
		end
	end

	return true
end

return function(object)
	local parentModule = require(script.Parent)
	local v = nil

	local function NumConns(p) -- 4 equivalent calls inferred from this helper
		return #(p or v):GetConnections()
	end

	object:BeforeEach(function()
		v = parentModule.new()
	end)
	object:AfterEach(function()
		v:Destroy()
	end)
	object:Describe("Constructor", function()
		object:Test("should create a new signal and fire it", function()
			object:Expect(parentModule.Is(v)):ToBe(true)
			task.defer(function()
				v:Fire(10, 20)
			end)
			local v2, v3 = v:Wait()
			object:Expect(v2):ToBe(10)
			object:Expect(v3):ToBe(20)
		end)
		object:Test("should create a proxy signal and connect to it", function()
			local wrap = parentModule.Wrap
			local RunService = game:GetService("RunService")
			local wrapped = wrap(RunService.Heartbeat)
			object:Expect(parentModule.Is(wrapped)):ToBe(true)
			local v2 = false
			wrapped:Connect(function()
				v2 = true
			end)
			object:Expect(AwaitCondition(function()
				return v2
			end, 2)):ToBe(true)
			wrapped:Destroy()
		end)
	end)
	object:Describe("FireDeferred", function()
		object:Test("should be able to fire primitive argument", function()
			local v2 = nil
			v:Connect(function(p)
				v2 = p
			end)
			v:FireDeferred(10)
			object:Expect(AwaitCondition(function()
				return v2 == 10
			end, 1)):ToBe(true)
		end)
		object:Test("should be able to fire a reference based argument", function()
			local v2 = { 10, 20 }
			local v3 = nil
			v:Connect(function(p)
				v3 = p
			end)
			v:FireDeferred(v2)
			object:Expect(AwaitCondition(function()
				return v2 == v3
			end, 1)):ToBe(true)
		end)
	end)
	object:Describe("Fire", function()
		object:Test("should be able to fire primitive argument", function()
			local v2 = nil
			v:Connect(function(p)
				v2 = p
			end)
			v:Fire(10)
			object:Expect(v2):ToBe(10)
		end)
		object:Test("should be able to fire a reference based argument", function()
			local v2 = { 10, 20 }
			local v3 = nil
			v:Connect(function(p)
				v3 = p
			end)
			v:Fire(v2)
			object:Expect(v3):ToBe(v2)
		end)
	end)
	object:Describe("ConnectOnce", function()
		object:Test("should only capture first fire", function()
			local v2 = nil
			local v3 = v:ConnectOnce(function(p)
				v2 = p
			end)
			object:Expect(v3.Connected):ToBe(true)
			v:Fire(10)
			object:Expect(v3.Connected):ToBe(false)
			v:Fire(20)
			object:Expect(v2):ToBe(10)
		end)
	end)
	object:Describe("Wait", function()
		object:Test("should be able to wait for a signal to fire", function()
			task.defer(function()
				v:Fire(10, 20, 30)
			end)
			local v2, v3, v4 = v:Wait()
			object:Expect(v2):ToBe(10)
			object:Expect(v3):ToBe(20)
			object:Expect(v4):ToBe(30)
		end)
	end)
	object:Describe("DisconnectAll", function()
		object:Test("should disconnect all connections", function()
			v:Connect(function() end)
			v:Connect(function() end)
			object:Expect(NumConns(nil)):ToBe(2) -- inferred equivalent call
			v:DisconnectAll()
			object:Expect(NumConns(nil)):ToBe(0) -- inferred equivalent call
		end)
	end)
	object:Describe("Disconnect", function()
		object:Test("should disconnect connection", function()
			local connection = v:Connect(function() end)
			object:Expect(NumConns(nil)):ToBe(1) -- inferred equivalent call
			connection:Disconnect()
			object:Expect(NumConns(nil)):ToBe(0) -- inferred equivalent call
		end)
		object:Test("should still work if connections disconnected while firing", function()
			local count = 0
			local connection = nil
			v:Connect(function()
				count += 1
			end)
			connection = v:Connect(function()
				connection:Disconnect()
				count += 1
			end)
			v:Connect(function()
				count += 1
			end)
			v:Fire()
			object:Expect(count):ToBe(3)
		end)
		object:Test("should still work if connections disconnected while firing deferred", function()
			local count = 0
			local connection = nil
			v:Connect(function()
				count += 1
			end)
			connection = v:Connect(function()
				connection:Disconnect()
				count += 1
			end)
			v:Connect(function()
				count += 1
			end)
			v:FireDeferred()
			object:Expect(AwaitCondition(function()
				return count == 3
			end)):ToBe(true)
		end)
	end)
end