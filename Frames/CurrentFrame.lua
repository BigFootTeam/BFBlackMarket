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
local serverDropdown, itemList
local updateRequired, LoadItems
local isCurrentServerSelected, selectedServer

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateCurrentFrame()
    currentFrame = AF.CreateFrame(BFBMMainFrame, "BFBMCurrentFrame")
    AF.SetPoint(currentFrame, "TOPLEFT", BFBMMainFrame, 10, -40)
    AF.SetPoint(currentFrame, "BOTTOMRIGHT", BFBMMainFrame, -10, 10)

    currentFrame:SetOnShow(function()
        if updateRequired then
            LoadItems()
        end
    end)

    -- server dropdown
    serverDropdown = AF.CreateDropdown(currentFrame)
    serverDropdown:SetPoint("TOPLEFT")
    serverDropdown:SetPoint("TOPRIGHT")

    local servers = AF.GetKeys(BFBM_DB.data.servers)
    tinsert(servers, 1, L["Current Server"])
    serverDropdown:SetItems(servers)
    serverDropdown:SetOnClick(function(v)
        LoadItems(v)
    end)

    -- item list
    itemList = AF.CreateScrollList(currentFrame, nil, 5, 5, 6, 40, 5)
    AF.SetPoint(itemList, "TOPLEFT", serverDropdown, "BOTTOMLEFT", 0, -10)
    AF.SetPoint(itemList, "TOPRIGHT", serverDropdown, "BOTTOMRIGHT", 0, -10)
end

