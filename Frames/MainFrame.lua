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
    -- about
    local aboutButton = AF.CreateButton(BFBMMainFrame.header, nil, "accent_hover", 20, 20)
    aboutButton:SetTexture(AF.GetIcon("Question"), {14, 14})
    aboutButton:SetOnClick(BFBM.ToggleAboutFrame)

    -- QR code
    if AF.portal == "CN" then
        local qrCodeButton = AF.CreateButton(BFBMMainFrame.header, nil, "accent", 20, 20)
        AF.SetPoint(qrCodeButton, "BOTTOMRIGHT", BFBMMainFrame.header.closeBtn, "BOTTOMLEFT", 1, 0)
        AF.SetPoint(aboutButton, "BOTTOMRIGHT", qrCodeButton, "BOTTOMLEFT", 1, 0)

        qrCodeButton:SetTexture(AF.GetIcon("QR_Code"), {14, 14})
        qrCodeButton:SetOnClick(function()
            BFBM_DB.qrCodeViewed = true
            AF.HideCalloutGlow(qrCodeButton)
            BFBM.ToggleQRCodeFrame()
        end)

        if not BFBM_DB.qrCodeViewed then
            AF.ShowCalloutGlow(qrCodeButton, true, false, 1)
        end
    else
        AF.SetPoint(aboutButton, "BOTTOMRIGHT", BFBMMainFrame.header.closeBtn, "BOTTOMLEFT", 1, 0)
    end

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
function BFBM.ToggleMainFrame()
    if not init then
        mainFrame:UpdatePixels()
        InitFrameWidgets()
        init = true
    end
    mainFrame:Toggle()
end