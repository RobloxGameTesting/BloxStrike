local createVector = vector.create
local Spectate = {}
Spectate.__index = Spectate
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local GetWeaponCameraKick = require(ReplicatedStorage.Components.Common.GetWeaponCameraKick)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local RemoveFromArray = require(ReplicatedStorage.Database.Components.Common.RemoveFromArray)
local Camera = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMuzzleFlash.Camera)
local CreateZeusBeam = require(ReplicatedStorage.Components.Common.VFXLibary.CreateZeusBeam)
local CreateTracer = require(ReplicatedStorage.Components.Common.VFXLibary.CreateTracer)
local WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent)
local Freecam = require(ReplicatedStorage.Classes.Freecam)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local Bullet = require(ReplicatedStorage.Components.Weapon.Classes.Bullet)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Spring = require(ReplicatedStorage.Shared.Spring)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Debris = workspace:WaitForChild("Debris")
local CurrentCamera = workspace.CurrentCamera
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local v = {
	["Heavy Swing"] = true,
	BackStab = true,
	Swing1 = true,
	Swing2 = true,
	Inspect = true,
	Reload = true,
	Throw = true,
	Use = true
}
local v2 = {
	NoSuppressorShoot = true,
	ShootRight = true,
	ShootLeft = true,
	Shoot = true,
	SlamFire = true
}
local v3 = { 37, 60 }
local v4 = {
	["Right Arm"] = true,
	["Left Arm"] = true,
	HumanoidRootPart = true,
	ViewmodelLight = true
}

local function isInspectVariantEvent(value: string) -- 1 equivalent call inferred from this helper
	return value == "Inspect" or string.match(value, "^Inspect%d+$") ~= nil
end

local function getTransparencyState(p, p2)
	local transparency = p.Transparencies[p2]

	if not transparency then
		transparency = { Transparency = p2.Transparency, Textures = {} }
		p.Transparencies[p2] = transparency
	end

	return transparency
end

local function cacheAndHideInstance(player, descendant)
	if descendant:IsA("BasePart") then
		local transparencyState = getTransparencyState(player, descendant)

		for _, texture in descendant:GetChildren() do
			if not texture:IsA("Texture") or table.find(transparencyState.Textures, texture) then
				continue
			end

			table.insert(transparencyState.Textures, texture)
			texture.Parent = nil
		end

		if descendant.Transparency < 1 then
			descendant.Transparency = 1
		end
	elseif descendant:IsA("Texture") then
		local parent = descendant.Parent

		if parent and parent:IsA("BasePart") then
			local transparencyState = getTransparencyState(player, parent)

			if not table.find(transparencyState.Textures, descendant) then
				table.insert(transparencyState.Textures, descendant)
			end

			descendant.Parent = nil
		end
	elseif descendant:IsA("BillboardGui") then
		descendant.Enabled = false
	end
end

local function updateSpectatedRevolverFireMode(weaponComponent, p: string) -- 1 equivalent call inferred from this helper
	if
		not weaponComponent
		or not weaponComponent.Bullet
		or weaponComponent.Properties.ShootingOptions ~= "Revolver"
	then
		return
	end

	local fireModes = weaponComponent.Properties.FireModes
	local secondary = fireModes and (p == "Secondary" and fireModes.Secondary or fireModes.Primary)
	local spread = secondary and secondary.Spread or weaponComponent.Properties.Spread
	weaponComponent.Bullet:setSpreadConfig(spread)
end

local function clearSpectatedRevolverChargeState(weaponComponent) -- 4 equivalent calls inferred from this helper
	if weaponComponent and weaponComponent.Bullet and weaponComponent.Properties.ShootingOptions == "Revolver" then
		local fireModes = weaponComponent.Properties.FireModes
		local secondary = fireModes and (fireModes.Secondary or fireModes.Primary)
		local spread = secondary and secondary.Spread or weaponComponent.Properties.Spread
		weaponComponent.Bullet:setSpreadConfig(spread)
	end

	weaponComponent.IsChargeFiring = false
	weaponComponent.ChargeStartTick = 0
end

local function syncSpectatedWeaponState(p, currentEquipped) -- 3 equivalent calls inferred from this helper
	if not p then
		return
	end

	p.IsSuppressed = currentEquipped.IsSuppressed
	p.Rounds = currentEquipped.Rounds
	p.Capacity = currentEquipped.Capacity
	p.RechargeStartTime = currentEquipped.RechargeStartTime
end

