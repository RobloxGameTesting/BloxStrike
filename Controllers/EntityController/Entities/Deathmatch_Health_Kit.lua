local DeathmatchHealthKit = {}
DeathmatchHealthKit.__index = DeathmatchHealthKit
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local health = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Deathmatch"):WaitForChild("Health")
local Debris = workspace:WaitForChild("Debris")

local function AttemptEntityPickup(object)
	local now = os.clock()

	if now - object.LastRequest < 0.5 or Players.LocalPlayer:GetAttribute("BuyMenu") then
		return
	end

	local localCharacter = CharacterResolver.getLocalCharacter()

	if not CharacterResolver.isAliveCharacter(localCharacter) then
		return
	end

	local rootPart = CharacterResolver.getRootPart(localCharacter)

	if not rootPart or (rootPart.Position - object.Position).Magnitude > 6 then
		return
	end

	object.LastRequest = now
	Remotes.Entity.InteractWithEntity.Send({ EntityId = object.EntityId, Action = "Pickup" })
end

function DeathmatchHealthKit.new(entityId: string, _: string, position: Vector3)
	local object = setmetatable({
		EntityId = entityId,
		Position = position,
		Model = health:Clone(),
		BindingName = RunServiceController.CreateBindingName("DeathmatchHealthKit"),
		LastRequest = 0,
		Elapsed = 0
	}, DeathmatchHealthKit)

	for _, part in object.Model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Anchored = true
	end

	object.Model:PivotTo(CFrame.new(position))
	object.Model.Parent = Debris
	RunServiceController.BindToHeartbeat(object.BindingName, function(p: number)
		object.Elapsed += p
		local v = math.sin(object.Elapsed * 0.5 * 2 * 3.141592653589793) * 0.15 + 0.2
		object.Model:PivotTo(CFrame.new(object.Position + Vector3.new(0, v, 0)) * CFrame.Angles(0, object.Elapsed * 1.5707963267948966, 0))
		AttemptEntityPickup(object)
	end)
	return object
end

function DeathmatchHealthKit:Destroy(p: number?)
	RunServiceController.Unbind("Heartbeat", self.BindingName)
	self.Model:Destroy()

	if p == Players.LocalPlayer.UserId then
		Router.broadcastRouter("DeathmatchHealthClaimed")
	end
end

return DeathmatchHealthKit