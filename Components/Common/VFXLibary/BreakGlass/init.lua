local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = workspace:WaitForChild("Debris")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local LocalPlayer = Players.LocalPlayer
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Sound = require(ReplicatedStorage.Classes.Sound)
local wedgePart = Instance.new("WedgePart", script)
wedgePart.BottomSurface = Enum.SurfaceType.Smooth
wedgePart.TopSurface = Enum.SurfaceType.Smooth
wedgePart.Anchored = true

local function draw3dTriangle(position: Vector3, position2: Vector3, vector: Vector3, debris)
	debug.profilebegin("VFX.BreakGlass.DrawTriangle")
	local vector2 = position2 - position
	local vector3 = vector - position
	local vector4 = vector - position2
	local dot = vector2:Dot(vector2)
	local dot2 = vector3:Dot(vector3)
	local dot3 = vector4:Dot(vector4)

	if dot2 < dot and dot3 < dot then
		vector, position = position, vector
	elseif dot3 < dot2 and dot < dot2 then
		position, position2 = position2, position
	end

	local vector5 = position2 - position
	local vector6 = vector - position
	local vector7 = vector - position2
	local unit = vector6:Cross(vector5).Unit
	local unit2 = vector7:Cross(unit).Unit
	local unit3 = vector7.Unit
	local v = math.abs((vector5:Dot(unit2)))
	local clone = wedgePart:Clone()
	clone.Size = Vector3.new(0, v, (math.abs((vector5:Dot(unit3)))))
	clone.CFrame = CFrame.fromMatrix((position + position2) / 2, unit, unit2, unit3)
	clone.Parent = debris
	local clone2 = wedgePart:Clone()
	clone2.Size = Vector3.new(0, v, (math.abs((vector6:Dot(unit3)))))
	clone2.CFrame = CFrame.fromMatrix((position + vector) / 2, -unit, unit2, -unit3)
	clone2.Parent = debris
	debug.profileend()
	return clone, clone2
end

local function retireSourcePart(instance, maid)
	instance.CollisionGroup = "Debris"
	instance.Transparency = 1
	instance.CanCollide = false
	instance.CastShadow = false
	instance.CanQuery = false
	instance.CanTouch = false
	instance.Anchored = true
	maid:Add(instance)
	local parent = instance.Parent

	if parent and parent:IsA("Model") and parent:HasTag("BreakableGlass") then
		maid:Add(parent)

		for _, decal in ipairs(parent:GetDescendants()) do
			if decal:IsA("Decal") then
				decal:Destroy()
			end
		end
	end
end

local v = {
	{ 1, 1 },
	{ 0, 1 },
	{ -1, 1 },
	{ -1, 0 },
	{ -1, -1 },
	{ 0, -1 },
	{ 1, -1 },
	{ 1, 0 }
}
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
return function(instance, vector: Vector3, vector2: Vector3)
	debug.profilebegin("VFX.BreakGlass")

	if not instance then
		debug.profileend()
		return
	end

	debug.profilebegin("VFX.BreakGlass.GetSetting")
	local v2 = DataController.Get(LocalPlayer, "Settings.Video.Presets.Glass Shatter") ~= false
	debug.profileend()
	local maid = Janitor.new()

	if v2 then
		debug.profilebegin("VFX.BreakGlass.BuildCornerPoints")
		local size = instance.Size
		local v3 = size.Z > size.X
		local v4

		if v3 then
			v4 = size.Z
		else
			v4 = size.X
		end

		local v5 = v4 * 0.5
		local v6 = size.Y * 0.5
		local v7 = {}

		for i, v8 in ipairs(v) do
			local v9 = v8[1] * v5
			local v10 = v8[2] * v6
			local cframe = instance.CFrame
			local v11

			if v3 then
				v11 = CFrame.new(0, v10, v9)
			else
				v11 = CFrame.new(v9, v10, 0)
			end

			v7[i] = cframe * v11
		end

		debug.profileend()
		debug.profilebegin("VFX.BreakGlass.CreateFragments")

		for i, v8 in ipairs(v7) do
			local v9 = v7[i + 1] or v7[1]
			local v10, v11 = draw3dTriangle(v8.Position, v9.Position, vector, Debris)

			for _, v12 in ipairs({ v10, v11 }) do
				v12.Transparency = math.min(instance.Transparency, 0.6)
				v12.AssemblyLinearVelocity = vector2 * 15
				v12.CollisionGroup = "Debris"
				v12.Color = instance.Color
				v12.Anchored = false
			end

			maid:Add(v10)
			maid:Add(v11)
			task.delay(4.75, function()
				debug.profilebegin("VFX.BreakGlass.FragmentFadeTween")
				maid:Add(TweenService:Create(v10, tweenInfo, { Transparency = 1 })):Play()
				maid:Add(TweenService:Create(v11, tweenInfo, { Transparency = 1 })):Play()
				debug.profileend()
			end)
		end

		debug.profileend()
		debug.profilebegin("VFX.BreakGlass.CleanupSource")
		Sound.new("Bullet"):playOneTime({ Name = "Glass Shattered", Parent = instance })
		retireSourcePart(instance, maid)
		debug.profileend()
		task.delay(5, function()
			debug.profilebegin("VFX.BreakGlass.DelayedCleanup")
			maid:Destroy()
			debug.profileend()
		end)
		debug.profileend()
	else
		debug.profilebegin("VFX.BreakGlass.NoShatter.Sound")
		Sound.new("Bullet"):PlaySoundAtPosition({
			Position = vector,
			Class = "Bullet",
			Name = "Glass Shattered"
		})
		debug.profileend()
		debug.profilebegin("VFX.BreakGlass.NoShatter.CleanupSource")
		retireSourcePart(instance, maid)
		debug.profileend()
		task.delay(0.1, function()
			debug.profilebegin("VFX.BreakGlass.NoShatter.DelayedCleanup")
			maid:Destroy()
			debug.profileend()
		end)
		debug.profileend()
	end
end