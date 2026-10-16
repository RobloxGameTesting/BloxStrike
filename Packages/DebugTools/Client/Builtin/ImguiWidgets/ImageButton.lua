local Imgui = require(script.Parent.Parent.Parent.Imgui)
Imgui:NewWidgetDefinition("ImageButton", {
	Events = {
		activated = {
			Evaluate = function(p)
				local pressed = p.Pressed
				p.Pressed = false
				return pressed
			end
		},
		hovered = {
			Evaluate = function(p)
				return p.Hovering
			end
		}
	},
	Construct = function(p, parent, size: UDim2, image: string)
		local imageButton = Instance.new("ImageButton")
		imageButton.Name = `ImageButton ({p.ID})`
		imageButton.AutomaticSize = Enum.AutomaticSize.XY
		imageButton.BorderSizePixel = 0
		imageButton.BackgroundTransparency = 1
		imageButton.AutoButtonColor = false
		imageButton.Image = image
		imageButton.Size = size
		imageButton.Parent = parent
		Imgui.applyMouseDownStyle(imageButton, function() end)
		Imgui.applyMouseUpStyle(imageButton, function() end)
		p.PressConnection = imageButton.Activated:Connect(function()
			p.Pressed = true
		end)
		p.MouseEnterConnection = Imgui.applyMouseHoverStyle(imageButton, function()
			p.Hovering = true
		end)
		p.MouseLeaveConnection = Imgui.applyMouseHoverEndStyle(imageButton, function()
			p.Hovering = false
		end)
		p.ImageButton = imageButton
		return imageButton
	end,
	Deconstruct = function(data)
		data.PressConnection:Disconnect()
		data.MouseEnterConnection:Disconnect()
		data.MouseLeaveConnection:Disconnect()
	end,
	Update = function(p, size: UDim2, image: string)
		p.TopInstance.Image = image
		p.TopInstance.Size = size
	end,
	Return = function(p)
		local pressed = p.Pressed
		p.Pressed = false
		return pressed or false
	end
})
return nil