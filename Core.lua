-- ============================================================================
-- Core.lua - Variables globales et utilitaires  
-- ============================================================================

PTR = PTR or {}
PTR.VERSION = "2.0.0"
PTR.PREFIX = "PTRANK2"

local addon = CreateFrame("Frame")
local realmName = GetRealmName()
local playerName = UnitName("player")
local lastPlayedRequest = 0

function PTR.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99PlaytimeRanking|r: " .. tostring(msg))
end

function PTR.GetCharKey(name, realm)
    return tostring(name) .. "-" .. tostring(realm)
end

function PTR.SafeRequestTimePlayed()
    local now = GetTime()
    if now - lastPlayedRequest >= 10 then
        RequestTimePlayed()
        lastPlayedRequest = now
        return true
    end
    return false
end

function PTR.GetCurrentMainPlayerName()
    local name = PlaytimeRankingDB.config.mainPlayerName
    if not name or name == "" then
        return nil
    end
    return name
end

addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("TIME_PLAYED_MSG")
addon:RegisterEvent("CHAT_MSG_ADDON")
addon:RegisterEvent("RAID_ROSTER_UPDATE")
addon:RegisterEvent("GUILD_ROSTER_UPDATE")

addon:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "PlaytimeRanking" then
            PTR.DB.Init()
            PTR.Comm.RegisterPrefix()
        end
    elseif event == "PLAYER_LOGIN" then
        if not PlaytimeRankingDB.config.firstTimeSetupDone then
            C_Timer.After(2, function()
                PTR.UI.ShowFirstTimeSetup()
            end)
            return
        end
        C_Timer.After(3, function()
            if PlaytimeRankingDB.config.autoRequestPlayed then
                PTR.SafeRequestTimePlayed()
            end
            PTR.Comm.BroadcastMyData()
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        if PlaytimeRankingDB.config.autoRequestPlayed then
            PTR.SafeRequestTimePlayed()
        end
    elseif event == "TIME_PLAYED_MSG" then
        local totalPlayed, currentLevelPlayed = ...
        if totalPlayed and totalPlayed > 0 then
            PTR.DB.UpdateCurrentCharacter(totalPlayed)
            if PTR.UI.mainFrame and PTR.UI.mainFrame:IsShown() then
                PTR.UI.RefreshMainFrame()
            end
            PTR.Comm.BroadcastMyData()
            PTR.Print("Temps de jeu mis à jour: " .. PTR.DB.SecondsToReadable(totalPlayed))
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == PTR.PREFIX then
            PTR.Comm.ReceiveData(message, sender)
        end
    elseif event == "RAID_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        C_Timer.After(2, function()
            PTR.Comm.BroadcastMyData()
        end)
    end
end)

SLASH_PTR1 = "/ptr"
SlashCmdList.PTR = function(msg)
    msg = msg:lower():trim()
    if msg == "" then
        PTR.UI.ToggleMainFrame()
    elseif msg == "options" then
        PTR.UI.OpenOptions()
    elseif msg == "sync" then
        PTR.Comm.BroadcastMyData()
        PTR.Print("Synchronisation envoyée")
    elseif msg == "update" then
        PTR.SafeRequestTimePlayed()
    elseif msg == "reset" then
        PTR.Print("|cffff0000⚠ Suppression de TOUTES les données !|r")
        PlaytimeRankingDB = nil
        PTR.DB.Init()
        PTR.Print("|cff00ff00✓|r Réinitialisé")
        if PTR.UI.mainFrame and PTR.UI.mainFrame:IsShown() then
            PTR.UI.RefreshMainFrame()
        end
    elseif msg == "debug" then
        PTR.Print("=== DEBUG ===")
        PTR.Print("Version: " .. PTR.VERSION)
        PTR.Print("Nom: " .. tostring(PTR.GetCurrentMainPlayerName()))
        local count = 0
        for accountName, data in pairs(PlaytimeRankingDB.players) do 
            count = count + 1
            PTR.Print("--- Joueur " .. count .. ": " .. accountName .. " ---")
            PTR.Print("  Total: " .. PTR.DB.SecondsToReadable(data.totalPlayed or 0))
            local charCount = PTR.DB.CountCharacters(data.characters)
            PTR.Print("  Persos: " .. charCount)
            for charKey, charData in pairs(data.characters) do
                PTR.Print("    • " .. charData.name .. " (" .. charData.realm .. ") - " .. PTR.DB.SecondsToReadable(charData.played or 0))
            end
        end
        PTR.Print("Total joueurs: " .. count)
    else
        PTR.Print("/ptr - Classement")
        PTR.Print("/ptr sync - Synchroniser")
        PTR.Print("/ptr reset - Réinitialiser")
    end
end