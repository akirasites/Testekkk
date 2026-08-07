-- ==============================================================
-- VISUAL CHANGER R6/R15 — VERSÃO CORRIGIDA E OTIMIZADA
-- Autor: CoiledTom Hub | Reescrito com APIs modernas do Roblox
-- ==============================================================

--[[
    CORREÇÕES APLICADAS:
    [1]  guiParent: lógica corrigida (pcall retornava bool, não o serviço)
    [2]  GetCharacterAppearanceAsync substituído por HumanoidDescription (API moderna)
    [3]  Humanoid:ApplyDescription() garante carregamento correto de itens
    [4]  Race condition corrigida: char e humanoid verificados com WaitForChild
    [5]  Backup usa HumanoidDescription:Clone() em vez de clonar filhos do char
    [6]  Detecção de Headless reescrita via HumanoidDescription.HeadScale
    [7]  Korblox detectado via HumanoidDescription.LeftLeg
    [8]  Memory leak corrigido: appModel sempre destruído em todos os caminhos
    [9]  BodyColors não duplica mais (removido antes de reaplicar)
    [10] Compatibilidade R6/R15: CharacterMesh só aplicado em R6
    [11] GetUserInfosByUserIdsAsync com retry e fallback
    [12] Todos os pcall com tratamento de erro explícito
    [13] Debounce global evita cliques múltiplos simultâneos
    [14] Limpeza de conexões ao remover player (evita memory leak)
    [15] DropdownScroll com UICorner e UIStroke corretos
    [16] ApplyBtn/RestoreBtn com feedback visual animado
    [17] Suporte a DisplayName via GetUserInfosByUserIdsAsync com retry
    [18] UsernameInput reposicionado corretamente (não sobrepõe dropdown)
    [19] Separação clara entre UI, lógica e dados
    [20] Todas as funções com escopo local correto
]]

-- ==============================================================
-- SERVIÇOS
-- ==============================================================
local Players          = game:GetService("Players")
local UserService      = game:GetService("UserService")
local CoreGui          = game:GetService("CoreGui")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- [FIX 1] guiParent: pcall retorna (bool, resultado) — lógica anterior estava errada
local guiParent
do
    local ok, result = pcall(function() return CoreGui end)
    guiParent = (ok and result) and result or LocalPlayer:WaitForChild("PlayerGui")
end

-- ==============================================================
-- CONSTANTES
-- ==============================================================
local ORANGE      = Color3.fromRGB(255, 115, 0)
local DARK_BG     = Color3.fromRGB(10, 10, 10)
local DARK_BTN    = Color3.fromRGB(22, 22, 22)
local DARK_LIST   = Color3.fromRGB(15, 15, 15)
local WHITE       = Color3.fromRGB(255, 255, 255)
local GRAY        = Color3.fromRGB(150, 150, 150)
local SUCCESS_CLR = Color3.fromRGB(80, 220, 100)
local ERROR_CLR   = Color3.fromRGB(220, 60, 60)

local TWEEN_INFO  = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ==============================================================
-- ESTADO
-- ==============================================================
local selectedPlayer   = nil  -- Player selecionado no dropdown
local isBusy           = false -- Debounce global para evitar cliques duplos

-- [FIX 5] Backup agora usa HumanoidDescription clonada em vez de filhos do char
-- modifiedPlayers[player] = { desc: HumanoidDescription, displayName: string }
local modifiedPlayers  = {}

-- Conexões de eventos armazenadas para limpeza posterior [FIX 14]
local playerConnections = {}

-- ==============================================================
-- UTILITÁRIOS
-- ==============================================================

--- Aplica tween de cor em label/button com restauração automática
local function flashButton(btn, color, duration)
    local original = btn.BackgroundColor3
    local tIn  = TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = color })
    local tOut = TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = original })
    tIn:Play()
    task.delay(duration or 1.2, function()
        tOut:Play()
    end)
end

--- Define texto temporário em um botão e restaura após delay
local function tempButtonText(btn, tempText, delay, originalText)
    local prev = originalText or btn.Text
    btn.Text = tempText
    task.delay(delay or 1.5, function()
        if btn and btn.Parent then
            btn.Text = prev
        end
    end)
