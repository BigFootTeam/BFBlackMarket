---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local mainFrame = AF.CreateHeaderedFrame(AF.UIParent, "BFBMMainFrame", L["BFBlackMarket"], 300, 375)
mainFrame:SetPoint("CENTER")

---------------------------------------------------------------------
-- init
---------------------------------------------------------------------
local function InitFrameWidgets()
    -- slider
    local slider = AF.CreateSlider(mainFrame.header, nil, 50, 1, 2, 0.05)
    AF.SetPoint(slider, "LEFT", mainFrame.header, 5, 0)
    slider:SetEditBoxShown(false)
    slider:SetValue(BFBM_DB.config.scale)
    slider:SetAfterValueChanged(function(value)
        BFBM_DB.config.scale = value
        mainFrame:SetScale(value)
        AF.UpdatePixelsForAddon()
    end)

    -- switch
    local switch = AF.CreateSwitch(mainFrame, 280, 20)
    mainFrame.switch = switch
    AF.SetPoint(switch, "TOPLEFT", mainFrame, "TOPLEFT", 10, -10)
    switch:SetLabels({
        {
            text = L["CURRENT"],
            value = "current",
            onClick = AF.GetFireFunc("BFBM_ShowFrame", "current")
        },
        {
            text = L["HISTORY"],
            value = "history",
            onClick = AF.GetFireFunc("BFBM_ShowFrame", "history")
        },
        {
            text = L["Config"],
            value = "config",
            onClick = AF.GetFireFunc("BFBM_ShowFrame", "config")
        }
    })
    switch:SetSelectedValue("current")
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
local init
function BFBM.ShowMainFrame()
    if not init then
        mainFrame:UpdatePixels()
        InitFrameWidgets()
        init = true
    end
    mainFrame:Toggle()
end