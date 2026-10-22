-- ==========================================
-- HUB: TP + INVISICAM + NOCLIP + FLY + FREE CAM + FULLBRIGHT
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

-- Variables de Velocidad
local flySpeed = 50
local freeCamSpeed = 50

-- Variables TP
local touchStartTime = 0
local touchStartPos = Vector2.new(0, 0)
local isDraggingCamera = false

-- Variables Fly/Noclip
local noclipConnection = nil
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil

-- Variables Free Cam
local freeCamConnection = nil
local freeCamRotateConnection = nil
local camYaw, camPitch = 0, 0
local camPos = Vector3.new(0, 0, 0)

-- Variables Fullbright
local savedLighting = {}

-- ==========================================
-- INTERFAZ COMPACTA (xcs)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xcsStyleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0, 20, 0.4, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.BackgroundTransparency = 0.3
ToggleBtn.Text = "TP"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 16
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- Panel Principal (Ajustado para 6 switches)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 230, 0, 290) 
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -145)
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

-- Botón de Ajustes (Engranaje)
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

local function createSwitch(yPos, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 25)
    label.Position = UDim2.new(0.06, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = MainFrame

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(0, 38, 0, 20)
    bg.Position = UDim2.new(0.7, 0, yPos, 2)
    bg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bg.Text = ""
    bg.Parent = MainFrame
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    return bg, knob
end

local TPSwitchBg, TPSwitchKnob = createSwitch(0.13, "TP Táctil (Móvil)")
local SwitchBg, SwitchKnob = createSwitch(0.27, "Invisicam")
local NoclipSwitchBg, NoclipSwitchKnob = createSwitch(0.41, "Noclip")
local FlySwitchBg, FlySwitchKnob = createSwitch(0.55, "Fly")
local FreeCamSwitchBg, FreeCamSwitchKnob = createSwitch(0.69, "Free Cam")
local FullbrightSwitchBg, FullbrightSwitchKnob = createSwitch(0.83, "Fullbright")

-- ==========================================
-- PANEL DE AJUSTES (Velocidades)
-- ==========================================
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(0, 230, 0, 130)
SettingsFrame.Position = UDim2.new(0.5, -115, 0.5, 155) -- Aparece abajo del menú principal
SettingsFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SettingsFrame.BorderSizePixel = 0
SettingsFrame.Visible = false
SettingsFrame.Parent = ScreenGui
Instance.new("UICorner", SettingsFrame).CornerRadius = UDim.new(0, 10)

local function createSlider(yPos, text, minVal, maxVal, defaultVal, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 20)
    label.Position = UDim2.new(0.1, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. " (" .. defaultVal .. ")"
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = SettingsFrame

    local barBg = Instance.new("TextButton")
    barBg.Size = UDim2.new(0.8, 0, 0, 15)
    barBg.Position = UDim2.new(0.1, 0, yPos, 22)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    barBg.Text = ""
    barBg.Parent = SettingsFrame
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

createSlider(0.1, "Velocidad Fly", 10, 300, 50, function(val) flySpeed = val end)
createSlider(0.6, "Velocidad Free Cam", 10, 300, 50, function(val) freeCamSpeed = val end)

SettingsBtn.Activated:Connect(function()
    SettingsFrame.Visible = not SettingsFrame.Visible
end)

-- ==========================================
-- SISTEMA DE ARRASTRE
-- ==========================================
local function makeDraggable(frame)
    local dragging, dragInput, mousePos, framePos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; mousePos = input.Position; framePos = frame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
            
            if frame == MainFrame and SettingsFrame.Visible then
                SettingsFrame.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset, frame.Position.Y.Scale, frame.Position.Y.Offset + 300)
            end
        end
    end)
end
makeDraggable(MainFrame)
makeDraggable(ToggleBtn)
makeDraggable(SettingsFrame)

-- ==========================================
-- TP (Móvil y PC)
-- ==========================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touchStartTime = tick()
        touchStartPos = input.Position
        isDraggingCamera = false
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

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local targetPos = Mouse.Hit.Position
            char.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        end
    end
end)

