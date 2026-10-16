local Spring = {}
Spring.__index = Spring
local exp = math.exp
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt

function Spring.new(value, value2, p)
	assert(type(value) == "number", "damping ratio must be a number")
	assert(type(value2) == "number", "frequency must be a number")
	assert(value * value2 >= 0, "Spring does not converge")
	return (setmetatable({
		d = value,
		f = value2 * 0.2,
		g = p,
		p = p,
		v = p * 0
	}, Spring))
end

function Spring:setDampingRatio(p: number)
	self.d = p
end

function Spring:setFrequency(p: number)
	self.f = p * 0.2
end

function Spring:setGoal(p)
	self.g = p
end

function Spring.getGoal(p)
	return p.g
end

function Spring:setPosition(p)
	self.p = p
end

function Spring.getPosition(p)
	return p.p
end

function Spring.getVelocity(p)
	return p.v / 0.2
end

function Spring:impulse(p)
	self.v += p * 0.2
end

function Spring:reset(p)
	self.g = p
	self.p = self.g
	self.v = self.g * 0
end

function Spring:update(p)
	local d = self.d
	local v = self.f * 2 * 3.141592653589793
	local g = self.g
	local p2 = self.p
	local v2 = self.v
	local v3 = p2 - g
	local v4 = exp(-d * v * p)
	local v5, v6

	if d == 1 then
		v5 = (v3 * (1 + v * p) + v2 * p) * v4 + g
		v6 = (v2 * (1 - v * p) - v3 * (v * v * p)) * v4
	elseif d < 1 then
		local v7 = sqrt(1 - d * d)
		local v8 = cos(v * v7 * p)
		local v9 = sin(v * v7 * p)
		local v10

		if v7 > 0.0001 then
			v10 = v9 / v7
		else
			local v11 = p * v
			v10 = v11 + (v11 * v11 * (v7 * v7) * (v7 * v7) / 20 - v7 * v7) * (v11 * v11 * v11) / 6
		end

		local v11

		if v * v7 > 0.0001 then
			v11 = v9 / (v * v7)
		else
			local v12 = v * v7
			v11 = p + (p * p * (v12 * v12) * (v12 * v12) / 20 - v12 * v12) * (p * p * p) / 6
		end

		v5 = (v3 * (v8 + d * v10) + v2 * v11) * v4 + g
		v6 = (v2 * (v8 - v10 * d) - v3 * (v10 * v)) * v4
	else
		local v7 = sqrt(d * d - 1)
		local v8 = -v * (d - v7)
		local v9 = -v * (d + v7)
		local v10 = (v2 - v3 * v8) / (2 * v * v7)
		local v11 = (v3 - v10) * exp(v8 * p)
		local v12 = v10 * exp(v9 * p)
		v5 = v11 + v12 + g
		v6 = v11 * v8 + v12 * v9
	end

	self.p = v5
	self.v = v6
	return v5
end

return Spring