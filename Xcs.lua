-- ==========================================
-- HUB: xcs (PC + Android compatible)
-- v7 FINAL: sin emojis, sin readfile obligatorio, posición segura
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
local quickButtonsMaster = true

local flySpeed = 50
local freeCamSpeed = 50

local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local noclipConnection = nil
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local fpXRayConnection = nil
local invisicamConnection = nil
local transparentParts = {}
local deletedPartsMemory = {}

local freeCamConnection = nil
local freeCamRotateConnection = nil
local camYaw, camPitch = 0, 0
local camPos = Vector3.new(0, 0, 0)

local savedLighting = {}
local listeningFor = nil
local QuickButtons = {}

-- ==========================================
-- GUARDADO CONDICIONAL (funciona en PC y Android)
-- ==========================================
local HAS_FILESYSTEM = (typeof(readfile) == "function") and (typeof(writefile) == "function")

local function saveData(name, data)
    if not HAS_FILESYSTEM then return end
    pcall(function() writefile("xcs_" .. name .. ".txt", tostring(data)) end)
end

local function loadData(name, default)
    if not HAS_FILESYSTEM then return default end
    local ok, content = pcall(function() return readfile("xcs_" .. name .. ".txt") end)
    if ok and content and content ~= "" then return content end
    return default
end

local function savePosition(name, pos)
    saveData(name, pos.X.Scale .. "," .. pos.X.Offset .. "," .. pos.Y.Scale .. "," .. pos.Y.Offset)
end

local function loadPosition(name, defaultPos)
    local content = loadData(name, nil)
    if content then
        local args = string.split(content, ",")
        if #args == 4 then
            local xS, xO, yS, yO = tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4])
            if xS and xO and yS and yO then
                return UDim2.new(xS, xO, yS, yO)
            end
        end
    end
    return defaultPos
end

local function saveButtonState(btnName, state) saveData("BtnState_" .. btnName, state) end
local function loadButtonState(btnName) return loadData("BtnState_" .. btnName, "true") == "true" end

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
}

local playerControls = nil
task.spawn(function()
    pcall(function()
        local playerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 10))
        if playerModule then playerControls = playerModule:GetControls() end
    end)
end)

-- ==========================================
-- INTERFAZ
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xcsStyleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- ✅ Posición segura para PC y Android (70px del borde derecho, 70px arriba)
local MINIBTN_POSITION = UDim2.new(1, -70, 0, 70)

local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 45, 0, 45)
MiniBtn.Position = MINIBTN_POSITION
MiniBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MiniBtn.Text = "xcs"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.TextSize = 12
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Visible = true
MiniBtn.ZIndex = 50
MiniBtn.Parent = ScreenGui
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", MiniBtn).Color = Color3.fromRGB(0, 150, 255)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 300)
MainFrame.Position = loadPosition("MainFrame", UDim2.new(0.5, -90, 0.5, -150))
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.ZIndex = 10
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.Text = "xcs Hub"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- ✅ Sin emojis (compatibilidad con ejecutores de PC)
local MasterQuickBtn = Instance.new("TextButton")
MasterQuickBtn.Size = UDim2.new(0, 18, 0, 18)
MasterQuickBtn.Position = UDim2.new(1, -68, 0, 3)
MasterQuickBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
MasterQuickBtn.Text = "O"
MasterQuickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterQuickBtn.TextSize = 10
MasterQuickBtn.Font = Enum.Font.GothamBold
MasterQuickBtn.Parent = Title
Instance.new("UICorner", MasterQuickBtn).CornerRadius = UDim.new(0, 4)

local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 18, 0, 18)
SettingsBtn.Position = UDim2.new(1, -45, 0, 3)
SettingsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsBtn.Text = "S"
SettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsBtn.TextSize = 10
SettingsBtn.Font = Enum.Font.GothamBold
SettingsBtn.Parent = Title
Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 4)

