-- ==========================================
-- HUB: xcs (Botones Rápidos sin Colisión)
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
local noclipEnabled = false
local flyEnabled = false
local freeCamEnabled = false
local fullbrightEnabled = false
local quickAccessEnabled = false

local flySpeed = 50
local freeCamSpeed = 50

local touchStartTime = 0
local touchStartPos = Vector2.new(0, 0)
local isDraggingCamera = false

local noclipConnection = nil
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil

local freeCamConnection = nil
local freeCamRotateConnection = nil
local camYaw, camPitch = 0, 0
local camPos = Vector3.new(0, 0, 0)

local savedLighting = {}
local keybinds = { Invisicam = Enum.KeyCode.V, Noclip = Enum.KeyCode.X, Fly = Enum.KeyCode.Z, FreeCam = Enum.KeyCode.C, Fullbright = Enum.KeyCode.B }
local listeningFor = nil
local QuickButtons = {}

-- ==========================================
-- SISTEMA DE GUARDADO
-- ==========================================
local function saveData(name, pos)
    if writefile then
        local data = tostring(pos.X.Scale) .. "," .. tostring(pos.X.Offset) .. "," .. tostring(pos.Y.Scale) .. "," .. tostring(pos.Y.Offset)
        pcall(function() writefile("xcs_" .. name .. ".txt", data) end)
    end
end

local function loadData(name, defaultPos)
    if isfile and readfile then
        local success, content = pcall(function() return readfile("xcs_" .. name .. ".txt") end)
        if success and content then
            local args = string.split(content, ",")
            if #args == 4 then
                return UDim2.new(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4]))
            end
        end
    end
    return defaultPos
end

-- ==========================================
-- INTERFAZ PRINCIPAL
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xcsStyleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = loadData("ToggleBtn", UDim2.new(0, 20, 0.4, 0))
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.BackgroundTransparency = 0.3
ToggleBtn.Text = "TP"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 16
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 230, 0, 330) 
MainFrame.Position = loadData("MainFrame", UDim2.new(0.5, -115, 0.5, -165))
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.Text = "xcs Hub"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 20, 0, 20)
SettingsBtn.Position = UDim2.new(1, -25, 0, 5)
SettingsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsBtn.Text = "⚙️"
SettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsBtn.TextSize = 12
SettingsBtn.Font = Enum.Font.GothamBold
SettingsBtn.Parent = Title
Instance.new("UICorner", SettingsBtn).CornerRadius = UDim.new(0, 4)

local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(0, 230, 0, 400) 
SettingsFrame.Position = loadData("SettingsFrame", UDim2.new(0.5, -115, 0.5, 155))
SettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = ScreenGui
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 10)

