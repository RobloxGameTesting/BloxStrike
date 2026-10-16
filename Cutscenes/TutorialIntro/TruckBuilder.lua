local ReplicatedStorage = game:GetService("ReplicatedStorage")
local object = setmetatable({}, { __mode = "k" })

local function findTemplate()
	local assets = ReplicatedStorage:WaitForChild("Assets", 5)
	local cutscenes = assets and assets:WaitForChild("Cutscenes", 5)
	local tutorialTruck = cutscenes and cutscenes:WaitForChild("TutorialTruck", 5)
	assert(tutorialTruck and tutorialTruck:IsA("Model"), "ReplicatedStorage.Assets.Cutscenes.TutorialTruck is missing")
	return tutorialTruck
end

local TruckBuilder = {}

function TruckBuilder.template()
	return (findTemplate())
end

function TruckBuilder.build(parent)
	local template = findTemplate()
	local clone = template:Clone()
	clone.Name = "CutsceneTruck"
	local v = {
		Parts = {},
		Locals = {},
		Axles = {},
		IsWheel = {},
		CFrames = {},
		Radius = template:GetAttribute("WheelRadius") or 1.6,
		Start = nil
	}

	for _, child in clone:GetChildren() do
		local v2 = child.Name == "Wheels"

		for _, part in child:GetChildren() do
			local attribute = part:GetAttribute("Local")

			if not (part:IsA("BasePart") and typeof(attribute) == "CFrame") then
				continue
			end

			local axle = part:GetAttribute("Axle")
			table.insert(v.Parts, part)
			table.insert(v.Locals, attribute)
			local axles = v.Axles
			local v3 = #v.Parts

			if typeof(axle) ~= "Vector3" then
				axle = nil
			end

			axles[v3] = axle
			table.insert(v.IsWheel, v2)
			table.insert(v.CFrames, attribute)
		end
	end

	object[clone] = v
	clone.Parent = parent
	return clone
end

function TruckBuilder.place(p, cframe: CFrame, cframe2: CFrame?)
	local v = object[p]

	if not v then
		return
	end

	local v2 = cframe2 or cframe

	if not v.Start then
		v.Start = v2.Position
	end

	local dot = (v2.Position - v.Start):Dot(v2.LookVector)
	local cframe3 = CFrame.Angles(-dot / v.Radius, 0, 0)
	local cframes = v.CFrames

	for k, v3 in v.Locals do
		if v.IsWheel[k] then
			local axle = v.Axles[k]

			if axle then
				local cframe4 = CFrame.new(axle)
				cframes[k] = v2 * cframe4 * cframe3 * cframe4:Inverse() * v3
			else
				cframes[k] = v2 * v3
			end
		else
			cframes[k] = cframe * v3
		end
	end

	workspace:BulkMoveTo(v.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
end

return TruckBuilder