---------------------------------------------------------------------
-- item pane
---------------------------------------------------------------------
local function Pane_OnEnter(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_highlight"))

    AF.IconTooltip:SetOwner(self, "ANCHOR_NONE")
    AF.IconTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
    AF.IconTooltip:SetItem(self.t.itemID)

    self.favorite:Show()
end

local function Pane_OnLeave(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_normal"))

    AF.IconTooltip:Hide()

    if not self:IsMouseOver() and not BFBM_DB.favorites[self.t.itemID] then
        self.favorite:Hide()
    end
end

local function Pane_Load(self, t)
    -- texplore(t)
    self.t = t

    self.icon:SetTexture(t.texture)
    self.name:SetText(t.name)
    self.type:SetText(t.itemType)

    local currBid = AF.FormatMoney(t.currBid == 0 and t.minBid or t.currBid, nil, true, true)
    local numBids = AF.WrapTextInColor(t.numBids == 0 and "" or (t.numBids .. " " .. BIDS), "gray")
    self.bid:SetText(currBid .. " " .. numBids)

    if t.quality then
        local r, g, b = AF.GetItemQualityColor(t.quality)
        self.iconBG:SetVertexColor(r, g, b)
        self.name:SetTextColor(r, g, b)
    else
        self.iconBG:SetVertexColor(0, 0, 0)
        self.name:SetTextColor(1.0, 0.82, 0)
    end

    if t.quantity and t.quantity > 1 then
        self.quantity:SetText(t.quantity)
    else
        self.quantity:SetText("")
    end

    if BFBM_DB.favorites[t.itemID] then
        self.favorite:SetIcon(AF.GetIcon("Star2"))
        self.favorite:SetColor(AF.GetColorTable("gold", 0.7))
        self.favorite:SetHoverColor("gold")
        self.favorite:Show()
    else
        self.favorite:SetIcon(AF.GetIcon("Star1"))
        self.favorite:SetColor("darkgray")
        self.favorite:SetHoverColor("white")
        if not self:IsMouseOver() then
            self.favorite:Hide()
        end
    end
end

local itemPanePool = AF.CreateObjectPool(function()
    local pane = AF.CreateBorderedFrame(itemList.slotFrame, nil, nil, nil, "sheet_normal")
    pane:SetOnEnter(Pane_OnEnter)
    pane:SetOnLeave(Pane_OnLeave)
    pane:SetOnMouseUp(function()
        if IsControlKeyDown() then
            DressUpLink(pane.t.link)
        elseif IsShiftKeyDown() then
            local editBox = ChatEdit_ChooseBoxForSend()
            if editBox:HasFocus() then
                editBox:Insert(pane.t.link)
            end
        end
    end)

    -- iconBG
    pane.iconBG = AF.CreateTexture(pane, AF.GetPlainTexture(), "black", "BORDER")
    AF.SetPoint(pane.iconBG, "TOPLEFT", 5, -5)
    AF.SetPoint(pane.iconBG, "BOTTOMRIGHT", pane, "BOTTOMLEFT", 35, 5)

    -- icon
    pane.icon = AF.CreateTexture(pane)
    AF.SetOnePixelInside(pane.icon, pane.iconBG)
    AF.ApplyDefaultTexCoord(pane.icon)

    -- favorite
    pane.favorite = AF.CreateIconButton(pane, nil, 15, 15, 0, "darkgray", "darkgray")
    AF.SetPoint(pane.favorite, "TOPRIGHT", -4, -4)
    pane.favorite:Hide()
    pane.favorite:HookOnEnter(pane:GetOnEnter())
    pane.favorite:HookOnLeave(pane:GetOnLeave())
    pane.favorite:SetOnClick(function()
        if BFBM_DB.favorites[pane.t.itemID] then
            BFBM_DB.favorites[pane.t.itemID] = nil
            pane.favorite:SetIcon(AF.GetIcon("Star1"))
            pane.favorite:SetColor("darkgray")
            pane.favorite:SetHoverColor("white")
        else
            BFBM_DB.favorites[pane.t.itemID] = true
            pane.favorite:SetIcon(AF.GetIcon("Star2"))
            pane.favorite:SetColor(AF.GetColorTable("gold", 0.7))
            pane.favorite:SetHoverColor("gold")
        end
        -- refresh
        LoadItems(selectedServer)
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
-- load
---------------------------------------------------------------------
local function Comparator(a, b)
    -- favorite
    if BFBM_DB.favorites[a.t.itemID] ~= BFBM_DB.favorites[b.t.itemID] then
        return BFBM_DB.favorites[a.t.itemID]
    end

    -- hot items
    if a.t.numBids ~= b.t.numBids then
        return a.t.numBids > b.t.numBids
    end

    -- current bid
    if a.t.currBid ~= b.t.currBid then
        return a.t.currBid > b.t.currBid
    end

    -- min bid
    if a.t.minBid ~= b.t.minBid then
        return a.t.minBid > b.t.minBid
    end

    -- item name
    if a.t.name ~= b.t.name then
        return a.t.name < b.t.name
    end
end

LoadItems = function(server)
    local data
    if not server or server == L["Current Server"] then
        isCurrentServerSelected = true
        selectedServer = AF.player.realm
        data = BFBM.currentServerData
    else
        isCurrentServerSelected = false
        selectedServer = server
        data = BFBM_DB.data.servers[server]
    end

    -- hide
    itemPanePool:ReleaseAll()

    -- load
    for _, t in pairs(data.items) do
        local pane = itemPanePool:Acquire()
        pane:Load(t)
    end

    -- sort
    local widgets = itemPanePool:GetAllActives()
    sort(widgets, Comparator)

    -- set
    itemList:SetWidgets(widgets)
end

function BFBM.UpdateCurrentItems()
    if not isCurrentServerSelected then return end

    if currentFrame and currentFrame:IsShown() then
        local scroll = itemList:GetScroll()
        LoadItems()
        itemList:SetScroll(scroll) -- restore scroll position
    else
        updateRequired = true
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFBM_ShowFrame", function(which)
    if which == "current" then
        if not currentFrame then
            CreateCurrentFrame()
            serverDropdown:SetSelectedValue(L["Current Server"])
            LoadItems()
        end
        currentFrame:Show()
    else
        if currentFrame then
            currentFrame:Hide()
        end
    end
end)