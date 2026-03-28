-- ============================================================================
-- Minimap.lua - Bouton minimap (SANS disparition au survol)
-- ============================================================================

PTR = PTR or {}
PTR.Minimap = {}

local button = nil

-- ============================================================================
-- CRÉATION DU BOUTON
-- ============================================================================

function PTR.Minimap.Create()
    if button then return button end
    
    if PlaytimeRankingDB.config.minimapHide then
        return
    end
    
    button = CreateFrame("Button", "PTRMinimapButton", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetMovable(true)
    
    -- Icon (horloge)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(17, 17)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    
    -- Border
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetSize(53, 53)
    button.border:SetPoint("TOPLEFT")
    button.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    
    -- Highlight
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    
    -- Tooltip
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cffffd700Playtime Ranking|r", 1, 1, 1)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cffffffffClic gauche :|r Ouvrir le classement", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cffffffffClic droit :|r Options", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("|cffffffffGlisser :|r Déplacer le bouton", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Click handlers
    button:SetScript("OnClick", function(self, btn)
        if btn == "LeftButton" then
            PTR.UI.ToggleMainFrame()
        elseif btn == "RightButton" then
            PTR.UI.OpenOptions()
        end
    end)
    
    -- Drag
    button:SetScript("OnDragStart", function(self)
        self:LockHighlight()
        self.isDragging = true
        self:SetScript("OnUpdate", PTR.Minimap.OnUpdate)
    end)
    
    button:SetScript("OnDragStop", function(self)
        self:UnlockHighlight()
        self.isDragging = false
        self:SetScript("OnUpdate", nil)
        PTR.Minimap.SavePosition()
    end)
    
    -- Position initiale
    PTR.Minimap.UpdatePosition()
    
    button:Show()
    
    PTR.Minimap.button = button
    return button
end

-- ============================================================================
-- POSITIONNEMENT
-- ============================================================================

function PTR.Minimap.UpdatePosition()
    if not button then return end
    
    local angle = math.rad(PlaytimeRankingDB.config.minimapAngle or 220)
    local x = math.cos(angle) * 80
    local y = math.sin(angle) * 80
    
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function PTR.Minimap.OnUpdate(self)
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    
    px, py = px / scale, py / scale
    
    local dx = px - mx
    local dy = py - my
    
    local angle = math.deg(math.atan2(dy, dx))
    
    PlaytimeRankingDB.config.minimapAngle = angle
    PTR.Minimap.UpdatePosition()
end

function PTR.Minimap.SavePosition()
    -- Already saved in OnUpdate
end

-- ============================================================================
-- VISIBILITY
-- ============================================================================

function PTR.Minimap.UpdateVisibility()
    if PlaytimeRankingDB.config.minimapHide then
        if button then
            button:Hide()
        end
    else
        if not button then
            PTR.Minimap.Create()
        else
            button:Show()
        end
    end
end

-- ============================================================================
-- INIT
-- ============================================================================

C_Timer.After(1, function()
    PTR.Minimap.Create()
end)