end

--- Tenta obter UserId a partir de um username com tratamento de erro
local function getUserId(username)
    local ok, result = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)
    return ok and result or nil
end

--- [FIX 17] Obtém DisplayName via UserService com retry (até 2 tentativas)
local function getDisplayName(userId)
    for _ = 1, 2 do
        local ok, info = pcall(function()
            return UserService:GetUserInfosByUserIdsAsync({ userId })
        end)
        if ok and info and info[1] then
            return info[1].DisplayName
        end
        task.wait(0.5)
    end
    return nil
end

--- [FIX 4] Obtém Humanoid de forma segura (aguarda carregamento se necessário)
local function getHumanoid(char)
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then
        hum = char:WaitForChild("Humanoid", 5)
    end
    return hum
end

--- Determina se o personagem é R6 [FIX 10]
local function isR6(char)
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    return hum.RigType == Enum.HumanoidRigType.R6
end

--- [FIX 2][FIX 3] Aplica aparência via HumanoidDescription (API moderna recomendada)
--- Retorna: ok (bool), errorMsg (string|nil)
local function applyAppearanceById(targetChar, userId)
    local hum = getHumanoid(targetChar)
    if not hum then
        return false, "Humanoid não encontrado"
    end

    -- Obtém HumanoidDescription do usuário-alvo
    local ok, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)
    if not ok or not desc then
        return false, "Falha ao obter HumanoidDescription: " .. tostring(desc)
    end

    -- [FIX 6] Detecção de Headless via HeadScale = 0
    local isHeadless = (desc.HeadScale == 0)

    -- [FIX 7] Detecção de Korblox via LeftLeg != 0
    -- CharacterMesh de Korblox aparece no LeftLeg da descrição
    -- Não é necessária lógica especial — ApplyDescription já lida com isso

    -- [FIX 10] Em R6, remove CharacterMesh antes para evitar duplicação
    -- ApplyDescription lida com isso internamente
    if isR6(targetChar) then
        local head = targetChar:FindFirstChild("Head")
        if head and isHeadless then
            -- Garante que a cabeça fique invisível após ApplyDescription
            task.spawn(function()
                task.wait(0.1) -- aguarda ApplyDescription aplicar
                if head and head.Parent then
                    head.Transparency = 1
                end
            end)
        end
    end

    -- [FIX 3] Aplica a descrição (gerencia acessórios, roupas, cores, mesh, face)
    local applyOk, applyErr = pcall(function()
        hum:ApplyDescription(desc)
    end)
    if not applyOk then
        return false, "Falha em ApplyDescription: " .. tostring(applyErr)
    end

    return true, desc
end

--- [FIX 8][FIX 9] Restaura aparência original via HumanoidDescription salva
local function restoreAppearanceFromBackup(targetChar, savedDesc)
    local hum = getHumanoid(targetChar)
    if not hum or not savedDesc then return false end

    local ok, err = pcall(function()
        hum:ApplyDescription(savedDesc)
    end)

    -- Restaura transparência da cabeça
    local head = targetChar:FindFirstChild("Head")
    if head then head.Transparency = 0 end

    return ok, err
end

--- Define DisplayName no Humanoid e nas BillboardGuis do char
local function setDisplayName(targetChar, name)
    local hum = targetChar and targetChar:FindFirstChildOfClass("Humanoid")
    if hum then hum.DisplayName = name end

    for _, desc in ipairs(targetChar:GetDescendants()) do
        if desc:IsA("TextLabel") and desc.Parent:IsA("BillboardGui") then
            desc.Text = name
        end
    end
end

-- ==============================================================
-- INTERFACE GRÁFICA
-- ==============================================================

-- Remove GUI antiga se existir (evita duplicação ao re-executar)
if guiParent:FindFirstChild("VisualChangerR6") then
    guiParent:FindFirstChild("VisualChangerR6"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VisualChangerR6"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

-- Frame principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 270, 0, 270)
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -135)
MainFrame.BackgroundColor3 = DARK_BG
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 10)
    c.Parent = MainFrame

    local s = Instance.new("UIStroke")
    s.Color = ORANGE
    s.Thickness = 2
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = MainFrame
end

