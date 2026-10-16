local RunService = game:GetService("RunService")
local v = 0
local class = {}
class.__index = class
local UIParticle = {}
UIParticle.__index = UIParticle
local v2 = {}
local heartbeatConnection = nil

local function rotate(directionVector: Vector2, spreadAngle: number) -- 1 equivalent call inferred from this helper
	local v3 = math.rad(spreadAngle)
	local v4 = math.sin(v3)
	local v5 = math.cos(v3)
	return Vector2.new(v5 * directionVector.X - v4 * directionVector.Y, v4 * directionVector.X + v5 * directionVector.Y)
end

local function alphaBetween(p: number, maxAge: number, age: number) -- 1 equivalent call inferred from this helper
	if maxAge <= p then
		return 1
	end

	return (math.clamp((age - p) / (maxAge - p), 0, 1))
end

local function evalColor(color, p: number)
	if typeof(color) ~= "ColorSequence" then
		return color
	end

	if p <= 0 then
		return color.Keypoints[1].Value
	end

	if p >= 1 then
		return color.Keypoints[#color.Keypoints].Value
	end

	for i = 1, #color.Keypoints - 1 do
		local keypoint = color.Keypoints[i]
		local keypoint2 = color.Keypoints[i + 1]

		if not (keypoint.Time <= p and p < keypoint2.Time) then
			continue
		end

		local v3 = (p - keypoint.Time) / (keypoint2.Time - keypoint.Time)
		return keypoint.Value:Lerp(keypoint2.Value, v3)
	end

	return color.Keypoints[#color.Keypoints].Value
end

local function evalNumber(sequence, p: number)
	if typeof(sequence) ~= "NumberSequence" then
		return sequence
	end

	if p <= 0 then
		return sequence.Keypoints[1].Value
	end

	if p >= 1 then
		return sequence.Keypoints[#sequence.Keypoints].Value
	end

	for i = 1, #sequence.Keypoints - 1 do
		local keypoint = sequence.Keypoints[i]
		local keypoint2 = sequence.Keypoints[i + 1]

		if not (keypoint.Time <= p and p < keypoint2.Time) then
			continue
		end

		local v3 = (p - keypoint.Time) / (keypoint2.Time - keypoint.Time)
		return (keypoint2.Value - keypoint.Value) * v3 + keypoint.Value
	end

	return sequence.Keypoints[#sequence.Keypoints].Value
end

local function sampleNumber(sequence)
	local typeName = typeof(sequence)

	if typeName == "NumberRange" then
		return math.random() * (sequence.Max - sequence.Min) + sequence.Min
	end

	if typeName ~= "NumberSequence" then
		return sequence
	end

	local value = sequence.Keypoints[1].Value
	local value2 = sequence.Keypoints[#sequence.Keypoints].Value
	return math.random() * (value2 - value) + value
end

local function getSpreadAngle(spreadAngle) -- 1 equivalent call inferred from this helper
	if typeof(spreadAngle) == "NumberRange" then
		return (sampleNumber(spreadAngle))
	end

	if spreadAngle == 0 then
		return 0
	end

	return math.random() * spreadAngle - spreadAngle / 2
end

local function getDirectionVector(emissionDirection: string, p: number)
	if emissionDirection == "Bottom" then
		return Vector2.new(0, p)
	elseif emissionDirection == "Left" then
		return Vector2.new(-p, 0)
	elseif emissionDirection == "Right" then
		return Vector2.new(p, 0)
	end

	return Vector2.new(0, -p)
end

local function getSpawnPosition(hook, emitterMode: string)
	local absoluteSize = hook.AbsoluteSize

	if emitterMode == "Fill" then
		return Vector2.new(math.random() * absoluteSize.X, math.random() * absoluteSize.Y)
	end

	return Vector2.new(absoluteSize.X / 2, absoluteSize.Y / 2)
end

local function applyVisual(instance, color: Color3, p: number, p2: number, p3: number, point: Vector2, rotation: number)
	instance.Size = UDim2.fromOffset(math.max(0, p2), (math.max(0, p3)))
	instance.Position = UDim2.fromOffset(point.X, point.Y)
	instance.Rotation = rotation

	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		instance.ImageColor3 = color
		instance.ImageTransparency = p
	elseif instance:IsA("CanvasGroup") then
		instance.GroupColor3 = color
		instance.GroupTransparency = p
	end
end

local function stepEmitter(state, __updateAccumulator: number)
	if not state.Enabled then
		return
	end

	if state.UpdateInterval > 0 then
		state.__updateAccumulator += __updateAccumulator

		if state.__updateAccumulator < state.UpdateInterval then
			return
		end

		__updateAccumulator = state.__updateAccumulator
		state.__updateAccumulator = 0
	end

	state.__elapsedTime += __updateAccumulator

	for i = #state.particles, 1, -1 do
		local particle = state.particles[i]

		if particle.isDead then
			table.remove(state.particles, i)
		else
			particle:Update(__updateAccumulator)
		end
	end

	if state.Rate <= 0 then
		return
	end

	local v3 = 1 / state.Rate

	while v3 <= state.__elapsedTime do
		if #state.particles >= state.MaxParticles or v >= 180 then
			state.__elapsedTime = 0
			break
		else
			table.insert(state.particles, class.new(state))
			state.__elapsedTime -= v3
		end
	end
end

local function stopHeartbeatIfIdle() -- 2 equivalent calls inferred from this helper
	if heartbeatConnection and next(v2) == nil then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end

local function startHeartbeat() -- 1 equivalent call inferred from this helper
	if heartbeatConnection then
		return
	end

	heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		for k in pairs(v2) do
			if k.__dead then
				v2[k] = nil
			else
				stepEmitter(k, dt)
			end
		end

		if heartbeatConnection and next(v2) == nil then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
	end)
end

local function acquireElement(p)
	local v3 = table.remove(p.__pool)

	if v3 then
		return v3
	end

	return p.Element:Clone()
end

local function releaseElement(emitter, element) -- 1 equivalent call inferred from this helper
	element.Parent = nil

	if #emitter.__pool < emitter.MaxParticles then
		table.insert(emitter.__pool, element)
	else
		element:Destroy()
	end
end

function class:new()
	local element = table.remove(self.__pool) or self.Element:Clone()
	local spawnPosition = getSpawnPosition(self.Hook, self.EmitterMode)
	local v3 = sampleNumber(self.Speed)
	local spreadAngle = getSpreadAngle(self.SpreadAngle) -- inferred equivalent call
	local rotation = sampleNumber(self.Rotation)
	local color = self.Color

	if typeof(color) == "ColorSequence" then
		color = color.Keypoints[1].Value
	end

	local transparency = self.Transparency

	if typeof(transparency) == "NumberSequence" then
		transparency = transparency.Keypoints[1].Value
	end

	local x = self.Size.X

	if typeof(x) == "NumberSequence" then
		x = x.Keypoints[1].Value
	end

	local y = self.Size.Y

	if typeof(y) == "NumberSequence" then
		y = y.Keypoints[1].Value
	end

	element.Name = "UIParticle"
	element.AnchorPoint = Vector2.new(0.5, 0.5)
	element.BackgroundTransparency = 1
	element.ZIndex = self.Hook.ZIndex + self.ZOffset
	applyVisual(element, color, transparency, x, y, spawnPosition, rotation)
	element.Parent = self.Hook

	if self.PreSpawn then
		self.PreSpawn(element)
	end

	local object = setmetatable({}, class)
	object.Element = element
	object.Position = spawnPosition
	object.Velocity = rotate(getDirectionVector(self.EmissionDirection, v3), spreadAngle) -- inferred equivalent call
	object.Acceleration = self.Acceleration
	object.Drag = self.Drag
	object.Age = 0
	object.MaxAge = sampleNumber(self.Lifetime)
	object.Size = self.Size
	object.Color = self.Color
	object.Transparency = self.Transparency
	object.RotSpeed = sampleNumber(self.RotSpeed)
	object.isDead = false
	object._emitter = self
	object._rotation = rotation
	v += 1
	return object
end

function class:Update(p: number)
	if self.Age >= self.MaxAge and self.MaxAge > 0 then
		self:Destroy()
		return
	end

	self.Age += p
	local v3 = alphaBetween(0, self.MaxAge, self.Age) -- inferred equivalent call
	local v4 = evalNumber(self.Size.X, v3)
	local v5 = evalNumber(self.Size.Y, v3)
	local v6 = evalColor(self.Color, v3)
	local v7 = evalNumber(self.Transparency, v3)

	if self.Drag > 0 then
		local v8 = math.max(0, 1 - self.Drag * p)
		self.Velocity *= v8
	end

	self.Velocity += self.Acceleration * p
	self.Position += self.Velocity * p
	self._rotation += self.RotSpeed * p
	applyVisual(self.Element, v6, v7, v4, v5, self.Position, self._rotation)
	local emitter = self._emitter

	if emitter.OnUpdate then
		emitter.OnUpdate(self.Element)
	end
end

function class:Destroy()
	if self.isDead then
		return
	end

	self.isDead = true
	v = math.max(0, v - 1)
	local emitter = self._emitter

	if not emitter or emitter.__dead then
		self.Element:Destroy()
		return
	end

	releaseElement(emitter, self.Element) -- inferred equivalent call
end

function UIParticle.new(hook, element)
	local self = setmetatable({}, UIParticle)
	self.particles = {}
	self.Enabled = false
	self.Element = element
	self.Hook = hook
	self.Rate = 20
	self.Color = Color3.new(1, 1, 1)
	self.Size = { X = NumberSequence.new(12), Y = NumberSequence.new(12) }
	self.Transparency = NumberSequence.new(0)
	self.ZOffset = 0
	self.Speed = NumberRange.new(150, 500)
	self.SpreadAngle = NumberRange.new(-15, 15)
	self.RotSpeed = NumberRange.new(0)
	self.Lifetime = NumberRange.new(5, 10)
	self.Acceleration = Vector2.new(0, -500)
	self.Drag = 0
	self.Rotation = 0
	self.EmissionDirection = "Top"
	self.EmitterMode = "Point"
	self.MaxParticles = 24
	self.UpdateInterval = 0
	self.PreSpawn = nil
	self.OnUpdate = nil
	self.__dead = false
	self.__elapsedTime = 0
	self.__updateAccumulator = 0
	self.__pool = {}
	self.__runServiceConnection = nil
	self.Emit = UIParticle.Emit
	self.SetEnabled = UIParticle.SetEnabled
	self.Destroy = UIParticle.Destroy
	return self
end

function UIParticle.fromEmitter3D(p, data, value: number?)
	local v3 = value or 1
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = data.Texture
	imageLabel.Size = UDim2.fromOffset(1, 1)
	local v4 = UIParticle.new(p, imageLabel)
	v4.Rate = data.Rate
	v4.Color = data.Color
	v4.Size = { X = data.Size, Y = data.Size }
	v4.Transparency = data.Transparency
	v4.ZOffset = data.ZOffset
	v4.Speed = NumberRange.new(data.Speed.Min * v3, data.Speed.Max * v3)
	v4.SpreadAngle = NumberRange.new(data.SpreadAngle.X, data.SpreadAngle.Y)
	v4.RotSpeed = data.RotSpeed
	v4.Lifetime = data.Lifetime
	v4.Acceleration = Vector2.new(data.Acceleration.X * v3, data.Acceleration.Y * v3)
	v4.EmitterMode = data.ShapeStyle == Enum.ParticleEmitterShapeStyle.Volume and "Fill" or "Point"
	return v4
end

function UIParticle.Emit(p, p2: number)
	for _ = 1, p2 do
		if #p.particles >= p.MaxParticles or v >= 180 then
			break
		else
			table.insert(p.particles, class.new(p))
		end
	end
end

function UIParticle:SetEnabled(flag: boolean)
	if self.__dead then
		return
	end

	local enabled = flag == true

	if self.Enabled == enabled then
		if enabled then
			v2[self] = true

			if heartbeatConnection then
				return
			else
				heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
					for k in pairs(v2) do
						if k.__dead then
							v2[k] = nil
						else
							stepEmitter(k, dt)
						end
					end

					if heartbeatConnection and next(v2) == nil then
						heartbeatConnection:Disconnect()
						heartbeatConnection = nil
					end
				end)
			end
		end
	else
		self.Enabled = enabled

		if enabled then
			v2[self] = true
			startHeartbeat() -- inferred equivalent call
		else
			v2[self] = nil

			for i = #self.particles, 1, -1 do
				self.particles[i]:Destroy()
				table.remove(self.particles, i)
			end

			stopHeartbeatIfIdle() -- inferred equivalent call
		end
	end
end

function UIParticle:Destroy()
	if self.__dead then
		return
	end

	self.__dead = true
	self.Enabled = false
	v2[self] = nil
	stopHeartbeatIfIdle() -- inferred equivalent call

	for _, particle in ipairs(self.particles) do
		particle:Destroy()
	end

	table.clear(self.particles)

	for _, v3 in ipairs(self.__pool) do
		v3:Destroy()
	end

	table.clear(self.__pool)
end

return UIParticle