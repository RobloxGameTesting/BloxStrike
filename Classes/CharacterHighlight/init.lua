local CharacterHighlight = {}
CharacterHighlight.__index = CharacterHighlight
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script:WaitForChild("Types"))
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Spring = require(ReplicatedStorage.Shared.Spring)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)

local function applyFill(state, p: number)
	local fillColor

	if state.OutlineOnly then
		fillColor = state.Properties.OutlineColor:Lerp(Color3.new(1, 1, 1), 0.2)
		p = 0.9
	else
		fillColor = state.Properties.FillColor
	end

	if state.AppliedFillColor ~= fillColor then
		state.Highlight.FillColor = fillColor
		state.AppliedFillColor = fillColor
	end

	if state.AppliedFillTransparency ~= p then
		state.Highlight.FillTransparency = p
		state.AppliedFillTransparency = p
	end
end

function CharacterHighlight:UpdateState(flag: boolean)
	if not (self.Highlight and self.Highlight.Parent) then
		return
	end

	if self.IsEnabled ~= flag then
		if flag then
			applyFill(self, self.CurrentTransparency:getPosition())
		end

		self.Highlight.Enabled = flag
		self.IsEnabled = flag
	end
end

function CharacterHighlight.new(character, properties)
	local object = setmetatable({}, CharacterHighlight)
	object.Janitor = Janitor.new()
	object.CurrentTransparency = Spring.new(0.95, 1.5, 0.6)
	object.Properties = properties
	object.Character = character
	local highlight = object.Janitor:Add(Instance.new("Highlight", character))
	highlight.Enabled = false
	highlight.OutlineTransparency = properties.OutlineTransparency
	highlight.FillTransparency = properties.FillTransparency
	highlight.OutlineColor = properties.OutlineColor
	highlight.DepthMode = properties.DepthMode
	highlight.FillColor = properties.FillColor
	object.Highlight = highlight
	object.IsEnabled = false
	object.OutlineOnly = false

	if CharacterResolver.isAliveCharacter(character) then
		object.Janitor:Add(character:GetAttributeChangedSignal("Dead"):Connect(function()
			if character:GetAttribute("Dead") then
				object:Destroy()
			end
		end))
	end

	local bindingName = RunServiceController.CreateBindingName("Classes.CharacterHighlight.Pulse")
	object.Janitor:Add(RunServiceController.BindToHeartbeat(bindingName, function(p: number)
		if not (object.IsEnabled and object.Highlight and object.Highlight.Parent) then
			return
		end

		local position = object.CurrentTransparency:getPosition()
		object.CurrentTransparency:update(p)

		if position >= 0.8 then
			object.CurrentTransparency:setGoal(0.6)
		elseif position <= 0.6 then
			object.CurrentTransparency:setGoal(0.8)
		end

		applyFill(object, position)
	end))
	return object
end

function CharacterHighlight:Destroy()
	self.Janitor:Destroy()
end

return CharacterHighlight