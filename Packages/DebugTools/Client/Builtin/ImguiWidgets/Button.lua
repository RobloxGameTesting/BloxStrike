local Imgui = require(script.Parent.Parent.Parent.Imgui)
Imgui:NewWidgetDefinition("Button", {
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
	Construct = function(p, parent, text: string)
		local textButton = Instance.new("TextButton")
		textButton.Name = `Button ({p.ID})`
		textButton.AutomaticSize = Enum.AutomaticSize.XY
		textButton.Text = text
		textButton.BackgroundColor3 = Color3.fromRGB(98, 114, 164)
		textButton.BorderSizePixel = 0
		textButton.AutoButtonColor = false
		Imgui.applyTextStyle(textButton)
		Imgui.applyFrameStyle(textButton)
		textButton.Parent = parent
		Imgui.applyMouseDownStyle(textButton, function() end)
		Imgui.applyMouseUpStyle(textButton, function() end)
		p.PressConnection = textButton.Activated:Connect(function()
			p.Pressed = true
		end)
		p.MouseEnterConnection = Imgui.applyMouseHoverStyle(textButton, function()
			p.Hovering = true
		end)
		p.MouseLeaveConnection = Imgui.applyMouseHoverEndStyle(textButton, function()
			p.Hovering = false
		end)
		p.Button = textButton
		return textButton
	end,
	Deconstruct = function(data)
		data.PressConnection:Disconnect()
		data.MouseEnterConnection:Disconnect()
		data.MouseLeaveConnection:Disconnect()
	end,
	Update = function(p, text: string)
		p.TopInstance.Text = text
	end
})
return nil