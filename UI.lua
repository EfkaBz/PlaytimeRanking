-- ============================================================================
-- UI.lua - Interface utilisateur (Classement + Options + FirstTime)
-- ============================================================================

PTR = PTR or {}
PTR.UI = {}

PTR.UI.mainFrame = nil
PTR.UI.optionsPanel = nil
PTR.UI.optionsCategory = nil

-- ============================================================================
-- POPUP PREMIÈRE CONNEXION
-- ============================================================================

function PTR.UI.ShowFirstTimeSetup()
    local popup = CreateFrame("Frame", "PTRFirstTimeSetup", UIParent, "BackdropTemplate")
    popup:SetSize(450, 280)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(100)
    popup:EnableMouse(true)
    
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    popup:SetBackdropColor(0, 0, 0, 1)
    
    -- Header
    local headerBg = popup:CreateTexture(nil, "ARTWORK")
    headerBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    headerBg:SetSize(300, 64)
    headerBg:SetPoint("TOP", 0, 12)
    
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, 4)
    title:SetText("|cffffd700Play|r|cffff8800time|r |cffff4400Ranking|r")
    
    local welcome = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    welcome:SetPoint("TOP", 0, -40)
    welcome:SetWidth(400)
    welcome:SetJustifyH("CENTER")
    welcome:SetText("Bienvenue !\n\nChoisissez votre nom de joueur pour le classement.")
    
    local label = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOP", 0, -95)
    label:SetText("Nom du joueur :")
    
    local editBox = CreateFrame("EditBox", nil, popup, "InputBoxTemplate")
    editBox:SetSize(200, 30)
    editBox:SetPoint("TOP", 0, -120)
    editBox:SetAutoFocus(true)
    editBox:SetMaxLetters(24)
    editBox:SetText(UnitName("player"))
    editBox:HighlightText()
    
    local info = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("TOP", 0, -155)
    info:SetWidth(400)
    info:SetJustifyH("CENTER")
    info:SetText("Ce nom apparaîtra dans le classement.\nTous vos personnages seront liés à ce nom.")
    info:SetTextColor(0.8, 0.8, 0.8)
    
    local warning = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warning:SetPoint("TOP", 0, -190)
    warning:SetWidth(400)
    warning:SetJustifyH("CENTER")
    warning:SetTextColor(1, 0.3, 0.3)
    warning:Hide()
    
    local function CheckNameExists(name)
        if not name or name == "" then return false end
        for accountName in pairs(PlaytimeRankingDB.players) do
            if accountName ~= name and PlaytimeRankingDB.players[accountName] and PTR.DB.CountCharacters(PlaytimeRankingDB.players[accountName].characters) > 0 then
                return true
            end
        end
        return false
    end
    
    local okBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    okBtn:SetSize(120, 30)
    okBtn:SetPoint("BOTTOM", 0, 20)
    okBtn:SetText("Confirmer")
    okBtn:SetScript("OnClick", function()
        local name = editBox:GetText()
        if not name or name == "" then
            warning:SetText("|cffff0000Veuillez entrer un nom !|r")
            warning:Show()
            return
        end
        
        local exists, existingData = CheckNameExists(name)
        if exists and existingData then
            warning:SetText("|cffffff00Ce nom existe déjà (" .. PTR.DB.CountCharacters(existingData.characters) .. " persos). Utilisez 'C'est moi' pour continuer.|r")
            warning:Show()
            return
        end
        
        PlaytimeRankingDB.config.mainPlayerName = name
        PlaytimeRankingDB.config.firstTimeSetupDone = true
        
        PTR.Print("Bienvenue, " .. name .. " !")
        
        -- IMPORTANT: Demander /played et synchroniser
        C_Timer.After(1, function()
            PTR.SafeRequestTimePlayed()
            C_Timer.After(2, function()
                PTR.Comm.BroadcastMyData()
            end)
        end)
        
        popup:Hide()
    end)
    
    local confirmBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    confirmBtn:SetSize(120, 30)
    confirmBtn:SetPoint("BOTTOM", 65, 20)
    confirmBtn:SetText("C'est moi !")
    confirmBtn:SetScript("OnClick", function()
        local name = editBox:GetText()
        if not name or name == "" then
            warning:SetText("|cffff0000Veuillez entrer un nom !|r")
            warning:Show()
            return
        end
        
        PlaytimeRankingDB.config.mainPlayerName = name
        PlaytimeRankingDB.config.firstTimeSetupDone = true
        
        local exists, existingData = CheckNameExists(name)
        if exists then
            PTR.Print("Bienvenue " .. name .. " ! (" .. PTR.DB.CountCharacters(existingData.characters) .. " personnages)")
        else
            PTR.Print("Bienvenue, " .. name .. " !")
        end
        
        -- IMPORTANT: Demander /played et synchroniser
        C_Timer.After(1, function()
            PTR.SafeRequestTimePlayed()
            C_Timer.After(2, function()
                PTR.Comm.BroadcastMyData()
            end)
        end)
        
        popup:Hide()
    end)
    
    popup:Show()
