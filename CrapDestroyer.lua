-- TO DO
-- add hotkey to settings
-- nothing to destroy output message

local CrapDestroyer = CreateFrame("Frame")
local itemListFrame = nil  -- Track the item list frame
local addonVisible = false



CrapDestroyer:RegisterEvent("ADDON_LOADED")

-- need to properly rewrite this shit for "save globally" instead of "per character" option (settings soon^TM)

-- local function SaveAddonData() 
--     if not CrapDestroyerData then
--         CrapDestroyerData = {}
--     end
--     CrapDestroyerData.items = {}  -- Initialize an empty table for items
--     CrapDestroyerData.itemsInfo = {}  -- Initialize an empty table for itemsInfo

--     for key, itemName in ipairs(items) do
--         table.insert(CrapDestroyerData.items, itemName)
--         print(key, itemName)
--     end

--     for key, itemInfo in ipairs(itemsInfo) do
--         table.insert(CrapDestroyerData.itemsInfo, itemInfo)
--         print(key, itemName)

--     end
-- end

-- local function LoadAddonData()
--     if CrapDestroyerData and CrapDestroyerData.items then
--         print('crapdestroyerData and CrapdestroyerData.items LOADED')
--         items = {}  -- Initialize an empty table for items

--         for _, itemName in ipairs(CrapDestroyerData.items) do
--             table.insert(items, itemName)
--         end
--     else
--         print('crapdestroyerData and CrapdestroyerData.items NOT LOADED')
--     end

--     if CrapDestroyerData and CrapDestroyerData.itemsInfo then
--         print('crapdestroyerData and CrapdestroyerData.itemsInfo LOADED')
--         itemsInfo = {}  -- Initialize an empty table for itemsInfo

--         for _, itemInfo in ipairs(CrapDestroyerData.itemsInfo) do
--             table.insert(itemsInfo, itemInfo)
--         end
--     else
--         print('crapdestroyerData and CrapdestroyerData.itemsInfo NOT LOADED')
--     end
-- end


local function ToggleAddonVisibility()
    if addonVisible then
        -- Hide the addon's main frame and the list
        CrapDestroyer:Hide()
        if itemListFrame then
            itemListFrame:Hide()
        end
    else
        -- Show the addon's main frame
        CrapDestroyer:Show()
    end
    addonVisible = not addonVisible
end

local function IsItemUnwanted(itemName)
    for _, unwantedItem in ipairs(CrapDestroyerItems) do
        if itemName == unwantedItem then
            return true
        end
    end
    return false
end

local function QualityCheck(itemLink)
    local _, _, itemQuality = GetItemInfo(tostring(itemLink))
    
    -- Define the quality threshold for unwanted items (0 = gray, 1 = white, 2 = green...)
    local qualityThreshold = 2  -- only gray and white items will be deleted by default

    if itemQuality and itemQuality < qualityThreshold then
        return true
    end
    return false
end


local function DeleteUnwantedItems()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
            if itemLink then
                local itemName = GetItemInfo(itemLink)
                if itemName and IsItemUnwanted(itemName) and QualityCheck(itemLink) then
                    PickupContainerItem(bag, slot)
                    DeleteCursorItem()
                    print("|cFFFF0000Deleted: " .. itemLink .. " (" .. itemCount .. ")")
                elseif itemName and IsItemUnwanted(itemName) and QualityCheck(itemLink) == false then
                    print("|cFFFF0000Aborted deletion of an item above common quality: "..tostring(itemLink))
                end
            end
        end
    end
end

local function IsItemInList(itemName)
    for _, item in ipairs(CrapDestroyerItems) do
        if item == itemName then
            return true
        end
    end
    return false
end

local function AddItemToList(itemName)
    if not IsItemInList(itemName) then
        table.insert(CrapDestroyerItems, itemName)
        print(itemName .. " |cFFFF0000added to the deletion list.|r")
    else
        print(itemName .. " |cFFFFFF00is already in the deletion list!|r")
    end
end



local function RemoveItemFromList(itemName)
    for i, item in ipairs(CrapDestroyerItems) do
        if item == itemName then
            table.remove(CrapDestroyerItems, i)
            print(itemName .. " |cFF00FF00removed from the deletion list.|r")
            return
        end
    end
    print(itemName .. " not found in the deletion list.")
end