local function syncSpectatedRechargeAfterShot(weaponComponent)
	if not (weaponComponent and weaponComponent.Properties and weaponComponent.Properties.RechargeTime) then
		return
	end

	local rounds = tonumber(weaponComponent.Properties.Rounds) or 0
	weaponComponent.Rounds = math.max((tonumber(weaponComponent.Rounds) or rounds) - 1, 0)
	weaponComponent.RechargeStartTime = workspace:GetServerTimeNow()
end

local function recreateSpectatedShotEffects(player)
	local barriers = { player.Character, CurrentCamera, Debris }
	local map = workspace:FindFirstChild("Map")
	local barriers2

	if map then
		barriers2 = map:FindFirstChild("Barriers")
	end

	if barriers2 then
		table.insert(barriers, barriers2)
	end

	raycastParams.FilterDescendantsInstances = barriers
	local weaponComponent = player.WeaponComponent
	local bullet = weaponComponent and weaponComponent.Bullet

	if bullet and bullet._updateShotSpread then
		bullet:_updateShotSpread(weaponComponent.Properties.AimingOptions, weaponComponent.IsAiming)
	end

	local raycastResult = workspace:Raycast(
		CurrentCamera.CFrame.Position,
		CurrentCamera.CFrame.LookVector * player.WeaponComponent.Properties.Range,
		raycastParams
	)
	local distance = raycastResult and raycastResult.Distance or player.WeaponComponent.Properties.Range
	local muzzlePart = player.WeaponComponent.Viewmodel.Model.Interactables:FindFirstChild("MuzzlePart")

	if muzzlePart then
		CreateTracer(distance, muzzlePart.Position, CurrentCamera.CFrame.LookVector)

		if player.WeaponComponent.Properties.MuzzleType == "Zeus x27" then
			CreateZeusBeam(muzzlePart)
		end

		if DataController.Get(LocalPlayer, "Settings.Video.Presets.Muzzle Flash") ~= false then
			local properties = player.WeaponComponent.Properties
			local isSuppressed = properties.HasSuppressor and player.CurrentEquipped.IsSuppressed
			Camera(muzzlePart, isSuppressed and "Suppressor" or properties.MuzzleType)
		end
	end
end

local function getPresentedView(p) -- 2 equivalent calls inferred from this helper
	local RemoteCharacters = require(ReplicatedStorage.Controllers.CharacterController.RemoteCharacters)
	return RemoteCharacters.GetCamera(p.Player) or p.CameraPart.CFrame
end

local function destroyFreecam(p) -- 2 equivalent calls inferred from this helper
	if p.FreecamInstance then
		p.FreecamInstance:Stop()
		p.FreecamInstance:Destroy()
		p.FreecamInstance = nil
	end
end

local function destroyWeaponComponent(state) -- 4 equivalent calls inferred from this helper
	if state.Bullet then
		state.Bullet:destroy()
		state.Bullet = nil
	end

	if state.Janitor then
		state.Janitor:Destroy()
	end
end

local function destroySpectatedWeaponComponent(state)
	if state.WeaponComponent then
		destroyWeaponComponent(state.WeaponComponent) -- inferred equivalent call
		state.WeaponComponent = nil
	end

	for _, parkedWeapon in state.ParkedWeapons do
		destroyWeaponComponent(parkedWeapon) -- inferred equivalent call
	end

	table.clear(state.ParkedWeapons)
	table.clear(state.ParkedOrder)
end

local function parkSpectatedWeaponComponent(player)
	local weaponComponent = player.WeaponComponent
	player.WeaponComponent = nil
	local viewmodel = weaponComponent.Viewmodel
	local identifier = weaponComponent.Identifier

	if viewmodel and identifier and not player.ParkedWeapons[identifier] then
		clearSpectatedRevolverChargeState(weaponComponent) -- inferred equivalent call

		if weaponComponent.CharacterAnimator then
			weaponComponent.CharacterAnimator:destroy()
			weaponComponent.CharacterAnimator = nil
		end

		if viewmodel.Bobble and viewmodel.Bobble.IsAiming then
			viewmodel:unaim()
		end

		viewmodel:unequip()
		player.ParkedWeapons[identifier] = weaponComponent
		table.insert(player.ParkedOrder, identifier)

		if #player.ParkedOrder > 6 then
			local v5 = table.remove(player.ParkedOrder, 1)
			destroyWeaponComponent(player.ParkedWeapons[v5]) -- inferred equivalent call
			player.ParkedWeapons[v5] = nil
		end
	else
		destroyWeaponComponent(weaponComponent) -- inferred equivalent call
	end
end

