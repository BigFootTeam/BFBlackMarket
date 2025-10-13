---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework
local LRI = LibStub("LibRealmInfoCN")

local detailFrame
local LoadData

---------------------------------------------------------------------
-- create frame
---------------------------------------------------------------------
local function CreateDetailFrame()
    detailFrame = AF.CreateBorderedFrame(BFBMMainFrame, "BFBMDetailFrame", 350, 202)
    AF.SetPoint(detailFrame, "TOPLEFT", BFBMMainFrame, "TOPRIGHT", 5, -70)

    detailFrame:SetOnHide(function()
        detailFrame:Hide()
    end)

    -- icon
    local iconBG = AF.CreateTexture(detailFrame, nil, "black", "BORDER")
    detailFrame.iconBG = iconBG
    AF.SetPoint(iconBG, "TOPLEFT", detailFrame, "TOPLEFT", 5, -5)
    AF.SetSize(iconBG, 20, 20)

    local icon = AF.CreateTexture(detailFrame, nil, nil, "ARTWORK")
    detailFrame.icon = icon
    AF.ApplyDefaultTexCoord(icon)
    AF.SetOnePixelInside(icon, iconBG)

    -- name
    local name = AF.CreateEditBox(detailFrame, nil, 215, 20)
    detailFrame.name = name
    AF.SetPoint(name, "TOPLEFT", iconBG, "TOPRIGHT", 5, 0)
    name:SetNotUserChangable(true)

    -- id
    local id = AF.CreateEditBox(detailFrame, nil, 70, 20)
    detailFrame.id = id
    AF.SetPoint(id, "TOPLEFT", name, "TOPRIGHT", 5, 0)
    id:SetNotUserChangable(true)

    -- close
    local closeBtn = AF.CreateCloseButton(detailFrame, nil, 20, 20)
    AF.SetPoint(closeBtn, "TOPLEFT", id, "TOPRIGHT", 5, 0)

    -- list
    local list = AF.CreateScrollList(detailFrame, nil, 2, 2, 7, 20, 1)
    detailFrame.list = list
    AF.SetPoint(list, "TOPLEFT", iconBG, "BOTTOMLEFT", 0, -5)
    AF.SetPoint(list, "RIGHT", -5, 0)

    -- status
    local status = AF.CreateFontString(detailFrame, nil, "gray")
    detailFrame.status = status
    AF.SetPoint(status, "TOPRIGHT", list, "BOTTOMRIGHT", 0, -5)
end