function CrapDestroyer:CreateUI()
    -- Create the main frame
    self:SetSize(145, 115)
    self:SetPoint("CENTER", 0, 0)
    self:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    self:SetBackdropColor(0, 0, 0, 0.7)
    self:SetMovable(true)
    self:EnableMouse(true)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", function(self) self:StartMoving() end)
    self:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    self:Hide()

    -- Create Minimize Button
    local minimizeButton = CreateFrame("Button", nil, self, "UIPanelCloseButton")
    minimizeButton:SetPoint("TOPRIGHT", -1, -1)
    minimizeButton:SetSize(20, 20) 
    minimizeButton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Up")
    minimizeButton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight")
    minimizeButton:SetScript("OnClick", function()
        ToggleAddonVisibility()
    end)
    -- Options Button
    local optionsButton = CreateFrame("Button", nil, self, "UIPanelCloseButton")
    optionsButton:SetPoint("TOPLEFT", 1, 1)
    optionsButton:SetSize(20, 20) 
    optionsButton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Up")
    optionsButton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight")
    optionsButton:SetScript("OnClick", function()
        if OptionsFrame then
            if OptionsFrame:IsVisible() then
                OptionsFrame:Hide()
            else
                OptionsFrame:Show()
            end
        else
            CreateOptionsFrame()
        end
    end)
    -- Create the Destroy Button
    local destroyButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    destroyButton:SetPoint("TOP", 0, -10)
    destroyButton:SetSize(100, 25)
    destroyButton:SetText("Destroy Items")
    destroyButton:SetScript("OnClick", DeleteUnwantedItems)

    -- Create the Add Button
    local addButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    addButton:SetPoint("TOPLEFT", destroyButton, "BOTTOMLEFT", 0, -10)
    addButton:SetSize(100, 25)
    addButton:SetText("Add Item")
    addButton:RegisterForDrag("LeftButton")
    
    -- Drag to Add Button logic
    addButton:SetScript("OnReceiveDrag", function()
        local cursorType, itemID = GetCursorInfo()
        if cursorType == "item" then
            local itemName = GetItemInfo(itemID)
            if itemName then
                AddItemToList(itemName)
                UpdateItemList()
            end
            ClearCursor()
        end
    end)

    -- Create Item List button
    local listButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    listButton:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -10)
    listButton:SetSize(100, 25)
    listButton:SetText("Item List")
    listButton:SetScript("OnClick", function()
        if itemListFrame then
            if itemListFrame:IsVisible() then
                itemListFrame:Hide()
            else
                itemListFrame:Show()
            end
        else
            CreateItemListFrame()
        end
    end)



    --DEBUG (outdated)

    -- local saveDataButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    -- saveDataButton:SetPoint("TOPLEFT", listButton, "BOTTOMLEFT", 0, -10)
    -- saveDataButton:SetSize(100, 25)
    -- saveDataButton:SetText("Save Data")
    -- saveDataButton:SetScript("OnClick", SaveAddonData)

    -- -- Create Load Data Button
    -- local loadDataButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    -- loadDataButton:SetPoint("TOPLEFT", saveDataButton, "BOTTOMLEFT", 0, -10)
    -- loadDataButton:SetSize(100, 25)
    -- loadDataButton:SetText("Load Data")
    -- loadDataButton:SetScript("OnClick", LoadAddonData)
    
    -- --update list button
    -- local updateListButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    -- updateListButton:SetPoint("TOPLEFT", loadDataButton, "BOTTOMLEFT", 0, -10)
    -- updateListButton:SetSize(100, 25)
    -- updateListButton:SetText("Update List")
    -- updateListButton:SetScript("OnClick", function()
    --     UpdateItemList()
    -- end)
    --/DEBUG
end
function CreateOptionsFrame()
    OptionsFrame = CreateFrame("Frame", "OptionsFrame", UIParent)
    OptionsFrame:SetSize(250, 300)
    OptionsFrame:SetPoint("TOPRIGHT", CrapDestroyer, "TOPLEFT", 0, 0)
    OptionsFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
end
function CreateItemListFrame()
    itemListFrame = CreateFrame("Frame", "ItemListFrame", UIParent)
    itemListFrame:SetSize(250, 300)
    local screenWidth, _ = GetScreenWidth(), GetScreenHeight()
    local availableSpace = screenWidth - CrapDestroyer:GetRight()
    if (availableSpace - 300) < itemListFrame:GetWidth() then
        itemListFrame:SetPoint("TOPRIGHT", CrapDestroyer, "TOPLEFT", 0, 0)
    else
        itemListFrame:SetPoint("TOPLEFT", CrapDestroyer, "TOPRIGHT", 0, 0)
    end
    itemListFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    itemListFrame:SetBackdropColor(0, 0, 0, 0.7)
    UpdateItemList()

    local closeButton = CreateFrame("Button", nil, itemListFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function() itemListFrame:Hide() end)
end

