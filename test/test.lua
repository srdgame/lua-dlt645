local basexx = require 'basexx'
local dlt645_code  = require 'dlt645.code'
local dlt645_data = require "dlt645.data"
local dlt645_apdu = require 'dlt645.apdu'

local function print_data(data)
	assert(data)
	local addr = basexx.to_hex(string.sub(data, 1, 4))
	local data = basexx.to_hex(string.sub(data, 5))
	print(addr, data)
	return addr, data
end

local format = dlt645_data.get_format(0x10020101)
assert(format == "YYMMDDhhmmss")

local function eq_assert(v1, v2)
	assert(math.type(v1) == math.type(v2), string.format("value type diff. %s - %s", v1, v2))
	if math.type(v1) == 'float' then
		assert(tostring(v1) == tostring(v2), string.format("value(float) diff. %s - %s", v1, v2))
	end
	if math.type(v1) == 'integer' then
		assert(v1 == v2, string.format("value(integer) diff. %s - %s", v1, v2))
	end

	if type(v1) == 'table' then
		for k, v in pairs(v1) do
			eq_assert(v, v2[k])
		end
	end
end

local function test_format(addr, value, expacted_fmt, expacted_val)
	local format = dlt645_data.get_format(addr)
	assert(format == expacted_fmt, string.format("format: %s - %s", format, expacted_fmt))
	local d = dlt645_data.encode(addr, value)
	local d2 = dlt645_data.encode(addr, value, format)
	assert(d == d2)

	local aa, dd = print_data(d)
	if expacted_val then
		assert(dd == expacted_val)
	end

	local ra, rv, rd = dlt645_data.decode(d)
	--print(ra, addr)
	assert(addr == ra)
	--print(value, rv)
	eq_assert(value, rv)
end

local addr = 0x00023F0C
local d = dlt645_data.encode(addr, 12131.50121)
local a, d = print_data(d)
assert(a == '0C3F0200')

a = 12131.51
b = 12131.51

print("=== begin number test====")
test_format(addr, 12131.51, "XXXXXX.XX", "01213151")
test_format(0x10020201, 12131.51, "XXXXXX.XX", "01213151")

print("=== begin array test====")
test_format(0x03100000, {123456, 123, 456, 0, 555, 444}, "XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX")

local tm = {year=18, month=08, day = 16, hour = 17, min = 50, sec=45}
local tm2 = {year=18, month=08, day = 16, hour = 17, min = 50, sec=46}
print("=== begin time struct test====")
test_format(0x03050001, {tm, 123.456, tm2}, "YYMMDDhhmmss,XXX.XXX,YYMMDDhhmmss")
test_format(0x01010000, {12.1234, {year=18, month=08, day = 16, hour = 17, min = 51}}, "XX.XXXX,YYMMDDhhmm")


local function test_apdu(dev_addr, code, data_addr, data_value)
	assert(dev_addr and code and data_addr and data_value)
	local data = assert(dlt645_data.encode(data_addr, data_value))
	local pdu = assert(dlt645_apdu(false, false):encode(dev_addr, code, data))
	local rpdu = dlt645_apdu(true, false):decode(pdu)
	assert(rpdu.code == code)
	assert(rpdu.addr == dev_addr)
	assert(rpdu.data == data)
	assert(rpdu.sflag == 0)
	-- TODO: for not_end stuff
	--assert
	--
	assert(not dlt645_apdu(true, false):decode(string.sub(pdu, 2)))
	print('=========== TestAPDU Done ===========')
end

test_apdu(991122334455, dlt645_code.ReadData, addr, 12131.51)


