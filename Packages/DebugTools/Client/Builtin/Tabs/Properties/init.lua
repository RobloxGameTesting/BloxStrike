local parent = script.Parent.Parent.Parent
local Tab = require(parent.Tab)
local Imgui = require(parent.Imgui)
local ClassIndex = require((parent.Vendor:WaitForChild("ClassIndex")))
local Explorer = require(script.Parent.Explorer)
require(script.PropertyLabel)
local v = { interface = {}, internal = {} }

function v.internal.getPropertiesFor(instance)
	local classSuperclasses = ClassIndex.FetchClassSuperclasses(instance.ClassName)
	table.insert(classSuperclasses, 1, instance.ClassName)
	local result = {}

	for _, classSuperclass in classSuperclasses do
		result[classSuperclass] = {}
	end

	for _, classSuperclass in classSuperclasses do
		if classSuperclass == "<<<ROOT>>>" then
			continue
		end

		local classMembers = ClassIndex.FetchClassMembers(classSuperclass)

		for _, classMember in classMembers do
			local classMemberType = ClassIndex.FetchClassMemberType(classSuperclass, classMember)

			if
				ClassIndex.FetchClassMemberTags(classSuperclass, classMember).Deprecated
				or classMemberType ~= "Property"
			then
				continue
			end

			table.insert(result[classSuperclass], classMember)
		end
	end

	return result
end

Tab.new("Properties", function(p)
	return Imgui:Connect(p, function()
		Imgui:ScrollingFrameY(UDim2.fromScale(1, 1))
		Imgui:BeginVertical()
		local selectedObject = Explorer.getSelectedObject()

		if selectedObject then
			local propertiesFor = v.internal.getPropertiesFor(selectedObject)
			Imgui:Label(`<b><i>{selectedObject.ClassName}</i> ["{selectedObject:GetFullName()}"]</b>`)

			for k, v2 in propertiesFor do
				if #v2 == 0 then
					continue
				end

				Imgui:Label("")
				Imgui:Label(`<b><i>Superclass</i> [{k}]</b>`)

				for _, v3 in v2 do
					Imgui:PropertyLabel(selectedObject, v3)
				end
			end
		else
			Imgui:Label("No instace currently selected, please go to the 'Explorer' page and select an instance.")
		end

		Imgui:End()
		Imgui:End()
	end)
end)
return v.interface