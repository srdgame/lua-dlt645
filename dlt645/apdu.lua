local bcd = require 'bcd'
local sum = require 'hashings.sum'
local dlt645_code = require 'dlt645.code'

local class = require 'middleclass'

local apdu = class('DLT645_APDU_CLASS')

local FRAME_START = string.char(0x68)
local FRAME_END = string.char(0x16)


function apdu:initialize(master)
	if master then
		self._dir = 0
	else
		self._dir = 1
	end
	self._apdu_lead = string.pack("!1<BBBB", 0xFE, 0xFE, 0xFE, 0xFE)
	-- FE FE FE FE 68 AA AA AA AA AA AA 68 CC LL CS 16
	self._min_apdu_len = string.len(self._apdu_lead) + 12 
end

function apdu:broadcast_addr()
	return self:addr(999999999999)
end

function apdu:encode_addr(addr)
	return bcd.encode(addr, "XXXXXX")
end

function apdu:decode_addr(addr)
	return bcd.decode(string.sub(addr, 1, 6))
end

---
-- Create control code
-- @tparam integer code Control Code
-- @tparam integer dir Direction, 0 - Master to slave  1 - Slave to master
-- @tparam boolean sflag Slave exception apdu flag
-- @tparam boolean not_end Is there any continous apdu
function apdu:encode_code(code, dir, sflag, not_end)
	local code = tonumber(code) & 0x1F
	if not_end then
		code = code + (1 << 5)
	end
	if sflag then
		code = code + (1 << 6)
	end
	code = code + ((dir & 1) << 7)

	return code
end

function apdu:decode_code(code)
	local c = code & 0x1F
	local not_end = code & (1 << 5)
	local sflag = code & (1 << 6)
	local dir = code & (1 << 7)
	return c, dir, sflag, not_end
end

function apdu:encode_data(data)
	return string.gsub(data, '.', function(c)
		return string.char( (0x33 + string.byte(c)) % 0xFF)
	end)
end

function apdu:decode_data(data)
	return string.gsub(data, '.', function(c)
		return string.char( (string.byte(c) - 0x33 + 0xFF) % 0xFF)
	end)
end

function apdu:apdu_lead()
	return self._apdu_lead
end

function apdu:make_apdu(addr, code, data)
	local apdu_init = string.pack("!1<Bc6BBs1", 0x68, addr, 0x68, code, data)
	local cs = sum:new(apdu_init):digest()
	return self._apdu_lead .. apdu_init .. cs.. string.char(0x16)
end


---
-- Create DLT645 apdu
-- @tparam integer addr Unit address e.g. 0x1000001
-- @tparam integer code Control code
-- @tparam string data Frame data
-- @tparam boolean sflag Exception flag (slave mode only)
-- @treturn string apdu string
function apdu:encode(addr, code, data, sflag)
	local addr = self:encode_addr(addr)
	local sflag = self._dir == 1 and sflag or false
	local code = tonumber(code) and tonumber(code) or dlt645_code[code]

	local apdus = {}
	while string.len(data) > 0 do
		if string.len(data) > 200 then
			local c = self:encode_code(code, self._dir, sflag, true)
			local d = self:encode_data(string.sub(data, 1, 200))
			apdus[#apdus + 1] = self:make_apdu(addr, c, d)
			data = string.sub(data, 201)
		else
			local c = self:encode_code(code, self._dir, sflag, false)
			local d = self:encode_data(data)
			apdus[#apdus + 1] = self:make_apdu(addr, c, d)
			break
		end
	end

	if #apdus == 1 then
		return apdus[1]
	end

	return apdus
end

local function valid_apdu(raw)
	local lead_len = string.len(self._apdu_lead) + 1
	local r, h1, addr, h2, code, data, cs, ed, se = pcall(string.unpack, '!1<Bc6BBs1BB', raw, lead_len + 1)
	if not r then
		return nil, raw
	end

	if h1 ~= 0x68 or h2 ~= 0x68 or ed ~= 0x16 then
		return nil, string.sub(raw, lead_len + 1) -- only skip apdu lead
	end

	local rcs = sub:new(string.sub(lead_len + 1, se - 3)):digest()
	if rcs ~= cs then
		return nil, string.sub(raw, lead_len + 2) -- skip apdu lead and one 0x68
	end

	return {addr = addr, code = code, data = data}, string.sub(raw, se)
end

function apdu:decode(raw)
	local s, e = string.find(raw, self._apdu_lead..string.char(0x68), 1, true)
	if not e then
		return nil, "", self._min_apdu_len
	end
	local raw = string.sub(raw, s)
	if string.len(raw) < self._min_apdu_len then
		return nil, raw, self._min_apdu_len - string.len(raw)
	end

	local apdu, raw = valid_apdu(raw)
	if not apdu then
		-- recursive decode
		return self:decode(raw)
	end

	local code, dir, sflag, not_end = self:decode_code(apdu.code)
	if dir == self._dir then
		return self:decode(raw)
	end

	return {
		addr = self:decode_addr(apdu.addr),
		code = code,
		sflag = sflag,
		not_end = not_end,
		data = self:decode_data(apdu.data),
	}, raw
end

return apdu
