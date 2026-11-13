-- ==========================================
-- HUB: xcs (Neon Glass v2.3 - Delta Safe Mode)
-- ==========================================

print("[xcs] 1/6: Inicializando servicios...")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- 🎨 PALETA NEON GLASS
local THEME = {
    BgMain      = Color3.fromRGB(13, 17, 26),
    BgHeader    = Color3.fromRGB(18, 24, 36),
    BgCard      = Color3.fromRGB(22, 29, 43),
    BgCardOn    = Color3.fromRGB(16, 48, 38),
    AccentCyan  = Color3.fromRGB(0, 210, 255),
    AccentGreen = Color3.fromRGB(0, 220, 120),
    AccentRed   = Color3.fromRGB(235, 65, 85),
    AccentAmber = Color3.fromRGB(240, 150, 30),
    SwitchOff   = Color3.fromRGB(45, 55, 72),
    TextMain    = Color3.fromRGB(240, 245, 255),
    TextMuted   = Color3.fromRGB(145, 160, 185),
}

local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

print("[xcs] 2/6: Desactivando File System para evitar crasheos...")
-- Memoria temporal (Se borra al salir para evitar el cuelgue de writefile)
local memoryStorage = {}

local function saveData(name, data)
    memoryStorage[name] = tostring(data)
end

local function loadData(name, default)
    return memoryStorage[name] or default
end

local function savePosition(name, pos)
    saveData(name, string.format("%.2f,%.2f", pos.X.Offset, pos.Y.Offset))
end

local function loadPosition(name, defaultUDim2)
    local content = loadData(name, nil)
    if content then
        local args = string.split(content, ",")
        if #args == 2 then return UDim2.new(0, tonumber(args[1]), 0, tonumber(args[2])) end
    end
    return defaultUDim2
end

local function saveButtonState(name, state) saveData("Btn_"..name, tostring(state)) end
local function loadButtonState(name) return loadData("Btn_"..name, "true") == "true" end

-- Variables de estado
local tpEnabled, invisicamEnabled, fpXRayEnabled, noclipEnabled = false, false, false, false
local flyEnabled, freeCamEnabled, fullbrightEnabled, deleteModeEnabled = false, false, false, false
local espEnabled, infJumpEnabled, thirdPersonEnabled, antiAfkEnabled = false, false, false, false
local quickButtonsMaster, hubUnloaded = true, false

local flySpeed, freeCamSpeed = 50, 50
local turboMultiplier = 2
local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local allConnections, cachedCharParts, transparentParts, deletedPartsMemory = {}, {}, {}, {}
local espHighlights, espCharConnections, playerDistanceLabels = {}, {}, {}
local noclipConnection, flyConnection, freeCamConnection, freeCamRotateConnection = nil, nil, nil, nil
local invisicamConnection, thirdPersonConnection, antiAfkConnection, fpXRayConnection = nil, nil, nil, nil
local flyAttachment, flyLinearVel, flyAlignOri = nil, nil, nil
local camYaw, camPitch, camPos = 0, 0, Vector3.zero
local savedLighting, QuickButtons, QuickButtonStrokes = {}, {}, {}
local filterQuery, spectatingPlayer, listeningFor = "", nil, nil

local function trackConn(conn) table.insert(allConnections, conn); return conn end

local function applyNeonStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or THEME.AccentCyan
    stroke.Transparency = transparency or 0.45
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

print("[xcs] 3/6: Inyectando Interfaz en PlayerGui...")
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xcsHub_SafeMode"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- Inyección directa hiper-segura
local successInject = pcall(function()
    local guiParent = LocalPlayer:FindFirstChild("PlayerGui")
    if not guiParent then guiParent = LocalPlayer:WaitForChild("PlayerGui", 5) end
    ScreenGui.Parent = guiParent
end)
if not successInject then print("ERROR: No se pudo inyectar en PlayerGui.") return end

-- Botones flotantes base
local MiniBtn = Instance.new("TextButton")
MiniBtn.Size, MiniBtn.Position = UDim2.new(0, 44, 0, 44), UDim2.new(0, 15, 0, 200)
MiniBtn.BackgroundColor3, MiniBtn.BackgroundTransparency = THEME.BgMain, 0.15
MiniBtn.Text, MiniBtn.TextColor3, MiniBtn.Font = "xcs", THEME.AccentCyan, Enum.Font.GothamBold
MiniBtn.Parent = ScreenGui
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)
applyNeonStroke(MiniBtn, THEME.AccentCyan, 0.2, 1.5)

