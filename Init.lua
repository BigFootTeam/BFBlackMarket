---@class BFBM
local BFBM = select(2, ...)
_G.BFBlackMarket = BFBM

BFBM.name = "BFBlackMarket"
BFBM.channelName = "BFBlackMarket"
BFBM.channelID = 0
BFBM.minVersion = 1

local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

AF.RegisterAddon(BFBM.name, L["BFBlackMarket"])
AF.AddEventHandler(BFBM)

---------------------------------------------------------------------
-- events
---------------------------------------------------------------------
BFBM:RegisterEvent("ADDON_LOADED", function(_, _, addon)
    if addon == BFBM.name then
        BFBM:UnregisterEvent("ADDON_LOADED")
        BFBM.version = AF.GetAddOnMetadata("Version")
        BFBM.versionNum = tonumber(BFBM.version:match("%d+"))

        if type("BFBM_DB") ~= "table" then
            BFBM_DB = {
                scale = 1,
            }
        end
    end
end)

---------------------------------------------------------------------
-- slash
---------------------------------------------------------------------
SLASH_BFBLACKMARKET1 = "/bfbm"
SlashCmdList["BFBLACKMARKET"] = function(msg)
    BFBM.ShowMainFrame()
end