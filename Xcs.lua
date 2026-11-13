-- ==========================================
-- HUB: xcs (Neon Glass v3.0 - Comfort & UX)
-- Stealth Avanzado + Anti-Rubberband TP
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

-- 🎨 PALETA NEON GLASS REFINADA
local THEME = {
    BgMain      = Color3.fromRGB(11, 15, 24),
    BgHeader    = Color3.fromRGB(17, 23, 36),
    BgCard      = Color3.fromRGB(20, 27, 41),
    BgCardHover = Color3.fromRGB(27, 36, 54),
    BgCardOn    = Color3.fromRGB(14, 46, 38),
    AccentCyan  = Color3.fromRGB(0, 215, 255),
    AccentGreen = Color3.fromRGB(0, 225, 130),
    AccentRed   = Color3.fromRGB(240, 70, 90),
    AccentAmber = Color3.fromRGB(245, 160, 40),
    SwitchOff   = Color3.fromRGB(45, 55, 74),
    TextMain    = Color3.fromRGB(242, 246, 255),
    TextMuted   = Color3.fromRGB(140, 156, 182),
}

local TWEEN_FAST   = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- 🛡️ MÓDULO DE SIGILO (STEALTH)
local Stealth = {}
local _stealthSeed = tick() % 1000

local function stealthName()
    _stealthSeed += 1
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

-- 💾 GUARDADO Y CARGA
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

-- 📊 VARIABLES DE ESTADO
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
local quickButtonsLocked = loadData("QuickLocked", "false") == "true"
local hubUnloaded = false

local flySpeed = tonumber(loadData("FlySpeed", 50)) or 50
local freeCamSpeed = tonumber(loadData("FreeCamSpeed", 50)) or 50
local turboMultiplier = 2
local verticalTouchInput = 0 -- -1 bajar, 0 quieto, 1 subir

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
local categorizedCards = {}

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
}

-- ✨ HELPERS VISUALES
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

local function applyGlassGradient(parent, c1, c2, rotation)
    local grad = Instance.new("UIGradient")
    Stealth.RandomizeName(grad)
    grad.Color = ColorSequence.new(c1, c2)
    grad.Rotation = rotation or 90
    grad.Parent = parent
    return grad
end

local function animateWindow(frame, show)
    local scale = frame:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale")
        Stealth.RandomizeName(scale)
        scale.Parent = frame
    end
    if show then
        frame.Visible = true
        scale.Scale = 0.92
        TweenService:Create(scale, TWEEN_SMOOTH, { Scale = 1 }):Play()
    else
        local tw = TweenService:Create(scale, TWEEN_FAST, { Scale = 0.92 })
        tw:Play()
        tw.Completed:Once(function()
            if scale.Scale <= 0.93 then
                frame.Visible = false
            end
        end)
    end
end

-- 🛡️ INTERFAZ PROTEGIDA (NEON GLASS)
local ScreenGui = Instance.new("ScreenGui")
Stealth.HideInstance(ScreenGui)
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
local successParent = pcall(function() ScreenGui.Parent = CoreGui end)
if not successParent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- 🔔 SISTEMA DE NOTIFICACIONES TOAST
local ToastContainer = Instance.new("Frame")
Stealth.RandomizeName(ToastContainer)
ToastContainer.Size = UDim2.new(0, 240, 0, 30)
ToastContainer.Position = UDim2.new(0.5, -120, 0, -45)
ToastContainer.BackgroundColor3 = THEME.BgHeader
ToastContainer.BackgroundTransparency = 0.1
ToastContainer.BorderSizePixel = 0
ToastContainer.ZIndex = 50
ToastContainer.Parent = ScreenGui
Instance.new("UICorner", ToastContainer).CornerRadius = UDim.new(1, 0)
local ToastStroke = applyNeonStroke(ToastContainer, THEME.AccentCyan, 0.25, 1.3)

local ToastLabel = Instance.new("TextLabel")
Stealth.RandomizeName(ToastLabel)
ToastLabel.Size = UDim2.new(1, -20, 1, 0)
ToastLabel.Position = UDim2.new(0, 10, 0, 0)
ToastLabel.BackgroundTransparency = 1
ToastLabel.Text = ""
ToastLabel.TextColor3 = THEME.TextMain
ToastLabel.Font = Enum.Font.GothamBold
ToastLabel.TextSize = 11
ToastLabel.ZIndex = 51
ToastLabel.Parent = ToastContainer

local toastToken = 0
local function showToast(msg, accentColor)
    if hubUnloaded then return end
    toastToken += 1
    local myToken = toastToken
    ToastLabel.Text = msg
    ToastStroke.Color = accentColor or THEME.AccentCyan
    TweenService:Create(ToastContainer, TWEEN_SMOOTH, { Position = UDim2.new(0.5, -120, 0, 16) }):Play()
    task.delay(1.8, function()
        if myToken == toastToken and ToastContainer and ToastContainer.Parent then
            TweenService:Create(ToastContainer, TWEEN_FAST, { Position = UDim2.new(0.5, -120, 0, -45) }):Play()
        end
    end)
end

-- 🔘 BOTÓN FLOTANTE PRINCIPAL (xcs)
local MiniBtn = Instance.new("TextButton")
Stealth.RandomizeName(MiniBtn)
MiniBtn.Size = UDim2.new(0, 46, 0, 46)
MiniBtn.Position = loadPosition("MiniBtn", UDim2.new(0, 15, 0, 200))
MiniBtn.BackgroundColor3 = THEME.BgMain
MiniBtn.BackgroundTransparency = 0.1
MiniBtn.Text = "◈ xcs"
MiniBtn.TextColor3 = THEME.AccentCyan
MiniBtn.TextSize = 12
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Visible = true
MiniBtn.Parent = ScreenGui
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)
applyNeonStroke(MiniBtn, THEME.AccentCyan, 0.2, 1.6)
applyGlassGradient(MiniBtn, Color3.fromRGB(255,255,255), Color3.fromRGB(180,220,255), 45)

-- Botón flotante minimizado de TP Jugadores
local MiniTpBtn = Instance.new("TextButton")
Stealth.RandomizeName(MiniTpBtn)
MiniTpBtn.Size = UDim2.new(0, 44, 0, 44)
MiniTpBtn.Position = loadPosition("MiniTpBtn", UDim2.new(0, 68, 0, 200))
MiniTpBtn.BackgroundColor3 = THEME.BgMain
MiniTpBtn.BackgroundTransparency = 0.1
MiniTpBtn.Text = "👥 TP"
MiniTpBtn.TextColor3 = THEME.AccentCyan
MiniTpBtn.TextSize = 11
MiniTpBtn.Font = Enum.Font.GothamBold
MiniTpBtn.Visible = false
MiniTpBtn.Parent = ScreenGui
Instance.new("UICorner", MiniTpBtn).CornerRadius = UDim.new(1, 0)
applyNeonStroke(MiniTpBtn, THEME.AccentCyan, 0.25, 1.5)

