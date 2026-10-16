local createVector = vector.create
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CharacterAnimator = require(ReplicatedStorage.Classes.Character.Classes.CharacterAnimator)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local CharacterActions = require(ReplicatedStorage.Database.Components.CharacterActions)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local ClientCharacterPresentation = require(ReplicatedStorage.Components.Common.ClientCharacterPresentation)
local CharacterPresentationDescriptor = require(ReplicatedStorage.Components.Common.CharacterPresentationDescriptor)
local CharacterPose = require(ReplicatedStorage.Components.Common.CharacterPose)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local RootFrame = require(ReplicatedStorage.MovementV2.RootFrame)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local BotCharacters = require(script.Parent.BotCharacters)
local LocalPlayer = Players.LocalPlayer
local RemoteCharacters = {}
local v = {}
local v2 = {}
local v3 = {}
local flag = false
local count = 0
local rootParts = {}
local rootCFrames = {}
local v4 = {}
local renderPoses = {}
local v5 = nil
local object = setmetatable({}, { __mode = "k" })

local function restoreEntryParent(state)
	if state.Shell.Parent ~= ClientCharacterPresentation.GetCulledFolder() then
		return
	end

	local visibleParent = state.VisibleParent

	if
		visibleParent == nil
		or visibleParent == ClientCharacterPresentation.GetCulledFolder()
		or not visibleParent:IsDescendantOf(game)
	then
		visibleParent = Workspace:FindFirstChild("Characters") or Workspace
		state.VisibleParent = visibleParent
	end

	state.Shell.Parent = visibleParent
end

local function cullEntryFromWorkspace(p) -- 3 equivalent calls inferred from this helper
	local culledFolder = ClientCharacterPresentation.GetCulledFolder()
	local parent = p.Shell.Parent

	if parent ~= nil and parent ~= culledFolder then
		p.VisibleParent = parent
	end

	if p.Shell.Parent ~= culledFolder then
		p.Shell.Parent = culledFolder
	end
end

local function decodeCurrentEquipped(player)
	local currentEquipped = player:GetAttribute("CurrentEquipped")

	if typeof(currentEquipped) ~= "string" or currentEquipped == "" then
		return nil, nil
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, currentEquipped)

	if not success or typeof(result) ~= "table" then
		return nil, nil
	end

	local name

	if typeof(result.Name) == "string" then
		name = result.Name
	end

	local v6

	if typeof(result.Identifier) == "string" then
		v6 = result.Identifier
	end

	return name, v6
end

local function syncEquippedWeapon(data, flag2: boolean) -- 3 equivalent calls inferred from this helper
	if not data.Visible then
		return
	end

	local v6, v7 = decodeCurrentEquipped(data.Player)
	data.Animator:setWeapon(v6, v7, flag2)
end

local function setEntryVisible(state, flag2: boolean)
	local visible = state.Player == v5 and state.Visible and state.Shell:GetAttribute("Dead") ~= true and true or flag2

	if state.Visible == visible then
		if visible then
			restoreEntryParent(state)
		else
			RuntimeKinematics.clear(state.Shell)
			cullEntryFromWorkspace(state) -- inferred equivalent call
		end
	else
		state.Visible = visible

		if visible then
			restoreEntryParent(state)
			state.Shell:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, true)
			syncEquippedWeapon(state, false) -- inferred equivalent call
		else
			state.Shell:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, false)
			state.Animator:stopAnimations(0)
			RuntimeKinematics.clear(state.Shell)
			cullEntryFromWorkspace(state) -- inferred equivalent call
		end
	end
end

function RemoteCharacters.SetPinnedPlayer(p)
	v5 = p
end

function RemoteCharacters.GetCamera(p)
	local v6 = v[p]

	if v6 == nil or not v6.Visible or v6.LookYaw == nil then
		return nil
	end

	local cameraPart = CharacterResolver.getCameraPart(v6.Shell)

	if cameraPart == nil then
		return nil
	end

	local v7 = math.asin((math.clamp(v6.VerticalLook or 0, -1, 1)))
	return CFrame.new(cameraPart.Position) * CFrame.Angles(0, v6.LookYaw, 0) * CFrame.Angles(v7, 0, 0)
end

