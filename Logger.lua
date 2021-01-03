local _, addon = ...

local Core = addon.Core
local Logger = Core:NewModule("Logger", "AceEvent-3.0")

hooksecurefunc("BuyMerchantItem", function(index, quantity)
	Logger:SetEvent({
		type = "VENDOR_BUY",
		item = GetMerchantItemLink(index),
		quantity = quantity,
	})
end)

hooksecurefunc("BuybackItem", function(index)
	local _, _, _, quantity = GetBuybackItemInfo(index)
	Logger:SetEvent({
		type = "VENDOR_BUYBACK",
		item = GetBuybackItemLink(index),
		quantity = quantity,
	})
end)

hooksecurefunc("UseContainerItem", function(bagId, slot)
	if MerchantFrame:IsVisible() then
		local _, quantity = GetContainerItemInfo(bagId, slot)
		Logger:SetEvent({
			type = "VENDOR_SELL",
			item = GetContainerItemLink(bagId, slot),
			quantity = quantity,
		})
	end
end)

hooksecurefunc("RepairAllItems", function(isGuildBankRepair)
	if not isGuildBankRepair then
		Logger:SetEvent({
			type = "REPAIR",
		})
	end
end)

hooksecurefunc("SellCursorItem", function()
	if MerchantFrame:IsVisible() and CursorHasItem() then
		local _, _, itemLink = GetCursorInfo()
		Logger:SetEvent({
			type = "VENDOR_SELL",
			item = itemLink,
		})
	end
end)

hooksecurefunc(
	C_AuctionHouse,
	"ConfirmCommoditiesPurchase",
	function(itemId, quantity)
		Logger:SetEvent({
			type = "AUCTION_HOUSE_COMMODITY_BUY",
			itemName = C_Item.GetItemNameByID(itemId),
			itemId = itemId,
			quantity = quantity,
		})
	end
)

hooksecurefunc(
	C_AuctionHouse,
	"PlaceBid",
	function(auctionId, bidAmount)
		-- TODO check if it's a bid or buyout since they both use this same function
		local _, itemLink = AuctionHouseFrame.ItemBuyFrame.ItemDisplay:GetItemInfo()
		Logger:SetEvent({
			type = "AUCTION_HOUSE_BID",
			item = itemLink,
		})
	end
)

hooksecurefunc("AutoLootMailItem", function()
	Logger:SetEvent({
		type = "MAIL_INCOMING",
	})
end)

hooksecurefunc("TakeInboxMoney", function()
	Logger:SetEvent({
		type = "MAIL_INCOMING",
	})
end)

hooksecurefunc("SendMail", function()
	Logger:SetEvent({
		type = "MAIL_OUTGOING",
	})
end)

function Logger:OnInitialize()
	self.prevMoney = GetMoney()
	self.character = {
		name = UnitName("player"),
		realm = GetRealmName(),
	}

	self:RegisterEvent("PLAYER_MONEY")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("BLACK_MARKET_BID_RESULT")
	self:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("LOOT_CLOSED")
	self:RegisterEvent("GUILDBANK_UPDATE_WITHDRAWMONEY")
end

function Logger:PLAYER_TRADE_MONEY()
	-- XXX sometimes this event fires after PLAYER_MONEY
	self:SetEvent({
		type = "TRADE",
	})
end

function Logger:BLACK_MARKET_BID_RESULT()
	self:SetEvent({
		type = "BMAH_BID",
	})
end

function Logger:AUCTION_HOUSE_AUCTION_CREATED()
	self:SetEvent({
		type = "AUCTION_HOUSE_DEPOSIT",
	})
end

function Logger:LOOT_SLOT_CLEARED(slot)
	self:SetEvent({
		type = "LOOT",
	})
end

function Logger:LOOT_CLOSED()
	C_Timer.After(0.1, function()
		self:SetEvent(nil)
	end)
end

function Logger:GUILDBANK_UPDATE_WITHDRAWMONEY()
	self:SetEvent({
		type = "GUILD_BANK"
	})
end

function Logger:PLAYER_MONEY()
	local money, prevMoney = GetMoney(), self.prevMoney
	self.prevMoney = money
	self:Log(prevMoney, money, self.event)
	self:SetEvent(nil)
end

function Logger:SetEvent(event)
	self.event = event
	self.eventUpdatedAt = GetTime()
end

function Logger:Log(prevMoney, newMoney, event)
	if self.eventUpdatedAt and GetTime() - self.eventUpdatedAt > 10 then
		-- expire old events
		self:SetEvent(nil)
	end
	if not event then
		event = {
			type = "UNKNOWN",
		}
	end
	event.prevMoney = prevMoney
	event.newMoney = newMoney
	event.timestamp = date("!%Y-%m-%dT%TZ")
	event.character = self.character

	local Storage = Core:GetModule("Storage")
	Storage:Store(event)
end