local function takeParkedWeaponComponent(player, identifier: string) -- 1 equivalent call inferred from this helper
	local parkedWeapon = player.ParkedWeapons[identifier]

	if parkedWeapon then
		player.ParkedWeapons[identifier] = nil
		table.remove(player.ParkedOrder, (table.find(player.ParkedOrder, identifier)))
	end

	return parkedWeapon
end

function Spectate:UpdateCameraCFrame(cframe: CFrame)
	if self.CameraPositionSpring and self.CameraRotationSpring then
		if (cframe.Position - self.CameraPositionSpring:getPosition()).Magnitude > 8 then
			self.CameraRotationSpring:reset(cframe.LookVector)
			self.CameraPositionSpring:reset(cframe.Position)
		end
	else
		self.CameraRotationSpring = Spring.new(1, 35, cframe.LookVector)
		self.CameraPositionSpring = Spring.new(1, 35, cframe.Position)
	end

	self.CameraRotationSpring:setGoal(cframe.LookVector)
	self.CameraPositionSpring:setGoal(cframe.Position)
end

function Spectate:UpdateSuppressorState(p)
	local silencer = p.Viewmodel.Model:FindFirstChild("Silencer", true)

	if silencer and p.Properties.HasSuppressor then
		silencer.Transparency = self.CurrentEquipped.IsSuppressed and 0 or 1
	end
end

function Spectate:UpdateSuppressor()
	if not (self.WeaponComponent and self.WeaponComponent.Viewmodel) then
		return
	end

	local silencer = self.WeaponComponent.Viewmodel.Model:FindFirstChild("Silencer", true)

	if not silencer then
		return
	end

	local animation = self.WeaponComponent.Viewmodel.Animation
	local animation2 = animation:getAnimation("RemoveSuppressor")
	local animation3 = animation:getAnimation("AddSuppressor")
	local janitor = self.WeaponComponent.Janitor

	if janitor then
		local function connectEnded(animation4, flag: boolean) -- 2 equivalent calls inferred from this helper
			janitor:Add(animation4.Ended:Connect(function()
				if flag == (silencer.Transparency < 1) then
					silencer.Transparency = flag and 0 or 1
				end
			end))
		end

		janitor:Add(animation2:GetMarkerReachedSignal("ScrewOnEnd"):Connect(function()
			silencer.Transparency = 1
		end))
		connectEnded(animation2, false) -- inferred equivalent call
		janitor:Add(animation3:GetPropertyChangedSignal("IsPlaying"):Connect(function()
			if animation3.IsPlaying then
				task.delay(1 / 60, function()
					silencer.Transparency = 0
				end)
			end
		end))
		connectEnded(animation3, true) -- inferred equivalent call
	end

	self:UpdateSuppressorState(self.WeaponComponent)
end

function Spectate:Switch(p)
	if CharacterResolver.isAliveCharacter(self.Character) then
		self.PendingPerspective = nil
		self.PerspectiveState = p
		destroyFreecam(self) -- inferred equivalent call

		if p == "First-Person" then
			self.TransparencyState = true
			self:SetCharacterTransparency(true)
			CurrentCamera.CameraType = Enum.CameraType.Scriptable
			CurrentCamera.CameraSubject = self.CameraPart

			if self.CurrentEquipped then
				self:SetEquipped(self.CurrentEquipped, false)
			end

			self:UpdateScopeState()
			CameraController.setPerspective(true, false)
		elseif p == "Third-Person" or p == "Free-Cam" then
			self.TransparencyState = false
			self:SetCharacterTransparency(false)

			if p == "Third-Person" then
				CurrentCamera.CameraType = Enum.CameraType.Follow
				CurrentCamera.CameraSubject = self.CameraPart
			end

			destroySpectatedWeaponComponent(self)
			CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)

			if p == "Third-Person" then
				CameraController.setPerspective(false, false, 8)
			else
				local freecamInstance = self.Janitor:Add(Freecam.new())
				self.FreecamInstance = freecamInstance
				freecamInstance:Start()
			end
		end

		Remotes.Spectate.SetSpectatePerspective.Send(self.PerspectiveState)
	elseif self.Character.Parent ~= nil and not self.Character:IsDescendantOf(workspace) then
		self.PendingPerspective = p
		CurrentCamera.CameraType = Enum.CameraType.Scriptable
	end
end

