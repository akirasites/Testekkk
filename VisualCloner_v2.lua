-- ╔══════════════════════════════════════════════════════════════════╗
-- ║          VISUAL CLONER v2.0 — CLIENT-SIDE ONLY                  ║
-- ║   HumanoidDescription Engine | R6 + R15 | Animações | Mobile    ║
-- ║   By CoiledTom — Delta Executor Compatible                       ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ══════════════════════════════════════════
--  SERVIÇOS
-- ══════════════════════════════════════════
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer
local Character        = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid         = Character:WaitForChild("Humanoid")

-- Guarda pai seguro (CoreGui ou PlayerGui)
local guiParent
do
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    guiParent = (ok and cg) and cg or LocalPlayer:WaitForChild("PlayerGui")
end

-- ══════════════════════════════════════════
--  ESTADO GLOBAL
-- ══════════════════════════════════════════
local originalDesc = nil          -- HumanoidDescription original salvo
local isBusy       = false        -- Evita duplo clique
local isMinimized  = false
local dragActive   = false
local dragStart, frameStart

-- ══════════════════════════════════════════
--  PALETA DE CORES
-- ══════════════════════════════════════════
local C = {
    BG         = Color3.fromRGB(8, 8, 14),
    BG2        = Color3.fromRGB(14, 14, 24),
    BG3        = Color3.fromRGB(20, 20, 36),
    ACCENT     = Color3.fromRGB(120, 60, 255),   -- Roxo
    ACCENT2    = Color3.fromRGB(60, 120, 255),   -- Azul
    RED        = Color3.fromRGB(220, 40, 80),
    GREEN      = Color3.fromRGB(50, 220, 120),
    ORANGE     = Color3.fromRGB(255, 160, 30),
    TEXT       = Color3.fromRGB(220, 220, 240),
    SUBTEXT    = Color3.fromRGB(130, 130, 160),
    WHITE      = Color3.fromRGB(255, 255, 255),
    DARK       = Color3.fromRGB(4, 4, 10),
}

-- ══════════════════════════════════════════
--  HELPERS DE UI
-- ══════════════════════════════════════════
local function corner(r, p) local o = Instance.new("UICorner") o.CornerRadius = UDim.new(0,r) o.Parent = p return o end
local function stroke(col, thick, p) local o = Instance.new("UIStroke") o.Color = col o.Thickness = thick o.ApplyStrokeMode = Enum.ApplyStrokeMode.Border o.Parent = p return o end
local function gradient(c0, c1, rot, p)
    local o = Instance.new("UIGradient")
    o.Color = ColorSequence.new(c0, c1)
    o.Rotation = rot
    o.Parent = p
    return o
end
local function padding(l,r,t,b, p)
    local o = Instance.new("UIPadding")
    o.PaddingLeft = UDim.new(0,l) o.PaddingRight = UDim.new(0,r)
    o.PaddingTop  = UDim.new(0,t) o.PaddingBottom = UDim.new(0,b)
    o.Parent = p
    return o
end
local function tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    return TweenService:Create(obj, info, props)
end
local function label(text, size, color, bold, parent)
    local o = Instance.new("TextLabel")
    o.Text = text o.TextSize = size or 13 o.TextColor3 = color or C.TEXT
    o.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    o.BackgroundTransparency = 1 o.TextXAlignment = Enum.TextXAlignment.Left
    o.Size = UDim2.new(1,0,0,size and size+6 or 20)
    o.Parent = parent return o
end

-- ══════════════════════════════════════════
--  CONSTRUÇÃO DA GUI
-- ══════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VisualClonerV2"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = guiParent

-- ── Moldura principal ──────────────────────────────────────────────
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 300, 0, 370)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -185)
MainFrame.BackgroundColor3 = C.BG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Parent = ScreenGui
corner(14, MainFrame)
stroke(C.ACCENT, 1.5, MainFrame)

