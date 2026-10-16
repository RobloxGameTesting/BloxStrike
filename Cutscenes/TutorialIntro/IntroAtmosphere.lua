local createVector = vector.create
local Lighting = game:GetService("Lighting")
local IntroAtmosphere = {}
IntroAtmosphere.__index = IntroAtmosphere
IntroAtmosphere.TEXTURES = { "rbxassetid://901813002", "rbxassetid://87378350610127" }
local v = {
	A = { 7, 9, 0.16, 0 },
	B = { 13, 9, 0.22, 0 },
	C = { 13, 10, 0.2, 0 },
	D = { 6, 14, 0.12, 0 }
}
local v2 = { Contrast = 0.08, Saturation = -0.05, Tint = Color3.fromRGB(255, 238, 218) }
local v3 = { Vector2.new(-3.5, 11.5), Vector2.new(2.5, 7.5), Vector2.new(5.5, 12.5) }
local color = Color3.fromRGB(255, 214, 166)
local v4 = { createVector(3.5, 0.5, 8), createVector(-3.5, 0.5, 8) }

local function smoother(value: number) -- 2 equivalent calls inferred from this helper
	local v5 = math.clamp(value, 0, 1)
	return v5 * v5 * v5 * (v5 * (v5 * 6 - 15) + 10)
end

local function invisiblePart(name: string, size: Vector3, folder) -- 1 equivalent call inferred from this helper
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	return part
end

local function numbers(items)
	local numberSequenceKeypoints = {}

	for _, item in items do
		table.insert(numberSequenceKeypoints, NumberSequenceKeypoint.new(item[1], item[2], item[3] or 0))
	end

	return NumberSequence.new(numberSequenceKeypoints)
end

local function motes(parent, rate: number, lightEmission: number)
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Name = "Motes"
	particleEmitter.Texture = "rbxassetid://901813002"
	particleEmitter.Shape = Enum.ParticleEmitterShape.Box
	particleEmitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	particleEmitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	particleEmitter.Rate = rate
	particleEmitter.Lifetime = NumberRange.new(5, 8)
	particleEmitter.Size = numbers({
		{ 0, 0.05, 0.02 },
		{ 1, 0.05, 0.02 }
	})
	particleEmitter.Transparency = numbers({
		{ 0, 1 },
		{ 0.2, 0.35, 0.15 },
		{ 0.8, 0.45, 0.15 },
		{ 1, 1 }
	})
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 228, 186))
	particleEmitter.LightEmission = lightEmission
	particleEmitter.LightInfluence = 0.3
	particleEmitter.Speed = NumberRange.new(0.04, 0.22)
	particleEmitter.SpreadAngle = Vector2.new(180, 180)
	particleEmitter.Drag = 0.6
	particleEmitter.Acceleration = createVector(0.05, 0.03, 0)
	particleEmitter.RotSpeed = NumberRange.new(-30, 30)
	particleEmitter.Parent = parent
	return particleEmitter
end

local function puffs(part, name: string)
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Name = name
	particleEmitter.Texture = "rbxassetid://87378350610127"
	particleEmitter.Rate = 0
	particleEmitter.Lifetime = NumberRange.new(1.4, 2.4)
	particleEmitter.Size = numbers({
		{ 0, 1.2, 0.4 },
		{ 1, 5, 1 }
	})
	particleEmitter.Transparency = numbers({
		{ 0, 1 },
		{ 0.1, 0.72 },
		{ 1, 1 }
	})
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(206, 184, 148))
	particleEmitter.LightEmission = 0.05
	particleEmitter.LightInfluence = 0.9
	particleEmitter.Speed = NumberRange.new(1.2, 3)
	particleEmitter.SpreadAngle = Vector2.new(30, 30)
	particleEmitter.EmissionDirection = Enum.NormalId.Back
	particleEmitter.Acceleration = createVector(0, 0.7, 0)
	particleEmitter.Drag = 1.4
	particleEmitter.Rotation = NumberRange.new(0, 360)
	particleEmitter.RotSpeed = NumberRange.new(-25, 25)
	particleEmitter.Parent = part
	return particleEmitter
end

