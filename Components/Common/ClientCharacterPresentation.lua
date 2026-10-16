local createVector = vector.create
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local AttachGlovesToCharacter = require(ReplicatedStorage.Database.Components.Common.AttachGlovesToCharacter)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local CharacterPresentationDescriptor = require(ReplicatedStorage.Components.Common.CharacterPresentationDescriptor)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local ClientCharacterPresentation = {}
local Attributes = CharacterPresentationDescriptor.Attributes
local characters = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Characters")
local v = {}
local v2 = {}
local v3 = nil
local v4 = {}
local v5 = {}
local v6 = {}
local v7 = false
local now = 0

local function getCharactersFolder() -- 1 equivalent call inferred from this helper
	return Workspace:FindFirstChild("Characters") or Workspace
end

local function disconnectCharacter(p) -- 2 equivalent calls inferred from this helper
	local v8 = v[p]

	if v8 ~= nil then
		v[p] = nil
		v8()
	end
end

local function setBodyColor(instance, p)
	if typeof(p) ~= "Color3" then
		return
	end

	local bodyColors = instance:FindFirstChild("Body Colors")

	if bodyColors == nil or not bodyColors:IsA("BodyColors") then
		return
	end

	bodyColors.HeadColor3 = p
	bodyColors.LeftArmColor3 = p
	bodyColors.RightArmColor3 = p
	bodyColors.LeftLegColor3 = p
	bodyColors.RightLegColor3 = p
	bodyColors.TorsoColor3 = p
end

local function attachGloves(clone, attribute)
	if typeof(attribute) ~= "string" or attribute == "" then
		return
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, attribute)

	if not success or typeof(result) ~= "table" then
		return
	end

	local name = result.Name
	local skin = result.Skin
	local float = result.Float

	if typeof(name) ~= "string" or typeof(skin) ~= "string" or typeof(float) ~= "number" then
		return
	end

	local gloves = Skins.GetGloves(name, skin, float)
	local characterArmor = clone:FindFirstChild("CharacterArmor")

	if gloves == nil or characterArmor == nil then
		return
	end

	local success2, result2 = pcall(function()
		AttachGlovesToCharacter(gloves:GetChildren(), clone, characterArmor, {
			collisionGroup = "Debris"
		})
	end)

	if not success2 then
		warn(`[CharacterPresentation] Failed to attach gloves to {clone.Name}: {result2}`)
	end
end

function ClientCharacterPresentation.GetCulledFolder()
	local v8 = v3

	if v8 ~= nil and v8.Parent == ReplicatedStorage then
		return v8
	end

	v8 = Instance.new("Folder")
	v8.Name = "_PVS_CulledCharacters"
	v8.Archivable = false
	v8.Parent = ReplicatedStorage
	v3 = v8
	return v8
end

function ClientCharacterPresentation.PrepareRuntimeRig(folder)
	for _, humanoid in folder:GetChildren() do
		if humanoid:IsA("Humanoid") then
			humanoid:Destroy()
		end
	end

	if CharacterResolver.getCameraPart(folder) == nil then
		CharacterResolver.createCameraPart(folder)
	end

	CharacterResolver.getOrCreateAnimator(folder)

	for _, childName in { "WeaponModel", "WeaponAttachments" } do
		local child = folder:FindFirstChild(childName)

		if child ~= nil then
			child:Destroy()
		end

		local folder2 = Instance.new("Folder")
		folder2.Name = childName
		folder2.Parent = folder
	end

	for _, part in folder:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanCollide = false
		part.CanTouch = false

		if part.Name ~= "HumanoidRootPart" then
			continue
		end

		part.Anchored = true
		part.AssemblyLinearVelocity = createVector(0, 0, 0)
		part.AssemblyAngularVelocity = createVector(0, 0, 0)
	end
end

local function getRigKey(instance)
	local attribute = instance:GetAttribute(Attributes.CharacterName)

	if typeof(attribute) ~= "string" or attribute == "" then
		return nil
	end

	local attribute2 = instance:GetAttribute(Attributes.BodyColor)
	return table.concat(
		{
			attribute,
			tostring(instance:GetAttribute(Attributes.EquippedGloves)),
			typeof(attribute2) ~= "Color3" and "" or attribute2:ToHex()
		},
		"|"
	)
end

