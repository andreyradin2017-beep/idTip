local select, UnitBuff, UnitDebuff, UnitAura, tonumber, hooksecurefunc, GetLocale =
	select, UnitBuff, UnitDebuff, UnitAura, tonumber, hooksecurefunc, GetLocale

local isRU = GetLocale() == "ruRU"
local ITEM_LABEL = isRU and "ID предмета:" or "ItemID:"
local SPELL_LABEL = isRU and "ID заклинания:" or "SpellID:"

-- Explicit state machine for "what is currently shown in this tooltip".
-- status: "idle" | "shown"; value: last shown id. Keeping item and spell
-- slots separate prevents one kind from suppressing the other.
local function newStateSlot() return { status = "idle", value = nil } end

local function getState(self)
	if not self.idTipMachine then
		self.idTipMachine = { item = newStateSlot(), spell = newStateSlot() }
	end
	return self.idTipMachine
end

local function transition(slot, event)
	if event.type == "RESET" then
		slot.status = "idle"
		slot.value = nil
		return true
	end
	if event.type == "SHOW" then
		if slot.status == "shown" and slot.value == event.value then
			return false -- duplicate, suppress
		end
		slot.status = "shown"
		slot.value = event.value
		return true
	end
	return false
end

local function addLine(self, id, isItem)
	local machine = getState(self)
	local slot = isItem and machine.item or machine.spell
	if not transition(slot, { type = "SHOW", value = id }) then
		return
	end

	if isItem then
		self:AddDoubleLine(ITEM_LABEL, "|cffffffff" .. id .. "|r")
	else
		self:AddDoubleLine(SPELL_LABEL, "|cffffffff" .. id .. "|r")
	end
	self:Show()
end

local function clearIdTip(self)
	local machine = self.idTipMachine
	if not machine then return end
	transition(machine.item, { type = "RESET" })
	transition(machine.spell, { type = "RESET" })
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