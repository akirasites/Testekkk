-- ============================================================
-- VISUAL CHANGER R6 ULTIMATE v3.0
-- ✓ Korblox corrigido (R15 e R6)
-- ✓ Headless corrigido
-- ✓ Conversão automática R15 → R6
-- ✓ Acessórios sem bug (não voam)
-- ✓ Suporte Mobile completo (Activated + Backdrop)
-- ============================================================

local Players     = game:GetService("Players")
local UserService = game:GetService("UserService")
local CoreGui     = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Remove instâncias anteriores para evitar duplicação
local old = CoreGui:FindFirstChild("VisualChangerR6Ultimate")
if old then old:Destroy() end

local guiParent
if pcall(function() return CoreGui end) then
    guiParent = CoreGui
else
    guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

-- ============================================================
-- ESTADO E CONSTANTES
-- ============================================================

local selectedPlayer  = nil
local modifiedPlayers = {}
local isProcessing    = false

local ORANGE = Color3.fromRGB(255, 115, 0)
local DARK   = Color3.fromRGB(10, 10, 10)
local DARK2  = Color3.fromRGB(25, 25, 25)
local DARK3  = Color3.fromRGB(40, 40, 40)
local WHITE  = Color3.new(1, 1, 1)

-- ============================================================
-- MAPEAMENTO R15 → R6
-- Para cada parte R15, define o equivalente no R6
-- ============================================================

local R15_TO_R6 = {
    UpperTorso    = "Torso",   LowerTorso    = "Torso",
    LeftUpperArm  = "Left Arm", LeftLowerArm  = "Left Arm", LeftHand      = "Left Arm",
    RightUpperArm = "Right Arm", RightLowerArm = "Right Arm", RightHand    = "Right Arm",
    LeftUpperLeg  = "Left Leg", LeftLowerLeg  = "Left Leg", LeftFoot      = "Left Leg",
    RightUpperLeg = "Right Leg", RightLowerLeg = "Right Leg", RightFoot    = "Right Leg",
}

-- Pares para detectar substituições visuais (Korblox, Rthro, etc.)
-- upper = parte que fica invisível | lower = parte com mesh especial
local SPECIAL_PAIRS = {
    { upper = "LeftUpperLeg",  lower = "LeftLowerLeg",  r6 = "Left Leg"  },
    { upper = "RightUpperLeg", lower = "RightLowerLeg", r6 = "Right Leg" },
    { upper = "LeftUpperArm",  lower = "LeftLowerArm",  r6 = "Left Arm"  },
    { upper = "RightUpperArm", lower = "RightLowerArm", r6 = "Right Arm" },
}

local R6_LIMBS = { "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }

-- ============================================================
-- SEÇÃO 1: INTERFACE GRÁFICA
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name         = "VisualChangerR6Ultimate"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent       = guiParent

local MainFrame = Instance.new("Frame")
MainFrame.Size                   = UDim2.new(0, 262, 0, 252)
MainFrame.Position               = UDim2.new(0.5, -131, 0.5, -126)
MainFrame.BackgroundColor3       = DARK
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel        = 0
MainFrame.Active                 = true
MainFrame.Draggable              = true
MainFrame.Parent                 = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local _stroke = Instance.new("UIStroke")
_stroke.Color           = ORANGE
_stroke.Thickness       = 1.5
_stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
_stroke.Parent          = MainFrame

local Title = Instance.new("TextLabel")
Title.Size               = UDim2.new(1, -50, 0, 36)
Title.Position           = UDim2.new(0, 12, 0, 5)
Title.BackgroundTransparency = 1
Title.Text               = "Visual Changer R6"
Title.TextColor3         = ORANGE
Title.Font               = Enum.Font.GothamBold
Title.TextSize           = 15
Title.TextXAlignment     = Enum.TextXAlignment.Left
Title.Parent             = MainFrame

local HideBtn = Instance.new("TextButton")
HideBtn.Size               = UDim2.new(0, 34, 0, 24)
HideBtn.Position           = UDim2.new(1, -44, 0, 11)
HideBtn.BackgroundColor3   = ORANGE
HideBtn.BackgroundTransparency = 0.15
HideBtn.Text               = "✕"
HideBtn.TextColor3         = WHITE
HideBtn.Font               = Enum.Font.GothamBold
HideBtn.TextSize           = 13
HideBtn.Parent             = MainFrame
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 6)