local function buildRig(instance)
	local attribute = instance:GetAttribute(Attributes.CharacterName)

	if typeof(attribute) ~= "string" or attribute == "" then
		return nil
	end

	local model = characters:FindFirstChild(attribute)

	if model == nil or not model:IsA("Model") then
		warn(`[CharacterPresentation] Missing character template {tostring(attribute)}`)
		return nil
	end

	local clone = model:Clone()
	clone.Archivable = true
	clone:SetAttribute("CharacterName", attribute)
	ClientCharacterPresentation.PrepareRuntimeRig(clone)
	local attribute2 = instance:GetAttribute(Attributes.EquippedGloves)

	if typeof(attribute2) == "string" then
		clone:SetAttribute("EquippedGloves", attribute2)
		attachGloves(clone, attribute2)
	end

	local attribute3 = instance:GetAttribute(Attributes.BodyColor)

	if typeof(attribute3) ~= "Color3" then
		return clone
	end

	local bodyColors = clone:FindFirstChild("Body Colors")

	if not (bodyColors ~= nil and bodyColors:IsA("BodyColors")) then
		return clone
	end

	bodyColors.HeadColor3 = attribute3
	bodyColors.LeftArmColor3 = attribute3
	bodyColors.RightArmColor3 = attribute3
	bodyColors.LeftLegColor3 = attribute3
	bodyColors.RightLegColor3 = attribute3
	bodyColors.TorsoColor3 = attribute3
	return clone
end

local function discardSpare(p) -- 1 equivalent call inferred from this helper
	local v8 = v4[p]

	if v8 ~= nil then
		v4[p] = nil
		v8.Rig:Destroy()
	end
end

local function takeSpare(player) -- 1 equivalent call inferred from this helper
	local v8 = v4[player]

	if v8 == nil then
		return nil
	end

	v4[player] = nil

	if v8.Key == getRigKey(player) then
		return v8.Rig
	end

	v8.Rig:Destroy()
	return nil
end

local function runSpareWorker()
	while #v5 > 0 do
		local now2 = os.clock()

		if now2 - now < 1 then
			task.wait(1 - (now2 - now))
		else
			local v8 = table.remove(v5, 1)
			v6[v8] = nil
			local v9

			if v8.Parent == Players then
				v9 = getRigKey(v8)
			end

			local v10 = v4[v8]

			if v9 ~= nil and (v10 == nil or v10.Key ~= v9) then
				discardSpare(v8) -- inferred equivalent call
				local rig = buildRig(v8)

				if rig ~= nil then
					v4[v8] = { Key = v9, Rig = rig }
				end

				task.wait(0.1)
			end
		end
	end

	v7 = false
end

local function queueSpare(player) -- 1 equivalent call inferred from this helper
	if v6[player] then
		return
	end

	v6[player] = true
	table.insert(v5, player)

	if not v7 then
		v7 = true
		task.spawn(runSpareWorker)
	end
end

function ClientCharacterPresentation.IsOwned(instance)
	return instance ~= nil and instance:GetAttribute(CharacterPresentationDescriptor.OwnedAttribute) == true
end

function ClientCharacterPresentation:Release(character)
	if not character then
		if ClientCharacterPresentation.IsOwned(self.Character) then
			character = self.Character
		else
			character = v2[self]
		end
	end

	if not ClientCharacterPresentation.IsOwned(character) then
		return
	end

	disconnectCharacter(character) -- inferred equivalent call

	if v2[self] == character then
		v2[self] = nil
	end

	if self.Character == character then
		self.Character = nil
	end

	character:Destroy()
end

