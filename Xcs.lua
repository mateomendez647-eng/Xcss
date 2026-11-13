-- ==========================================
-- HUB: xcs (Neon Glass v2.2 - Optimizado)
-- Wall‑Bang + Stealth Avanzado
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

-- 🛡️ MÓDULO DE SIGILO (STEALTH) AVANZADO
local Stealth = {}

local _stealthSeed = tick() % 1000

local function stealthName()
    _stealthSeed = _stealthSeed + 1
    local prefixes = {"Frame","TextLabel","ImageLabel","UICorner","UIStroke","ScrollingFrame","TextButton","ImageButton","ViewportFrame"}
    return prefixes[math.random(1, #prefixes)] .. "_" .. string.format("%04x", math.random(0, 0xFFFF))
end

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
    pcall(function() instance.Name = stealthName() end)
end

function Stealth.RandomizeName(instance)
    if instance and typeof(instance) == "Instance" then
        pcall(function() instance.Name = stealthName() end)
    end
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
local wallBangEnabled = false
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
local wallBangConnection = nil
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

local keybinds = {
    Invisicam  = loadKeybind("Invisicam",  Enum.KeyCode.V),
    Noclip     = loadKeybind("Noclip",     Enum.KeyCode.X),
    Fly        = loadKeybind("Fly",        Enum.KeyCode.Z),
    FreeCam    = loadKeybind("FreeCam",    Enum.KeyCode.C),
    Fullbright = loadKeybind("Fullbright", Enum.KeyCode.B),
    Teleport   = loadKeybind("Teleport",   Enum.KeyCode.G),
    XRay       = loadKeybind("XRay",       Enum.KeyCode.K),
    Delete     = loadKeybind("Delete",     Enum.KeyCode.L),
    Restore    = loadKeybind("Restore",    Enum.KeyCode.R),
    ESP        = loadKeybind("ESP",        Enum.KeyCode.H),
    InfJump    = loadKeybind("InfJump",    Enum.KeyCode.J),
    WallBang   = loadKeybind("WallBang",   Enum.KeyCode.N),
}

-- Helper de bordes neón
local function applyNeonStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    Stealth.RandomizeName(stroke)
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
Stealth.RandomizeName(MiniBtn)
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
Stealth.RandomizeName(MiniTpBtn)
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
Stealth.RandomizeName(Title)
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
Stealth.RandomizeName(HeaderDivider)
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
HeaderDivider.BackgroundColor3 = THEME.AccentCyan
HeaderDivider.BackgroundTransparency = 0.65
HeaderDivider.BorderSizePixel = 0
HeaderDivider.Parent = Title

local function createHeaderBtn(text, offsetX, bgColor, textColor, textSize)
    local btn = Instance.new("TextButton")
    Stealth.RandomizeName(btn)
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
Stealth.RandomizeName(MainScroll)
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

-- Tarjeta Neon Glass con Switch animado por TweenService
local function createNeonSwitch(parent, icon, text)
    local card = Instance.new("Frame")
    Stealth.RandomizeName(card)
    card.Size = UDim2.new(1, 0, 0, 28)
    card.BackgroundColor3 = THEME.BgCard
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = applyNeonStroke(card, THEME.AccentCyan, 0.78, 1)

    local label = Instance.new("TextLabel")
    Stealth.RandomizeName(label)
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
    Stealth.RandomizeName(bg)
    bg.Size = UDim2.new(0, 32, 0, 16)
    bg.Position = UDim2.new(1, -40, 0.5, -8)
    bg.BackgroundColor3 = THEME.SwitchOff
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.Parent = card
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    Stealth.RandomizeName(knob)
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
local WallBangSwitchBg, WallBangSwitchKnob, WallBangCard, WallBangStroke = createNeonSwitch(MainScroll, "🔨", "Wall-Bang")

-- 🎥 Lógica de Invisicam con Zoom Libre integrado
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
            pcall(function()
                if LocalPlayer.CameraMaxZoomDistance < 400 then
                    LocalPlayer.CameraMaxZoomDistance = 400
                end
            end)
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
        pcall(function()
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.DevComputerCameraMode = Enum.DevComputerCameraMode.Classic
            LocalPlayer.DevTouchCameraMode = Enum.DevTouchCameraMode.Classic
        end)
        if thirdPersonConnection then thirdPersonConnection:Disconnect() end
        thirdPersonConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            if not thirdPersonEnabled then return end
            pcall(function()
                if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                end
            end)
        end))
    else
        if thirdPersonConnection then thirdPersonConnection:Disconnect() end
        thirdPersonConnection = nil
    end
end

-- ==========================================
-- 🔨 WALL-BANG
-- ==========================================
local function performWallBang()
    if not wallBangEnabled then return end

    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)

    -- Whitelist: solo personajes de otros jugadores
    local filter = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            table.insert(filter, plr.Character)
        end
    end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = filter
    params.FilterType = Enum.RaycastFilterType.Include
    params.IgnoreWater = true

    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
    if result and result.Instance then
        local hitPart = result.Instance
        local character = hitPart:FindFirstAncestorOfClass("Model")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid and character ~= LocalPlayer.Character then
            local dmg = 25
            if humanoid.Health > 0 then
                humanoid:TakeDamage(dmg)
            end
        end
    end
end

local function toggleWallBang(state)
    wallBangEnabled = state
    setSwitchVisual(state, WallBangSwitchBg, WallBangSwitchKnob, WallBangCard, WallBangStroke, "WallBang")

    if state then
        if wallBangConnection then wallBangConnection:Disconnect() end
        wallBangConnection = Stealth.HideConnections(UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed or hubUnloaded then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 and input.UserInputState == Enum.UserInputState.Begin then
                performWallBang()
            end
        end))
        trackConn(wallBangConnection)
    else
        if wallBangConnection then wallBangConnection:Disconnect() end
        wallBangConnection = nil
    end
end

-- 👥 Ventana de TP a Jugadores (Con Distancia y Botón Volver a Mí)
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
Stealth.RandomizeName(PlayerWindowTitle)
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
Stealth.RandomizeName(PlayerWindowMinBtn)
PlayerWindowMinBtn.Size = UDim2.new(0, 19, 0, 19)
PlayerWindowMinBtn.Position = UDim2.new(1, -46, 0.5, -9)
PlayerWindowMinBtn.BackgroundColor3 = THEME.BgCard
PlayerWindowMinBtn.Text = "—"
PlayerWindowMinBtn.TextColor3 = THEME.TextMain
PlayerWindowMinBtn.TextSize = 9
PlayerWindowMinBtn.Font = Enum.Font.GothamBold
PlayerWindowMinBtn.Parent = PlayerWindowTitle
Instance.new("UICorner", PlayerWindowMinBtn).CornerRadius = UDim.new(0, 5)
applyNeonStroke(PlayerWindowMinBtn, THEME.AccentCyan, 0.5, 1)