-- Glow de fundo (decorativo)
local GlowFrame = Instance.new("Frame")
GlowFrame.Size = UDim2.new(1,0,0,3)
GlowFrame.Position = UDim2.new(0,0,0,0)
GlowFrame.BackgroundColor3 = C.ACCENT
GlowFrame.BorderSizePixel = 0
GlowFrame.ZIndex = 2
GlowFrame.Parent = MainFrame
gradient(C.ACCENT, C.ACCENT2, 90, GlowFrame)

-- ── Topbar ────────────────────────────────────────────────────────
local Topbar = Instance.new("Frame")
Topbar.Name = "Topbar"
Topbar.Size = UDim2.new(1,0,0,48)
Topbar.Position = UDim2.new(0,0,0,3)
Topbar.BackgroundColor3 = C.BG2
Topbar.BorderSizePixel = 0
Topbar.ZIndex = 3
Topbar.Parent = MainFrame

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, C.ACCENT),
    ColorSequenceKeypoint.new(0.5, C.ACCENT2),
    ColorSequenceKeypoint.new(1, C.BG2)
})
TopGradient.Rotation = 90
TopGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.85),
    NumberSequenceKeypoint.new(1, 1)
})
TopGradient.Parent = Topbar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size = UDim2.new(0,28,0,28)
TitleIcon.Position = UDim2.new(0,12,0,10)
TitleIcon.BackgroundColor3 = C.ACCENT
TitleIcon.BackgroundTransparency = 0.6
TitleIcon.Text = "VC"
TitleIcon.TextColor3 = C.WHITE
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.TextSize = 11
TitleIcon.ZIndex = 4
TitleIcon.Parent = Topbar
corner(6, TitleIcon)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0,160,0,20)
TitleLabel.Position = UDim2.new(0,48,0,8)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Visual Cloner"
TitleLabel.TextColor3 = C.WHITE
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 4
TitleLabel.Parent = Topbar

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(0,160,0,14)
SubLabel.Position = UDim2.new(0,48,0,26)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = "Client-Side Only • CoiledTom"
SubLabel.TextColor3 = C.SUBTEXT
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextSize = 10
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.ZIndex = 4
SubLabel.Parent = Topbar

-- Botões de controle (Minimize e Hide)
local function makeCtrlBtn(text, posX, bgCol)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,26,0,26)
    btn.Position = UDim2.new(1, posX, 0, 11)
    btn.BackgroundColor3 = bgCol
    btn.BackgroundTransparency = 0.5
    btn.Text = text
    btn.TextColor3 = C.WHITE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.ZIndex = 5
    btn.Parent = Topbar
    corner(6, btn)
    return btn
end

local MinBtn  = makeCtrlBtn("−", -60, C.ACCENT)
local HideBtn = makeCtrlBtn("×", -30, C.RED)

-- ── Corpo da GUI ──────────────────────────────────────────────────
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1,0,1,-51)
Body.Position = UDim2.new(0,0,0,51)
Body.BackgroundTransparency = 1
Body.ZIndex = 3
Body.Parent = MainFrame
padding(14,14,12,12, Body)

local BodyLayout = Instance.new("UIListLayout")
BodyLayout.SortOrder = Enum.SortOrder.LayoutOrder
BodyLayout.Padding = UDim.new(0,10)
BodyLayout.Parent = Body

-- ── Input de Username ─────────────────────────────────────────────
local InputWrap = Instance.new("Frame")
InputWrap.Size = UDim2.new(1,0,0,44)
InputWrap.BackgroundColor3 = C.BG3
InputWrap.BorderSizePixel = 0
InputWrap.LayoutOrder = 1
InputWrap.Parent = Body
corner(8, InputWrap)
stroke(C.ACCENT, 1, InputWrap)