function Spectate:SetEquipped(currentEquipped, flag: boolean)
	local identifier = self.WeaponComponent and self.WeaponComponent.Identifier
	self.CurrentEquipped = currentEquipped

	if identifier == currentEquipped.Identifier then
		syncSpectatedWeaponState(self.WeaponComponent, currentEquipped) -- inferred equivalent call
		self:UpdateSuppressorState(self.WeaponComponent)
	else
		if self.WeaponComponent then
			self:SetWeaponViewmodelTransparency(false)
			parkSpectatedWeaponComponent(self)
		end

		if self.PerspectiveState == "First-Person" then
			local weaponComponent = takeParkedWeaponComponent(self, currentEquipped.Identifier) -- inferred equivalent call

			if weaponComponent then
				if weaponComponent.StatTrack ~= currentEquipped.StatTrack then
					weaponComponent:updateStatTrackCounter(currentEquipped.StatTrack)
				end

				syncSpectatedWeaponState(weaponComponent, currentEquipped) -- inferred equivalent call
				self.WeaponComponent = weaponComponent
				self.TransparencyState = true
				self:SetCharacterTransparency(true)
				weaponComponent.Viewmodel:equip(not flag)

				if weaponComponent.Properties.HasSuppressor then
					self:UpdateSuppressorState(weaponComponent)
				end

				self:UpdateScopeState()
				self.CurrentEquippedChanged:Fire(self.CurrentEquipped)
				return
			else
				local success, result = pcall(function()
					local new = WeaponComponent.new
					local player = self.Player
					local identifier2 = self.CurrentEquipped.Identifier
					local id = self.CurrentEquipped._id
					local name = self.CurrentEquipped.Name
					local skin = self.CurrentEquipped.Skin
					local float = self.CurrentEquipped.Float
					local statTrack = self.CurrentEquipped.StatTrack
					local nameTag = self.CurrentEquipped.NameTag
					local originalOwner = self.CurrentEquipped.OriginalOwner
					local charm = self.CurrentEquipped.Charm
					local stickers = self.CurrentEquipped.Stickers
					local v5

					if self.IsBot then
						v5 = self.Character
					end

					return new(
						player,
						identifier2,
						id,
						1,
						name,
						skin,
						float,
						statTrack,
						nameTag,
						originalOwner,
						charm,
						stickers,
						v5
					)
				end)

				if success and result then
					if result.Properties and result.Properties.Spread then
						local bullet = Bullet.new(result, result.Properties)
						result.Bullet = bullet

						if result.Janitor then
							result.Janitor:Add(bullet, "destroy", "SpectateBullet")
						end
					end

					syncSpectatedWeaponState(result, currentEquipped) -- inferred equivalent call
					self.WeaponComponent = result
					self.TransparencyState = true
					self:SetCharacterTransparency(true)
					local viewmodel = result.Viewmodel

					if viewmodel then
						viewmodel:equip(not flag)

						if result.Properties.HasSuppressor then
							self:UpdateSuppressor()
						end
					end

					self:UpdateScopeState()
				else
					warn(`[Spectate] Failed to create viewmodel for {Participants.Name(self.Player)} ({self.CurrentEquipped.Name} | {self.CurrentEquipped.Skin}): {tostring(result)}`)
					self.TransparencyState = false

					if not pcall(function()
						self:SetCharacterTransparency(false)
					end) then
						warn("[Spectate] Failed to restore character transparency after viewmodel creation failure")
					end

					self:Switch("Third-Person")
					self.CurrentEquippedChanged:Fire(self.CurrentEquipped)
					return
				end
			end
		end

		self.CurrentEquippedChanged:Fire(self.CurrentEquipped)
	end
end

function Spectate:UpdateScopeState()
	if self.PerspectiveState ~= "First-Person" or not self.CurrentEquipped then
		return
	end

	local name = self.CurrentEquipped.Name
	local v5 = name == "AWP" or name == "SSG 08"
	local v6 = name == "AUG" or name == "SG 553"
	local v7

	if self.IsBot then
		v7 = self.Character
	else
		v7 = self.Player
	end

	local scopeIncrement = v7:GetAttribute("ScopeIncrement") or 0
	local v8 = scopeIncrement > 0
	local viewmodel = self.WeaponComponent and self.WeaponComponent.Viewmodel

	if v5 then
		local scopeReticlePart = viewmodel and viewmodel.Bobble and viewmodel.Bobble.ScopeReticlePart
		local surfaceGui = scopeReticlePart and scopeReticlePart:FindFirstChildOfClass("SurfaceGui")

		if surfaceGui then
			surfaceGui.Enabled = false
		end

		local v9 = v8 and scopeIncrement <= 2
		local updateCameraFOV = CameraController.updateCameraFOV
		local v10

		if v9 then
			v10 = Constants.DEFAULT_CAMERA_FOV - v3[scopeIncrement]
		else
			v10 = Constants.DEFAULT_CAMERA_FOV
		end

		updateCameraFOV(v10)
		self:SetWeaponViewmodelTransparency(v9)
	elseif v6 then
		if viewmodel then
			if v8 then
				if not viewmodel.Hidden then
					viewmodel:hide()
				end

				if viewmodel.Bobble and viewmodel.Bobble.Scope and viewmodel.Bobble.ScopeReticlePart then
					viewmodel:aim()
				end

				CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV - 15)
			else
				if viewmodel.Hidden then
					viewmodel:unhide()
				end

				if viewmodel.Bobble and viewmodel.Bobble.Scope and viewmodel.Bobble.ScopeReticlePart then
					viewmodel:unaim()
				end

				CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
			end
		end
	else
		CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
		self:SetWeaponViewmodelTransparency(false)
	end
