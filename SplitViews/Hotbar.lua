local _, addonTable = ...

BaganatorSplitViewHotbarMixin = {}

function BaganatorSplitViewHotbarMixin:OnLoad()
  self:RegisterForDrag("LeftButton")
  self:SetMovable(true)
  self:SetClampedToScreen(true)
  self:SetUserPlaced(false)

  addonTable.Utilities.AddBagSortManager(self) -- self.sortManager
  addonTable.Utilities.AddBagTransferManager(self) -- self.transferManager

  Syndicator.CallbackRegistry:RegisterCallback("GuildNameSet",  function(_, guild)
    if self.lastCharacter ~= nil and Syndicator.API.GetCharacter(self.lastCharacter) then
      self:UpdateGuildButton()
    end
  end)

  self.confirmTransferAllDialogName = "addonTable.ConfirmTransferAll_" .. self:GetName()
  StaticPopupDialogs[self.confirmTransferAllDialogName] = {
    text = BAGANATOR_L_CONFIRM_TRANSFER_ALL_ITEMS_FROM_BAG,
    button1 = YES,
    button2 = NO,
    OnAccept = function()
      self:Transfer(true, self.data)
    end,
    timeout = 0,
    hideOnEscape = 1,
  }

  addonTable.AddBagTransferActivationCallback(function()
    if self:IsVisible() then
      self:UpdateTransferButton()
    end
  end)

  if addonTable.Constants.IsEra then
    local index = tIndexOf(self.AllButtons, self.ToggleGuildBankButton)
    table.remove(self.AllButtons, index)
    self.ToggleGuildBankButton:Hide()
  end

  addonTable.Skins.AddFrame("ButtonFrame", self)
end

function BaganatorSplitViewHotbarMixin:OnShow()
  if addonTable.Config.Get(addonTable.Config.Options.AUTO_SORT_ON_OPEN) then
    C_Timer.After(0, function()
      self:CombineStacksAndSort()
    end)
  end
  PlaySound(SOUNDKIT.IG_BACKPACK_OPEN);
end

function BaganatorSplitViewHotbarMixin:CombineStacks(callback)
  addonTable.Sorting.CombineStacks(Syndicator.API.GetCharacter(self:GetParent().liveCharacter).bags, Syndicator.Constants.AllBagIndexes, function(status)
    self.sortManager:Apply(status, function()
      self:CombineStacks(callback)
    end, function()
      callback()
    end)
  end)
end

function BaganatorSplitViewHotbarMixin:UpdateTransferButton()
  if not self:GetParent().isLive then
    self.TransferButton:Hide()
    return
  end

  for _, info in ipairs(addonTable.BagTransfers) do
    if info.condition() then
      self.TransferButton:Show()
      self.TransferButton.tooltipText = info.tooltipText
      return
    end
  end
  self.TransferButton:Hide()
end

function BaganatorSplitViewHotbarMixin:IsTransferActive()
  return self.TransferButton:IsShown()
end

function BaganatorSplitViewHotbarMixin:UpdateAll()
  self.SortButton:SetShown(addonTable.Utilities.ShouldShowSortButton() and self:GetParent().isLive)
  self:UpdateTransferButton()

  local prev = nil
  local count = 0
  for _, button in ipairs(self.AllButtons) do
    if button:IsShown() then
      count = count + 1
      button:ClearAllPoints()
      if not prev then
        button:SetPoint("TOP", self, 0, -5)
      else
        button:SetPoint("TOP", prev, "BOTTOM")
      end
      prev = button
    end
  end

  self:SetSize(prev:GetWidth() + 10, prev:GetHeight() * count + 10)

  --[[if self.CurrencyWidget.lastCharacter ~= self:GetParent().lastCharacter then
    self.CurrencyWidget:UpdateCurrencies(self:GetParent().lastCharacter)
  end

  self.CurrencyWidget:UpdateCurrencyTextPositions(self:GetWidth() - 20 - self.CurrencyButton:GetWidth())]]
