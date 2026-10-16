local worldModel = nil
local RunService = game:GetService("RunService")
local CollectiveWorldModel = {}

function CollectiveWorldModel.setupWorldModel(_)
	if worldModel then
		return worldModel
	end

	local v = RunService:IsClient() and "ReplicatedStorage" or "ServerStorage"
	worldModel = Instance.new("WorldModel")
	worldModel.Name = "ZonePlusWorldModel"
	worldModel.Parent = game:GetService(v)
	return worldModel
end

function CollectiveWorldModel:_getCombinedResults(p, ...)
	local result = workspace[p](workspace, ...)

	if worldModel then
		local v = worldModel[p](worldModel, ...)

		for _, v2 in pairs(v) do
			table.insert(result, v2)
		end
	end

	return result
end

function CollectiveWorldModel:GetPartBoundsInBox(p, p2, p3)
	return self:_getCombinedResults("GetPartBoundsInBox", p, p2, p3)
end

function CollectiveWorldModel:GetPartBoundsInRadius(p, p2, p3)
	return self:_getCombinedResults("GetPartBoundsInRadius", p, p2, p3)
end

function CollectiveWorldModel:GetPartsInPart(p, p2)
	return self:_getCombinedResults("GetPartsInPart", p, p2)
end

return CollectiveWorldModel