return function(p, instance, name: string, className: string)
	debug.profilebegin("VFX.MuzzleFlash.CloneAsset")
	local clone = instance:FindFirstChild(name):Clone()
	clone.Name = name
	clone.CollisionGroup = "Debris"
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	clone.Anchored = false
	clone.Massless = true
	clone.CFrame = p.CFrame
	clone.Parent = p
	local instance2 = Instance.new(className)
	instance2.Part0 = p
	instance2.Part1 = clone
	instance2.Parent = clone
	debug.profileend()
	return clone
end