function IntroAtmosphere.new(data)
	local object = setmetatable({}, IntroAtmosphere)
	object.Events = data.Data.Events
	object.Camera = data.Camera
	object.Folder = data.Folder
	local depthOfFieldEffect = Instance.new("DepthOfFieldEffect")
	depthOfFieldEffect.Name = "TutorialIntroFocus"
	depthOfFieldEffect.Parent = data.Camera
	object.Focus = depthOfFieldEffect
	local colorCorrectionEffect = Instance.new("ColorCorrectionEffect")
	colorCorrectionEffect.Name = "TutorialIntroGrade"
	colorCorrectionEffect.Parent = data.Camera
	object.Grade = colorCorrectionEffect
	local folder = data.Folder
	local part = Instance.new("Part")
	part.Name = "BedDust"
	part.Size = createVector(7, 5.6, 13)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	object.BedDust = part
	object.BedLocal = CFrame.new(0, 6, 2.2)
	local bedMotes = motes(part, 14, 0.45)
	bedMotes.LockedToPart = true
	object.BedMotes = bedMotes
	object.WheelDust = {}

	for k, position in v4 do
		local name = "WheelDust" .. k
		local folder2 = data.Folder
		local part2 = Instance.new("Part")
		part2.Name = name
		part2.Size = createVector(0.6, 0.2, 0.6)
		part2.Transparency = 1
		part2.Anchored = true
		part2.CanCollide = false
		part2.CanQuery = false
		part2.CanTouch = false
		part2.CastShadow = false
		part2.Parent = folder2
		table.insert(object.WheelDust, {
			Part = part2,
			Local = CFrame.new(position),
			Emitter = puffs(part2, "Dust")
		})
	end

	local folder2 = data.Folder
	local part2 = Instance.new("Part")
	part2.Name = "LandingDust"
	part2.Size = createVector(1.4, 0.2, 1.4)
	part2.Transparency = 1
	part2.Anchored = true
	part2.CanCollide = false
	part2.CanQuery = false
	part2.CanTouch = false
	part2.CastShadow = false
	part2.Parent = folder2
	local landingPuffs = puffs(part2, "Puffs")
	landingPuffs.EmissionDirection = Enum.NormalId.Top
	landingPuffs.SpreadAngle = Vector2.new(75, 75)
	landingPuffs.Speed = NumberRange.new(2.5, 5)
	landingPuffs.Lifetime = NumberRange.new(0.9, 1.6)
	landingPuffs.Size = numbers({
		{ 0, 0.8, 0.3 },
		{ 1, 3.2, 0.6 }
	})
	landingPuffs.Acceleration = createVector(0, -1.5, 0)
	landingPuffs.Drag = 3
	object.Landing = part2
	object.LandingPuffs = landingPuffs
	object.Landed = {}
	local v5 = -(data.SunDirection or Lighting:GetSunDirection())
	object.ShaftParts = {}
	object.ShaftBeams = {}
	object.ShaftMotes = nil

	if v5.Z > 0.2 and v5.Y < 0 then
		local v6 = 33 / v5.Z
		local folder3 = data.Folder
		local part3 = Instance.new("Part")
		part3.Name = "SunShaft"
		part3.Size = createVector(0.2, 0.2, 0.2)
		part3.Transparency = 1
		part3.Anchored = true
		part3.CanCollide = false
		part3.CanQuery = false
		part3.CanTouch = false
		part3.CastShadow = false
		part3.Parent = folder3
		part3.CFrame = CFrame.new(0, 0, -126)
		table.insert(object.ShaftParts, part3)

		for k, v7 in v3 do
			local attachment = Instance.new("Attachment")
			attachment.Parent = part3
			attachment.WorldPosition = Vector3.new(v7.X, v7.Y, -128)
			local attachment2 = Instance.new("Attachment")
			attachment2.Parent = part3
			attachment2.WorldPosition = attachment.WorldPosition + v5 * v6
			local beam = Instance.new("Beam")
			beam.Name = "Shaft" .. k
			beam.Attachment0 = attachment
			beam.Attachment1 = attachment2
			beam.Texture = "rbxassetid://901813002"
			beam.TextureMode = Enum.TextureMode.Stretch
			beam.TextureLength = 1
			beam.FaceCamera = true
			beam.Width0 = 5 + k
			beam.Width1 = 7 + k
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Color = ColorSequence.new(color)
			beam.Segments = 1
			beam.Enabled = false
			beam.Parent = part3
			table.insert(object.ShaftBeams, beam)
		end

		local parent = invisiblePart("ShaftDust", Vector3.new(14, 9, v6), data.Folder) -- inferred equivalent call
		local v7 = createVector(1, 7, -126) + v5 * (v6 / 2)
		parent.CFrame = CFrame.lookAt(v7, v7 + v5)
		table.insert(object.ShaftParts, parent)
		local shaftMotes = motes(parent, 0, 0.5)
		shaftMotes.LightInfluence = 0
		shaftMotes.Size = numbers({
			{ 0, 0.05, 0.02 },
			{ 1, 0.05, 0.02 }
		})
		shaftMotes.Transparency = numbers({
			{ 0, 1 },
			{ 0.25, 0.55, 0.15 },
			{ 0.75, 0.6, 0.15 },
			{ 1, 1 }
		})
		object.ShaftMotes = shaftMotes
	end

	object.ShaftOn = false
	object.LastTruck = nil
	object.Speed = 0
	return object