local InputIcon = Instance.new("TextLabel")
InputIcon.Size = UDim2.new(0,30,1,0)
InputIcon.Position = UDim2.new(0,8,0,0)
InputIcon.BackgroundTransparency = 1
InputIcon.Text = "@"
InputIcon.TextColor3 = C.ACCENT
InputIcon.Font = Enum.Font.GothamBold
InputIcon.TextSize = 16
InputIcon.ZIndex = 4
InputIcon.Parent = InputWrap

local UsernameInput = Instance.new("TextBox")
UsernameInput.Size = UDim2.new(1,-48,1,0)
UsernameInput.Position = UDim2.new(0,36,0,0)
UsernameInput.BackgroundTransparency = 1
UsernameInput.Text = ""
UsernameInput.PlaceholderText = "Digite o Username..."
UsernameInput.PlaceholderColor3 = C.SUBTEXT
UsernameInput.TextColor3 = C.TEXT
UsernameInput.Font = Enum.Font.Gotham
UsernameInput.TextSize = 13
UsernameInput.ClearTextOnFocus = false
UsernameInput.ZIndex = 4
UsernameInput.Parent = InputWrap

local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0,26,0,26)
ClearBtn.Position = UDim2.new(1,-32,0,9)
ClearBtn.BackgroundColor3 = C.BG
ClearBtn.BackgroundTransparency = 0.4
ClearBtn.Text = "✕"
ClearBtn.TextColor3 = C.SUBTEXT
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.TextSize = 11
ClearBtn.ZIndex = 5
ClearBtn.Parent = InputWrap
corner(5, ClearBtn)

-- ── Área de Status ────────────────────────────────────────────────
local StatusBox = Instance.new("Frame")
StatusBox.Size = UDim2.new(1,0,0,50)
StatusBox.BackgroundColor3 = C.BG2
StatusBox.BorderSizePixel = 0
StatusBox.LayoutOrder = 2
StatusBox.ClipsDescendants = true
StatusBox.Parent = Body
corner(8, StatusBox)
stroke(C.SUBTEXT, 1, StatusBox)

local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.new(0,8,0,8)
StatusDot.Position = UDim2.new(0,12,0.5,-4)
StatusDot.BackgroundColor3 = C.SUBTEXT
StatusDot.BorderSizePixel = 0
StatusDot.Parent = StatusBox
corner(4, StatusDot)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1,-32,1,0)
StatusLabel.Position = UDim2.new(0,28,0,0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Aguardando username..."
StatusLabel.TextColor3 = C.SUBTEXT
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextWrapped = true
StatusLabel.ZIndex = 4
StatusLabel.Parent = StatusBox

-- ── Log de itens skippados ────────────────────────────────────────
local LogBox = Instance.new("ScrollingFrame")
LogBox.Size = UDim2.new(1,0,0,72)
LogBox.BackgroundColor3 = C.DARK
LogBox.BorderSizePixel = 0
LogBox.LayoutOrder = 3
LogBox.ScrollBarThickness = 3
LogBox.ScrollBarImageColor3 = C.ACCENT
LogBox.CanvasSize = UDim2.new(0,0,0,0)
LogBox.ClipsDescendants = true
LogBox.Parent = Body
corner(8, LogBox)
stroke(C.BG3, 1, LogBox)
padding(6,6,4,4, LogBox)

local LogLayout = Instance.new("UIListLayout")
LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
LogLayout.Padding = UDim.new(0,2)
LogLayout.Parent = LogBox

local function addLog(text, col)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,0,14)
    l.BackgroundTransparency = 1
    l.Text = "› " .. text
    l.TextColor3 = col or C.SUBTEXT
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.ZIndex = 4
    l.LayoutOrder = #LogBox:GetChildren()
    l.Parent = LogBox
    LogBox.CanvasSize = UDim2.new(0,0,0, LogLayout.AbsoluteContentSize.Y + 8)
    LogBox.CanvasPosition = Vector2.new(0, math.max(0, LogLayout.AbsoluteContentSize.Y - 60))
end

