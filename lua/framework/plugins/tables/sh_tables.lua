local mRand, istable = math.random, istable

function table.seqRandom(array)
	if (!istable(array)) then
		return false
	end
	return array[mRand(#array)]
end

function table.newInsert(table, data)
	table[#table + 1] = data
end