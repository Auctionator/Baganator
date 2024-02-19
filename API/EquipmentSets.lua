-- Blizzard Equipment sets (Wrath onwards)
do
  local BlizzardSetTracker = CreateFrame("Frame")

  function BlizzardSetTracker:OnLoad()
    FrameUtil.RegisterFrameForEvents(self, {
      "BANKFRAME_OPENED",
      "EQUIPMENT_SETS_CHANGED",
      "PLAYER_LOGIN",
    })
    self.equipmentSetInfo = {}

    Baganator.API.RegisterItemSetSource(BAGANATOR_L_BLIZZARD, "blizzard", function(itemLocation, guid)
      return self.equipmentSetInfo[guid]
    end)
  end
  BlizzardSetTracker:OnLoad()

  function BlizzardSetTracker:QueueScan()
    self:SetScript("OnUpdate", self.OnUpdate)
  end

  BlizzardSetTracker:SetScript("OnEvent", function(self)
    self:QueueScan()
  end)

  function BlizzardSetTracker:OnUpdate()
    self:SetScript("OnUpdate", nil)
    self:ScanEquipmentSets()
  end

  -- Determine the GUID of all accessible items in an equipment set
  function BlizzardSetTracker:ScanEquipmentSets()
    -- Option is disabled on classic WoW for Macs because there is a crash when
    -- all 19 set item slots are occupied, see https://github.com/Stanzilla/WoWUIBugs/issues/511
    if IsMacClient() and not Baganator.Constants.IsRetail then
      return
    end

    local start = debugprofilestop()

    local oldSetInfo = CopyTable(self.equipmentSetInfo)

    local cache = {}
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
      local name, iconTexture = C_EquipmentSet.GetEquipmentSetInfo(setID)
      local info = {name = name, iconTexture = iconTexture, setID = setID}
      -- Uses or {} because a set might exist without any associated item
      -- locations
      for _, location in pairs(C_EquipmentSet.GetItemLocations(setID) or {}) do
        if location ~= -1 and location ~= 0 and location ~= 1 then
          local player, bank, bags, voidStorage, slot, bag
          if Baganator.Constants.IsClassic then
            player, bank, bags, slot, bag = EquipmentManager_UnpackLocation(location)
          else
            player, bank, bags, voidStorage, slot, bag = EquipmentManager_UnpackLocation(location)
          end
          local location, bagID, slotID
          if (player or bank) and bags then
            bagID = bag
            slotID = slot
            location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
          elseif bank and not bags then
            bagID = Baganator.Constants.AllBankIndexes[1]
            slotID = slot - BankButtonIDToInvSlotID(0)
            location = ItemLocation:CreateFromBagAndSlot(bagID, slotID)
          elseif player then
            location = ItemLocation:CreateFromEquipmentSlot(slot)
          end
          if location then
            local guid = C_Item.GetItemGUID(location)
            if not cache[guid] then
              cache[guid] = {}
            end
            table.insert(cache[guid], info)
          end
        end
      end
    end
    if Baganator.Config.Get(Baganator.Config.Options.DEBUG_TIMERS) then
      print("equipment set tracking took", debugprofilestop() - start)
    end
    if not tCompare(oldSetInfo, cache, 15) then
      self.equipmentSetInfo = cache
      Baganator.API.RequestItemButtonsRefresh()
    end
  end
end

-- ItemRack Classic
if not Baganator.Constants.IsRetail then
  Baganator.Utilities.OnAddonLoaded("ItemRack", function()
    local equipmentSetInfo = {}
    local function ItemRackUpdated()
      equipmentSetInfo = {}
      for name, details in pairs(ItemRackUser.Sets) do
        if name:sub(1, 1) ~= "~" then
          local setInfo = {name = name, icon = details.icon}
          for _, itemRef in pairs(details.equip) do
            if not equipmentSetInfo[itemRef] then
              equipmentSetInfo[itemRef] = {}
            end
            table.insert(equipmentSetInfo[itemRef], setInfo)
          end
        end
      end

      Baganator.API.RequestItemButtonsRefresh()
    end
    ItemRackUpdated()

    ItemRack:RegisterExternalEventListener("ITEMRACK_SET_SAVED", ItemRackUpdated)
    ItemRack:RegisterExternalEventListener("ITEMRACK_SET_DELETED", ItemRackUpdated)

    Baganator.API.RegisterItemSetSource("ItemRack", "item_rack_classic", function(itemLocation, guid, itemLink)
      if not guid then
        return
      end

      local id = ItemRack.GetIRString(itemLink)
      -- Workaround for ItemRack classic not getting the run id correctly for
      -- bag items
      if ItemRack.AppendRuneID and C_Engraving.IsInventorySlotEngravable(itemLocation:GetBagAndSlot()) then
        local runeInfo = C_Engraving.GetRuneForInventorySlot(itemLocation:GetBagAndSlot())
        if runeInfo then
          id = id .. ":runeid:" .. tostring(runeInfo.skillLineAbilityID)
        else
          id = id .. ":runeid:0"
        end
      end
      return equipmentSetInfo[id]
    end)
  end)
end