local PlayerWindowCloseBtn = Instance.new("TextButton")
Stealth.RandomizeName(PlayerWindowCloseBtn)
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
Stealth.RandomizeName(PlayerWindowScroll)
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
PlayerWindowScrollList.SortOrder = Enum.SortOrder.LayoutOrder
PlayerWindowScrollList.Parent = PlayerWindowScroll

local PlayerWindowPadding = Instance.new("UIPadding")
PlayerWindowPadding.PaddingTop = UDim.new(0, 6)
PlayerWindowPadding.PaddingBottom = UDim.new(0, 8)
PlayerWindowPadding.PaddingLeft = UDim.new(0, 8)
PlayerWindowPadding.PaddingRight = UDim.new(0, 8)
PlayerWindowPadding.Parent = PlayerWindowScroll

local searchBox = Instance.new("TextBox")
Stealth.RandomizeName(searchBox)
searchBox.Size = UDim2.new(1, 0, 0, 24)
searchBox.BackgroundColor3 = THEME.BgCard
searchBox.BackgroundTransparency = 0.15
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Buscar jugador..."
searchBox.PlaceholderColor3 = THEME.TextMuted
searchBox.TextColor3 = THEME.TextMain
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.ClearTextOnFocus = false
searchBox.Parent = PlayerWindowScroll
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
applyNeonStroke(searchBox, THEME.AccentCyan, 0.65, 1)

-- Botón rápido para volver la cámara a tu personaje
local ResetCamSelfBtn = Instance.new("TextButton")
Stealth.RandomizeName(ResetCamSelfBtn)
ResetCamSelfBtn.Size = UDim2.new(1, 0, 0, 22)
ResetCamSelfBtn.BackgroundColor3 = THEME.BgCardOn
ResetCamSelfBtn.Text = "🏠 Volver cámara a mí"
ResetCamSelfBtn.TextColor3 = THEME.AccentGreen
ResetCamSelfBtn.Font = Enum.Font.GothamBold
ResetCamSelfBtn.TextSize = 9
ResetCamSelfBtn.Visible = false
ResetCamSelfBtn.Parent = PlayerWindowScroll
Instance.new("UICorner", ResetCamSelfBtn).CornerRadius = UDim.new(0, 6)
applyNeonStroke(ResetCamSelfBtn, THEME.AccentGreen, 0.4, 1)

local PlayerListContainer = Instance.new("Frame")
Stealth.RandomizeName(PlayerListContainer)
PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
PlayerListContainer.AutomaticSize = Enum.AutomaticSize.Y
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.Parent = PlayerWindowScroll

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 4)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerListContainer

local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
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
    if spectatingPlayer == targetPlayer then
        resetSpectate()
    else
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
            local displayName = p.DisplayName
            local userName = p.Name

            local isFriend = false
            pcall(function()
                isFriend = LocalPlayer:IsFriendsWith(p.UserId)
            end)

            local formattedName = (isFriend and "⭐ " or "") .. displayName

            if filterQuery == "" or string.find(string.lower(displayName), string.lower(filterQuery)) or string.find(string.lower(userName), string.lower(filterQuery)) then
                local row = Instance.new("Frame")
                Stealth.RandomizeName(row)
                row.Size = UDim2.new(1, 0, 0, 30)
                row.BackgroundColor3 = THEME.BgCard
                row.BackgroundTransparency = 0.3
                row.Parent = PlayerListContainer
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                applyNeonStroke(row, isFriend and Color3.fromRGB(255, 215, 0) or THEME.AccentCyan, 0.8, 1)

                local thumbImg = Instance.new("ImageLabel")
                Stealth.RandomizeName(thumbImg)
                thumbImg.Size = UDim2.new(0, 22, 0, 22)
                thumbImg.Position = UDim2.new(0, 4, 0.5, -11)
                thumbImg.BackgroundColor3 = THEME.BgHeader
                thumbImg.BorderSizePixel = 0
                thumbImg.Image = ""
                thumbImg.Parent = row
                Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)

                task.spawn(function()
                    local userId = p.UserId
                    local finalUrl = ""
                    local success, url = pcall(function()
                        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    end)
                    if success and url and url ~= "" then
                        finalUrl = url
                    else
                        finalUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png"
                    end
                    if thumbImg and thumbImg.Parent then thumbImg.Image = finalUrl end
                end)

                local pNameLabel = Instance.new("TextLabel")
                Stealth.RandomizeName(pNameLabel)
                pNameLabel.Size = UDim2.new(0.45, 0, 0, 14)
                pNameLabel.Position = UDim2.new(0, 30, 0, 2)
                pNameLabel.BackgroundTransparency = 1
                pNameLabel.Text = formattedName
                pNameLabel.TextColor3 = isFriend and Color3.fromRGB(255, 215, 0) or THEME.TextMain
                pNameLabel.Font = Enum.Font.GothamMedium
                pNameLabel.TextSize = 9
                pNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                pNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                pNameLabel.Parent = row

                local distLabel = Instance.new("TextLabel")
                Stealth.RandomizeName(distLabel)
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
                Stealth.RandomizeName(tpBtn)
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
                Stealth.RandomizeName(viewBtn)
                viewBtn.Size = UDim2.new(0, 28, 0, 18)
                viewBtn.Position = UDim2.new(1, -31, 0.5, -9)
                viewBtn.BackgroundColor3 = (spectatingPlayer == p) and THEME.AccentGreen or THEME.SwitchOff
                viewBtn.Text = "VIEW"
                viewBtn.TextColor3 = THEME.TextMain
                viewBtn.Font = Enum.Font.GothamBold
                viewBtn.TextSize = 7
                viewBtn.Parent = row
                Instance.new("UICorner", viewBtn).CornerRadius = UDim.new(0, 4)
                viewBtn.MouseButton1Click:Connect(function()
                    spectatePlayer(p)
                    refreshPlayerList()
                end)
            end
        end
    end
end

