-- ==========================================
-- HUB: xcs (Diseño Compacto con Scroll y Botones Flotantes)
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

local touchStartTime = 0
local touchStartPos = Vector2.new(0, 0)
local isDraggingCamera = false

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
local keybinds = { Invisicam = Enum.KeyCode.V, Noclip = Enum.KeyCode.X, Fly = Enum.KeyCode.Z, FreeCam = Enum.KeyCode.C, Fullbright = Enum.KeyCode.B, Teleport = Enum.KeyCode.G, XRay = Enum.KeyCode.K, Delete = Enum.KeyCode.L, Restore = Enum.KeyCode.R }
local listeningFor = nil
local QuickButtons = {}

-- ==========================================
-- SISTEMA DE GUARDADO
-- ==========================================
local function saveData(name, data)
    if writefile then pcall(function() writefile("xcs_" .. name .. ".txt", tostring(data)) end) end
end

local function loadData(name, default)
    if isfile and readfile then
        local success, content = pcall(function() return readfile("xcs_" .. name .. ".txt") end)
        if success and content then return content end
    end
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
            return UDim2.new(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4]))
        end
    end
    return defaultPos
end

local function saveButtonState(btnName, state) saveData("BtnState_"..btnName, state) end
local function loadButtonState(btnName) return loadData("BtnState_"..btnName, "true") == "true" end

-- ==========================================
-- INTERFAZ PRINCIPAL COMPACTA CON SCROLL
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "xcsStyleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Botón flotante mini
local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 45, 0, 45)
MiniBtn.Position = loadPosition("MiniBtn", UDim2.new(0, 15, 0.4, 0))
MiniBtn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MiniBtn.Text = "xcs"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.TextSize = 12
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Visible = false
MiniBtn.Parent = ScreenGui
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)
Instance.new("UIStroke", MiniBtn).Color = Color3.fromRGB(0, 150, 255)

-- Panel Principal
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 180, 0, 300) 
MainFrame.Position = loadPosition("MainFrame", UDim2.new(0.5, -90, 0.5, -150))
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Título del panel principal
local Title = Instance.new("TextButton")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Title.Text = "xcs Hub"
Title.TextColor3 = Color3.fromRGB(200, 200, 200)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

-- Botón Master (Movido arriba a la derecha)
local MasterQuickBtn = Instance.new("TextButton")
MasterQuickBtn.Size = UDim2.new(0, 18, 0, 18)
MasterQuickBtn.Position = UDim2.new(1, -68, 0, 3)
MasterQuickBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
MasterQuickBtn.Text = "👁️"
MasterQuickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MasterQuickBtn.TextSize = 10
MasterQuickBtn.Parent = Title
Instance.new("UICorner", MasterQuickBtn).CornerRadius = UDim.new(0, 4)

local SettingsBtn = Instance.new("TextButton")
SettingsBtn.Size = UDim2.new(0, 18, 0, 18)
SettingsBtn.Position = UDim2.new(1, -45, 0, 3)
SettingsBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SettingsBtn.Text = "⚙️"
SettingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsBtn.TextSize = 10
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

-- ScrollingFrame para los switches
local MainScroll = Instance.new("ScrollingFrame")
MainScroll.Size = UDim2.new(1, 0, 1, -25)
MainScroll.Position = UDim2.new(0, 0, 0, 25)
MainScroll.BackgroundTransparency = 1
MainScroll.BorderSizePixel = 0
MainScroll.ScrollBarThickness = 3
MainScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
MainScroll.CanvasSize = UDim2.new(0, 0, 0, 300) 
MainScroll.Parent = MainFrame

