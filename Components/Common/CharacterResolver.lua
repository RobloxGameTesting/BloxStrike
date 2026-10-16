local createVector = vector.create
local Players = game:GetService("Players")
local CharacterPresentationDescriptor = require(script.Parent.CharacterPresentationDescriptor)
local CharacterResolver = {}

local function getBasePart(instance, childName: string)
	local part

	if instance then
		part = instance:FindFirstChild(childName)
	end

	if part and part:IsA("BasePart") then
		return part
	end

	return nil
end

function CharacterResolver.getRootPart(instance)
	local humanoidRootPart

	if instance then
		humanoidRootPart = instance:FindFirstChild("HumanoidRootPart")
	end

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end

	return nil
end

function CharacterResolver.getHead(instance)
	local head

	if instance then
		head = instance:FindFirstChild("Head")
	end

	if head and head:IsA("BasePart") then
		return head
	end

	return nil
end

function CharacterResolver:pivotCharacter(cframe: CFrame)
	local rootPart = CharacterResolver.getRootPart(self)

	if rootPart and self.PrimaryPart ~= rootPart then
		self.PrimaryPart = rootPart
	end

	self:PivotTo(cframe)
end

function CharacterResolver.pivotCharacterTo(p, vector: Vector3)
	local rootPart = CharacterResolver.getRootPart(p)

	if not rootPart then
		return
	end

	CharacterResolver.pivotCharacter(p, rootPart.CFrame.Rotation + vector)
end

function CharacterResolver.getAnimationController(instance)
	local animationController

	if instance then
		animationController = instance:FindFirstChild("AnimationController")
	end

	if animationController and animationController:IsA("AnimationController") then
		return animationController
	end

	return nil
end

function CharacterResolver.getOrCreateAnimator(parent)
	local parent2 = CharacterResolver.getAnimationController(parent)

	if not parent2 then
		parent2 = Instance.new("AnimationController")
		parent2.Name = "AnimationController"
		parent2.Parent = parent
	end

	local animator = parent2:FindFirstChild("Animator")

	if animator then
		assert(animator:IsA("Animator"), `Expected {parent2:GetFullName()}.Animator to be an Animator`)
		return animator
	end

	local animator2 = Instance.new("Animator")
	animator2.Parent = parent2
	return animator2
end

function CharacterResolver.getAnimator(p)
	local animationController = CharacterResolver.getAnimationController(p)
	local animator

	if animationController then
		animator = animationController:FindFirstChild("Animator")
	end

	if animator and animator:IsA("Animator") then
		return animator
	end

	return nil
end

function CharacterResolver.getCameraPart(instance)
	local cameraPart

	if instance then
		cameraPart = instance:FindFirstChild("CameraPart")
	end

	if cameraPart and cameraPart:IsA("BasePart") then
		return cameraPart
	end

	return nil
end

