local AddonName, Data = ...

local GetBattlefieldArenaFaction = GetBattlefieldArenaFaction
local C_PvP_GetActiveMatchWinner = C_PvP.GetActiveMatchWinner

local debugg = false
local function debug(...)
    if debugg then
        print(...)
    end
end

local backdropInfo = {
	bgFile = "Interface\\Buttons\\WHITE8X8",
	edgeFile = "Interface\\Buttons\\WHITE8X8",
	edgeSize = 1,
	insets = { left = 1, right = 1, top = 1, bottom = 1, },
}

local frame = CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")

frame:SetPoint("TOPLEFT")

frame.dragme = frame:CreateFontString(nil, "OVERLAY")
frame.dragme:SetFont("Fonts\\FRIZQT__.TTF", 4)
frame.dragme:SetSize(200, 100)
frame.dragme:SetText("drag me")
frame.dragme:SetPoint("BOTTOMLEFT")
frame.dragme:SetPoint("BOTTOMRIGHT")
frame.dragme:SetHeight(8)
frame.dragme:Hide()

local reset = CreateFrame("Button", nil, UIParent)
reset:SetNormalTexture([[Interface\Buttons\UI-GroupLoot-Pass-Up]])
reset:GetNormalTexture():SetDesaturated(true)
reset:SetHighlightTexture([[Interface\Buttons\UI-GroupLoot-Pass-Highlight]])
reset:SetPushedTexture([[Interface\Buttons\UI-GroupLoot-Pass-Down]])
reset:SetScript("OnEnter", function(self, motion) debug("reset OnEnter") self:SetAlpha(1) end)
reset:SetScript("OnLeave", function(self, motion) debug("reset OnLeave") self:SetAlpha(0) end)
reset:SetScript("OnClick", function() StaticPopup_Show("CONFIRM_OVERRITE_"..AddonName) end)
reset:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, 0)
reset:SetSize(32,32)


local function frameOnEnter()
    frame:SetBackdrop(backdropInfo)
    frame:SetBackdrop(backdropInfo)
    frame:SetBackdropColor(0, 0, 0,1) -- Black background
    frame:SetBackdropBorderColor(1,1,1,1) -- White border
    reset:SetAlpha(1)
    frame.dragme:Show()
end

local function frameOnLeave()
    frame:SetBackdrop(nil)
    reset:SetAlpha(0)
    frame.dragme:Hide()

end

function frame:ApplySettings()
    self:SetScale(ArenaWinTracker.Scale)

    if not ArenaWinTracker.Position_X and not ArenaWinTracker.Position_Y then
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER")
        debug("hier")
    else
        self:ClearAllPoints()
        debug("dort")
        local scale = self:GetEffectiveScale()
        self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ArenaWinTracker.Position_X / scale, ArenaWinTracker.Position_Y / scale)
    end
    self.wins:SetEnabled(ArenaWinTracker.Editable)
    self.loses:SetEnabled(ArenaWinTracker.Editable)
    if ArenaWinTracker.Locked then
        self.dragme:SetText("Locked")
    else
        self.dragme:SetText("Drag me")
    end
 

end

function frame:OnDragStart()
    return ArenaWinTracker.Locked or self:StartMoving()
end	


function frame:OnDragStop()
    self:StopMovingOrSizing()
   
    local scale = self:GetEffectiveScale()
    ArenaWinTracker.Position_X = self:GetLeft() * scale
    ArenaWinTracker.Position_Y = self:GetTop() * scale
end

frame:SetClampedToScreen(true)



frame:SetSize(100, 20)
frame:SetScript("OnSizeChanged", function(self, width, height)
    debug("frame size changed,", width, height)
end)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.OnDragStart)
frame:SetScript("OnDragStop", frame.OnDragStop)
frame:SetScript("OnEnter", function(self, motion) debug("frame OnEnter") frameOnEnter() end)
frame:SetScript("OnLeave", function(self, motion) debug("frame OnLeave") frameOnLeave() end)
function frame:SetFrameWidth()
    frame:SetWidth(frame.wins:GetWidth()  + frame.dash:GetWidth() + frame.loses:GetWidth())
