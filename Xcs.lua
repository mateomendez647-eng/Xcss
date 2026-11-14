-- ==========================================
-- HUB: xcs (Neon Glass v3.0 - Modular)
-- Stealth Avanzado + Anti-Rubberband TP + Server Hop Variado
-- ==========================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local ProximityPromptService = game:GetService("ProximityPromptService")

math.randomseed(tick() * 1000)

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local isTouchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ==========================================
-- 🛡️ MÓDULO DE SIGILO (STEALTH)
-- ==========================================
local Stealth = {}
local _stealthSeed = tick() % 1000
local realDisconnects = setmetatable({}, { __mode = "k" })

local function stealthName()
    _stealthSeed = _stealthSeed + 1
    local prefixes = {"Frame", "TextLabel", "ImageLabel", "UICorner", "UIStroke", "ScrollingFrame", "TextButton", "ImageButton", "ViewportFrame"}
    return prefixes[math.random(1, #prefixes)] .. "_" .. string.format("%04x", math.random(0, 0xFFFF))
end

function Stealth.HideConnections(connection)
    if not connection then return connection end
    pcall(function()
        realDisconnects[connection] = connection.Disconnect
        if setmetatable then
            local oldmt = getmetatable(connection)
            if oldmt then
                setmetatable(connection, {
                    __index = function(_, k)
                        if k == "Disconnect" then return function() end end
                        return oldmt.__index[k]
                    end
                })
            end
        end
    end)
    return connection
end

function Stealth.Disconnect(connection)
    if not connection then return end
    local fn = realDisconnects[connection]
    if fn then
        pcall(fn, connection)
        realDisconnects[connection] = nil
    else
        pcall(function() connection:Disconnect() end)
    end
end

function Stealth.RandomizeName(instance)
    if instance and typeof(instance) == "Instance" then
        pcall(function() instance.Name = stealthName() end)
    end
end

-- ==========================================
-- 🧹 GESTOR DE LIMPIEZA CENTRALIZADO (MAID)
-- ==========================================
local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end

function Maid:GiveTask(taskObj)
    if not taskObj then return taskObj end
    table.insert(self._tasks, taskObj)
    return taskObj
end

function Maid:DoCleaning()
    for i = #self._tasks, 1, -1 do
        local taskObj = self._tasks[i]
        self._tasks[i] = nil
        local t = typeof(taskObj)
        if t == "RBXScriptConnection" then
            Stealth.Disconnect(taskObj)
        elseif t == "Instance" then
            pcall(function() taskObj:Destroy() end)
        elseif t == "function" then
            pcall(taskObj)
        elseif type(taskObj) == "table" and taskObj.Destroy then
            pcall(function() taskObj:Destroy() end)
        end
    end
end

local HubMaid = Maid.new()

-- ==========================================
-- 🎨 TEMAS NEON GLASS DINÁMICOS
-- ==========================================
local PRESET_THEMES = {
    ["Neon Cyan"] = {
        BgMain      = Color3.fromRGB(13, 17, 26),
        BgHeader    = Color3.fromRGB(18, 24, 36),
        BgCard      = Color3.fromRGB(22, 29, 43),
        BgCardOn    = Color3.fromRGB(16, 48, 38),
        Accent      = Color3.fromRGB(0, 210, 255),
        AccentGreen = Color3.fromRGB(0, 220, 120),
        AccentRed   = Color3.fromRGB(235, 65, 85),
        AccentAmber = Color3.fromRGB(240, 150, 30),
        SwitchOff   = Color3.fromRGB(45, 55, 72),
        TextMain    = Color3.fromRGB(240, 245, 255),
        TextMuted   = Color3.fromRGB(145, 160, 185),
    },
    ["Crimson"] = {
        BgMain      = Color3.fromRGB(22, 13, 18),
        BgHeader    = Color3.fromRGB(32, 18, 25),
        BgCard      = Color3.fromRGB(40, 22, 31),
        BgCardOn    = Color3.fromRGB(65, 22, 38),
        Accent      = Color3.fromRGB(255, 55, 95),
        AccentGreen = Color3.fromRGB(255, 75, 110),
        AccentRed   = Color3.fromRGB(235, 65, 85),
        AccentAmber = Color3.fromRGB(245, 165, 45),
        SwitchOff   = Color3.fromRGB(65, 42, 52),
        TextMain    = Color3.fromRGB(255, 240, 245),
        TextMuted   = Color3.fromRGB(185, 145, 160),
    },
    ["Emerald"] = {
        BgMain      = Color3.fromRGB(12, 22, 18),
        BgHeader    = Color3.fromRGB(17, 32, 26),
        BgCard      = Color3.fromRGB(21, 40, 33),
        BgCardOn    = Color3.fromRGB(18, 65, 48),
        Accent      = Color3.fromRGB(0, 230, 140),
        AccentGreen = Color3.fromRGB(0, 230, 140),
        AccentRed   = Color3.fromRGB(235, 65, 85),
        AccentAmber = Color3.fromRGB(240, 175, 40),
        SwitchOff   = Color3.fromRGB(40, 62, 54),
        TextMain    = Color3.fromRGB(240, 255, 248),
        TextMuted   = Color3.fromRGB(145, 185, 168),
    },
    ["Amethyst"] = {
        BgMain      = Color3.fromRGB(18, 14, 28),
        BgHeader    = Color3.fromRGB(26, 20, 40),
        BgCard      = Color3.fromRGB(33, 26, 50),
        BgCardOn    = Color3.fromRGB(52, 34, 82),
        Accent      = Color3.fromRGB(175, 95, 255),
        AccentGreen = Color3.fromRGB(155, 110, 255),
        AccentRed   = Color3.fromRGB(235, 65, 85),
        AccentAmber = Color3.fromRGB(240, 160, 45),
        SwitchOff   = Color3.fromRGB(55, 46, 76),
        TextMain    = Color3.fromRGB(245, 240, 255),
        TextMuted   = Color3.fromRGB(165, 150, 195),
    },
    ["Minimal Dark"] = {
        BgMain      = Color3.fromRGB(16, 16, 18),
        BgHeader    = Color3.fromRGB(24, 24, 27),
        BgCard      = Color3.fromRGB(30, 30, 34),
        BgCardOn    = Color3.fromRGB(48, 48, 54),
        Accent      = Color3.fromRGB(220, 220, 230),
        AccentGreen = Color3.fromRGB(90, 210, 130),
        AccentRed   = Color3.fromRGB(235, 65, 85),
        AccentAmber = Color3.fromRGB(235, 160, 50),
        SwitchOff   = Color3.fromRGB(55, 55, 62),
        TextMain    = Color3.fromRGB(245, 245, 248),
        TextMuted   = Color3.fromRGB(150, 150, 160),
    }
}

local THEME_ORDER = {"Neon Cyan", "Crimson", "Emerald", "Amethyst", "Minimal Dark"}
local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- ==========================================
-- 💾 SISTEMA UNIFICADO DE CONFIGURACIÓN (JSON)
-- ==========================================
local CONFIG_FILE = "xcs_config.json"

local function buildDefaultProfile()
    return {
        Theme = "Neon Cyan",
        GlassTransparency = 0.12,
        UiScale = 1.0,
        FlySpeed = 50,
        FreeCamSpeed = 50,
        AntiAFK = true,
        FPSBooster = false,
        Keybinds = {
            Invisicam  = "V",
            Noclip     = "X",
            Fly        = "Z",
            FreeCam    = "C",
            Fullbright = "B",
            Teleport   = "G",
            XRay       = "K",
            Delete     = "L",
            Restore    = "R",
            ESP        = "H",
            InfJump    = "J",
        },
        QuickVisible = {
            TPS = true, Invisicam = true, FPXRay = true, ESP = true,
            DeleteMode = true, Noclip = true, InfJump = true, Fly = true,
            FreeCam = true, Fullbright = true, ThirdPerson = true,
            InstantInteract = true, Restore = true
        },
        Positions = {
            MainFrame             = {x = 20,  y = 90},
            MiniBtn               = {x = 15,  y = 200},
            Quick_TPS             = {x = 60,  y = 100},
            Quick_Invisicam       = {x = 100, y = 100},
            Quick_FPXRay          = {x = 140, y = 100},
            Quick_ESP             = {x = 180, y = 100},
            Quick_DeleteMode      = {x = 220, y = 100},
            Quick_Noclip          = {x = 60,  y = 145},
            Quick_InfJump         = {x = 100, y = 145},
            Quick_Fly             = {x = 140, y = 145},
            Quick_FreeCam         = {x = 180, y = 145},
            Quick_Fullbright      = {x = 220, y = 145},
            Quick_ThirdPerson     = {x = 260, y = 145},
            Quick_Restore         = {x = 60,  y = 190},
            Quick_InstantInteract = {x = 100, y = 190},
        }
    }
end

local function deepCopy(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = (type(v) == "table") and deepCopy(v) or v
    end
    return copy
end

local function mergeMissing(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            target[k] = (type(v) == "table") and deepCopy(v) or v
        elseif type(v) == "table" and type(target[k]) == "table" then
            mergeMissing(target[k], v)
        end
    end
end

local Store = {
    ActiveProfile = "Default",
    Profiles = {
        Default = buildDefaultProfile()
    }
}

local function saveStore()
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(Store))
        end
    end)
end

local function loadStore()
    pcall(function()
        if isfile and readfile and isfile(CONFIG_FILE) then
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(decoded) == "table" and type(decoded.Profiles) == "table" then
                Store = decoded
            end
        end
    end)
    if not Store.Profiles[Store.ActiveProfile] then
        Store.ActiveProfile = "Default"
    end
    if not Store.Profiles.Default then
        Store.Profiles.Default = buildDefaultProfile()
    end
    mergeMissing(Store.Profiles[Store.ActiveProfile], buildDefaultProfile())
end

loadStore()
local Config = Store.Profiles[Store.ActiveProfile]
local THEME = PRESET_THEMES[Config.Theme] or PRESET_THEMES["Neon Cyan"]

local function getSavedUDim2(key)
    local pos = Config.Positions[key]
    if pos and pos.x and pos.y then
        return UDim2.new(0, pos.x, 0, pos.y)
    end
    return UDim2.new(0, 50, 0, 50)
end

local function setSavedUDim2(key, udim)
    Config.Positions[key] = {x = math.floor(udim.X.Offset), y = math.floor(udim.Y.Offset)}
    saveStore()
end

-- ==========================================
-- ⚙️ ESTADOS Y VARIABLES DE MÓDULOS
-- ==========================================
local State = {
    TPS = false,
    Invisicam = false,
    FPXRay = false,
    ESP = false,
    DeleteMode = false,
    Noclip = false,
    InfJump = false,
    Fly = false,
    FreeCam = false,
    Fullbright = false,
    ThirdPerson = false,
    InstantInteract = false,
}

local quickButtonsMaster = true
local hubUnloaded = false
local listeningFor = nil
local spectatingPlayer = nil
local filterQuery = ""

local QuickButtons = {}
local QuickButtonStrokes = {}
local ToggleUpdaters = {}
local ThemeCallbacks = {}

local function registerThemeCallback(fn)
    table.insert(ThemeCallbacks, fn)
    fn(THEME)
end

-- Conexiones y cachés de rendimiento
local noclipConnection = nil
local cachedCharParts = {}
local originalPartCollide = setmetatable({}, { __mode = "k" })
local flyConnection, flyAttachment, flyLinearVel, flyAlignOri = nil, nil, nil, nil
local fpXRayConnection, invisicamConnection, thirdPersonConnection = nil, nil, nil
local transparentParts = {}
local deletedPartsMemory = {}
local espHighlights = {}
local espCharConnections = {}
local freeCamConnection, freeCamRotateConnection = nil, nil
local camYaw, camPitch = 0, 0
local camPos = Vector3.zero
local savedLighting = {}

-- Caché reutilizable de RaycastParams para FPXRay
local xrayFilterList = {Camera}
local xrayRayParams = RaycastParams.new()
xrayRayParams.FilterType = Enum.RaycastFilterType.Exclude

local function rebuildXRayFilter()
    table.clear(xrayFilterList)
    table.insert(xrayFilterList, Camera)
    if LocalPlayer.Character then
        table.insert(xrayFilterList, LocalPlayer.Character)
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            table.insert(xrayFilterList, plr.Character)
        end
    end
    xrayRayParams.FilterDescendantsInstances = xrayFilterList
end

-- ==========================================
-- ⚡ PACK DE SESIÓN, RENDIMIENTO Y SERVER HOP VARIADO
-- ==========================================
local gfxBackup = setmetatable({}, { __mode = "k" })
local savedGfxLighting = {}
local fpsDescendantConn = nil

local function optimizeSingleInstance(obj)
    if obj:IsA("BasePart") then
        if not gfxBackup[obj] then
            gfxBackup[obj] = { Material = obj.Material, Reflectance = obj.Reflectance, CastShadow = obj.CastShadow }
        end
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
        obj.CastShadow = false
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
        if not gfxBackup[obj] then
            gfxBackup[obj] = { Enabled = obj.Enabled }
        end
        obj.Enabled = false
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        if not gfxBackup[obj] then
            gfxBackup[obj] = { Transparency = obj.Transparency }
        end
        obj.Transparency = 1
    end
end

local function toggleFPSBooster(state)
    Config.FPSBooster = state
    saveStore()

    if state then
        savedGfxLighting = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
            EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
        }
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        pcall(function()
            Lighting.EnvironmentDiffuseScale = 0
            Lighting.EnvironmentSpecularScale = 0
        end)

        for _, obj in ipairs(Workspace:GetDescendants()) do
            optimizeSingleInstance(obj)
        end

        Stealth.Disconnect(fpsDescendantConn)
        fpsDescendantConn = Stealth.HideConnections(Workspace.DescendantAdded:Connect(function(obj)
            if Config.FPSBooster then
                optimizeSingleInstance(obj)
            end
        end))
    else
        Stealth.Disconnect(fpsDescendantConn)
        fpsDescendantConn = nil

        if savedGfxLighting.GlobalShadows ~= nil and not State.Fullbright then
            Lighting.GlobalShadows = savedGfxLighting.GlobalShadows
            Lighting.FogEnd = savedGfxLighting.FogEnd
            pcall(function()
                Lighting.EnvironmentDiffuseScale = savedGfxLighting.EnvironmentDiffuseScale
                Lighting.EnvironmentSpecularScale = savedGfxLighting.EnvironmentSpecularScale
            end)
        end

        for obj, props in pairs(gfxBackup) do
            if obj and obj.Parent then
                for propName, origVal in pairs(props) do
                    pcall(function() obj[propName] = origVal end)
                end
            end
        end
        gfxBackup = setmetatable({}, { __mode = "k" })
    end
end

HubMaid:GiveTask(LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK and not hubUnloaded then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end))