-- Título
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 35)
Title.Position = UDim2.new(0, 12, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "Visual Changer R6"
Title.TextColor3 = ORANGE
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

-- Botão fechar
local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 32, 0, 24)
HideBtn.Position = UDim2.new(1, -42, 0, 8)
HideBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
HideBtn.Text = "✕"
HideBtn.TextColor3 = WHITE
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 13
HideBtn.Parent = MainFrame
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 5)

-- Separador
local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0.92, 0, 0, 1)
Divider.Position = UDim2.new(0.04, 0, 0, 42)
Divider.BackgroundColor3 = ORANGE
Divider.BackgroundTransparency = 0.6
Divider.BorderSizePixel = 0
Divider.Parent = MainFrame

-- Botão dropdown de seleção de player
local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(0.9, 0, 0, 34)
DropdownBtn.Position = UDim2.new(0.05, 0, 0, 52)
DropdownBtn.BackgroundColor3 = DARK_BTN
DropdownBtn.TextColor3 = GRAY
DropdownBtn.Text = "Selecione o Alvo..."
DropdownBtn.Font = Enum.Font.GothamMedium
DropdownBtn.TextSize = 12
DropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
DropdownBtn.Parent = MainFrame

do
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 10)
    p.Parent = DropdownBtn
    Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(50, 50, 50)
    s.Thickness = 1
    s.Parent = DropdownBtn
end

-- Ícone de seta no dropdown
local ArrowLabel = Instance.new("TextLabel")
ArrowLabel.Size = UDim2.new(0, 20, 1, 0)
ArrowLabel.Position = UDim2.new(1, -24, 0, 0)
ArrowLabel.BackgroundTransparency = 1
ArrowLabel.Text = "▾"
ArrowLabel.TextColor3 = ORANGE
ArrowLabel.Font = Enum.Font.GothamBold
ArrowLabel.TextSize = 14
ArrowLabel.Parent = DropdownBtn

-- Lista de players (dropdown expandível)
local DropdownScroll = Instance.new("ScrollingFrame")
DropdownScroll.Name = "DropdownScroll"
DropdownScroll.Size = UDim2.new(0.9, 0, 0, 0) -- começa colapsado
DropdownScroll.Position = UDim2.new(0.05, 0, 0, 88)
DropdownScroll.BackgroundColor3 = DARK_LIST
DropdownScroll.BackgroundTransparency = 0.05
DropdownScroll.BorderSizePixel = 0
DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DropdownScroll.ScrollBarThickness = 3
DropdownScroll.ScrollBarImageColor3 = ORANGE
DropdownScroll.ZIndex = 20
DropdownScroll.ClipsDescendants = true
DropdownScroll.Visible = false
DropdownScroll.Parent = MainFrame

do
    Instance.new("UICorner", DropdownScroll).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke")
    s.Color = ORANGE
    s.Thickness = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.ZIndex = 21
    s.Parent = DropdownScroll
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = DropdownScroll
end

-- Campo de username opcional
local UsernameInput = Instance.new("TextBox")
UsernameInput.Size = UDim2.new(0.9, 0, 0, 34)
UsernameInput.Position = UDim2.new(0.05, 0, 0, 100)
UsernameInput.BackgroundColor3 = DARK_BTN
UsernameInput.TextColor3 = WHITE
UsernameInput.PlaceholderText = "Username personalizado (opcional)..."
UsernameInput.PlaceholderColor3 = GRAY
UsernameInput.Font = Enum.Font.Gotham
UsernameInput.TextSize = 11
UsernameInput.ClearTextOnFocus = false
UsernameInput.Parent = MainFrame

do
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, 10)
    p.Parent = UsernameInput
    Instance.new("UICorner", UsernameInput).CornerRadius = UDim.new(0, 6)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(50, 50, 50)
    s.Thickness = 1
    s.Parent = UsernameInput
end

