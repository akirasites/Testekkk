-- ==========================================================
-- VISUAL CHANGER MOBILE
-- ULTIMATE R6 FIX
-- ==========================================================

local Players = game:GetService("Players")
local UserService = game:GetService("UserService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local ORANGE_COLOR = Color3.fromRGB(255, 115, 0)
local selectedPlayer = nil
local modifiedPlayers = {}
local applying = {}
local activeVisuals = {}

local guiParent
local coreSuccess = pcall(function() return CoreGui.Name end)
if coreSuccess then
    guiParent = CoreGui
else
    guiParent = LocalPlayer:WaitForChild("PlayerGui")
end

local function getCharacter(player)
    return player and player.Character
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function isR6(character)
    if not character then return false end
    return character:FindFirstChild("Head") ~= nil
        and character:FindFirstChild("Torso") ~= nil
        and character:FindFirstChild("Left Arm") ~= nil
        and character:FindFirstChild("Right Arm") ~= nil
        and character:FindFirstChild("Left Leg") ~= nil
        and character:FindFirstChild("Right Leg") ~= nil
end

local function safeClone(object)
    local success, clone = pcall(function() return object:Clone() end)
    return success and clone or nil
end

local function removeVisualObjects(character)
    if not character then return end
    for _, object in ipairs(character:GetChildren()) do
        if object:IsA("Accessory")
        or object:IsA("Shirt")
        or object:IsA("Pants")
        or object:IsA("ShirtGraphic")
        or object:IsA("BodyColors")
        or object:IsA("CharacterMesh") then
            pcall(function() object:Destroy() end)
        end
    end
end

local function clearHeadVisuals(head)
    if not head then return end
    for _, object in ipairs(head:GetChildren()) do
        if object:IsA("SpecialMesh")
        or object:IsA("Decal")
        or object:IsA("Texture") then
            pcall(function() object:Destroy() end)
        end
    end
end

local function setDisplayName(character, name)
    if not character then return end
    local humanoid = getHumanoid(character)
    if humanoid then
        pcall(function() humanoid.DisplayName = name end)
    end
    for _, object in ipairs(character:GetDescendants()) do
        if object:IsA("TextLabel") and object.Parent and object.Parent:IsA("BillboardGui") then
            pcall(function() object.Text = name end)
        end
    end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VisualChangerR6UltimateFix"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = guiParent

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 270, 0, 260)
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -130)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
MainFrame.BackgroundTransparency = 0.18
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = ORANGE_COLOR
FrameStroke.Thickness = 2
FrameStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -55, 0, 35)
Title.Position = UDim2.new(0, 12, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "Visual Changer R6"
Title.TextColor3 = ORANGE_COLOR
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 35, 0, 25)
HideBtn.Position = UDim2.new(1, -45, 0, 10)
HideBtn.BackgroundColor3 = ORANGE_COLOR
HideBtn.BackgroundTransparency = 0.15
HideBtn.Text = "X"
HideBtn.TextColor3 = Color3.new(1, 1, 1)
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 14
HideBtn.Parent = MainFrame
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 8)

local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Size = UDim2.new(0.9, 0, 0, 35)
DropdownBtn.Position = UDim2.new(0.05, 0, 0, 45)
DropdownBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
DropdownBtn.BackgroundTransparency = 0.2
DropdownBtn.TextColor3 = Color3.new(1, 1, 1)
DropdownBtn.Text = "Selecione o Alvo..."
DropdownBtn.Font = Enum.Font.GothamMedium
DropdownBtn.TextSize = 13
DropdownBtn.ZIndex = 5
DropdownBtn.Parent = MainFrame
Instance.new("UICorner", DropdownBtn).CornerRadius = UDim.new(0, 8)

local DropdownBackdrop = Instance.new("TextButton")
DropdownBackdrop.Size = UDim2.new(1, 0, 1, 0)
DropdownBackdrop.BackgroundTransparency = 1
DropdownBackdrop.Text = ""
DropdownBackdrop.Visible = false
DropdownBackdrop.ZIndex = 14
DropdownBackdrop.Parent = MainFrame