local function performRejoin(btn)
    local origText = btn.Text
    btn.Text = "⏳ Reconectando..."
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
    if not ok then
        btn.Text = "❌ No se pudo reconectar"
        task.wait(1.5)
        if btn and btn.Parent then btn.Text = origText end
    end
end

-- Historial persistente de servidores visitados para evitar repeticiones
local SERVERS_FILE = "xcs_servers.json"
local VisitedStore = {}

local function loadVisitedServers()
    pcall(function()
        if isfile and readfile and isfile(SERVERS_FILE) then
            local decoded = HttpService:JSONDecode(readfile(SERVERS_FILE))
            if type(decoded) == "table" then
                VisitedStore = decoded
            end
        end
    end)
    local placeKey = tostring(game.PlaceId)
    if type(VisitedStore[placeKey]) ~= "table" then
        VisitedStore[placeKey] = {}
    end
end

local function saveVisitedServers()
    pcall(function()
        if writefile then
            writefile(SERVERS_FILE, HttpService:JSONEncode(VisitedStore))
        end
    end)
end

local function markServerVisited(jobId)
    if not jobId or jobId == "" then return end
    local placeKey = tostring(game.PlaceId)
    if type(VisitedStore[placeKey]) ~= "table" then
        VisitedStore[placeKey] = {}
    end
    VisitedStore[placeKey][jobId] = true
    saveVisitedServers()
end

loadVisitedServers()
markServerVisited(game.JobId)

local isHopping = false
local activeHopBtn = nil
local activeHopOrigText = nil

HubMaid:GiveTask(TeleportService.TeleportInitFailed:Connect(function(_, teleportResult)
    if isHopping then
        isHopping = false
        if activeHopBtn and activeHopBtn.Parent then
            activeHopBtn.Text = (teleportResult == Enum.TeleportResult.GameFull)
                and "⚠️ Se llenó, reintentá"
                or "⚠️ Error TP, reintentá"
            local btnRef, origRef = activeHopBtn, activeHopOrigText
            task.delay(1.8, function()
                if btnRef and btnRef.Parent and origRef then
                    btnRef.Text = origRef
                end
            end)
        end
    end
end))

local function performServerHop(btn, sortOrder)
    if isHopping then return end
    isHopping = true
    local origText = btn.Text
    activeHopBtn = btn
    activeHopOrigText = origText
    local order = sortOrder or "Desc"
    btn.Text = "🔍 Buscando servidor variado..."

    task.spawn(function()
        local placeKey = tostring(game.PlaceId)
        local visited = VisitedStore[placeKey] or {}

        local ok, res = pcall(function()
            local url = string.format(
                "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100",
                game.PlaceId,
                order
            )
            return HttpService:JSONDecode(game:HttpGet(url))
        end)

        if ok and res and type(res.data) == "table" then
            local validServers = {}
            for _, srv in ipairs(res.data) do
                local playing = tonumber(srv.playing)
                local maxP = tonumber(srv.maxPlayers)
                if srv.id and srv.id ~= game.JobId and playing and maxP then
                    local freeSlots = maxP - playing
                    -- Margen de ~10 espacios libres para evitar Error 772 (si el mapa es muy chico, usa 25% de margen)
                    local minFree = (maxP >= 15) and 10 or math.max(3, math.floor(maxP * 0.25))
                    if freeSlots >= minFree and playing >= 1 then
                        table.insert(validServers, srv)
                    end
                end
            end

            -- Si no hubo con >= 10 espacios libres, relajar a >= 4 espacios libres
            if #validServers == 0 then
                for _, srv in ipairs(res.data) do
                    local playing = tonumber(srv.playing)
                    local maxP = tonumber(srv.maxPlayers)
                    if srv.id and srv.id ~= game.JobId and playing and maxP and (maxP - playing) >= 4 then
                        table.insert(validServers, srv)
                    end
                end
            end

            -- Filtrar los que todavía no visitaste
            local unvisited = {}
            for _, srv in ipairs(validServers) do
                if not visited[srv.id] then
                    table.insert(unvisited, srv)
                end
            end

            -- Si ya pasaste por todos, reiniciar historial y volver a permitir los anteriores
            if #unvisited == 0 and #validServers > 0 then
                VisitedStore[placeKey] = { [game.JobId] = true }
                saveVisitedServers()
                unvisited = validServers
                btn.Text = "🔄 Lista reiniciada..."
                task.wait(0.4)
            end

            if #unvisited > 0 then
                -- Elegir al azar entre los mejores candidatos para que sea bien variado
                local poolSize = math.min(#unvisited, 15)
                local chosen = unvisited[math.random(1, poolSize)]
                markServerVisited(chosen.id)

                btn.Text = "✅ Entrando (" .. chosen.playing .. "/" .. chosen.maxPlayers .. ")..."
                local tpOk = pcall(function()
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, LocalPlayer)
                end)
                if tpOk then
                    task.delay(6, function()
                        if isHopping then
                            isHopping = false
                            if btn and btn.Parent then btn.Text = origText end
                        end
                    end)
                    return
                end
            end
        end

        btn.Text = "⚠️ Sin servidores disponibles"
        task.wait(1.5)
        if btn and btn.Parent then btn.Text = origText end
        isHopping = false
    end)
end

-- ==========================================
-- 🚀 TELEPORT ANTI-RUBBERBAND
-- ==========================================
local function SafeTeleport(targetCFrame)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

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

