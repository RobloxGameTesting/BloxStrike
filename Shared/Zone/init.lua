local createVector = vector.create
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Heartbeat = RunService.Heartbeat
local localPlayer = RunService:IsClient() and Players.LocalPlayer
game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Enum2 = require(script.Enum)
local enums = Enum2.enums
local Janitor = require(script.Janitor)
local Signal = require(script.Signal)
local ZonePlusReference = require(script.ZonePlusReference)
local object = ZonePlusReference.getObject()
local ZoneController = script.ZoneController
local Tracker = ZoneController.Tracker
local CollectiveWorldModel = ZoneController.CollectiveWorldModel
local module = require(ZoneController)
local RunService2 = game:GetService("RunService")
local v = RunService2:IsClient() and "Client" or "Server"
local child = object and object:FindFirstChild(v)

if child then
	return require(object.Value)
end

local Zone = {}
Zone.__index = Zone

if not child then
	ZonePlusReference.addToReplicatedStorage()
end

Zone.enum = enums

function Zone.new(container)
	local class = {}
	setmetatable(class, Zone)
	local typeName = typeof(container)

	if typeName ~= "table" and typeName ~= "Instance" then
		error("The zone container must be a model, folder, basepart or table!")
	end

	class.accuracy = enums.Accuracy.High
	class.autoUpdate = true
	class.respectUpdateQueue = true
	local janitor = Janitor.new()
	class.janitor = janitor
	class._updateConnections = janitor:add(Janitor.new(), "destroy")
	class.container = container
	class.zoneParts = {}
	class.overlapParams = {}
	class.region = nil
	class.volume = nil
	class.boundMin = nil
	class.boundMax = nil
	class.recommendedMaxParts = nil
	class.zoneId = HttpService:GenerateGUID()
	class.activeTriggers = {}
	class.occupants = {}
	class.trackingTouchedTriggers = {}
	class.enterDetection = enums.Detection.Centre
	class.exitDetection = enums.Detection.Centre
	class._currentEnterDetection = nil
	class._currentExitDetection = nil
	class.totalPartVolume = 0
	class.allZonePartsAreBlocks = true
	class.trackedItems = {}
	class.settingsGroupName = nil
	class.worldModel = workspace
	class.onItemDetails = {}
	class.itemsToUntrack = {}
	module.updateDetection(class)
	class.updated = janitor:add(Signal.new(), "destroy")
	local v2 = { "player", "part", "localPlayer", "item" }
	local v3 = { "entered", "exited" }

	for _, v4 in pairs(v2) do
		local v5 = 0
		local total = 0

		for _, v6 in pairs(v3) do
			local v7 = janitor:add(Signal.new(true), "destroy")
			local v8 = v6:sub(1, 1):upper() .. v6:sub(2)
			class[v4 .. v8] = v7
			local v9 = v4
			v7.connectionsChanged:Connect(function(p)
				if v9 == "localPlayer" and not localPlayer and p == 1 then
					error(("Can only connect to 'localPlayer%s' on the client!"):format(v8))
				end

				v5 = total
				total += p

				if v5 == 0 and total > 0 then
					module._registerConnection(class, v9, v8)
				elseif v5 > 0 and total == 0 then
					module._deregisterConnection(class, v9)
				end
			end)
		end
	end

	Zone.touchedConnectionActions = {}

	for _, v4 in pairs(v2) do
		local v5 = class[("_%sTouchedZone"):format(v4)]

		if not v5 then
			continue
		end

		class.trackingTouchedTriggers[v4] = {}

		Zone.touchedConnectionActions[v4] = function(p)
			v5(class, p)
		end
	end

	class:_update()
	module._registerZone(class)
	janitor:add(function()
		module._deregisterZone(class)
	end, true)
	return class
end

