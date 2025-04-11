---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local currentFrame

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateCurrentFrame()
    currentFrame = AF.CreateFrame(BFBMMainFrame, "BFBMCurrentFrame")
    AF.SetPoint(currentFrame, "TOPLEFT", BFBMMainFrame, 10, -40)
    AF.SetPoint(currentFrame, "BOTTOMRIGHT", BFBMMainFrame, -10, 10)

    -- server dropdown
    local serverDropdown = AF.CreateDropdown(currentFrame)
    serverDropdown:SetPoint("TOPLEFT")
    serverDropdown:SetPoint("TOPRIGHT")
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFBM_ShowFrame", function(which)
    if which == "current" then
        if not currentFrame then
            CreateCurrentFrame()
        end
        currentFrame:Show()
    else
        if currentFrame then
            currentFrame:Hide()
        end
    end
end)