return function(instance)
	return instance ~= nil
		and instance:GetAttribute("IsPlantingBomb") ~= true
		and instance:GetAttribute("IsDefusingBomb") ~= true
		and instance:GetAttribute("IsRescuingHostage") ~= true
end