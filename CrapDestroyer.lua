-- TO DO
-- add hotkey to settings
-- nothing to destroy output message

local CrapDestroyer = CreateFrame("Frame")
local itemListFrame = nil  -- Track the item list frame
local addonVisible = false


CrapDestroyer:RegisterEvent("ADDON_LOADED")

local function SaveAddonData()
    if not CrapDestroyerData then
        CrapDestroyerData = {}
    end
    CrapDestroyerData.items = {}  -- Initialize an empty table for items

    for _, itemName in ipairs(items) do
        local itemInfo = {}
        local _,_,itemQuality,_,_,_,_,_,_,itemTexture = GetItemInfo(itemName)
        itemInfo.name = itemName
        itemInfo.texture = itemTexture
        table.insert(CrapDestroyerData.items, itemInfo)
    end
end


local function LoadAddonData()
    if CrapDestroyerData and CrapDestroyerData.items then
        items = {}  -- Initialize an empty table for items

        for _, itemInfo in ipairs(CrapDestroyerData.items) do
            table.insert(items, itemInfo.name)
        end
    end
end

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



local List = {} -- define and initialize the List table
items = {"Scroll of Spirit VII", "Shiny Fish Scales", "Salted Venison"} -- example of unwanted items

local function IsItemUnwanted(itemName)
    for _, unwantedItem in ipairs(items) do
        if itemName == unwantedItem then
            return true
        end
    end
    return false
end

local function QualityCheck(itemLink)
    local _, _, itemQuality = GetItemInfo(tostring(itemLink))
    
    -- Define the quality threshold for unwanted items (e.g., Poor quality items have a quality of 0)
    local qualityThreshold = 2  -- Change this to your desired quality threshold

    if itemQuality and itemQuality < qualityThreshold then
        return true
    end

    return false
end


local function DeleteUnwantedItems()
    for bag = 0, 4 do
        for slot = 1, 36 do
            local _, itemCount, _, _, _, _, itemLink = GetContainerItemInfo(bag, slot)
            if itemLink and IsItemUnwanted(GetItemInfo(itemLink)) and QualityCheck(itemLink)  then
                PickupContainerItem(bag, slot)
                DeleteCursorItem()
                print("|cFFFF0000Deleted: " .. itemLink .. " (" .. itemCount .. ")")
            elseif itemLink and IsItemUnwanted(GetItemInfo(itemLink)) and QualityCheck(itemLink) == false then
                print("|cFFFF0000Aborted deletion of an item above common quality: "..tostring(itemLink))
            elseif itemLink and IsItemUnwanted(GetItemInfo(itemLink)) == false then
                --print(tostring(itemLink).." is not unwanted["..bag.."]["..slot.."]")
            end
        end
    end
end

local function IsItemInList(itemName)
    for _, item in ipairs(items) do
        if item == itemName then
            return true
        end
    end
    return false
end
local function AddItemToList(itemName)
    -- Check if the item is not already in the list
    if not IsItemInList(itemName) then
        table.insert(items, itemName)
        print(itemName .. " |cFFFF0000added to the deletion list.|r")
    else
        print(itemName .. " |cFFFFFF00is already in the deletion list!|r")
    end
end



local function RemoveItemFromList(itemName)
    for i, item in ipairs(items) do
        if item == itemName then
            table.remove(items, i)
            print(itemName .. " |cFF00FF00removed from the deletion list.|r")
            return
        end
    end
    print(itemName .. " not found in the deletion list.")
end

