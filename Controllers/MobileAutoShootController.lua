local MobileAutoShootController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local FlashEffect = require(ReplicatedStorage.Components.Common.VFXLibary.FlashEffect)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local CharacterPresentationDescriptor = require(ReplicatedStorage.Components.Common.CharacterPresentationDescriptor)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local LocalPlayer = Players.LocalPlayer
local userPlatform = GetUserPlatform()
local v

if table.find(userPlatform, "Mobile") == nil then
	v = false
else
	v = #userPlatform <= 1
end

local v2 = { ["Counter-Terrorists"] = true, Terrorists = true }
local v3 = {
	CFrame.identity,
	CFrame.Angles(0.017453292519943295, 0, 0),
	CFrame.Angles(-0.017453292519943295, 0, 0),
	CFrame.Angles(0, 0.017453292519943295, 0),
	CFrame.Angles(0, -0.017453292519943295, 0),
	CFrame.Angles(0.012217304763960306, 0.012217304763960306, 0),
	CFrame.Angles(0.012217304763960306, -0.012217304763960306, 0),
	CFrame.Angles(-0.012217304763960306, 0.012217304763960306, 0),
	CFrame.Angles(-0.012217304763960306, -0.012217304763960306, 0)
}
local v4 = { UserInputType = Enum.UserInputType.Touch }
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local callback = nil
local connection = nil
local random = Random.new()
local v5 = 0
local v6 = false
local v7 = nil
local v8 = 0
local v9 = 0
local v10 = nil
local now = 0
local rounds = 0
local count = 0
local v11 = nil
local v12 = 0

local function refreshRaycastFilter(p) -- 2 equivalent calls inferred from this helper
	local filterDescendantsInstances = {}

	if p then
		table.insert(filterDescendantsInstances, p)
	end

	if Workspace.CurrentCamera then
		table.insert(filterDescendantsInstances, Workspace.CurrentCamera)
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
end

local function isEnemyTeam(team) -- 2 equivalent calls inferred from this helper
	local team2 = LocalPlayer:GetAttribute("Team")

	if v2[team2] and v2[team] then
		return Workspace:GetAttribute("Gamemode") == "Deathmatch" or team ~= team2
	end

	return false
end

local function getBotShell(parent)
	while parent and parent:IsA("Model") do
		if parent:GetAttribute("Bot") == true then
			return parent
		else
			parent = parent.Parent
		end
	end

	return nil
end

local function getEnemyCharacter(instance)
	local model = instance:FindFirstAncestorOfClass("Model")

	if not model then
		return nil
	end

	local botShell = getBotShell(model)

	if botShell then
		if botShell:GetAttribute(CharacterPresentationDescriptor.VisibleAttribute) == false then
			return nil
		end

		if CharacterResolver.isAliveCharacter(botShell) and isEnemyTeam(botShell:GetAttribute("Team")) then -- inferred equivalent call
			return botShell
		end

		return nil
	else
		if not CharacterResolver.isAliveCharacter(model) then
			return nil
		end

		local playerFromCharacter = CharacterResolver.getPlayerFromCharacter(model)

		if playerFromCharacter and isEnemyTeam(playerFromCharacter:GetAttribute("Team")) then -- inferred equivalent call
			return model
		end

		return nil
	end
end

local function clipSlab(p: number, p2: number, p3: number, p4: number, p5: number, p6: number)
	if math.abs(p2) < 0.0001 then
		if p < p3 or p4 < p then
			return 1, 0
		end

		return p5, p6
	else
		local v13 = (p3 - p) / p2
		local v14 = (p4 - p) / p2

		if v14 < v13 then
			v14, v13 = v13, v14
		end

		return math.max(p5, v13), (math.min(p6, v14))
	end
end

