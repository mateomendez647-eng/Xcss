-- ==========================================
-- HUB: xcs (Ventanas Separadas + Miniaturas HD Corregidas + Buscador)
-- ==========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local tpEnabled = false
local invisicamEnabled = false
local fpXRayEnabled = false
local noclipEnabled = false
local flyEnabled = false
local freeCamEnabled = false
local fullbrightEnabled = false
local deleteModeEnabled = false
local espEnabled = false
local quickButtonsMaster = true

local spectatingPlayer = nil
local filterQuery = ""

local flySpeed = 50
local freeCamSpeed = 50
local turboMultiplier = 2

local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local noclipConnection = nil
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local fpXRayConnection = nil
local invisicamConnection = nil
local espConnection = nil
local transparentParts = {}
local deletedPartsMemory = {}
local espHighlights = {}

local freeCamConnection = nil
local freeCamRotateConnection = nil
local camYaw, camPitch = 0, 0
local camPos = Vector3.new(0, 0, 0)

local savedLighting = {}
local listeningFor = nil
local QuickButtons = {}

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
            if xO and yO then
                return UDim2.new(0, xO, 0, yO)
            end
        end
    end
    return defaultUDim2
end

local function saveButtonState(btnName, state) saveData("BtnState_" .. btnName, tostring(state)) end
local function loadButtonState(btnName) return loadData("BtnState_" .. btnName, "true") == "true" end

local function saveKeybind(keyName, keyCode) saveData("Key_" .. keyName, keyCode.Name) end
local function loadKeybind(keyName, defaultCode)
    local saved = loadData("Key_" .. keyName, nil)
    if saved then
        local ok, code = pcall(function() return Enum.KeyCode[saved] end)
        if ok and code then return code end
    end
    return defaultCode
end

local keybinds = {
    Invisicam  = loadKeybind("Invisicam",  Enum.KeyCode.V),
    Noclip     = loadKeybind("Noclip",     Enum.KeyCode.X),
    Fly        = loadKeybind("Fly",        Enum.KeyCode.Z),
    FreeCam    = loadKeybind("FreeCam",    Enum.KeyCode.C),
    Fullbright = loadKeybind("Fullbright", Enum.KeyCode.B),
    Teleport   = loadKeybind("Teleport",   Enum.KeyCode.G),
    XRay       = loadKeybind("XRay",       Enum.KeyCode.K),
    ESP        = loadKeybind("ESP",        Enum.KeyCode.H),
    Delete     = loadKeybind("Delete",     Enum.KeyCode.L),
    Restore    = loadKeybind("Restore",    Enum.KeyCode.R),
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xcsStyleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Bolita Principal (xcs)
local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 45, 0, 45)
MiniBtn.Position = loadPosition("MiniBtn", UDim2.new(0, 15, 0, 200))
MiniBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MiniBtn.Text = "xcs"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.TextSize = 12
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Visible = false
MiniBtn.Parent = ScreenGui
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", MiniBtn).Color = Color3.fromRGB(0, 150, 255)

-- Bolita Independiente para la Lista TP
local MiniTpBtn = Instance.new("TextButton")
MiniTpBtn.Size = UDim2.new(0, 45, 0, 45)
MiniTpBtn.Position = loadPosition("MiniTpBtn", UDim2.new(0, 70, 0, 200))
MiniTpBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MiniTpBtn.Text = "TP"
MiniTpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniTpBtn.TextSize = 12
MiniTpBtn.Font = Enum.Font.GothamBold
MiniTpBtn.Visible = false
MiniTpBtn.Parent = ScreenGui
Instance.new("UICorner", MiniTpBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", MiniTpBtn).Color = Color3.fromRGB(0, 150, 255)

-- Ventana Principal (Hub)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 300)
MainFrame.Position = loadPosition("MainFrame", UDim2.new(0, 100, 0, 100))
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("Frame")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.BorderSizePixel = 0
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 50, 1, 0)
TitleText.Position = UDim2.new(0, 8, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "xcs"
TitleText.TextColor3 = Color3.fromRGB(0, 150, 255)
TitleText.Font = Enum.Font.GothamBold
TitleText.TextSize = 12
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = Title

local ResetPositionsBtn = Instance.new("TextButton")
ResetPositionsBtn.Size = UDim2.new(0, 18, 0, 18)
ResetPositionsBtn.Position = UDim2.new(1, -135, 0, 3)
ResetPositionsBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
ResetPositionsBtn.Text = "🔄"
ResetPositionsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetPositionsBtn.TextSize = 9
ResetPositionsBtn.Parent = Title
Instance.new("UICorner", ResetPositionsBtn).CornerRadius = UDim.new(0, 4)

local MasterQuickBtn = Instance.new("TextButton")
MasterQuickBtn.Size = UDim2.new(0, 18, 0, 18)
MasterQuickBtn.Position = UDim2.new(1, -112, 0, 3)
MasterQuickBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
MasterQuickBtn.Text = "👁️"
MasterQuickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterQuickBtn.TextSize = 10
MasterQuickBtn.Parent = Title
Instance.new("UICorner", MasterQuickBtn).CornerRadius = UDim.new(0, 4)

local KeybindsBtn = Instance.new("TextButton")
KeybindsBtn.Size = UDim2.new(0, 18, 0, 18)
KeybindsBtn.Position = UDim2.new(1, -89, 0, 3)
KeybindsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
KeybindsBtn.Text = "⌨️"
KeybindsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
KeybindsBtn.TextSize = 10
KeybindsBtn.Parent = Title
Instance.new("UICorner", KeybindsBtn).CornerRadius = UDim.new(0, 4)

local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 18, 0, 18)
SettingsBtn.Position = UDim2.new(1, -66, 0, 3)
SettingsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsBtn.Text = "⚙️"
SettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsBtn.TextSize = 10
SettingsBtn.Parent = Title
Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 4)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 18, 0, 18)
MinimizeBtn.Position = UDim2.new(1, -43, 0, 3)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
MinimizeBtn.Text = "_"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 10
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Title
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 18, 0, 18)
CloseBtn.Position = UDim2.new(1, -20, 0, 3)
CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 10
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Title
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Size = UDim2.new(1, 0, 1, -25)
MainScroll.Position = UDim2.new(0, 0, 0, 25)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 3
MainScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 300)
MainScroll.Parent = MainFrame

