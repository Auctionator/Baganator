local function PopulateCategoryOrder(container)
  local hidden = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HIDDEN)

  local elements = {}
  local dataProviderElements = {}
  local customCategories = Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    local color = WHITE_FONT_COLOR
    if hidden[source] then
      color = GRAY_FONT_COLOR
    end

    local category = Baganator.CategoryViews.Constants.SourceToCategory[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = color:WrapTextInColorCode(category.name)})
      table.insert(elements, source)
    end
    category = customCategories[source]
    if category then
      table.insert(dataProviderElements, {value = source, label = color:WrapTextInColorCode(category.name .. " (*)")})
      table.insert(elements, source)
    end
    if source == Baganator.CategoryViews.Constants.DividerName then
      table.insert(dataProviderElements, {value = source, label = Baganator.CategoryViews.Constants.DividerLabel})
      table.insert(elements, source)
    end
  end

  container.elements = elements
  container.ScrollBox:SetDataProvider(CreateDataProvider(dataProviderElements), true)
end

local function GetCategoryContainer(parent, pickupCallback)
  local container = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
  Baganator.Skins.AddFrame("InsetFrame", container)
  container.ScrollBox = CreateFrame("Frame", nil, container, "WowScrollBoxList")
  container.ScrollBox:SetPoint("TOPLEFT", 1, -3)
  container.ScrollBox:SetPoint("BOTTOMRIGHT", -1, 3)
  local scrollView = CreateScrollBoxListLinearView()
  scrollView:SetElementExtent(22)
  scrollView:SetElementInitializer("Button", function(frame, elementData)
    if not frame.initialized then
      frame.initialized = true
      frame:SetNormalFontObject(GameFontHighlight)
      frame:SetHighlightAtlas("auctionhouse-ui-row-highlight")
      frame:SetScript("OnClick", function(self, button)
        if value ~= Baganator.CategoryViews.Constants.ProtectedCategory then
          Baganator.CallbackRegistry:TriggerEvent("EditCategory", self.value)
        end
      end)
      local button = CreateFrame("Button", nil, frame)
      button:SetSize(28, 22)
      local tex = button:CreateTexture(nil, "ARTWORK")
      tex:SetTexture("Interface\\PaperDollInfoFrame\\statsortarrows")
      tex:SetPoint("LEFT", 4, 0)
      tex:SetSize(14, 14)
      button:SetAlpha(0.8)
      button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT", -16, 0)
        GameTooltip:SetText(BAGANATOR_L_MOVE)
        GameTooltip:Show()
        button:SetAlpha(0.4)
      end)
      button:SetScript("OnLeave", function()
        GameTooltip:Hide()
        button:SetAlpha(0.8)
      end)
      button:SetScript("OnClick", function(self)
        pickupCallback(self:GetParent().value, self:GetParent():GetText(), self:GetParent().indexValue)
      end)
      button:SetPoint("LEFT", 4, 1)

      frame.repositionButton = button
    end
    frame.indexValue = container.ScrollBox:GetDataProvider():FindIndex(elementData)
    frame.value = elementData.value
    frame:SetText(elementData.label)
    frame:GetFontString():SetPoint("RIGHT", -8, 0)
    frame:GetFontString():SetPoint("LEFT")
    local default = Baganator.CategoryViews.Constants.SourceToCategory[frame.value]
    local divider = frame.value == Baganator.CategoryViews.Constants.DividerName
    frame:SetEnabled(not divider and (not default or not default.auto))
    local protected = elementData.value == Baganator.CategoryViews.Constants.ProtectedCategory
    frame.repositionButton:SetShown(not protected)
  end)
  container.ScrollBar = CreateFrame("EventFrame", nil, container, "WowTrimScrollBar")
  container.ScrollBar:SetPoint("TOPRIGHT")
  container.ScrollBar:SetPoint("BOTTOMRIGHT")
  ScrollUtil.InitScrollBoxListWithScrollBar(container.ScrollBox, container.ScrollBar, scrollView)
  Baganator.Skins.AddFrame("TrimScrollBar", container.ScrollBar)

  container:SetSize(250, 500)

  PopulateCategoryOrder(container)

  return container
end

local function GetInsertedCategories()
  local result = {}
  for _, source in ipairs(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER)) do
    result[source] = true
  end
  return result
end

local function SetCategoriesToDropDown(dropDown, ignore)
  local options = {}
  for source, category in pairs(Baganator.CategoryViews.Constants.SourceToCategory) do
    if not ignore[source] then
      table.insert(options, {label = category.name, value = source})
    end
  end
  for source, category in pairs(Baganator.Config.Get(Baganator.Config.Options.CUSTOM_CATEGORIES)) do
    if not ignore[source] then
      table.insert(options, {label = category.name .. " (*)", value = category.name})
    end
  end
  table.sort(options, function(a, b) return a.label:lower() < b.label:lower() end)

  local entries, values = {
    BAGANATOR_L_CREATE_NEW,
    BAGANATOR_L_CATEGORY_DIVIDER,
  }, {
    "",
    Baganator.CategoryViews.Constants.DividerName
  }

  for _, opt in ipairs(options) do
    table.insert(entries, opt.label)
    table.insert(values, opt.value)
  end

  dropDown:SetupOptions(entries, values)
end