local function createSwitch(parent, yPos, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 25)
    label.Position = UDim2.new(0.06, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(0, 38, 0, 20)
    bg.Position = UDim2.new(0.7, 0, yPos, 2)
    bg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bg.Text = ""
    bg.Parent = parent
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    return bg, knob
end

local TPSwitchBg, TPSwitchKnob = createSwitch(MainFrame, 0.12, "TPS")
local SwitchBg, SwitchKnob = createSwitch(MainFrame, 0.24, "Invisicam")
local NoclipSwitchBg, NoclipSwitchKnob = createSwitch(MainFrame, 0.36, "Noclip")
local FlySwitchBg, FlySwitchKnob = createSwitch(MainFrame, 0.48, "Fly")
local FreeCamSwitchBg, FreeCamSwitchKnob = createSwitch(MainFrame, 0.60, "Free Cam")
local FullbrightSwitchBg, FullbrightSwitchKnob = createSwitch(MainFrame, 0.72, "Fullbright")

local ToggleQuickBtn = Instance.new("TextButton")
ToggleQuickBtn.Size = UDim2.new(0.8, 0, 0, 30)
ToggleQuickBtn.Position = UDim2.new(0.1, 0, 0.85, 0)
ToggleQuickBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
ToggleQuickBtn.Text = "Mostrar Botones Rápidos"
ToggleQuickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleQuickBtn.Font = Enum.Font.GothamBold
ToggleQuickBtn.TextSize = 11
ToggleQuickBtn.Parent = MainFrame
Instance.new("UICorner", ToggleQuickBtn).CornerRadius = UDim.new(0, 4)

-- ==========================================
-- LÓGICAS DE LAS FUNCIONES
-- ==========================================
local function toggleNoclip(state)
    noclipEnabled = state
    NoclipSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    NoclipSwitchKnob.Position = state and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    if QuickButtons["Noclip"] then QuickButtons["Noclip"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
    else
        if noclipConnection then noclipConnection:Disconnect() end
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CanCollide = true end
        end
    end
end

local function toggleFullbright(state)
    fullbrightEnabled = state
    FullbrightSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FullbrightSwitchKnob.Position = state and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
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

local function toggleFly(state)
    flyEnabled = state
    FlySwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FlySwitchKnob.Position = state and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    if QuickButtons["Fly"] then QuickButtons["Fly"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        if freeCamEnabled then toggleFreeCam(false) end
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
    end
end

local function toggleFreeCam(state)
    freeCamEnabled = state
    FreeCamSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FreeCamSwitchKnob.Position = state and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
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

        freeCamConnection = RunService.RenderStepped:Connect(function(dt)
            if not freeCamEnabled then return end
            local moveVector = Vector3.zero
            local rot = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)
            
            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector - rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector - rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveVector = moveVector - Vector3.new(0, 1, 0) end
            else
                local c = LocalPlayer.Character
                if c and c:FindFirstChild("Humanoid") then
                    local humanoidMove = c.Humanoid.MoveDirection
                    if humanoidMove.Magnitude > 0.1 then
                        local move = Camera.CFrame:VectorToObjectSpace(humanoidMove)
                        moveVector = (rot.LookVector * -move.Z) + (rot.RightVector * move.X)
                    end
                end
            end

            if moveVector.Magnitude > 0 then
                camPos = camPos + (moveVector.Unit * freeCamSpeed * dt)
            end
            Camera.CFrame = CFrame.new(camPos, camPos + rot.LookVector)
        end)
        
        freeCamRotateConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
            if not freeCamEnabled or gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Touch then
                camYaw = camYaw - input.Delta.X * 0.005
                camPitch = math.clamp(camPitch - input.Delta.Y * 0.005, math.rad(-89), math.rad(89))
            end
        end)
    else
        if freeCamConnection then freeCamConnection:Disconnect() end
        if freeCamRotateConnection then freeCamRotateConnection:Disconnect() end
        Camera.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
    end
end

local function toggleInvisicam(state)
    invisicamEnabled = state
    SwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    SwitchKnob.Position = state and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    if QuickButtons["Invisicam"] then QuickButtons["Invisicam"].BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end

    if state then
        pcall(function() LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end)
    else
        pcall(function() LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom end)
    end
end

-- ==========================================
-- SISTEMA DE ARRASTRE CON GUARDADO
-- ==========================================
local function makeDraggable(frame, saveName)
    local dragging, dragInput, mousePos, framePos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then 
                dragging = false
                if saveName then saveData(saveName, frame.Position) end
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
makeDraggable(ToggleBtn, "ToggleBtn")
makeDraggable(SettingsFrame, "SettingsFrame")

-- ==========================================
-- BOTONES RÁPIDOS SIN COLISIÓN
-- ==========================================
local function createQuickBtn(name, text, initialPos, toggleFunc, getState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 45)
    btn.Position = loadData("Quick_"..name, initialPos)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.Visible = false
    btn.Active = true -- Permite que reciba clics
    btn.Parent = ScreenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    QuickButtons[name] = btn

    local startPos = nil
    local isDragging = false
    local dragStartPos = nil

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            startPos = input.Position
            isDragging = false
            dragStartPos = input.Position
            -- TRAER AL FRENTE: Hace que el botón que tocas esté por encima de los demás
            btn.Parent = ScreenGui 
            btn.ZIndex = 100 
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
                btn.BackgroundColor3 = getState() and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40)
            end
            if isDragging then
                saveData("Quick_"..name, btn.Position) -- Guardar posición al soltar
            end
            startPos = nil
            isDragging = false
            dragStartPos = nil
        end
    end)
end

createQuickBtn("TPS", "TPS", UDim2.new(0, 80, 0.15, 0), function() 
    tpEnabled = not tpEnabled
    TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
end, function() return tpEnabled end)

