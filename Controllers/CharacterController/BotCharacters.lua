local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Common = ReplicatedStorage.Components.Common
local BotPresentationState = require(Common.BotPresentationState)
local BotWeaponModel = require(Common.BotWeaponModel)
local BotWeaponEffects = require(Common.BotWeaponEffects)
local BotWeaponRecoil = require(Common.BotWeaponRecoil)
local CharacterGeneration = require(Common.CharacterGeneration)
local CharacterPose = require(Common.CharacterPose)
local CharacterResolver = require(Common.CharacterResolver)
local ClientCharacterPresentation = require(Common.ClientCharacterPresentation)
local CharacterPresentationDescriptor = require(Common.CharacterPresentationDescriptor)
local CharacterAnimator = require(ReplicatedStorage.Classes.Character.Classes.CharacterAnimator)
local RootFrame = require(ReplicatedStorage.MovementV2.RootFrame)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local BotCombatCodec = require(ReplicatedStorage.MovementV2.BotCombatCodec)
local Transport = require(ReplicatedStorage.MovementV2.Transport)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Defuser = require(ReplicatedStorage.Controllers.Observers.Character.Components.Defuser)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local BotCharacters = { CombatEvent = Signal.new() }
local v = {}
local v2 = {}
local v3 = {}
local roots = {}
local v4 = {}
local v5 = {}
local v6 = {}
local v7 = {}
local v8 = {}
local v9 = 0
local flag = false
local maid = nil
local v10 = nil
local v11 = {}
local v12 = {}
local v13 = {}

local function destroyShell(data)
	BotWeaponModel.destroy(data.Weapon)
	BotWeaponModel.clear(data.Shell)
	RuntimeKinematics.clear(data.Shell)

	if data.Defuser then
		data.Defuser:Destroy()
	end

	data.Animator:destroy()
	data.Shell:Destroy()
end

local function releaseCorpseSource(p: number, p2)
	local v14 = v12[p]

	if v14 == nil or p2 ~= nil and v14 ~= p2 then
		return
	end

	v12[p] = nil
	destroyShell(v14)
end

local function destroyEntry(p) -- 2 equivalent calls inferred from this helper
	local entry = p.Entry

	if entry ~= nil then
		p.Entry = nil
		destroyShell(entry)
	end
end

local function hide(state)
	if state.Visible then
		state.Visible = false
		state.Shell:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, false)
		state.Animator:stopAnimations(0)
		RuntimeKinematics.clear(state.Shell)
		state.LastPosition = nil
	end

	state.Shell.Parent = ClientCharacterPresentation.GetCulledFolder()
end

local function cullCorpseShell(entry) -- 2 equivalent calls inferred from this helper
	BotWeaponModel.destroy(entry.Weapon)
	BotWeaponModel.clear(entry.Shell)
	entry.Weapon = nil

	if entry.Defuser then
		entry.Defuser:Destroy()
		entry.Defuser = nil
	end

	hide(entry)
end

local function retireToCorpse(p)
	local entry = p.Entry

	if entry == nil then
		return
	end

	p.Entry = nil
	p.CorpseGeneration = entry.Descriptor.Generation
	entry.Shell:SetAttribute("Health", 0)
	entry.Shell:SetAttribute("Dead", true)

	if entry.Visible then
		entry.Shell:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, false)
		entry.Animator:freezeAnimations()
		RuntimeKinematics.clear(entry.Shell)

		for _, part in entry.Shell:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanQuery = false
			end
		end

		task.delay(1.5, function()
			if entry.Shell.Parent ~= nil then
				cullCorpseShell(entry) -- inferred equivalent call
			end
		end)
	else
		cullCorpseShell(entry) -- inferred equivalent call
	end

	local v14 = v11[entry.Descriptor.CombatantId]

	if v14 then
		destroyShell(v14.Entry)
	end

	v11[entry.Descriptor.CombatantId] = {
		Entry = entry,
		Generation = entry.Descriptor.Generation,
		ExpiresAt = os.clock() + 1.5
	}
end

local function releaseEntry(p, p2) -- 2 equivalent calls inferred from this helper
	if p.Entry ~= nil and p2 ~= nil and (p2.Dead or p2.Health <= 0) then
		retireToCorpse(p)
		return
	end

	destroyEntry(p) -- inferred equivalent call