local function createSwitch(parent, text)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.75, 0, 1, 0)
    label.Position = UDim2.new(0.06, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(0, 30, 0, 16)
    bg.Position = UDim2.new(0.8, 0, 0.5, -8)
    bg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bg.Text = ""
    bg.Parent = container
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    return bg, knob, container
end

local MainList = Instance.new("UIListLayout")
MainList.Padding = UDim.new(0, 8)
MainList.SortOrder = Enum.SortOrder.LayoutOrder
MainList.Parent = MainScroll

local MainPadding = Instance.new("UIPadding")
MainPadding.PaddingTop = UDim.new(0, 10)
MainPadding.PaddingLeft = UDim.new(0, 5)
MainPadding.Parent = MainScroll

local TPSwitchBg, TPSwitchKnob, TPSwitchContainer = createSwitch(MainScroll, "TPS")
if not isTouchDevice then TPSwitchContainer.Visible = false end

local SwitchBg, SwitchKnob = createSwitch(MainScroll, "Invisicam")
local FPXRaySwitchBg, FPXRaySwitchKnob = createSwitch(MainScroll, "FP X-Ray")
local ESPSwitchBg, ESPSwitchKnob = createSwitch(MainScroll, "ESP Jugadores")
local DeleteSwitchBg, DeleteSwitchKnob = createSwitch(MainScroll, "Borrador de Paredes")
local NoclipSwitchBg, NoclipSwitchKnob = createSwitch(MainScroll, "Noclip")
local FlySwitchBg, FlySwitchKnob = createSwitch(MainScroll, "Fly")
local FreeCamSwitchBg, FreeCamSwitchKnob = createSwitch(MainScroll, "Free Cam")
local FullbrightSwitchBg, FullbrightSwitchKnob = createSwitch(MainScroll, "Fullbright")

-- Ventana de Configuración
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(0, 180, 0, 300)
SettingsFrame.Position = loadPosition("SettingsFrame", UDim2.new(0, 120, 0, 120))
SettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = ScreenGui
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 8)

local CloseSettingsBtn = Instance.new("TextButton")
CloseSettingsBtn.Size = UDim2.new(0, 20, 0, 20)
CloseSettingsBtn.Position = UDim2.new(1, -25, 0, 5)
CloseSettingsBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
CloseSettingsBtn.Text = "X"
CloseSettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseSettingsBtn.Font = Enum.Font.GothamBold
CloseSettingsBtn.TextSize = 10
CloseSettingsBtn.ZIndex = 10
CloseSettingsBtn.Parent = SettingsFrame
Instance.new("UICorner", CloseSettingsBtn).CornerRadius = UDim.new(0, 4)

local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, 0, 1, 0)
SettingsScroll.Position = UDim2.new(0, 0, 0, 0)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
SettingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
SettingsScroll.Parent = SettingsFrame

local SettingsList = Instance.new("UIListLayout")
SettingsList.Padding = UDim.new(0, 8)
SettingsList.SortOrder = Enum.SortOrder.LayoutOrder
SettingsList.Parent = SettingsScroll

local SettingsPadding = Instance.new("UIPadding")
SettingsPadding.PaddingTop = UDim.new(0, 10)
SettingsPadding.PaddingLeft = UDim.new(0, 5)
SettingsPadding.Parent = SettingsScroll

-- Ventana de Teclas
local KeybindsFrame = Instance.new("Frame")
KeybindsFrame.Size = UDim2.new(0, 180, 0, 300)
KeybindsFrame.Position = loadPosition("KeybindsFrame", UDim2.new(0, 140, 0, 140))
KeybindsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
KeybindsFrame.BorderSizePixel = 0
KeybindsFrame.Visible = false
KeybindsFrame.Parent = ScreenGui
Instance.new("UICorner", KeybindsFrame).CornerRadius = UDim.new(0, 8)