local MiniTpBtn = MiniBtn:Clone()
MiniTpBtn.Position, MiniTpBtn.Text, MiniTpBtn.Visible = UDim2.new(0, 68, 0, 200), "TP", false
MiniTpBtn.Parent = ScreenGui

print("[xcs] 4/6: Construyendo Paneles...")
-- Ventana Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size, MainFrame.Position = UDim2.new(0, 215, 0, 360), UDim2.new(0, 20, 0, 90)
MainFrame.BackgroundColor3, MainFrame.BackgroundTransparency = THEME.BgMain, 0.12
MainFrame.BorderSizePixel, MainFrame.Visible = 0, false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
applyNeonStroke(MainFrame, THEME.AccentCyan, 0.35, 1.3)

local Title = Instance.new("TextButton")
Title.Size, Title.BackgroundColor3, Title.BackgroundTransparency = UDim2.new(1, 0, 0, 30), THEME.BgHeader, 0.15
Title.Text, Title.TextColor3, Title.Font, Title.TextSize = "  ◈ xcs Hub", THEME.TextMain, Enum.Font.GothamBold, 11
Title.TextXAlignment, Title.AutoButtonColor, Title.Parent = Enum.TextXAlignment.Left, false, MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

local function createHeaderBtn(text, offsetX, bgColor, textColor, parent)
    local btn = Instance.new("TextButton")
    btn.Size, btn.Position = UDim2.new(0, 20, 0, 20), UDim2.new(1, offsetX, 0.5, -10)
    btn.BackgroundColor3, btn.BackgroundTransparency = bgColor, 0.2
    btn.Text, btn.TextColor3, btn.Font, btn.TextSize = text, textColor, Enum.Font.GothamBold, 10
    btn.Parent = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    applyNeonStroke(btn, bgColor, 0.4, 1)
    return btn
end

local PlayerWindowToggleBtn = createHeaderBtn("TP", -74, THEME.AccentCyan, THEME.BgMain, Title)
local SettingsBtn = createHeaderBtn("⚙️", -50, THEME.BgCard, THEME.TextMain, Title)
local MinimizeBtn = createHeaderBtn("✕", -26, THEME.AccentRed, THEME.TextMain, Title)

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Size, MainScroll.Position = UDim2.new(1, 0, 1, -32), UDim2.new(0, 0, 0, 32)
MainScroll.BackgroundTransparency, MainScroll.BorderSizePixel, MainScroll.ScrollBarThickness = 1, 0, 2
MainScroll.ScrollBarImageColor3, MainScroll.AutomaticCanvasSize = THEME.AccentCyan, Enum.AutomaticSize.Y
MainScroll.Parent = MainFrame
local MainList = Instance.new("UIListLayout", MainScroll); MainList.Padding, MainList.SortOrder = UDim.new(0, 5), Enum.SortOrder.LayoutOrder
local MainPad = Instance.new("UIPadding", MainScroll); MainPad.PaddingTop, MainPad.PaddingLeft, MainPad.PaddingRight = UDim.new(0, 6), UDim.new(0, 8), UDim.new(0, 8)

-- Helper Switches
local function createNeonSwitch(parent, icon, text)
    local card = Instance.new("Frame", parent)
    card.Size, card.BackgroundColor3, card.BackgroundTransparency = UDim2.new(1, 0, 0, 28), THEME.BgCard, 0.25
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = applyNeonStroke(card, THEME.AccentCyan, 0.78, 1)

    local lbl = Instance.new("TextLabel", card)
    lbl.Size, lbl.Position, lbl.BackgroundTransparency = UDim2.new(0.74, 0, 1, 0), UDim2.new(0, 9, 0, 0), 1
    lbl.Text, lbl.TextColor3, lbl.Font, lbl.TextSize, lbl.TextXAlignment = (icon ~= "" and (icon.."  ") or "")..text, THEME.TextMain, Enum.Font.GothamMedium, 10, Enum.TextXAlignment.Left

    local bg = Instance.new("TextButton", card)
    bg.Size, bg.Position, bg.BackgroundColor3, bg.Text = UDim2.new(0, 32, 0, 16), UDim2.new(1, -40, 0.5, -8), THEME.SwitchOff, ""
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)
    local knob = Instance.new("Frame", bg)
    knob.Size, knob.Position, knob.BackgroundColor3 = UDim2.new(0, 12, 0, 12), UDim2.new(0, 2, 0.5, -6), Color3.new(1,1,1)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    return bg, knob, card, stroke
