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

    -- requireCtrlForItemTooltips
    local requireCtrlCheckButton = AF.CreateCheckButton(configFrame, L["Hold Ctrl to show item tooltips"], function(checked)
        BFBM_DB.config.requireCtrlForItemTooltips = checked
    end)
    AF.SetPoint(requireCtrlCheckButton, "TOPLEFT", configFrame, "TOPLEFT", 0, -2)

    -- noDataReceivingInInstance
    local blockInstanceReceivingCheckButton = AF.CreateCheckButton(configFrame, L["No data receiving in instances"], function(checked)
        BFBM_DB.config.noDataReceivingInInstance = checked
        BFBM.DisableInstanceReceiving(checked)
    end)
    AF.SetPoint(blockInstanceReceivingCheckButton, "TOPLEFT", requireCtrlCheckButton, "BOTTOMLEFT", 0, -10)

    function configFrame:Load()
        requireCtrlCheckButton:SetChecked(BFBM_DB.config.requireCtrlForItemTooltips)
        blockInstanceReceivingCheckButton:SetChecked(BFBM_DB.config.noDataReceivingInInstance)
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