end
frameOnEnter()






local function CreateEditbox(parent, key)
    local editbox = CreateFrame("EditBox", nil, parent)
    editbox.fs = editbox:GetRegions()

    local origSetWidth = editbox.fs.SetWidth
    editbox.fs.SetWidth = function(self, width)
        debug("useddfsdaf", width)
        editbox:SetWidth(width  + 2)
        origSetWidth(self, width)
    end

    function editbox:BeforeTextInsertion()
        self.fs:SetWidth(self.fs:GetUnboundedStringWidth() + 10)
    end

    editbox:SetScript("OnEnter", function(self, motion) debug("frame OnEnter") frameOnEnter() end)
    editbox:SetScript("OnLeave", function(self, motion) debug("frame OnLeave") frameOnLeave() end)
    editbox:SetScript("OnSizeChanged", function(self, width, height)
        frame:SetFrameWidth()
    end)
    editbox:SetScript("OnTextChanged", function(self, userInput) 
        debug("OnTextChanged", userInput, self:GetText(), self.fs:GetUnboundedStringWidth(), (self:GetRegions()))

        if userInput then
            self.fs:SetWidth(self.fs:GetUnboundedStringWidth()  + 10) --necessary, otherwise we exceed the length when typing and it doesnt work
        else
            if not self.fs:GetText() then
                debug("no fs text")
                self.fs:SetText(self:GetText())
            end
            self.fs:SetWidth(self.fs:GetUnboundedStringWidth())  --necessary, since it fires after OnEditFocusLost in which we SetText()
        end
        --self:SetWidth(self.fs:GetUnboundedStringWidth() + 11)
    end)
    editbox:SetScript("OnEditFocusLost", function(self) 
        debug("OnEditFocusLost", self:GetText(), self.fs:GetUnboundedStringWidth(), (self:GetRegions()))
        if self:GetText() == "" then
            ArenaWinTracker[self.key] = 0
        else
            ArenaWinTracker[self.key] = tonumber(self:GetText())
        end
        self:SetText(ArenaWinTracker[self.key]) -- when the users enters like 009, this changes it to 9 and then OnTextChanged fires
        C_Timer.After(0, function() 
            self.fs:SetWidth(self.fs:GetUnboundedStringWidth())
        end)
    end)
    editbox:SetScript("OnEditFocusGained", function(self) 
        self.fs:SetWidth(self.fs:GetUnboundedStringWidth() + 10) --necessary, otherwise we exceed the length when typing and it doesnt work
    end)
    editbox.key = key
    editbox:SetSize(100, 13)
    editbox:SetMultiLine(false)
    editbox:SetAutoFocus(false) -- dont automatically focus
    editbox:SetNumeric(true)
    editbox:SetFontObject("ChatFontNormal")
    editbox:SetText("30")
   
    return editbox
end


frame.wins = CreateEditbox(frame, "Wins")
frame.wins:SetPoint("TOPLEFT", frame, "TOPLEFT")
frame.wins:SetSize(100, 13)
frame.wins.fs = frame.wins:GetRegions()

frame.dash = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
frame.dash:SetSize(200, 100)
frame.dash:SetText("-")
C_Timer.After(0, function() 
    frame.dash:SetSize(ceil(frame.dash:GetUnboundedStringWidth()), ceil(frame.dash:GetStringHeight()))
    C_Timer.After(0, function() 
        frame:SetFrameWidth()
    end)
end)
frame.dash:SetJustifyH("LEFT")
frame.dash:SetPoint("LEFT", (frame.wins:GetRegions()), "RIGHT")

frame.loses = CreateEditbox(frame, "Loses")
frame.loses:SetPoint("LEFT", frame.dash, "RIGHT")
frame.loses:SetSize(100, 13)
frame.loses.fs = frame.loses:GetRegions()