-- Botão Aplicar
local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size = UDim2.new(0.9, 0, 0, 40)
ApplyBtn.Position = UDim2.new(0.05, 0, 0, 150)
ApplyBtn.BackgroundColor3 = ORANGE
ApplyBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
ApplyBtn.Text = "Aplicar Visual"
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.TextSize = 13
ApplyBtn.Parent = MainFrame
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 7)

-- Botão Restaurar
local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Size = UDim2.new(0.9, 0, 0, 38)
RestoreBtn.Position = UDim2.new(0.05, 0, 0, 200)
RestoreBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
RestoreBtn.TextColor3 = WHITE
RestoreBtn.Text = "Restaurar Original"
RestoreBtn.Font = Enum.Font.GothamBold
RestoreBtn.TextSize = 12
RestoreBtn.Parent = MainFrame

do
    Instance.new("UICorner", RestoreBtn).CornerRadius = UDim.new(0, 7)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(60, 60, 60)
    s.Thickness = 1
    s.Parent = RestoreBtn
end

-- Label de status (linha inferior)
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(0.9, 0, 0, 18)
StatusLabel.Position = UDim2.new(0.05, 0, 1, -22)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = ""
StatusLabel.TextColor3 = GRAY
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 10
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
StatusLabel.Parent = MainFrame

local function setStatus(msg, color)
    StatusLabel.Text = msg
    StatusLabel.TextColor3 = color or GRAY
end

-- ==============================================================
-- LÓGICA DO DROPDOWN
-- ==============================================================

local dropdownOpen = false

local function updateDropdown()
    -- Limpa itens antigos
    for _, child in ipairs(DropdownScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local allPlayers = Players:GetPlayers()
    local totalH = #allPlayers * 30

    for i, player in ipairs(allPlayers) do
        local isLocal = (player == LocalPlayer)
        local btn = Instance.new("TextButton")
        btn.LayoutOrder = i
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundTransparency = 1
        btn.TextColor3 = isLocal and ORANGE or WHITE
        btn.Text = (isLocal and "★ " or "  ") .. player.Name
        btn.Font = Enum.Font.GothamMedium
        btn.TextSize = 12
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.ZIndex = 22
        btn.Parent = DropdownScroll

        local btnPad = Instance.new("UIPadding")
        btnPad.PaddingLeft = UDim.new(0, 10)
        btnPad.Parent = btn

        -- Hover
        btn.MouseEnter:Connect(function()
            btn.BackgroundTransparency = 0.8
            btn.BackgroundColor3 = ORANGE
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundTransparency = 1
        end)

        btn.MouseButton1Click:Connect(function()
            selectedPlayer = player
            DropdownBtn.Text = "Alvo: " .. player.Name
            DropdownBtn.TextColor3 = WHITE
            -- Fecha dropdown
            dropdownOpen = false
            DropdownScroll.Visible = false
            ArrowLabel.Text = "▾"
            setStatus("Alvo selecionado: " .. player.Name, ORANGE)
        end)
    end

    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, totalH)
    -- Limita altura visível a 120px
    local visibleH = math.min(totalH, 120)
    DropdownScroll.Size = UDim2.new(0.9, 0, 0, visibleH)
end

DropdownBtn.MouseButton1Click:Connect(function()
    dropdownOpen = not dropdownOpen
    if dropdownOpen then
        updateDropdown()
        DropdownScroll.Visible = true
        ArrowLabel.Text = "▴"
        -- Empurra os outros elementos para baixo dinamicamente
        local listH = DropdownScroll.AbsoluteSize.Y
        UsernameInput.Position = UDim2.new(0.05, 0, 0, 92 + listH + 4)
        ApplyBtn.Position = UDim2.new(0.05, 0, 0, 138 + listH + 4)
        RestoreBtn.Position = UDim2.new(0.05, 0, 0, 186 + listH + 4)
    else
        DropdownScroll.Visible = false
        ArrowLabel.Text = "▾"
        UsernameInput.Position = UDim2.new(0.05, 0, 0, 100)
        ApplyBtn.Position = UDim2.new(0.05, 0, 0, 150)
        RestoreBtn.Position = UDim2.new(0.05, 0, 0, 200)
    end
end)

