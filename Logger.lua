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

hooksecurefunc("WithdrawGuildBankMoney", function()
	Logger:SetEvent({
		type = "GUILD_BANK_WITHDRAW"
	})
end)

hooksecurefunc("DepositGuildBankMoney", function()
	Logger:SetEvent({
		type = "GUILD_BANK_DEPOSIT"
	})
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

do
	local function onLoot(index)
		local _, _, _, _, isInvoice = GetInboxText(index)
		local invoiceType, itemName, buyerName = GetInboxInvoiceInfo(index)
		if isInvoice and invoiceType == "seller" then
			Logger:SetEvent({
				type = "AUCTION_HOUSE_SELL",
				itemName = itemName,
				buyerName = buyerName
			})
		else
			Logger:SetEvent({
				type = "MAIL_IN",
			})
		end
	end

	hooksecurefunc("AutoLootMailItem", onLoot)
	hooksecurefunc("TakeInboxMoney", onLoot)
end

hooksecurefunc("SendMail", function(recipient)
	Logger:SetEvent({
		type = "MAIL_OUT",
		recipient = recipient,
	})
end)

function Logger:OnInitialize()
	self.character = {
		name = UnitName("player"),
		realm = GetRealmName(),
	}

	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("BLACK_MARKET_BID_RESULT")
	self:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("QUEST_TURNED_IN")

	self:RegisterEvent("PLAYER_MONEY")
end

function Logger:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.prevMoney = GetMoney()
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

function Logger:LOOT_SLOT_CLEARED()
	self:SetEvent({
		type = "LOOT",
	})
end

function Logger:QUEST_TURNED_IN(_, questId, _, copperReward)
	if copperReward and copperReward > 0 then
		self:SetEvent({
			type = "QUEST_REWARD",
			questId = questId,
		})
	end
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