end

function Spectate:SetWeaponViewmodelTransparency(flag: boolean)
	if not (self.WeaponComponent and self.WeaponComponent.Viewmodel and self.WeaponComponent.Viewmodel.Model) then
		return
	end

	local model = self.WeaponComponent.Viewmodel.Model

	if not self.WeaponTransparencyCache then
		self.WeaponTransparencyCache = {}
	end

	for _, part in ipairs(model:GetDescendants()) do
		if not part:IsA("BasePart") or v4[part.Name] then
			continue
		end

		if flag then
			if not self.WeaponTransparencyCache[part] then
				self.WeaponTransparencyCache[part] = part.Transparency
			end

			part.Transparency = 1
		else
			local transparency = self.WeaponTransparencyCache[part]

			if transparency ~= nil then
				part.Transparency = transparency
				self.WeaponTransparencyCache[part] = nil
			end
		end
	end
end

function Spectate:SetCharacterTransparency(flag: boolean)
	local descendants = self.Character:GetDescendants()

	if flag then
		self.Character:SetAttribute("SpectatedFirstPerson", true)

		if not self.TransparencyJanitor then
			local maid = self.Janitor:Add(Janitor.new())
			self.TransparencyJanitor = maid
			maid:Add(self.Character.DescendantAdded:Connect(function(descendant)
				if self.TransparencyState then
					cacheAndHideInstance(self, descendant)
				end
			end))
		end

		for _, descendant in ipairs(descendants) do
			cacheAndHideInstance(self, descendant)
		end
	else
		if self.TransparencyJanitor then
			self.TransparencyJanitor:Destroy()
			self.TransparencyJanitor = nil
		end

		for k, transparency in pairs(self.Transparencies) do
			if not (k and k.Parent) then
				continue
			end

			k.Transparency = transparency.Transparency
			local parent = k
			RemoveFromArray(transparency.Textures, function(_, p)
				p.Parent = parent
				return true
			end)
		end

		for _, billboardGui in ipairs(descendants) do
			if billboardGui:IsA("BillboardGui") then
				billboardGui.Enabled = true
			end
		end

		self.Character:SetAttribute("SpectatedFirstPerson", nil)
	end
end

