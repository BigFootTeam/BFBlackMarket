---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local BFBM_SEND_PREFIX = "BFBM_DATA"
local BFBM_CHK_VER_PREFIX = "BFBM_VER"

---------------------------------------------------------------------
-- data for send
---------------------------------------------------------------------
function BFBM.UpdateDataForSend()
    if not BFBM.currentServerData.lastUpdate or not AF.IsToday(BFBM.currentServerData.lastUpdate) then
        -- no data or not today
        BFBM.dataForSend = ""
        return
    end

    local data = {
        version = BFBM.versionNum,
        server = AF.player.realm,
        lastUpdate = BFBM.currentServerData.lastUpdate,
        items = {},
    }

    for _, t in pairs(BFBM.currentServerData.items) do
        tinsert(data.items, {
            itemID = t.itemID,
            quantity = t.quantity,
            minBid = t.minBid,
            currBid = t.currBid,
            numBids = t.numBids,
            timeLeft = t.timeLeft,
        })
    end

    BFBM.dataForSend = AF.Serialize(data, true)
end

---------------------------------------------------------------------
-- version check
---------------------------------------------------------------------
local function VersionCheckReceived(version)
    if type(version) == "number" and version > BFBM.versionNum and (not BFBM_DB.lastVersionCheck or time() - BFBM_DB.lastVersionCheck >= 3600) then
        BFBM_DB.lastVersionCheck = time()
        AF.Print(L["New version (%s) available! Please consider updating."]:format("r" .. version))
    end
end
AF.RegisterComm(BFBM_CHK_VER_PREFIX, VersionCheckReceived)

function BFBM.BroadcastVersion()
    if BFBM.channelID == 0 then return end
    AF.SendCommMessage_Channel(BFBM_CHK_VER_PREFIX, BFBM.versionNum, BFBM.channelName)
end

---------------------------------------------------------------------
-- sending
---------------------------------------------------------------------
function BFBM.SendData(channel)
    if AF.IsBlank(BFBM.dataForSend) then return end

    if channel == "guild" then
        AF.SendCommMessage_Guild(BFBM_SEND_PREFIX, BFBM.dataForSend, nil, nil, nil, nil, true)
    elseif channel == "channel" then
        AF.SendCommMessage_Channel(BFBM_SEND_PREFIX, BFBM.dataForSend, BFBM.channelName, nil, nil, nil, true)
    elseif channel == "group" then
        AF.SendCommMessage_Group(BFBM_SEND_PREFIX, BFBM.dataForSend, nil, nil, nil, true)
    end
end

---------------------------------------------------------------------
-- receiving
---------------------------------------------------------------------
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local function FillItemData(_, item, itemID, _, _, data)
    if item then
        if not data._temp then data._temp = {} end
        data._temp[itemID] = {}
        local t = data._temp[itemID]
        t.name = item:GetItemName()
        t.link = item:GetItemLink()
        t.texture = item:GetItemIcon()
        t.quality = item:GetItemQuality()
        t.itemType = select(2, GetItemInfoInstant(itemID))
    end
end

local function OnDataProcessFinish(_, data)
    if not data._temp then return end
    for _, t in pairs(data.items) do
        if data._temp[t.itemID] then
            local temp = data._temp[t.itemID]
            t.name = temp.name
            t.link = temp.link
            t.texture = temp.texture
            t.quality = temp.quality
            t.itemType = temp.itemType
        end
    end
    data._temp = nil

    -- texplore(data)
    local server = data.server
    if AF.IsConnectedRealm(server) then
        -- NOTE: if connected realm, change to current server
        server = AF.player.realm
    end
    BFBM.UpdateLocalCache(server, data.lastUpdate, data.items)
end

local itemLoadExecutor = AF.BuildItemLoadExecutor(FillItemData, nil, OnDataProcessFinish)

local function ShouldProcess(server, lastUpdate)
    return not BFBM_DB.data.servers[server] or not BFBM_DB.data.servers[server].lastUpdate or BFBM_DB.data.servers[server].lastUpdate < lastUpdate
end

local function DataReceived(data, sender)
    if sender == AF.player.name then return end -- ignore self

    if AF.IsEmpty(data) then return end -- empty data
    if type(data.version) ~= "number" or data.version < BFBM.minVersion then return end --version
    if type(data.server) ~= "string" then return end -- server
    if type(data.lastUpdate) ~= "number" or not AF.IsToday(data.lastUpdate) then return end -- today
    if not ShouldProcess(data.server, data.lastUpdate) then return end -- process
    if type(data.items) ~= "table" or #data.items == 0 then return end -- items

    itemLoadExecutor:Submit(AF.ExtractSubTableValues(data.items, "itemID"), data)
end

---------------------------------------------------------------------
-- instance receiving
---------------------------------------------------------------------
local function EnterInstance()
    AF.UnregisterComm(BFBM_SEND_PREFIX, DataReceived)
end

local function LeaveInstance()
    AF.RegisterComm(BFBM_SEND_PREFIX, DataReceived)
end

function BFBM.DisableInstanceReceiving(disable)
    if disable then
        AF.RegisterCallback("AF_INSTANCE_ENTER", EnterInstance)
        AF.RegisterCallback("AF_INSTANCE_LEAVE", LeaveInstance)
    else
        AF.UnregisterCallback("AF_INSTANCE_ENTER", EnterInstance)
        AF.UnregisterCallback("AF_INSTANCE_LEAVE", LeaveInstance)
        AF.RegisterComm(BFBM_SEND_PREFIX, DataReceived)
    end
end

---------------------------------------------------------------------
-- group joined
---------------------------------------------------------------------
local function GROUP_JOINED()
    BFBM.SendData("group")
end
BFBM:RegisterEvent("GROUP_JOINED", GROUP_JOINED)