function Zone.fromRegion(p, p2)
	local model = Instance.new("Model")
	local function createCube(cframe, size)
		if size.X > 2024 or size.Y > 2024 or size.Z > 2024 then
			local v2 = size * 0.25
			local v3 = size * 0.5
			createCube(cframe * CFrame.new(-v2.X, -v2.Y, -v2.Z), v3)
			createCube(cframe * CFrame.new(-v2.X, -v2.Y, v2.Z), v3)
			createCube(cframe * CFrame.new(-v2.X, v2.Y, -v2.Z), v3)
			createCube(cframe * CFrame.new(-v2.X, v2.Y, v2.Z), v3)
			createCube(cframe * CFrame.new(v2.X, -v2.Y, -v2.Z), v3)
			createCube(cframe * CFrame.new(v2.X, -v2.Y, v2.Z), v3)
			createCube(cframe * CFrame.new(v2.X, v2.Y, -v2.Z), v3)
			createCube(cframe * CFrame.new(v2.X, v2.Y, v2.Z), v3)
		else
			local part = Instance.new("Part")
			part.CFrame = cframe
			part.Size = size
			part.Anchored = true
			part.Parent = model
		end
	end

	createCube(p, p2)
	local v2 = Zone.new(model)
	v2:relocate()
	return v2
end

function Zone:_calculateRegion(items, p)
	local v2 = { Min = {}, Max = {} }

	for k, v3 in pairs(v2) do
		v3.Values = {}
		local v4 = k

		function v3.parseCheck(p2, p3)
			if v4 == "Min" then
				return p2 <= p3
			elseif v4 == "Max" then
				return p3 <= p2
			end
		end

		function v3:parse(items2)
			for k2, item in pairs(items2) do
				local v5 = self.Values[k2] or item

				if self.parseCheck(item, v5) then
					self.Values[k2] = item
				end
			end
		end
	end

	for _, item in pairs(items) do
		local v3 = item.Size * 0.5
		local v4 = {
			item.CFrame * CFrame.new(-v3.X, -v3.Y, -v3.Z),
			item.CFrame * CFrame.new(-v3.X, -v3.Y, v3.Z),
			item.CFrame * CFrame.new(-v3.X, v3.Y, -v3.Z),
			item.CFrame * CFrame.new(-v3.X, v3.Y, v3.Z),
			item.CFrame * CFrame.new(v3.X, -v3.Y, -v3.Z),
			item.CFrame * CFrame.new(v3.X, -v3.Y, v3.Z),
			item.CFrame * CFrame.new(v3.X, v3.Y, -v3.Z),
			item.CFrame * CFrame.new(v3.X, v3.Y, v3.Z)
		}

		for _, cframe in pairs(v4) do
			local components, v5, v6 = cframe:GetComponents()
			local v7 = { components, v5, v6 }
			v2.Min:parse(v7)
			v2.Max:parse(v7)
		end
	end

	local function roundToFour(p2) -- 1 equivalent call inferred from this helper
		return math.floor((p2 + 2) / 4) * 4
	end

	local v3 = {}
	local v4 = {}

	for k, v5 in pairs(v2) do
		for _, value in pairs(v5.Values) do
			local v6 = k == "Min" and v4 or v3

			if not p then
				value = roundToFour(value + (k == "Min" and -2 or 2)) -- inferred equivalent call
			end

			table.insert(v6, value)
		end
	end

	local vector = Vector3.new(unpack(v4))
	local vector2 = Vector3.new(unpack(v3))
	return Region3.new(vector, vector2), vector, vector2
end

function Zone:_displayBounds()
	if not self.displayBoundParts then
		self.displayBoundParts = true
		local v2 = { BoundMin = self.boundMin, BoundMax = self.boundMax }

		for k, position in pairs(v2) do
			local part = Instance.new("Part")
			part.Anchored = true
			part.CanCollide = false
			part.Transparency = 0.5
			part.Size = createVector(1, 1, 1)
			part.Color = Color3.fromRGB(255, 0, 0)
			part.CFrame = CFrame.new(position)
			part.Name = k
			part.Parent = workspace
			self.janitor:add(part, "Destroy")
		end
	end
end

