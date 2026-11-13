-- ==========================================
-- HUB: xcs (Neon Glass v2.2 - Optimizado + Anti-Rubberband Seguro)
-- ==========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")

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

-- 🛡️ MÓDULO DE SIGILO (STEALTH)
local Stealth = {}
function Stealth.HideConnections(connection)
    if not connection then return connection end
    pcall(function()
        if setmetatable then
            local oldmt = getmetatable(connection)
            if oldmt then
                setmetatable(connection, {
                    __index = function(t, k)
                        if k == "Disconnect" then return function() end end
                        return oldmt.__index[k]
                    end
                })
            end
        end
    end)
    return connection
end

function Stealth.HideInstance(instance)
    if not instance then return end
    pcall(function() instance.Name = "CoreUI_" .. math.random(1000, 9999) end)
end

-- Guardado y Carga
local function saveData(name, data)
    pcall(function()
        if writefile then writefile("xcs_" .. name .. ".txt", tostring(data)) end
    end)
end

local function loadData(name, default)
    local success, content = pcall(function()
        if isfile and readfile and isfile("xcs_" .. name .. ".txt") then
            return readfile("xcs_" .. name .. ".txt")
        end
    end)
    if success and content then return content end
    return default
end

local function savePosition(name, pos)
    saveData(name, string.format("%.2f,%.2f", pos.X.Offset, pos.Y.Offset))
end

local function loadPosition(name, defaultUDim2)
    local content = loadData(name, nil)
    if content then
        local args = string.split(content, ",")
        if #args == 2 then
            local xO, yO = tonumber(args[1]), tonumber(args[2])
            if xO and yO then return UDim2.new(0, xO, 0, yO) end
        end
    end
    return defaultUDim2
end

local function saveButtonState(btnName, state)
    saveData("BtnState_" .. btnName, tostring(state))
end

local function loadButtonState(btnName)
    return loadData("BtnState_" .. btnName, "true") == "true"
end

local function saveKeybind(keyName, keyCode)
    saveData("Key_" .. keyName, keyCode.Name)
end

local function loadKeybind(keyName, defaultCode)
    local saved = loadData("Key_" .. keyName, nil)
    if saved then
        local ok, code = pcall(function() return Enum.KeyCode[saved] end)
        if ok and code then return code end
    end
    return defaultCode
end

-- Variables de estado
local tpEnabled = false
local invisicamEnabled = false
local fpXRayEnabled = false
local noclipEnabled = false
local flyEnabled = false
local freeCamEnabled = false
local fullbrightEnabled = false
local deleteModeEnabled = false
local espEnabled = false
local infJumpEnabled = false
local thirdPersonEnabled = false
local quickButtonsMaster = true
local hubUnloaded = false

local flySpeed = tonumber(loadData("FlySpeed", 50)) or 50
local freeCamSpeed = tonumber(loadData("FreeCamSpeed", 50)) or 50
local turboMultiplier = 2

local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- Conexiones y Cachés
local allConnections = {}
local noclipConnection = nil
local cachedCharParts = {}
local flyConnection = nil
local flyAttachment = nil
local flyLinearVel = nil
local flyAlignOri = nil
local fpXRayConnection = nil
local invisicamConnection = nil
local thirdPersonConnection = nil
local transparentParts = {}
local deletedPartsMemory = {}
local espHighlights = {}
local espCharConnections = {}

local freeCamConnection = nil
local freeCamRotateConnection = nil
local camYaw, camPitch = 0, 0
local camPos = Vector3.new(0, 0, 0)

local savedLighting = {}
local listeningFor = nil
local QuickButtons = {}
local QuickButtonStrokes = {}
local filterQuery = ""
local spectatingPlayer = nil
local playerDistanceLabels = {}

local function trackConn(conn)
    table.insert(allConnections, conn)
    return conn
end

-- Helper de bordes neón
local function applyNeonStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or THEME.AccentCyan
    stroke.Transparency = transparency or 0.45
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- 🛡️ INTERFAZ PROTEGIDA (NEON GLASS)
local ScreenGui = Instance.new("ScreenGui")
Stealth.HideInstance(ScreenGui)
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
local successParent = pcall(function() ScreenGui.Parent = CoreGui end)
if not successParent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Botón flotante principal (xcs)
local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 44, 0, 44)
MiniBtn.Position = loadPosition("MiniBtn", UDim2.new(0, 15, 0, 200))
MiniBtn.BackgroundColor3 = THEME.BgMain
MiniBtn.BackgroundTransparency = 0.15
MiniBtn.Text = "xcs"
MiniBtn.TextColor3 = THEME.AccentCyan
MiniBtn.TextSize = 13
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Visible = true
MiniBtn.Parent = ScreenGui
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)
applyNeonStroke(MiniBtn, THEME.AccentCyan, 0.2, 1.5)