local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 18, 0, 18)
MinimizeBtn.Position = UDim2.new(1, -22, 0, 3)
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MinimizeBtn.Text = "X"
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.TextSize = 10
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Title
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 4)

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
if not isTouchDevice then
    TPSwitchContainer.Visible = false
end

local SwitchBg, SwitchKnob = createSwitch(MainScroll, "Invisicam")
local FPXRaySwitchBg, FPXRaySwitchKnob = createSwitch(MainScroll, "FP X-Ray")
local DeleteSwitchBg, DeleteSwitchKnob = createSwitch(MainScroll, "Borrador de Paredes")
local NoclipSwitchBg, NoclipSwitchKnob = createSwitch(MainScroll, "Noclip")
local FlySwitchBg, FlySwitchKnob = createSwitch(MainScroll, "Fly")
local FreeCamSwitchBg, FreeCamSwitchKnob = createSwitch(MainScroll, "Free Cam")
local FullbrightSwitchBg, FullbrightSwitchKnob = createSwitch(MainScroll, "Fullbright")

-- ==========================================
-- PANEL DE AJUSTES
-- ==========================================
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(0, 180, 0, 300)
SettingsFrame.Position = loadPosition("SettingsFrame", UDim2.new(0.5, -90, 0.5, -150))
SettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.ZIndex = 20
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
CloseSettingsBtn.ZIndex = 25
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

-- ==========================================
-- LÓGICAS
-- ==========================================
local function toggleNoclip(state)
    noclipEnabled = state
    NoclipSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    NoclipSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if QuickButtons["Noclip"] then QuickButtons["Noclip"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

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
        if char and hrp then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
                    if part.Name == "HumanoidRootPart" or part.Name == "Head" or part.Name == "Torso" or part.Name:find("Torso") or part.Name:find("Leg") or part.Name:find("Foot") then
                        part.CanCollide = true
                    else
                        part.CanCollide = false
                    end
                end
            end
            if humanoid then
                humanoid:ChangeState(Enum.HumanoidStateType.Landed)
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
end

local function toggleDeleteMode(state)
    deleteModeEnabled = state
    DeleteSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    DeleteSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    if state then MainFrame.BackgroundTransparency = 0.5 else MainFrame.BackgroundTransparency = 0 end
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
        invisicamConnection = RunService.Stepped:Connect(function()
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            if part.Transparency > 0 then part.Transparency = 0 end
                        elseif part:IsA("Decal") or part:IsA("Texture") then
                            if part.Transparency > 0 then part.Transparency = 0 end
                        end
                    end
                end
            end
        end)
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

            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = filterList
            rayParams.FilterType = Enum.RaycastFilterType.Exclude

            local currentOrigin = Camera.CFrame.Position
            local rayDirection = Camera.CFrame.LookVector * 250

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
        flyConnection, flyBodyVelocity, flyBodyGyro = nil, nil, nil

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

        flyConnection = RunService.RenderStepped:Connect(function(dt)
            if not flyEnabled then return end
            local c = LocalPlayer.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") or not flyBodyVelocity or not flyBodyGyro then return end

            local moveVector = Vector3.zero
            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
            else
                moveVector = getMoveDirection()
            end

            if moveVector.Magnitude > 0 then
                flyBodyVelocity.Velocity = moveVector.Unit * flySpeed
            else
                flyBodyVelocity.Velocity = Vector3.zero
            end
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
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true

        local look = Camera.CFrame.LookVector
        camYaw = math.atan2(-look.X, -look.Z)
        camPitch = math.asin(look.Y)
        camPos = Camera.CFrame.Position

        if freeCamConnection then freeCamConnection:Disconnect() end
        freeCamConnection = RunService.RenderStepped:Connect(function(dt)
            if not freeCamEnabled then return end
            local rot = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)
            local moveVector = Vector3.zero

            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
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
                camPos = camPos + (moveVector.Unit * freeCamSpeed * dt)
            end
            Camera.CFrame = CFrame.new(camPos, camPos + rot.LookVector)
        end)

        if freeCamRotateConnection then freeCamRotateConnection:Disconnect() end
        freeCamRotateConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
            if not freeCamEnabled then return end
            if gameProcessed then return end

            local function isJoystickZone(pos)
                if not isTouchDevice then return false end
                local vp = Camera.ViewportSize
                return pos.X < vp.X * 0.45 and pos.Y > vp.Y * 0.45
            end

            if input.UserInputType == Enum.UserInputType.Touch then
                if isJoystickZone(input.Position) then return end
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
        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
        UserInputService.MouseIconEnabled = true

        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if freeCamEnabled then toggleFreeCam(false) end
    if flyEnabled then toggleFly(false) end
end)

