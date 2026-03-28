-- ============================================================================
-- Database.lua
-- ============================================================================

PTR = PTR or {}
PTR.DB = {}

function PTR.DB.Init()
    if not PlaytimeRankingDB then PlaytimeRankingDB = {} end
    if not PlaytimeRankingDB.config then
        PlaytimeRankingDB.config = {
            mainPlayerName = "",
            achievementStepHours = 500,
            minimapAngle = 220,
            minimapHide = false,
            autoRequestPlayed = true,
            firstTimeSetupDone = false,
            lastBroadcast = 0
        }
    end
    if not PlaytimeRankingDB.players then PlaytimeRankingDB.players = {} end
    if not PlaytimeRankingDB.expandedPlayers then PlaytimeRankingDB.expandedPlayers = {} end
end

function PTR.DB.EnsurePlayerEntry(accountName)
    if not PlaytimeRankingDB.players[accountName] then
        PlaytimeRankingDB.players[accountName] = {
            totalPlayed = 0,
            achievements = {},
            characters = {},
            lastUpdate = 0
        }
    end
    return PlaytimeRankingDB.players[accountName]
end

function PTR.DB.UpdateCurrentCharacter(totalPlayed)
    local accountName = PTR.GetCurrentMainPlayerName()
    if not accountName then return end
    
    local realm = GetRealmName()
    local name = UnitName("player")
    local _, classFile = UnitClass("player")
    local level = UnitLevel("player")
    local charKey = PTR.GetCharKey(name, realm)
    
    local entry = PTR.DB.EnsurePlayerEntry(accountName)
    entry.characters[charKey] = {
        name = name,
        realm = realm,
        classFile = classFile or "UNKNOWN",
        level = level,
        played = totalPlayed,
        owner = accountName,
        lastSeen = time()
    }
    PTR.DB.RebuildPlayerTotal(accountName)
end

function PTR.DB.RebuildPlayerTotal(accountName)
    local entry = PTR.DB.EnsurePlayerEntry(accountName)
    local total = 0
    for _, charData in pairs(entry.characters) do
        total = total + (tonumber(charData.played) or 0)
    end
    entry.totalPlayed = total
    entry.lastUpdate = time()
    PTR.Achievements.CheckAchievements(accountName)
end

function PTR.DB.SerializePlayer(accountName)
    local entry = PlaytimeRankingDB.players[accountName]
    if not entry then return nil end
    local charStrings = {}
    for charKey, charData in pairs(entry.characters) do
        table.insert(charStrings, string.format("%s^%s^%s^%s^%d^%d",
            charKey, charData.name or "", charData.realm or "", charData.classFile or "UNKNOWN",
            charData.level or 1, charData.played or 0))
    end
    return accountName .. "|" .. entry.totalPlayed .. "|" .. entry.lastUpdate .. "|" .. table.concat(charStrings, "~")
end

function PTR.DB.DeserializePlayer(payload)
    local parts = {}
    for part in string.gmatch(payload, "[^|]+") do table.insert(parts, part) end
    if #parts < 3 then return nil end
    
    local accountName = parts[1]
    local totalPlayed = tonumber(parts[2]) or 0
    local lastUpdate = tonumber(parts[3]) or 0
    local charactersData = parts[4] or ""
    
    local entry = PTR.DB.EnsurePlayerEntry(accountName)
    
    
    entry.totalPlayed = totalPlayed
    entry.lastUpdate = lastUpdate
    
   for charString in string.gmatch(charactersData, "[^~]+") do
    local charParts = {}
    for p in string.gmatch(charString, "[^^]+") do table.insert(charParts, p) end
    if #charParts >= 6 then
        local charKey = charParts[1]
        local newPlayed = tonumber(charParts[6]) or 0
        
        -- NE PAS écraser si le perso existe déjà avec plus de temps
        if not entry.characters[charKey] or (entry.characters[charKey].played or 0) < newPlayed then
            entry.characters[charKey] = {
                name = charParts[2],
                realm = charParts[3],
                classFile = charParts[4],
                level = tonumber(charParts[5]) or 1,
                played = newPlayed,
                owner = accountName,
                lastSeen = lastUpdate
            }
        end
    end
end
    PTR.Achievements.CheckAchievements(accountName)
    return accountName
end

function PTR.DB.CountCharacters(tbl)
    local count = 0
    for _ in pairs(tbl) do count = count + 1 end
    return count
end

function PTR.DB.SecondsToReadable(sec)
    sec = tonumber(sec) or 0
    local totalHours = math.floor(sec / 3600)
    local days = math.floor(totalHours / 24)
    local hours = totalHours % 24
    local mins = math.floor((sec % 3600) / 60)
    if days > 0 then
        return string.format("%dj %dh %dm", days, hours, mins)
    elseif totalHours > 0 then
        return string.format("%dh %dm", totalHours, mins)
    else
        return string.format("%dm", mins)
    end
end

function PTR.DB.GetSortedPlayers()
    local sorted = {}
    for accountName, data in pairs(PlaytimeRankingDB.players) do
        table.insert(sorted, {name = accountName, totalPlayed = data.totalPlayed or 0, data = data})
    end
    table.sort(sorted, function(a, b) return a.totalPlayed > b.totalPlayed end)
    return sorted
end
