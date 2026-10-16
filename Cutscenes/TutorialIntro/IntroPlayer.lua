local createVector = vector.create
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local IntroPlayer = {}
IntroPlayer.__index = IntroPlayer

local function cframeOf(list) -- 5 equivalent calls inferred from this helper
	return CFrame.new(
		list[1],
		list[2],
		list[3],
		list[4],
		list[5],
		list[6],
		list[7],
		list[8],
		list[9],
		list[10],
		list[11],
		list[12]
	)
end

local function sampleTrack(list, p: number, fps: number)
	local v = math.max(0, p * fps)
	local v2 = math.floor(v)
	local count = #list

	if count - 1 <= v2 then
		return cframeOf(list[count])
	end

	return cframeOf(list[v2 + 1]):Lerp(cframeOf(list[v2 + 2]), v - v2) -- inferred equivalent call
end

local function sampleNumber(list, p: number, fps: number) -- 2 equivalent calls inferred from this helper
	local v = math.max(0, p * fps)
	local v2 = math.floor(v)
	local count = #list

	if count - 1 <= v2 then
		return list[count]
	end

	return list[v2 + 1] + (list[v2 + 2] - list[v2 + 1]) * (v - v2)
end

local function smoother(value: number) -- 3 equivalent calls inferred from this helper
	local v = math.clamp(value, 0, 1)
	return v * v * v * (v * (v * 6 - 15) + 10)
end

local function window(p: number, list)
	if not list then
		return 0
	end

	return smoother((p - list[1]) / (list[2] - list[1])) -- inferred equivalent call
end

local function buildActor(object, k: string, rig)
	local options = object.Options
	local clone = options.CharacterTemplate:Clone()
	clone.Name = "Intro_" .. k

	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		elseif descendant:IsA("Sound") then
			descendant:Destroy()
		end
	end

	local upperTorso = clone:FindFirstChild("UpperTorso")
	local head = upperTorso and upperTorso:FindFirstChild("Head")

	if head and head:IsA("Motor6D") then
		head:Destroy()
	end

	local humanoidRootPart = clone:FindFirstChild("HumanoidRootPart")
	humanoidRootPart.Anchored = true

	if options.HeadMeshScale then
		local head2 = clone:FindFirstChild("Head")
		local specialMesh = head2 and head2:FindFirstChildOfClass("SpecialMesh")

		if specialMesh then
			specialMesh.Scale = createVector(1, 1, 1) * options.HeadMeshScale
		end
	end

	local animationController = Instance.new("AnimationController")
	animationController.Parent = clone
	local animator = Instance.new("Animator")
	animator.Parent = animationController
	local clone2 = options.WeaponTemplate:Clone()
	clone2.Name = "AK-47"
	local weapon = clone2:FindFirstChild("Weapon")

	if weapon then
		for _, childName in { "Hitbox", "Insert" } do
			local child = weapon:FindFirstChild(childName)

			if child then
				child:Destroy()
			end
		end
	end

	for _, descendant in clone2:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.Massless = true
		elseif descendant:IsA("Sound") or descendant:IsA("Light") then
			descendant:Destroy()
		end
	end

	clone2.Parent = clone
	local weaponHold = rig.WeaponHold
	local motor6D = Instance.new("Motor6D")
	motor6D.Name = weaponHold.MotorName
	motor6D.Part0 = clone:FindFirstChild(weaponHold.Part0)
	motor6D.Part1 = weapon and weapon:FindFirstChild(weaponHold.Part1)
	motor6D.C0 = cframeOf(weaponHold.C0) -- inferred equivalent call
	motor6D.C1 = cframeOf(weaponHold.C1) -- inferred equivalent call
	motor6D.Parent = motor6D.Part0
	humanoidRootPart.CFrame = cframeOf(rig.Root[1]) -- inferred equivalent call
	clone.Parent = object.Folder

	local function load(keyframeSequence, priority, looped: boolean) -- 3 equivalent calls inferred from this helper
		local v

		if keyframeSequence:IsA("KeyframeSequence") then
			v = Instance.new("Animation")
			v.AnimationId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
		else
			v = keyframeSequence
		end

		local track = animator:LoadAnimation(v)
		track.Looped = looped
		track.Priority = priority
		return track
	end

	local track = load(options.Animations[k], Enum.AnimationPriority.Core, false) -- inferred equivalent call
	local hold = load(options.HoldAnimation, Enum.AnimationPriority.Idle, true) -- inferred equivalent call
	local leftArm = load(options.LeftArmAnimations[k], Enum.AnimationPriority.Action, false) -- inferred equivalent call
	local parts = {}

	for _, descendant in clone:GetDescendants() do
		if not (descendant:IsA("BasePart") or descendant:IsA("Decal")) then
			continue
		end

		table.insert(parts, { descendant, descendant.Transparency })
		descendant.Transparency = 1
	end

	return {
		Model = clone,
		Root = humanoidRootPart,
		Track = track,
		Hold = hold,
		LeftArm = leftArm,
		Rig = rig,
		Parts = parts,
		Hidden = true,
		Animated = false
	}
