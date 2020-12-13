local AceAddon = LibStub("AceAddon-3.0")

local addon = AceAddon:NewAddon("HuokanGoldLogger", "AceEvent-3.0")

function addon:OnInitialize()
	self.prevMoney = GetMoney()

	self:RegisterEvent("PLAYER_MONEY")
end

function addon:PLAYER_MONEY()
	local money, prevMoney = GetMoney(), self.prevMoney
	self.prevMoney = money
	self:Log(prevMoney, money, "UNKNOWN")
end

function addon:LogTrade(trade)
end

function addon:LogVendor(vendor)
end

function addon:LogRepair(repair)
end

function addon:LogBankTransaction(transaction)
end

function addon:LogMail(mail)
end

function addon:LogAuctionDeposit(auction)
end

function addon:LogLoot(loot)
end

function addon:Log(obj)
	-- todo log object
end
