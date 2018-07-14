local Addon, L = _G[select(1,...).."_GET"]()

Addon.RulesUI = {}
local L = Addon:GetLocalizedStrings()

local function toggleRuleWithItemLevel(frame)
    if (frame.ItemLevel) then
        if (frame.Enabled:GetChecked()) then
            frame.ItemLevel:Enable()
        else
            frame.ItemLevel:Disable()
        end
    end
end

--*****************************************************************************
-- Determines if the specified rule is enabled based on the provied rule
-- list by looking for a match on the ID.
--*****************************************************************************
local function updateRuleEnabledState(ruleFrame, ruleConfig)
    ruleFrame.Enabled:SetChecked(false)
    if (ruleFrame.ItemLevel) then
        ruleFrame.ItemLevel:SetNumber(0)
        ruleFrame.ItemLevel:Disable()
    end

    for _, entry in pairs(ruleConfig) do
        if (type(entry) == "string") then
            if (entry == ruleFrame.RuleId) then
                ruleFrame.Enabled:SetChecked(true)

                if (ruleFrame.ItemLevel) then
                    ruleFrame.ItemLevel:SetNumber(0)
                    ruleFrame.Enabled:SetChecked(false)
                    ruleFrame.ItemLevel:Disable()
                end
            end
        elseif (type(entry) == "table") then
            local ruleId = entry["rule"]
            if (ruleId and (ruleId == ruleFrame.RuleId)) then
                ruleFrame.Enabled:SetChecked(true)

                if (ruleFrame.ItemLevel) then
                    if (type(entry["itemlevel"]) == "number") then
                        ruleFrame.ItemLevel:SetNumber(entry["itemlevel"])
                    else
                        ruleFrame.ItemLevel:SetNumber(0)
                        ruleFrame.Enabled:SetChecked(false)
                        ruleFrame.ItemLevel:Disable()
                    end
                end
            end
        end
    end

    toggleRuleWithItemLevel(ruleFrame)
end

local function ruleNeeds(rule, inset)
    inset = string.lower(inset)
    if (rule.InsetsNeeded) then
        for _, needed in ipairs(rule.InsetsNeeded) do
            if (string.lower(needed) == inset) then
                return true
            end
        end
    end
end

