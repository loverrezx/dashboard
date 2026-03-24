-- [[ Anime Vanguards Real-time Dashboard Script - Updated ]] --
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

-- ฟังก์ชันดึงรายชื่อ Units (ดึงชื่อจาก UnitName)
local function getUnits()
    local units = {}
    local success, _ = pcall(function()
        local path = LocalPlayer.PlayerGui.Windows.GlobalInventory.Holder.LeftContainer.FakeScrollingFrame.Items.CacheContainer
        for _, item in ipairs(path:GetChildren()) do
            -- ค้นหาออบเจ็กต์ที่มีชื่อว่า "UnitName" (แบบค้นหาลึกลงไป)
            local unitNameObj = item:FindFirstChild("UnitName", true)
            if unitNameObj and (unitNameObj:IsA("TextLabel") or unitNameObj:IsA("TextBox")) then
                if unitNameObj.Text ~= "" then
                    table.insert(units, unitNameObj.Text)
                end
            end
        end
    end)
    return table.concat(units, ", ")
end

-- ฟังก์ชันหลักในการส่งข้อมูล
local function sendStats()
    local success, err = pcall(function()
        local mainGui = LocalPlayer.PlayerGui:WaitForChild("HUD"):WaitForChild("Main")
        local currencies = mainGui:WaitForChild("Currencies")
        
        -- 1. ดึง Level และตัดเอาเฉพาะตัวเลขหน้าวงเล็บ (เช่น "100 (99%)" จะเหลือแค่ "100")
        local rawLevel = mainGui:WaitForChild("Level"):WaitForChild("Level").Text
        local cleanLevel = string.match(rawLevel, "^%d+") or rawLevel

        -- 2. ดึงข้อมูล Currencies ตาม Path
        local gems = currencies:GetChildren()[5].Amount.Text
        local gold = currencies:GetChildren()[7].Amount.Text
        local leaves = currencies:GetChildren()[6].Amount.Text
        local rerolls = currencies.CurrencyFrame.Amount.Text

        local payload = {
            ["game_id"] = settings.game_id,
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            
            -- ส่งข้อมูลไปยัง Dashboard
            ["level"] = cleanLevel,
            ["gems"] = gems,
            ["gold"] = gold,
            ["leaves"] = leaves,
            ["rerolls"] = rerolls,
            ["units"] = getUnits()
        }

        local jsonPayload = HttpService:JSONEncode(payload)
        
        -- ส่งข้อมูลแบบ POST
        local response = request({
            Url = updateUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = jsonPayload
        })
    end)

    if not success then
        warn("❌ Error ในการดึงข้อมูล/ส่งข้อมูล: " .. tostring(err))
    end
end

-- เริ่มทำงานวนลูปตามวินาทีที่กำหนด
print("✅ Anime Vanguards Dashboard Script (Updated Level Logic) Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 5)
end
