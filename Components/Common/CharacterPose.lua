local v = {}

local function findMotor(instance, childName: string) -- 4 equivalent calls inferred from this helper
	local motor6D = instance:FindFirstChild(childName, true)

	if motor6D and motor6D:IsA("Motor6D") then
		return motor6D
	end

	return nil
end

function v.getJoints(instance)
	local motor = findMotor(instance, "RightShoulder") -- inferred equivalent call
	local motor2 = findMotor(instance, "LeftShoulder") -- inferred equivalent call
	local motor3 = findMotor(instance, "Waist") -- inferred equivalent call

	if not (motor and motor2 and motor3) then
		return nil
	end

	local motor4 = findMotor(instance, "Neck") -- inferred equivalent call
	local v2 = {
		RightShoulder = motor,
		LeftShoulder = motor2,
		Waist = motor3,
		Neck = motor4,
		BaseRightShoulderC0 = motor.C0,
		BaseLeftShoulderC0 = motor2.C0,
		BaseWaistC0 = motor3.C0,
		BaseNeckC0 = 0,
		LastVerticalLook = nil
	}
	local baseNeckC

	if motor4 then
		baseNeckC = motor4.C0
	end

	v2.BaseNeckC0 = baseNeckC
	return v2
end

function v.composeRootCFrame(position: Vector3, p: number)
	return CFrame.new(position) * CFrame.Angles(0, p, 0)
end

function v.predictHeadCFrame(data, cframe: CFrame, p: number, value: number)
	local waist = data.Waist
	local neck = data.Neck

	if
		not waist.Part0
		or not waist.Part1
		or not neck
		or not neck.Part1
		or neck.Part0 ~= waist.Part1
		or not data.BaseNeckC0
	then
		return nil
	end

	local v2 = math.clamp(value, -1, 1)
	local v3 = waist.Part0.CFrame * data.BaseWaistC0 * CFrame.Angles(v2 * 0.6283185307179585, 0, 0) * waist.Transform * waist.C1:Inverse() * data.BaseNeckC0 * CFrame.Angles(v2 * 1.0471975511965976, 0, 0) * neck.Transform * neck.C1:Inverse()
	return v.composeRootCFrame(cframe.Position, p) * cframe:Inverse() * v3
end

function v:applyVerticalLook(value: number, value2: number?)
	local lastVerticalLook = math.clamp(value, -1, 1)

	if self.LastVerticalLook ~= nil and (value2 or 0.0001) > math.abs(lastVerticalLook - self.LastVerticalLook) then
		return
	end

	self.RightShoulder.C0 = self.BaseRightShoulderC0 * CFrame.Angles(lastVerticalLook * 0.5235987755982988, 0, 0)
	self.LeftShoulder.C0 = self.BaseLeftShoulderC0 * CFrame.Angles(lastVerticalLook * 0.5235987755982988, 0, 0)
	self.Waist.C0 = self.BaseWaistC0 * CFrame.Angles(lastVerticalLook * 0.6283185307179585, 0, 0)
	local neck = self.Neck
	local baseNeckC0 = self.BaseNeckC0

	if neck and baseNeckC0 then
		neck.C0 = baseNeckC0 * CFrame.Angles(lastVerticalLook * 1.0471975511965976, 0, 0)
	end

	self.LastVerticalLook = lastVerticalLook
end

return table.freeze(v)