local Set = {
	add = require(script.add),
	copy = require(script.copy),
	count = require(script.count),
	delete = require(script.delete),
	difference = require(script.difference),
	differenceSymmetric = require(script.differenceSymmetric),
	filter = require(script.filter),
	fromArray = require(script.fromArray),
	has = require(script.has),
	intersection = require(script.intersection),
	isSubset = require(script.isSubset),
	isSuperset = require(script.isSuperset),
	map = require(script.map),
	merge = require(script.merge),
	toArray = require(script.toArray)
}
Set.fromList = Set.fromArray
Set.join = Set.merge
Set.subtract = Set.delete
Set.union = Set.merge
return Set