-- ==========================================
-- 🎮 LÓGICA DE FUNCIONES DEL HUB
-- ==========================================
local function syncQuickBtnVisual(key, enabled)
    local btn = QuickButtons[key]
    local stroke = QuickButtonStrokes[key]
    if not btn then return end
    TweenService:Create(btn, TWEEN_FAST, {
        BackgroundColor3 = enabled and THEME.BgCardOn or THEME.BgMain,
        TextColor3 = enabled and THEME.AccentGreen or THEME.TextMain
    }):Play()
    if stroke then
        TweenService:Create(stroke, TWEEN_FAST, {
            Color = enabled and THEME.AccentGreen or THEME.Accent,
            Transparency = enabled and 0.15 or 0.45
        }):Play()
    end
end

local function setFeatureState(key, enabled, skipCallback)
    State[key] = enabled
    if ToggleUpdaters[key] then
        ToggleUpdaters[key](enabled, skipCallback)
    else
        syncQuickBtnVisual(key, enabled)
    end
end

-- ⚡ Interactuar sin espera (ProximityPrompt HoldDuration = 0)
local originalPromptDurations = setmetatable({}, { __mode = "k" })
local instantPromptShownConn = nil
local instantPromptAddedConn = nil

local function makePromptInstant(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") then return end
    if originalPromptDurations[prompt] == nil then
        originalPromptDurations[prompt] = prompt.HoldDuration
    end
    prompt.HoldDuration = 0
end

local function toggleInstantInteract(state)
    State.InstantInteract = state
    syncQuickBtnVisual("InstantInteract", state)

    if state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                makePromptInstant(obj)
            end
        end

        Stealth.Disconnect(instantPromptShownConn)
        instantPromptShownConn = Stealth.HideConnections(ProximityPromptService.PromptShown:Connect(function(prompt)
            if State.InstantInteract then
                makePromptInstant(prompt)
            end
        end))

        Stealth.Disconnect(instantPromptAddedConn)
        instantPromptAddedConn = Stealth.HideConnections(Workspace.DescendantAdded:Connect(function(obj)
            if State.InstantInteract and obj:IsA("ProximityPrompt") then
                makePromptInstant(obj)
            end
        end))
    else
        Stealth.Disconnect(instantPromptShownConn)
        instantPromptShownConn = nil
        Stealth.Disconnect(instantPromptAddedConn)
        instantPromptAddedConn = nil

        for prompt, origDuration in pairs(originalPromptDurations) do
            if prompt and prompt.Parent then
                pcall(function() prompt.HoldDuration = origDuration end)
            end
        end
        originalPromptDurations = setmetatable({}, { __mode = "k" })
    end
end

local function toggleInvisicam(state)
    State.Invisicam = state
    syncQuickBtnVisual("Invisicam", state)
    if state then
        pcall(function()
            LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
            LocalPlayer.CameraMaxZoomDistance = 400
            LocalPlayer.CameraMinZoomDistance = 0.5
        end)
        Stealth.Disconnect(invisicamConnection)
        invisicamConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            if not State.Invisicam then return end
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
        Stealth.Disconnect(invisicamConnection)
        invisicamConnection = nil
    end
end

local function toggleThirdPerson(state)
    State.ThirdPerson = state
    syncQuickBtnVisual("ThirdPerson", state)
    if state then
        pcall(function()
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            LocalPlayer.DevComputerCameraMode = Enum.DevComputerCameraMode.Classic
            LocalPlayer.DevTouchCameraMode = Enum.DevTouchCameraMode.Classic
        end)
        Stealth.Disconnect(thirdPersonConnection)
        thirdPersonConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            if not State.ThirdPerson then return end
            pcall(function()
                if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                end
            end)
        end))
    else
        Stealth.Disconnect(thirdPersonConnection)
        thirdPersonConnection = nil
    end
end

local function applyHighlightToCharacter(plr, char)
    if not State.ESP or plr == LocalPlayer or not char then return end
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
        rebuildXRayFilter()
        task.wait(0.2)
        if State.ESP then applyHighlightToCharacter(plr, char) end
    end)
    if State.ESP and plr.Character then
        applyHighlightToCharacter(plr, plr.Character)
    end
end

local function toggleESP(state)
    State.ESP = state
    syncQuickBtnVisual("ESP", state)
    if state then
        for _, plr in ipairs(Players:GetPlayers()) do
            setupPlayerESP(plr)
        end
    else
        for _, hl in pairs(espHighlights) do
            if hl and hl.Parent then hl:Destroy() end
        end
        table.clear(espHighlights)
    end
end

local function cacheCharacterParts(char)
    table.clear(cachedCharParts)
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
            table.insert(cachedCharParts, part)
            if originalPartCollide[part] == nil then
                originalPartCollide[part] = part.CanCollide
            end
        end
    end
    char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") and not desc:FindFirstAncestorOfClass("Accessory") then
            table.insert(cachedCharParts, desc)
            if originalPartCollide[desc] == nil then
                originalPartCollide[desc] = desc.CanCollide
            end
        end
    end)
end

if LocalPlayer.Character then cacheCharacterParts(LocalPlayer.Character) end

local function toggleNoclip(state)
    State.Noclip = state
    syncQuickBtnVisual("Noclip", state)

    if state then
        Stealth.Disconnect(noclipConnection)
        noclipConnection = nil

        if #cachedCharParts == 0 and LocalPlayer.Character then
            cacheCharacterParts(LocalPlayer.Character)
        end

        noclipConnection = Stealth.HideConnections(RunService.Stepped:Connect(function()
            if not State.Noclip then return end
            for i = 1, #cachedCharParts do
                local part = cachedCharParts[i]
                if part and part.Parent and part.CanCollide then
                    if originalPartCollide[part] == nil then
                        originalPartCollide[part] = true
                    end
                    part.CanCollide = false
                end
            end
        end))
    else
        Stealth.Disconnect(noclipConnection)
        noclipConnection = nil

        for i = 1, #cachedCharParts do
            local part = cachedCharParts[i]
            if part and part.Parent and originalPartCollide[part] ~= nil then
                part.CanCollide = originalPartCollide[part]
            end
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
        end
    end
end

local function toggleInfJump(state)
    State.InfJump = state
    syncQuickBtnVisual("InfJump", state)
end

local function toggleDeleteMode(state)
    State.DeleteMode = state
    syncQuickBtnVisual("DeleteMode", state)
end

local function RestoreMap()
    for _, data in ipairs(deletedPartsMemory) do
        if data.part and data.part.Parent then
            data.part.Transparency = data.trans
            data.part.CanCollide = data.collide
        end
    end
    table.clear(deletedPartsMemory)
end

local function clearXRayParts()
    for part, origTrans in pairs(transparentParts) do
        if part and part.Parent then
            part.Transparency = origTrans
        end
    end
    table.clear(transparentParts)
end

local function toggleFPXRay(state)
    State.FPXRay = state
    syncQuickBtnVisual("FPXRay", state)
    if state then
        rebuildXRayFilter()
        Stealth.Disconnect(fpXRayConnection)
        fpXRayConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function()
            if not State.FPXRay or not LocalPlayer.Character then return end
            clearXRayParts()

            local rayOrigin = Camera.CFrame.Position
            local rayDirection = Camera.CFrame.LookVector * 250
            local currentOrigin = rayOrigin

            for _ = 1, 5 do
                local result = Workspace:Raycast(currentOrigin, rayDirection, xrayRayParams)
                if result and result.Instance then
                    local hitPart = result.Instance
                    if hitPart:IsA("BasePart")
                        and not hitPart:FindFirstAncestorOfClass("Accessory")
                        and not hitPart.Parent:FindFirstChildOfClass("Humanoid") then
                        if hitPart.Transparency < 0.7 and not transparentParts[hitPart] then
                            transparentParts[hitPart] = hitPart.Transparency
                            hitPart.Transparency = 0.7
                        end
                    end
                    currentOrigin = result.Position + rayDirection.Unit * 0.1
                else
                    break
                end
            end
        end))
    else
        Stealth.Disconnect(fpXRayConnection)
        fpXRayConnection = nil
        clearXRayParts()
    end
end

local function toggleFullbright(state)
    State.Fullbright = state
    syncQuickBtnVisual("Fullbright", state)
    if state then
        savedLighting = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            GlobalShadows = Lighting.GlobalShadows,
        }
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 12
        Lighting.FogEnd = 1000000
        Lighting.GlobalShadows = false
    elseif savedLighting.Ambient then
        Lighting.Ambient = savedLighting.Ambient
        Lighting.OutdoorAmbient = savedLighting.OutdoorAmbient
        Lighting.Brightness = savedLighting.Brightness
        Lighting.ClockTime = savedLighting.ClockTime
        Lighting.FogEnd = Config.FPSBooster and 9e9 or savedLighting.FogEnd
        Lighting.GlobalShadows = Config.FPSBooster and false or savedLighting.GlobalShadows
    end
end

local function getMoveDirection()
    local c = LocalPlayer.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    if not hum or hum.MoveDirection.Magnitude == 0 then return Vector3.zero end
    local move = Camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
    return (Camera.CFrame * CFrame.new(move.X, 0, move.Z)).Position - Camera.CFrame.Position
end

local toggleFreeCam

local function cleanupFlyPhysics()
    Stealth.Disconnect(flyConnection)
    flyConnection = nil
    if flyLinearVel then flyLinearVel:Destroy(); flyLinearVel = nil end
    if flyAlignOri then flyAlignOri:Destroy(); flyAlignOri = nil end
    if flyAttachment then flyAttachment:Destroy(); flyAttachment = nil end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end

local function toggleFly(state)
    State.Fly = state
    syncQuickBtnVisual("Fly", state)
    if state then
        cleanupFlyPhysics()
        if State.FreeCam and toggleFreeCam then setFeatureState("FreeCam", false) end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
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
            if not State.Fly then return end
            local c = LocalPlayer.Character
            if not c or not c:FindFirstChild("HumanoidRootPart") or not flyLinearVel or not flyAlignOri then return end

            local speed = Config.FlySpeed * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 2 or 1)
            local moveVector = Vector3.zero

            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector -= Vector3.yAxis end
            else
                moveVector = getMoveDirection()
            end

            flyLinearVel.VectorVelocity = moveVector.Magnitude > 0 and (moveVector.Unit * speed) or Vector3.zero
            flyAlignOri.CFrame = Camera.CFrame
        end))
    else
        cleanupFlyPhysics()
    end
end