-- Dropdown: seletor de alvo
local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size               = UDim2.new(0.92, 0, 0, 34)
DropdownBtn.Position           = UDim2.new(0.04, 0, 0, 46)
DropdownBtn.BackgroundColor3   = DARK2
DropdownBtn.BackgroundTransparency = 0.25
DropdownBtn.TextColor3         = WHITE
DropdownBtn.Text               = "Selecione o Alvo..."
DropdownBtn.Font               = Enum.Font.GothamMedium
DropdownBtn.TextSize           = 13
DropdownBtn.ZIndex             = 5
DropdownBtn.Parent             = MainFrame
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 8)

-- Backdrop invisível para fechar o dropdown ao tocar fora — ESSENCIAL NO MOBILE
local DropdownBackdrop = Instance.new("TextButton")
DropdownBackdrop.Size                   = UDim2.new(1, 0, 1, 0)
DropdownBackdrop.BackgroundTransparency = 1
DropdownBackdrop.Text                   = ""
DropdownBackdrop.Visible                = false
DropdownBackdrop.ZIndex                 = 14
DropdownBackdrop.Parent                 = MainFrame

local DropdownScroll = Instance.new("ScrollingFrame")
DropdownScroll.Size                 = UDim2.new(0.92, 0, 0, 112)
DropdownScroll.Position             = UDim2.new(0.04, 0, 0, 84)
DropdownScroll.BackgroundColor3     = Color3.fromRGB(15, 15, 15)
DropdownScroll.BackgroundTransparency = 0.1
DropdownScroll.CanvasSize           = UDim2.new(0, 0, 0, 0)
DropdownScroll.ScrollBarThickness   = 4
DropdownScroll.ScrollBarImageColor3 = ORANGE
DropdownScroll.Visible              = false
DropdownScroll.ZIndex               = 15
DropdownScroll.Active               = true
DropdownScroll.Parent               = MainFrame
Instance.new("UICorner", DropdownScroll).CornerRadius = UDim.new(0, 8)
do
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, 3)
    ll.Parent    = DropdownScroll

    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 4); p.PaddingBottom = UDim.new(0, 4)
    p.PaddingLeft = UDim.new(0, 4); p.PaddingRight = UDim.new(0, 4)
    p.Parent = DropdownScroll
end

local UsernameInput = Instance.new("TextBox")
UsernameInput.Size               = UDim2.new(0.92, 0, 0, 34)
UsernameInput.Position           = UDim2.new(0.04, 0, 0, 90)
UsernameInput.BackgroundColor3   = DARK2
UsernameInput.BackgroundTransparency = 0.25
UsernameInput.TextColor3         = WHITE
UsernameInput.PlaceholderText    = "Username para copiar..."
UsernameInput.PlaceholderColor3  = Color3.fromRGB(115, 115, 115)
UsernameInput.Font               = Enum.Font.Gotham
UsernameInput.TextSize           = 13
UsernameInput.ClearTextOnFocus   = false
UsernameInput.ZIndex             = 2
UsernameInput.Parent             = MainFrame
Instance.new("UICorner", UsernameInput).CornerRadius = UDim.new(0, 8)

local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size               = UDim2.new(0.92, 0, 0, 40)
ApplyBtn.Position           = UDim2.new(0.04, 0, 0, 140)
ApplyBtn.BackgroundColor3   = ORANGE
ApplyBtn.TextColor3         = DARK
ApplyBtn.Text               = "Aplicar Visual Completo"
ApplyBtn.Font               = Enum.Font.GothamBold
ApplyBtn.TextSize           = 13
ApplyBtn.ZIndex             = 2
ApplyBtn.Parent             = MainFrame
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 8)

local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Size               = UDim2.new(0.92, 0, 0, 38)
RestoreBtn.Position           = UDim2.new(0.04, 0, 0, 192)
RestoreBtn.BackgroundColor3   = DARK3
RestoreBtn.BackgroundTransparency = 0.15
RestoreBtn.TextColor3         = WHITE
RestoreBtn.Text               = "Restaurar Original"
RestoreBtn.Font               = Enum.Font.GothamBold
RestoreBtn.TextSize           = 13
RestoreBtn.ZIndex             = 2
RestoreBtn.Parent             = MainFrame
Instance.new("UICorner", RestoreBtn).CornerRadius = UDim.new(0, 8)