end

local function shotAt(events, p: number) -- 1 equivalent call inferred from this helper
	if events.ShotD <= p then
		return "D"
	end

	if events.ShotC <= p then
		return "C"
	end

	if events.ShotB <= p then
		return "B"
	end

	return "A"
end

function IntroAtmosphere:Update(p: number, p2: number, cframe: CFrame, cframe2: CFrame, items)
	local events = self.Events
	local v5 = 1 - smoother((p - events.LetterboxRetract[1]) / (events.LetterboxRetract[2] - events.LetterboxRetract[1])) -- inferred equivalent call
	local v6 = v[shotAt(events, p)] -- inferred equivalent call
	self.Focus.FocusDistance = v6[1]
	self.Focus.InFocusRadius = v6[2]
	self.Focus.FarIntensity = v6[3] * v5
	self.Focus.NearIntensity = v6[4] * v5
	self.Focus.Enabled = v5 > 0.001
	self.Grade.Contrast = v2.Contrast * v5
	self.Grade.Saturation = v2.Saturation * v5
	self.Grade.TintColor = Color3.new(1, 1, 1):Lerp(v2.Tint, v5)
	self.Grade.Enabled = v5 > 0.001
	local position = cframe2.Position

	if self.LastTruck and p2 > 0 then
		local v7 = (position - self.LastTruck).Magnitude / p2
		self.Speed += (v7 - self.Speed) * math.min(1, p2 * 8)
	end

	self.LastTruck = position
	self.BedDust.CFrame = cframe * self.BedLocal
	local v7 = math.clamp(self.Speed / 14, 0, 1)

	for _, v8 in self.WheelDust do
		v8.Part.CFrame = cframe2 * v8.Local
		v8.Emitter.Rate = v7 * 16
	end

	if events.ShotB <= p then
		for k, item in items do
			if self.Landed[k] or not (item.Position.Y < 3.3) then
				continue
			end

			self.Landed[k] = true
			self.Landing.CFrame = CFrame.new(item.Position.X, 0.15, item.Position.Z)
			self.LandingPuffs:Emit(12)
		end
	end

	local v8

	if events.ShotB <= p then
		v8 = 1 - smoother((p - events.ShotD) / 0.75) -- inferred equivalent call
	else
		v8 = 0
	end

	if v8 > 0 and not self.ShaftOn then
		self.ShaftOn = true

		if self.ShaftMotes then
			self.ShaftMotes.Rate = 9
			self.ShaftMotes:Emit(45)
		end
	elseif v8 <= 0 and self.ShaftOn and events.ShotD <= p then
		self.ShaftOn = false

		if self.ShaftMotes then
			self.ShaftMotes.Rate = 0
			self.ShaftMotes:Clear()
		end
	end

	for k, shaftBeam in self.ShaftBeams do
		shaftBeam.Enabled = v8 > 0
		local v9 = 1 - (1 - (0.84 + 0.03 * k)) * v8
		shaftBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.18, v9),
			NumberSequenceKeypoint.new(0.65, 1 - (1 - v9) * 0.8),
			NumberSequenceKeypoint.new(1, 1)
		})
	end
end

function IntroAtmosphere.Shake(p, p2: number)
	if p.Events.ShotB <= p2 then
		return CFrame.identity
	end

	local v5 = math.clamp(p.Speed / 14, 0.2, 1)

	local function n(p3: number, p4: number)
		return math.noise(p2 * p3, p4, 0.5) + 0.35 * math.noise(p2 * 1.3, p4 + 7, 0.25)
	end

	return CFrame.new(
		v5 * 0.01600000075995922 * (math.noise(p2 * 9, 1, 0.5) + 0.35 * math.noise(p2 * 1.3, 8, 0.25)),
		v5 * 0.026000000536441803 * (math.noise(p2 * 11, 2, 0.5) + 0.35 * math.noise(p2 * 1.3, 9, 0.25)),
		0
	) * CFrame.Angles(
		v5 * 0.0035000001080334187 * (math.noise(p2 * 8, 3, 0.5) + 0.35 * math.noise(p2 * 1.3, 10, 0.25)),
		v5 * 0.002199999988079071 * (math.noise(p2 * 7, 4, 0.5) + 0.35 * math.noise(p2 * 1.3, 11, 0.25)),
		v5 * 0.0044999998062849045 * (math.noise(p2 * 10, 5, 0.5) + 0.35 * math.noise(p2 * 1.3, 12, 0.25))
	)
end

function IntroAtmosphere:Destroy()
	self.Focus:Destroy()
	self.Grade:Destroy()
end

return IntroAtmosphere