local DropdownScroll = Instance.new("ScrollingFrame")
DropdownScroll.Size = UDim2.new(0.9, 0, 0, 115)
DropdownScroll.Position = UDim2.new(0.05, 0, 0, 84)
DropdownScroll.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
DropdownScroll.BackgroundTransparency = 0.05
DropdownScroll.BorderSizePixel = 0
DropdownScroll.ScrollBarThickness = 4
DropdownScroll.ScrollBarImageColor3 = ORANGE_COLOR
DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
DropdownScroll.Visible = false
DropdownScroll.Active = true
DropdownScroll.ZIndex = 15
DropdownScroll.Parent = MainFrame
Instance.new("UICorner", DropdownScroll).CornerRadius = UDim.new(0, 8)

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = DropdownScroll

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 5)
ListPadding.PaddingBottom = UDim.new(0, 5)
ListPadding.PaddingLeft = UDim.new(0, 5)
ListPadding.PaddingRight = UDim.new(0, 5)
ListPadding.Parent = DropdownScroll

local UsernameInput = Instance.new("TextBox")
UsernameInput.Size = UDim2.new(0.9, 0, 0, 35)
UsernameInput.Position = UDim2.new(0.05, 0, 0, 95)
UsernameInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
UsernameInput.BackgroundTransparency = 0.2
UsernameInput.TextColor3 = Color3.new(1, 1, 1)
UsernameInput.PlaceholderText = "Username para copiar..."
UsernameInput.PlaceholderColor3 = Color3.fromRGB(145, 145, 145)
UsernameInput.Font = Enum.Font.Gotham
UsernameInput.TextSize = 13
UsernameInput.ClearTextOnFocus = false
UsernameInput.ZIndex = 2
UsernameInput.Parent = MainFrame
Instance.new("UICorner", UsernameInput).CornerRadius = UDim.new(0, 8)

local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size = UDim2.new(0.9, 0, 0, 40)
ApplyBtn.Position = UDim2.new(0.05, 0, 0, 145)
ApplyBtn.BackgroundColor3 = ORANGE_COLOR
ApplyBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
ApplyBtn.Text = "Aplicar Visual Completo"
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.TextSize = 14
ApplyBtn.ZIndex = 2
ApplyBtn.Parent = MainFrame
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 8)

local RestoreBtn = Instance.new("TextButton")
RestoreBtn.Size = UDim2.new(0.9, 0, 0, 40)
RestoreBtn.Position = UDim2.new(0.05, 0, 0, 195)
RestoreBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
RestoreBtn.BackgroundTransparency = 0.15
RestoreBtn.TextColor3 = Color3.new(1, 1, 1)
RestoreBtn.Text = "Restaurar Original"
RestoreBtn.Font = Enum.Font.GothamBold
RestoreBtn.TextSize = 13
RestoreBtn.ZIndex = 2
RestoreBtn.Parent = MainFrame
Instance.new("UICorner", RestoreBtn).CornerRadius = UDim.new(0, 8)

local function updateDropdown()
    for _, child in ipairs(DropdownScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local totalHeight = 10

    for _, player in ipairs(Players:GetPlayers()) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 30)
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        button.BackgroundTransparency = 0.15
        button.BorderSizePixel = 0
        button.Text = player.Name .. (player == LocalPlayer and " (Você)" or "")
        button.TextColor3 = Color3.new(1, 1, 1)
        button.Font = Enum.Font.GothamMedium
        button.TextSize = 12
        button.ZIndex = 16
        button.Parent = DropdownScroll
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

        button.Activated:Connect(function()
            selectedPlayer = player
            DropdownBtn.Text = "Alvo: " .. player.Name
            DropdownScroll.Visible = false
            DropdownBackdrop.Visible = false
        end)

        totalHeight += 34
    end

    DropdownScroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
end

Players.PlayerAdded:Connect(function()
    task.wait(0.2)
    updateDropdown()
end)

Players.PlayerRemoving:Connect(function(player)
    if selectedPlayer == player then
        selectedPlayer = nil
        DropdownBtn.Text = "Selecione o Alvo..."
    end
    updateDropdown()
end)

DropdownBtn.Activated:Connect(function()
    local visible = not DropdownScroll.Visible
    DropdownScroll.Visible = visible
    DropdownBackdrop.Visible = visible
    if visible then updateDropdown() end
end)

DropdownBackdrop.Activated:Connect(function()
    DropdownScroll.Visible = false
    DropdownBackdrop.Visible = false
end)

