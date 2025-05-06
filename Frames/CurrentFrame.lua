---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local BAG_ITEM_QUALITY_COLORS = BAG_ITEM_QUALITY_COLORS
local BIDS = BIDS
local DressUpLink = DressUpLink
local ChatEdit_ChooseBoxForSend = ChatEdit_ChooseBoxForSend
local IsControlKeyDown = IsControlKeyDown
local IsShiftKeyDown = IsShiftKeyDown

local currentFrame
local serverDropdown, itemList, noDataText, lastUpdateText
local updateRequired, LoadItems, LoadServerDropdown
local selectedServer

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateCurrentFrame()
    currentFrame = AF.CreateFrame(BFBMMainFrame, "BFBMCurrentFrame")
    AF.SetPoint(currentFrame, "TOPLEFT", BFBMMainFrame, 10, -40)
    AF.SetPoint(currentFrame, "BOTTOMRIGHT", BFBMMainFrame, -10, 7)

    currentFrame:SetOnShow(function()
        if updateRequired then
            LoadServerDropdown()
            LoadItems(selectedServer)
        end
    end)

    -- server dropdown
    serverDropdown = AF.CreateDropdown(currentFrame)
    serverDropdown:SetPoint("TOPLEFT")
    serverDropdown:SetPoint("TOPRIGHT")

    local servers = AF.GetKeys(BFBM_DB.data.servers)
    serverDropdown:SetOnClick(function(v)
        LoadItems(v)
    end)

    -- item list
    itemList = AF.CreateScrollList(currentFrame, nil, 5, 5, 6, 40, 5)
    AF.SetPoint(itemList, "TOPLEFT", serverDropdown, "BOTTOMLEFT", 0, -10)
    AF.SetPoint(itemList, "TOPRIGHT", serverDropdown, "BOTTOMRIGHT", 0, -10)

    -- no data text
    noDataText = AF.CreateFontString(itemList, AF.UpperEachWord(L["No data"]), "firebrick", "AF_FONT_TITLE")
    noDataText:SetPoint("CENTER")
    noDataText:Hide()

    -- last update text
    local tips = AF.CreateTipsButton(currentFrame)
    tips:SetPoint("BOTTOMRIGHT")
    tips:SetTips(L["Last Update"], L["Only update time when data changes"])

    lastUpdateText = AF.CreateFontString(currentFrame, nil, "gray")
    lastUpdateText:SetPoint("RIGHT", tips, "LEFT")
end

---------------------------------------------------------------------
-- item pane
---------------------------------------------------------------------
local TIME_LEFT = "AUCTION_TIME_LEFT%d"
local TIME_LEFT_DETAIL = "AUCTION_TIME_LEFT%d_DETAIL"

local function GetTimeLeftColor(timeLeft)
    if timeLeft == 0 then -- 完成！：拍卖已结束。
        return "darkgray"
    elseif timeLeft == 1 then -- 短：少于30分钟
        return "firebrick"
    elseif timeLeft == 2 then -- 中：30分钟到2小时
        return "orange"
    elseif timeLeft == 3 then -- 长：2小时到12小时
        return "sand"
    else -- 非常长：大于12小时
        return "white"
    end
end

