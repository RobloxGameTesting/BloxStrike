local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
require(ReplicatedStorage.Database.Custom.Types)
local SprayPatterns = ReplicatedStorage.Database.Custom.Weapons.SprayPatterns
local RecoilPatterns = {}

local function quadraticBezier(point: Vector2, point2: Vector2, point3: Vector2, p: number) -- 1 equivalent call inferred from this helper
	local v = 1 - p
	return v * v * point + v * 2 * p * point2 + p * p * point3
end

local function cubicBezier(point: Vector2, point2: Vector2, point3: Vector2, point4: Vector2, p: number) -- 1 equivalent call inferred from this helper
	local v = 1 - p
	local v2 = p * p
	local v3 = v * v
	local v4 = v3 * v
	local v5 = v2 * p
	return v4 * point + v3 * 3 * p * point2 + v * 3 * v2 * point3 + v5 * point4
end

local function getPositionOnPath(path, value: number)
	if #path == 2 then
		return path[1]:Lerp(path[2], value)
	end

	if #path == 3 then
		return quadraticBezier(path[1], path[2], path[3], value) -- inferred equivalent call
	else
		if #path ~= 4 then
			return Vector2.zero
		end

		return cubicBezier(path[1], path[2], path[3], path[4], value) -- inferred equivalent call
	end
end

local function getKeyframeAtTime(list, p: number)
	local v = 0

	for _, v2 in ipairs(list) do
		local duration = v2.Duration
		local v3 = v + duration

		if p <= v3 then
			return v2, (math.clamp((p - v) / duration, 0, 1))
		else
			v = v3
		end
	end

	return nil, nil
end

local function getSequenceDuration(list) -- 1 equivalent call inferred from this helper
	local total = 0

	for _, v in ipairs(list) do
		total += v.Duration
	end

	return total
end

local function CreatePattern(childName: string, p)
	local fireRate = p.FireRate
	local rounds = p.Rounds
	local result = {}
	local child = SprayPatterns:FindFirstChild(childName)

	if not child then
		warn(string.format("%s has no spray pattern part", childName))
		return nil
	end

	if #child:GetChildren() < rounds then
		warn(
			string.format("%s spray pattern has fewer points than magazine size", childName),
			rounds,
			#child:GetChildren()
		)
	end

	local v = child[tostring(1)]

	for i = 1, rounds do
		local v2 = child[tostring(i)]
		local zero = Vector2.zero
		local zero2 = Vector2.zero

		if i > 1 then
			local position = (v.WorldCFrame:Inverse() * child[tostring(i - 1)].WorldCFrame).Position
			zero = Vector2.new(position.X, position.Y)
			local position2 = (v.WorldCFrame:Inverse() * v2.WorldCFrame).Position
			zero2 = Vector2.new(position2.X, position2.Y)
		end

		table.insert(result, {
			Duration = 1 * fireRate,
			EasingStyle = Enum.EasingStyle.Linear,
			EasingDirection = Enum.EasingDirection.In,
			Path = { zero * 0.5, zero2 * 0.5 }
		})
	end

	return result
end

local function AppendPattern(name) -- 1 equivalent call inferred from this helper
	RecoilPatterns[name] = function(p)
		local pattern = CreatePattern(name, p)
		local sequenceDuration = getSequenceDuration(pattern) -- inferred equivalent call
		return function(value: number)
			local keyframeAtTime, v = getKeyframeAtTime(pattern, math.clamp(value, 0, sequenceDuration))
			local value2 = TweenService:GetValue(v, keyframeAtTime.EasingStyle, keyframeAtTime.EasingDirection)
			return (getPositionOnPath(keyframeAtTime.Path, value2))
		end
	end
end

for _, child in ipairs(SprayPatterns:GetChildren()) do
	AppendPattern(child.Name) -- inferred equivalent call
end

return RecoilPatterns