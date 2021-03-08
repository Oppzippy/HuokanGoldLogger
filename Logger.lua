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
	local guildName, _, _, guildRealm = GetGuildInfo("player")
	Logger:SetEvent({
		type = "GUILD_BANK_WITHDRAW",
		guild = {
			name = guildName,
			realm = guildRealm or GetRealmName(),
		},
	})
end)

hooksecurefunc("DepositGuildBankMoney", function()
	local guildName, _, _, guildRealm = GetGuildInfo("player")
	Logger:SetEvent({
		type = "GUILD_BANK_DEPOSIT",
		guild = {
			name = guildName,
			realm = guildRealm or GetRealmName(),
		},
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
		if buyerName == "" then
			buyerName = nil
		end
		local _, _, sender, _, money = GetInboxHeaderInfo(index)
		if money > 0 then
			-- There's no good way of matching mails to the loot received from them,
			-- so we just go by amount of gold and hope that's unique enough for the most part
			-- Worst case, we have a mail show up as UNKNOWN.
			local event
			if isInvoice and invoiceType == "seller" then
				event = {
					type = "AUCTION_HOUSE_SELL",
					sender = sender,
					itemName = itemName,
					buyerName = buyerName
				}
			else
				event = {
					type = "MAIL_IN",
					sender = sender,
				}
			end
			Logger.mailEvents[money] = event
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
	self.mailEvents = {}

	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	self:RegisterEvent("MAIL_SHOW")
	self:RegisterEvent("MAIL_CLOSED")
	self:RegisterEvent("TRADE_SHOW")
	self:RegisterEvent("PLAYER_TRADE_MONEY")
	self:RegisterEvent("BLACK_MARKET_BID_RESULT")
	self:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
	self:RegisterEvent("LOOT_SLOT_CLEARED")
	self:RegisterEvent("QUEST_TURNED_IN")
	self:RegisterEvent("TAXIMAP_CLOSED")
	self:RegisterEvent("LFG_COMPLETION_REWARD")

	self:RegisterEvent("PLAYER_MONEY")
end

function Logger:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self.prevMoney = GetMoney()
end

function Logger:MAIL_SHOW()
	if self.clearMailEventsTimer then
		self.clearMailEventsTimer:Cancel()
		self.clearMailEventsTimer = nil
	end
end

function Logger:MAIL_CLOSED()
	if self.clearMailEventsTimer then
		self.clearMailEventsTimer:Cancel()
	end
	self.clearMailEventsTimer = C_Timer.NewTimer(5, function()
		self.mailEvents = {}
		self.clearMailEventsTimer = nil
	end)
end

function Logger:TRADE_SHOW()
	local name, realm = UnitName("npc")
	self.tradeTarget = {
		name = name,
		realm = realm or GetRealmName(),
	}
end

function Logger:PLAYER_TRADE_MONEY()
	self:SetEvent({
		type = "TRADE",
		tradeTarget = self.tradeTarget,
	})
	self.tradeTarget = nil
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

function Logger:TAXIMAP_CLOSED()
	self:SetEvent({
		type = "FLIGHT_PATH",
	})
end

function Logger:LFG_COMPLETION_REWARD()
	self:SetEvent({
		type = "LFG_COMPLETION_REWARD",
	})
end

function Logger:PLAYER_MONEY()
	local money, prevMoney = GetMoney(), self.prevMoney
	if money ~= prevMoney then
		self.prevMoney = money
		local diff = money - prevMoney
		if (MailFrame:IsVisible() or self.clearMailEventsTimer) and self.mailEvents[diff] then
			self:SetEvent(self.mailEvents[diff])
		end
		self:Log(prevMoney, money, self.event)
		self:SetEvent(nil)
	end
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
		if HuokanGoldLogger_DebugMode then
			Core:Print("Unknown gold change!")
		end
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