function CreateItemButton(itemName) --here is the problem that itemlink is a string if an item not in a bag
    local itemLink = GetItemInfo(itemName)
    print(itemLink)
    if itemLink then
        local _, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemLink)
        CrapDestroyerItemsInfo[itemName] = { quality = itemQuality, texture = itemTexture, name = itemName }
    else
        print("not itemlink")
        CrapDestroyerItemsInfo[itemName] = { quality = nil, texture = nil, name = itemName }
    end

    local yOffset = -10
    local button = CreateFrame("Button", nil, itemListFrame)
    button:SetPoint("TOPLEFT", 10, yOffset)
    button:SetSize(20, 20)

    local removeButton = CreateFrame("Button", nil, button)
    removeButton:SetPoint("LEFT", button, "LEFT", 0, 0)
    removeButton:SetSize(20, 20)
    removeButton:SetNormalTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Up")
    removeButton:SetHighlightTexture("Interface\\BUTTONS\\UI-Panel-MinimizeButton-Highlight")
    removeButton:SetScript("OnClick", function()
        RemoveItemFromList(itemName)
        UpdateItemList()
    end)

    local iconTexture = button:CreateTexture(nil, "ARTWORK")
    iconTexture:SetSize(20, 20)
    iconTexture:SetPoint("LEFT", removeButton, "RIGHT", 5, 0)

    local itemInfo = CrapDestroyerItemsInfo[itemName]
    if itemInfo and itemInfo.texture then
        local itemQuality = itemInfo.quality
        local itemTexture = itemInfo.texture
        iconTexture:SetTexture(itemTexture)
        print(itemTexture)

        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", iconTexture, "RIGHT", 5, 0)
        for i = 0, 8 do
            local _, _, _, hex = GetItemQualityColor(i)
            if itemQuality == i then
                label:SetText(hex .. itemInfo.name)
            end
        end
    else
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", iconTexture, "RIGHT", 5, 0)
        label:SetText(itemName)
    end

    yOffset = yOffset - 25
    return button
end

function UpdateItemList()
    if not itemListFrame then return end

    local yOffset = -10
    for _, child in pairs({ itemListFrame:GetChildren() }) do
        child:Hide()
    end

    for _, item in ipairs(CrapDestroyerItems) do
        print("updateUI item:"..item)
        local button = CreateItemButton(item)
        button:SetPoint("TOPLEFT", 10, yOffset)
        button:Show()
        yOffset = yOffset - 25
    end
end
    
local function CrapDestroyerSlashCommandHandler(msg)
    if msg == "toggle" then
        -- Toggle the visibility of your addon's UI here
        ToggleAddonVisibility()

    elseif msg == "info" then
        print("CrapDestroyer is a simple addon that helps you manage unwanted items. Sometimes you are too far away from a vendors and destroying items like Salted Venison or Honey-Spiced Lichen manually can be tedious while farming... This addon will destroy that crap for you!")
        print("Please note that unlike most addons that auto-sell items, this one will permanently destroy them, so make sure you don't put anything important in the list.\n")
        print("|cFFFF0000[Basic usage]:|r")
        print("Open the UI by typing |cFFFF0000/crap toggle|r in chat")
        print("You should see a window with 3 buttons")
        print("To add an item you want to destroy simple drag and drop it from your bag to the '|cFF00FF00Add Item|r' button")
        print("To check the list of items that are currently listed for destruction press '|cFF00FF00Item List|r'")
        print("You can remove items from this list by pressing the cross button near every entry")
        print("To destroy items press '|cFF00FF00Destroy items|r' button or type |cFFFF0000/crap destroy|r in chat")
        print("Protip: you can make a macro with a hotkey for faster usage")
    elseif msg == "help" then
        print("Available commands:")
        print("/crap toggle - open UI")
        print("/crap info - Display addon information")
        print("/crap help - Display this help message")
        print("/crap destroy - destroys all items that was added to the list")
    elseif msg == "destroy" then
        DeleteUnwantedItems()
    else
        print("Invalid command. Type '|cFFFF0000/crap help|r' for a list of commands.")
    end
end

-- Register the slash command
SlashCmdList["CRAPDESTROYER"] = CrapDestroyerSlashCommandHandler

-- Set up the slash command trigger
SLASH_CRAPDESTROYER1 = "/crap"


function CrapDestroyer:OnEvent(event, arg1)
    if event == "ADDON_LOADED" and arg1 == "CrapDestroyer" then
        print("|cFFFF0000Crap Destroyer addon loaded. Type /crap to open UI or /crap info for help|r")
        CrapDestroyerItems = CrapDestroyerItems
        CrapDestroyerItemsInfo = CrapDestroyerItemsInfo
        if not CrapDestroyerItems then
            CrapDestroyerItems = {}
            print('CrapDestroyerItems IS EMPTY')
        end
        
        if not CrapDestroyerItemsInfo then 
            CrapDestroyerItemsInfo = {}
            print('CrapDestroyerItemsInfo IS EMPTY')

        end

        self:CreateUI()
        -- LoadAddonData()  -- Load saved data when the addon is loaded
    elseif event == "PLAYER_LOGOUT" then
        -- SaveAddonData()  -- Save your addon's data when quitting the game
        
    end
end

-- Register events
CrapDestroyer:RegisterEvent("ADDON_LOADED")
CrapDestroyer:RegisterEvent("PLAYER_LOGOUT")
CrapDestroyer:SetScript("OnEvent", CrapDestroyer.OnEvent)