local function clearLog()
    for _, c in pairs(LogBox:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    LogBox.CanvasSize = UDim2.new(0,0,0,0)
end

-- ── Botão Aplicar ─────────────────────────────────────────────────
local function makeBtn(text, col, col2, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,0,42)
    btn.BackgroundColor3 = col
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = C.WHITE
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.LayoutOrder = order
    btn.ZIndex = 4
    btn.Parent = Body
    corner(8, btn)
    if col2 then gradient(col, col2, 90, btn) end
    return btn
end

local ApplyBtn   = makeBtn("▶  Aplicar Avatar", C.ACCENT, C.ACCENT2, 4)
local RestoreBtn = makeBtn("↺  Restaurar Original", C.BG3, nil, 5)
stroke(C.SUBTEXT, 1, RestoreBtn)

-- Indicador de loading (barra animada)
local LoadBar = Instance.new("Frame")
LoadBar.Size = UDim2.new(0,0,0,3)
LoadBar.Position = UDim2.new(0,0,1,-3)
LoadBar.BackgroundColor3 = C.ACCENT
LoadBar.BorderSizePixel = 0
LoadBar.ZIndex = 6
LoadBar.Visible = false
LoadBar.Parent = MainFrame
gradient(C.ACCENT, C.ACCENT2, 90, LoadBar)

-- ══════════════════════════════════════════
--  STATUS HELPER
-- ══════════════════════════════════════════
local statusTween = nil
local function setStatus(text, color, showDot)
    if statusTween then statusTween:Cancel() end
    StatusLabel.Text = text
    StatusLabel.TextColor3 = color or C.SUBTEXT
    StatusDot.BackgroundColor3 = color or C.SUBTEXT
    -- pequena animação de pop
    StatusBox.BackgroundTransparency = 1
    statusTween = tween(StatusBox, {BackgroundTransparency = 0}, 0.15)
    statusTween:Play()
end

local loadTween = nil
local function showLoading(active)
    LoadBar.Visible = active
    if loadTween then loadTween:Cancel() end
    if active then
        LoadBar.Size = UDim2.new(0,0,0,3)
        loadTween = tween(LoadBar, {Size = UDim2.new(0.7,0,0,3)}, 1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        loadTween:Play()
    else
        LoadBar.Size = UDim2.new(1,0,0,3)
        loadTween = tween(LoadBar, {Size = UDim2.new(0,0,0,3)}, 0.3)
        loadTween:Play()
        task.delay(0.35, function() LoadBar.Visible = false end)
    end
end

-- ══════════════════════════════════════════
--  DRAG SYSTEM (MOBILE + PC)
-- ══════════════════════════════════════════
local function makeDraggable(handle, frame)
    local dragging = false
    local dragStart_, startPos

    local function onInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart_ = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end

    handle.InputBegan:Connect(onInput)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart_
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

makeDraggable(Topbar, MainFrame)

-- ══════════════════════════════════════════
--  MINIMIZAR
-- ══════════════════════════════════════════
local FULL_H = 370
local MINI_H = 51

MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    local target = isMinimized and MINI_H or FULL_H
    local tw = tween(MainFrame, {Size = UDim2.new(0,300,0,target)}, 0.25, Enum.EasingStyle.Back)
    tw:Play()
    MinBtn.Text = isMinimized and "+" or "−"
end)

HideBtn.MouseButton1Click:Connect(function()
    ScreenGui.Enabled = false
end)

LocalPlayer.Chatted:Connect(function(msg)
    if string.lower(msg) == "papoi" then
        ScreenGui.Enabled = true
    end
end)

ClearBtn.MouseButton1Click:Connect(function()
    UsernameInput.Text = ""
    setStatus("Aguardando username...", C.SUBTEXT)
    clearLog()
end)

-- Hover ApplyBtn
ApplyBtn.MouseEnter:Connect(function()
    tween(ApplyBtn, {BackgroundTransparency = 0.2}, 0.15):Play()
end)
ApplyBtn.MouseLeave:Connect(function()
    tween(ApplyBtn, {BackgroundTransparency = 0}, 0.15):Play()
end)

-- ══════════════════════════════════════════
--  NÚCLEO: DETEÇÃO DE RIG
-- ══════════════════════════════════════════
local function getRigType()
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if hum.RigType == Enum.HumanoidRigType.R15 then return "R15" end
        return "R6"
    end
    return "R6"
end

-- ══════════════════════════════════════════
--  NÚCLEO: APLICAÇÃO VIA HUMANOIDDESCRIPTION
--  (único método robusto para Korblox, Headless, animações, escalas)
-- ══════════════════════════════════════════
local function applyAvatarFromDescription(desc)
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum then
        addLog("Humanoid não encontrado!", C.RED)
        return false
    end

    -- Aplica a descrição completa (roupas, acessórios, corpo, face, escalas)
    local ok, err = pcall(function()
        hum:ApplyDescription(desc)
    end)

    if not ok then
        addLog("Erro ApplyDescription: " .. tostring(err), C.RED)
        return false
    end

    return true
end

-- ══════════════════════════════════════════
--  NÚCLEO: ANIMAÇÕES (R15)
-- ══════════════════════════════════════════
local function applyAnimations(desc)
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local animator = hum:FindFirstChildOfClass("Animator")
        or hum:FindFirstChild("Animate")

    -- Mapa de animações do HumanoidDescription para o script Animate
    local animMap = {
        ["idle"]       = {desc.IdleAnimation},
        ["walk"]       = {desc.WalkAnimation},
        ["run"]        = {desc.RunAnimation},
        ["jump"]       = {desc.JumpAnimation},
        ["fall"]       = {desc.FallAnimation},
        ["climb"]      = {desc.ClimbAnimation},
        ["swim"]       = {desc.SwimAnimation},
        ["swimidle"]   = {desc.SwimIdleAnimation},
    }

    -- Tenta atualizar o script Animate (existe na maioria dos jogos R15)
    local animScript = Character:FindFirstChild("Animate")
    if animScript and animScript:IsA("LocalScript") then
        for animName, ids in pairs(animMap) do
            local animFolder = animScript:FindFirstChild(animName)
            if animFolder then
                for i, child in pairs(animFolder:GetChildren()) do
                    if child:IsA("Animation") and ids[i] and ids[i] ~= 0 then
                        child.AnimationId = "rbxassetid://" .. ids[i]
                        addLog("Anim " .. animName .. " → " .. ids[i], C.ACCENT2)
                    end
                end
            end
        end
    else
        addLog("Script Animate não encontrado (normal em alguns jogos)", C.ORANGE)
    end
end

-- ══════════════════════════════════════════
--  NÚCLEO: KORBLOX / HEADLESS FIX R6
--  No R6, ApplyDescription não funciona para CharacterMesh.
--  Precisamos adicionar manualmente os CharacterMesh.
-- ══════════════════════════════════════════
local function applyR6CharacterMesh(userId)
    -- Busca o modelo de aparência (inclui CharacterMesh para Korblox)
    local ok, appModel = pcall(function()
        return Players:GetCharacterAppearanceAsync(userId)
    end)
    if not ok or not appModel then
        addLog("Falha ao buscar CharacterMesh (Korblox)", C.ORANGE)
        return
    end

    -- Remove meshes velhos
    for _, item in pairs(Character:GetChildren()) do
        if item:IsA("CharacterMesh") then
            item:Destroy()
        end
    end

    -- Aplica novos meshes (é o que faz Korblox aparecer no R6)
    local meshCount = 0
    for _, item in pairs(appModel:GetChildren()) do
        if item:IsA("CharacterMesh") then
            item:Clone().Parent = Character
            meshCount = meshCount + 1
        end
    end

    if meshCount > 0 then
        addLog("CharacterMesh R6: " .. meshCount .. " partes aplicadas", C.GREEN)
    else
        addLog("Nenhum CharacterMesh especial (normal)", C.SUBTEXT)
    end

    appModel:Destroy()
end

-- ══════════════════════════════════════════
--  NÚCLEO: HEADLESS FIX
--  HumanoidDescription.HeadScale = 0 = headless.
--  ApplyDescription já trata isso, mas a transparência da cabeça
--  precisa ser forçada localmente.
-- ══════════════════════════════════════════
local function fixHeadless(desc)
    local head = Character:FindFirstChild("Head")
    if not head then return end

    -- HeadScale muito pequena = Headless
    local isHeadless = (desc.HeadScale < 0.1)

    if isHeadless then
        head.Transparency = 1
        -- Esconde decal de face também
        for _, item in pairs(head:GetChildren()) do
            if item:IsA("Decal") or item.Name == "face" then
                item.Transparency = 1
            end
        end
        addLog("Headless aplicado!", C.ACCENT)
    else
        head.Transparency = 0
        for _, item in pairs(head:GetChildren()) do
            if item:IsA("Decal") or item.Name == "face" then
                item.Transparency = 0
            end
        end
    end
end

-- ══════════════════════════════════════════
--  FLUXO PRINCIPAL: CLONAR AVATAR
-- ══════════════════════════════════════════
local function cloneAvatar()
    if isBusy then return end
    local username = UsernameInput.Text
    if username == "" or username == " " then
        setStatus("Digite um username válido!", C.RED)
        return
    end

    isBusy = true
    clearLog()
    showLoading(true)
    ApplyBtn.Text = "⏳  Carregando..."
    ApplyBtn.Active = false

    -- Salva original uma única vez
    local hum = Character:FindFirstChildOfClass("Humanoid")
    if not hum then
        setStatus("Humanoid não encontrado!", C.RED)
        isBusy = false
        showLoading(false)
        ApplyBtn.Text = "▶  Aplicar Avatar"
        ApplyBtn.Active = true
        return
    end

    if not originalDesc then
        local ok, desc = pcall(function() return hum:GetAppliedDescription() end)
        if ok and desc then
            originalDesc = desc
            addLog("Backup original salvo", C.GREEN)
        else
            addLog("Aviso: backup original falhou", C.ORANGE)
        end
    end

    -- 1. Resolve UserId
    setStatus("Buscando usuário...", C.SUBTEXT)
    local okId, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not okId or not userId then
        setStatus("Usuário '" .. username .. "' não encontrado!", C.RED)
        addLog("GetUserIdFromNameAsync falhou", C.RED)
        isBusy = false
        showLoading(false)
        ApplyBtn.Text = "▶  Aplicar Avatar"
        ApplyBtn.Active = true
        return
    end

    addLog("UserId: " .. tostring(userId), C.SUBTEXT)

    -- 2. Busca HumanoidDescription
    setStatus("Baixando avatar...", C.SUBTEXT)
    local okDesc, desc = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)

    if not okDesc or not desc then
        setStatus("Não foi possível baixar o avatar!", C.RED)
        addLog("GetHumanoidDescriptionFromUserId falhou", C.RED)
        isBusy = false
        showLoading(false)
        ApplyBtn.Text = "▶  Aplicar Avatar"
        ApplyBtn.Active = true
        return
    end

    addLog("HumanoidDescription obtido", C.GREEN)

    -- 3. Aplica descrição (roupas, acessórios, face, escalas, Headless, Korblox R15)
    setStatus("Aplicando visual...", C.ACCENT)
    local applied = applyAvatarFromDescription(desc)

    if applied then
        addLog("ApplyDescription: OK", C.GREEN)
    end

    -- 4. Fix Headless (transparência da cabeça)
    task.wait(0.1)
    fixHeadless(desc)

    -- 5. Korblox R6: CharacterMesh manual
    local rigType = getRigType()
    addLog("Rig detectado: " .. rigType, C.SUBTEXT)

    if rigType == "R6" then
        setStatus("Aplicando pacote R6...", C.ACCENT)
        applyR6CharacterMesh(userId)
    end

    -- 6. Animações (R15 principalmente, tenta em ambos)
    setStatus("Aplicando animações...", C.ACCENT2)
    task.wait(0.1)
    applyAnimations(desc)

    -- 7. Finaliza
    showLoading(false)
    setStatus("✓ Avatar de @" .. username .. " aplicado!", C.GREEN)
    ApplyBtn.Text = "✓  Aplicado!"
    task.wait(2)
    ApplyBtn.Text = "▶  Aplicar Avatar"
    ApplyBtn.Active = true
    isBusy = false
