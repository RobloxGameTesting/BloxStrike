local ReplicatedStorage = game:GetService("ReplicatedStorage")
return {
	IsEnabled = function(p: string)
		return ReplicatedStorage:GetAttribute("Debug_" .. p) == true
	end
}