-- ==========================================
-- ARRASTRE
-- ==========================================
local function makeDraggable(frame, saveName)
    local dragging, dragInput, mousePos, framePos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then
                dragging = false
                if saveName then savePosition(saveName, frame.Position) end
            end end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainFrame, "MainFrame")
makeDraggable(SettingsFrame, "SettingsFrame")

-- ==========================================
-- BOTONES FLOTANTES
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

    local startPos, isDragging, dragStartPos

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            startPos = input.Position; isDragging = false; dragStartPos = input.Position; btn.ZIndex = 100
        end
    end)

    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement then
            if dragStartPos then
                if (input.Position - dragStartPos).Magnitude > 10 then
                    isDragging = true
                    local delta = input.Position - dragStartPos
                    btn.Position = UDim2.new(btn.Position.X.Scale, btn.Position.X.Offset + delta.X, btn.Position.Y.Scale, btn.Position.Y.Offset + delta.Y)
                    dragStartPos = input.Position
                end
            end
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if startPos and not isDragging then
                toggleFunc()
                btn.BackgroundColor3 = getState() and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(30, 30, 30)
            end
            if isDragging then savePosition("Quick_" .. name, btn.Position) end
            startPos = nil; isDragging = false; dragStartPos = nil
        end
    end)
end

if isTouchDevice then
    createQuickBtn("TPS", "TPS", UDim2.new(0, 60, 0.15, 0), function()
        tpEnabled = not tpEnabled
        TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
        TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    end, function() return tpEnabled end)
    QuickButtons["TPS"].Visible = true
end

createQuickBtn("Invisicam", "INV", UDim2.new(0, 100, 0.15, 0), function() toggleInvisicam(not invisicamEnabled) end, function() return invisicamEnabled end)
createQuickBtn("FPXRay", "XRY", UDim2.new(0, 140, 0.15, 0), function() toggleFPXRay(not fpXRayEnabled) end, function() return fpXRayEnabled end)
createQuickBtn("DeleteMode", "DEL", UDim2.new(0, 180, 0.15, 0), function() toggleDeleteMode(not deleteModeEnabled) end, function() return deleteModeEnabled end)
createQuickBtn("Noclip", "NOC", UDim2.new(0, 60, 0.22, 0), function() toggleNoclip(not noclipEnabled) end, function() return noclipEnabled end)
createQuickBtn("Fly", "FLY", UDim2.new(0, 100, 0.22, 0), function() toggleFly(not flyEnabled) end, function() return flyEnabled end)
createQuickBtn("FreeCam", "CAM", UDim2.new(0, 140, 0.22, 0), function() toggleFreeCam(not freeCamEnabled) end, function() return freeCamEnabled end)
createQuickBtn("Fullbright", "LGT", UDim2.new(0, 180, 0.22, 0), function() toggleFullbright(not fullbrightEnabled) end, function() return fullbrightEnabled end)

local RestoreQuickBtn = Instance.new("TextButton")
RestoreQuickBtn.Size = UDim2.new(0, 35, 0, 35)
RestoreQuickBtn.Position = UDim2.new(0, 60, 0.29, 0)
RestoreQuickBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
RestoreQuickBtn.BackgroundTransparency = 0.2
RestoreQuickBtn.Text = "RST"
RestoreQuickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RestoreQuickBtn.TextSize = 9
RestoreQuickBtn.Font = Enum.Font.GothamBold
RestoreQuickBtn.Visible = false
RestoreQuickBtn.Parent = ScreenGui
Instance.new("UICorner", RestoreQuickBtn).CornerRadius = UDim.new(1, 0)