toggleFreeCam = function(state)
    State.FreeCam = state
    syncQuickBtnVisual("FreeCam", state)
    if state then
        if State.Fly then setFeatureState("Fly", false) end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end

        Camera.CameraType = Enum.CameraType.Scriptable
        local look = Camera.CFrame.LookVector
        camYaw = math.atan2(-look.X, -look.Z)
        camPitch = math.asin(look.Y)
        camPos = Camera.CFrame.Position

        Stealth.Disconnect(freeCamConnection)
        freeCamConnection = Stealth.HideConnections(RunService.RenderStepped:Connect(function(dt)
            if not State.FreeCam then return end
            local rot = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)
            local moveVector = Vector3.zero
            local speed = Config.FreeCamSpeed * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 2 or 1)

            if UserInputService.KeyboardEnabled then
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= rot.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += rot.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector -= Vector3.yAxis end
            else
                local c = LocalPlayer.Character
                local h = c and c:FindFirstChildOfClass("Humanoid")
                if h and h.MoveDirection.Magnitude > 0.05 then
                    local localMove = Camera.CFrame:VectorToObjectSpace(h.MoveDirection)
                    moveVector = (rot.LookVector * -localMove.Z) + (rot.RightVector * localMove.X)
                end
            end

            if moveVector.Magnitude > 0 then
                camPos += moveVector.Unit * speed * dt
            end
            Camera.CFrame = CFrame.new(camPos, camPos + rot.LookVector)
        end))

        if freeCamRotateConnection then freeCamRotateConnection:Disconnect() end
        freeCamRotateConnection = UserInputService.InputChanged:Connect(function(input, gameProcessed)
            if not State.FreeCam or gameProcessed then return end
            if input.UserInputType == Enum.UserInputType.Touch
                or (input.UserInputType == Enum.UserInputType.MouseMovement and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
                camYaw -= input.Delta.X * 0.005
                camPitch = math.clamp(camPitch - input.Delta.Y * 0.005, math.rad(-89), math.rad(89))
            end
        end)
    else
        Stealth.Disconnect(freeCamConnection)
        freeCamConnection = nil
        if freeCamRotateConnection then freeCamRotateConnection:Disconnect(); freeCamRotateConnection = nil end
        Camera.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
    end
end

-- ==========================================
-- 🖼️ INTERFAZ MODULAR NEON GLASS v3.0
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
Stealth.RandomizeName(ScreenGui)
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
if not pcall(function() ScreenGui.Parent = CoreGui end) then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
HubMaid:GiveTask(ScreenGui)

local function applyNeonStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    Stealth.RandomizeName(stroke)
    stroke.Color = color or THEME.Accent
    stroke.Transparency = transparency or 0.45
    stroke.Thickness = thickness or 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- Botón flotante principal
local MiniBtn = Instance.new("TextButton")
Stealth.RandomizeName(MiniBtn)
MiniBtn.Size = UDim2.new(0, 44, 0, 44)
MiniBtn.Position = getSavedUDim2("MiniBtn")
MiniBtn.Text = "xcs"
MiniBtn.TextSize = 13
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Visible = true
MiniBtn.Parent = ScreenGui
Instance.new("UICorner", MiniBtn).CornerRadius = UDim.new(1, 0)
local miniStroke = applyNeonStroke(MiniBtn, THEME.Accent, 0.2, 1.5)

registerThemeCallback(function(t)
    MiniBtn.BackgroundColor3 = t.BgMain
    MiniBtn.BackgroundTransparency = Config.GlassTransparency
    MiniBtn.TextColor3 = t.Accent
    miniStroke.Color = t.Accent
end)

-- Ventana Principal Unificada
local MainFrame = Instance.new("Frame")
Stealth.RandomizeName(MainFrame)
MainFrame.Size = UDim2.new(0, 275, 0, 355)
MainFrame.Position = getSavedUDim2("MainFrame")
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local mainStroke = applyNeonStroke(MainFrame, THEME.Accent, 0.35, 1.3)

local UiScaler = Instance.new("UIScale")
UiScaler.Scale = Config.UiScale
UiScaler.Parent = MainFrame

-- Cabecera
local Header = Instance.new("TextButton")
Stealth.RandomizeName(Header)
Header.Size = UDim2.new(1, 0, 0, 32)
Header.Text = "   ◈ xcs Hub  v3.0"
Header.Font = Enum.Font.GothamBold
Header.TextSize = 11
Header.TextXAlignment = Enum.TextXAlignment.Left
Header.AutoButtonColor = false
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local HeaderLine = Instance.new("Frame")
Stealth.RandomizeName(HeaderLine)
HeaderLine.Size = UDim2.new(1, 0, 0, 1)
HeaderLine.Position = UDim2.new(0, 0, 1, -1)
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = Header

local function createHeaderIcon(text, offsetX, customColor)
    local btn = Instance.new("TextButton")
    Stealth.RandomizeName(btn)
    btn.Size = UDim2.new(0, 22, 0, 22)
    btn.Position = UDim2.new(1, offsetX, 0.5, -11)
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.Parent = Header
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    local st = applyNeonStroke(btn, customColor or THEME.Accent, 0.4, 1)
    return btn, st
end

local MasterQuickBtn, masterQuickStroke = createHeaderIcon("👁️", -54)
local MinimizeBtn, minimizeStroke       = createHeaderIcon("✕",  -28, THEME.AccentRed)

registerThemeCallback(function(t)
    MainFrame.BackgroundColor3 = t.BgMain
    MainFrame.BackgroundTransparency = Config.GlassTransparency
    mainStroke.Color = t.Accent
    Header.BackgroundColor3 = t.BgHeader
    Header.BackgroundTransparency = math.clamp(Config.GlassTransparency + 0.03, 0, 0.85)
    Header.TextColor3 = t.TextMain
    HeaderLine.BackgroundColor3 = t.Accent
    HeaderLine.BackgroundTransparency = 0.65

    MasterQuickBtn.BackgroundColor3 = quickButtonsMaster and t.AccentGreen or t.SwitchOff
    MasterQuickBtn.TextColor3 = t.TextMain
    masterQuickStroke.Color = quickButtonsMaster and t.AccentGreen or t.Accent

    MinimizeBtn.BackgroundColor3 = t.AccentRed
    MinimizeBtn.TextColor3 = t.TextMain
    minimizeStroke.Color = t.AccentRed
end)

-- Barra de Pestañas (Tabs)
local TabBar = Instance.new("Frame")
Stealth.RandomizeName(TabBar)
TabBar.Size = UDim2.new(1, -16, 0, 26)
TabBar.Position = UDim2.new(0, 8, 0, 38)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabBarLayout = Instance.new("UIListLayout")
TabBarLayout.FillDirection = Enum.FillDirection.Horizontal
TabBarLayout.Padding = UDim.new(0, 4)
TabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabBarLayout.Parent = TabBar

-- Contenedor de Páginas
local PagesFolder = Instance.new("Frame")
Stealth.RandomizeName(PagesFolder)
PagesFolder.Size = UDim2.new(1, 0, 1, -70)
PagesFolder.Position = UDim2.new(0, 0, 0, 70)
PagesFolder.BackgroundTransparency = 1
PagesFolder.Parent = MainFrame

-- ==========================================
-- 🧩 LIBRERÍA DE COMPONENTES (WINDOW / TAB)
-- ==========================================
local Tabs = {}
local ActiveTabName = nil

local function selectTab(name)
    ActiveTabName = name
    for tabName, tabData in pairs(Tabs) do
        local isSelected = (tabName == name)
        tabData.Page.Visible = isSelected
        TweenService:Create(tabData.Button, TWEEN_FAST, {
            BackgroundColor3 = isSelected and THEME.Accent or THEME.BgCard,
            BackgroundTransparency = isSelected and 0.15 or 0.35,
            TextColor3 = isSelected and THEME.BgMain or THEME.TextMuted
        }):Play()
        tabData.Stroke.Color = THEME.Accent
        tabData.Stroke.Transparency = isSelected and 0.1 or 0.75
    end
end

local function CreateTab(name, icon)
    local tabBtn = Instance.new("TextButton")
    Stealth.RandomizeName(tabBtn)
    tabBtn.Size = UDim2.new(0.25, -3, 1, 0)
    tabBtn.Text = icon .. " " .. name
    tabBtn.Font = Enum.Font.GothamBold
    tabBtn.TextSize = 9
    tabBtn.AutoButtonColor = false
    tabBtn.Parent = TabBar
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 7)
    local tabStroke = applyNeonStroke(tabBtn, THEME.Accent, 0.75, 1)

    local page = Instance.new("ScrollingFrame")
    Stealth.RandomizeName(page)
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 2
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = PagesFolder

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 5)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 2)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = page

    local TabObj = { Page = page, Button = tabBtn, Stroke = tabStroke }
    Tabs[name] = TabObj

    tabBtn.MouseButton1Click:Connect(function()
        selectTab(name)
    end)

    registerThemeCallback(function(t)
        page.ScrollBarImageColor3 = t.Accent
        if ActiveTabName == name then
            tabBtn.BackgroundColor3 = t.Accent
            tabBtn.TextColor3 = t.BgMain
            tabStroke.Color = t.Accent
        else
            tabBtn.BackgroundColor3 = t.BgCard
            tabBtn.TextColor3 = t.TextMuted
            tabStroke.Color = t.Accent
        end
    end)

    function TabObj:AddSection(titleText)
        local lbl = Instance.new("TextLabel")
        Stealth.RandomizeName(lbl)
        lbl.Size = UDim2.new(1, 0, 0, 18)
        lbl.BackgroundTransparency = 1
        lbl.Text = "  " .. string.upper(titleText)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 8
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = page
        registerThemeCallback(function(t) lbl.TextColor3 = t.Accent end)
        return lbl
    end

    function TabObj:AddToggle(opts)
        local card = Instance.new("Frame")
        Stealth.RandomizeName(card)
        card.Size = UDim2.new(1, 0, 0, 28)
        card.BackgroundTransparency = 0.25
        card.BorderSizePixel = 0
        card.Parent = page
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local stroke = applyNeonStroke(card, THEME.Accent, 0.78, 1)

        local label = Instance.new("TextLabel")
        Stealth.RandomizeName(label)
        label.Size = UDim2.new(0.75, 0, 1, 0)
        label.Position = UDim2.new(0, 9, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = (opts.Icon and (opts.Icon .. "  ") or "") .. opts.Title
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local bg = Instance.new("TextButton")
        Stealth.RandomizeName(bg)
        bg.Size = UDim2.new(0, 32, 0, 16)
        bg.Position = UDim2.new(1, -40, 0.5, -8)
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

        local current = opts.Default or false

        local function updateVisual(val, skipCb)
            current = val
            TweenService:Create(bg, TWEEN_FAST, {
                BackgroundColor3 = val and THEME.AccentGreen or THEME.SwitchOff
            }):Play()
            TweenService:Create(knob, TWEEN_FAST, {
                Position = val and UDim2.new(0, 18, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }):Play()
            TweenService:Create(card, TWEEN_FAST, {
                BackgroundColor3 = val and THEME.BgCardOn or THEME.BgCard
            }):Play()
            TweenService:Create(stroke, TWEEN_FAST, {
                Color = val and THEME.AccentGreen or THEME.Accent,
                Transparency = val and 0.35 or 0.78
            }):Play()

            if opts.Key then
                syncQuickBtnVisual(opts.Key, val)
            end
            if not skipCb and opts.Callback then
                opts.Callback(val)
            end
        end

        if opts.Key then
            ToggleUpdaters[opts.Key] = updateVisual
        end

        registerThemeCallback(function(t)
            label.TextColor3 = t.TextMain
            bg.BackgroundColor3 = current and t.AccentGreen or t.SwitchOff
            card.BackgroundColor3 = current and t.BgCardOn or t.BgCard
            stroke.Color = current and t.AccentGreen or t.Accent
        end)

        bg.MouseButton1Click:Connect(function()
            local nextState = not current
            if opts.Key then
                State[opts.Key] = nextState
            end
            updateVisual(nextState, false)
        end)

        updateVisual(current, true)
        return { Set = updateVisual, Card = card }
    end

    function TabObj:AddSlider(opts)
        local card = Instance.new("Frame")
        Stealth.RandomizeName(card)
        card.Size = UDim2.new(1, 0, 0, 38)
        card.BackgroundTransparency = 0.25
        card.BorderSizePixel = 0
        card.Parent = page
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)
        local stroke = applyNeonStroke(card, THEME.Accent, 0.78, 1)

        local minVal, maxVal = opts.Min, opts.Max
        local decimals = opts.Decimals or 0
        local currentVal = math.clamp(opts.Default or minVal, minVal, maxVal)

        local function formatVal(v)
            if decimals > 0 then
                return string.format("%." .. decimals .. "f", v) .. (opts.Suffix or "")
            end
            return tostring(math.floor(v)) .. (opts.Suffix or "")
        end

        local label = Instance.new("TextLabel")
        Stealth.RandomizeName(label)
        label.Size = UDim2.new(1, -18, 0, 14)
        label.Position = UDim2.new(0, 9, 0, 4)
        label.BackgroundTransparency = 1
        label.Text = opts.Title .. ": " .. formatVal(currentVal)
        label.Font = Enum.Font.GothamMedium
        label.TextSize = 9
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local barBg = Instance.new("TextButton")
        Stealth.RandomizeName(barBg)
        barBg.Size = UDim2.new(1, -18, 0, 7)
        barBg.Position = UDim2.new(0, 9, 0, 23)
        barBg.Text = ""
        barBg.AutoButtonColor = false
        barBg.Parent = card
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        Stealth.RandomizeName(fill)
        fill.Size = UDim2.new((currentVal - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.Parent = barBg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        registerThemeCallback(function(t)
            card.BackgroundColor3 = t.BgCard
            stroke.Color = t.Accent
            label.TextColor3 = t.TextMain
            barBg.BackgroundColor3 = t.SwitchOff
            fill.BackgroundColor3 = t.Accent
        end)

        local function setSliderValue(v, triggerRelease)
            currentVal = math.clamp(v, minVal, maxVal)
            local ratio = (currentVal - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(ratio, 0, 1, 0)
            label.Text = opts.Title .. ": " .. formatVal(currentVal)
            if opts.OnChange then opts.OnChange(currentVal) end
            if triggerRelease and opts.OnRelease then opts.OnRelease(currentVal) end
        end

        local sliding = false
        local function applyInputX(screenX)
            local ratio = math.clamp((screenX - barBg.AbsolutePosition.X) / math.max(1, barBg.AbsoluteSize.X), 0, 1)
            local raw = minVal + (maxVal - minVal) * ratio
            local val = decimals > 0 and (math.floor(raw * (10 ^ decimals) + 0.5) / (10 ^ decimals)) or math.floor(raw + 0.5)
            setSliderValue(val, false)
        end

        barBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliding = true
                applyInputX(input.Position.X)
            end
        end)

        HubMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                applyInputX(input.Position.X)
            end
        end))

        HubMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
            if sliding and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                sliding = false
                if opts.OnRelease then opts.OnRelease(currentVal) end
            end
        end))

        return { Set = function(v) setSliderValue(v, false) end }
    end

    function TabObj:AddKeybind(opts)
        local card = Instance.new("Frame")
        Stealth.RandomizeName(card)
        card.Size = UDim2.new(1, 0, 0, 26)
        card.BackgroundTransparency = 0.25
        card.Parent = page
        Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)
        local stroke = applyNeonStroke(card, THEME.Accent, 0.8, 1)

        local label = Instance.new("TextLabel")
        Stealth.RandomizeName(label)
        label.Size = UDim2.new(0.68, 0, 1, 0)
        label.Position = UDim2.new(0, 9, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = opts.Title
        label.Font = Enum.Font.Gotham
        label.TextSize = 9
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local box = Instance.new("TextButton")
        Stealth.RandomizeName(box)
        box.Size = UDim2.new(0, 48, 0, 18)
        box.Position = UDim2.new(1, -54, 0.5, -9)
        box.Text = Config.Keybinds[opts.KeyName] or "None"
        box.Font = Enum.Font.GothamBold
        box.TextSize = 8
        box.Parent = card
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
        local boxStroke = applyNeonStroke(box, THEME.Accent, 0.5, 1)

        registerThemeCallback(function(t)
            card.BackgroundColor3 = t.BgCard
            stroke.Color = t.Accent
            label.TextColor3 = t.TextMain
            if listeningFor ~= opts.KeyName then
                box.BackgroundColor3 = t.BgHeader
                box.TextColor3 = t.Accent
                boxStroke.Color = t.Accent
            end
        end)

        box.MouseButton1Click:Connect(function()
            if listeningFor then return end
            listeningFor = opts.KeyName
            box.Text = "..."
            box.BackgroundColor3 = THEME.AccentAmber
            box.TextColor3 = THEME.TextMain

            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Config.Keybinds[opts.KeyName] = input.KeyCode.Name
                    saveStore()
                    box.Text = input.KeyCode.Name
                    box.BackgroundColor3 = THEME.BgHeader
                    box.TextColor3 = THEME.Accent
                    listeningFor = nil
                    conn:Disconnect()
                end
            end)
        end)

        return { Refresh = function() box.Text = Config.Keybinds[opts.KeyName] or "None" end }
    end

    function TabObj:AddButton(opts)
        local btn = Instance.new("TextButton")
        Stealth.RandomizeName(btn)
        btn.Size = UDim2.new(1, 0, 0, 26)
        btn.BackgroundTransparency = 0.18
        btn.Text = opts.Title
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 9
        btn.Parent = page
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
        local stroke = applyNeonStroke(btn, opts.Danger and THEME.AccentRed or THEME.Accent, 0.35, 1)

        registerThemeCallback(function(t)
            btn.BackgroundColor3 = opts.Danger and t.AccentRed or t.BgCard
            btn.TextColor3 = opts.Danger and t.TextMain or t.Accent
            stroke.Color = opts.Danger and t.AccentRed or t.Accent
        end)

        btn.MouseButton1Click:Connect(function()
            if opts.Callback then opts.Callback(btn) end
        end)
        return btn
    end

    return TabObj
