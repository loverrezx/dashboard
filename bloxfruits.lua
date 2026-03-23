local settings = getgenv()["loverr-ezx_Settings"]
local game_id = settings and settings.game_id or 1 
local base_url = settings and settings.BaseUrl or "http://localhost:8080/"
local interval = settings and settings.Interval or 20

local player = game:GetService("Players").LocalPlayer

-- ฟังก์ชันดึงค่าแบบปลอดภัย (ป้องกันสคริปต์หลุดถ้าข้อมูลยังไม่โหลด)
local function getVal(parent, path, default)
    local current = parent
    for _, part in pairs(path) do
        if current and current:FindFirstChild(part) then
            current = current[part]
        else
            return default
        end
    end
    return (current and current:IsA("ValueBase")) and current.Value or default
end

local function getFruits()
    local fruits = {}
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if string.find(item.Name, "Fruit") or string.find(item.Name, "-") then
                table.insert(fruits, item.Name)
            end
        end
    end
    return table.concat(fruits, ", ")
end

local function updateStats() 
    local data = { 
        game_id = game_id, 
        pc_name = settings.PC or "Unknown", 
        username = player.Name, 
        cash = tostring(getVal(player, {"leaderstats", "Money"}, "0")),
        level = getVal(player, {"Data", "Level"}, 0),
        race = getVal(player, {"Data", "Race"}, "N/A"),
        bounty = tostring(getVal(player, {"leaderstats", "Bounty/Honor"}, "0")),
        m_melee = getVal(player, {"Data", "Stats", "Melee", "Level"}, 0),
        m_defense = getVal(player, {"Data", "Stats", "Defense", "Level"}, 0),
        m_sword = getVal(player, {"Data", "Stats", "Sword", "Level"}, 0),
        m_gun = getVal(player, {"Data", "Stats", "Gun", "Level"}, 0),
        m_fruit = getVal(player, {"Data", "Stats", "Demon Fruit", "Level"}, 0),
        fruits = getFruits()
    } 
  
    local jsonData = game:GetService("HttpService"):JSONEncode(data) 
     
    local success, res = pcall(function()
        return request({ 
            Url = base_url .. "services/update_stats.php", 
            Method = "POST", 
            Headers = { ["Content-Type"] = "application/json" }, 
            Body = jsonData
        })
    end)

    if success then
        print("Loverr-EZX: Update Sent! (Status: " .. tostring(res.StatusCode) .. ")")
    else
        warn("Loverr-EZX: Request Failed! " .. tostring(res))
    end
end 
 
print("Loverr-EZX: [Blox Fruit] Super Robust Script Loaded") 
while true do 
    pcall(updateStats) 
    task.wait(interval)
end
