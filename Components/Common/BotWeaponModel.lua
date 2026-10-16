local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetWeaponProperties = require(script.Parent.GetWeaponProperties)
local Attachments = require(ReplicatedStorage.Database.Custom.GameStats.Character.Attachments)
local GetMuzzleFlash = require(script.Parent.VFXLibary.CreateMuzzleFlash.GetMuzzleFlash)
local ThirdPersonWeaponStash = require(script.Parent.ThirdPersonWeaponStash)
local v = {}
local frozen = table.freeze({
	MuzzlePart = true,
	MuzzlePartL = true,
	MuzzlePartR = true,
	RootPart = true,
	Hitbox = true,
	Insert = true,
	move = true
})
local v2 = {}

function v.destroy(p)
	if p == nil then
		return
	end

	for _, motor in p.Motors do
		motor:Destroy()
	end

	p.Model:Destroy()
end

function v.stow(p, data)
	if data == nil then
		return
	end

	local dataByName = v2[p]

	if dataByName == nil then
		dataByName = {}
		v2[p] = dataByName
	end

	v.destroy(dataByName[data.Name])
	dataByName[data.Name] = data
	ThirdPersonWeaponStash.Park(data.Model, data.Motors)
end

function v.clear(p)
	local v3 = v2[p]

	if v3 == nil then
		return
	end

	v2[p] = nil

	for _, v4 in v3 do
		v.destroy(v4)
	end
end

local function joinMotor(p, p2, part, p3: string, name: string)
	local identity = CFrame.identity
	local identity2 = CFrame.identity
	local properties = p.Model:FindFirstChild("Properties")

	if properties then
		local cframeValue = properties:FindFirstChild("C0" .. p3)
		local cframeValue2 = properties:FindFirstChild("C1" .. p3)

		if cframeValue and cframeValue:IsA("CFrameValue") then
			identity = cframeValue.Value
		end

		if cframeValue2 and cframeValue2:IsA("CFrameValue") then
			identity2 = cframeValue2.Value
		end
	end

	ThirdPersonWeaponStash.PoseForJoint(p.Model, part, p2, identity, identity2)
	local motor6D = Instance.new("Motor6D")
	motor6D.Name = name
	motor6D.C0 = identity
	motor6D.C1 = identity2
	motor6D.Part0 = p2
	motor6D.Part1 = part
	motor6D.Parent = p2
	p.Motors[#p.Motors + 1] = motor6D
end

local function joinHands(instance, p, part, flag: boolean)
	local model = p.Model

	if not flag then
		joinMotor(p, part, model.PrimaryPart, "", "WeaponAttachment")
		return true
	end

	local handleR = model:FindFirstChild("HandleR", true)
	local handleL = model:FindFirstChild("HandleL", true)

	if handleR == nil or handleL == nil or not (handleR:IsA("BasePart") and handleL:IsA("BasePart")) then
		return false
	end

	joinMotor(p, instance:FindFirstChild("RightHand"), handleR, "RIGHT", "WeaponAttachmentHandleR")
	joinMotor(p, instance:FindFirstChild("LeftHand"), handleL, "LEFT", "WeaponAttachmentHandleL")
	return true
end

function v.attach(instance, weaponName: string, revision: number)
	local weaponProperties = GetWeaponProperties(weaponName)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local weapons

	if assets then
		weapons = assets:FindFirstChild("Weapons")
	end

	local child

	if weapons then
		child = weapons:FindFirstChild(weaponName)
	end

	local character

	if child then
		character = child:FindFirstChild("Character")
	end

	local weaponModel = instance:FindFirstChild("WeaponModel")

	if weaponProperties == nil or character == nil or not character:IsA("Model") or weaponModel == nil then
		return nil
	end

	local v3 = weaponProperties.ShootingOptions == "Dual"
	local part = instance:FindFirstChild(Attachments.WEAPON_JOINT_PARTS[weaponName] or Attachments.DEFAULT_JOINT_PART)

	if
		part == nil
		or not part:IsA("BasePart")
		or v3 and (instance:FindFirstChild("LeftHand") == nil or instance:FindFirstChild("RightHand") == nil)
	then
		return nil
	end

	local v4 = v2[instance]
	local v5

	if v4 then
		v5 = v4[weaponName]
	end

	if v5 then
		v4[weaponName] = nil

		if ThirdPersonWeaponStash.TryUnpark(v5.Model, weaponModel) then
			if not joinHands(instance, v5, part, v3) then
				v.destroy(v5)
				return nil
			end

			ThirdPersonWeaponStash.Release(v5.Motors)
			v5.Revision = revision
			v5.Model:SetAttribute("WeaponRevision", revision)
			return v5
		end
	end

	local botLoadout = instance:GetAttribute("BotLoadout")
	local v6

	if type(botLoadout) == "string" then
		v6 = HttpService:JSONDecode(botLoadout)
	end

	local v7 = v6 and v6.Weapons[weaponName]
	local clone

	if v7 then
		local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
		clone = Skins.GetCharacterModel(
			weaponName,
			v7.Skin,
			v7.Float,
			false,
			false,
			false,
			{},
			instance:GetAttribute("Team")
		)
	else
		clone = character:Clone()
	end

	if clone == nil then
		return nil
	end

	if clone.PrimaryPart == nil then
		clone:Destroy()
		return nil
	end

	local v8 = {
		Model = clone,
		Name = weaponName,
		Revision = revision,
		Motors = {},
		Muzzles = {},
		MuzzleType = weaponProperties.MuzzleType
	}

	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = "WeaponModel"
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Anchored = false
			descendant.Massless = true
			descendant.CastShadow = false

			if frozen[descendant.Name] or descendant.Name == "Silencer" then
				descendant.Transparency = 1
			end
		elseif descendant:IsA("BaseScript") then
			descendant:Destroy()
		end
	end

	if not joinHands(instance, v8, part, v3) then
		clone:Destroy()
		return nil
	end

	local muzzleFlashes

	if assets then
		muzzleFlashes = assets:FindFirstChild("MuzzleFlashes")
	end

	local character2

	if muzzleFlashes then
		character2 = muzzleFlashes:FindFirstChild("Character")
	end

	local interactables = clone:FindFirstChild("Interactables")

	if interactables then
		for _, childName in v3 and { "MuzzlePartR", "MuzzlePartL" } or { "MuzzlePart" } do
			local part2 = interactables:FindFirstChild(childName)

			if not (part2 and part2:IsA("BasePart")) then
				continue
			end

			v8.Muzzles[#v8.Muzzles + 1] = part2

			if
				character2
				and weaponProperties.MuzzleType
				and character2:FindFirstChild(weaponProperties.MuzzleType)
			then
				GetMuzzleFlash(part2, character2, weaponProperties.MuzzleType, "WeldConstraint")
			end
		end
	end

	clone.Name = "Equipped"
	clone:SetAttribute("WeaponName", weaponName)
	clone:SetAttribute("WeaponRevision", revision)
	clone.Parent = weaponModel
	return v8
end

return table.freeze(v)