-- Botón flotante minimizado de TP Jugadores
local MiniTpBtn = Instance.new("TextButton")
MiniTpBtn.Size = UDim2.new(0, 44, 0, 44)
MiniTpBtn.Position = loadPosition("MiniTpBtn", UDim2.new(0, 68, 0, 200))
MiniTpBtn.BackgroundColor3 = THEME.BgMain
MiniTpBtn.BackgroundTransparency = 0.15
MiniTpBtn.Text = "TP"
MiniTpBtn.TextColor3 = THEME.AccentCyan
MiniTpBtn.TextSize = 12
MiniTpBtn.Font = Enum.Font.GothamBold
MiniTpBtn.Visible = false
MiniTpBtn.Parent = ScreenGui
Instance.new("UICorner", MiniTpBtn).CornerRadius = UDim.new(1, 0)
applyNeonStroke(MiniTpBtn, THEME.AccentCyan, 0.25, 1.5)

-- Ventana Principal Compacta
local MainFrame = Instance.new("Frame")
Stealth.HideInstance(MainFrame)
MainFrame.Size = UDim2.new(0, 215, 0, 350)
MainFrame.Position = loadPosition("MainFrame", UDim2.new(0, 20, 0, 90))
MainFrame.BackgroundColor3 = THEME.BgMain
MainFrame.BackgroundTransparency = 0.12
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
applyNeonStroke(MainFrame, THEME.AccentCyan, 0.35, 1.3)

local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = THEME.BgHeader
Title.BackgroundTransparency = 0.15
Title.Text = "  ◈ xcs Hub"
Title.TextColor3 = THEME.TextMain
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.AutoButtonColor = false
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

local HeaderDivider = Instance.new("Frame")
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
HeaderDivider.BackgroundColor3 = THEME.AccentCyan
HeaderDivider.BackgroundTransparency = 0.65
HeaderDivider.BorderSizePixel = 0
HeaderDivider.Parent = Title

local function createHeaderBtn(text, offsetX, bgColor, textColor, textSize)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 20, 0, 20)
    btn.Position = UDim2.new(1, offsetX, 0.5, -10)
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = textColor or THEME.TextMain
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = textSize or 10
    btn.Parent = Title
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    applyNeonStroke(btn, bgColor, 0.4, 1)
    return btn
end

local ResetPositionsBtn     = createHeaderBtn("🔄", -122, THEME.AccentAmber, THEME.TextMain, 9)
local MasterQuickBtn        = createHeaderBtn("👁️", -98,  THEME.AccentGreen, THEME.TextMain, 10)
local PlayerWindowToggleBtn = createHeaderBtn("TP", -74,  THEME.AccentCyan,  THEME.BgMain,   8)
local SettingsBtn           = createHeaderBtn("⚙️", -50,  THEME.BgCard,      THEME.TextMain, 10)
local MinimizeBtn           = createHeaderBtn("✕",  -26,  THEME.AccentRed,   THEME.TextMain, 10)

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Size = UDim2.new(1, 0, 1, -32)
MainScroll.Position = UDim2.new(0, 0, 0, 32)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 2
MainScroll.ScrollBarImageColor3 = THEME.AccentCyan
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainScroll.Parent = MainFrame

local MainList = Instance.new("UIListLayout")
MainList.Padding = UDim.new(0, 5)
MainList.SortOrder = Enum.SortOrder.LayoutOrder
MainList.Parent = MainScroll

local MainPadding = Instance.new("UIPadding")
MainPadding.PaddingTop = UDim.new(0, 6)
MainPadding.PaddingBottom = UDim.new(0, 8)
MainPadding.PaddingLeft = UDim.new(0, 8)
MainPadding.PaddingRight = UDim.new(0, 8)
MainPadding.Parent = MainScroll

-- Tarjeta Neon Glass con Switch animado
local function createNeonSwitch(parent, icon, text)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 28)
    card.BackgroundColor3 = THEME.BgCard
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = applyNeonStroke(card, THEME.AccentCyan, 0.78, 1)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.74, 0, 1, 0)
    label.Position = UDim2.new(0, 9, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icon ~= "" and (icon .. "  ") or "") .. text
    label.TextColor3 = THEME.TextMain
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(0, 32, 0, 16)
    bg.Position = UDim2.new(1, -40, 0.5, -8)
    bg.BackgroundColor3 = THEME.SwitchOff
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.Parent = card
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    return bg, knob, card, stroke
end