-- Actualizador ligero de distancias
task.spawn(function()
    while not hubUnloaded do
        if PlayerWindow.Visible then
            local myChar = LocalPlayer.Character
            local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
            for plr, lbl in pairs(playerDistanceLabels) do
                if lbl and lbl.Parent then
                    local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                    if myHrp and tHrp then
                        local dist = math.floor((myHrp.Position - tHrp.Position).Magnitude)
                        lbl.Text = dist .. " m"
                    else
                        lbl.Text = "Fuera de rango"
                    end
                end
            end
        end
        task.wait(0.25)
    end
end)

trackConn(searchBox:GetPropertyChangedSignal("Text"):Connect(function() filterQuery = searchBox.Text; refreshPlayerList() end))
trackConn(Players.PlayerAdded:Connect(refreshPlayerList))
trackConn(Players.PlayerRemoving:Connect(function(p)
    if spectatingPlayer == p then resetSpectate() end
    refreshPlayerList()
end))
task.spawn(refreshPlayerList)

PlayerWindowMinBtn.MouseButton1Click:Connect(function() PlayerWindow.Visible = false; MiniTpBtn.Visible = true end)
PlayerWindowCloseBtn.MouseButton1Click:Connect(function() PlayerWindow.Visible = false; MiniTpBtn.Visible = false end)
PlayerWindowToggleBtn.MouseButton1Click:Connect(function() PlayerWindow.Visible = not PlayerWindow.Visible; MiniTpBtn.Visible = false end)
MiniTpBtn.Activated:Connect(function() PlayerWindow.Visible = true; MiniTpBtn.Visible = false end)

-- ⚙️ Ventana de Configuración
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
Stealth.RandomizeName(SettingsTitle)
SettingsTitle.Size = UDim2.new(1, 0, 0, 28)
SettingsTitle.BackgroundColor3 = THEME.BgHeader
SettingsTitle.BackgroundTransparency = 0.15
SettingsTitle.Text = "  ⚙️ Ajustes y Botones"
SettingsTitle.TextColor3 = THEME.AccentCyan
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextSize = 11
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.AutoButtonColor = false
SettingsTitle.Parent = SettingsFrame
Instance.new("UICorner", SettingsTitle).CornerRadius = UDim.new(0, 12)

local CloseSettingsBtn = Instance.new("TextButton")
Stealth.RandomizeName(CloseSettingsBtn)
CloseSettingsBtn.Size = UDim2.new(0, 20, 0, 20)
CloseSettingsBtn.Position = UDim2.new(1, -25, 0.5, -10)
CloseSettingsBtn.BackgroundColor3 = THEME.AccentRed
CloseSettingsBtn.Text = "✕"
CloseSettingsBtn.TextColor3 = THEME.TextMain
CloseSettingsBtn.Font = Enum.Font.GothamBold
CloseSettingsBtn.TextSize = 10
CloseSettingsBtn.ZIndex = 10
CloseSettingsBtn.Parent = SettingsTitle
Instance.new("UICorner", CloseSettingsBtn).CornerRadius = UDim.new(0, 5)

local SettingsScroll = Instance.new("ScrollingFrame")
Stealth.RandomizeName(SettingsScroll)
SettingsScroll.Size = UDim2.new(1, 0, 1, -30)
SettingsScroll.Position = UDim2.new(0, 0, 0, 30)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 2
SettingsScroll.ScrollBarImageColor3 = THEME.AccentCyan
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsScroll.Parent = SettingsFrame

local SettingsList = Instance.new("UIListLayout")
SettingsList.Padding = UDim.new(0, 5)
SettingsList.SortOrder = Enum.SortOrder.LayoutOrder
SettingsList.Parent = SettingsScroll

local SettingsPadding = Instance.new("UIPadding")
SettingsPadding.PaddingTop = UDim.new(0, 6)
SettingsPadding.PaddingBottom = UDim.new(0, 10)
SettingsPadding.PaddingLeft = UDim.new(0, 8)
SettingsPadding.PaddingRight = UDim.new(0, 8)
SettingsPadding.Parent = SettingsScroll

-- ==========================================
-- 🎯 LÓGICA DE ESP OPTIMIZADA
-- ==========================================
local function applyHighlightToCharacter(plr, char)
    if not espEnabled or plr == LocalPlayer or not char then return end
    if espHighlights[plr] and espHighlights[plr].Parent then
        espHighlights[plr]:Destroy()
    end
    local hl = Instance.new("Highlight")
    Stealth.RandomizeName(hl)
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
    if espEnabled and plr.Character then
        applyHighlightToCharacter(plr, plr.Character)
    end
end

local function removeESP()
    for _, hl in pairs(espHighlights) do
        if hl and hl.Parent then hl:Destroy() end
    end
    espHighlights = {}
end

local function toggleESP(state)
    espEnabled = state
    setSwitchVisual(state, ESPSwitchBg, ESPSwitchKnob, ESPCard, ESPStroke, "ESP")

    if state then
        for _, plr in ipairs(Players:GetPlayers()) do
            setupPlayerESP(plr)
        end
    else
        removeESP()
    end
end

trackConn(Players.PlayerAdded:Connect(setupPlayerESP))
trackConn(Players.PlayerRemoving:Connect(function(plr)
    if espCharConnections[plr] then
        espCharConnections[plr]:Disconnect()
        espCharConnections[plr] = nil
    end
    if espHighlights[plr] then
        espHighlights[plr]:Destroy()
        espHighlights[plr] = nil
    end
end))

-- ==========================================
-- 👻 NOCLIP OPTIMIZADO
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
        if desc:IsA("BasePart") and not desc:FindFirstAncestorOfClass("Accessory") then
            table.insert(cachedCharParts, desc)
        end
    end)
end

if LocalPlayer.Character then
    cacheCharacterParts(LocalPlayer.Character)
end

