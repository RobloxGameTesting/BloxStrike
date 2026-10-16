local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Sound = require(ReplicatedStorage.Classes.Sound)
local Router = require(ReplicatedStorage.Database.Security.Router)
local CurrentCamera = workspace.CurrentCamera
local parent = nil
local template = nil
local backgroundTransparency = 0
local count = 0

local function animateCross(_: number)
	local clone = template:Clone()
	local v = 0.6 + math.random() * 0.4
	local size = template.Size

	local function scaledSize(p: number) -- 3 equivalent calls inferred from this helper
		return UDim2.fromScale(size.X.Scale * p, size.Y.Scale * p)
	end

	local v2 = math.random() < 0.5 and -1 or 1
	local v3 = math.random() ^ 0.5 * 0.44
	local v4 = 0.5 + v2 * v3
	local v5 = (math.random() - 0.5) * 2 * 0.04
	local v6 = (math.clamp((v3 - 0.15) / 0.29000000000000004, 0, 1) * 0.3 + 0.3) * (0.9 + math.random() * 0.2)
	local v7 = {
		{ Label = clone, Authored = template.ImageTransparency }
	}

	for _, image in clone:GetDescendants() do
		if image:IsA("ImageLabel") then
			table.insert(v7, { Label = image, Authored = image.ImageTransparency })
		end
	end

	clone.Name = "Cross"
	clone.Visible = true
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Size = UDim2.fromScale(0, 0)
	clone.Position = UDim2.fromScale(v4, 1.04)
	clone.Rotation = (math.random() - 0.5) * 24

	for _, v8 in v7 do
		v8.Label.ImageTransparency = 1
	end

	clone.Parent = parent
	TweenService:Create(clone, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = scaledSize(v * 1.25) -- inferred equivalent call
	}):Play()

	for _, v8 in v7 do
		TweenService:Create(v8.Label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = v8.Authored
		}):Play()
	end

	task.delay(0.12, function()
		TweenService:Create(clone, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = scaledSize(v) -- inferred equivalent call
		}):Play()
	end)
	TweenService:Create(clone, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(v4 + v5, 1.04 - v6),
		Rotation = clone.Rotation + (math.random() - 0.5) * 30
	}):Play()
	task.delay(0.54, function()
		TweenService:Create(clone, TweenInfo.new(0.66, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = scaledSize(v * 0.6) -- inferred equivalent call
		}):Play()

		for _, v8 in v7 do
			TweenService:Create(v8.Label, TweenInfo.new(0.66, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				ImageTransparency = 1
			}):Play()
		end
	end)
	task.delay(1.3, function()
		clone:Destroy()
	end)
end

local function ExecuteHPClaimBonus()
	count += 1
	local v = count

	if not parent.Visible then
		parent.BackgroundTransparency = 1
		parent.Visible = true
	end

	TweenService:Create(parent, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = backgroundTransparency
	}):Play()
	Sound.new("Deathmatch"):playOneTime({ Parent = CurrentCamera, Name = "Deathmatch HP Bonus" })

	for i = 1, 10 do
		task.delay((i - 1) * 0.05, animateCross, i)
	end

	task.delay(0.99, function()
		if count ~= v then
			return
		end

		local tween = TweenService:Create(parent, TweenInfo.new(0.66, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			BackgroundTransparency = 1
		})
		tween.Completed:Once(function()
			if count == v then
				parent.Visible = false
			end
		end)
		tween:Play()
	end)
end

local DeathmatchHealth = {}

function DeathmatchHealth.Initialize(_, instance)
	template = instance:WaitForChild("Template")
	template.Visible = false
	parent = instance
	backgroundTransparency = instance.BackgroundTransparency
	parent.BackgroundTransparency = 1
	parent.Visible = false
end

function DeathmatchHealth.Start()
	Router.observerRouter("DeathmatchHealthClaimed", ExecuteHPClaimBonus)
end

return DeathmatchHealth