local function createSwitch(parent, yPos, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.75, 0, 0, 20)
    label.Position = UDim2.new(0.06, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local bg = Instance.new("TextButton")
    bg.Size = UDim2.new(0, 30, 0, 16)
    bg.Position = UDim2.new(0.75, 0, yPos, 2)
    bg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    bg.Text = ""
    bg.Parent = parent
    Instance.new("UICorner", bg).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = bg
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    return bg, knob
end

local TPSwitchBg, TPSwitchKnob = createSwitch(MainScroll, 0.05, "TPS")
local SwitchBg, SwitchKnob = createSwitch(MainScroll, 0.15, "Invisicam")
local FPXRaySwitchBg, FPXRaySwitchKnob = createSwitch(MainScroll, 0.25, "FP X-Ray")
local DeleteSwitchBg, DeleteSwitchKnob = createSwitch(MainScroll, 0.35, "Borrador de Paredes") 
local NoclipSwitchBg, NoclipSwitchKnob = createSwitch(MainScroll, 0.45, "Noclip")
local FlySwitchBg, FlySwitchKnob = createSwitch(MainScroll, 0.55, "Fly")
local FreeCamSwitchBg, FreeCamSwitchKnob = createSwitch(MainScroll, 0.65, "Free Cam")
local FullbrightSwitchBg, FullbrightSwitchKnob = createSwitch(MainScroll, 0.75, "Fullbright")

-- ==========================================
-- PANEL DE AJUSTES (TUERCA)
-- ==========================================
local SettingsFrame = Instance.new("Frame")
SettingsFrame.Size = UDim2.new(0, 180, 0, 300) 
SettingsFrame.Position = loadPosition("SettingsFrame", UDim2.new(0.5, -90, 0.5, -150)) 
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
CloseSettingsBtn.ZIndex = 5
CloseSettingsBtn.Parent = SettingsFrame
Instance.new("UICorner", CloseSettingsBtn).CornerRadius = UDim.new(0, 4)

local SettingsScroll = Instance.new("ScrollingFrame")
SettingsScroll.Size = UDim2.new(1, 0, 1, 0)
SettingsScroll.Position = UDim2.new(0, 0, 0, 0)
SettingsScroll.BackgroundTransparency = 1
SettingsScroll.BorderSizePixel = 0
SettingsScroll.ScrollBarThickness = 3
SettingsScroll.ScrollBarImageColor3 = Color3.fromRGB(0, 150, 255)
SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, 700) 
SettingsScroll.Parent = SettingsFrame

-- ==========================================
-- LÓGICAS DE LAS FUNCIONES
-- ==========================================
local function toggleNoclip(state)
    noclipEnabled = state
    NoclipSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    NoclipSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
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

local function toggleDeleteMode(state)
    deleteModeEnabled = state
    DeleteSwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    DeleteSwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    
    if state then
        MainFrame.BackgroundTransparency = 0.5 
    else
        MainFrame.BackgroundTransparency = 0 
    end
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

local function toggleFly(state)
    flyEnabled = state
    FlySwitchBg.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    FlySwitchKnob.Position = state and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
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
makeDraggable(MiniBtn, "MiniBtn")
makeDraggable(SettingsFrame, "SettingsFrame") 

-- ==========================================
-- BOTONES RÁPIDOS INDEPENDIENTES (FLOTANTES)
-- ==========================================
local function createQuickBtn(name, text, initialPos, toggleFunc, getState)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 35, 0, 35)
    btn.Position = loadPosition("Quick_"..name, initialPos)
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

    local startPos = nil
    local isDragging = false
    local dragStartPos = nil

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            startPos = input.Position
            isDragging = false
            dragStartPos = input.Position
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
                btn.BackgroundColor3 = getState() and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(30, 30, 30)
            end
            if isDragging then
                savePosition("Quick_"..name, btn.Position) 
            end
            startPos = nil
            isDragging = false
            dragStartPos = nil
        end
    end)
end

-- Posiciones iniciales
createQuickBtn("TPS", "TPS", UDim2.new(0, 60, 0.15, 0), function() 
    tpEnabled = not tpEnabled
    TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
end, function() return tpEnabled end)