local function setSwitchVisual(state, bg, knob, card, stroke, quickKey)
    TweenService:Create(bg, TWEEN_FAST, {
        BackgroundColor3 = state and THEME.AccentGreen or THEME.SwitchOff
    }):Play()
    TweenService:Create(knob, TWEEN_FAST, {
        Position = state and UDim2.new(0, 18, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    }):Play()

    if card then
        TweenService:Create(card, TWEEN_FAST, {
            BackgroundColor3 = state and THEME.BgCardOn or THEME.BgCard
        }):Play()
    end
    if stroke then
        TweenService:Create(stroke, TWEEN_FAST, {
            Color = state and THEME.AccentGreen or THEME.AccentCyan,
            Transparency = state and 0.35 or 0.78
        }):Play()
    end
    if quickKey and QuickButtons[quickKey] then
        TweenService:Create(QuickButtons[quickKey], TWEEN_FAST, {
            BackgroundColor3 = state and THEME.BgCardOn or THEME.BgMain,
            TextColor3 = state and THEME.AccentGreen or THEME.TextMain
        }):Play()
        if QuickButtonStrokes[quickKey] then
            TweenService:Create(QuickButtonStrokes[quickKey], TWEEN_FAST, {
                Color = state and THEME.AccentGreen or THEME.AccentCyan,
                Transparency = state and 0.15 or 0.45
            }):Play()
        end
    end
end

local TPSwitchBg, TPSwitchKnob, TPSwitchCard, TPSwitchStroke = createNeonSwitch(MainScroll, "📍", "TPS (Toque)")
if not isTouchDevice then TPSwitchCard.Visible = false end
local SwitchBg, SwitchKnob, SwitchCard, SwitchStroke = createNeonSwitch(MainScroll, "👁️", "Invisicam")
local FPXRaySwitchBg, FPXRaySwitchKnob, FPXRayCard, FPXRayStroke = createNeonSwitch(MainScroll, "🧱", "FP X-Ray")
local ESPSwitchBg, ESPSwitchKnob, ESPCard, ESPStroke = createNeonSwitch(MainScroll, "🎯", "ESP Jugadores")
local DeleteSwitchBg, DeleteSwitchKnob, DeleteCard, DeleteStroke = createNeonSwitch(MainScroll, "🗑️", "Borrador Paredes")
local NoclipSwitchBg, NoclipSwitchKnob, NoclipCard, NoclipStroke = createNeonSwitch(MainScroll, "👻", "Noclip")
local InfJumpSwitchBg, InfJumpSwitchKnob, InfJumpCard, InfJumpStroke = createNeonSwitch(MainScroll, "⚡", "Infinite Jump")
local FlySwitchBg, FlySwitchKnob, FlyCard, FlyStroke = createNeonSwitch(MainScroll, "🕊️", "Fly")
local FreeCamSwitchBg, FreeCamSwitchKnob, FreeCamCard, FreeCamStroke = createNeonSwitch(MainScroll, "🎥", "Free Cam")
local FullbrightSwitchBg, FullbrightSwitchKnob, FullbrightCard, FullbrightStroke = createNeonSwitch(MainScroll, "☀️", "Fullbright")
local ThirdPersonSwitchBg, ThirdPersonSwitchKnob, ThirdPersonCard, ThirdPersonStroke = createNeonSwitch(MainScroll, "🧍", "Third Person")

-- ==========================================
-- 🛑 SISTEMA ANTI-RUBBERBAND SEGURO (Fuerza Bruta TP)
-- ==========================================
local function ForceTeleport(targetPos)
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Matamos inercia de forma segura
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    local startTime = os.clock()
    local tpConnection
    
    tpConnection = RunService.Heartbeat:Connect(function()
        -- Detenemos la fuerza bruta después de 0.2s
        if os.clock() - startTime > 0.2 then
            if tpConnection then tpConnection:Disconnect() end
            return
        end
        
        -- Ejecutamos la posición asegurándonos de que no crashee si mueres
        pcall(function()
            if hrp and hrp.Parent then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(targetPos)
            end
        end)
    end)
    trackConn(tpConnection) -- Lo agregamos a conexiones por si das Unload en medio del TP
end

-- ==========================================
-- LÓGICAS PRINCIPALES DE CÁMARA Y TPS
-- ==========================================
local function toggleInvisicam(state)
    invisicamEnabled = state
    setSwitchVisual(state, SwitchBg, SwitchKnob, SwitchCard, SwitchStroke, "Invisicam")
    if state then
        pcall(function()
            LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
            LocalPlayer.CameraMaxZoomDistance = 400
            LocalPlayer.CameraMinZoomDistance = 0.5
        end)
        if invisicamConnection then invisicamConnection:Disconnect() end
        invisicamConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            if not invisicamEnabled then return end
            pcall(function() if LocalPlayer.CameraMaxZoomDistance < 400 then LocalPlayer.CameraMaxZoomDistance = 400 end end)
        end))
    else
        pcall(function()
            LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
            LocalPlayer.CameraMaxZoomDistance = 15
        end)
        if invisicamConnection then invisicamConnection:Disconnect() end
        invisicamConnection = nil
    end
