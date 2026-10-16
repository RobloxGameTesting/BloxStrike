local v = {
	OpenAngle = 1.5707963267948966,
	OpenSeconds = 0.35,
	MinSwingSeconds = 1 / 240,
	ClosedAngleEpsilon = 0.05,
	TargetEpsilon = 0.01,
	InteractRange = 15
}
v.SwingRate = v.OpenAngle / v.OpenSeconds

function v.durationSeconds(p: number)
	return (math.max(v.MinSwingSeconds, p / v.OpenAngle * v.OpenSeconds))
end

return table.freeze(v)