local function toggleNoclip(state)
    noclipEnabled = state
    setSwitchVisual(state, NoclipSwitchBg, NoclipSwitchKnob, NoclipCard, NoclipStroke, "Noclip")

    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        if #cachedCharParts == 0 and LocalPlayer.Character then
            cacheCharacterParts(LocalPlayer.Character)
        end
        noclipConnection = Stealth.HideConnections(RunService.Stepped:Connect(function()
            for i = 1, #cachedCharParts do
                local part = cachedCharParts[i]
                if part and part.Parent and part.CanCollide then
                    part.CanCollide = false
                end
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

local function toggleInfJump(state)
    infJumpEnabled = state
    setSwitchVisual(state, InfJumpSwitchBg, InfJumpSwitchKnob, InfJumpCard, InfJumpStroke, "InfJump")
end

trackConn(UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end))

local function toggleDeleteMode(state)
    deleteModeEnabled = state
    setSwitchVisual(state, DeleteSwitchBg, DeleteSwitchKnob, DeleteCard, DeleteStroke, "DeleteMode")
end

local function RestoreMap()
    for _, data in ipairs(deletedPartsMemory) do
        if data.part and data.part.Parent then
            data.part.Transparency = data.trans
            data.part.CanCollide = data.collide
        end
    end
    deletedPartsMemory = {}
end

local function toggleFPXRay(state)
    fpXRayEnabled = state
    setSwitchVisual(state, FPXRaySwitchBg, FPXRaySwitchKnob, FPXRayCard, FPXRayStroke, "FPXRay")

    if state then
        if fpXRayConnection then fpXRayConnection:Disconnect() end
        fpXRayConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, data in ipairs(transparentParts) do
                if data.part and data.part.Parent then data.part.Transparency = data.trans end
            end
            transparentParts = {}

            local filterList = {char, Camera}
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then table.insert(filterList, p.Character) end
            end

            local rayOrigin = Camera.CFrame.Position
            local rayDirection = Camera.CFrame.LookVector * 250
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = filterList
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local currentOrigin = rayOrigin
            for i = 1, 5 do
                local result = Workspace:Raycast(currentOrigin, rayDirection, rayParams)
                if result and result.Instance then
                    local hitPart = result.Instance
                    if hitPart:IsA("BasePart") and not hitPart:FindFirstAncestorOfClass("Accessory") and not hitPart.Parent:FindFirstChildOfClass("Humanoid") then
                        if hitPart.Transparency < 0.7 then
                            table.insert(transparentParts, {part = hitPart, trans = hitPart.Transparency})
                            hitPart.Transparency = 0.7
                        end
                    end
                    currentOrigin = result.Position + rayDirection.Unit * 0.1
                else break end
            end
        end))
    else
        if fpXRayConnection then fpXRayConnection:Disconnect() end
        fpXRayConnection = nil
        for _, data in ipairs(transparentParts) do
            if data.part and data.part.Parent then data.part.Transparency = data.trans end
        end
        transparentParts = {}
    end
end

local function toggleFullbright(state)
    fullbrightEnabled = state
    setSwitchVisual(state, FullbrightSwitchBg, FullbrightSwitchKnob, FullbrightCard, FullbrightStroke, "Fullbright")
    if state then
        savedLighting.Ambient = Lighting.Ambient
        savedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        savedLighting.Brightness = Lighting.Brightness
        savedLighting.ClockTime = Lighting.ClockTime
        savedLighting.FogEnd = Lighting.FogEnd
        savedLighting.GlobalShadows = Lighting.GlobalShadows
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
    else
        if savedLighting.Ambient then
            Lighting.Ambient = savedLighting.Ambient
            Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
            Lighting.Brightness = savedLighting.Brightness
            Lighting.ClockTime = savedLighting.ClockTime
            Lighting.FogEnd = savedLighting.FogEnd
            Lighting.GlobalShadows = savedLighting.GlobalShadows
        end
    end
end

local function getMoveDirection()
    local c = LocalPlayer.Character
    if not c then return Vector3.zero end
    local humanoid = c:FindFirstChild("Humanoid")
    if not humanoid or humanoid.MoveDirection.Magnitude == 0 then return Vector3.zero end
    local move = Camera.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
    return (Camera.CFrame * CFrame.new(move.X, 0, move.Z)).Position - Camera.CFrame.Position
end

local toggleFreeCam

-- ==========================================
-- 🕊️ FLY MODERNO
-- ==========================================
local function cleanupFlyPhysics()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyLinearVel then flyLinearVel:Destroy(); flyLinearVel = nil end
    if flyAlignOri then flyAlignOri:Destroy(); flyAlignOri = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function toggleFly(state)
    flyEnabled = state
    setSwitchVisual(state, FlySwitchBg, FlySwitchKnob, FlyCard, FlyStroke, "Fly")

    if state then
        cleanupFlyPhysics()
        if freeCamEnabled and toggleFreeCam then toggleFreeCam(false) end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp then return end

        if hum then hum.PlatformStand = true end

        flyAttachment = Instance.new("Attachment")
        Stealth.RandomizeName(flyAttachment)
        flyAttachment.Parent = hrp

        flyLinearVel = Instance.new("LinearVelocity")
        Stealth.RandomizeName(flyLinearVel)
        flyLinearVel.Attachment0 = flyAttachment
        flyLinearVel.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        flyLinearVel.MaxForce = math.huge
        flyLinearVel.VectorVelocity = Vector3.zero
        flyLinearVel.Parent = hrp

        flyAlignOri = Instance.new("AlignOrientation")
        Stealth.RandomizeName(flyAlignOri)
        flyAlignOri.Attachment0 = flyAttachment
        flyAlignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
        flyAlignOri.RigidityEnabled = true
        flyAlignOri.CFrame = hrp.CFrame
        flyAlignOri.Parent = hrp

        flyConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            if not flyEnabled then return end
            local c = LocalPlayer.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") or not flyLinearVel or not flyAlignOri then return end

            local currentFlySpeed = flySpeed
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                currentFlySpeed = flySpeed * turboMultiplier
            end

            local moveVector = Vector3.zero
            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector = moveVector - Vector3.new(0, 1, 0) end
            else
                moveVector = getMoveDirection()
            end

            flyLinearVel.VectorVelocity = moveVector.Magnitude > 0 and (moveVector.Unit * currentFlySpeed) or Vector3.zero
            flyAlignOri.CFrame = Camera.CFrame
        end))
    else
        cleanupFlyPhysics()
    end
end

