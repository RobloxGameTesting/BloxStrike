local SceneRegistry = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local v = {
	Default = {
		AssetFolder = "CaseScene",
		InteractionType = "Click",
		Animations = {
			CaseFall = "rbxassetid://91366765923171",
			CloseIdle = "rbxassetid://96896409518629",
			CaseOpening = "rbxassetid://100000665946048",
			OpenIdle = "rbxassetid://127592440292292"
		},
		Sounds = { Drop = "Case Fall", Opening = "Case Opening" }
	},
	CharmCapsule = {
		AssetFolder = "CharmScene",
		InteractionType = "Drag",
		Animations = { PackOpening = "rbxassetid://97837283629886" },
		DragSettings = { Threshold = 0.5, EndKeyframe = "DragEndPoint" },
		Sounds = { DragStart = "Charm Drag Start", DragLoop = "Charm Drag Loop" }
	},
	Package = {
		AssetFolder = "PackageScene",
		InteractionType = "Click",
		Animations = {
			CaseFall = "rbxassetid://134599478765866",
			CloseIdle = "rbxassetid://119593507010060",
			CaseOpening = "rbxassetid://97681949800792"
		},
		AnimationKeyframeSounds = {
			CaseFall = { Drop = "Package Drop" },
			CaseOpening = {
				RightTape = "Package Right Tape",
				LeftTape = "Package Left Tape",
				FrontLid = "Package Front Lid",
				FinalOpen = "Package Final Open"
			}
		}
	},
	Console = {
		AssetFolder = "ConsoleScene",
		InteractionType = "Click",
		Animations = {
			CaseFall = "rbxassetid://127945219825547",
			CaseOpening = "rbxassetid://136396496384739"
		},
		Sounds = { Enter = "Console Enter Animation", Opening = "Console Open Animation" },
		ConsoleColumnCount = 8
	},
	KnifeConsole = {
		AssetFolder = "KnifeConsoleScene",
		InteractionType = "Click",
		Animations = {
			CaseFall = "rbxassetid://127945219825547",
			CaseOpening = "rbxassetid://136396496384739"
		},
		Sounds = { Enter = "Console Enter Animation", Opening = "Console Open Animation" },
		ConsoleColumnCount = 10
	}
}
local v2 = {
	Case = "Default",
	["Sticker Capsule"] = "Default",
	["Charm Capsule"] = "CharmCapsule",
	Package = "Package",
	Console = "Console"
}

local function hasSpecialItems(p)
	if p.specialContents and #p.specialContents > 0 then
		return true
	end

	for _, content in p.contents do
		if content.isSpecial or content.rarity == "Special" then
			return true
		end
	end

	return false
end

function SceneRegistry.GetSceneForCase(p: string, p2)
	if p ~= "Console" or not p2 then
		return v2[p] or "Default"
	end

	local flag

	if p2.specialContents and #p2.specialContents > 0 then
		flag = true
	else
		local flag2 = true

		for _, content in p2.contents do
			if not (content.isSpecial or content.rarity == "Special") then
				continue
			end

			flag = true
			flag2 = false
			break
		end

		if flag2 then
			flag = false
		end
	end

	if flag then
		return "KnifeConsole"
	end

	return v2[p] or "Default"
end

function SceneRegistry.GetConfig(p: string)
	return v[p]
end

function SceneRegistry.GetAllSceneNames()
	local result = {}

	for k in v do
		table.insert(result, k)
	end

	return result
end

return SceneRegistry