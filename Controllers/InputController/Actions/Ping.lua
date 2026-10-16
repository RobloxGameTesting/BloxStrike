local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera
local now = 0
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = false

local function GetWeaponDataFromInstance(parent)
	while parent do
		if CollectionService:HasTag(parent, "WeaponDropped") then
			local weapon = parent:GetAttribute("Weapon")
			local skin = parent:GetAttribute("Skin")

			if weapon and skin then
				return weapon, skin, parent.Name
			else
				break
			end
		else
			parent = parent.Parent
		end
	end

	return nil, nil, nil
end

local function GetRaycastResult(...)
	local instances = { CurrentCamera, ... }
	raycastParams.FilterDescendantsInstances = instances
	local raycastResult = workspace:Raycast(
		CurrentCamera.CFrame.Position,
		CurrentCamera.CFrame.LookVector * 1000,
		raycastParams
	)

	while raycastResult and raycastResult.Instance do
		local instance = raycastResult.Instance

		if not instance:IsA("BasePart") or instance.Transparency <= 0.98 then
			break
		end

		table.insert(instances, instance)
		raycastParams.FilterDescendantsInstances = instances
		raycastResult = workspace:Raycast(
			raycastResult.Position,
			CurrentCamera.CFrame.LookVector.Unit * (1000 - raycastResult.Distance),
			raycastParams
		)
	end

	return raycastResult
end

local function onInput(p)
	if not (workspace:GetAttribute("Gamemode") ~= "Deathmatch" and DataController.Get(
		LocalPlayer,
		"Settings.Game.HUD.Player Pings"
	) ~= "Disabled") then
		return
	end

	if
		not CharacterResolver.isAliveCharacter(CharacterResolver.getPlayerCharacter(LocalPlayer))
		or p ~= Enum.UserInputState.Begin
	then
		return
	end

	local raycastResult = GetRaycastResult(CharacterResolver.getLocalCharacter())

	if not raycastResult then
		return
	end

	local weaponName, weaponSkin, weaponIdentity = GetWeaponDataFromInstance(raycastResult.Instance)

	if weaponName and weaponSkin and weaponIdentity then
		Remotes.Ping.CreatePlayerPositionPing.Send({
			Position = raycastResult.Position,
			WeaponIdentity = weaponIdentity,
			WeaponName = weaponName,
			WeaponSkin = weaponSkin,
			IsDanger = false
		})
	else
		Remotes.Ping.CreatePlayerPositionPing.Send({
			IsDanger = tick() - now < 0.5,
			Position = raycastResult.Position
		})
	end

	now = tick()
end

return table.freeze({ Name = "Ping", Group = "Gameplay", Category = "UI Keys", Callback = onInput })