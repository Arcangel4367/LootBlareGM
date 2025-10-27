
local weird_vibes_mode = true
local MSSRRollMessages = {}
local MSRollMessages = {}
local OSSRRollMessages = {}
local OSRollMessages = {}
local tmogRollMessages = {}
local EPGPMSRollMessages = {}
local EPGPOSRollMessages = {}
local rollers = {}
local isRolling = false
local time_elapsed = 0
local item_query = 0.5
local times = 5
local discover = CreateFrame("GameTooltip", "CustomTooltip1", UIParent, "GameTooltipTemplate")
local masterLooter = nil
local MSSRRollCap = 101
local MSRollCap = 100
local OSSRRollCap = 99
local OSRollCap = 98
local tmogRollCap = 50


--EPGP Settings--
PriceDB = nil
local CurrentSelection
local FixSelected
local RaidEPGP = 0
local MinGP = 100
local TestZone = 0
local Naxx = 0
local K40 = 1
local MSPrice = 0
local OSPrice = 0
local Ratio = 0
local AwardSent = 0

local BUTTON_WIDTH = 32
local BUTTON_COUNT = 5
local BUTTON_PADING = 10
FONT_NAME = "Fonts\\FRIZQT__.TTF"
FONT_SIZE = 10
FONT_OUTLINE = "OUTLINE"
local RAID_CLASS_COLORS = {
  ["Warrior"] = "FFC79C6E",
  ["Mage"]    = "FF69CCF0",
  ["Rogue"]   = "FFFFF569",
  ["Druid"]   = "FFFF7D0A",
  ["Hunter"]  = "FFABD473",
  ["Shaman"]  = "FF0070DE",
  ["Priest"]  = "FFFFFFFF",
  ["Warlock"] = "FF9482C9",
  ["Paladin"] = "FFF58CBA",
}

local ADDON_TEXT_COLOR = "FFEDD8BB"
local DEFAULT_TEXT_COLOR = "FFFFFF00"
local MSSR_Text_Color = "FFFF00FF"
local MS_Text_Color = "FFFFFF00"
local OSSR_TEXT_COLOR = "FF776CDA"
local OS_TEXT_COLOR = "FFEC9512"
local TM_TEXT_COLOR = "FF00FFFF"

local CORE_TEXT_COLOR = "FFFF00FF"
local RAIDER_TEXT_COLOR = "FFFFFF00"
local CASUAL_TEXT_COLOR = "FFEC9512"
local MEMPUG_TEXT_COLOR = "FFFFFFFF"

local LB_PREFIX = "LootBlare "
local LB_GET_DATA = "get data"
local LB_SET_ML = "ML set to "
local LB_SET_ROLL_TIME = "Roll time set to "
local LB_BID = "Bid on item: "
local LB_AWARD = "Awarded to: "
local LB_EPGPSET = "EPGP Set: "

local function lb_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|c" .. ADDON_TEXT_COLOR .. "LootBlare: " .. msg .. "|r")
end

NUM_DISPLAY_ROWS = 12
ScrollShow = nil

local function resetRolls()
  MSSRRollMessages = {}
  MSRollMessages = {}
  OSSRRollMessages = {}
  OSRollMessages = {}
  tmogRollMessages = {}
  rollers = {}
  EPGPMSRollMessages = {}
  EPGPOSRollMessages = {}
end



local function sortRolls()
  table.sort(EPGPMSRollMessages, function(a, b)
    return a.ratio > b.ratio
  end)
  table.sort(EPGPOSRollMessages, function(a, b)
    return a.ratio > b.ratio
  end)
  table.sort(MSSRRollMessages, function(a, b)
    return a.roll > b.roll
  end)
  table.sort(MSRollMessages, function(a, b)
    return a.roll > b.roll
  end)
  table.sort(OSSRRollMessages, function(a, b)
    return a.roll > b.roll
  end)
  table.sort(OSRollMessages, function(a, b)
    return a.roll > b.roll
  end)
  table.sort(tmogRollMessages, function(a, b)
    return a.roll > b.roll
  end)
end

local function colorMsg(message)
  local msg = message.msg
  local class = message.class
  _,_,_, message_end = string.find(msg, "(%S+)%s+(.+)")
  local classColor = RAID_CLASS_COLORS[class]
  local textColor = DEFAULT_TEXT_COLOR
  local rankColor = DEFAULT_TEXT_COLOR

  if string.find(msg, "-"..MSSRRollCap) then
    textColor = MSSR_Text_Color
  elseif string.find(msg, "-"..MSRollCap) then
    textColor = MS_Text_Color
  elseif string.find(msg, "-"..OSSRRollCap) then
    textColor = OSSR_TEXT_COLOR
  elseif string.find(msg, "-"..OSRollCap) then
    textColor = OS_TEXT_COLOR
  elseif string.find(msg, "-"..tmogRollCap) then
    textColor = TM_TEXT_COLOR
  end
  if message.rankI <= 4 then
    rankColor = CORE_TEXT_COLOR
  elseif  message.rankI == 5 then
    rankColor = RAIDER_TEXT_COLOR
  elseif  message.rankI == 6 then
    rankColor = CASUAL_TEXT_COLOR
  elseif  message.rankI >= 7 then
    rankColor = MEMPUG_TEXT_COLOR
  end

  local colored_msg = "|c".. rankColor .. ""  .. message.rank .. " |c" .. classColor .. "" .. message.roller .. "|r |c" .. textColor .. message_end .. "|r"
  return colored_msg
end

local function colorEPGPMsg(message)
  local class = message.class
  local classColor = RAID_CLASS_COLORS[class]
  local textColor = DEFAULT_TEXT_COLOR
  local rankColor = DEFAULT_TEXT_COLOR

  if message.type == "MS" then
    textColor = MS_Text_Color
  elseif message.type == "OS" then
    textColor = OS_TEXT_COLOR
  end
  if message.rankI <= 4 then
    rankColor = CORE_TEXT_COLOR
  elseif  message.rankI == 5 then
    rankColor = RAIDER_TEXT_COLOR
  elseif  message.rankI == 6 then
    rankColor = CASUAL_TEXT_COLOR
  elseif  message.rankI >= 7 then
    rankColor = MEMPUG_TEXT_COLOR
  end
  local colored_msg = "|c".. rankColor .. message.rank .. " |c" .. classColor .. message.roller .. "|r |c" .. textColor .. message.type .. "|r |cFF0070DE".. message.ratio .. "|r"
  return colored_msg
