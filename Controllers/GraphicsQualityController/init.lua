local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MaterialService = game:GetService("MaterialService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local PotatoColors = require(script.PotatoColors)
local v = { BloomEffect = true, SunRaysEffect = true, DepthOfFieldEffect = true, Clouds = true }
local v2 = { SurfaceAppearance = true, Texture = true }
local LocalPlayer = Players.LocalPlayer
local flag = false
local v3 = {}
local baseMaterialOverrides = {}
local object = setmetatable({}, { __mode = "k" })
local object2 = setmetatable({}, { __mode = "k" })

local function assetIdOf(value: string) -- 2 equivalent calls inferred from this helper
	return (tonumber(string.match(value, "(%d+)$")))
end

local function colorOf(list) -- 2 equivalent calls inferred from this helper
	return Color3.fromRGB(list[1], list[2], list[3])
end

local function multiplyColors(color: Color3, color2: Color3) -- 2 equivalent calls inferred from this helper
	return Color3.new(color.R * color2.R, color.G * color2.G, color.B * color2.B)
end

local function tintForMaterialVariant(instance)
	if object[instance] then
		return
	end

	object[instance] = true
	local materialVariant

	if instance.MaterialVariant == "" then
		materialVariant = baseMaterialOverrides[instance.Material]
	else
		materialVariant = instance.MaterialVariant
	end

	local v4

	if materialVariant then
		v4 = PotatoColors.MaterialVariants[`{instance.Material.Name}/{materialVariant}`]
	end

	if v4 then
		instance.Color = multiplyColors(instance.Color, colorOf(v4)) -- inferred equivalent call
	end
end

local function tintForRemovedSurface(instance)
	local parent = instance.Parent

	if not (parent and parent:IsA("BasePart")) then
		return
	end

	local v4 = 1
	local v5 = 1
	local v6, texture, color3

	if instance:IsA("Texture") then
		local v7 = assetIdOf(instance.Texture) -- inferred equivalent call

		if v7 then
			v6 = PotatoColors.Textures[v7]
		end

		texture = instance.Texture
		color3 = instance.Color3
		v4 = 1 - instance.Transparency
	else
		if not (instance:IsA("SurfaceAppearance") and parent:IsA("MeshPart")) then
			return
		end

		local v7 = assetIdOf(parent.MeshId) -- inferred equivalent call

		if v7 then
			v6 = PotatoColors.SurfaceAppearances[v7]
		end

		color3 = instance.Color
		texture = "SurfaceAppearance"
	end

	if not (v6 and texture) then
		return
	end

	if instance:IsA("Texture") or instance.AlphaMode == Enum.AlphaMode.Overlay then
		v5 = v6[4]
	end

	local v7 = object2[parent]

	if not v7 then
		v7 = {}
		object2[parent] = v7
	end

	if v7[texture] then
		return
	end

	v7[texture] = true
	parent.Color = parent.Color:Lerp(multiplyColors(colorOf(v6), color3), v5 * v4) -- inferred equivalent call
end

local function stripMaterialInstance(materialVariant)
	if materialVariant:IsA("MaterialVariant") then
		materialVariant:Destroy()
	end
end

local function stripEffectInstance(instance)
	if v[instance.ClassName] then
		instance:Destroy()
	end
end

local function isInsideRig(instance)
	local parent = instance.Parent

	while parent and parent ~= Workspace do
		if
			parent:IsA("Model")
			and (parent:FindFirstChild("HumanoidRootPart") or parent:FindFirstChildOfClass("Humanoid") or parent:FindFirstChildOfClass("AnimationController"))
		then
			return true
		else
			parent = parent.Parent
		end
	end

	return false
end

local function stripMapInstance(instance)
	if (v2[instance.ClassName] or instance:IsA("BasePart")) and isInsideRig(instance) then
		return
	end

	if v2[instance.ClassName] then
		tintForRemovedSurface(instance)
		instance:Destroy()
	elseif instance:IsA("BasePart") then
		instance.CastShadow = false
		tintForMaterialVariant(instance)
	elseif instance:IsA("Light") then
		instance.Shadows = false
	end
end

local function stripContainer(folder, callback, flag2: boolean)
	local v4

	if flag2 then
		v4 = folder.DescendantAdded
	else
		v4 = folder.ChildAdded
	end

	v4:Connect(function(p)
		task.defer(callback, p)
	end)
	local v5

	if flag2 then
		v5 = folder:GetDescendants()
	else
		v5 = folder:GetChildren()
	end

	for k, v6 in v5 do
		if v6.Parent then
			callback(v6)
		end

		if k % 2000 == 0 then
			task.wait()
		end
	end
end

local function resetBaseMaterialOverrides()
	for _, v4 in Enum.Material:GetEnumItems() do
		local success, baseMaterialOverride = pcall(MaterialService.GetBaseMaterialOverride, MaterialService, v4)

		if success and baseMaterialOverride ~= "" then
			baseMaterialOverrides[v4] = baseMaterialOverride
		end

		pcall(MaterialService.SetBaseMaterialOverride, MaterialService, v4, "")
	end
end

local function stopAnimatedProps()
	local v4 = v3
	v3 = {}

	for _, callback in v4 do
		task.spawn(callback)
	end
end

local function applyPotatoMode()
	if flag then
		return
	end

	flag = true
	stopAnimatedProps()
	resetBaseMaterialOverrides()
	task.spawn(stripContainer, MaterialService, stripMaterialInstance, true)
	task.spawn(stripContainer, Lighting, stripEffectInstance, false)
	task.spawn(stripContainer, Workspace.Terrain, stripEffectInstance, false)
	local map = Workspace:FindFirstChild("Map")

	if map then
		task.spawn(stripContainer, map, stripMapInstance, true)
	end

	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "Map" then
			task.spawn(stripContainer, child, stripMapInstance, true)
		end
	end)
end

local GraphicsQualityController = {}

function GraphicsQualityController.RunAnimatedProp(callback)
	if flag then
		return nil
	end

	local v4 = callback()

	if not v4 then
		return nil
	end

	local v5 = {}
	v3[v5] = v4
	return function()
		if v3[v5] then
			v3[v5] = nil
			v4()
		end
	end
end

function GraphicsQualityController.Start()
	DataController.CreateListener(LocalPlayer, "Settings.Video.Presets.Potato Mode", function(p)
		if p == true then
			applyPotatoMode()
		end

		return nil
	end)
end

return GraphicsQualityController