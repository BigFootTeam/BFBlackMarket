---@class BFBM
local BFBM = select(2, ...)
_G.BFBlackMarket = BFBM

BFBM.name = "BFBlackMarket"
BFBM.channelName = "BFChannel"
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

        -- config
        if type(BFBM_DB.config) ~= "table" then
            BFBM_DB.config = {
                scale = 1,
                requireCtrlForItemTooltips = true,
                noDataReceivingInInstance = true,
                priceChangeAlerts = true,
            }
        end
        BFBMMainFrame:SetScale(BFBM_DB.config.scale)
        BFBM.DisableInstanceReceiving(BFBM_DB.config.noDataReceivingInInstance)

        -- favorites
        if type(BFBM_DB.favorites) ~= "table" then
            BFBM_DB.favorites = {
                -- [itemID] = true,
            }
        end

        -- data
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

        -- NOTE: cache is only for CN servers
        BFBM_DataUpload = nil
        if AF.portal == "CN" and type(BFBM_DataUpload) ~= "table" then
            BFBM_DataUpload = {}
        end
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
    -- update data for send
    BFBM.UpdateDataForSend()
end)

---------------------------------------------------------------------
-- channel
---------------------------------------------------------------------
AF.RegisterTemporaryChannel(BFBM.channelName)
AF.BlockChatConfigFrameInteractionForChannel(BFBM.channelName)
AF.RegisterCallback("AF_JOIN_TEMP_CHANNEL", function(channelName, channelID)
    if channelName == BFBM.channelName then
        BFBM.channelID = channelID
        BFBM.BroadcastVersion()
    end
end)

---------------------------------------------------------------------
-- slash
---------------------------------------------------------------------
SLASH_BFBLACKMARKET1 = "/bfbm"
SlashCmdList["BFBLACKMARKET"] = function(msg)
    BFBM.ShowMainFrame()
end