local function doesRayHitBox(vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3, p: number)
	local x = vector.X
	local x2 = vector2.X
	local x3 = vector3.X
	local x4 = vector4.X
	local v13

	if math.abs(x2) < 0.0001 then
		if x < x3 or x4 < x then
			p = 0
			v13 = 1
		else
			v13 = 0
		end
	else
		local v14 = (x3 - x) / x2
		local v15 = (x4 - x) / x2

		if v15 < v14 then
			v15, v14 = v14, v15
		end

		v13 = math.max(0, v14)
		p = math.min(p, v15)
	end

	if p < v13 then
		return false
	end

	local y = vector.Y
	local y2 = vector2.Y
	local y3 = vector3.Y
	local y4 = vector4.Y

	if math.abs(y2) < 0.0001 then
		if y < y3 or y4 < y then
			v13 = 1
			p = 0
		end
	else
		local v14 = (y3 - y) / y2
		local v15 = (y4 - y) / y2

		if v15 < v14 then
			v15, v14 = v14, v15
		end

		v13 = math.max(v13, v14)
		p = math.min(p, v15)
	end

	if p < v13 then
		return false
	end

	local z = vector.Z
	local z2 = vector2.Z
	local z3 = vector3.Z
	local z4 = vector4.Z

	if math.abs(z2) < 0.0001 then
		if z < z3 or z4 < z then
			v13 = 1
			p = 0
		end
	else
		local v14 = (z3 - z) / z2
		local v15 = (z4 - z) / z2

		if v15 < v14 then
			v15, v14 = v14, v15
		end

		v13 = math.max(v13, v14)
		p = math.min(p, v15)
	end

	return v13 <= p
end

local function isRayBlockedBySmoke(position: Vector3, lookVector: Vector3, distance: number)
	local debris = Workspace:FindFirstChild("Debris")

	if not debris then
		return false
	end

	for _, folder in debris:GetChildren() do
		if not (folder:IsA("Folder") and string.sub(folder.Name, 1, 11) == "VoxelSmoke_") then
			continue
		end

		for _, part in folder:GetChildren() do
			if not (part.Name == "SmokeVoxel" and part:IsA("BasePart")) then
				continue
			end

			local halfSize = part.Size / 2
			local position2 = part.Position

			if doesRayHitBox(position, lookVector, position2 - halfSize, position2 + halfSize, distance) then
				return true
			end
		end
	end

	return false
end

local function getHoveredEnemy(p: number)
	local currentCamera = Workspace.CurrentCamera

	if not (currentCamera and CharacterResolver.getLocalCharacter()) then
		return nil, 0
	end

	local cframe = currentCamera.CFrame
	local position = cframe.Position

	for _, v13 in v3 do
		local lookVector = (cframe * v13).LookVector
		local raycastResult = Workspace:Raycast(position, lookVector * p, raycastParams)
		local selected = raycastResult and getEnemyCharacter(raycastResult.Instance)

		if selected and not isRayBlockedBySmoke(position, lookVector, raycastResult.Distance) then
			return selected, raycastResult.Distance
		end
	end

	return nil, 0
end

local function pressFire(currentEquipped) -- 1 equivalent call inferred from this helper
	if not callback then
		return
	end

	v10 = currentEquipped
	now = os.clock()
	rounds = currentEquipped.Rounds
	callback(Enum.UserInputState.Begin, v4)
end

local function releaseFire() -- 4 equivalent calls inferred from this helper
	if not v10 then
		return
	end

	v10 = nil

	if callback then
		callback(Enum.UserInputState.End, v4)
	end
end

local function clearTargetState() -- 3 equivalent calls inferred from this helper
	v7 = nil
	count = 0
	v11 = nil
	v12 = 0
	v5 = 0
end

local function resetState() -- 4 equivalent calls inferred from this helper
	releaseFire() -- inferred equivalent call
	clearTargetState() -- inferred equivalent call
end

local function getBurstSize(currentEquipped, p: number) -- 1 equivalent call inferred from this helper
	if not currentEquipped.Properties.Automatic then
		return 1
	end

	if p <= 30 then
		return 1e999
	end

	if p <= 80 then
		return 4
	end

	return 2
end

local function isWeaponRecovered(currentEquipped, now2: number) -- 1 equivalent call inferred from this helper
	if not v11 or now2 - v11 >= 0.9 then
		return true
	end

	local recoil = currentEquipped.Recoil

	if recoil and recoil.Time > recoil.ActiveFireRate * 0.25 then
		return false
	end

	local spread = currentEquipped.Properties.Spread

	if not spread then
		return true
	end

	local range = spread.Range
	return currentEquipped:getBaseSpread() <= range.Min + (range.Max - range.Min) * 0.3
