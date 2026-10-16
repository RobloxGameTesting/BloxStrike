local Workspace = game:GetService("Workspace")
local cframe = CFrame.new(0, 10000, 0)
local v2 = nil

local function getStash()
	local v = v2

	if v and v.Parent == Workspace then
		return v
	end

	local folder = Instance.new("Folder")
	folder.Name = "ThirdPersonWeaponStash"
	folder.Archivable = false
	folder.Parent = Workspace
	v2 = folder
	return folder
end

local v = {
	Park = function(self, list)
		for _, v in list do
			local part1 = v.Part1
			v:Destroy()

			if part1 then
				part1.Anchored = true
			end
		end

		table.clear(list)
		self:PivotTo(cframe)
		local parent = v2

		if not parent or parent.Parent ~= Workspace then
			parent = Instance.new("Folder")
			parent.Name = "ThirdPersonWeaponStash"
			parent.Archivable = false
			parent.Parent = Workspace
			v2 = parent
		end

		self.Parent = parent
	end,
	PoseForJoint = function(instance, p, p2, cframe2: CFrame, cframe3: CFrame)
		if p.Anchored then
			instance:PivotTo(p2.CFrame * cframe2 * cframe3:Inverse() * p.CFrame:Inverse() * instance:GetPivot())
		end
	end,
	Release = function(items)
		for _, item in items do
			local part1 = item.Part1

			if part1 then
				part1.Anchored = false
			end
		end
	end,
	TryUnpark = function(self, parent)
		return pcall(function()
			self.Parent = parent
		end)
	end
}
return table.freeze(v)