function frame:SetupOptions()
	self.panel = CreateFrame("Frame")
	self.panel.name = AddonName

	self.panel.locked = CreateFrame("CheckButton", nil, self.panel, "InterfaceOptionsCheckButtonTemplate")
	self.panel.locked:SetPoint("TOPLEFT", 20, -20)
	self.panel.locked.Text:SetText("Locked")
	self.panel.locked.SetValue = function(_, value)
		ArenaWinTracker.Locked = (value == "1") -- value can be either "0" or "1"
        frame:ApplySettings()
	end
	self.panel.locked:SetChecked(ArenaWinTracker.Locked) -- set the initial checked state

    self.panel.editable = CreateFrame("CheckButton", nil, self.panel, "InterfaceOptionsCheckButtonTemplate")
	self.panel.editable:SetPoint("TOPLEFT", self.panel.locked, "TOPLEFT", 0, -40)
	self.panel.editable.Text:SetText("Editable score")
	self.panel.editable.SetValue = function(_, value)
		ArenaWinTracker.Editable = (value == "1") -- value can be either "0" or "1"
        frame:ApplySettings()
	end
	self.panel.editable:SetChecked(ArenaWinTracker.Editable) -- set the initial checked state

    self.panel.scale = CreateFrame("Slider", nil, self.panel, "OptionsSliderTemplate")
    self.panel.scale:SetMinMaxValues(3, 15)
    self.panel.scale:SetValue(ArenaWinTracker.Scale)
    self.panel.scale:SetValueStep(0.05)
	self.panel.scale:SetPoint("TOPLEFT", self.panel.editable, "TOPLEFT", 0, -40)

    self.panel.scale:SetScript("OnValueChanged", function(self, value, userInput)
		debug("You changed me!", value, userInput)
        ArenaWinTracker.Scale = value
        frame:ApplySettings()
	end)
    self.panel.scale.Text:SetText("Scale")
  
    

	InterfaceOptions_AddCategory(self.panel)
end



StaticPopupDialogs["CONFIRM_OVERRITE_"..AddonName] = {
    text = "Are you sure you want to reset the score?",
    button1 = YES,
    button2 = NO,
    OnAccept = function (self) 
          frame:Reset()
    end,
    OnCancel = function (self) end,
    OnHide = function (self) self.data = nil; self.selectedIcon = nil; end,
    hideOnEscape = 1,
    timeout = 30,
    exclusive = 1,
    whileDead = 1,
}

function frame:UpdateScore()
    self.wins:SetText(ArenaWinTracker.Wins)
    self.loses:SetText(ArenaWinTracker.Loses)
end

function frame:Reset()
    ArenaWinTracker.Wins = 0 -- we have to do this magic because ottherwise we insert the additional space into the fontstring even tho nothing is about tho change
    ArenaWinTracker.Loses = 0
    self:UpdateScore()
end

--copied from PVPMatchResultsMixin:Init()  -> local function GetOutcomeText
local function DidIWin(winner, factionIndex)
    local enemyFactionIndex = (factionIndex + 1) % 2;
    if winner == factionIndex then
        return true
    elseif winner == enemyFactionIndex then
        return false		
    end
    return
end


frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self,event,...)
    if event == "PLAYER_LOGIN" then
        
        ArenaWinTracker = ArenaWinTracker or {}
        ArenaWinTracker.Wins = ArenaWinTracker.Wins or 0
        ArenaWinTracker.Loses = ArenaWinTracker.Loses or 0
        ArenaWinTracker.Scale = ArenaWinTracker.Scale or 3
        ArenaWinTracker.Editable = ArenaWinTracker.Editable or false

        --self:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", ArenaWinTracker.Position_X / scale, ArenaWinTracker.Position_Y / scale)

        self:SetupOptions()
        self:ApplySettings()


        self:RegisterEvent("PVP_MATCH_COMPLETE")
        self:UpdateScore()
    else

        local _, zone = IsInInstance()

		if zone == "arena" then
            local iWon = DidIWin(C_PvP_GetActiveMatchWinner(), GetBattlefieldArenaFaction())
            if iWon then
                ArenaWinTracker.Wins = ArenaWinTracker.Wins + 1
            elseif iWon == false then
                ArenaWinTracker.Loses = ArenaWinTracker.Loses + 1
            end
            self:UpdateScore()
        end
    end
end)