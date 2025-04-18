---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local historyFrame
local searchBox, itemList
local LoadItems
local updateRequired

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateHistoryFrame()
    historyFrame = AF.CreateFrame(BFBMMainFrame, "BFBMHistoryFrame")
    AF.SetPoint(historyFrame, "TOPLEFT", BFBMMainFrame, 10, -40)
    AF.SetPoint(historyFrame, "BOTTOMRIGHT", BFBMMainFrame, -10, 10)

    historyFrame:SetOnShow(function()
        if updateRequired then
            LoadItems()
        end
    end)

    -- search
    searchBox = AF.CreateEditBox(historyFrame, _G.SEARCH, nil, 20)
    searchBox:SetPoint("TOPLEFT")
    searchBox:SetPoint("TOPRIGHT")

    -- item list
    itemList = AF.CreateScrollList(historyFrame, nil, 5, 5, 6, 40, 5)
    AF.SetPoint(itemList, "TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    AF.SetPoint(itemList, "TOPRIGHT", searchBox, "BOTTOMRIGHT", 0, -10)
end

---------------------------------------------------------------------
-- item pane
---------------------------------------------------------------------
local function Pane_OnEnter(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_highlight"))

    AF.Tooltip:SetOwner(self, "ANCHOR_NONE")
    AF.Tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
    AF.Tooltip:SetItem(self.id)

    self.favorite:Show()
end

local function Pane_OnLeave(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_normal"))

    AF.Tooltip:Hide()

    if not self:IsMouseOver() and not BFBM_DB.favorites[self.id] then
        self.favorite:Hide()
    end
end

local function CalcAvgBid(t)
    if t.lastAvgCalc == t.lastUpdate then
        return t.avgBid
    end

    local totalBid = 0
    local totalCount = 0

    for _, history in pairs(t.history) do -- servers
        for _, day in pairs(history) do -- days
            -- "final" bid
            local bid
            if day.finalBid then
                bid = day.finalBid
            else
                _, bid = AF.GetMaxKeyValue(day.bids)
            end

            if bid then
                totalBid = totalBid + bid
                totalCount = totalCount + 1
            end
        end
    end

    if totalCount > 0 then
        t.avgBid = totalBid / totalCount
    else
        t.avgBid = 0
    end

    return t.avgBid
end

local function Pane_Load(self, id, t)
    -- texplore(t)
    self.id = id
    self.t = t

    self.itemID:SetText("ID: " .. id)
    self.icon:SetTexture(t.texture)
    self.name:SetText(t.name)

    if CalcAvgBid(t) == 0 then
        self.avgBid:SetText("")
    else
        if t.avgBid >= BFBM.MAX_BID then
            self.avgBid:SetText(AF.WrapTextInColor(L["Avg"] .. ": ", "gray") .. AF.WrapTextInColor(AF.FormatMoney(t.avgBid, nil, true, true), "firebrick"))
        else
            self.avgBid:SetText(AF.WrapTextInColor(L["Avg"] .. ": ", "gray") .. AF.FormatMoney(t.avgBid, nil, true, true))
        end
    end

    if t.quality then
        local r, g, b = AF.GetItemQualityColor(t.quality)
        self.iconBG:SetVertexColor(r, g, b)
        self.name:SetTextColor(r, g, b)
    else
        self.iconBG:SetVertexColor(0, 0, 0)
        self.name:SetTextColor(1.0, 0.82, 0)
    end

    if BFBM_DB.favorites[id] then
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
        if BFBM_DB.favorites[pane.id] then
            BFBM_DB.favorites[pane.id] = nil
            pane.favorite:SetIcon(AF.GetIcon("Star"))
            pane.favorite:SetColor("darkgray")
            pane.favorite:SetHoverColor("white")
        else
            BFBM_DB.favorites[pane.id] = true
            pane.favorite:SetIcon(AF.GetIcon("Star_Filled"))
            pane.favorite:SetColor(AF.GetColorTable("gold", 0.7))
            pane.favorite:SetHoverColor("gold")
        end
        -- refresh
        LoadItems()
        -- refresh current
        BFBM.UpdateCurrentItems(nil, true)
    end)

    -- name
    pane.name = AF.CreateFontString(pane)
    pane.name:SetJustifyH("LEFT")
    pane.name:SetWordWrap(false)
    AF.SetPoint(pane.name, "TOPLEFT", pane.iconBG, "TOPRIGHT", 5, 0)
    AF.SetPoint(pane.name, "RIGHT", pane.favorite, "LEFT", -5, 0)

    -- avgBid
    pane.avgBid = AF.CreateFontString(pane)
    AF.SetPoint(pane.avgBid, "BOTTOMLEFT", pane.iconBG, "BOTTOMRIGHT", 5, 0)

    -- itemID
    pane.itemID = AF.CreateFontString(pane)
    pane.itemID:SetColor("gray")
    AF.SetPoint(pane.itemID, "BOTTOMRIGHT", -5, 5)

    -- function
    pane.Load = Pane_Load

    return pane
end)

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
local function Comparator(a, b)
    -- favorite
    if BFBM_DB.favorites[a.id] ~= BFBM_DB.favorites[b.id] then
        return BFBM_DB.favorites[a.id]
    end

    -- avgBid
    if a.t.avgBid ~= b.t.avgBid then
        return a.t.avgBid > b.t.avgBid
    end

    -- name
    if a.t.name ~= b.t.name then
        return a.t.name < b.t.name
    end
end

LoadItems = function()
    -- hide
    itemPanePool:ReleaseAll()

    -- load
    for id, t in pairs(BFBM_DB.data.items) do
        local pane = itemPanePool:Acquire()
        pane:Load(id, t)
    end

    -- sort
    local widgets = itemPanePool:GetAllActives()
    sort(widgets, Comparator)

    -- set
    itemList:SetWidgets(widgets)
end

function BFBM.UpdateHistoryItems()
    if historyFrame and historyFrame:IsShown() then
        LoadItems()
    else
        updateRequired = true
    end
end

---------------------------------------------------------------------
-- show
---------------------------------------------------------------------
AF.RegisterCallback("BFBM_ShowFrame", function(which)
    if which == "history" then
        if not historyFrame then
            CreateHistoryFrame()
            LoadItems()
        end
        historyFrame:Show()
    else
        if historyFrame then
            historyFrame:Hide()
        end
    end
end)