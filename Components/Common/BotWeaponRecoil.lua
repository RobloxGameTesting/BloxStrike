local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spring = require(ReplicatedStorage.Shared.Spring)
local GetWeaponProperties = require(script.Parent.GetWeaponProperties)
local class = {}
class.__index = class

function class.new(p: string)
	local properties = GetWeaponProperties(p)
	local recoil = properties and properties.Recoil

	if recoil and type(recoil.Pattern) == "function" then
		return (setmetatable({
			Properties = properties,
			Pattern = recoil.Pattern(properties),
			Spring = Spring.new(recoil.Damper, recoil.Speed, Vector2.zero),
			Value = Vector2.zero,
			PatternTime = 0,
			RecoveryTime = 0
		}, class))
	end

	return nil
end

function class:Step(lastUpdate: number)
	local v = not self.LastUpdate and 0 or math.max(0, lastUpdate - self.LastUpdate)
	local v2

	if self.LastShot then
		v2 = self.LastShot + self.Properties.FireRate
	else
		v2 = lastUpdate
	end

	local v3 = math.max(0, lastUpdate - math.max(self.LastUpdate or lastUpdate, v2))
	local recoverySpeed = self.Properties.Recoil.RecoverySpeed

	if v3 > 0 then
		local magnitude = self.Value.Magnitude
		local v4

		if magnitude > 0 then
			v4 = self.Value * math.max(0, 1 - recoverySpeed * v3 / magnitude)
		else
			v4 = self.Value
		end

		self.Value = v4
		self.PatternTime = math.max(0, self.PatternTime - self.RecoveryTime * recoverySpeed * v3)
	end

	self.Spring:setGoal(self.Value)
	self.Spring:update(v)
	self.LastUpdate = lastUpdate
	return self.Spring:getPosition() * math.rad(self.Properties.Recoil.Scale) * self.Properties.Recoil.CameraScale
end

function class:OnShot(lastShot: number)
	self:Step(lastShot)
	self.LastShot = lastShot
	self.PatternTime += self.Properties.FireRate
	self.RecoveryTime = self.PatternTime
	self.Value = self.Pattern(self.PatternTime)
	self.Spring:setGoal(self.Value)
end

return table.freeze(class)