end

local function toggleThirdPerson(state)
    thirdPersonEnabled = state
    setSwitchVisual(state, ThirdPersonSwitchBg, ThirdPersonSwitchKnob, ThirdPersonCard, ThirdPersonStroke, "ThirdPerson")
    if state then
        pcall(function() LocalPlayer.CameraMode = Enum.CameraMode.Classic end)
        if thirdPersonConnection then thirdPersonConnection:Disconnect() end
        thirdPersonConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            if not thirdPersonEnabled then return end
            pcall(function() if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then LocalPlayer.CameraMode = Enum.CameraMode.Classic end end)
        end))
    else
        if thirdPersonConnection then thirdPersonConnection:Disconnect() end
        thirdPersonConnection = nil
    end
end

-- 👥 Ventana de TP a Jugadores (Integrada con ForceTeleport)
local PlayerWindow = Instance.new("Frame")
Stealth.HideInstance(PlayerWindow)
PlayerWindow.Size = UDim2.new(0, 215, 0, 325)
PlayerWindow.Position = loadPosition("PlayerWindow", UDim2.new(0, 245, 0, 90))
PlayerWindow.BackgroundColor3 = THEME.BgMain
PlayerWindow.BackgroundTransparency = 0.12
PlayerWindow.BorderSizePixel = 0
PlayerWindow.Visible = false
PlayerWindow.Parent = ScreenGui
Instance.new("UICorner", PlayerWindow).CornerRadius = UDim.new(0, 12)
applyNeonStroke(PlayerWindow, THEME.AccentCyan, 0.35, 1.3)

local PlayerWindowTitle = Instance.new("TextButton")
PlayerWindowTitle.Size = UDim2.new(1, 0, 0, 28)
PlayerWindowTitle.BackgroundColor3 = THEME.BgHeader
PlayerWindowTitle.BackgroundTransparency = 0.15
PlayerWindowTitle.Text = "  👥 TP Jugadores"
PlayerWindowTitle.TextColor3 = THEME.AccentCyan
PlayerWindowTitle.Font = Enum.Font.GothamBold
PlayerWindowTitle.TextSize = 11
PlayerWindowTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerWindowTitle.AutoButtonColor = false
PlayerWindowTitle.Parent = PlayerWindow
Instance.new("UICorner", PlayerWindowTitle).CornerRadius = UDim.new(0, 12)

local PlayerWindowMinBtn = Instance.new("TextButton")
PlayerWindowMinBtn.Size = UDim2.new(0, 19, 0, 19)
PlayerWindowMinBtn.Position = UDim2.new(1, -46, 0.5, -9)
PlayerWindowMinBtn.BackgroundColor3 = THEME.BgCard
PlayerWindowMinBtn.Text = "—"
PlayerWindowMinBtn.TextColor3 = THEME.TextMain
PlayerWindowMinBtn.TextSize = 9
PlayerWindowMinBtn.Font = Enum.Font.GothamBold
PlayerWindowMinBtn.Parent = PlayerWindowTitle
Instance.new("UICorner", PlayerWindowMinBtn).CornerRadius = UDim.new(0, 5)

local PlayerWindowCloseBtn = Instance.new("TextButton")
PlayerWindowCloseBtn.Size = UDim2.new(0, 19, 0, 19)
PlayerWindowCloseBtn.Position = UDim2.new(1, -23, 0.5, -9)
PlayerWindowCloseBtn.BackgroundColor3 = THEME.AccentRed
PlayerWindowCloseBtn.Text = "✕"
PlayerWindowCloseBtn.TextColor3 = THEME.TextMain
PlayerWindowCloseBtn.TextSize = 9
PlayerWindowCloseBtn.Font = Enum.Font.GothamBold
PlayerWindowCloseBtn.Parent = PlayerWindowTitle
Instance.new("UICorner", PlayerWindowCloseBtn).CornerRadius = UDim.new(0, 5)