function Zone:_update()
	local container = self.container
	local v2 = {}
	local v3 = 0
	self._updateConnections:clean()
	local typeName = typeof(container)
	local v4 = {}

	if typeName == "table" then
		for _, part in pairs(container) do
			if part:IsA("BasePart") then
				table.insert(v2, part)
			end
		end
	elseif typeName == "Instance" then
		if container:IsA("BasePart") then
			table.insert(v2, container)
		else
			table.insert(v4, container)

			for _, part in pairs(container:GetDescendants()) do
				if part:IsA("BasePart") then
					table.insert(v2, part)
				else
					table.insert(v4, part)
				end
			end
		end
	end

	self.zoneParts = v2
	self.overlapParams = {}
	local allZonePartsAreBlocks = true

	for _, v5 in pairs(v2) do
		local v6 = v5
		local _, result = pcall(function()
			return v6.Shape.Name
		end)

		if result ~= "Block" then
			allZonePartsAreBlocks = false
		end
	end

	self.allZonePartsAreBlocks = allZonePartsAreBlocks
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.MaxParts = #v2
	overlapParams.FilterDescendantsInstances = v2
	self.overlapParams.zonePartsWhitelist = overlapParams
	local overlapParams2 = OverlapParams.new()
	overlapParams2.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams2.FilterDescendantsInstances = v2
	self.overlapParams.zonePartsIgnorelist = overlapParams2

	local function update()
		if self.autoUpdate then
			local now = os.clock()

			if self.respectUpdateQueue then
				v3 += 1
				now += 0.1
			end

			local heartbeatConnection = nil
			heartbeatConnection = RunService.Heartbeat:Connect(function()
				if now <= os.clock() then
					heartbeatConnection:Disconnect()

					if self.respectUpdateQueue then
						v3 -= 1
					end

					if v3 == 0 and self.zoneId then
						self:_update()
					end
				end
			end)
		end
	end

	local function verifyDefaultCollision(p) -- 2 equivalent calls inferred from this helper
		local collisionGroup = p.CollisionGroup

		if collisionGroup ~= "Default" and collisionGroup ~= "Debris" then
			error("Zone parts must belong to the 'Default' or 'Debris' CollisionGroup.")
		end
	end

	local v5 = { "Size", "Position" }

	for _, v6 in pairs(v2) do
		for _, propertyName in pairs(v5) do
			self._updateConnections:add(v6:GetPropertyChangedSignal(propertyName):Connect(update), "Disconnect")
		end

		verifyDefaultCollision(v6) -- inferred equivalent call
		local v7 = v6
		self._updateConnections:add(v6:GetPropertyChangedSignal("CollisionGroupId"):Connect(function()
			verifyDefaultCollision(v7) -- inferred equivalent call
		end), "Disconnect")
	end

	local v6 = { "ChildAdded", "ChildRemoved" }

	for _, _ in pairs(v4) do
		for _, v7 in pairs(v6) do
			self._updateConnections:add(self.container[v7]:Connect(function(part)
				if part:IsA("BasePart") and self.autoUpdate then
					local now = os.clock()

					if self.respectUpdateQueue then
						v3 += 1
						now += 0.1
					end

					local heartbeatConnection = nil
					heartbeatConnection = RunService.Heartbeat:Connect(function()
						if now <= os.clock() then
							heartbeatConnection:Disconnect()

							if self.respectUpdateQueue then
								v3 -= 1
							end

							if v3 == 0 and self.zoneId then
								self:_update()
							end
						end
					end)
				end
			end), "Disconnect")
		end
	end

	local region, boundMin, boundMax = self:_calculateRegion(v2)
	local region2, _, _ = self:_calculateRegion(v2, true)
	self.region = region
	self.exactRegion = region2
	self.boundMin = boundMin
	self.boundMax = boundMax
	local size = region.Size
	self.volume = size.X * size.Y * size.Z
	self:_updateTouchedConnections()
	self.updated:Fire()
end

function Zone._updateOccupants(p, p2, items)
	local occupant = p.occupants[p2]

	if not occupant then
		occupant = {}
		p.occupants[p2] = occupant
	end

	local result = {}

	for k, v2 in pairs(occupant) do
		local item = items[k]

		if not (item == nil or item ~= v2) then
			continue
		end

		occupant[k] = nil

		if not result.exited then
			result.exited = {}
		end

		table.insert(result.exited, k)
	end

	for player, _ in pairs(items) do
		if occupant[player] ~= nil then
			continue
		end

		occupant[player] = not player:IsA("Player") or (player.Character or true)

		if not result.entered then
			result.entered = {}
		end

		table.insert(result.entered, player)
	end

	return result
