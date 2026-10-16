local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ViewmodelHand = require(ReplicatedStorage.Shared.ViewmodelHand)
local cframe = CFrame.new(0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 1)
local cframe2 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1)
local v = { SurfaceAppearance = true, Decal = true, Texture = true }
local BakedViewmodelMirror = {}
BakedViewmodelMirror.__index = BakedViewmodelMirror
local v2 = {}
local v3 = {}
local v4 = {}
local v5 = {}
local v6 = false
local v7 = {}
local v8 = false
local flag = false
local v9 = false
local now = 0
local v10 = {}

local function isLoaded(p) -- 2 equivalent calls inferred from this helper
	local meshId = p.MeshId

	if v3[meshId] then
		return true
	end

	if ContentProvider:GetAssetFetchStatus(meshId) ~= Enum.AssetFetchStatus.Success then
		return false
	end

	v3[meshId] = true
	return true
end

local function waitForQuiet()
	local v11 = os.clock() - now

	while v11 < 2 do
		task.wait(2 - v11)
		v11 = os.clock() - now
	end
end

local function runDownloads()
	while #v5 > 0 do
		waitForQuiet()
		local v11 = {}

		while #v11 < 8 and #v5 > 0 do
			local v12 = table.remove(v5, 1)
			v4[v12.MeshId] = nil

			if not isLoaded(v12) then -- inferred equivalent call
				table.insert(v11, v12)
			end
		end

		if not (#v11 > 0) then
			continue
		end

		pcall(ContentProvider.PreloadAsync, ContentProvider, v11)
		task.wait(0.25)
	end

	v6 = false
end

local function queueDownloads(items)
	for _, item in items do
		if v4[item.MeshId] or v3[item.MeshId] then
			continue
		end

		v4[item.MeshId] = true
		table.insert(v5, item)
	end

	if not v6 and #v5 > 0 then
		v6 = true
		task.spawn(runDownloads)
	end
end

local function runBuilds()
	while #v7 > 0 do
		waitForQuiet()
		RunService.Heartbeat:Wait()
		local v11 = table.remove(v7, 1)

		if not v11.Model or v11.Twins then
			continue
		end

		v11:BuildTwins()
	end

	v8 = false
end

local function queueBuild(p) -- 2 equivalent calls inferred from this helper
	table.insert(v7, p)

	if not v8 then
		v8 = true
		task.spawn(runBuilds)
	end
end

local function preloadBothHands(p)
	local v11 = {}

	for _, entry in p.Entries do
		table.insert(v11, entry.part)
		table.insert(v11, entry.bake)
	end

	task.spawn(pcall, ContentProvider.PreloadAsync, ContentProvider, v11)
end

local function activate()
	if flag then
		return
	end

	flag = true
	local parts = {}

	for k in v2 do
		queueBuild(k) -- inferred equivalent call
		preloadBothHands(k)
	end

	local viewmodelMirrors = ReplicatedStorage:FindFirstChild("ViewmodelMirrors")

	for _, part in not viewmodelMirrors and {} or viewmodelMirrors:GetChildren() do
		if part:IsA("MeshPart") then
			table.insert(parts, part)
		end
	end

	queueDownloads(parts)
end

local function modifierSet(instance)
	local decals = { instance }

	for _, decal in instance:GetChildren() do
		if decal:IsA("Decal") then
			table.insert(decals, decal)
		end
	end

	return decals
end

function BakedViewmodelMirror.ReflectPose(cframe3: CFrame, cframe4: CFrame)
	return cframe3 * cframe * cframe3:ToObjectSpace(cframe4)
end

function BakedViewmodelMirror.new(folder, instance, flag2: boolean)
	local entries = {}

	for _, part in folder:GetDescendants() do
		if not part:IsA("MeshPart") then
			continue
		end

		local match = part.MeshId:match("%d+")
		local part2 = match and instance:FindFirstChild(match)

		if part2 and part2:IsA("MeshPart") then
			table.insert(entries, { part = part, bake = part2 })
		else
			if not v10[part.MeshId] then
				v10[part.MeshId] = true
				warn(`[BakedViewmodelMirror] No left-hand bake for {part:GetFullName()} ({part.MeshId})`)
			end

			return nil
		end
	end

	local object = setmetatable({
		Model = folder,
		Entries = entries,
		Surfaces = {},
		Hand = "Right",
		Visible = true,
		Twins = false,
		Ready = {}
	}, BakedViewmodelMirror)
	v2[object] = true
	now = os.clock()

	if flag then
		queueBuild(object) -- inferred equivalent call
		preloadBothHands(object)
	elseif flag2 then
		queueDownloads(object:Bakes())
	end

	return object
end

function BakedViewmodelMirror:Bakes()
	local bakes = {}

	for _, entry in self.Entries do
		table.insert(bakes, entry.bake)
	end

	return bakes
end

function BakedViewmodelMirror:HandReady(p: string)
	if self.Ready[p] then
		return true
	end

	for _, entry in self.Entries do
		local v11

		if p == "Left" then
			v11 = entry.bake
		else
			v11 = entry.part
		end

		if not isLoaded(v11) then -- inferred equivalent call
			return false
		end
	end

	self.Ready[p] = true
	return true
end

function BakedViewmodelMirror:BuildTwins()
	if self.Twins or not self.Model then
		return
	end

	for _, entry in self.Entries do
		local part = entry.part
		local clone = entry.bake:Clone()
		clone.Name = part.Name
		clone.Archivable = false
		clone.Anchored = false
		clone.Massless = true
		clone.CanCollide = false
		clone.CanQuery = false
		clone.CanTouch = false
		clone.CastShadow = part.CastShadow
		clone.EnableFluidForces = false
		clone.CollisionGroup = part.CollisionGroup
		clone.Size = part.Size
		clone.Color = part.Color
		clone.Material = part.Material
		clone.MaterialVariant = part.MaterialVariant
		clone.Reflectance = part.Reflectance
		clone.TextureID = part.TextureID
		clone.Transparency = part.Transparency
		clone.DoubleSided = false

		for _, child in part:GetChildren() do
			if not v[child.ClassName] then
				continue
			end

			local clone_2 = child:Clone()
			clone_2.Parent = clone
		end

		local weld = Instance.new("Weld")
		weld.Part0 = part
		weld.Part1 = clone
		weld.Parent = clone
		clone.CFrame = part.CFrame
		entry.twin = clone
		entry.sourceSet = modifierSet(part)
		entry.twinSet = modifierSet(clone)
	end

	self:CreateSurfaces()
	self.Twins = true
	self:WriteVisibility()

	for _, entry in self.Entries do
		if entry.part.Parent then
			entry.twin.Parent = entry.part
		end
	end
end

function BakedViewmodelMirror:CreateSurfaces()
	local folder = Instance.new("Folder")
	folder.Name = "ViewmodelSurfaceDisplays"
	self.SurfaceFolder = folder

	for _, surfaceGui in self.Model:GetDescendants() do
		if not surfaceGui:IsA("SurfaceGui") then
			continue
		end

		local adornee = surfaceGui.Adornee or surfaceGui.Parent

		if not (adornee and adornee:IsA("BasePart") and adornee:IsDescendantOf(self.Model)) then
			continue
		end

		local part = Instance.new("Part")
		part.Name = surfaceGui.Name
		part.Anchored = true
		part.Transparency = 1
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Parent = folder
		table.insert(self.Surfaces, {
			gui = surfaceGui,
			part = adornee,
			proxy = part,
			originalAdornee = surfaceGui.Adornee
		})
	end

	self.ParentConnection = self.Model:GetPropertyChangedSignal("Parent"):Connect(function()
		self:UpdateSurfaceParent()
	end)
end

function BakedViewmodelMirror:PrepareEquip()
	if flag and not self.Twins then
		self:BuildTwins()
	end
end

function BakedViewmodelMirror:WriteVisibility()
	if not self.Twins then
		return
	end

	local v11 = self.Hand == "Left"
	local v12 = self.Visible and not v9
	local localTransparencyModifier = (v11 or not v12) and 1 or 0
	local localTransparencyModifier2 = v11 and v12 and 0 or 1

	for _, entry in self.Entries do
		for _, v13 in entry.sourceSet do
			v13.LocalTransparencyModifier = localTransparencyModifier
		end

		for _, v13 in entry.twinSet do
			v13.LocalTransparencyModifier = localTransparencyModifier2
		end
	end

	for _, surface in self.Surfaces do
		local gui = surface.gui
		local adornee

		if v11 then
			adornee = surface.proxy
		else
			adornee = surface.originalAdornee
		end

		gui.Adornee = adornee
	end

	self:UpdateSurfaceParent()
end

function BakedViewmodelMirror:SyncTransparency()
	for _, entry in self.Entries do
		local transparency = entry.part.Transparency

		if entry.twin.Transparency ~= transparency then
			entry.twin.Transparency = transparency
		end
	end
end

function BakedViewmodelMirror:SetLeftHanded(flag2: boolean)
	local hand = flag2 and "Left" or "Right"

	if hand == self.Hand and self.Visible then
		if flag2 then
			self:SyncTransparency()
		end
	else
		if not self.Twins then
			if not flag2 then
				return
			end

			activate()
			self:BuildTwins()
		end

		local v11 = hand ~= self.Hand

		if v11 then
			self.Hand = hand
			self.PendingSince = os.clock()

			if not self:HandReady(hand) then
				local v12 = {}

				for _, entry in self.Entries do
					local v13

					if flag2 then
						v13 = entry.bake
					else
						v13 = entry.part
					end

					table.insert(v12, v13)
				end

				task.spawn(pcall, ContentProvider.PreloadAsync, ContentProvider, v12)
			end
		end

		local visible = self:HandReady(hand) or os.clock() - self.PendingSince >= 1.5

		if visible and flag2 then
			self:SyncTransparency()
		end

		if v11 or visible ~= self.Visible then
			self.Visible = visible
			self:WriteVisibility()
		end
	end
end

function BakedViewmodelMirror.SetSuppressed(flag2: boolean)
	v9 = flag2

	if not flag2 then
		for k in v2 do
			k:WriteVisibility()
		end
	end
end

function BakedViewmodelMirror:UpdateSurfaceParent()
	local model = self.Model

	if self.SurfaceFolder and model then
		local currentCamera = workspace.CurrentCamera
		local visible

		if self.Hand == "Left" then
			visible = self.Visible
		else
			visible = false
		end

		local surfaceFolder = self.SurfaceFolder

		if not visible or model.Parent ~= currentCamera then
			currentCamera = nil
		end

		surfaceFolder.Parent = currentCamera
	end
end

function BakedViewmodelMirror:GetDisplayPose(lastCamera: CFrame, cframe3: CFrame)
	self.LastCamera = lastCamera

	if self.Hand == "Left" then
		return (BakedViewmodelMirror.ReflectPose(lastCamera, cframe3))
	end

	return cframe3
end

function BakedViewmodelMirror.UpdateSurfaces(data)
	if data.Hand ~= "Left" or not data.Visible then
		return
	end

	for _, surface in data.Surfaces do
		local face = surface.gui.Face
		local v11

		if face == Enum.NormalId.Front or face == Enum.NormalId.Back then
			v11 = cframe
		else
			v11 = cframe2
		end

		surface.proxy.Size = surface.part.Size
		surface.proxy.CFrame = surface.part.CFrame * v11
	end
end

function BakedViewmodelMirror.ToNormalPose(p, cframe3: CFrame)
	if p.Hand == "Left" and p.LastCamera then
		return BakedViewmodelMirror.ReflectPose(p.LastCamera, cframe3)
	end

	return cframe3
end

function BakedViewmodelMirror:Destroy()
	v2[self] = nil

	if self.ParentConnection then
		self.ParentConnection:Disconnect()
	end

	for _, surface in self.Surfaces do
		if surface.gui.Parent then
			surface.gui.Adornee = surface.originalAdornee
		end
	end

	if self.SurfaceFolder then
		self.SurfaceFolder:Destroy()
	end

	table.clear(self.Surfaces)

	for _, entry in self.Entries do
		if entry.twin then
			entry.twin:Destroy()
		end
	end

	table.clear(self.Entries)
	self.Model = nil
end

ViewmodelHand.Changed:Connect(function(flag2: boolean)
	if flag2 then
		activate()
	end
end)
return BakedViewmodelMirror