end

-- ============================================================================
-- INTERFACE PRINCIPALE - CLASSEMENT
-- ============================================================================

function PTR.UI.CreateMainFrame()
    if PTR.UI.mainFrame then return PTR.UI.mainFrame end
    
    local f = CreateFrame("Frame", "PTRMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(700, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    
    -- Backdrop avec fond sombre
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    f:SetBackdropColor(0.05, 0.05, 0.1, 0.95)
    
    -- Gradient overlay
    local gradient = f:CreateTexture(nil, "BACKGROUND")
    gradient:SetAllPoints(f)
    gradient:SetGradient("VERTICAL", 
        CreateColor(0.1, 0.1, 0.15, 0.9), 
        CreateColor(0.05, 0.05, 0.1, 0.9)
    )
    
    -- Drag
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -5, -5)
    
    -- Header
    local headerBg = f:CreateTexture(nil, "ARTWORK")
    headerBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    headerBg:SetSize(400, 64)
    headerBg:SetPoint("TOP", 0, 0)
    
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOP", 0, -8)
    title:SetText("|cffffd700Play|r|cffff8800time|r |cffff4400Ranking|r")
    
    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText("|cff888888Classement par joueur • Cliquez pour voir les personnages|r")
    
    -- Bouton Actualiser
    local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    refreshBtn:SetSize(120, 24)
    refreshBtn:SetPoint("TOPRIGHT", -35, -35)
    refreshBtn:SetText("Actualiser")
    refreshBtn:SetScript("OnClick", function()
        PTR.SafeRequestTimePlayed()
        C_Timer.After(0.5, function()
            PTR.UI.RefreshMainFrame()
        end)
    end)
    
    -- Headers des colonnes
    local headerFrame = CreateFrame("Frame", nil, f, "BackdropTemplate")
    headerFrame:SetSize(650, 30)
    headerFrame:SetPoint("TOP", 0, -70)
    headerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        edgeSize = 1
    })
    headerFrame:SetBackdropColor(0.15, 0.15, 0.2, 0.8)
    headerFrame:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local rankHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rankHeader:SetPoint("LEFT", 15, 0)
    rankHeader:SetText("|cffffd700Rang|r")
    
    local playerHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    playerHeader:SetPoint("LEFT", 70, 0)
    playerHeader:SetText("|cffffd700Joueur|r")
    
    local timeHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeHeader:SetPoint("RIGHT", -200, 0)
    playerHeader:SetText("|cffffd700Temps total|r")
    
    local charsHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    charsHeader:SetPoint("RIGHT", -100, 0)
    charsHeader:SetText("|cffffd700Persos|r")
    
    local hfHeader = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hfHeader:SetPoint("RIGHT", -15, 0)
    hfHeader:SetText("|cffffd700HF Max|r")
    
    -- ScrollFrame pour le classement
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 20, -105)
    scrollFrame:SetPoint("BOTTOMRIGHT", -40, 20)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(630, 1)
    scrollFrame:SetScrollChild(scrollChild)
    
    f.scrollFrame = scrollFrame
    f.scrollChild = scrollChild
    f.rows = {}
    
    f:Hide()
    PTR.UI.mainFrame = f
    
    return f