function CharacterResolver.createCameraPart(parent)
	assert(not parent:FindFirstChild("CameraPart"), `{parent:GetFullName()} already has a CameraPart`)
	local part2 = assert(CharacterResolver.getRootPart(parent), `{parent:GetFullName()} has no HumanoidRootPart`)
	local v = assert(CharacterResolver.getHead(parent), `{parent:GetFullName()} has no Head`)
	local part = Instance.new("Part")
	part.Name = "CameraPart"
	part.Size = createVector(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Massless = true
	part.CFrame = CFrame.new(v.Position)
	part.Parent = parent
	local weld = Instance.new("Weld")
	weld.Name = "CameraPartWeld"
	weld.Part0 = part2
	weld.Part1 = part
	weld.C0 = CFrame.new(part2.CFrame:PointToObjectSpace(v.Position))
	weld.Parent = part
	return part
end

function CharacterResolver.resolve(character)
	if not character then
		return nil
	end

	local rootPart = CharacterResolver.getRootPart(character)
	local cameraPart = CharacterResolver.getCameraPart(character)

	if rootPart and cameraPart then
		return {
			Character = character,
			RootPart = rootPart,
			Head = CharacterResolver.getHead(character),
			CameraPart = cameraPart,
			AnimationController = CharacterResolver.getAnimationController(character),
			Animator = CharacterResolver.getAnimator(character)
		}
	end

	return nil
end

function CharacterResolver.getPlayerFromCharacter(instance)
	if instance == nil then
		return nil
	end

	local playerFromCharacter = Players:GetPlayerFromCharacter(instance)

	if playerFromCharacter ~= nil then
		return playerFromCharacter
	end

	local attribute = instance:GetAttribute(CharacterPresentationDescriptor.OwnerUserIdAttribute)

	if typeof(attribute) == "number" then
		return (Players:GetPlayerByUserId(attribute))
	end

	return nil
end

function CharacterResolver.getPlayerFromInstance(instance)
	if instance == nil then
		return nil
	end

	local model = instance:FindFirstAncestorOfClass("Model")

	while model ~= nil do
		local playerFromCharacter = CharacterResolver.getPlayerFromCharacter(model)

		if playerFromCharacter ~= nil then
			return playerFromCharacter
		end

		model = model:FindFirstAncestorOfClass("Model")
	end

	return nil
end

function CharacterResolver.getPlayerCharacter(player)
	local character

	if player then
		character = player.Character
	end

	if character and character.Parent then
		return character
	end

	return nil
end

function CharacterResolver.getLocalCharacter()
	return CharacterResolver.getPlayerCharacter(Players.LocalPlayer)
end

function CharacterResolver.observeCharacter(p, callback)
	local playerCharacter = CharacterResolver.getPlayerCharacter(p)
	local v = callback(playerCharacter, nil)

	local function setCharacter(p2)
		if p2 == playerCharacter then
			return
		end

		local v2 = playerCharacter
		playerCharacter = p2

		if v then
			v()
		end

		v = callback(p2, v2)
	end

	local characterAddedConnection = p.CharacterAdded:Connect(setCharacter)
	local characterRemovingConnection = p.CharacterRemoving:Connect(function(character)
		if character == playerCharacter then
			if playerCharacter == nil then
				return
			end

			local v2 = playerCharacter
			playerCharacter = nil

			if v then
				v()
			end

			v = callback(nil, v2)
		end
	end)
	return function()
		characterAddedConnection:Disconnect()
		characterRemovingConnection:Disconnect()

		if v then
			v()
		end
	end
end

function CharacterResolver.isPlayerCharacter(instance)
	return instance ~= nil
		and instance:GetAttribute("CharacterType") == "PlayerCustomCharacter"
		and CharacterResolver.getRootPart(instance) ~= nil
end

function CharacterResolver.isTutorialDummy(instance)
	return instance ~= nil
		and instance:GetAttribute("TutorialDummy") == true
		and CharacterResolver.getRootPart(instance) ~= nil
end

function CharacterResolver.isTutorialCutout(instance)
	return instance ~= nil and instance:GetAttribute("TutorialCutout") == true
end

function CharacterResolver.getCutoutBoard(model)
	if not (model and model:IsA("Model")) then
		model = model and model:FindFirstAncestorOfClass("Model")
	end

	while model do
		if CharacterResolver.isTutorialCutout(model) then
			return model.PrimaryPart
		else
			model = model:FindFirstAncestorOfClass("Model")
		end
	end

	return nil
end

function CharacterResolver.isCutoutHeadshot(instance, vector: Vector3?)
	if instance and typeof(vector) == "Vector3" then
		return instance.CFrame:PointToObjectSpace(vector).Y >= instance.Size.Y * 0.345
	end

	return false
end

function CharacterResolver.getImpactMaterial(model, value: string?)
	if not (model and model:IsA("Model")) and model then
		model = model:FindFirstAncestorOfClass("Model")
	end

	while model do
		if CharacterResolver.isTutorialCutout(model) then
			return "WoodPlanks"
		end

		if CharacterResolver.isPlayerCharacter(model) or CharacterResolver.isTutorialDummy(model) then
			return "Blood Splatter"
		else
			model = model:FindFirstAncestorOfClass("Model")
		end
	end

	return value or "Plastic"
end

function CharacterResolver.getHealth(instance)
	local health

	if instance then
		health = instance:GetAttribute("Health")
	end

	if typeof(health) == "number" then
		return health
	end

	return 0
end

function CharacterResolver.getMaxHealth(instance)
	local maxHealth

	if instance then
		maxHealth = instance:GetAttribute("MaxHealth")
	end

	if typeof(maxHealth) == "number" then
		return maxHealth
	end

	return 0
end

function CharacterResolver.isAliveCharacter(instance)
	local v

	if instance == nil then
		return false
	else
		v = instance:IsDescendantOf(workspace)

		if v then
			if instance:GetAttribute("Dead") == false then
				return CharacterResolver.getHealth(instance) > 0
			else
				return false
			end
		end
	end

	return v
end

function CharacterResolver.isAlivePlayer(instance)
	if instance == nil or instance.Parent ~= Players or instance:GetAttribute("Dead") ~= false then
		return false
	end

	local attribute = instance:GetAttribute(CharacterPresentationDescriptor.Attributes.Health)
	return typeof(attribute) == "number" and attribute > 0
end

return CharacterResolver