function Baganator.CustomiseDialog.GetCategoriesOrganiser(parent)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(300, 570)
  container:SetPoint("CENTER")

  local previousOrder = CopyTable(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER))

  container:SetScript("OnShow", function()
    previousOrder = CopyTable(Baganator.Config.Get(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER))
  end)

  local categoryOrder
  local highlightContainer = CreateFrame("Frame", nil, container)
  local highlight = highlightContainer:CreateTexture(nil, "OVERLAY", nil, 7)
  highlight:SetSize(200, 20)
  highlight:SetAtlas("128-RedButton-Highlight")
  highlight:Hide()
  local draggable
  draggable = Baganator.CustomiseDialog.GetDraggable(function()
    if categoryOrder:IsMouseOver() then
      local f, isTop, index = Baganator.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      if not f then
        table.insert(categoryOrder.elements, draggable.value)
      else
        if isTop then
          table.insert(categoryOrder.elements, index, draggable.value)
        else
          table.insert(categoryOrder.elements, index + 1, draggable.value)
        end
      end
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end
    highlight:Hide()
  end, function()
    highlight:ClearAllPoints()
    highlight:Hide()
    if categoryOrder:IsMouseOver() then
      highlight:Show()
      local f, isTop = Baganator.CustomiseDialog.GetMouseOverInContainer(categoryOrder)
      if f and isTop then
        highlight:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, -10)
      elseif f then
        highlight:SetPoint("TOPLEFT", f, "BOTTOMLEFT", 0, 10)
      else
        highlight:SetPoint("BOTTOMLEFT", categoryOrder, 0, 0)
      end
    end
  end)

  local dropDown = Baganator.CustomiseDialog.GetDropdown(container)
  SetCategoriesToDropDown(dropDown, GetInsertedCategories())

  local function Pickup(value, label, index)
    if index ~= nil then
      table.remove(categoryOrder.elements, index)
      Baganator.Config.Set(Baganator.Config.Options.CATEGORY_DISPLAY_ORDER, categoryOrder.elements)
    end

    dropDown:SetText(label)
    draggable:Show()
    draggable.text:SetText(label)
    draggable.value = value
  end

  categoryOrder = GetCategoryContainer(container, Pickup)
  categoryOrder:SetPoint("TOPLEFT", 0, -40)

  dropDown:SetText(BAGANATOR_L_INSERT_OR_CREATE)

  hooksecurefunc(dropDown, "OnEntryClicked", function(_, option)
    if option.value ~= "" then
      Pickup(option.value, option.label, option.value ~= Baganator.CategoryViews.Constants.DividerName and tIndexOf(categoryOrder.elements, option.value) or nil)
    else
      Baganator.CallbackRegistry:TriggerEvent("EditCategory", option.value)
    end
  end)
  draggable:SetScript("OnHide", function()
    dropDown:SetText(BAGANATOR_L_INSERT_OR_CREATE)
  end)
  dropDown:SetPoint("TOPLEFT", 0, 0)
  dropDown:SetPoint("RIGHT", categoryOrder)

  Baganator.CallbackRegistry:RegisterCallback("SettingChanged", function(_, settingName)
    if settingName == Baganator.Config.Options.CATEGORY_DISPLAY_ORDER or settingName == Baganator.Config.Options.CATEGORY_HIDDEN then
      SetCategoriesToDropDown(dropDown, GetInsertedCategories())
      PopulateCategoryOrder(categoryOrder)
    elseif settingName == Baganator.Config.Options.CUSTOM_CATEGORIES then
      SetCategoriesToDropDown(dropDown, GetInsertedCategories())
    end
  end)

  local exportDialog = "Baganator_Export_Dialog"
  StaticPopupDialogs[exportDialog] = {
    text = BAGANATOR_L_CTRL_C_TO_COPY,
    button1 = DONE,
    hasEditBox = 1,
    OnShow = function(self, data)
      self.editBox:SetText(data)
      self.editBox:HighlightText()
    end,
    EditBoxOnEnterPressed = function(self)
      self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    editBoxWidth = 230,
    timeout = 0,
    hideOnEscape = 1,
  }

  local importDialog = "Baganator_Import_Dialog"
  StaticPopupDialogs[importDialog] = {
    text = BAGANATOR_L_PASTE_YOUR_IMPORT_STRING_HERE,
    button1 = BAGANATOR_L_IMPORT,
    button2 = CANCEL,
    hasEditBox = 1,
    OnShow = function(self, data)
      self.editBox:SetText("")
    end,
    OnAccept = function(self)
      Baganator.CustomiseDialog.CategoriesImport(self.editBox:GetText())
    end,
    EditBoxOnEnterPressed = function(self)
      Baganator.CustomiseDialog.CategoriesImport(self:GetText())
      self:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
    editBoxWidth = 230,
    timeout = 0,
    hideOnEscape = 1,
  }

  local exportButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  exportButton:SetPoint("RIGHT", categoryOrder, 0, 0)
  exportButton:SetPoint("BOTTOM", container)
  exportButton:SetText(BAGANATOR_L_EXPORT)
  DynamicResizeButton_Resize(exportButton)
  exportButton:SetScript("OnClick", function()
    StaticPopup_Show(exportDialog, nil, nil, Baganator.CustomiseDialog.CategoriesExport())
  end)
  Baganator.Skins.AddFrame("Button", exportButton)

  local importButton = CreateFrame("Button", nil, container, "UIPanelDynamicResizeButtonTemplate")
  importButton:SetPoint("LEFT", categoryOrder, 0, 0)
  importButton:SetPoint("BOTTOM", container)
  importButton:SetText(BAGANATOR_L_IMPORT)
  DynamicResizeButton_Resize(importButton)
  importButton:SetScript("OnClick", function()
    StaticPopup_Show(importDialog)
  end)
  Baganator.Skins.AddFrame("Button", importButton)

  return container
end