end

function PTR.UI.RefreshMainFrame()
    if not PTR.UI.mainFrame then return end
    
    local f = PTR.UI.mainFrame
    local scrollChild = f.scrollChild
    
    -- Clear existing rows
    for _, row in ipairs(f.rows) do
        row:Hide()
    end
    
    -- Clear character rows
    if f.charRows then
        for _, charRow in ipairs(f.charRows) do
            charRow:Hide()
            charRow:SetParent(nil)
        end
    end
    f.charRows = {}
    
    local sorted = PTR.DB.GetSortedPlayers()
    
    local yOffset = 0
    for rank, entry in ipairs(sorted) do
        local row = f.rows[rank]
        if not row then
            row = PTR.UI.CreatePlayerRow(scrollChild, rank)
            f.rows[rank] = row
        end
        
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -yOffset)
        row:Show()
        
        -- Update row data
        PTR.UI.UpdatePlayerRow(row, rank, entry)
        
        yOffset = yOffset + 32
        
        -- Expanded characters
        if PlaytimeRankingDB.expandedPlayers[entry.name] then
            -- Trier les personnages par temps de jeu
            local sortedChars = {}
            for charKey, charData in pairs(entry.data.characters) do
                table.insert(sortedChars, charData)
            end
            table.sort(sortedChars, function(a, b)
                return (a.played or 0) > (b.played or 0)
            end)
            
            for _, charData in ipairs(sortedChars) do
                local charRow = PTR.UI.CreateCharacterRowFrame(scrollChild, yOffset, charData)
                table.insert(f.charRows, charRow)
                yOffset = yOffset + 26
            end
        end
    end
    
    scrollChild:SetHeight(math.max(yOffset, 400))
end

function PTR.UI.CreatePlayerRow(parent, index)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(630, 30)
    
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = false
    })
    
    -- Hover effect
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.2, 0.2, 0.25, 0.6)
        if self.accountName then
            PTR.Achievements.ShowTooltip(self, self.accountName)
        end
    end)
    row:SetScript("OnLeave", function(self)
        local r, g, b = self.normalColor[1], self.normalColor[2], self.normalColor[3]
        self:SetBackdropColor(r, g, b, 0.4)
        GameTooltip:Hide()
    end)
    
    -- Click to expand
    row:SetScript("OnMouseDown", function(self)
        if self.accountName then
            PlaytimeRankingDB.expandedPlayers[self.accountName] = not PlaytimeRankingDB.expandedPlayers[self.accountName]
            PTR.UI.RefreshMainFrame()
        end
    end)
    
    row.normalColor = {0.1, 0.1, 0.15}
    
    -- Rank
    row.rankText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.rankText:SetPoint("LEFT", 15, 0)
    
    -- Player name + title
    row.playerText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.playerText:SetPoint("LEFT", 70, 0)
    row.playerText:SetWidth(250)
    row.playerText:SetJustifyH("LEFT")
    
    -- Total time
    row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.timeText:SetPoint("RIGHT", -200, 0)
    
    -- Chars count
    row.charsText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.charsText:SetPoint("RIGHT", -100, 0)
    
    -- HF max
    row.hfText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.hfText:SetPoint("RIGHT", -15, 0)
    
    return row
end

