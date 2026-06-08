
mtt.register("Promise.memoize", function(callback)
	local i = 0
	local c = Promise.memoize(function(a, b)
		i = i + 1
		return a * b
	end)

	assert(c(20, 10) == 200)
	assert(i == 1)
	assert(c(20, 10) == 200)
	assert(i == 1)
	assert(c(20, 20) == 400)
	assert(i == 2)

	callback()
end)
