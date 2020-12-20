local AceAddon = LibStub("AceAddon-3.0")

local addon = AceAddon:NewAddon("HuokanGoldLogger", "AceEvent-3.0")

hooksecurefunc("BuyMerchantItem", function(index, quantity)
	addon.event = {
		type = "VENDOR_BUY",
		item = GetMerchantItemLink(index),
		quantity = quantity,
	}
end)

hooksecurefunc("BuybackItem", function(index)
	local _, _, _, quantity = GetBuybackItemInfo(index)
	addon.event = {
		type = "VENDOR_BUYBACK",
		item = GetBuybackItemLink(index),
		quantity = quantity,
	}
end)

hooksecurefunc("UseContainerItem", function(bagId, slot)
	if MerchantFrame:IsVisible() then
		local _, quantity = GetContainerItemInfo(bagId, slot)
		addon.event = {
			type = "VENDOR_SELL",
			item = GetContainerItemLink(bagId, slot),
			quantity = quantity,
		}
	end
end)

hooksecurefunc("SellCursorItem", function()
	if MerchantFrame:IsVisible() and CursorHasItem() then
		local _, _, itemLink = GetCursorInfo()
		addon.event = {
			type = "VENDOR_SELL",
			item = itemLink,
		}
	end
end)

function addon:OnInitialize()
	self.prevMoney = GetMoney()

	self:RegisterEvent("PLAYER_MONEY")
end

function addon:PLAYER_MONEY()
	local money, prevMoney = GetMoney(), self.prevMoney
	self.prevMoney = money
	self:Log(prevMoney, money, self.event)
	self.event = nil
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

function addon:Log(prevMoney, newMoney, event)
	if not event then
		event = {
			type = "UNKNOWN",
		}
	end
	event.prevMoney = prevMoney
	event.newMoney = newMoney
	ViragDevTool_AddData(event)
end