function PTR.UI.UpdatePlayerRow(row, rank, entry)
    row.accountName = entry.name
    
    -- Rank avec médailles
    local rankText = tostring(rank)
    if rank == 1 then
        rankText = "|TInterface\\PVPFrame\\Icons\\PVP-Banner-Emblem-1:16:16|t |cffffd7001|r"
    elseif rank == 2 then
        rankText = "|TInterface\\PVPFrame\\Icons\\PVP-Banner-Emblem-2:16:16|t |cffc0c0c02|r"
    elseif rank == 3 then
        rankText = "|TInterface\\PVPFrame\\Icons\\PVP-Banner-Emblem-3:16:16|t |cffcd7f323|r"
    end
    row.rankText:SetText(rankText)
    
    -- Player name avec titre coloré
    local displayName = PTR.Achievements.GetPlayerTitleColored(entry.name)
    row.playerText:SetText(displayName)
    
    -- Time
    row.timeText:SetText(PTR.DB.SecondsToReadable(entry.totalPlayed))
    
    -- Chars count
    local charCount = PTR.DB.CountCharacters(entry.data.characters)
    row.charsText:SetText(charCount .. " perso" .. (charCount > 1 and "s" or ""))
    
    -- HF max
    local tier = PTR.Achievements.GetTierByHours(entry.totalPlayed)
    if tier then
        local r, g, b = tier.color[1], tier.color[2], tier.color[3]
        local hexColor = string.format("%02x%02x%02x", r*255, g*255, b*255)
        row.hfText:SetText("|cff" .. hexColor .. tier.title .. "|r")
        row.normalColor = {r * 0.3, g * 0.3, b * 0.3}
    else
        row.hfText:SetText("|cff888888-|r")
        row.normalColor = {0.1, 0.1, 0.15}
    end
    
    row:SetBackdropColor(row.normalColor[1], row.normalColor[2], row.normalColor[3], 0.4)
    
    -- Expand indicator
    if PlaytimeRankingDB.expandedPlayers[entry.name] then
        row.playerText:SetText("▼ " .. displayName)
    else
        row.playerText:SetText("▶ " .. displayName)
    end
end

function PTR.UI.CreateCharacterRowFrame(parent, yOffset, charData)
    local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    row:SetSize(630, 26)
    row:SetPoint("TOPLEFT", 0, -yOffset)
    
    row:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = nil,
        tile = false
    })
    row:SetBackdropColor(0.05, 0.05, 0.08, 0.5)
    
    -- Hover effect
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.1, 0.1, 0.13, 0.7)
    end)
    row:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.05, 0.05, 0.08, 0.5)
    end)
    
    -- Indent bullet
    local bullet = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bullet:SetPoint("LEFT", 50, 0)
    bullet:SetText("|cff666666•|r")
    
    -- Character name with class color
    local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("LEFT", 70, 0)
    nameText:SetWidth(200)
    nameText:SetJustifyH("LEFT")
    
    local classColor = RAID_CLASS_COLORS[charData.classFile] or {r = 1, g = 1, b = 1}
    local className = charData.classFile or "UNKNOWN"
    
    nameText:SetText(string.format("|cff%02x%02x%02x%s|r |cff888888-|r |cffaaaaaa%s|r", 
        classColor.r * 255, 
        classColor.g * 255, 
        classColor.b * 255,
        charData.name,
        charData.realm
    ))
    
    -- Class icon (small)
    local classIcon = row:CreateTexture(nil, "ARTWORK")
    classIcon:SetSize(16, 16)
    classIcon:SetPoint("LEFT", nameText, "RIGHT", 5, 0)
    classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    
    local coords = CLASS_ICON_TCOORDS[charData.classFile]
    if coords then
        classIcon:SetTexCoord(unpack(coords))
    end
    
    -- Level
    local levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelText:SetPoint("LEFT", 320, 0)
    levelText:SetText("|cffccccccNiv. " .. (charData.level or 1) .. "|r")
    
    -- Time played
    local timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetPoint("RIGHT", -15, 0)
    timeText:SetText(PTR.DB.SecondsToReadable(charData.played or 0))
    
    row:Show()
    return row
end

function PTR.UI.ToggleMainFrame()
    if not PTR.UI.mainFrame then
        PTR.UI.CreateMainFrame()
    end
    
    if PTR.UI.mainFrame:IsShown() then
        PTR.UI.mainFrame:Hide()
    else
        PTR.UI.RefreshMainFrame()
        PTR.UI.mainFrame:Show()
    end
end