function Spectate:AddSpectateEvent(value: string)
	if not (self.WeaponComponent and self.WeaponComponent.Viewmodel) then
		return
	end

	local animation = self.WeaponComponent.Viewmodel.Animation
	local weaponComponent = self.WeaponComponent

	if value == "RevolverChargeStart" then
		if weaponComponent and weaponComponent.Bullet and weaponComponent.Properties.ShootingOptions == "Revolver" then
			local fireModes = weaponComponent.Properties.FireModes
			local primary = fireModes and fireModes.Primary
			local spread = primary and primary.Spread or weaponComponent.Properties.Spread
			weaponComponent.Bullet:setSpreadConfig(spread)
		end

		weaponComponent.IsChargeFiring = true
		weaponComponent.ChargeStartTick = tick()
		animation:stopAnimations()
		animation:play("Shoot")
		animation:play("Idle")
	elseif value == "RevolverChargeCancel" then
		clearSpectatedRevolverChargeState(weaponComponent) -- inferred equivalent call
		animation:stopAnimations()
		animation:play("Idle")
	elseif value == "RevolverChargeRelease" then
		if weaponComponent and weaponComponent.Bullet and weaponComponent.Properties.ShootingOptions == "Revolver" then
			local fireModes = weaponComponent.Properties.FireModes
			local primary = fireModes and fireModes.Primary
			local spread = primary and primary.Spread or weaponComponent.Properties.Spread
			weaponComponent.Bullet:setSpreadConfig(spread)
		end

		recreateSpectatedShotEffects(self)
		clearSpectatedRevolverChargeState(weaponComponent) -- inferred equivalent call
	elseif v2[value] then
		if self.IsBot then
			local cameraShake = weaponComponent.Viewmodel.Model:FindFirstChild("CameraShake")

			if cameraShake then
				local v5, v6 = GetWeaponCameraKick(cameraShake)
				self.KickRotationSpring:setDampingRatio(v5.Damper)
				self.KickRotationSpring:setFrequency(v5.Speed)
				self.KickRotationSpring:setPosition(v5.Value * 0.017453292519943295)
				self.KickPositionSpring:setDampingRatio(v6.Damper)
				self.KickPositionSpring:setFrequency(v6.Speed)
				self.KickPositionSpring:setPosition(v6.Value)
			end

			weaponComponent.Viewmodel.Bobble:addScopeKick()
		end

		if weaponComponent.Properties.ShootingOptions == "Revolver" then
			local v5 = value == "SlamFire" and "Secondary" or "Primary"
			updateSpectatedRevolverFireMode(weaponComponent, v5) -- inferred equivalent call

			if
				v5 == "Secondary"
				and weaponComponent
				and weaponComponent.Bullet
				and weaponComponent.Properties.ShootingOptions == "Revolver"
			then
				local fireModes = weaponComponent.Properties.FireModes
				local secondary = fireModes and (fireModes.Secondary or fireModes.Primary)
				local spread = secondary and secondary.Spread or weaponComponent.Properties.Spread
				weaponComponent.Bullet:setSpreadConfig(spread)
			end

			weaponComponent.IsChargeFiring = false
			weaponComponent.ChargeStartTick = 0
		end

		syncSpectatedRechargeAfterShot(weaponComponent)
		local v5 = not animation:getAnimation(value) and "Shoot" or value
		animation:stopAnimations()
		animation:play(v5)
		animation:play("Idle")
		recreateSpectatedShotEffects(self)

		if weaponComponent.Properties.ShootingOptions == "Revolver" and value ~= "SlamFire" then
			clearSpectatedRevolverChargeState(weaponComponent) -- inferred equivalent call
		end
	elseif value == "Remove Suppressor" or value == "Add Suppressor" then
		animation:stopAnimations()
		animation:play(string.gsub(value, " ", ""))
		animation:play("Idle")
	elseif value == "Switch Fire Mode" then
		animation:stopAnimations()
		animation:play("Switch")
		animation:play("Idle")
	elseif value == "StartThrow" then
		animation:stopAnimations()
		animation:play("StartThrow")
		local v5 = animation:play("ThrowIdle")

		if v5 then
			v5.Looped = true
		end
	elseif value == "Cancel Plant" or value == "CancelThrow" then
		animation:stopAnimations()
		animation:play("Idle")
	elseif value == "ReloadStart" or value == "ReloadEnd" then
		if animation:getAnimation(value) then
			animation:stopAnimations()
			animation:play(value)
			animation:play("Idle")
		end
	elseif v[value] or value == "Inspect" or string.match(value, "^Inspect%d+$") ~= nil then
		local v5 = isInspectVariantEvent(value) and not animation:getAnimation(value) and "Inspect" or value -- inferred equivalent call
		local v6 = value == "Reload"
			and not animation:getAnimation("Reload")
			and animation:getAnimation("ReloadAction")
			and "ReloadAction"
			or v5
		animation:stopAnimations()
		animation:play(v6)
		animation:play("Idle")
	end
end

local function updateSpectatorAutomaticScope(player, p: number)
	if player.PerspectiveState ~= "First-Person" or not player.CurrentEquipped then
		return
	end

	local name = player.CurrentEquipped.Name

	if name ~= "AUG" and name ~= "SG 553" then
		return
	end

	local v5

	if player.IsBot then
		v5 = player.Character
	else
		v5 = player.Player
	end

	if (v5:GetAttribute("ScopeIncrement") or 0) <= 0 then
		return
	end

	local weaponComponent = player.WeaponComponent
	local viewmodel = weaponComponent and weaponComponent.Viewmodel

	if not (viewmodel and viewmodel.Bobble and viewmodel.Bobble.IsAiming and weaponComponent.Bullet) then
		return
	end

	local lastSpreadValue = weaponComponent.Bullet:getBaseSpread() or 0
	local v6 = math.abs(lastSpreadValue - (player.LastSpreadValue or 0))
	local lastScopeUpdateTime = (player.LastScopeUpdateTime or 0) + p

	if v6 < 0.01 and lastScopeUpdateTime < 1 / 30 then
		player.LastScopeUpdateTime = lastScopeUpdateTime
		return
	end

	player.LastScopeUpdateTime = 0
	player.LastSpreadValue = lastSpreadValue
	local scopeReticlePart = viewmodel.Bobble.ScopeReticlePart
	local surfaceGui = scopeReticlePart and scopeReticlePart:FindFirstChildOfClass("SurfaceGui")
	local surfaceGuiFrame = surfaceGui and surfaceGui:FindFirstChild("Frame")
	local frame = surfaceGuiFrame and surfaceGuiFrame:FindFirstChild("Frame")

	if frame then
		local v7 = math.clamp(lastSpreadValue, 0, 2) * 2
		frame.Size = UDim2.fromScale(v7 + 2.5, v7 + 2.5)
		frame.Position = UDim2.fromScale(0.5, 0.5)
	end
