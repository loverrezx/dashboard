-- [[ Anime Vanguards Dashboard Script - Fix Mismatch Version ]] --
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

-- ฟังก์ชันดึงตัวเลขจากข้อความ (ใช้ดึง Level และลบลูกน้ำออก)
local function cleanNumber(txt)
    if not txt then return "0" end
    local num = string.match(txt, "%d+%,?%d*%,?%d*") or "0"
    return num:gsub(",", "") -- ลบลูกน้ำออกเพื่อให้ระบบคำนวณได้
end

local function getUnits()
    local units = {}
    pcall(function()
        local path = LocalPlayer.PlayerGui.Windows.GlobalInventory.Holder.LeftContainer.FakeScrollingFrame.Items.CacheContainer
        for _, item in ipairs(path:GetChildren()) do
            local unitNameObj = item:FindFirstChild("UnitName", true)
            if unitNameObj and unitNameObj.Text ~= "" then
                table.insert(units, unitNameObj.Text)
            end
        end
    end)
    return table.concat(units, ", ")
end

local function sendStats()
    local success, err = pcall(function()
        local hud = LocalPlayer.PlayerGui:WaitForChild("HUD", 10)
        local main = hud:WaitForChild("Main", 10)
        local currencies = main:WaitForChild("Currencies", 10)
        
        -- 1. ดึง Level (ดึงเฉพาะตัวเลขจากข้อความใดๆ เช่น "Level 1 (0/350)" -> "1")
        local rawLevel = main:WaitForChild("Level", 5):WaitForChild("Level", 5).Text
        local cleanLevel = string.match(rawLevel, "%d+") or "0"

        -- 2. ดึงข้อมูลเงิน (พยายามหาตามโครงสร้างที่แน่นอน)
        local gems = "0"
        local gold = "0"
        local leaves = "0"
        local rerolls = "0"

        -- ดึง Gems, Gold, Leaves จากลำดับ (ปรับตามที่เห็นใน Dashboard ว่า Gems ไปอยู่ช่อง 6)
        local children = currencies:GetChildren()
        -- ลองไล่ลำดับใหม่ตามที่ข้อมูลโผล่ผิด
        gems = (children[6] and children[6]:FindFirstChild("Amount")) and children[6].Amount.Text or "0"
        gold = (children[5] and children[5]:FindFirstChild("Amount")) and children[5].Amount.Text or "0"
        leaves = (children[7] and children[7]:FindFirstChild("Amount")) and children[7].Amount.Text or "0"
        
        -- Rerolls ดึงจากชื่อ Path โดยตรง
        local rrObj = currencies:FindFirstChild("CurrencyFrame")
        if rrObj and rrObj:FindFirstChild("Amount") then
            rerolls = rrObj.Amount.Text
        end

        local payload = {
            ["game_id"] = settings.game_id,
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            ["level"] = cleanLevel,
            ["gems"] = cleanNumber(gems),
            ["gold"] = cleanNumber(gold),
            ["leaves"] = cleanNumber(leaves),
            ["rerolls"] = cleanNumber(rerolls),
            ["units"] = getUnits()
        }

        request({
            Url = updateUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    if not success then warn("⚠️ Error: " .. tostring(err)) end
end

print("✅ Anime Vanguards Script (Fix Mismatch) Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 20)
end
