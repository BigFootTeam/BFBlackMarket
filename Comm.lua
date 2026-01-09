---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework
local LRI = LibStub("LibRealmInfoCN")

local BFBM_SEND_PREFIX = "BFBM_DATA"
local BFBM_REQ_PREFIX = "BFBM_REQ"
local BFBM_RESP_PREFIX = "BFBM_RESP"
local BFBM_CHK_VER_PREFIX = "BFBM_VER"

local InCombatLockdown = InCombatLockdown
local UnitExists = UnitExists
local UnitIsPlayer = UnitIsPlayer
local UnitIsConnected = UnitIsConnected
local TARGET_SEND_INTERVAL = 60 * 5

---------------------------------------------------------------------
-- data for send
---------------------------------------------------------------------
function BFBM.UpdateDataForSend()
    if not BFBM.currentServerData.lastUpdate or not AF.IsToday(BFBM.currentServerData.lastUpdate, true) then
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

    for itemID, t in pairs(BFBM.currentServerData.items) do
        data.items[itemID] = {
            quantity = t.quantity,
            currBid = t.currBid,
            numBids = t.numBids,
            timeLeft = t.timeLeft,
        }
    end

    -- texplore(data)
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
    if item and data then
        if not data._temp then data._temp = {} end
        data._temp[itemID] = {}
        local t = data._temp[itemID]
        t.name = item:GetItemName()
        t.link = item:GetItemLink()
        t.texture = item:GetItemIcon()
        t.quality = item:GetItemQuality()
        t.itemType = select(3, GetItemInfoInstant(itemID))
    end
end

local function OnDataProcessFinish(_, data)
    if not data._temp then return end
    for itemID, t in pairs(data.items) do
        if data._temp[itemID] then
            local temp = data._temp[itemID]
            t.name = temp.name
            t.link = temp.link
            t.texture = temp.texture
            t.quality = temp.quality
            t.itemType = temp.itemType
        end
    end
    data._temp = nil

    -- texplore(data)
    BFBM.UpdateLocalCache(data.server, data.lastUpdate, data.items)
end

local itemLoadExecutor = AF.BuildItemLoadExecutor(FillItemData, nil, OnDataProcessFinish)

local function ShouldProcess(server, lastUpdate, items)
    if not BFBM_DB.data.servers[server] then
        -- print("ShouldProcess: true, no local server data")
        return true
    elseif not BFBM_DB.data.servers[server].lastUpdate then
        -- print("ShouldProcess: true, no local lastUpdate")
        return true
    elseif BFBM_DB.data.servers[server].lastUpdate < lastUpdate then
        -- check if data changed
        local old = {}
        for itemID, t in pairs(BFBM_DB.data.servers[server].items) do
            old[itemID] = {
                numBids = t.numBids,
                timeLeft = t.timeLeft,
            }
        end

        for itemID, t in pairs(items) do
            if not old[itemID] or old[itemID].numBids ~= t.numBids or old[itemID].timeLeft ~= t.timeLeft then
                -- print("ShouldProcess: true, newer data")
                return true
            end
        end
    end
    -- print("ShouldProcess: false, older data")
end

local function DataReceived(data, sender)
    if sender == AF.player.name then return end -- ignore self

    if AF.IsEmpty(data) then return end -- empty data
    if type(data.version) ~= "number" or data.version < BFBM.minVersion then return end --version
    if type(data.server) ~= "string" then return end -- server
    if type(data.lastUpdate) ~= "number" or not AF.IsToday(data.lastUpdate, true) then return end -- today
    if type(data.items) ~= "table" or AF.IsEmpty(data.items) then return end -- items

    if AF.IsConnectedRealm(data.server) then
        -- NOTE: if connected realm, change to current server
        data.server = AF.player.realm
    else
        --! CN only
        -- NOTE: if a part of connected realm, change to the first connected realm
        local server = LRI.GetConnectedRealmName(data.server, true)
        if server then
            data.server = server
        end
    end

    if not ShouldProcess(data.server, data.lastUpdate, data.items) then return end -- process

    itemLoadExecutor:Submit(AF.GetKeys(data.items), data)
end

---------------------------------------------------------------------
-- sending/receiving (whisper, for Mists only)
---------------------------------------------------------------------
local targetLastRequest = {}
local targetLastSend = {}