createQuickBtn("Invisicam", "INV", UDim2.new(0, 100, 0.15, 0), function() toggleInvisicam(not invisicamEnabled) end, function() return invisicamEnabled end)
createQuickBtn("FPXRay", "XRY", UDim2.new(0, 140, 0.15, 0), function() toggleFPXRay(not fpXRayEnabled) end, function() return fpXRayEnabled end)
createQuickBtn("DeleteMode", "DEL", UDim2.new(0, 180, 0.15, 0), function() toggleDeleteMode(not deleteModeEnabled) end, function() return deleteModeEnabled end) 
createQuickBtn("Noclip", "NOC", UDim2.new(0, 60, 0.22, 0), function() toggleNoclip(not noclipEnabled) end, function() return noclipEnabled end)
createQuickBtn("Fly", "FLY", UDim2.new(0, 100, 0.22, 0), function() toggleFly(not flyEnabled) end, function() return flyEnabled end)
createQuickBtn("FreeCam", "CAM", UDim2.new(0, 140, 0.22, 0), function() toggleFreeCam(not freeCamEnabled) end, function() return freeCamEnabled end)
createQuickBtn("Fullbright", "LGT", UDim2.new(0, 180, 0.22, 0), function() toggleFullbright(not fullbrightEnabled) end, function() return fullbrightEnabled end)

-- Botón Restaurar
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
-- CONFIGURACIÓN DE QUÉ BOTONES APARECEN
-- ==========================================
local function createQuickConfig(yPos, text, btnName)
    local bg, knob = createSwitch(SettingsScroll, yPos, text)
    
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

local ConfigLabel = Instance.new("TextLabel")
ConfigLabel.Size = UDim2.new(1, 0, 0, 15)
ConfigLabel.Position = UDim2.new(0, 0, 0.65, 0)
ConfigLabel.BackgroundTransparency = 1
ConfigLabel.Text = "--- Botones ---"
ConfigLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
ConfigLabel.Font = Enum.Font.GothamBold
ConfigLabel.TextSize = 9
ConfigLabel.Parent = SettingsScroll

createQuickConfig(0.70, "TPS", "TPS")
createQuickConfig(0.75, "Invisicam", "Invisicam")
createQuickConfig(0.80, "FP X-Ray", "FPXRay")
createQuickConfig(0.85, "Borrador", "DeleteMode")
createQuickConfig(0.90, "Noclip", "Noclip")
createQuickConfig(0.95, "Fly", "Fly")
createQuickConfig(1.00, "Free Cam", "FreeCam")
createQuickConfig(1.05, "Fullbright", "Fullbright")

-- Opción para el botón RST en los ajustes
local RestoreConfigBg, RestoreConfigKnob = createSwitch(SettingsScroll, 1.10, "Botón Restaurar")
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
-- BOTONES DEL MENÚ Y MINIMIZAR
-- ==========================================
TPSwitchBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        tpEnabled = not tpEnabled
        TPSwitchBg.BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
        TPSwitchKnob.Position = tpEnabled and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        if QuickButtons["TPS"] then QuickButtons["TPS"].BackgroundColor3 = tpEnabled and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(30, 30, 30) end
    end
end)
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

