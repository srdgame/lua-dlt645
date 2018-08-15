local bcd = require 'bcd'

local _M = {}

local function encode_addr(data_addr)
	return string.pack("!1<I4", data_addr)
end

local function encode_data(value, format)
	return bcd.encode(value, format)
end

local function get_format(addr)
	local d0 = 0xFF & addr
	local d1 = 0xFF & (addr >> 8)
	local d2 = 0xFF & (addr >> 16)
	local d3 = 0xFF & (addr >> 24)

	-- D3: 0x00
	if d3 == 0x00 and (d0 == 0x00 or d0 == 0x01 or d0 == 0x0C) then
		if d2 <= 0x0A then
			return "XXXXXX.XX"
		end
		if d2 >= 0x80 and d2 <= 0x86 and d1 == 0x00 then
			return "XXXXXX.XX"
		end
		if d2 >= 0x15 and d2 <= 0x1E and d1 == 0x00 then
			return "XXXXXX.XX"
		end
		if d2 >= 0x94 and d2 <= 0x9A and d1 == 0x00 then
			return "XXXXXX.XX"
		end
		if d2 >= 0x29 and d2 <= 0x32 and d1 == 0x00 then
			return "XXXXXX.XX"
		end
		if d2 >= 0xA8 and d2 <= 0xAE and d1 == 0x00 then
			return "XXXXXX.XX"
		end
		if d2 >= 0x3D and d2 <= 0x46 and d1 == 0x00 then
			return "XXXXXX.XX"
		end
		if d2 >= 0xBC and d2 <= 0xC2 and d1 == 0x00 then
			return "XXXXXX.XX"
		end
	end
	if d3 == 0x00 and d0 == 0xFF then
		return "XXXXXX.XX"
	end

	-- D3: 0x01
	if d3 == 0x01 and (d0 == 0x00 or d0 == 0x01 or d0 == 0x0C) then
		if d2 <= 0x0A then
			return "XX.XXXX,YYMMDDhhmm"
		end
		if d2 >= 0x15 and d2 <= 0x1E and d1 == 0x00 then
			return "XX.XXXX,YYMMDDhhmm"
		end
		if d2 >= 0x29 and d2 <= 0x32 and d1 == 0x00 then
			return "XX.XXXX,YYMMDDhhmm"
		end
		if d2 >= 0x3D and d2 <= 0x46 and d1 == 0x00 then
			return "XX.XXXX,YYMMDDhhmm"
		end
	end
	if d3 == 0x01 and d0 == 0xFF then
		return "XX.XXXX,YYMMDDhhmm"
	end

	-- D3: 0x02
	if d3 == 0x02 and d0 == 0x00 then
		-- d1: 0x01 0x02 0x03 0xFF
		if d2 == 0x01 then
			return "XXX.X"
		end
		if d2 == 0x02 then
			return "XXX.XXX"
		end
		if d2 >= 0x03 and d2 <= 0x05 then
			return "XX.XXXX"
		end
		if d2 == 0x06 then
			return "X.XXX"
		end
		if d2 == 0x07 then
			return "XXX.X"
		end
		if d2 >= 0x08 and d2 <= 0x09 then
			return "XX.XX"
		end
	end
	if d3 == 0x02 and d2 >= 0x0A then
		if d1 >= 0x01 and d1 <= 0x03 then
			return "XX.XX"
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
			return "XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX"
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
	if d3 == 0x03 and (d2 == 0x0B or d2 == 0x0C) then
		if d1 == 0x00 and d0 == 0x00 then
			return "XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX,XXXXXX"
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
		if d1 == 0x00 and d0 = 0x00 then
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
		if d1 == 0x00 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x00 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			for i = 1, 10 do
				f_map[#f_map + 1] = "XXXXXXXX"
			end
			return table.concat(f_map, ",")
		end
		if d1 == 0x01 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x01 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			for i = 1, 24 do
				f_map[#f_map + 1] = "XXXXXX.XX"
			end
			return table.concat(f_map, ",")
		end
		if d1 == 0x02 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x02 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			for i = 1, 24 do
				f_map[#f_map + 1] = "XX.XXXXXX"
				f_map[#f_map + 1] = "YYMMDDhhmm"
			end
			return table.concat(f_map, ",")
		end
		if d1 == 0x03 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x03 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3","XXXXXXXX"}
			return table.concat(f_map, ",")
		end
		if d1 == 0x04 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x04 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"C0C1C2C3","YYMMDDhhmmss","YYMMDDhhmmss"}
			return table.concat(f_map, ",")
		end
		if d1 == 0x05 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x05 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			for i = 1, 16 do
				f_map[#f_map + 1] = "hhmmNN"
			end
			return table.concat(f_map, ",")
		end
		if d1 == 0x06 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x06 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			for i = 1, 28 do
				f_map[#f_map + 1] = "MMDDNN"
			end
			return table.concat(f_map, ",")
		end
		if (d1 == 0x07 or d1 == 0x09 or d1 == 0x0A or d1 == 0x0B) and d0 = 0x00 then
			return "XXXXXX"
		end
		if (d1 == 0x07 or d1 == 0x09 or d1 == 0x0A or d1 == 0x0B) and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3", "XX"}
			return table.concat(f_map, ",")
		end
		if d1 == 0x08 and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x08 and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			for i = 1, 254 do
				f_map[#f_map + 1] = "YYMMDDNN"
			end
			return table.concat(f_map, ",")
		end
		if d1 == 0x0C and d0 = 0x00 then
			return "XXXXXX"
		end
		if d1 == 0x0C and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","C0C1C2C3"}
			for i = 1, 3 do
				f_map[#f_map + 1] = "DDhh"
			end
			return table.concat(f_map, ",")
		end
		if (d1 == 0x0D or d1 == 0x0E) and d0 = 0x00 then
			return "XXXXXX"
		end
		if (d1 == 0x0D or d1 == 0x0E) and d0 >= 0x01 and d0 <= 0x0A then
			local f_map = {"YYMMDDhhmmss","YYMMDDhhmmss"}
			for i = 1, 12 do
				f_map[#f_map + 1] = "XXXXXX.XX"
			end
			return table.concat(f_map, ",")
		end
	end
	if d3 == 0x03 and d2 == 0x32 then
		if (d1 >= 0x01 and d1 <= 0x06) and (d0 >= 0x01 and d0 <= 0x0A) then
			local f_map = {"YYMMDDhhmm","XXXX"}
			for i = 1, 4 do
				f_map[#f_map + 1] = "XXXXXX.XX"
			end
			return table.concat(f_map, ",")
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
			local f_map = {"NNNNNNNNNNNN", "NNNNNNNNNNNN", "N32", "XXXXXXXXXXXX", "XXXXXXXXXXXX", "XXXXXXXXXXXX", "XXXXXXXX", "XXXXXXXX", "XXXXXX", "XXXXXX", "X10", "X10", "X16", "N12"}
			return f_map[d0]
		end
		if d1 == 0x05 then
			if d1 >= 0x01 and d1 <= 0x07 then
				return "XXXX"
			end
			if d0 == 0xFF then
				return "XXXX"
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
				for i = 1, 14 do
					f_map[#f_map + 1] = "MMDDNN"
				end
				return table.concat(f_map, ",")
			end
			if d0 >= 0x01 and d0 <= 08 then
				local f_map = {}
				for i = 1, 14 do
					f_map[#f_map + 1] = "hhmmNN"
				end
				return table.concat(f_map, ",")
			end
		end
	end
	if d3 == 0x04 and d2 == 0x03 then
		if d1 == 0x00 then
			return "YYMMDDNN"
		end
	end
	if d3 == 0x04 and d2 == 0x04 then
		if d1 == 0x01 or d1 == 0x02 then
			return "NNNNNNNN,NN"
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
		if d1 == 0x00 then
			return "NNNNNN.NN"
		end
		if d1 == 0x01 then
			return "NNNN.NNNN"
		end
		if d1 == 0x02 then
			return "NNNNNN.NN"
		end
		if d1 == 0x03 then
			return "NNNN.NNNN"
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
				local f_map = {}
				for i = 1, 64 do
					f_map[#f_map + 1] = "XXXXXX.XX"
				end
				return table.concat(f_map, ",")
			end
			if d1 >= 0x09 and d1 <= 0x0A then
				local f_map = {}
				for i = 1, 64 do
					f_map[#f_map + 1] = "XX.XXXX"
				end
				f_map[#f_map + 1] = "YYMMDDhhmm"
				return table.concat(f_map, ",")
			end
			if d1 == 0x10 then
				local f_map = {}
				for i = 1, 8 do
					f_map[#f_map + 1] = "XX.XXXX"
				end
				return table.concat(f_map, ",")
			end
			if d1 == 0xFF then
				--- TOD:
			end
		end
	end
	if d3 == 0x05 and (d2 == 0x01 or d2 == 0x02 or d2 == 0x03) then
		if d0 >= 0x01 and d0 <= 0x03 then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end
			if d1 >= 0x01 and d1 <= 0x08 then
				local f_map = {}
				for i = 1, 64 do
					f_map[#f_map + 1] = "XXXXXX.XX"
				end
				return table.concat(f_map, ",")
			end
			if d1 >= 0x09 and d1 <= 0x0A then
				local f_map = {}
				for i = 1, 64 do
					f_map[#f_map + 1] = "XX.XXXX"
				end
				f_map[#f_map + 1] = "YYMMDDhhmm"
				return table.concat(f_map, ",")
			end
			if d1 == 0x10 then
				local f_map = {}
				for i = 1, 8 do
					f_map[#f_map + 1] = "XX.XXXX"
				end
				return table.concat(f_map, ",")
			end
			if d1 == 0xFF then
				--- TOD:
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
				-- TODO:
			end
		end
	end
	if d3 == 0x05 and d2 == 0x06 then
		if d0 >= 0x01 and d0 <= 0x3E then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end
			if d1 >= 0x01 and d1 <= 0x08 then
				return "XXXXXX.XX"
			end
			if d1 == 0x09 or d1 == 0x0A then
				return "XX.XXXX,YYMMDDhhmm"
			end
			if d1 == 0x10 then
				return "XX.XXXX"
			end
			if d1 == 0xFF then
				-- TODO:
			end
		end
	end
	if d3 == 0x05 and d2 == 0x07 then
		if d0 >= 0x01 and d0 <= 0x02 then
			if d1 == 0x00 then
				return "YYMMDDhhmm"
			end
			if d1 >= 0x01 and d1 <= 0x08 then
				return "XXXXXX.XX"
			end
			if d1 == 0x09 or d1 == 0x0A then
				return "XX.XXXX,YYMMDDhhmm"
			end
			if d1 == 0x10 then
				return "XX.XXXX"
			end
			if d1 == 0xFF then
				-- TODO:
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

	-- TODO:
end

local function get_format_len(format)
	local f = string.gsub(format, '%.', '')

	return math.ceil(string.len(f) / 2)
end


function _M.encode(addr, value, format)
	local format = format or get_format(addr)

	return encode_addr(addr) .. encode_data(value, format)
end

function _M.encode_table(dt)
	local data = {}
	for _, v in ipairs(dt) do
		data[#data + 1] = _M.encode(v.addr, v.value, v.format)
	end
	return table.concat(data)
end


function _M.decode(raw, format)
	local vals = {}
	while string.len(raw) > 4 do
		local addr = string.unpack("!1<I4", raw)
		local format = format or get_format(addr)
		local len = get_format_len(format)
		
		local value = bcd.decode(string.sub(raw, 4 + 1, 4 + len), format)
		vals[#vals + 1] = {
			addr = addr,
			value = value
		}
		raw = string.sub(raw, 4 + len + 1)
	end

	if #vals == 1 then
		return vals[1]
	end

	return vals
end

return _M