-- ============================================================
-- SEÇÃO 2: DROPDOWN — USA Activated PARA FUNCIONAR NO MOBILE
-- ============================================================

local function updateDropdown()
    for _, c in ipairs(DropdownScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local totalH = 0
    for _, p in ipairs(Players:GetPlayers()) do
        local btn = Instance.new("TextButton")
        btn.Size               = UDim2.new(1, 0, 0, 29)
        btn.BackgroundColor3   = Color3.fromRGB(35, 35, 35)
        btn.BackgroundTransparency = 0.2
        btn.TextColor3         = WHITE
        btn.Text               = p.Name .. (p == LocalPlayer and " (Você)" or "")
        btn.Font               = Enum.Font.GothamMedium
        btn.TextSize           = 12
        btn.ZIndex             = 16
        btn.Parent             = DropdownScroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        btn.Activated:Connect(function()
            selectedPlayer           = p
            DropdownBtn.Text         = "▸ " .. p.Name
            DropdownScroll.Visible   = false
            DropdownBackdrop.Visible = false
        end)
        totalH = totalH + 32
    end
    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, totalH + 8)
end

DropdownBtn.Activated:Connect(function()
    DropdownScroll.Visible   = not DropdownScroll.Visible
    DropdownBackdrop.Visible = DropdownScroll.Visible
    if DropdownScroll.Visible then updateDropdown() end
end)
DropdownBackdrop.Activated:Connect(function()
    DropdownScroll.Visible   = false
    DropdownBackdrop.Visible = false
end)
Players.PlayerAdded:Connect(function()    if DropdownScroll.Visible then updateDropdown() end end)
Players.PlayerRemoving:Connect(function() if DropdownScroll.Visible then updateDropdown() end end)

-- ============================================================
-- SEÇÃO 3: FUNÇÕES AUXILIARES
-- ============================================================

local function isR15(model)
    return model:FindFirstChild("UpperTorso") ~= nil
end

local function setDisplayName(char, name)
    local hum = char:FindFirstChild("Humanoid")
    if hum then hum.DisplayName = name end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("TextLabel") and d.Parent:IsA("BillboardGui") then
            d.Text = name
        end
    end
end

-- ============================================================
-- SEÇÃO 4: CABEÇA + HEADLESS
-- Copia transparência, cor, malhas e faces da cabeça.
-- Transparência 1 = Headless — funciona automaticamente.
-- ============================================================

local function applyHead(src, tgtChar)
    local srcHead = src:FindFirstChild("Head")
    local tgtHead = tgtChar:FindFirstChild("Head")
    if not (srcHead and tgtHead) then return end

    for _, c in ipairs(tgtHead:GetChildren()) do
        if c:IsA("SpecialMesh") or c:IsA("Decal") then c:Destroy() end
    end
    for _, c in ipairs(srcHead:GetChildren()) do
        if c:IsA("SpecialMesh") or c:IsA("Decal") then c:Clone().Parent = tgtHead end
    end

    tgtHead.Transparency = srcHead.Transparency  -- 1 = headless ✓
    tgtHead.Color        = srcHead.Color
end

-- ============================================================
-- SEÇÃO 5: CORES DO CORPO COM CONVERSÃO R15 → R6
-- Agrupa partes R15 pelo equivalente R6 e usa a mais opaca
-- como referência de cor, evitando partes transparentes.
-- ============================================================

local function applyBodyColors(src, tgtChar)
    if isR15(src) then
        local bestColor, bestAlpha = {}, {}
        for r15Name, r6Name in pairs(R15_TO_R6) do
            local sp = src:FindFirstChild(r15Name)
            if sp and sp:IsA("BasePart") then
                local t = sp.Transparency
                if not bestAlpha[r6Name] or t < bestAlpha[r6Name] then
                    bestColor[r6Name] = sp.Color
                    bestAlpha[r6Name] = t
                end
            end
        end
        for _, r6Name in ipairs(R6_LIMBS) do
            local tp = tgtChar:FindFirstChild(r6Name)
            if tp and bestColor[r6Name] then
                tp.Color        = bestColor[r6Name]
                tp.Transparency = 0  -- Korblox sobrescreve abaixo se necessário
            end
        end
    else
        -- R6 → R6: cópia direta de cor e transparência
        for _, r6Name in ipairs(R6_LIMBS) do
            local sp = src:FindFirstChild(r6Name)
            local tp = tgtChar:FindFirstChild(r6Name)
            if sp and tp and sp:IsA("BasePart") then
                tp.Color        = sp.Color
                tp.Transparency = sp.Transparency
            end
        end
    end
