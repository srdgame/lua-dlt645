local basexx = require 'basexx'
local data = require "dlt645.data"

local function print_data(data)
	assert(data)
	local addr = basexx.to_hex(string.sub(data, 1, 4))
	local data = basexx.to_hex(string.sub(data, 5))
	print(addr, data)
	return addr, data
end

local format = data.get_format(0x10020101)
assert(format == "YYMMDDhhmmss")

local function eq_assert(v1, v2)
	assert(math.type(v1) == math.type(v2), string.format("value type diff. %s - %s", v1, v2))
	if math.type(v1) == 'float' then
		assert(tostring(v1) == tostring(v2))
	end
	if math.type(v1) == 'integer' then
		assert(v1 == v2)
	end

	if type(v1) == 'table' then
		for i, v in ipairs(v1) do
			eq_assert(v, v2[i])
		end
	end
end

local function test_format(addr, value, expacted_fmt, expacted_val)
	local format = data.get_format(addr)
	assert(format == expacted_fmt, string.format("format: %s - %s", format, expacted_fmt))
	local d = data.encode(addr, value)
	local d2 = data.encode(addr, value, format)
	assert(d == d2)

	local aa, dd = print_data(d)
	if expacted_val then
		assert(dd == expacted_val)
	end

	local ra, rv, rd = data.decode(d)
	--print(ra, addr)
	assert(addr == ra)
	print(value, rv)
	eq_assert(value, rv)
end

local addr = 0x00023F0C
local d = data.encode(addr, 12131.50121)
local a, d = print_data(d)
assert(a == '0C3F0200')

a = 12131.51
b = 12131.51

test_format(addr, 12131.51, "XXXXXX.XX", "01213151")
test_format(0x10020201, 12131.51, "XXXXXX.XX", "01213151")

test_format(0x03100000, {123456, 123, 456, 0, 555, 444}, "XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX")

