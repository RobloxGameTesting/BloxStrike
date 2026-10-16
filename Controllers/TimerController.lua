local TimerController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local v = {}

local function WaitForTimersLoaded(p: number)
	local total = 0

	while not ReplicatedStorage:GetAttribute("TimersLoaded") do
		total += task.wait()

		if p <= total then
			break
		end
	end
end

local function FireTimerListeners(p: string) -- 1 equivalent call inferred from this helper
	local v2 = v[p]

	if not v2 or #v2 == 0 then
		return
	end

	local timer = TimerController.GetTimer(p)

	for _, v3 in v2 do
		v3(timer)
	end
end

function TimerController.GetTimer(p: string)
	local attribute = ReplicatedStorage:GetAttribute(`timers_source/{p}`)
	assert(typeof(attribute) == "number", "Timer attribute is not a number.")
	return attribute
end

function TimerController.ListenToTimerChanged(p: string, callback)
	local timer = TimerController.GetTimer(p)
	v[p] = v[p] or {}
	table.insert(v[p], callback)
	callback(timer)
end

function TimerController.Initialize()
	WaitForTimersLoaded(10)

	for k in ReplicatedStorage:GetAttributes() do
		if not string.find(string.lower(k), "timers_source") then
			continue
		end

		local v2 = string.gsub(k, "timers_source/", "")
		FireTimerListeners(v2) -- inferred equivalent call
		ReplicatedStorage:GetAttributeChangedSignal(k):Connect(function()
			local v3 = v2
			local v4 = v[v3]

			if v4 then
				if #v4 == 0 then
					return
				end

				local timer = TimerController.GetTimer(v3)

				for _, v5 in v4 do
					v5(timer)
				end
			end
		end)
	end
end

return TimerController