end

function Zone:_formTouchedConnection(p)
	local v2 = "_touchedJanitor" .. p
	local v3 = self[v2]

	if v3 then
		v3:clean()
	else
		self[v2] = self.janitor:add(Janitor.new(), "destroy")
	end

	self:_updateTouchedConnection(p)
end

function Zone:_updateTouchedConnection(p)
	local v2 = self["_touchedJanitor" .. p]

	if not v2 then
		return
	end

	for _, zonePart in pairs(self.zoneParts) do
		v2:add(zonePart.Touched:Connect(self.touchedConnectionActions[p], self), "Disconnect")
	end
end

function Zone:_updateTouchedConnections()
	for k, _ in pairs(self.touchedConnectionActions) do
		local v2 = self["_touchedJanitor" .. k]

		if not v2 then
			continue
		end

		v2:cleanup()
		self:_updateTouchedConnection(k)
	end
end

function Zone:_disconnectTouchedConnection(p)
	local v2 = "_touchedJanitor" .. p
	local v3 = self[v2]

	if v3 then
		v3:cleanup()
		self[v2] = nil
	end
end

local function round(p, p2)
	return math.round(p * 10 ^ p2) * 10 ^ (-p2)
end

function Zone:_partTouchedZone(instance)
	local part = self.trackingTouchedTriggers.part

	if part[instance] then
		return
	end

	local v2 = 0
	local flag = false
	local position = instance.Position
	local now = os.clock()
	local v3 = self.janitor:add(Janitor.new(), "destroy")
	part[instance] = v3

	if
		not ({ Seat = true, VehicleSeat = true })[instance.ClassName]
		and ({ HumanoidRootPart = true })[instance.Name]
	then
		instance.CanTouch = false
	end

	local v4 = math.round(instance.Size.X * instance.Size.Y * instance.Size.Z * 100000) * 0.00001
	self.totalPartVolume += v4
	v3:add(Heartbeat:Connect(function()
		local now2 = os.clock()

		if v2 <= now2 then
			local property = enums.Accuracy.getProperty(self.accuracy)
			v2 = now2 + property
			local v5 = self:findPoint(instance.CFrame) or self:findPart(instance)

			if flag then
				if not v5 then
					flag = false
					position = instance.Position
					now = os.clock()
					self.partExited:Fire(instance)
				end
			elseif v5 then
				flag = true
				self.partEntered:Fire(instance)
			elseif (instance.Position - position).Magnitude > 1.5 and property <= now2 - now then
				v3:cleanup()
			end
		end
	end), "Disconnect")
	v3:add(function()
		part[instance] = nil
		instance.CanTouch = true
		self.totalPartVolume = math.round((self.totalPartVolume - v4) * 100000) * 0.00001
	end, true)
end

local v2 = {
	Ball = function(p)
		return "GetPartBoundsInRadius", { p.Position, p.Size.X }
	end,
	Block = function(instance)
		return "GetPartBoundsInBox", { instance.CFrame, instance.Size }
	end,
	Other = function(p)
		return "GetPartsInPart", { p }
	end
}

function Zone:_getRegionConstructor(p, p2)
	local success, result = pcall(function()
		return p.Shape.Name
	end)
	local v3 = nil
	local v4 = nil

	if success and self.allZonePartsAreBlocks then
		local v5 = v2[result]

		if v5 then
			v3, v4 = v5(p)
		end
	end

	if not v3 then
		v4 = { p }
		v3 = "GetPartsInPart"
	end

	if p2 then
		table.insert(v4, p2)
	end

	return v3, v4
end

function Zone:findLocalPlayer()
	if not localPlayer then
		error("Can only call 'findLocalPlayer' on the client!")
	end

	return self:findPlayer(localPlayer)