end

-- ==========================================
-- 📑 CREACIÓN DE LAS 4 PESTAÑAS
-- ==========================================
local TabMove    = CreateTab("Mov.", "🕊️")
local TabVisuals = CreateTab("Vis.", "👁️")
local TabPlayers = CreateTab("Jug.", "👥")
local TabConfig  = CreateTab("Ajust.", "⚙️")

-- --- PESTAÑA 1: MOVIMIENTO ---
TabMove:AddSection("Desplazamiento")
TabMove:AddToggle({ Key = "Fly",         Icon = "🕊️", Title = "Fly (Vuelo)",         Callback = toggleFly })
TabMove:AddToggle({ Key = "Noclip",      Icon = "👻", Title = "Noclip (Atravesar)",  Callback = toggleNoclip })
TabMove:AddToggle({ Key = "InfJump",     Icon = "⚡", Title = "Infinite Jump",       Callback = toggleInfJump })
if isTouchDevice then
    TabMove:AddToggle({ Key = "TPS",     Icon = "📍", Title = "TPS (Toque en mapa)", Callback = function(v) State.TPS = v end })
end

TabMove:AddSection("Velocidades")
local flySlider = TabMove:AddSlider({
    Title = "Velocidad Fly", Min = 10, Max = 300, Default = Config.FlySpeed,
    OnChange = function(v) Config.FlySpeed = v end,
    OnRelease = function() saveStore() end
})

-- --- PESTAÑA 2: VISUALES, CÁMARA E INTERACCIÓN ---
TabVisuals:AddSection("Cámara y Visión")
TabVisuals:AddToggle({ Key = "ESP",         Icon = "🎯", Title = "ESP Jugadores",       Callback = toggleESP })
TabVisuals:AddToggle({ Key = "Invisicam",   Icon = "👁️", Title = "Invisicam + Zoom",    Callback = toggleInvisicam })
TabVisuals:AddToggle({ Key = "FPXRay",      Icon = "🧱", Title = "FP X-Ray (Paredes)",  Callback = toggleFPXRay })
TabVisuals:AddToggle({ Key = "Fullbright",  Icon = "☀️", Title = "Fullbright",          Callback = toggleFullbright })
TabVisuals:AddToggle({ Key = "ThirdPerson", Icon = "🧍", Title = "Third Person Forzado",Callback = toggleThirdPerson })
TabVisuals:AddToggle({ Key = "FreeCam",     Icon = "🎥", Title = "Free Cam",            Callback = toggleFreeCam })