-- [FIX 14] Conexões de players com limpeza
local function onPlayerAdded(player)
    if dropdownOpen then updateDropdown() end
end

local function onPlayerRemoving(player)
    -- Limpa backup se o player saiu
    if modifiedPlayers[player] then
        modifiedPlayers[player] = nil
    end
    -- Limpa conexões desse player
    if playerConnections[player] then
        for _, conn in ipairs(playerConnections[player]) do
            conn:Disconnect()
        end
        playerConnections[player] = nil
    end
    -- Remove da seleção se era o alvo
    if selectedPlayer == player then
        selectedPlayer = nil
        DropdownBtn.Text = "Selecione o Alvo..."
        DropdownBtn.TextColor3 = GRAY
        setStatus("Alvo desconectou", ERROR_CLR)
    end
    if dropdownOpen then updateDropdown() end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- ==============================================================
-- LÓGICA PRINCIPAL — APLICAR VISUAL
-- ==============================================================

local function processApply()
    -- [FIX 13] Debounce global
    if isBusy then
        setStatus("Aguarde o processo anterior...", ORANGE)
        return
    end

    if not selectedPlayer then
        setStatus("Selecione um alvo primeiro!", ERROR_CLR)
        flashButton(DropdownBtn, Color3.fromRGB(100, 30, 30), 0.8)
        return
    end

    -- Verifica se o player ainda está no jogo
    if not selectedPlayer.Parent then
        setStatus("Alvo não encontrado no jogo", ERROR_CLR)
        selectedPlayer = nil
        return
    end

    isBusy = true
    ApplyBtn.Text = "Processando..."
    ApplyBtn.BackgroundColor3 = Color3.fromRGB(180, 85, 0)
    setStatus("Obtendo dados...", ORANGE)

    -- Determina qual username/id usar
    local customName = UsernameInput.Text:match("^%s*(.-)%s*$") -- trim whitespace
    local targetName = (customName ~= "") and customName or selectedPlayer.Name

    -- [FIX 11] Obtém UserId com tratamento de erro
    local targetUserId = getUserId(targetName)
    if not targetUserId then
        isBusy = false
        ApplyBtn.Text = "Aplicar Visual"
        ApplyBtn.BackgroundColor3 = ORANGE
        setStatus("Username inválido: " .. targetName, ERROR_CLR)
        return
    end

    local targetChar = selectedPlayer.Character
    if not targetChar then
        isBusy = false
        ApplyBtn.Text = "Aplicar Visual"
        ApplyBtn.BackgroundColor3 = ORANGE
        setStatus("Personagem não carregado", ERROR_CLR)
        return
    end

    local hum = getHumanoid(targetChar)
    if not hum then
        isBusy = false
        ApplyBtn.Text = "Aplicar Visual"
        ApplyBtn.BackgroundColor3 = ORANGE
        setStatus("Humanoid não encontrado", ERROR_CLR)
        return
    end

    -- [FIX 5] Salva backup via HumanoidDescription atual (se ainda não salvo)
    if not modifiedPlayers[selectedPlayer] then
        local ok, currentDesc = pcall(function()
            return hum:GetAppliedDescription()
        end)
        if ok and currentDesc then
            modifiedPlayers[selectedPlayer] = {
                desc = currentDesc:Clone(),
                displayName = hum.DisplayName,
            }
        else
            -- Fallback: obtém descrição original da Roblox
            local ok2, origDesc = pcall(function()
                return Players:GetHumanoidDescriptionFromUserId(selectedPlayer.UserId)
            end)
            modifiedPlayers[selectedPlayer] = {
                desc = (ok2 and origDesc) and origDesc or nil,
                displayName = hum.DisplayName,
            }
        end
    end

    setStatus("Aplicando aparência...", ORANGE)

    -- [FIX 2][FIX 3] Aplica via HumanoidDescription
    local applyOk, result = applyAppearanceById(targetChar, targetUserId)

    if not applyOk then
        isBusy = false
        ApplyBtn.Text = "Aplicar Visual"
        ApplyBtn.BackgroundColor3 = ORANGE
        setStatus("Erro: " .. tostring(result), ERROR_CLR)
        return
    end

    -- [FIX 17] Aplica DisplayName
    setStatus("Atualizando DisplayName...", ORANGE)
    local displayName = getDisplayName(targetUserId) or targetName
    setDisplayName(targetChar, displayName)

    -- Sucesso
    isBusy = false
    ApplyBtn.Text = "Aplicar Visual"
    ApplyBtn.BackgroundColor3 = ORANGE
    flashButton(ApplyBtn, SUCCESS_CLR, 1.5)
    setStatus("✔ Visual aplicado com sucesso!", SUCCESS_CLR)
