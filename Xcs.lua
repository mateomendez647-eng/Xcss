-- ==========================================
-- HUB: TP + INVISICAM + NOCLIP + FLY (xcs)
-- ==========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

print("¡Script de xcs cargado correctamente!") -- Si tu amigo no ve esto, el script no se ejecutó.

local tpEnabled = false
local invisicamEnabled = false
local noclipEnabled = false
local flyEnabled = false

-- Variables TP
local touchStartTime = 0
local touchStartPos = Vector2.new(0, 0)
local isDraggingCamera = false

-- Variables Fly/Noclip
local noclipConnection = nil
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flySpeed = 50

-- ==========================================
-- INTERFAZ COMPACTA (xcs)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xcsStyleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true -- Ayuda en celulares con notch
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
local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(1, 0)
BtnCorner.Parent = ToggleBtn

-- Panel Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 230, 0, 210) 
-- Forzamos la posición al centro exacto de la pantalla
MainFrame.Position = UDim2.new(0.5, -115, 0.5, -105)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 10)
FrameCorner.Parent = MainFrame

local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.Text = "xcs Hub"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = MainFrame
local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

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
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = bg

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = knob
    
    return bg, knob
end

local TPSwitchBg, TPSwitchKnob = createSwitch(0.18, "TP Táctil (Móvil)")
local SwitchBg, SwitchKnob = createSwitch(0.38, "Invisicam")
local NoclipSwitchBg, NoclipSwitchKnob = createSwitch(0.58, "Noclip")
local FlySwitchBg, FlySwitchKnob = createSwitch(0.78, "Fly")

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
        end
    end)
end
makeDraggable(MainFrame)
makeDraggable(ToggleBtn)

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
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        NoclipSwitchBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        NoclipSwitchKnob.Position = UDim2.new(0, 2, 0.5, -8)
        
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        
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
-- FLY (SISTEMA AK ADMIN / xcs)
-- ==========================================
local function getMoveDirection()
    local c = LocalPlayer.Character
    if not c then return Vector3.zero end
    local humanoid = c:FindFirstChild("Humanoid")
    if not humanoid or humanoid.MoveDirection.Magnitude == 0 then 
        return Vector3.zero 
    end
    
    local move = Camera.CFrame:VectorToObjectSpace(humanoid.MoveDirection)
    return (Camera.CFrame * CFrame.new(move.X, 0, move.Z)).Position - Camera.CFrame.Position
end

local function toggleFly(state)
    flyEnabled = state
    
    if state then
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

        flyConnection = RunService.RenderStepped:Connect(function()
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
        
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end

        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
    end
end

FlySwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        toggleFly(not flyEnabled)
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

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
