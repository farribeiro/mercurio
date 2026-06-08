
-- memoize utility
function Promise.memoize(fn)
	local values = {}
	return function(...)
		local key = minetest.write_json({...})
		local value = values[key]
		if not value then
			value = {fn(...)}
			values[key] = value
		end
		return unpack(value)
	end
end
