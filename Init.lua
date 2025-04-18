---@class BFBM
local BFBM = select(2, ...)
_G.BFBlackMarket = BFBM

BFBM.name = "BFBlackMarket"
BFBM.channelName = "BFBlackMarket"
BFBM.channelID = 0
BFBM.minVersion = 1
BFBM.MAX_BID = 99999990000

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

        if type(BFBM_DB.config) ~= "table" then BFBM_DB.config = {} end
        if type(BFBM_DB.config.scale) ~= "number" then BFBM_DB.config.scale = 1 end
        if type(BFBM_DB.config.requireCtrlForItemTooltips) ~= "boolean" then
            BFBM_DB.config.requireCtrlForItemTooltips = true
        end

        if type(BFBM_DB.favorites) ~= "table" then
            BFBM_DB.favorites = {
                -- [itemID] = true,
            }
        end

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
                    --             minBid = (number),
                    --             currBid = (number),
                    --             numBids = (number),
                    --             timeLeft = (number),
                    --         }
                    --     },
                    --     lastUpdate = (number),
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
                    --                 finalBid = (number|nil),
                    --             },
                    --         },
                    --     },
                    --     lastUpdate = (number),
                    --     lastAvgCalc = (number),
                    --     avgBid = (number),
                    -- },
                },
            }
        end

        -- clear cache
        -- BFBM_TODAY = nil
    end
end)

BFBM:RegisterEvent("PLAYER_LOGIN", function()
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