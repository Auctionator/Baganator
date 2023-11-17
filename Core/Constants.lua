-- Retail bag indexes. Will need changing for classic.
Baganator.Constants = {
  AllBagIndexes = {
    Enum.BagIndex.Backpack,
    Enum.BagIndex.Bag_1,
    Enum.BagIndex.Bag_2,
    Enum.BagIndex.Bag_3,
    Enum.BagIndex.Bag_4,
  },
  AllBankIndexes = {
    Enum.BagIndex.Bank,
    Enum.BagIndex.BankBag_1,
    Enum.BagIndex.BankBag_2,
    Enum.BagIndex.BankBag_3,
    Enum.BagIndex.BankBag_4,
    Enum.BagIndex.BankBag_5,
    Enum.BagIndex.BankBag_6,
    Enum.BagIndex.BankBag_7,
  },
  IsRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE,
  IsWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC,
  IsEra = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC,
  IsClassic = WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE,

  MaxRecents = 4,
  BattlePetCageID = 82800,

  BankBagSlotsCount = 7,

  MaxGuildBankTabItemSlots = 98,
}

if Baganator.Constants.IsWrath then
  table.insert(Baganator.Constants.AllBagIndexes, Enum.BagIndex.Keyring)
end
if Baganator.Constants.IsRetail then
  table.insert(Baganator.Constants.AllBagIndexes, Enum.BagIndex.ReagentBag)
  table.insert(Baganator.Constants.AllBankIndexes, Enum.BagIndex.Reagentbank)
  Baganator.Constants.BagSlotsCount = 5
  Baganator.Constants.MaxBagSize = 42
end
if Baganator.Constants.IsClassic then
  -- Workaround for the enum containing the wrong values for the bank bag slots
  for i = 1, Baganator.Constants.BankBagSlotsCount do
    Baganator.Constants.AllBankIndexes[i + 1] = NUM_BAG_SLOTS + i
  end
  Baganator.Constants.BagSlotsCount = 4
  Baganator.Constants.MaxBagSize = 36
end

Baganator.Constants.Events = {
  "SettingChangedEarly",
  "SettingChanged",

  "CharacterDeleted",

  "BagCacheUpdate",
  "MailCacheUpdate",
  "CurrencyCacheUpdate",
  "GuildCacheUpdate",

  "SearchTextChanged",
  "BagShow",
  "BagHide",
  "CharacterSelect",

  "ShowCustomise",
  "ResetFramePositions",

  "ReagentOnEnter",
  "ReagentOnLeave",
}

-- Hidden currencies for all characters tooltips as they are shared between characters
Baganator.Constants.SharedCurrencies = {
  2032, -- Trader's Tender
}
