local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Entities = script:WaitForChild("Entities")
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local v = {}
local v2 = {}
return {
	Initialize = function()
		for _, moduleScript in Entities:GetChildren() do
			if not moduleScript:IsA("ModuleScript") then
				continue
			end

			local v3 = v2
			local name = moduleScript.Name
			local module = require(moduleScript)
			v3[name] = module
		end

		Remotes.Entity.CreateEntity.Listen(function(data)
			local v3 = v2[data.EntityName]

			if not v3 then
				return
			end

			v[data.EntityId] = v3.new(data.EntityId, data.EntityName, data.EntityPosition)
		end)
		Remotes.Entity.DestroyEntity.Listen(function(p)
			local v3 = v[p.EntityId]

			if not v3 then
				return
			end

			v[p.EntityId] = nil
			v3:Destroy(p.ClaimedBy)
		end)
	end
}