local CloseKeybindsBtn = Instance.new("TextButton")
CloseKeybindsBtn.Size = UDim2.new(0, 20, 0, 20)
CloseKeybindsBtn.Position = UDim2.new(1, -25, 0, 5)
CloseKeybindsBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
CloseKeybindsBtn.Text = "X"
CloseKeybindsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseKeybindsBtn.Font = Enum.Font.GothamBold
CloseKeybindsBtn.TextSize = 10
CloseKeybindsBtn.ZIndex = 10
CloseKeybindsBtn.Parent = KeybindsFrame
Instance.new("UICorner", CloseKeybindsBtn).CornerRadius = UDim.new(0, 4)

local KeybindsScroll = Instance.new("ScrollingFrame")
KeybindsScroll.Size = UDim2.new(1, 0, 1, 0)
KeybindsScroll.Position = UDim2.new(0, 0, 0, 0)
KeybindsScroll.BackgroundTransparency = 1
KeybindsScroll.BorderSizePixel = 0
KeybindsScroll.ScrollBarThickness = 3
KeybindsScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
KeybindsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
KeybindsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
KeybindsScroll.Parent = KeybindsFrame

local KeybindsList = Instance.new("UIListLayout")
KeybindsList.Padding = UDim.new(0, 8)
KeybindsList.SortOrder = Enum.SortOrder.LayoutOrder
KeybindsList.Parent = KeybindsScroll

local KeybindsPadding = Instance.new("UIPadding")
KeybindsPadding.PaddingTop = UDim.new(0, 10)
KeybindsPadding.PaddingLeft = UDim.new(0, 5)
KeybindsPadding.Parent = KeybindsScroll

-- VENTANA INDEPENDIENTE PARA EL TELEPORT / JUGADORES
local PlayerWindow = Instance.new("Frame")
PlayerWindow.Size = UDim2.new(0, 180, 0, 300)
PlayerWindow.Position = loadPosition("PlayerWindow", UDim2.new(0, 300, 0, 100))
PlayerWindow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
PlayerWindow.BorderSizePixel = 0
PlayerWindow.Visible = true
PlayerWindow.Parent = ScreenGui
Instance.new("UICorner", PlayerWindow).CornerRadius = UDim.new(0, 8)

local PlayerWindowTitle = Instance.new("Frame")
PlayerWindowTitle.Size = UDim2.new(1, 0, 0, 25)
PlayerWindowTitle.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
PlayerWindowTitle.BorderSizePixel = 0
PlayerWindowTitle.Parent = PlayerWindow
Instance.new("UICorner", PlayerWindowTitle).CornerRadius = UDim.new(0, 8)

local PlayerWindowTitleText = Instance.new("TextLabel")
PlayerWindowTitleText.Size = UDim2.new(0, 100, 1, 0)
PlayerWindowTitleText.Position = UDim2.new(0, 8, 0, 0)
PlayerWindowTitleText.BackgroundTransparency = 1
PlayerWindowTitleText.Text = "TP Jugadores"
PlayerWindowTitleText.TextColor3 = Color3.fromRGB(0, 150, 255)
PlayerWindowTitleText.Font = Enum.Font.GothamBold
PlayerWindowTitleText.TextSize = 11
PlayerWindowTitleText.TextXAlignment = Enum.TextXAlignment.Left
PlayerWindowTitleText.Parent = PlayerWindowTitle

local PlayerWindowMinBtn = Instance.new("TextButton")
PlayerWindowMinBtn.Size = UDim2.new(0, 18, 0, 18)
PlayerWindowMinBtn.Position = UDim2.new(1, -43, 0, 3)
PlayerWindowMinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
PlayerWindowMinBtn.Text = "_"
PlayerWindowMinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerWindowMinBtn.TextSize = 10
PlayerWindowMinBtn.Font = Enum.Font.GothamBold
PlayerWindowMinBtn.Parent = PlayerWindowTitle
Instance.new("UICorner", PlayerWindowMinBtn).CornerRadius = UDim.new(0, 4)

local PlayerWindowCloseBtn = Instance.new("TextButton")
PlayerWindowCloseBtn.Size = UDim2.new(0, 18, 0, 18)
PlayerWindowCloseBtn.Position = UDim2.new(1, -20, 0, 3)
PlayerWindowCloseBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
PlayerWindowCloseBtn.Text = "X"
PlayerWindowCloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerWindowCloseBtn.TextSize = 10
PlayerWindowCloseBtn.Font = Enum.Font.GothamBold
PlayerWindowCloseBtn.Parent = PlayerWindowTitle
Instance.new("UICorner", PlayerWindowCloseBtn).CornerRadius = UDim.new(0, 4)