-- Function to create the user interface (UI)
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

    -- Create a flag to track if an item is being dragged
    local isDraggingItem = false

    -- Set up functions for drag-and-drop
    addButton:RegisterForDrag("LeftButton")
    addButton:SetScript("OnReceiveDrag", function(self)
        local cursorType, itemID = GetCursorInfo()
        if cursorType == "item" then
            local itemName = GetItemInfo(itemID)
            if itemName and itemListFrame then
                AddItemToList(itemName)
                UpdateItemList()
                else
                    AddItemToList(itemName)
            end
            -- Cancel the drag and drop
            PickupItem(0)
            isDraggingItem = false
        end
    end)
    addButton:SetScript("OnDragStart", function(self)
        self:SetAttribute("type1", "item")
        self:SetAttribute("item1", "item")
        isDraggingItem = true
    end)
    addButton:SetScript("OnDragStop", function(self)
        self:SetAttribute("type1", nil)
        self:SetAttribute("item1", nil)
        if isDraggingItem then
            -- Cancel the drag and drop
            PickupItem(0)
            isDraggingItem = false
        end
    end)

    -- Create the List Button
    local listButton = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    listButton:SetPoint("TOPLEFT", addButton, "BOTTOMLEFT", 0, -10)
    listButton:SetSize(100, 25)
    listButton:SetText("Item List")


    listButton:SetScript("OnClick", function()
        if itemListFrame and itemListFrame:IsVisible() then
            itemListFrame:Hide()
        else
            -- Create a new frame to display the item list and buttons
            itemListFrame = CreateFrame("Frame", "ItemListFrame", UIParent)
            itemListFrame:SetSize(250, 300)
            
            --Checks if there is enough space for the list on the screen
            local screenWidth, _ = GetScreenWidth(), GetScreenHeight()
            local availableSpace = screenWidth - self:GetRight()

            if (availableSpace - 300) < itemListFrame:GetWidth() then
                itemListFrame:SetPoint("TOPRIGHT", self, "TOPLEFT", 0, 0) -- Anchor to the left
            else
                itemListFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", 0, 0) -- Anchor to the right
            end
            
            itemListFrame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 16, edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            itemListFrame:SetBackdropColor(0, 0, 0, 0.7)

            local yOffset = -10
            local itemListButtons = {}  -- Track the buttons in the item list

            local function CreateItemButton(itemName)

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
                    UpdateItemList()  -- Update the list after removing an item
                end)
            
                local iconTexture = button:CreateTexture(nil, "ARTWORK")
                iconTexture:SetSize(20, 20)  
                iconTexture:SetPoint("LEFT", removeButton, "RIGHT", 5, 0)
                local _,_,itemQuality,_,_,_,_,_,_,itemTexture = GetItemInfo(itemName)
                --iconTexture:SetTexture('"'..tostring(itemTexture)..'"')
                iconTexture:SetTexture(itemTexture)
                print(itemTexture)
            
                local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                label:SetPoint("LEFT", iconTexture, "RIGHT", 5, 0)
                for i = 0, 8 do 
                    local r, g, b, hex = GetItemQualityColor(i)
                    if itemQuality == i then
                        label:SetText(hex..itemName)
                    end
                end
                yOffset = yOffset - 25
            
                return button
            end

            function UpdateItemList()
                for _, button in ipairs(itemListButtons) do
                    button:Hide()
                    button:ClearAllPoints()  -- Clear button anchor points
                end

                itemListButtons = {}

                yOffset = -10
                for _, itemName in ipairs(items) do
                    local buttonData = CreateItemButton(itemName)
                    itemListButtons[#itemListButtons + 1] = buttonData
                end

                itemListFrame:SetHeight(10 - yOffset)
            end

            UpdateItemList()  -- Initial update of the item list

            -- Create a button to close the item list frame
            local closeButton = CreateFrame("Button", nil, itemListFrame, "UIPanelCloseButton")
            closeButton:SetPoint("TOPRIGHT", 0, 0)
            closeButton:SetScript("OnClick", function()
                itemListFrame:Hide()
            end)
        end
    end)
end


local function CrapDestroyerSlashCommandHandler(msg)
    if msg == "toggle" then
        -- Toggle the visibility of your addon's UI here
        ToggleAddonVisibility()

    elseif msg == "info" then
        print("CrapDestroyer is an simple addon that helps you manage unwanted items. Sometimes you are too far from a merchant and destroying items like Salted Venison or Honey-Spiced Lichen manually can be tedious when farming... This addon will destroy this crap for you!")
        print("Please note that unlike most addons that auto-selling items this one is permanently destroying them, so make sure you don't put important stuff in the list\n")
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
        self:CreateUI()
        LoadAddonData()  -- Load saved data when the addon is loaded
    elseif event == "PLAYER_QUITTING" then
        SaveAddonData()  -- Save your addon's data when quitting the game
    end
end

-- Register events
CrapDestroyer:RegisterEvent("ADDON_LOADED")
CrapDestroyer:RegisterEvent("PLAYER_QUITTING")
CrapDestroyer:SetScript("OnEvent", CrapDestroyer.OnEvent)
