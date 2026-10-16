local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maps = ReplicatedStorage.Database.Custom.GameStats.Maps
local MapIcon = {}
local rect = Rect.new(0, 0, 0, 0)
local frozen = table.freeze({
	["rbxassetid://72973444783842"] = Rect.new(280, 308, 756, 720),
	["rbxassetid://96627370550320"] = Rect.new(296, 296, 688, 712),
	["rbxassetid://88605850938693"] = Rect.new(252, 236, 748, 764),
	["rbxassetid://139602408955630"] = Rect.new(260, 364, 760, 648),
	["rbxassetid://118014135553992"] = Rect.new(240, 304, 784, 772),
	["rbxassetid://95578841758233"] = Rect.new(268, 252, 756, 772),
	["rbxassetid://78468254134558"] = Rect.new(276, 320, 716, 728)
})
local v = {}

local function Read(childName: string, p: string)
	if childName == "" then
		return ""
	end

	local v2 = v[childName]

	if not v2 then
		v2 = {}
		v[childName] = v2
	end

	local v3 = v2[p]

	if v3 then
		return v3
	end

	local moduleScript = Maps:FindFirstChild(childName)
	local v4 = ""

	if moduleScript and moduleScript:IsA("ModuleScript") then
		local success, result = pcall(require, moduleScript)

		if success and typeof(result) == "table" then
			v4 = tostring(result[p] or "")
		end
	end

	if v4 ~= "" then
		v2[p] = v4
	end

	return v4
end

function MapIcon.Get(p: string)
	return (Read(p, "Icon"))
end

function MapIcon.GetRadar(p: string)
	local read = Read(p, "Radar")

	if read == "" then
		return MapIcon.Get(p), rect
	end

	return read, frozen[read] or rect
end

return MapIcon