end

function Zone:_find(p, p2)
	module.updateDetection(self)
	local tracker = module.trackers[p]
	local touchingZones = module.getTouchingZones(p2, false, self._currentEnterDetection, tracker)

	for _, touchingZone in pairs(touchingZones) do
		if touchingZone == self then
			return true
		end
	end

	return false
end

function Zone:findPlayer(player)
	local character = player.Character

	if character and character:FindFirstChild("HumanoidRootPart") then
		return self:_find("player", player.Character)
	end

	return false
end

function Zone:findItem(p)
	return self:_find("item", p)
end

function Zone:findPart(p)
	local regionConstructor, v3 = self:_getRegionConstructor(p, self.overlapParams.zonePartsWhitelist)
	local v4 = self.worldModel[regionConstructor](self.worldModel, unpack(v3))

	if #v4 > 0 then
		return true, v4
	end

	return false
end

function Zone:getCheckerPart()
	local checkerPart = self.checkerPart

	if not checkerPart then
		checkerPart = self.janitor:add(Instance.new("Part"), "Destroy")
		checkerPart.Size = createVector(0.1, 0.1, 0.1)
		checkerPart.Name = "ZonePlusCheckerPart"
		checkerPart.Anchored = true
		checkerPart.Transparency = 1
		checkerPart.CanCollide = false
		self.checkerPart = checkerPart
	end

	local worldModel = self.worldModel

	if worldModel == workspace then
		worldModel = module.getWorkspaceContainer()
	end

	if checkerPart.Parent ~= worldModel then
		checkerPart.Parent = worldModel
	end

	return checkerPart
end

function Zone:findPoint(cframe)
	if typeof(cframe) == "Vector3" then
		cframe = CFrame.new(cframe)
	end

	local checkerPart = self:getCheckerPart()
	checkerPart.CFrame = cframe
	local regionConstructor, v3 = self:_getRegionConstructor(checkerPart, self.overlapParams.zonePartsWhitelist)
	local v4 = self.worldModel[regionConstructor](self.worldModel, unpack(v3))

	if #v4 > 0 then
		return true, v4
	end

	return false
end

function Zone:_getAll(p)
	module.updateDetection(self)
	local result = {}
	local v3 = module._getZonesAndItems(p, { self = true }, self.volume, false, self._currentEnterDetection)[self]

	if v3 then
		for k, _ in pairs(v3) do
			table.insert(result, k)
		end
	end

	return result
end

function Zone:getPlayers()
	return self:_getAll("player")
end

function Zone:getItems()
	return self:_getAll("item")
end

function Zone:getParts()
	local result = {}

	if self.activeTriggers.part then
		local part = self.trackingTouchedTriggers.part

		for k, _ in pairs(part) do
			table.insert(result, k)
		end

		return result
	else
		local partBoundsInBox = self.worldModel:GetPartBoundsInBox(
			self.region.CFrame,
			self.region.Size,
			self.overlapParams.zonePartsIgnorelist
		)

		for _, v3 in pairs(partBoundsInBox) do
			if self:findPart(v3) then
				table.insert(result, v3)
			end
		end

		return result
	end
end

function Zone:getRandomPoint()
	local exactRegion = self.exactRegion
	local size = exactRegion.Size
	local cframe = exactRegion.CFrame
	local random = Random.new()
	local v3 = nil
	local v4, v5

	repeat
		v4 = cframe * CFrame.new(
			random:NextNumber(-size.X / 2, size.X / 2),
			random:NextNumber(-size.Y / 2, size.Y / 2),
			random:NextNumber(-size.Z / 2, size.Z / 2)
		)
		local v6
		v6, v5 = self:findPoint(v4)
		v3 = v6 and true or v3
	until v3

	return v4.Position, v5
end

function Zone:setAccuracy(p)
	local accuracy = tonumber(p)

	if accuracy then
		if not enums.Accuracy.getName(accuracy) then
			error(("%s is an invalid enumId!"):format(accuracy))
		end
	else
		accuracy = enums.Accuracy[p]

		if not accuracy then
			error(("'%s' is an invalid enumName!"):format(p))
		end
	end

	self.accuracy = accuracy