local freeCamSlider = TabVisuals:AddSlider({
    Title = "Velocidad Free Cam", Min = 10, Max = 300, Default = Config.FreeCamSpeed,
    OnChange = function(v) Config.FreeCamSpeed = v end,
    OnRelease = function() saveStore() end
})

TabVisuals:AddSection("Interacción y Mapa")
TabVisuals:AddToggle({ Key = "InstantInteract", Icon = "⚡", Title = "Interactuar sin Espera", Callback = toggleInstantInteract })
TabVisuals:AddToggle({ Key = "DeleteMode",      Icon = "🗑️", Title = "Borrador de Paredes",    Callback = toggleDeleteMode })
TabVisuals:AddButton({
    Title = "♻️ Restaurar Paredes Borradas",
    Callback = RestoreMap
})

-- --- PESTAÑA 3: JUGADORES (ORDENAMIENTO DINÁMICO + SPECTATE) ---
local searchBox = Instance.new("TextBox")
Stealth.RandomizeName(searchBox)
searchBox.Size = UDim2.new(1, 0, 0, 24)
searchBox.BackgroundTransparency = 0.15
searchBox.Text = ""
searchBox.PlaceholderText = "🔍 Buscar jugador..."
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 10
searchBox.ClearTextOnFocus = false
searchBox.Parent = TabPlayers.Page
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 6)
local searchStroke = applyNeonStroke(searchBox, THEME.Accent, 0.65, 1)

local SpectateBar = Instance.new("Frame")
Stealth.RandomizeName(SpectateBar)
SpectateBar.Size = UDim2.new(1, 0, 0, 24)
SpectateBar.BackgroundTransparency = 1
SpectateBar.Parent = TabPlayers.Page

local function makeSpecNavBtn(text, pos, size)
    local b = Instance.new("TextButton")
    Stealth.RandomizeName(b)
    b.Size = size
    b.Position = pos
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.Parent = SpectateBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    local st = applyNeonStroke(b, THEME.Accent, 0.5, 1)
    return b, st
end

local PrevSpecBtn, prevSpecStroke = makeSpecNavBtn("◀", UDim2.new(0, 0, 0, 0),      UDim2.new(0, 28, 1, 0))
local SelfSpecBtn, selfSpecStroke = makeSpecNavBtn("🏠 Mi Cámara", UDim2.new(0, 32, 0, 0), UDim2.new(1, -64, 1, 0))
local NextSpecBtn, nextSpecStroke = makeSpecNavBtn("▶", UDim2.new(1, -28, 0, 0),    UDim2.new(0, 28, 1, 0))

registerThemeCallback(function(t)
    searchBox.BackgroundColor3 = t.BgCard
    searchBox.PlaceholderColor3 = t.TextMuted
    searchBox.TextColor3 = t.TextMain
    searchStroke.Color = t.Accent

    for _, pair in ipairs({{PrevSpecBtn, prevSpecStroke}, {NextSpecBtn, nextSpecStroke}}) do
        pair[1].BackgroundColor3 = t.BgCard
        pair[1].TextColor3 = t.Accent
        pair[2].Color = t.Accent
    end
    SelfSpecBtn.BackgroundColor3 = spectatingPlayer and t.BgCardOn or t.BgCard
    SelfSpecBtn.TextColor3 = spectatingPlayer and t.AccentGreen or t.TextMuted
    selfSpecStroke.Color = spectatingPlayer and t.AccentGreen or t.Accent
end)

local PlayerListContainer = Instance.new("Frame")
Stealth.RandomizeName(PlayerListContainer)
PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
PlayerListContainer.AutomaticSize = Enum.AutomaticSize.Y
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.Parent = TabPlayers.Page

local PlayerListLayout = Instance.new("UIListLayout")
PlayerListLayout.Padding = UDim.new(0, 4)
PlayerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
PlayerListLayout.Parent = PlayerListContainer

local playerCards = {}

local function updateSpectateVisuals()
    SelfSpecBtn.BackgroundColor3 = spectatingPlayer and THEME.BgCardOn or THEME.BgCard
    SelfSpecBtn.TextColor3 = spectatingPlayer and THEME.AccentGreen or THEME.TextMuted
    selfSpecStroke.Color = spectatingPlayer and THEME.AccentGreen or THEME.Accent

    for plr, data in pairs(playerCards) do
        local isSpec = (spectatingPlayer == plr)
        data.ViewBtn.BackgroundColor3 = isSpec and THEME.AccentGreen or THEME.SwitchOff
        data.Row.BackgroundColor3 = isSpec and THEME.BgCardOn or THEME.BgCard
        data.Stroke.Color = isSpec and THEME.AccentGreen or (data.IsFriend and Color3.fromRGB(255, 215, 0) or THEME.Accent)
        data.Stroke.Transparency = isSpec and 0.2 or 0.78
    end
end

local function resetSpectate()
    spectatingPlayer = nil
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then Camera.CameraSubject = hum end
    updateSpectateVisuals()
end

local function spectatePlayer(targetPlayer)
    if not targetPlayer or spectatingPlayer == targetPlayer then
        resetSpectate()
        return
    end
    spectatingPlayer = targetPlayer
    local hum = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then Camera.CameraSubject = hum end
    updateSpectateVisuals()
end

local function cycleSpectate(step)
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and playerCards[p] and playerCards[p].Row.Visible then
            table.insert(list, p)
        end
    end
    if #list == 0 then return end
    table.sort(list, function(a, b)
        return playerCards[a].Row.LayoutOrder < playerCards[b].Row.LayoutOrder
    end)

    local idx = 1
    for i, p in ipairs(list) do
        if p == spectatingPlayer then
            idx = ((i - 1 + step) % #list) + 1
            break
        end
    end
    spectatePlayer(list[idx])
end

SelfSpecBtn.MouseButton1Click:Connect(resetSpectate)
PrevSpecBtn.MouseButton1Click:Connect(function() cycleSpectate(-1) end)
NextSpecBtn.MouseButton1Click:Connect(function() cycleSpectate(1) end)

local function applyPlayerFilter()
    local q = string.lower(filterQuery)
    for plr, data in pairs(playerCards) do
        local match = (q == "")
            or string.find(string.lower(plr.DisplayName), q, 1, true)
            or string.find(string.lower(plr.Name), q, 1, true)
        data.Row.Visible = match ~= nil
    end
end

local function createPlayerRow(p)
    if p == LocalPlayer or playerCards[p] then return end

    local isFriend = false
    pcall(function() isFriend = LocalPlayer:IsFriendsWith(p.UserId) end)

    local row = Instance.new("Frame")
    Stealth.RandomizeName(row)
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundColor3 = THEME.BgCard
    row.BackgroundTransparency = 0.28
    row.LayoutOrder = isFriend and -100000 or 99999
    row.Parent = PlayerListContainer
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
    local stroke = applyNeonStroke(row, isFriend and Color3.fromRGB(255, 215, 0) or THEME.Accent, 0.78, 1)

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
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        end)
        if thumbImg and thumbImg.Parent then
            thumbImg.Image = (ok and url and url ~= "") and url
                or ("https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=150&height=150&format=png")
        end
    end)

    local nameLbl = Instance.new("TextLabel")
    Stealth.RandomizeName(nameLbl)
    nameLbl.Size = UDim2.new(0.52, 0, 0, 14)
    nameLbl.Position = UDim2.new(0, 30, 0, 2)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = (isFriend and "⭐ " or "") .. p.DisplayName
    nameLbl.TextColor3 = isFriend and Color3.fromRGB(255, 215, 0) or THEME.TextMain
    nameLbl.Font = Enum.Font.GothamMedium
    nameLbl.TextSize = 9
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = row

    local distLbl = Instance.new("TextLabel")
    Stealth.RandomizeName(distLbl)
    distLbl.Size = UDim2.new(0.52, 0, 0, 11)
    distLbl.Position = UDim2.new(0, 30, 0, 16)
    distLbl.BackgroundTransparency = 1
    distLbl.Text = "--- m"
    distLbl.TextColor3 = THEME.TextMuted
    distLbl.Font = Enum.Font.Gotham
    distLbl.TextSize = 8
    distLbl.TextXAlignment = Enum.TextXAlignment.Left
    distLbl.Parent = row

    local tpBtn = Instance.new("TextButton")
    Stealth.RandomizeName(tpBtn)
    tpBtn.Size = UDim2.new(0, 26, 0, 18)
    tpBtn.Position = UDim2.new(1, -62, 0.5, -9)
    tpBtn.BackgroundColor3 = THEME.Accent
    tpBtn.Text = "TP"
    tpBtn.TextColor3 = THEME.BgMain
    tpBtn.Font = Enum.Font.GothamBold
    tpBtn.TextSize = 8
    tpBtn.Parent = row
    Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
    tpBtn.MouseButton1Click:Connect(function()
        local tHrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if tHrp then
            SafeTeleport(tHrp.CFrame + Vector3.new(0, 3.5, 0))
        end
    end)

    local viewBtn = Instance.new("TextButton")
    Stealth.RandomizeName(viewBtn)
    viewBtn.Size = UDim2.new(0, 30, 0, 18)
    viewBtn.Position = UDim2.new(1, -33, 0.5, -9)
    viewBtn.BackgroundColor3 = THEME.SwitchOff
    viewBtn.Text = "VIEW"
    viewBtn.TextColor3 = THEME.TextMain
    viewBtn.Font = Enum.Font.GothamBold
    viewBtn.TextSize = 7
    viewBtn.Parent = row
    Instance.new("UICorner", viewBtn).CornerRadius = UDim.new(0, 4)
    viewBtn.MouseButton1Click:Connect(function()
        spectatePlayer(p)
    end)

    playerCards[p] = {
        Row = row,
        DistLabel = distLbl,
        ViewBtn = viewBtn,
        Stroke = stroke,
        IsFriend = isFriend
    }
    applyPlayerFilter()
end

for _, p in ipairs(Players:GetPlayers()) do createPlayerRow(p) end
HubMaid:GiveTask(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    filterQuery = searchBox.Text
    applyPlayerFilter()
end))

