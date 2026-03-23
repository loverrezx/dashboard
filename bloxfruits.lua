local settings = getgenv()["loverr-ezx_Settings"]
local game_id = settings and settings.game_id or 1 
local base_url = "http://localhost:8080/" 
local interval = settings and settings.Interval or 20

local player = game:GetService("Players").LocalPlayer

local function getFruits()
    local fruits = {}
    for _, item in pairs(player.Backpack:GetChildren()) do
        if string.find(item.Name, "Fruit") or string.find(item.Name, "-") then
            table.insert(fruits, item.Name)
        end
    end
    return table.concat(fruits, ", ")
end

local function updateStats() 
    local data = { 
        game_id = game_id, 
        pc_name = settings.PC or "Unknown", 
        username = player.Name, 
        cash = tostring(player.leaderstats.Money.Value),
        level = player.Data.Level.Value,
        race = player.Data.Race.Value,
        bounty = tostring(player.leaderstats["Bounty/Honor"].Value),
        m_melee = player.Data.Stats.Melee.Level.Value,
        m_defense = player.Data.Stats.Defense.Level.Value,
        m_sword = player.Data.Stats.Sword.Level.Value,
        m_gun = player.Data.Stats.Gun.Level.Value,
        m_fruit = player.Data.Stats["Demon Fruit"].Level.Value,
        fruits = getFruits()
    } 
  
    local jsonData = game:GetService("HttpService"):JSONEncode(data) 
     
    pcall(function()
        request({ 
            Url = base_url .. "services/update_stats.php", 
            Method = "POST", 
            Headers = { ["Content-Type"] = "application/json" }, 
            Body = jsonData
        })
    end)
end 
 
print("Loverr-EZX: [Blox Fruit] Stats Script Loaded") 
while true do 
    pcall(updateStats) 
    task.wait(interval)
end
