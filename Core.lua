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

hooksecurefunc("RepairAllItems", function(isGuildBankRepair)
	if not isGuildBankRepair then
		addon.event = {
			type = "REPAIR",
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

hooksecurefunc(
	C_AuctionHouse,
	"ConfirmCommoditiesPurchase",
	function(itemId, quantity)
		addon.event = {
			type = "AUCTION_HOUSE_COMMODITY_BUY",
			itemid = itemId,
			quantity = quantity,
		}
	end
)

hooksecurefunc(
	C_AuctionHouse,
	"PlaceBid",
	function(auctionId, bidAmount)
		-- TODO check if it's a bid or buyout since they both use this same function
		-- Add item link
		addon.event = {
			type = "AUCTION_HOUSE_BID",
		}
	end
)

hooksecurefunc("AutoLootMailItem", function()
	addon.event = {
		type = "MAIL",
	}
end)

hooksecurefunc("TakeInboxMoney", function()
	addon.event = {
		type = "MAIL",
	}
end)

function addon:OnInitialize()
	self.prevMoney = GetMoney()

	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("BLACK_MARKET_BID_RESULT")
	self:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("LOOT_CLOSED")
end

function addon:PLAYER_TRADE_MONEY()
	-- XXX sometimes this event fires after PLAYER_MONEY
	self.event = {
		type = "TRADE",
	}
end

function addon:BLACK_MARKET_BID_RESULT()
	self.event = {
		type = "BMAH_BID",
	}
end

function addon:AUCTION_HOUSE_AUCTION_CREATED()
	self.event = {
		type = "AUCTION_HOUSE_DEPOSIT",
	}
end

function addon:LOOT_SLOT_CLEARED(slot)
	self.event = {
		type = "LOOT",
	}
end

function addon:LOOT_CLOSED()
	C_Timer.After(0.1, function()
		self.event = nil
	end)
end

function addon:PLAYER_MONEY()
	local money, prevMoney = GetMoney(), self.prevMoney
	self.prevMoney = money
	self:Log(prevMoney, money, self.event)
	self.event = nil
end

function addon:LogTrade(trade)
end

function addon:LogBankTransaction(transaction)
end

function addon:LogMail(mail)
end

function addon:Log(prevMoney, newMoney, event)
	if not event then
		event = {
			type = "UNKNOWN",
		}
	end
	event.prevMoney = prevMoney
	event.newMoney = newMoney
	event.timestamp = date("!%Y-%m-%dT%TZ")
	ViragDevTool_AddData(event)
end
