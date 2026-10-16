local v = {}

local function getEmitterConfigs(folder)
	local v2 = v[folder]

	if v2 then
		return v2
	end

	local result = {}

	for _, emitter in ipairs(folder:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			table.insert(result, {
				Emitter = emitter,
				Delay = emitter:GetAttribute("EmitDelay") or 0,
				Count = emitter:GetAttribute("EmitCount") or 1
			})
		end
	end

	v[folder] = result
	folder.Destroying:Once(function()
		v[folder] = nil
	end)
	return result
end

local function emitParticle(data)
	local emitter = data.Emitter

	if data.Delay > 0 then
		task.delay(data.Delay, function()
			if emitter.Parent then
				emitter:Emit(data.Count)
			end
		end)
	elseif emitter.Parent then
		emitter:Emit(data.Count)
	end
end

return function(p)
	for _, v2 in ipairs((getEmitterConfigs(p))) do
		local emitter = v2.Emitter

		if v2.Delay > 0 then
			local v3 = v2
			task.delay(v2.Delay, function()
				if emitter.Parent then
					emitter:Emit(v3.Count)
				end
			end)
		elseif emitter.Parent then
			emitter:Emit(v2.Count)
		end
	end
end