local function Pane_OnEnter(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_highlight"))

    if BFBM_DB.config.requireCtrlForItemTooltips then
        AF.Tooltip:RequireModifier("ctrl")
    end
    AF.Tooltip:SetOwner(self, "ANCHOR_NONE")
    AF.Tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
    AF.Tooltip:SetItem(self.itemID)

    if self.t.timeLeft then
        AF.Tooltip2:SetOwner(self, "ANCHOR_NONE")
        AF.Tooltip2:SetPoint("TOPLEFT", self, "TOPRIGHT", 5, 0)
        AF.Tooltip2:AddLine(AF.WrapTextInColor(_G[TIME_LEFT:format(self.t.timeLeft)], "accent"))
        AF.Tooltip2:AddLine(AF.GetIconString("Clock_Round") .. " " .. AF.WrapTextInColor(_G[TIME_LEFT_DETAIL:format(self.t.timeLeft)], GetTimeLeftColor(self.t.timeLeft)))
        AF.Tooltip2:Show()
    end

    self.favorite:Show()
end

local function Pane_OnLeave(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_normal"))

    AF.Tooltip:Hide()
    AF.Tooltip2:Hide()

    if not self:IsMouseOver() and not BFBM_DB.favorites[self.itemID] then
        self.favorite:Hide()
    end
end

local function Pane_OnMouseUp(self)
    if IsControlKeyDown() then
        DressUpLink(self.t.link)
    elseif IsShiftKeyDown() then
        local editBox = ChatEdit_ChooseBoxForSend()
        if editBox:HasFocus() then
            editBox:Insert(self.t.link)
        end
    else
        BFBM.ShowDetailFrame(self.itemID)
    end
end

local function Pane_Load(self, itemID, t)
    -- texplore(t)
    self.itemID = itemID
    self.t = t

    self.icon:SetTexture(t.texture)
    self.name:SetText(t.name)
    self.type:SetText(t.itemType)

    -- bid
    local currBid = AF.FormatMoney(t.currBid, nil, true, true)
    local numBids = AF.WrapTextInColor(t.numBids == 0 and "" or (t.numBids .. " " .. BIDS), "gray")
    self.bid:SetText((t.currBid >= BFBM.MAX_BID and AF.WrapTextInColor(currBid, "firebrick") or currBid) .. " " .. numBids)

    -- quality
    if t.quality then
        local r, g, b = AF.GetItemQualityColor(t.quality)
        self.iconBG:SetVertexColor(r, g, b)
        self.name:SetTextColor(r, g, b)
    else
        self.iconBG:SetVertexColor(0, 0, 0)
        self.name:SetTextColor(1.0, 0.82, 0)
    end

    -- quantity
    if t.quantity and t.quantity > 1 then
        self.quantity:SetText(t.quantity)
    else
        self.quantity:SetText("")
    end

    -- favorite
    if BFBM_DB.favorites[itemID] then
        self.favorite:SetIcon(AF.GetIcon("Star_Filled"))
        self.favorite:SetColor(AF.GetColorTable("gold", 0.7))
        self.favorite:SetHoverColor("gold")
        self.favorite:Show()
    else
        self.favorite:SetIcon(AF.GetIcon("Star"))
        self.favorite:SetColor("darkgray")
        self.favorite:SetHoverColor("white")
        if not self:IsMouseOver() then
            self.favorite:Hide()
        end
    end

    -- time left
    self.timeLeft:SetColor(GetTimeLeftColor(t.timeLeft))
end

local itemPanePool = AF.CreateObjectPool(function()
    local pane = AF.CreateBorderedFrame(itemList.slotFrame, nil, nil, nil, "sheet_normal")
    pane:SetOnEnter(Pane_OnEnter)
    pane:SetOnLeave(Pane_OnLeave)
    pane:SetOnMouseUp(Pane_OnMouseUp)

    -- iconBG
    pane.iconBG = AF.CreateTexture(pane, AF.GetPlainTexture(), "black", "BORDER")
    AF.SetPoint(pane.iconBG, "TOPLEFT", 5, -5)
    AF.SetPoint(pane.iconBG, "BOTTOMRIGHT", pane, "BOTTOMLEFT", 35, 5)

    -- icon
    pane.icon = AF.CreateTexture(pane)
    AF.SetOnePixelInside(pane.icon, pane.iconBG)
    AF.ApplyDefaultTexCoord(pane.icon)

    -- timeLeft
    pane.timeLeft = AF.CreateTexture(pane, AF.GetIcon("Clock_Round"), nil, "OVERLAY", nil, nil, nil, "TRILINEAR")
    pane.timeLeft:SetPoint("TOPLEFT")
    AF.SetSize(pane.timeLeft, 14, 14)

    -- favorite
    pane.favorite = AF.CreateIconButton(pane, nil, 15, 15, 0, "darkgray", "darkgray")
    AF.SetPoint(pane.favorite, "TOPRIGHT", -4, -4)
    pane.favorite:Hide()
    pane.favorite:HookOnEnter(pane:GetOnEnter())
    pane.favorite:HookOnLeave(pane:GetOnLeave())
    pane.favorite:SetOnClick(function()
        if BFBM_DB.favorites[pane.itemID] then
            BFBM_DB.favorites[pane.itemID] = nil
            pane.favorite:SetIcon(AF.GetIcon("Star"))
            pane.favorite:SetColor("darkgray")
            pane.favorite:SetHoverColor("white")
        else
            BFBM_DB.favorites[pane.itemID] = true
            pane.favorite:SetIcon(AF.GetIcon("Star_Filled"))
            pane.favorite:SetColor(AF.GetColorTable("gold", 0.7))
            pane.favorite:SetHoverColor("gold")
        end
        -- refresh
        LoadItems(selectedServer)
        -- refresh history
        BFBM.UpdateHistoryItems()
    end)

    -- name
    pane.name = AF.CreateFontString(pane)
    pane.name:SetJustifyH("LEFT")
    pane.name:SetWordWrap(false)
    AF.SetPoint(pane.name, "TOPLEFT", pane.iconBG, "TOPRIGHT", 5, 0)
    AF.SetPoint(pane.name, "RIGHT", pane.favorite, "LEFT", -5, 0)

    -- quantity
    pane.quantity = AF.CreateFontString(pane, nil, "white", "AF_FONT_OUTLINE")
    pane.quantity:SetPoint("BOTTOMRIGHT", pane.icon, 1, 1)

    -- type
    pane.type = AF.CreateFontString(pane, nil, "gray")
    AF.SetPoint(pane.type, "BOTTOMRIGHT", -5, 5)

    -- bid
    pane.bid = AF.CreateFontString(pane)
    AF.SetPoint(pane.bid, "BOTTOMLEFT", pane.iconBG, "BOTTOMRIGHT", 5, 0)

    -- function
    pane.Load = Pane_Load

    return pane
end)

---------------------------------------------------------------------
-- load dropdown
---------------------------------------------------------------------
local function ServerComparator(a, b)
    -- current server
    if a[2] ~= b[2] then
        return a[2]
    end

    -- last update desc
    if a[3] ~= b[3] then
        return a[3] > b[3]
    end

    -- name asc
    return a[1] < b[1]
end

function LoadServerDropdown()
    local servers = {}
    local items = {}

    for server, t in pairs(BFBM_DB.data.servers) do
        table.insert(servers, {server, server == AF.player.realm, t.lastUpdate or 0})
    end
    table.sort(servers, ServerComparator)

    for i, v in ipairs(servers) do
        tinsert(items, {
            text = v[2] and AF.WrapTextInColor(v[1], "softlime") or v[1],
            value = v[1],
        })
    end

    serverDropdown:SetItems(items)
end

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
local function Comparator(a, b)
    -- favorite
    if BFBM_DB.favorites[a.itemID] ~= BFBM_DB.favorites[b.itemID] then
        return BFBM_DB.favorites[a.itemID]
    end

    -- time left
    if a.t.timeLeft ~= b.t.timeLeft then
        if a.t.timeLeft == 0 then
            return false -- completed
        elseif b.t.timeLeft == 0 then
            return true -- completed
        end
        return a.t.timeLeft < b.t.timeLeft
    end

    -- hot items
    if a.t.numBids ~= b.t.numBids then
        return a.t.numBids > b.t.numBids
    end

    -- current bid
    if a.t.currBid ~= b.t.currBid then
        return a.t.currBid > b.t.currBid
    end

    -- item name
    if a.t.name ~= b.t.name then
        return a.t.name < b.t.name
    end
end

LoadItems = function(server)
    selectedServer = server or selectedServer or AF.player.realm
    serverDropdown:SetSelectedValue(selectedServer)

    local data = BFBM_DB.data.servers[selectedServer]

    -- hide
    itemPanePool:ReleaseAll()

    -- load
    for itemID, t in pairs(data.items) do
        local pane = itemPanePool:Acquire()
        pane:Load(itemID, t)
    end

    -- sort
    local widgets = itemPanePool:GetAllActives()
    sort(widgets, Comparator)

    -- set
    itemList:SetWidgets(widgets)

    -- last update
    if data.lastUpdate then
        if AF.IsToday(data.lastUpdate, true) then
            lastUpdateText:SetText(AF.FormatTime(data.lastUpdate))
        else
            lastUpdateText:SetText(AF.WrapTextInColor(AF.FormatRelativeTime(data.lastUpdate), "firebrick"))
        end
        noDataText:Hide()
    else
        lastUpdateText:SetText(L["No data"])
        noDataText:Show()
    end
end

function BFBM.UpdateCurrentItems(server, force)
    if currentFrame and currentFrame:IsShown() then
        LoadServerDropdown()
    end

    if selectedServer ~= server and not force then
        updateRequired = true
        return
    end

    -- force
    selectedServer = server or selectedServer

    if currentFrame and currentFrame:IsShown() then
        local scroll = itemList:GetScroll()
        LoadItems(selectedServer)
        itemList:SetScroll(scroll) -- restore scroll position
    else
        updateRequired = true
    end
end

---------------------------------------------------------------------
-- open currentFrame
---------------------------------------------------------------------
function BFBM.OpenCurrentFrame(_, _, server, itemID)
    if not (server and itemID) then return end

    if not BFBMMainFrame:IsShown() then
        BFBM.ToggleMainFrame()
    end
    BFBMMainFrame.switch:SetSelectedValue("current")

    LoadItems(server)

    for i, pane in pairs(itemList.widgets) do
        if pane.itemID == itemID then
            itemList:SetScroll(i)
            break
        end
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFBM_ShowFrame", function(_, which)
    if which == "current" then
        if not currentFrame then
            CreateCurrentFrame()
            LoadServerDropdown()
            LoadItems()
        end
        currentFrame:Show()
    else
        if currentFrame then
            currentFrame:Hide()
        end
    end
end)