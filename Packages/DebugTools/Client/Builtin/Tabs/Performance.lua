local RunService = game:GetService("RunService")
local parent = script.Parent.Parent.Parent
local Tab = require(parent.Tab)
local Imgui = require(parent.Imgui)
local frozen = table.freeze({ 60, 45, 30, 20, 15 })
local v = {
	internal = {
		FPSCap = { Enabled = false, Cap = 0 }
	},
	interface = {}
}

function v.internal.FPSCap.Set(cap: number)
	local fpsCap = v.internal.FPSCap

	if cap and cap ~= 0 then
		local enabled = fpsCap.Enabled
		fpsCap.Enabled = true
		fpsCap.Cap = cap

		if not enabled then
			task.spawn(function()
				while fpsCap.Enabled do
					local now = os.clock()
					RunService.Heartbeat:Wait()

					if fpsCap.Cap <= 0 then
						break
					else
						while not (now + 1 / fpsCap.Cap < os.clock()) do

						end
					end
				end
			end)
		end
	else
		fpsCap.Enabled = false
		fpsCap.Cap = 0
	end
end

function v.interface.IsFPSCapEnabled(_)
	return v.internal.FPSCap.Enabled
end

function v.interface.GetFPSCap(_)
	return v.internal.FPSCap.Cap
end

Tab.new("Performance", function(p)
	local fpsCap = v.internal.FPSCap
	return Imgui:Connect(p, function()
		Imgui:BeginHorizontal()
		Imgui:BeginGroup(UDim2.fromScale(0.5, 1))
		Imgui:BeginVertical()
		Imgui:Label(`FPS Cap - {fpsCap.Enabled and `Enabled ({fpsCap.Cap})` or "Disabled"}`)
		Imgui:BeginHorizontal()

		for _, v2 in frozen do
			if Imgui:Button(v2).activated() then
				fpsCap.Set(v2)
			end
		end

		if fpsCap.Enabled and Imgui:Button("Disable Cap").activated() then
			fpsCap.Set(0)
		end

		Imgui:End()
		Imgui:End()
		Imgui:End()
		Imgui:End()
	end)
end)
return v.interface