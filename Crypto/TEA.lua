local TEA = {}
local _, addon = ...
addon.TEA = TEA

-- encryptBlock and decryptBlock are converted from c to lua from here
-- https://en.wikipedia.org/wiki/Tiny_Encryption_Algorithm#Reference_code

local function doOverflow(num)
	return bit.band(num, 0xFFFFFFFF)
end

local function stringToInts(str)
	local t = {}
	for i = 1, #str, 4 do
		-- Big endian
		local c1 = string.byte(str:sub(i, i)) or 0
		local c2 = string.byte(str:sub(i+1, i+1)) or 0
		local c3 = string.byte(str:sub(i+2, i+2)) or 0
		local c4 = string.byte(str:sub(i+3, i+3)) or 0
		local num = bit.lshift(c1, 24) + bit.lshift(c2, 16) + bit.lshift(c3, 8) + c4
		t[#t+1] = num
	end
	if (#t % 2) ~= 0 then
		t[#t+1] = 0
	end
	return t
end

local function intsToString(t)
	local chars = {}
	for _, num in ipairs(t) do
		-- Big endian
		local c1 = bit.rshift(bit.band(num, 0xFF000000), 24)
		local c2 = bit.rshift(bit.band(num, 0x00FF0000), 16)
		local c3 = bit.rshift(bit.band(num, 0x0000FF00), 8)
		local c4 = bit.band(num, 0x000000FF)
		chars[#chars+1] = string.char(c1)
		chars[#chars+1] = string.char(c2)
		chars[#chars+1] = string.char(c3)
		chars[#chars+1] = string.char(c4)
	end
	return table.concat(chars, "")
end

local function encryptBlock(v, k)
	local v0, v1 = v[1], v[2]
	local sum = 0
	local delta = 0x9E3779B9
	local k0, k1, k2, k3 = k[1], k[2], k[3], k[4]
	for _ = 1, 32 do
		sum = doOverflow(sum + delta)
		v0 = doOverflow(v0 + bit.bxor(bit.bxor((bit.lshift(v1, 4) + k0), (v1 + sum)), (bit.rshift(v1, 5) + k1)))
		v1 = doOverflow(v1 + bit.bxor(bit.bxor((bit.lshift(v0, 4) + k2), (v0 + sum)), (bit.rshift(v0, 5) + k3)))
	end
	return v0, v1
end

local function decryptBlock(v, k)
	local v0, v1 = v[1], v[2]
	local sum = 0xC6EF3720
	local delta = 0x9E3779B9
	local k0, k1, k2, k3 = k[1], k[2], k[3], k[4]
	for _ = 1, 32 do
        v1 = doOverflow(v1 - bit.bxor(bit.bxor(bit.lshift(v0, 4) + k2, (v0 + sum)), (bit.rshift(v0, 5) + k3)))
        v0 = doOverflow(v0 - bit.bxor(bit.bxor(bit.lshift(v1, 4) + k0, (v1 + sum)), (bit.rshift(v1, 5) + k1)))
		sum = doOverflow(sum - delta)
	end
	return v0, v1
end

function TEA.encrypt(data, key)
	local ints = stringToInts(data)
	local result = {}
	for i = 1, #ints, 2 do
		local v0, v1 = encryptBlock({ints[i], ints[i+1] or 0}, key)
		result[#result+1] = v0
		result[#result+1] = v1
	end
	return intsToString(result)
end

function TEA.decrypt(data, key)
	local ints = stringToInts(data)
	local result = {}
	for i = 1, #ints, 2 do
		local v0, v1 = decryptBlock({ints[i], ints[i+1]}, key)
		result[#result+1] = v0
		result[#result+1] = v1
	end
	return intsToString(result)
end