-- ⬆️⬇️ CONTROLES DE ALTURA PARA MÓVIL (FLY / FREECAM)
local AltitudeFrame = Instance.new("Frame")
Stealth.RandomizeName(AltitudeFrame)
AltitudeFrame.Size = UDim2.new(0, 44, 0, 96)
AltitudeFrame.Position = UDim2.new(1, -60, 0.5, -48)
AltitudeFrame.BackgroundTransparency = 1
AltitudeFrame.Visible = false
AltitudeFrame.Parent = ScreenGui

local function createAltBtn(text, posY, dirVal)
    local b = Instance.new("TextButton")
    Stealth.RandomizeName(b)
    b.Size = UDim2.new(0, 44, 0, 44)
    b.Position = UDim2.new(0, 0, 0, posY)
    b.BackgroundColor3 = THEME.BgMain
    b.BackgroundTransparency = 0.15
    b.Text = text
    b.TextColor3 = THEME.AccentCyan
    b.Font = Enum.Font.GothamBold
    b.TextSize = 15
    b.Parent = AltitudeFrame
    Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
    local st = applyNeonStroke(b, THEME.AccentCyan, 0.25, 1.5)

    b.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            verticalTouchInput = dirVal
            b.BackgroundColor3 = THEME.BgCardOn
            st.Color = THEME.AccentGreen
        end
    end)
    b.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            if verticalTouchInput == dirVal then verticalTouchInput = 0 end
            b.BackgroundColor3 = THEME.BgMain
            st.Color = THEME.AccentCyan
        end
    end)
end
createAltBtn("▲", 0, 1)
createAltBtn("▼", 52, -1)

local function updateAltitudeVisibility()
    if isTouchDevice then
        AltitudeFrame.Visible = (flyEnabled or freeCamEnabled)
    else
        AltitudeFrame.Visible = false
    end
end

-- 🪟 VENTANA PRINCIPAL COMPACTA Y ERGONÓMICA
local MainFrame = Instance.new("Frame")
Stealth.HideInstance(MainFrame)
MainFrame.Size = UDim2.new(0, 240, 0, 385)
MainFrame.Position = loadPosition("MainFrame", UDim2.new(0, 20, 0, 85))
MainFrame.BackgroundColor3 = THEME.BgMain
MainFrame.BackgroundTransparency = 0.08
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)
applyNeonStroke(MainFrame, THEME.AccentCyan, 0.3, 1.4)

local Title = Instance.new("TextButton")
Stealth.RandomizeName(Title)
Title.Size = UDim2.new(1, 0, 0, 34)
Title.BackgroundColor3 = THEME.BgHeader
Title.BackgroundTransparency = 0.1
Title.Text = "  ◈ xcs Hub"
Title.TextColor3 = THEME.TextMain
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.AutoButtonColor = false
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 14)
applyGlassGradient(Title, Color3.fromRGB(255,255,255), Color3.fromRGB(200,225,255), 0)

local HeaderDivider = Instance.new("Frame")
Stealth.RandomizeName(HeaderDivider)
HeaderDivider.Size = UDim2.new(1, 0, 0, 1)
HeaderDivider.Position = UDim2.new(0, 0, 1, -1)
HeaderDivider.BackgroundColor3 = THEME.AccentCyan
HeaderDivider.BackgroundTransparency = 0.6
HeaderDivider.BorderSizePixel = 0
HeaderDivider.Parent = Title

local function createHeaderBtn(text, offsetX, bgColor, textColor, textSize)
    local btn = Instance.new("TextButton")
    Stealth.RandomizeName(btn)
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.Position = UDim2.new(1, offsetX, 0.5, -11)
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0.15
    btn.Text = text
    btn.TextColor3 = textColor or THEME.TextMain
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = textSize or 10
    btn.Parent = Title
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    applyNeonStroke(btn, bgColor, 0.35, 1)
    return btn
end

local LockQuickBtn          = createHeaderBtn(quickButtonsLocked and "🔒" or "🔓", -148, quickButtonsLocked and THEME.AccentAmber or THEME.BgCard, THEME.TextMain, 10)
local ResetPositionsBtn     = createHeaderBtn("🔄", -123, THEME.AccentAmber, THEME.TextMain, 10)
local MasterQuickBtn        = createHeaderBtn("👁️", -98,  THEME.AccentGreen, THEME.TextMain, 10)
local PlayerWindowToggleBtn = createHeaderBtn("TP", -73,  THEME.AccentCyan,  THEME.BgMain,   9)
local SettingsBtn           = createHeaderBtn("⚙️", -48,  THEME.BgCard,      THEME.TextMain, 10)
local MinimizeBtn           = createHeaderBtn("✕",  -25,  THEME.AccentRed,   THEME.TextMain, 10)

-- 🏷️ BARRA DE CATEGORÍAS RÁPIDAS
local TabBar = Instance.new("Frame")
Stealth.RandomizeName(TabBar)
TabBar.Size = UDim2.new(1, -16, 0, 24)
TabBar.Position = UDim2.new(0, 8, 0, 39)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.Padding = UDim.new(0, 4)
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Parent = TabBar

local tabButtons = {}
local activeCategory = "Todo"
local categories = {"Todo", "Mov", "Visual", "Mundo"}

local function filterCardsByCategory(cat)
    activeCategory = cat
    for cName, btn in pairs(tabButtons) do
        local isSelected = (cName == cat)
        TweenService:Create(btn, TWEEN_FAST, {
            BackgroundColor3 = isSelected and THEME.AccentCyan or THEME.BgCard,
            TextColor3 = isSelected and THEME.BgMain or THEME.TextMuted
        }):Play()
    end
    for _, item in ipairs(categorizedCards) do
        if item.forceHidden then
            item.card.Visible = false
        else
            item.card.Visible = (cat == "Todo" or item.category == cat)
        end
    end
end

for _, catName in ipairs(categories) do
    local tBtn = Instance.new("TextButton")
    Stealth.RandomizeName(tBtn)
    tBtn.Size = UDim2.new(0.235, 0, 1, 0)
    tBtn.BackgroundColor3 = (catName == "Todo") and THEME.AccentCyan or THEME.BgCard
    tBtn.Text = catName
    tBtn.TextColor3 = (catName == "Todo") and THEME.BgMain or THEME.TextMuted
    tBtn.Font = Enum.Font.GothamBold
    tBtn.TextSize = 9
    tBtn.Parent = TabBar
    Instance.new("UICorner", tBtn).CornerRadius = UDim.new(0, 6)
    tabButtons[catName] = tBtn
    tBtn.MouseButton1Click:Connect(function()
        filterCardsByCategory(catName)
    end)
end

local MainScroll = Instance.new("ScrollingFrame")
Stealth.RandomizeName(MainScroll)
MainScroll.Size = UDim2.new(1, 0, 1, -68)
MainScroll.Position = UDim2.new(0, 0, 0, 68)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 2
MainScroll.ScrollBarImageColor3 = THEME.AccentCyan
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
MainScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
MainScroll.Parent = MainFrame