end

local function tsize(t)
  c = 0
  for _ in pairs(t) do
    c = c + 1
  end
  if c > 0 then return c else return nil end
end

local function GetRankOfRollerI(rollerName)
  -- Iterate through the raid roster
  for i = 1, GetNumGuildMembers() do
      local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote,  isOnline, status = GetGuildRosterInfo(i)
      if name == rollerName then
          return rankIndex-- Return the rank as a string (e.g., Core, Raider, Member)
      end
    end
    return 13 -- Return nil if the player is not found in the raid
end

local function GetRankOfRoller(rollerName)
  -- Iterate through the raid roster
  for i = 1, GetNumGuildMembers() do
      local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote,  isOnline, status = GetGuildRosterInfo(i)
      if name == rollerName then
          return rankName -- Return the rank as a string (e.g., Core, Raider, Member)
      end
    end
    return "Non-Guildie" -- Return nil if the player is not found in the raid
end

local function CheckItem(link)
  discover:SetOwner(UIParent, "ANCHOR_PRESERVE")
  discover:SetHyperlink(link)

  if discoverTextLeft1 and discoverTooltipTextLeft1:IsVisible() then
    local name = discoverTooltipTextLeft1:GetText()
    discoverTooltip:Hide()

    if name == (RETRIEVING_ITEM_INFO or "") then
      return false
    else
      return true
    end
  end
  return false
end

function OverrideType_InitializeDropDown()

  local MS = UIDropDownMenu_CreateInfo()
  

  MS = {
    text = "MS",
    value = 0,
    type = "MS",
    func = function(self)
      AwardType:SetText(MS.type)
      CurrentSelection.type = MS.type
      CurrentSelection.price = MSPrice
      
    end
  }
  UIDropDownMenu_AddButton(MS)
  local OS = UIDropDownMenu_CreateInfo()
  OS = {
    text = "OS",
    value = 1,
    type = "OS",
    func = function(self)
      AwardType:SetText(OS.type)
      CurrentSelection.type = OS.type
      CurrentSelection.price = OSPrice
      
    end
  }
  
  UIDropDownMenu_AddButton(OS)
end

function FixSelect_InitializeDropdown()
  local numMembers = GetNumRaidMembers()
  for k = 1, numMembers do
    local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(k)


      
      local i = 1
      while ImportEPGP[i][1]~= name and i < getn(ImportEPGP) do
        i = i + 1
      end
      local data = ImportEPGP[i]
      local info = UIDropDownMenu_CreateInfo()
      if name == data[1] then
        info = {
          text = name,
          value = i;
          player = name,
          ep = data[2],
          gp = data[3],
          func = function(self)
            SelectedRaider:SetText(info.player)
            FixEPBox:SetText(info.ep)
            FixGPBox:SetText(info.gp)
            FixSelected = {
              player = info.player,
              ep = info.ep,
              gp = info.gp,
              activegp = 100, 
            }
            if info.gp < 100 then
              FixSelected.activegp = 100
            else
              FixSelected.activegp = info.gp
            end
            FixRatio:SetText(string.format("%.2f", (FixSelected.ep / FixSelected.activegp)))
          end
        }
      else
        info = {
          text = name,
          value = i;
          player = name,
          ep = 100,
          gp = 0,
          func = function(self)
            SelectedRaider:SetText(info.player)
            FixEPBox:SetText(info.ep)
            FixGPBox:SetText(info.gp)
            FixSelected = {
              player = info.player,
              ep = info.ep,
              gp = info.gp,
              activegp = 100,
            }
            FixRatio:SetText(string.format("%.2f", (FixSelected.ep / FixSelected.activegp)))
          end
        }
      end
      UIDropDownMenu_AddButton(info)
    
  end
end

function UpdateFixes()
  FixEPBox:ClearFocus()
  FixGPBox:ClearFocus()
  FixSelected.ep = tonumber(FixEPBox:GetText())
  FixSelected.gp = tonumber(FixGPBox:GetText())
  FixRatio:SetText(string.format("%.2f", (FixSelected.ep / FixSelected.activegp)))
end

function SendEPGPValues()
  UpdateFixes()
  if FixSelected ~= nil then
    lb_print("Sending EPGP values for " ..FixSelected.player.. ": EP: " ..FixSelected.ep.. ", GP: " ..FixSelected.gp.. ", Ratio: " ..string.format("%.2f", (FixSelected.ep / FixSelected.activegp)))
    SendAddonMessage(LB_PREFIX,LB_EPGPSET.. " -" ..FixSelected.player.. "- +" ..FixSelected.ep.."+ *"..FixSelected.gp.."* ", "RAID")
  end
end

function Override_InitializeDropdown()

  for i, v in ipairs(EPGPMSRollMessages) do
    local info = UIDropDownMenu_CreateInfo()
    info = {
      text = EPGPMSRollMessages[i].roller,
      value = i;
      player = EPGPMSRollMessages[i].roller,
      type = EPGPMSRollMessages[i].type,
      func = function(self)
        Awardee:SetText(info.player)
        AwardType:SetText(info.type)
        CurrentSelection = {
          player = info.player,
          type = info.type,
          price = MSPrice
        }
      end
    }
    UIDropDownMenu_AddButton(info)
  end
  for i, v in ipairs(EPGPOSRollMessages) do
    local info = UIDropDownMenu_CreateInfo()
    info = {
      text = EPGPOSRollMessages[i].roller,
      value = i;
      player = EPGPOSRollMessages[i].roller,
      type = EPGPOSRollMessages[i].type,
      func = function(self)
        Awardee:SetText(info.player)
        AwardType:SetText(info.type)
        CurrentSelection = {
          player = info.player,
          type = info.type,
          price = OSPrice
        }
      end
    }
    UIDropDownMenu_AddButton(info)
  end
end

function OverrideFrameDropDownType_OnShow()
  UIDropDownMenu_Initialize(OverideFrameDropDownType, Override_InitializeDropdown)
  UIDropDownMenu_Initialize(OverideTypeFrameDropDownType, OverrideType_InitializeDropDown)
end

function FixEPGPDropdown_OnShow()
  UIDropDownMenu_Initialize(FixSelectDropdown, FixSelect_InitializeDropdown)
  UIDropDownMenu_SetWidth(80, FixSelectDropdown)