end

local function readDescriptor(instance)
	local weaponName = instance:GetAttribute("WeaponName")
	local weaponRevision = instance:GetAttribute("WeaponRevision")
	local objectiveAction = instance:GetAttribute("ObjectiveAction")
	local v14 = {
		BotLoadout = instance:GetAttribute("BotLoadout"),
		CombatantId = instance:GetAttribute("CombatantId"),
		ActorId = instance:GetAttribute("ActorId"),
		Generation = instance:GetAttribute("Generation"),
		DisplayName = instance:GetAttribute("DisplayName"),
		Team = instance:GetAttribute("Team"),
		CharacterName = instance:GetAttribute("CharacterName"),
		Health = instance:GetAttribute("Health"),
		MaxHealth = instance:GetAttribute("MaxHealth"),
		Dead = instance:GetAttribute("Dead"),
		ObjectiveAction = 0,
		WeaponName = 0,
		WeaponRevision = 0
	}

	if objectiveAction ~= "Planting" and objectiveAction ~= "Defusing" then
		objectiveAction = nil
	end

	v14.ObjectiveAction = objectiveAction
	v14.WeaponName = (type(weaponName) ~= "string" or not (#weaponName <= 48)) and "" or weaponName
	v14.WeaponRevision = (type(weaponRevision) ~= "number" or not (weaponRevision >= 0) or not (weaponRevision <= 4294967295) or weaponRevision % 1 ~= 0)
		and 0
		or weaponRevision

	if BotPresentationState.validate(v14) and instance.Name == tostring(v14.CombatantId) then
		return v14
	end

	return nil
end

local function refresh(folder, state)
	local descriptor2 = readDescriptor(folder)
	local descriptor = state.Descriptor

	if descriptor ~= nil and v2[descriptor.ActorId] == state then
		v2[descriptor.ActorId] = nil
	end

	if descriptor2 ~= nil then
		v2[descriptor2.ActorId] = state

		if descriptor == nil or not BotPresentationState.sameLife(descriptor, descriptor2) then
			state.LastEventSequence = nil
		end
	end

	local entry = state.Entry

	if entry ~= nil then
		if
			descriptor2 == nil
			or not BotPresentationState.sameLife(entry.Descriptor, descriptor2)
			or entry.Descriptor.CharacterName ~= descriptor2.CharacterName
			or entry.Descriptor.BotLoadout ~= descriptor2.BotLoadout
			or BotPresentationState.decide(descriptor2, nil) == "Destroy"
		then
			releaseEntry(state, descriptor2) -- inferred equivalent call
		else
			entry.Descriptor = descriptor2
			entry.Shell.Name = descriptor2.DisplayName
			entry.Shell:SetAttribute("Team", descriptor2.Team)
			entry.Shell:SetAttribute("Health", descriptor2.Health)
			entry.Shell:SetAttribute("MaxHealth", descriptor2.MaxHealth)
		end
	end

	if descriptor ~= nil and (descriptor2 == nil or not BotPresentationState.sameLife(descriptor, descriptor2)) then
		state.LastDescriptor = descriptor
	end

	state.Descriptor = descriptor2
end

local function untrack(k) -- 2 equivalent calls inferred from this helper
	local v14 = v[k]

	if v14 == nil then
		return
	end

	v[k] = nil
	local descriptor = v14.Descriptor

	if descriptor ~= nil and v2[descriptor.ActorId] == v14 then
		v2[descriptor.ActorId] = nil
	end

	v14.Descriptor = nil
	v14.Janitor:Destroy()
	destroyEntry(v14) -- inferred equivalent call
end

local function track(folder)
	if not folder:IsA("Folder") or v[folder] ~= nil then
		return
	end

	local v14 = {
		Folder = folder,
		Descriptor = nil,
		Entry = nil,
		Janitor = Janitor.new(),
		LastEventSequence = nil
	}
	v[folder] = v14
	v14.Janitor:Add(folder.AttributeChanged:Connect(function()
		refresh(folder, v14)
	end))
	refresh(folder, v14)
end

local function bindFolder(folder)
	if folder == v10 or not folder:IsA("Folder") then
		return
	end

	if maid ~= nil then
		maid:Destroy()
	end

	for k in v do
		untrack(k) -- inferred equivalent call
	end

	v10 = folder
	maid = Janitor.new()
	maid:Add(folder.ChildAdded:Connect(track))
	maid:Add(folder.ChildRemoved:Connect(untrack))
	maid:Add(folder.AncestryChanged:Connect(function()
		if folder.Parent ~= ReplicatedStorage then
			for k in v do
				untrack(k) -- inferred equivalent call
			end

			v10 = nil
			maid:Destroy()
			maid = nil
		end
	end))

	for _, child in folder:GetChildren() do
		track(child)
	end
end

function BotCharacters.Initialize()
	if flag then
		return
	end

	flag = true
	Transport.getClientChannels().BotCombat.OnClientEvent:Connect(function(p)
		local decoded = BotCombatCodec.decode(p)

		if decoded ~= nil then
			BotCharacters.PresentCombatEvents(decoded)
		end
	end)
	ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "Combatants" then
			bindFolder(child)
		end
	end)
	local combatants = ReplicatedStorage:FindFirstChild("Combatants")

	if combatants ~= nil then
		bindFolder(combatants)
	end
end

local function poseRootCFrame(renderPose) -- 1 equivalent call inferred from this helper
	local visualRootPosition = renderPose.VisualRootPosition
		or RootFrame.simulationToVisualRootPosition(renderPose.Position, renderPose.DuckAmount)
	return CharacterPose.composeRootCFrame(visualRootPosition, renderPose.LookYaw)
end

local function createEntry(folder, descriptor, cframe: CFrame)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local characters

	if assets ~= nil then
		characters = assets:FindFirstChild("Characters")
	end

	local model

	if characters ~= nil then
		model = characters:FindFirstChild(descriptor.CharacterName)
	end

	if model == nil or not model:IsA("Model") then
		return nil
	end

	local clone = model:Clone()
	clone.Name = descriptor.DisplayName
	clone:SetAttribute("CharacterType", "PlayerCustomCharacter")
	clone:SetAttribute("CharacterName", descriptor.CharacterName)
	clone:SetAttribute("Bot", true)
	clone:SetAttribute("CombatantId", descriptor.CombatantId)
	clone:SetAttribute("ActorId", descriptor.ActorId)
	clone:SetAttribute("Team", descriptor.Team)
	clone:SetAttribute("Health", descriptor.Health)
	clone:SetAttribute("MaxHealth", descriptor.MaxHealth)
	clone:SetAttribute("Dead", false)
	clone:SetAttribute(CharacterPresentationDescriptor.OwnedAttribute, true)
	clone:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, true)
	CharacterGeneration.Set(clone, descriptor.Generation)
	ClientCharacterPresentation.PrepareRuntimeRig(clone)

	if descriptor.BotLoadout then
		local jsonDecode = HttpService:JSONDecode(descriptor.BotLoadout)
		clone:SetAttribute("BotLoadout", descriptor.BotLoadout)

		if jsonDecode.Gloves then
			local gloves = jsonDecode.Gloves
			clone:SetAttribute("EquippedGloves", HttpService:JSONEncode(gloves))
			local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
			local gloves2 = Skins.GetGloves(gloves.Name, gloves.Skin, gloves.Float)

			if gloves2 then
				local AttachGlovesToCharacter = require(ReplicatedStorage.Database.Components.Common.AttachGlovesToCharacter)
				AttachGlovesToCharacter(gloves2:GetChildren(), clone, clone:FindFirstChild("CharacterArmor") or clone)
				gloves2:Destroy()
			end
		end
	end

	local resolved = CharacterResolver.resolve(clone)

	if resolved == nil then
		clone:Destroy()
		return nil
	end

	clone:PivotTo(cframe * resolved.RootPart.CFrame:ToObjectSpace(clone:GetPivot()))
	clone.Parent = Workspace:FindFirstChild("Characters") or Workspace
	task.spawn(function()
		if clone:IsDescendantOf(game) and clone:GetAttribute("Dead") ~= true then
			local success, result = pcall(Ragdoll.PrepareCharacter, clone)

			if not success then
				warn(`[BotCharacters] Ragdoll preparation failed for {descriptor.DisplayName}: {result}`)
			end
		end
	end)
	return {
		Descriptor = descriptor,
		Shell = clone,
		Root = resolved.RootPart,
		Joints = CharacterPose.getJoints(clone),
		Animator = CharacterAnimator.new(clone),
		Visible = true,
		LastPosition = nil,
		LastAnimationAt = -1e999,
		Weapon = nil,
		Defuser = Defuser.new(folder, clone)
	}