-- Lógica del Botón Master (Ojo)
MasterQuickBtn.MouseButton1Click:Connect(function()
    quickButtonsMaster = not quickButtonsMaster
    MasterQuickBtn.BackgroundColor3 = quickButtonsMaster and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(60, 60, 60)
    
    for name, btn in pairs(QuickButtons) do
        if quickButtonsMaster then
            btn.Visible = loadButtonState(name)
        else
            btn.Visible = false
        end
    end
    if quickButtonsMaster then
        RestoreQuickBtn.Visible = loadButtonState("Restore")
    else
        RestoreQuickBtn.Visible = false
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
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
-- PANEL DE AJUSTES (Velocidades y Keybinds)
-- ==========================================
local function createSlider(parent, yPos, text, minVal, maxVal, defaultVal, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.8, 0, 0, 15)
    label.Position = UDim2.new(0.1, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text .. " (" .. defaultVal .. ")"
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local barBg = Instance.new("TextButton")
    barBg.Size = UDim2.new(0.8, 0, 0, 10)
    barBg.Position = UDim2.new(0.1, 0, yPos, 18)
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

createSlider(SettingsScroll, 0.05, "Velocidad Fly", 10, 300, 50, function(val) flySpeed = val end)
createSlider(SettingsScroll, 0.12, "Velocidad Free Cam", 10, 300, 50, function(val) freeCamSpeed = val end)

local function createKeybindBox(yPos, text, keyName)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 0, 20)
    label.Position = UDim2.new(0.1, 0, yPos, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.Font = Enum.Font.Gotham
    label.TextSize = 9
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = SettingsScroll

    local box = Instance.new("TextButton")
    box.Size = UDim2.new(0.25, 0, 0, 20)
    box.Position = UDim2.new(0.65, 0, yPos, 0)
    box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    box.Text = keybinds[keyName].Name
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 9
    box.Parent = SettingsScroll
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 3)

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

createKeybindBox(0.22, "Tecla Invisicam", "Invisicam")
createKeybindBox(0.28, "Tecla Noclip", "Noclip")
createKeybindBox(0.34, "Tecla Fly", "Fly")
createKeybindBox(0.40, "Tecla Free Cam", "FreeCam")
createKeybindBox(0.46, "Tecla Fullbright", "Fullbright")
createKeybindBox(0.52, "Tecla X-Ray", "XRay")
createKeybindBox(0.58, "Tecla TP (PC)", "Teleport") 
createKeybindBox(0.64, "Tecla Borrador", "Delete") 
createKeybindBox(0.70, "Tecla Restaurar", "Restore") 

-- ==========================================
-- TECLAS DE ACCESO RÁPIDO (KEYBINDS) Y TP PC
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
        if input.KeyCode == keybinds.Delete then toggleDeleteMode(not deleteModeEnabled) end 
        if input.KeyCode == keybinds.Restore then RestoreMap() end 
        
        -- TP Instantáneo en PC
        if input.KeyCode == keybinds.Teleport and tpEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local ray = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {char}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
                if result then
                    char.HumanoidRootPart.CFrame = CFrame.new(result.Position + Vector3.new(0, 3, 0))
                end
            end
        end
    end
end)

-- ==========================================
-- SISTEMA DE BORRADO Y TP TÁCTIL (CORREGIDO)
-- ==========================================
local function DeletePartAt(mousePos)
    local ray = Camera:ScreenPointToRay(mousePos.X, mousePos.Y)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(params.FilterDescendantsInstances, p.Character) end
    end
    
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    if result and result.Instance then
        local part = result.Instance
        if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
            table.insert(deletedPartsMemory, {part = part, trans = part.Transparency, collide = part.CanCollide})
            part.Transparency = 1
            part.CanCollide = false
        end
    end
end

-- Click en PC para Borrar
Mouse.Button1Down:Connect(function()
    if deleteModeEnabled then
        DeletePartAt(UserInputService:GetMouseLocation())
    end
end)

-- Toques en Móvil
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touchStartTime = tick(); touchStartPos = input.Position; isDraggingCamera = false
    end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        if (input.Position - touchStartPos).Magnitude > 15 then isDraggingCamera = true end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        local touchDuration = tick() - touchStartTime
        
        if touchDuration < 0.2 and not isDraggingCamera then
            local guiObjects = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
            local touchedUI = false
            for _, obj in ipairs(guiObjects) do if obj:IsDescendantOf(ScreenGui) then touchedUI = true break end end

            if not touchedUI then
                if deleteModeEnabled then
                    DeletePartAt(input.Position)
                elseif tpEnabled then
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
        end
        isDraggingCamera = false
    end
end)
