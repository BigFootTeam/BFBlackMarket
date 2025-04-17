---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local historyFrame
local searchBox, itemList
local LoadItems

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
    searchBox = AF.CreateEditBox(historyFrame, L["Search"], nil, 20)
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

    AF.IconTooltip:SetOwner(self, "ANCHOR_NONE")
    AF.IconTooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
    AF.IconTooltip:SetItem(self.id)

    self.favorite:Show()
end

local function Pane_OnLeave(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_normal"))

    AF.IconTooltip:Hide()

    if not self:IsMouseOver() and not BFBM_DB.favorites[self.id] then
        self.favorite:Hide()
    end
end

local function Pane_Load(self, id, t)
    -- texplore(t)
    self.id = id
    self.t = t

    self.itemID:SetText(id)
    self.icon:SetTexture(t.texture)
    self.name:SetText(t.name)

    self.avgBid:SetText("AVG_BID")

    if t.quality then
        local r, g, b = AF.GetItemQualityColor(t.quality)
        self.iconBG:SetVertexColor(r, g, b)
        self.name:SetTextColor(r, g, b)
    else
        self.iconBG:SetVertexColor(0, 0, 0)
        self.name:SetTextColor(1.0, 0.82, 0)
    end

    if BFBM_DB.favorites[id] then
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
        LoadItems()
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
    AF.SetPoint(pane.itemID, "BOTTOMRIGHT", -5, 5)

    -- function
    pane.Load = Pane_Load

    return pane
end)

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
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

    -- set
    itemList:SetWidgets(widgets)
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