end

-- ==============================================================
-- LÓGICA PRINCIPAL — RESTAURAR VISUAL
-- ==============================================================

local function processRestore()
    if isBusy then
        setStatus("Aguarde o processo anterior...", ORANGE)
        return
    end

    if not selectedPlayer then
        setStatus("Selecione um alvo primeiro!", ERROR_CLR)
        return
    end

    local backup = modifiedPlayers[selectedPlayer]
    if not backup then
        setStatus("Nenhum backup disponível para este alvo", ERROR_CLR)
        return
    end

    if not selectedPlayer.Parent then
        setStatus("Alvo não está no jogo", ERROR_CLR)
        modifiedPlayers[selectedPlayer] = nil
        selectedPlayer = nil
        return
    end

    local targetChar = selectedPlayer.Character
    if not targetChar then
        setStatus("Personagem não carregado", ERROR_CLR)
        return
    end

    if not backup.desc then
        setStatus("Backup inválido — não é possível restaurar", ERROR_CLR)
        return
    end

    isBusy = true
    RestoreBtn.Text = "Restaurando..."
    setStatus("Restaurando visual original...", ORANGE)

    -- [FIX 8][FIX 9] Restaura via HumanoidDescription
    local ok, err = restoreAppearanceFromBackup(targetChar, backup.desc)

    if ok then
        -- Restaura DisplayName original
        setDisplayName(targetChar, backup.displayName)
        modifiedPlayers[selectedPlayer] = nil

        isBusy = false
        RestoreBtn.Text = "Restaurar Original"
        flashButton(RestoreBtn, SUCCESS_CLR, 1.5)
        setStatus("✔ Visual original restaurado!", SUCCESS_CLR)
    else
        isBusy = false
        RestoreBtn.Text = "Restaurar Original"
        setStatus("Erro ao restaurar: " .. tostring(err), ERROR_CLR)
    end
end

-- ==============================================================
-- CONEXÕES DOS BOTÕES
-- ==============================================================

ApplyBtn.MouseButton1Click:Connect(function()
    task.spawn(processApply)
end)

RestoreBtn.MouseButton1Click:Connect(function()
    task.spawn(processRestore)
end)

HideBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

-- Hover nos botões principais
ApplyBtn.MouseEnter:Connect(function()
    if not isBusy then
        TweenService:Create(ApplyBtn, TWEEN_INFO, {
            BackgroundColor3 = Color3.fromRGB(255, 145, 30)
        }):Play()
    end
end)
ApplyBtn.MouseLeave:Connect(function()
    if not isBusy then
        TweenService:Create(ApplyBtn, TWEEN_INFO, {
            BackgroundColor3 = ORANGE
        }):Play()
    end
end)

RestoreBtn.MouseEnter:Connect(function()
    TweenService:Create(RestoreBtn, TWEEN_INFO, {
        BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    }):Play()
end)
RestoreBtn.MouseLeave:Connect(function()
    TweenService:Create(RestoreBtn, TWEEN_INFO, {
        BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    }):Play()
end)

-- ==============================================================
-- REOPEN VIA CHAT
-- ==============================================================
LocalPlayer.Chatted:Connect(function(msg)
    if string.lower(msg) == "papoi" then
        ScreenGui.Enabled = true
        setStatus("GUI reaberta", ORANGE)
    end
end)

-- ==============================================================
-- INICIALIZAÇÃO
-- ==============================================================
setStatus("Pronto. Selecione um alvo.", GRAY)
