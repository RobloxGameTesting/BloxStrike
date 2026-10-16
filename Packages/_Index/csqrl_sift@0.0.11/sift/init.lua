require(script.Types)
local Sift = {
	Array = require(script.Array),
	Dictionary = require(script.Dictionary),
	Set = require(script.Set),
	None = require(script.None),
	Types = require(script.Types),
	equalObjects = require(script.Util.equalObjects),
	isEmpty = require(script.Util.isEmpty)
}
Sift.List = Sift.Array
return Sift