local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local v = {}

local function findNeckMotor(instance)
	local upperTorso = instance:FindFirstChild("UpperTorso")
	local head

	if upperTorso then
		head = upperTorso:FindFirstChild("Head")
	end

	if head and head:IsA("Motor6D") then
		return head
	end

	local neck = instance:FindFirstChild("Neck", true)

	if neck and neck:IsA("Motor6D") then
		return neck
	end

	return nil
end

local function armFlinch(instance, vector: Vector3?)
	local v2 = v[instance]

	if not (v2 and v2.Neck.Parent) then
		local neckMotor = findNeckMotor(instance)

		if not neckMotor then
			warn(`[HitFlinch] No neck Motor6D found on {instance:GetFullName()}; hit flinch skipped`)
			return nil
		end

		local waist = instance:FindFirstChild("Waist", true)
		v2 = {
			Neck = neckMotor,
			BaseC1 = neckMotor.C1,
			Waist = waist,
			WaistBaseC1 = waist and waist.C1,
			HeadPitch = 0,
			BodyPitch = 0
		}
		v[instance] = v2
	end

	local part1 = v2.Neck.Part1
	local v3 = not (vector and part1) and createVector(0, 0, 1) or part1.CFrame:VectorToObjectSpace(vector)
	local vector2 = Vector3.new(v3.X, 0, v3.Z)
	v2.Axis = not (vector2.Magnitude > 0.01) and createVector(1, 0, 0) or (createVector(0, 1, 0)):Cross(vector2.Unit)
	local pivot

	if part1 then
		pivot = CFrame.new(0, -part1.Size.Y / 2, 0)
	else
		pivot = CFrame.identity
	end

	v2.Pivot = pivot
	return v2
end

RunServiceController.BindToRenderStep("CharacterController.HitFlinch.Update", function(p: number)
	local v2 = math.exp(p * -12)

	for k, v3 in pairs(v) do
		local neck = v3.Neck

		if neck.Parent then
			if not (v3.HeadPitch <= 0 and v3.BodyPitch <= 0) then
				v3.HeadPitch *= v2
				v3.BodyPitch *= v2

				if v3.HeadPitch + v3.BodyPitch <= 0.008726646259971648 then
					neck.C1 = v3.BaseC1

					if v3.Waist then
						v3.Waist.C1 = v3.WaistBaseC1
					end

					v3.HeadPitch = 0
					v3.BodyPitch = 0
				else
					local v4 = v3.HeadPitch + v3.BodyPitch * 0.5
					local v5 = v3.HeadPitch * 0.3 + v3.BodyPitch
					neck.C1 = v3.Pivot * CFrame.fromAxisAngle(v3.Axis, -v4) * v3.Pivot:Inverse() * v3.BaseC1

					if v3.Waist then
						v3.Waist.C1 = v3.WaistBaseC1 * CFrame.fromAxisAngle(v3.Axis, -v5)
					end
				end
			end
		else
			v[k] = nil
		end
	end
end)
local HitFlinch = {}

function HitFlinch.flickHead(p, vector: Vector3?)
	local v2 = armFlinch(p, vector)

	if v2 then
		v2.HeadPitch = math.min(1.5707963267948966, v2.HeadPitch + 1.2217304763960306)
	end
end

function HitFlinch.flinchBody(p, vector: Vector3?)
	local v2 = armFlinch(p, vector)

	if v2 then
		v2.BodyPitch = math.min(0.4363323129985824, v2.BodyPitch + 0.24434609527920614)
	end
end

return HitFlinch