local PlayerWindowScroll = Instance.new("ScrollingFrame")
PlayerWindowScroll.Size = UDim2.new(1, 0, 1, -30)
PlayerWindowScroll.Position = UDim2.new(0, 0, 0, 30)
PlayerWindowScroll.BackgroundTransparency = 1
PlayerWindowScroll.BorderSizePixel = 0
PlayerWindowScroll.ScrollBarThickness = 2
PlayerWindowScroll.ScrollBarImageColor3 = THEME.AccentCyan
PlayerWindowScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerWindowScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerWindowScroll.Parent = PlayerWindow

local PlayerWindowScrollList = Instance.new("UIListLayout")
PlayerWindowScrollList.Padding = UDim.new(0, 6)
PlayerWindowScrollList.Parent = PlayerWindowScroll

local PlayerWindowPadding = Instance.new("UIPadding")
PlayerWindowPadding.PaddingTop = UDim.new(0, 6)
PlayerWindowPadding.PaddingLeft = UDim.new(0, 8)
PlayerWindowPadding.PaddingRight = UDim.new(0, 8)
PlayerWindowPadding.Parent = PlayerWindowScroll

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, 0, 0, 24)
searchBox.BackgroundColor3 = THEME.BgCard
searchBox.BackgroundTransparency = 0.15
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Buscar jugador..."
searchBox.TextColor3 = THEME.TextMain
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.Parent = PlayerWindowScroll
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
applyNeonStroke(searchBox, THEME.AccentCyan, 0.65, 1)

local ResetCamSelfBtn = Instance.new("TextButton")
ResetCamSelfBtn.Size = UDim2.new(1, 0, 0, 22)
ResetCamSelfBtn.BackgroundColor3 = THEME.BgCardOn
ResetCamSelfBtn.Text = "🏠 Volver cámara a mí"
ResetCamSelfBtn.TextColor3 = THEME.AccentGreen
ResetCamSelfBtn.Font = Enum.Font.GothamBold
ResetCamSelfBtn.TextSize = 9
ResetCamSelfBtn.Visible = false
ResetCamSelfBtn.Parent = PlayerWindowScroll
Instance.new("UICorner", ResetCamSelfBtn).CornerRadius = UDim.new(0, 6)

local PlayerListContainer = Instance.new("Frame")
PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
PlayerListContainer.AutomaticSize = Enum.AutomaticSize.Y
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.Parent = PlayerWindowScroll
local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 4)
PlayerListLayout.Parent = PlayerListContainer

-- NUEVO TP DE JUGADORES USANDO FORCE TELEPORT
local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local targetPos = targetPlayer.Character.HumanoidRootPart.Position
        ForceTeleport(targetPos + Vector3.new(0, 3, 0))
    end
end

local refreshPlayerList
local function resetSpectate()
    spectatingPlayer = nil
    ResetCamSelfBtn.Visible = false
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    if refreshPlayerList then refreshPlayerList() end
end

local function spectatePlayer(targetPlayer)
    if spectatingPlayer == targetPlayer then resetSpectate() else
        spectatingPlayer = targetPlayer
        ResetCamSelfBtn.Visible = true
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    end
end
ResetCamSelfBtn.MouseButton1Click:Connect(resetSpectate)