end

local function updatePendingPress(p, p2: number)
	if not v10 then
		return
	end

	if p and p == v10 and p.Rounds < rounds then
		releaseFire() -- inferred equivalent call
		count += 1
		v11 = p2
	elseif p ~= v10 or p2 - now > 0.5 then
		releaseFire() -- inferred equivalent call
	end
end

local function step()
	if v6 then
		return
	end

	local now2 = os.clock()
	local currentEquipped = InventoryController.getCurrentEquipped()

	if not currentEquipped or currentEquipped.Properties.Class ~= "Weapon" then
		currentEquipped = nil
	end

	if v10 then
		if currentEquipped and currentEquipped == v10 and currentEquipped.Rounds < rounds then
			releaseFire() -- inferred equivalent call
			count += 1
			v11 = now2
		elseif (currentEquipped ~= v10 or now2 - now > 0.5) and v10 then
			v10 = nil

			if callback then
				callback(Enum.UserInputState.End, v4)
			end
		end
	end

	if currentEquipped and not (currentEquipped.Rounds <= 0 or FlashEffect.IsFlashed()) then
		if not v7 and now2 < v5 then
			return
		end

		v5 = now2 + 1 / 30
		debug.profilebegin("MobileAutoShootController.Scan")
		local hoveredEnemy, v13 = getHoveredEnemy(not currentEquipped.IsAiming and 180 or currentEquipped.Properties.Range or 180)
		debug.profileend()

		if hoveredEnemy then
			v8 = now2

			if not v7 then
				v7 = now2
				v9 = random:NextNumber(0.12, 0.2)
			end

			if v10 or currentEquipped.IsShooting or now2 - v7 < v9 then
				return
			end

			if count >= getBurstSize(currentEquipped, v13) then -- inferred equivalent call
				if not isWeaponRecovered(currentEquipped, now2) then -- inferred equivalent call
					return
				end

				count = 0
				v12 = now2 + random:NextNumber(0, 0.04)
			end

			if v12 <= now2 then
				pressFire(currentEquipped) -- inferred equivalent call
			end
		elseif v7 and now2 - v8 > 0.12 then
			resetState() -- inferred equivalent call
		end
	elseif v7 then
		resetState() -- inferred equivalent call
	end
end

local function setEnabled(flag: boolean)
	if flag and not connection then
		connection = RunServiceController.BindToRenderStep("MobileAutoShootController.Step", step)
	elseif not flag and connection then
		connection:Disconnect()
		connection = nil
		resetState() -- inferred equivalent call
	end
end

function MobileAutoShootController.SetManualFireHeld(flag: boolean)
	v6 = flag

	if flag then
		v10 = nil
		clearTargetState() -- inferred equivalent call
	end
end

function MobileAutoShootController.Start()
	if not v then
		return
	end

	local Fire = require(ReplicatedStorage.Controllers.InputController.Actions.Fire)
	callback = Fire.Callback
	Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		refreshRaycastFilter(CharacterResolver.getLocalCharacter()) -- inferred equivalent call
	end)
	CharacterResolver.observeCharacter(LocalPlayer, function(p)
		refreshRaycastFilter(p) -- inferred equivalent call

		if v10 then
			v10 = nil

			if callback then
				callback(Enum.UserInputState.End, v4)
			end
		end

		clearTargetState() -- inferred equivalent call
		return function() end
	end)

	if not connection then
		connection = RunServiceController.BindToRenderStep("MobileAutoShootController.Step", step)
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.Other.Mobile Auto Shoot", function(flag: boolean?)
		local v13 = flag ~= false

		if v13 and not connection then
			connection = RunServiceController.BindToRenderStep("MobileAutoShootController.Step", step)
		elseif not v13 and connection then
			connection:Disconnect()
			connection = nil
			resetState() -- inferred equivalent call
		end

		return nil
	end)
end

return MobileAutoShootController