local MainList = Instance.new("UIListLayout")
MainList.Padding = UDim.new(0, 6)
MainList.SortOrder = Enum.SortOrder.LayoutOrder
MainList.Parent = MainScroll

local MainPadding = Instance.new("UIPadding")
MainPadding.PaddingTop = UDim.new(0, 4)
MainPadding.PaddingBottom = UDim.new(0, 10)
MainPadding.PaddingLeft = UDim.new(0, 8)
MainPadding.PaddingRight = UDim.new(0, 8)
MainPadding.Parent = MainScroll

-- 🎛️ TARJETA NEON GLASS (CLICABLE EN TODA SU ÁREA)
local function createNeonSwitch(parent, icon, text, category, onToggle)
    local card = Instance.new("TextButton")
    Stealth.RandomizeName(card)
    card.Size = UDim2.new(1, 0, 0, 32)
    card.BackgroundColor3 = THEME.BgCard
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = parent
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
    local stroke = applyNeonStroke(card, THEME.AccentCyan, 0.78, 1)

    local label = Instance.new("TextLabel")
    Stealth.RandomizeName(label)
    label.Size = UDim2.new(0.75, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = (icon ~= "" and (icon .. "  ") or "") .. text
    label.TextColor3 = THEME.TextMain
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local bg = Instance.new("Frame")
    Stealth.RandomizeName(bg)
    bg.Size = UDim2.new(0, 34, 0, 18)
    bg.Position = UDim2.new(1, -44, 0.5, -9)
    bg.BackgroundColor3 = THEME.SwitchOff
    bg.Parent = card
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    Stealth.RandomizeName(knob)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    if category then
        table.insert(categorizedCards, { card = card, category = category, forceHidden = false })
    end

    if onToggle then
        card.Activated:Connect(onToggle)
    end

    return bg, knob, card, stroke
end

local function setSwitchVisual(state, bg, knob, card, stroke, quickKey)
    TweenService:Create(bg, TWEEN_FAST, {
        BackgroundColor3 = state and THEME.AccentGreen or THEME.SwitchOff
    }):Play()
    TweenService:Create(knob, TWEEN_FAST, {
        Position = state and UDim2.new(0, 18, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
    }):Play()

    if card then
        TweenService:Create(card, TWEEN_FAST, {
            BackgroundColor3 = state and THEME.BgCardOn or THEME.BgCard
        }):Play()
    end
    if stroke then
        TweenService:Create(stroke, TWEEN_FAST, {
            Color = state and THEME.AccentGreen or THEME.AccentCyan,
            Transparency = state and 0.3 or 0.78
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

-- Declaración anticipada de funciones toggle
local toggleInvisicam, toggleThirdPerson, toggleESP, toggleNoclip, toggleInfJump, toggleDeleteMode, toggleFPXRay, toggleFullbright, toggleFly, toggleFreeCam

local TPSwitchBg, TPSwitchKnob, TPSwitchCard, TPSwitchStroke = createNeonSwitch(MainScroll, "📍", "TPS (Toque)", "Mov", function()
    tpEnabled = not tpEnabled
    setSwitchVisual(tpEnabled, TPSwitchBg, TPSwitchKnob, TPSwitchCard, TPSwitchStroke, "TPS")
    showToast(tpEnabled and "📍 TPS activado" or "📍 TPS desactivado", tpEnabled and THEME.AccentGreen or THEME.TextMuted)
end)
if not isTouchDevice then
    TPSwitchCard.Visible = false
    for _, item in ipairs(categorizedCards) do
        if item.card == TPSwitchCard then item.forceHidden = true end
    end
end

local SwitchBg, SwitchKnob, SwitchCard, SwitchStroke = createNeonSwitch(MainScroll, "👁️", "Invisicam", "Visual", function() toggleInvisicam(not invisicamEnabled) end)
local FPXRaySwitchBg, FPXRaySwitchKnob, FPXRayCard, FPXRayStroke = createNeonSwitch(MainScroll, "🧱", "FP X-Ray", "Visual", function() toggleFPXRay(not fpXRayEnabled) end)
local ESPSwitchBg, ESPSwitchKnob, ESPCard, ESPStroke = createNeonSwitch(MainScroll, "🎯", "ESP Jugadores", "Visual", function() toggleESP(not espEnabled) end)
local FullbrightSwitchBg, FullbrightSwitchKnob, FullbrightCard, FullbrightStroke = createNeonSwitch(MainScroll, "☀️", "Fullbright", "Visual", function() toggleFullbright(not fullbrightEnabled) end)
local ThirdPersonSwitchBg, ThirdPersonSwitchKnob, ThirdPersonCard, ThirdPersonStroke = createNeonSwitch(MainScroll, "🧍", "Third Person", "Visual", function() toggleThirdPerson(not thirdPersonEnabled) end)

local NoclipSwitchBg, NoclipSwitchKnob, NoclipCard, NoclipStroke = createNeonSwitch(MainScroll, "👻", "Noclip", "Mov", function() toggleNoclip(not noclipEnabled) end)
local InfJumpSwitchBg, InfJumpSwitchKnob, InfJumpCard, InfJumpStroke = createNeonSwitch(MainScroll, "⚡", "Infinite Jump", "Mov", function() toggleInfJump(not infJumpEnabled) end)
local FlySwitchBg, FlySwitchKnob, FlyCard, FlyStroke = createNeonSwitch(MainScroll, "🕊️", "Fly", "Mov", function() toggleFly(not flyEnabled) end)
local FreeCamSwitchBg, FreeCamSwitchKnob, FreeCamCard, FreeCamStroke = createNeonSwitch(MainScroll, "🎥", "Free Cam", "Mov", function() toggleFreeCam(not freeCamEnabled) end)

local DeleteSwitchBg, DeleteSwitchKnob, DeleteCard, DeleteStroke = createNeonSwitch(MainScroll, "🗑️", "Borrador Paredes", "Mundo", function() toggleDeleteMode(not deleteModeEnabled) end)

-- Botón de acción directa para Restaurar Mapa dentro del menú
local RestoreActionCard = Instance.new("TextButton")
Stealth.RandomizeName(RestoreActionCard)
RestoreActionCard.Size = UDim2.new(1, 0, 0, 30)
RestoreActionCard.BackgroundColor3 = THEME.BgHeader
RestoreActionCard.Text = "↩️  Restaurar Mapa Borrado"
RestoreActionCard.TextColor3 = THEME.AccentCyan
RestoreActionCard.Font = Enum.Font.GothamBold
RestoreActionCard.TextSize = 10
RestoreActionCard.Parent = MainScroll
Instance.new("UICorner", RestoreActionCard).CornerRadius = UDim.new(0, 8)
applyNeonStroke(RestoreActionCard, THEME.AccentCyan, 0.5, 1)
table.insert(categorizedCards, { card = RestoreActionCard, category = "Mundo", forceHidden = false })

-- 🎥 LÓGICA DE INVISICAM Y THIRD PERSON
toggleInvisicam = function(state)
    invisicamEnabled = state
    setSwitchVisual(state, SwitchBg, SwitchKnob, SwitchCard, SwitchStroke, "Invisicam")
    showToast(state and "👁️ Invisicam activado" or "👁️ Invisicam desactivado", state and THEME.AccentGreen or THEME.TextMuted)

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

toggleThirdPerson = function(state)
    thirdPersonEnabled = state
    setSwitchVisual(state, ThirdPersonSwitchBg, ThirdPersonSwitchKnob, ThirdPersonCard, ThirdPersonStroke, "ThirdPerson")
    showToast(state and "🧍 Third Person activado" or "🧍 Third Person desactivado", state and THEME.AccentGreen or THEME.TextMuted)

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

-- 🚀 SISTEMA DE TELEPORT ANTI-RUBBERBAND
local function SafeTeleport(targetCFrame)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        char:PivotTo(targetCFrame)
        task.spawn(function()
            task.wait()
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                char:PivotTo(targetCFrame)
            end
        end)
    end
end

-- 👥 VENTANA DE TP A JUGADORES
local PlayerWindow = Instance.new("Frame")
Stealth.HideInstance(PlayerWindow)
PlayerWindow.Size = UDim2.new(0, 230, 0, 340)
PlayerWindow.Position = loadPosition("PlayerWindow", UDim2.new(0, 270, 0, 85))
PlayerWindow.BackgroundColor3 = THEME.BgMain
PlayerWindow.BackgroundTransparency = 0.08
PlayerWindow.BorderSizePixel = 0
PlayerWindow.Visible = false
PlayerWindow.Parent = ScreenGui
Instance.new("UICorner", PlayerWindow).CornerRadius = UDim.new(0, 14)
applyNeonStroke(PlayerWindow, THEME.AccentCyan, 0.3, 1.4)

local PlayerWindowTitle = Instance.new("TextButton")
Stealth.RandomizeName(PlayerWindowTitle)
PlayerWindowTitle.Size = UDim2.new(1, 0, 0, 32)
PlayerWindowTitle.BackgroundColor3 = THEME.BgHeader
PlayerWindowTitle.BackgroundTransparency = 0.1
PlayerWindowTitle.Text = "  👥 TP Jugadores"
PlayerWindowTitle.TextColor3 = THEME.AccentCyan
PlayerWindowTitle.Font = Enum.Font.GothamBold
PlayerWindowTitle.TextSize = 11
PlayerWindowTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerWindowTitle.AutoButtonColor = false
PlayerWindowTitle.Parent = PlayerWindow
Instance.new("UICorner", PlayerWindowTitle).CornerRadius = UDim.new(0, 14)

local PlayerWindowMinBtn = Instance.new("TextButton")
Stealth.RandomizeName(PlayerWindowMinBtn)
PlayerWindowMinBtn.Size = UDim2.new(0, 20, 0, 20)
PlayerWindowMinBtn.Position = UDim2.new(1, -48, 0.5, -10)
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
PlayerWindowCloseBtn.Size = UDim2.new(0, 20, 0, 20)
PlayerWindowCloseBtn.Position = UDim2.new(1, -24, 0.5, -10)
PlayerWindowCloseBtn.BackgroundColor3 = THEME.AccentRed
PlayerWindowCloseBtn.Text = "✕"
PlayerWindowCloseBtn.TextColor3 = THEME.TextMain
PlayerWindowCloseBtn.TextSize = 9
PlayerWindowCloseBtn.Font = Enum.Font.GothamBold
PlayerWindowCloseBtn.Parent = PlayerWindowTitle
Instance.new("UICorner", PlayerWindowCloseBtn).CornerRadius = UDim.new(0, 5)

local PlayerWindowScroll = Instance.new("ScrollingFrame")
Stealth.RandomizeName(PlayerWindowScroll)
PlayerWindowScroll.Size = UDim2.new(1, 0, 1, -34)
PlayerWindowScroll.Position = UDim2.new(0, 0, 0, 34)
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
searchBox.LayoutOrder = 1
searchBox.Size = UDim2.new(1, 0, 0, 26)
searchBox.BackgroundColor3 = THEME.BgCard
searchBox.BackgroundTransparency = 0.1
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Buscar jugador..."
searchBox.PlaceholderColor3 = THEME.TextMuted
searchBox.TextColor3 = THEME.TextMain
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.ClearTextOnFocus = false
searchBox.Parent = PlayerWindowScroll
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 7)
applyNeonStroke(searchBox, THEME.AccentCyan, 0.6, 1)

local ResetCamSelfBtn = Instance.new("TextButton")
Stealth.RandomizeName(ResetCamSelfBtn)
ResetCamSelfBtn.LayoutOrder = 2
ResetCamSelfBtn.Size = UDim2.new(1, 0, 0, 24)
ResetCamSelfBtn.BackgroundColor3 = THEME.BgCardOn
ResetCamSelfBtn.Text = "🏠 Volver cámara a mí"
ResetCamSelfBtn.TextColor3 = THEME.AccentGreen
ResetCamSelfBtn.Font = Enum.Font.GothamBold
ResetCamSelfBtn.TextSize = 10
ResetCamSelfBtn.Visible = false
ResetCamSelfBtn.Parent = PlayerWindowScroll
Instance.new("UICorner", ResetCamSelfBtn).CornerRadius = UDim.new(0, 7)
applyNeonStroke(ResetCamSelfBtn, THEME.AccentGreen, 0.35, 1)

local PlayerListContainer = Instance.new("Frame")
Stealth.RandomizeName(PlayerListContainer)
PlayerListContainer.LayoutOrder = 3
PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
PlayerListContainer.AutomaticSize = Enum.AutomaticSize.Y
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.Parent = PlayerWindowScroll

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 5)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerListContainer

local function teleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        SafeTeleport(targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3.5, 0))
        showToast("⚡ TP hacia " .. targetPlayer.DisplayName, THEME.AccentCyan)
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
        showToast("🏠 Cámara restaurada", THEME.AccentGreen)
    else
        spectatingPlayer = targetPlayer
        ResetCamSelfBtn.Visible = true
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
            showToast("👁️ Viendo a " .. targetPlayer.DisplayName, THEME.AccentCyan)
        end
    end
end

ResetCamSelfBtn.MouseButton1Click:Connect(function()
    resetSpectate()
    showToast("🏠 Cámara restaurada", THEME.AccentGreen)
end)

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
            pcall(function() isFriend = LocalPlayer:IsFriendsWith(p.UserId) end)
            local formattedName = (isFriend and "⭐ " or "") .. displayName

            if filterQuery == "" or string.find(string.lower(displayName), string.lower(filterQuery)) or string.find(string.lower(userName), string.lower(filterQuery)) then
                local isSpec = (spectatingPlayer == p)
                local row = Instance.new("Frame")
                Stealth.RandomizeName(row)
                row.LayoutOrder = isFriend and 1 or 2
                row.Size = UDim2.new(1, 0, 0, 34)
                row.BackgroundColor3 = isSpec and THEME.BgCardOn or THEME.BgCard
                row.BackgroundTransparency = 0.2
                row.Parent = PlayerListContainer
                Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
                applyNeonStroke(row, isSpec and THEME.AccentGreen or (isFriend and Color3.fromRGB(255, 215, 0) or THEME.AccentCyan), isSpec and 0.3 or 0.78, 1)

                local thumbImg = Instance.new("ImageLabel")
                Stealth.RandomizeName(thumbImg)
                thumbImg.Size = UDim2.new(0, 24, 0, 24)
                thumbImg.Position = UDim2.new(0, 5, 0.5, -12)
                thumbImg.BackgroundColor3 = THEME.BgHeader
                thumbImg.BorderSizePixel = 0
                thumbImg.Image = ""
                thumbImg.Parent = row
                Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)

                task.spawn(function()
                    local userId = p.UserId
                    local success, url = pcall(function()
                        return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                    end)
                    local finalUrl = (success and url and url ~= "") and url or ("https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png")
                    if thumbImg and thumbImg.Parent then thumbImg.Image = finalUrl end
                end)

                local pNameLabel = Instance.new("TextLabel")
                Stealth.RandomizeName(pNameLabel)
                pNameLabel.Size = UDim2.new(0.46, 0, 0, 15)
                pNameLabel.Position = UDim2.new(0, 34, 0, 3)
                pNameLabel.BackgroundTransparency = 1
                pNameLabel.Text = formattedName
                pNameLabel.TextColor3 = isFriend and Color3.fromRGB(255, 215, 0) or THEME.TextMain
                pNameLabel.Font = Enum.Font.GothamBold
                pNameLabel.TextSize = 10
                pNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                pNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                pNameLabel.Parent = row

                local distLabel = Instance.new("TextLabel")
                Stealth.RandomizeName(distLabel)
                distLabel.Size = UDim2.new(0.46, 0, 0, 12)
                distLabel.Position = UDim2.new(0, 34, 0, 18)
                distLabel.BackgroundTransparency = 1
                distLabel.Text = "--- m"
                distLabel.TextColor3 = THEME.TextMuted
                distLabel.Font = Enum.Font.Gotham
                distLabel.TextSize = 9
                distLabel.TextXAlignment = Enum.TextXAlignment.Left
                distLabel.Parent = row
                playerDistanceLabels[p] = distLabel

                local tpBtn = Instance.new("TextButton")
                Stealth.RandomizeName(tpBtn)
                tpBtn.Size = UDim2.new(0, 26, 0, 20)
                tpBtn.Position = UDim2.new(1, -62, 0.5, -10)
                tpBtn.BackgroundColor3 = THEME.AccentCyan
                tpBtn.Text = "TP"
                tpBtn.TextColor3 = THEME.BgMain
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.TextSize = 9
                tpBtn.Parent = row
                Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 5)
                tpBtn.MouseButton1Click:Connect(function() teleportToPlayer(p) end)

                local viewBtn = Instance.new("TextButton")
                Stealth.RandomizeName(viewBtn)
                viewBtn.Size = UDim2.new(0, 30, 0, 20)
                viewBtn.Position = UDim2.new(1, -34, 0.5, -10)
                viewBtn.BackgroundColor3 = isSpec and THEME.AccentGreen or THEME.SwitchOff
                viewBtn.Text = "VIEW"
                viewBtn.TextColor3 = isSpec and THEME.BgMain or THEME.TextMain
                viewBtn.Font = Enum.Font.GothamBold
                viewBtn.TextSize = 8
                viewBtn.Parent = row
                Instance.new("UICorner", viewBtn).CornerRadius = UDim.new(0, 5)
                viewBtn.MouseButton1Click:Connect(function()
                    spectatePlayer(p)
                    refreshPlayerList()
                end)
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

