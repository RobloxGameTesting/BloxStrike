local TutorialBotSmoothing = {}
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local v = {
	TutorialEscorts = true,
	TutorialRetakers = true,
	TutorialCTSquad = true,
	TutorialBAttackers = true
}
local v2 = {}
local v3 = {}
local renderSteppedConnection = nil
local roots = {}
local v4 = {}
local v5 = 0

local function isSamePose(cframe: CFrame, cframe2: CFrame) -- 3 equivalent calls inferred from this helper
	return (cframe.Position - cframe2.Position).Magnitude <= 0.001
		and cframe.LookVector:Dot(cframe2.LookVector) >= 0.999998
		and cframe.UpVector:Dot(cframe2.UpVector) >= 0.999998
end

local function untrack(p)
	local v6 = v2[p]

	if not v6 then
		return
	end

	v2[p] = nil

	for _, connection in v6.Connections do
		connection:Disconnect()
	end

	local written = v6.Written

	if written and v6.Root.Parent and isSamePose(v6.Root.CFrame, written) then -- inferred equivalent call
		v6.Root.CFrame = v6.Target
	end

	if next(v2) == nil and renderSteppedConnection then
		renderSteppedConnection:Disconnect()
		renderSteppedConnection = nil
	end
end

local function receive(state, cframe: CFrame, now: number)
	state.Target = cframe
	local position = cframe.Position
	local path = state.Path
	local v6

	if #path > 0 then
		v6 = path[#path]
	else
		v6 = state.Visual.Position
	end

	local magnitude = (position - v6).Magnitude

	if magnitude > 8 then
		table.clear(path)
		table.clear(state.Arrivals)
		state.Visual = cframe
		state.Speed = 0
		state.Cruise = 0
	else
		if magnitude > 0.001 then
			table.insert(path, position)
			state.Queued += magnitude
			local movedAt = state.MovedAt

			if movedAt and now - movedAt < 0.6 then
				v5 = math.max(v5, now - movedAt)
			end

			state.MovedAt = now
		end

		table.insert(state.Arrivals, { Time = now, Distance = state.Queued })
	end
end

local function measureSpeed(p, now: number)
	local arrivals = p.Arrivals

	while #arrivals > 1 and now - arrivals[1].Time > 0.5 do
		table.remove(arrivals, 1)
	end

	if #arrivals < 2 then
		return 0
	end

	local arrival = arrivals[1]
	return (p.Queued - arrival.Distance) / math.max(now - arrival.Time, 0.25)
end

local function pathLength(vector: Vector3, items)
	local total = 0

	for _, item in items do
		total += (item - vector).Magnitude
		vector = item
	end

	return total
end

local function advance(position: Vector3, path, p: number)
	while #path > 0 do
		local v6 = path[1]
		local magnitude = (v6 - position).Magnitude

		if p < magnitude then
			return position + (v6 - position) * (p / magnitude)
		end

		p -= magnitude
		table.remove(path, 1)
		position = v6
	end

	return position
end

local function step(p: number)
	local v6 = math.min(p, 0.1)
	local now = os.clock()
	local v7 = 1 - math.exp(v6 * -10)
	local v8 = 1 - math.exp(v6 * -14)
	v5 *= math.exp(-v6 / 3)
	local v9 = math.clamp(v5 * 1.25, 0.1, 0.4)
	local v10 = math.exp(-v6 / 1)
	table.clear(roots)
	table.clear(v4)

	for k, v11 in v2 do
		local root = v11.Root

		if k.Parent == v11.Folder and root.Parent ~= nil and k:GetAttribute("Dead") ~= true then
			local cframe = root.CFrame
			local written = v11.Written

			if written then
				if not isSamePose(cframe, written) then -- inferred equivalent call
					receive(v11, cframe, now)
				end
			else
				receive(v11, cframe, now)
			end

			local target = v11.Target
			local visual = v11.Visual
			v11.Speed += (measureSpeed(v11, now) - v11.Speed) * v7
			v11.Cruise = math.max(v11.Speed, v11.Cruise * v10)
			local path = v11.Path
			local position = visual.Position
			local total = 0

			for _, v12 in path do
				total += (v12 - position).Magnitude
				position = v12
			end

			local position2

			if total <= 0.01 then
				table.clear(path)
				position2 = target.Position
			else
				local v12 = v11.Speed + (total - v11.Speed * v9) * 3
				local movedAt = v11.MovedAt

				if not movedAt or v9 < now - movedAt then
					v12 = math.max(v12, v11.Cruise)
				end

				local v13 = math.max(math.clamp(v12, 0, (math.max(v11.Cruise * 1.5, 4))) * v6, total - 7)

				if total - 0.01 <= v13 then
					position2 = advance(visual.Position, path, 1e999)
				else
					position2 = advance(visual.Position, path, v13)
				end
			end

			local v12

			if visual.LookVector:Dot(target.LookVector) >= 0.9999904807207345 then
				v12 = visual.UpVector:Dot(target.UpVector) >= 0.9999904807207345
			else
				v12 = false
			end

			local v13

			if v12 then
				v13 = target.Rotation
			else
				v13 = visual.Rotation:Lerp(target.Rotation, v8)
			end

			local v14 = CFrame.new(position2) * v13

			if #path == 0 and v12 then
				v14 = target
			end

			v11.Visual = v14

			if v14 == target and isSamePose(cframe, target) then -- inferred equivalent call
				v11.Written = cframe
				continue
			end

			v11.Written = v14
			roots[#roots + 1] = root
			v4[#v4 + 1] = v14
		else
			untrack(k)
		end
	end

	if #roots == 1 then
		roots[1].CFrame = v4[1]
	elseif #roots > 1 then
		Workspace:BulkMoveTo(roots, v4, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local function track(model, instance)
	if
		not model:IsA("Model")
		or v2[model]
		or (model:GetAttribute("TutorialDummy") ~= true or model:GetAttribute("TutorialCutout") == true)
	then
		return
	end

	if model:GetAttribute("Dead") == true then
		return
	end

	local humanoidRootPart = model:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		if not humanoidRootPart.Anchored then
			return
		end

		local cframe = humanoidRootPart.CFrame
		local v6 = {
			Model = model,
			Folder = instance,
			Root = humanoidRootPart,
			Target = cframe,
			Visual = cframe,
			Written = nil,
			Path = {},
			Queued = 0,
			Arrivals = {},
			Speed = 0,
			Cruise = 0,
			MovedAt = nil,
			Connections = {}
		}
		v2[model] = v6
		table.insert(v6.Connections, model:GetAttributeChangedSignal("Dead"):Connect(function()
			if model:GetAttribute("Dead") == true then
				untrack(model)
			end
		end))
		table.insert(v6.Connections, model.AncestryChanged:Connect(function()
			if model.Parent ~= instance then
				untrack(model)
			end
		end))

		if not renderSteppedConnection then
			renderSteppedConnection = RunService.RenderStepped:Connect(step)
		end
	else
		local childAddedConnection = nil
		childAddedConnection = model.ChildAdded:Connect(function(child)
			if child.Name == "HumanoidRootPart" then
				childAddedConnection:Disconnect()
				track(model, instance)
			end
		end)
		task.delay(10, function()
			childAddedConnection:Disconnect()
		end)
	end
end

local function watchFolder(child)
	if not v[child.Name] or v3[child] then
		return
	end

	v3[child] = {
		child.ChildAdded:Connect(function(child2)
			track(child2, child)
		end),
		child.ChildRemoved:Connect(function(model)
			if model:IsA("Model") then
				untrack(model)
			end
		end)
	}

	for _, child2 in child:GetChildren() do
		track(child2, child)
	end
end

local function unwatchFolder(p)
	local v6 = v3[p]

	if not v6 then
		return
	end

	v3[p] = nil

	for _, connection in v6 do
		connection:Disconnect()
	end

	for k, v7 in v2 do
		if v7.Folder == p then
			untrack(k)
		end
	end
end

function TutorialBotSmoothing.Start()
	Workspace.ChildAdded:Connect(watchFolder)
	Workspace.ChildRemoved:Connect(unwatchFolder)

	for _, child in Workspace:GetChildren() do
		watchFolder(child)
	end
end

return TutorialBotSmoothing