makeDraggable(RestoreQuickBtn, "Quick_RST")

RestoreQuickBtn.MouseButton1Click:Connect(function()
    RestoreMap()
    RestoreQuickBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    task.wait(0.3)
    RestoreQuickBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)

-- ==========================================
-- CONFIGURACIÓN DE BOTONES
-- ==========================================
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
            if QuickButtons[btnName] and quickButtonsMaster then QuickButtons[btnName].Visible = newState end
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
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end)

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
ConfigLabel.Text = "--- Botones ---"
ConfigLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
ConfigLabel.Font = Enum.Font.GothamBold
ConfigLabel.TextSize = 9
ConfigLabel.Parent = SettingsScroll

if isTouchDevice then
    createQuickConfig("TPS", "TPS")
    task.defer(function()
        if QuickButtons["TPS"] then QuickButtons["TPS"].Visible = true end
    end)
end
createQuickConfig("Invisicam", "Invisicam")
createQuickConfig("FP X-Ray", "FPXRay")
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

-- ==========================================
-- BOTONES DEL MENÚ
-- ==========================================
if isTouchDevice then
    TPSwitchBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            tpEnabled = not tpEnabled
            TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
            TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            if QuickButtons["TPS"] then QuickButtons["TPS"].BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(30, 30, 30) end
        end
    end)
end

SwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleInvisicam(not invisicamEnabled) end
end)
FPXRaySwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFPXRay(not fpXRayEnabled) end
end)
DeleteSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleDeleteMode(not deleteModeEnabled) end
end)
NoclipSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleNoclip(not noclipEnabled) end
end)
FlySwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFly(not flyEnabled) end
end)
FreeCamSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFreeCam(not freeCamEnabled) end
end)
FullbrightSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFullbright(not fullbrightEnabled) end
end)

MasterQuickBtn.MouseButton1Click:Connect(function()
    quickButtonsMaster = not quickButtonsMaster
    MasterQuickBtn.BackgroundColor3 = quickButtonsMaster and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    for name, btn in pairs(QuickButtons) do
        if quickButtonsMaster then
            if name == "TPS" and isTouchDevice then btn.Visible = true
            else btn.Visible = loadButtonState(name) end
        else btn.Visible = false end
    end
    if quickButtonsMaster then RestoreQuickBtn.Visible = loadButtonState("Restore")
    else RestoreQuickBtn.Visible = false end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    MiniBtn.Position = MINIBTN_POSITION
    MiniBtn.Visible = true
end)

MiniBtn.Activated:Connect(function()
    MainFrame.Visible = true
    MiniBtn.Visible = false
end)

SettingsBtn.Activated:Connect(function()
    SettingsFrame.Position = UDim2.new(0.5, -90, 0.5, -150)
    SettingsFrame.Visible = not SettingsFrame.Visible
end)

CloseSettingsBtn.MouseButton1Click:Connect(function()
    SettingsFrame.Visible = false
end)

-- ==========================================
-- KEYBINDS UI
-- ==========================================
local function createKeybindBox(text, keyName)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 20)
    container.BackgroundTransparency = 1
    container.Parent = SettingsScroll

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

        local connection, cancelConnection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybinds[keyName] = input.KeyCode
                saveKeybind(keyName, input.KeyCode)
                box.Text = input.KeyCode.Name
                box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                listeningFor = nil
                connection:Disconnect()
                if cancelConnection then cancelConnection:Disconnect() end
            end
        end)
        cancelConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                task.delay(0.1, function()
                    if listeningFor == keyName then
                        box.Text = keybinds[keyName].Name
                        box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                        listeningFor = nil
                        connection:Disconnect()
                        if cancelConnection then cancelConnection:Disconnect() end
                    end
                end)
            end
        end)
    end)
