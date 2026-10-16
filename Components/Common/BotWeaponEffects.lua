local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EmitParticles = require(script.Parent.VFXLibary.CreateMuzzleFlash.EmitParticles)
local CreateTracer = require(script.Parent.VFXLibary.CreateTracer)
local Sound = require(ReplicatedStorage.Classes.Sound)
local FlashEffect = require(script.Parent.VFXLibary.FlashEffect)

local function playSound(name: string, childName: string, position: Vector3, flag: boolean?)
	local sounds = ReplicatedStorage:FindFirstChild("Sounds")
	local child

	if sounds then
		child = sounds:FindFirstChild(name)
	end

	if child == nil or child:FindFirstChild(childName) == nil then
		return
	end

	local v = Sound.new(name)

	if not flag then
		v:PlaySoundAtPosition(
			{ Class = name, Name = childName, Position = position },
			nil,
			FlashEffect.GetAudioFadeMultiplier()
		)
		return
	end

	v:play({ Parent = Players.LocalPlayer.PlayerGui, Name = childName }, FlashEffect.GetAudioFadeMultiplier())
	v:destroy()
end

return table.freeze({
	shoot = function(data, vector: Vector3, p: number, flag: boolean?)
		local count = #data.Muzzles

		if count == 0 then
			return
		end

		local muzzle = data.Muzzles[p % count + 1]
		local child

		if data.MuzzleType then
			child = muzzle:FindFirstChild(data.MuzzleType)
		end

		if child and not flag then
			EmitParticles(child)
		end

		local v = vector - muzzle.Position

		if v.Magnitude > 0.0001 and not flag then
			CreateTracer(v.Magnitude, muzzle.Position, v.Unit, true)
		end

		playSound(data.Name, "Shoot", muzzle.Position, flag)
	end,
	reloadSound = function(p, p2, flag: boolean?)
		playSound(p.Name, "MagOut", p2.Position, flag)
	end
})