function ClientCharacterPresentation:Create(value: number)
	if self.Parent ~= Players or typeof(value) ~= "number" then
		return nil
	end

	local v8 = v2[self]

	if v8 ~= nil and v8.Parent == nil then
		v2[self] = nil
		v8 = nil
	end

	local character

	if ClientCharacterPresentation.IsOwned(self.Character) then
		character = self.Character
	else
		character = v8
	end

	if character == nil or CharacterGeneration.Get(character) ~= value or character.Parent == nil then
		if character ~= nil then
			ClientCharacterPresentation.Release(self, character)
		end

		if v8 ~= nil and v8 ~= character then
			ClientCharacterPresentation.Release(self, v8)
		end

		now = os.clock()
		local character2 = takeSpare(self) or buildRig(self) -- inferred equivalent call

		if character2 == nil then
			return nil
		end

		queueSpare(self) -- inferred equivalent call
		character2.Name = self.Name
		character2:SetAttribute(CharacterPresentationDescriptor.OwnedAttribute, true)
		character2:SetAttribute(CharacterPresentationDescriptor.OwnerUserIdAttribute, self.UserId)
		character2:SetAttribute(CharacterPresentationDescriptor.VisibleAttribute, true)
		character2:SetAttribute("CharacterType", "PlayerCustomCharacter")
		CharacterGeneration.Set(character2, value)

		local function mirrorAttribute(attributeName: string, p: string, p2)
			local attribute = self:GetAttribute(attributeName)

			if attribute ~= nil then
				p2 = attribute
			end

			character2:SetAttribute(p, p2)
		end

		local attribute = self:GetAttribute(Attributes.Health)
		character2:SetAttribute("Health", attribute == nil and 100 or attribute)
		local attribute2 = self:GetAttribute(Attributes.MaxHealth)
		character2:SetAttribute("MaxHealth", attribute2 == nil and 100 or attribute2)
		local dead = self:GetAttribute("Dead")

		if dead == nil then
			dead = false
		end

		character2:SetAttribute("Dead", dead)
		local competitivePlayerColor = self:GetAttribute("CompetitivePlayerColor")

		if competitivePlayerColor == nil then
			competitivePlayerColor = nil
		end

		character2:SetAttribute("CompetitivePlayerColor", competitivePlayerColor)
		local attribute3 = self:GetAttribute(Attributes.SpawnPosition)
		local attribute4 = self:GetAttribute(Attributes.SpawnYaw)

		if typeof(attribute3) == "Vector3" then
			character2:PivotTo(CFrame.new(attribute3) * CFrame.Angles(
				0,
				typeof(attribute4) ~= "number" and 0 or attribute4,
				0
			))
		else
			character2:PivotTo(CFrame.new(0, -1000, 0))
		end

		local connections = {}

		local function connect(p: string, fn) -- 3 equivalent calls inferred from this helper
			connections[#connections + 1] = self:GetAttributeChangedSignal(p):Connect(fn)
		end

		local function fn()
			local attribute5 = self:GetAttribute(Attributes.Health)
			character2:SetAttribute("Health", attribute5 == nil and 0 or attribute5)
		end

		connect(Attributes.Health, fn) -- inferred equivalent call

		local function fn2()
			local attribute5 = self:GetAttribute(Attributes.MaxHealth)
			character2:SetAttribute("MaxHealth", attribute5 == nil and 100 or attribute5)
		end

		connect(Attributes.MaxHealth, fn2) -- inferred equivalent call
		connections[#connections + 1] = self:GetAttributeChangedSignal("Dead"):Connect(function()
			local dead2 = self:GetAttribute("Dead")

			if dead2 == nil then
				dead2 = false
			end

			character2:SetAttribute("Dead", dead2)
		end)
		connections[#connections + 1] = self:GetAttributeChangedSignal("CompetitivePlayerColor"):Connect(function()
			local competitivePlayerColor2 = self:GetAttribute("CompetitivePlayerColor")

			if competitivePlayerColor2 == nil then
				competitivePlayerColor2 = nil
			end

			character2:SetAttribute("CompetitivePlayerColor", competitivePlayerColor2)
		end)

		local function fn3()
			local attribute5 = self:GetAttribute(Attributes.BodyColor)

			if typeof(attribute5) ~= "Color3" then
				return
			end

			local bodyColors = character2:FindFirstChild("Body Colors")

			if bodyColors ~= nil then
				if not bodyColors:IsA("BodyColors") then
					return
				end

				bodyColors.HeadColor3 = attribute5
				bodyColors.LeftArmColor3 = attribute5
				bodyColors.RightArmColor3 = attribute5
				bodyColors.LeftLegColor3 = attribute5
				bodyColors.RightLegColor3 = attribute5
				bodyColors.TorsoColor3 = attribute5
			end
		end

		connect(Attributes.BodyColor, fn3) -- inferred equivalent call

		v[character2] = function()
			for _, connection in connections do
				connection:Disconnect()
			end
		end

		connections[#connections + 1] = character2.Destroying:Connect(function()
			disconnectCharacter(character2) -- inferred equivalent call

			if v2[self] == character2 then
				v2[self] = nil
			end
		end)
		character2.Parent = getCharactersFolder() -- inferred equivalent call
		v2[self] = character2
		self.Character = character2
		return character2
	else
		if self.Character ~= character then
			self.Character = character
		end

		return character
	end
end

function ClientCharacterPresentation.ObserveLocalPlayer()
	local localPlayer = Players.LocalPlayer

	local function refresh() -- 1 equivalent call inferred from this helper
		local attribute = localPlayer:GetAttribute(Attributes.Generation)

		if typeof(attribute) == "number" and localPlayer:GetAttribute("Dead") ~= true then
			ClientCharacterPresentation.Create(localPlayer, attribute)
		end
	end

	local v8 = {
		localPlayer:GetAttributeChangedSignal(Attributes.Generation):Connect(refresh),
		localPlayer:GetAttributeChangedSignal(Attributes.CharacterName):Connect(refresh),
		localPlayer:GetAttributeChangedSignal("Dead"):Connect(refresh)
	}
	refresh() -- inferred equivalent call
	return function()
		for _, connection in v8 do
			connection:Disconnect()
		end

		ClientCharacterPresentation.Release(localPlayer, localPlayer.Character)
	end
end

Players.PlayerRemoving:Connect(discardSpare)
return ClientCharacterPresentation