local _, addon = ...

local AceAddon = LibStub("AceAddon-3.0")

local Core = AceAddon:NewAddon("HuokanGoldLogger", "AceConsole-3.0")
addon.Core = Core

if not HuokanGoldLog then HuokanGoldLog = {} end

function Core:OnInitialize()
	self:RegisterChatCommand("huokangoldlogger", "SlashCmd")
	self:RegisterChatCommand("huokangoldlog", "SlashCmd")
	self:RegisterChatCommand("hgl", "SlashCmd")
	if #HuokanGoldLog > 10000 then
		local Storage = self:GetModule("Storage")
		local startIndex = Storage:GetFirstUncompressedIndex()
		Storage:CompressAfter(startIndex)
	end
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
	elseif args == "fullcompress" then
		local Storage = self:GetModule("Storage")
		self:Print("Fully compressing gold log. This may take some time.")
		Storage:CompressAfter(1)
		self:Print("Done compressing!")
	elseif args == "help" or args == "?" or args == "" then
		self:Print([[
Don't use any of these commands unless you know what you're doing and have a good reason.
/huokangoldlogger compress - Compresses all log data since the last compress.
/huokangoldlogger fullcompress - Decompresses all data from previous compressions, merges it all together, and compresses again. This will result in a significantly smaller file after many compressons have ben run but may take a long time with large log files. Make a backup of your log first before using this.
]])
	end
end
