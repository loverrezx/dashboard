local settings = getgenv()["loverr-ezx_Settings"]
local game_id = settings and settings.game_id or 1 
local base_url = "http://localhost:8080/" -- แก้ไข URL ให้ถูกต้องไม่มีช่องว่าง
local interval = settings and settings.Interval or 20 -- ดึงค่าความถี่จาก Config

local player = game:GetService("Players").LocalPlayer

local function updateStats() 
    local cashValue = 0 
   
    -- รอให้ leaderstats และ Cash โหลดเสร็จก่อน
    local leaderstats = player:FindFirstChild("leaderstats") 
    if leaderstats then
        local cashObj = leaderstats:FindFirstChild("Cash")
        if cashObj then
            cashValue = cashObj.Value
        end
    end
  
    local data = { 
        game_id = game_id, 
        pc_name = settings.PC or "Unknown", 
        username = player.Name, 
        cash = tostring(cashValue) 
    } 
  
    local jsonData = game:GetService("HttpService"):JSONEncode(data) 
     
    -- ส่งข้อมูล
    request({ 
        Url = base_url .. "services/update_stats.php", 
        Method = "POST", 
        Headers = { ["Content-Type"] = "application/json" }, 
        Body = jsonData
    })
end 
 
print("Loverr-EZX: [Driving Empire] Stats Script Loaded (High-Speed)") 
while true do 
    pcall(updateStats) 
    task.wait(interval) -- รันตามความถี่ที่ตั้งไว้ใน Config
end