end

function CreateCloseButton(frame)
  -- Add a close button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetWidth(32) -- Button size
  closeButton:SetHeight(32) -- Button size
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5) -- Position at the top right

  -- Set textures if you want to customize the appearance
  closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
  closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
  closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")

  -- Hide the frame when the button is clicked
  closeButton:SetScript("OnClick", function()
      frame:Hide()
      resetRolls()
  end)
end

local function CreateActionButton(frame, buttonText, tooltipText, index, onClickAction)
  local panelWidth = frame:GetWidth()
  local spacing = (panelWidth - (BUTTON_COUNT * BUTTON_WIDTH)) / (BUTTON_COUNT + 1)
  local button = CreateFrame("Button", nil, frame, UIParent)
  button:SetWidth(BUTTON_WIDTH)
  button:SetHeight(BUTTON_WIDTH)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", index*spacing + (index-1)*BUTTON_WIDTH, BUTTON_PADING)

  -- Set button text
  button:SetText(buttonText)
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
      GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
      GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function(self)
      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
      GameTooltip:Hide()
  end)

  -- Add functionality to the button
  button:SetScript("OnClick", function()
    onClickAction()
  end)

  return button
end

local function CreateLMButton(frame)
  local button = CreateFrame("Button", nil, frame, UIParent)
  button:SetWidth(20)
  button:SetHeight(20)
  button:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -55)

    -- Set button text
  button:SetText("LM")
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
      GameTooltip:SetText("Open Loot Master Panel", nil, nil, nil, nil, true)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
      GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function(self)
      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
      GameTooltip:Hide()
  end)

  button:SetScript("OnClick", function()
    if LootMasterFrame:IsVisible() then
      LootMasterFrame:Hide()
    else
      LootMasterFrame:Show()
    end
  end)
  button:Hide()
  return button
end

local function CreateItemRollFrame()
  local frame = CreateFrame("Frame", "ItemRollFrame", UIParent)
  
  frame:SetWidth(270)
  
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

  --Create EPGP Price Frame--
  local EPGPl1 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local EPGPl2 = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  local EP = frame:CreateFontString(nil,"OVERLAY", "GameFontNormal")
  local GP = frame:CreateFontString(nil,"OVERLAY", "GameFontNormal")
  local EPGPRatio = frame:CreateFontString(nil,"OVERLAY", "GameFontNormal")
  EPGPl1:SetPoint("RIGHT", frame, "RIGHT", -35, 175)
  EPGPl1:SetFont(FONT_NAME, 13)
  EPGPl2:SetPoint("LEFT", EPGPl1, "BOTTOMLEFT", 0, -10)
  EPGPl2:SetFont(FONT_NAME, 10)
  EPGPl1:SetText("EPGP Prices")
  EPGPl2:SetText("|c"..MS_Text_Color.. "MS: 0|r |c"..OS_TEXT_COLOR.."OS: 0|r")
  EP:SetPoint("LEFT", frame, "BOTTOMLEFT", 135, 25)
  EP:SetFont(FONT_NAME, 10)
  EP:SetText("EP:")
  GP:SetPoint("LEFT", EP, "BOTTOMLEFT", -2, -8)
  GP:SetFont(FONT_NAME, 10)
  GP:SetText("GP:")
  EPGPRatio:SetPoint("LEFT", EP, "TOPLEFT", -25, 8)
  EPGPRatio:SetFont(FONT_NAME, 10)
  EPGPRatio:SetText("Priority:")
  
  
  frame.EPGPl1 = EPGPl1
  frame.EPGPl2 = EPGPl2
  frame.EP = EP
  frame.GP = GP
  frame.EPGPRatio = EPGPRatio
  
  frame.MSSR = CreateActionButton(frame, "MS SR", "Roll for MS SR", 1, function() RandomRoll(1,MSSRRollCap) end)
  frame.MS = CreateActionButton(frame, "MS", "Roll for MS", 2, function() RandomRoll(1,MSRollCap) end)
  frame.OSSR = CreateActionButton(frame, "OS SR", "Roll for OS SR", 3, function() RandomRoll(1,OSSRRollCap) end)
  frame.OS = CreateActionButton(frame, "OS", "Roll for OS", 4, function() RandomRoll(1,OSRollCap) end)
  frame.TM = CreateActionButton(frame, "TM", "Roll for Transmog", 5, function() RandomRoll(1,tmogRollCap) end)
  
  frame.BidMS = CreateActionButton(frame, "Bid MS", "Bid for MS", 1, function() SendAddonMessage(LB_PREFIX,LB_BID.. "Player: " ..UnitName("player").. " -MS- +" ..PlayerEP.."+ *"..ActiveGP.."* =" ..Ratio.."= end", "RAID") end)
  frame.BidOS = CreateActionButton(frame, "Bid OS", "Bid for OS", 2, function() SendAddonMessage(LB_PREFIX,LB_BID.. "Player: " ..UnitName("player").. " -OS- +" ..PlayerEP.."+ *"..ActiveGP.."* =" ..Ratio.."= end", "RAID") end)
  
  frame.LM = CreateLMButton(frame)
  
  frame.BidMS:Hide()
  frame.BidOS:Hide()
  frame.EPGPl1:Hide()
  frame.EPGPl2:Hide()
  frame.EP:Hide()
  frame.GP:Hide()
  frame.EPGPRatio:Hide()
  
  frame:Hide()

  return frame
end

local itemRollFrame = CreateItemRollFrame()