-- ==========================================
-- NOCLIP
-- ==========================================
local function toggleNoclip(state)
    noclipEnabled = state
    if state then
        NoclipSwitchBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        NoclipSwitchKnob.Position = UDim2.new(0, 20, 0.5, -8)
        
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
                end
            end
        end)
    else
        NoclipSwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        NoclipSwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
        if noclipConnection then noclipConnection:Disconnect() end
        
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.CanCollide = true end
        end
    end
end

NoclipSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleNoclip(not noclipEnabled)
    end
end)

-- ==========================================
-- FULLBRIGHT
-- ==========================================
local function toggleFullbright(state)
    fullbrightEnabled = state
    if state then
        FullbrightSwitchBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        FullbrightSwitchKnob.Position = UDim2.new(0, 20, 0.5, -8)
        
        -- Guardar la iluminación original
        savedLighting.Ambient = Lighting.Ambient
        savedLighting.OutdoorAmbient = Lighting.OutdoorAmbient
        savedLighting.Brightness = Lighting.Brightness
        savedLighting.ClockTime = Lighting.ClockTime
        savedLighting.FogEnd = Lighting.FogEnd
        savedLighting.GlobalShadows = Lighting.GlobalShadows

        -- Aplicar Fullbright
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12 -- Mediodía
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
    else
        FullbrightSwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        FullbrightSwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
        
        -- Restaurar iluminación original
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

FullbrightSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleFullbright(not fullbrightEnabled)
    end
end)

-- ==========================================
-- FLY (SISTEMA AK ADMIN / xcs)
-- ==========================================
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
    if state then
        if freeCamEnabled then
            FreeCamSwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            FreeCamSwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
            freeCamEnabled = false
            if freeCamConnection then freeCamConnection:Disconnect() end
            if freeCamRotateConnection then freeCamRotateConnection:Disconnect() end
            Camera.CameraType = Enum.CameraType.Custom
            local c = LocalPlayer.Character
            if c and c:FindFirstChild("Humanoid") then 
                c.Humanoid.WalkSpeed = 16
                c.Humanoid.JumpPower = 50
            end
        end

        FlySwitchBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        FlySwitchKnob.Position = UDim2.new(0, 20, 0.5, -8)
        
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
        FlySwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        FlySwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
        if flyConnection then flyConnection:Disconnect() end
        if flyBodyVelocity then flyBodyVelocity:Destroy() end
        if flyBodyGyro then flyBodyGyro:Destroy() end
    end
end

FlySwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleFly(not flyEnabled)
    end
end)

-- ==========================================
-- FREE CAM (CON VELOCIDAD DINÁMICA)
-- ==========================================
local function toggleFreeCam(state)
    freeCamEnabled = state
    if state then
        if flyEnabled then
            FlySwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            FlySwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
            flyEnabled = false
            if flyConnection then flyConnection:Disconnect() end
            if flyBodyVelocity then flyBodyVelocity:Destroy() end
            if flyBodyGyro then flyBodyGyro:Destroy() end
        end

        FreeCamSwitchBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        FreeCamSwitchKnob.Position = UDim2.new(0, 20, 0.5, -8)
        
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
        FreeCamSwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        FreeCamSwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
        
        if freeCamConnection then
            freeCamConnection:Disconnect()
            freeCamConnection = nil
        end
        if freeCamRotateConnection then
            freeCamRotateConnection:Disconnect()
            freeCamRotateConnection = nil
        end
        
        Camera.CameraType = Enum.CameraType.Custom
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
    end
end

FreeCamSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleFreeCam(not freeCamEnabled)
    end
end)

-- ==========================================
-- INVISICAM
-- ==========================================
local function toggleInvisicam(state)
    invisicamEnabled = state
    if state then
        pcall(function() LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam end)
        SwitchBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        SwitchKnob.Position = UDim2.new(0, 20, 0.5, -8)
    else
        pcall(function() LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom end)
        SwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        SwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
    end
end

SwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleInvisicam(not invisicamEnabled)
    end
end)

-- ==========================================
-- SWITCH TP Y BOTÓN FLOTANTE
-- ==========================================
TPSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tpEnabled = not tpEnabled
        if tpEnabled then
            TPSwitchBg.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            TPSwitchKnob.Position = UDim2.new(0, 20, 0.5, -8)
        else
            TPSwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            TPSwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
        end
    end
end)

ToggleBtn.Activated:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    if not MainFrame.Visible then SettingsFrame.Visible = false end
end)
