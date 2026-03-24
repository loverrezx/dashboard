-- [[ Sailor Piece Dashboard Script - Map #6 ]] --
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

-- ฟังก์ชันล้างตัวเลข (ลบลูกน้ำและสัญลักษณ์)
local function cleanNumber(txt)
    if not txt then return "0" end
    if typeof(txt) == "number" then return tostring(txt) end
    local num = string.match(tostring(txt), "%d+%,?%d*%,?%d*") or "0"
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
    
    -- ดึงจาก Storage (InventoryPanelUI)
    pcall(function()
        local storage = LocalPlayer.PlayerGui.InventoryPanelUI.MainFrame.Frame.Content.Holder.StorageHolder.Storage
        for _, item in ipairs(storage:GetChildren()) do
            local itemName = formatItemName(item.Name)
            -- แยกหมวดหมู่ (Sword / Melee / Items)
            if itemName == "Dark Blade" or itemName == "Katana" then
                table.insert(swords, itemName)
            elseif itemName == "Combat" then
                table.insert(melee, itemName)
            else
                table.insert(items, itemName)
            end
        end
    end)
    
    -- ดึงจาก Backpack
    pcall(function()
        for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
            table.insert(items, tool.Name)
        end
    end)
    
    return table.concat(swords, ", "), table.concat(melee, ", "), table.concat(items, ", ")
end

local function sendStats()
    local success, err = pcall(function()
        -- ตำแหน่งข้อมูลตามที่ระบุ
        local data = LocalPlayer:WaitForChild("Data", 10)
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        
        local money = data:WaitForChild("Money", 5).Value
        local gems = data:WaitForChild("Gems", 5).Value
        local level = data:WaitForChild("Level", 5).Value
        local statPoints = data:WaitForChild("StatPoints", 5).Value
        local bounty = leaderstats:WaitForChild("Bounty", 5).Value
        
        local swords, melee, items = getInventoryData()

        local payload = {
            ["game_id"] = 6, -- Sailor Piece (Map #6)
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

        -- ส่งข้อมูลแบบ POST
        local reqFunc = (syn and syn.request) or (http and http.request) or request
        if reqFunc then
            reqFunc({
                Url = updateUrl,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        else
            HttpService:PostAsync(updateUrl, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
        end
    end)
    if not success then warn("⚠️ Error: " .. tostring(err)) end
end

print("✅ Sailor Piece Script (Map #6) Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 20)
end
