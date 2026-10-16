local Enums = require(script.Parent.Parent.Enums)
local Serial = require(script.Parent.Parent.Serial)
local Config = require(script.Parent.Parent.Simulation.Config)
local State = require(script.Parent.Parent.Simulation.State)
require(script.Parent.Parent.Types)

local function finiteSpeed(predictedBaseMoveSpeed) -- 1 equivalent call inferred from this helper
	return type(predictedBaseMoveSpeed) == "number"
		and predictedBaseMoveSpeed == predictedBaseMoveSpeed
		and math.abs(predictedBaseMoveSpeed) < 1e999
end

return table.freeze({
	forCommand = function(data, data2, p: number, callback, flag: boolean, flag2: boolean?)
		local predictedWeaponMoveSpeed = data2.PredictedWeaponMoveSpeed or data.WeaponMoveSpeed
		local predictedWeaponScopedMoveSpeed = data2.PredictedWeaponScopedMoveSpeed or data.WeaponScopedMoveSpeed
		local predictedBaseMoveSpeed

		if not flag then
			predictedBaseMoveSpeed = data2.PredictedBaseMoveSpeed
		end

		if predictedBaseMoveSpeed == nil and callback ~= nil then
			predictedBaseMoveSpeed = callback(
				data.BaseMoveSpeed,
				p,
				predictedWeaponMoveSpeed,
				predictedWeaponScopedMoveSpeed,
				Enums.Buttons.has(data2.Buttons, Enums.Buttons.Scoped)
			)
		end

		if not finiteSpeed(predictedBaseMoveSpeed) then -- inferred equivalent call
			predictedBaseMoveSpeed = data.BaseMoveSpeed
		end

		local v = math.clamp(predictedBaseMoveSpeed, 0, Config.Default.MaxBaseMoveSpeed)
		local baseMoveSpeed = flag2 and 0 or v

		if
			baseMoveSpeed == data.BaseMoveSpeed
			and predictedWeaponMoveSpeed == data.WeaponMoveSpeed
			and predictedWeaponScopedMoveSpeed == data.WeaponScopedMoveSpeed
		then
			return data
		end

		local clone = State.clone(data)
		clone.BaseMoveSpeed = baseMoveSpeed
		clone.WeaponMoveSpeed = math.clamp(predictedWeaponMoveSpeed, 0, Config.Default.MaxBaseMoveSpeed)
		clone.WeaponScopedMoveSpeed = math.clamp(predictedWeaponScopedMoveSpeed, 0, Config.Default.MaxBaseMoveSpeed)
		return clone
	end,
	serverTimeAtTick = function(p, p2: number, p3: number)
		return p.ServerTime + Serial.deltaUInt32(p2, p.ServerTick) * p3
	end
})