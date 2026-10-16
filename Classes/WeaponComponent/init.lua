local WeaponComponent = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
require(script:WaitForChild("Types"))
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local CharacterAnimator = require(script.Classes.CharacterAnimator)
local Viewmodel = require(script.Classes.Viewmodel)

function WeaponComponent.new(player, identifier: string, id: string, slot: number, name: string, skin: string, float: number, statTrack, nameTag, originalOwner: string?, charm, stickers, character)
	debug.profilebegin("WeaponComponent.new")
	local class = {}
	debug.profilebegin("WeaponComponent.new.Janitor")
	class.Janitor = Janitor.new()
	class.IsDestroyed = false
	debug.profileend()
	class.OriginalOwner = originalOwner
	class.Identifier = identifier
	class.StatTrack = statTrack
	class.Stickers = stickers
	class.NameTag = nameTag
	class.Player = player
	class.Character = character
	class.Float = float
	class.Name = name
	class.Charm = charm
	class.Skin = skin
	class.Slot = slot
	class._id = id
	debug.profilebegin("WeaponComponent.new.GetWeaponProperties")
	class.Properties = GetWeaponProperties(name)
	debug.profileend()
	debug.profilebegin("WeaponComponent.new.CharacterAnimator")
	class.CharacterAnimator = CharacterAnimator.new(class.Player, name, character)
	debug.profileend()
	debug.profilebegin("WeaponComponent.new.Viewmodel")
	local claim = Viewmodel.claim(class, name, skin)
	local result, success

	if claim then
		result = claim
		success = true
	else
		success, result = pcall(Viewmodel.new, class, name, skin)
	end

	debug.profileend()

	if not success then
		debug.profileend()
		error(result, 2)
	end

	class.Viewmodel = result
	debug.profilebegin("WeaponComponent.new.CleanupCallbacks")
	class.Janitor:Add(function()
		if class.CharacterAnimator then
			class.CharacterAnimator:destroy()
			class.CharacterAnimator = nil
		end
	end)
	class.Janitor:Add(function()
		if class.Viewmodel then
			class.Viewmodel:release()
			class.Viewmodel = nil
		end
	end)
	debug.profileend()

	function class:updateStatTrackCounter(statTrack2)
		self.StatTrack = statTrack2

		if not self.StatTrack then
			return
		end

		local killTrak = self.Viewmodel.Model:FindFirstChild("KillTrak", true)

		if killTrak then
			killTrak.Screen.SurfaceGui.TextLabel.Text = Skins.GetKillTrackValue(statTrack2, self.Name)
		end
	end

	if claim and statTrack then
		class:updateStatTrackCounter(statTrack)
	end

	debug.profileend()
	return class
end

function WeaponComponent:destroy()
	debug.profilebegin("WeaponComponent.destroy")

	if self.CharacterAnimator then
		self.CharacterAnimator:destroy()
		self.CharacterAnimator = nil
	end

	if self.Viewmodel then
		self.Viewmodel:release()
		self.Viewmodel = nil
	end

	if self.Janitor then
		self.Janitor:Destroy()
		self.Janitor = nil
	end

	self.updateStatTrackCounter = nil
	self.OriginalOwner = nil
	self.Properties = nil
	self.Identifier = nil
	self.StatTrack = nil
	self.Stickers = nil
	self.NameTag = nil
	self.Player = nil
	self.Character = nil
	self.Float = nil
	self.Name = nil
	self.Charm = nil
	self.Skin = nil
	self.Slot = nil
	self._id = nil
	debug.profileend()
end

return WeaponComponent