refreshPlayerList = function()
    for _, child in ipairs(PlayerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    playerDistanceLabels = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local isFriend = false
            pcall(function() isFriend = LocalPlayer:IsFriendsWith(p.UserId) end)
            local formattedName = (isFriend and "⭐ " or "") .. p.DisplayName

            if filterQuery == "" or string.find(string.lower(p.DisplayName), string.lower(filterQuery)) or string.find(string.lower(p.Name), string.lower(filterQuery)) then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = THEME.BgCard
                row.BackgroundTransparency = 0.3
                row.Parent = PlayerListContainer
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

                local pNameLabel = Instance.new("TextLabel")
                pNameLabel.Size = UDim2.new(0.45, 0, 0, 14)
                pNameLabel.Position = UDim2.new(0, 30, 0, 2)
                pNameLabel.BackgroundTransparency = 1
                pNameLabel.Text = formattedName
                pNameLabel.TextColor3 = isFriend and Color3.fromRGB(255, 215, 0) or THEME.TextMain
                pNameLabel.Font = Enum.Font.GothamMedium
                pNameLabel.TextSize = 9
                pNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                pNameLabel.Parent = row

                local distLabel = Instance.new("TextLabel")
                distLabel.Size = UDim2.new(0.45, 0, 0, 11)
                distLabel.Position = UDim2.new(0, 30, 0, 16)
                distLabel.BackgroundTransparency = 1
                distLabel.Text = "--- m"
                distLabel.TextColor3 = THEME.TextMuted
                distLabel.Font = Enum.Font.Gotham
                distLabel.TextSize = 8
                distLabel.TextXAlignment = Enum.TextXAlignment.Left
                distLabel.Parent = row
                playerDistanceLabels[p] = distLabel

                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(0, 24, 0, 18)
                tpBtn.Position = UDim2.new(1, -58, 0.5, -9)
                tpBtn.BackgroundColor3 = THEME.AccentCyan
                tpBtn.Text = "TP"
                tpBtn.TextColor3 = THEME.BgMain
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.TextSize = 8
                tpBtn.Parent = row
                Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
                tpBtn.MouseButton1Click:Connect(function() teleportToPlayer(p) end)

                local viewBtn = Instance.new("TextButton")
                viewBtn.Size = UDim2.new(0, 28, 0, 18)
                viewBtn.Position = UDim2.new(1, -31, 0.5, -9)
                viewBtn.BackgroundColor3 = (spectatingPlayer == p) and THEME.AccentGreen or THEME.SwitchOff
                viewBtn.Text = "VIEW"
                viewBtn.TextColor3 = THEME.TextMain
                viewBtn.Font = Enum.Font.GothamBold
                viewBtn.TextSize = 7
                viewBtn.Parent = row
                Instance.new("UICorner", viewBtn).CornerRadius = UDim.new(0, 4)
                viewBtn.MouseButton1Click:Connect(function() spectatePlayer(p); refreshPlayerList() end)
            end
        end
    end
end

task.spawn(function()
    while not hubUnloaded do
        if PlayerWindow.Visible then
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            for plr, lbl in pairs(playerDistanceLabels) do
                if lbl and lbl.Parent then
                    local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if myHrp and tHrp then lbl.Text = math.floor((myHrp.Position - tHrp.Position).Magnitude) .. " m"
                    else lbl.Text = "Fuera" end
                end
            end
        end
        task.wait(0.25)
    end
end)

trackConn(searchBox:GetPropertyChangedSignal("Text"):Connect(function() filterQuery = searchBox.Text; refreshPlayerList() end))
trackConn(Players.PlayerAdded:Connect(refreshPlayerList))
trackConn(Players.PlayerRemoving:Connect(function(p) if spectatingPlayer == p then resetSpectate() end; refreshPlayerList() end))
task.spawn(refreshPlayerList)

PlayerWindowMinBtn.MouseButton1Click:Connect(function() PlayerWindow.Visible = false; MiniTpBtn.Visible = true end)
PlayerWindowCloseBtn.MouseButton1Click:Connect(function() PlayerWindow.Visible = false; MiniTpBtn.Visible = false end)
PlayerWindowToggleBtn.MouseButton1Click:Connect(function() PlayerWindow.Visible = not PlayerWindow.Visible; MiniTpBtn.Visible = false end)
MiniTpBtn.Activated:Connect(function() PlayerWindow.Visible = true; MiniTpBtn.Visible = false end)

-- ⚙️ Ventana de Configuración (Compacta para no alargar código base)
local SettingsFrame = Instance.new("Frame")
Stealth.HideInstance(SettingsFrame)
SettingsFrame.Size = UDim2.new(0, 220, 0, 345)
SettingsFrame.Position = loadPosition("SettingsFrame", UDim2.new(0, 245, 0, 110))
SettingsFrame.BackgroundColor3 = THEME.BgMain
SettingsFrame.BackgroundTransparency = 0.1
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = ScreenGui
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 12)
applyNeonStroke(SettingsFrame, THEME.AccentCyan, 0.35, 1.3)

local SettingsTitle = Instance.new("TextButton")
SettingsTitle.Size = UDim2.new(1, 0, 0, 28)
SettingsTitle.BackgroundColor3 = THEME.BgHeader
SettingsTitle.BackgroundTransparency = 0.15
SettingsTitle.Text = "  ⚙️ Ajustes"
SettingsTitle.TextColor3 = THEME.AccentCyan
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextSize = 11
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.AutoButtonColor = false
SettingsTitle.Parent = SettingsFrame
Instance.new("UICorner", SettingsTitle).CornerRadius = UDim.new(0, 12)

