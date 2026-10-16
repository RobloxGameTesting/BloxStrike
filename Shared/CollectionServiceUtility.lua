return {
	FindDescendantWithTag = function(object, p: string)
		return object:QueryDescendants(`.{p}`)[1]
	end
}