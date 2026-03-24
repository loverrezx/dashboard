-- [[ Anime Vanguards Dashboard Script - Super Robust Version ]] --
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

-- ฟังก์ชันดึงค่าจาก UI แบบปลอดภัย (หาด้วยชื่อหรือหา Amount)
local function getCurrencyValue(parent, name)
    local folder = parent:FindFirstChild(name)
    if folder and folder:FindFirstChild("Amount") then
        return folder.Amount.Text
    end
    -- ถ้าหาด้วยชื่อไม่เจอ ให้พยายามหาจากลูกตัวไหนก็ได้ที่มี Amount (Fallback)
    for _, child in ipairs(parent:GetChildren()) do
        if child:FindFirstChild("Amount") then
            -- เช็คเงื่อนไขเพิ่มเติมถ้าจำเป็น
            return child.Amount.Text
        end
    end
    return "0"
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
        
        -- ดึงเลเวลและตัดเอาเฉพาะตัวเลขหน้าวงเล็บ
        local levelLabel = main:WaitForChild("Level", 5):WaitForChild("Level", 5)
        local rawLevel = levelLabel.Text
        local cleanLevel = string.match(rawLevel, "^%d+") or rawLevel

        -- ดึงข้อมูลเงินแบบระบุตำแหน่งตามที่แจ้งมา (แต่เพิ่มการเช็ค nil)
        local children = currencies:GetChildren()
        local gems = (children[5] and children[5]:FindFirstChild("Amount")) and children[5].Amount.Text or "0"
        local gold = (children[7] and children[7]:FindFirstChild("Amount")) and children[7].Amount.Text or "0"
        local leaves = (children[6] and children[6]:FindFirstChild("Amount")) and children[6].Amount.Text or "0"
        local rerolls = (currencies:FindFirstChild("CurrencyFrame") and currencies.CurrencyFrame:FindFirstChild("Amount")) and currencies.CurrencyFrame.Amount.Text or "0"

        local payload = {
            ["game_id"] = settings.game_id,
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            ["level"] = cleanLevel,
            ["gems"] = gems,
            ["gold"] = gold,
            ["leaves"] = leaves,
            ["rerolls"] = rerolls,
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

print("✅ Anime Vanguards Script Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 20)
end