end

local function needsWeapon(p, p2) -- 2 equivalent calls inferred from this helper
	local weaponName = p2.WeaponName or ""
	local weapon = p.Weapon

	if weaponName == "" then
		return weapon ~= nil
	end

	return weapon == nil or weapon.Name ~= weaponName or weapon.Revision ~= (p2.WeaponRevision or 0)
end

local function syncWeapon(entry, descriptor)
	if not needsWeapon(entry, descriptor) then -- inferred equivalent call
		return
	end

	local weaponName = descriptor.WeaponName or ""
	local v14

	if entry.Weapon == nil then
		v14 = false
	else
		v14 = entry.Weapon.Name ~= weaponName
	end

	BotWeaponModel.stow(entry.Shell, entry.Weapon)
	entry.Weapon = nil
	entry.Recoil = nil
	entry.Animator:setWeapon(nil, nil, false)

	if weaponName == "" then
		return
	end

	local weapon = BotWeaponModel.attach(entry.Shell, weaponName, descriptor.WeaponRevision or 0)

	if weapon ~= nil then
		entry.Weapon = weapon
		entry.Recoil = BotWeaponRecoil.new(weaponName)
		entry.Animator:setWeapon(weaponName, tostring(weapon.Revision), v14)
	end
end

function BotCharacters.PresentCombatEvents(items)
	local serverTimeNow = Workspace:GetServerTimeNow()

	for _, item in items do
		local v14 = v2[item.ActorId]
		local entry

		if v14 then
			entry = v14.Entry
		end

		local descriptor

		if v14 then
			descriptor = v14.Descriptor
		end

		if not (v14 ~= nil and entry ~= nil and descriptor ~= nil) then
			continue
		end

		local weapon = entry.Weapon
		local v15

		if
			descriptor.WeaponName == item.WeaponName
			and descriptor.WeaponRevision == item.WeaponRevision
			and weapon ~= nil
			and weapon.Name == item.WeaponName
		then
			v15 = weapon.Revision == item.WeaponRevision
		else
			v15 = false
		end

		local v16

		if (item.WeaponRevision or 0) > (descriptor.WeaponRevision or 0) then
			v16 = true
		elseif descriptor.WeaponName == item.WeaponName then
			v16 = descriptor.WeaponRevision == item.WeaponRevision
		else
			v16 = false
		end

		if
			v15
			or not v16
			or item.ActorId ~= descriptor.ActorId
			or item.Generation ~= descriptor.Generation
			or not (serverTimeNow - item.ServerTime <= BotCombatCodec.MaxEventAgeSeconds)
		then
			if
				v15
				and BotCombatCodec.canPresent(item, descriptor, entry.Visible, v14.LastEventSequence, serverTimeNow)
				and entry.Shell:IsDescendantOf(Workspace)
				and BotPresentationState.sameLife(entry.Descriptor, descriptor)
				and CharacterGeneration.Get(entry.Shell) == item.Generation
			then
				v14.LastEventSequence = item.Sequence
				BotCharacters.CombatEvent:Fire(item)
				entry.Animator:playAction(item.Kind)

				if item.Kind == "Shoot" and item.Target ~= nil then
					if entry.Recoil then
						entry.Recoil:OnShot(serverTimeNow)
					end

					BotWeaponEffects.shoot(
						weapon,
						item.Target,
						item.Sequence,
						entry.Shell:GetAttribute("SpectatedFirstPerson") == true
					)
				elseif item.Kind == "Reload" then
					BotWeaponEffects.reloadSound(
						weapon,
						entry.Root,
						entry.Shell:GetAttribute("SpectatedFirstPerson") == true
					)
				end
			end
		else
			v13[v14] = item
		end
	end
