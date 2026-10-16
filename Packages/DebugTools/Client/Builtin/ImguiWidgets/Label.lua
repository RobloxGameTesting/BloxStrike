local Imgui = require(script.Parent.Parent.Parent.Imgui)
Imgui:NewWidgetDefinition("Label", {
	Construct = function(p, parent, text: string)
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = `Label ({p.ID})`
		textLabel.AutomaticSize = Enum.AutomaticSize.XY
		textLabel.Text = text
		textLabel.RichText = true
		textLabel.BackgroundTransparency = 1
		textLabel.BorderSizePixel = 0
		Imgui.applyTextStyle(textLabel)
		textLabel.Parent = parent
		return textLabel
	end,
	Update = function(p, text: string)
		p.TopInstance.Text = text
	end
})
return nil