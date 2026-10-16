local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Other = ReplicatedStorage.Assets.Other
local defuser = Other.Defuser
local DefuseA1 = Other.DefuseA1
local DefuseA2 = Other.DefuseA2
local DefuseB1 = Other.DefuseB1
local DefuseB2 = Other.DefuseB2
local v = CFrame.new(0, -0.2, -0.5) * CFrame.Angles(0, 3.141592653589793, 0)
local Defuser = {}
Defuser.__index = Defuser

local function cloneDefusePart(instance, instance2, object)
	local clone = instance:Clone()
	local attachment = clone:FindFirstChild("Attachment")
	local parent = instance2.Parent
	clone.CFrame = parent.CFrame * instance2.CFrame * attachment.CFrame:Inverse()
	clone.Parent = workspace
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = parent
	weldConstraint.Part1 = clone
	weldConstraint.Parent = clone
	object:Add(clone)
	return attachment
end

local function disconnectBeam(p) -- 2 equivalent calls inferred from this helper
	if p then
		p.Attachment0 = nil
		p.Attachment1 = nil
	end
end

local function cleanupVisuals(instance) -- 1 equivalent call inferred from this helper
	task.defer(function()
		pcall(function()
			instance:Destroy()
		end)
	end)
end

local function connectBeam(defusePart, defusePart2) -- 2 equivalent calls inferred from this helper
	local beam = defusePart.Parent:FindFirstChildWhichIsA("Beam")

	if beam then
		beam.Attachment0 = defusePart
		beam.Attachment1 = defusePart2
		beam.Enabled = true
	end

	return beam
end

function Defuser.new(p, parent)
	local self = setmetatable({}, Defuser)
	self.Janitor = Janitor.new()
	local v2 = nil
	local v3 = nil
	local v4 = nil

	local function reset() -- 1 equivalent call inferred from this helper
		disconnectBeam(v3) -- inferred equivalent call
		disconnectBeam(v4) -- inferred equivalent call

		if v2 then
			cleanupVisuals(v2) -- inferred equivalent call
		end

		v3 = nil
		v4 = nil
		v2 = nil
	end

	self.Janitor:Add(Observers.observeAttribute(p, "IsDefusingBomb", function(p2)
		reset() -- inferred equivalent call

		if p2 ~= true then
			return reset
		end

		local leftHand = parent:FindFirstChild("LeftHand")
		local v5 = CollectionService:GetTagged("Bomb")[1]

		if not (leftHand and v5) then
			return function() end
		end

		v2 = Janitor.new()
		local clone = defuser:Clone()
		local handle = clone.Handle
		clone.Parent = parent
		handle.CFrame = leftHand.CFrame * v
		clone.PrimaryPart = handle
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Part0 = leftHand
		weldConstraint.Part1 = handle
		weldConstraint.Parent = handle
		v2:Add(clone)
		local body = v5.Weapon.Body
		local defusePart = cloneDefusePart(DefuseA1, handle:FindFirstChild("AttachmentA"), v2)
		local defusePart2 = cloneDefusePart(DefuseA2, body:FindFirstChild("AttachmentA"), v2)
		local defusePart3 = cloneDefusePart(DefuseB1, handle:FindFirstChild("AttachmentB"), v2)
		local defusePart4 = cloneDefusePart(DefuseB2, body:FindFirstChild("AttachmentB"), v2)
		v3 = connectBeam(defusePart, defusePart2) -- inferred equivalent call
		v4 = connectBeam(defusePart3, defusePart4) -- inferred equivalent call
		return reset
	end))
	return self
end

function Defuser:Destroy()
	self.Janitor:Destroy()
end

return Defuser