PlayerWindowMinBtn.MouseButton1Click:Connect(function() animateWindow(PlayerWindow, false); MiniTpBtn.Visible = true end)
PlayerWindowCloseBtn.MouseButton1Click:Connect(function() animateWindow(PlayerWindow, false); MiniTpBtn.Visible = false end)
PlayerWindowToggleBtn.MouseButton1Click:Connect(function()
    local nextState = not PlayerWindow.Visible
    animateWindow(PlayerWindow, nextState)
    MiniTpBtn.Visible = false
end)
MiniTpBtn.Activated:Connect(function() animateWindow(PlayerWindow, true); MiniTpBtn.Visible = false end)

-- ⚙️ VENTANA DE CONFIGURACIÓN
local SettingsFrame = Instance.new("Frame")
Stealth.HideInstance(SettingsFrame)
SettingsFrame.Size = UDim2.new(0, 235, 0, 365)
SettingsFrame.Position = loadPosition("SettingsFrame", UDim2.new(0, 270, 0, 105))
SettingsFrame.BackgroundColor3 = THEME.BgMain
SettingsFrame.BackgroundTransparency = 0.08
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = ScreenGui
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 14)
applyNeonStroke(SettingsFrame, THEME.AccentCyan, 0.3, 1.4)

local SettingsTitle = Instance.new("TextButton")
Stealth.RandomizeName(SettingsTitle)
SettingsTitle.Size = UDim2.new(1, 0, 0, 32)
SettingsTitle.BackgroundColor3 = THEME.BgHeader
SettingsTitle.BackgroundTransparency = 0.1
SettingsTitle.Text = "  ⚙️ Ajustes y Botones"
SettingsTitle.TextColor3 = THEME.AccentCyan
SettingsTitle.Font = Enum.Font.GothamBold
SettingsTitle.TextSize = 11
SettingsTitle.TextXAlignment = Enum.TextXAlignment.Left
SettingsTitle.AutoButtonColor = false
SettingsTitle.Parent = SettingsFrame
Instance.new("UICorner", SettingsTitle).CornerRadius = UDim.new(0, 14)

