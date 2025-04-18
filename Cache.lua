---@class BFBM
local BFBM = select(2, ...)
---@type AbstractFramework
local AF = _G.AbstractFramework

local GetHotItem = C_BlackMarket.GetHotItem
local GetNumItems = C_BlackMarket.GetNumItems
local GetItemInfoByIndex = C_BlackMarket.GetItemInfoByIndex
local GetItemInfoInstant = C_Item.GetItemInfoInstant
local GetServerTime = GetServerTime

local function BLACK_MARKET_ITEM_UPDATE()
    local numItems = GetNumItems()
    if not numItems or numItems == 0 then
        return
    end

    wipe(BFBM.currentServerData.items)
    BFBM.currentServerData.lastUpdate = GetServerTime()

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
        tinsert(BFBM.currentServerData.items, {
            itemID = itemID,
            name = name,
            texture = texture,
            quantity = quantity,
            quality = quality,
            itemType = itemType,
            -- usable = usable,
            -- level = level,
            -- levelType = levelType,
            -- sellerName = sellerName,
            minBid = minBid,
            minIncrement = minIncrement,
            currBid = currBid,
            -- youHaveHighBid = youHaveHighBid,
            numBids = numBids,
            timeLeft = timeLeft,
            link = link,
            -- marketID = marketID,
            -- isHot = marketID == hotMarketID,
        })

        -- update history
        if not BFBM_DB.data.items[itemID] then
            BFBM_DB.data.items[itemID] = {
                name = name,
                texture = texture,
                link = link,
                quality = quality,
                -- quantity = quantity,
                itemType = itemType,
                history = {},
            }
        end
        BFBM_DB.data.items[itemID].lastUpdate = GetServerTime()

        -- item history server
        if not BFBM_DB.data.items[itemID].history[AF.player.realm] then
            BFBM_DB.data.items[itemID].history[AF.player.realm] = {}
        end

        -- item history date
        local day = AF.GetDateString()
        if not BFBM_DB.data.items[itemID].history[AF.player.realm][day] then
            BFBM_DB.data.items[itemID].history[AF.player.realm][day] = {
                bids = {},
                finalBid = nil,
            }
        end

        -- fix 0 bid
        if currBid == 0 then
            currBid = minBid
        end

        -- item history bids
        BFBM_DB.data.items[itemID].history[AF.player.realm][day].bids[numBids] = currBid

        -- item history final price
        if currBid >= BFBM.MAX_BID then
            BFBM_DB.data.items[itemID].history[AF.player.realm][day].finalBid = currBid
        elseif timeLeft == 0 then
            BFBM_DB.data.items[itemID].history[AF.player.realm][day].finalBid = currBid
        end
    end

    BFBM.UpdateCurrentItems(AF.player.realm)

    -- TODO: communication
end
BFBM:RegisterEvent("BLACK_MARKET_ITEM_UPDATE", AF.GetDelayedInvoker(0.5, BLACK_MARKET_ITEM_UPDATE))