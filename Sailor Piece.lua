-- [[ Sailor Piece Dashboard Script (Map #6) - Full Fix ]] --
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

local function cleanNumber(txt)
    if not txt or txt == "" then return "1" end
    local num = tostring(txt):gsub("x", ""):match("%d+")
    return (not num or num == "") and "1" or num
end

local function getCleanLevel(rawText)
    if not rawText then return "0" end
    local noParentheses = tostring(rawText):gsub("%b()", "")
    return string.match(noParentheses, "%d+") or "0"
end

local function formatItemName(name)
    return name:sub(1, 5) == "Item_" and name:sub(6) or name
end

local function getInventoryData()
    local swords, melee, items = {}, {}, {}
    
    -- ดึงจาก Storage
    pcall(function()
        local storage = LocalPlayer.PlayerGui.InventoryPanelUI.MainFrame.Frame.Content.Holder.StorageHolder.Storage
        for _, item in ipairs(storage:GetChildren()) do
            local itemName = formatItemName(item.Name)
            local qty = "1"
            local qtyObj = item:FindFirstChild("Slot") and item.Slot:FindFirstChild("Holder") and item.Slot.Holder:FindFirstChild("Quantity")
            if qtyObj and qtyObj:IsA("TextLabel") and qtyObj.Text ~= "" then
                qty = cleanNumber(qtyObj.Text)
            end
            
            if itemName == "Dark Blade" or itemName == "Katana" then
                table.insert(swords, itemName)
            elseif itemName == "Combat" then
                table.insert(melee, itemName)
            else
                table.insert(items, itemName .. "|" .. qty)
            end
        end
    end)
    
    -- ดึงจาก Backpack
    pcall(function()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                local itemName = tool.Name
                if itemName == "Dark Blade" or itemName == "Katana" then
                    if not table.find(swords, itemName) then table.insert(swords, itemName) end
                elseif itemName == "Combat" then
                    if not table.find(melee, itemName) then table.insert(melee, itemName) end
                else
                    table.insert(items, itemName .. "|1")
                end
            end
        end
    end)
    
    return table.concat(swords, ", "), table.concat(melee, ", "), table.concat(items, ", ")
end

local function sendStats()
    local success, err = pcall(function()
        local data = LocalPlayer:WaitForChild("Data", 10)
        local leaderstats = LocalPlayer:WaitForChild("leaderstats", 10)
        
        local swords, melee, items = getInventoryData()
        local payload = {
            ["game_id"] = settings.game_id or 6,
            ["key"] = settings.key,
            ["pc_name"] = settings.PC,
            ["username"] = LocalPlayer.Name,
            ["cash"] = tostring(data:WaitForChild("Money", 5).Value),
            ["gems"] = tostring(data:WaitForChild("Gems", 5).Value),
            ["level"] = getCleanLevel(data:WaitForChild("Level", 5).Value),
            ["stat_points"] = tostring(data:WaitForChild("StatPoints", 5).Value),
            ["bounty"] = tostring(leaderstats:WaitForChild("Bounty", 5).Value),
            ["swords"] = swords,
            ["melee"] = melee,
            ["items"] = items
        }

        local req = (syn and syn.request) or (http and http.request) or request
        if req then
            req({Url = updateUrl, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = HttpService:JSONEncode(payload)})
        else
            HttpService:PostAsync(updateUrl, HttpService:JSONEncode(payload), Enum.HttpContentType.ApplicationJson)
        end
    end)
end

print("✅ Sailor Piece Script (Map #6) Started!")
while true do
    sendStats()
    task.wait(settings.Interval or 20)
end