local function InitItemInfo(frame)
  -- Create the texture for the item icon
  local icon = frame:CreateTexture()
  icon:SetWidth(40) -- Size of the icon
  icon:SetHeight(40) -- Size of the icon
  icon:SetPoint("TOP", frame, "TOP", 0, -10)

  -- Create a button for mouse interaction
  local iconButton = CreateFrame("Button", nil, frame)
  iconButton:SetWidth(40) -- Size of the icon
  iconButton:SetHeight(40) -- Size of the icon
  iconButton:SetPoint("TOP", frame, "TOP", 0, -10)

  -- Create a FontString for the frame hide timer
  local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  timerText:SetPoint("CENTER", frame, "TOPLEFT", 30, -32)
  timerText:SetFont(timerText:GetFont(), 20)

  -- Create a FontString for the item name
  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("TOP", icon, "BOTTOM", 0, -10)

  frame.icon = icon
  frame.iconButton = iconButton
  frame.timerText = timerText
  frame.name = name
  frame.itemLink = ""

  local tt = CreateFrame("GameTooltip", "CustomTooltip2", UIParent, "GameTooltipTemplate")

  -- Set up tooltip
  iconButton:SetScript("OnEnter", function()
    tt:SetOwner(iconButton, "ANCHOR_RIGHT")
    tt:SetHyperlink(frame.itemLink)
    tt:Show()
  end)
  iconButton:SetScript("OnLeave", function()
    tt:Hide()
  end)
  iconButton:SetScript("OnClick", function()
    if ( IsControlKeyDown() ) then
      DressUpItemLink(frame.itemLink);
    elseif ( IsShiftKeyDown() and ChatFrameEditBox:IsVisible() ) then
      local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(frame.itemLink)
      ChatFrameEditBox:Insert(ITEM_QUALITY_COLORS[itemQuality].hex.."\124H"..itemLink.."\124h["..itemName.."]\124h"..FONT_COLOR_CODE_CLOSE);
    end
  end)
end

local function PullPrices(itemID)
  local data = PriceDB[itemID]
	if data then
		MSPrice = math.floor(data[2] + 0.5)
    OSPrice = math.floor(data[3] + 0.5)
  else
    MSPrice = 0
    OSPrice = 0
  end

end

local function CheckGP()
  if PlayerGP < MinGP then
    ActiveGP = MinGP
  else
    ActiveGP = PlayerGP
  end
end

-- Function to return colored text based on item quality
local function GetColoredTextByQuality(text, qualityIndex)
  -- Get the color associated with the item quality
  local r, g, b, hex = GetItemQualityColor(qualityIndex)
  -- Return the text wrapped in WoW's color formatting
  return string.format("%s%s|r", hex, text)
end

local function SetItemInfo(frame, itemLinkArg)
  local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(itemLinkArg)
  if not frame.icon then InitItemInfo(frame) end

  -- if we know the item, and the quality isn't green+, don't show it
  if itemName and itemQuality < 2 then return false end
  if not itemIcon then
    frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.name:SetText("Unknown item, attempting to query...")
    -- could be an item we want to see, try to show it
    return true
  end
  if RaidEPGP == 1 then
    local _,_,idMatch = string.find(itemLink, "item:(%d+):")
    if idMatch then
      local itemID = tonumber(idMatch)
      PullPrices(itemID)
    end

    frame.EPGPl2:SetText("|c"..MS_Text_Color.."MS: " ..MSPrice.."|r  |c"..OS_TEXT_COLOR.."OS: " ..OSPrice.."|r")
  end
  frame.icon:SetTexture(itemIcon)
  frame.iconButton:SetNormalTexture(itemIcon)  -- Sets the same texture as the icon

  frame.name:SetText(GetColoredTextByQuality(itemName,itemQuality))
  
  frame.itemLink = itemLink
  return true
end

local function ShowFrame(frame,duration,item)
  frame:SetScript("OnUpdate", function()
    time_elapsed = time_elapsed + arg1
    item_query = item_query - arg1
    if frame.timerText then frame.timerText:SetText(format("%.1f", duration - time_elapsed)) end
    if time_elapsed >= duration then
      frame.timerText:SetText("0.0")
      frame:SetScript("OnUpdate", nil)
      time_elapsed = 0
      item_query = 1.5
      times = 3
      rollMessages = {}
      isRolling = false
      if FrameAutoClose and not (masterLooter == UnitName("player")) then frame:Hide() end
    end
    if times > 0 and item_query < 0 and not CheckItem(item) then
      times = times - 1
    else
      if not SetItemInfo(itemRollFrame,item) then frame:Hide() end
      times = 5
    end
  end)
  CheckGP()
  Ratio = PlayerEP/ActiveGP
  Ratio = string.format("%.2f", Ratio)
  itemRollFrame.EP:SetText("EP: " ..PlayerEP)
  itemRollFrame.GP:SetText("GP: " ..ActiveGP)
  itemRollFrame.EPGPRatio:SetText("Priority: " ..Ratio)
  if masterLooter == UnitName("player") and RaidEPGP == 1 then 
    itemRollFrame.LM:Show()
    LootMasterFrame:Show()
  elseif GetRankOfRollerI(UnitName("player")) <= 2 and RaidEPGP == 1 then
    itemRollFrame.LM:Show()
  else
    itemRollFrame.LM:Hide()
  end
  frame:Show()
end

local function CreateTextArea(frame)
  local textArea = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  if IsAddOnLoaded("pfUI") then
    textArea:SetFont("Interface\\AddOns\\LootBlare\\Myriad-Pro.ttf", 10)
  else
    textArea:SetFont("Fonts\\FRIZQT__.TTF", 11)
  end
  textArea:SetHeight(300) -- Size of the icon
  textArea:SetPoint("TOP", frame, "TOP", 0, -80)
  textArea:SetJustifyH("LEFT")
  textArea:SetJustifyV("TOP")

  return textArea
end

local function GetClassOfRoller(rollerName)
  -- Iterate through the raid roster
  for i = 1, GetNumRaidMembers() do
      local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i)
      if name == rollerName then
          return class -- Return the class as a string (e.g., "Warrior", "Mage")
      end
  end
  return nil -- Return nil if the player is not found in the raid
end

local function updateAwardee()
  if next(EPGPMSRollMessages) then
    Awardee:SetText(EPGPMSRollMessages[1].roller)
    AwardType:SetText(EPGPMSRollMessages[1].type)
    CurrentSelection = {
          player = EPGPMSRollMessages[1].roller,
          type = EPGPMSRollMessages[1].type,
          price = MSPrice
        }
  elseif next(EPGPOSRollMessages) then
    Awardee:SetText(EPGPOSRollMessages[1].roller)
    AwardType:SetText(EPGPOSRollMessages[1].type)
    CurrentSelection = {
          player = EPGPOSRollMessages[1].roller,
          type = EPGPOSRollMessages[1].type,
          price = OSPrice
        }
  else
    Awardee:SetText("None")
  end
end

