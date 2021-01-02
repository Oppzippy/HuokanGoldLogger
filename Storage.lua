local _, addon = ...

local Deflate = LibStub("LibDeflate")
local JSON = LibStub("json.lua")
local Base64 = LibStub("base64")

local Core = addon.Core
local Storage = Core:NewModule("Storage", "AceEvent-3.0")

function Storage:OnInitialize()
	if not HuokanGoldLog then
		HuokanGoldLog = {}
	end
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Storage:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	if #HuokanGoldLog > 10000 then
		Core:Print("Your log file is getting big. Consider using \"/huokangoldlogger compress\" to significantly decrease file size.")
	end
end

function Storage:Store(event)
	HuokanGoldLog[#HuokanGoldLog+1] = self:Encode(event)
end

function Storage:Encode(event)
	local json = JSON.encode(event)
	local compressed = Deflate:CompressDeflate(json)
	return Base64.encode(compressed)
end

function Storage:Decode(b64)
	local compressed = Base64.decode(b64)
	local json = Deflate:DecompressDeflate(compressed)
	return JSON.decode(json)
end

function Storage:CompressAfter(startIndex)
	local endIndex = #HuokanGoldLog
	if endIndex <= startIndex then return end

	local events = {}
	for i = startIndex, endIndex do
		local b64 = HuokanGoldLog[i]
		local event = self:Decode(b64)
		if event[1] then
			for _, subEvent in ipairs(event) do
				events[#events+1] = subEvent
			end
		else
			events[#events+1] = event
		end
	end

	HuokanGoldLog[startIndex] = self:Encode(events)
	for i = startIndex + 1, endIndex do
		HuokanGoldLog[i] = nil
	end
end

function Storage:GetFirstUncompressedIndex()
	for i, b64 in ipairs(HuokanGoldLog) do
		local compressed = Base64.decode(b64)
		local json = Deflate:DecompressDeflate(compressed)
		-- Skip the json parsing step for efficiency and just look at the first character
		if json:sub(1, 1) == "{" then
			-- Not an array so it's a single event
			return i
		end
	end
end