end

local function setSwitchVisual(state, bg, knob, card, stroke)
    TweenService:Create(bg, TWEEN_FAST, {BackgroundColor3 = state and THEME.AccentGreen or THEME.SwitchOff}):Play()
    TweenService:Create(knob, TWEEN_FAST, {Position = state and UDim2.new(0, 18, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)}):Play()
    if card then TweenService:Create(card, TWEEN_FAST, {BackgroundColor3 = state and THEME.BgCardOn or THEME.BgCard}):Play() end
    if stroke then TweenService:Create(stroke, TWEEN_FAST, {Color = state and THEME.AccentGreen or THEME.AccentCyan, Transparency = state and 0.35 or 0.78}):Play() end
end

local TPSwitchBg, TPSwitchKnob, TPSwitchCard = createNeonSwitch(MainScroll, "📍", "TPS (Toque)")
local SwitchBg, SwitchKnob, SwitchCard = createNeonSwitch(MainScroll, "👁️", "Invisicam")
local ESPSwitchBg, ESPSwitchKnob, ESPCard = createNeonSwitch(MainScroll, "🎯", "ESP Jugadores")
local DeleteSwitchBg, DeleteSwitchKnob, DeleteCard = createNeonSwitch(MainScroll, "🗑️", "Borrador Paredes")

local DeleteActionsRow = Instance.new("Frame", MainScroll)
DeleteActionsRow.Size, DeleteActionsRow.BackgroundTransparency = UDim2.new(1, 0, 0, 24), 1

local UndoLastBtn = Instance.new("TextButton", DeleteActionsRow)
UndoLastBtn.Size, UndoLastBtn.BackgroundColor3, UndoLastBtn.BackgroundTransparency = UDim2.new(0.56, -2, 1, 0), THEME.BgCard, 0.2
UndoLastBtn.Text, UndoLastBtn.TextColor3, UndoLastBtn.Font, UndoLastBtn.TextSize = "↩️ Undo (0)", THEME.AccentCyan, Enum.Font.GothamBold, 9
Instance.new("UICorner", UndoLastBtn).CornerRadius = UDim.new(0, 6)
applyNeonStroke(UndoLastBtn, THEME.AccentCyan, 0.55, 1)

local RestoreAllBtn = Instance.new("TextButton", DeleteActionsRow)
RestoreAllBtn.Size, RestoreAllBtn.Position, RestoreAllBtn.BackgroundColor3, RestoreAllBtn.BackgroundTransparency = UDim2.new(0.44, -2, 1, 0), UDim2.new(0.56, 2, 0, 0), THEME.BgCard, 0.2
RestoreAllBtn.Text, RestoreAllBtn.TextColor3, RestoreAllBtn.Font, RestoreAllBtn.TextSize = "🧱 Todo", THEME.AccentRed, Enum.Font.GothamBold, 9
Instance.new("UICorner", RestoreAllBtn).CornerRadius = UDim.new(0, 6)
applyNeonStroke(RestoreAllBtn, THEME.AccentRed, 0.55, 1)

local FlySwitchBg, FlySwitchKnob, FlyCard = createNeonSwitch(MainScroll, "🕊️", "Fly")
local FullbrightSwitchBg, FullbrightSwitchKnob, FullbrightCard = createNeonSwitch(MainScroll, "☀️", "Fullbright")
local AntiAfkSwitchBg, AntiAfkSwitchKnob, AntiAfkCard = createNeonSwitch(MainScroll, "🛡️", "Anti-AFK")

if not isTouchDevice then TPSwitchCard.Visible = false end

print("[xcs] 5/6: Generando Lógica Principal...")

