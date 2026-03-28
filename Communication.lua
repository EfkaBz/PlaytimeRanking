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
    
    -- Envoyer UN message par personnage (encodé pour les accents)
    for charKey, charData in pairs(entry.characters) do
        -- Remplacer les | par ~ pour éviter les conflits
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
        
        -- TOUJOURS envoyer sur GUILD
        if IsInGuild() then
            PTR.Comm.SendMessage(payload, "GUILD")
        end
        
        -- Pour les non-guild : canal WHISPER entre comptes
        -- Note : PARTY ne fonctionne pas en TBC Anniversary
        -- Il faut que tous les comptes soient dans la même guilde
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