function FixEPGP()
  if GetRankOfRollerI(UnitName("player")) <= 2 or UnitName("player") == "Gweneira" or UnitName("player") == "Inoreida" then
    if FixEPGPFrame:IsVisible() then
      FixEPGPFrame:Hide()
    else
      FixEPGPFrame:Show()
      FixEPGPDropdown_OnShow()
    end
  else
    lb_print("You do not have permission to adjust EP/GP values.")
  end
end

function AwardConfirmation()
  Confirmation:SetText(itemRollFrame.name:GetText() .. "\n going to " .. CurrentSelection.player .. " for " .. CurrentSelection.price)
  if AwardSent ~= 1 then
    AwardConfirm:Show()
  end
end

function AwardCancel()
  AwardConfirm:Hide()
end

function AwardSend()
  
  if AwardSent ~= 1 then
    AwardSent = 1
    --lb_print("Item awarded to: " .. CurrentSelection.type .. " ".. CurrentSelection.player .. " for " .. CurrentSelection.price)
    SendAddonMessage(LB_PREFIX, LB_AWARD .. "-" ..CurrentSelection.player.. "- +" ..CurrentSelection.price.. "+ ", "RAID")
  end
  AwardConfirm:Hide()
end

local function UpdateTextArea(frame)
  if not frame.textArea then
    frame.textArea = CreateTextArea(frame)
  end

  -- frame.textArea:SetTeClear()  -- Clear the existing messages
  local text = ""
  local colored_msg = ""
  

  sortRolls()

  for i, v in ipairs(EPGPMSRollMessages) do
    local count = 0
    if count >= 15 then break end
    colored_msg = v.msg
    text = text .. colorEPGPMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(EPGPOSRollMessages) do
    local count = 0
    if count >= 15 then break end
    colored_msg = v.msg
    text = text .. colorEPGPMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(MSSRRollMessages) do
    local count = 0
    if count >= 8 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(MSRollMessages) do
    local count = 0
    if count >= 30 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(OSSRRollMessages) do
    local count = 0
    if count >= 8 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(OSRollMessages) do
    local count = 0
    if count >= 30 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(tmogRollMessages) do
    local count = 0
    if count >= 30 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. "\n"
    count = count + 1
  end
  updateAwardee()
  OverrideFrameDropDownType_OnShow()
  frame.textArea:SetText(text)
end



function UpdateLMScrollFrame()
  local length
  local offset = 0
  if (getn(EPGPMSRollMessages) + getn(EPGPOSRollMessages)) > 12 then
    length = (getn(EPGPMSRollMessages) + getn(EPGPOSRollMessages))
    offset = FauxScrollFrame_GetOffset(LootMasterScrollFrame)
    LootMasterScrollFrameScrollBar:Show()
    LootMasterScrollFrameScrollBarScrollUpButton:Show()
    LootMasterScrollFrameScrollBarScrollDownButton:Show()
  else
    length = 13
    LootMasterScrollFrameScrollBar:Hide()
    LootMasterScrollFrameScrollBarScrollUpButton:Hide()
    LootMasterScrollFrameScrollBarScrollDownButton:Hide()
  end
  FauxScrollFrame_Update(LootMasterScrollFrame, length, NUM_DISPLAY_ROWS, 20)
  
  for i = 1, NUM_DISPLAY_ROWS do
    local rowIndex = offset + i;
    local rowFrame = _G["LMScrollFrame" .. i];
    if rowFrame then
      if EPGPMSRollMessages[rowIndex] then
        rowFrame:Show()
        _G[rowFrame:GetName() .. "Column1"]:SetText(EPGPMSRollMessages[rowIndex].roller);
        _G[rowFrame:GetName() .. "Column2"]:SetText(EPGPMSRollMessages[rowIndex].type);
        _G[rowFrame:GetName() .. "Column3"]:SetText(EPGPMSRollMessages[rowIndex].ep);
        _G[rowFrame:GetName() .. "Column4"]:SetText(EPGPMSRollMessages[rowIndex].gp);
        _G[rowFrame:GetName() .. "Column5"]:SetText(EPGPMSRollMessages[rowIndex].ratio);
        -- Set text for Column3, Column4, Column5
      elseif EPGPOSRollMessages[rowIndex - getn(EPGPMSRollMessages)] then
        rowFrame:Show()
        _G[rowFrame:GetName() .. "Column1"]:SetText(EPGPOSRollMessages[rowIndex - getn(EPGPMSRollMessages)].roller);
        _G[rowFrame:GetName() .. "Column2"]:SetText(EPGPOSRollMessages[rowIndex - getn(EPGPMSRollMessages)].type);
        _G[rowFrame:GetName() .. "Column3"]:SetText(EPGPOSRollMessages[rowIndex - getn(EPGPMSRollMessages)].ep);
        _G[rowFrame:GetName() .. "Column4"]:SetText(EPGPOSRollMessages[rowIndex - getn(EPGPMSRollMessages)].gp);
        _G[rowFrame:GetName() .. "Column5"]:SetText(EPGPOSRollMessages[rowIndex - getn(EPGPMSRollMessages)].ratio);
        -- Set text for Column3, Column4, Column5
      else
        rowFrame:Hide();
      end
    end
  end
end

function UpdateImportScrollFrame()
  local length = getn(ImportEPGP)
  local offset = FauxScrollFrame_GetOffset(ImportScrollFrame)
  
  FauxScrollFrame_Update(ImportScrollFrame, length, 16, 20)
  
  for i = 1, 16 do
    local rowIndex = offset + i;
    local rowFrame = _G["ImportScrollFrame" .. i];
    local ImportData = ImportEPGP[rowIndex]
    if rowFrame then
      rowFrame:Show()
      _G[rowFrame:GetName() .. "Column1"]:SetText(ImportData[1]);
      _G[rowFrame:GetName() .. "Column2"]:SetText(ImportData[2]);
      _G[rowFrame:GetName() .. "Column3"]:SetText(ImportData[3]);
      _G[rowFrame:GetName() .. "Column4"]:SetText(ImportData[4]);
    end
  end
end

local function ExtractItemLinksFromMessage(message)
  local itemLinks = {}
  -- This pattern matches the standard item link structure in WoW
  for link in string.gfind(message, "|c.-|H(item:.-)|h.-|h|r") do
    table.insert(itemLinks, link)
  end
  return itemLinks
end