local CloseSettingsBtn = Instance.new("TextButton")
Stealth.RandomizeName(CloseSettingsBtn)
CloseSettingsBtn.Size = UDim2.new(0, 22, 0, 22)
CloseSettingsBtn.Position = UDim2.new(1, -27, 0.5, -11)
CloseSettingsBtn.BackgroundColor3 = THEME.AccentRed
CloseSettingsBtn.Text = "✕"
CloseSettingsBtn.TextColor3 = THEME.TextMain
CloseSettingsBtn.Font = Enum.Font.GothamBold
CloseSettingsBtn.TextSize = 10
CloseSettingsBtn.ZIndex = 10
CloseSettingsBtn.Parent = SettingsTitle
Instance.new("UICorner", CloseSettingsBtn).CornerRadius = UDim.new(0, 6)

local SettingsScroll = Instance.new("ScrollingFrame")
Stealth.RandomizeName(SettingsScroll)
SettingsScroll.Size = UDim2.new(1, 0, 1, -34)
SettingsScroll.Position = UDim2.new(0, 0, 0, 34)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 2
SettingsScroll.ScrollBarImageColor3 = THEME.AccentCyan
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsScroll.Parent = SettingsFrame

local SettingsList = Instance.new("UIListLayout")
SettingsList.Padding = UDim.new(0, 6)
SettingsList.SortOrder = Enum.SortOrder.LayoutOrder
SettingsList.Parent = SettingsScroll

