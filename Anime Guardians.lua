-- [[ Anime Guardians Real-time Dashboard Script ]] --
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
local baseUrl = settings.BaseUrl or "https://thanathipth.site/"
local updateUrl = baseUrl .. "services/update_stats.php"

-- ฟังก์ชันหลักในการส่งข้อมูล
local function sendStats()
    local success, err = pcall(function()
        -- รอข้อมูลสำคัญโหลด (ป้องกัน Error ตอนเริ่มเกม)
        local data = LocalPlayer:WaitForChild("Data", 10)
        
        if not data then 
            warn("⚠️ ไม่พบโฟลเดอร์ Data ในตัวละคร")
            return 
        end

        local payload = {
            ["game_id"] = settings.game_id,
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            
            -- ข้อมูลที่ต้องการดึง
            ["level"] = data:WaitForChild("Levels").Value,
            ["cash"] = tostring(data:WaitForChild("Coins").Value), -- ส่ง Coins เข้าช่อง Cash
            ["tokens"] = tostring(data:WaitForChild("Tokens").Value),
            ["moonnight"] = tostring(data:WaitForChild("MoonNight").Value),
            ["mushroom"] = tostring(data:WaitForChild("Mushroom").Value)
        }

        local jsonPayload = HttpService:JSONEncode(payload)
        
        -- ส่งข้อมูลไปยังเซิร์ฟเวอร์
        local response = request({
            Url = updateUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = jsonPayload
        })

        if response.StatusCode ~= 200 then
            warn("⚠️ ส่งข้อมูลไม่สำเร็จ (Status: " .. tostring(response.StatusCode) .. ")")
        end
    end)

    if not success then
        warn("❌ Error ในการส่งข้อมูล: " .. tostring(err))
    end
end

-- เริ่มทำงานวนลูปตามวินาทีที่กำหนด
print("✅ Anime Guardians Dashboard Script Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 5)
end
