

function CreateAwardButton(frame)
	local button = CreateFrame("Button", nil, frame)
	button:SetWidth(60)
  button:SetHeight(20)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)

	-- Set button text
  button:SetText("Award")
  local font = button:GetFontString()
  font:SetFont(FONT_NAME, FONT_SIZE, FONT_OUTLINE)

  -- Add background 
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(button)
  bg:SetTexture(1, 1, 1, 1) -- White texture
  bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray background
  
  button:SetScript("OnMouseDown", function(self)
      bg:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
  end)

  button:SetScript("OnMouseUp", function(self)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
  end)

  -- Add tooltip
  button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText("Award Item to Current Selection", nil, nil, nil, nil, true)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
      GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function(self)
      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
      GameTooltip:Hide()
  end)
	
	return button
end

function CreateRecipient(award)

end

function CreateLootMasterFrame()
  local frame = CreateFrame("Frame", "LootMasterFrame", UIParent)
  
  frame:SetWidth(400)
  frame:SetHeight(400)
  frame:SetPoint("CENTER",UIParent,"CENTER",0,0) -- Position at center of the parent frame
  frame:SetBackdrop({
  	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 1) -- Black background with full opacity

  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton") -- Only start dragging with the left mouse button
  frame:SetScript("OnDragStart", function () frame:StartMoving() end)
  frame:SetScript("OnDragStop", function () frame:StopMovingOrSizing() end)
  CreateCloseButton(frame)

	--Add functionality to the button
  ItemRollFrame.LM:SetScript("OnClick", function()
    if frame:IsVisible() then
      frame:Hide()
    else
      frame:Show()
    end
  end)
	frame.Award = CreateAwardButton(frame)
	frame.Recipient = CreateRecipient(frame.award)
	frame:Hide()
  return frame
end