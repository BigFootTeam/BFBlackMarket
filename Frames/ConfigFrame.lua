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
    local  optionsPane = AF.CreateTitledPane(configFrame, AF.L["Options"], nil, 100)
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

    -- priceChangeAlerts
    local priceChangeAlertsCheckButton = AF.CreateCheckButton(optionsPane, L["Price change alerts"], function(checked)
        BFBM_DB.config.priceChangeAlerts = checked
    end)
    AF.SetTooltips(priceChangeAlertsCheckButton, "TOPLEFT", 0, 1,
        L["Price change alerts"], L["Show notification popups when watched items change price"])
    AF.SetPoint(priceChangeAlertsCheckButton, "TOPLEFT", blockInstanceReceivingCheckButton, "BOTTOMLEFT", 0, -10)

    -- importExportPane
    local importExportPane = AF.CreateTitledPane(configFrame, AF.L["Import & Export"] .. AF.WrapTextInColor(" (WIP)", "gray"), nil, 100)
    AF.SetPoint(importExportPane, "TOPLEFT", optionsPane, "BOTTOMLEFT", 0, -20)
    AF.SetPoint(importExportPane, "TOPRIGHT", optionsPane, "BOTTOMRIGHT", 0, -20)

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
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFBM_ShowFrame", function(which)
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