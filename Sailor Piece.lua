-- [[ Sailor Piece Dashboard Script (Map #6) - Quantity Fix ]] --
repeat task.wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not getgenv()["loverr-ezx_Settings"] then
    warn("❌ ไม่พบการตั้งค่า Config!")
    return
end

local settings = getgenv()["loverr-ezx_Settings"]
local baseUrl = settings.BaseUrl or "https://thanathipth.site/"
local updateUrl = baseUrl .. "services/update_stats.php"

-- ฟังก์ชันดึงเฉพาะตัวเลข และเช็คค่าว่าง
local function cleanNumber(txt)
    if not txt or txt == "" then return "1" end
    -- ดึงเฉพาะตัวเลขออกจากข้อความ (เช่น "x50" -> "50", "" -> "1")
    local num = tostring(txt):gsub("x", ""):match("%d+")
    if not num or num == "" then
        return "1"
    end
    return num
end

local function getCleanLevel(rawText)
    if not rawText then return "0" end
    local noParentheses = tostring(rawText):gsub("%b()", "")
    return string.match(noParentheses, "%d+") or "0"
end

local function formatItemName(name)
    return name:sub(1, 5) == "Item_" and name:sub(6) or name
end

-- ฟังก์ชันดึงข้อมูล Inventory
local function getInventoryData()
    local swords, melee, items = {}, {}, {}
    
    pcall(function()
        local storage = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("InventoryPanelUI"):WaitForChild("MainFrame"):WaitForChild("Frame"):WaitForChild("Content"):WaitForChild("Holder"):WaitForChild("StorageHolder"):WaitForChild("Storage")
        
        for _, item in ipairs(storage:GetChildren()) do
            local itemName = formatItemName(item.Name)
            
            -- ดึงจำนวนจาก UI
            local qty = "1"
            local qtyObj = item:FindFirstChild("Slot") and item.Slot:FindFirstChild("Holder") and item.Slot.Holder:FindFirstChild("Quantity")
            if qtyObj and qtyObj:IsA("TextLabel") then
                qty = cleanNumber(qtyObj.Text)
            end
            
            -- แยกหมวดหมู่
            if itemName == "Dark Blade" or itemName == "Katana" then
                table.insert(swords, itemName)
            elseif itemName == "Combat" then
                table.insert(melee, itemName)
            else
                -- รายการไอเทมที่ต้องการส่งจำนวน
                local targets = {
                    ["Conqueror Fragment"] = true, ["Clan Reroll"] = true, ["Dark Grail"] = true, 
                    ["Dungeon Key"] = true, ["Haki Color Reroll"] = true, ["Passive Shard"] = true, 
                    ["Tempest Relic"] = true, ["Trait Reroll"] = true
                }
                if targets[itemName] then
                    table.insert(items, itemName .. "|" .. qty)
                end
            end
        end
    end)
    
    -- ดึงจาก Backpack (เช็คชื่อตรงๆ)
    pcall(function()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            if bp:FindFirstChild("Dark Blade") then table.insert(swords, "Dark Blade") end
            if bp:FindFirstChild("Katana") then table.insert(swords, "Katana") end
            if bp:FindFirstChild("Combat") then table.insert(melee, "Combat") end
        end
    end)
    
    return table.concat(swords, ", "), table.concat(melee, ", "), table.concat(items, ", ")
end

local function sendStats()
    local success, err = pcall(function()
        local data = LocalPlayer:WaitForChild("Data", 10)
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        
        local swords, melee, items = getInventoryData()
        local payload = {
            ["game_id"] = settings.game_id or 6,
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            ["cash"] = cleanNumber(data:WaitForChild("Money", 5).Value),
            ["gems"] = cleanNumber(data:WaitForChild("Gems", 5).Value),
            ["level"] = getCleanLevel(data:WaitForChild("Level", 5).Value),
            ["stat_points"] = cleanNumber(data:WaitForChild("StatPoints", 5).Value),
            ["bounty"] = cleanNumber(leaderstats:WaitForChild("Bounty", 5).Value),
            ["swords"] = swords,
            ["melee"] = melee,
            ["items"] = items
        }

        local req = (syn and syn.request) or (http and http.request) or request
        if req then
            req({Url = updateUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
        else
            HttpService:PostAsync(updateUrl, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
        end
    end)
end

print("✅ Sailor Piece Script (Map #6) Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 20)
end
