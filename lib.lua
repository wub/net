--[[

	Example usage:

	req = '32|cmd|hello'
	req = req:split('|')

	print(req[2])

]]

function string:split(sep, max, regex)
	assert(sep ~= '')
	assert(max == nil or max >= 1)

	local record = {}

	if self:len() > 0 then
		local plain = not regex
		max = max or -1

		local field = 1 start = 1
		local first, last = self:find(sep, start, plain)
		while first and max ~= 0 do
			record[field] = self:sub(start, first - 1)
			field = field + 1
			start = last + 1
			first, last = self:find(sep, start, plain)
			max = max - 1
		end
		record[field] = self:sub(start)
	end

	return record
end

--[[
	-- get by key / get by value
	for k,v in pairs(t) do print(k,v) end
	for i,v in ipairs(t) do print(i,v) end
]]
