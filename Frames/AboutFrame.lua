---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local aboutFrame

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateAboutFrame()
    aboutFrame = AF.CreateBorderedFrame(BFBMMainFrame, "BFBMAboutFrame", nil, 160, nil, "accent")
    AF.SetPoint(aboutFrame, "TOPLEFT", BFBMMainFrame, 10, -10)
    AF.SetPoint(aboutFrame, "TOPRIGHT", BFBMMainFrame, -10, -10)
    AF.SetFrameLevel(aboutFrame, 100)
    aboutFrame:Hide()

    aboutFrame:SetOnShow(function()
        AF.ShowMask(BFBMMainFrame)
    end)

    aboutFrame:SetOnHide(function()
        AF.HideMask(BFBMMainFrame)
        aboutFrame:Hide()
    end)

    -- close
    local closeBtn = AF.CreateCloseButton(aboutFrame, nil, 20, 20)
    AF.SetPoint(closeBtn, "TOPRIGHT")
    closeBtn:SetBorderColor("accent")

    -- feedback (Cn)
    local feedbackCnEditBox = AF.CreateEditBox(aboutFrame, nil, nil, 20)
    AF.SetPoint(feedbackCnEditBox, "TOPLEFT", 10, -35)
    AF.SetPoint(feedbackCnEditBox, "RIGHT", -10, 0)
    feedbackCnEditBox:SetNotUserChangable(true)
    feedbackCnEditBox:SetText("https://kook.vip/JpQlUv")

    local feedbackCnText = AF.CreateFontString(aboutFrame, AF.EscapeIcon(AF.GetLogo("kook"), 18) .. " " .. AF.L["Feedback & Suggestions"] .. " (CN)")
    AF.SetPoint(feedbackCnText, "BOTTOMLEFT", feedbackCnEditBox, "TOPLEFT", 2, 2)
    feedbackCnText:SetColor("accent")

    -- feedback (En)
    local feedbackEnEditBox = AF.CreateEditBox(aboutFrame, nil, nil, 20)
    AF.SetPoint(feedbackEnEditBox, "TOPLEFT", feedbackCnEditBox, "BOTTOMLEFT", 0, -35)
    AF.SetPoint(feedbackEnEditBox, "RIGHT", feedbackCnEditBox)
    feedbackEnEditBox:SetNotUserChangable(true)
    feedbackEnEditBox:SetText("https://discord.gg/9PSe3fKQGJ")

    local feedbackEnText = AF.CreateFontString(aboutFrame, AF.EscapeIcon(AF.GetLogo("discord"), 18) .. " ".. AF.L["Feedback & Suggestions"] .. " (EN)")
    AF.SetPoint(feedbackEnText, "BOTTOMLEFT", feedbackEnEditBox, "TOPLEFT", 2, 2)
    feedbackEnText:SetColor("accent")

    -- author
    local authorText = AF.CreateFontString(aboutFrame, AF.WrapTextInColor(AF.L["Author"] .. ": ", "accent") .. "enderneko")
    AF.SetPoint(authorText, "TOPLEFT", feedbackEnEditBox, "BOTTOMLEFT", 0, -20)

    -- version
    local versionText = AF.CreateFontString(aboutFrame, AF.WrapTextInColor(AF.L["Version"] .. ": ", "accent") .. AF.GetAddOnMetadata("Version"))
    AF.SetPoint(versionText, "LEFT", aboutFrame, "BOTTOM", 10, 0)
    AF.SetPoint(versionText, "BOTTOM", authorText)
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
function BFBM.ToggleAboutFrame()
    if not aboutFrame then
        CreateAboutFrame()
    end
    aboutFrame:Toggle()
end