end

function BotCharacters.GetEquipment(p: number, p2: number)
	local v14 = v2[p]
	local entry

	if v14 then
		entry = v14.Entry
	end

	if not entry or not entry.Visible or entry.Descriptor.Generation ~= p2 then
		return nil
	end

	local weapon = entry.Weapon

	if not weapon then
		return nil
	end

	local v15 = entry.Descriptor.BotLoadout and HttpService:JSONDecode(entry.Descriptor.BotLoadout)
	local v16 = v15 and v15.Weapons[weapon.Name]
	return {
		Name = weapon.Name,
		Revision = weapon.Revision,
		Skin = not v16 and "Stock" or v16.Skin,
		Float = not v16 and 0 or v16.Float
	}
end

function BotCharacters.GetRecoil(p: number, p2: number)
	local v14 = v2[p]
	local entry

	if v14 then
		entry = v14.Entry
	end

	if entry and entry.Visible and entry.Weapon and entry.Recoil and entry.Descriptor.Generation == p2 then
		return entry.Recoil:Step(Workspace:GetServerTimeNow())
	end

	return Vector2.zero
end

local function lifeDescriptor(p, p2: number, p3: number)
	for _, v14 in { p.Descriptor, p.LastDescriptor } do
		if v14 and v14.CombatantId == p2 and v14.Generation == p3 then
			return v14
		end
	end

	return nil