end

if not isTouchDevice then
    createKeybindBox("Tecla TP (PC)", "Teleport")
end
createKeybindBox("Tecla Invisicam", "Invisicam")
createKeybindBox("Tecla Noclip", "Noclip")
createKeybindBox("Tecla Fly", "Fly")
createKeybindBox("Tecla Free Cam", "FreeCam")
createKeybindBox("Tecla Fullbright", "Fullbright")
createKeybindBox("Tecla X-Ray", "XRay")
createKeybindBox("Tecla Borrador", "Delete")
createKeybindBox("Tecla Restaurar", "Restore")

-- ==========================================
-- RAYCAST
-- ==========================================
local function raycastIgnoringDeleted(origin, direction, extraFilter)
    local filter = {LocalPlayer.Character, Camera}
    if extraFilter then for _, v in ipairs(extraFilter) do table.insert(filter, v) end end
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

-- ==========================================
-- KEYBINDS
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if listeningFor then return end

    if input.UserInputType == Enum.UserInputType.Keyboard then
        if input.KeyCode == keybinds.Invisicam then toggleInvisicam(not invisicamEnabled) end
        if input.KeyCode == keybinds.Noclip then toggleNoclip(not noclipEnabled) end
        if input.KeyCode == keybinds.Fly then toggleFly(not flyEnabled) end
        if input.KeyCode == keybinds.FreeCam then toggleFreeCam(not freeCamEnabled) end
        if input.KeyCode == keybinds.Fullbright then toggleFullbright(not fullbrightEnabled) end
        if input.KeyCode == keybinds.XRay then toggleFPXRay(not fpXRayEnabled) end
        if input.KeyCode == keybinds.Restore then RestoreMap() end
        if input.KeyCode == keybinds.Teleport then TeleportAt(Vector2.new(Mouse.X, Mouse.Y)) end
        if input.KeyCode == keybinds.Delete then DeletePartAt(Vector2.new(Mouse.X, Mouse.Y)) end
    end
end)

-- ==========================================
-- TÁCTIL
-- ==========================================
local function isOverGui(pos)
    local guiObjects = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)
    for _, obj in ipairs(guiObjects) do
        if obj:IsDescendantOf(ScreenGui) then return true end
    end
    return false
end

local touchState = {
    active = false, startTime = 0,
    startPos = Vector2.new(0, 0), lastPos = Vector2.new(0, 0),
    totalMoved = 0, maxFrameDelta = 0, isCameraDrag = false,
}

local TAP_MAX_TIME = 0.30
local TAP_MAX_MOVE = 10
local CAMERA_DRAG_THRESHOLD = 8

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touchState.active = true
        touchState.startTime = os.clock()
        touchState.startPos = input.Position
        touchState.lastPos = input.Position
        touchState.totalMoved = 0
        touchState.maxFrameDelta = 0
        touchState.isCameraDrag = false
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        local delta = (input.Position - touchState.lastPos).Magnitude
        touchState.totalMoved = touchState.totalMoved + delta
        if delta > touchState.maxFrameDelta then touchState.maxFrameDelta = delta end
        if delta > CAMERA_DRAG_THRESHOLD then touchState.isCameraDrag = true end
        if touchState.totalMoved > TAP_MAX_MOVE then touchState.isCameraDrag = true end
        touchState.lastPos = input.Position
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        touchState.active = false
        local duration = os.clock() - touchState.startTime
        local totalMoved = touchState.totalMoved
        local isCameraDrag = touchState.isCameraDrag
        local isTap = duration < TAP_MAX_TIME and not isCameraDrag and totalMoved < TAP_MAX_MOVE

        if not isTap then
            touchState.isCameraDrag = false
            return
        end
        if isOverGui(input.Position) then
            touchState.isCameraDrag = false
            return
        end

        if deleteModeEnabled then DeletePartAt(input.Position)
        elseif tpEnabled then TeleportAt(input.Position) end

        touchState.isCameraDrag = false
    end
end)