---------------------------------------------------------------------
-- list widget
---------------------------------------------------------------------
local function W_OnEnter(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_highlight"))
end

local function W_OnLeave(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_normal"))
end

local pool = AF.CreateObjectPool(function()
    local w = AF.CreateBorderedFrame(detailFrame.list.slotFrame, nil, nil, nil, "sheet_normal")
    w:SetOnEnter(W_OnEnter)
    w:SetOnLeave(W_OnLeave)

    -- server
    local server = AF.CreateFontString(w)
    w.server = server
    AF.SetPoint(server, "LEFT", 5, 0)
    server:SetWordWrap(false)
    server:SetJustifyH("LEFT")
    AF.SetWidth(server, 130)

    -- current bid
    local currBid = AF.CreateFontString(w)
    w.currBid = currBid
    AF.SetPoint(currBid, "LEFT", server, "RIGHT", 5, 0)
    currBid:SetWordWrap(false)
    currBid:SetJustifyH("LEFT")
    AF.SetWidth(currBid, 100)

    -- last seen
    local lastSeenDate = AF.CreateFontString(w)
    w.lastSeenDate = lastSeenDate
    AF.SetPoint(lastSeenDate, "RIGHT", -5, 0)
    lastSeenDate:SetWordWrap(false)
    lastSeenDate:SetJustifyH("LEFT")

    return w
end)

---------------------------------------------------------------------
-- merge
---------------------------------------------------------------------
local function MergeConnectedRealmData(itemID)
    if BFBM_DB.data.items[itemID].lastMerge == BFBM_DB.data.items[itemID].lastUpdate then
        return
    end
    BFBM_DB.data.items[itemID].lastMerge = BFBM_DB.data.items[itemID].lastUpdate

    local history = BFBM_DB.data.items[itemID].history
    local merged = {}

    for server, ht in pairs(history) do
        local newServer
        if AF.IsConnectedRealm(server) then
            newServer = AF.player.realm
        else
            newServer = server
        end

        if not merged[newServer] then
            merged[newServer] = ht
        else
            AF.Merge(merged[newServer], ht)
        end
    end

    BFBM_DB.data.items[itemID].history = merged
end

local function MergeConnectedRealmDataCN(itemID)
    if BFBM_DB.data.items[itemID].lastMerge == BFBM_DB.data.items[itemID].lastUpdate then
        return
    end
    BFBM_DB.data.items[itemID].lastMerge = BFBM_DB.data.items[itemID].lastUpdate

    local history = BFBM_DB.data.items[itemID].history
    local merged = {}

    for server, ht in pairs(history) do
        if LRI.HasConnectedRealm(server) then
            newServer = LRI.GetConnectedRealmName(server, true, true)
        else
            newServer = server
        end

        if not merged[newServer] then
            merged[newServer] = ht
        else
            AF.Merge(merged[newServer], ht)
        end
    end

    BFBM_DB.data.items[itemID].history = merged
end

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
LoadData = function(itemID)
    local t = BFBM_DB.data.items[itemID]
    if not t then
        detailFrame:Hide()
        return
    end

    detailFrame.itemID = itemID
    detailFrame.icon:SetTexture(t.texture)
    detailFrame.name:SetText(t.name)
    detailFrame.name:SetCursorPosition(0)
    detailFrame.id:SetText(itemID)
    detailFrame.id:SetCursorPosition(0)

    if t.quality then
        local r, g, b = AF.GetItemQualityColor(t.quality)
        detailFrame.iconBG:SetColorTexture(r, g, b)
        detailFrame.name:SetTextColor(r, g, b)
    else
        detailFrame.iconBG:SetColorTexture(0, 0, 0)
        detailFrame.name:SetTextColor(1.0, 0.82, 0)
    end

    pool:ReleaseAll()

    local today = AF.GetDateString()
    local count = 0

    -- merge
    if AF.portal == "CN" then
        MergeConnectedRealmDataCN(itemID)
    else
        MergeConnectedRealmData(itemID)
    end

    for server, st in pairs(t.history) do
        local lastSeenDate, lastSeenInfo = AF.GetMaxKeyValue(st)

        local _, lastBid = AF.GetMaxKeyValue(lastSeenInfo.bids)
        lastBid = lastSeenInfo.finalBid or lastBid

        local w = pool:Acquire()
        w.server:SetText(server .. (LRI.HasConnectedRealm(server) and "*" or ""))
        w.currBid:SetText(AF.FormatMoney(lastBid, nil, true, true))
        w.lastSeenDate:SetText(AF.FormatTime(AF.GetDateSeconds(lastSeenDate), "%Y/%m/%d"))

        w.sortKey2 = lastSeenDate

        if lastSeenDate == today then
            count = count + 1
            if server == AF.player.realm then
                w.sortKey1 = 2
                w.server:SetTextColor(AF.GetColorRGB("softlime"))
                w.currBid:SetTextColor(AF.GetColorRGB("softlime"))
                w.lastSeenDate:SetTextColor(AF.GetColorRGB("softlime"))
            else
                w.sortKey1 = 1
                w.server:SetTextColor(AF.GetColorRGB("white"))
                w.currBid:SetTextColor(AF.GetColorRGB("white"))
                w.lastSeenDate:SetTextColor(AF.GetColorRGB("white"))
            end
        else
            w.sortKey1 = 0
            w.server:SetTextColor(AF.GetColorRGB("darkgray"))
            w.currBid:SetTextColor(AF.GetColorRGB("darkgray"))
            w.lastSeenDate:SetTextColor(AF.GetColorRGB("darkgray"))
        end
    end

    local widgets = pool:GetAllActives()
    AF.Sort(widgets, "sortKey1", "descending", "sortKey2", "descending")
    detailFrame.list:SetWidgets(widgets)
    detailFrame.status:SetText(L["Available on %s servers"]:format(count))

    detailFrame:Show()
end

---------------------------------------------------------------------
-- toggle
---------------------------------------------------------------------
function BFBM.ShowDetailFrame(itemID)
    if not detailFrame then
        CreateDetailFrame()
    end
    LoadData(itemID)
end

---------------------------------------------------------------------
-- callback
---------------------------------------------------------------------
AF.RegisterCallback("BFBM_ITEM_HISTORY_UPDATE", function(_, server, lastUpdate, itemID)
    if detailFrame and detailFrame:IsShown() and detailFrame.itemID == itemID then
        LoadData(itemID)
    end
end)