local PlayerWindowScroll = Instance.new("ScrollingFrame")
PlayerWindowScroll.Size = UDim2.new(1, 0, 1, -25)
PlayerWindowScroll.Position = UDim2.new(0, 0, 0, 25)
PlayerWindowScroll.BackgroundTransparency = 1
PlayerWindowScroll.BorderSizePixel = 0
PlayerWindowScroll.ScrollBarThickness = 3
PlayerWindowScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
PlayerWindowScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerWindowScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerWindowScroll.Parent = PlayerWindow

local PlayerWindowScrollList = Instance.new("UIListLayout")
PlayerWindowScrollList.Padding = UDim.new(0, 6)
PlayerWindowScrollList.SortOrder = Enum.SortOrder.LayoutOrder
PlayerWindowScrollList.Parent = PlayerWindowScroll

local PlayerWindowPadding = Instance.new("UIPadding")
PlayerWindowPadding.PaddingTop = UDim.new(0, 8)
PlayerWindowPadding.PaddingLeft = UDim.new(0, 5)
PlayerWindowPadding.Parent = PlayerWindowScroll

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -10, 0, 22)
searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Buscar jugador..."
searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 9
searchBox.ClearTextOnFocus = false
searchBox.Parent = PlayerWindowScroll
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 4)

local PlayerListContainer = Instance.new("Frame")
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

