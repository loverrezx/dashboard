-- [[ Blox Fruit Real-time Dashboard Script ]] --
repeat task.wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ตรวจสอบการตั้งค่า Config
if not getgenv()["loverr-ezx_Settings"] then
    warn("❌ ไม่พบการตั้งค่า Config! กรุณาคัดลอก Config จากหน้าเว็บมาวางก่อนสคริปต์นี้")
    return
end

local settings = getgenv()["loverr-ezx_Settings"]
local baseUrl = settings.BaseUrl or "https://thanathipth.site/Dashboard%20Loverr_ezx/"
local updateUrl = baseUrl .. "services/update_stats.php"

-- ฟังก์ชันดึงข้อมูลผลไม้ในกระเป๋า
local function getFruits()
    local fruits = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            -- ดึงชื่อที่มีคำว่า "Fruit" หรือมีเครื่องหมาย "-"
            if item.Name:find("Fruit") or item.Name:find("-") then
                table.insert(fruits, item.Name)
            end
        end
    end
    -- ดึงจากตัวที่ถืออยู่ด้วย (ถ้ามี)
    local character = LocalPlayer.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") and (item.Name:find("Fruit") or item.Name:find("-")) then
                table.insert(fruits, item.Name)
            end
        end
    end
    return table.concat(fruits, ", ")
end

-- ฟังก์ชันหลักในการส่งข้อมูล
local function sendStats()
    local success, err = pcall(function()
        -- รอข้อมูลสำคัญโหลด (ป้องกัน Error ตอนเริ่มเกม)
        local data = LocalPlayer:WaitForChild("Data", 5)
        local stats = data and data:WaitForChild("Stats", 5)
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 5)

        if not (data and stats and leaderstats) then return end

        local payload = {
            ["game_id"] = settings.game_id,
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            
            -- ข้อมูลหลัก
            ["cash"] = tostring(data:WaitForChild("Beli").Value), -- ส่ง Beli เข้าช่อง Cash
            ["level"] = data:WaitForChild("Level").Value,
            ["race"] = data:WaitForChild("Race").Value,
            ["bounty"] = tostring(leaderstats:WaitForChild("Bounty/Honor").Value),
            
            -- ข้อมูล Mastery
            ["m_melee"] = stats:WaitForChild("Melee"):WaitForChild("Level").Value,
            ["m_defense"] = stats:WaitForChild("Defense"):WaitForChild("Level").Value,
            ["m_sword"] = stats:WaitForChild("Sword"):WaitForChild("Level").Value,
            ["m_gun"] = stats:WaitForChild("Gun"):WaitForChild("Level").Value,
            ["m_fruit"] = stats:WaitForChild("Demon Fruit"):WaitForChild("Level").Value,
            
            -- ข้อมูลผลไม้
            ["fruits"] = getFruits()
        }

        local jsonPayload = HttpService:JSONEncode(payload)
        local response = request({
            Url = updateUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonPayload
        })

        if response.StatusCode ~= 200 then
            warn("⚠️ ส่งข้อมูลไม่สำเร็จ: " .. tostring(response.StatusCode))
        end
    end)

    if not success then
        warn("❌ Error ในการส่งข้อมูล: " .. tostring(err))
    end
end

-- เริ่มทำงานวนลูปตามวินาทีที่กำหนด
print("✅ Blox Fruit Dashboard Script Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 5)
end
