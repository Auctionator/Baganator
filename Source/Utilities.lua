Baganator.Utilities = {}

local function SplitLink(linkString)
  return linkString:match("^(.*)|H(.-)|h(.*)$")
end
-- Assumes itemLink is in the format found at
-- https://wowpedia.fandom.com/wiki/ItemLink
-- itemID : enchantID : gemID1 : gemID2 : gemID3 : gemID4
-- : suffixID : uniqueID : linkLevel : specializationID : modifiersMask : itemContext
-- : numBonusIDs[:bonusID1:bonusID2:...] : numModifiers[:modifierType1:modifierValue1:...]
-- : relic1NumBonusIDs[:relicBonusID1:relicBonusID2:...] : relic2NumBonusIDs[...] : relic3NumBonusIDs[...]
-- : crafterGUID : extraEnchantID
local function KeyPartsItemLink(itemLink)
  local pre, hyperlink, post = SplitLink(itemLink)

  local parts = { strsplit(":", hyperlink) }

  -- offset by 1 because the first item in "item", not the id
  for i = 3, 7 do
    parts[i] = ""
  end

  -- Remove uniqueID, linkLevel, specializationID, modifiersMask and itemContext
  for i = 9, 13 do
    parts[i] = ""
  end

  local numBonusIDs = tonumber(parts[14] or "") or 0

  for i = 14 + numBonusIDs + 1, #parts do
    parts[i] = nil
  end

  return strjoin(":", unpack(parts))
end

local function KeyPartsPetLink(itemLink)
  local pre, hyperlink, post = SplitLink(itemLink)

  local parts = { strsplit(":", hyperlink) }

  for i = 6, #parts do
    parts[i] = nil
  end

  return strjoin(":", unpack(parts))
end

function Baganator.Utilities.IsEquipment(itemLink)
  local classID = select(6, GetItemInfoInstant(itemLink))
  return classID == Enum.ItemClass.Armor or classID == Enum.ItemClass.Weapon or (C_AuctionHouse and classID == Enum.ItemClass.Profession)
end

local IsEquipment = Baganator.Utilities.IsEquipment

-- Assumes the item link has been refreshed since the last patch
function Baganator.Utilities.GetItemKey(itemLink)
  -- Battle pets
  if itemLink:match("battlepet:") then
    return "p:" .. KeyPartsPetLink(itemLink)
  -- Keystone
  elseif itemLink:match("keystone:") then
    return (select(2, SplitLink(itemLink)))
  -- Equipment
  elseif IsEquipment(itemLink) then
    return "g:" .. KeyPartsItemLink(itemLink)
  -- Everything else
  else
    return "i:" .. GetItemInfoInstant(itemLink)
  end
end

function Baganator.Utilities.Message(text)
  print(LINK_FONT_COLOR:WrapTextInColorCode("Baganator") .. ": " .. text)
end

local classicBorderFrames = {
  "BotLeftCorner", "BotRightCorner", "BottomBorder", "LeftBorder", "RightBorder",
  "TopRightCorner", "TopLeftCorner", "TopBorder"
}

function Baganator.Utilities.ApplyVisuals(frame)
  local alpha = Baganator.Config.Get(Baganator.Config.Options.VIEW_ALPHA)
  local noFrameBorders = Baganator.Config.Get(Baganator.Config.Options.NO_FRAME_BORDERS)

  frame.Bg:SetAlpha(alpha)
  frame.TopTileStreaks:SetAlpha(alpha)

  if frame.NineSlice then -- retail
    frame.NineSlice:SetAlpha(alpha)
    frame.NineSlice:SetShown(not noFrameBorders)
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 6, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 6, -21)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 6, -21)
    end
  elseif frame.TitleBg then -- classic
    frame.TitleBg:SetAlpha(alpha)
    for _, key in ipairs(classicBorderFrames) do
      frame[key]:SetAlpha(alpha)
      frame[key]:SetShown(not noFrameBorders)
    end
    if noFrameBorders then
      frame.Bg:SetPoint("TOPLEFT", 2, 0)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, 0)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 0)
    else
      frame.Bg:SetPoint("TOPLEFT", 2, -21)
      frame.Bg:SetPoint("BOTTOMRIGHT", -2, 2)
      frame.TopTileStreaks:SetPoint("TOPLEFT", 2, -21)
    end
  end
end

function Baganator.Utilities.ClearNewItemState(indexes)
  for _, bagID in ipairs(indexes) do
    for slotID = 1, C_Container.GetContainerNumSlots(bagID) do
      C_NewItems.RemoveNewItem(bagID, slotID)
    end
  end
end
