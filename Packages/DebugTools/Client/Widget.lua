local Players = game:GetService("Players")
local Shared = script.Parent.Parent.Shared
local Signal = require(Shared.Signal)
local Constants = require(Shared.Constants)
local v = {
	internal = { WidgetData = {} },
	interface = {
		WidgetAdded = Signal.new(),
		WidgetMounted = Signal.new(),
		WidgetUnmounted = Signal.new()
	}
}

function v.internal.createWidgetScreenGui(p)
	local v2 = v.internal.WidgetData[p.Name]

	if not v2 then
		return nil
	end

	if v2.ScreenGui then
		return v2.ScreenGui
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = `[DEBUG] {p.Name}`
	screenGui.DisplayOrder = Constants.WIDGET_DISPLAY_ORDER
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = Players.LocalPlayer.PlayerGui
	v2.ScreenGui = screenGui
	return screenGui
end

function v.internal.addWidget(widget)
	v.internal.WidgetData[widget.Name] = { Widget = widget, Mounted = false }
	v.interface.WidgetAdded:Fire(widget.Name)
	v.internal.mountWidget(widget)
end

function v.internal.removeWidget(p: string)
	local v2 = v.internal.WidgetData[p]

	if not v2 then
		return
	end

	if v2.ScreenGui then
		v2.ScreenGui:Destroy()
		v2.ScreenGui = nil
	end

	v.internal.WidgetData[p] = nil
end

function v.internal.mountWidget(p)
	local widgetScreenGui = v.internal.createWidgetScreenGui(p)
	assert(widgetScreenGui, `Widget parent doesn't exist for '{p.Name}'`)
	local v2 = v.internal.WidgetData[p.Name]
	v2.DestroyFunction = p.CreateFunction(widgetScreenGui)

	if typeof(v2.DestroyFunction) == "function" then
		if #widgetScreenGui:GetChildren() == 0 then
			v.internal.removeWidget(p.Name)
			warn(`Widget '{p.Name}' didn't create any interface elements.`)
		else
			v2.Mounted = true
			v.interface.WidgetMounted:Fire(p.Name, widgetScreenGui)
		end
	else
		v.internal.removeWidget(p.Name)
		warn(`Widget '{p.Name}' needs to return a destructor of a type 'function' got '{typeof(v2.DestroyFunction)}'`)
	end
end

function v.internal.unmountWidget(p)
	local v2 = v.internal.WidgetData[p.Name]

	if not (v2 and v2.Mounted) then
		return
	end

	if v2.DestroyFunction then
		v2.DestroyFunction()
	end

	if v2.ScreenGui then
		local children = v2.ScreenGui:GetChildren()

		if #children > 0 then
			warn(`Widget '{p.Name}' didn't cleanup unmounted interface properly, there are leftover elements:`)

			for _, v3 in children do
				warn(`  ╠ {v3.Name}({v3.ClassName})`)
			end
		end

		v2.ScreenGui:Destroy()
		v2.ScreenGui = nil
	end

	v2.Mounted = false
	v.interface.WidgetUnmounted:Fire(p.Name)
end

function v.internal.getWidgetData(p: string)
	return v.internal.WidgetData[p]
end

function v.interface.new(name: string, createFunction)
	assert(type(name) == "string", `Expected parameter #1 'widgetName' to be a string, got {type(name)}`)
	assert(
		type(createFunction) == "function",
		`Expected parameter #2 'widgetCreateFunction' to be a function, got {type(createFunction)}`
	)
	v.internal.addWidget({ Name = name, CreateFunction = createFunction })
end

function v.interface.GetAll(_)
	local result = {}

	for k, v2 in v.internal.WidgetData do
		result[k] = { Mounted = v2.Mounted, ScreenGui = v2.ScreenGui }
	end

	return result
end

function v.interface:Hide(p: string)
	local widgetData = v.internal.getWidgetData(p)

	if widgetData and widgetData.Mounted then
		v.internal.unmountWidget(widgetData.Widget)
	end
end

function v.interface:Show(p: string)
	local widgetData = v.internal.getWidgetData(p)

	if widgetData and not widgetData.Mounted then
		v.internal.mountWidget(widgetData.Widget)
	end
end

function v.interface:IsVisible(p: string)
	local widgetData = v.internal.getWidgetData(p)
	return widgetData and widgetData.Mounted or false
end

function v.interface.SwitchVisibility(_, p: string)
	if v.interface:IsVisible(p) then
		v.interface:Hide(p)
	else
		v.interface:Show(p)
	end
end

return v.interface