local function destroyPending(player) -- 7 equivalent calls inferred from this helper
	local v6 = v3[player]

	if v6 == nil then
		return
	end

	v3[player] = nil
	v6.Janitor:Destroy()
end

local function destroyEntry(player, flag2: boolean?)
	local v6 = v[player]

	if v6 == nil then
		return
	end

	v[player] = nil

	if v2[player.UserId] == v6 then
		v2[player.UserId] = nil
	end

	if
		flag2 ~= false
		and v6.Shell.Parent ~= nil
		and v6.Shell:GetAttribute("Dead") ~= true
		and player.Character == v6.Shell
	then
		setEntryVisible(v6, true)
	end

	RuntimeKinematics.clear(v6.Shell)
	v6.Janitor:Destroy()
end

local function releaseHeldShell(p) -- 2 equivalent calls inferred from this helper
	local v6 = object[p]

	if v6 then
		object[p] = nil
		v6:destroy()
	end
end

local function retireDeadEntry(state)
	local player = state.Player
	local shell = state.Shell

	if state.Visible and shell.Parent ~= nil then
		local animator = state.Animator
		animator:freezeAnimations()
		RuntimeKinematics.clear(shell)
		shell:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, false)

		for _, part in shell:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanQuery = false
			end
		end

		object[shell] = animator
		state.RetainAnimator = true
		local v6 = v[player]

		if v6 ~= nil then
			v[player] = nil

			if v2[player.UserId] == v6 then
				v2[player.UserId] = nil
			end

			RuntimeKinematics.clear(v6.Shell)
			v6.Janitor:Destroy()
		end

		task.delay(1.5, function()
			if object[shell] ~= animator then
				return
			end

			releaseHeldShell(shell) -- inferred equivalent call

			if shell.Parent then
				shell.Parent = ClientCharacterPresentation.GetCulledFolder()
			end
		end)
	else
		setEntryVisible(state, false)
		local v6 = v[player]

		if v6 == nil then
			return
		end

		v[player] = nil

		if v2[player.UserId] == v6 then
			v2[player.UserId] = nil
		end

		RuntimeKinematics.clear(v6.Shell)
		v6.Janitor:Destroy()
	end
end

