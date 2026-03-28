-- ============================================================================
-- Achievements.lua - Système de hauts faits
-- ============================================================================

PTR = PTR or {}
PTR.Achievements = {}

-- ============================================================================
-- PALIERS ET TITRES (10 niveaux)
-- ============================================================================

local TIERS = {
    { hours = 500,   title = "Explorateur",   color = {0.5, 0.9, 0.5}, icon = "Interface\\Icons\\INV_Misc_Map_01" },
    { hours = 1000,  title = "Voyageur",      color = {0.3, 0.8, 1.0}, icon = "Interface\\Icons\\INV_Misc_Map02" },
    { hours = 2000,  title = "Aventurier",    color = {0.4, 0.7, 1.0}, icon = "Interface\\Icons\\INV_Misc_Map04" },
    { hours = 3000,  title = "Champion",      color = {0.8, 0.5, 1.0}, icon = "Interface\\Icons\\INV_Jewelry_Talisman_07" },
    { hours = 4000,  title = "Héros",         color = {1.0, 0.5, 0.8}, icon = "Interface\\Icons\\INV_Jewelry_Talisman_12" },
    { hours = 5000,  title = "Vétéran",       color = {1.0, 0.6, 0.2}, icon = "Interface\\Icons\\Spell_Holy_GreaterHeal" },
    { hours = 7500,  title = "Maître",        color = {1.0, 0.8, 0.0}, icon = "Interface\\Icons\\INV_Crown_02" },
    { hours = 10000, title = "Légende",       color = {1.0, 0.5, 0.0}, icon = "Interface\\Icons\\INV_Jewelry_Ring_66" },
    { hours = 15000, title = "Immortel",      color = {1.0, 0.2, 0.2}, icon = "Interface\\Icons\\Spell_Holy_HolyGuidance" },
    { hours = 20000, title = "Dieu Vivant",   color = {1.0, 0.0, 1.0}, icon = "Interface\\Icons\\Spell_Nature_LightningOverload" }
}

-- ============================================================================
-- FONCTIONS PUBLIQUES
-- ============================================================================

function PTR.Achievements.GetTierByHours(totalSeconds)
    local hours = totalSeconds / 3600
    local currentTier = nil
    
    for _, tier in ipairs(TIERS) do
        if hours >= tier.hours then
            currentTier = tier
        else
            break
        end
    end
    
    return currentTier
end

function PTR.Achievements.GetNextTier(totalSeconds)
    local hours = totalSeconds / 3600
    
    for _, tier in ipairs(TIERS) do
        if hours < tier.hours then
            return tier
        end
    end
    
    return nil -- Max atteint
end

function PTR.Achievements.CheckAchievements(accountName)
    local player = PlaytimeRankingDB.players[accountName]
    if not player then return end
    
    local currentTier = PTR.Achievements.GetTierByHours(player.totalPlayed)
    
    if currentTier then
        local key = tostring(currentTier.hours)
        
        -- Nouveau haut fait ?
        if not player.achievements[key] then
            player.achievements[key] = {
                title = currentTier.title,
                hours = currentTier.hours,
                unlockedAt = time(),
                icon = currentTier.icon
            }
            
            -- Notifier uniquement si c'est le joueur principal
            if accountName == PTR.GetCurrentMainPlayerName() then
                PTR.Achievements.ShowUnlockNotification(currentTier)
            end
        end
    end
end

function PTR.Achievements.ShowUnlockNotification(tier)
    -- Message stylé dans le chat
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    DEFAULT_CHAT_FRAME:AddMessage("|TInterface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow:32:32|t |cffffd700HAUT FAIT DÉBLOQUÉ !|r |TInterface\\ACHIEVEMENTFRAME\\UI-Achievement-Alert-Glow:32:32|t")
    
    local r, g, b = tier.color[1], tier.color[2], tier.color[3]
    local hexColor = string.format("%02x%02x%02x", r*255, g*255, b*255)
    
    DEFAULT_CHAT_FRAME:AddMessage("|cff" .. hexColor .. "» " .. tier.title .. " «|r |cff888888(" .. tier.hours .. "h)|r")
    DEFAULT_CHAT_FRAME:AddMessage(" ")
    
    -- Son épique
    PlaySound(SOUNDKIT.UI_RAID_BOSS_WHISPER_WARNING)
    
    -- Message à l'écran
    UIErrorsFrame:AddMessage("Haut fait débloqué : " .. tier.title, r, g, b, 1.0, 5.0)
end

function PTR.Achievements.GetPlayerTitle(accountName)
    local player = PlaytimeRankingDB.players[accountName]
    if not player then return nil end
    
    local tier = PTR.Achievements.GetTierByHours(player.totalPlayed)
    return tier and tier.title or nil
end

function PTR.Achievements.GetPlayerTitleColored(accountName)
    local player = PlaytimeRankingDB.players[accountName]
    if not player then return accountName end
    
    local tier = PTR.Achievements.GetTierByHours(player.totalPlayed)
    if not tier then return accountName end
    
    local r, g, b = tier.color[1], tier.color[2], tier.color[3]
    local hexColor = string.format("%02x%02x%02x", r*255, g*255, b*255)
    
    return accountName .. " |cff888888-|r |cff" .. hexColor .. tier.title .. "|r"
end

function PTR.Achievements.GetAllTiers()
    return TIERS
end

-- ============================================================================
-- TOOLTIP
-- ============================================================================

function PTR.Achievements.ShowTooltip(parent, accountName)
    local player = PlaytimeRankingDB.players[accountName]
    if not player then return end
    
    GameTooltip:SetOwner(parent, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    -- Titre
    GameTooltip:AddLine(accountName, 1, 1, 1)
    GameTooltip:AddLine(" ")
    
    -- Titre actuel
    local currentTier = PTR.Achievements.GetTierByHours(player.totalPlayed)
    if currentTier then
        local r, g, b = currentTier.color[1], currentTier.color[2], currentTier.color[3]
        GameTooltip:AddDoubleLine("|cffffd700Titre actuel :|r", currentTier.title, 1, 1, 1, r, g, b)
        GameTooltip:AddTexture(currentTier.icon, {width = 16, height = 16})
    end
    
    -- Prochain titre
    local nextTier = PTR.Achievements.GetNextTier(player.totalPlayed)
    if nextTier then
        local hoursNeeded = nextTier.hours - (player.totalPlayed / 3600)
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("|cff888888Prochain titre :|r", nextTier.title, 0.8, 0.8, 0.8, 0.8, 0.8, 0.8)
        GameTooltip:AddDoubleLine("|cff888888Il reste :|r", string.format("%.0fh", hoursNeeded), 0.8, 0.8, 0.8, 1, 1, 0)
    else
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffd700Tous les titres débloqués !|r", 1, 0.8, 0)
    end
    
    -- Nombre de hauts faits
    local count = 0
    for _ in pairs(player.achievements) do
        count = count + 1
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine("Hauts faits :", count .. " / " .. #TIERS, 0.7, 0.7, 0.7, 0.5, 1, 0.5)
    
    GameTooltip:Show()
end