end

function Spectate:Render(p: number, cframe: CFrame?)
	if self.PerspectiveState == "Free-Cam" then
		return
	end

	if not cframe and self.IsBot then
		local BotCharacters = require(ReplicatedStorage.Controllers.CharacterController.BotCharacters)
		local actorId = self.Character:GetAttribute("ActorId")
		local v5 = CharacterGeneration.Get(self.Character)

		if type(actorId) == "number" and v5 then
			cframe = BotCharacters.GetCamera(actorId, v5)
		end
	end

	if not (cframe or self.IsBot or self.HasRemoteCamera) then
		local RemoteCharacters = require(ReplicatedStorage.Controllers.CharacterController.RemoteCharacters)
		cframe = RemoteCharacters.GetCamera(self.Player)
	end

	if cframe then
		self:UpdateCameraCFrame(cframe)
	end

	if self.CameraPositionSpring and self.CameraRotationSpring then
		self.CameraPositionSpring:update(p)
		self.CameraRotationSpring:update(p)

		if self.PerspectiveState == "First-Person" then
			CurrentCamera.CFrame = CFrame.lookAt(
				self.CameraPositionSpring:getPosition(),
				self.CameraPositionSpring:getPosition() + self.CameraRotationSpring:getPosition()
			)

			if cframe then
				CurrentCamera.CFrame = cframe
			end

			if self.IsBot then
				self.KickRotationSpring:update(p)
				self.KickPositionSpring:update(p)
				local position = self.KickRotationSpring:getPosition()
				CurrentCamera.CFrame *= CFrame.new(self.KickPositionSpring:getPosition()) * CFrame.Angles(position.X, position.Y, position.Z)
				CurrentCamera.FieldOfView = CameraController.getTargetFOV()
			end

			if self.WeaponComponent and self.WeaponComponent.Viewmodel then
				self.WeaponComponent.Viewmodel:render(p)
			end

			local weaponComponent = self.WeaponComponent

			if weaponComponent and weaponComponent.Bullet and weaponComponent.Bullet.updateSpread then
				weaponComponent.Bullet:updateSpread(p)
			end

			updateSpectatorAutomaticScope(self, p)
		end
	end
end