function ImportBroadcast()
  lb_print("Broadcasting import data to raid...")
  for i, v in ipairs(ImportEPGP) do
    SendAddonMessage(LB_PREFIX, LB_EPGPSET .. " -" ..v[1].. "- +" ..v[2].. "+ *" ..v[3].. "* ", "RAID")
  end
end

local function swapButtons()
  if RaidEPGP == 1 then
    itemRollFrame.MSSR:Hide()
    itemRollFrame.MS:Hide()
    itemRollFrame.OSSR:Hide()
    itemRollFrame.OS:Hide()
    itemRollFrame.TM:Hide()
    itemRollFrame.BidMS:Show()
    itemRollFrame.BidOS:Show()
    itemRollFrame.EPGPl1:Show()
    itemRollFrame.EPGPl2:Show()
    itemRollFrame.EP:Show()
    itemRollFrame.GP:Show()
    itemRollFrame.EPGPRatio:Show()
  elseif RaidEPGP == 0 then
    itemRollFrame.MSSR:Show()
    itemRollFrame.MS:Show()
    itemRollFrame.OSSR:Show()
    itemRollFrame.OS:Show()
    itemRollFrame.TM:Show()
    itemRollFrame.BidMS:Hide()
    itemRollFrame.BidOS:Hide()
    itemRollFrame.EPGPl1:Hide()
    itemRollFrame.EPGPl2:Hide()
    itemRollFrame.EP:Hide()
    itemRollFrame.GP:Hide()
    itemRollFrame.EPGPRatio:Hide()
  end
end

local function RequestML()
  local lootMethod, masterLooterPartyID = GetLootMethod()
    if lootMethod == "master" and masterLooterPartyID then
      SendAddonMessage(LB_PREFIX, LB_GET_DATA, "RAID") -- fetch ML info
      swapButtons()
    end
end

local function ZoneCheck()
  local zone = GetRealZoneText()
  if TestZone == 1 and zone == "The Barrens" then
    if RaidEPGP ~= 1 then
      RaidEPGP = 1
      PriceDB = Kara40
      swapButtons()
      lb_print("EPGP functions|cFF00FF00 enabled|r")
    end  
  elseif Naxx == 1 and zone == "Naxxramas" then
    if RaidEPGP ~= 1 then
      RaidEPGP = 1
      swapButtons()
      lb_print("EPGP functions|cFF00FF00 enabled|r")
    end
  elseif K40 == 1 and zone == "Tower of Karazhan" and GetNumRaidMembers() > 15 then
    if RaidEPGP ~= 1 then
      RaidEPGP = 1
      PriceDB = Kara40
      swapButtons()
      lb_print("EPGP functions|cFF00FF00 enabled|r")
    end
  elseif K40 == 1 and zone == "The Rock of Desolation" then
    if RaidEPGP ~= 1 then
      RaidEPGP = 1
      PriceDB = Kara40
      swapButtons()
      lb_print("EPGP functions|cFF00FF00 enabled|r")
    end
  else
    if RaidEPGP ~= 0 then
      RaidEPGP = 0
      swapButtons()
      lb_print("EPGP functions |cFFFF0000 disabled |r")
    end
  end
  
end 

local function IsSenderMasterLooter(sender)
  local lootMethod, masterLooterPartyID = GetLootMethod()
  if lootMethod == "master" and masterLooterPartyID then
    if masterLooterPartyID == 0 then
      return sender == UnitName("player")
    else
      local senderUID = "party" .. masterLooterPartyID
      local masterLooterName = UnitName(senderUID)
      return masterLooterName == sender
    end
  end
  return false
end

function LM_OnLoad()
  LootMasterFrame:RegisterForDrag("LeftButton")
  UIDropDownMenu_SetWidth(120, OverideFrameDropDownType)
  UIDropDownMenu_SetWidth(50, OverideTypeFrameDropDownType)
  for i = 1, NUM_DISPLAY_ROWS do
    local rowFrame = CreateFrame("Button", "LMScrollFrame" .. i, LootMasterScrollFrame, "LMScrollEntryTemplate");
    if i == 1 then
      rowFrame:SetPoint("TOPLEFT", LootMasterScrollFrame, "TOPLEFT", 2, -5);
    else
      rowFrame:SetPoint("TOPLEFT", _G["LMScrollFrame" .. (i-1)], "BOTTOMLEFT", 0, -4);
    end
    --rowFrame:Hide()
  end
end

function LMImport_OnLoad()
  ImportFrame:RegisterForDrag("LeftButton")

  for i = 1, 16 do
    local rowFrame = CreateFrame("Button", "ImportScrollFrame" .. i, ImportScrollFrame, "ImportScrollEntryTemplate");
    if i == 1 then
      rowFrame:SetPoint("TOPLEFT", ImportScrollFrame, "TOPLEFT", 2, -5);
    else
      rowFrame:SetPoint("TOPLEFT", _G["ImportScrollFrame" .. (i-1)], "BOTTOMLEFT", 0, -4);
    end
    --rowFrame:Hide()
  end
end

function kiddos ()
    DEFAULT_CHAT_FRAME:AddMessage(GetMouseFocus():GetName())
    local kiddos = { GetMouseFocus():GetRegions() };
    for _, child in ipairs(kiddos) do
        DEFAULT_CHAT_FRAME:AddMessage(child:GetName());
    end
end

function LM_StartMoving()
	
	LootMasterFrame:StartMoving();
	
end

function LMImport_StartMoving()
	
	ImportFrame:StartMoving();
	
end

local function RollCheck(maxRoll, message)
  
  if maxRoll == tostring(MSSRRollCap) then
    table.insert(MSSRRollMessages, message)
  elseif maxRoll == tostring(MSRollCap) then
    table.insert(MSRollMessages, message)
  elseif maxRoll == tostring(OSSRRollCap) then
    table.insert(OSSRRollMessages, message)
  elseif maxRoll == tostring(OSRollCap) then
    table.insert(OSRollMessages, message)
  elseif maxRoll == tostring(tmogRollCap) then
    table.insert(tmogRollMessages, message)
  end  
end