end

-- ══════════════════════════════════════════
--  RESTAURAR ORIGINAL
-- ══════════════════════════════════════════
local function restoreAvatar()
    if isBusy then return end
    if not originalDesc then
        setStatus("Nenhum backup encontrado!", C.ORANGE)
        return
    end

    isBusy = true
    showLoading(true)
    RestoreBtn.Text = "⏳  Restaurando..."
    setStatus("Restaurando avatar original...", C.SUBTEXT)
    clearLog()

    local hum = Character:FindFirstChildOfClass("Humanoid")
    if hum then
        local ok, err = pcall(function()
            hum:ApplyDescription(originalDesc)
        end)
        if ok then
            addLog("Avatar original restaurado", C.GREEN)
            -- Fix head original
            fixHeadless(originalDesc)

            -- Restaura CharacterMesh R6 original
            if getRigType() == "R6" then
                for _, item in pairs(Character:GetChildren()) do
                    if item:IsA("CharacterMesh") then item:Destroy() end
                end
                for _, item in pairs(originalDesc:GetChildren()) do
                    if item:IsA("CharacterMesh") then item:Clone().Parent = Character end
                end
            end

            setStatus("✓ Avatar original restaurado!", C.GREEN)
        else
            setStatus("Erro ao restaurar: " .. tostring(err), C.RED)
            addLog(tostring(err), C.RED)
        end
    else
        setStatus("Humanoid não encontrado!", C.RED)
    end

    showLoading(false)
    RestoreBtn.Text = "↺  Restaurar Original"
    RestoreBtn.Active = true
    isBusy = false