local SettingsPadding = Instance.new("UIPadding")
SettingsPadding.PaddingTop = UDim.new(0, 6)
SettingsPadding.PaddingBottom = UDim.new(0, 10)
SettingsPadding.PaddingLeft = UDim.new(0, 8)
SettingsPadding.PaddingRight = UDim.new(0, 8)
SettingsPadding.Parent = SettingsScroll

-- 🎯 LÓGICA DE ESP
local function applyHighlightToCharacter(plr, char)
    if not espEnabled or plr == LocalPlayer or not char then return end
    if espHighlights[plr] and espHighlights[plr].Parent then
        espHighlights[plr]:Destroy()
    end
    local hl = Instance.new("Highlight")
    Stealth.RandomizeName(hl)
    hl.FillColor = Color3.fromRGB(255, 0, 85)
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

toggleESP = function(state)
    espEnabled = state
    setSwitchVisual(state, ESPSwitchBg, ESPSwitchKnob, ESPCard, ESPStroke, "ESP")
    showToast(state and "🎯 ESP activado" or "🎯 ESP desactivado", state and THEME.AccentGreen or THEME.TextMuted)

    if state then
        for _, plr in ipairs(Players:GetPlayers()) do setupPlayerESP(plr) end
    else
        removeESP()
    end
end

trackConn(Players.PlayerAdded:Connect(setupPlayerESP))
trackConn(Players.PlayerRemoving:Connect(function(plr)
    if espCharConnections[plr] then espCharConnections[plr]:Disconnect(); espCharConnections[plr] = nil end
    if espHighlights[plr] then espHighlights[plr]:Destroy(); espHighlights[plr] = nil end
end))

-- 👻 NOCLIP
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

if LocalPlayer.Character then cacheCharacterParts(LocalPlayer.Character) end

toggleNoclip = function(state)
    noclipEnabled = state
    setSwitchVisual(state, NoclipSwitchBg, NoclipSwitchKnob, NoclipCard, NoclipStroke, "Noclip")
    showToast(state and "👻 Noclip activado" or "👻 Noclip desactivado", state and THEME.AccentGreen or THEME.TextMuted)

    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        if #cachedCharParts == 0 and LocalPlayer.Character then cacheCharacterParts(LocalPlayer.Character) end
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

toggleInfJump = function(state)
    infJumpEnabled = state
    setSwitchVisual(state, InfJumpSwitchBg, InfJumpSwitchKnob, InfJumpCard, InfJumpStroke, "InfJump")
    showToast(state and "⚡ Infinite Jump activado" or "⚡ Infinite Jump desactivado", state and THEME.AccentGreen or THEME.TextMuted)
end

trackConn(UserInputService.JumpRequest:Connect(function()
    if infJumpEnabled then
        local char = LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end))

toggleDeleteMode = function(state)
    deleteModeEnabled = state
    setSwitchVisual(state, DeleteSwitchBg, DeleteSwitchKnob, DeleteCard, DeleteStroke, "DeleteMode")
    showToast(state and "🗑️ Borrador activado" or "🗑️ Borrador desactivado", state and THEME.AccentGreen or THEME.TextMuted)
end

local function RestoreMap(silent)
    local count = #deletedPartsMemory
    for _, data in ipairs(deletedPartsMemory) do
        if data.part and data.part.Parent then
            data.part.Transparency = data.trans
            data.part.CanCollide = data.collide
        end
    end
    deletedPartsMemory = {}
    if not silent then
        showToast("↩️ Mapa restaurado (" .. count .. " piezas)", THEME.AccentCyan)
    end
end

RestoreActionCard.MouseButton1Click:Connect(function() RestoreMap(false) end)

toggleFPXRay = function(state)
    fpXRayEnabled = state
    setSwitchVisual(state, FPXRaySwitchBg, FPXRaySwitchKnob, FPXRayCard, FPXRayStroke, "FPXRay")
    showToast(state and "🧱 FP X-Ray activado" or "🧱 FP X-Ray desactivado", state and THEME.AccentGreen or THEME.TextMuted)

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

toggleFullbright = function(state)
    fullbrightEnabled = state
    setSwitchVisual(state, FullbrightSwitchBg, FullbrightSwitchKnob, FullbrightCard, FullbrightStroke, "Fullbright")
    showToast(state and "☀️ Fullbright activado" or "☀️ Fullbright desactivado", state and THEME.AccentGreen or THEME.TextMuted)

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

-- 🕊️ FLY MODERNO
local function cleanupFlyPhysics()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    if flyLinearVel then flyLinearVel:Destroy(); flyLinearVel = nil end
    if flyAlignOri then flyAlignOri:Destroy(); flyAlignOri = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

toggleFly = function(state)
    flyEnabled = state
    setSwitchVisual(state, FlySwitchBg, FlySwitchKnob, FlyCard, FlyStroke, "Fly")
    updateAltitudeVisibility()
    showToast(state and "🕊️ Fly activado" or "🕊️ Fly desactivado", state and THEME.AccentGreen or THEME.TextMuted)

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
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector -= Vector3.new(0, 1, 0) end
            else
                moveVector = getMoveDirection() + Vector3.new(0, verticalTouchInput, 0)
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
    updateAltitudeVisibility()
    showToast(state and "🎥 Free Cam activada" or "🎥 Free Cam desactivada", state and THEME.AccentGreen or THEME.TextMuted)

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
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector -= Vector3.new(0, 1, 0) end
            else
                local c = LocalPlayer.Character
                if c then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if hum and hum.MoveDirection.Magnitude > 0.05 then
                        local localMove = Camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
                        moveVector = (rot.LookVector * -localMove.Z) + (rot.RightVector * localMove.X)
                    end
                end
                moveVector += Vector3.new(0, verticalTouchInput, 0)
            end
            if moveVector.Magnitude > 0 then camPos += (moveVector.Unit * currentFreeCamSpeed * dt) end
            Camera.CFrame = CFrame.new(camPos, camPos + rot.LookVector)
        end))

        if freeCamRotateConnection then freeCamRotateConnection:Disconnect() end
        freeCamRotateConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
            if not freeCamEnabled or gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Touch then
                camYaw -= input.Delta.X * 0.005
                camPitch = math.clamp(camPitch - input.Delta.Y * 0.005, math.rad(-89), math.rad(89))
            elseif input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                camYaw -= input.Delta.X * 0.005
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
end))