function BFBM.RequestDataNeedDecisionForTarget()
    if InCombatLockdown() then return end
    if AF.IsBlank(BFBM.dataForSend) then return end

    if not (UnitExists("target") and UnitIsPlayer("target") and UnitIsConnected("target")) then return end
    if not AF.IsSameFaction("target") then return end

    local fullname = AF.UnitFullName("target")
    if not (fullname and AF.IsConnectedRealm(fullname)) then return end

    local lastRequest = targetLastRequest[fullname]
    if lastRequest and time() - lastRequest < TARGET_SEND_INTERVAL then return end
    targetLastRequest[fullname] = time()

    AF.SendCommMessage_Whisper(BFBM_REQ_PREFIX,
        {AF.player.realm, BFBM.currentServerData.lastUpdate}, AF.UnitFullName("target"))
end

local function RequestReceived(data, sender)
    if InCombatLockdown() then return end
    if AF.IsEmpty(data) then return end

    local server, lastUpdate = unpack(data)
    if type(server) ~= "string" or type(lastUpdate) ~= "number" then return end
    -- print("RequestReceived from", sender, "for", server, "lastUpdate", lastUpdate)
    -- lastUpdate = time() -- TEST

    local sendResp

    if not BFBM_DB.data.servers[server] then
        -- print("sendResp: no local data for", server)
        sendResp = true
    elseif not BFBM_DB.data.servers[server].lastUpdate or BFBM_DB.data.servers[server].lastUpdate < lastUpdate then
        -- print("sendResp: local data older for", server)
        sendResp = true
    else
        -- print("no need to send response to", sender)
    end

    if sendResp then
        AF.SendCommMessage_Whisper(BFBM_RESP_PREFIX, 1, sender)
    end
end

local function ResponseReceived(_, sender)
    if InCombatLockdown() then return end
    if AF.IsBlank(BFBM.dataForSend) then return end

    local lastSend = targetLastSend[sender]
    if lastSend and time() - lastSend < TARGET_SEND_INTERVAL then return end
    targetLastSend[sender] = time()

    -- print("ResponseReceived from", sender, "- sending data")

    AF.SendCommMessage_Whisper(BFBM_SEND_PREFIX, BFBM.dataForSend, sender)
end

if AF.isMists then
    BFBM:RegisterEvent("PLAYER_TARGET_CHANGED", BFBM.RequestDataNeedDecisionForTarget)
end

---------------------------------------------------------------------
-- instance receiving
---------------------------------------------------------------------
local function InstanceStateChange(_, info)
    if info.isIn then
        AF.UnregisterComm(BFBM_SEND_PREFIX)
        if AF.isMists then
            AF.UnregisterComm(BFBM_REQ_PREFIX)
            AF.UnregisterComm(BFBM_RESP_PREFIX)
        end
    else
        AF.RegisterComm(BFBM_SEND_PREFIX, DataReceived)
        if AF.isMists then
            AF.RegisterComm(BFBM_REQ_PREFIX, RequestReceived)
            AF.RegisterComm(BFBM_RESP_PREFIX, ResponseReceived)
        end
    end
end

function BFBM.DisableInstanceReceiving(disable)
    if disable then
        AF.RegisterCallback("AF_INSTANCE_STATE_CHANGE", InstanceStateChange)
        if AF.IsInInstance() then
            AF.UnregisterComm(BFBM_SEND_PREFIX)
            if AF.isMists then
                AF.UnregisterComm(BFBM_REQ_PREFIX)
                AF.UnregisterComm(BFBM_RESP_PREFIX)
            end
        end
    else
        AF.UnregisterCallback("AF_INSTANCE_STATE_CHANGE", InstanceStateChange)
        AF.RegisterComm(BFBM_SEND_PREFIX, DataReceived)
        if AF.isMists then
            AF.RegisterComm(BFBM_REQ_PREFIX, RequestReceived)
            AF.RegisterComm(BFBM_RESP_PREFIX, ResponseReceived)
        end
    end
end

---------------------------------------------------------------------
-- group joined
---------------------------------------------------------------------
local function GROUP_JOINED()
    BFBM.SendData("group")
end
BFBM:RegisterEvent("GROUP_JOINED", GROUP_JOINED)