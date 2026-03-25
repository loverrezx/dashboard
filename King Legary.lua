repeat task.wait() until game:IsLoaded()

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

if not getgenv()["loverr-ezx_Settings"] then
    warn("ไม่พบการตั้งค่า Config! กรุณาคัดลอก Config จากหน้าเว็บมาวางก่อนสคริปต์นี้")
    return
end

local settings = getgenv()["loverr-ezx_Settings"]
local baseUrl = settings.BaseUrl or "https://thanathipth.site/"
local updateUrl = tostring(baseUrl):gsub("/?$", "/") .. "services/update_stats.php"

local request = (syn and syn.request) or (http and http.request) or http_request or request
if not request then
    warn("request function not found")
    return
end

local function getValue(obj)
    if not obj then return 0 end
    local ok, v = pcall(function() return obj.Value end)
    if ok then return v end
    return 0
end

local function findDarkLeg()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild("DarkLeg") then
        return "DarkLeg"
    end
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("DarkLeg") then
        return "DarkLeg"
    end
    return "None"
end

local function getConfigValue(...)
    for i = 1, select("#", ...) do
        local k = select(i, ...)
        local v = settings[k]
        if v ~= nil and tostring(v) ~= "" then
            return v
        end
    end
    return nil
end

local function sendStats()
    local ok, err = pcall(function()
        local playerStats = LocalPlayer:WaitForChild("PlayerStats", 10)
        local leveling = LocalPlayer:WaitForChild("Leveling", 10)
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        if not (playerStats and leveling and leaderstats) then return end

        local keyValue = getConfigValue("key", "Key", "KEY", "user_key", "UserKey")
        if not keyValue then
            warn("Config ไม่ถูกต้อง: ไม่พบ key ใน loverr-ezx_Settings (เช่น key = \"USERNAME\")")
            return
        end

        local gameId = tonumber(getConfigValue("game_id", "gameId", "GameId", "GAME_ID") or 0) or 0
        local pcName = tostring(getConfigValue("PC", "pc", "Pc") or "Unknown")

        local payload = {
            ["game_id"] = gameId,
            ["key"] = tostring(keyValue),
            ["pc_name"] = pcName,
            ["username"] = tostring(LocalPlayer.Name),

            ["gems"] = tostring(getValue(playerStats:FindFirstChild("Gem"))),
            ["cash"] = tostring(getValue(playerStats:FindFirstChild("beli"))),
            ["level"] = tostring(getValue(playerStats:FindFirstChild("lvl"))),
            ["bounty"] = tostring(getValue(leaderstats:FindFirstChild("Bounty"))),
            ["fishing"] = tostring(getValue(leveling:FindFirstChild("Fishing"))),

            ["m_melee"] = tostring(getValue(playerStats:FindFirstChild("Melee"))),
            ["m_sword"] = tostring(getValue(playerStats:FindFirstChild("sword"))),
            ["m_defense"] = tostring(getValue(playerStats:FindFirstChild("Defense"))),

            ["melee"] = findDarkLeg()
        }

        local response = request({
            Url = updateUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })

        local status = response and (response.StatusCode or response.Status) or 0
        if tonumber(status) ~= 200 then
            warn("ส่งข้อมูลไม่สำเร็จ: " .. tostring(status))
            if response and response.Body then
                warn(tostring(response.Body))
            end
        end
    end)

    if not ok then
        warn("Error ในการส่งข้อมูล: " .. tostring(err))
    end
end

print("King Legacy Dashboard Script Started!")
while true do
    sendStats()
    task.wait(tonumber(getConfigValue("Interval", "interval") or 5) or 5)
end
