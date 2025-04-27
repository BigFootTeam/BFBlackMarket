---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local GetHotItem = C_BlackMarket.GetHotItem
local GetNumItems = C_BlackMarket.GetNumItems
local GetItemInfoByIndex = C_BlackMarket.GetItemInfoByIndex
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetServerTime = GetServerTime

---------------------------------------------------------------------
-- scan and cache
---------------------------------------------------------------------
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
    BFBM.UpdateHistoryCache(BFBM.currentServerData.items)

    if dataChanged then
        -- NOTE: only update if data changed
        BFBM.currentServerData.lastUpdate = GetServerTime()
        -- current
        BFBM.UpdateCurrentItems(AF.player.realm)
        -- history
        BFBM.UpdateHistoryItems()
        -- send
        BFBM.UpdateDataForSend()
        BFBM.SendData("channel")
        BFBM.SendData("guild")
        -- favorites
        BFBM.AlertFavorites(AF.player.realm, BFBM.currentServerData.items)
        -- CN data
        BFBM.UpdateDataUpload(AF.player.realm, BFBM.currentServerData.lastUpdate, BFBM.currentServerData.items)
    end
end
BFBM:RegisterEvent("BLACK_MARKET_ITEM_UPDATE", AF.GetDelayedInvoker(0.5, BLACK_MARKET_ITEM_UPDATE))

---------------------------------------------------------------------
-- history
---------------------------------------------------------------------
function BFBM.UpdateHistoryCache(items, lastUpdate)
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
        if not BFBM_DB.data.items[itemID].history[AF.player.realm] then
            BFBM_DB.data.items[itemID].history[AF.player.realm] = {}
        end

        -- item history date
        local day = AF.GetDateString(lastUpdate)
        if not BFBM_DB.data.items[itemID].history[AF.player.realm][day] then
            BFBM_DB.data.items[itemID].history[AF.player.realm][day] = {
                bids = {},
                finalBid = nil,
            }
        end

        -- item history bids
        if not BFBM_DB.data.items[itemID].history[AF.player.realm][day].bids[numBids] then
            BFBM_DB.data.items[itemID].history[AF.player.realm][day].bids[numBids] = currBid
            BFBM_DB.data.items[itemID].lastUpdate = lastUpdate
        end

        -- item history final price
        if currBid >= BFBM.MAX_BID or timeLeft == 0  then
            BFBM_DB.data.items[itemID].history[AF.player.realm][day].finalBid = currBid
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
    BFBM.UpdateHistoryCache(items, lastUpdate)

    -- current
    BFBM.UpdateCurrentItems(server)
    -- history
    BFBM.UpdateHistoryItems()
    -- send
    BFBM.UpdateDataForSend()
    -- favorites
    BFBM.AlertFavorites(server, items)
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
        if BFBM_DB.favorites[itemID] and BFBM_DB.alert.servers[server][itemID] ~= t.numBids then
            BFBM_DB.alert.servers[server][itemID] = t.numBids
            local currBid = AF.FormatMoney(t.currBid, nil, true, true)
            local text = L["%s is on the Black Market!\nCurrent bid: %s\nServer: %s"]:format(t.link, currBid, server)
            AF.ShowNotificationPopup(text, 60, t.texture, AF.GetSound("notification1"), 270, "LEFT", BFBM.OpenCurrentFrame, server, itemID)
        end
    end
end
        end
    end
end

---------------------------------------------------------------------
-- data for upload
---------------------------------------------------------------------
function BFBM.UpdateDataUpload(server, lastUpdate, items)
    if type(BFBM_DataUpload) ~= "table" then return end

    BFBM_DataUpload[server] = {
        Server = server,
        LastUpdate = lastUpdate,
        Items = {},
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
            TimeLeft = t.timeLeft,
        })
    end
end