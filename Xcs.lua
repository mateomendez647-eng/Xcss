-- ==========================================
-- HUB: xcs (Neon Glass v3.1 - Safe Boot & Modular)
-- Carga Escalonada + Anti-Límite 200 Locals + ESP Info + Mute + Join Friends + Server Hop
-- ==========================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end
task.wait(0.4)

local env = (getgenv and getgenv()) or _G
if type(env.__XCS_UNLOAD) == "function" then
    pcall(env.__XCS_UNLOAD)
    task.wait(0.1)
end

local Services = {
    Players                = game:GetService("Players"),
    UserInputService       = game:GetService("UserInputService"),
    RunService             = game:GetService("RunService"),
    TweenService           = game:GetService("TweenService"),
    Workspace              = game:GetService("Workspace"),
    Lighting               = game:GetService("Lighting"),
    CoreGui                = game:GetService("CoreGui"),
    HttpService            = game:GetService("HttpService"),
    TeleportService        = game:GetService("TeleportService"),
    VirtualUser            = game:GetService("VirtualUser"),
    ProximityPromptService = game:GetService("ProximityPromptService"),
}

math.randomseed(tick() * 1000)

local LocalPlayer = Services.Players.LocalPlayer or Services.Players.PlayerAdded:Wait()
local Camera = Services.Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local isTouchDevice = Services.UserInputService.TouchEnabled and not Services.UserInputService.KeyboardEnabled

-- ==========================================
-- 🛡️ MÓDULO DE SIGILO SEGURO (STEALTH)
-- ==========================================
local Stealth = { _seed = tick() % 1000 }

local function stealthName()
    Stealth._seed += 1
    local prefixes = {"Frame", "TextLabel", "ImageLabel", "UICorner", "UIStroke", "ScrollingFrame", "TextButton", "ImageButton", "ViewportFrame"}
    return prefixes[math.random(1, #prefixes)] .. "_" .. string.format("%04x", math.random(0, 0xFFFF))
end

function Stealth.Disconnect(connection)
    if connection then
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
        ESPInfo = true,
        ESPName = true,
        ESPHealth = true,
        ESPDistance = true,
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
    Profiles = { Default = buildDefaultProfile() }
}

local function saveStore()
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, Services.HttpService:JSONEncode(Store))
        end
    end)
end