local function HandleChatMessage(event, message, sender)
  if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
    local _,_,duration = string.find(message, "Roll time set to (%d+) seconds")
    duration = tonumber(duration)
    if duration and duration ~= FrameShownDuration then
      FrameShownDuration = duration
      -- The players get the new duration from the master looter after the first rolls
      lb_print("Rolling duration set to " .. FrameShownDuration .. " seconds. (set by Master Looter)")
    end
  elseif event == "CHAT_MSG_LOOT" then
    -- Hide frame for masterlooter when loot is awarded
    if not ItemRollFrame:IsVisible() or masterLooter ~= UnitName("player") then return end

    local _,_,who = string.find(message, "^(%a+) receive.? loot:")
    local links = ExtractItemLinksFromMessage(message)

    if who and tsize(links) == 1 then
      if this.itemLink == links[1] then
        resetRolls()
        this:Hide()
      end
    end
  elseif event == "CHAT_MSG_SYSTEM" then
    local _,_, newML = string.find(message, "(%S+) is now the loot master")
    if newML then
      masterLooter = newML
      playerName = UnitName("player")
      -- if the player is the new master looter, announce the roll time
      if newML == playerName then
        SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. FrameShownDuration .. " seconds", "RAID")
      end
    elseif isRolling and string.find(message, "rolls") and string.find(message, "(%d+)") then
      local _,_,roller, roll, minRoll, maxRoll = string.find(message, "(%S+) rolls (%d+) %((%d+)%-(%d+)%)")
      if roller and roll and rollers[roller] == nil then
        roll = tonumber(roll)
        rollers[roller] = 1
        message = { rank = GetRankOfRoller(roller), rankI = GetRankOfRollerI(roller), roller = roller, roll = roll, minRoll = minRoll, maxRoll = maxRoll, msg = message, class = GetClassOfRoller(roller) }
        RollCheck(maxRoll, message)
        UpdateTextArea(itemRollFrame)
      end
    end

  elseif event == "CHAT_MSG_RAID_WARNING" and sender == masterLooter then
    local links = ExtractItemLinksFromMessage(message)
    if tsize(links) == 1 then
      -- interaction with other looting addons
      if string.find(message, "^No one has nee") or
        -- prevents reblaring on loot award
        string.find(message,"has been sent to") or
        string.find(message, " received ") then
        return
      end
      AwardSent = 0
      resetRolls()
      UpdateTextArea(itemRollFrame)
      UpdateLMScrollFrame()
      time_elapsed = 0
      isRolling = true
      ShowFrame(itemRollFrame,FrameShownDuration,links[1])
    end
  elseif event == "PLAYER_ENTERING_WORLD" then
    RequestML()
    ZoneCheck()
  elseif event == "ZONE_CHANGED_NEW_AREA" then
    ZoneCheck()
  elseif event == "ADDON_LOADED"then
    if FrameShownDuration == nil then FrameShownDuration = 15 end
    if FrameAutoClose == nil then FrameAutoClose = true end
    if PlayerEP == nil then PlayerEP = 100 end
    if PlayerGP == nil then PlayerGP = 0 end
    CheckGP()
    if IsSenderMasterLooter(UnitName("player")) then
      SendAddonMessage(LB_PREFIX, LB_SET_ML .. UnitName("player"), "RAID")
      SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. FrameShownDuration, "RAID")
      itemRollFrame:UnregisterEvent("ADDON_LOADED")
    else
      SendAddonMessage(LB_PREFIX, LB_GET_DATA, "RAID")
    end

  elseif event == "PARTY_MEMBERS_CHANGED"then
    RequestML()
    ZoneCheck()
  elseif event == "RAID_ROSTER_UPDATE"then
    RequestML()
    ZoneCheck()
  elseif event == "CHAT_MSG_ADDON" and arg1 == LB_PREFIX then
    local prefix, message, channel, sender = arg1, arg2, arg3, arg4

    -- Someone is asking for the master looter and his roll time
    if message == LB_GET_DATA and IsSenderMasterLooter(UnitName("player")) then
      masterLooter = UnitName("player")
      SendAddonMessage(LB_PREFIX, LB_SET_ML .. masterLooter, "RAID")
      SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. FrameShownDuration, "RAID")
    end

    -- Someone is setting the master looter
    if string.find(message, LB_SET_ML) then
      local _,_, newML = string.find(message, "ML set to (%S+)")
      if masterLooter ~= newML then
        lb_print("Masterlooter set to |cFF00FF00" .. newML .. "|r")
        masterLooter = newML
      end
    end
    -- Someone is setting the roll time
    if string.find(message, LB_SET_ROLL_TIME) then
      local _,_,duration = string.find(message, "Roll time set to (%d+)")
      duration = tonumber(duration)
      if duration and duration ~= FrameShownDuration then
        FrameShownDuration = duration
        lb_print("Roll time set to " .. FrameShownDuration .. " seconds.")
      end
    end

    if string.find(message, LB_EPGPSET) then
      local msg
      local _,_,player = string.find(message, "-(%S+)-")
      local _,_,ep = string.find(message, "+(%d*%.?%d+)+")
      local _,_,gp = string.find(message, "*(%d*%.?%d+)*")
      msg = { player = player, ep = tonumber(ep), gp = tonumber(gp) }
      if player == UnitName("player") then
        PlayerEP = tonumber(ep)
        PlayerGP = tonumber(gp)
        CheckGP()
        Ratio = PlayerEP/ActiveGP
        Ratio = string.format("%.2f", Ratio)
        itemRollFrame.EP:SetText("EP: " ..PlayerEP)
        lb_print("Your EP has been set to: " .. PlayerEP)
        itemRollFrame.GP:SetText("GP: " ..ActiveGP)
        lb_print("Your Real GP has been set to: " .. PlayerGP)
        lb_print("Your Effective GP has been set to: " .. ActiveGP)
        itemRollFrame.EPGPRatio:SetText("Priority: " ..Ratio)
        lb_print("Your Priority has been set to: " .. Ratio)
      end
    end

    --EPGP Communication--
    if string.find(message, LB_BID) then
      local msg
      local _,_,player = string.find(message, "Player: (%S+)")
      local _,_,type = string.find(message, "-(%u+)-")
      local _,_,effort = string.find(message, "+(%d*%.?%d+)+")
      local _,_,gear = string.find(message, "*(%d*%.?%d+)*")
      local _,_,rat = string.find(message, "=(%d*%.?%d+)=")
      rat = string.format("%.2f", rat)
      msg = { rank = GetRankOfRoller(player), rankI = GetRankOfRollerI(player), roller = player, type = type, ep = tonumber(effort), gp = tonumber(gear), ratio = tonumber(rat), class = GetClassOfRoller(player) }
    
      --lb_print(message)
      --lb_print(player.. " "..type.." "..effort.." "..gear.." "..rat)
      if rollers[player] == nil then
        rollers[player] = 1
        if type == "MS" then
          table.insert(EPGPMSRollMessages, msg)
        elseif type == "OS" then
          table.insert(EPGPOSRollMessages, msg)
        end
        UpdateTextArea(itemRollFrame)
        UpdateLMScrollFrame()
      end
      
    end
    
    if string.find(message, LB_AWARD) then
      local msg
      local _,_,player = string.find(message, "-(%S+)-")
      local _,_,price = string.find(message, "+(%d*%.?%d+)+")
      lb_print("Item awarded to: " .. player .. " for " .. price)
      if player == UnitName("player") then
        PlayerGP = PlayerGP + tonumber(price)
        CheckGP()
        Ratio = PlayerEP/ActiveGP
        Ratio = string.format("%.2f", Ratio)
        itemRollFrame.GP:SetText("GP: " ..ActiveGP)
        itemRollFrame.EPGPRatio:SetText("Priority: " ..Ratio)
        
      end
    end
  end