end

function BotCharacters.TakeCorpse(p: number, p2: number, vector: Vector3, p3: number)
	local v14 = v11[p]

	if v14 == nil or v14.Generation ~= p2 then
		for _, v15 in v do
			local descriptor = lifeDescriptor(v15, p, p2)

			if not (descriptor and v15.CorpseGeneration ~= p2) then
				continue
			end

			local entry = v15.Entry

			if entry == nil or entry.Descriptor.Generation ~= p2 then
				v15.Entry = createEntry(v15.Folder, descriptor, CharacterPose.composeRootCFrame(vector, p3))
				retireToCorpse(v15)
				v15.Entry = entry
			else
				retireToCorpse(v15)
			end

			v14 = v11[p]
			break
		end
	end

	if v14 == nil or v14.Generation ~= p2 then
		return nil
	end

	v11[p] = nil
	local entry = v14.Entry
	local v15 = v12[p]

	if v15 ~= nil then
		v12[p] = nil
		destroyShell(v15)
	end

	v12[p] = entry
	task.delay(30, releaseCorpseSource, p, entry)
	return entry.Shell
end

function BotCharacters.GetCamera(p: number, p2: number)
	local v14 = v2[p]
	local entry

	if v14 then
		entry = v14.Entry
	end

	local v15 = v3[p]

	if not entry or not entry.Visible or not v15 or entry.Descriptor.Generation ~= p2 then
		return nil
	end

	local cameraPart = CharacterResolver.getCameraPart(entry.Shell)

	if not cameraPart then
		return nil
	end

	local renderPose = v15.RenderPose

	if renderPose == nil then
		return nil
	end

	local recoil = BotCharacters.GetRecoil(p, p2)
	local v16 = math.asin((math.clamp(renderPose.VerticalLook, -1, 1)))
	return CFrame.new(cameraPart.Position) * CFrame.Angles(0, renderPose.LookYaw + recoil.X, 0) * CFrame.Angles(v16 + recoil.Y, 0, 0)
end

