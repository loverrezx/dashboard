local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Settings = getgenv()["loverr-ezx_Settings"] or {}
local BASE_URL = tostring(Settings.BaseUrl or "")
if BASE_URL ~= "" and not BASE_URL:match("/$") then
    BASE_URL = BASE_URL .. "/"
end

local ENDPOINT = BASE_URL .. "services/update_stats.php"

local requestFn = (syn and syn.request) or (http and http.request) or http_request or request
if not requestFn then
    warn("[loverr-ezx] request function not found")
    return
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
    return "None"
end

local function collectData()
    local gemObj = safeFind({"PlayerStats", "Gem"})
    local beliObj = safeFind({"PlayerStats", "beli"})
    local lvlObj = safeFind({"PlayerStats", "lvl"})
    local bountyObj = safeFind({"leaderstats", "Bounty"})
    local fishingObj = safeFind({"Leveling", "Fishing"})

    local meleeStatObj = safeFind({"PlayerStats", "Melee"})
    local swordStatObj = safeFind({"PlayerStats", "sword"})
    local defenseStatObj = safeFind({"PlayerStats", "Defense"})

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
end

local interval = tonumber(Settings.Interval) or 20
while task.wait(interval) do
    sendOnce()
end