task.spawn(function()
    while not hubUnloaded do
        if MainFrame.Visible and ActiveTabName == "Jug." then
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            for plr, data in pairs(playerCards) do
                local tHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if myHrp and tHrp then
                    local dist = math.floor((myHrp.Position - tHrp.Position).Magnitude)
                    data.DistLabel.Text = dist .. " m"
                    data.Row.LayoutOrder = (data.IsFriend and -100000 or 0) + dist
                else
                    data.DistLabel.Text = "Fuera de rango"
                    data.Row.LayoutOrder = (data.IsFriend and -50000 or 99999)
                end
            end
        end
        task.wait(0.3)
    end
end)

-- --- PESTAÑA 4: AJUSTES, SESIÓN/FPS, TEMAS, PERFILES Y KEYBINDS ---
TabConfig:AddSection("Sesión y Rendimiento")

local antiAfkToggle = TabConfig:AddToggle({
    Icon = "🛡️",
    Title = "Anti-AFK (Evitar Kick)",
    Default = Config.AntiAFK ~= false,
    Callback = function(v)
        Config.AntiAFK = v
        saveStore()
    end
})

local fpsBoosterToggle = TabConfig:AddToggle({
    Icon = "⚡",
    Title = "FPS Booster (Optimizar Gráficos)",
    Default = Config.FPSBooster == true,
    Callback = toggleFPSBooster
})

TabConfig:AddButton({
    Title = "🔁 Rejoin (Reconectar Servidor)",
    Callback = performRejoin
})

TabConfig:AddButton({
    Title = "🔥 Server Hop (Con Gente / Variado)",
    Callback = function(btn)
        performServerHop(btn, "Desc")
    end
})

TabConfig:AddButton({
    Title = "🌐 Server Hop (Tranquilo / Variado)",
    Callback = function(btn)
        performServerHop(btn, "Asc")
    end
})

TabConfig:AddSection("Apariencia y Escala")

local function applyThemeByName(themeName)
    if not PRESET_THEMES[themeName] then return end
    Config.Theme = themeName
    THEME = PRESET_THEMES[themeName]
    for _, fn in ipairs(ThemeCallbacks) do
        pcall(fn, THEME)
    end
    for k, v in pairs(State) do
        syncQuickBtnVisual(k, v)
    end
    updateSpectateVisuals()
    saveStore()
end

local themeBtn = TabConfig:AddButton({
    Title = "🎨 Tema: " .. Config.Theme .. " (Click para cambiar)",
    Callback = function(btn)
        local idx = table.find(THEME_ORDER, Config.Theme) or 1
        local nextTheme = THEME_ORDER[(idx % #THEME_ORDER) + 1]
        applyThemeByName(nextTheme)
        btn.Text = "🎨 Tema: " .. nextTheme .. " (Click para cambiar)"
    end
})

local scaleSlider = TabConfig:AddSlider({
    Title = "Escala de Interfaz", Min = 0.75, Max = 1.40, Decimals = 2, Suffix = "x", Default = Config.UiScale,
    OnChange = function(v)
        Config.UiScale = v
        UiScaler.Scale = v
    end,
    OnRelease = function() saveStore() end
})

local glassSlider = TabConfig:AddSlider({
    Title = "Transparencia Cristal", Min = 0.0, Max = 0.55, Decimals = 2, Default = Config.GlassTransparency,
    OnChange = function(v)
        Config.GlassTransparency = v
        MainFrame.BackgroundTransparency = v
        MiniBtn.BackgroundTransparency = v
        Header.BackgroundTransparency = math.clamp(v + 0.03, 0, 0.85)
    end,
    OnRelease = function() saveStore() end
})

TabConfig:AddSection("Perfiles JSON")

local PROFILE_NAMES = {"Default", "PC", "Movil"}
local keybindRefreshers = {}

local function applyAllPositionsFromConfig()
    MainFrame.Position = getSavedUDim2("MainFrame")
    MiniBtn.Position = getSavedUDim2("MiniBtn")
    for qName, qBtn in pairs(QuickButtons) do
        qBtn.Position = getSavedUDim2("Quick_" .. qName)
        if qName == "TPS" and not isTouchDevice then
            qBtn.Visible = false
        else
            qBtn.Visible = quickButtonsMaster and (Config.QuickVisible[qName] ~= false)
        end
    end
end

local function switchProfile(profileName)
    Store.ActiveProfile = profileName
    if not Store.Profiles[profileName] then
        Store.Profiles[profileName] = buildDefaultProfile()
    end
    mergeMissing(Store.Profiles[profileName], buildDefaultProfile())
    Config = Store.Profiles[profileName]
    saveStore()

    applyThemeByName(Config.Theme)
    themeBtn.Text = "🎨 Tema: " .. Config.Theme .. " (Click para cambiar)"
    UiScaler.Scale = Config.UiScale
    scaleSlider.Set(Config.UiScale)
    glassSlider.Set(Config.GlassTransparency)
    flySlider.Set(Config.FlySpeed)
    freeCamSlider.Set(Config.FreeCamSpeed)
    antiAfkToggle.Set(Config.AntiAFK ~= false, true)
    fpsBoosterToggle.Set(Config.FPSBooster == true, false)
    applyAllPositionsFromConfig()
    for _, refreshFn in ipairs(keybindRefreshers) do refreshFn() end
end

TabConfig:AddButton({
    Title = "📁 Perfil Activo: " .. Store.ActiveProfile .. " (Cambiar)",
    Callback = function(btn)
        local idx = table.find(PROFILE_NAMES, Store.ActiveProfile) or 1
        local nextProf = PROFILE_NAMES[(idx % #PROFILE_NAMES) + 1]
        switchProfile(nextProf)
        btn.Text = "📁 Perfil Activo: " .. nextProf .. " (Cambiar)"
    end
})

TabConfig:AddButton({
    Title = "🔄 Resetear Posiciones del Perfil",
    Callback = function()
        Config.Positions = buildDefaultProfile().Positions
        saveStore()
        applyAllPositionsFromConfig()
    end
})

TabConfig:AddSection("Botones Flotantes Rápidos")
local quickSpecs = {
    {Key = "TPS",             Label = "Botón TPS (Toque)",     TouchOnly = true},
    {Key = "Invisicam",       Label = "Botón Invisicam (INV)"},
    {Key = "FPXRay",          Label = "Botón FP X-Ray (XRY)"},
    {Key = "ESP",             Label = "Botón ESP (ESP)"},
    {Key = "InstantInteract", Label = "Botón Sin Espera (INT)"},
    {Key = "DeleteMode",      Label = "Botón Borrador (DEL)"},
    {Key = "Noclip",          Label = "Botón Noclip (NOC)"},
    {Key = "InfJump",         Label = "Botón Inf Jump (JMP)"},
    {Key = "Fly",             Label = "Botón Fly (FLY)"},
    {Key = "FreeCam",         Label = "Botón Free Cam (CAM)"},
    {Key = "Fullbright",      Label = "Botón Fullbright (LGT)"},
    {Key = "ThirdPerson",     Label = "Botón Third Person (3PS)"},
    {Key = "Restore",         Label = "Botón Restaurar (RST)"},
}

for _, item in ipairs(quickSpecs) do
    if not item.TouchOnly or isTouchDevice then
        TabConfig:AddToggle({
            Icon = "🔘",
            Title = item.Label,
            Default = Config.QuickVisible[item.Key] ~= false,
            Callback = function(val)
                Config.QuickVisible[item.Key] = val
                saveStore()
                if QuickButtons[item.Key] then
                    QuickButtons[item.Key].Visible = val and quickButtonsMaster
                end
            end
        })
    end
end

TabConfig:AddSection("Atajos de Teclado (PC)")
local keybindSpecs = {
    {Title = "Tecla TP (PC)",     KeyName = "Teleport", DesktopOnly = true},
    {Title = "Tecla Invisicam",   KeyName = "Invisicam"},
    {Title = "Tecla Noclip",      KeyName = "Noclip"},
    {Title = "Tecla Fly",         KeyName = "Fly"},
    {Title = "Tecla Free Cam",    KeyName = "FreeCam"},
    {Title = "Tecla Fullbright",  KeyName = "Fullbright"},
    {Title = "Tecla X-Ray",       KeyName = "XRay"},
    {Title = "Tecla ESP",         KeyName = "ESP"},
    {Title = "Tecla Inf Jump",    KeyName = "InfJump"},
    {Title = "Tecla Borrador",    KeyName = "Delete"},
    {Title = "Tecla Restaurar",   KeyName = "Restore"},
}

for _, kb in ipairs(keybindSpecs) do
    if not kb.DesktopOnly or not isTouchDevice then
        local created = TabConfig:AddKeybind(kb)
        table.insert(keybindRefreshers, created.Refresh)
    end
end

TabConfig:AddSection("Sistema")
TabConfig:AddButton({
    Title = "🛑 Cerrar y Limpiar Hub (Unload)",
    Danger = true,
    Callback = function()
        hubUnloaded = true
        if State.Invisicam then toggleInvisicam(false) end
        if State.FPXRay then toggleFPXRay(false) end
        if State.ESP then toggleESP(false) end
        if State.Noclip then toggleNoclip(false) end
        if State.Fly then toggleFly(false) end
        if State.FreeCam then toggleFreeCam(false) end
        if State.Fullbright then toggleFullbright(false) end
        if State.ThirdPerson then toggleThirdPerson(false) end
        if State.InstantInteract then toggleInstantInteract(false) end
        if Config.FPSBooster then
            toggleFPSBooster(false)
            Config.FPSBooster = true
            saveStore()
        end
        if spectatingPlayer then resetSpectate() end
        RestoreMap()

        for _, conn in pairs(espCharConnections) do
            pcall(function() conn:Disconnect() end)
        end
        HubMaid:DoCleaning()
    end
})

if Config.FPSBooster then
    toggleFPSBooster(true)
end

selectTab("Mov.")

-- ==========================================
-- 🖱️ ARRASTRE DE VENTANAS Y QUICK BUTTONS
-- ==========================================
local function makeDraggable(dragHandle, targetFrame, saveKey)
    local dragging, dragInput, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if saveKey then setSavedUDim2(saveKey, targetFrame.Position) end
                end
            end)
        end
    end)
    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    HubMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local vp = Camera.ViewportSize
            local newX = math.clamp(startPos.X.Offset + delta.X, 0, math.max(0, vp.X - targetFrame.AbsoluteSize.X))
            local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, vp.Y - targetFrame.AbsoluteSize.Y))
            targetFrame.Position = UDim2.new(0, newX, 0, newY)
        end
    end))