-- ============================================================================
-- PANNEAU OPTIONS
-- ============================================================================

function PTR.UI.CreateOptionsPanel()
    local panel = CreateFrame("Frame")
    panel.name = "PlaytimeRanking"
    
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cffffd700Play|r|cffff8800time|r |cffff4400Ranking|r")
    
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    version:SetText("|cff888888Version " .. PTR.VERSION .. "|r")
    
    -- Main player name
    local mainLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    mainLabel:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -20)
    mainLabel:SetText("Nom du joueur principal :")
    
    local mainBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    mainBox:SetSize(180, 24)
    mainBox:SetPoint("TOPLEFT", mainLabel, "BOTTOMLEFT", 0, -8)
    mainBox:SetAutoFocus(false)
    mainBox:SetMaxLetters(24)
    
    -- Info hauts faits
    local achievementInfo = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    achievementInfo:SetPoint("TOPLEFT", mainBox, "BOTTOMLEFT", 0, -20)
    achievementInfo:SetWidth(400)
    achievementInfo:SetJustifyH("LEFT")
    achievementInfo:SetText("|cff00ff00✓|r Hauts faits débloqués automatiquement tous les 500 heures\n|cff00ff0010 titres disponibles|r du novice à la légende !")
    
    -- Checkboxes
    local autoCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    autoCheck:SetPoint("TOPLEFT", achievementInfo, "BOTTOMLEFT", -4, -16)
    autoCheck.text = autoCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    autoCheck.text:SetPoint("LEFT", autoCheck, "RIGHT", 2, 1)
    autoCheck.text:SetText("Mettre à jour auto le /played")
    
    local minimapCheck = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    minimapCheck:SetPoint("TOPLEFT", autoCheck, "BOTTOMLEFT", 0, -8)
    minimapCheck.text = minimapCheck:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    minimapCheck.text:SetPoint("LEFT", minimapCheck, "RIGHT", 2, 1)
    minimapCheck.text:SetText("Afficher le bouton minimap")
    
    -- Save button
    local saveBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    saveBtn:SetSize(120, 22)
    saveBtn:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 4, -20)
    saveBtn:SetText("Enregistrer")
    
    saveBtn:SetScript("OnClick", function()
        local name = mainBox:GetText()
        if name and name ~= "" then
            PlaytimeRankingDB.config.mainPlayerName = name
            PlaytimeRankingDB.config.firstTimeSetupDone = true
        end
        
        PlaytimeRankingDB.config.achievementStepHours = 500
        PlaytimeRankingDB.config.autoRequestPlayed = autoCheck:GetChecked()
        PlaytimeRankingDB.config.minimapHide = not minimapCheck:GetChecked()
        
        if PTR.Minimap then
            PTR.Minimap.UpdateVisibility()
        end
        
        PTR.Print("Options sauvegardées !")
    end)
    
    -- Refresh
    panel.refresh = function()
        local currentName = PlaytimeRankingDB.config.mainPlayerName
        if not currentName or currentName == "" then
            currentName = UnitName("player")
        end
        mainBox:SetText(currentName)
        autoCheck:SetChecked(PlaytimeRankingDB.config.autoRequestPlayed)
        minimapCheck:SetChecked(not PlaytimeRankingDB.config.minimapHide)
    end
    
    panel:SetScript("OnShow", function(self)
        if self.refresh then self.refresh() end
    end)
    
    -- Register dans Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        PTR.UI.optionsPanel = panel
        PTR.UI.optionsCategory = category
        PTR.Print("Panneau d'options créé ! Voir dans Echap > Interface > AddOns")
    end
    
    return panel
end

function PTR.UI.OpenOptions()
    if PTR.UI.optionsCategory and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(PTR.UI.optionsCategory:GetID())
    else
        PTR.Print("Ouvrez: Echap > Interface > AddOns > PlaytimeRanking")
    end
end

-- Init
C_Timer.After(1, function()
    PTR.UI.CreateOptionsPanel()
    PTR.UI.CreateMainFrame()
end)
