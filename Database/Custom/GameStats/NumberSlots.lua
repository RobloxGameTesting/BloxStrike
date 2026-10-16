game:GetService("ReplicatedStorage")
local _ = {
	Primary = 1,
	Secondary = 2,
	Melee = 3,
	Grenade = 4,
	C4 = 5
}
return (table.freeze({
	Primary = 1,
	Secondary = 2,
	Melee = 3,
	Grenade = 4,
	C4 = 5,
	Priorities = { 3, 2, 0, 1, 1 }
}))