toggleFreeCam = function(state)
    freeCamEnabled = state
    setSwitchVisual(state, FreeCamSwitchBg, FreeCamSwitchKnob, FreeCamCard, FreeCamStroke, "FreeCam")

    if state then
        if flyEnabled then toggleFly(false) end
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 0
            char.Humanoid.JumpPower = 0
        end
        Camera.CameraType = Enum.CameraType.Scriptable
        local look = Camera.CFrame.LookVector
        camYaw = math.atan2(-look.X, -look.Z)
        camPitch = math.asin(look.Y)
        camPos = Camera.CFrame.Position

        if freeCamConnection then freeCamConnection:Disconnect() end
        freeCamConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function(dt)
            if not freeCamEnabled then return end
            local rot = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)
            local moveVector = Vector3.zero
            local currentFreeCamSpeed = freeCamSpeed
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then currentFreeCamSpeed = freeCamSpeed * turboMultiplier end

            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector = moveVector - Vector3.new(0, 1, 0) end
            else
                local c = LocalPlayer.Character
                if c then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if hum and hum.MoveDirection.Magnitude > 0.05 then
                        local localMove = Camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
                        moveVector = (rot.LookVector * -localMove.Z) + (rot.RightVector * localMove.X)
                    end
                end
            end
            if moveVector.Magnitude > 0 then camPos = camPos + (moveVector.Unit * currentFreeCamSpeed * dt) end
            Camera.CFrame = CFrame.new(camPos, camPos + rot.LookVector)
        end))

        if freeCamRotateConnection then freeCamRotateConnection:Disconnect() end
        freeCamRotateConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
            if not freeCamEnabled or gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Touch then
                camYaw = camYaw - input.Delta.X * 0.005
                camPitch = math.clamp(camPitch - input.Delta.Y * 0.005, math.rad(-89), math.rad(89))
            elseif input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                camYaw = camYaw - input.Delta.X * 0.005
                camPitch = math.clamp(camPitch - input.Delta.Y * 0.005, math.rad(-89), math.rad(89))
            end
        end)
    else
        if freeCamConnection then freeCamConnection:Disconnect() end
        if freeCamRotateConnection then freeCamRotateConnection:Disconnect() end
        freeCamConnection = nil
        freeCamRotateConnection = nil
        Camera.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
    end
end

trackConn(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    cacheCharacterParts(char)
    if noclipEnabled then toggleNoclip(true) end
    if invisicamEnabled then toggleInvisicam(true) end
    if fpXRayEnabled then toggleFPXRay(true) end
    if fullbrightEnabled then toggleFullbright(true) end
    if thirdPersonEnabled then toggleThirdPerson(true) end
    if flyEnabled then toggleFly(true) end
    if wallBangEnabled then toggleWallBang(true) end
end))

-- Arrastre de ventanas
local function makeDraggable(dragHandle, targetFrame, saveName)
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if saveName then savePosition(saveName, targetFrame.Position) end
                end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local vpSize = Camera.ViewportSize
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, math.max(0, vpSize.X - targetFrame.AbsoluteSize.X))
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, vpSize.Y - targetFrame.AbsoluteSize.Y))
            targetFrame.Position = UDim2.new(0, newX, 0, newY)
        end
    end))
end

makeDraggable(Title, MainFrame, "MainFrame")
makeDraggable(MiniBtn, MiniBtn, "MiniBtn")
makeDraggable(MiniTpBtn, MiniTpBtn, "MiniTpBtn")
makeDraggable(SettingsTitle, SettingsFrame, "SettingsFrame")
makeDraggable(PlayerWindowTitle, PlayerWindow, "PlayerWindow")

-- Botones Flotantes Rápidos (Neon Glass)
local function createQuickBtn(name, text, initialPos, toggleFunc)
    local btn = Instance.new("TextButton")
    Stealth.RandomizeName(btn)
    btn.Size = UDim2.new(0, 36, 0, 36)
    btn.Position = loadPosition("Quick_" .. name, initialPos)
    btn.BackgroundColor3 = THEME.BgMain
    btn.BackgroundTransparency = 0.15
    btn.Text = text
    btn.TextColor3 = THEME.TextMain
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.Visible = false
    btn.Active = true
    btn.Parent = ScreenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = applyNeonStroke(btn, THEME.AccentCyan, 0.45, 1.3)

    QuickButtons[name] = btn
    QuickButtonStrokes[name] = stroke

    local startTouchPos, isDragging, dragStartScreenPos, initialButtonPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            startTouchPos = input.Position; isDragging = false; dragStartScreenPos = input.Position; initialButtonPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and dragStartScreenPos then
            if (input.Position - dragStartScreenPos).Magnitude > 6 then
                isDragging = true
                local delta = input.Position - dragStartScreenPos
                local vpSize = Camera.ViewportSize
                local newX = math.clamp(initialButtonPos.X.Offset + delta.X, 0, math.max(0, vpSize.X - btn.AbsoluteSize.X))
                local newY = math.clamp(initialButtonPos.Y.Offset + delta.Y, 0, math.max(0, vpSize.Y - btn.AbsoluteSize.Y))
                btn.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if startTouchPos and not isDragging then
                toggleFunc()
            end
            if isDragging then
                local snapDistance = 35
                for otherName, otherBtn in pairs(QuickButtons) do
                    if otherName ~= name and otherBtn.Visible then
                        local diffX = math.abs(btn.Position.X.Offset - otherBtn.Position.X.Offset)
                        local diffY = math.abs(btn.Position.Y.Offset - otherBtn.Position.Y.Offset)
                        if diffX < snapDistance and diffY < 50 then btn.Position = UDim2.new(0, otherBtn.Position.X.Offset, 0, btn.Position.Y.Offset)
                        elseif diffY < snapDistance and diffX < 50 then btn.Position = UDim2.new(0, btn.Position.X.Offset, 0, otherBtn.Position.Y.Offset) end
                    end
                end
                savePosition("Quick_" .. name, btn.Position)
            end
            startTouchPos = nil; isDragging = false; dragStartScreenPos = nil
        end
    end)
end

if isTouchDevice then
    createQuickBtn("TPS", "TPS", UDim2.new(0, 60, 0, 100), function()
        tpEnabled = not tpEnabled
        setSwitchVisual(tpEnabled, TPSwitchBg, TPSwitchKnob, TPSwitchCard, TPSwitchStroke, "TPS")
    end)
end

