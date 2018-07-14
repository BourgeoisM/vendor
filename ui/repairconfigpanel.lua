
Vendor = Vendor or {}
Vendor.ConfigPanel = Vendor.ConfigPanel or {}
local L = Vendor:GetLocalizedStrings()
Vendor.ConfigPanel.Repair = {}

--*****************************************************************************
-- Called when the enabled state of "auto-repair" to keep the state
-- of hte sub-options in sync.
--*****************************************************************************
function Vendor.ConfigPanel.Repair.updateGuildRepair(self, repairState)
    if (not repairState) then
        self.GuildRepair.State:Disable()
    else
        self.GuildRepair.State:Enable()
    end
end

--*****************************************************************************
-- Called to sync the values on our page with the config.
--*****************************************************************************
function Vendor.ConfigPanel.Repair.Set(self, config)
    Vendor:Debug("Setting repair panel config")
    self.AutoRepair.State:SetChecked(not not config:GetValue("autorepair"))
    self.GuildRepair.State:SetChecked(not not config:GetValue("guildrepair"))
end

--*****************************************************************************
-- Push the values from our UI into the config
--*****************************************************************************
function Vendor.ConfigPanel.Repair.Apply(self, config)
    Vendor:Debug("Applying repair options")

    local autorepair = self.AutoRepair.State:GetChecked()
    config:SetValue("autorepair", autorepair)
    if (not autorepair) then
        config:SetValue("guildrepair", false)
    else
        config:SetValue("guildrepair", self.GuildRepair.State:GetChecked())
    end
end

--*****************************************************************************
-- Called to setup our panel
--*****************************************************************************
function Vendor.ConfigPanel.Repair.Init(self)
    self.Title:SetText(L["OPTIONS_HEADER_REPAIR"])
    self.HelpText:SetText(L["OPTIONS_DESC_REPAIR"])
    self.AutoRepair.Text:SetText(L["OPTIONS_SETTINGDESC_AUTOREPAIR"])
    self.AutoRepair.Label:SetText(L["OPTIONS_SETTINGNAME_AUTOREPAIR"])
    self.GuildRepair.Label:SetText(L["OPTIONS_SETTINGNAME_GUILDREPAIR"])
    self.GuildRepair.Text:SetText(L["OPTIONS_SETTINGDESC_GUILDREPAIR"])

    self.AutoRepair.OnStateChange =
        function(checkbox, state)
           Vendor.ConfigPanel.Repair.updateGuildRepair(self, state)
        end
end