local function tryBind(player, instance)
	if player == LocalPlayer or player.Parent ~= Players or player.Character ~= instance or instance.Parent == nil then
		destroyPending(player) -- inferred equivalent call
		return false
	elseif instance:GetAttribute("Dead") == true then
		if not object[instance] then
			instance:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, false)
			instance.Parent = ClientCharacterPresentation.GetCulledFolder()
		end

		destroyPending(player) -- inferred equivalent call
		return true
	else
		local generation = CharacterGeneration.Get(instance)
		local resolved = CharacterResolver.resolve(instance)

		if generation == nil or resolved == nil or resolved.Animator == nil then
			return false
		end

		local v6 = v[player]

		if v6 ~= nil then
			v[player] = nil

			if v2[player.UserId] == v6 then
				v2[player.UserId] = nil
			end

			if v6.Shell.Parent ~= nil and v6.Shell:GetAttribute("Dead") ~= true and player.Character == v6.Shell then
				setEntryVisible(v6, true)
			end

			RuntimeKinematics.clear(v6.Shell)
			v6.Janitor:Destroy()
		end

		releaseHeldShell(instance) -- inferred equivalent call
		local maid = Janitor.new()
		local animator = CharacterAnimator.new(instance)
		animator.Player = player
		local v7 = {
			Player = player,
			Shell = instance,
			Generation = generation,
			RootPart = resolved.RootPart,
			Joints = CharacterPose.getJoints(instance),
			Animator = animator,
			Visible = true,
			VisibleParent = 0,
			LastPosePosition = nil,
			LookYaw = nil,
			VerticalLook = nil,
			LastAnimationUpdateAt = -1e999,
			PresentedFrame = 0,
			RetainAnimator = false,
			Janitor = 0
		}
		local visibleParent

		if instance.Parent ~= ClientCharacterPresentation.GetCulledFolder() then
			visibleParent = instance.Parent
		end

		v7.VisibleParent = visibleParent
		v7.Janitor = maid
		v[player] = v7
		v2[player.UserId] = v7
		destroyPending(player) -- inferred equivalent call
		resolved.RootPart.Anchored = true
		resolved.RootPart.AssemblyLinearVelocity = createVector(0, 0, 0)
		resolved.RootPart.AssemblyAngularVelocity = createVector(0, 0, 0)
		maid:Add(function()
			if not v7.RetainAnimator then
				animator:destroy()
			end
		end)
		maid:Add(player:GetAttributeChangedSignal("CurrentEquipped"):Connect(function()
			if v[player] == v7 then
				syncEquippedWeapon(v7, true) -- inferred equivalent call
			end
		end))
		maid:Add(instance.DescendantAdded:Connect(function()
			if v7.Joints == nil then
				v7.Joints = CharacterPose.getJoints(instance)
			end
		end))
		maid:Add(instance.DescendantRemoving:Connect(function(descendant)
			local joints = v7.Joints

			if
				joints ~= nil
				and (descendant == joints.RightShoulder or descendant == joints.LeftShoulder or descendant == joints.Waist or descendant == joints.Neck)
			then
				v7.Joints = nil
			end

			if descendant == v7.RootPart or descendant == v7.Animator.Animator then
				task.defer(function()
					if v[player] == v7 then
						local v8 = player
						local v9 = v[v8]

						if v9 ~= nil then
							v[v8] = nil

							if v2[v8.UserId] == v9 then
								v2[v8.UserId] = nil
							end

							if
								v9.Shell.Parent ~= nil
								and v9.Shell:GetAttribute("Dead") ~= true
								and v8.Character == v9.Shell
							then
								setEntryVisible(v9, true)
							end

							RuntimeKinematics.clear(v9.Shell)
							v9.Janitor:Destroy()
						end

						if player.Character == instance and instance.Parent ~= nil then
							RemoteCharacters.Track(player, instance)
						end
					end
				end)
			end
		end))
		maid:Add(instance.AncestryChanged:Connect(function(_, parent)
			if parent == nil and v[player] == v7 then
				local v8 = player
				local v9 = v[v8]

				if v9 == nil then
					return
				end

				v[v8] = nil

				if v2[v8.UserId] == v9 then
					v2[v8.UserId] = nil
				end

				RuntimeKinematics.clear(v9.Shell)
				v9.Janitor:Destroy()
			elseif
				parent ~= nil
				and v[player] == v7
				and not v7.Visible
				and parent ~= ClientCharacterPresentation.GetCulledFolder()
			then
				task.defer(function()
					if
						v[player] == v7
						and not v7.Visible
						and v7.Shell.Parent ~= ClientCharacterPresentation.GetCulledFolder()
					then
						cullEntryFromWorkspace(v7) -- inferred equivalent call
					end
				end)
			end
		end))
		maid:Add(instance:GetAttributeChangedSignal("Dead"):Connect(function()
			if instance:GetAttribute("Dead") == true and v[player] == v7 then
				retireDeadEntry(v7)
			end
		end))
		maid:Add(instance:GetAttributeChangedSignal(CharacterGeneration.AttributeName):Connect(function()
			if CharacterGeneration.Get(instance) ~= v7.Generation and v[player] == v7 then
				RemoteCharacters.Track(player, instance)
			end
		end))
		syncEquippedWeapon(v7, false) -- inferred equivalent call
		setEntryVisible(v7, false)
		task.spawn(function()
			if instance:IsDescendantOf(game) and instance:GetAttribute("Dead") ~= true then
				local success, result = pcall(Ragdoll.PrepareCharacter, instance)

				if not success then
					warn(`[RemoteCharacters] Ragdoll preparation failed for {player.Name}: {result}`)
				end
			end
		end)
		return true
	end
end