createQuickBtn("Invisicam", "INV", UDim2.new(0, 100, 0, 100), function() toggleInvisicam(not invisicamEnabled) end)
createQuickBtn("FPXRay", "XRY", UDim2.new(0, 140, 0, 100), function() toggleFPXRay(not fpXRayEnabled) end)
createQuickBtn("ESP", "ESP", UDim2.new(0, 180, 0, 100), function() toggleESP(not espEnabled) end)
createQuickBtn("DeleteMode", "DEL", UDim2.new(0, 220, 0, 100), function() toggleDeleteMode(not deleteModeEnabled) end)
createQuickBtn("Noclip", "NOC", UDim2.new(0, 60, 0, 145), function() toggleNoclip(not noclipEnabled) end)
createQuickBtn("InfJump", "JMP", UDim2.new(0, 100, 0, 145), function() toggleInfJump(not infJumpEnabled) end)
createQuickBtn("Fly", "FLY", UDim2.new(0, 140, 0, 145), function() toggleFly(not flyEnabled) end)
createQuickBtn("FreeCam", "CAM", UDim2.new(0, 180, 0, 145), function() toggleFreeCam(not freeCamEnabled) end)
createQuickBtn("Fullbright", "LGT", UDim2.new(0, 220, 0, 145), function() toggleFullbright(not fullbrightEnabled) end)
createQuickBtn("ThirdPerson", "3PS", UDim2.new(0, 260, 0, 145), function() toggleThirdPerson(not thirdPersonEnabled) end)
createQuickBtn("WallBang", "WB", UDim2.new(0, 300, 0, 145), function() toggleWallBang(not wallBangEnabled) end)

-- Botón Restaurar Flotante (RST)
local RestoreQuickBtn = Instance.new("TextButton")
Stealth.RandomizeName(RestoreQuickBtn)
RestoreQuickBtn.Size = UDim2.new(0, 36, 0, 36)
RestoreQuickBtn.Position = loadPosition("Quick_Restore", UDim2.new(0, 60, 0, 190))
RestoreQuickBtn.BackgroundColor3 = THEME.BgMain
RestoreQuickBtn.BackgroundTransparency = 0.15
RestoreQuickBtn.Text = "RST"
RestoreQuickBtn.TextColor3 = THEME.AccentRed
RestoreQuickBtn.TextSize = 9
RestoreQuickBtn.Font = Enum.Font.GothamBold
RestoreQuickBtn.Visible = false
RestoreQuickBtn.Parent = ScreenGui
Instance.new("UICorner", RestoreQuickBtn).CornerRadius = UDim.new(1, 0)
local rstStroke = applyNeonStroke(RestoreQuickBtn, THEME.AccentRed, 0.35, 1.3)
QuickButtons["Restore"] = RestoreQuickBtn
QuickButtonStrokes["Restore"] = rstStroke

local rStartPos, rIsDragging, rDragStartScreen, rInitBtnPos
RestoreQuickBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rStartPos = input.Position; rIsDragging = false; rDragStartScreen = input.Position; rInitBtnPos = RestoreQuickBtn.Position
    end
end)
RestoreQuickBtn.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and rDragStartScreen then
        if (input.Position - rDragStartScreen).Magnitude > 6 then
            rIsDragging = true
            local delta = input.Position - rDragStartScreen
            local vpSize = Camera.ViewportSize
            local newX = math.clamp(rInitBtnPos.X.Offset + delta.X, 0, math.max(0, vpSize.X - RestoreQuickBtn.AbsoluteSize.X))
            local newY = math.clamp(rInitBtnPos.Y.Offset + delta.Y, 0, math.max(0, vpSize.Y - RestoreQuickBtn.AbsoluteSize.Y))
            RestoreQuickBtn.Position = UDim2.new(0, newX, 0, newY)
        end
    end
end)
RestoreQuickBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if rStartPos and not rIsDragging then
            RestoreMap()
            RestoreQuickBtn.TextColor3 = THEME.AccentGreen
            rstStroke.Color = THEME.AccentGreen
            task.wait(0.3)
            RestoreQuickBtn.TextColor3 = THEME.AccentRed
            rstStroke.Color = THEME.AccentRed
        end
        if rIsDragging then savePosition("Quick_Restore", RestoreQuickBtn.Position) end
        rStartPos, rIsDragging, rDragStartScreen, rInitBtnPos = nil, false, nil, nil
    end
end)

-- Resetear posiciones
ResetPositionsBtn.MouseButton1Click:Connect(function()
    local defaultPositions = {
        MainFrame = UDim2.new(0, 20, 0, 90),
        MiniBtn = UDim2.new(0, 15, 0, 200),
        MiniTpBtn = UDim2.new(0, 68, 0, 200),
        SettingsFrame = UDim2.new(0, 245, 0, 110),
        PlayerWindow = UDim2.new(0, 245, 0, 90),
        Quick_TPS = UDim2.new(0, 60, 0, 100),
        Quick_Invisicam = UDim2.new(0, 100, 0, 100),
        Quick_FPXRay = UDim2.new(0, 140, 0, 100),
        Quick_ESP = UDim2.new(0, 180, 0, 100),
        Quick_DeleteMode = UDim2.new(0, 220, 0, 100),
        Quick_Noclip = UDim2.new(0, 60, 0, 145),
        Quick_InfJump = UDim2.new(0, 100, 0, 145),
        Quick_Fly = UDim2.new(0, 140, 0, 145),
        Quick_FreeCam = UDim2.new(0, 180, 0, 145),
        Quick_Fullbright = UDim2.new(0, 220, 0, 145),
        Quick_ThirdPerson = UDim2.new(0, 260, 0, 145),
        Quick_WallBang = UDim2.new(0, 300, 0, 145),
        Quick_Restore = UDim2.new(0, 60, 0, 190)
    }

    MainFrame.Position = defaultPositions.MainFrame
    MiniBtn.Position = defaultPositions.MiniBtn
    MiniTpBtn.Position = defaultPositions.MiniTpBtn
    SettingsFrame.Position = defaultPositions.SettingsFrame
    PlayerWindow.Position = defaultPositions.PlayerWindow

    for key, pos in pairs(defaultPositions) do
        savePosition(key, pos)
        if string.sub(key, 1, 6) == "Quick_" then
            local qName = string.sub(key, 7)
            if QuickButtons[qName] then QuickButtons[qName].Position = pos end
        end
    end

    ResetPositionsBtn.BackgroundColor3 = THEME.AccentGreen
    task.wait(0.3)
    ResetPositionsBtn.BackgroundColor3 = THEME.AccentAmber
end)

-- ==========================================
-- CONFIGURACIÓN: VISIBILIDAD DE BOTONES, SLIDERS GUARDADOS Y KEYBINDS
-- ==========================================
local function createSectionTitle(titleText)
    local lbl = Instance.new("TextLabel")
    Stealth.RandomizeName(lbl)
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextColor3 = THEME.AccentCyan
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = SettingsScroll
end

