local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local v2 = nil

local function getParking()
	local v = v2

	if v and v.Parent == ReplicatedStorage then
		return v
	end

	local folder = Instance.new("Folder")
	folder.Name = "ParkedScenes"
	folder.Archivable = false
	folder.Parent = ReplicatedStorage
	v2 = folder
	return folder
end

local v = {
	Park = function(p)
		pcall(function()
			local v = p
			local parent = v2

			if not parent or parent.Parent ~= ReplicatedStorage then
				parent = Instance.new("Folder")
				parent.Name = "ParkedScenes"
				parent.Archivable = false
				parent.Parent = ReplicatedStorage
				v2 = parent
			end

			v.Parent = parent
		end)
	end,
	Unpark = function(self)
		if self.Parent ~= Workspace then
			self.Parent = Workspace
		end
	end
}
return table.freeze(v)