local function createBackup(player)
    if modifiedPlayers[player] then return end

    local character = getCharacter(player)
    local humanoid = getHumanoid(character)
    if not character or not humanoid then return end

    local backup = {
        OriginalName = humanoid.DisplayName,
        Items = {},
        Parts = {},
        HeadItems = {},
        HeadTransparency = 0,
        HeadColor = Color3.new(1, 1, 1)
    }

    for _, object in ipairs(character:GetChildren()) do
        if object:IsA("Accessory")
        or object:IsA("Shirt")
        or object:IsA("Pants")
        or object:IsA("ShirtGraphic")
        or object:IsA("BodyColors")
        or object:IsA("CharacterMesh") then
            local clone = safeClone(object)
            if clone then table.insert(backup.Items, clone) end
        end
    end

    for _, object in ipairs(character:GetChildren()) do
        if object:IsA("BasePart") then
            backup.Parts[object.Name] = {
                Color = object.Color,
                Transparency = object.Transparency,
                Material = object.Material
            }

            local mesh = object:FindFirstChildOfClass("SpecialMesh")
            if mesh then
                backup.Parts[object.Name].Mesh = safeClone(mesh)
            end
        end
    end

    local head = character:FindFirstChild("Head")
    if head then
        backup.HeadTransparency = head.Transparency
        backup.HeadColor = head.Color

        for _, object in ipairs(head:GetChildren()) do
            if object:IsA("SpecialMesh")
            or object:IsA("Decal")
            or object:IsA("Texture") then
                local clone = safeClone(object)
                if clone then table.insert(backup.HeadItems, clone) end
            end
        end
    end

    modifiedPlayers[player] = backup
end

local function copySpecialMesh(sourcePart, targetPart)
    if not sourcePart or not targetPart then return end

    for _, object in ipairs(targetPart:GetChildren()) do
        if object:IsA("SpecialMesh") then object:Destroy() end
    end

    local sourceMesh = sourcePart:FindFirstChildOfClass("SpecialMesh")

    if sourceMesh then
        local mesh = safeClone(sourceMesh)
        if mesh then mesh.Parent = targetPart end
        return
    end

    if sourcePart:IsA("MeshPart") then
        local meshId = sourcePart.MeshId
        local textureId = sourcePart.TextureID

        if meshId and meshId ~= "" then
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.FileMesh
            mesh.MeshId = meshId

            if textureId then
                mesh.TextureId = textureId
            end

            local targetSize = targetPart.Size
            local sourceSize = sourcePart.Size

            if targetSize.X ~= 0 and targetSize.Y ~= 0 and targetSize.Z ~= 0 then
                mesh.Scale = Vector3.new(
                    sourceSize.X / targetSize.X,
                    sourceSize.Y / targetSize.Y,
                    sourceSize.Z / targetSize.Z
                )
            end

            mesh.Parent = targetPart
        end
    end
end

local function copyBodyPart(sourcePart, targetPart)
    if not sourcePart or not targetPart then return end
    if not sourcePart:IsA("BasePart") or not targetPart:IsA("BasePart") then return end

    pcall(function() targetPart.Color = sourcePart.Color end)
    pcall(function() targetPart.Transparency = sourcePart.Transparency end)
    pcall(function() targetPart.Material = sourcePart.Material end)

    copySpecialMesh(sourcePart, targetPart)
end

local function copyHead(sourceHead, targetHead)
    if not sourceHead or not targetHead then return end

    clearHeadVisuals(targetHead)

    pcall(function() targetHead.Color = sourceHead.Color end)
    pcall(function() targetHead.Transparency = sourceHead.Transparency end)

    local sourceMesh = sourceHead:FindFirstChildOfClass("SpecialMesh")

    if sourceMesh then
        local mesh = safeClone(sourceMesh)
        if mesh then mesh.Parent = targetHead end
    end

    for _, object in ipairs(sourceHead:GetChildren()) do
        if object:IsA("Decal") or object:IsA("Texture") then
            local clone = safeClone(object)
            if clone then clone.Parent = targetHead end
        end
    end

    if sourceHead.Transparency >= 0.95 then
        targetHead.Transparency = 1
        for _, object in ipairs(targetHead:GetChildren()) do
            if object:IsA("Decal") then
                object.Transparency = 1
            end
        end
    end
end

local function prepareAccessory(accessory)
    if not accessory then return end

    local handle = accessory:FindFirstChild("Handle")
    if not handle then return end

    if handle:IsA("BasePart") then
        pcall(function() handle.CanCollide = false end)
        pcall(function() handle.CanTouch = false end)
        pcall(function() handle.CanQuery = false end)
        pcall(function() handle.Massless = true end)
        pcall(function() handle.Anchored = false end)
    end
end