local function loadStore()
    pcall(function()
        if isfile and readfile and isfile(CONFIG_FILE) then
            local decoded = Services.HttpService:JSONDecode(readfile(CONFIG_FILE))
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
-- ⚙️ ESTADOS, CONTENEDORES Y CACHÉS GLOBALES
-- ==========================================
local State = {
    TPS = false, Invisicam = false, FPXRay = false, ESP = false,
    DeleteMode = false, Noclip = false, InfJump = false, Fly = false,
    FreeCam = false, Fullbright = false, ThirdPerson = false, InstantInteract = false,
}

local Runtime = {
    isReady = false,
    quickButtonsMaster = true,
    hubUnloaded = false,
    listeningFor = nil,
    spectatingPlayer = nil,
    filterQuery = "",
    playersSubView = "Server",
    ActiveTabName = nil,
    isHopping = false,
    activeTpBtn = nil,
    activeTpOrigText = nil,
    isRefreshingFriends = false,
    muteAllActive = false,
}

local QuickButtons = {}
local QuickButtonStrokes = {}
local ToggleUpdaters = {}
local ThemeCallbacks = {}

local function registerThemeCallback(fn)
    table.insert(ThemeCallbacks, fn)
    fn(THEME)
end

local Modules = {
    noclipConn = nil,
    cachedCharParts = {},
    originalPartCollide = setmetatable({}, { __mode = "k" }),
    flyConn = nil,
    flyAttachment = nil,
    flyLinearVel = nil,
    flyAlignOri = nil,
    fpXRayConn = nil,
    invisicamConn = nil,
    thirdPersonConn = nil,
    transparentParts = {},
    deletedPartsMemory = {},
    espHighlights = {},
    espBillboards = {},
    espCharConns = {},
    freeCamConn = nil,
    freeCamRotateConn = nil,
    camYaw = 0,
    camPitch = 0,
    camPos = Vector3.zero,
    savedLighting = {},
    xrayFilterList = {Camera},
    xrayRayParams = RaycastParams.new(),
    gfxBackup = setmetatable({}, { __mode = "k" }),
    savedGfxLighting = {},
    fpsDescendantConn = nil,
    visitedStore = {},
    originalPromptDurations = setmetatable({}, { __mode = "k" }),
    instantPromptShownConn = nil,
    instantPromptAddedConn = nil,
    mutedPlayers = {},
    originalSoundVolumes = setmetatable({}, { __mode = "k" }),
    muteCharConns = {},
    playerCards = {},
    friendCards = {},
}
Modules.xrayRayParams.FilterType = Enum.RaycastFilterType.Exclude

local Funcs = {}
local UI = {}
local Controls = { keybindRefreshers = {} }

-- ==========================================
-- 🛑 FUNCIÓN DE LIMPIEZA TOTAL (UNLOAD)
-- ==========================================
local function unloadHub()
    if Runtime.hubUnloaded then return end
    Runtime.hubUnloaded = true
    env.__XCS_UNLOAD = nil

    if State.Invisicam and Funcs.toggleInvisicam then Funcs.toggleInvisicam(false) end
    if State.FPXRay and Funcs.toggleFPXRay then Funcs.toggleFPXRay(false) end
    if State.ESP and Funcs.toggleESP then Funcs.toggleESP(false) end
    if State.Noclip and Funcs.toggleNoclip then Funcs.toggleNoclip(false) end
    if State.Fly and Funcs.toggleFly then Funcs.toggleFly(false) end
    if State.FreeCam and Funcs.toggleFreeCam then Funcs.toggleFreeCam(false) end
    if State.Fullbright and Funcs.toggleFullbright then Funcs.toggleFullbright(false) end
    if State.ThirdPerson and Funcs.toggleThirdPerson then Funcs.toggleThirdPerson(false) end
    if State.InstantInteract and Funcs.toggleInstantInteract then Funcs.toggleInstantInteract(false) end

    if Config.FPSBooster and Funcs.toggleFPSBooster then
        Funcs.toggleFPSBooster(false)
        Config.FPSBooster = true
        saveStore()
    end

    for _, plr in ipairs(Services.Players:GetPlayers()) do
        if plr ~= LocalPlayer and Modules.mutedPlayers[plr.UserId] and Funcs.setPlayerMuted then
            Funcs.setPlayerMuted(plr, false)
        end
    end

    if Runtime.spectatingPlayer and Funcs.resetSpectate then
        Funcs.resetSpectate()
    end
    if Funcs.RestoreMap then
        Funcs.RestoreMap()
    end

    for _, conn in pairs(Modules.espCharConns) do Stealth.Disconnect(conn) end
    for _, conn in pairs(Modules.muteCharConns) do Stealth.Disconnect(conn) end
    HubMaid:DoCleaning()
end

env.__XCS_UNLOAD = unloadHub

-- ==========================================
-- 🖼️ PASO 1 DE CARGA: SCREENGUI Y BOTÓN FLOTANTE
-- ==========================================
do
    local sg = Instance.new("ScreenGui")
    Stealth.RandomizeName(sg)
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    if not pcall(function() sg.Parent = Services.CoreGui end) then
        sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    HubMaid:GiveTask(sg)
    UI.ScreenGui = sg

    function UI.applyNeonStroke(parent, color, transparency, thickness)
        local stroke = Instance.new("UIStroke")
        Stealth.RandomizeName(stroke)
        stroke.Color = color or THEME.Accent
        stroke.Transparency = transparency or 0.45
        stroke.Thickness = thickness or 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = parent
        return stroke
    end

    local mini = Instance.new("TextButton")
    Stealth.RandomizeName(mini)
    mini.Size = UDim2.new(0, 44, 0, 44)
    mini.Position = getSavedUDim2("MiniBtn")
    mini.BackgroundColor3 = THEME.BgMain
    mini.BackgroundTransparency = Config.GlassTransparency
    mini.Text = "..."
    mini.TextColor3 = THEME.AccentAmber
    mini.TextSize = 13
    mini.Font = Enum.Font.GothamBold
    mini.Visible = true
    mini.Parent = sg
    Instance.new("UICorner", mini).CornerRadius = UDim.new(1, 0)
    local miniSt = UI.applyNeonStroke(mini, THEME.AccentAmber, 0.2, 1.5)

    UI.MiniBtn = mini
    UI.miniStroke = miniSt

    registerThemeCallback(function(t)
        mini.BackgroundColor3 = t.BgMain
        mini.BackgroundTransparency = Config.GlassTransparency
        if Runtime.isReady then
            mini.TextColor3 = t.Accent
            miniSt.Color = t.Accent
        end
    end)
end

task.wait()

-- ==========================================
-- ⚡ MÓDULO DE RENDIMIENTO, SESIÓN Y SERVER HOP
-- ==========================================
do
    local SERVERS_FILE = "xcs_servers.json"

    local function optimizeSingleInstance(obj)
        if obj:IsA("BasePart") then
            if not Modules.gfxBackup[obj] then
                Modules.gfxBackup[obj] = { Material = obj.Material, Reflectance = obj.Reflectance, CastShadow = obj.CastShadow }
            end
            obj.Material = Enum.Material.SmoothPlastic
            obj.Reflectance = 0
            obj.CastShadow = false
        elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
            if not Modules.gfxBackup[obj] then
                Modules.gfxBackup[obj] = { Enabled = obj.Enabled }
            end
            obj.Enabled = false
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            if not Modules.gfxBackup[obj] then
                Modules.gfxBackup[obj] = { Transparency = obj.Transparency }
            end
            obj.Transparency = 1
        end
    end

    function Funcs.toggleFPSBooster(state)
        Config.FPSBooster = state
        saveStore()

        if state then
            Modules.savedGfxLighting = {
                GlobalShadows = Services.Lighting.GlobalShadows,
                FogEnd = Services.Lighting.FogEnd,
                EnvironmentDiffuseScale = Services.Lighting.EnvironmentDiffuseScale,
                EnvironmentSpecularScale = Services.Lighting.EnvironmentSpecularScale,
            }
            Services.Lighting.GlobalShadows = false
            Services.Lighting.FogEnd = 9e9
            pcall(function()
                Services.Lighting.EnvironmentDiffuseScale = 0
                Services.Lighting.EnvironmentSpecularScale = 0
            end)

            task.spawn(function()
                local descendants = Services.Workspace:GetDescendants()
                for i, obj in ipairs(descendants) do
                    if not Config.FPSBooster or Runtime.hubUnloaded then break end
                    optimizeSingleInstance(obj)
                    if i % 250 == 0 then
                        task.wait()
                    end
                end
            end)

            Stealth.Disconnect(Modules.fpsDescendantConn)
            Modules.fpsDescendantConn = Services.Workspace.DescendantAdded:Connect(function(obj)
                if Config.FPSBooster and not Runtime.hubUnloaded then
                    optimizeSingleInstance(obj)
                end
            end)
        else
            Stealth.Disconnect(Modules.fpsDescendantConn)
            Modules.fpsDescendantConn = nil

            if Modules.savedGfxLighting.GlobalShadows ~= nil and not State.Fullbright then
                Services.Lighting.GlobalShadows = Modules.savedGfxLighting.GlobalShadows
                Services.Lighting.FogEnd = Modules.savedGfxLighting.FogEnd
                pcall(function()
                    Services.Lighting.EnvironmentDiffuseScale = Modules.savedGfxLighting.EnvironmentDiffuseScale
                    Services.Lighting.EnvironmentSpecularScale = Modules.savedGfxLighting.EnvironmentSpecularScale
                end)
            end

            for obj, props in pairs(Modules.gfxBackup) do
                if obj and obj.Parent then
                    for propName, origVal in pairs(props) do
                        pcall(function() obj[propName] = origVal end)
                    end
                end
            end
            Modules.gfxBackup = setmetatable({}, { __mode = "k" })
        end
    end

    HubMaid:GiveTask(LocalPlayer.Idled:Connect(function()
        if Config.AntiAFK and not Runtime.hubUnloaded then
            pcall(function()
                Services.VirtualUser:CaptureController()
                Services.VirtualUser:ClickButton2(Vector2.zero)
            end)
        end
    end))

    function Funcs.performRejoin(btn)
        local origText = btn.Text
        btn.Text = "⏳ Reconectando..."
        local ok = pcall(function()
            Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
        if not ok then
            btn.Text = "❌ No se pudo reconectar"
            task.wait(1.5)
            if btn and btn.Parent then btn.Text = origText end
        end
    end

    local function loadVisitedServers()
        pcall(function()
            if isfile and readfile and isfile(SERVERS_FILE) then
                local decoded = Services.HttpService:JSONDecode(readfile(SERVERS_FILE))
                if type(decoded) == "table" then
                    Modules.visitedStore = decoded
                end
            end
        end)
        local placeKey = tostring(game.PlaceId)
        if type(Modules.visitedStore[placeKey]) ~= "table" then
            Modules.visitedStore[placeKey] = {}
        end
    end

    local function saveVisitedServers()
        pcall(function()
            if writefile then
                writefile(SERVERS_FILE, Services.HttpService:JSONEncode(Modules.visitedStore))
            end
        end)
    end

    local function markServerVisited(jobId)
        if not jobId or jobId == "" then return end
        local placeKey = tostring(game.PlaceId)
        if type(Modules.visitedStore[placeKey]) ~= "table" then
            Modules.visitedStore[placeKey] = {}
        end
        Modules.visitedStore[placeKey][jobId] = true
        saveVisitedServers()
    end

    loadVisitedServers()
    markServerVisited(game.JobId)

    HubMaid:GiveTask(Services.TeleportService.TeleportInitFailed:Connect(function(_, teleportResult)
        Runtime.isHopping = false
        if Runtime.activeTpBtn and Runtime.activeTpBtn.Parent then
            local msg = "⚠️ Error TP"
            if teleportResult == Enum.TeleportResult.GameFull then
                msg = "⚠️ Lleno (772)"
            elseif teleportResult == Enum.TeleportResult.Unauthorized then
                msg = "🔒 Privado"
            end
            Runtime.activeTpBtn.Text = msg
            local btnRef, origRef = Runtime.activeTpBtn, Runtime.activeTpOrigText
            Runtime.activeTpBtn = nil
            task.delay(1.8, function()
                if btnRef and btnRef.Parent and origRef then
                    btnRef.Text = origRef
                end
            end)
        end
    end))

    function Funcs.performServerHop(btn, sortOrder)
        if Runtime.isHopping then return end
        Runtime.isHopping = true
        local origText = btn.Text
        Runtime.activeTpBtn = btn
        Runtime.activeTpOrigText = origText
        local order = sortOrder or "Desc"
        btn.Text = "🔍 Buscando servidor..."

        task.spawn(function()
            local placeKey = tostring(game.PlaceId)
            local visited = Modules.visitedStore[placeKey] or {}

            local ok, res = pcall(function()
                local url = string.format(
                    "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=%s&limit=100",
                    game.PlaceId, order
                )
                return Services.HttpService:JSONDecode(game:HttpGet(url))
            end)

            if ok and res and type(res.data) == "table" then
                local validServers = {}
                for _, srv in ipairs(res.data) do
                    local playing = tonumber(srv.playing)
                    local maxP = tonumber(srv.maxPlayers)
                    if srv.id and srv.id ~= game.JobId and playing and maxP then
                        local freeSlots = maxP - playing
                        local minFree = (maxP >= 15) and 10 or math.max(3, math.floor(maxP * 0.25))
                        if freeSlots >= minFree and playing >= 1 then
                            table.insert(validServers, srv)
                        end
                    end
                end

                if #validServers == 0 then
                    for _, srv in ipairs(res.data) do
                        local playing = tonumber(srv.playing)
                        local maxP = tonumber(srv.maxPlayers)
                        if srv.id and srv.id ~= game.JobId and playing and maxP and (maxP - playing) >= 4 then
                            table.insert(validServers, srv)
                        end
                    end
                end

                local unvisited = {}
                for _, srv in ipairs(validServers) do
                    if not visited[srv.id] then
                        table.insert(unvisited, srv)
                    end
                end

                if #unvisited == 0 and #validServers > 0 then
                    Modules.visitedStore[placeKey] = { [game.JobId] = true }
                    saveVisitedServers()
                    unvisited = validServers
                    btn.Text = "🔄 Lista reiniciada..."
                    task.wait(0.4)
                end

                if #unvisited > 0 then
                    local poolSize = math.min(#unvisited, 15)
                    local chosen = unvisited[math.random(1, poolSize)]
                    markServerVisited(chosen.id)

                    btn.Text = "✅ Entrando (" .. chosen.playing .. "/" .. chosen.maxPlayers .. ")..."
                    local tpOk = pcall(function()
                        Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, chosen.id, LocalPlayer)
                    end)
                    if tpOk then
                        task.delay(6, function()
                            if Runtime.isHopping then
                                Runtime.isHopping = false
                                if btn and btn.Parent then btn.Text = origText end
                            end
                        end)
                        return
                    end
                end
            end

            btn.Text = "⚠️ Sin servidores"
            task.wait(1.5)
            if btn and btn.Parent then btn.Text = origText end
            Runtime.isHopping = false
        end)
    end
end

-- ==========================================
-- 🎮 MÓDULO DE FUNCIONES CORE (MOVIMIENTO Y VISUALES)
-- ==========================================
do
    function Funcs.rebuildXRayFilter()
        table.clear(Modules.xrayFilterList)
        table.insert(Modules.xrayFilterList, Camera)
        if LocalPlayer.Character then
            table.insert(Modules.xrayFilterList, LocalPlayer.Character)
        end
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                table.insert(Modules.xrayFilterList, plr.Character)
            end
        end
        Modules.xrayRayParams.FilterDescendantsInstances = Modules.xrayFilterList
    end

    function Funcs.SafeTeleport(targetCFrame)
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

    function Funcs.syncQuickBtnVisual(key, enabled)
        local btn = QuickButtons[key]
        local stroke = QuickButtonStrokes[key]
        if not btn then return end
        Services.TweenService:Create(btn, TWEEN_FAST, {
            BackgroundColor3 = enabled and THEME.BgCardOn or THEME.BgMain,
            TextColor3 = enabled and THEME.AccentGreen or THEME.TextMain
        }):Play()
        if stroke then
            Services.TweenService:Create(stroke, TWEEN_FAST, {
                Color = enabled and THEME.AccentGreen or THEME.Accent,
                Transparency = enabled and 0.15 or 0.45
            }):Play()
        end
    end

    function Funcs.setFeatureState(key, enabled, skipCallback)
        State[key] = enabled
        if ToggleUpdaters[key] then
            ToggleUpdaters[key](enabled, skipCallback)
        else
            Funcs.syncQuickBtnVisual(key, enabled)
        end
    end

    -- Interactuar sin espera
    local function makePromptInstant(prompt)
        if not prompt or not prompt:IsA("ProximityPrompt") then return end
        if Modules.originalPromptDurations[prompt] == nil then
            Modules.originalPromptDurations[prompt] = prompt.HoldDuration
        end
        prompt.HoldDuration = 0
    end

    function Funcs.toggleInstantInteract(state)
        State.InstantInteract = state
        Funcs.syncQuickBtnVisual("InstantInteract", state)

        if state then
            for _, obj in ipairs(Services.Workspace:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then
                    makePromptInstant(obj)
                end
            end

            Stealth.Disconnect(Modules.instantPromptShownConn)
            Modules.instantPromptShownConn = Services.ProximityPromptService.PromptShown:Connect(function(prompt)
                if State.InstantInteract then makePromptInstant(prompt) end
            end)

            Stealth.Disconnect(Modules.instantPromptAddedConn)
            Modules.instantPromptAddedConn = Services.Workspace.DescendantAdded:Connect(function(obj)
                if State.InstantInteract and obj:IsA("ProximityPrompt") then
                    makePromptInstant(obj)
                end
            end)
        else
            Stealth.Disconnect(Modules.instantPromptShownConn)
            Modules.instantPromptShownConn = nil
            Stealth.Disconnect(Modules.instantPromptAddedConn)
            Modules.instantPromptAddedConn = nil

            for prompt, origDuration in pairs(Modules.originalPromptDurations) do
                if prompt and prompt.Parent then
                    pcall(function() prompt.HoldDuration = origDuration end)
                end
            end
            Modules.originalPromptDurations = setmetatable({}, { __mode = "k" })
        end
    end

    -- Invisicam
    function Funcs.toggleInvisicam(state)
        State.Invisicam = state
        Funcs.syncQuickBtnVisual("Invisicam", state)
        if state then
            pcall(function()
                LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
                LocalPlayer.CameraMaxZoomDistance = 400
                LocalPlayer.CameraMinZoomDistance = 0.5
            end)
            Stealth.Disconnect(Modules.invisicamConn)
            Modules.invisicamConn = Services.RunService.RenderStepped:Connect(function()
                if not State.Invisicam then return end
                pcall(function()
                    if LocalPlayer.CameraMaxZoomDistance < 400 then
                        LocalPlayer.CameraMaxZoomDistance = 400
                    end
                end)
            end)
        else
            pcall(function()
                LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Zoom
                LocalPlayer.CameraMaxZoomDistance = 15
            end)
            Stealth.Disconnect(Modules.invisicamConn)
            Modules.invisicamConn = nil
        end
    end

    -- Third Person
    function Funcs.toggleThirdPerson(state)
        State.ThirdPerson = state
        Funcs.syncQuickBtnVisual("ThirdPerson", state)
        if state then
            pcall(function()
                LocalPlayer.CameraMode = Enum.CameraMode.Classic
                LocalPlayer.DevComputerCameraMode = Enum.DevComputerCameraMode.Classic
                LocalPlayer.DevTouchCameraMode = Enum.DevTouchCameraMode.Classic
            end)
            Stealth.Disconnect(Modules.thirdPersonConn)
            Modules.thirdPersonConn = Services.RunService.RenderStepped:Connect(function()
                if not State.ThirdPerson then return end
                pcall(function()
                    if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                        LocalPlayer.CameraMode = Enum.CameraMode.Classic
                    end
                end)
            end)
        else
            Stealth.Disconnect(Modules.thirdPersonConn)
            Modules.thirdPersonConn = nil
        end
    end

    -- ESP + Etiqueta Flotante (Nombre, Vida, Distancia)
    local function shouldShowESPBillboard()
        return State.ESP
            and (Config.ESPInfo ~= false)
            and (Config.ESPName ~= false or Config.ESPHealth ~= false or Config.ESPDistance ~= false)
    end

    local function getHealthHex(hum)
        if not hum or hum.MaxHealth <= 0 then return "#00DC78" end
        local pct = hum.Health / hum.MaxHealth
        if pct > 0.6 then return "#00DC78"
        elseif pct > 0.3 then return "#F0961E"
        else return "#EB4155" end
    end

    local function buildESPString(plr, hum, dist)
        local parts = {}
        if Config.ESPName ~= false then
            local safeName = string.gsub(plr.DisplayName, "[<>&]", "")
            table.insert(parts, string.format('<font color="#F0F5FF">%s</font>', safeName))
        end
        if Config.ESPHealth ~= false then
            local hp = hum and math.max(0, math.floor(hum.Health + 0.5)) or 0
            table.insert(parts, string.format('<font color="%s">%d HP</font>', getHealthHex(hum), hp))
        end
        if Config.ESPDistance ~= false then
            local dText = dist and (dist .. "m") or "--m"
            table.insert(parts, string.format('<font color="#91A0B9">%s</font>', dText))
        end
        return table.concat(parts, ' <font color="#5A6982">•</font> ')
    end

    function Funcs.refreshESPBillboards()
        local show = shouldShowESPBillboard()
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

        for plr, data in pairs(Modules.espBillboards) do
            if data.Gui and data.Gui.Parent then
                data.Gui.Enabled = show
                if show then
                    local char = plr.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local tHrp = char and char:FindFirstChild("HumanoidRootPart")
                    local dist = (myHrp and tHrp) and math.floor((myHrp.Position - tHrp.Position).Magnitude) or nil
                    data.Label.Text = buildESPString(plr, hum, dist)
                end
            end
        end
    end

    function Funcs.applyESPToCharacter(plr, char)
        if not State.ESP or plr == LocalPlayer or not char then return end

        if Modules.espHighlights[plr] and Modules.espHighlights[plr].Parent then
            Modules.espHighlights[plr]:Destroy()
        end
        if Modules.espBillboards[plr] and Modules.espBillboards[plr].Gui and Modules.espBillboards[plr].Gui.Parent then
            Modules.espBillboards[plr].Gui:Destroy()
        end
        Modules.espBillboards[plr] = nil

        local hl = Instance.new("Highlight")
        Stealth.RandomizeName(hl)
        hl.FillColor = Color3.fromRGB(255, 0, 80)
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.FillTransparency = 0.5
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        Modules.espHighlights[plr] = hl

        task.spawn(function()
            local adornee = char:FindFirstChild("Head")
                or char:FindFirstChild("HumanoidRootPart")
                or char:WaitForChild("Head", 2)
                or char:FindFirstChild("HumanoidRootPart")

            if not adornee or not char.Parent or not State.ESP then return end

            local bb = Instance.new("BillboardGui")
            Stealth.RandomizeName(bb)
            bb.Adornee = adornee
            bb.AlwaysOnTop = true
            bb.Size = UDim2.new(0, 220, 0, 22)
            bb.StudsOffset = (adornee.Name == "Head") and Vector3.new(0, 2.1, 0) or Vector3.new(0, 3.3, 0)
            bb.MaxDistance = 2500
            bb.Enabled = shouldShowESPBillboard()
            bb.Parent = char

            local pill = Instance.new("Frame")
            Stealth.RandomizeName(pill)
            pill.AnchorPoint = Vector2.new(0.5, 0.5)
            pill.Position = UDim2.new(0.5, 0, 0.5, 0)
            pill.Size = UDim2.new(0, 0, 0, 18)
            pill.AutomaticSize = Enum.AutomaticSize.X
            pill.BackgroundColor3 = Color3.fromRGB(13, 17, 26)
            pill.BackgroundTransparency = 0.35
            pill.BorderSizePixel = 0
            pill.Parent = bb
            Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

            local pillStroke = Instance.new("UIStroke")
            Stealth.RandomizeName(pillStroke)
            pillStroke.Color = Color3.fromRGB(255, 0, 80)
            pillStroke.Transparency = 0.45
            pillStroke.Thickness = 1
            pillStroke.Parent = pill

            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 7)
            pad.PaddingRight = UDim.new(0, 7)
            pad.Parent = pill

            local lbl = Instance.new("TextLabel")
            Stealth.RandomizeName(lbl)
            lbl.Size = UDim2.new(0, 0, 1, 0)
            lbl.AutomaticSize = Enum.AutomaticSize.X
            lbl.BackgroundTransparency = 1
            lbl.RichText = true
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 10
            lbl.TextColor3 = Color3.fromRGB(240, 245, 255)
            lbl.TextStrokeTransparency = 0.65
            lbl.Parent = pill

            local hum = char:FindFirstChildOfClass("Humanoid")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local tHrp = char:FindFirstChild("HumanoidRootPart")
            local dist = (myHrp and tHrp) and math.floor((myHrp.Position - tHrp.Position).Magnitude) or nil
            lbl.Text = buildESPString(plr, hum, dist)

            Modules.espBillboards[plr] = { Gui = bb, Label = lbl, Stroke = pillStroke }
        end)
    end

    function Funcs.setupPlayerESP(plr)
        if plr == LocalPlayer then return end
        if Modules.espCharConns[plr] then Stealth.Disconnect(Modules.espCharConns[plr]) end
        Modules.espCharConns[plr] = plr.CharacterAdded:Connect(function(char)
            Funcs.rebuildXRayFilter()
            task.wait(0.2)
            if State.ESP then Funcs.applyESPToCharacter(plr, char) end
        end)
        if State.ESP and plr.Character then
            Funcs.applyESPToCharacter(plr, plr.Character)
        end
    end

    function Funcs.toggleESP(state)
        State.ESP = state
        Funcs.syncQuickBtnVisual("ESP", state)
        if state then
            for _, plr in ipairs(Services.Players:GetPlayers()) do
                Funcs.setupPlayerESP(plr)
            end
        else
            for _, hl in pairs(Modules.espHighlights) do
                if hl and hl.Parent then hl:Destroy() end
            end
            table.clear(Modules.espHighlights)
            for _, data in pairs(Modules.espBillboards) do
                if data.Gui and data.Gui.Parent then data.Gui:Destroy() end
            end
            table.clear(Modules.espBillboards)
        end
    end

    task.spawn(function()
        while not Runtime.hubUnloaded do
            if State.ESP then
                Funcs.refreshESPBillboards()
            end
            task.wait(0.15)
        end
    end)

    -- Noclip
    function Funcs.cacheCharacterParts(char)
        table.clear(Modules.cachedCharParts)
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
                table.insert(Modules.cachedCharParts, part)
                if Modules.originalPartCollide[part] == nil then
                    Modules.originalPartCollide[part] = part.CanCollide
                end
            end
        end
        char.DescendantAdded:Connect(function(desc)
            if desc:IsA("BasePart") and not desc:FindFirstAncestorOfClass("Accessory") then
                table.insert(Modules.cachedCharParts, desc)
                if Modules.originalPartCollide[desc] == nil then
                    Modules.originalPartCollide[desc] = desc.CanCollide
                end
            end
        end)
    end

    if LocalPlayer.Character then Funcs.cacheCharacterParts(LocalPlayer.Character) end

    function Funcs.toggleNoclip(state)
        State.Noclip = state
        Funcs.syncQuickBtnVisual("Noclip", state)

        if state then
            Stealth.Disconnect(Modules.noclipConn)
            Modules.noclipConn = nil

            if #Modules.cachedCharParts == 0 and LocalPlayer.Character then
                Funcs.cacheCharacterParts(LocalPlayer.Character)
            end

            Modules.noclipConn = Services.RunService.Stepped:Connect(function()
                if not State.Noclip then return end
                for i = 1, #Modules.cachedCharParts do
                    local part = Modules.cachedCharParts[i]
                    if part and part.Parent and part.CanCollide then
                        if Modules.originalPartCollide[part] == nil then
                            Modules.originalPartCollide[part] = true
                        end
                        part.CanCollide = false
                    end
                end
            end)
        else
            Stealth.Disconnect(Modules.noclipConn)
            Modules.noclipConn = nil

            for i = 1, #Modules.cachedCharParts do
                local part = Modules.cachedCharParts[i]
                if part and part.Parent and Modules.originalPartCollide[part] ~= nil then
                    part.CanCollide = Modules.originalPartCollide[part]
                end
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end

    function Funcs.toggleInfJump(state)
        State.InfJump = state
        Funcs.syncQuickBtnVisual("InfJump", state)
    end

    function Funcs.toggleDeleteMode(state)
        State.DeleteMode = state
        Funcs.syncQuickBtnVisual("DeleteMode", state)
    end

    function Funcs.RestoreMap()
        for _, data in ipairs(Modules.deletedPartsMemory) do
            if data.part and data.part.Parent then
                data.part.Transparency = data.trans
                data.part.CanCollide = data.collide
            end
        end
        table.clear(Modules.deletedPartsMemory)
    end

    local function clearXRayParts()
        for part, origTrans in pairs(Modules.transparentParts) do
            if part and part.Parent then
                part.Transparency = origTrans
            end
        end
        table.clear(Modules.transparentParts)
    end

    function Funcs.toggleFPXRay(state)
        State.FPXRay = state
        Funcs.syncQuickBtnVisual("FPXRay", state)
        if state then
            Funcs.rebuildXRayFilter()
            Stealth.Disconnect(Modules.fpXRayConn)
            Modules.fpXRayConn = Services.RunService.RenderStepped:Connect(function()
                if not State.FPXRay or not LocalPlayer.Character then return end
                clearXRayParts()

                local rayOrigin = Camera.CFrame.Position
                local rayDirection = Camera.CFrame.LookVector * 250
                local currentOrigin = rayOrigin

                for _ = 1, 5 do
                    local result = Services.Workspace:Raycast(currentOrigin, rayDirection, Modules.xrayRayParams)
                    if result and result.Instance then
                        local hitPart = result.Instance
                        if hitPart:IsA("BasePart")
                            and not hitPart:FindFirstAncestorOfClass("Accessory")
                            and not hitPart.Parent:FindFirstChildOfClass("Humanoid") then
                            if hitPart.Transparency < 0.7 and not Modules.transparentParts[hitPart] then
                                Modules.transparentParts[hitPart] = hitPart.Transparency
                                hitPart.Transparency = 0.7
                            end
                        end
                        currentOrigin = result.Position + rayDirection.Unit * 0.1
                    else
                        break
                    end
                end
            end)
        else
            Stealth.Disconnect(Modules.fpXRayConn)
            Modules.fpXRayConn = nil
            clearXRayParts()
        end
    end

    function Funcs.toggleFullbright(state)
        State.Fullbright = state
        Funcs.syncQuickBtnVisual("Fullbright", state)
        if state then
            Modules.savedLighting = {
                Ambient = Services.Lighting.Ambient,
                OutdoorAmbient = Services.Lighting.OutdoorAmbient,
                Brightness = Services.Lighting.Brightness,
                ClockTime = Services.Lighting.ClockTime,
                FogEnd = Services.Lighting.FogEnd,
                GlobalShadows = Services.Lighting.GlobalShadows,
            }
            Services.Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Services.Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            Services.Lighting.Brightness = 2
            Services.Lighting.ClockTime = 12
            Services.Lighting.FogEnd = 1000000
            Services.Lighting.GlobalShadows = false
        elseif Modules.savedLighting.Ambient then
            Services.Lighting.Ambient = Modules.savedLighting.Ambient
            Services.Lighting.OutdoorAmbient = Modules.savedLighting.OutdoorAmbient
            Services.Lighting.Brightness = Modules.savedLighting.Brightness
            Services.Lighting.ClockTime = Modules.savedLighting.ClockTime
            Services.Lighting.FogEnd = Config.FPSBooster and 9e9 or Modules.savedLighting.FogEnd
            Services.Lighting.GlobalShadows = Config.FPSBooster and false or Modules.savedLighting.GlobalShadows
        end
    end

    -- Fly & FreeCam
    local function getMoveDirection()
        local c = LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if not hum or hum.MoveDirection.Magnitude == 0 then return Vector3.zero end
        local move = Camera.CFrame:VectorToObjectSpace(hum.MoveDirection)
        return (Camera.CFrame * CFrame.new(move.X, 0, move.Z)).Position - Camera.CFrame.Position
    end

    local function cleanupFlyPhysics()
        Stealth.Disconnect(Modules.flyConn)
        Modules.flyConn = nil
        if Modules.flyLinearVel then Modules.flyLinearVel:Destroy(); Modules.flyLinearVel = nil end
        if Modules.flyAlignOri then Modules.flyAlignOri:Destroy(); Modules.flyAlignOri = nil end
        if Modules.flyAttachment then Modules.flyAttachment:Destroy(); Modules.flyAttachment = nil end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end

    function Funcs.toggleFly(state)
        State.Fly = state
        Funcs.syncQuickBtnVisual("Fly", state)
        if state then
            cleanupFlyPhysics()
            if State.FreeCam and Funcs.toggleFreeCam then Funcs.setFeatureState("FreeCam", false) end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp then return end

            if hum then hum.PlatformStand = true end

            local att = Instance.new("Attachment")
            Stealth.RandomizeName(att)
            att.Parent = hrp
            Modules.flyAttachment = att

            local lv = Instance.new("LinearVelocity")
            Stealth.RandomizeName(lv)
            lv.Attachment0 = att
            lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
            lv.MaxForce = math.huge
            lv.VectorVelocity = Vector3.zero
            lv.Parent = hrp
            Modules.flyLinearVel = lv

            local ao = Instance.new("AlignOrientation")
            Stealth.RandomizeName(ao)
            ao.Attachment0 = att
            ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
            ao.RigidityEnabled = true
            ao.CFrame = hrp.CFrame
            ao.Parent = hrp
            Modules.flyAlignOri = ao

            Modules.flyConn = Services.RunService.RenderStepped:Connect(function()
                if not State.Fly then return end
                local c = LocalPlayer.Character
                if not c or not c:FindFirstChild("HumanoidRootPart") or not Modules.flyLinearVel or not Modules.flyAlignOri then return end

                local speed = Config.FlySpeed * (Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 2 or 1)
                local moveVector = Vector3.zero

                if Services.UserInputService.KeyboardEnabled then
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += Camera.CFrame.LookVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= Camera.CFrame.LookVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= Camera.CFrame.RightVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += Camera.CFrame.RightVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.yAxis end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector -= Vector3.yAxis end
                else
                    moveVector = getMoveDirection()
                end

                Modules.flyLinearVel.VectorVelocity = moveVector.Magnitude > 0 and (moveVector.Unit * speed) or Vector3.zero
                Modules.flyAlignOri.CFrame = Camera.CFrame
            end)
        else
            cleanupFlyPhysics()
        end
    end

    function Funcs.toggleFreeCam(state)
        State.FreeCam = state
        Funcs.syncQuickBtnVisual("FreeCam", state)
        if state then
            if State.Fly then Funcs.setFeatureState("Fly", false) end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 0; hum.JumpPower = 0 end

            Camera.CameraType = Enum.CameraType.Scriptable
            local look = Camera.CFrame.LookVector
            Modules.camYaw = math.atan2(-look.X, -look.Z)
            Modules.camPitch = math.asin(look.Y)
            Modules.camPos = Camera.CFrame.Position

            Stealth.Disconnect(Modules.freeCamConn)
            Modules.freeCamConn = Services.RunService.RenderStepped:Connect(function(dt)
                if not State.FreeCam then return end
                local rot = CFrame.fromEulerAnglesYXZ(Modules.camPitch, Modules.camYaw, 0)
                local moveVector = Vector3.zero
                local speed = Config.FreeCamSpeed * (Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 2 or 1)

                if Services.UserInputService.KeyboardEnabled then
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += rot.LookVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= rot.LookVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= rot.RightVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += rot.RightVector end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector += Vector3.yAxis end
                    if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector -= Vector3.yAxis end
                else
                    local c = LocalPlayer.Character
                    local h = c and c:FindFirstChildOfClass("Humanoid")
                    if h and h.MoveDirection.Magnitude > 0.05 then
                        local localMove = Camera.CFrame:VectorToObjectSpace(h.MoveDirection)
                        moveVector = (rot.LookVector * -localMove.Z) + (rot.RightVector * localMove.X)
                    end
                end

                if moveVector.Magnitude > 0 then
                    Modules.camPos += moveVector.Unit * speed * dt
                end
                Camera.CFrame = CFrame.new(Modules.camPos, Modules.camPos + rot.LookVector)
            end)

            Stealth.Disconnect(Modules.freeCamRotateConn)
            Modules.freeCamRotateConn = Services.UserInputService.InputChanged:Connect(function(input, gameProcessed)
                if not State.FreeCam or gameProcessed then return end
                if input.UserInputType == Enum.UserInputType.Touch
                    or (input.UserInputType == Enum.UserInputType.MouseMovement and Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)) then
                    Modules.camYaw -= input.Delta.X * 0.005
                    Modules.camPitch = math.clamp(Modules.camPitch - input.Delta.Y * 0.005, math.rad(-89), math.rad(89))
                end
            end)
        else
            Stealth.Disconnect(Modules.freeCamConn)
            Modules.freeCamConn = nil
            Stealth.Disconnect(Modules.freeCamRotateConn)
            Modules.freeCamRotateConn = nil
            Camera.CameraType = Enum.CameraType.Custom
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
        end
    end
end

-- ==========================================
-- 🖼️ PASO 2 DE CARGA: VENTANA Y LIBRERÍA DE COMPONENTES
-- ==========================================
do
    local mainFrame = Instance.new("Frame")
    Stealth.RandomizeName(mainFrame)
    mainFrame.Size = UDim2.new(0, 275, 0, 355)
    mainFrame.Position = getSavedUDim2("MainFrame")
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = UI.ScreenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
    local mainSt = UI.applyNeonStroke(mainFrame, THEME.Accent, 0.35, 1.3)

    local scaler = Instance.new("UIScale")
    scaler.Scale = Config.UiScale
    scaler.Parent = mainFrame

    local header = Instance.new("TextButton")
    Stealth.RandomizeName(header)
    header.Size = UDim2.new(1, 0, 0, 32)
    header.Text = "   ◈ xcs Hub  v3.1"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 11
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.AutoButtonColor = false
    header.Parent = mainFrame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

    local headerLine = Instance.new("Frame")
    Stealth.RandomizeName(headerLine)
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, -1)
    headerLine.BorderSizePixel = 0
    headerLine.Parent = header

    local function createHeaderIcon(text, offsetX, customColor)
        local btn = Instance.new("TextButton")
        Stealth.RandomizeName(btn)
        btn.Size = UDim2.new(0, 22, 0, 22)
        btn.Position = UDim2.new(1, offsetX, 0.5, -11)
        btn.BackgroundTransparency = 0.2
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.Parent = header
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
        local st = UI.applyNeonStroke(btn, customColor or THEME.Accent, 0.4, 1)
        return btn, st
    end

    local masterBtn, masterSt = createHeaderIcon("👁️", -54)
    local minBtn, minSt       = createHeaderIcon("✕",  -28, THEME.AccentRed)

    local tabBar = Instance.new("Frame")
    Stealth.RandomizeName(tabBar)
    tabBar.Size = UDim2.new(1, -16, 0, 26)
    tabBar.Position = UDim2.new(0, 8, 0, 38)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    local pagesFolder = Instance.new("Frame")
    Stealth.RandomizeName(pagesFolder)
    pagesFolder.Size = UDim2.new(1, 0, 1, -70)
    pagesFolder.Position = UDim2.new(0, 0, 0, 70)
    pagesFolder.BackgroundTransparency = 1
    pagesFolder.Parent = mainFrame

    UI.MainFrame = mainFrame
    UI.mainStroke = mainSt
    UI.UiScaler = scaler
    UI.Header = header
    UI.MasterQuickBtn = masterBtn
    UI.masterQuickStroke = masterSt
    UI.MinimizeBtn = minBtn
    UI.TabBar = tabBar
    UI.PagesFolder = pagesFolder
    UI.Tabs = {}

    registerThemeCallback(function(t)
        mainFrame.BackgroundColor3 = t.BgMain
        mainFrame.BackgroundTransparency = Config.GlassTransparency
        mainSt.Color = t.Accent
        header.BackgroundColor3 = t.BgHeader
        header.BackgroundTransparency = math.clamp(Config.GlassTransparency + 0.03, 0, 0.85)
        header.TextColor3 = t.TextMain
        headerLine.BackgroundColor3 = t.Accent
        headerLine.BackgroundTransparency = 0.65

        masterBtn.BackgroundColor3 = Runtime.quickButtonsMaster and t.AccentGreen or t.SwitchOff
        masterBtn.TextColor3 = t.TextMain
        masterSt.Color = Runtime.quickButtonsMaster and t.AccentGreen or t.Accent

        minBtn.BackgroundColor3 = t.AccentRed
        minBtn.TextColor3 = t.TextMain
        minSt.Color = t.AccentRed
    end)

    function UI.selectTab(name)
        Runtime.ActiveTabName = name
        for tabName, tabData in pairs(UI.Tabs) do
            local isSelected = (tabName == name)
            tabData.Page.Visible = isSelected
            Services.TweenService:Create(tabData.Button, TWEEN_FAST, {
                BackgroundColor3 = isSelected and THEME.Accent or THEME.BgCard,
                BackgroundTransparency = isSelected and 0.15 or 0.35,
                TextColor3 = isSelected and THEME.BgMain or THEME.TextMuted
            }):Play()
            tabData.Stroke.Color = THEME.Accent
            tabData.Stroke.Transparency = isSelected and 0.1 or 0.75
        end
    end

    function UI.CreateTab(name, icon)
        local tabBtn = Instance.new("TextButton")
        Stealth.RandomizeName(tabBtn)
        tabBtn.Size = UDim2.new(0.25, -3, 1, 0)
        tabBtn.Text = icon .. " " .. name
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 9
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabBar
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 7)
        local tabStroke = UI.applyNeonStroke(tabBtn, THEME.Accent, 0.75, 1)

        local page = Instance.new("ScrollingFrame")
        Stealth.RandomizeName(page)
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 2
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = pagesFolder

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
        UI.Tabs[name] = TabObj

        tabBtn.MouseButton1Click:Connect(function()
            UI.selectTab(name)
        end)

        registerThemeCallback(function(t)
            page.ScrollBarImageColor3 = t.Accent
            if Runtime.ActiveTabName == name then
                tabBtn.BackgroundColor3 = t.Accent
                tabBtn.TextColor3 = t.BgMain
            else
                tabBtn.BackgroundColor3 = t.BgCard
                tabBtn.TextColor3 = t.TextMuted
            end
            tabStroke.Color = t.Accent
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
            local stroke = UI.applyNeonStroke(card, THEME.Accent, 0.78, 1)

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
                Services.TweenService:Create(bg, TWEEN_FAST, {
                    BackgroundColor3 = val and THEME.AccentGreen or THEME.SwitchOff
                }):Play()
                Services.TweenService:Create(knob, TWEEN_FAST, {
                    Position = val and UDim2.new(0, 18, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                }):Play()
                Services.TweenService:Create(card, TWEEN_FAST, {
                    BackgroundColor3 = val and THEME.BgCardOn or THEME.BgCard
                }):Play()
                Services.TweenService:Create(stroke, TWEEN_FAST, {
                    Color = val and THEME.AccentGreen or THEME.Accent,
                    Transparency = val and 0.35 or 0.78
                }):Play()

                if opts.Key then Funcs.syncQuickBtnVisual(opts.Key, val) end
                if not skipCb and opts.Callback then opts.Callback(val) end
            end

            if opts.Key then ToggleUpdaters[opts.Key] = updateVisual end

            registerThemeCallback(function(t)
                label.TextColor3 = t.TextMain
                bg.BackgroundColor3 = current and t.AccentGreen or t.SwitchOff
                card.BackgroundColor3 = current and t.BgCardOn or t.BgCard
                stroke.Color = current and t.AccentGreen or t.Accent
            end)

            bg.MouseButton1Click:Connect(function()
                local nextState = not current
                if opts.Key then State[opts.Key] = nextState end
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
            local stroke = UI.applyNeonStroke(card, THEME.Accent, 0.78, 1)

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

            HubMaid:GiveTask(Services.UserInputService.InputChanged:Connect(function(input)
                if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    applyInputX(input.Position.X)
                end
            end))

            HubMaid:GiveTask(Services.UserInputService.InputEnded:Connect(function(input)
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
            local stroke = UI.applyNeonStroke(card, THEME.Accent, 0.8, 1)

            local label = Instance.new("TextLabel")
            Stealth.RandomizeName(label)
            label.Size = UDim2.new(0.58, 0, 1, 0)
            label.Position = UDim2.new(0, 9, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = opts.Title
            label.Font = Enum.Font.Gotham
            label.TextSize = 9
            label.TextTruncate = Enum.TextTruncate.AtEnd
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = card

            local box = Instance.new("TextButton")
            Stealth.RandomizeName(box)
            box.Size = UDim2.new(0, 46, 0, 18)
            box.Position = UDim2.new(1, -76, 0.5, -9)
            box.Text = Config.Keybinds[opts.KeyName] or "None"
            box.Font = Enum.Font.GothamBold
            box.TextSize = 8
            box.Parent = card
            Instance.new("UICorner", box).CornerRadius = UDim.new(0, 5)
            local boxStroke = UI.applyNeonStroke(box, THEME.Accent, 0.5, 1)

            local clearBtn = Instance.new("TextButton")
            Stealth.RandomizeName(clearBtn)
            clearBtn.Size = UDim2.new(0, 20, 0, 18)
            clearBtn.Position = UDim2.new(1, -26, 0.5, -9)
            clearBtn.Text = "✕"
            clearBtn.Font = Enum.Font.GothamBold
            clearBtn.TextSize = 8
            clearBtn.Parent = card
            Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)
            local clearStroke = UI.applyNeonStroke(clearBtn, THEME.AccentRed, 0.55, 1)

            local function refreshKeyVisual()
                local val = Config.Keybinds[opts.KeyName] or "None"
                box.Text = val
                if Runtime.listeningFor ~= opts.KeyName then
                    box.BackgroundColor3 = THEME.BgHeader
                    box.TextColor3 = (val == "None") and THEME.TextMuted or THEME.Accent
                    boxStroke.Color = THEME.Accent
                    boxStroke.Transparency = (val == "None") and 0.75 or 0.5
                end
            end

            registerThemeCallback(function(t)
                card.BackgroundColor3 = t.BgCard
                stroke.Color = t.Accent
                label.TextColor3 = t.TextMain
                clearBtn.BackgroundColor3 = t.BgHeader
                clearBtn.TextColor3 = t.AccentRed
                clearStroke.Color = t.AccentRed
                refreshKeyVisual()
            end)

            local activeConn = nil

            clearBtn.MouseButton1Click:Connect(function()
                if activeConn then activeConn:Disconnect(); activeConn = nil end
                if Runtime.listeningFor == opts.KeyName then Runtime.listeningFor = nil end
                Config.Keybinds[opts.KeyName] = "None"
                saveStore()
                refreshKeyVisual()
            end)

            box.MouseButton1Click:Connect(function()
                if Runtime.listeningFor then return end
                Runtime.listeningFor = opts.KeyName
                box.Text = "..."
                box.BackgroundColor3 = THEME.AccentAmber
                box.TextColor3 = THEME.TextMain

                activeConn = Services.UserInputService.InputBegan:Connect(function(input, gp)
                    if gp then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        local kc = input.KeyCode
                        if kc == Enum.KeyCode.Backspace or kc == Enum.KeyCode.Delete or kc == Enum.KeyCode.Escape then
                            Config.Keybinds[opts.KeyName] = "None"
                        else
                            Config.Keybinds[opts.KeyName] = kc.Name
                        end
                        saveStore()
                        Runtime.listeningFor = nil
                        if activeConn then activeConn:Disconnect(); activeConn = nil end
                        refreshKeyVisual()
                    end
                end)
            end)

            return { Refresh = refreshKeyVisual }
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
            local stroke = UI.applyNeonStroke(btn, opts.Danger and THEME.AccentRed or THEME.Accent, 0.35, 1)

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
end

task.wait()

-- ==========================================
-- 📑 PASO 3 DE CARGA: PESTAÑAS 1 Y 2 (MOV. Y VIS.)
-- ==========================================
local TabMove    = UI.CreateTab("Mov.", "🕊️")
local TabVisuals = UI.CreateTab("Vis.", "👁️")
local TabPlayers = UI.CreateTab("Jug.", "👥")
local TabConfig  = UI.CreateTab("Ajust.", "⚙️")

do
    TabMove:AddSection("Desplazamiento")
    TabMove:AddToggle({ Key = "Fly",     Icon = "🕊️", Title = "Fly (Vuelo)",         Callback = Funcs.toggleFly })
    TabMove:AddToggle({ Key = "Noclip",  Icon = "👻", Title = "Noclip (Atravesar)",  Callback = Funcs.toggleNoclip })
    TabMove:AddToggle({ Key = "InfJump", Icon = "⚡", Title = "Infinite Jump",       Callback = Funcs.toggleInfJump })
    if isTouchDevice then
        TabMove:AddToggle({ Key = "TPS", Icon = "📍", Title = "TPS (Toque en mapa)", Callback = function(v) State.TPS = v end })
    end

    TabMove:AddSection("Velocidades")
    Controls.flySlider = TabMove:AddSlider({
        Title = "Velocidad Fly", Min = 10, Max = 300, Default = Config.FlySpeed,
        OnChange = function(v) Config.FlySpeed = v end,
        OnRelease = function() saveStore() end
    })

    TabVisuals:AddSection("Cámara y Visión")
    TabVisuals:AddToggle({ Key = "ESP", Icon = "🎯", Title = "ESP Jugadores", Callback = Funcs.toggleESP })

    Controls.espInfoToggle = TabVisuals:AddToggle({
        Icon = "🏷️", Title = "ESP: Etiqueta Flotante", Default = Config.ESPInfo ~= false,
        Callback = function(v) Config.ESPInfo = v; saveStore(); Funcs.refreshESPBillboards() end
    })
    Controls.espNameToggle = TabVisuals:AddToggle({
        Icon = "🪪", Title = "ESP: Mostrar Nombre", Default = Config.ESPName ~= false,
        Callback = function(v) Config.ESPName = v; saveStore(); Funcs.refreshESPBillboards() end
    })
    Controls.espHealthToggle = TabVisuals:AddToggle({
        Icon = "❤️", Title = "ESP: Mostrar Vida (HP)", Default = Config.ESPHealth ~= false,
        Callback = function(v) Config.ESPHealth = v; saveStore(); Funcs.refreshESPBillboards() end
    })
    Controls.espDistToggle = TabVisuals:AddToggle({
        Icon = "📏", Title = "ESP: Mostrar Distancia (m)", Default = Config.ESPDistance ~= false,
        Callback = function(v) Config.ESPDistance = v; saveStore(); Funcs.refreshESPBillboards() end
    })

    TabVisuals:AddToggle({ Key = "Invisicam",   Icon = "👁️", Title = "Invisicam + Zoom",     Callback = Funcs.toggleInvisicam })
    TabVisuals:AddToggle({ Key = "FPXRay",      Icon = "🧱", Title = "FP X-Ray (Paredes)",   Callback = Funcs.toggleFPXRay })
    TabVisuals:AddToggle({ Key = "Fullbright",  Icon = "☀️", Title = "Fullbright",           Callback = Funcs.toggleFullbright })
    TabVisuals:AddToggle({ Key = "ThirdPerson", Icon = "🧍", Title = "Third Person Forzado", Callback = Funcs.toggleThirdPerson })
    TabVisuals:AddToggle({ Key = "FreeCam",     Icon = "🎥", Title = "Free Cam",             Callback = Funcs.toggleFreeCam })

    Controls.freeCamSlider = TabVisuals:AddSlider({
        Title = "Velocidad Free Cam", Min = 10, Max = 300, Default = Config.FreeCamSpeed,
        OnChange = function(v) Config.FreeCamSpeed = v end,
        OnRelease = function() saveStore() end
    })

    TabVisuals:AddSection("Interacción y Mapa")
    TabVisuals:AddToggle({ Key = "InstantInteract", Icon = "⚡", Title = "Interactuar sin Espera", Callback = Funcs.toggleInstantInteract })
    TabVisuals:AddToggle({ Key = "DeleteMode",      Icon = "🗑️", Title = "Borrador de Paredes",    Callback = Funcs.toggleDeleteMode })
    TabVisuals:AddButton({ Title = "♻️ Restaurar Paredes Borradas", Callback = Funcs.RestoreMap })
end

task.wait()

-- ==========================================
-- 👥 PASO 4 DE CARGA: PESTAÑA 3 (JUGADORES, MUTE Y AMIGOS)
-- ==========================================
do
    local SubTabBar = Instance.new("Frame")
    Stealth.RandomizeName(SubTabBar)
    SubTabBar.Size = UDim2.new(1, 0, 0, 22)
    SubTabBar.BackgroundTransparency = 1
    SubTabBar.Parent = TabPlayers.Page

    local function makeSubTabBtn(text, posX)
        local b = Instance.new("TextButton")
        Stealth.RandomizeName(b)
        b.Size = UDim2.new(0.5, -2, 1, 0)
        b.Position = posX
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 8
        b.AutoButtonColor = false
        b.Parent = SubTabBar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local st = UI.applyNeonStroke(b, THEME.Accent, 0.5, 1)
        return b, st
    end

    local SubServerBtn, subServerStroke   = makeSubTabBtn("🌐 En Servidor", UDim2.new(0, 0, 0, 0))
    local SubFriendsBtn, subFriendsStroke = makeSubTabBtn("⭐ Amigos",      UDim2.new(0.5, 2, 0, 0))

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
    local searchStroke = UI.applyNeonStroke(searchBox, THEME.Accent, 0.65, 1)

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
        local st = UI.applyNeonStroke(b, THEME.Accent, 0.5, 1)
        return b, st
    end

    local PrevSpecBtn, prevSpecStroke = makeSpecNavBtn("◀", UDim2.new(0, 0, 0, 0),      UDim2.new(0, 28, 1, 0))
    local SelfSpecBtn, selfSpecStroke = makeSpecNavBtn("🏠 Mi Cámara", UDim2.new(0, 32, 0, 0), UDim2.new(1, -64, 1, 0))
    local NextSpecBtn, nextSpecStroke = makeSpecNavBtn("▶", UDim2.new(1, -28, 0, 0),    UDim2.new(0, 28, 1, 0))

    local MuteAllBtn = Instance.new("TextButton")
    Stealth.RandomizeName(MuteAllBtn)
    MuteAllBtn.Size = UDim2.new(1, 0, 0, 22)
    MuteAllBtn.BackgroundTransparency = 0.15
    MuteAllBtn.Text = "🔇 Silenciar a Todos"
    MuteAllBtn.Font = Enum.Font.GothamBold
    MuteAllBtn.TextSize = 8
    MuteAllBtn.Parent = TabPlayers.Page
    Instance.new("UICorner", MuteAllBtn).CornerRadius = UDim.new(0, 6)
    local muteAllStroke = UI.applyNeonStroke(MuteAllBtn, THEME.Accent, 0.5, 1)

    local RefreshFriendsBtn = Instance.new("TextButton")
    Stealth.RandomizeName(RefreshFriendsBtn)
    RefreshFriendsBtn.Size = UDim2.new(1, 0, 0, 24)
    RefreshFriendsBtn.BackgroundTransparency = 0.15
    RefreshFriendsBtn.Text = "🔄 Actualizar Amigos Conectados"
    RefreshFriendsBtn.Font = Enum.Font.GothamBold
    RefreshFriendsBtn.TextSize = 9
    RefreshFriendsBtn.Visible = false
    RefreshFriendsBtn.Parent = TabPlayers.Page
    Instance.new("UICorner", RefreshFriendsBtn).CornerRadius = UDim.new(0, 6)
    local refreshFriendsStroke = UI.applyNeonStroke(RefreshFriendsBtn, THEME.Accent, 0.4, 1)

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

    local FriendsListContainer = Instance.new("Frame")
    Stealth.RandomizeName(FriendsListContainer)
    FriendsListContainer.Size = UDim2.new(1, 0, 0, 0)
    FriendsListContainer.AutomaticSize = Enum.AutomaticSize.Y
    FriendsListContainer.BackgroundTransparency = 1
    FriendsListContainer.Visible = false
    FriendsListContainer.Parent = TabPlayers.Page

    local FriendsListLayout = Instance.new("UIListLayout")
    FriendsListLayout.Padding = UDim.new(0, 4)
    FriendsListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FriendsListLayout.Parent = FriendsListContainer

    -- Sistema de silencio
    local function applyAudioMuteState(plr, isMuted)
        if not plr or plr == LocalPlayer then return end
        for _, inst in ipairs(plr:GetDescendants()) do
            if inst:IsA("AudioDeviceInput") then
                pcall(function() inst.Muted = isMuted end)
            end
        end
        for _, inst in ipairs(Services.Workspace:GetDescendants()) do
            if inst:IsA("AudioDeviceInput") and inst.Player == plr then
                pcall(function() inst.Muted = isMuted end)
            end
        end
        pcall(function()
            local vci = game:GetService("VoiceChatInternal")
            if vci and vci.SubscribePause then
                vci:SubscribePause(plr.UserId, isMuted)
            end
        end)

        local function handleSound(snd)
            if snd:IsA("Sound") then
                if isMuted then
                    if Modules.originalSoundVolumes[snd] == nil then
                        Modules.originalSoundVolumes[snd] = snd.Volume
                    end
                    snd.Volume = 0
                elseif Modules.originalSoundVolumes[snd] ~= nil then
                    snd.Volume = Modules.originalSoundVolumes[snd]
                    Modules.originalSoundVolumes[snd] = nil
                end
            end
        end

        if plr.Character then
            for _, desc in ipairs(plr.Character:GetDescendants()) do
                handleSound(desc)
            end
        end
    end

    function Funcs.updateMuteVisuals()
        MuteAllBtn.BackgroundColor3 = Runtime.muteAllActive and THEME.AccentRed or THEME.BgCard
        MuteAllBtn.TextColor3 = Runtime.muteAllActive and THEME.TextMain or THEME.TextMuted
        MuteAllBtn.Text = Runtime.muteAllActive and "🔊 Quitar Silencio a Todos" or "🔇 Silenciar a Todos"
        muteAllStroke.Color = Runtime.muteAllActive and THEME.AccentRed or THEME.Accent

        for plr, data in pairs(Modules.playerCards) do
            local isMuted = Modules.mutedPlayers[plr.UserId] == true
            if data.MuteBtn then
                data.MuteBtn.BackgroundColor3 = isMuted and THEME.AccentRed or THEME.SwitchOff
                data.MuteBtn.Text = isMuted and "🔇" or "🔊"
            end
        end
    end

    function Funcs.setPlayerMuted(plr, isMuted)
        if not plr or plr == LocalPlayer then return end
        Modules.mutedPlayers[plr.UserId] = isMuted or nil

        if Modules.muteCharConns[plr] then
            Stealth.Disconnect(Modules.muteCharConns[plr])
            Modules.muteCharConns[plr] = nil
        end

        if isMuted then
            Modules.muteCharConns[plr] = plr.DescendantAdded:Connect(function(desc)
                if Modules.mutedPlayers[plr.UserId] then
                    if desc:IsA("AudioDeviceInput") then
                        pcall(function() desc.Muted = true end)
                    elseif desc:IsA("Sound") then
                        if Modules.originalSoundVolumes[desc] == nil then
                            Modules.originalSoundVolumes[desc] = desc.Volume
                        end
                        desc.Volume = 0
                    end
                end
            end)
        end

        applyAudioMuteState(plr, isMuted)
        Funcs.updateMuteVisuals()
    end

    HubMaid:GiveTask(Services.Workspace.DescendantAdded:Connect(function(desc)
        if Runtime.hubUnloaded then return end
        if desc:IsA("AudioDeviceInput") then
            task.defer(function()
                local owner = desc.Player
                if owner and (Modules.mutedPlayers[owner.UserId] or Runtime.muteAllActive) then
                    pcall(function() desc.Muted = true end)
                end
            end)
        end
    end))

    MuteAllBtn.MouseButton1Click:Connect(function()
        Runtime.muteAllActive = not Runtime.muteAllActive
        for _, plr in ipairs(Services.Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                Funcs.setPlayerMuted(plr, Runtime.muteAllActive)
            end
        end
        Funcs.updateMuteVisuals()
    end)

    function Funcs.updatePlayersSubTabVisuals()
        local isServer = (Runtime.playersSubView == "Server")
        SubServerBtn.BackgroundColor3 = isServer and THEME.Accent or THEME.BgCard
        SubServerBtn.TextColor3 = isServer and THEME.BgMain or THEME.TextMuted
        subServerStroke.Transparency = isServer and 0.1 or 0.7

        SubFriendsBtn.BackgroundColor3 = (not isServer) and THEME.Accent or THEME.BgCard
        SubFriendsBtn.TextColor3 = (not isServer) and THEME.BgMain or THEME.TextMuted
        subFriendsStroke.Transparency = (not isServer) and 0.1 or 0.7

        SpectateBar.Visible = isServer
        MuteAllBtn.Visible = isServer
        PlayerListContainer.Visible = isServer
        RefreshFriendsBtn.Visible = not isServer
        FriendsListContainer.Visible = not isServer
        searchBox.PlaceholderText = isServer and "🔍 Buscar jugador en sala..." or "🔍 Buscar amigo conectado..."
    end

    function Funcs.updateSpectateVisuals()
        SelfSpecBtn.BackgroundColor3 = Runtime.spectatingPlayer and THEME.BgCardOn or THEME.BgCard
        SelfSpecBtn.TextColor3 = Runtime.spectatingPlayer and THEME.AccentGreen or THEME.TextMuted
        selfSpecStroke.Color = Runtime.spectatingPlayer and THEME.AccentGreen or THEME.Accent

        for plr, data in pairs(Modules.playerCards) do
            local isSpec = (Runtime.spectatingPlayer == plr)
            data.ViewBtn.BackgroundColor3 = isSpec and THEME.AccentGreen or THEME.SwitchOff
            data.Row.BackgroundColor3 = isSpec and THEME.BgCardOn or THEME.BgCard
            data.Stroke.Color = isSpec and THEME.AccentGreen or (data.IsFriend and Color3.fromRGB(255, 215, 0) or THEME.Accent)
            data.Stroke.Transparency = isSpec and 0.2 or 0.78
        end
    end

    function Funcs.resetSpectate()
        Runtime.spectatingPlayer = nil
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
        Funcs.updateSpectateVisuals()
    end

    function Funcs.spectatePlayer(targetPlayer)
        if not targetPlayer or Runtime.spectatingPlayer == targetPlayer then
            Funcs.resetSpectate()
            return
        end
        Runtime.spectatingPlayer = targetPlayer
        local hum = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then Camera.CameraSubject = hum end
        Funcs.updateSpectateVisuals()
    end

    local function cycleSpectate(step)
        local list = {}
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p ~= LocalPlayer and Modules.playerCards[p] and Modules.playerCards[p].Row.Visible then
                table.insert(list, p)
            end
        end
        if #list == 0 then return end
        table.sort(list, function(a, b)
            return Modules.playerCards[a].Row.LayoutOrder < Modules.playerCards[b].Row.LayoutOrder
        end)

        local idx = 1
        for i, p in ipairs(list) do
            if p == Runtime.spectatingPlayer then
                idx = ((i - 1 + step) % #list) + 1
                break
            end
        end
        Funcs.spectatePlayer(list[idx])
    end

    SelfSpecBtn.MouseButton1Click:Connect(Funcs.resetSpectate)
    PrevSpecBtn.MouseButton1Click:Connect(function() cycleSpectate(-1) end)
    NextSpecBtn.MouseButton1Click:Connect(function() cycleSpectate(1) end)

    registerThemeCallback(function(t)
        searchBox.BackgroundColor3 = t.BgCard
        searchBox.PlaceholderColor3 = t.TextMuted
        searchBox.TextColor3 = t.TextMain
        searchStroke.Color = t.Accent

        subServerStroke.Color = t.Accent
        subFriendsStroke.Color = t.Accent
        Funcs.updatePlayersSubTabVisuals()
        Funcs.updateMuteVisuals()

        RefreshFriendsBtn.BackgroundColor3 = t.BgCard
        RefreshFriendsBtn.TextColor3 = t.Accent
        refreshFriendsStroke.Color = t.Accent

        for _, pair in ipairs({{PrevSpecBtn, prevSpecStroke}, {NextSpecBtn, nextSpecStroke}}) do
            pair[1].BackgroundColor3 = t.BgCard
            pair[1].TextColor3 = t.Accent
            pair[2].Color = t.Accent
        end
        Funcs.updateSpectateVisuals()
    end)

    local function applyPlayerFilter()
        local q = string.lower(Runtime.filterQuery)
        for plr, data in pairs(Modules.playerCards) do
            local match = (q == "")
                or string.find(string.lower(plr.DisplayName), q, 1, true)
                or string.find(string.lower(plr.Name), q, 1, true)
            data.Row.Visible = match ~= nil
        end
        for _, data in ipairs(Modules.friendCards) do
            local match = (q == "")
                or string.find(string.lower(data.DisplayName), q, 1, true)
                or string.find(string.lower(data.UserName), q, 1, true)
                or string.find(string.lower(data.Location), q, 1, true)
            data.Row.Visible = match ~= nil
        end
    end

    local function fetchPresenceMap(userIds)
        local map = {}
        if #userIds == 0 then return map end
        pcall(function()
            local reqFn = (syn and syn.request) or http_request or request or (http and http.request)
            if not reqFn then return end
            local res = reqFn({
                Url = "https://presence.roblox.com/v1/presence/users",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = Services.HttpService:JSONEncode({ userIds = userIds })
            })
            if res and res.Body then
                local decoded = Services.HttpService:JSONDecode(res.Body)
                if decoded and type(decoded.userPresences) == "table" then
                    for _, item in ipairs(decoded.userPresences) do
                        map[tonumber(item.userId)] = item
                    end
                end
            end
        end)
        return map
    end

    local function joinExperienceOrServer(btn, origLabel, placeId, gameId)
        if Runtime.isHopping then return end
        Runtime.isHopping = true
        Runtime.activeTpBtn = btn
        Runtime.activeTpOrigText = origLabel
        btn.Text = "⏳..."

        if placeId == game.PlaceId then
            task.delay(4.5, function()
                if Runtime.isHopping and Runtime.activeTpBtn == btn then
                    Runtime.isHopping = false
                    Runtime.activeTpBtn = nil
                    if btn and btn.Parent then
                        btn.Text = "⚠️ Falló"
                        task.delay(1.2, function()
                            if btn and btn.Parent then btn.Text = origLabel end
                        end)
                    end
                end
            end)

            local tpOk = pcall(function()
                if gameId and gameId ~= "" then
                    Services.TeleportService:TeleportToPlaceInstance(placeId, gameId, LocalPlayer)
                else
                    Services.TeleportService:Teleport(placeId, LocalPlayer)
                end
            end)
            if not tpOk then
                Runtime.isHopping = false
                Runtime.activeTpBtn = nil
                btn.Text = "Error"
                task.delay(1.2, function()
                    if btn and btn.Parent then btn.Text = origLabel end
                end)
            end
            return
        end

        local deepLink = (gameId and gameId ~= "")
            and string.format("roblox://experiences/start?placeId=%d&gameInstanceId=%s", placeId, gameId)
            or string.format("roblox://experiences/start?placeId=%d", placeId)

        local opened = pcall(function()
            game:GetService("LinkingService"):OpenUrl(deepLink)
        end)
        if not opened then
            opened = pcall(function()
                game:GetService("GuiService"):OpenBrowserWindow(deepLink)
            end)
        end

        if opened then
            btn.Text = "✅ Abriendo"
            task.delay(2.5, function()
                Runtime.isHopping = false
                Runtime.activeTpBtn = nil
                if btn and btn.Parent then btn.Text = origLabel end
            end)
        else
            local webUrl = string.format("https://www.roblox.com/games/%d", placeId)
            pcall(function() if setclipboard then setclipboard(webUrl) end end)
            pcall(function()
                if gameId and gameId ~= "" then
                    Services.TeleportService:TeleportToPlaceInstance(placeId, gameId, LocalPlayer)
                else
                    Services.TeleportService:Teleport(placeId, LocalPlayer)
                end
            end)
            btn.Text = "📋 Link"
            task.delay(2.0, function()
                Runtime.isHopping = false
                Runtime.activeTpBtn = nil
                if btn and btn.Parent then btn.Text = origLabel end
            end)
        end
    end

    local function refreshOnlineFriends()
        if Runtime.isRefreshingFriends then return end
        Runtime.isRefreshingFriends = true
        RefreshFriendsBtn.Text = "⏳ Cargando amigos..."

        task.spawn(function()
            for _, child in ipairs(FriendsListContainer:GetChildren()) do
                if child:IsA("GuiObject") then child:Destroy() end
            end
            table.clear(Modules.friendCards)

            local ok, onlineList = pcall(function()
                return LocalPlayer:GetFriendsOnline(200)
            end)

            if ok and type(onlineList) == "table" and #onlineList > 0 then
                local ids = {}
                for _, f in ipairs(onlineList) do
                    local uid = tonumber(f.VisitorId)
                    if uid and uid > 0 then table.insert(ids, uid) end
                end
                local presenceMap = fetchPresenceMap(ids)

                for _, f in ipairs(onlineList) do
                    local uid = tonumber(f.VisitorId) or 0
                    local pInfo = presenceMap[uid]
                    if pInfo then
                        if (not f.PlaceId or tonumber(f.PlaceId) == 0) and tonumber(pInfo.placeId) and tonumber(pInfo.placeId) > 0 then
                            f.PlaceId = tonumber(pInfo.placeId)
                        end
                        if (not f.GameId or f.GameId == "") and pInfo.gameId and pInfo.gameId ~= "" then
                            f.GameId = tostring(pInfo.gameId)
                        end
                        f._presenceType = tonumber(pInfo.userPresenceType) or 0
                        if pInfo.lastLocation and pInfo.lastLocation ~= "" then
                            f.LastLocation = pInfo.lastLocation
                        end
                    else
                        f._presenceType = (tonumber(f.PlaceId) and tonumber(f.PlaceId) > 0) and 2 or 1
                    end
                end

                table.sort(onlineList, function(a, b)
                    local pA = tonumber(a.PlaceId) or 0
                    local pB = tonumber(b.PlaceId) or 0
                    local gA = tostring(a.GameId or "")
                    local gB = tostring(b.GameId or "")
                    local scoreA = (pA > 0 and gA ~= "") and 1 or ((pA > 0) and 2 or ((a._presenceType == 2) and 3 or 4))
                    local scoreB = (pB > 0 and gB ~= "") and 1 or ((pB > 0) and 2 or ((b._presenceType == 2) and 3 or 4))
                    if scoreA ~= scoreB then return scoreA < scoreB end
                    return tostring(a.DisplayName or a.UserName) < tostring(b.DisplayName or b.UserName)
                end)

                for idx, f in ipairs(onlineList) do
                    local userId = tonumber(f.VisitorId) or 0
                    local dName = tostring(f.DisplayName or f.UserName or "Amigo")
                    local uName = tostring(f.UserName or "")
                    local placeId = tonumber(f.PlaceId) or 0
                    local gameId = tostring(f.GameId or "")
                    local inSameServer = (gameId ~= "" and gameId == game.JobId)
                    local canJoinInstance = (placeId > 0 and gameId ~= "" and not inSameServer)
                    local canJoinPlace = (placeId > 0 and not inSameServer)
                    local isPrivateInGame = (placeId == 0 and f._presenceType == 2)

                    local locText = tostring(f.LastLocation or "")
                    if locText == "" or locText == "Website" then
                        if placeId > 0 then locText = "En experiencia"
                        elseif isPrivateInGame then locText = "En juego (Unión privada)"
                        else locText = "En línea (Web/Menú)" end
                    end

                    local row = Instance.new("Frame")
                    Stealth.RandomizeName(row)
                    row.Size = UDim2.new(1, 0, 0, 32)
                    row.BackgroundColor3 = THEME.BgCard
                    row.BackgroundTransparency = 0.28
                    row.LayoutOrder = idx
                    row.Parent = FriendsListContainer
                    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
                    UI.applyNeonStroke(row, canJoinInstance and THEME.AccentGreen or THEME.Accent, 0.72, 1)

                    local thumbImg = Instance.new("ImageLabel")
                    Stealth.RandomizeName(thumbImg)
                    thumbImg.Size = UDim2.new(0, 22, 0, 22)
                    thumbImg.Position = UDim2.new(0, 4, 0.5, -11)
                    thumbImg.BackgroundColor3 = THEME.BgHeader
                    thumbImg.BorderSizePixel = 0
                    thumbImg.Image = ""
                    thumbImg.Parent = row
                    Instance.new("UICorner", thumbImg).CornerRadius = UDim.new(1, 0)

                    if userId > 0 then
                        task.spawn(function()
                            local tOk, url = pcall(function()
                                return Services.Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                            end)
                            if thumbImg and thumbImg.Parent then
                                thumbImg.Image = (tOk and url and url ~= "") and url
                                    or ("https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=150&height=150&format=png")
                            end
                        end)
                    end

                    local nameLbl = Instance.new("TextLabel")
                    Stealth.RandomizeName(nameLbl)
                    nameLbl.Size = UDim2.new(0.46, 0, 0, 14)
                    nameLbl.Position = UDim2.new(0, 30, 0, 3)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.Text = "⭐ " .. dName
                    nameLbl.TextColor3 = Color3.fromRGB(255, 215, 0)
                    nameLbl.Font = Enum.Font.GothamMedium
                    nameLbl.TextSize = 9
                    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    nameLbl.Parent = row

                    local gameLbl = Instance.new("TextLabel")
                    Stealth.RandomizeName(gameLbl)
                    gameLbl.Size = UDim2.new(0.46, 0, 0, 11)
                    gameLbl.Position = UDim2.new(0, 30, 0, 17)
                    gameLbl.BackgroundTransparency = 1
                    gameLbl.Text = inSameServer and "✅ En tu mismo servidor" or ("🎮 " .. locText)
                    gameLbl.TextColor3 = inSameServer and THEME.AccentGreen or THEME.TextMuted
                    gameLbl.Font = Enum.Font.Gotham
                    gameLbl.TextSize = 8
                    gameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                    gameLbl.TextXAlignment = Enum.TextXAlignment.Left
                    gameLbl.Parent = row

                    if canJoinInstance and placeId ~= game.PlaceId then
                        local salaBtn = Instance.new("TextButton")
                        Stealth.RandomizeName(salaBtn)
                        salaBtn.Size = UDim2.new(0, 34, 0, 18)
                        salaBtn.Position = UDim2.new(1, -74, 0.5, -9)
                        salaBtn.BackgroundColor3 = THEME.AccentGreen
                        salaBtn.TextColor3 = THEME.BgMain
                        salaBtn.Text = "SALA"
                        salaBtn.Font = Enum.Font.GothamBold
                        salaBtn.TextSize = 7
                        salaBtn.Parent = row
                        Instance.new("UICorner", salaBtn).CornerRadius = UDim.new(0, 4)
                        salaBtn.MouseButton1Click:Connect(function()
                            joinExperienceOrServer(salaBtn, "SALA", placeId, gameId)
                        end)

                        local juegoBtn = Instance.new("TextButton")
                        Stealth.RandomizeName(juegoBtn)
                        juegoBtn.Size = UDim2.new(0, 34, 0, 18)
                        juegoBtn.Position = UDim2.new(1, -37, 0.5, -9)
                        juegoBtn.BackgroundColor3 = THEME.Accent
                        juegoBtn.TextColor3 = THEME.BgMain
                        juegoBtn.Text = "JUEGO"
                        juegoBtn.Font = Enum.Font.GothamBold
                        juegoBtn.TextSize = 7
                        juegoBtn.Parent = row
                        Instance.new("UICorner", juegoBtn).CornerRadius = UDim.new(0, 4)
                        juegoBtn.MouseButton1Click:Connect(function()
                            joinExperienceOrServer(juegoBtn, "JUEGO", placeId, nil)
                        end)
                    else
                        local joinBtn = Instance.new("TextButton")
                        Stealth.RandomizeName(joinBtn)
                        joinBtn.Size = UDim2.new(0, 52, 0, 18)
                        joinBtn.Position = UDim2.new(1, -56, 0.5, -9)
                        joinBtn.Font = Enum.Font.GothamBold
                        joinBtn.TextSize = 7
                        joinBtn.Parent = row
                        Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 4)

                        if canJoinInstance then
                            joinBtn.BackgroundColor3 = THEME.AccentGreen
                            joinBtn.TextColor3 = THEME.BgMain
                            joinBtn.Text = "UNIRSE"
                            joinBtn.MouseButton1Click:Connect(function()
                                joinExperienceOrServer(joinBtn, "UNIRSE", placeId, gameId)
                            end)
                        elseif canJoinPlace then
                            joinBtn.BackgroundColor3 = THEME.Accent
                            joinBtn.TextColor3 = THEME.BgMain
                            joinBtn.Text = "JUEGO"
                            joinBtn.MouseButton1Click:Connect(function()
                                joinExperienceOrServer(joinBtn, "JUEGO", placeId, nil)
                            end)
                        else
                            joinBtn.BackgroundColor3 = THEME.SwitchOff
                            joinBtn.TextColor3 = isPrivateInGame and THEME.AccentAmber or THEME.TextMuted
                            joinBtn.AutoButtonColor = false
                            joinBtn.Text = inSameServer and "AQUÍ" or (isPrivateInGame and "PRIVADO" or "WEB")
                        end
                    end

                    table.insert(Modules.friendCards, {
                        Row = row, DisplayName = dName, UserName = uName, Location = locText
                    })
                end
            else
                local emptyLbl = Instance.new("TextLabel")
                Stealth.RandomizeName(emptyLbl)
                emptyLbl.Size = UDim2.new(1, 0, 0, 28)
                emptyLbl.BackgroundTransparency = 1
                emptyLbl.Text = "No hay amigos conectados en este momento."
                emptyLbl.TextColor3 = THEME.TextMuted
                emptyLbl.Font = Enum.Font.Gotham
                emptyLbl.TextSize = 9
                emptyLbl.Parent = FriendsListContainer
            end

            applyPlayerFilter()
            RefreshFriendsBtn.Text = "🔄 Actualizar Amigos Conectados"
            Runtime.isRefreshingFriends = false
        end)
    end

    SubServerBtn.MouseButton1Click:Connect(function()
        Runtime.playersSubView = "Server"
        Funcs.updatePlayersSubTabVisuals()
        applyPlayerFilter()
    end)

    SubFriendsBtn.MouseButton1Click:Connect(function()
        Runtime.playersSubView = "Friends"
        Funcs.updatePlayersSubTabVisuals()
        refreshOnlineFriends()
    end)

    RefreshFriendsBtn.MouseButton1Click:Connect(refreshOnlineFriends)

    function Funcs.createPlayerRow(p)
        if p == LocalPlayer or Modules.playerCards[p] then return end

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
        local stroke = UI.applyNeonStroke(row, isFriend and Color3.fromRGB(255, 215, 0) or THEME.Accent, 0.78, 1)

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
                return Services.Players:GetUserThumbnailAsync(p.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            if thumbImg and thumbImg.Parent then
                thumbImg.Image = (ok and url and url ~= "") and url
                    or ("https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=150&height=150&format=png")
            end
        end)

        local nameLbl = Instance.new("TextLabel")
        Stealth.RandomizeName(nameLbl)
        nameLbl.Size = UDim2.new(1, -122, 0, 14)
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
        distLbl.Size = UDim2.new(1, -122, 0, 11)
        distLbl.Position = UDim2.new(0, 30, 0, 16)
        distLbl.BackgroundTransparency = 1
        distLbl.Text = "--- m"
        distLbl.TextColor3 = THEME.TextMuted
        distLbl.Font = Enum.Font.Gotham
        distLbl.TextSize = 8
        distLbl.TextXAlignment = Enum.TextXAlignment.Left
        distLbl.Parent = row

        local isMutedInit = (Modules.mutedPlayers[p.UserId] == true) or Runtime.muteAllActive
        local muteBtn = Instance.new("TextButton")
        Stealth.RandomizeName(muteBtn)
        muteBtn.Size = UDim2.new(0, 22, 0, 18)
        muteBtn.Position = UDim2.new(1, -86, 0.5, -9)
        muteBtn.BackgroundColor3 = isMutedInit and THEME.AccentRed or THEME.SwitchOff
        muteBtn.Text = isMutedInit and "🔇" or "🔊"
        muteBtn.TextColor3 = THEME.TextMain
        muteBtn.Font = Enum.Font.GothamBold
        muteBtn.TextSize = 8
        muteBtn.Parent = row
        Instance.new("UICorner", muteBtn).CornerRadius = UDim.new(0, 4)
        muteBtn.MouseButton1Click:Connect(function()
            Funcs.setPlayerMuted(p, not (Modules.mutedPlayers[p.UserId] == true))
        end)

        local tpBtn = Instance.new("TextButton")
        Stealth.RandomizeName(tpBtn)
        tpBtn.Size = UDim2.new(0, 26, 0, 18)
        tpBtn.Position = UDim2.new(1, -61, 0.5, -9)
        tpBtn.BackgroundColor3 = THEME.Accent
        tpBtn.Text = "TP"
        tpBtn.TextColor3 = THEME.BgMain
        tpBtn.Font = Enum.Font.GothamBold
        tpBtn.TextSize = 8
        tpBtn.Parent = row
        Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)
        tpBtn.MouseButton1Click:Connect(function()
            local tHrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then Funcs.SafeTeleport(tHrp.CFrame + Vector3.new(0, 3.5, 0)) end
        end)

        local viewBtn = Instance.new("TextButton")
        Stealth.RandomizeName(viewBtn)
        viewBtn.Size = UDim2.new(0, 30, 0, 18)
        viewBtn.Position = UDim2.new(1, -32, 0.5, -9)
        viewBtn.BackgroundColor3 = THEME.SwitchOff
        viewBtn.Text = "VIEW"
        viewBtn.TextColor3 = THEME.TextMain
        viewBtn.Font = Enum.Font.GothamBold
        viewBtn.TextSize = 7
        viewBtn.Parent = row
        Instance.new("UICorner", viewBtn).CornerRadius = UDim.new(0, 4)
        viewBtn.MouseButton1Click:Connect(function()
            Funcs.spectatePlayer(p)
        end)

        Modules.playerCards[p] = {
            Row = row, DistLabel = distLbl, MuteBtn = muteBtn,
            ViewBtn = viewBtn, Stroke = stroke, IsFriend = isFriend
        }
        if isMutedInit then Funcs.setPlayerMuted(p, true) end
        applyPlayerFilter()
    end

    for _, p in ipairs(Services.Players:GetPlayers()) do Funcs.createPlayerRow(p) end

    HubMaid:GiveTask(searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Runtime.filterQuery = searchBox.Text
        applyPlayerFilter()
    end))

    task.spawn(function()
        while not Runtime.hubUnloaded do
            if UI.MainFrame.Visible and Runtime.ActiveTabName == "Jug." and Runtime.playersSubView == "Server" then
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                for plr, data in pairs(Modules.playerCards) do
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
end

task.wait()

-- ==========================================
-- ⚙️ PASO 5 DE CARGA: PESTAÑA 4 (AJUSTES, PERFILES Y KEYBINDS)
-- ==========================================
do
    TabConfig:AddSection("Sesión y Rendimiento")

    Controls.antiAfkToggle = TabConfig:AddToggle({
        Icon = "🛡️", Title = "Anti-AFK (Evitar Kick)", Default = Config.AntiAFK ~= false,
        Callback = function(v) Config.AntiAFK = v; saveStore() end
    })

    Controls.fpsBoosterToggle = TabConfig:AddToggle({
        Icon = "⚡", Title = "FPS Booster (Optimizar Gráficos)", Default = Config.FPSBooster == true,
        Callback = Funcs.toggleFPSBooster
    })

    TabConfig:AddButton({ Title = "🔁 Rejoin (Reconectar Servidor)", Callback = Funcs.performRejoin })
    TabConfig:AddButton({ Title = "🔥 Server Hop (Con Gente / Variado)", Callback = function(btn) Funcs.performServerHop(btn, "Desc") end })
    TabConfig:AddButton({ Title = "🌐 Server Hop (Tranquilo / Variado)", Callback = function(btn) Funcs.performServerHop(btn, "Asc") end })

    TabConfig:AddSection("Apariencia y Escala")

    local function applyThemeByName(themeName)
        if not PRESET_THEMES[themeName] then return end
        Config.Theme = themeName
        THEME = PRESET_THEMES[themeName]
        for _, fn in ipairs(ThemeCallbacks) do pcall(fn, THEME) end
        for k, v in pairs(State) do Funcs.syncQuickBtnVisual(k, v) end
        if Funcs.updateSpectateVisuals then Funcs.updateSpectateVisuals() end
        if Funcs.updateMuteVisuals then Funcs.updateMuteVisuals() end
        saveStore()
    end

    Controls.themeBtn = TabConfig:AddButton({
        Title = "🎨 Tema: " .. Config.Theme .. " (Click para cambiar)",
        Callback = function(btn)
            local idx = table.find(THEME_ORDER, Config.Theme) or 1
            local nextTheme = THEME_ORDER[(idx % #THEME_ORDER) + 1]
            applyThemeByName(nextTheme)
            btn.Text = "🎨 Tema: " .. nextTheme .. " (Click para cambiar)"
        end
    })

    Controls.scaleSlider = TabConfig:AddSlider({
        Title = "Escala de Interfaz", Min = 0.75, Max = 1.40, Decimals = 2, Suffix = "x", Default = Config.UiScale,
        OnChange = function(v) Config.UiScale = v; UI.UiScaler.Scale = v end,
        OnRelease = function() saveStore() end
    })

    Controls.glassSlider = TabConfig:AddSlider({
        Title = "Transparencia Cristal", Min = 0.0, Max = 0.55, Decimals = 2, Default = Config.GlassTransparency,
        OnChange = function(v)
            Config.GlassTransparency = v
            UI.MainFrame.BackgroundTransparency = v
            UI.MiniBtn.BackgroundTransparency = v
            UI.Header.BackgroundTransparency = math.clamp(v + 0.03, 0, 0.85)
        end,
        OnRelease = function() saveStore() end
    })

    TabConfig:AddSection("Perfiles JSON")

    local PROFILE_NAMES = {"Default", "PC", "Movil"}

    function Controls.applyAllPositionsFromConfig()
        UI.MainFrame.Position = getSavedUDim2("MainFrame")
        UI.MiniBtn.Position = getSavedUDim2("MiniBtn")
        for qName, qBtn in pairs(QuickButtons) do
            qBtn.Position = getSavedUDim2("Quick_" .. qName)
            if qName == "TPS" and not isTouchDevice then
                qBtn.Visible = false
            else
                qBtn.Visible = Runtime.quickButtonsMaster and (Config.QuickVisible[qName] ~= false)
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
        Controls.themeBtn.Text = "🎨 Tema: " .. Config.Theme .. " (Click para cambiar)"
        UI.UiScaler.Scale = Config.UiScale
        Controls.scaleSlider.Set(Config.UiScale)
        Controls.glassSlider.Set(Config.GlassTransparency)
        Controls.flySlider.Set(Config.FlySpeed)
        Controls.freeCamSlider.Set(Config.FreeCamSpeed)
        Controls.antiAfkToggle.Set(Config.AntiAFK ~= false, true)
        Controls.fpsBoosterToggle.Set(Config.FPSBooster == true, false)
        Controls.espInfoToggle.Set(Config.ESPInfo ~= false, true)
        Controls.espNameToggle.Set(Config.ESPName ~= false, true)
        Controls.espHealthToggle.Set(Config.ESPHealth ~= false, true)
        Controls.espDistToggle.Set(Config.ESPDistance ~= false, true)
        Funcs.refreshESPBillboards()
        Controls.applyAllPositionsFromConfig()
        for _, refreshFn in ipairs(Controls.keybindRefreshers) do refreshFn() end
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
            Controls.applyAllPositionsFromConfig()
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
                Icon = "🔘", Title = item.Label, Default = Config.QuickVisible[item.Key] ~= false,
                Callback = function(val)
                    Config.QuickVisible[item.Key] = val
                    saveStore()
                    if QuickButtons[item.Key] then
                        QuickButtons[item.Key].Visible = val and Runtime.quickButtonsMaster
                    end
                end
            })
        end
    end

    TabConfig:AddSection("Atajos de Teclado (PC) — ✕ para quitar")
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
            table.insert(Controls.keybindRefreshers, created.Refresh)
        end
    end

    TabConfig:AddSection("Sistema")
    TabConfig:AddButton({
        Title = "🛑 Cerrar y Limpiar Hub (Unload)",
        Danger = true,
        Callback = unloadHub
    })
end

task.wait()

-- ==========================================
-- 🖱️ PASO 6 DE CARGA: BOTONES RÁPIDOS Y EVENTOS GLOBALES
-- ==========================================
do
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
        HubMaid:GiveTask(Services.UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                local vp = Camera.ViewportSize
                local newX = math.clamp(startPos.X.Offset + delta.X, 0, math.max(0, vp.X - targetFrame.AbsoluteSize.X))
                local newY = math.clamp(startPos.Y.Offset + delta.Y, 0, math.max(0, vp.Y - targetFrame.AbsoluteSize.Y))
                targetFrame.Position = UDim2.new(0, newX, 0, newY)
            end
        end))
    end

    makeDraggable(UI.Header, UI.MainFrame, "MainFrame")
    makeDraggable(UI.MiniBtn, UI.MiniBtn, "MiniBtn")

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
        btn.Parent = UI.ScreenGui
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
        local stroke = UI.applyNeonStroke(btn, isActionBtn and THEME.AccentRed or THEME.Accent, 0.4, 1.3)

        QuickButtons[name] = btn
        QuickButtonStrokes[name] = stroke

        registerThemeCallback(function(t)
            if isActionBtn then
                btn.BackgroundColor3 = t.BgMain
                btn.TextColor3 = t.AccentRed
                stroke.Color = t.AccentRed
            else
                Funcs.syncQuickBtnVisual(name, State[name] or false)
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
        createQuickBtn("TPS", "TPS", function() Funcs.setFeatureState("TPS", not State.TPS) end)
    end
    createQuickBtn("Invisicam",       "INV", function() Funcs.setFeatureState("Invisicam",       not State.Invisicam) end)
    createQuickBtn("FPXRay",          "XRY", function() Funcs.setFeatureState("FPXRay",          not State.FPXRay) end)
    createQuickBtn("ESP",             "ESP", function() Funcs.setFeatureState("ESP",             not State.ESP) end)
    createQuickBtn("InstantInteract", "INT", function() Funcs.setFeatureState("InstantInteract", not State.InstantInteract) end)
    createQuickBtn("DeleteMode",      "DEL", function() Funcs.setFeatureState("DeleteMode",      not State.DeleteMode) end)
    createQuickBtn("Noclip",          "NOC", function() Funcs.setFeatureState("Noclip",          not State.Noclip) end)
    createQuickBtn("InfJump",         "JMP", function() Funcs.setFeatureState("InfJump",         not State.InfJump) end)
    createQuickBtn("Fly",             "FLY", function() Funcs.setFeatureState("Fly",             not State.Fly) end)
    createQuickBtn("FreeCam",         "CAM", function() Funcs.setFeatureState("FreeCam",         not State.FreeCam) end)
    createQuickBtn("Fullbright",      "LGT", function() Funcs.setFeatureState("Fullbright",      not State.Fullbright) end)
    createQuickBtn("ThirdPerson",     "3PS", function() Funcs.setFeatureState("ThirdPerson",     not State.ThirdPerson) end)
    createQuickBtn("Restore",         "RST", function(btn, stroke)
        Funcs.RestoreMap()
        btn.TextColor3 = THEME.AccentGreen
        stroke.Color = THEME.AccentGreen
        task.wait(0.3)
        btn.TextColor3 = THEME.AccentRed
        stroke.Color = THEME.AccentRed
    end, true)

    UI.MasterQuickBtn.MouseButton1Click:Connect(function()
        Runtime.quickButtonsMaster = not Runtime.quickButtonsMaster
        UI.MasterQuickBtn.BackgroundColor3 = Runtime.quickButtonsMaster and THEME.AccentGreen or THEME.SwitchOff
        UI.masterQuickStroke.Color = Runtime.quickButtonsMaster and THEME.AccentGreen or THEME.Accent
        for name, btn in pairs(QuickButtons) do
            if name == "TPS" and not isTouchDevice then
                btn.Visible = false
            else
                btn.Visible = Runtime.quickButtonsMaster and (Config.QuickVisible[name] ~= false)
            end
        end
    end)

    UI.MinimizeBtn.MouseButton1Click:Connect(function()
        UI.MainFrame.Visible = false
        UI.MiniBtn.Visible = true
    end)
    UI.MiniBtn.Activated:Connect(function()
        if not Runtime.isReady then return end
        UI.MainFrame.Visible = true
        UI.MiniBtn.Visible = false
    end)

    -- Raycast e Inputs
    local function raycastIgnoringDeleted(origin, direction)
        local filter = {LocalPlayer.Character, Camera}
        for _, p in ipairs(Services.Players:GetPlayers()) do
            if p.Character then table.insert(filter, p.Character) end
        end
        for _, data in ipairs(Modules.deletedPartsMemory) do
            if data.part and data.part.Parent then table.insert(filter, data.part) end
        end
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = filter
        params.FilterType = Enum.RaycastFilterType.Exclude
        return Services.Workspace:Raycast(origin, direction, params)
    end

    local function DeletePartAt(screenPos)
        local ray = Camera:ScreenPointToRay(screenPos.X, screenPos.Y)
        local result = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
        local part = result and result.Instance
        if part and part:IsA("BasePart") and not part:FindFirstAncestorOfClass("Accessory") then
            table.insert(Modules.deletedPartsMemory, {part = part, trans = part.Transparency, collide = part.CanCollide})
            part.Transparency = 1
            part.CanCollide = false
        end
    end

    local function TeleportAt(screenPos)
        local ray = Camera:ScreenPointToRay(screenPos.X, screenPos.Y)
        local result = raycastIgnoringDeleted(ray.Origin, ray.Direction * 1000)
        if result then
            Funcs.SafeTeleport(CFrame.new(result.Position + Vector3.new(0, 3.5, 0)))
        end
    end

    HubMaid:GiveTask(Services.UserInputService.JumpRequest:Connect(function()
        if State.InfJump then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))

    local function isKeyMatch(codeName, bindName)
        return bindName and bindName ~= "" and bindName ~= "None" and codeName == bindName
    end

    HubMaid:GiveTask(Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp or Runtime.listeningFor or Runtime.hubUnloaded then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local codeName = input.KeyCode.Name
            local kb = Config.Keybinds
            if isKeyMatch(codeName, kb.Invisicam)  then Funcs.setFeatureState("Invisicam",  not State.Invisicam) end
            if isKeyMatch(codeName, kb.Noclip)     then Funcs.setFeatureState("Noclip",     not State.Noclip) end
            if isKeyMatch(codeName, kb.Fly)        then Funcs.setFeatureState("Fly",        not State.Fly) end
            if isKeyMatch(codeName, kb.FreeCam)    then Funcs.setFeatureState("FreeCam",    not State.FreeCam) end
            if isKeyMatch(codeName, kb.Fullbright) then Funcs.setFeatureState("Fullbright", not State.Fullbright) end
            if isKeyMatch(codeName, kb.XRay)       then Funcs.setFeatureState("FPXRay",     not State.FPXRay) end
            if isKeyMatch(codeName, kb.ESP)        then Funcs.setFeatureState("ESP",        not State.ESP) end
            if isKeyMatch(codeName, kb.InfJump)    then Funcs.setFeatureState("InfJump",    not State.InfJump) end
            if isKeyMatch(codeName, kb.Restore)    then Funcs.RestoreMap() end
            if isKeyMatch(codeName, kb.Teleport)   then TeleportAt(Vector2.new(Mouse.X, Mouse.Y)) end
            if isKeyMatch(codeName, kb.Delete)     then DeletePartAt(Vector2.new(Mouse.X, Mouse.Y)) end
        end
    end))

    local function isOverGui(pos)
        if not UI.ScreenGui or not UI.ScreenGui.Parent then return false end
        for _, obj in ipairs(LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)) do
            if obj:IsDescendantOf(UI.ScreenGui) then return true end
        end
        return false
    end

    local touchState = { active = false, startTime = 0, totalMoved = 0, isCameraDrag = false }
    HubMaid:GiveTask(Services.UserInputService.InputBegan:Connect(function(input, gp)
        if gp or Runtime.hubUnloaded then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            touchState.active = true
            touchState.startTime = os.clock()
            touchState.totalMoved = 0
            touchState.isCameraDrag = false
        end
    end))

    HubMaid:GiveTask(Services.UserInputService.InputChanged:Connect(function(input, gp)
        if gp or Runtime.hubUnloaded then return end
        if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
            touchState.totalMoved += input.Delta.Magnitude
            if touchState.totalMoved > 10 then touchState.isCameraDrag = true end
        end
    end))

    HubMaid:GiveTask(Services.UserInputService.InputEnded:Connect(function(input, gp)
        if gp or Runtime.hubUnloaded then return end
        if input.UserInputType == Enum.UserInputType.Touch and touchState.active then
            touchState.active = false
            if (os.clock() - touchState.startTime) < 0.3 and not touchState.isCameraDrag and not isOverGui(input.Position) then
                if State.DeleteMode then DeletePartAt(input.Position)
                elseif State.TPS then TeleportAt(input.Position) end
            end
        end
    end))

    HubMaid:GiveTask(Services.Players.PlayerAdded:Connect(function(plr)
        Funcs.setupPlayerESP(plr)
        Funcs.createPlayerRow(plr)
        Funcs.rebuildXRayFilter()
    end))

    HubMaid:GiveTask(Services.Players.PlayerRemoving:Connect(function(plr)
        if Runtime.spectatingPlayer == plr then Funcs.resetSpectate() end
        if Modules.espCharConns[plr] then Stealth.Disconnect(Modules.espCharConns[plr]); Modules.espCharConns[plr] = nil end
        if Modules.muteCharConns[plr] then Stealth.Disconnect(Modules.muteCharConns[plr]); Modules.muteCharConns[plr] = nil end
        if Modules.espHighlights[plr] then Modules.espHighlights[plr]:Destroy(); Modules.espHighlights[plr] = nil end
        if Modules.espBillboards[plr] then
            if Modules.espBillboards[plr].Gui then Modules.espBillboards[plr].Gui:Destroy() end
            Modules.espBillboards[plr] = nil
        end
        if Modules.playerCards[plr] then
            Modules.playerCards[plr].Row:Destroy()
            Modules.playerCards[plr] = nil
        end
        Funcs.rebuildXRayFilter()
    end))

    HubMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        Funcs.cacheCharacterParts(char)
        Funcs.rebuildXRayFilter()
        if State.Noclip      then Funcs.toggleNoclip(true) end
        if State.Invisicam   then Funcs.toggleInvisicam(true) end
        if State.FPXRay      then Funcs.toggleFPXRay(true) end
        if State.Fullbright  then Funcs.toggleFullbright(true) end
        if State.ThirdPerson then Funcs.toggleThirdPerson(true) end
        if State.Fly         then Funcs.toggleFly(true) end
    end))
end

-- ==========================================
-- ✅ FINALIZACIÓN SEGURA DE ARRANQUE
-- ==========================================
if Config.FPSBooster then
    Funcs.toggleFPSBooster(true)
end

UI.selectTab("Mov.")
Runtime.isReady = true
UI.MiniBtn.Text = "xcs"
UI.MiniBtn.TextColor3 = THEME.Accent
UI.miniStroke.Color = THEME.Accent