function Spectate.new(player, character, value, flag: boolean?)
	local object = setmetatable({}, Spectate)
	local resolved = CharacterResolver.resolve(character)
	assert(resolved, `[Spectate] Invalid player character rig for {Participants.Name(player)}`)
	local perspectiveState = value or "First-Person"
	object.Janitor = Janitor.new()
	object.CurrentEquippedChanged = object.Janitor:Add(Signal.new())
	object.StopSpectating = object.Janitor:Add(Signal.new())
	object.RootPart = resolved.RootPart
	object.CameraPart = resolved.CameraPart
	object.Character = character
	object.Player = player
	object.IsBot = flag == true
	object.KickRotationSpring = Spring.new(1, 1, createVector(0, 0, 0))
	object.KickPositionSpring = Spring.new(1, 1, createVector(0, 0, 0))
	object.PerspectiveState = perspectiveState
	object.TransparencyState = perspectiveState == "First-Person"
	object.Transparencies = {}
	object.WeaponTransparencyCache = {}
	object.ParkedWeapons = {}
	object.ParkedOrder = {}
	object.LastScopeUpdateTime = 0
	object.LastSpreadValue = 0
	object:SetCharacterTransparency(object.TransparencyState)
	object:Switch(object.PerspectiveState)

	if
		not object.IsBot
		and object.PerspectiveState == "First-Person"
		and object.Character:IsDescendantOf(workspace)
	then
		CurrentCamera.CFrame = getPresentedView(object) -- inferred equivalent call
	end

	LocalPlayer.ReplicationFocus = object.RootPart
	object.Janitor:Add(function()
		LocalPlayer.ReplicationFocus = nil
	end)

	if object.Player:GetAttribute("CurrentEquipped") then
		object:SetEquipped(HttpService:JSONDecode((object.Player:GetAttribute("CurrentEquipped"))), false)
	end

	object.Janitor:Add(object.Player:GetAttributeChangedSignal("CurrentEquipped"):Connect(function()
		local currentEquipped = object.Player:GetAttribute("CurrentEquipped")

		if currentEquipped then
			object:SetEquipped(HttpService:JSONDecode(currentEquipped), true)
			task.defer(function()
				if object.TransparencyState and object.PerspectiveState == "First-Person" then
					object:SetCharacterTransparency(true)
				end
			end)
		end
	end))

	if object.IsBot then
		local BotCharacters = require(ReplicatedStorage.Controllers.CharacterController.BotCharacters)
		object.Janitor:Add(BotCharacters.CombatEvent:Connect(function(p)
			if p.ActorId == object.Character:GetAttribute("ActorId") then
				object:AddSpectateEvent(p.Kind == "Shoot" and "Shoot" or p.Kind)
			end
		end))
		object.Janitor:Add(object.Player:GetAttributeChangedSignal("ObjectiveAction"):Connect(function()
			object:AddSpectateEvent(object.Player:GetAttribute("ObjectiveAction") == "Planting" and "Use" or "Cancel Plant")
		end))
	else
		object.Janitor:Add(Remotes.Spectate.UpdateCameraCFrame.Listen(function(p)
			if p.UserId ~= object.Player.UserId then
				return
			end

			object.HasRemoteCamera = true
			object:UpdateCameraCFrame(p.CameraCFrame)
		end))

		if object.Player:GetAttribute("ScopeIncrement") then
			object:UpdateScopeState()
		end

		object.Janitor:Add(object.Player:GetAttributeChangedSignal("ScopeIncrement"):Connect(function()
			object:UpdateScopeState()
		end))
	end

	local function stopSpectating() -- 4 equivalent calls inferred from this helper
		object.StopSpectating:Fire()
	end

	if CharacterResolver.getHealth(object.Character) <= 0 then
		task.defer(stopSpectating)
	end

	object.Janitor:Add(object.Character:GetAttributeChangedSignal("Health"):Connect(function()
		if CharacterResolver.getHealth(object.Character) <= 0 then
			stopSpectating() -- inferred equivalent call
		end
	end))

	if object.Character:GetAttribute("Dead") then
		task.defer(stopSpectating)
	end

	object.Janitor:Add(object.Character:GetAttributeChangedSignal("Dead"):Connect(function()
		if object.Character:GetAttribute("Dead") then
			stopSpectating() -- inferred equivalent call
		end
	end))
	object.Janitor:Add(Remotes.UI.UIPlayerKilled.Listen(function(p)
		local victim = p.Victim

		if victim and tostring(Participants.Key(object.Player)) == victim then
			stopSpectating() -- inferred equivalent call
		end
	end))
	object.Janitor:Add(object.Character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			stopSpectating() -- inferred equivalent call
			return
		end

		local pendingPerspective = object.PendingPerspective

		if pendingPerspective and object.Character:IsDescendantOf(workspace) then
			object:Switch(pendingPerspective)

			if pendingPerspective == "First-Person" and not (object.IsBot or object.CameraPositionSpring) then
				CurrentCamera.CFrame = getPresentedView(object) -- inferred equivalent call
			end
		end
	end))
	object.Janitor:Add(function()
		object.TransparencyState = false

		if object.Character:GetAttribute("Dead") ~= false or CharacterResolver.getHealth(object.Character) <= 0 then
			Ragdoll.HideCharacterLocally(object.Character)
			object.Character:SetAttribute("SpectatedFirstPerson", nil)
		elseif next(object.Transparencies) ~= nil then
			object:SetCharacterTransparency(false)
		end

		CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	end)
	object.Janitor:Add(function()
		destroySpectatedWeaponComponent(object)
	end)
	object.Janitor:Add(function()
		destroyFreecam(object) -- inferred equivalent call
	end)
	return object
end

function Spectate.newBot(p, instance, p2)
	assert(instance:GetAttribute("Bot") == true, "Expected a bot presentation")
	return Spectate.new(p, instance, p2, true)
end

function Spectate:Destroy()
	self.Janitor:Destroy()
end

return Spectate