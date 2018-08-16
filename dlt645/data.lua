local bcd = require 'bcd'

local _M = {}

local function encode_addr(data_addr)
	return string.pack("!1<I4", data_addr)
end

local dlt645_format_bcd = {
	["PAP0P1P2"] = {
		encode = function(value, format)
			return string.sub(value, 1, 4)
		end,
		decode = function(str, format)
			return string.sub(str, 1, 4)
		end
	},
	["C0C1C2C3"] = {
		encode = function(value, format)
			return string.sub(value, 1, 4)
		end,
		decode = function(str, format)
			return string.sub(str, 1, 4)
		end
	},
	["YYMMDDhhmmss"] = {
		encode = function(value, format)
			local tm = value
			if type(tm) == 'number' then
				os.date("*t", value)
			end
			local val = { tm.sec % 60, tm.min % 60, tm.hour % 24, tm.day % 31, tm.month % 12, tm.year % 100 }
			local ret = {}
			for _, v in ipairs(val) do
				ret[#ret + 1] = bcd.encode(v, "XX")
			end
			return table.concat(ret)
		end,
		decode = function(str, format)
			local ret = {}
			for i = 1, 6 do
				ret[#ret + 1] = bcd.decode(string.sub(str, i, i), "XX")
			end
			local tm = {
				year = ret[6],
				month = ret[5],
				day = ret[4],
				hour = ret[3],
				min = ret[2],
				sec = ret[1]
			}
			--[[
			local cur_year = os.date("*t").year
			if tm.year > (cur_year % 100) then
				tm.year = tm.year + ((cur_year // 100) - 1) * 100
			else
				tm.year = tm.year + (cur_year // 100) * 100
			end
			return os.time(tm)
			]]--
			return tm
		end
	},
	["YYMMDDhhmm"] = {
		encode = function(value, format)
			assert(type(value) == 'table')
			local val = { value.min, value.hour, value.day, value.month, value.year}
			local ret = {}
			for _, v in ipairs(val) do
				ret[#ret + 1] = bcd.encode(v % 100, "XX")
			end
			return table.concat(ret)
		end,
		decode = function(str, format)
			local ret = {}
			for i = 1, 5 do
				ret[#ret + 1] = bcd.decode(string.sub(str, i, i), "XX")
			end
			local tm = {
				year = ret[5],
				month = ret[4],
				day = ret[3],
				hour = ret[2],
				min = ret[1],
			}
			--[[
			local cur_year = os.date("*t").year
			if tm.year > (cur_year % 100) then
				tm.year = tm.year + ((cur_year // 100) - 1) * 100
			else
				tm.year = tm.year + (cur_year // 100) * 100
			end
			return os.time(tm)
			]]--
			return tm
		end
	},
	["MMDDhhmm"] = {
		encode = function(value, format)
			assert(type(value) == 'table')
			local val = { value.min, value.hour, value.day, value.month }
			local ret = {}
			for _, v in ipairs(val) do
				ret[#ret + 1] = bcd.encode(v % 100, "XX")
			end
			return table.concat(ret)
		end,
		decode = function(str, format)
			local ret = {}
			for i = 1, 4 do
				ret[#ret + 1] = bcd.decode(string.sub(str, i, i), "XX")
			end
			return {
				month = ret[4],
				day = ret[3],
				hour = ret[2],
				min = ret[1],
			}
		end
	},
	["hhmm"] = {
		encode = function(value, format)
			return bcd.encode(value.min, "XX") .. bcd.encode(value.hour, "XX")
		end,
		decode = function(str, format)
			local min = bcd.decode(string.sub(str, 1, 1), "XX")
			local hour = bcd.decode(string.sub(str, 2, 2), "XX")
			return { hour = hour, min = min }
		end
	},
	["MMDDNN"] = {
		encode = function(value, format)
			return bcd.encode(value.n, "XX") .. bcd.encode(value.day, "XX") .. bcd.encode(value.month, "XX")
		end,
		decode = function(str, format)
			local n = bcd.decode(string.sub(str, 1, 1), "XX")
			local day = bcd.decode(string.sub(str, 2, 2), "XX")
			local month = bcd.decode(string.sub(str, 3, 3), "XX")
			return { month = month, day = day, n = n }
		end
	},
	["hhmmNN"] = {
		encode = function(value, format)
			return bcd.encode(value.n, "XX") .. bcd.encode(value.min, "XX") .. bcd.encode(value.hour, "XX")
		end,
		decode = function(str, format)
			local n = bcd.decode(string.sub(str, 1, 1), "XX")
			local min = bcd.decode(string.sub(str, 2, 2), "XX")
			local hour = bcd.decode(string.sub(str, 3, 3), "XX")
			return { hour = hour, min = min, n = n }
		end
	},
}

local function encode_data(value, format)
	local f = dlt645_format_bcd[format] or bcd
	return f.encode(value, format)
end

local function decode_data(raw, format)
	local f = dlt645_format_bcd[format] or bcd
	return f.decode(raw, format)
end

local function multi_format(f_map, count, ...)
	local fmts = {...}
	for i = 1, count do
		for _, v in ipairs(fmts) do
			f_map[#f_map + 1] = v
		end
	end
end

local function multi_format_map(count, ...)
	local f_map = {}
	local fmts = {...}
	for i = 1, count do
		for _, v in ipairs(fmts) do
			f_map[#f_map + 1] = v
		end
	end
	return table.concat(f_map, ",")
end

local function get_format(addr)
	local d0 = 0xFF & addr
	local d1 = 0xFF & (addr >> 8)
	local d2 = 0xFF & (addr >> 16)
	local d3 = 0xFF & (addr >> 24)

	-- D3: 0x00
	if d3 == 0x00 and (d0 <= 0x0C or d0 == 0xFF) then
		if d2 == 0x90 then
			if d1 == 0x01 or d1 == 0x02 then
				if d0 == 0x01 and d0 == 0x01 then
					return "XXXXXX.XX"
				end
			end
		end

		if d2 <= 0x0A and d1 == 0XFF then
			return multi_format_map(64, "XXXXXX.XX")
		end

		local valid = false
		if d2 <= 0x0A and d1 <= 0x3F then
			valid = true
		end

		if d2 >= 0x80 and d2 <= 0x86 and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0x15 and d2 <= 0x1E and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0x94 and d2 <= 0x9A and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0x29 and d2 <= 0x32 and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0xA8 and d2 <= 0xAE and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0x3D and d2 <= 0x46 and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0xBC and d2 <= 0xC2 and d1 == 0x00 then
			valid = true
		end
		if valid then
			if d0 == 0xFF then
				return multi_format_map(13, "XXXXXX.XX")
			end
			return "XXXXXX.XX"
		end
	end

	-- D3: 0x01
	if d3 == 0x01 and (d0 <= 0x0C or d0 == 0xFF) then
		if d2 <= 0x0A and d1 == 0XFF then
			return multi_format_map(64, "XXXXXX.XX")
		end

		local valid = false
		if d2 <= 0x0A and d1 < 0x3F then
			valid = true
		end
		if d2 >= 0x15 and d2 <= 0x1E and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0x29 and d2 <= 0x32 and d1 == 0x00 then
			valid = true
		end
		if d2 >= 0x3D and d2 <= 0x46 and d1 == 0x00 then
			valid = true
		end
		if valid then
			if d0 == 0xFF then
				return multi_format_map(13, "XX.XXXX,YYMMDDhhmm")
			end
			return "XX.XXXX,YYMMDDhhmm"
		end
	end

	-- D3: 0x02
	if d3 == 0x02 and d0 == 0x00 then
		local f_map = { "XXX.X", "XXX.XXX", "XX.XXXX", "XX.XXXX", "XX.XXXX", "X.XXX", "XXX.X", "XX.XX", "XX.XX" }
		if d1 <= 0x03 then
			return f_map[d2]
		end
		if d1 == 0xFF then
			return multi_format_map(4, f_map[d2])
		end
	end
	if d3 == 0x02 and (d2 == 0x0A or d2 == 0x0B) then
		if d1 >= 0x01 and d1 <= 0x03 then
			if d0 <= 0x15 then
				return "XX.XX"
			end
			if d0 == 0xFF then
				return multi_format_map(21, "XX.XX")
			end
		end
	end
	if d3 == 0x02 and d2 == 0x80 and d1 == 0x00 then
		local f_map = {"XXX.XXX", "XX.XX", "XX.XXXX", "XX.XXXX", "XX.XXXX", "XX.XXXX", "XXX.X", "XX.XX", "XX.XX", "XXXXXXXX", "XXXX.XXXX"}
		return f_map[d0]
	end

	-- D3: 0x03
	if d3 == 0x03 and (d2 >= 0x01 and d2 <= 0x04) then
		if d1 == 0x00 and d0 == 0x00 then
			-- A\B\C 相失压总次数,总累计时间(分)
			return multi_format_map(6, "XXXXXX")
		end
		if (d1 >= 0x01 and d1 <= 0x03) and (d0 >= 0x01 and d0 <= 0x0A) then
			local f_map = {
				"YYMMDDhhmmss", -- 6 发生时刻
				"YYMMDDhhmmss", -- 6 结束时刻
				"XXXXXX.XX", -- 4 kWh 失压期间正向有功总电能增量
				"XXXXXX.XX", -- 4 kWh 失压期间反向有功总电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间组合无功1总电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间组合无功2总电能增量
				"XXXXXX.XX", -- 4 kWh 失压期间A相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 失压期间A相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间A相组合无功1电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间A相组合无功2电能增量
				"XXX.X", -- 2 V 失压时刻A相电压
				"XXX.XXX", -- 3 A 失压时刻A相电流
				"XX.XXXX", -- 3 kW 失压时刻A相有功功率
				"XX.XXXX", -- 3 kvar 失压时刻A相无功功率
				"X.XXX", -- 2 失压时刻A相功率因数
				"XXXXXX.XX", -- 4 kWh 失压期间B相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 失压期间B相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间B相组合无功1电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间B相组合无功2电能增量
				"XXX.X", -- 2 V 失压时刻B相电压
				"XXX.XXX", -- 3 A 失压时刻B相电流
				"XX.XXXX", -- 3 kW 失压时刻B相有功功率
				"XX.XXXX", -- 3 kvar 失压时刻B相无功功率
				"X.XXX", -- 2 失压时刻B相功率因数
				"XXXXXX.XX", -- 4 kWh 失压期间C相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 失压期间C相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间C相组合无功1电能增量
				"XXXXXX.XX", -- 4 kvarh 失压期间C相组合无功2电能增量
				"XXX.X", -- 2 V 失压时刻C相电压
				"XXX.XXX", -- 3 A 失压时刻C相电流
				"XX.XXXX", -- 3 kW 失压时刻C相有功功率
				"XX.XXXX", -- 3 kvar 失压时刻C相无功功率
				"X.XXX", -- 2 失压时刻C相功率因数
				"XXXXXX.XX", -- 4 Ah 失压期间总安时数
				"XXXXXX.XX", -- 4 Ah 失压期间A相安时数
				"XXXXXX.XX", -- 4 Ah 失压期间B相安时数
				"XXXXXX.XX", -- 4 Ah 失压期间C相安时数
			}
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and d2 == 0x05 then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX,XXXXXX"
		end
		if d1 == 0x00 and (d0 >= 0x01 and d0  <= 0x0A) then
			return "YYMMDDhhmmss,XXX.XXX,YYMMDDhhmmss"
		end
	end
	if d3 == 0x03 and d2 == 0x06 then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX,XXXXXX"
		end
		if d1 == 0x00 and (d0 >= 0x01 and d0  <= 0x0A) then
			return "YYMMDDhhmmss,YYMMDDhhmmss"
		end
	end
	if d3 == 0x03 and (d2 == 0x07 or d2 == 0x08) then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX,XXXXXX"
		end
		if d1 == 0x00 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {
				"YYMMDDhhmmss", -- 6 发生时刻
				"YYMMDDhhmmss", -- 6 结束时刻
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间正向有功总电能增量
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间反向有功总电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间组合无功 1 总电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间组合无功 2 总电能增量
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间 A 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间 A 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间 A 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间 A 相组合无功 2 电能增量
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间 B 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间 B 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间 B 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间 B 相组合无功 2 电能增量
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间 C 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 电压逆相序期间 C 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间 C 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 电压逆相序期间 C 相组合无功 2 电能增量
			}
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and (d2 == 0x09 or d2 == 0x0A) then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX,XXXXXX"
		end
		if d1 == 0x00 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {
				"YYMMDDhhmmss", -- 6 发生时刻
				"YYMMDDhhmmss", -- 6 结束时刻
				"XX.XX", -- 2 % 最大不平衡率
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间正向有功总电能增量
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间反向有功总电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间组合无功 1 总电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间组合无功 2 总电能增量
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间 A 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间 A 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间 A 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间 A 相组合无功 2 电能增量
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间 B 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间 B 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间 B 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间 B 相组合无功 2 电能增量
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间 C 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 电压不平衡期间 C 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间 C 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 电压不平衡期间 C 相组合无功 2 电能增量
			}
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and (d2 >= 0x0B or d2 <= 0x0D) then
		if d1 == 0x00 and d0 == 0x00 then
			return multi_format_map(6, "XXXXXX")
		end
		if (d1 >= 0x01 and d1 <= 0x03) and d0 >= 0x01 and d <= 0x0A then
			local f_map = {
				"YYMMDDhhmmss", -- 6 发生时刻
				"YYMMDDhhmmss", -- 6 结束时刻
				"XXXXXX.XX", -- 4 kWh 失流期间正向有功总电能增量
				"XXXXXX.XX", -- 4 kWh 失流期间反向有功总电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间组合无功1总电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间组合无功2总电能增量
				"XXXXXX.XX", -- 4 kWh 失流期间A相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 失流期间A相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间A相组合无功1电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间A相组合无功2电能增量
				"XXX.X", -- 2 V 失流时刻A相电压
				"XXX.XXX", -- 3 A 失流时刻A相电流
				"XX.XXXX", -- 3 kW 失流时刻A相有功功率
				"XX.XXXX", -- 3 kvar 失流时刻A相无功功率
				"X.XXX", -- 2 失流时刻A相功率因数
				"XXXXXX.XX", -- 4 kWh 失流期间B相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 失流期间B相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间B相组合无功1电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间B相组合无功2电能增量
				"XXX.X", -- 2 V 失流时刻B相电压
				"XXX.XXX", -- 3 A 失流时刻B相电流
				"XX.XXXX", -- 3 kW 失流时刻B相有功功率
				"XX.XXXX", -- 3 kvar 失流时刻B相无功功率
				"X.XXX", -- 2 失流时刻B相功率因数
				"XXXXXX.XX", -- 4 kWh 失流期间C相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 失流期间C相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间C相组合无功1电能增量
				"XXXXXX.XX", -- 4 kvarh 失流期间C相组合无功2电能增量
				"XXX.X", -- 2 V 失流时刻C相电压
				"XXX.XXX", -- 3 A 失流时刻C相电流
				"XX.XXXX", -- 3 kW 失流时刻C相有功功率
				"XX.XXXX", -- 3 kvar 失流时刻C相无功功率
				"X.XXX", -- 2 失流时刻C相功率因数
			}
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and (d2 == 0x0E or d2 == 0x0F) then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX"
		end
		if (d1 >= 0x01 and d1 <= 0x03) and d0 >= 0x01 and d <= 0x0A then
			local f_map = {
				"YYMMDDhhmmss", -- 6 发生时刻
				"YYMMDDhhmmss", -- 6 结束时刻
				"XXXXXX.XX", -- 4 kWh 潮流反向期间正向有功总电能增量
				"XXXXXX.XX", -- 4 kWh 潮流反向期间反向有功总电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间组合无功 1 总电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间组合无功 2 总电能增量
				"XXXXXX.XX", -- 4 kWh 潮流反向期间 A 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 潮流反向期间 A 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间 A 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间 A 相组合无功 2 电能增量
				"XXXXXX.XX", -- 4 kWh 潮流反向期间 B 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 潮流反向期间 B 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间 B 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间 B 相组合无功 2 电能增量
				"XXXXXX.XX", -- 4 kWh 潮流反向期间 C 相正向有功电能增量
				"XXXXXX.XX", -- 4 kWh 潮流反向期间 C 相反向有功电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间 C 相组合无功 1 电能增量
				"XXXXXX.XX", -- 4 kvarh 潮流反向期间 C 相组合无功 2 电能增量
			}
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and d2 == 0x10 then
		if d1 == 0x00 and d0 <= 0x0C then
			local f_map = {
				"XXXXXX", -- 3 分 电压监测时间
				"XXXX.XX", -- 3 % 电压合格率
				"XXXX.XX", -- 3 % 电压超限率
				"XXXXXX", -- 3 分 电压超上限时间
				"XXXXXX", -- 3 分 电压超下限时间
				"XXX.X", -- 2 V 最高电压
				"MMDDhhmm", -- 4 最高电压出现时间
				"XXX.X", -- 2 V 最低电压
				"MMDDhhmm", -- 4 最低电压出现时间
			}
			return table.concat(f_map, ",")
		end
		if (d1 >= 0x01 and d1 <= 0x03) and d0 <= 0x0C then
			local f_map = {
				"XXXXXX", --  3 分 A 相电压监测时间
				"XX.XX", --  2 % A 相电压合格率
				"XX.XX", --  2 % A 相电压超限率
				"XXXXXX", --  3 分 A 相电压超上限时间
				"XXXXXX", --  3 分 A 相电压超下限时间
				"XXX.X", --  2 V A 相最高电压
				"MMDDhhmm", --  4 A 相最高电压出现时间
				"XXX.X", --  2 A V 相最低电压
				"MMDDhhmm", --  4 A 相最低电压出现时间
			}
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and d2 == 0x11 then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x00 and (d0 >= 0x01 and d0 <= 0x0A) then
			return "YYMMDDhhmmss,YYMMDDhhmmss"
		end
	end
	if d3 == 0x03 and d2 == 0x12 then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX"
		end
		if d1 >= 0x01 and d2 <= 0x06 and d0 >= 0x01 and d0 <= 0x0A then
			return "YYMMDDhhmmss,YYMMDDhhmmss,XX.XXXX,YYMMDDhhmm"
		end
	end
	if d3 == 0x03 and d2 == 0x30 then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x00 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			multi_format(f_map, 10, "XXXXXXXX")
			return table.concat(f_map, ",")
		end
		if d1 == 0x01 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x01 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			multi_format(f_map, 24, "XXXXXX.XX")
			return table.concat(f_map, ",")
		end
		if d1 == 0x02 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x02 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			multi_format(f_map, 24, "XX.XXXXXX", "YYMMDDhhmm")
			return table.concat(f_map, ",")
		end
		if d1 == 0x03 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x03 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3","XXXXXXXX"}
			return table.concat(f_map, ",")
		end
		if d1 == 0x04 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x04 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"C0C1C2C3","YYMMDDhhmmss","YYMMDDhhmmss"}
			return table.concat(f_map, ",")
		end
		if d1 == 0x05 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x05 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			multi_format(f_map, 16, "hhmmNN")
			return table.concat(f_map, ",")
		end
		if d1 == 0x06 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x06 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			multi_format(f_map, 28, "MMDDNN")
			return table.concat(f_map, ",")
		end
		if (d1 == 0x07 or d1 == 0x09 or d1 == 0x0A or d1 == 0x0B) and d0 == 0x00 then
			return "XXXXXX"
		end
		if (d1 == 0x07 or d1 == 0x09 or d1 == 0x0A or d1 == 0x0B) and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3", "XX"}
			return table.concat(f_map, ",")
		end
		if d1 == 0x08 and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x08 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			multi_format(f_map, 254, "YYMMDDNN")
			return table.concat(f_map, ",")
		end
		if d1 == 0x0C and d0 == 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x0C and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			multi_format(f_map, 3, "DDhh")
			return table.concat(f_map, ",")
		end
		if (d1 == 0x0D or d1 == 0x0E) and d0 == 0x00 then
			return "XXXXXX"
		end
		if (d1 == 0x0D or d1 == 0x0E) and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","YYMMDDhhmmss"}
			multi_format(f_map, 12, "XXXXXX.XX")
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and (d2 == 0x32 or d2 == 0x33) then
		if d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmm","XXXX"}
			multi_format(f_map, 4, "XXXXXX.XX")
			return f_map[d1]
		end
	end

	-- D3: 0x04
	if d3 == 0x04 and d2 == 0x00 then
		if d1 == 0x01 then
			local f_map = {"YYMMDDWW", "hhmmss", "NN", "NN", "XXXX", "YYMMDDhhmm", "YYMMDDhhmm", "YYMMDDhhmm", "YYMMDDhhmm"}
			return f_map[d0]
		end
		if d1 == 0x02 then
			local f_map = {"NN", "NN", "NN", "NN", "NNNN", "NN", "NN"}
			return f_map[d0]
		end
		if d1 == 0x03 then
			local f_map = {"NN", "NN", "NN", "NN", "NN", "NNNNNN", "NNNNNN"}
			return f_map[d0]
		end
		if d1 == 0x04 then
			local f_map = {"N12", "N12", "N32", "X12", "X12", "X12", "X8", "X8", "XXXXXX", "XXXXXX", "X10", "X10", "X16", "N12"}
			return f_map[d0]
		end
		if d1 == 0x05 then
			if d1 >= 0x01 and d1 <= 0x07 then
				return "XXXX"
			end
			if d0 == 0xFF then
				return multi_format_map(7, "XXXX")
			end
		end
		if d1 == 0x06 then
			if d1 >= 0x01 and d1 <= 0x03 then
				return "NN"
			end
		end
		if d1 == 0x07 then
			if d1 >= 0x01 and d1 <= 0x05 then
				return "NN"
			end
		end
		if d1 == 0x08 then
			if d1 >= 0x01 and d1 <= 0x02 then
				return "NN"
			end
		end
		if d1 == 0x09 then
			if d1 >= 0x01 and d1 <= 0x06 then
				return "NN"
			end
		end
		if d1 == 0x0A then
			if d1 == 0x00 then
				return "MMDDhhmm"
			end
			if d1 >= 0x02 and d1 <= 0x07 then
				return "NNNN"
			end
		end
		if d1 == 0x0B then
			if d1 >= 0x01 and d1 <= 0x03 then
				return "DDhh"
			end
		end
		if d1 == 0x0C then
			if d1 >= 0x01 and d1 <= 0x0A then
				return "N8"
			end
		end
		if d1 == 0x0D then
			if d1 >= 0x01 and d1 <= 0x0C then
				return "N.NNN"
			end
		end
		if d1 == 0x0E then
			if d1 >= 0x01 and d1 <= 0x02 then
				return "NN.NNNN"
			end
			if d1 >= 0x03 and d1 <= 0x04 then
				return "NNN.N"
			end
		end
		if d1 == 0x0F then
			if d1 >= 0x01 and d1 <= 0x04 then
				return "XXXXXX.XX"
			end
		end
		if d1 == 0x10 then
			if d1 >= 0x01 and d1 <= 0x05 then
				return "XXXXXX.XX"
			end
		end
		if d1 == 0x11 or d1 == 0x13 then
			if d1 == 0x01 then
				return "NN"
			end
		end
		if d1 == 0x12 then
			local f_map = {"YYMMDDhhmm", "NN", "hhmm"}
			return f_map[d0]
		end
		if d1 == 0x14 then
			if d1 == 0x01 then
				return "NNNN"
			end
		end
	end
	if d3 == 0x04 and (d2 == 0x01 or d2 == 0x02) then
		if d1 == 0x00 then
			if d0 == 0x00 then
				local f_map = {}
				multi_format(f_map, 14, "MMDDNN")
				return table.concat(f_map, ",")
			end
			if d0 >= 0x01 and d0 <= 08 then
				local f_map = {}
				multi_format(f_map, 14, "hhmmNN")
				return table.concat(f_map, ",")
			end
		end
	end
	if d3 == 0x04 and d2 == 0x03 then
		if d1 == 0x00 then
			if d0 >= 0x01 and d0 <= 0xFE then
				return "YYMMDDNN"
			end
		end
	end
	if d3 == 0x04 and d2 == 0x04 then
		if d1 == 0x01 or d1 == 0x02 then
			if d0 >= 0x01 and d0 <= 0xFE then
				return "NNNNNNNN,NN"
			end
		end
	end
	if d3 == 0x04 and d2 == 0x05 then
		if d1 == 0x01 or d1 == 0x02 then
			if d0 >= 0x01 and d0 <= 0x3F then
				return "NNNN.NNNN"
			end
		end
	end
	if d3 == 0x04 and d2 == 0x06 then
		local f_map = { "NNNNNN.NN", "NNNN.NNNN", "NNNNNN.NN", "NNNN.NNNN" }
		if d1 >= 0x00 and d1 <= 0x03 then
			if d0 >= 0x01 and d0 <= 0xFE then
				return f_map[d1 + 1]
			end
		end
	end
	if d3 == 0x04 and d2 == 0x09 then
		if d1 == 0x01 then
			local f_map = {"NNN.N", "NNN.N", "NN.NNNN", "NN"}
			return f_map[d0]
		end
		if d1 == 0x02 or d1 == 0x03 or d1 == 0x05 or d1 == 0x06 or d1 == 0x08 then
			local f_map = {"NNN.N", "NN"}
			return f_map[d0]
		end
		if d1 == 0x04 or d1 == 0x09 then
			local f_map = {"NNN.N", "NN.NNNN", "NN"}
			return f_map[d0]
		end
		if d1 == 0x07 then
			local f_map = {"NNN.N", "NN.NNNN", "NN.NNNN", "NN"}
			return f_map[d0]
		end
		if d1 == 0x0A or d1 == 0x0B then
			local f_map = {"NN.NNNN", "NN"}
			return f_map[d0]
		end
		if d1 == 0x0C then
			local f_map = {"NNN.N", "NNN.N"}
			return f_map[d0]
		end
		if d1 == 0x0D then
			local f_map = {"NN.NNNN", "NN.NNNN", "NN"}
			return f_map[d0]
		end
		if d1 == 0x0E then
			local f_map = {"N.NNN", "NN"}
			return f_map[d0]
		end
		if d1 == 0x0F then
			local f_map = {"NN.NN", "NN"}
			return f_map[d0]
		end
	end

	-- D3: 0x05
	if d3 == 0x05 and d2 == 0x00 then
		if d0 >= 0x01 and d0 <= 0x0C then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end
			if d1 >= 0x01 and d1 <= 0x08 then
				return multi_format_map(64, "XXXXXX.XX")
			end
			if d1 >= 0x09 and d1 <= 0x0A then
				return multi_format_map(64, "XX.XXXX", "YYMMDDhhmm")
			end
			if d1 == 0x10 then
				return multi_format_map(8, "XX.XXXX")
			end
			if d1 == 0xFF then
				--- TODO:
			end
		end
	end
	if d3 == 0x05 and (d2 == 0x01 or d2 == 0x02 or d2 == 0x03) then
		if d0 >= 0x01 and d0 <= 0x03 then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end
			if d1 >= 0x01 and d1 <= 0x08 then
				return multi_format_map(64, "XXXXXX.XX")
			end
			if d1 >= 0x09 and d1 <= 0x0A then
				return multi_format_map(64, "XX.XXXX", "YYMMDDhhmm")
			end
			if d1 == 0x10 then
				return multi_format_map(8, "XX.XXXX")
			end
			if d1 == 0xFF then
				--- TODO:
			end
		end
	end
	if d3 == 0x05 and d2 == 0x04 then
		if d0 >= 0x01 and d0 <= 0xFE then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end
			if d1 == 0x01 then
				return "XXXXXX.XX"
			end
			if d1 == 0x02 then
				return "XXXXXX.XX"
			end
			if d1 == 0xFF then
				return "YYMMDDhhmm,XXXXXX.XX,XXXXXX.XX"
			end
		end
	end
	if d3 == 0x05 and d2 == 0x06 then
		if d0 >= 0x01 and d0 <= 0x3E then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end

			local f_map = {}
			multi_format(f_map, 8, "XXXXXX.XX")
			multi_format(f_map, 2, "XXXXXX.XX,YYMMDDhhmm")
			if d1 <= 0x0A then
				return multi_format_map(64, f_map[d1])
			end

			if d1 == 0x10 then
				return multi_format_map(8, "XX.XXXX")
			end
			if d1 == 0xFF then
				-- TODO:
				--return table.concat(f_map, ",")
			end
		end
	end
	if d3 == 0x05 and d2 == 0x07 then
		if d0 >= 0x01 and d0 <= 0x02 then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end

			local f_map = {}
			multi_format(f_map, 8, "XXXXXX.XX")
			multi_format(f_map, 2, "XXXXXX.XX,YYMMDDhhmm")
			if d1 <= 0x0A then
				return multi_format_map(64, f_map[d1])
			end

			if d1 == 0x10 then
				return multi_format_map(8, "XX.XXXX")
			end
			if d1 == 0xFF then
				-- TODO:
				--return table.concat(f_map, ",")
			end
		end
	end

	-- D3: 0x06
	if d3 == 0x06 and d2 >= 0x00 and d2 <= 0x06 then
		local f_map = { "NN", "YYMMDDhhmmNN", "01" }
		return f_map[d0]
	end

	-- D3: 0x07
	if d3 == 0x07 and d2 == 0x80 then
		if d1 == 0x01 and d0 == 0x01 then
			return "H8"
		end
		if d1 == 0x01 and d0 == 0xFF then
			return "H8,HLd,H4"
		end
	end
	if d3 == 0x07 and d2 == 0x81 then
		-- TODO:
		if d1 == 0x02 and d0 == 0x01 then
			return "H8"
		end
		if d1 == 0x02 and d0 == 0xFF then
			return "H8,HLd,H4"
		end
	end

	-- D3: 0x10
	if d3 == 0x10 and d2 == 0x00 then
		if d1 == 0x00 then
			return "X6"
		end
	end
	-- D3: 0x10 0x11 0x12 0x13
	if d3 >= 0x10 and d3 <= 0x13 and d2 >= 0x01 and d2 <= 0x03 then
		if d1 == 0x00 then
			if d0 == 0x01 or d0 == 0x02 then
				return "X6"
			end
		end
		-- 失压数据
		local f_map = {"YYMMDDhhmmss"}
		multi_format(f_map, 8, "XXXXXX.XX")
		f_map[#f_map + 1] = "XXX.X"
		f_map[#f_map + 1] = "XXX.XXX"
		multi_format(f_map, 2, "XX.XXXX")
		f_map[#f_map + 1] = "X.XXX"

		multi_format(f_map, 4, "XXXXXX.XX")
		f_map[#f_map + 1] = "XXX.X"
		f_map[#f_map + 1] = "XXX.XXX"
		multi_format(f_map, 2, "XX.XXXX")
		f_map[#f_map + 1] = "X.XXX"

		multi_format(f_map, 4, "XXXXXX.XX")
		f_map[#f_map + 1] = "XXX.X"
		f_map[#f_map + 1] = "XXX.XXX"
		multi_format(f_map, 2, "XX.XXXX")
		f_map[#f_map + 1] = "X.XXX"

		multi_format(f_map, 4, "XXXXXX.XX")

		f_map[#f_map + 1] = "YYMMDDhhmmss"
		multi_format(f_map, 16, "XXXXXX.XX")

		if d1 >= 0x01 and d1 <= 0x35 then
			if d0 >= 0x01 and d0 <= 0x0A then
				return f_map[d1]
			end
			if d0 == 0xFF then
				local ff_map = {}
				multi_format(ff_map, 10, f_map[d1])
				return table.concat(ff_map, ",")
			end
		end
		if d1 == 0xFF then
			return table.concat(f_map, ",")
		end
	end

	-- D3: 0x14 0x15
	if (d3 == 0x14 or d3 == 0x15) and d2 == 0x00 then
		if d1 == 0x00 then
			if d0 == 0x01 or d0 == 0x02 then
				return "X6"
			end
		end

		-- 电压/电流逆序
		local f_map = {"YYMMDDhhmmss"}
		multi_format(f_map, 16, "XXXXXX.XX")
		f_map[#f_map + 1] = "YYMMDDhhmmss"
		multi_format(f_map, 16, "XXXXXX.XX")

		if d1 >= 0x01 and d1 <= 0x22 then
			if d0 >= 0x01 and d0 <= 0x0A then
				return f_map[d1]
			end
			if d0 == 0xFF then
				local ff_map = {}
				multi_format(ff_map, 10, f_map[d1])
				return table.concat(ff_map, ",")
			end
		end
		if d1 == 0xFF then
			return table.concat(f_map, ",")
		end
	end

	-- D3: 0x16 0x17
	if (d3 == 0x16 or d3 == 0x17) and d2 == 0x00 then
		if d1 == 0x00 then
			if d0 == 0x01 or d0 == 0x02 then
				return "X6"
			end
		end

		-- 电压/电流不平衡
		local f_map = {"YYMMDDhhmmss"}
		multi_format(f_map, 16, "XXXXXX.XX")
		f_map[#f_map + 1] = "XXXX.XX"
		f_map[#f_map + 1] = "YYMMDDhhmmss"
		multi_format(f_map, 16, "XXXXXX.XX")

		if d1 >= 0x01 and d1 <= 0x23 then
			if d0 >= 0x01 and d0 <= 0x0A then
				return f_map[d1]
			end
			if d0 == 0xFF then
				local ff_map = {}
				multi_format(ff_map, 10, f_map[d1])
				return table.concat(ff_map, ",")
			end
		end
		if d1 == 0xFF then
			return table.concat(f_map, ",")
		end
	end

	-- D3: 0x18 ~ 0x1A
	if (d3 >= 0x18 and d3 <= 0x1A) and (d2 >= 0x01 and d2 <= 0x03) then
		if d1 == 0x00 then
			if d0 == 0x01 or d0 == 0x02 then
				return "X6"
			end
		end

		-- 电流失流/过流/断流
		local f_map = {"YYMMDDhhmmss"}
		multi_format(f_map, 8, "XXXXXX.XX")
		f_map[#f_map + 1] = "XXX.X"
		f_map[#f_map + 1] = "XXX.XXX"
		multi_format(f_map, 2, "XX.XXXX")
		f_map[#f_map + 1] = "X.XXX"

		multi_format(f_map, 4, "XXXXXX.XX")
		f_map[#f_map + 1] = "XXX.X"
		f_map[#f_map + 1] = "XXX.XXX"
		multi_format(f_map, 2, "XX.XXXX")
		f_map[#f_map + 1] = "X.XXX"

		multi_format(f_map, 4, "XXXXXX.XX")
		f_map[#f_map + 1] = "XXX.X"
		f_map[#f_map + 1] = "XXX.XXX"
		multi_format(f_map, 2, "XX.XXXX")
		f_map[#f_map + 1] = "X.XXX"

		f_map[#f_map + 1] = "YYMMDDhhmmss"
		multi_format(f_map, 16, "XXXXXX.XX")

		if d1 >= 0x01 and d1 <= 0x31 then
			if d0 >= 0x01 and d0 <= 0x0A then
				return f_map[d1]
			end
			if d0 == 0xFF then
				local ff_map = {}
				multi_format(ff_map, 10, f_map[d1])
				return table.concat(ff_map, ",")
			end
		end
		if d1 == 0xFF then
			return table.concat(f_map, ",")
		end
	end

	-- D3: 0x1B 0x1C
	if d3 == 0x1B and d2 >= 0x01 and d2 <= 0x03 then
		if d1 == 0x00 then
			if d0 == 0x01 or d0 == 0x02 then
				return "X6"
			end
		end

		-- 潮流/过载
		local f_map = {"YYMMDDhhmmss"}
		multi_format(f_map, 16, "XXXXXX.XX")
		f_map[#f_map + 1] = "YYMMDDhhmmss"
		multi_format(f_map, 16, "XXXXXX.XX")

		if d1 >= 0x01 and d1 <= 0x22 then
			if d0 >= 0x01 and d0 <= 0x0A then -- 10次
				return f_map[d1]
			end
			if d0 == 0xFF then
				local ff_map = {}
				multi_format(ff_map, 10, f_map[d1])
				return table.concat(ff_map, ",")
			end
		end
		if d1 == 0xFF then
			return table.concat(f_map, ",")
		end
	end

	-- D3: 0x1D  0x1E
	if (d3 == 0x1D or d3 ==0x1E) and d2 == 0x00 then
		if d1 == 0x00 then
			if d0 == 0x01 then
				return "X6"
			end
		end

		-- 跳闸/合闸
		local f_map = {"YYMMDDhhmmss", "C0C1C2C3"}
		multi_format(f_map, 6, "XXXXXX.XX")

		if d1 >= 0x01 and d1 <= 0x08 then
			if d0 >= 0x01 and d0 <= 0x0A then -- 10次
				return f_map[d1]
			end
			if d0 == 0xFF then
				local ff_map = {}
				multi_format(ff_map, 10, f_map[d1])
				return table.concat(ff_map, ",")
			end
		end
		if d1 == 0xFF then
			return table.concat(f_map, ",")
		end
	end

	-- D3: 0x1F
	if d3 == 0x1F and d2 == 0x00 then
		if d1 == 0x00 then
			if d0 == 0x01 then
				return "X6"
			end
		end

		-- 跳闸/合闸
		local f_map = {"YYMMDDhhmmss"}
		multi_format(f_map, 4, "XXXXXX.XX")
		f_map[#f_map + 1] = "YYMMDDhhmmss"
		multi_format(f_map, 4, "XXXXXX.XX")

		if d1 >= 0x01 and d1 <= 0x0A then
			if d0 >= 0x01 and d0 <= 0x0A then -- 10次
				return f_map[d1]
			end
			if d0 == 0xFF then
				local ff_map = {}
				multi_format(ff_map, 10, f_map[d1])
				return table.concat(ff_map, ",")
			end
		end
		if d1 == 0xFF then
			return table.concat(f_map, ",")
		end
	end
end

local function unfold_format(format)
	return string.gsub(format, "([XxNn#])(%d+)", function(c, num)
		local ret = {}
		for i = 1, num do
			ret[#ret + 1] = c
		end
		return table.concat(ret)
	end)
end

local function replace_special(format)
	return format:gsub("PAP0P1P2", "N4"):gsub("C0C1C2C3", "N4")
end

local function get_format_len(format)
	local format = unfold_format(replace_special(format))
	local f = format:gsub('%.', ''):gsub(',', '')
	return math.ceil(string.len(f) / 2)
end

_M.get_format= get_format
_M.get_format_len = get_format_len

function _M.encode(addr, value, format)
	local format = format or get_format(addr)

	if not string.find(format, ",") then
		return encode_addr(addr) .. encode_data(value, format)
	end

	local fmts = {}
	for w in string.gmatch(format, '([^,]+)') do
		table.insert(fmts, w)
	end
	assert(type(value) == 'table')
	assert(#value == #fmts)
	local ret = { encode_addr(addr) }
	for i, format in ipairs(fmts) do
		ret[#ret + 1] = encode_data(value[i], format)
	end
	return table.concat(ret)
end

function _M.encode_table(dt)
	local data = {}
	for _, v in ipairs(dt) do
		data[#data + 1] = _M.encode(v.addr, v.value, v.format)
	end
	return table.concat(data)
end


function _M.decode(raw, format)
	local addr = string.unpack("!1<I4", raw)
	local format = format or get_format(addr)
	local len = get_format_len(format)

	if string.len(raw) < 4 + len then
		return nil, nil, raw
	end

	if not string.find(format, ",") then
		local value = decode_data(string.sub(raw, 4 + 1, 4 + len), format)
		return addr, value, string.sub(raw, 4 + len + 1)
	end

	local fmts = {}
	for w in string.gmatch(format, '([^,]+)') do
		table.insert(fmts, w)
	end
	assert(#fmts > 1)

	local value = {}
	local start = 4
	for _, format in ipairs(fmts) do
		local sub_len = get_format_len(format)
		value[#value + 1] = decode_data(string.sub(raw, start + 1, start + sub_len), format)
		start = start + sub_len
	end
	return addr, value, string.sub(raw, 4 + len + 1)
end

return _M
