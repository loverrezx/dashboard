repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Settings = getgenv()["loverr-ezx_Settings"]
if not Settings then
    warn("[loverr-ezx] missing config: getgenv()[\"loverr-ezx_Settings\"]")
    return
end

local BASE_URL = tostring(Settings.BaseUrl or "https://thanathipth.site/")
if BASE_URL ~= "" and not BASE_URL:match("/$") then
    BASE_URL = BASE_URL .. "/"
end

local ENDPOINT = BASE_URL .. "services/update_stats.php"

local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
if not requestFn then
    warn("[loverr-ezx] request function not found")
    return
end

local function waitChild(parent, name, timeout)
    if not parent then return nil end
    return parent:WaitForChild(name, timeout or 5)
end

local function safeFind(pathArray)
    local obj = LocalPlayer
    for _, childName in ipairs(pathArray) do
        if not obj then return nil end
        obj = obj:FindFirstChild(childName)
    end
    return obj
end

local function valueOf(v)
    if not v then return 0 end
    local ok, val = pcall(function()
        if v.Value ~= nil then return v.Value end
        return tostring(v)
    end)
    if not ok then return 0 end
    return val
end

local function toNumberClean(x)
    local s = tostring(x or "0"):gsub("[^%d%.]", "")
    return s == "" and "0" or s
end

local function getDarkLeg()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return "None" end
    local darkLeg = backpack:FindFirstChild("DarkLeg")
    if darkLeg then
        return "DarkLeg"
    end
    local character = LocalPlayer.Character
    if character then
        local held = character:FindFirstChild("DarkLeg")
        if held then
            return "DarkLeg"
        end
    end
    return "None"
end

local function collectData()
    local playerStats = waitChild(LocalPlayer, "PlayerStats", 10)
    local leveling = waitChild(LocalPlayer, "Leveling", 10)
    local leaderstats = waitChild(LocalPlayer, "leaderstats", 10)

    local gemObj = playerStats and (playerStats:FindFirstChild("Gem") or playerStats:FindFirstChild("Gems"))
    local beliObj = playerStats and (playerStats:FindFirstChild("beli") or playerStats:FindFirstChild("Beli"))
    local lvlObj = playerStats and (playerStats:FindFirstChild("lvl") or playerStats:FindFirstChild("Level"))
    local bountyObj = leaderstats and leaderstats:FindFirstChild("Bounty")
    local fishingObj = leveling and leveling:FindFirstChild("Fishing")

    local meleeStatObj = playerStats and playerStats:FindFirstChild("Melee")
    local swordStatObj = playerStats and (playerStats:FindFirstChild("sword") or playerStats:FindFirstChild("Sword"))
    local defenseStatObj = playerStats and (playerStats:FindFirstChild("Defense") or playerStats:FindFirstChild("defense"))

    local payload = {
        key = tostring(Settings.key or ""),
        game_id = tonumber(Settings.game_id) or 0,
        pc_name = tostring(Settings.PC or "Unknown"),
        username = tostring(LocalPlayer.Name),

        cash = toNumberClean(valueOf(beliObj)),
        gems = toNumberClean(valueOf(gemObj)),
        level = toNumberClean(valueOf(lvlObj)),
        bounty = toNumberClean(valueOf(bountyObj)),
        fishing = toNumberClean(valueOf(fishingObj)),

        m_melee = toNumberClean(valueOf(meleeStatObj)),
        m_sword = toNumberClean(valueOf(swordStatObj)),
        m_defense = toNumberClean(valueOf(defenseStatObj)),

        melee = getDarkLeg()
    }

    return payload
end

local function sendOnce()
    local body = HttpService:JSONEncode(collectData())

    local ok, res = pcall(function()
        return requestFn({
            Url = ENDPOINT,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = body
        })
    end)

    if not ok then
        warn("[loverr-ezx] send failed:", res)
        return
    end

    if not res then
        warn("[loverr-ezx] empty response")
        return
    end

    local status = res.StatusCode or res.Status or 0
    if tonumber(status) ~= 200 then
        warn("[loverr-ezx] http status:", tostring(status))
        if res.Body then
            warn("[loverr-ezx] body:", tostring(res.Body))
        end
    end
end

local interval = tonumber(Settings.Interval) or 20
warn("[loverr-ezx] King Legacy started | endpoint:", ENDPOINT)
while task.wait(interval) do
    sendOnce()
end