local CloseSettingsBtn = Instance.new("TextButton")
CloseSettingsBtn.Size = UDim2.new(0, 20, 0, 20)
CloseSettingsBtn.Position = UDim2.new(1, -25, 0.5, -10)
CloseSettingsBtn.BackgroundColor3 = THEME.AccentRed
CloseSettingsBtn.Text = "✕"
CloseSettingsBtn.TextColor3 = THEME.TextMain
CloseSettingsBtn.Font = Enum.Font.GothamBold
CloseSettingsBtn.TextSize = 10
CloseSettingsBtn.Parent = SettingsTitle
Instance.new("UICorner", CloseSettingsBtn).CornerRadius = UDim.new(0, 5)

-- ==========================================
-- 👻 NOCLIP SEGURO (CON SUSPENSIÓN DE FÍSICAS - ChangeState 11)
-- ==========================================
local function cacheCharacterParts(char)
    cachedCharParts = {}
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
            table.insert(cachedCharParts, part)
        end
    end
    char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") and not desc:FindFirstAncestorOfClass("Accessory") then table.insert(cachedCharParts, desc) end
    end)
end

if LocalPlayer.Character then cacheCharacterParts(LocalPlayer.Character) end

local function toggleNoclip(state)
    noclipEnabled = state
    setSwitchVisual(state, NoclipSwitchBg, NoclipSwitchKnob, NoclipCard, NoclipStroke, "Noclip")

    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        if #cachedCharParts == 0 and LocalPlayer.Character then cacheCharacterParts(LocalPlayer.Character) end
        
        noclipConnection = Stealth.HideConnections(RunService.Stepped:Connect(function()
            -- NUEVO: Suspendemos las físicas del servidor de forma segura
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function() hum:ChangeState(11) end) -- 11 = StrafingNoPhysics
                end
            end

            for i = 1, #cachedCharParts do
                local part = cachedCharParts[i]
                if part and part.Parent and part.CanCollide then part.CanCollide = false end
            end
        end))
    else
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = nil
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0) end
        end
    end
end

-- ==========================================
-- ESP, DELETE MODE Y DEMÁS
-- ==========================================
local function applyHighlightToCharacter(plr, char)
    if not espEnabled or plr == LocalPlayer or not char then return end
    if espHighlights[plr] and espHighlights[plr].Parent then espHighlights[plr]:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = "CoreUI_HL"
    hl.FillColor = Color3.fromRGB(255, 0, 80)
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = char
    espHighlights[plr] = hl
end

local function setupPlayerESP(plr)
    if plr == LocalPlayer then return end
    if espCharConnections[plr] then espCharConnections[plr]:Disconnect() end
    espCharConnections[plr] = plr.CharacterAdded:Connect(function(char)
        task.wait(0.2)
        if espEnabled then applyHighlightToCharacter(plr, char) end
    end)
    if espEnabled and plr.Character then applyHighlightToCharacter(plr, plr.Character) end
end

local function toggleESP(state)
    espEnabled = state
    setSwitchVisual(state, ESPSwitchBg, ESPSwitchKnob, ESPCard, ESPStroke, "ESP")
    if state then for _, plr in ipairs(Players:GetPlayers()) do setupPlayerESP(plr) end
    else for _, hl in pairs(espHighlights) do if hl and hl.Parent then hl:Destroy() end end espHighlights = {} end
end
trackConn(Players.PlayerAdded:Connect(setupPlayerESP))

local function toggleDeleteMode(state)
    deleteModeEnabled = state
    setSwitchVisual(state, DeleteSwitchBg, DeleteSwitchKnob, DeleteCard, DeleteStroke, "DeleteMode")
end

local function RestoreMap()
    for _, data in ipairs(deletedPartsMemory) do
        if data.part and data.part.Parent then data.part.Transparency = data.trans; data.part.CanCollide = data.collide end
    end
    deletedPartsMemory = {}
end

-- ==========================================
-- CONTROLES RAYCAST Y RATÓN (NUEVO TELEPORT APLICADO)
-- ==========================================
local function raycastIgnoringDeleted(origin, direction)
    local filter = {LocalPlayer.Character, Camera}
    for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(filter, p.Character) end end
    for _, data in ipairs(deletedPartsMemory) do if data.part and data.part.Parent then table.insert(filter, data.part) end end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = filter
    params.FilterType = Enum.RaycastFilterType.Exclude
    return Workspace:Raycast(origin, direction, params)
end

