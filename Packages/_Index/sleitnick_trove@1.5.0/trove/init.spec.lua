return function()
	local parentModule = require(script.Parent)
	describe("Trove", function()
		local maid = nil
		beforeEach(function()
			maid = parentModule.new()
		end)
		afterEach(function()
			if maid then
				maid:Destroy()
				maid = nil
			end
		end)
		it("should add and clean up roblox instance", function()
			local part = Instance.new("Part")
			part.Parent = workspace
			maid:Add(part)
			maid:Destroy()
			expect(part.Parent).to.equal(nil)
		end)
		it("should add and clean up roblox connection", function()
			local changedConnection = workspace.Changed:Connect(function() end)
			maid:Add(changedConnection)
			maid:Destroy()
			expect(changedConnection.Connected).to.equal(false)
		end)
		it("should add and clean up a table with a destroy method", function()
			local v = { Destroyed = false }

			function v:Destroy()
				self.Destroyed = true
			end

			maid:Add(v)
			maid:Destroy()
			expect(v.Destroyed).to.equal(true)
		end)
		it("should add and clean up a table with a disconnect method", function()
			local v = { Connected = true }

			function v:Disconnect()
				self.Connected = false
			end

			maid:Add(v)
			maid:Destroy()
			expect(v.Connected).to.equal(false)
		end)
		it("should add and clean up a function", function()
			local v = false
			maid:Add(function()
				v = true
			end)
			maid:Destroy()
			expect(v).to.equal(true)
		end)
		it("should allow a custom cleanup method", function()
			local v = { Cleaned = false }

			function v:Cleanup()
				self.Cleaned = true
			end

			maid:Add(v, "Cleanup")
			maid:Destroy()
			expect(v.Cleaned).to.equal(true)
		end)
		it("should return the object passed to add", function()
			local part = Instance.new("Part")
			local v = maid:Add(part)
			expect(part).to.equal(v)
			maid:Destroy()
		end)
		it("should fail to add object without proper cleanup method", function()
			local v = {}
			expect(function()
				maid:Add(v)
			end).to.throw()
		end)
		it("should construct an object and add it", function()
			local class = {}
			class.__index = class

			function class.new(msg)
				local self = setmetatable({}, class)
				self._msg = msg
				self._destroyed = false
				return self
			end

			function class:Destroy()
				self._destroyed = true
			end

			local v = maid:Construct(class, "abc")
			expect((typeof(v))).to.equal("table")
			expect((getmetatable(v))).to.equal(class)
			expect(v._msg).to.equal("abc")
			expect(v._destroyed).to.equal(false)
			maid:Destroy()
			expect(v._destroyed).to.equal(true)
		end)
		it("should connect to a signal", function()
			local connection = maid:Connect(workspace.Changed, function() end)
			expect((typeof(connection))).to.equal("RBXScriptConnection")
			expect(connection.Connected).to.equal(true)
			maid:Destroy()
			expect(connection.Connected).to.equal(false)
		end)
		it("should remove an object", function()
			local connection = maid:Connect(workspace.Changed, function() end)
			expect(maid:Remove(connection)).to.equal(true)
			expect(connection.Connected).to.equal(false)
		end)
		it("should not remove an object not in the trove", function()
			local changedConnection = workspace.Changed:Connect(function() end)
			expect(maid:Remove(changedConnection)).to.equal(false)
			expect(changedConnection.Connected).to.equal(true)
			changedConnection:Disconnect()
		end)
		it("should attach to instance", function()
			local part = Instance.new("Part")
			part.Parent = workspace
			local v = maid:AttachToInstance(part)
			expect(v.Connected).to.equal(true)
			part:Destroy()
			expect(v.Connected).to.equal(false)
		end)
		it("should fail to attach to instance not in hierarchy", function()
			local part = Instance.new("Part")
			expect(function()
				maid:AttachToInstance(part)
			end).to.throw()
		end)
		it("should extend itself", function()
			local maid2 = maid:Extend()
			local v = false
			maid2:Add(function()
				v = true
			end)
			expect(maid2).to.be.a("table")
			expect((getmetatable(maid2))).to.equal(parentModule)
			maid:Clean()
			expect(v).to.equal(true)
		end)
		it("should clone an instance", function()
			local v = maid:Construct(Instance.new, "Part")
			v.Name = "TroveCloneTest"
			local clone = maid:Clone(v)
			expect((typeof(clone))).to.equal("Instance")
			expect(clone).to.never.equal(v)
			expect(clone.Name).to.equal("TroveCloneTest")
			expect(v.Name).to.equal(clone.Name)
		end)
		it("should clean up a thread", function()
			local thread = coroutine.create(function() end)
			maid:Add(thread)
			expect(coroutine.status(thread)).to.equal("suspended")
			maid:Clean()
			expect(coroutine.status(thread)).to.equal("dead")
		end)
		it("should not allow objects added during cleanup", function()
			expect(function()
				maid:Add(function()
					maid:Add(function() end)
				end)
				maid:Clean()
			end).to.throw()
		end)
		it("should not allow objects to be removed during cleanup", function()
			expect(function()
				local function fn() end

				maid:Add(fn)
				maid:Add(function()
					maid:Remove(fn)
				end)
				maid:Clean()
			end).to.throw()
		end)
	end)
end