local spectatingPlayer = nil
local function spectatePlayer(targetPlayer)
    if spectatingPlayer == targetPlayer then
        spectatingPlayer = nil
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
    else
        spectatingPlayer = targetPlayer
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid") then
            Camera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
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
    ESPSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    ESPSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["ESP"] then QuickButtons["ESP"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        if espConnection then espConnection:Disconnect() end
        espConnection = RunService.RenderStepped:Connect(function()
            if not espEnabled then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local char = plr.Character
                    local hl = espHighlights[plr]
                    if not hl or not hl.Parent then
                        hl = Instance.new("Highlight")
                        hl.Name = "xcsESP"
                        hl.FillColor = Color3.fromRGB(255, 0, 80)
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = char
                        espHighlights[plr] = hl
                    end
                end
            end
        end)
    else
        if espConnection then espConnection:Disconnect() end
        espConnection = nil
        removeESP()
    end
end

local function toggleNoclip(state)
    noclipEnabled = state
    NoclipSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    NoclipSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["Noclip"] then QuickButtons["Noclip"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        if noclipConnection then noclipConnection:Disconnect() end
        noclipConnection = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if not c then return end
            for _, part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
                    if part.CanCollide then part.CanCollide = false end
                end
            end
        end)
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

local function toggleDeleteMode(state)
    deleteModeEnabled = state
    DeleteSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    DeleteSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
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

local function toggleInvisicam(state)
    invisicamEnabled = state
    SwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    SwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["Invisicam"] then QuickButtons["Invisicam"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        pcall(function() LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end)
    else
        pcall(function() LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom end)
        if invisicamConnection then invisicamConnection:Disconnect() end
    end
end

local function toggleFPXRay(state)
    fpXRayEnabled = state
    FPXRaySwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FPXRaySwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["FPXRay"] then QuickButtons["FPXRay"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        if fpXRayConnection then fpXRayConnection:Disconnect() end
        fpXRayConnection = RunService.RenderStepped:Connect(function()
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
        end)
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
    FullbrightSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FullbrightSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["Fullbright"] then QuickButtons["Fullbright"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

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

local function toggleFly(state)
    flyEnabled = state
    FlySwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FlySwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["Fly"] then QuickButtons["Fly"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        if flyConnection then flyConnection:Disconnect() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        if freeCamEnabled and toggleFreeCam then toggleFreeCam(false) end

        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyVelocity.Velocity = Vector3.zero
        flyBodyVelocity.Parent = hrp

        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        flyBodyGyro.P = 1000
        flyBodyGyro.D = 50
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp

        flyConnection = RunService.RenderStepped:Connect(function()
            if not flyEnabled then return end
            local c = LocalPlayer.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") or not flyBodyVelocity or not flyBodyGyro then return end

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
            else
                moveVector = getMoveDirection()
            end

            flyBodyVelocity.Velocity = moveVector.Magnitude > 0 and (moveVector.Unit * currentFlySpeed) or Vector3.zero
            flyBodyGyro.CFrame = Camera.CFrame
        end)
    else
        if flyConnection then flyConnection:Disconnect() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
        flyConnection, flyBodyVelocity, flyBodyGyro = nil, nil, nil
    end
end

toggleFreeCam = function(state)
    freeCamEnabled = state
    FreeCamSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FreeCamSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["FreeCam"] then QuickButtons["FreeCam"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

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
        freeCamConnection = RunService.RenderStepped:Connect(function(dt)
            if not freeCamEnabled then return end
            local rot = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)
            local moveVector = Vector3.zero

            local currentFreeCamSpeed = freeCamSpeed
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                currentFreeCamSpeed = freeCamSpeed * turboMultiplier
            end

            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
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

            if moveVector.Magnitude > 0 then
                camPos = camPos + (moveVector.Unit * currentFreeCamSpeed * dt)
            end
            Camera.CFrame = CFrame.new(camPos, camPos + rot.LookVector)
        end)

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

LocalPlayer.CharacterAdded:Connect(function(char)
    spectatingPlayer = nil
    if char and char:FindFirstChildOfClass("Humanoid") then
        Camera.CameraSubject = char:FindFirstChildOfClass("Humanoid")
    end
    task.wait(0.5)
    if noclipEnabled then toggleNoclip(true) end
    if invisicamEnabled then toggleInvisicam(true) end
    if fpXRayEnabled then toggleFPXRay(true) end
    if fullbrightEnabled then toggleFullbright(true) end
    if espEnabled then toggleESP(true) end
end)

local function makeDraggable(frame, saveName)
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if saveName then savePosition(saveName, frame.Position) end
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local vpSize = Camera.ViewportSize
            
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, math.max(0, vpSize.X - frame.AbsoluteSize.X))
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, vpSize.Y - frame.AbsoluteSize.Y))
            
            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

makeDraggable(MainFrame, "MainFrame")
makeDraggable(MiniBtn, "MiniBtn")
makeDraggable(MiniTpBtn, "MiniTpBtn")
makeDraggable(SettingsFrame, "SettingsFrame")
makeDraggable(KeybindsFrame, "KeybindsFrame")
makeDraggable(PlayerWindow, "PlayerWindow")

-- ==========================================
-- BOTONES FLOTANTES CON SISTEMA DE IMANES
-- ==========================================
local function createQuickBtn(name, text, initialPos, toggleFunc, getState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 35, 0, 35)
    btn.Position = loadPosition("Quick_" .. name, initialPos)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.Visible = false
    btn.Active = true
    btn.Parent = ScreenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    QuickButtons[name] = btn

    local startTouchPos = nil
    local isDragging = false
    local dragStartScreenPos = nil
    local initialButtonPos = nil

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            startTouchPos = input.Position
            isDragging = false
            dragStartScreenPos = input.Position
            initialButtonPos = btn.Position
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
                btn.BackgroundColor3 = getState() and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(30, 30, 30)
            end
            if isDragging then
                local snapDistance = 35
                for otherName, otherBtn in pairs(QuickButtons) do
                    if otherName ~= name and otherBtn.Visible then
                        local diffX = math.abs(btn.Position.X.Offset - otherBtn.Position.X.Offset)
                        local diffY = math.abs(btn.Position.Y.Offset - otherBtn.Position.Y.Offset)
                        
                        if diffX < snapDistance and diffY < 50 then
                            btn.Position = UDim2.new(0, otherBtn.Position.X.Offset, 0, btn.Position.Y.Offset)
                        elseif diffY < snapDistance and diffX < 50 then
                            btn.Position = UDim2.new(0, btn.Position.X.Offset, 0, otherBtn.Position.Y.Offset)
                        end
                    end
                end
                savePosition("Quick_" .. name, btn.Position)
            end
            startTouchPos = nil
            isDragging = false
            dragStartScreenPos = nil
        end
    end)
end

if isTouchDevice then
    createQuickBtn("TPS", "TPS", UDim2.new(0, 60, 0, 100), function()
        tpEnabled = not tpEnabled
        TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
        TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    end, function() return tpEnabled end)
    QuickButtons["TPS"].Visible = true
end

createQuickBtn("Invisicam", "INV", UDim2.new(0, 100, 0, 100), function() toggleInvisicam(not invisicamEnabled) end, function() return invisicamEnabled end)
createQuickBtn("FPXRay", "XRY", UDim2.new(0, 140, 0, 100), function() toggleFPXRay(not fpXRayEnabled) end, function() return fpXRayEnabled end)
createQuickBtn("ESP", "ESP", UDim2.new(0, 180, 0, 100), function() toggleESP(not espEnabled) end, function() return espEnabled end)
createQuickBtn("DeleteMode", "DEL", UDim2.new(0, 220, 0, 100), function() toggleDeleteMode(not deleteModeEnabled) end, function() return deleteModeEnabled end)
createQuickBtn("Noclip", "NOC", UDim2.new(0, 60, 0, 145), function() toggleNoclip(not noclipEnabled) end, function() return noclipEnabled end)
createQuickBtn("Fly", "FLY", UDim2.new(0, 100, 0, 145), function() toggleFly(not flyEnabled) end, function() return flyEnabled end)
createQuickBtn("FreeCam", "CAM", UDim2.new(0, 140, 0, 145), function() toggleFreeCam(not freeCamEnabled) end, function() return freeCamEnabled end)
createQuickBtn("Fullbright", "LGT", UDim2.new(0, 180, 0, 145), function() toggleFullbright(not fullbrightEnabled) end, function() return fullbrightEnabled end)

local RestoreQuickBtn = Instance.new("TextButton")
RestoreQuickBtn.Size = UDim2.new(0, 35, 0, 35)
RestoreQuickBtn.Position = loadPosition("Quick_Restore", UDim2.new(0, 60, 0, 190)) 
RestoreQuickBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RestoreQuickBtn.BackgroundTransparency = 0.2
RestoreQuickBtn.Text = "RST"
RestoreQuickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RestoreQuickBtn.TextSize = 9
RestoreQuickBtn.Font = Enum.Font.GothamBold
RestoreQuickBtn.Visible = false
RestoreQuickBtn.Parent = ScreenGui
Instance.new("UICorner", RestoreQuickBtn).CornerRadius = UDim.new(1, 0)
QuickButtons["Restore"] = RestoreQuickBtn

local rStartPos, rIsDragging, rDragStartScreen, rInitBtnPos = nil, false, nil, nil
RestoreQuickBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        rStartPos = input.Position
        rIsDragging = false
        rDragStartScreen = input.Position
        rInitBtnPos = RestoreQuickBtn.Position
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
            RestoreQuickBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            task.wait(0.3)
            RestoreQuickBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
        if rIsDragging then savePosition("Quick_Restore", RestoreQuickBtn.Position) end
        rStartPos, rIsDragging, rDragStartScreen, rInitBtnPos = nil, false, nil, nil
    end
end)

ResetPositionsBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if delfile then
            delfile("xcs_MainFrame.txt")
            delfile("xcs_MiniBtn.txt")
            delfile("xcs_MiniTpBtn.txt")
            delfile("xcs_SettingsFrame.txt")
            delfile("xcs_KeybindsFrame.txt")
            delfile("xcs_PlayerWindow.txt")
            delfile("xcs_Quick_TPS.txt")
            delfile("xcs_Quick_Invisicam.txt")
            delfile("xcs_Quick_FPXRay.txt")
            delfile("xcs_Quick_ESP.txt")
            delfile("xcs_Quick_DeleteMode.txt")
            delfile("xcs_Quick_Noclip.txt")
            delfile("xcs_Quick_Fly.txt")
            delfile("xcs_Quick_FreeCam.txt")
            delfile("xcs_Quick_Fullbright.txt")
            delfile("xcs_Quick_Restore.txt")
        end
    end)

    MainFrame.Position = UDim2.new(0, 100, 0, 100)
    MiniBtn.Position = UDim2.new(0, 15, 0, 200)
    MiniTpBtn.Position = UDim2.new(0, 70, 0, 200)
    SettingsFrame.Position = UDim2.new(0, 120, 0, 120)
    KeybindsFrame.Position = UDim2.new(0, 140, 0, 140)
    PlayerWindow.Position = UDim2.new(0, 300, 0, 100)

    ResetPositionsBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    task.wait(0.3)
    ResetPositionsBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 0)
end)

local function createQuickConfig(text, btnName)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = SettingsScroll

    local bg, knob = createSwitch(container, text)
    local isEnabled = loadButtonState(btnName)
    bg.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    knob.Position = isEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)

    if isEnabled and QuickButtons[btnName] and quickButtonsMaster then
        QuickButtons[btnName].Visible = true
    end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local newState = not (bg.BackgroundColor3 == Color3.fromRGB(0, 200, 100))
            bg.BackgroundColor3 = newState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
            knob.Position = newState and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)

            if QuickButtons[btnName] and quickButtonsMaster then
                QuickButtons[btnName].Visible = newState
            end
            saveButtonState(btnName, newState)
        end
    end)
end

local function createSliderSwitch(btnName, switchText, sliderText, minVal, maxVal, defaultVal, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = SettingsScroll

    local bg, knob = createSwitch(container, switchText)
    local isEnabled = loadButtonState(btnName)
    bg.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    knob.Position = isEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if isEnabled and QuickButtons[btnName] and quickButtonsMaster then QuickButtons[btnName].Visible = true end

    bg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            local newState = not (bg.BackgroundColor3 == Color3.fromRGB(0, 200, 100))
            bg.BackgroundColor3 = newState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
            knob.Position = newState and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            if QuickButtons[btnName] and quickButtonsMaster then QuickButtons[btnName].Visible = newState end
            saveButtonState(btnName, newState)
        end
    end)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 10)
    label.Position = UDim2.new(0.1, 0, 0, 22)
    label.BackgroundTransparency = 1
    label.Text = sliderText .. " (" .. defaultVal .. ")"
    label.TextColor3 = Color3.fromRGB(150, 150, 150)
    label.Font = Enum.Font.Gotham
    label.TextSize = 8
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local barBg = Instance.new("TextButton")
    barBg.Size = UDim2.new(0.8, 0, 0, 6)
    barBg.Position = UDim2.new(0.1, 0, 0, 36)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    barBg.Text = ""
    barBg.Parent = container
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    fill.Parent = barBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local isSliding = false
    barBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isSliding = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then isSliding = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local posX = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(posX, 0, 1, 0)
            local val = math.floor(minVal + (maxVal - minVal) * posX)
            label.Text = sliderText .. " (" .. val .. ")"
            callback(val)
        end
    end)
end

local ConfigLabel = Instance.new("TextLabel")
ConfigLabel.Size = UDim2.new(1, 0, 0, 15)
ConfigLabel.BackgroundTransparency = 1
ConfigLabel.Text = "--- Botones Flotantes ---"
ConfigLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
ConfigLabel.Font = Enum.Font.GothamBold
ConfigLabel.TextSize = 9
ConfigLabel.Parent = SettingsScroll