end

local function buildOverlay(gui)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialIntroOverlay"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 50
	screenGui.ResetOnSpawn = false
	local frame = Instance.new("Frame")
	frame.Name = "BarTop"
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 0.12)
	frame.Parent = screenGui
	local clone = frame:Clone()
	clone.Name = "BarBottom"
	clone.AnchorPoint = Vector2.new(0, 1)
	clone.Position = UDim2.fromScale(0, 1)
	clone.Parent = screenGui
	screenGui.Parent = gui
	return { Screen = screenGui, Top = frame, Bottom = clone, Bar = 0.12 }
end

function IntroPlayer.new(options)
	local object = setmetatable({}, IntroPlayer)
	object.Options = options
	object.Data = options.Data
	object.Fps = options.Data.Fps
	object.Duration = options.Data.Duration
	object.CutFrames = {}

	for k, event in options.Data.Events do
		if not (string.sub(k, 1, 4) == "Shot" and type(event) == "number") then
			continue
		end

		object.CutFrames[math.floor(event * object.Fps + 0.5)] = true
	end

	object.Camera = options.Camera or workspace.CurrentCamera
	local folder = Instance.new("Folder")
	folder.Name = "TutorialIntro"
	folder.Parent = options.Parent or workspace
	object.Folder = folder
	object.Actors = {}

	for k, rig in options.Data.Rigs do
		object.Actors[k] = buildActor(object, k, rig)
	end

	object.Truck = options.TruckBuilder.build(folder)
	object.Roots = {}

	for _, actor in object.Actors do
		table.insert(object.Roots, actor.Root)
	end

	if options.Atmosphere then
		object.Atmosphere = options.Atmosphere.new({
			Data = options.Data,
			Folder = folder,
			Camera = object.Camera,
			SunDirection = options.SunDirection
		})
	end

	local tutorialDoors = options.Map and options.Map:FindFirstChild("TutorialDoors")
	local dockDoor = tutorialDoors and tutorialDoors:FindFirstChild("DockDoor")

	if dockDoor and dockDoor:IsA("Model") then
		object.DockDoor = dockDoor
		object.DockDoorClosed = dockDoor:GetPivot()
		object.DockDoorOffset = dockDoor:GetAttribute("OpenOffset") or createVector(0, 10.5, 0)
	end

	if options.Gui then
		object.Overlay = buildOverlay(options.Gui)
	end

	object.Started = false
	object:Update(0)
	return object
end

function IntroPlayer:Start()
	for _, actor in self.Actors do
		actor.Track:Play(0, 1, 1)
		actor.Hold:Play(0, 1, 1)
		actor.LeftArm:Play(0, 0.0001, 1)
	end

	self.Started = true
	self.LastClock = nil
end

function IntroPlayer:Time()
	for _, actor in self.Actors do
		if actor.Track.IsPlaying then
			return actor.Track.TimePosition
		end
	end

	return self.Duration
