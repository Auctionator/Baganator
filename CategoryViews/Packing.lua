function Baganator.CategoryViews.PackSimple(activeLayouts, labelsPool, searchLabels, baseOffsetX, baseOffsetY, bagWidth)
  local iconPadding, iconSize = Baganator.ItemButtonUtil.GetPaddingAndSize()

  local headerPadding = 6
  if Baganator.Config.Get(Baganator.Config.Options.REDUCE_SPACING) then
    headerPadding = 0
  end

  local categorySpacing = Baganator.Config.Get(Baganator.Config.Options.CATEGORY_HORIZONTAL_SPACING) * (iconSize + iconPadding)

  local targetPixelWidth = bagWidth * (iconSize + iconPadding) - iconPadding

  local maxWidth = 0

  local offsetX, offsetY = 0, 0
  local prevLayout, prevLabel = nil, nil
  for index, layout in ipairs(activeLayouts) do
    layout:SetShown(index <= #searchLabels)
    if layout:IsShown() and layout:GetHeight() > 0 then
      if math.floor(offsetX + layout:GetWidth()) > targetPixelWidth then
        prevLabel:SetWidth(targetPixelWidth - offsetX + prevLayout:GetWidth() + categorySpacing)
        offsetX = 0
        offsetY = offsetY - prevLayout:GetHeight() - prevLabel:GetHeight() - headerPadding / 2
      end
      local label = labelsPool:Acquire()
      label:SetText(searchLabels[index])
      label:Show()
      label:SetJustifyH("LEFT")
      label:SetPoint("TOPLEFT", offsetX + baseOffsetX, offsetY + baseOffsetY)
      label:SetWidth(math.min(layout:GetWidth() + categorySpacing, targetPixelWidth - offsetX))
      label:SetWordWrap(false)
      layout:SetPoint("TOPLEFT", offsetX + baseOffsetX, offsetY + baseOffsetY - label:GetHeight() - headerPadding / 2)
      offsetX = offsetX + layout:GetWidth() + iconPadding
      maxWidth = math.max(maxWidth, offsetX + iconPadding)
      offsetX = offsetX + categorySpacing
      prevLayout = layout
      prevLabel = label
    end
  end
  prevLabel:SetWidth(targetPixelWidth - offsetX + categorySpacing + prevLayout:GetWidth())

  return maxWidth, - offsetY + prevLayout:GetHeight() + prevLabel:GetHeight() + headerPadding / 2
end