end

function BaganatorSplitViewHotbarMixin:OnFinished()
  local sideSpacing, topSpacing = addonTable.Utilities.GetSpacing()

  --self.SearchWidget:SetSpacing(sideSpacing)

  self:UpdateGuildButton()
end

function BaganatorSplitViewHotbarMixin:UpdateGuildButton()
  local guildName = Syndicator.API.GetCharacter(self:GetParent().lastCharacter).details.guild
  self.ToggleGuildBankButton:SetEnabled(guildName ~= nil and Syndicator.API.GetGuild(guildName))
  self.ToggleGuildBankButton.Icon:SetDesaturated(not self.ToggleGuildBankButton:IsEnabled())
end

function BaganatorSplitViewHotbarMixin:RunAction(action, getItems)
  action((getItems and getItems()) or self:GetParent():GetSearchMatches(), self:GetParent().liveCharacter, function(status, modes)
    self.transferManager:Apply(status, modes or {"BagCacheUpdate"}, function()
      self:RunAction(action, getItems)
    end, function() end)
  end)
end

function BaganatorSplitViewHotbarMixin:Transfer(force, getItems)
  for _, transferDetails in ipairs(addonTable.BagTransfers) do
    if transferDetails.condition() then
      if not force and transferDetails.confirmOnAll and self.SearchWidget.SearchBox:GetText() == "" then
        StaticPopup_Show(self.confirmTransferAllDialogName, nil, nil, getItems)
        break
      else
        self:RunAction(transferDetails.action, getItems)
        break
      end
    end
  end
end

function BaganatorSplitViewHotbarMixin:DoSort(isReverse)
  local bagsToSort = {}
  for index, bagID in ipairs(Syndicator.Constants.AllBagIndexes) do
    bagsToSort[index] = true
  end
  local bagChecks = addonTable.Sorting.GetBagUsageChecks(Syndicator.Constants.AllBagIndexes)
  local function DoSortInternal()
    local status = addonTable.Sorting.ApplyBagOrdering(
      Syndicator.API.GetCharacter(self:GetParent().liveCharacter).bags,
      Syndicator.Constants.AllBagIndexes,
      bagsToSort,
      bagChecks,
      isReverse,
      addonTable.Config.Get(addonTable.Config.Options.SORT_IGNORE_SLOTS_AT_END),
      addonTable.Config.Get(addonTable.Config.Options.SORT_IGNORE_BAG_SLOTS_COUNT)
    )
    self.sortManager:Apply(status, DoSortInternal, function() end)
  end
  DoSortInternal()
end

function BaganatorSplitViewHotbarMixin:CombineStacksAndSort(isReverse)
  local sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)

  if not addonTable.Sorting.IsModeAvailable(sortMethod) then
    addonTable.Config.ResetOne(addonTable.Config.Options.SORT_METHOD)
    sortMethod = addonTable.Config.Get(addonTable.Config.Options.SORT_METHOD)
  end

  if addonTable.API.ExternalContainerSorts[sortMethod] then
    addonTable.API.ExternalContainerSorts[sortMethod].callback(isReverse, Baganator.API.Constants.ContainerType.Backpack)
  elseif sortMethod == "combine_stacks_only" then
    self:CombineStacks(function() end)
  else
    self:CombineStacks(function()
      self:DoSort(isReverse)
    end)
  end
end

function BaganatorSplitViewHotbarMixin:GetExternalSortMethodName()
  return addonTable.Utilities.GetExternalSortMethodName()
end

function BaganatorSplitViewHotbarMixin:ToggleBank()
  addonTable.CallbackRegistry:TriggerEvent("BankToggle", self:GetParent().lastCharacter)
  self:Raise()
end

function BaganatorSplitViewHotbarMixin:ToggleGuildBank()
  addonTable.CallbackRegistry:TriggerEvent("GuildToggle", Syndicator.API.GetCharacter(self:GetParent().lastCharacter).details.guild)
end