if isTouchDevice then
    createQuickConfig("TPS", "TPS")
    task.defer(function() if QuickButtons["TPS"] then QuickButtons["TPS"].Visible = true end end)
end
createQuickConfig("Invisicam", "Invisicam")
createQuickConfig("FP X-Ray", "FPXRay")
createQuickConfig("ESP", "ESP")
createQuickConfig("Borrador", "DeleteMode")
createQuickConfig("Noclip", "Noclip")

createSliderSwitch("Fly", "Fly", "Velocidad Fly", 10, 300, 50, function(val) flySpeed = val end)
createSliderSwitch("FreeCam", "Free Cam", "Velocidad Free Cam", 10, 300, 50, function(val) freeCamSpeed = val end)
createQuickConfig("Fullbright", "Fullbright")

local RestoreConfigBg, RestoreConfigKnob = createSwitch(SettingsScroll, "Botón Restaurar")
local rstEnabled = loadButtonState("Restore")
RestoreConfigBg.BackgroundColor3 = rstEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
RestoreConfigKnob.Position = rstEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
if rstEnabled and quickButtonsMaster then RestoreQuickBtn.Visible = true end

RestoreConfigBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local newState = not (RestoreConfigBg.BackgroundColor3 == Color3.fromRGB(0, 200, 100))
        RestoreConfigBg.BackgroundColor3 = newState and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
        RestoreConfigKnob.Position = newState and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        if quickButtonsMaster then RestoreQuickBtn.Visible = newState end
        saveButtonState("Restore", newState)
    end
end)

if isTouchDevice then
    TPSwitchBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            tpEnabled = not tpEnabled
            TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
            TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        end
    end)
end

SwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleInvisicam(not invisicamEnabled) end end)
FPXRaySwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFPXRay(not fpXRayEnabled) end end)
ESPSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleESP(not espEnabled) end end)
DeleteSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleDeleteMode(not deleteModeEnabled) end end)
NoclipSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleNoclip(not noclipEnabled) end end)
FlySwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFly(not flyEnabled) end end)
FreeCamSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFreeCam(not freeCamEnabled) end end)
FullbrightSwitchBg.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFullbright(not fullbrightEnabled) end end)

MasterQuickBtn.MouseButton1Click:Connect(function()
    quickButtonsMaster = not quickButtonsMaster
    MasterQuickBtn.BackgroundColor3 = quickButtonsMaster and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    for name, btn in pairs(QuickButtons) do
        if quickButtonsMaster then
            btn.Visible = (name == "TPS" and isTouchDevice) or loadButtonState(name)
        else
            btn.Visible = false
        end
    end
    RestoreQuickBtn.Visible = quickButtonsMaster and loadButtonState("Restore")
end)

-- Controles Menú Principal
MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    SettingsFrame.Visible = false
    KeybindsFrame.Visible = false
    MiniBtn.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    SettingsFrame.Visible = false
    KeybindsFrame.Visible = false
end)

MiniBtn.Activated:Connect(function() MainFrame.Visible = true; MiniBtn.Visible = false end)

-- Controles Ventana TP / Jugadores
PlayerWindowMinBtn.MouseButton1Click:Connect(function()
    PlayerWindow.Visible = false
    MiniTpBtn.Visible = true
end)

PlayerWindowCloseBtn.MouseButton1Click:Connect(function()
    PlayerWindow.Visible = false
end)

MiniTpBtn.Activated:Connect(function() PlayerWindow.Visible = true; MiniTpBtn.Visible = false end)

SettingsBtn.Activated:Connect(function() SettingsFrame.Visible = not SettingsFrame.Visible end)
CloseSettingsBtn.MouseButton1Click:Connect(function() SettingsFrame.Visible = false end)

KeybindsBtn.Activated:Connect(function() KeybindsFrame.Visible = not KeybindsFrame.Visible end)
CloseKeybindsBtn.MouseButton1Click:Connect(function() KeybindsFrame.Visible = false end)

local KeyLabel = Instance.new("TextLabel")
KeyLabel.Size = UDim2.new(1, 0, 0, 15)
KeyLabel.BackgroundTransparency = 1
KeyLabel.Text = "--- Asignación de Teclas ---"
KeyLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
KeyLabel.Font = Enum.Font.GothamBold
KeyLabel.TextSize = 9
KeyLabel.Parent = KeybindsScroll

