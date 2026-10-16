local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local Router = require(ReplicatedStorage.Database.Security.Router)

local function MultiplyUdim2(size: UDim2, p: number) -- 4 equivalent calls inferred from this helper
	return UDim2.new(size.X.Scale * p, size.X.Offset, size.Y.Scale * p, size.Y.Offset)
end

return function(data, flag: boolean?, p)
	local size = data.Size
	local tween = TweenService:Create(data, tweenInfo, { Size = MultiplyUdim2(size, 0.9) }) -- inferred equivalent call
	local tween2 = TweenService:Create(data, tweenInfo, { Size = MultiplyUdim2(size, 0.95) }) -- inferred equivalent call
	local tween3 = TweenService:Create(data, tweenInfo, { Size = MultiplyUdim2(size, 0.95) }) -- inferred equivalent call
	local tween4 = TweenService:Create(data, tweenInfo, { Size = MultiplyUdim2(size, 1) }) -- inferred equivalent call
	data.MouseEnter:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
		tween3:Play()
	end)
	data.MouseLeave:Connect(function()
		tween4:Play()
	end)
	data.MouseButton1Down:Connect(function()
		if flag and p.Menu.GlobalMarketPlace.Visible then
			return
		end

		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		tween:Play()
	end)
	data.MouseButton1Up:Connect(function()
		tween2:Play()
	end)
end