end

makeDraggable(Header, MainFrame, "MainFrame")
makeDraggable(MiniBtn, MiniBtn, "MiniBtn")

local function createQuickBtn(name, shortText, onClick, isActionBtn)
    local btn = Instance.new("TextButton")
    Stealth.RandomizeName(btn)
    btn.Size = UDim2.new(0, 36, 0, 36)
    btn.Position = getSavedUDim2("Quick_" .. name)
    btn.BackgroundTransparency = 0.15
    btn.Text = shortText
    btn.TextSize = 9
    btn.Font = Enum.Font.GothamBold
    btn.Visible = (name == "TPS" and not isTouchDevice) and false or (Config.QuickVisible[name] ~= false)
    btn.Parent = ScreenGui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
    local stroke = applyNeonStroke(btn, isActionBtn and THEME.AccentRed or THEME.Accent, 0.4, 1.3)

    QuickButtons[name] = btn
    QuickButtonStrokes[name] = stroke

    registerThemeCallback(function(t)
        if isActionBtn then
            btn.BackgroundColor3 = t.BgMain
            btn.TextColor3 = t.AccentRed
            stroke.Color = t.AccentRed
        else
            syncQuickBtnVisual(name, State[name] or false)
        end
    end)

    local startPos, isDragging, dragStartScreen, initBtnPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            startPos = input.Position
            isDragging = false
            dragStartScreen = input.Position
            initBtnPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) and dragStartScreen then
            if (input.Position - dragStartScreen).Magnitude > 6 then
                isDragging = true
                local delta = input.Position - dragStartScreen
                local vp = Camera.ViewportSize
                local newX = math.clamp(initBtnPos.X.Offset + delta.X, 0, math.max(0, vp.X - btn.AbsoluteSize.X))
                local newY = math.clamp(initBtnPos.Y.Offset + delta.Y, 0, math.max(0, vp.Y - btn.AbsoluteSize.Y))
                btn.Position = UDim2.new(0, newX, 0, newY)
            end
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if startPos and not isDragging then
                onClick(btn, stroke)
            elseif isDragging then
                local snap = 35
                for otherName, otherBtn in pairs(QuickButtons) do
                    if otherName ~= name and otherBtn.Visible then
                        local dx = math.abs(btn.Position.X.Offset - otherBtn.Position.X.Offset)
                        local dy = math.abs(btn.Position.Y.Offset - otherBtn.Position.Y.Offset)
                        if dx < snap and dy < 50 then
                            btn.Position = UDim2.new(0, otherBtn.Position.X.Offset, 0, btn.Position.Y.Offset)
                        elseif dy < snap and dx < 50 then
                            btn.Position = UDim2.new(0, btn.Position.X.Offset, 0, otherBtn.Position.Y.Offset)
                        end
                    end
                end
                setSavedUDim2("Quick_" .. name, btn.Position)
            end
            startPos, isDragging, dragStartScreen = nil, false, nil
        end
    end)
end

if isTouchDevice then
    createQuickBtn("TPS", "TPS", function() setFeatureState("TPS", not State.TPS) end)
end
createQuickBtn("Invisicam",       "INV", function() setFeatureState("Invisicam",       not State.Invisicam) end)
createQuickBtn("FPXRay",          "XRY", function() setFeatureState("FPXRay",          not State.FPXRay) end)
createQuickBtn("ESP",             "ESP", function() setFeatureState("ESP",             not State.ESP) end)
createQuickBtn("InstantInteract", "INT", function() setFeatureState("InstantInteract", not State.InstantInteract) end)
createQuickBtn("DeleteMode",      "DEL", function() setFeatureState("DeleteMode",      not State.DeleteMode) end)
createQuickBtn("Noclip",          "NOC", function() setFeatureState("Noclip",          not State.Noclip) end)
createQuickBtn("InfJump",         "JMP", function() setFeatureState("InfJump",         not State.InfJump) end)
createQuickBtn("Fly",             "FLY", function() setFeatureState("Fly",             not State.Fly) end)
createQuickBtn("FreeCam",         "CAM", function() setFeatureState("FreeCam",         not State.FreeCam) end)
createQuickBtn("Fullbright",      "LGT", function() setFeatureState("Fullbright",      not State.Fullbright) end)
createQuickBtn("ThirdPerson",     "3PS", function() setFeatureState("ThirdPerson",     not State.ThirdPerson) end)
createQuickBtn("Restore",         "RST", function(btn, stroke)
    RestoreMap()
    btn.TextColor3 = THEME.AccentGreen
    stroke.Color = THEME.AccentGreen
    task.wait(0.3)
    btn.TextColor3 = THEME.AccentRed
    stroke.Color = THEME.AccentRed
end, true)

-- Botones de cabecera
MasterQuickBtn.MouseButton1Click:Connect(function()
    quickButtonsMaster = not quickButtonsMaster
    MasterQuickBtn.BackgroundColor3 = quickButtonsMaster and THEME.AccentGreen or THEME.SwitchOff
    masterQuickStroke.Color = quickButtonsMaster and THEME.AccentGreen or THEME.Accent
    for name, btn in pairs(QuickButtons) do
        if name == "TPS" and not isTouchDevice then
            btn.Visible = false
        else
            btn.Visible = quickButtonsMaster and (Config.QuickVisible[name] ~= false)
        end
    end
end)

MinimizeBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniBtn.Visible = true end)
MiniBtn.Activated:Connect(function() MainFrame.Visible = true; MiniBtn.Visible = false end)

-- ==========================================
-- 🎯 RAYCAST, INPUTS Y EVENTOS GLOBALES
-- ==========================================
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

local function DeletePartAt(screenPos)
    local ray = Camera:ScreenPointToRay(screenPos.X, screenPos.Y)
    local result = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
    local part = result and result.Instance
    if part and part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
        table.insert(deletedPartsMemory, {part = part, trans = part.Transparency, collide = part.CanCollide})
        part.Transparency = 1
        part.CanCollide = false
    end
end

local function TeleportAt(screenPos)
    local ray = Camera:ScreenPointToRay(screenPos.X, screenPos.Y)
    local result = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
    if result then
        SafeTeleport(CFrame.new(result.Position + Vector3.new(0, 3.5, 0)))
    end
end

HubMaid:GiveTask(UserInputService.JumpRequest:Connect(function()
    if State.InfJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

HubMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or listeningFor or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        local codeName = input.KeyCode.Name
        local kb = Config.Keybinds
        if codeName == kb.Invisicam  then setFeatureState("Invisicam",  not State.Invisicam) end
        if codeName == kb.Noclip     then setFeatureState("Noclip",     not State.Noclip) end
        if codeName == kb.Fly        then setFeatureState("Fly",        not State.Fly) end
        if codeName == kb.FreeCam    then setFeatureState("FreeCam",    not State.FreeCam) end
        if codeName == kb.Fullbright then setFeatureState("Fullbright", not State.Fullbright) end
        if codeName == kb.XRay       then setFeatureState("FPXRay",     not State.FPXRay) end
        if codeName == kb.ESP        then setFeatureState("ESP",        not State.ESP) end
        if codeName == kb.InfJump    then setFeatureState("InfJump",    not State.InfJump) end
        if codeName == kb.Restore    then RestoreMap() end
        if codeName == kb.Teleport   then TeleportAt(Vector2.new(Mouse.X, Mouse.Y)) end
        if codeName == kb.Delete     then DeletePartAt(Vector2.new(Mouse.X, Mouse.Y)) end
    end
end))

-- Soporte táctil (Toque rápido para TP o Borrador)
local function isOverGui(pos)
    if not ScreenGui or not ScreenGui.Parent then return false end
    for _, obj in ipairs(LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)) do
        if obj:IsDescendantOf(ScreenGui) then return true end
    end
    return false
end

local touchState = { active = false, startTime = 0, totalMoved = 0, isCameraDrag = false }
HubMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gp)
    if gp or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Touch then
        touchState.active = true
        touchState.startTime = os.clock()
        touchState.totalMoved = 0
        touchState.isCameraDrag = false
    end
end))

HubMaid:GiveTask(UserInputService.InputChanged:Connect(function(input, gp)
    if gp or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        touchState.totalMoved += input.Delta.Magnitude
        if touchState.totalMoved > 10 then touchState.isCameraDrag = true end
    end
end))

HubMaid:GiveTask(UserInputService.InputEnded:Connect(function(input, gp)
    if gp or hubUnloaded then return end
    if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
        touchState.active = false
        if (os.clock() - touchState.startTime) < 0.3 and not touchState.isCameraDrag and not isOverGui(input.Position) then
            if State.DeleteMode then DeletePartAt(input.Position)
            elseif State.TPS then TeleportAt(input.Position) end
        end
    end
end))

-- Eventos de jugadores y respawn
HubMaid:GiveTask(Players.PlayerAdded:Connect(function(plr)
    setupPlayerESP(plr)
    createPlayerRow(plr)
    rebuildXRayFilter()
end))

HubMaid:GiveTask(Players.PlayerRemoving:Connect(function(plr)
    if spectatingPlayer == plr then resetSpectate() end
    if espCharConnections[plr] then espCharConnections[plr]:Disconnect(); espCharConnections[plr] = nil end
    if espHighlights[plr] then espHighlights[plr]:Destroy(); espHighlights[plr] = nil end
    if playerCards[plr] then
        playerCards[plr].Row:Destroy()
        playerCards[plr] = nil
    end
    rebuildXRayFilter()
end))

HubMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    cacheCharacterParts(char)
    rebuildXRayFilter()
    if State.Noclip      then toggleNoclip(true) end
    if State.Invisicam   then toggleInvisicam(true) end
    if State.FPXRay      then toggleFPXRay(true) end
    if State.Fullbright  then toggleFullbright(true) end
    if State.ThirdPerson then toggleThirdPerson(true) end
    if State.Fly         then toggleFly(true) end
end))