local function createQuickConfig(text, btnName)
    local bg, knob, card, stroke = createNeonSwitch(SettingsScroll, "🔘", text)
    local isEnabled = loadButtonState(btnName)
    setSwitchVisual(isEnabled, bg, knob, card, stroke, nil)

    if QuickButtons[btnName] then
        QuickButtons[btnName].Visible = isEnabled and quickButtonsMaster
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local newState = not (bg.BackgroundColor3 == THEME.AccentGreen)
            setSwitchVisual(newState, bg, knob, card, stroke, nil)
            if QuickButtons[btnName] then
                QuickButtons[btnName].Visible = newState and quickButtonsMaster
            end
            saveButtonState(btnName, newState)
        end
    end)
end

local function createSliderSwitch(btnName, switchText, sliderText, saveKey, minVal, maxVal, currentVal, callback)
    local card = Instance.new("Frame")
    Stealth.RandomizeName(card)
    card.Size = UDim2.new(1, 0, 0, 54)
    card.BackgroundColor3 = THEME.BgCard
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.Parent = SettingsScroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
    local stroke = applyNeonStroke(card, THEME.AccentCyan, 0.78, 1)

    local titleLbl = Instance.new("TextLabel")
    Stealth.RandomizeName(titleLbl)
    titleLbl.Size = UDim2.new(0.74, 0, 0, 26)
    titleLbl.Position = UDim2.new(0, 9, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "🔘  " .. switchText
    titleLbl.TextColor3 = THEME.TextMain
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = card

    local bg = Instance.new("TextButton")
    Stealth.RandomizeName(bg)
    bg.Size = UDim2.new(0, 32, 0, 16)
    bg.Position = UDim2.new(1, -40, 0, 5)
    bg.BackgroundColor3 = THEME.SwitchOff
    bg.Text = ""
    bg.AutoButtonColor = false
    bg.Parent = card
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    Stealth.RandomizeName(knob)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isEnabled = loadButtonState(btnName)
    setSwitchVisual(isEnabled, bg, knob, card, stroke, nil)
    if QuickButtons[btnName] then
        QuickButtons[btnName].Visible = isEnabled and quickButtonsMaster
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local newState = not (bg.BackgroundColor3 == THEME.AccentGreen)
            setSwitchVisual(newState, bg, knob, card, stroke, nil)
            if QuickButtons[btnName] then
                QuickButtons[btnName].Visible = newState and quickButtonsMaster
            end
            saveButtonState(btnName, newState)
        end
    end)

    local clampedInit = math.clamp(currentVal, minVal, maxVal)
    local label = Instance.new("TextLabel")
    Stealth.RandomizeName(label)
    label.Size = UDim2.new(1, -18, 0, 12)
    label.Position = UDim2.new(0, 9, 0, 26)
    label.BackgroundTransparency = 1
    label.Text = sliderText .. ": " .. clampedInit
    label.TextColor3 = THEME.TextMuted
    label.Font = Enum.Font.Gotham
    label.TextSize = 8
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local barBg = Instance.new("TextButton")
    Stealth.RandomizeName(barBg)
    barBg.Size = UDim2.new(1, -18, 0, 6)
    barBg.Position = UDim2.new(0, 9, 0, 41)
    barBg.BackgroundColor3 = THEME.SwitchOff
    barBg.Text = ""
    barBg.AutoButtonColor = false
    barBg.Parent = card
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    Stealth.RandomizeName(fill)
    fill.Size = UDim2.new((clampedInit - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = THEME.AccentCyan
    fill.Parent = barBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local isSliding = false
    local latestVal = clampedInit
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
        end
    end)
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            isSliding = false
            saveData(saveKey, latestVal)
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local posX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(posX, 0, 1, 0)
            latestVal = math.floor(minVal + (maxVal - minVal) * posX)
            label.Text = sliderText .. ": " .. latestVal
            callback(latestVal)
        end
    end))
end

createSectionTitle("  MOSTRAR / OCULTAR BOTONES FLOTANTES")

if isTouchDevice then
    createQuickConfig("Botón TPS (Toque)", "TPS")
end
createQuickConfig("Botón Invisicam (INV)", "Invisicam")
createQuickConfig("Botón FP X-Ray (XRY)", "FPXRay")
createQuickConfig("Botón ESP (ESP)", "ESP")
createQuickConfig("Botón Borrador (DEL)", "DeleteMode")
createQuickConfig("Botón Noclip (NOC)", "Noclip")
createQuickConfig("Botón Inf Jump (JMP)", "InfJump")
createSliderSwitch("Fly", "Botón Fly (FLY)", "Velocidad Fly", "FlySpeed", 10, 300, flySpeed, function(val) flySpeed = val end)
createSliderSwitch("FreeCam", "Botón Free Cam (CAM)", "Velocidad Free Cam", "FreeCamSpeed", 10, 300, freeCamSpeed, function(val) freeCamSpeed = val end)
createQuickConfig("Botón Fullbright (LGT)", "Fullbright")
createQuickConfig("Botón Third Person (3PS)", "ThirdPerson")
createQuickConfig("Botón Wall-Bang (WB)", "WallBang")
createQuickConfig("Botón Restaurar (RST)", "Restore")

-- Conexión de Switches del Panel Principal
if isTouchDevice then
    TPSwitchBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            tpEnabled = not tpEnabled
            setSwitchVisual(tpEnabled, TPSwitchBg, TPSwitchKnob, TPSwitchCard, TPSwitchStroke, "TPS")
        end
    end)
end

SwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleInvisicam(not invisicamEnabled) end end)
FPXRaySwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFPXRay(not fpXRayEnabled) end end)
ESPSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleESP(not espEnabled) end end)
DeleteSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleDeleteMode(not deleteModeEnabled) end end)
NoclipSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleNoclip(not noclipEnabled) end end)
InfJumpSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleInfJump(not infJumpEnabled) end end)
FlySwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFly(not flyEnabled) end end)
FreeCamSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFreeCam(not freeCamEnabled) end end)
FullbrightSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFullbright(not fullbrightEnabled) end end)
ThirdPersonSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleThirdPerson(not thirdPersonEnabled) end end)
WallBangSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleWallBang(not wallBangEnabled) end end)

-- Ojo maestro
MasterQuickBtn.MouseButton1Click:Connect(function()
    quickButtonsMaster = not quickButtonsMaster
    MasterQuickBtn.BackgroundColor3 = quickButtonsMaster and THEME.AccentGreen or THEME.SwitchOff
    for name, btn in pairs(QuickButtons) do
        if quickButtonsMaster then
            if name == "TPS" and not isTouchDevice then
                btn.Visible = false
            else
                btn.Visible = loadButtonState(name)
            end
        else
            btn.Visible = false
        end
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniBtn.Visible = true end)
MiniBtn.Activated:Connect(function() MainFrame.Visible = true; MiniBtn.Visible = false end)
SettingsBtn.Activated:Connect(function() SettingsFrame.Visible = not SettingsFrame.Visible end)
CloseSettingsBtn.MouseButton1Click:Connect(function() SettingsFrame.Visible = false end)

