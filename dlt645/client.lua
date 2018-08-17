local skynet = require 'skynet'
local apdu = require 'dlt645.apdu'
local code = require "dlt645.code"
local class = require 'middleclass'

local client = class("DLT645_SKYNET_CLIENT")

local function packet_decode(apdu)
	return function(raw)
		return apdu:decode(raw)
	end
end

local function compose_message(apdu, req)
	if type(req.code) == 'string' then
		req.code = code[req.code]
	end
	local data = apdu:encode_addr(req.data_addr)
	return assert(apdu:encode(req.addr, req.code, data))
end

local function make_read_response(apdu, req, timeout, cb)
	return function(sock)
		local start = skynet.now()
		local buf = ""
		local need_len = apdu._min_packet_len
		local decode = packet_decode(apdu)

		while true do
			local t = (timeout / 10) - (skynet.now() - start)
			if t <= 0 then
				break
			end

			local str, err = sock:read(need_len, t)
			if not str then
				return false, err
			end
			if cb then
				cb("IN", str)
			end

			buf = buf..str
			local pdu, buf, need_len = decode(buf)
			if pdu then
				if pdu.addr == req.addr and pdu.code == req.code then
					-- TODO: read next if pdu.not_end is true
					return true, pdu
				else
					return false, "Data address or Function code is not matched!"
				end
			end
		end
		return false, "DLT645 Request timeout"
	end
end

function client:initialize(sc, opt, master)
	local channel = sc.channel(opt)
	self._chn = channel
	self._apdu = apdu:new(master)
end

function client:connect(only_once)
	return self._chn:connect(only_once)
end

function client:set_io_cb(cb)
	self._data_cb = cb
end

function client:request(req, timeout)
	local cb = self._data_cb
	local pdu = compose_message(self._apdu, req)
	if cb then
		cb("OUT", pdu)
	end
	return self._chn:request(pdu, make_read_response(self._apdu, req, timeout, cb))
end

return client
