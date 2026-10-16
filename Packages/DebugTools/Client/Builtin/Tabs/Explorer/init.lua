local parent = script.Parent.Parent.Parent
local Tab = require(parent.Tab)
local Imgui = require(parent.Imgui)
require(script.ClassIcon)
require(script.BeginExplorerHorizontal)
local v = {
	interface = {},
	internal = { ExpandedInstances = {}, SelectedInstance = nil }
}

function v.internal.processChildren(items, value: number?)
	for _, item in items do
		v.internal.processInstance(item, (value or -1) + 1)
	end
end

function v.internal.processInstance(selectedInstance, p: number)
	local children = selectedInstance:GetChildren()
	local v2 = #children == 0 and ""
		or v.internal.ExpandedInstances[selectedInstance]
		and "rbxasset://studio_svg_textures/Shared/Navigation/Dark/Standard/ArrowDown.png"
		or "rbxasset://studio_svg_textures/Shared/Navigation/Dark/Standard/ArrowRight.png"

	if Imgui:BeginExplorerHorizontal(v.internal.SelectedInstance == selectedInstance).activated() then
		v.internal.SelectedInstance = selectedInstance
	end

	Imgui:BeginGroup(UDim2.fromOffset(p * 10, 0))
	Imgui:End()

	if Imgui:ImageButton(UDim2.fromOffset(16, 16), v2).activated() then
		v.internal.ExpandedInstances[selectedInstance] = not v.internal.ExpandedInstances[selectedInstance]
	end

	Imgui:ExplorerClassIcon(UDim2.fromOffset(16, 16), selectedInstance)
	Imgui:BeginGroup(UDim2.fromOffset(5, 0))
	Imgui:End()
	Imgui:Label(`<i>{selectedInstance.ClassName}</i> ["{selectedInstance.Name}"]`)
	Imgui:End()

	if v.internal.ExpandedInstances[selectedInstance] then
		v.internal.processChildren(children, p + 1)
	end
end

function v.interface.getSelectedObject()
	return v.internal.SelectedInstance
end

Tab.new("Explorer", function(p)
	return Imgui:Connect(p, function()
		Imgui:ScrollingFrameY(UDim2.fromScale(1, 1))
		Imgui:BeginVertical()
		local processChildren = v.internal.processChildren
		local Workspace = game:GetService("Workspace")
		local Players = game:GetService("Players")
		local Lighting = game:GetService("Lighting")
		local MaterialService = game:GetService("MaterialService")
		local ReplicatedFirst = game:GetService("ReplicatedFirst")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local ServerScriptService = game:GetService("ServerScriptService")
		local ServerStorage = game:GetService("ServerStorage")
		local StarterGui = game:GetService("StarterGui")
		local StarterPack = game:GetService("StarterPack")
		local StarterPlayer = game:GetService("StarterPlayer")
		local Teams = game:GetService("Teams")
		local SoundService = game:GetService("SoundService")
		local Chat = game:GetService("Chat")
		local TextChatService = game:GetService("TextChatService")
		local VoiceChatService = game:GetService("VoiceChatService")
		processChildren({
			Workspace,
			Players,
			Lighting,
			MaterialService,
			ReplicatedFirst,
			ReplicatedStorage,
			ServerScriptService,
			ServerStorage,
			StarterGui,
			StarterPack,
			StarterPlayer,
			Teams,
			SoundService,
			Chat,
			TextChatService,
			VoiceChatService,
			game:GetService("LocalizationService")
		})
		Imgui:End()
		Imgui:End()
	end)
end)
return v.interface