-- Anti-AFK
AntiAfkSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        antiAfkEnabled = not antiAfkEnabled
        setSwitchVisual(antiAfkEnabled, AntiAfkSwitchBg, AntiAfkSwitchKnob, AntiAfkCard)
        if antiAfkEnabled then
            if antiAfkConnection then antiAfkConnection:Disconnect() end
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
            end)
        else
            if antiAfkConnection then antiAfkConnection:Disconnect(); antiAfkConnection = nil end
        end
    end
end)

-- Borrador y Undo
local function updateDeleteCounter() UndoLastBtn.Text = "↩️ Undo (" .. #deletedPartsMemory .. ")" end

DeleteSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        deleteModeEnabled = not deleteModeEnabled
        setSwitchVisual(deleteModeEnabled, DeleteSwitchBg, DeleteSwitchKnob, DeleteCard)
    end
end)

UndoLastBtn.MouseButton1Click:Connect(function()
    while #deletedPartsMemory > 0 do
        local lastData = table.remove(deletedPartsMemory)
        if lastData and lastData.part and lastData.part.Parent then
            lastData.part.Transparency, lastData.part.CanCollide = lastData.trans, lastData.collide
            break
        end
    end
    updateDeleteCounter()
end)

RestoreAllBtn.MouseButton1Click:Connect(function()
    for _, data in ipairs(deletedPartsMemory) do
        if data.part and data.part.Parent then data.part.Transparency, data.part.CanCollide = data.trans, data.collide end
    end
    deletedPartsMemory = {}
    updateDeleteCounter()
end)

local function raycastIgnoringDeleted(origin, direction)
    local filter = {LocalPlayer.Character, Camera}
    for _, data in ipairs(deletedPartsMemory) do if data.part and data.part.Parent then table.insert(filter, data.part) end end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances, params.FilterType = filter, Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(origin, direction, params)
end

-- Fly Básico
FlySwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        flyEnabled = not flyEnabled
        setSwitchVisual(flyEnabled, FlySwitchBg, FlySwitchKnob, FlyCard)
        if flyEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                flyAttachment = Instance.new("Attachment", hrp)
                flyLinearVel = Instance.new("LinearVelocity", hrp)
                flyLinearVel.Attachment0, flyLinearVel.VelocityConstraintMode, flyLinearVel.MaxForce = flyAttachment, Enum.VelocityConstraintMode.Vector, math.huge
                
                flyAlignOri = Instance.new("AlignOrientation", hrp)
                flyAlignOri.Attachment0, flyAlignOri.Mode, flyAlignOri.RigidityEnabled, flyAlignOri.CFrame = flyAttachment, Enum.OrientationAlignmentMode.OneAttachment, true, hrp.CFrame
                
                flyConnection = RunService.RenderStepped:Connect(function()
                    if not flyEnabled or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") then return end
                    local moveDir = Camera.CFrame:VectorToObjectSpace(LocalPlayer.Character.Humanoid.MoveDirection)
                    local worldMove = (Camera.CFrame * CFrame.new(moveDir.X, 0, moveDir.Z)).Position - Camera.CFrame.Position
                    flyLinearVel.VectorVelocity = worldMove.Magnitude > 0 and (worldMove.Unit * flySpeed) or Vector3.zero
                    flyAlignOri.CFrame = Camera.CFrame
                end)
            end
        else
            if flyConnection then flyConnection:Disconnect() end
            if flyLinearVel then flyLinearVel:Destroy() end
            if flyAlignOri then flyAlignOri:Destroy() end
            if flyAttachment then flyAttachment:Destroy() end
        end
    end
end)

-- UI Interaction Global
local function isOverGui(pos)
    for _, obj in ipairs(LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)) do
        if obj:IsDescendantOf(ScreenGui) then return true end
    end
    return false
end

trackConn(UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not isOverGui(input.Position) then
            if deleteModeEnabled then
                local ray = Camera:ScreenPointToRay(input.Position.X, input.Position.Y)
                local res = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
                if res and res.Instance and res.Instance:IsA("BasePart") then
                    table.insert(deletedPartsMemory, {part = res.Instance, trans = res.Instance.Transparency, collide = res.Instance.CanCollide})
                    res.Instance.Transparency, res.Instance.CanCollide = 1, false
                    updateDeleteCounter()
                end
            elseif tpEnabled then
                local ray = Camera:ScreenPointToRay(input.Position.X, input.Position.Y)
                local res = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
                if res and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(res.Position + Vector3.new(0,3,0))
                end
            end
        end
    end
end))

