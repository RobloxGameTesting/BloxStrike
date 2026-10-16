local Imgui = require(script.Parent.Parent.Parent.Parent.Imgui)
local ClassIndex = require(script.Parent.Parent.Parent.Parent.Vendor.ClassIndex)
Imgui:NewWidgetDefinition("ExplorerClassIcon", {
	Construct = function(p, parent, size: UDim2, instance)
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = `Label ({p.ID})`
		imageLabel.AutomaticSize = Enum.AutomaticSize.XY
		imageLabel.BackgroundTransparency = 1
		imageLabel.BorderSizePixel = 0
		imageLabel.Size = size

		for k, v in ClassIndex.FetchClassIcon(instance.ClassName) do
			imageLabel[k] = v
		end

		imageLabel.Parent = parent
		return imageLabel
	end,
	Update = function(p, size: UDim2, instance)
		p.TopInstance.Size = size

		for k, v in ClassIndex.FetchClassIcon(instance.ClassName) do
			p.TopInstance[k] = v
		end
	end
})
return nil