end

-- ============================================================
-- SEÇÃO 6: KORBLOX, RTHRO E PARTES ESPECIAIS
-- Detecta substituição de membro: parte superior invisível
-- (Transparency >= 0.9) + parte inferior com mesh próprio.
-- Aplica via SpecialMesh no membro R6 correspondente.
-- ============================================================

local function applySpecialParts(src, tgtChar)
    if isR15(src) then
        for _, pair in ipairs(SPECIAL_PAIRS) do
            local upperPart = src:FindFirstChild(pair.upper)
            local lowerPart = src:FindFirstChild(pair.lower)
            local tgtPart   = tgtChar:FindFirstChild(pair.r6)
            if not (upperPart and lowerPart and tgtPart) then continue end

            -- KORBLOX / substituição visual: parte superior oculta + inferior com mesh
            if upperPart.Transparency < 0.9 then continue end

            local existingSM = lowerPart:FindFirstChildOfClass("SpecialMesh")
            local isMeshPart = lowerPart:IsA("MeshPart") and lowerPart.MeshId ~= ""
            if not (existingSM or isMeshPart) then continue end

            -- Remove qualquer mesh anterior no alvo
            for _, c in ipairs(tgtPart:GetChildren()) do
                if c:IsA("SpecialMesh") or c:IsA("SurfaceAppearance") then c:Destroy() end
            end

            if existingSM then
                -- Parte R6 com SpecialMesh interno: clona diretamente
                existingSM:Clone().Parent = tgtPart
            else
                -- Parte R15 é MeshPart: converte para SpecialMesh compatível R6
                local sm     = Instance.new("SpecialMesh")
                sm.MeshType  = Enum.MeshType.FileMesh
                sm.MeshId    = lowerPart.MeshId
                sm.TextureId = lowerPart.TextureID
                sm.Scale     = Vector3.one
                sm.Parent    = tgtPart
            end

            -- SurfaceAppearance (texturas PBR, ex: Korblox moderno)
            local sa = lowerPart:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Clone().Parent = tgtPart end

            tgtPart.Color        = lowerPart.Color
            tgtPart.Transparency = lowerPart.Transparency
        end
    else
        -- R6 → R6: copia SpecialMesh de cada membro diretamente
        for _, r6Name in ipairs(R6_LIMBS) do
            local sp = src:FindFirstChild(r6Name)
            local tp = tgtChar:FindFirstChild(r6Name)
            if not (sp and tp) then continue end
            for _, c in ipairs(tp:GetChildren()) do
                if c:IsA("SpecialMesh") then c:Destroy() end
            end
            for _, c in ipairs(sp:GetChildren()) do
                if c:IsA("SpecialMesh") then c:Clone().Parent = tp end
            end
        end
    end
end

-- ============================================================
-- SEÇÃO 7: ACESSÓRIOS — R6 COMPATÍVEL SEM BUG DE VOO
-- Tenta 3 métodos em cascata:
--   1. Humanoid:AddAccessory() — usa attachments automaticamente
--   2. Weld manual buscando attachment por nome no personagem
--   3. Fallback: gruda no Torso
-- ============================================================

