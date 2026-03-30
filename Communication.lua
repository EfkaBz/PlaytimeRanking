-- ============================================================================
-- Communication.lua - Messages découpés pour éviter la limite 255 caractères
-- ============================================================================

PTR = PTR or {}
PTR.Comm = {}

function PTR.Comm.RegisterPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PTR.PREFIX)
    end
end

-- ============================================================================
-- BROADCAST - Envoyer 1 message par perso
-- ============================================================================

function PTR.Comm.BroadcastMyData()
    local accountName = PTR.GetCurrentMainPlayerName()
    if not accountName then return end
    
    local entry = PlaytimeRankingDB.players[accountName]
    if not entry then return end
    
    -- Collecter tous les messages à envoyer
    local messages = {}
    for charKey, charData in pairs(entry.characters) do
        local safeName = (charData.name or ""):gsub("|", "~")
        local safeRealm = (charData.realm or ""):gsub("|", "~")
        local safeClass = (charData.classFile or "UNKNOWN"):gsub("|", "~")
        
        local payload = string.format("%s|%s|%s|%s|%s|%d|%d",
            accountName,
            charKey,
            safeName,
            safeRealm,
            safeClass,
            charData.level or 1,
            charData.played or 0
        )
        table.insert(messages, payload)
    end
    
    -- Envoyer avec délai de 0.15s entre chaque message
    local delay = 0
    for _, payload in ipairs(messages) do
        C_Timer.After(delay, function()
            if IsInGuild() then
                PTR.Comm.SendMessage(payload, "GUILD")
            end
        end)
        delay = delay + 0.15
    end
    
    PlaytimeRankingDB.config.lastBroadcast = time()
end

function PTR.Comm.SendMessage(message, channel, target)
    if not message or message == "" then return end
    
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        local success = C_ChatInfo.SendAddonMessage(PTR.PREFIX, message, channel, target)
        if channel == "PARTY" then
            PTR.Print("Envoi PARTY: " .. tostring(success))
        end
    end
end

-- ============================================================================
-- RECEIVE - Recevoir 1 perso à la fois
-- ============================================================================

function PTR.Comm.ReceiveData(message, sender)
    if not message or message == "" then return end
    
    -- Format: accountName|charKey|name|realm|classFile|level|played
    local parts = {}
    for part in string.gmatch(message, "[^|]+") do 
        table.insert(parts, part) 
    end
    
    if #parts < 7 then return end
    
    local accountName = parts[1]
    local charKey = parts[2]
    local name = parts[3]
    local realm = parts[4]
    local classFile = parts[5]
    local level = tonumber(parts[6]) or 1
    local played = tonumber(parts[7]) or 0
    
    local entry = PTR.DB.EnsurePlayerEntry(accountName)
    
    -- Ajouter OU mettre à jour si plus de temps
    if not entry.characters[charKey] or (entry.characters[charKey].played or 0) < played then
        entry.characters[charKey] = {
            name = name,
            realm = realm,
            classFile = classFile,
            level = level,
            played = played,
            owner = accountName,
            lastSeen = time()
        }
        
        -- Recalculer le total
        local total = 0
        for _, charData in pairs(entry.characters) do
            total = total + (tonumber(charData.played) or 0)
        end
        entry.totalPlayed = total
        entry.lastUpdate = time()
        
        PTR.Achievements.CheckAchievements(accountName)
        
        -- Refresh UI
        if PTR.UI.mainFrame and PTR.UI.mainFrame:IsShown() then
            C_Timer.After(0.5, function()
                PTR.UI.RefreshMainFrame()
            end)
        end
    end
end