-- ============================================================================
-- Communication.lua
-- ============================================================================

PTR = PTR or {}
PTR.Comm = {}

function PTR.Comm.RegisterPrefix()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        C_ChatInfo.RegisterAddonMessagePrefix(PTR.PREFIX)
    end
end

function PTR.Comm.BroadcastMyData()
    local accountName = PTR.GetCurrentMainPlayerName()
    if not accountName then return end
    
    local payload = PTR.DB.SerializePlayer(accountName)
    if not payload then return end
    
    if IsInGuild() then
        PTR.Comm.SendMessage(payload, "GUILD")
    end
    if IsInRaid() then
        PTR.Comm.SendMessage(payload, "RAID")
    elseif IsInGroup() then
        PTR.Comm.SendMessage(payload, "PARTY")
    end
    PlaytimeRankingDB.config.lastBroadcast = time()
end

function PTR.Comm.SendMessage(message, channel, target)
    if not message or message == "" then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        C_ChatInfo.SendAddonMessage(PTR.PREFIX, message, channel, target)
    end
end

function PTR.Comm.ReceiveData(message, sender)
    local accountName = PTR.DB.DeserializePlayer(message)
    if accountName then
        if PTR.UI.mainFrame and PTR.UI.mainFrame:IsShown() then
            PTR.UI.RefreshMainFrame()
        end
    end
end