local function attachAccessory(tgtChar, acc)
    local hum    = tgtChar:FindFirstChild("Humanoid")
    local handle = acc:FindFirstChild("Handle")
    if not handle then acc:Destroy(); return end

    handle.Massless   = true
    handle.CanCollide = false
    handle.Anchored   = false

    -- Método 1: AddAccessory usa attachments do personagem R6 automaticamente
    if hum then
        pcall(function() hum:AddAccessory(acc) end)
        for _, c in ipairs(handle:GetChildren()) do
            if c:IsA("Weld") or c:IsA("WeldConstraint") or c:IsA("Motor6D") then
                return  -- Weld criado com sucesso!
            end
        end
    end

    if acc.Parent ~= tgtChar then acc.Parent = tgtChar end

    -- Método 2: Weld manual procurando o attachment pelo nome no personagem
    local accAtt = handle:FindFirstChildOfClass("Attachment")
    if accAtt then
        local tgtAtt = tgtChar:FindFirstChild(accAtt.Name, true)
        if tgtAtt and tgtAtt:IsA("Attachment") and tgtAtt.Parent:IsA("BasePart") then
            handle.CFrame = tgtAtt.WorldCFrame * accAtt.CFrame:Inverse()
            local weld    = Instance.new("WeldConstraint")
            weld.Part0    = handle
            weld.Part1    = tgtAtt.Parent
            weld.Parent   = handle
            return
        end
    end

    -- Método 3: Fallback — gruda no Torso (mais estável que a cabeça)
    local anchor = tgtChar:FindFirstChild("Torso") or tgtChar:FindFirstChild("Head")
    if anchor then
        handle.CFrame = anchor.CFrame
        local weld    = Instance.new("WeldConstraint")
        weld.Part0    = handle
        weld.Part1    = anchor
        weld.Parent   = handle
    end
end

-- ============================================================
-- SEÇÃO 8: BACKUP DO VISUAL ORIGINAL
-- ============================================================

local function createBackup(player)
    if modifiedPlayers[player] then return end
    local char = player.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    local head = char and char:FindFirstChild("Head")
    if not char or not hum then return end

    local bk = {
        OriginalName     = hum.DisplayName,
        Items            = {},
        HeadItems        = {},
        HeadTransparency = head and head.Transparency or 0,
        HeadColor        = head and head.Color or WHITE,
        PartColors       = {},
        PartTransparency = {},
        PartMeshes       = {}
    }

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or
           item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
            table.insert(bk.Items, item:Clone())
        end
    end

    if head then
        for _, c in ipairs(head:GetChildren()) do
            if c:IsA("SpecialMesh") or c:IsA("Decal") then
                table.insert(bk.HeadItems, c:Clone())
            end
        end
    end

    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            bk.PartColors[part.Name]       = part.Color
            bk.PartTransparency[part.Name] = part.Transparency
            bk.PartMeshes[part.Name]       = {}
            for _, c in ipairs(part:GetChildren()) do
                if c:IsA("SpecialMesh") then
                    table.insert(bk.PartMeshes[part.Name], c:Clone())
                end
            end
        end
    end

    modifiedPlayers[player] = bk
end

-- ============================================================
-- SEÇÃO 9: LIMPEZA DO PERSONAGEM
-- ============================================================

local function cleanCharacter(char)
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Accessory") or item:IsA("Shirt") or item:IsA("Pants") or
           item:IsA("ShirtGraphic") or item:IsA("BodyColors") or item:IsA("CharacterMesh") then
            item:Destroy()
        end
    end
    local head = char:FindFirstChild("Head")
    if head then
        for _, c in ipairs(head:GetChildren()) do
            if c:IsA("SpecialMesh") or c:IsA("Decal") then c:Destroy() end
        end
    end
    for _, limb in ipairs(R6_LIMBS) do
        local part = char:FindFirstChild(limb)
        if part then
            for _, c in ipairs(part:GetChildren()) do
                if c:IsA("SpecialMesh") or c:IsA("SurfaceAppearance") then c:Destroy() end
            end
        end
    end
end

-- ============================================================
-- SEÇÃO 10: PROCESSO PRINCIPAL — APLICAR SKIN
-- ============================================================

