local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local v = { ["Zeus x27"] = "Taser" }
local frozen = table.freeze({ ["Lebron James"] = "LeGoat", ["Medal.tv"] = "Medal" })
local v2 = {}

for k, v3 in v do
	v2[v3:lower()] = k
end

local v3 = {}

local function replaceCaseInsensitive(value: string, p: string, p2: string)
	if p == "" then
		return value
	end

	local lower = value:lower()
	local v4 = 1
	local v5 = {}

	while true do
		local v6, v7 = lower:find(p, v4, true)

		if not (v6 and v7) then
			break
		end

		table.insert(v5, value:sub(v4, v6 - 1))
		table.insert(v5, p2)
		v4 = v7 + 1
	end

	table.insert(v5, value:sub(v4))
	return table.concat(v5)
end

function v3.GetNameTag(value)
	if typeof(value) == "string" and value ~= "" then
		return value
	end

	return nil
end

local function escapeRichText(value: string) -- 1 equivalent call inferred from this helper
	return value:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

function v3.FormatNameLabelText(value: string, p)
	if v3.GetNameTag(p) then
		return `<i>{escapeRichText(value)}</i>` -- inferred equivalent call
	end

	return value
end

function v3:ApplyNameLabel(p: string, p2)
	if not (self and (self:IsA("TextLabel") or self:IsA("TextButton") or self:IsA("TextBox"))) then
		return
	end

	local v4 = v3.GetNameTag(p2) ~= nil

	if self:GetAttribute("NameTagRichTextDefault") == nil then
		self:SetAttribute("NameTagRichTextDefault", self.RichText)
	end

	if self:GetAttribute("NameTagFontStyleDefault") == nil then
		self:SetAttribute("NameTagFontStyleDefault", self.FontFace.Style.Name)
	end

	local nameTagFontStyleDefault = self:GetAttribute("NameTagFontStyleDefault")
	local fontFace = self.FontFace
	local v5

	if v4 or nameTagFontStyleDefault == "Italic" then
		v5 = Enum.FontStyle.Italic
	else
		v5 = Enum.FontStyle.Normal
	end

	self.FontFace = Font.new(fontFace.Family, fontFace.Weight, v5)
	self.RichText = v4 or self:GetAttribute("NameTagRichTextDefault") == true
	self.Text = v3.FormatNameLabelText(p, p2)
end

function v3.GetWeaponDisplayName(p: string?, p2)
	local nameTag = v3.GetNameTag(p2)

	if nameTag then
		return nameTag
	end

	if not p then
		return ""
	end

	local v4 = v[p]

	if v4 then
		return v4
	end

	for k, v5 in v do
		p = replaceCaseInsensitive(p, k:lower(), v5)
	end

	return p
end

function v3.GetSkinDisplayName(value: string?, flag: boolean?)
	if not value then
		return ""
	end

	if not value:find("PATTERN") then
		return frozen[value] or value
	end

	local v4, v5 = table.unpack(value:split("_PATTERN_"))

	if flag then
		return `{v4} • Pattern {v5}` or v4
	end

	return v4
end

function v3.GetFullItemDisplayName(p: string, p2: string, flag: boolean?, flag2: boolean?, p3)
	local skinInformation = Skins.GetSkinInformation(p, p2)

	if not skinInformation then
		return ""
	end

	local v4 = flag2 == nil or flag2
	local weaponDisplayName = v3.GetWeaponDisplayName(skinInformation.paintId, p3)

	if weaponDisplayName:find("PATTERN") then
		local v5, v6 = table.unpack(weaponDisplayName:split("_PATTERN_"))

		if v4 then
			return `{v5} • Pattern {v6}` or v5
		end

		return v5
	else
		local formatted = `{weaponDisplayName:split(" | ")[1]} | {v3.GetSkinDisplayName(p2, v4)}`
		local v5 = flag and "KillTrak™ " or ""

		if skinInformation.type == "Melee" or skinInformation.type == "Glove" then
			v5 ..= "★ "
		end

		return `{v5}{formatted}`
	end
end

function v3.GetInternalSearchQuery(p: string?)
	if not p then
		return ""
	end

	for k, v4 in v2 do
		p = replaceCaseInsensitive(p, k, v4)
	end

	return p
end

function v3.GetSearchIdentity(value: string?, value2: string?)
	local v4 = value or ""
	local weaponDisplayName = v3.GetWeaponDisplayName(v4)
	local skinDisplayName = v3.GetSkinDisplayName(value2 or "", true)

	if weaponDisplayName == v4 then
		return `{v4} | {skinDisplayName}`
	end

	return `{weaponDisplayName} | {skinDisplayName} {v4}`
end

return (setmetatable(v3, {
	__call = function(_, p: string, flag: boolean?)
		return v3.GetSkinDisplayName(p, flag)
	end
}))