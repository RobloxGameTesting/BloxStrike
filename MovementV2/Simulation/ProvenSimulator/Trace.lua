local DeterminismTrace = require(script.Parent.Parent.DeterminismTrace)
require(script.Parent.Parent.ProvenTypes)
local v2 = nil
local v = {
	bind = function(p)
		v2 = p
	end,
	isActive = function()
		return v2 ~= nil
	end,
	line = function(p: number)
		if v2 == nil then
			return 0
		end

		return debug.info(p + 1, "l")
	end,
	state = function(p: string, p2, p3: number)
		DeterminismTrace.checkpoint(
			v2,
			p,
			p2,
			nil,
			nil,
			nil,
			"ReplicatedStorage.MovementV2.Simulation.ProvenSimulator",
			p3
		)
	end,
	vector = function(p: string, vector: Vector3, vector2: Vector3, p2: number?, p3: number?, p4: number)
		DeterminismTrace.vector(
			v2,
			p,
			vector,
			vector2,
			p2,
			p3,
			nil,
			"ReplicatedStorage.MovementV2.Simulation.ProvenSimulator",
			p4
		)
	end
}
return table.freeze(v)