--*****************************************************************************
-- Create a new frame for a rule item in the provided list. This will setup
-- the item for all of the proeprties of the rule
--
-- TODO: handle insets here.
--*****************************************************************************
local function createRuleItem(parent, ruleId, rule)
    local template = "VendorSimpleRuleTemplate"
    if ruleNeeds(rule, "itemlevel") then
        template = "VendorRuleTemplateWithItemLevel"
    end

    local frame = CreateFrame("Frame", ("$parent" .. ruleId), parent, template)
    frame.Rule = rule
    frame.RuleId = ruleId
    frame.RuleName:SetText(rule.Name)
    frame.RuleDescription:SetText(rule.Description)

   -- if (parent.Rules and ((#parent.Rules % 2) ~= 0)) then
   --   frame.OddBackground:Show()
   --  end

    if (frame.ItemLevel) then
        frame.ItemLevel.Label:SetText(L["RULEUI_LABEL_ITEMLEVEL"])
        frame.ToggleRuleState = toggleRuleWithItemLevel
    end

    updateRuleEnabledState(frame, parent.RuleConfig)
    return frame
end

--*****************************************************************************
-- Builds a list of rules which shoudl be enalbed based on the state of
-- rules within the list.
--*****************************************************************************
local function getRuleConfigFromList(frame)
    local config = {}
    if (frame.Rules) then
        for _, ruleItem in ipairs(frame.Rules) do
            if (ruleItem.Enabled:GetChecked()) then
                local entry = { rule = ruleItem.RuleId }

                if (ruleItem.ItemLevel) then
                    local ilvl = ruleItem.ItemLevel:GetNumber()
                    if (ilvl ~= 0) then
                        entry.itemlevel = ilvl
                    else
                        entry = nil
                    end
                end

                if (entry) then
                    table.insert(config, entry)
                end
            end
        end
    end
    return config
end

--*****************************************************************************
-- Updates the state of the list based on the config passed in
--*****************************************************************************
local function setRuleConfigFromList(frame, config)
    frame.RuleConfig = config or {}
    if (frame.Rules) then
        for _, ruleFrame in ipairs(frame.Rules) do
            updateRuleEnabledState(ruleFrame, config)
        end
    end
end

--*****************************************************************************
-- Called when a rules list is loaded in order to populate the list of
-- frames which represent the rules contained in the list.
--*****************************************************************************
function Addon.RulesUI.InitRuleList(frame, ruleType, ruleList, ruleConfig)
    frame.RuleFrameSize = 0
    frame.NumVisible = 0
    frame.GetRuleConfig = getRuleConfigFromList
    frame.SetRuleConfig = setRuleConfigFromList
    frame.RuleConfig = ruleConfig or {}
    frame.RuleList = ruleList
    frame.RuleType = ruleType

    assert(frame.RuleList, "Rule List frame needs to have the rule list set")
    assert(frame.RuleType, "Rule List frame needs to have the rule type set")

    -- Create the frame for each of our rules.
    for id, rule in pairs(frame.RuleList) do
        if (not rule.Locked) then
            local rule = createRuleItem(frame, id, rule)
            frame.RuleFrameSize = math.max(frame.RuleFrameSize, rule:GetHeight())
        end
    end

    -- Give an initial update of the view
    Addon.RulesUI.UpdateRuleList(frame)
end

--*****************************************************************************
-- Called when the list is scrolled/created and will iterate through our list
-- of frames an then show/hide and position the frames which should be
-- currently visibile.
--*****************************************************************************
function Addon.RulesUI.UpdateRuleList(frame)
    if (frame.Rules) then
        local offset = FauxScrollFrame_GetOffset(frame.View)
        local ruleHeight = frame.RuleFrameSize
        local previousFrame = nil
        local totalItems = #frame.Rules
        local numVisible = math.floor(frame.View:GetHeight() / frame.RuleFrameSize)
        local startIndex = (1 + offset)
        local endIndex = math.min(totalItems, offset + numVisible)

        FauxScrollFrame_Update(frame.View, totalItems, numVisible, frame.RuleFrameSize, nil, nil, nil, nil, nil, nil, true)
        for ruleIndex=1,#frame.Rules do
            local ruleFrame = frame.Rules[ruleIndex]
            if ((ruleIndex < startIndex) or (ruleIndex > endIndex)) then
                ruleFrame:Hide()
            else
                if (previousFrame) then
                    ruleFrame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
                    ruleFrame:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0, 0)
                else
                    ruleFrame:SetPoint("TOPLEFT", frame.View, "TOPLEFT", 0, 0)
                    ruleFrame:SetPoint("TOPRIGHT", frame.View, "TOPRIGHT", 0, 0)
                end
                ruleFrame:Show()
                previousFrame = ruleFrame
            end
        end
    end
end

function Addon.RulesUI.ApplySystemRuleConfig(frame)
    Addon:DebugRules("Applying config for rule type '%s'", frame.RuleType)
    Addon:GetConfig():SetRulesConfig(frame.RuleType, getRuleConfigFromList(frame))
end

--************************************--

local function showHideFrame(frameName, show)
	local frame = _G[frameName]
	if (frame) then
		if (show) then
			frame:Show()
		else
			frame:Hide()
		end
	end
end

function Addon.RulesUI.RuleDialog_OnLoad(self)
    --tinsert(UISpecialFrames, self:GetName());
	self.Caption:SetText(L["CONFIG_DIALOG_CAPTION"])

	-- Setup the sell Panel
	self.SellTab:SetText(L["CONFIG_DIALOG_SELLRULES_TAB"])
	PanelTemplates_TabResize(self.SellTab, 0)
	self.SellPanel.TopText:SetText(L["CONFIG_DIALOG_SELLRULES_TEXT"])
	self.SellPanel.List:SetBackdropBorderColor(.6, .6, .6, 1)
	self.SellPanel.List:SetBackdropColor(1.0, 1.0, 1.0, 0.10)

	-- Setup the keep panel
	self.KeepTab:SetText(L["CONFIG_DIALOG_KEEPRULES_TAB"])
	PanelTemplates_TabResize(self.KeepTab, 0)
	self.KeepPanel.List:SetBackdropBorderColor(.6, .6, .6, 1)
	self.KeepPanel.List:SetBackdropColor(1.0, 1.0, 1.0, 0.10)
	self.KeepPanel.TopText:SetText(L["CONFIG_DIALOG_KEEPRULES_TEXT"])

	-- Setup the custom rules panel
	--self.CustomPanel.List:SetBackdropBorderColor(.6, .6, .6, 1);
	self.CustomTab:SetText(L["CONFIG_DIALOG_CUSTOMRULES_TAB"])
	PanelTemplates_TabResize(self.CustomTab, 0)
	self.CustomPanel.TopText:SetText(L["CONFIG_DIALOG_CUSTOMRULES_TEXT"])

	-- Initialize the tabs
	PanelTemplates_SetNumTabs(self, 3)
	self.selectedTab = 2
	PanelTemplates_UpdateTabs(self)
	Addon.RulesUI.RuleDialog_ShowTab(self, self.selectedTab)
end

function Addon.RulesUI.RuleDialog_ShowTab(self, tabId)
	local tabName1 = (self:GetName() .. "Tab1")
	local tabName2 = (self:GetName() .. "Tab2")
	local tabName3 = (self:GetName() .. "Tab3")

	if (tabId == 1) then
		showHideFrame(tabName1 .. "Spacer1", true)
		showHideFrame(tabName2 .. "Spacer1", false)
		showHideFrame(tabName2 .. "Spacer2", false)
		showHideFrame(tabName3 .. "Spacer1", false)
		showHideFrame(tabName3 .. "Spacer2", false)
		self.SellPanel:Hide()
		self.KeepPanel:Show()
		self.CustomPanel:Hide()
	elseif (tabId == 2) then
		showHideFrame(tabName1 .. "Spacer1", false)
		showHideFrame(tabName2 .. "Spacer1", true)
		showHideFrame(tabName2 .. "Spacer2", true)
		showHideFrame(tabName3 .. "Spacer1", false)
		showHideFrame(tabName3 .. "Spacer2", false)
		self.SellPanel:Show()
		self.KeepPanel:Hide()
		self.CustomPanel:Hide()
	elseif (tabId == 3) then
		showHideFrame(tabName1 .. "Spacer1", false)
		showHideFrame(tabName2 .. "Spacer1", false)
		showHideFrame(tabName2 .. "Spacer2", false)
		showHideFrame(tabName3 .. "Spacer1", true)
		showHideFrame(tabName3 .. "Spacer2", true)
		self.SellPanel:Hide()
		self.KeepPanel:Hide()
		self.CustomPanel:Show()
	end
end

function Addon.RulesUI.RulesDialog_SetDefaults(self)
	Addon:DebugRules("Restoring rule configuration to the default")
	local config = Addon:GetConfig()
	self.SellPanel.List:SetRuleConfig(config:GetDefaultRulesConfig(Addon.c_RuleType_Sell))
	self.KeepPanel.List:SetRuleConfig(config:GetDefaultRulesConfig(Addon.c_RuleType_Keep))
end

function Addon.RulesUI.RulesDialog_OnOk(self)
	Addon:DebugRules("Applying new rule configuration")
	Addon:GetConfig():BeginBatch()
	Addon.RulesUI.ApplySystemRuleConfig(self.SellPanel.List)
    Addon.RulesUI.ApplySystemRuleConfig(self.KeepPanel.List)
    Addon:GetConfig():EndBatch()
	HideParentPanel(self.Container)
end

function Addon:ShowRulesDialog()
	VendorRulesDialog.SellPanel.List:SetRuleConfig(Addon:GetRulesConfig(Addon.c_RuleType_Sell))
	VendorRulesDialog.KeepPanel.List:SetRuleConfig(Addon:GetRulesConfig(Addon.c_RulesType_Keep))
	VendorRulesDialog:Show()
end

