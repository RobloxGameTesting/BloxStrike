local AttachCharm = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local v = nil
AttachCharm.ActionType = "AttachCharm"

local function IsCharmEligibleWeapon(p) -- 4 equivalent calls inferred from this helper
	return p.Type == "Weapon" or p.Type == "Zeus x27"
end

local function WeaponsWithoutCharm(p, _)
	if not IsCharmEligibleWeapon(p) then -- inferred equivalent call
		return false
	end

	return p.Charm == nil
		or p.Charm == false
		or type(p.Charm) ~= "string" and p.Charm ~= true and type(p.Charm) ~= "table"
end

local function AllCharms(p, _)
	if p.Type ~= "Charm" then
		return false
	end

	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not inventory then
		return true
	end

	for _, v2 in ipairs(inventory) do
		if not v2.Charm then
			continue
		end

		local id = type(v2.Charm) == "table" and v2.Charm._id

		if not id then
			if type(v2.Charm) == "string" then
				id = v2.Charm
			else
				id = false
			end
		end

		if id == p._id then
			return false
		end
	end

	return true
end

function AttachCharm.GetFilter(p)
	if IsCharmEligibleWeapon(p) then -- inferred equivalent call
		return AllCharms
	end

	if p.Type == "Charm" then
		return WeaponsWithoutCharm
	end

	return function()
		return false
	end
end

function AttachCharm.GetContext(sourceItem)
	return {
		ActionType = AttachCharm.ActionType,
		SourceItem = sourceItem,
		Title = sourceItem.Type == "Charm" and "Select Weapon" or "Select Charm"
	}
end

function AttachCharm.OnItemSelected(weaponItem, p)
	if not p.SourceItem then
		return
	end

	local sourceItem = p.SourceItem
	local id, id2

	if IsCharmEligibleWeapon(sourceItem) then -- inferred equivalent call
		if weaponItem.Type ~= "Charm" then
			return
		end

		id = sourceItem._id
		id2 = weaponItem._id
		weaponItem = sourceItem
	else
		if not (sourceItem.Type == "Charm" and IsCharmEligibleWeapon(weaponItem)) then -- inferred equivalent call
			return
		end

		id = weaponItem._id
		id2 = sourceItem._id
	end

	v = { WeaponId = id, CharmId = id2, WeaponItem = weaponItem }
	Router.broadcastRouter(
		"WeaponInspect",
		weaponItem.Name,
		weaponItem.Skin,
		weaponItem.Float,
		weaponItem.StatTrack,
		weaponItem.NameTag,
		{ _id = id2, Position = "1" },
		weaponItem.Stickers,
		weaponItem.Type,
		weaponItem.Pattern,
		weaponItem._id,
		weaponItem.Serial,
		weaponItem.IsTradeable
	)
end

function AttachCharm.ConfirmAttachment()
	if not v then
		return false
	end

	local v2 = Router.broadcastRouter("GetCurrentCharmPosition") or 1
	Remotes.Inventory.UpdateWeaponCharm.Send({
		WeaponId = v.WeaponId,
		CharmId = v.CharmId,
		Position = tostring(v2)
	})
	v = nil
	Router.broadcastRouter("WeaponInspectClose")
	return true
end

function AttachCharm.CancelAttachment()
	if not v then
		return false
	end

	v = nil
	Router.broadcastRouter("WeaponInspectClose")
	return true
end

function AttachCharm.HasPendingAttachment()
	return v ~= nil
end

function AttachCharm.Initialize()
	MenuState.OnInspectStateChanged:Connect(function(flag: boolean)
		if not flag and v then
			v = nil
		end
	end)
	Router.observerRouter("ConfirmCharmAttachment", AttachCharm.ConfirmAttachment)
	Router.observerRouter("HasPendingCharmAttachment", AttachCharm.HasPendingAttachment)
	Router.observerRouter("CancelCharmAttachment", AttachCharm.CancelAttachment)
end

return AttachCharm