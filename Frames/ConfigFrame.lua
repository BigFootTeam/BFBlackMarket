---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local configFrame

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateConfigFrame()
    configFrame = AF.CreateFrame(BFBMMainFrame, "BFBMConfigFrame")
    AF.SetPoint(configFrame, "TOPLEFT", BFBMMainFrame, 10, -40)
    AF.SetPoint(configFrame, "BOTTOMRIGHT", BFBMMainFrame, -10, 10)

    -- optionsPane
    local  optionsPane = AF.CreateTitledPane(configFrame, AF.L["Options"], nil, 120)
    AF.SetPoint(optionsPane, "TOPLEFT")
    AF.SetPoint(optionsPane, "TOPRIGHT")

    -- requireCtrlForItemTooltips
    local requireCtrlCheckButton = AF.CreateCheckButton(optionsPane, L["Hold Ctrl to show item tooltips"], function(checked)
        BFBM_DB.config.requireCtrlForItemTooltips = checked
    end)
    AF.SetPoint(requireCtrlCheckButton, "TOPLEFT", optionsPane, 0, -30)

    -- noDataReceivingInInstance
    local blockInstanceReceivingCheckButton = AF.CreateCheckButton(optionsPane, L["No data receiving in instances"], function(checked)
        BFBM_DB.config.noDataReceivingInInstance = checked
        BFBM.DisableInstanceReceiving(checked)
    end)
    AF.SetPoint(blockInstanceReceivingCheckButton, "TOPLEFT", requireCtrlCheckButton, "BOTTOMLEFT", 0, -10)

    -- autoWipe
    local autoWipeCheckButton = AF.CreateCheckButton(optionsPane, L["Auto wipe outdated server data"], function(checked)
        BFBM_DB.config.autoWipeOutdatedServerData = checked
    end)
    AF.SetTooltips(autoWipeCheckButton, "TOPLEFT", 0, 1,
        L["Auto wipe outdated server data"], L["Server history data will be preserved"])
    AF.SetPoint(autoWipeCheckButton, "TOPLEFT", blockInstanceReceivingCheckButton, "BOTTOMLEFT", 0, -10)

    -- priceChangeAlerts
    local priceChangeAlertsCheckButton = AF.CreateCheckButton(optionsPane, L["Price change alerts"], function(checked)
        BFBM_DB.config.priceChangeAlerts = checked
    end)
    AF.SetTooltips(priceChangeAlertsCheckButton, "TOPLEFT", 0, 1,
        L["Price change alerts"], L["Show notification popups when watched items change price"], AF.L["Right Click the popup to dismiss"])
    AF.SetPoint(priceChangeAlertsCheckButton, "TOPLEFT", autoWipeCheckButton, "BOTTOMLEFT", 0, -10)

    -- chat alerts
    local chatAlertsDropdown = AF.CreateDropdown(optionsPane)
    chatAlertsDropdown:SetLabel(L["Chat messages on BM changes"])
    AF.SetPoint(chatAlertsDropdown, "TOPLEFT", priceChangeAlertsCheckButton, "BOTTOMLEFT", 0, -30)
    AF.SetPoint(chatAlertsDropdown, "RIGHT")

    chatAlertsDropdown:SetIconBGColor()
    chatAlertsDropdown:SetItems({
        {text = AF.WrapTextInColor(L["Never"], "firebrick"), value = "never", icon = AF.GetIcon("Fluent_Color_Unavailable")},
        {text = AF.WrapTextInColor(L["Current Server Only"], "softlime"), value = "current", icon = AF.GetIcon("Fluent_Color_Home")},
        {text = AF.WrapTextInColor(L["All Servers"], "yellow_text"), value = "all", icon = AF.GetIcon("Fluent_Color_Globe")},
    })

    chatAlertsDropdown:SetOnClick(function(v)
        BFBM_DB.config.chatAlerts = v
    end)

    -- chat alerts interval
    local chatAlertsIntervalDropdown = AF.CreateDropdown(optionsPane)
    chatAlertsIntervalDropdown:SetLabel(L["Chat messages interval"])
    AF.SetPoint(chatAlertsIntervalDropdown, "TOPLEFT", chatAlertsDropdown, "BOTTOMLEFT", 0, -30)
    AF.SetPoint(chatAlertsIntervalDropdown, "RIGHT")

    chatAlertsIntervalDropdown:SetItems({
        {text = L["Instant"], value = 0},
        {text = AF.L["%d minutes"]:format(5), value = 5 * 60},
        {text = AF.L["%d minutes"]:format(10), value = 10 * 60},
        {text = AF.L["%d minutes"]:format(15), value = 15 * 60},
        {text = AF.L["%d minutes"]:format(30), value = 30 * 60},
        {text = AF.L["%d minutes"]:format(60), value = 60 * 60},
    })

    chatAlertsIntervalDropdown:SetOnClick(function(v)
        BFBM_DB.config.chatAlertsInterval = v
    end)

    -- importExportPane
    local importExportPane = AF.CreateTitledPane(configFrame, AF.L["Import & Export"] .. AF.WrapTextInColor(" (WIP)", "gray"), nil, 50)
    AF.SetPoint(importExportPane, "BOTTOMLEFT")
    AF.SetPoint(importExportPane, "BOTTOMRIGHT")

    -- importButton
    local importButton = AF.CreateButton(importExportPane, AF.L["Import"], "accent_hover", 135, 20)
    AF.SetPoint(importButton, "TOPLEFT", importExportPane, 0, -30)
    importButton:SetTexture(AF.GetIcon("Import1"), nil, {"LEFT", 2, 0})

    -- exportButton
    local exportButton = AF.CreateButton(importExportPane, AF.L["Export"], "accent_hover", 135, 20)
    AF.SetPoint(exportButton, "TOPRIGHT", importExportPane, 0, -30)
    exportButton:SetTexture(AF.GetIcon("Export1"), nil, {"LEFT", 2, 0})

    -- TODO: import & export
    AF.Disable(importButton, exportButton)

    function configFrame:Load()
        requireCtrlCheckButton:SetChecked(BFBM_DB.config.requireCtrlForItemTooltips)
        blockInstanceReceivingCheckButton:SetChecked(BFBM_DB.config.noDataReceivingInInstance)
        priceChangeAlertsCheckButton:SetChecked(BFBM_DB.config.priceChangeAlerts)
        autoWipeCheckButton:SetChecked(BFBM_DB.config.autoWipeOutdatedServerData)
        chatAlertsDropdown:SetSelectedValue(BFBM_DB.config.chatAlerts)
        chatAlertsIntervalDropdown:SetSelectedValue(BFBM_DB.config.chatAlertsInterval)
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFBM_ShowFrame", function(_, which)
    if which == "config" then
        if not configFrame then
            CreateConfigFrame()
            configFrame:Load()
        end
        configFrame:Show()
    else
        if configFrame then
            configFrame:Hide()
        end
    end
end)