createQuickBtn("Invisicam", "INV", UDim2.new(0, 80, 0.25, 0), function() toggleInvisicam(not invisicamEnabled) end, function() return invisicamEnabled end)
createQuickBtn("Noclip", "NOC", UDim2.new(0, 80, 0.35, 0), function() toggleNoclip(not noclipEnabled) end, function() return noclipEnabled end)
createQuickBtn("Fly", "FLY", UDim2.new(0, 80, 0.45, 0), function() toggleFly(not flyEnabled) end, function() return flyEnabled end)
createQuickBtn("FreeCam", "CAM", UDim2.new(0, 80, 0.55, 0), function() toggleFreeCam(not freeCamEnabled) end, function() return freeCamEnabled end)
createQuickBtn("Fullbright", "LGT", UDim2.new(0, 80, 0.65, 0), function() toggleFullbright(not fullbrightEnabled) end, function() return fullbrightEnabled end)

-- ==========================================
-- BOTONES DEL MENÚ Y AJUSTES
-- ==========================================
TPSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tpEnabled = not tpEnabled
        TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
        TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 20, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        if QuickButtons["TPS"] then QuickButtons["TPS"].BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(40, 40, 40) end
    end
end)
SwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then toggleInvisicam(not invisicamEnabled) end
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

ToggleBtn.Activated:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

ToggleQuickBtn.MouseButton1Click:Connect(function()
    quickAccessEnabled = not quickAccessEnabled
    ToggleQuickBtn.BackgroundColor3 = quickAccessEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    ToggleQuickBtn.Text = quickAccessEnabled and "Ocultar Botones Rápidos" or "Mostrar Botones Rápidos"
    
    for _, btn in pairs(QuickButtons) do
        btn.Visible = quickAccessEnabled
    end
end)

SettingsBtn.Activated:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
end)

-- ==========================================
-- PANEL DE AJUSTES (Velocidades y Keybinds)
-- ==========================================
local function createSlider(parent, yPos, text, minVal, maxVal, defaultVal, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 20)
    label.Position = UDim2.new(0.1, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. " (" .. defaultVal .. ")"
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local barBg = Instance.new("TextButton")
    barBg.Size = UDim2.new(0.8, 0, 0, 15)
    barBg.Position = UDim2.new(0.1, 0, yPos, 22)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    barBg.Text = ""
    barBg.Parent = parent
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
            label.Text = text .. " (" .. val .. ")"
            callback(val)
        end
    end)
end

createSlider(SettingsFrame, 0.05, "Velocidad Fly", 10, 300, 50, function(val) flySpeed = val end)
createSlider(SettingsFrame, 0.2, "Velocidad Free Cam", 10, 300, 50, function(val) freeCamSpeed = val end)

local function createKeybindBox(yPos, text, keyName)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 25)
    label.Position = UDim2.new(0.1, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = SettingsFrame

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0.3, 0, 0, 25)
    box.Position = UDim2.new(0.6, 0, yPos, 0)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.Text = keybinds[keyName].Name
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.Parent = SettingsFrame
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    box.MouseButton1Click:Connect(function()
        box.Text = "..."
        box.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
        listeningFor = keyName
        
        local connection
        connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Keyboard then
                keybinds[keyName] = input.KeyCode
                box.Text = input.KeyCode.Name
                box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                listeningFor = nil
                connection:Disconnect()
            end
        end)
    end)
end

createKeybindBox(0.4, "Tecla Invisicam", "Invisicam")
createKeybindBox(0.5, "Tecla Noclip", "Noclip")
createKeybindBox(0.6, "Tecla Fly", "Fly")
createKeybindBox(0.7, "Tecla Free Cam", "FreeCam")
createKeybindBox(0.8, "Tecla Fullbright", "Fullbright")

-- ==========================================
-- TECLAS DE ACCESO RÁPIDO (KEYBINDS)
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
    end
end)

-- ==========================================
-- TP TÁCTIL Y TECLADO (T)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touchStartTime = tick(); touchStartPos = input.Position; isDraggingCamera = false
    end
    if input.KeyCode == Enum.KeyCode.T then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0, 3, 0))
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        if (input.Position - touchStartPos).Magnitude > 15 then isDraggingCamera = true end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed or not tpEnabled then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        local touchDuration = tick() - touchStartTime
        if touchDuration < 0.2 and not isDraggingCamera then
            local guiObjects = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
            local touchedUI = false
            for _, obj in ipairs(guiObjects) do if obj:IsDescendantOf(ScreenGui) then touchedUI = true break end end

            if not touchedUI then
                local ray = Camera:ScreenPointToRay(input.Position.X, input.Position.Y)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                
                local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
                if result then
                    local char = LocalPlayer.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        char.HumanoidRootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
        isDraggingCamera = false
    end
end)
