local select, UnitBuff, UnitDebuff, UnitAura, tonumber, hooksecurefunc, GetLocale =
	select, UnitBuff, UnitDebuff, UnitAura, tonumber, hooksecurefunc, GetLocale

local isRU = GetLocale() == "ruRU"
local ITEM_LABEL = isRU and "ID предмета:" or "ItemID:"
local SPELL_LABEL = isRU and "ID заклинания:" or "SpellID:"

local function addLine(self, id, isItem)
	local field = isItem and "idTipLastItem" or "idTipLastSpell"
	if self[field] == id then return end
	self[field] = id

	if isItem then
		self:AddDoubleLine(ITEM_LABEL, "|cffffffff" .. id .. "|r")
	else
		self:AddDoubleLine(SPELL_LABEL, "|cffffffff" .. id .. "|r")
	end
	self:Show()
end

local function clearIdTip(self)
	self.idTipLastItem = nil
	self.idTipLastSpell = nil
end

-- Spell Hooks ----------------------------------------------------------------
hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, unit, index, filter)
	local id = select(11, UnitBuff(unit, index, filter))
	if id then addLine(self, id) end
end)

hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self, unit, index, filter)
	local id = select(11, UnitDebuff(unit, index, filter))
	if id then addLine(self, id) end
end)

hooksecurefunc(GameTooltip, "SetUnitAura", function(self, unit, index, filter)
	local id = select(11, UnitAura(unit, index, filter))
	if id then addLine(self, id) end
end)

GameTooltip:HookScript("OnTooltipSetSpell", function(self)
	local _, _, id = self:GetSpell()
	if id then addLine(self, id) end
end)

-- Item Hooks -----------------------------------------------------------------
hooksecurefunc("SetItemRef", function(link)
	if type(link) ~= "string" then return end
	local id = tonumber(link:match("spell:(%d+)"))
	if id then addLine(ItemRefTooltip, id) end
end)

local function attachItemTooltip(self)
	local _, link = self:GetItem()
	if not link then return end
	local id = tonumber(tostring(link):match("item:(%d+)"))
	if id then addLine(self, id, true) end
end

GameTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip3:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
ShoppingTooltip3:HookScript("OnTooltipSetItem", attachItemTooltip)

-- avoid repeated ID lines on tooltip updates
for _, tt in ipairs({GameTooltip, ItemRefTooltip, ItemRefShoppingTooltip1, ItemRefShoppingTooltip2, ItemRefShoppingTooltip3, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3}) do
	if tt then tt:HookScript("OnHide", clearIdTip) end
end