-- Atajos de Teclado (PC)
createSectionTitle("  ATAJOS DE TECLADO (PC)")

local function createKeybindBox(text, keyName)
    local card = Instance.new("Frame")
    Stealth.RandomizeName(card)
    card.Size = UDim2.new(1, 0, 0, 24)
    card.BackgroundColor3 = THEME.BgCard
    card.BackgroundTransparency = 0.25
    card.Parent = SettingsScroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    applyNeonStroke(card, THEME.AccentCyan, 0.82, 1)

    local label = Instance.new("TextLabel")
    Stealth.RandomizeName(label)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 9, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.TextMain
    label.Font = Enum.Font.Gotham
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local box = Instance.new("TextButton")
    Stealth.RandomizeName(box)
    box.Size = UDim2.new(0, 44, 0, 18)
    box.Position = UDim2.new(1, -50, 0.5, -9)
    box.BackgroundColor3 = THEME.BgHeader
    box.Text = keybinds[keyName].Name
    box.TextColor3 = THEME.AccentCyan
    box.Font = Enum.Font.GothamBold
    box.TextSize = 8
    box.Parent = card
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    applyNeonStroke(box, THEME.AccentCyan, 0.5, 1)

    box.MouseButton1Click:Connect(function()
        if listeningFor then return end
        box.Text = "..."
        box.BackgroundColor3 = THEME.AccentAmber
        box.TextColor3 = THEME.TextMain
        listeningFor = keyName
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybinds[keyName] = input.KeyCode
                saveKeybind(keyName, input.KeyCode)
                box.Text = input.KeyCode.Name
                box.BackgroundColor3 = THEME.BgHeader
                box.TextColor3 = THEME.AccentCyan
                listeningFor = nil
                connection:Disconnect()
            end
        end)
    end)
end

if not isTouchDevice then createKeybindBox("Tecla TP (PC)", "Teleport") end
createKeybindBox("Tecla Invisicam", "Invisicam")
createKeybindBox("Tecla Noclip", "Noclip")
createKeybindBox("Tecla Fly", "Fly")
createKeybindBox("Tecla Free Cam", "FreeCam")
createKeybindBox("Tecla Fullbright", "Fullbright")
createKeybindBox("Tecla X-Ray", "XRay")
createKeybindBox("Tecla ESP", "ESP")
createKeybindBox("Tecla Inf Jump", "InfJump")
createKeybindBox("Tecla Wall-Bang", "WallBang")
createKeybindBox("Tecla Borrador", "Delete")
createKeybindBox("Tecla Restaurar", "Restore")

-- 🛑 BOTÓN UNLOAD (CERRAR Y LIMPIAR TODO EL SCRIPT)
createSectionTitle("  SISTEMA")
local UnloadBtn = Instance.new("TextButton")
Stealth.RandomizeName(UnloadBtn)
UnloadBtn.Size = UDim2.new(1, 0, 0, 26)
UnloadBtn.BackgroundColor3 = THEME.AccentRed
UnloadBtn.BackgroundTransparency = 0.15
UnloadBtn.Text = "🛑 Cerrar y Limpiar Hub (Unload)"
UnloadBtn.TextColor3 = THEME.TextMain
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 9
UnloadBtn.Parent = SettingsScroll
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 6)
applyNeonStroke(UnloadBtn, THEME.AccentRed, 0.2, 1)

UnloadBtn.MouseButton1Click:Connect(function()
    hubUnloaded = true
    if invisicamEnabled then toggleInvisicam(false) end
    if fpXRayEnabled then toggleFPXRay(false) end
    if espEnabled then toggleESP(false) end
    if noclipEnabled then toggleNoclip(false) end
    if flyEnabled then toggleFly(false) end
    if freeCamEnabled then toggleFreeCam(false) end
    if fullbrightEnabled then toggleFullbright(false) end
    if thirdPersonEnabled then toggleThirdPerson(false) end
    if wallBangEnabled then toggleWallBang(false) end
    if spectatingPlayer then resetSpectate() end
    RestoreMap()

    for _, conn in ipairs(allConnections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, conn in pairs(espCharConnections) do
        pcall(function() conn:Disconnect() end)
    end
    if wallBangConnection then pcall(function() wallBangConnection:Disconnect() end) end
    if ScreenGui then ScreenGui:Destroy() end
end)

-- Raycast y Controles
local function raycastIgnoringDeleted(origin, direction)
    local filter = {LocalPlayer.Character, Camera}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(filter, p.Character) end
    end
    for _, data in ipairs(deletedPartsMemory) do
        if data.part and data.part.Parent then table.insert(filter, data.part) end
    end
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
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
        end
    end
end

trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or listeningFor or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == keybinds.Invisicam then toggleInvisicam(not invisicamEnabled) end
        if input.KeyCode == keybinds.Noclip then toggleNoclip(not noclipEnabled) end
        if input.KeyCode == keybinds.Fly then toggleFly(not flyEnabled) end
        if input.KeyCode == keybinds.FreeCam then toggleFreeCam(not freeCamEnabled) end
        if input.KeyCode == keybinds.Fullbright then toggleFullbright(not fullbrightEnabled) end
        if input.KeyCode == keybinds.XRay then toggleFPXRay(not fpXRayEnabled) end
        if input.KeyCode == keybinds.ESP then toggleESP(not espEnabled) end
        if input.KeyCode == keybinds.InfJump then toggleInfJump(not infJumpEnabled) end
        if input.KeyCode == keybinds.WallBang then toggleWallBang(not wallBangEnabled) end
        if input.KeyCode == keybinds.Restore then RestoreMap() end
        if input.KeyCode == keybinds.Teleport then TeleportAt(Vector2.new(Mouse.X, Mouse.Y)) end
        if input.KeyCode == keybinds.Delete then DeletePartAt(Vector2.new(Mouse.X, Mouse.Y)) end
    end
end))

local function isOverGui(pos)
    if not ScreenGui or not ScreenGui.Parent then return false end
    for _, obj in ipairs(LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)) do
        if obj:IsDescendantOf(ScreenGui) then return true end
    end
    return false
end

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