end

function IntroPlayer:Update(p: number?)
	local lastClock = math.clamp(p or not self.Started and 0 or self:Time(), 0, self.Duration)
	local data = self.Data
	local fps = self.Fps
	local v = not self.LastClock and 0 or math.clamp(lastClock - self.LastClock, 0, 0.1)
	self.LastClock = lastClock

	for _, actor in self.Actors do
		actor.Root.CFrame = sampleTrack(actor.Rig.Root, lastClock, fps)

		if self.Started then
			local v2 = math.min(lastClock + v, self.Duration)
			actor.LeftArm:AdjustWeight(math.max(sampleNumber(actor.Rig.LeftArmWeight, v2, fps), 0.0001), 0) -- inferred equivalent call
		end

		if self.Started and actor.Track.TimePosition > 0 then
			actor.Animated = true
		end

		local hiddenFrom = actor.Rig.HiddenFrom
		local hidden = not actor.Animated

		if not hidden then
			if hiddenFrom == nil then
				hidden = false
			else
				hidden = hiddenFrom <= lastClock
			end
		end

		if hidden == actor.Hidden then
			continue
		end

		actor.Hidden = hidden

		for _, part in actor.Parts do
			part[1].Transparency = hidden and 1 or part[2]
		end
	end

	local v2 = math.min(lastClock, (data.Truck.SettledFrame - 1) / fps)
	local v3 = sampleTrack(data.Truck.Body, v2, fps)
	local v4 = sampleTrack(data.Truck.Wheels, v2, fps)
	self.Options.TruckBuilder.place(self.Truck, v3, v4)
	local atmosphere = self.Atmosphere

	if atmosphere then
		atmosphere:Update(lastClock, v, v3, v4, self.Roots)
	end

	local camera = self.Camera
	camera.CameraType = Enum.CameraType.Scriptable
	local v5 = math.floor(lastClock * fps + 0.01)
	local v6

	if self.CutFrames[v5 + 1] then
		v6 = v5 / fps
	else
		v6 = lastClock
	end

	local cframe = sampleTrack(data.Camera, v6, fps)

	if atmosphere then
		cframe *= atmosphere:Shake(v6)
	end

	camera.CFrame = cframe
	camera.FieldOfView = sampleNumber(data.CameraFov, v6, fps) -- inferred equivalent call
	local events = data.Events

	if self.DockDoor then
		local dockDoor = self.DockDoor
		local dockDoorClosed = self.DockDoorClosed
		local dockDoorOffset = self.DockDoorOffset
		local dockDoorOpen = events.DockDoorOpen
		local v7

		if dockDoorOpen then
			v7 = smoother((lastClock - dockDoorOpen[1]) / (dockDoorOpen[2] - dockDoorOpen[1])) -- inferred equivalent call
		else
			v7 = 0
		end

		dockDoor:PivotTo(dockDoorClosed + dockDoorOffset * v7)
	end

	local overlay = self.Overlay

	if not overlay then
		return self.Duration <= lastClock
	end

	local letterboxRetract = events.LetterboxRetract
	local v7

	if letterboxRetract then
		v7 = smoother((lastClock - letterboxRetract[1]) / (letterboxRetract[2] - letterboxRetract[1])) -- inferred equivalent call
	else
		v7 = 0
	end

	overlay.Top.Position = UDim2.fromScale(0, -overlay.Bar * v7)
	overlay.Bottom.Position = UDim2.fromScale(0, 1 + overlay.Bar * v7)
	return self.Duration <= lastClock
end

function IntroPlayer:Destroy()
	for _, actor in self.Actors do
		actor.Track:Stop(0)
		actor.Hold:Stop(0)
		actor.LeftArm:Stop(0)
	end

	if self.Overlay then
		self.Overlay.Screen:Destroy()
	end

	if self.Atmosphere then
		self.Atmosphere:Destroy()
	end

	self.Folder:Destroy()
end

return IntroPlayer