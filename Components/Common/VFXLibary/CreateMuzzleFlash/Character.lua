local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local CreateZeusBeam = require(ReplicatedStorage.Components.Common.VFXLibary.CreateZeusBeam)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local ClientCharacterPresentation = require(ReplicatedStorage.Components.Common.ClientCharacterPresentation)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local EmitParticles = require(script.Parent.EmitParticles)

local function executeMuzzleFlash(muzzlePart, childName: string)
	debug.profilebegin("VFX.MuzzleFlash.Character.Execute")
	local child = muzzlePart:FindFirstChild(childName)

	if not child then
		debug.profileend()
		return nil
	end

	debug.profilebegin("VFX.MuzzleFlash.Character.EmitParticles")
	EmitParticles(child)
	debug.profileend()
	debug.profileend()
	return muzzlePart.Position
end

local function dlog(p: string, ...)
	if not DebugFlags.IsEnabled("WeaponFX") then
		return
	end

	warn(("[WeaponFX][MuzzleFlash.Character] " .. p):format(...))
end

local function findTutorialDummy(p: number)
	if not IsTutorialMode() then
		return nil
	end

	for _, folder in workspace:GetChildren() do
		if not (folder:IsA("Folder") and string.sub(folder.Name, 1, 8) == "Tutorial") then
			continue
		end

		for _, model in folder:GetChildren() do
			if
				model:IsA("Model")
				and model:GetAttribute("TutorialDummy") == true
				and model:GetAttribute("DummyUserId") == p
			then
				return model
			end
		end
	end

	return nil
end

local function findDummyWeaponModel(instance, childName: string)
	local model = instance:FindFirstChild(childName)

	if model and model:IsA("Model") then
		return model
	end

	for _, model2 in instance:GetChildren() do
		if model2:IsA("Model") and model2:FindFirstChild("Interactables") then
			return model2
		end
	end

	return nil
end

local function tryCreate(p: number, p2: number, p3: string, p4: string, p5: string?, flag: boolean?)
	debug.profilebegin("VFX.MuzzleFlash.Character.TryCreate")
	local playerByUserId = Players:GetPlayerByUserId(p)
	local v

	if not playerByUserId then
		v = findTutorialDummy(p)
	end

	if playerByUserId or v then
		local name

		if playerByUserId then
			name = playerByUserId.Name
		else
			name = v.Name
		end

		debug.profilebegin("VFX.MuzzleFlash.Character.TryCreate.GetWeaponProperties")
		local weaponProperties = GetWeaponProperties(p3)
		debug.profileend()

		if weaponProperties then
			debug.profilebegin("VFX.MuzzleFlash.Character.TryCreate.FindWeaponModel")
			local equipped

			if playerByUserId then
				local v2 = ClientCharacterPresentation.Create(playerByUserId, p2)

				if v2 and CharacterGeneration.Matches(v2, p2) then
					local weaponModel = v2:FindFirstChild("WeaponModel")
					equipped = weaponModel and weaponModel:FindFirstChild("Equipped")

					if not (equipped and equipped:IsA("Model")) then
						equipped = nil
					end
				else
					dlog("presentation missing player=%s generation=%s weapon=%s", name, tostring(p2), (tostring(p3)))
					debug.profileend()
					debug.profileend()
					return
				end
			else
				equipped = findDummyWeaponModel(v, p3)
			end

			debug.profileend()

			if equipped then
				debug.profilebegin("VFX.MuzzleFlash.Character.TryCreate.FindMuzzlePart")
				local interactables = equipped:FindFirstChild("Interactables")

				if interactables then
					local muzzlePart = interactables:FindFirstChild("MuzzlePart")

					if weaponProperties.ShootingOptions == "Dual" then
						muzzlePart = interactables:FindFirstChild("MuzzlePart" .. (p4 == "Left" and "L" or "R"))
					end

					if muzzlePart then
						debug.profileend()

						if weaponProperties.MuzzleType == "Zeus x27" then
							debug.profilebegin("VFX.MuzzleFlash.Character.CreateZeusBeam")
							CreateZeusBeam(muzzlePart)
							debug.profileend()
						end

						if flag then
							debug.profileend()
							return
						end

						local v2 = p5 or weaponProperties.MuzzleType

						if not v2 then
							debug.profileend()
							return
						end

						if not executeMuzzleFlash(muzzlePart, v2) then
							dlog(
								"executeMuzzleFlash failed player=%s weapon=%s override=%s",
								name,
								tostring(p3),
								(tostring(p5))
							)
						end

						debug.profileend()
					else
						dlog(
							"missing muzzle part player=%s weapon=%s shootingHand=%s",
							name,
							tostring(p3),
							(tostring(p4))
						)
						debug.profileend()
						debug.profileend()
					end
				else
					dlog("missing Interactables player=%s weapon=%s", name, (tostring(p3)))
					debug.profileend()
					debug.profileend()
				end
			else
				dlog("missing equipped presentation player=%s weapon=%s", name, (tostring(p3)))
				debug.profileend()
			end
		else
			dlog("weapon properties missing player=%s weapon=%s", name, (tostring(p3)))
			debug.profileend()
		end
	else
		dlog("player not found userId=%s weapon=%s", tostring(p), (tostring(p3)))
		debug.profileend()
	end
end

return tryCreate