local function attachAccessoryR6(humanoid, accessory)
    if not humanoid or not accessory then return false end

    prepareAccessory(accessory)

    local success = pcall(function()
        humanoid:AddAccessory(accessory)
    end)

    if success then return true end

    local character = humanoid.Parent
    if not character then return false end

    local handle = accessory:FindFirstChild("Handle")
    if not handle then return false end

    local accessoryAttachment = handle:FindFirstChildOfClass("Attachment")

    if accessoryAttachment then
        local targetAttachment = character:FindFirstChild(accessoryAttachment.Name, true)

        if targetAttachment
        and targetAttachment:IsA("Attachment")
        and targetAttachment.Parent:IsA("BasePart") then

            accessory.Parent = character

            handle.CFrame =
                targetAttachment.WorldCFrame *
                accessoryAttachment.CFrame:Inverse()

            local weld = Instance.new("WeldConstraint")
            weld.Part0 = handle
            weld.Part1 = targetAttachment.Parent
            weld.Parent = handle

            return true
        end
    end

    local head = character:FindFirstChild("Head")

    if head then
        accessory.Parent = character
        handle.CFrame = head.CFrame

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = handle
        weld.Part1 = head
        weld.Parent = handle

        return true
    end

    return false
end

local function applyR6Source(sourceModel, targetCharacter)
    if not sourceModel or not targetCharacter then return false end

    local targetHumanoid = getHumanoid(targetCharacter)
    if not targetHumanoid then return false end

    removeVisualObjects(targetCharacter)

    local targetHead = targetCharacter:FindFirstChild("Head")

    if targetHead then
        clearHeadVisuals(targetHead)
        targetHead.Transparency = 0
    end

    for _, object in ipairs(sourceModel:GetChildren()) do
        if object:IsA("Shirt")
        or object:IsA("Pants")
        or object:IsA("ShirtGraphic")
        or object:IsA("BodyColors")
        or object:IsA("CharacterMesh") then

            local clone = safeClone(object)
            if clone then clone.Parent = targetCharacter end
        end
    end

    local sourceHead = sourceModel:FindFirstChild("Head")

    if sourceHead and targetHead then
        copyHead(sourceHead, targetHead)
    end

    for _, partName in ipairs({
        "Torso",
        "Left Arm",
        "Right Arm",
        "Left Leg",
        "Right Leg"
    }) do
        local sourcePart = sourceModel:FindFirstChild(partName)
        local targetPart = targetCharacter:FindFirstChild(partName)

        if sourcePart and targetPart then
            copyBodyPart(sourcePart, targetPart)
        end
    end

    for _, object in ipairs(sourceModel:GetChildren()) do
        if object:IsA("Accessory") then
            local clone = safeClone(object)
            if clone then
                attachAccessoryR6(targetHumanoid, clone)
            end
        end
    end

    return true
end

local function createR6Avatar(userId)
    local descriptionSuccess, description = pcall(function()
        return Players:GetHumanoidDescriptionFromUserId(userId)
    end)

    if not descriptionSuccess or not description then
        return nil, "HumanoidDescription falhou"
    end

    local modelSuccess, model = pcall(function()
        return Players:CreateHumanoidModelFromDescription(
            description,
            Enum.HumanoidRigType.R6
        )
    end)

    if not modelSuccess or not model then
        return nil, "Criação do modelo R6 falhou"
    end

    return model
end

local function getDisplayName(userId, fallback)
    local success, information = pcall(function()
        return UserService:GetUserInfosByUserIdsAsync({userId})
    end)

    if success
    and information
    and information[1]
    and information[1].DisplayName then
        return information[1].DisplayName
    end

    return fallback
end

