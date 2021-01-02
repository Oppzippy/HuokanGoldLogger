local _, addon = ...

local AceAddon = LibStub("AceAddon-3.0")

local Core = AceAddon:NewAddon("HuokanGoldLogger", "AceConsole-3.0")
addon.Core = Core

function Core:OnInitialize()
	self:RegisterChatCommand("huokangoldlogger", "SlashCmd")
	self:RegisterChatCommand("huokangoldlog", "SlashCmd")
	self:RegisterChatCommand("hgl", "SlashCmd")
end

function Core:SlashCmd(args)
	if args == "compress" then
		local Storage = self:GetModule("Storage")
		self:Print("Compressing gold log.")
		local startIndex = Storage:GetFirstUncompressedIndex()
		if startIndex then
			Storage:CompressAfter(startIndex)
			self:Print("Done compressing!")
		else
			self:Print("Already compressed!")
		end
		local logSize = #HuokanGoldLog
		if logSize >= 20 then
			self:Printf("Your log file is still %d lines long after compressing. Consider running a full compress. Type \"/huokangoldlogger help\" for more info.", logSize)
		end
	elseif args == "fullcompress" then
		local Storage = self:GetModule("Storage")
		self:Print("Fully compressing gold log. This may take some time.")
		Storage:CompressAfter(1)
		self:Print("Done compressing!")
	elseif args == "help" or args == "?" or args == "" then
		self:Print([[\n
/huokangoldlogger compress - Compresses all log data since the last compress
/huokangoldlogger fullcompress - Decompresses all data from previous compressions, merges it all together, and compresses again. This will result in a significantly smaller file after many compressons have ben run but may take a long time with large log files.
]])
	end
end
