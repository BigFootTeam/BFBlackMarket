---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local SEND_INTERVAL = 99

local GetHotItem = C_BlackMarket.GetHotItem
local GetNumItems = C_BlackMarket.GetNumItems
local GetItemInfoByIndex = C_BlackMarket.GetItemInfoByIndex
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetServerTime = GetServerTime

---------------------------------------------------------------------
-- scan and cache
---------------------------------------------------------------------
local lastSent
local function BLACK_MARKET_ITEM_UPDATE()
    local numItems = GetNumItems()
    if not numItems or numItems == 0 then
        return
    end

    -- old
    local lastScanned = {}
    for itemID, t in pairs(BFBM.currentServerData.items) do
        lastScanned[itemID] = {
            numBids = t.numBids,
            timeLeft = t.timeLeft,
        }
    end
    wipe(BFBM.currentServerData.items)

    local dataChanged

    -- local hotMarketID = select(16, GetHotItem())

    -- AUCTION_TIME_LEFT0          完成！
    -- AUCTION_TIME_LEFT0_DETAIL   拍卖已结束。
    -- AUCTION_TIME_LEFT1          短
    -- AUCTION_TIME_LEFT1_DETAIL   少于30分钟
    -- AUCTION_TIME_LEFT2          中
    -- AUCTION_TIME_LEFT2_DETAIL   30分钟到2小时
    -- AUCTION_TIME_LEFT3          长
    -- AUCTION_TIME_LEFT3_DETAIL   2小时到12小时
    -- AUCTION_TIME_LEFT4          非常长
    -- AUCTION_TIME_LEFT4_DETAIL   大于12小时

    for i = 1, numItems do
        local name, texture, quantity, itemType, usable, level, levelType, sellerName, minBid, minIncrement, currBid, youHaveHighBid, numBids, timeLeft, link, marketID, quality = GetItemInfoByIndex(i)
        local itemID = GetItemInfoInstant(link)

        -- update favorite
        if youHaveHighBid then
            BFBM_DB.favorites[itemID] = true
            BFBM.currentServerBids[itemID] = {currBid, GetServerTime()}
        end

        -- update BFBM_DB.data
        BFBM.currentServerData.items[itemID] = {
            -- itemID = itemID,
            name = name,
            texture = texture,
            quantity = quantity,
            quality = quality,
            itemType = itemType,
            -- usable = usable,
            -- level = level,
            -- levelType = levelType,
            -- sellerName = sellerName,
            -- minBid = minBid,
            -- minIncrement = minIncrement,
            currBid = currBid == 0 and minBid or currBid,
            -- youHaveHighBid = youHaveHighBid,
            numBids = numBids,
            timeLeft = timeLeft,
            link = link,
            -- marketID = marketID,
            -- isHot = marketID == hotMarketID,
        }

        -- check if data changed
        if not lastScanned[itemID] or lastScanned[itemID].numBids ~= numBids or lastScanned[itemID].timeLeft ~= timeLeft then
            dataChanged = true
        end
    end

    -- update history
    BFBM.UpdateHistoryCache(AF.player.realm, nil, BFBM.currentServerData.items)

    if dataChanged then
        -- NOTE: only update if data changed
        BFBM.currentServerData.lastUpdate = GetServerTime()
        -- current
        BFBM.UpdateCurrentItems(AF.player.realm, true)
        -- history
        BFBM.UpdateHistoryItems()
        -- favorites
        BFBM.AlertFavorites(AF.player.realm, BFBM.currentServerData.items)
        -- CN data
        BFBM.UpdateDataUpload(AF.player.realm, BFBM.currentServerData.lastUpdate, BFBM.currentServerData.items)
    end

    if dataChanged or not lastSent or time() - lastSent >= SEND_INTERVAL then
        lastSent = time()
        -- send
        BFBM.UpdateDataForSend()
        BFBM.SendData("channel")
        BFBM.SendData("guild")
        BFBM.SendData("group")
    end
end
BFBM:RegisterEvent("BLACK_MARKET_ITEM_UPDATE", AF.GetDelayedInvoker(0.5, BLACK_MARKET_ITEM_UPDATE))

---------------------------------------------------------------------
-- history
---------------------------------------------------------------------
function BFBM.UpdateHistoryCache(server, lastUpdate, items)
    lastUpdate = lastUpdate or GetServerTime()

    for itemID, t in pairs(items) do
        local name = t.name
        local texture = t.texture
        local link = t.link
        local quality = t.quality
        local itemType = t.itemType
        local currBid = t.currBid
        local numBids = t.numBids
        local timeLeft = t.timeLeft

        if not BFBM_DB.data.items[itemID] then
            BFBM_DB.data.items[itemID] = {
                name = name,
                texture = texture,
                link = link,
                quality = quality,
                itemType = itemType,
                history = {},
            }
        end

        -- item history server
        if not BFBM_DB.data.items[itemID].history[server] then
            BFBM_DB.data.items[itemID].history[server] = {}
        end

        -- item history date
        local day = AF.GetDateString(lastUpdate)
        if not BFBM_DB.data.items[itemID].history[server][day] then
            BFBM_DB.data.items[itemID].history[server][day] = {
                bids = {},
                finalBid = nil,
            }
        end

        local changed

        -- item history bids
        if not BFBM_DB.data.items[itemID].history[server][day].bids[numBids] then
            BFBM_DB.data.items[itemID].history[server][day].bids[numBids] = currBid
            BFBM_DB.data.items[itemID].lastUpdate = lastUpdate
            changed = true
        end

        -- item history final price
        if not BFBM_DB.data.items[itemID].history[server][day].finalBid and (currBid >= BFBM.MAX_BID or timeLeft == 0) then
            BFBM_DB.data.items[itemID].history[server][day].finalBid = currBid
            changed = true
        end

        if changed then
            AF.Fire("BFBM_ITEM_HISTORY_UPDATE", server, lastUpdate, itemID)
        end
    end
