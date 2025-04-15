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

        if type(BFBM_DB) ~= "table" then BFBM_DB = {} end
        if type(BFBM_DB.scale) ~= "number" then BFBM_DB.scale = 1 end

        if type(BFBM_DB.data) ~= "table" then
            BFBM_DB.data = {
                servers = {
                    -- [serverName] = {
                    --     items = {
                    --         {
                    --             itemID = (number),
                    --             name = (string),
                    --             texture = (number),
                    --             link = (string),
                    --             quantity = (number),
                    --             quality = (number),
                    --             itemType = (string),
                    --             level = (number),
                    --             levelType = (string),
                    --             sellerName = (string),
                    --             minBid = (number),
                    --             minIncrement = (number),
                    --             currBid = (number),
                    --             numBids = (number),
                    --             timeLeft = (number),
                    --             marketID = (number),
                    --             isHot = (boolean),
                    --         }
                    --     },
                    --     lastUpdate = (number|nil),
                    -- },
                },
                items = {
                    -- [itemID] = {
                    --     name = (string),
                    --     texture = (number),
                    --     link = (string),
                    --     quality = (number),
                    --     itemType = (string),
                    --     history = {
                    --         [serverName] = {
                    --             [date] = { -- 20250413
                    --                 bids = {
                    --                     [bidIndex] = (number),
                    --                 },
                    --                 finalPrice = (number|nil),
                    --             },
                    --         },
                    --     },
                    -- },
                },
            }
        end

        -- clear cache
        -- BFBM_TODAY = nil
    end
end)

BFBM:RegisterEvent("PLAYER_LOGIN", function()
    print(AF.player.realm)
    -- current server
    if type(BFBM_DB.data.servers[AF.player.realm]) ~= "table" then
        BFBM_DB.data.servers[AF.player.realm] = {
            items = {},
            lastUpdate = nil,
        }
    end
    BFBM.currentServerData = BFBM_DB.data.servers[AF.player.realm]
end)

---------------------------------------------------------------------
-- slash
---------------------------------------------------------------------
SLASH_BFBLACKMARKET1 = "/bfbm"
SlashCmdList["BFBLACKMARKET"] = function(msg)
    BFBM.ShowMainFrame()
end