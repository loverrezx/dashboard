-- [[ Sailor Piece Dashboard Script (Map #6) - Backpack Melee/Sword Fix ]] --
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

-- ฟังก์ชันล้างตัวเลข
local function cleanNumber(txt)
    if not txt then return "0" end
    if typeof(txt) == "number" then return tostring(txt) end
    local num = string.match(tostring(txt), "[%d%.]+") or "0"
    return num:gsub(",", "")
end

-- ฟังก์ชันดึง Level
local function getCleanLevel(rawText)
    if not rawText then return "0" end
    if typeof(rawText) == "number" then return tostring(rawText) end
    local noParentheses = tostring(rawText):gsub("%b()", "")
    local level = string.match(noParentheses, "%d+") or "0"
    return level
end

-- ฟังก์ชันตัด Item_ ออกจากชื่อ
local function formatItemName(name)
    if name:sub(1, 5) == "Item_" then
        return name:sub(6)
    end
    return name
end

-- ฟังก์ชันดึงข้อมูล Inventory และ Backpack
local function getInventoryData()
    local swords = {}
    local melee = {}
    local items = {}
    
    -- 1. ดึง Melee/Sword จาก Backpack โดยตรงตามที่คุณระบุ
    pcall(function()
        local backpack = LocalPlayer:WaitForChild("Backpack", 5)
        if backpack then
            -- เช็ค Sword
            if backpack:FindFirstChild("Dark Blade") then table.insert(swords, "Dark Blade") end
            if backpack:FindFirstChild("Katana") then table.insert(swords, "Katana") end
            
            -- เช็ค Melee
            if backpack:FindFirstChild("Combat") then table.insert(melee, "Combat") end
            
            -- ดึงไอเทมอื่นๆ ใน Backpack ที่ไม่ใช่ Sword/Melee ลงช่อง Items
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool.Name ~= "Dark Blade" and tool.Name ~= "Katana" and tool.Name ~= "Combat" then
                    table.insert(items, tool.Name)
                end
            end
        end
    end)
    
    -- 2. ดึงข้อมูลจาก Storage (InventoryPanelUI) ลงช่อง Items
    pcall(function()
        local storage = LocalPlayer.PlayerGui.InventoryPanelUI.MainFrame.Frame.Content.Holder.StorageHolder.Storage
        for _, item in ipairs(storage:GetChildren()) do
            local itemName = formatItemName(item.Name)
            -- เฉพาะไอเทมที่ยังไม่มีในรายการ (ป้องกันซ้ำ)
            table.insert(items, itemName)
        end
    end)
    
    return table.concat(swords, ", "), table.concat(melee, ", "), table.concat(items, ", ")
end

local function sendStats()
    local success, err = pcall(function()
        local data = LocalPlayer:WaitForChild("Data", 10)
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        
        local money = data:WaitForChild("Money", 5).Value
        local gems = data:WaitForChild("Gems", 5).Value
        local level = data:WaitForChild("Level", 5).Value
        local statPoints = data:WaitForChild("StatPoints", 5).Value
        local bounty = leaderstats:WaitForChild("Bounty", 5).Value
        
        local swords, melee, items = getInventoryData()

        local payload = {
            ["game_id"] = settings.game_id or 6, -- Sailor Piece (Map #6)
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            ["cash"] = cleanNumber(money),
            ["gems"] = cleanNumber(gems),
            ["level"] = getCleanLevel(level),
            ["stat_points"] = cleanNumber(statPoints),
            ["bounty"] = cleanNumber(bounty),
            ["swords"] = swords,
            ["melee"] = melee,
            ["items"] = items
        }

        local requestFunc = (syn and syn.request) or (http and http.request) or request
        if requestFunc then
            requestFunc({
                Url = updateUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        else
            HttpService:PostAsync(updateUrl, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
        end
    end)
    if not success then warn("⚠️ [Loverr-Ezx] Error: " .. tostring(err)) end
end

print("✅ Sailor Piece Script (Map #6) Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 20)
end
end