local function DeletePartAt(mousePos)
    local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
    local result = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
    if result and result.Instance then
        local part = result.Instance
        if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
            table.insert(deletedPartsMemory, {part = part, trans = part.Transparency, collide = part.CanCollide})
            part.Transparency = 1
            part.CanCollide = false
        end
    end
end

local function TeleportAt(mousePos)
    local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
    local result = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
    if result then
        -- Usamos el nuevo sistema seguro de ForceTeleport en lugar de asignación directa
        ForceTeleport(result.Position + Vector3.new(0, 3, 0))
    end
end

local keybinds = {
    Invisicam  = loadKeybind("Invisicam",  Enum.KeyCode.V),
    Noclip     = loadKeybind("Noclip",     Enum.KeyCode.X),
    Teleport   = loadKeybind("Teleport",   Enum.KeyCode.G),
    Delete     = loadKeybind("Delete",     Enum.KeyCode.L),
    Restore    = loadKeybind("Restore",    Enum.KeyCode.R),
    ESP        = loadKeybind("ESP",        Enum.KeyCode.H),
}

trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or listeningFor or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == keybinds.Invisicam then toggleInvisicam(not invisicamEnabled) end
        if input.KeyCode == keybinds.Noclip then toggleNoclip(not noclipEnabled) end
        if input.KeyCode == keybinds.ESP then toggleESP(not espEnabled) end
        if input.KeyCode == keybinds.Restore then RestoreMap() end
        if input.KeyCode == keybinds.Teleport then TeleportAt(Vector2.new(Mouse.X, Mouse.Y)) end
        if input.KeyCode == keybinds.Delete then DeletePartAt(Vector2.new(Mouse.X, Mouse.Y)) end
    end
end))

local touchState = { active = false, startTime = 0, totalMoved = 0, isCameraDrag = false }
trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touchState.active = true; touchState.startTime = os.clock(); touchState.totalMoved = 0; touchState.isCameraDrag = false
    end
end))
trackConn(UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        touchState.totalMoved = touchState.totalMoved + input.Delta.Magnitude
        if touchState.totalMoved > 10 then touchState.isCameraDrag = true end
    end
end))
local function isOverGui(pos)
    if not ScreenGui or not ScreenGui.Parent then return false end
    for _, obj in ipairs(LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)) do
        if obj:IsDescendantOf(ScreenGui) then return true end
    end
    return false
end
trackConn(UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        touchState.active = false
        if (os.clock() - touchState.startTime) < 0.3 and not touchState.isCameraDrag and not isOverGui(input.Position) then
            if deleteModeEnabled then DeletePartAt(input.Position)
            elseif tpEnabled then TeleportAt(input.Position) end
        end
    end
end))

-- Botones Base
if isTouchDevice then
    TPSwitchBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            tpEnabled = not tpEnabled; setSwitchVisual(tpEnabled, TPSwitchBg, TPSwitchKnob, TPSwitchCard, TPSwitchStroke, "TPS")
        end
    end)
end
SwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleInvisicam(not invisicamEnabled) end end)
NoclipSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleNoclip(not noclipEnabled) end end)
ESPSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleESP(not espEnabled) end end)
DeleteSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleDeleteMode(not deleteModeEnabled) end end)

MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniBtn.Visible = true end)
MiniBtn.Activated:Connect(function() MainFrame.Visible = true; MiniBtn.Visible = false end)
SettingsBtn.Activated:Connect(function() SettingsFrame.Visible = not SettingsFrame.Visible end)
CloseSettingsBtn.MouseButton1Click:Connect(function() SettingsFrame.Visible = false end)

-- Sistema de Unload
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(1, -16, 0, 26)
UnloadBtn.Position = UDim2.new(0, 8, 0, 40)
UnloadBtn.BackgroundColor3 = THEME.AccentRed
UnloadBtn.Text = "🛑 Cerrar Hub (Unload)"
UnloadBtn.TextColor3 = THEME.TextMain
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 9
UnloadBtn.Parent = SettingsFrame
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 6)

UnloadBtn.MouseButton1Click:Connect(function()
    hubUnloaded = true
    if invisicamEnabled then toggleInvisicam(false) end
    if espEnabled then toggleESP(false) end
    if noclipEnabled then toggleNoclip(false) end
    if spectatingPlayer then resetSpectate() end
    RestoreMap()
    for _, conn in ipairs(allConnections) do pcall(function() conn:Disconnect() end) end
    for _, conn in pairs(espCharConnections) do pcall(function() conn:Disconnect() end) end
    if ScreenGui then ScreenGui:Destroy() end
end)