local function processCloning()
    if isProcessing then return end

    if not selectedPlayer then
        ApplyBtn.Text = "⚠ Selecione um alvo!"
        task.wait(1.5); ApplyBtn.Text = "Aplicar Visual Completo"; return
    end

    local username = (UsernameInput.Text or ""):match("^%s*(.-)%s*$")
    if username == "" then
        ApplyBtn.Text = "⚠ Digite um username!"
        task.wait(1.5); ApplyBtn.Text = "Aplicar Visual Completo"; return
    end

    local char = selectedPlayer.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not char or not hum then
        ApplyBtn.Text = "⚠ Personagem indisponível!"
        task.wait(1.5); ApplyBtn.Text = "Aplicar Visual Completo"; return
    end

    isProcessing  = true
    ApplyBtn.Text = "Buscando usuário..."

    local ok1, targetId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    if not ok1 or not targetId then
        ApplyBtn.Text = "✗ Usuário não encontrado!"
        task.wait(2); ApplyBtn.Text = "Aplicar Visual Completo"; isProcessing = false; return
    end

    ApplyBtn.Text = "Baixando avatar..."

    local ok2, srcModel = pcall(function()
        return Players:CreateHumanoidModelFromUserId(targetId)
    end)
    if not ok2 or not srcModel then
        ApplyBtn.Text = "✗ Erro ao baixar avatar!"
        task.wait(2); ApplyBtn.Text = "Aplicar Visual Completo"; isProcessing = false; return
    end

    -- Move o modelo para longe do mapa (evita colisões e aparição visual indesejada)
    srcModel.Parent = workspace
    pcall(function() srcModel:SetPrimaryPartCFrame(CFrame.new(0, 99999, 0)) end)

    ApplyBtn.Text = "Aplicando skin..."

    createBackup(selectedPlayer)
    cleanCharacter(char)

    applyHead(srcModel, char)          -- 1. Cabeça + Headless
    applyBodyColors(srcModel, char)    -- 2. Cores (R15→R6 automático)
    applySpecialParts(srcModel, char)  -- 3. Korblox, Rthro, meshes especiais

    -- 4. Roupas e acessórios
    for _, child in ipairs(srcModel:GetChildren()) do
        if child:IsA("Shirt") or child:IsA("Pants") or child:IsA("ShirtGraphic") or
           child:IsA("BodyColors") or child:IsA("CharacterMesh") then
            child:Clone().Parent = char
        elseif child:IsA("Accessory") then
            attachAccessory(char, child:Clone())
        end
    end

    srcModel:Destroy()

    -- 5. Atualiza DisplayName para o nome de exibição do usuário copiado
    local ok3, info = pcall(function()
        return UserService:GetUserInfosByUserIdsAsync({targetId})
    end)
    setDisplayName(char, (ok3 and info and info[1]) and info[1].DisplayName or username)

    ApplyBtn.Text = "✓ Aplicado com sucesso!"
    task.wait(2); ApplyBtn.Text = "Aplicar Visual Completo"
    isProcessing = false
end

-- ============================================================
-- SEÇÃO 11: RESTAURAR VISUAL ORIGINAL
-- ============================================================

local function restoreVisuals()
    local data = selectedPlayer and modifiedPlayers[selectedPlayer]
    if not data then
        RestoreBtn.Text = "Nada para restaurar"
        task.wait(1.5); RestoreBtn.Text = "Restaurar Original"; return
    end

    local char = selectedPlayer.Character
    local hum  = char and char:FindFirstChild("Humanoid")
    if not char or not hum then return end

    cleanCharacter(char)

    for _, item in ipairs(data.Items) do
        if item:IsA("Accessory") then
            attachAccessory(char, item:Clone())
        else
            item:Clone().Parent = char
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = data.HeadTransparency
        head.Color        = data.HeadColor
        for _, item in ipairs(data.HeadItems) do item:Clone().Parent = head end
    end

    for partName, color in pairs(data.PartColors) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            part.Color        = color
            part.Transparency = data.PartTransparency[partName] or 0
            for _, c in ipairs(part:GetChildren()) do
                if c:IsA("SpecialMesh") then c:Destroy() end
            end
            if data.PartMeshes[partName] then
                for _, mesh in ipairs(data.PartMeshes[partName]) do
                    mesh:Clone().Parent = part
                end
            end
        end
    end

    setDisplayName(char, data.OriginalName)
    modifiedPlayers[selectedPlayer] = nil

    RestoreBtn.Text = "✓ Restaurado!"
    task.wait(1.5); RestoreBtn.Text = "Restaurar Original"
end

-- ============================================================
-- SEÇÃO 12: CONEXÕES DOS EVENTOS
-- ============================================================

ApplyBtn.Activated:Connect(processCloning)
RestoreBtn.Activated:Connect(restoreVisuals)
HideBtn.Activated:Connect(function() ScreenGui.Enabled = false end)
LocalPlayer.Chatted:Connect(function(msg)
    if msg:lower() == "papoi" then ScreenGui.Enabled = true end
end)