local function processCloning()
    if applying[selectedPlayer] then return end

    if not selectedPlayer then
        ApplyBtn.Text = "Selecione um alvo!"
        task.wait(1.5)
        ApplyBtn.Text = "Aplicar Visual Completo"
        return
    end

    local targetCharacter = getCharacter(selectedPlayer)
    local targetHumanoid = getHumanoid(targetCharacter)

    if not targetCharacter or not targetHumanoid then
        ApplyBtn.Text = "Alvo sem personagem!"
        task.wait(1.5)
        ApplyBtn.Text = "Aplicar Visual Completo"
        return
    end

    if not isR6(targetCharacter) then
        ApplyBtn.Text = "Alvo precisa ser R6!"
        task.wait(1.5)
        ApplyBtn.Text = "Aplicar Visual Completo"
        return
    end

    local username = UsernameInput.Text
    if username == "" then username = selectedPlayer.Name end

    applying[selectedPlayer] = true

    ApplyBtn.Text = "Obtendo usuário..."

    local idSuccess, userId = pcall(function()
        return Players:GetUserIdFromNameAsync(username)
    end)

    if not idSuccess or not userId then
        applying[selectedPlayer] = nil
        ApplyBtn.Text = "Usuário inválido!"
        task.wait(1.5)
        ApplyBtn.Text = "Aplicar Visual Completo"
        return
    end

    createBackup(selectedPlayer)

    ApplyBtn.Text = "Convertendo para R6..."

    local sourceModel, errorMessage = createR6Avatar(userId)

    if not sourceModel then
        applying[selectedPlayer] = nil
        ApplyBtn.Text = "Erro R6!"
        warn("[VisualChanger]", errorMessage)
        task.wait(1.5)
        ApplyBtn.Text = "Aplicar Visual Completo"
        return
    end

    sourceModel.Parent = workspace

    pcall(function()
        sourceModel:PivotTo(CFrame.new(0, -10000, 0))
    end)

    ApplyBtn.Text = "Aplicando aparência..."

    local applySuccess, applyError = pcall(function()
        local result = applyR6Source(sourceModel, targetCharacter)
        if not result then
            error("Falha ao copiar modelo R6")
        end
    end)

    pcall(function()
        sourceModel:Destroy()
    end)

    if not applySuccess then
        applying[selectedPlayer] = nil
        ApplyBtn.Text = "Erro ao aplicar!"
        warn("[VisualChanger]", applyError)
        task.wait(1.5)
        ApplyBtn.Text = "Aplicar Visual Completo"
        return
    end

    local displayName = getDisplayName(userId, username)
    setDisplayName(targetCharacter, displayName)

    activeVisuals[selectedPlayer] = {
        UserId = userId,
        DisplayName = displayName
    }

    applying[selectedPlayer] = nil

    ApplyBtn.Text = "Sucesso ✓"
    task.wait(1.5)
    ApplyBtn.Text = "Aplicar Visual Completo"
end

local function restoreVisuals()
    if not selectedPlayer then return end

    local backup = modifiedPlayers[selectedPlayer]
    if not backup then return end

    activeVisuals[selectedPlayer] = nil

    local character = getCharacter(selectedPlayer)
    local humanoid = getHumanoid(character)

    if not character or not humanoid then return end

    removeVisualObjects(character)

    local head = character:FindFirstChild("Head")

    if head then
        clearHeadVisuals(head)
        head.Transparency = 0
    end

    for _, object in ipairs(backup.Items) do
        local clone = safeClone(object)

        if clone then
            if clone:IsA("Accessory") then
                attachAccessoryR6(humanoid, clone)
            else
                clone.Parent = character
            end
        end
    end

    for partName, data in pairs(backup.Parts) do
        local part = character:FindFirstChild(partName)

        if part and part:IsA("BasePart") then
            pcall(function() part.Color = data.Color end)
            pcall(function() part.Transparency = data.Transparency end)
            pcall(function() part.Material = data.Material end)

            for _, object in ipairs(part:GetChildren()) do
                if object:IsA("SpecialMesh") then
                    object:Destroy()
                end
            end

            if data.Mesh then
                local mesh = safeClone(data.Mesh)
                if mesh then mesh.Parent = part end
            end
        end
    end

    if head then
        head.Transparency = backup.HeadTransparency
        head.Color = backup.HeadColor

        for _, object in ipairs(backup.HeadItems) do
            local clone = safeClone(object)
            if clone then clone.Parent = head end
        end
    end

    setDisplayName(character, backup.OriginalName)
    modifiedPlayers[selectedPlayer] = nil

    RestoreBtn.Text = "Restaurado ✓"
    task.wait(1.5)
    RestoreBtn.Text = "Restaurar Original"
end

local function setupRespawnHandler(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(1)

        local data = activeVisuals[player]
        if not data then return end
        if not isR6(character) then return end

        local humanoid = getHumanoid(character)
        if not humanoid then return end

        task.spawn(function()
            local sourceModel = createR6Avatar(data.UserId)
            if not sourceModel then return end

            sourceModel.Parent = workspace

            pcall(function()
                sourceModel:PivotTo(CFrame.new(0, -10000, 0))
            end)

            pcall(function()
                applyR6Source(sourceModel, character)
            end)

            pcall(function()
                sourceModel:Destroy()
            end)

            setDisplayName(character, data.DisplayName)
        end)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupRespawnHandler(player)
end

Players.PlayerAdded:Connect(function(player)
    setupRespawnHandler(player)
end)

ApplyBtn.Activated:Connect(function()
    task.spawn(processCloning)
end)

RestoreBtn.Activated:Connect(function()
    task.spawn(restoreVisuals)
end)

HideBtn.Activated:Connect(function()
    ScreenGui.Enabled = false
end)

LocalPlayer.Chatted:Connect(function(message)
    if string.lower(string.gsub(message, "^%s*(.-)%s*$", "%1")) == "papoi" then
        ScreenGui.Enabled = true
        updateDropdown()
    end
end)

updateDropdown()
