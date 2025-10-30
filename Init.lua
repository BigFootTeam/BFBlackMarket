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
local LRI = LibStub("LibRealmInfoCN")

AF.RegisterAddon(BFBM.name, L["BFBlackMarket"])
AF.AddEventHandler(BFBM)

---------------------------------------------------------------------
-- events
---------------------------------------------------------------------
BFBM:RegisterEvent("ADDON_LOADED", function(_, _, addon)
    if addon == BFBM.name then
        BFBM.version, BFBM.versionNum = AF.GetAddOnVersion(BFBM.name)

        if type(BFBM_DB) ~= "table" then BFBM_DB = {} end

        -- config
        if type(BFBM_DB.config) ~= "table" then
            BFBM_DB.config = {
                scale = 1,
                requireCtrlForItemTooltips = false,
                noDataReceivingInInstance = false,
                priceChangeAlerts = true,
                autoWipeOutdatedServerData = true,
                chatAlerts = "current",
                chatAlertsInterval = 0,
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
                    --         [itemID] = {
                    --             name = (string),
                    --             texture = (number),
                    --             link = (string),
                    --             quantity = (number),
                    --             quality = (number),
                    --             itemType = (string),
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
                    --     lastMerge = (number),
                    --     avgBid = (number),
                    -- },
                },
            }
        end

        -- alert
        if type(BFBM_DB.alert) ~= "table" then BFBM_DB.alert = {} end
        if not AF.IsToday(BFBM_DB.alert.created, true) then
            BFBM_DB.alert.servers = {
                -- [serverName] = {
                --     [itemID] = numBids,
                -- },
            }
            BFBM_DB.alert.created = GetServerTime()
        end

        -- my bids
        if type(BFBM_DB.myBids) ~= "table" then
            BFBM_DB.myBids = {
                -- [server] = {
                --     itemID = {bid, time},
                -- }
            }
        end
        for server, t in pairs(BFBM_DB.myBids) do
            for itemID, v in pairs(t) do
                if not AF.IsToday(v[2], true) then
                    BFBM_DB.myBids[server][itemID] = nil
                end
            end
        end

        -- auto wipe
        if BFBM_DB.config.autoWipeOutdatedServerData then
            for server, t in pairs(BFBM_DB.data.servers) do
                if not AF.IsToday(t.lastUpdate, true) then
                    BFBM_DB.data.servers[server] = nil
                end
            end
        end

        -- NOTE: cache is only for CN servers
        BFBM_DataUpload = nil
        if AF.portal == "CN" and LOCALE_zhCN then
            BFBM_DataUpload = {}
        end

        -- minimap button
        if type(BFBM_DB.minimap) ~= "table" then BFBM_DB.minimap = {} end
        AF.NewMinimapButton(BFBM.name, "Interface\\AddOns\\BFBlackMarket\\BFBM", BFBM_DB.minimap, BFBM.ToggleMainFrame, L["BFBlackMarket"])

    elseif addon == "Blizzard_BlackMarketUI" then
        BFBM:UnregisterEvent("ADDON_LOADED")

        -- title container button
        local button = AF.CreateButton(BlackMarketFrame, nil, "accent_hover", 20, 20)
        AF.SetPoint(button, "RIGHT", BlackMarketFrame.CloseButton, "LEFT", -5, 0)
        AF.SetTooltip(button, "TOP", 0, 5, L["BFBlackMarket"])
        button:SetTexture("Interface\\AddOns\\BFBlackMarket\\BFBM")
        button:SetOnClick(BFBM.ToggleMainFrame)

        if not BFBM_DB.blackMarketFrameHelpViewed then
            AF.ShowHelpTip({
                widget = button,
                position = "TOP",
                text = L["Click this button to open BFBlackMarket"],
                glow = true,
                callback = function()
                    BFBM_DB.blackMarketFrameHelpViewed = true
                end,
            })
        end
    end
end)

local function MergeConnectedRealmData()
    local temp

    for server, t in pairs(BFBM_DB.data.servers) do
        if AF.IsConnectedRealm(server) then
            if not temp or temp.lastUpdate < t.lastUpdate then
                temp = t
            end
            BFBM_DB.data.servers[server] = nil
        end
    end

    BFBM_DB.data.servers[AF.player.realm] = temp
end

local function MergeConnectedRealmDataCN()
    local newServer
    local serverData = {}

    for server, t in pairs(BFBM_DB.data.servers) do
        if LRI.HasConnectedRealm(server) then
            newServer = LRI.GetConnectedRealmName(server, true, true)
        else
            newServer = server
        end

        if not serverData[newServer] then
            serverData[newServer] = t
        elseif not serverData[newServer].lastUpdate or (t.lastUpdate and serverData[newServer].lastUpdate < t.lastUpdate) then
            serverData[newServer] = t
        end
    end

    BFBM_DB.data.servers = serverData
end

AF.RegisterCallback("AF_PLAYER_LOGIN", function()
    if AF.portal == "CN" then
        MergeConnectedRealmDataCN()
    else
        MergeConnectedRealmData()
    end

    -- current server
    if type(BFBM_DB.data.servers[AF.player.realm]) ~= "table" then
        BFBM_DB.data.servers[AF.player.realm] = {
            items = {},
            lastUpdate = nil,
        }
    end
    BFBM.currentServerData = BFBM_DB.data.servers[AF.player.realm]

    -- my bids
    if type(BFBM_DB.myBids[AF.player.realm]) ~= "table" then
        BFBM_DB.myBids[AF.player.realm] = {}
    end
    BFBM.currentServerBids = BFBM_DB.myBids[AF.player.realm]

    -- update data for send
    BFBM.UpdateDataForSend()
end)

---------------------------------------------------------------------
-- channel
---------------------------------------------------------------------
AF.RegisterTemporaryChannel(BFBM.channelName)
AF.BlockChatConfigFrameInteractionForChannel(BFBM.channelName)
AF.RegisterCallback("AF_JOIN_TEMP_CHANNEL", function(_, channelName, channelID)
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
    if msg == "reset" then
        BFBM_DB = nil
        ReloadUI()
    else
        BFBM.ToggleMainFrame()
    end
end

---------------------------------------------------------------------
-- addon button
---------------------------------------------------------------------
function BFBM_OnAddonCompartmentClick()
    BFBM.ToggleMainFrame()
end