function RemoteCharacters.Track(player, instance)
	if player == LocalPlayer or player.Character ~= instance then
		return
	end

	local v6 = v[player]

	if
		v6 ~= nil
		and instance:GetAttribute("Dead") ~= true
		and v6.Shell == instance
		and v6.Generation == CharacterGeneration.Get(instance)
	then
		return
	end

	local v7 = v[player]

	if v7 ~= nil then
		v[player] = nil

		if v2[player.UserId] == v7 then
			v2[player.UserId] = nil
		end

		if v7.Shell.Parent ~= nil and v7.Shell:GetAttribute("Dead") ~= true and player.Character == v7.Shell then
			setEntryVisible(v7, true)
		end

		RuntimeKinematics.clear(v7.Shell)
		v7.Janitor:Destroy()
	end

	local v8 = v3[player]

	if v8 ~= nil and v8.Shell == instance then
		tryBind(player, instance)
		return
	end

	destroyPending(player) -- inferred equivalent call
	local maid = Janitor.new()
	v3[player] = { Shell = instance, Janitor = maid }

	local function retry() -- 2 equivalent calls inferred from this helper
		if v3[player] ~= nil then
			tryBind(player, instance)
		end
	end

	maid:Add(instance.DescendantAdded:Connect(retry))
	maid:Add(instance:GetAttributeChangedSignal("CharacterType"):Connect(retry))
	maid:Add(instance:GetAttributeChangedSignal("Dead"):Connect(retry))
	maid:Add(instance:GetAttributeChangedSignal(CharacterGeneration.AttributeName):Connect(retry))
	maid:Add(instance.AncestryChanged:Connect(function()
		if instance.Parent == nil then
			destroyPending(player) -- inferred equivalent call
		else
			retry() -- inferred equivalent call
		end
	end))
	retry() -- inferred equivalent call
end

function RemoteCharacters.Untrack(player, p)
	local v6 = v[player]

	if v6 ~= nil and (p == nil or v6.Shell == p) then
		local v7 = v[player]

		if v7 ~= nil then
			v[player] = nil

			if v2[player.UserId] == v7 then
				v2[player.UserId] = nil
			end

			if v7.Shell.Parent ~= nil and v7.Shell:GetAttribute("Dead") ~= true and player.Character == v7.Shell then
				setEntryVisible(v7, true)
			end

			RuntimeKinematics.clear(v7.Shell)
			v7.Janitor:Destroy()
		end
	end

	local v7 = v3[player]

	if v7 ~= nil and (p == nil or v7.Shell == p) then
		destroyPending(player) -- inferred equivalent call
	end
end

