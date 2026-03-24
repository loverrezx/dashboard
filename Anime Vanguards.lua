-- [[ Anime Vanguards Dashboard Script - Level & Column Fix ]] --
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
    local num = string.match(txt, "%d+%,?%d*%,?%d*") or "0"
    return num:gsub(",", "")
end

-- ฟังก์ชันดึง Level (ดึงเฉพาะตัวเลขที่อยู่นอกวงเล็บ)
local function getCleanLevel(rawText)
    if not rawText then return "0" end
    -- 1. ลบสิ่งที่อยู่ในวงเล็บออกทั้งหมด (รวมถึงตัววงเล็บเอง)
    local noParentheses = rawText:gsub("%b()", "")
    -- 2. ดึงเฉพาะตัวเลขที่เหลืออยู่
    local level = string.match(noParentheses, "%d+") or "0"
    return level
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
        
        -- ดึง Level และใช้ฟังก์ชันตัดวงเล็บ
        local rawLevel = main:WaitForChild("Level", 5):WaitForChild("Level", 5).Text
        local cleanLevel = getCleanLevel(rawLevel)

        -- ดึงข้อมูลเงิน (ปรับลำดับ Index ตามที่คุณแจ้งว่า Gems ไปอยู่ช่อง Leaves)
        local children = currencies:GetChildren()
        
        -- ลำดับที่ปรับใหม่เพื่อให้ตรงช่อง:
        local gems = (children[6] and children[6]:FindFirstChild("Amount")) and children[6].Amount.Text or "0"
        local gold = (children[5] and children[5]:FindFirstChild("Amount")) and children[5].Amount.Text or "0"
        local leaves = (children[7] and children[7]:FindFirstChild("Amount")) and children[7].Amount.Text or "0"
        
        -- Rerolls ดึงจากชื่อ Path โดยตรง (เสถียรที่สุด)
        local rerolls = "0"
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

print("✅ Anime Vanguards Script (Level & Column Fix) Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 20)
end