end

---------------------------------------------------------------------
-- update local cache
---------------------------------------------------------------------
function BFBM.UpdateLocalCache(server, lastUpdate, items)
    -- update BFBM_DB.data.servers
    if not BFBM_DB.data.servers[server] then
        -- print("UpdateLocalCache: SAVE RECEIVED DATA")
        BFBM_DB.data.servers[server] = {
            items = items,
            lastUpdate = lastUpdate,
        }

    elseif not BFBM_DB.data.servers[server].lastUpdate or BFBM_DB.data.servers[server].lastUpdate < lastUpdate then
        -- print("UpdateLocalCache: UPDATE USING RECEIVED DATA")

        BFBM_DB.data.servers[server].items = items
        BFBM_DB.data.servers[server].lastUpdate = lastUpdate

    else
        -- print("UpdateLocalCache: RECEIVED DATA OLDER THAN LOCAL")
        return
    end

    -- update BFBM_DB.data.items
    BFBM.UpdateHistoryCache(server, lastUpdate, items)

    -- current
    BFBM.UpdateCurrentItems(server)
    -- history
    BFBM.UpdateHistoryItems()
    -- send
    BFBM.UpdateDataForSend()
    -- favorites
    BFBM.AlertFavorites(server, items)
    -- chat alerts
    BFBM.ShowChatAlerts(server)
    -- CN data
    BFBM.UpdateDataUpload(server, lastUpdate, items)
end

---------------------------------------------------------------------
-- alert favorites
---------------------------------------------------------------------
function BFBM.AlertFavorites(server, items)
    if not BFBM_DB.config.priceChangeAlerts then return end
    if not BFBM_DB.alert.servers[server] then
        BFBM_DB.alert.servers[server] = {}
    end

    for itemID, t in pairs(items) do
        if BFBM_DB.favorites[itemID] then
            if BFBM_DB.myBids[server] and BFBM_DB.myBids[server][itemID] then
                if BFBM_DB.myBids[server][itemID][1] < t.currBid then
                    BFBM_DB.myBids[server][itemID] = nil
                    -- be outbid
                    local currBid = AF.FormatMoney(t.currBid, nil, true, true)
                    local text = L["%s\nYou've been outbid!\nCurrent bid: %s\nServer: %s"]:format(t.link, currBid, server)
                    AF.ShowNotificationPopup(text, 60, t.texture, AF.GetSound("notification1"), 220, "LEFT", BFBM.OpenCurrentFrame, server, itemID)
                end
            elseif BFBM_DB.alert.servers[server][itemID] == nil then
                -- first seen today
                local currBid = AF.FormatMoney(t.currBid, nil, true, true)
                local text = L["%s\nis on the Black Market!\nCurrent bid: %s\nServer: %s"]:format(t.link, currBid, server)
                AF.ShowNotificationPopup(text, 60, t.texture, AF.GetSound("notification1"), 220, "LEFT", BFBM.OpenCurrentFrame, server, itemID)
            elseif BFBM_DB.alert.servers[server][itemID] ~= t.numBids then
                -- bid changed
                local currBid = AF.FormatMoney(t.currBid, nil, true, true)
                local text = L["%s\nThe bid price has changed!\nCurrent bid: %s\nServer: %s"]:format(t.link, currBid, server)
                AF.ShowNotificationPopup(text, 60, t.texture, AF.GetSound("notification1"), 220, "LEFT", BFBM.OpenCurrentFrame, server, itemID)
            end
            BFBM_DB.alert.servers[server][itemID] = t.numBids
        end
    end
end

---------------------------------------------------------------------
-- chat alerts
---------------------------------------------------------------------
function BFBM.ShowChatAlerts(server)
    if BFBM_DB.config.chatAlerts == "all" or (BFBM_DB.config.chatAlerts == "current" and AF.IsConnectedRealm(server)) then
        if AF.IsConnectedRealm(server) then
            server = AF.WrapTextInColor(server, "softlime")
        else
            server = AF.WrapTextInColor(server, "yellow_text")
        end
        AF.Print(L["%s data updated, check %s to view details!"]:format(server, AF.WrapTextInColor(L["BFBlackMarket"], "accent")))
    end
end

---------------------------------------------------------------------
-- data for upload
---------------------------------------------------------------------
local function GetBigFootClientVersion(wowProjectID)
    wowProjectID = wowProjectID or WOW_PROJECT_ID
    if wowProjectID == WOW_PROJECT_MAINLINE then -- 正式服
        return 0
    elseif wowProjectID == WOW_PROJECT_CLASSIC then -- 经典60
        return 1
    elseif wowProjectID == WOW_PROJECT_WRATH_CLASSIC then -- 巫妖王
        return 3
    else -- 大灾变
        return 2
    end
end

function BFBM.UpdateDataUpload(server, lastUpdate, items)
    if type(BFBM_DataUpload) ~= "table" then return end

    BFBM_DataUpload[server] = {
        Server = server,
        LastUpdate = lastUpdate,
        Items = {},
        ClientVersion = GetBigFootClientVersion(),
    }

    for itemID, t in pairs(items) do
        tinsert(BFBM_DataUpload[server].Items, {
            ID = itemID,
            Name = t.name,
            Type = t.itemType,
            Quality = t.quality,
            IconFileDataID = t.texture,
            CurrentBid = t.currBid,
            NumBids = t.numBids,
            TimeLeft = t.timeLeft == 0 and 5 or t.timeLeft,
        })
    end
end