---@class BFBM
local BFBM = select(2, ...)
local L = BFBM.L
---@type AbstractFramework
local AF = _G.AbstractFramework

local GetItemInfo = C_Item.GetItemInfo
local GetItemInfoInstant = C_Item.GetItemInfoInstant

local historyFrame
local searchBox, itemList, itemCount
local LoadItems
local updateRequired

---------------------------------------------------------------------
-- create
---------------------------------------------------------------------
local function CreateHistoryFrame()
    historyFrame = AF.CreateFrame(BFBMMainFrame, "BFBMHistoryFrame")
    AF.SetPoint(historyFrame, "TOPLEFT", BFBMMainFrame, 10, -40)
    AF.SetPoint(historyFrame, "BOTTOMRIGHT", BFBMMainFrame, -10, 7)

    historyFrame:SetOnShow(function()
        if updateRequired then
            LoadItems()
        end
    end)

    -- search
    searchBox = AF.CreateEditBox(historyFrame, _G.SEARCH, nil, 20)
    AF.SetPoint(searchBox, "TOPLEFT")
    searchBox:SetOnHide(nil) -- disable auto reset
    searchBox:SetOnTextChanged(function(_, userChanged)
        if userChanged then
            LoadItems()
        end
    end)

    -- add
    local addButton = AF.CreateButton(historyFrame, nil, "accent_hover", 20, 20)
    addButton:SetPoint("TOPRIGHT")
    AF.SetPoint(searchBox, "TOPRIGHT", addButton, "TOPLEFT", -5, 0)
    addButton:SetTexture(AF.GetIcon("Create_Square"))

    local content = AF.CreateDialogContent(20)
    content.idBox = AF.CreateEditBox(content, L["Item ID"], nil, 20, "number")
    content.idBox:SetPoint("TOPLEFT")
    content.idBox:SetPoint("TOPRIGHT")
    content.idBox:SetOnTextChanged(function(value, userChanged)
        if userChanged and value and GetItemInfoInstant(value) then
            AF.Tooltip:SetOwner(content.dialog, "ANCHOR_NONE")
            AF.Tooltip:SetPoint("TOPRIGHT", content.dialog, "TOPLEFT", -5, 0)
            AF.Tooltip:SetItem(value)
            content.dialog:EnableYes(true)
        else
            AF.Tooltip:Hide()
            content.dialog:EnableYes(false)
        end
    end)

    addButton:SetOnClick(function()
        AF.ShowDialog(historyFrame, L["Add Item to Watchlist"], nil, nil, nil, true, content, true)
        AF.SetDialogOnConfirm(function()
            local id = content.idBox:GetValue()
            if id then
                BFBM_DB.favorites[id] = true
                if not BFBM_DB.data.items[id] then
                    local name, link, quality, _, _, itemType, _, _, _, texture = GetItemInfo(id)
                    BFBM_DB.data.items[id] = {
                        name = name,
                        texture = texture,
                        link = link,
                        quality = quality,
                        itemType = itemType,
                        history = {},
                    }
                end
                BFBM_DB.data.items[id].lastUpdate = GetServerTime()
                LoadItems()
            end
        end)
        AF.SetDialogPoint("TOP", 0, -30)
    end)

    -- item list
    itemList = AF.CreateScrollList(historyFrame, nil, 5, 5, 6, 40, 5)
    AF.SetPoint(itemList, "TOPLEFT", searchBox, "BOTTOMLEFT", 0, -10)
    AF.SetPoint(itemList, "TOPRIGHT", addButton, "BOTTOMRIGHT", 0, -10)

    -- item count
    local tips = AF.CreateTipsButton(historyFrame)
    tips:SetPoint("BOTTOMRIGHT")
    tips:SetTips(AF.L["Tips"], L["Alt + Left Click to delete item"])

    itemCount = AF.CreateFontString(historyFrame, nil, "gray")
    itemCount:SetPoint("RIGHT", tips, "LEFT")
end

---------------------------------------------------------------------
-- item pane
---------------------------------------------------------------------
local function Pane_OnEnter(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_highlight"))

    if BFBM_DB.config.requireCtrlForItemTooltips then
        AF.Tooltip:RequireModifier("ctrl")
    end
    AF.Tooltip:SetOwner(self, "ANCHOR_NONE")
    AF.Tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -5, 0)
    AF.Tooltip:SetItem(self.itemID)

    self.favorite:Show()
end

local function Pane_OnLeave(self)
    self:SetBackdropColor(AF.GetColorRGB("sheet_normal"))

    AF.Tooltip:Hide()

    if not self:IsMouseOver() and not BFBM_DB.favorites[self.itemID] then
        self.favorite:Hide()
    end
end

local function Pane_OnMouseUp(self, button)
    if IsControlKeyDown() then
        DressUpLink(self.t.link)
    elseif IsShiftKeyDown() then
        local editBox = ChatEdit_ChooseBoxForSend()
        if editBox:HasFocus() then
            editBox:Insert(self.t.link)
        end
    elseif IsAltKeyDown() then
        if button == "LeftButton" then
            BFBM_DB.data.items[self.itemID] = nil
            BFBM_DB.favorites[self.itemID] = nil
            AF.Fire("BFBM_ITEM_HISTORY_UPDATE", nil, nil, self.itemID)
            LoadItems()
        end
    else
        BFBM.ShowDetailFrame(self.itemID)
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
    self.itemID = id
    self.t = t

    self.id:SetText("ID: " .. id)
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
    pane:SetOnMouseUp(Pane_OnMouseUp)

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
    pane.id = AF.CreateFontString(pane)
    pane.id:SetColor("gray")
    AF.SetPoint(pane.id, "BOTTOMRIGHT", -5, 5)

    -- function
    pane.Load = Pane_Load

    return pane
end)

---------------------------------------------------------------------
-- load
---------------------------------------------------------------------
local function Comparator(a, b)
    -- favorite
    if BFBM_DB.favorites[a.itemID] ~= BFBM_DB.favorites[b.itemID] then
        return BFBM_DB.favorites[a.itemID]
    end

    -- avgBid
    if a.t.avgBid ~= b.t.avgBid then
        return a.t.avgBid > b.t.avgBid
    end

    -- last update
    if a.t.lastUpdate ~= b.t.lastUpdate then
        return a.t.lastUpdate > b.t.lastUpdate
    end

    -- name
    if a.t.name ~= b.t.name then
        return a.t.name < b.t.name
    end
end

LoadItems = function()
    local n = 0

    -- hide
    itemPanePool:ReleaseAll()

    -- load
    for id, t in pairs(BFBM_DB.data.items) do
        local search = searchBox:GetText()
        if search == "" or t.name:find(search) or strfind(id, search) then
            local pane = itemPanePool:Acquire()
            pane:Load(id, t)
            n = n + 1
        end
    end

    -- sort
    local widgets = itemPanePool:GetAllActives()
    sort(widgets, Comparator)

    -- set
    itemList:SetWidgets(widgets)

    -- count
    if n == 0 then
        itemCount:SetText(L["No items found"])
    else
        itemCount:SetText(n .. " " .. L["items"])
    end
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
AF.RegisterCallback("BFBM_ShowFrame", function(_, which)
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