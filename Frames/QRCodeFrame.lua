---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local qrCodeFrame

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateQRCodeFrame()
    qrCodeFrame = AF.CreateBorderedFrame(BFBMMainFrame, "BFBMQRCodeFrame", 0, 0, nil, "accent")
    AF.SetPoint(qrCodeFrame, "TOPLEFT", BFBMMainFrame.header, "TOPRIGHT", 5, 0)
    qrCodeFrame:SetFrameStrata("DIALOG")
    qrCodeFrame:SetClampedToScreen(true)
    qrCodeFrame:Hide()

    -- text
    local text = AF.CreateFontString(qrCodeFrame, "打开" .. AF.WrapTextInColorCode("微信", "91ED61") .. "\n扫一扫下面的二维码\n使用" .. AF.WrapTextInColor("大脚微信小程序", "accent") .. "\n可以查看更多数据哦")
    AF.SetPoint(text, "TOPLEFT", 10, -10)
    AF.SetPoint(text, "TOPRIGHT", -10, -10)
    text:Hide()
    text:SetSpacing(5)

    -- qrcode
    local qrcode = AF.GetQRCodeFrame(qrCodeFrame, "https://bfi.178.com/wx_app/bf?source=bfbm", 140)
    AF.SetPoint(qrcode, "TOP", text, "BOTTOM", 0, -10)
    qrcode:Hide()

    -- animation
    function qrCodeFrame:Show()
        AF.FrameShow(qrCodeFrame)
        AF.SetSize(qrCodeFrame, 1, 1)
        AF.AnimatedResize(qrCodeFrame, 160, 240, nil, nil, nil, function()
            text:Show()
            qrcode:Show()
        end)
    end

    function qrCodeFrame:Hide()
        AF.AnimatedResize(qrCodeFrame, 1, 1, nil, nil, function()
            text:Hide()
            qrcode:Hide()
        end, function()
            AF.FrameHide(qrCodeFrame)
        end)
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
function BFBM.ToggleQRCodeFrame()
    if not qrCodeFrame then
        CreateQRCodeFrame()
    end
    qrCodeFrame:Toggle()
end