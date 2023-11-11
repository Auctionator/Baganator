BaganatorCurrencyCacheMixin = {}

-- Assumed to run after PLAYER_LOGIN
function BaganatorCurrencyCacheMixin:OnLoad()
  if Baganator.Constants.IsEra then
    return
  end

  FrameUtil.RegisterFrameForEvents(self, {
    "CURRENCY_DISPLAY_UPDATE",
  })

  local characterName, realm = UnitFullName("player")
  self.currentCharacter = characterName .. "-" .. realm

  self.waiting = {}

  self:ScanAllCurrencies()
end

function BaganatorCurrencyCacheMixin:OnEvent(eventName, ...)
  if eventName == "CURRENCY_DISPLAY_UPDATE" then
    local currencyID, quantity = ...
    if currencyID ~= nil then
      BAGANATOR_DATA.Characters[self.currentCharacter].currencies[currencyID] = quantity

      self:SetScript("OnUpdate", self.OnUpdate)
    else
      self:ScanAllCurrencies()
    end
  end
end

function BaganatorCurrencyCacheMixin:ScanAllCurrencies()
  local currencies = {}

  if Baganator.Constants.IsRetail then
    local index = 0
    local toCollapse = {}
    while index < C_CurrencyInfo.GetCurrencyListSize() do
      index = index + 1
      local info = C_CurrencyInfo.GetCurrencyListInfo(index)
      if info.isHeader then
        if not info.isHeaderExpanded then
          table.insert(toCollapse, index)
          C_CurrencyInfo.ExpandCurrencyList(index, true)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = C_CurrencyInfo.GetCurrencyIDFromLink(link)
          currencies[currencyID] = info.quantity
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1 do
        C_CurrencyInfo.ExpandCurrencyList(toCollapse[index], false)
      end
    end
  else -- Only versions of classic with currency (due to checks earlier)
    local index = 0
    local toCollapse = {}
    while index < GetCurrencyListSize() do
      index = index + 1
      local _, isHeader, isHeaderExpanded, _, _, quantity = GetCurrencyListInfo(index)
      if isHeader then
        if not isHeaderExpanded then
          table.insert(toCollapse, index)
          ExpandCurrencyList(index, 1)
        end
      else
        local link = C_CurrencyInfo.GetCurrencyListLink(index)
        if link ~= nil then
          local currencyID = tonumber((link:match("|Hcurrency:(%d+)")))
          if currencyID ~= nil then
            currencies[currencyID] = quantity
          end
        end
      end
    end

    if #toCollapse > 0 then
      for index = #toCollapse, 1 do
        print(toCollapse[index], index)
        ExpandCurrencyList(toCollapse[index], 0)
      end
    end
  end

  BAGANATOR_DATA.Characters[self.currentCharacter].currencies = currencies

  self:SetScript("OnUpdate", self.OnUpdate)
end

-- Event is fired in OnUpdate to avoid multiple events per-frame
function BaganatorCurrencyCacheMixin:OnUpdate()
  self:SetScript("OnUpdate", nil)

  Baganator.CallbackRegistry:TriggerEvent("CurrencyCacheUpdate", self.currentCharacter)
end