end

itemRollFrame:RegisterEvent("ADDON_LOADED")
itemRollFrame:RegisterEvent("CHAT_MSG_SYSTEM")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
itemRollFrame:RegisterEvent("CHAT_MSG_ADDON")
itemRollFrame:RegisterEvent("CHAT_MSG_LOOT")
itemRollFrame:RegisterEvent("RAID_ROSTER_UPDATE")
itemRollFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
itemRollFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
itemRollFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
itemRollFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
itemRollFrame:SetScript("OnEvent", function () HandleChatMessage(event,arg1,arg2) end)


-- Register the slash command
SLASH_LOOTBLARE1 = '/lootblare'
SLASH_LOOTBLARE2 = '/lb'

-- Command handler
SlashCmdList["LOOTBLARE"] = function(msg)
  msg = string.lower(msg)
  if msg == "" then
    if itemRollFrame:IsVisible() then
      itemRollFrame:Hide()
    else
      itemRollFrame:Show()
      if masterLooter == UnitName("player") or GetRankOfRollerI(UnitName("player")) <= 2 then 
        itemRollFrame.LM:Show()
        LootMasterFrame:Show()
      end
    end
  elseif msg == "help" then
    lb_print("LootBlare is a simple addon that displays and sort item rolls in a frame.")
    lb_print("Type /lb check to print your current EP")
    lb_print("Type /lb time <seconds> to set the duration the frame is shown. This value will be automatically set by the master looter after the first rolls.")
    lb_print("Type /lb autoClose on/off to enable/disable auto closing the frame after the time has elapsed.")
    lb_print("Type /lb settings to see the current settings.")
  elseif msg == "settings" then
    lb_print("Frame shown duration: " .. FrameShownDuration .. " seconds.")
    lb_print("Auto closing: " .. (FrameAutoClose and "on" or "off"))
    lb_print("Master Looter: " .. (masterLooter or "unknown"))
  elseif string.find(msg, "time") then
    local _,_,newDuration = string.find(msg, "time (%d+)")
    newDuration = tonumber(newDuration)
    if newDuration and newDuration > 0 then
      FrameShownDuration = newDuration
      lb_print("Roll time set to " .. newDuration .. " seconds.")
      if IsSenderMasterLooter(UnitName("player")) then
        SendAddonMessage(LB_PREFIX, LB_SET_ROLL_TIME .. newDuration, "RAID")
      end
    else
      lb_print("Invalid duration. Please enter a number greater than 0.")
    end
  elseif string.find(msg, "autoclose") then
    local _,_,autoClose = string.find(msg, "autoclose (%a+)")
    if autoClose == "on" or autoClose == "true" then
      lb_print("Auto closing enabled.")
      FrameAutoClose = true
    elseif autoClose == "off" or autoClose == "false" then
      lb_print("Auto closing disabled.")
      FrameAutoClose = false
    else
      lb_print("Invalid option. Please enter 'on' or 'off'.")
    end
  elseif string.find(msg, "ep") then
    if UnitName("player") == "Gweneira" then
      local _,_,newEP = string.find(msg, "ep (%d*%.?%d+)")
      newEP = tonumber(newEP)
      if newEP == nil then
        newEP = PlayerEP
      end
      PlayerEP = newEP
      CheckGP()
      Ratio = PlayerEP/ActiveGP
      Ratio = string.format("%.2f", Ratio)
      lb_print("Your EP has been set to " ..PlayerEP)
      itemRollFrame.EP:SetText("EP: " ..PlayerEP)
      itemRollFrame.EPGPRatio:SetText("Priority: " ..Ratio)
    else
      lb_print("Warning: Setting EP is deprecated and only exists for testing purposes.")
    end
  elseif string.find(msg, "gp") then
    if UnitName("player") == "Gweneira" then
      local _,_,newGP = string.find(msg, "gp (%d*%.?%d+)")
      newGP = tonumber(newGP)
      if newGP == nil then
        newGP = PlayerGP
      end
      PlayerGP = newGP
      CheckGP()
      lb_print("Your GP has been set to " ..ActiveGP)
      Ratio = PlayerEP/ActiveGP
      Ratio = string.format("%.2f", Ratio)
      itemRollFrame.GP:SetText("GP: " ..ActiveGP)
      itemRollFrame.EPGPRatio:SetText("Priority: " ..Ratio)
    else
      lb_print("This command has been deprecated, only existing for testing purposes.")
    end
  elseif string.find(msg, "check") then
    lb_print("Your current EP is set to: " ..PlayerEP)
    lb_print("Your current Real GP is set to: " ..PlayerGP)
    lb_print("Your current Effective GP is set to: " ..ActiveGP)
    lb_print("Your current priority is: " ..Ratio)
  elseif string.find(msg, "kiddos") then
    kiddos()
  elseif string.find(msg, "import") then
    ranki = GetRankOfRollerI(UnitName("player"))
    if ranki <= 2 or (UnitName("player") == "Gweneira")then
      ImportFrame:Show()

    else
      lb_print("You do not have permission to import EPGP data.")
    end
  else
  lb_print("Invalid command. Type /lb help for a list of commands.")
  end
end
