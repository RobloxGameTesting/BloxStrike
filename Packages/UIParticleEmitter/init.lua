local UIParticle = require(script.UIParticle)
local UIParticleEmitter = {}
UIParticleEmitter.__index = UIParticleEmitter

local function toSize2D(size) -- 1 equivalent call inferred from this helper
	return { X = size, Y = size }
end

local function createParticleElement(texture: string) -- 1 equivalent call inferred from this helper
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Particle"
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = texture
	imageLabel.Size = UDim2.fromOffset(1, 1)
	return imageLabel
end

local function syncRuntime(data)
	local runtimeEmitter = data._runtimeEmitter

	if not runtimeEmitter then
		return
	end

	runtimeEmitter.Rate = data.Rate
	runtimeEmitter.Color = data.Color
	runtimeEmitter.Size = toSize2D(data.Size) -- inferred equivalent call
	runtimeEmitter.Transparency = data.Transparency
	runtimeEmitter.ZOffset = data.ZOffset
	runtimeEmitter.Speed = data.Speed
	runtimeEmitter.SpreadAngle = data.SpreadAngle
	runtimeEmitter.RotSpeed = data.RotSpeed
	runtimeEmitter.Lifetime = data.Lifetime
	runtimeEmitter.Acceleration = data.Acceleration
	runtimeEmitter.Drag = data.Drag
	runtimeEmitter.Rotation = data.Rotation
	runtimeEmitter.EmissionDirection = data.EmissionDirection
	runtimeEmitter.EmitterMode = data.EmitterMode or "Fill"
	runtimeEmitter.MaxParticles = data.MaxParticles or 24
	runtimeEmitter.UpdateInterval = data.UpdateInterval or 0
	runtimeEmitter.OnUpdate = data.OnUpdate

	if data._particleElement then
		data._particleElement.Image = data.Texture
	end
end

function UIParticleEmitter:SetParent(parent)
	if self._runtimeEmitter then
		self._runtimeEmitter:Destroy()
		self._runtimeEmitter = nil
	end

	self.Parent = parent

	if not parent then
		return
	end

	local particleElement = createParticleElement(self.Texture) -- inferred equivalent call
	local runtimeEmitter = UIParticle.new(parent, particleElement)
	self._particleElement = particleElement
	self._runtimeEmitter = runtimeEmitter
	syncRuntime(self)
	local setEnabled = runtimeEmitter.SetEnabled

	if typeof(setEnabled) == "function" then
		setEnabled(runtimeEmitter, true)
	else
		runtimeEmitter.Enabled = true
	end

	local maxParticles = self.MaxParticles or 24

	if self.Rate > 0 and maxParticles > 0 then
		runtimeEmitter:Emit((math.min(maxParticles, (math.max(1, (math.floor(self.Rate / 4)))))))
	end
end

function UIParticleEmitter:Emit(p: number)
	if self._runtimeEmitter then
		syncRuntime(self)
		self._runtimeEmitter:Emit(p)
	end
end

function UIParticleEmitter.Update(p, _: number)
	syncRuntime(p)
end

function UIParticleEmitter:SetEnabled(flag: boolean)
	local runtimeEmitter = self._runtimeEmitter

	if not runtimeEmitter then
		return
	end

	local setEnabled = runtimeEmitter.SetEnabled

	if typeof(setEnabled) == "function" then
		setEnabled(runtimeEmitter, flag == true)
	else
		runtimeEmitter.Enabled = flag == true
	end
end

function UIParticleEmitter:Destroy()
	if self._runtimeEmitter then
		self._runtimeEmitter:Destroy()
		self._runtimeEmitter = nil
	end

	if self._particleElement then
		self._particleElement:Destroy()
		self._particleElement = nil
	end

	self.Parent = nil
end

function UIParticleEmitter.new()
	local self = setmetatable({}, UIParticleEmitter)
	self.Color = Color3.new(1, 1, 1)
	self.Size = NumberSequence.new(12)
	self.Transparency = NumberSequence.new(0)
	self.Texture = ""
	self.EmissionDirection = "Top"
	self.Lifetime = NumberRange.new(1)
	self.Rate = 20
	self.Rotation = 0
	self.RotSpeed = 0
	self.Speed = 0
	self.SpreadAngle = 0
	self.Acceleration = Vector2.zero
	self.Drag = 0
	self.ZOffset = 0
	self.EmitterMode = nil
	self.MaxParticles = nil
	self.UpdateInterval = nil
	self.OnUpdate = nil
	self._runtimeEmitter = nil
	self._particleElement = nil
	self.SetParent = UIParticleEmitter.SetParent
	self.SetEnabled = UIParticleEmitter.SetEnabled
	self.Emit = UIParticleEmitter.Emit
	self.Update = UIParticleEmitter.Update
	self.Destroy = UIParticleEmitter.Destroy
	return self
end

return UIParticleEmitter