-- 🖱️ ARRASTRE DE VENTANAS
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

-- 🔘 BOTONES FLOTANTES RÁPIDOS (CON BLOQUEO DE ARRASTRE)
local function createQuickBtn(name, text, initialPos, toggleFunc)
    local btn = Instance.new("TextButton")
    Stealth.RandomizeName(btn)
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = loadPosition("Quick_" .. name, initialPos)
    btn.BackgroundColor3 = THEME.BgMain
    btn.BackgroundTransparency = 0.12
    btn.Text = text
    btn.TextColor3 = THEME.TextMain
    btn.TextSize = 10
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
        if quickButtonsLocked then return end
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
            if isDragging and not quickButtonsLocked then
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
        showToast(tpEnabled and "📍 TPS activado" or "📍 TPS desactivado", tpEnabled and THEME.AccentGreen or THEME.TextMuted)
    end)
end

createQuickBtn("Invisicam", "INV", UDim2.new(0, 106, 0, 100), function() toggleInvisicam(not invisicamEnabled) end)
createQuickBtn("FPXRay", "XRY", UDim2.new(0, 152, 0, 100), function() toggleFPXRay(not fpXRayEnabled) end)
createQuickBtn("ESP", "ESP", UDim2.new(0, 198, 0, 100), function() toggleESP(not espEnabled) end)
createQuickBtn("DeleteMode", "DEL", UDim2.new(0, 244, 0, 100), function() toggleDeleteMode(not deleteModeEnabled) end)
createQuickBtn("Noclip", "NOC", UDim2.new(0, 60, 0, 148), function() toggleNoclip(not noclipEnabled) end)
createQuickBtn("InfJump", "JMP", UDim2.new(0, 106, 0, 148), function() toggleInfJump(not infJumpEnabled) end)
createQuickBtn("Fly", "FLY", UDim2.new(0, 152, 0, 148), function() toggleFly(not flyEnabled) end)
createQuickBtn("FreeCam", "CAM", UDim2.new(0, 198, 0, 148), function() toggleFreeCam(not freeCamEnabled) end)
createQuickBtn("Fullbright", "LGT", UDim2.new(0, 244, 0, 148), function() toggleFullbright(not fullbrightEnabled) end)
createQuickBtn("ThirdPerson", "3PS", UDim2.new(0, 290, 0, 148), function() toggleThirdPerson(not thirdPersonEnabled) end)

-- Botón Restaurar Flotante (RST)
local RestoreQuickBtn = Instance.new("TextButton")
Stealth.RandomizeName(RestoreQuickBtn)
RestoreQuickBtn.Size = UDim2.new(0, 40, 0, 40)
RestoreQuickBtn.Position = loadPosition("Quick_Restore", UDim2.new(0, 60, 0, 196))
RestoreQuickBtn.BackgroundColor3 = THEME.BgMain
RestoreQuickBtn.BackgroundTransparency = 0.12
RestoreQuickBtn.Text = "RST"
RestoreQuickBtn.TextColor3 = THEME.AccentRed
RestoreQuickBtn.TextSize = 10
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
    if quickButtonsLocked then return end
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
            RestoreMap(false)
            RestoreQuickBtn.TextColor3 = THEME.AccentGreen
            rstStroke.Color = THEME.AccentGreen
            task.wait(0.3)
            RestoreQuickBtn.TextColor3 = THEME.AccentRed
            rstStroke.Color = THEME.AccentRed
        end
        if rIsDragging and not quickButtonsLocked then savePosition("Quick_Restore", RestoreQuickBtn.Position) end
        rStartPos, rIsDragging, rDragStartScreen, rInitBtnPos = nil, false, nil, nil
    end
end)

-- 🔒 BLOQUEAR / DESBLOQUEAR POSICIÓN DE BOTONES FLOTANTES
LockQuickBtn.MouseButton1Click:Connect(function()
    quickButtonsLocked = not quickButtonsLocked
    saveData("QuickLocked", tostring(quickButtonsLocked))
    LockQuickBtn.Text = quickButtonsLocked and "🔒" or "🔓"
    LockQuickBtn.BackgroundColor3 = quickButtonsLocked and THEME.AccentAmber or THEME.BgCard
    showToast(quickButtonsLocked and "🔒 Botones flotantes bloqueados" or "🔓 Botones flotantes desbloqueados", quickButtonsLocked and THEME.AccentAmber or THEME.AccentCyan)
end)