-- Ventana Settings / Server
local SettingsFrame = Instance.new("Frame", ScreenGui)
SettingsFrame.Size, SettingsFrame.Position = UDim2.new(0, 220, 0, 150), UDim2.new(0, 245, 0, 90)
SettingsFrame.BackgroundColor3, SettingsFrame.BackgroundTransparency, SettingsFrame.Visible = THEME.BgMain, 0.1, false
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 12)
applyNeonStroke(SettingsFrame, THEME.AccentCyan, 0.35, 1.3)

local SettingsTitle = Instance.new("TextButton", SettingsFrame)
SettingsTitle.Size, SettingsTitle.BackgroundColor3, SettingsTitle.BackgroundTransparency = UDim2.new(1, 0, 0, 28), THEME.BgHeader, 0.15
SettingsTitle.Text, SettingsTitle.TextColor3, SettingsTitle.Font, SettingsTitle.TextSize, SettingsTitle.TextXAlignment = "  SISTEMA", THEME.AccentCyan, Enum.Font.GothamBold, 11, Enum.TextXAlignment.Left
Instance.new("UICorner", SettingsTitle).CornerRadius = UDim.new(0, 12)

local CloseSettingsBtn = createHeaderBtn("✕", -25, THEME.AccentRed, THEME.TextMain, SettingsTitle)
CloseSettingsBtn.MouseButton1Click:Connect(function() SettingsFrame.Visible = false end)
SettingsBtn.Activated:Connect(function() SettingsFrame.Visible = not SettingsFrame.Visible end)

local ServerRow = Instance.new("Frame", SettingsFrame)
ServerRow.Size, ServerRow.Position, ServerRow.BackgroundTransparency = UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 40), 1

local RejoinBtn = Instance.new("TextButton", ServerRow)
RejoinBtn.Size, RejoinBtn.BackgroundColor3 = UDim2.new(0.48, -2, 1, 0), THEME.BgCard
RejoinBtn.Text, RejoinBtn.TextColor3, RejoinBtn.Font, RejoinBtn.TextSize = "🔄 Rejoin", THEME.AccentCyan, Enum.Font.GothamBold, 9
Instance.new("UICorner", RejoinBtn).CornerRadius = UDim.new(0, 6)
applyNeonStroke(RejoinBtn, THEME.AccentCyan, 0.45, 1)

local UnloadBtn = Instance.new("TextButton", SettingsFrame)
UnloadBtn.Size, UnloadBtn.Position, UnloadBtn.BackgroundColor3 = UDim2.new(1, -16, 0, 26), UDim2.new(0, 8, 0, 80), THEME.AccentRed
UnloadBtn.Text, UnloadBtn.TextColor3, UnloadBtn.Font, UnloadBtn.TextSize = "🛑 Cerrar (Unload)", THEME.TextMain, Enum.Font.GothamBold, 9
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 6)

RejoinBtn.MouseButton1Click:Connect(function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) end)

UnloadBtn.MouseButton1Click:Connect(function()
    hubUnloaded = true
    for _, data in ipairs(deletedPartsMemory) do
        if data.part and data.part.Parent then data.part.Transparency, data.part.CanCollide = data.trans, data.collide end
    end
    for _, conn in ipairs(allConnections) do pcall(function() conn:Disconnect() end) end
    if ScreenGui then ScreenGui:Destroy() end
end)

-- Dragging Simple
local function makeDraggable(handle, frame)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(0, startPos.X.Offset + delta.X, 0, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end
makeDraggable(Title, MainFrame)
makeDraggable(MiniBtn, MiniBtn)
makeDraggable(SettingsTitle, SettingsFrame)

MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniBtn.Visible = true end)
MiniBtn.Activated:Connect(function() MainFrame.Visible = true; MiniBtn.Visible = false end)

print("[xcs] 6/6: CARGA FINALIZADA CON ÉXITO. Verifica tu pantalla.")
