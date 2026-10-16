local ReplicatedStorage = game:GetService("ReplicatedStorage")
local v = {
	EQUIP_PULLOUT_FRACTION = 0.925,
	DEFAULT_EQUIP_PULLOUT = 0.5,
	EQUIP_ACTION_LOCKOUT = 1,
	MELEE_EQUIP_LOCKOUT = 1,
	BURST_SHOT_COUNT = 3,
	BURST_SHOT_INTERVAL = 0.075,
	BURST_COOLDOWN = 0.15
}
local v2 = {}
local flag = false

function v.PulloutSeconds(p: number?)
	if p == nil or not (p > 0) then
		return v.DEFAULT_EQUIP_PULLOUT
	end

	return p * v.EQUIP_PULLOUT_FRACTION
end

local function clipLength(keyframeSequence)
	local v3 = 0

	if keyframeSequence:IsA("KeyframeSequence") then
		for _, v4 in keyframeSequence:GetKeyframes() do
			v3 = math.max(v3, v4.Time)
		end
	else
		for _, descendant in keyframeSequence:GetDescendants() do
			if not (descendant:IsA("FloatCurve") or descendant:IsA("RotationCurve")) then
				continue
			end

			for _, v4 in descendant:GetKeys() do
				v3 = math.max(v3, v4.Time)
			end
		end
	end

	if v3 > 0 then
		return v3
	end

	return nil
end

local function fetchLength(AnimationClipProvider, cameraAnimations, childName: string, name: string)
	local animation = cameraAnimations:FindFirstChild(childName)

	if animation == nil or not animation:IsA("Animation") then
		return nil
	end

	local success, animationClipAsync = pcall(
		AnimationClipProvider.GetAnimationClipAsync,
		AnimationClipProvider,
		animation.AnimationId
	)

	if not success or animationClipAsync == nil then
		warn(`[WeaponTimings] {name} {childName} clip unavailable: {tostring(animationClipAsync)}`)
		return nil
	end

	local v3 = clipLength(animationClipAsync)
	animationClipAsync:Destroy()
	return v3
end

function v.Load()
	if flag then
		return
	end

	flag = true
	local AnimationClipProvider = game:GetService("AnimationClipProvider")

	for _, moduleScript in ReplicatedStorage.Database.Custom.Weapons:GetChildren() do
		if not moduleScript:IsA("ModuleScript") then
			continue
		end

		local module = require(moduleScript)
		local cameraAnimations = module.CameraAnimations

		if module.Class == "Weapon" and typeof(cameraAnimations) == "Instance" then
			v2[moduleScript.Name] = {
				Equip = fetchLength(AnimationClipProvider, cameraAnimations, "Equip", moduleScript.Name),
				Reload = fetchLength(AnimationClipProvider, cameraAnimations, "Reload", moduleScript.Name)
			}
		end
	end
end

function v.DrawSeconds(p: string)
	local v3 = v2[p]
	local pulloutSeconds = v.PulloutSeconds
	local v4

	if v3 then
		v4 = v3.Equip
	end

	return pulloutSeconds(v4)
end

function v.MinShotInterval(data)
	local fireRate = data.FireRate or 0
	local fireModes = data.FireModes

	if fireModes ~= nil then
		if fireModes.Primary ~= nil and fireModes.Primary.FireRate ~= nil then
			fireRate = math.min(fireRate, fireModes.Primary.FireRate)
		end

		if fireModes.Secondary ~= nil and fireModes.Secondary.FireRate ~= nil then
			fireRate = math.min(fireRate, fireModes.Secondary.FireRate)
		end
	end

	if data.ShootingOptions == "Burst" then
		fireRate = math.min(
			fireRate,
			(v.BURST_SHOT_INTERVAL * v.BURST_SHOT_COUNT + v.BURST_COOLDOWN) / v.BURST_SHOT_COUNT
		)
	end

	return fireRate
end

function v.ReloadSeconds(p: string)
	local v3 = v2[p]

	if v3 then
		return v3.Reload
	end

	return nil
end

return table.freeze(v)