-- 🔄 RESETEAR POSICIONES
ResetPositionsBtn.MouseButton1Click:Connect(function()
    local defaultPositions = {
        MainFrame = UDim2.new(0, 20, 0, 85),
        MiniBtn = UDim2.new(0, 15, 0, 200),
        MiniTpBtn = UDim2.new(0, 68, 0, 200),
        SettingsFrame = UDim2.new(0, 270, 0, 105),
        PlayerWindow = UDim2.new(0, 270, 0, 85),
        Quick_TPS = UDim2.new(0, 60, 0, 100),
        Quick_Invisicam = UDim2.new(0, 106, 0, 100),
        Quick_FPXRay = UDim2.new(0, 152, 0, 100),
        Quick_ESP = UDim2.new(0, 198, 0, 100),
        Quick_DeleteMode = UDim2.new(0, 244, 0, 100),
        Quick_Noclip = UDim2.new(0, 60, 0, 148),
        Quick_InfJump = UDim2.new(0, 106, 0, 148),
        Quick_Fly = UDim2.new(0, 152, 0, 148),
        Quick_FreeCam = UDim2.new(0, 198, 0, 148),
        Quick_Fullbright = UDim2.new(0, 244, 0, 148),
        Quick_ThirdPerson = UDim2.new(0, 290, 0, 148),
        Quick_Restore = UDim2.new(0, 60, 0, 196)
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

    showToast("🔄 Posiciones restauradas", THEME.AccentAmber)
    ResetPositionsBtn.BackgroundColor3 = THEME.AccentGreen
    task.wait(0.3)
    ResetPositionsBtn.BackgroundColor3 = THEME.AccentAmber
end)

-- ⚙️ CONFIGURACIÓN: VISIBILIDAD DE BOTONES, SLIDERS Y KEYBINDS
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
    local isEnabled = loadButtonState(btnName)
    local bg, knob, card, stroke
    bg, knob, card, stroke = createNeonSwitch(SettingsScroll, "🔘", text, nil, function()
        local newState = not (bg.BackgroundColor3 == THEME.AccentGreen)
        setSwitchVisual(newState, bg, knob, card, stroke, nil)
        if QuickButtons[btnName] then
            QuickButtons[btnName].Visible = newState and quickButtonsMaster
        end
        saveButtonState(btnName, newState)
    end)
    setSwitchVisual(isEnabled, bg, knob, card, stroke, nil)

    if QuickButtons[btnName] then
        QuickButtons[btnName].Visible = isEnabled and quickButtonsMaster
    end
end

local function createSliderSwitch(btnName, switchText, sliderText, saveKey, minVal, maxVal, currentVal, callback)
    local card = Instance.new("Frame")
    Stealth.RandomizeName(card)
    card.Size = UDim2.new(1, 0, 0, 58)
    card.BackgroundColor3 = THEME.BgCard
    card.BackgroundTransparency = 0.2
    card.BorderSizePixel = 0
    card.Parent = SettingsScroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 9)
    local stroke = applyNeonStroke(card, THEME.AccentCyan, 0.78, 1)

    local titleBtn = Instance.new("TextButton")
    Stealth.RandomizeName(titleBtn)
    titleBtn.Size = UDim2.new(1, 0, 0, 28)
    titleBtn.BackgroundTransparency = 1
    titleBtn.Text = ""
    titleBtn.Parent = card

    local titleLbl = Instance.new("TextLabel")
    Stealth.RandomizeName(titleLbl)
    titleLbl.Size = UDim2.new(0.75, 0, 1, 0)
    titleLbl.Position = UDim2.new(0, 10, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "🔘  " .. switchText
    titleLbl.TextColor3 = THEME.TextMain
    titleLbl.Font = Enum.Font.GothamMedium
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = titleBtn

    local bg = Instance.new("Frame")
    Stealth.RandomizeName(bg)
    bg.Size = UDim2.new(0, 34, 0, 18)
    bg.Position = UDim2.new(1, -44, 0.5, -9)
    bg.BackgroundColor3 = THEME.SwitchOff
    bg.Parent = titleBtn
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    Stealth.RandomizeName(knob)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(0, 2, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local isEnabled = loadButtonState(btnName)
    setSwitchVisual(isEnabled, bg, knob, card, stroke, nil)
    if QuickButtons[btnName] then
        QuickButtons[btnName].Visible = isEnabled and quickButtonsMaster
    end

    titleBtn.Activated:Connect(function()
        local newState = not (bg.BackgroundColor3 == THEME.AccentGreen)
        setSwitchVisual(newState, bg, knob, card, stroke, nil)
        if QuickButtons[btnName] then
            QuickButtons[btnName].Visible = newState and quickButtonsMaster
        end
        saveButtonState(btnName, newState)
    end)

    local clampedInit = math.clamp(currentVal, minVal, maxVal)
    local label = Instance.new("TextLabel")
    Stealth.RandomizeName(label)
    label.Size = UDim2.new(1, -20, 0, 13)
    label.Position = UDim2.new(0, 10, 0, 28)
    label.BackgroundTransparency = 1
    label.Text = sliderText .. ": " .. clampedInit
    label.TextColor3 = THEME.TextMuted
    label.Font = Enum.Font.GothamBold
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local barBg = Instance.new("TextButton")
    Stealth.RandomizeName(barBg)
    barBg.Size = UDim2.new(1, -20, 0, 8)
    barBg.Position = UDim2.new(0, 10, 0, 44)
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

    local function updateSliderFromX(screenX)
        local posX = math.clamp((screenX - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(posX, 0, 1, 0)
        latestVal = math.floor(minVal + (maxVal - minVal) * posX)
        label.Text = sliderText .. ": " .. latestVal
        callback(latestVal)
    end

    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            updateSliderFromX(input.Position.X)
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
            updateSliderFromX(input.Position.X)
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
createQuickConfig("Botón Restaurar (RST)", "Restore")

-- 👁️ OJO MAESTRO
MasterQuickBtn.MouseButton1Click:Connect(function()
    quickButtonsMaster = not quickButtonsMaster
    MasterQuickBtn.BackgroundColor3 = quickButtonsMaster and THEME.AccentGreen or THEME.SwitchOff
    showToast(quickButtonsMaster and "👁️ Botones rápidos visibles" or "🙈 Botones rápidos ocultos", quickButtonsMaster and THEME.AccentGreen or THEME.TextMuted)
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

MinimizeBtn.MouseButton1Click:Connect(function() animateWindow(MainFrame, false); MiniBtn.Visible = true end)
MiniBtn.Activated:Connect(function() animateWindow(MainFrame, true); MiniBtn.Visible = false end)
SettingsBtn.Activated:Connect(function() animateWindow(SettingsFrame, not SettingsFrame.Visible) end)
CloseSettingsBtn.MouseButton1Click:Connect(function() animateWindow(SettingsFrame, false) end)

-- ⌨️ ATAJOS DE TECLADO (PC)
createSectionTitle("  ATAJOS DE TECLADO (PC)")

local function createKeybindBox(text, keyName)
    local card = Instance.new("Frame")
    Stealth.RandomizeName(card)
    card.Size = UDim2.new(1, 0, 0, 26)
    card.BackgroundColor3 = THEME.BgCard
    card.BackgroundTransparency = 0.2
    card.Parent = SettingsScroll
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
    applyNeonStroke(card, THEME.AccentCyan, 0.82, 1)

    local label = Instance.new("TextLabel")
    Stealth.RandomizeName(label)
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = THEME.TextMain
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = card

    local box = Instance.new("TextButton")
    Stealth.RandomizeName(box)
    box.Size = UDim2.new(0, 48, 0, 19)
    box.Position = UDim2.new(1, -54, 0.5, -9)
    box.BackgroundColor3 = THEME.BgHeader
    box.Text = keybinds[keyName].Name
    box.TextColor3 = THEME.AccentCyan
    box.Font = Enum.Font.GothamBold
    box.TextSize = 9
    box.Parent = card
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
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
createKeybindBox("Tecla Borrador", "Delete")
createKeybindBox("Tecla Restaurar", "Restore")

-- 🛑 BOTÓN UNLOAD
createSectionTitle("  SISTEMA")
local UnloadBtn = Instance.new("TextButton")
Stealth.RandomizeName(UnloadBtn)
UnloadBtn.Size = UDim2.new(1, 0, 0, 28)
UnloadBtn.BackgroundColor3 = THEME.AccentRed
UnloadBtn.BackgroundTransparency = 0.12
UnloadBtn.Text = "🛑 Cerrar y Limpiar Hub (Unload)"
UnloadBtn.TextColor3 = THEME.TextMain
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 10
UnloadBtn.Parent = SettingsScroll
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 7)
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
    if spectatingPlayer then resetSpectate() end
    RestoreMap(true)

    for _, conn in ipairs(allConnections) do
        pcall(function() conn:Disconnect() end)
    end
    for _, conn in pairs(espCharConnections) do
        pcall(function() conn:Disconnect() end)
    end
    if ScreenGui then ScreenGui:Destroy() end
end)

-- 🎯 RAYCAST Y CONTROLES
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
        SafeTeleport(CFrame.new(result.Position + Vector3.new(0, 3.5, 0)))
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
        if input.KeyCode == keybinds.Restore then RestoreMap(false) end
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
        touchState.totalMoved += input.Delta.Magnitude
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