end

function Zone:setDetection(p)
	local v3 = tonumber(p)

	if v3 then
		if not enums.Detection.getName(v3) then
			error(("%s is an invalid enumId!"):format(v3))
		end
	else
		v3 = enums.Detection[p]

		if not v3 then
			error(("'%s' is an invalid enumName!"):format(p))
		end
	end

	self.enterDetection = v3
	self.exitDetection = v3
end

function Zone:trackItem(part)
	local isA = part:IsA("BasePart")
	local isCharacter

	if isA then
		isCharacter = false
	else
		isCharacter = part:FindFirstChild("HumanoidRootPart") ~= nil
	end

	assert(isA or isCharacter, "Only BaseParts or Characters/NPCs can be tracked!")

	if self.trackedItems[part] then
		return
	end

	if self.itemsToUntrack[part] then
		self.itemsToUntrack[part] = nil
	end

	local janitor = self.janitor:add(Janitor.new(), "destroy")
	local v3 = { janitor = janitor, item = part, isBasePart = isA, isCharacter = isCharacter }
	self.trackedItems[part] = v3
	janitor:add(part.AncestryChanged:Connect(function()
		if not part:IsDescendantOf(game) then
			self:untrackItem(part)
		end
	end), "Disconnect")
	local module2 = require(Tracker)
	module2.itemAdded:Fire(v3)
end

function Zone:untrackItem(p)
	local trackedItem = self.trackedItems[p]

	if trackedItem then
		trackedItem.janitor:destroy()
	end

	self.trackedItems[p] = nil
	local module2 = require(Tracker)
	module2.itemRemoved:Fire(trackedItem)
end

function Zone:bindToGroup(settingsGroupName)
	self:unbindFromGroup();
	(module.getGroup(settingsGroupName) or module.setGroup(settingsGroupName))._memberZones[self.zoneId] = self
	self.settingsGroupName = settingsGroupName
end

function Zone:unbindFromGroup()
	if self.settingsGroupName then
		local group = module.getGroup(self.settingsGroupName)

		if group then
			group._memberZones[self.zoneId] = nil
		end

		self.settingsGroupName = nil
	end
end

function Zone:relocate()
	if self.hasRelocated then
		return
	end

	local module2 = require(CollectiveWorldModel)
	local v3 = module2.setupWorldModel(self)
	self.worldModel = v3
	self.hasRelocated = true
	local parent = self.container

	if typeof(parent) == "table" then
		parent = Instance.new("Folder")

		for _, zonePart in pairs(self.zoneParts) do
			zonePart.Parent = parent
		end
	end

	self.relocationContainer = self.janitor:add(parent, "Destroy", "RelocationContainer")
	parent.Parent = v3
end

function Zone:_onItemCallback(p, p2, p3, callback)
	local onItemDetail = self.onItemDetails[p3]

	if not onItemDetail then
		onItemDetail = {}
		self.onItemDetails[p3] = onItemDetail
	end

	if #onItemDetail == 0 then
		self.itemsToUntrack[p3] = true
	end

	table.insert(onItemDetail, p3)
	self:trackItem(p3)

	local function triggerCallback() -- 2 equivalent calls inferred from this helper
		callback()

		if self.itemsToUntrack[p3] then
			self.itemsToUntrack[p3] = nil
			self:untrackItem(p3)
		end
	end

	if self:findItem(p3) == p2 then
		triggerCallback() -- inferred equivalent call
	else
		local connection = nil
		connection = self[p]:Connect(function(p4)
			if connection and p4 == p3 then
				connection:Disconnect()
				connection = nil
				triggerCallback() -- inferred equivalent call
			end
		end)
	end
end

function Zone:onItemEnter(...)
	self:_onItemCallback("itemEntered", true, ...)
end

function Zone:onItemExit(...)
	self:_onItemCallback("itemExited", false, ...)
end

function Zone:destroy()
	self:unbindFromGroup()
	self.janitor:destroy()
end

Zone.Destroy = Zone.destroy
return Zone