local function queueMove(entry, renderPose) -- 2 equivalent calls inferred from this helper
	local v14 = poseRootCFrame(renderPose) -- inferred equivalent call

	if entry.Root.CFrame ~= v14 then
		roots[#roots + 1] = entry.Root
		v4[#v4 + 1] = v14
	end

	v5[#v5 + 1] = entry
	v6[#v6 + 1] = renderPose
end

function BotCharacters.Present(items)
	BotCharacters.Initialize()
	local now = os.clock()

	for k, v14 in v11 do
		if not (v14.ExpiresAt <= now) then
			continue
		end

		v11[k] = nil
		destroyShell(v14.Entry)
	end

	table.clear(v3)
	table.clear(roots)
	table.clear(v4)
	table.clear(v5)
	table.clear(v6)
	table.clear(v7)
	table.clear(v8)

	for _, item in items do
		if item.UserId == 0 then
			v3[item.ActorId] = item
		end
	end

	for _, v14 in v do
		local descriptor = v14.Descriptor
		local v15

		if descriptor ~= nil then
			v15 = v3[descriptor.ActorId]
		end

		local decide = BotPresentationState.decide(descriptor, v15)
		v14.LastDecision = decide
		local entry = v14.Entry

		if decide == "Destroy" then
			releaseEntry(v14, descriptor) -- inferred equivalent call
		elseif decide == "Hide" then
			if entry ~= nil then
				hide(entry)
			end
		elseif decide == "Present" then
			if entry ~= nil then
				queueMove(entry, v15.RenderPose) -- inferred equivalent call
			end

			if entry ~= nil and not needsWeapon(entry, descriptor) then -- inferred equivalent call
				continue
			end

			v7[#v7 + 1] = v14
			v8[#v8 + 1] = v15
		end
	end

	local count = #v7

	if count > 0 then
		local v14 = v9 % count
		local v15 = math.min(2, count)

		for i = 1, v15 do
			local v16 = (v14 + i - 1) % count + 1
			local v17 = v7[v16]
			local v18 = v8[v16]
			local descriptor = v17.Descriptor

			if not (BotPresentationState.decide(descriptor, v18) == "Present" and (not descriptor or v17.CorpseGeneration ~= descriptor.Generation)) then
				continue
			end

			local entry = v17.Entry
			local v19 = entry == nil

			if v19 then
				local v20 = v12[descriptor.CombatantId]

				if v20 and v20.Descriptor.Generation ~= descriptor.Generation then
					local combatantId = descriptor.CombatantId
					local v21 = v12[combatantId]

					if v21 ~= nil then
						v12[combatantId] = nil
						destroyShell(v21)
					end
				end

				entry = createEntry(v17.Folder, descriptor, poseRootCFrame(v18.RenderPose))
				v17.Entry = entry
			end

			if entry == nil then
				continue
			end

			syncWeapon(entry, descriptor)

			if v19 then
				queueMove(entry, v18.RenderPose) -- inferred equivalent call
			end
		end

		v9 = (v14 + v15) % count
	end

	if #roots == 1 then
		roots[1].CFrame = v4[1]
	elseif #roots > 1 then
		Workspace:BulkMoveTo(roots, v4, Enum.BulkMoveMode.FireCFrameChanged)
	end

	local now2 = os.clock()

	for k, v14 in v5 do
		local v15 = v6[k]
		local visible = v14.Visible

		if not visible then
			v14.ObjectiveAction = nil
			v14.Visible = true
			v14.Shell.Parent = Workspace:FindFirstChild("Characters") or Workspace
			v14.Shell:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, true)

			if v14.Weapon ~= nil then
				v14.Animator:setWeapon(v14.Weapon.Name, tostring(v14.Weapon.Revision), false)
			end
		end

		local objectiveAction = v14.Descriptor.ObjectiveAction

		if v14.ObjectiveAction ~= objectiveAction then
			if objectiveAction == "Planting" then
				if v14.Weapon and v14.Weapon.Name == "C4" then
					v14.Animator:playAction("Use")
					v14.ObjectiveAction = "Planting"
				end
			else
				if v14.ObjectiveAction == "Planting" and v14.Weapon and v14.Weapon.Name == "C4" then
					v14.Animator:playAction("Cancel Plant")
				end

				v14.ObjectiveAction = objectiveAction
			end
		end

		local v16 = (v14.LastPosition == nil or not ((v15.Position - v14.LastPosition).Magnitude > 0.00001))
			and createVector(0, 0, 0)
			or v15.Velocity
		RuntimeKinematics.write(v14.Shell, v16, v15.OnGround)
		v14.LastPosition = v15.Position

		if not (not visible or now2 - v14.LastAnimationAt >= 1 / 60) then
			continue
		end

		v14.Animator:updateLocomotion(v16, v15.OnGround, v15.DuckAmount > 0.5, v15.MovementMode == "Ladder")

		if v14.Joints ~= nil then
			CharacterPose.applyVerticalLook(v14.Joints, v15.VerticalLook, 0.003)
		end

		v14.LastAnimationAt = now2
	end

	if next(v13) ~= nil then
		local v14 = v13
		v13 = {}

		for _, v15 in v14 do
			BotCharacters.PresentCombatEvents({ v15 })
		end
	end
end

return BotCharacters