function RemoteCharacters.Present(items, _)
	BotCharacters.Present(items)
	count += 1
	table.clear(rootParts)
	table.clear(rootCFrames)
	table.clear(v4)
	table.clear(renderPoses)

	for _, item in items do
		if item.UserId == 0 then
			continue
		end

		local v6 = v2[item.UserId]
		local playerByUserId

		if v6 == nil then
			playerByUserId = Players:GetPlayerByUserId(item.UserId)
		else
			playerByUserId = v6.Player
		end

		if not (playerByUserId ~= nil and playerByUserId ~= LocalPlayer) then
			continue
		end

		if v6 ~= nil and v6.Generation == item.Generation and CharacterGeneration.Get(v6.Shell) == item.Generation then
			v6.PresentedFrame = count
		end

		local renderPose = item.RenderPose

		if renderPose == nil then
			continue
		end

		local v7 = v[playerByUserId]
		local character = playerByUserId.Character

		if
			not ClientCharacterPresentation.IsOwned(character)
			or character == nil
			or CharacterGeneration.Get(character) ~= renderPose.Generation
		then
			character = ClientCharacterPresentation.Create(playerByUserId, renderPose.Generation)
		end

		if character ~= nil and (v7 == nil or v7.Shell ~= character or v7.Generation ~= renderPose.Generation) then
			RemoteCharacters.Track(playerByUserId, character)
			v7 = v[playerByUserId]
		end

		if not (v7 ~= nil and character ~= nil and v7.Shell == character and v7.Shell.Parent ~= nil) then
			continue
		end

		if not (v7.Shell:GetAttribute("Dead") ~= true and v7.Generation == renderPose.Generation and CharacterGeneration.Get(v7.Shell) == renderPose.Generation) then
			continue
		end

		v7.PresentedFrame = count
		local visualRootPosition = renderPose.VisualRootPosition
			or RootFrame.simulationToVisualRootPosition(renderPose.Position, renderPose.DuckAmount)
		local rootCFrame = CharacterPose.composeRootCFrame(visualRootPosition, renderPose.LookYaw)

		if v7.RootPart.CFrame ~= rootCFrame then
			rootParts[#rootParts + 1] = v7.RootPart
			rootCFrames[#rootCFrames + 1] = rootCFrame
		end

		v4[#v4 + 1] = v7
		renderPoses[#renderPoses + 1] = renderPose
	end

	if #rootParts == 1 then
		rootParts[1].CFrame = rootCFrames[1]
	elseif #rootParts > 1 then
		Workspace:BulkMoveTo(rootParts, rootCFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end

	local now = os.clock()

	for k, v6 in v4 do
		local v7 = renderPoses[k]
		local visible = v6.Visible
		setEntryVisible(v6, true)
		local lastPosePosition = v6.LastPosePosition
		local v8 = (lastPosePosition == nil or not ((v7.Position - lastPosePosition).Magnitude > 0.00001))
			and createVector(0, 0, 0)
			or v7.Velocity
		RuntimeKinematics.write(v6.Shell, v8, v7.OnGround)
		v6.LastPosePosition = v7.Position
		v6.LookYaw = v7.LookYaw
		v6.VerticalLook = v7.VerticalLook
		local v9 = now - v6.LastAnimationUpdateAt

		if not (not visible or v9 >= 1 / 60) then
			continue
		end

		local v10 = v7.DuckAmount > 0.5
		local v11 = v7.MovementMode == "Ladder"
		v6.Animator:updateLocomotion(v8, v7.OnGround, v10, v11)

		if v6.Joints ~= nil then
			CharacterPose.applyVerticalLook(v6.Joints, v7.VerticalLook, 0.003)
		end

		local lastAnimationUpdateAt

		if v9 == 1e999 then
			lastAnimationUpdateAt = now
		else
			lastAnimationUpdateAt = v6.LastAnimationUpdateAt + math.floor(v9 / (1 / 60)) * (1 / 60)
		end

		v6.LastAnimationUpdateAt = lastAnimationUpdateAt
	end

	for k, v6 in v do
		if v6.PresentedFrame == count then
			continue
		end

		if k.Parent == Players and k.Character == v6.Shell and v6.Shell.Parent ~= nil then
			if v6.Shell:GetAttribute("Dead") == true then
				retireDeadEntry(v6)
			elseif CharacterGeneration.Get(v6.Shell) == v6.Generation then
				setEntryVisible(v6, false)
			else
				local shell = v6.Shell
				local v7 = v[k]

				if v7 ~= nil then
					v[k] = nil

					if v2[k.UserId] == v7 then
						v2[k.UserId] = nil
					end

					RuntimeKinematics.clear(v7.Shell)
					v7.Janitor:Destroy()
				end

				ClientCharacterPresentation.Release(k, shell)
			end
		else
			local v7 = v[k]

			if v7 ~= nil then
				v[k] = nil

				if v2[k.UserId] == v7 then
					v2[k.UserId] = nil
				end

				RuntimeKinematics.clear(v7.Shell)
				v7.Janitor:Destroy()
			end
		end
	end
end

function RemoteCharacters.Initialize()
	if flag then
		return
	end

	flag = true
	BotCharacters.Initialize()
	Remotes.Character.Action.Listen(function(data)
		local playerByUserId = Players:GetPlayerByUserId(data.UserId)

		if playerByUserId == nil or playerByUserId == LocalPlayer then
			return
		end

		local v6 = v[playerByUserId]
		local name = CharacterActions.ToName(data.ActionId)

		if
			v6 ~= nil
			and v6.Visible
			and v6.Generation == data.Generation
			and CharacterGeneration.Get(v6.Shell) == data.Generation
			and playerByUserId.Character == v6.Shell
			and v6.Shell:GetAttribute("Dead") ~= true
			and name ~= nil
		then
			v6.Animator:playAction(name)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if v5 == player then
			v5 = nil
		end

		local character = player.Character
		local v6 = v[player]

		if v6 ~= nil then
			v[player] = nil

			if v2[player.UserId] == v6 then
				v2[player.UserId] = nil
			end

			RuntimeKinematics.clear(v6.Shell)
			v6.Janitor:Destroy()
		end

		destroyPending(player) -- inferred equivalent call
		ClientCharacterPresentation.Release(player, character)
	end)
end

return RemoteCharacters