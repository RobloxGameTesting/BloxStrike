local Players = game:GetService("Players")
local parent = script.Parent.Parent.Parent.Parent.Parent
local ArgumentType = require(parent.Parent.Shared.Enums.ArgumentType)
local StringPropertyComponent = require(parent.Components.StringPropertyComponent)
local NumberPropertyComponent = require(parent.Components.NumberPropertyComponent)
local DropdownPropertyComponent = require(parent.Components.DropdownPropertyComponent)
local CheckmarkPropertyComponent = require(parent.Components.CheckmarkPropertyComponent)
return function(parent2, data, callback)
	local propertyText = data.Name and `{string.gsub(data.Name, "^%l", string.upper)}:` or `#{data.Index} argument:`
	local v = nil

	if data.Type == ArgumentType.Player then
		local displayNames = {}

		for _, v2 in Players:GetPlayers() do
			table.insert(displayNames, v2.DisplayName)
		end

		v = DropdownPropertyComponent(
			{
				PropertyText = propertyText,
				Value = Players.LocalPlayer.DisplayName,
				Options = displayNames,
				Parent = parent2
			},
			function(p: string)
				for _, v2 in Players:GetPlayers() do
					if v2.DisplayName ~= p then
						continue
					end

					callback(v2)
					break
				end
			end
		)
		callback(Players.LocalPlayer)
	elseif data.Options then
		v = DropdownPropertyComponent({
			PropertyText = propertyText,
			Value = data.Default or data.Options[1],
			Options = data.Options,
			Parent = parent2
		}, function(p)
			callback(p)
		end)
	elseif data.Type == ArgumentType.boolean then
		v = CheckmarkPropertyComponent(
			{ PropertyText = propertyText, Value = data.Default, Parent = parent2 },
			function(flag: boolean)
				callback(flag)
			end
		)
	elseif data.Type == ArgumentType.string then
		v = StringPropertyComponent(
			{
				PropertyText = propertyText,
				Value = data.Default,
				Default = data.Default,
				Parent = parent2
			},
			function(p: string)
				callback(p)
			end
		)
	elseif data.Type == ArgumentType.number then
		v = NumberPropertyComponent(
			{
				PropertyText = propertyText,
				Value = data.Default,
				Default = data.Default,
				Parent = parent2
			},
			function(p: number)
				callback(p)
			end
		)
	end

	return function()
		if v then
			v()
		end
	end
end