local function createKeybindBox(text, keyName)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = KeybindsScroll

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0.1, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0.25, 0, 1, 0)
    box.Position = UDim2.new(0.65, 0, 0, 0)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.Text = keybinds[keyName].Name
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 9
    box.Parent = container
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

    box.MouseButton1Click:Connect(function()
        if listeningFor then return end
        box.Text = "..."
        box.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        listeningFor = keyName

        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybinds[keyName] = input.KeyCode
                saveKeybind(keyName, input.KeyCode)
                box.Text = input.KeyCode.Name
                box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
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
createKeybindBox("Tecla Borrador", "Delete")
createKeybindBox("Tecla Restaurar", "Restore")

local refreshPlayerList
refreshPlayerList = function()
    for _, child in ipairs(PlayerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local displayName = p.DisplayName
            local userName = p.Name
            if filterQuery == "" or string.find(string.lower(displayName), string.lower(filterQuery)) or string.find(string.lower(userName), string.lower(filterQuery)) then
                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -10, 0, 26)
                row.BackgroundTransparency = 1
                row.Parent = PlayerListContainer

                local thumbImg = Instance.new("ImageLabel")
                thumbImg.Size = UDim2.new(0, 22, 0, 22)
                thumbImg.Position = UDim2.new(0, 0, 0.5, -11)
                thumbImg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                thumbImg.BorderSizePixel = 0
                thumbImg.Parent = row
                Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)

                -- CARGA DE FOTO SEGURA CON REINTENTOS
                task.spawn(function()
                    local success, content = pcall(function()
                        return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size42x42)
                    end)
                    if success and content and thumbImg and thumbImg.Parent then
                        thumbImg.Image = content
                    end
                end)

                p.CharacterAppearanceLoaded:Connect(function()
                    task.spawn(function()
                        local success, content = pcall(function()
                            return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size42x42)
                        end)
                        if success and content and thumbImg and thumbImg.Parent then
                            thumbImg.Image = content
                        end
                    end)
                end)

                local pNameLabel = Instance.new("TextLabel")
                pNameLabel.Size = UDim2.new(0.42, 0, 1, 0)
                pNameLabel.Position = UDim2.new(0, 26, 0, 0)
                pNameLabel.BackgroundTransparency = 1
                pNameLabel.Text = displayName
                pNameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
                pNameLabel.Font = Enum.Font.Gotham
                pNameLabel.TextSize = 8
                pNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
                pNameLabel.TextXAlignment = Enum.TextXAlignment.Left
                pNameLabel.Parent = row

                local tpBtn = Instance.new("TextButton")
                tpBtn.Size = UDim2.new(0, 24, 0, 20)
                tpBtn.Position = UDim2.new(0.68, 0, 0.5, -10)
                tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                tpBtn.Text = "TP"
                tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpBtn.Font = Enum.Font.GothamBold
                tpBtn.TextSize = 8
                tpBtn.Parent = row
                Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)

                tpBtn.MouseButton1Click:Connect(function()
                    teleportToPlayer(p)
                end)

                local viewBtn = Instance.new("TextButton")
                viewBtn.Size = UDim2.new(0, 28, 0, 20)
                viewBtn.Position = UDim2.new(0.81, 0, 0.5, -10)
                viewBtn.BackgroundColor3 = (spectatingPlayer == p) and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(50, 50, 50)
                viewBtn.Text = "VIEW"
                viewBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
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

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterQuery = searchBox.Text
    refreshPlayerList()
end)

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function(p)
    if spectatingPlayer == p then spectatePlayer(p) end
    refreshPlayerList()
end)
task.spawn(refreshPlayerList)

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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or listeningFor then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == keybinds.Invisicam then toggleInvisicam(not invisicamEnabled) end
        if input.KeyCode == keybinds.Noclip then toggleNoclip(not noclipEnabled) end
        if input.KeyCode == keybinds.Fly then toggleFly(not flyEnabled) end
        if input.KeyCode == keybinds.FreeCam then toggleFreeCam(not freeCamEnabled) end
        if input.KeyCode == keybinds.Fullbright then toggleFullbright(not fullbrightEnabled) end
        if input.KeyCode == keybinds.XRay then toggleFPXRay(not fpXRayEnabled) end
        if input.KeyCode == keybinds.ESP then toggleESP(not espEnabled) end
        if input.KeyCode == keybinds.Restore then RestoreMap() end
        if input.KeyCode == keybinds.Teleport then TeleportAt(Vector2.new(Mouse.X, Mouse.Y)) end
        if input.KeyCode == keybinds.Delete then DeletePartAt(Vector2.new(Mouse.X, Mouse.Y)) end
    end
end)

local function isOverGui(pos)
    for _, obj in ipairs(LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)) do
        if obj:IsDescendantOf(ScreenGui) then return true end
    end
    return false
end

local touchState = { active = false, startTime = 0, totalMoved = 0, isCameraDrag = false }
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touchState.active = true
        touchState.startTime = os.clock()
        touchState.totalMoved = 0
        touchState.isCameraDrag = false
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        touchState.totalMoved = touchState.totalMoved + input.Delta.Magnitude
        if touchState.totalMoved > 10 then touchState.isCameraDrag = true end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        touchState.active = false
        if (os.clock() - touchState.startTime) < 0.3 and not touchState.isCameraDrag and not isOverGui(input.Position) then
            if deleteModeEnabled then DeletePartAt(input.Position)
            elseif tpEnabled then TeleportAt(input.Position) end
        end
    end
end)