end

-- ══════════════════════════════════════════
--  RECONECTA QUANDO O PERSONAGEM RESPAWNA
-- ══════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid  = newChar:WaitForChild("Humanoid")
    originalDesc = nil -- reseta backup ao spawnar
    setStatus("Personagem respawnou. Pronto.", C.SUBTEXT)
    clearLog()
    addLog("Personagem reconectado", C.SUBTEXT)
end)

-- ══════════════════════════════════════════
--  EVENTOS DE BOTÃO
-- ══════════════════════════════════════════
ApplyBtn.MouseButton1Click:Connect(cloneAvatar)
RestoreBtn.MouseButton1Click:Connect(restoreAvatar)

-- Confirma enter no input
UsernameInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then cloneAvatar() end
end)

-- ══════════════════════════════════════════
--  ANIMAÇÃO DE ENTRADA
-- ══════════════════════════════════════════
MainFrame.BackgroundTransparency = 1
MainFrame.Size = UDim2.new(0,300,0,0)
local entryTween = tween(MainFrame, {
    BackgroundTransparency = 0,
    Size = UDim2.new(0,300,0,370)
}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
entryTween:Play()

-- ══════════════════════════════════════════
--  PRONTO
-- ══════════════════════════════════════════
setStatus("Pronto. Digite um username acima.", C.SUBTEXT)
addLog("Visual Cloner v2.0 carregado", C.ACCENT)
addLog("Rig atual: " .. getRigType(), C.SUBTEXT)
addLog("Chat 'papoi' para reabrir a GUI", C.SUBTEXT)
