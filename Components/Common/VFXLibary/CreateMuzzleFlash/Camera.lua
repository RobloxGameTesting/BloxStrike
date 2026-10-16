local EmitParticles = require(script.Parent.EmitParticles)
return function(instance, childName: string)
	debug.profilebegin("VFX.MuzzleFlash.Camera")
	local child = instance:FindFirstChild(childName)

	if not child then
		debug.profileend()
		return nil
	end

	debug.profilebegin("VFX.MuzzleFlash.Camera.EmitParticles")
	EmitParticles(child)
	debug.profileend()
	debug.profileend()
	return instance.Position
end