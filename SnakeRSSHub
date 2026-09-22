--[[ ============================================================================
    SNAKEHUB V3 LITE  |  REALISTIC STREET SOCCER (Roblox)
    ----------------------------------------------------------------------------
    VERSAO CORRIGIDA + ULTRA LEVE para celular fraco (ex: Itel A70)
    - Motor reescrito: sensores por EVENTO (sem varredura pesada), tick leve
    - Metodo duplo: TECLAS REAIS simuladas (VIM) + remotes com AUTO-CALIBRACAO
    - Anti-lag: modo ULTRA, modo Batata, Mini UI nativa, FPS adaptativo
    - Diagnostico na tela: bola, remotes, VIM, FPS (voce ve o que funciona)
    ----------------------------------------------------------------------------
    Interface Rayfield com 10 ABAS (Mobile + PC, todos os executors)
    Se o Rayfield falhar ou o celular for fraco: MINI UI automatica.
    ----------------------------------------------------------------------------
    COMO USAR:
    1) Entre no jogo, execute este script no executor
    2) Aperte DIAGNOSTICO (aba Inicio) para ver o status
    3) Fique com a bola no pe e aperte CALIBRAR CHUTE (1 vez)
    4) Ative TOP 1 GLOBAL e jogue. No lag? Aba Ajustes > ANTI-LAG ULTRA
    5) Botao semitransparente AUTO SHOOT aparece sozinho na tela
    6) Aba Inicio > MAPEAR EXPLORER gera a estrutura real do jogo
    ----------------------------------------------------------------------------
    AVISO: use por sua conta e risco. Exploits podem gerar punicao no jogo.
============================================================================= ]]

--[[ ============================ ANTI-DUPLICACAO =========================== ]]
local ENV = nil
pcall(function()
    if typeof(getgenv) == "function" then
        ENV = getgenv()
    end
end)
if ENV == nil then
    ENV = _G
end

if ENV.__SNAKEHUB_V3_ENGINE == true then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "SnakeHub V3",
            Text = "Motor ja esta rodando!",
            Duration = 3
        })
    end)
    return
end
ENV.__SNAKEHUB_V3_ENGINE = true

--[[ ============================ SERVICOS BASE ============================= ]]
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local IS_MOBILE = false
pcall(function()
    IS_MOBILE = UserInputService.TouchEnabled and (not UserInputService.KeyboardEnabled)
end)

-- VirtualInputManager = aperta teclas/clicks REAIS (o jogo obedece 100%)
local VIM = nil
local VIM_OK = false
pcall(function()
    VIM = game:GetService("VirtualInputManager")
    -- teste inofensivo: solta uma tecla que ninguem usa
    VIM:SendKeyEvent(false, Enum.KeyCode.F24, false, game)
    VIM_OK = true
end)

--[[ ============================ CONFIGURACOES ============================= ]]
local Config = {
    NotifyUI = true,
    UIKey = "RightShift",
    FloatUI = true,
    FloatShoot = true,
    FloatAutoShoot = true, -- botao exclusivo semitransparente (aparece sozinho)

    -- Metodos de disparo (o segredo da V3)
    VimKeys = true,        -- usa teclas reais (Q/E/X/F) - mais confiavel
    DoubleFire = true,     -- dispara tecla + remote juntos (maximo efeito)
    ShootMethod = "Auto",  -- Auto | Remote | Tecla Real (VIM)
    ShootSig = 1,          -- assinatura calibrada do chute
    ShootRemoteAlt = false,-- usar ShootTheBaII em vez do principal
    Calibrated = false,

    -- Auto Shoot
    AutoShoot = false,
    ShootDist = 260,
    Power = 100,
    Accuracy = 99,
    RandomCurve = true,
    CurveShoot = true,
    CurveIntensity = 0.7,
    TargetArea = "Aleatorio PRO",
    AimLock = true,
    ShootKeyEnabled = true,
    ShootKey = "G",
    AutoPowerShot = false,

    -- Auto Drible / Tackle
    AutoDribble = false,
    DribbleDist = 5.5,
    DribbleStyle = "Perfeito PRO",
    BodyShield = true,
    DribbleCD = 0.7,
    AutoTackle = false,
    TackleDist = 6.0,
    LegitTackle = true,
    InterceptPro = true,

    -- Actions
    AutoBicycle = false,
    AutoHeader = false,
    AutoVolley = false,
    AutoChip = false,
    HeaderShoot = true,

    -- GK
    AutoDive = false,
    AutoDefense = false,
    AutoPassGK = false,
    AutoPunch = false,
    GKRange = 40,
    GKMode = "Automatico",
    CompatMode = true,

    -- Top Global
    TopGlobal = false,
    TopStyle = "Completo",
    SteerAssist = 65,
    ProMovement = true,
    FullAuto = false,
    ZeroDelay = true,
    MoveMirror = true,

    -- Partida
    AutoFaceoff = false,
    AutoPenalty = false,
    InfiniteStamina = false,
    NoShake = false,
    SkipCutscene = false,
    AntiAFK = true,
    AutoCollect = false,
    WalkEnabled = false,
    WalkSpeed = 22,
    StreamerMode = false,

    -- ESP
    BallESP = false,
    GoalESP = false,
    PlayerESP = false,

    -- Performance / Anti-lag
    CombatHz = 12,       -- tick do motor (12x por segundo = leve e rapido)
    AdaptiveHz = true,   -- reduz sozinho se o FPS cair
    LiteMode = true,     -- sensores leves sempre ligados
}

local Running = true
local ErrorCount = 0
local Cooldown = {
    Shoot = 0, Dribble = 0, Tackle = 0, Dive = 0, Punch = 0,
    Bicycle = 0, Header = 0, Volley = 0, Chip = 0, Pass = 0,
    PowerShot = 0, Faceoff = 0, Penalty = 0,
}
local Connections = {}
local function track(conn)
    table.insert(Connections, conn)
    return conn
end

local Rayfield = nil
local function notify(title, content, dur)
    if not Config.NotifyUI then
        return
    end
    if Rayfield then
        pcall(function()
            Rayfield:Notify({ Title = title, Content = content, Duration = dur or 3 })
        end)
    else
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = title, Text = content, Duration = dur or 3
            })
        end)
    end
end

--[[ ============================ AJUDANTES GERAIS ========================== ]]
local function SafeFind(parent, name)
    if not parent then
        return nil
    end
    local ok, res = pcall(function()
        return parent:FindFirstChild(name, true)
    end)
    if ok then
        return res
    end
    return nil
end

local function fire(remote, ...)
    if remote == nil then
        return false
    end
    local args = { ... }
    local ok = pcall(function()
        remote:FireServer(unpack(args))
    end)
    return ok
end

local function invoke(remoteFunc, ...)
    if remoteFunc == nil then
        return false, nil
    end
    local args = { ... }
    local ok, res = pcall(function()
        return remoteFunc:InvokeServer(unpack(args))
    end)
    return ok, res
end

local function normOpt(opt, fallback)
    if type(opt) == "table" then
        if opt[1] ~= nil then
            return opt[1]
        else
            return fallback
        end
    end
    if opt == nil then
        return fallback
    end
    return opt
end

local function getGuiParent()
    local ok, h = pcall(function()
        if typeof(gethui) == "function" then
            return gethui()
        end
        return nil
    end)
    if ok and h ~= nil then
        return h
    end
    return game:GetService("CoreGui")
end

-- Aperta uma tecla REAL do jogo (Q/E/X/F/Espaco) - funciona em PC e mobile
local function pressKey(keycode, holdTime)
    if not VIM_OK then
        return false
    end
    -- nao aperta tecla enquanto digita no chat
    local focused = false
    pcall(function()
        focused = UserInputService:GetFocusedTextBox() ~= nil
    end)
    if focused then
        return false
    end
    local ok = pcall(function()
        VIM:SendKeyEvent(true, keycode, false, game)
    end)
    if not ok then
        return false
    end
    task.delay(holdTime or 0.12, function()
        pcall(function()
            VIM:SendKeyEvent(false, keycode, false, game)
        end)
    end)
    return true
end

-- Click REAL do mouse numa posicao da tela (x, y em pixels)
local function clickAt(x, y, button, holdTime)
    if not VIM_OK then
        return false
    end
    button = button or 0
    local ok = pcall(function()
        -- tenta mover o cursor ate o alvo (mira real do jogo)
        pcall(function()
            VIM:SendMouseMoveEvent(x, y, game)
        end)
        VIM:SendMouseButtonEvent(x, y, button, true, game, 0)
    end)
    if not ok then
        return false
    end
    task.delay(holdTime or 0.15, function()
        pcall(function()
            VIM:SendMouseButtonEvent(x, y, button, false, game, 0)
        end)
    end)
    return true
end

--[[ ============================ MAPA DE REMOTES =========================== ]]
local Remotes = {
    Shoot      = SafeFind(ReplicatedStorage, "ShootTheBall"),
    ShootAlt   = SafeFind(ReplicatedStorage, "ShootTheBaII"),
    Pass       = SafeFind(ReplicatedStorage, "Pass"),
    Tackle     = SafeFind(ReplicatedStorage, "Tackle"),
    Action     = SafeFind(ReplicatedStorage, "Action"),
    Curve      = SafeFind(ReplicatedStorage, "cfactor"),
    GKHitbox   = SafeFind(ReplicatedStorage, "GKHitbox"),
    Faceoff    = SafeFind(ReplicatedStorage, "Faceoff"),
    Penalty    = SafeFind(ReplicatedStorage, "Penalty"),
    Position   = SafeFind(ReplicatedStorage, "Position"),
    TeamChange = SafeFind(ReplicatedStorage, "TeamChange"),
    TeleportR  = SafeFind(ReplicatedStorage, "Teleport"),
    SettingsR  = SafeFind(ReplicatedStorage, "Settings"),
    Avatar     = SafeFind(ReplicatedStorage, "Avatar"),
    Jersey     = SafeFind(ReplicatedStorage, "Jersey"),
    Equip      = SafeFind(ReplicatedStorage, "Equip"),
    Unbox      = SafeFind(ReplicatedStorage, "Unbox"),
    ClaimStick = SafeFind(ReplicatedStorage, "ClaimStick"),
    Collect    = SafeFind(ReplicatedStorage, "Collect"),
    TCellLoc   = SafeFind(ReplicatedStorage, "tcelloc"),
    Daily      = SafeFind(ReplicatedStorage, "ClaimReward"),
    DailyEv    = SafeFind(ReplicatedStorage, "DailyReward"),
    WQuest     = SafeFind(ReplicatedStorage, "WQuest"),
    RedeemCode = SafeFind(ReplicatedStorage, "RedeemCode"),
    Cutscene   = SafeFind(ReplicatedStorage, "CutsceneRemote"),
    PodiumCam  = SafeFind(ReplicatedStorage, "PodiumCamera"),
    PodiumCel  = SafeFind(ReplicatedStorage, "PodiumCelebration"),
    Shake      = SafeFind(ReplicatedStorage, "Shake"),
    FPSNORE    = SafeFind(ReplicatedStorage, "FPSNORE"),
    PINGNORE   = SafeFind(ReplicatedStorage, "PINGNORE"),
    AFK        = SafeFind(ReplicatedStorage, "AFKRemote"),
    Purchase   = SafeFind(ReplicatedStorage, "Purchase"),
    ShopEvent  = SafeFind(ReplicatedStorage, "ShopEvent"),
    ShopReset  = SafeFind(ReplicatedStorage, "ResetShop"),
    SoftDis    = SafeFind(ReplicatedStorage, "SoftDisPlayer"),
    IsMobile   = SafeFind(ReplicatedStorage, "isMobile"),
    NotifyR    = SafeFind(ReplicatedStorage, "notify"),
    WorldCup   = SafeFind(ReplicatedStorage, "GetWorldCupClaims"),
    RedeemWC   = SafeFind(ReplicatedStorage, "RedeemWorldCupCard"),
    SelectWC   = SafeFind(ReplicatedStorage, "SelectWorldCupCard"),
    SpinCards  = SafeFind(ReplicatedStorage, "SpinnerContentsCards"),
    SpinDrib   = SafeFind(ReplicatedStorage, "SpinnerContentsDribble"),
    SpinGoalie = SafeFind(ReplicatedStorage, "SpinnerContentsGoalie"),
    SpinShoes  = SafeFind(ReplicatedStorage, "SpinnerContentsShoes"),
    SpeedRemote = nil,
}
local RemoteCount = 0
for _, r in pairs(Remotes) do
    if r ~= nil then
        RemoteCount = RemoteCount + 1
    end
end

task.spawn(function()
    local ok, pgui = pcall(function()
        return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 6)
    end)
    if ok and pgui then
        Remotes.SpeedRemote = SafeFind(pgui, "Speed")
    end
end)

--[[ ============ SENSORES LEVES (EVENTO, SEM VARREDURA PESADA) ============= ]]
-- A V3 rastreia a bola por EVENTO: 1 varredura no inicio + ouvintes.
-- Nunca mais GetDescendants() repetido = zero travamento por causa disso.

local BallPart = nil
local ManualBallLock = nil
local GoalsList = {}
local LastFullRescan = 0

local function ballNameScore(name)
    local n = string.lower(name)
    if n == "ball" or n == "football" then
        return 100
    end
    if string.find(n, "football", 1, true) then
        return 90
    end
    if string.find(n, "soccer", 1, true) then
        return 85
    end
    if string.find(n, "match ball", 1, true) or string.find(n, "matchball", 1, true) then
        return 80
    end
    if n == "bola" or n == "futebol" then
        return 75
    end
    if string.find(n, "ball", 1, true) and not string.find(n, "spawn", 1, true) then
        return 60
    end
    return 0
end

local function considerBall(d)
    if not d or not d.Parent then
        return
    end
    if not d:IsA("BasePart") then
        -- bola pode ser um Modelo
        if d:IsA("Model") and ballNameScore(d.Name) >= 60 then
            local pp = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)
            if pp and (not BallPart or not BallPart.Parent) then
                BallPart = pp
            end
        end
        return
    end
    -- ignora partes do corpo dos jogadores
    if d.Parent and d.Parent:FindFirstChildOfClass("Humanoid") then
        return
    end
    local score = ballNameScore(d.Name)
    if score >= 60 and (not BallPart or not BallPart.Parent) then
        BallPart = d
    end
end

-- OUVINTES: mantem a bola rastreada sem varredura (custo ~zero)
track(workspace.DescendantAdded:Connect(function(d)
    if Running then
        considerBall(d)
    end
end))
track(workspace.DescendantRemoving:Connect(function(d)
    if d == BallPart then
        BallPart = nil
    end
end))

local function goalNameHit(name)
    local n = string.lower(name)
    return string.find(n, "goal", 1, true) or string.find(n, "trave", 1, true)
        or string.find(n, "crossbar", 1, true) or string.find(n, "goalpost", 1, true)
end

-- UNICA varredura completa: 1x no inicio (+ botao manual). Leve e rapido.
local function initialScan()
    local ok, desc = pcall(function()
        return workspace:GetDescendants()
    end)
    if not ok then
        return
    end
    local best, bestScore = nil, 0
    for _, d in ipairs(desc) do
        if d:IsA("BasePart") then
            local s = ballNameScore(d.Name)
            if s > bestScore then
                local skip = d.Parent and d.Parent:FindFirstChildOfClass("Humanoid")
                if not skip then
                    bestScore = s
                    best = d
                end
            end
            if goalNameHit(d.Name) and #GoalsList < 24 then
                table.insert(GoalsList, d)
            end
        elseif d:IsA("Model") and ballNameScore(d.Name) >= 60 and not best then
            local pp = d.PrimaryPart or d:FindFirstChildWhichIsA("BasePart", true)
            if pp then
                best = pp
                bestScore = 60
            end
        end
    end
    if best then
        BallPart = best
    end
end

local function findBall()
    if ManualBallLock and ManualBallLock.Parent then
        return ManualBallLock
    end
    if BallPart and BallPart.Parent then
        return BallPart
    end
    -- perdemos a bola: atalho O(1) antes de qualquer varredura
    local quick = workspace:FindFirstChild("Ball") or workspace:FindFirstChild("Football")
    if quick and quick:IsA("BasePart") then
        BallPart = quick
        return quick
    end
    -- re-varredura de emergencia: no maximo 1x a cada 5s
    local now = os.clock()
    if now - LastFullRescan > 5 then
        LastFullRescan = now
        task.spawn(initialScan)
    end
    return BallPart
end

-- TRAVA MANUAL: fique perto da bola e chame = 100% garantido
local function lockNearBall()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return nil
    end
    local best, bestD = nil, 30
    local ok, desc = pcall(function()
        return workspace:GetDescendants()
    end)
    if not ok then
        return nil
    end
    for _, d in ipairs(desc) do
        if d:IsA("BasePart") and not d.Anchored then
            if not (d.Parent and d.Parent:FindFirstChildOfClass("Humanoid")) then
                local dist = (d.Position - hrp.Position).Magnitude
                if dist < bestD then
                    local s = ballNameScore(d.Name)
                    local shapeBonus = (d.Shape == Enum.PartType.Ball and 30 or 0)
                    if s > 0 or shapeBonus > 0 or dist < 8 then
                        bestD = dist
                        best = d
                    end
                end
            end
        end
    end
    if best then
        ManualBallLock = best
        BallPart = best
    end
    return best
end

-- Cache de jogadores (atualiza por evento, nao por varredura)
local PlayerCache = {}
local function rebuildPlayerCache()
    PlayerCache = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        table.insert(PlayerCache, plr)
    end
end
rebuildPlayerCache()
track(Players.PlayerAdded:Connect(rebuildPlayerCache))
track(Players.PlayerRemoving:Connect(rebuildPlayerCache))

local function myChar()
    local c = LocalPlayer.Character
    if not c then
        return nil, nil, nil
    end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then
        return nil, nil, nil
    end
    return c, hrp, hum
end

local function hasBall(radius)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    return (hrp.Position - ball.Position).Magnitude <= (radius or 5)
end

local function isEnemy(plr)
    if plr == LocalPlayer then
        return false
    end
    if LocalPlayer.Team == nil or plr.Team == nil then
        return true
    end
    return plr.Team ~= LocalPlayer.Team
end

local function charHrp(char)
    if not char or not char.Parent then
        return nil
    end
    return char:FindFirstChild("HumanoidRootPart")
end

local function getClosestEnemy(maxDist)
    local _, hrp = myChar()
    if not hrp then
        return nil, math.huge
    end
    local best, bestD = nil, maxDist or math.huge
    for _, plr in ipairs(PlayerCache) do
        if isEnemy(plr) and plr.Character then
            local eHrp = charHrp(plr.Character)
            if eHrp then
                local dx = eHrp.Position.X - hrp.Position.X
                local dy = eHrp.Position.Y - hrp.Position.Y
                local dz = eHrp.Position.Z - hrp.Position.Z
                local d = math.sqrt(dx * dx + dy * dy + dz * dz)
                if d < bestD then
                    bestD = d
                    best = plr.Character
                end
            end
        end
    end
    return best, bestD
end

local function getEnemyWithBall(maxDist)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return nil, math.huge
    end
    local best, bestD = nil, maxDist or math.huge
    for _, plr in ipairs(PlayerCache) do
        if isEnemy(plr) and plr.Character then
            local eHrp = charHrp(plr.Character)
            if eHrp then
                local dMe = (eHrp.Position - hrp.Position).Magnitude
                if dMe < bestD and (eHrp.Position - ball.Position).Magnitude <= 5.5 then
                    bestD = dMe
                    best = plr.Character
                end
            end
        end
    end
    return best, bestD
end

local function getBestMate()
    local _, hrp = myChar()
    if not hrp then
        return nil
    end
    local atk = getAttackGoal()
    local best, bestScore = nil, -math.huge
    for _, plr in ipairs(PlayerCache) do
        if plr ~= LocalPlayer and (not isEnemy(plr)) and plr.Character then
            local mHrp = charHrp(plr.Character)
            if mHrp then
                local d = (mHrp.Position - hrp.Position).Magnitude
                if d > 8 and d < 140 then
                    local ahead = 0
                    if atk then
                        local toAtk = (atk - hrp.Position)
                        local toMate = (mHrp.Position - hrp.Position)
                        if toAtk.Magnitude > 1 and toMate.Magnitude > 1 then
                            ahead = toAtk.Unit:Dot(toMate.Unit)
                        end
                    end
                    local score = ahead * 50 - d * 0.15
                    if score > bestScore then
                        bestScore = score
                        best = plr.Character
                    end
                end
            end
        end
    end
    return best
end

local function isBallFree()
    local ball = findBall()
    if not ball then
        return false
    end
    for _, plr in ipairs(PlayerCache) do
        if plr.Character then
            local h = charHrp(plr.Character)
            if h and (h.Position - ball.Position).Magnitude <= 6 then
                return false
            end
        end
    end
    return true
end

function getAttackGoal()
    local _, hrp = myChar()
    if not hrp then
        return nil
    end
    local best, bestD = nil, -1
    for _, g in ipairs(GoalsList) do
        if g.Parent then
            local d = (g.Position - hrp.Position).Magnitude
            if d > bestD and d < 450 then
                bestD = d
                best = g.Position
            end
        end
    end
    if best then
        return best
    end
    return hrp.Position + (hrp.CFrame.LookVector * 120)
end

function getOwnGoal()
    local _, hrp = myChar()
    if not hrp then
        return nil
    end
    local best, bestD = nil, math.huge
    for _, g in ipairs(GoalsList) do
        if g.Parent then
            local d = (g.Position - hrp.Position).Magnitude
            if d < bestD then
                bestD = d
                best = g.Position
            end
        end
    end
    return best
end

local function isGK()
    if Config.GKMode == "Sou GK" then
        return true
    end
    if Config.GKMode == "Nao sou GK" then
        return false
    end
    local _, hrp = myChar()
    local own = getOwnGoal()
    if hrp and own then
        return (hrp.Position - own.Position).Magnitude <= 28
    end
    return false
end

local function faceTowards(pos)
    local _, hrp = myChar()
    if not hrp then
        return
    end
    local look = pos - hrp.Position
    look = Vector3.new(look.X, 0, look.Z)
    if look.Magnitude < 0.5 then
        return
    end
    pcall(function()
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + look)
    end)
end

local function softSteer(pos, strength01)
    local _, hrp = myChar()
    if not hrp then
        return
    end
    local cur = hrp.CFrame.LookVector
    cur = Vector3.new(cur.X, 0, cur.Z)
    local des = pos - hrp.Position
    des = Vector3.new(des.X, 0, des.Z)
    if cur.Magnitude < 0.1 or des.Magnitude < 0.5 then
        return
    end
    local alpha = math.clamp(strength01, 0, 1) * 0.35
    local blended = cur.Unit:Lerp(des.Unit, alpha)
    pcall(function()
        hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + blended)
    end)
end

--[[ ====================== MIRA INTELIGENTE (99%/100%) ==================== ]]
local function computeAim(perfect)
    local _, hrp = myChar()
    local goalPos = getAttackGoal()
    if not hrp or not goalPos then
        return nil
    end
    local toGoal = goalPos - hrp.Position
    local flat = Vector3.new(toGoal.X, 0, toGoal.Z)
    if flat.Magnitude < 1 then
        flat = hrp.CFrame.LookVector
    end
    local right = flat.Unit:Cross(Vector3.new(0, 1, 0)).Unit

    local area = Config.TargetArea
    if area == "Aleatorio PRO" then
        local pool = { "Gaveta", "Canto Direito", "Canto Esquerdo", "Rasteiro", "Meio" }
        area = pool[math.random(1, #pool)]
    end

    local side = (math.random() > 0.5) and 1 or -1
    local aim = goalPos
    if area == "Gaveta" then
        aim = goalPos + right * (6.5 * side) + Vector3.new(0, 5.6, 0)
    elseif area == "Canto Direito" then
        aim = goalPos + right * 7.5 + Vector3.new(0, 3.2, 0)
    elseif area == "Canto Esquerdo" then
        aim = goalPos + right * -7.5 + Vector3.new(0, 3.2, 0)
    elseif area == "Rasteiro" then
        aim = goalPos + right * (6.5 * side) + Vector3.new(0, 0.9, 0)
    else
        aim = goalPos + right * (3 * side) + Vector3.new(0, 3.0, 0)
    end

    -- 99% SEMPRE: micro-variacao humana (4cm) = parece legit mas quase nunca erra
    local miss = math.max(0, (100 - Config.Accuracy)) / 100
    local spread = miss * 4
    aim = aim + Vector3.new((math.random() - 0.5) * 2 * spread, (math.random() - 0.5) * spread, (math.random() - 0.5) * 2 * spread)
    return aim
end

--[[ ================== CHUTE: ASSINATURAS + CALIBRACAO ===================== ]]
-- O jogo pode esperar os argumentos em ordens diferentes. A V3 testa varios
-- formatos e DESCOBRE sozinha qual funciona (observando a bola se mover).

local ShootSigs = {
    { desc = "mira+forca", fn = function(rm, aim, dir) return fire(rm, aim, 100) end },
    { desc = "mira+forca01", fn = function(rm, aim, dir) return fire(rm, aim, 1) end },
    { desc = "so-mira", fn = function(rm, aim, dir) return fire(rm, aim) end },
    { desc = "forca+mira", fn = function(rm, aim, dir) return fire(rm, 100, aim) end },
    { desc = "dir+forca", fn = function(rm, aim, dir) return fire(rm, dir, 100) end },
    { desc = "dir+forca01", fn = function(rm, aim, dir) return fire(rm, dir, 1) end },
    { desc = "cframe+forca", fn = function(rm, aim, dir) return fire(rm, CFrame.new(aim), 100) end },
    { desc = "mira+forca+ok", fn = function(rm, aim, dir) return fire(rm, aim, 100, true) end },
}

local function shootRemote()
    if Config.ShootRemoteAlt and Remotes.ShootAlt then
        return Remotes.ShootAlt
    end
    return Remotes.Shoot or Remotes.ShootAlt
end

local function fireCurve(useCurve)
    if not Remotes.Curve then
        return
    end
    if useCurve then
        local dir = ((math.random() < 0.5) and -1 or 1) * Config.CurveIntensity
        fire(Remotes.Curve, dir)
    else
        fire(Remotes.Curve, 0)
    end
end

local function doShootRemote(powerOverride, useCurveOverride, perfect)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false, "sem-jogo"
    end
    if not hasBall(6.5) then
        return false, "sem-bola"
    end
    local aim = computeAim(perfect)
    if not aim then
        return false, "sem-mira"
    end
    if (aim - hrp.Position).Magnitude > Config.ShootDist then
        return false, "longe"
    end
    if not (Config.ZeroDelay and Config.TopGlobal) then
        task.wait(0.05)
    end
    faceTowards(aim)

    local curveOn
    if useCurveOverride ~= nil then
        curveOn = useCurveOverride
    elseif Config.RandomCurve then
        curveOn = (math.random() < 0.5)
    else
        curveOn = Config.CurveShoot
    end
    fireCurve(curveOn)

    local dir = (aim - hrp.Position)
    if dir.Magnitude < 0.5 then
        return false, "sem-mira"
    end
    dir = dir.Unit
    local sig = ShootSigs[Config.ShootSig] or ShootSigs[1]
    local ok = sig.fn(shootRemote(), aim, dir)
    return ok, "ok"
end

-- Chute por CLICK REAL na posicao do gol na tela (metodo alternativo)
local function doShootVIM(powerHold)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false, "sem-jogo"
    end
    if not hasBall(6.5) then
        return false, "sem-bola"
    end
    local aim = computeAim(Config.TopGlobal)
    if not aim then
        return false, "sem-mira"
    end
    if (aim - hrp.Position).Magnitude > Config.ShootDist then
        return false, "longe"
    end
    faceTowards(aim)
    local cam = workspace.CurrentCamera
    if not cam then
        return false, "sem-camera"
    end
    local sp, onScreen = cam:WorldToScreenPoint(aim)
    local vs = cam.ViewportSize
    local x, y = vs.X / 2, vs.Y / 2
    if onScreen then
        x = math.clamp(sp.X, 20, vs.X - 20)
        y = math.clamp(sp.Y, 20, vs.Y - 20)
    end
    -- forca = tempo segurando (0.15 leve ... 0.9 bomba)
    local hold = 0.15 + (powerHold or 100) / 100 * 0.75
    return clickAt(x, y, 0, hold), "ok"
end

local function doShoot(powerOverride, useCurveOverride, perfect)
    local method = Config.ShootMethod
    if method == "Tecla Real (VIM)" then
        return doShootVIM(powerOverride)
    end
    -- Auto / Remote: usa a assinatura calibrada
    return doShootRemote(powerOverride, useCurveOverride, perfect)
end

-- AUTO-CALIBRACAO: chuta de varios jeitos e ve qual mexe a bola de verdade
local Calibrating = false
local function calibrateShoot()
    if Calibrating then
        notify("Calibracao", "Ja estou calibrando, aguarde.", 2)
        return
    end
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        notify("Calibracao", "Entre em campo primeiro.", 3)
        return
    end
    if not hasBall(6.5) then
        notify("Calibracao", "Fique PARADO com a bola no pe e tente de novo.", 4)
        return
    end
    Calibrating = true
    notify("Calibracao", "Fique PARADO! Testando formatos de chute...", 4)
    task.spawn(function()
        local remotesToTry = {}
        if Remotes.Shoot then
            table.insert(remotesToTry, { r = Remotes.Shoot, alt = false })
        end
        if Remotes.ShootAlt then
            table.insert(remotesToTry, { r = Remotes.ShootAlt, alt = true })
        end
        if #remotesToTry == 0 then
            notify("Calibracao", "Remote de chute nao existe! Usando Tecla Real.", 4)
            Config.ShootMethod = "Tecla Real (VIM)"
            Calibrating = false
            return
        end
        for _, entry in ipairs(remotesToTry) do
            for i, sig in ipairs(ShootSigs) do
                if not Running then
                    Calibrating = false
                    return
                end
                local b = findBall()
                local _, h = myChar()
                if not b or not h or not hasBall(7) then
                    notify("Calibracao", "Perdi a bola. Fique parado com ela e recalibre.", 4)
                    Calibrating = false
                    return
                end
                local aim = computeAim(true)
                local dir = aim and (aim - h.Position)
                if aim and dir.Magnitude > 0.5 then
                    dir = dir.Unit
                    faceTowards(aim)
                    local v0 = b.Velocity
                    pcall(function()
                        sig.fn(entry.r, aim, dir)
                    end)
                    task.wait(0.35)
                    local v1 = b.Velocity
                    local dv = (v1 - v0).Magnitude
                    local toward = false
                    if dv > 8 then
                        toward = (v1.Unit:Dot(dir) > 0.25)
                    end
                    if dv > 8 and toward then
                        Config.ShootSig = i
                        Config.ShootRemoteAlt = entry.alt
                        Config.Calibrated = true
                        Config.ShootMethod = "Auto"
                        notify("Calibracao", "CHUTE FUNCIONANDO! Formato: " .. sig.desc, 5)
                        Calibrating = false
                        return
                    end
                end
            end
        end
        -- nada moveu a bola: cai para o metodo de tecla real
        notify("Calibracao", "Remote nao respondeu. Ativei o modo TECLA REAL.", 5)
        Config.ShootMethod = "Tecla Real (VIM)"
        Calibrating = false
    end)
end

--[[ ============================ ACOES DE JOGO ============================= ]]
-- Prioridade: TECLA REAL (VIM) + remote junto = funciona em qualquer caso.

local function doDribble()
    local _, hrp = myChar()
    if not hrp or not hasBall(5) then
        return false
    end
    if not (Config.ZeroDelay and Config.TopGlobal) then
        task.wait(0.04)
    end
    local did = false
    if Config.VimKeys and VIM_OK then
        did = pressKey(Enum.KeyCode.Q, 0.15) or did
    end
    if (not did) or Config.DoubleFire then
        if Remotes.Action then
            local ok = fire(Remotes.Action, "Dribble", math.random(1, 3))
            if Config.CompatMode and Config.DribbleStyle == "Agressivo" then
                fire(Remotes.Action, "Dribble", math.random(1, 5))
            end
            did = ok or did
        end
    end
    -- corte de corpo lateral (fisica local, sempre funciona)
    pcall(function()
        local side = (math.random() > 0.5) and 1 or -1
        local push = hrp.CFrame.RightVector * (11 * side)
        hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + push
    end)
    return did
end

local function doTackle(targetChar)
    local _, hrp = myChar()
    if not hrp then
        return false
    end
    if targetChar then
        local tHrp = charHrp(targetChar)
        if tHrp then
            faceTowards(tHrp.Position)
            if Config.LegitTackle then
                task.wait(0.03)
            end
        end
    end
    if not (Config.ZeroDelay and Config.TopGlobal) then
        task.wait(0.04)
    end
    local did = false
    if Config.VimKeys and VIM_OK then
        did = pressKey(Enum.KeyCode.E, 0.12) or did
    end
    if (not did) or Config.DoubleFire then
        did = fire(Remotes.Tackle) or did
    end
    return did
end

local function doDive(side)
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    side = side or (((ball.Position - hrp.Position).X > 0) and "Right" or "Left")
    if not (Config.ZeroDelay and Config.TopGlobal) then
        task.wait(0.04)
    end
    local did = false
    if Config.VimKeys and VIM_OK then
        did = pressKey(Enum.KeyCode.X, 0.2) or did
    end
    if (not did) or Config.DoubleFire then
        if Remotes.Action then
            did = fire(Remotes.Action, "GKDive", side) or did
            if Config.CompatMode then
                fire(Remotes.Action, "Dive", side)
            end
        end
        if Remotes.GKHitbox then
            fire(Remotes.GKHitbox, ball.Position)
        end
    elseif Remotes.GKHitbox then
        fire(Remotes.GKHitbox, ball.Position)
    end
    return did
end

local function doGKPass()
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    if not isGK() or not hasBall(6.5) or ball.Velocity.Magnitude > 10 then
        return false
    end
    local mate = getBestMate()
    if not mate then
        return false
    end
    local mHrp = charHrp(mate)
    if not mHrp then
        return false
    end
    local target = mHrp.Position + mHrp.Velocity * 0.25
    faceTowards(target)
    local ok = fire(Remotes.Pass, target, 70)
    if not ok then
        ok = fire(Remotes.Pass, target)
    end
    if (not ok) and Config.VimKeys and VIM_OK then
        -- passe por clique direito REAL no companheiro
        local cam = workspace.CurrentCamera
        if cam then
            local sp, onScreen = cam:WorldToScreenPoint(target)
            if onScreen then
                ok = clickAt(sp.X, sp.Y, 1, 0.4)
            end
        end
    end
    return ok
end

local function doJump()
    local _, _, hum = myChar()
    if not hum then
        return false
    end
    local did = false
    pcall(function()
        hum.Jump = true
        did = true
    end)
    if (not did) and VIM_OK then
        pressKey(Enum.KeyCode.Space, 0.1)
        did = true
    end
    return did
end

local function doHeader()
    local char, hrp = myChar()
    local ball = findBall()
    if not char or not hrp or not ball then
        return false
    end
    local head = char:FindFirstChild("Head")
    local headY = head and head.Position.Y or (hrp.Position.Y + 2)
    if (ball.Position - hrp.Position).Magnitude > 8 or ball.Position.Y < headY + 1.5 then
        return false
    end
    doJump()
    if Remotes.Action then
        fire(Remotes.Action, "Header")
        if Config.CompatMode then
            fire(Remotes.Action, "Head")
        end
    end
    if Config.HeaderShoot then
        task.delay(0.12, function()
            if Running and hasBall(7) then
                doShoot(100, false, Config.TopGlobal)
            end
        end)
    end
    return true
end

local function doBicycle()
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    if (ball.Position - hrp.Position).Magnitude > 7 or ball.Position.Y < hrp.Position.Y + 3.5 then
        return false
    end
    doJump()
    if Remotes.Action then
        fire(Remotes.Action, "Bicycle")
        if Config.CompatMode then
            fire(Remotes.Action, "BicycleKick")
        end
    end
    task.delay(0.15, function()
        if Running and hasBall(7.5) then
            if Config.VimKeys and VIM_OK and Config.ShootMethod == "Tecla Real (VIM)" then
                doShootVIM(100)
            else
                doShoot(100, true, Config.TopGlobal)
            end
        end
    end)
    return true
end

local function doVolley()
    local _, hrp = myChar()
    local ball = findBall()
    if not hrp or not ball then
        return false
    end
    local d = (ball.Position - hrp.Position).Magnitude
    local h = ball.Position.Y - hrp.Position.Y
    if d > 6 or h < 0.5 or h > 4.5 then
        return false
    end
    if Remotes.Action and Config.CompatMode then
        fire(Remotes.Action, "Volley")
    end
    local ok = doShoot(100, false, Config.TopGlobal)
    return ok
end

local function doChip()
    local _, hrp = myChar()
    local ball = findBall()
    local goalPos = getAttackGoal()
    if not hrp or not ball or not goalPos then
        return false
    end
    if not hasBall(6) or (goalPos - hrp.Position).Magnitude > 30 then
        return false
    end
    local aim = goalPos + Vector3.new(0, 4.5, 0)
    faceTowards(aim)
    fireCurve(false)
    return fire(shootRemote(), aim, 28)
end

local function doPowerShot()
    local now = os.clock()
    if now - Cooldown.PowerShot < 30 then
        return false, "recarga"
    end
    if not hasBall(6) then
        return false, "sem-bola"
    end
    -- Power Shot REAL: segura F + clica (igual jogador humano)
    if VIM_OK then
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        end)
        task.wait(0.25)
        local ok = doShootVIM(100)
        task.delay(0.3, function()
            pcall(function()
                VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
            end)
        end)
        if ok then
            Cooldown.PowerShot = now
            return true, "ok"
        end
    end
    local ok2, reason = doShoot(100, true, true)
    if ok2 then
        Cooldown.PowerShot = now
    end
    return ok2, reason
end

--[[ ============================ SISTEMA DE ESP ============================ ]]
local ESPFolder = nil
local function getESPFolder()
    if ESPFolder and ESPFolder.Parent then
        return ESPFolder
    end
    local parent = getGuiParent()
    local f = parent:FindFirstChild("__SnakeESP3")
    if not f then
        f = Instance.new("Folder")
        f.Name = "__SnakeESP3"
        pcall(function()
            f.Parent = parent
        end)
    end
    ESPFolder = f
    return f
end

local BallHL, BallTag, BallTagLabel = nil, nil, nil
local function ensureBallESP()
    local folder = getESPFolder()
    if not BallHL or not BallHL.Parent then
        BallHL = Instance.new("Highlight")
        BallHL.Name = "__SnakeBallHL"
        BallHL.FillColor = Color3.fromRGB(0, 255, 120)
        BallHL.OutlineColor = Color3.fromRGB(0, 200, 90)
        BallHL.FillTransparency = 0.6
        BallHL.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        BallHL.Parent = folder
    end
    if not BallTag or not BallTag.Parent then
        BallTag = Instance.new("BillboardGui")
        BallTag.Name = "__SnakeBallTag"
        BallTag.Size = UDim2.new(0, 120, 0, 40)
        BallTag.StudsOffset = Vector3.new(0, 3, 0)
        BallTag.AlwaysOnTop = true
        BallTagLabel = Instance.new("TextLabel")
        BallTagLabel.Size = UDim2.new(1, 0, 1, 0)
        BallTagLabel.BackgroundTransparency = 1
        BallTagLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        BallTagLabel.TextStrokeTransparency = 0.3
        BallTagLabel.Font = Enum.Font.GothamBold
        BallTagLabel.TextSize = 14
        BallTagLabel.Text = "BOLA"
        BallTagLabel.Parent = BallTag
        BallTag.Parent = folder
    end
end

local GoalHLs = {}
local function refreshGoalESP()
    local folder = getESPFolder()
    for _, h in ipairs(GoalHLs) do
        pcall(function()
            h:Destroy()
        end)
    end
    GoalHLs = {}
    for i = 1, math.min(#GoalsList, 8) do
        local g = GoalsList[i]
        if g and g.Parent then
            local h = Instance.new("Highlight")
            h.Name = "__SnakeGoalHL"
            h.FillColor = Color3.fromRGB(255, 200, 0)
            h.OutlineColor = Color3.fromRGB(255, 150, 0)
            h.FillTransparency = 0.7
            h.Adornee = g
            h.Parent = folder
            table.insert(GoalHLs, h)
        end
    end
end

local function clearPlayerESP()
    for _, plr in ipairs(PlayerCache) do
        if plr.Character then
            local tag = plr.Character:FindFirstChild("__SnakePTag3")
            if tag then
                pcall(function()
                    tag:Destroy()
                end)
            end
        end
    end
end

local function refreshPlayerESP()
    local _, hrp = myChar()
    for _, plr in ipairs(PlayerCache) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local eHrp = charHrp(plr.Character)
            if head and eHrp then
                local tag = plr.Character:FindFirstChild("__SnakePTag3")
                if not tag then
                    tag = Instance.new("BillboardGui")
                    tag.Name = "__SnakePTag3"
                    tag.Size = UDim2.new(0, 140, 0, 36)
                    tag.StudsOffset = Vector3.new(0, 2.6, 0)
                    tag.AlwaysOnTop = true
                    local lb = Instance.new("TextLabel")
                    lb.Name = "L"
                    lb.Size = UDim2.new(1, 0, 1, 0)
                    lb.BackgroundTransparency = 1
                    lb.Font = Enum.Font.GothamBold
                    lb.TextSize = 13
                    lb.TextStrokeTransparency = 0.3
                    lb.Parent = tag
                    tag.Parent = plr.Character
                end
                local lb = tag:FindFirstChild("L")
                if lb then
                    local d = hrp and math.floor((eHrp.Position - hrp.Position).Magnitude) or 0
                    lb.Text = plr.DisplayName .. " [" .. d .. "m]"
                    if isEnemy(plr) then
                        lb.TextColor3 = Color3.fromRGB(255, 80, 80)
                    else
                        lb.TextColor3 = Color3.fromRGB(90, 160, 255)
                    end
                end
            end
        end
    end
end

local function clearESP()
    pcall(function()
        if BallHL then
            BallHL:Destroy()
        end
    end)
    pcall(function()
        if BallTag then
            BallTag:Destroy()
        end
    end)
    BallHL, BallTag, BallTagLabel = nil, nil, nil
    for _, h in ipairs(GoalHLs) do
        pcall(function()
            h:Destroy()
        end)
    end
    GoalHLs = {}
    clearPlayerESP()
end

--[[ =================== BOTOES FLUTUANTES (MOBILE + PC) ==================== ]]
local FloatGui = nil
local function getFloatGui()
    if FloatGui and FloatGui.Parent then
        return FloatGui
    end
    local parent = getGuiParent()
    local old = parent:FindFirstChild("__SnakeFloatV3")
    if old then
        pcall(function()
            old:Destroy()
        end)
    end
    local g = Instance.new("ScreenGui")
    g.Name = "__SnakeFloatV3"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    pcall(function()
        g.Parent = parent
    end)
    FloatGui = g
    return g
end

local function styleFloatButton(btn, size, pos, text, color, textSize)
    btn.Size = size
    btn.Position = pos
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = textSize or 26
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = color
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = btn
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(255, 255, 255)
    s.Transparency = 0.4
    s.Thickness = 2
    s.Parent = btn
end

local function makeFloatButton(btn, onTap)
    local dragging = false
    local moved = false
    local dragStart = nil
    local startPos = nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 12 then
                moved = true
            end
            if moved then
                btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            local wasTap = dragging and (not moved)
            dragging = false
            moved = false
            if wasTap and onTap then
                task.spawn(onTap)
            end
        end
    end)
end

local UIVisible = true
local function setUiVisible(v)
    UIVisible = v
    pcall(function()
        local parents = { getGuiParent(), game:GetService("CoreGui") }
        local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pgui then
            table.insert(parents, pgui)
        end
        for _, par in ipairs(parents) do
            for _, g in ipairs(par:GetChildren()) do
                if g:IsA("ScreenGui") and (string.lower(g.Name) == "rayfield" or g.Name == "__SnakeMiniV3") then
                    g.Enabled = v
                end
            end
        end
    end)
end

local SnakeBtn, ShootBtn, AutoShootBtn = nil, nil, nil

-- Botao EXCLUSIVO do auto shoot: semitransparente, liga/desliga + chuta
local function refreshAutoShootBtn()
    if AutoShootBtn and AutoShootBtn.Parent then
        if Config.AutoShoot then
            AutoShootBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
            AutoShootBtn.Text = "AUTO\nSHOOT ON"
        else
            AutoShootBtn.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
            AutoShootBtn.Text = "AUTO\nSHOOT"
        end
        AutoShootBtn.Visible = Config.FloatAutoShoot
    end
end

local function buildFloatButtons()
    local gui = getFloatGui()
    if not SnakeBtn or not SnakeBtn.Parent then
        SnakeBtn = Instance.new("TextButton")
        SnakeBtn.Name = "SnakeToggle"
        styleFloatButton(SnakeBtn, UDim2.new(0, 56, 0, 56), UDim2.new(0, 14, 0.5, -120),
            "S", Color3.fromRGB(0, 170, 80))
        SnakeBtn.Parent = gui
        makeFloatButton(SnakeBtn, function()
            setUiVisible(not UIVisible)
        end)
    end
    if not ShootBtn or not ShootBtn.Parent then
        ShootBtn = Instance.new("TextButton")
        ShootBtn.Name = "ShootNow"
        styleFloatButton(ShootBtn, UDim2.new(0, 88, 0, 88), UDim2.new(1, -104, 0.5, 20),
            "CHUTE", Color3.fromRGB(200, 40, 40), 16)
        ShootBtn.Parent = gui
        makeFloatButton(ShootBtn, function()
            local ok, reason = doShoot(100, nil, Config.TopGlobal)
            if not ok and reason == "sem-bola" then
                notify("SnakeHub Chute", "Chegue perto da bola para chutar.", 2)
            elseif not ok and reason == "longe" then
                notify("SnakeHub Chute", "Fora do alcance configurado.", 2)
            end
        end)
    end
    if not AutoShootBtn or not AutoShootBtn.Parent then
        AutoShootBtn = Instance.new("TextButton")
        AutoShootBtn.Name = "AutoShootToggle"
        styleFloatButton(AutoShootBtn, UDim2.new(0, 78, 0, 78), UDim2.new(0, 10, 0.5, -44),
            "AUTO\nSHOOT", Color3.fromRGB(90, 90, 100), 13)
        AutoShootBtn.BackgroundTransparency = 0.35 -- semitransparente exclusivo
        AutoShootBtn.Parent = gui
        makeFloatButton(AutoShootBtn, function()
            Config.AutoShoot = not Config.AutoShoot
            refreshAutoShootBtn()
            if Config.AutoShoot then
                notify("Auto Shoot", "LIGADO pelo botao exclusivo (99%).", 2)
                task.spawn(function()
                    doShoot(100, nil, false)
                end)
            else
                notify("Auto Shoot", "DESLIGADO.", 2)
            end
        end)
    end
    SnakeBtn.Visible = Config.FloatUI
    ShootBtn.Visible = Config.FloatShoot
    refreshAutoShootBtn()
end

--[[ ================== MEDIDOR DE FPS + TICK ADAPTATIVO =================== ]]
local FPSFrames = 0
local FPSValue = 60
local TickInterval = 1 / 12
track(RunService.Heartbeat:Connect(function()
    FPSFrames = FPSFrames + 1
end))
task.spawn(function()
    while Running do
        task.wait(1)
        FPSValue = FPSFrames
        FPSFrames = 0
        if Config.AdaptiveHz then
            if FPSValue < 15 then
                Config.CombatHz = 6
            elseif FPSValue < 22 then
                Config.CombatHz = 8
            else
                Config.CombatHz = 12
            end
            TickInterval = 1 / Config.CombatHz
        else
            TickInterval = 1 / Config.CombatHz
        end
        pcall(updateMiniStatus)
    end
end)

--[[ ================== MOTOR PRINCIPAL (TICK LEVE 12Hz) ==================== ]]
-- Roda 12x por segundo (nao 60x) = 5x mais leve, mesma eficacia.
local lastMoveDir = Vector3.new(0, 0, 0)
local lastMoveTime = 0
local lastTopChase = 0

local function combatTick()
    local char, hrp, hum = myChar()
    if not char or not hrp or not hum then
        return
    end
    local ball = findBall()
    if not ball then
        return
    end
    local now = os.clock()
    local TOP = Config.TopGlobal
    local ballDistMe = (ball.Position - hrp.Position).Magnitude

    -- 1) AUTO SHOOT
    if Config.AutoShoot and (now - Cooldown.Shoot) > 0.7 then
        if ballDistMe <= 4.5 then
            local aim = computeAim(TOP)
            if aim and (aim - hrp.Position).Magnitude <= Config.ShootDist then
                Cooldown.Shoot = now
                task.spawn(function()
                    doShoot(nil, nil, TOP)
                end)
            end
        end
    end

    -- 2) POWER SHOT em chance clara
    if Config.AutoPowerShot and (now - Cooldown.PowerShot) >= 30 then
        if ballDistMe <= 5 then
            local aim = computeAim(true)
            if aim and (aim - hrp.Position).Magnitude <= 65 then
                task.spawn(doPowerShot)
            end
        end
    end

    -- 3) AUTO DRIBLE
    if Config.AutoDribble and (now - Cooldown.Dribble) > Config.DribbleCD then
        if ballDistMe <= 4.2 then
            local enemy, eDist = getClosestEnemy(Config.DribbleDist)
            if enemy and eDist <= Config.DribbleDist then
                local eHrp = charHrp(enemy)
                if eHrp and eHrp.Velocity.Magnitude > 6 then
                    Cooldown.Dribble = now
                    task.spawn(doDribble)
                end
            end
        end
    end

    -- 4) AUTO TACKLE
    if Config.AutoTackle and (now - Cooldown.Tackle) > 0.5 then
        if ballDistMe > 2.5 then
            local enemy = getEnemyWithBall(Config.TackleDist)
            local doIt = (enemy ~= nil)
            if (not doIt) and Config.InterceptPro then
                if ballDistMe <= Config.TackleDist + 2 and ball.Velocity.Magnitude > 12 then
                    local toMe = (hrp.Position - ball.Position)
                    if toMe.Magnitude > 0.5 and ball.Velocity.Unit:Dot(toMe.Unit) > 0.5 then
                        doIt = true
                    end
                end
            end
            if doIt then
                Cooldown.Tackle = now
                task.spawn(function()
                    doTackle(enemy)
                end)
            end
        end
    end

    -- 5) AUTO ACTIONS
    do
        local head = char:FindFirstChild("Head")
        local headY = head and head.Position.Y or (hrp.Position.Y + 2)
        local ballH = ball.Position.Y - hrp.Position.Y
        if Config.AutoBicycle and (now - Cooldown.Bicycle) > 1.2 then
            if ballDistMe <= 7 and ball.Position.Y >= hrp.Position.Y + 3.5 then
                Cooldown.Bicycle = now
                task.spawn(doBicycle)
            end
        end
        if Config.AutoHeader and (now - Cooldown.Header) > 1.0 then
            if ballDistMe <= 8 and ball.Position.Y >= headY + 1.5 and ball.Velocity.Y < 4 then
                Cooldown.Header = now
                task.spawn(doHeader)
            end
        end
        if Config.AutoVolley and (now - Cooldown.Volley) > 0.8 then
            if ballDistMe <= 6 and ballH >= 0.5 and ballH <= 4.5 then
                Cooldown.Volley = now
                task.spawn(doVolley)
            end
        end
        if Config.AutoChip and (now - Cooldown.Chip) > 1.0 then
            if ballDistMe <= 6 then
                local atk = getAttackGoal()
                if atk and (atk - hrp.Position).Magnitude <= 30 then
                    Cooldown.Chip = now
                    task.spawn(doChip)
                end
            end
        end
    end

    -- 6) GOLEIRO
    local amGK = isGK()
    if (Config.AutoDive or Config.AutoDefense or Config.AutoPunch) and (now - Cooldown.Dive) > 0.9 then
        if ballDistMe <= Config.GKRange and ball.Velocity.Magnitude > 16 then
            local toMe = (hrp.Position - ball.Position)
            if toMe.Magnitude > 0.5 and ball.Velocity.Unit:Dot(toMe.Unit) > 0.35 then
                Cooldown.Dive = now
                task.spawn(function()
                    doDive()
                end)
            end
        end
    end
    if Config.AutoDefense and amGK and hum.MoveDirection.Magnitude < 0.15 then
        local own = getOwnGoal()
        if own then
            local between = (ball.Position - own)
            if between.Magnitude > 1 then
                local mid = own + between.Unit * 2.5
                mid = Vector3.new(mid.X, hrp.Position.Y, mid.Z)
                if (hrp.Position - mid).Magnitude > 4 then
                    pcall(function()
                        hum:MoveTo(mid)
                    end)
                end
            end
        end
    end
    if Config.AutoPunch and (now - Cooldown.Punch) > 1.0 then
        if ballDistMe <= 7 and ball.Position.Y > hrp.Position.Y + 1 then
            Cooldown.Punch = now
            task.spawn(function()
                local did = false
                if Config.VimKeys and VIM_OK then
                    did = pressKey(Enum.KeyCode.X, 0.15) or did
                end
                if Remotes.Action then
                    fire(Remotes.Action, "Punch")
                    if Config.CompatMode then
                        fire(Remotes.Action, "Clear")
                    end
                end
                if Remotes.GKHitbox then
                    fire(Remotes.GKHitbox, ball.Position)
                end
            end)
        end
    end
    if Config.AutoPassGK and (now - Cooldown.Pass) > 3 then
        if amGK and ballDistMe <= 6.5 and ball.Velocity.Magnitude <= 10 then
            Cooldown.Pass = now
            task.spawn(doGKPass)
        end
    end

    -- 7) AIM LOCK
    if Config.AimLock and ballDistMe <= 5 and not TOP then
        local aim = computeAim(false)
        if aim then
            softSteer(aim, 0.8)
        end
    end

    -- 8) TOP GLOBAL: mira 99% + espelho + movimento PRO
    if TOP then
        if ballDistMe <= 5.5 then
            local aim = computeAim(true)
            if aim then
                softSteer(aim, Config.SteerAssist / 100)
            end
        end
        if Config.MoveMirror and ballDistMe <= 5 then
            local md = hum.MoveDirection
            if md.Magnitude > 0.2 and lastMoveDir.Magnitude > 0.2 then
                if md.Unit:Dot(lastMoveDir.Unit) < 0.4 and (now - lastMoveTime) < 0.3
                    and (now - Cooldown.Dribble) > Config.DribbleCD then
                    local _, eDist = getClosestEnemy(8)
                    if eDist <= 8 then
                        Cooldown.Dribble = now
                        task.spawn(doDribble)
                    end
                end
            end
            if md.Magnitude > 0.2 then
                lastMoveDir = md
                lastMoveTime = now
            end
        end
        if Config.ProMovement and hum.MoveDirection.Magnitude < 0.15 and (now - lastTopChase) > 0.4 then
            lastTopChase = now
            if isBallFree() then
                local chase = ball.Position + ball.Velocity * 0.2
                pcall(function()
                    hum:MoveTo(chase)
                end)
            elseif Config.FullAuto and ballDistMe <= 5.5 then
                local atk = getAttackGoal()
                if atk then
                    pcall(function()
                        hum:MoveTo(atk)
                    end)
                end
            end
        end
    end

    -- 9) AUTO FACEOFF
    if Config.AutoFaceoff and (now - Cooldown.Faceoff) > 0.4 then
        if ballDistMe <= 12 then
            Cooldown.Faceoff = now
            fire(Remotes.Faceoff)
        end
    end
end

-- Loop do motor: acumulador leve + pcall TOTAL (nunca quebra, nunca trava)
local lastCombatTick = 0
track(RunService.Heartbeat:Connect(function(dt)
    if not Running then
        return
    end
    local now = os.clock()
    if now - lastCombatTick >= TickInterval then
        lastCombatTick = now
        local ok, err = pcall(combatTick)
        if not ok then
            ErrorCount = ErrorCount + 1
            if ErrorCount == 5 then
                notify("SnakeHub", "Motor se protegeu de erros. Tudo continua rodando.", 4)
            end
        end
    end
end))

--[[ ======== MANUTENCAO LEVE (0.5s) + PENALTI + ESP + ANTI-AFK ============ ]]
task.spawn(function()
    while Running do
        task.wait(0.5)
        pcall(function()
            if Config.InfiniteStamina and Remotes.SpeedRemote then
                fire(Remotes.SpeedRemote, true, 100)
            end
            if Config.WalkEnabled then
                local _, _, hum = myChar()
                if hum and math.abs(hum.WalkSpeed - Config.WalkSpeed) > 0.5 then
                    hum.WalkSpeed = Config.WalkSpeed
                end
            end
            if Config.SkipCutscene then
                fire(Remotes.Cutscene, "Skip")
                fire(Remotes.PodiumCam, "Skip")
                fire(Remotes.PodiumCel, "Skip")
            end
            if Config.AntiAFK and Remotes.AFK then
                fire(Remotes.AFK, false)
            end
            if Config.NoShake and Remotes.Shake then
                fire(Remotes.Shake, 0)
            end
            if Config.AutoCollect then
                fire(Remotes.ClaimStick)
                fire(Remotes.Collect)
                fire(Remotes.TCellLoc)
            end
        end)
    end
end)

task.spawn(function()
    local side = 0
    while Running do
        task.wait(0.9)
        if Config.AutoPenalty and Remotes.Penalty then
            side = side + 1
            local corners = { "Left", "Right", "Center", "Right", "Left" }
            fire(Remotes.Penalty, corners[(side % #corners) + 1])
        end
    end
end)

task.spawn(function()
    local goalTick = 0
    while Running do
        task.wait(0.4)
        pcall(function()
            if Config.BallESP then
                ensureBallESP()
                local ball = findBall()
                local _, hrp = myChar()
                if ball then
                    BallHL.Adornee = ball
                    BallHL.Enabled = true
                    BallTag.Adornee = ball
                    BallTag.Enabled = true
                    if BallTagLabel then
                        local d = hrp and math.floor((ball.Position - hrp.Position).Magnitude) or 0
                        BallTagLabel.Text = "BOLA [" .. d .. "m]"
                    end
                end
            elseif BallHL then
                BallHL.Enabled = false
                if BallTag then
                    BallTag.Enabled = false
                end
            end
            if Config.GoalESP then
                goalTick = goalTick + 1
                if goalTick >= 20 or #GoalHLs == 0 then
                    goalTick = 0
                    refreshGoalESP()
                end
            elseif #GoalHLs > 0 then
                for _, h in ipairs(GoalHLs) do
                    h:Destroy()
                end
                GoalHLs = {}
            end
            if Config.PlayerESP then
                refreshPlayerESP()
            end
        end)
    end
end)

track(LocalPlayer.Idled:Connect(function()
    if Config.AntiAFK and Running then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0, 0), Camera.CFrame)
            task.wait(0.5)
            VirtualUser:Button2Up(Vector2.new(0, 0), Camera.CFrame)
        end)
    end
end))

track(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = workspace.CurrentCamera
end))

track(UserInputService.InputBegan:Connect(function(input, gpe)
    if not Running then
        return
    end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end
    local okUI, uiKey = pcall(function()
        return Enum.KeyCode[Config.UIKey]
    end)
    if okUI and uiKey and input.KeyCode == uiKey then
        setUiVisible(not UIVisible)
        return
    end
    if Config.ShootKeyEnabled then
        local okS, sKey = pcall(function()
            return Enum.KeyCode[Config.ShootKey]
        end)
        if okS and sKey and input.KeyCode == sKey and not gpe then
            task.spawn(function()
                doShoot(100, nil, Config.TopGlobal)
            end)
        end
    end
end))

--[[ ============================ ANTI-LAG ================================== ]]
-- Nivel 1 LEVE: cortes visuais seguros (1 varredura unica, sem loop)
local LagLevel = 0
local function applyAntiLag(level)
    level = level or 1
    LagLevel = level
    pcall(function()
        -- qualidade minima de renderizacao
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        pcall(function()
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 2
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
                or v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") then
                v.Enabled = false
            end
        end
        local atmos = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmos then
            atmos.Density = 0
            atmos.Haze = 0
        end
        -- UMA varredura unica: desliga particulas e efeitos
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke")
                or d:IsA("Fire") or d:IsA("Sparkles") or d:IsA("Beam") then
                d.Enabled = false
            elseif level >= 2 and d:IsA("PointLight") or level >= 2 and d:IsA("SpotLight") or level >= 2 and d:IsA("SurfaceLight") then
                d.Enabled = false
            end
        end
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            pcall(function()
                terrain.WaterTransparency = 1
            end)
        end
        fire(Remotes.FPSNORE)
    end)
    if level >= 2 then
        -- ULTRA: motor em 8Hz + ESP desligado
        Config.AdaptiveHz = true
        Config.BallESP = false
        Config.GoalESP = false
        Config.PlayerESP = false
        pcall(clearESP)
        notify("Anti-Lag ULTRA", "Graficos minimos + motor economico. FPS deve subir!", 4)
    else
        notify("Anti-Lag", "Efeitos pesados desligados.", 3)
    end
end

-- MODO BATATA: plastico liso + sem texturas (maximo FPS em GPU fraca)
local PotatoOn = false
local function applyPotatoMode(on)
    PotatoOn = on
    if not on then
        notify("Modo Batata", "Desligado (entre de novo p/ voltar o visual).", 3)
        return
    end
    task.spawn(function()
        pcall(function()
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Material = Enum.Material.SmoothPlastic
                    d.CastShadow = false
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d.Transparency = 1
                elseif d:IsA("SurfaceGui") then
                    d.Enabled = false
                end
            end
        end)
        notify("Modo Batata", "Visual simplificado = FPS MAXIMO.", 4)
    end)
end

-- Remove acessorios dos OUTROS jogadores (1 varredura + evento, leve)
local NoHats = false
local function stripHats(char)
    pcall(function()
        for _, x in ipairs(char:GetChildren()) do
            if x:IsA("Accessory") or x:IsA("Hat") then
                x:Destroy()
            end
        end
        local sh = char:FindFirstChildOfClass("Shirt")
        if sh then
            sh:Destroy()
        end
        local pa = char:FindFirstChildOfClass("Pants")
        if pa then
            pa:Destroy()
        end
    end)
end
local function applyNoHats(on)
    NoHats = on
    if not on then
        return
    end
    task.spawn(function()
        for _, plr in ipairs(PlayerCache) do
            if plr ~= LocalPlayer and plr.Character then
                stripHats(plr.Character)
            end
        end
    end)
end
track(Players.PlayerAdded:Connect(function(plr)
    if NoHats then
        plr.CharacterAdded:Connect(function(char)
            task.wait(1)
            if NoHats and Running then
                stripHats(char)
            end
        end)
    end
end))

--[[ ============================ DIAGNOSTICO ================================ ]]
local function diagString()
    local ball = findBall()
    local _, hrp = myChar()
    local ballTxt = "NAO"
    if ball then
        local d = hrp and math.floor((ball.Position - hrp.Position).Magnitude) or -1
        ballTxt = "SIM (" .. ball.Name .. " " .. d .. "m)"
    end
    local ping = 0
    pcall(function()
        ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
    end)
    local shootTxt = (Remotes.Shoot ~= nil or Remotes.ShootAlt ~= nil) and "SIM" or "NAO"
    local lines = {}
    table.insert(lines, "FPS: " .. FPSValue .. " | Ping: " .. ping .. "ms")
    table.insert(lines, "Bola: " .. ballTxt)
    table.insert(lines, "Remotes: " .. RemoteCount .. " | Chute: " .. shootTxt)
    table.insert(lines, "Teclas reais (VIM): " .. (VIM_OK and "SIM" or "NAO"))
    table.insert(lines, "Chute calibrado: " .. (Config.Calibrated and ("SIM (" .. (ShootSigs[Config.ShootSig] and ShootSigs[Config.ShootSig].desc or "?") .. ")") or "NAO - calibre!"))
    table.insert(lines, "Motor: " .. Config.CombatHz .. "Hz | Erros contidos: " .. ErrorCount)
    return table.concat(lines, "\n")
end

--[[ ==================== MAPEADOR DO EXPLORER (1 clique) =================== ]]
-- Varre o jogo e mostra a ESTRUTURA REAL: remotes, bola, workspace, PlayerGui.
-- Copie o resultado e envie para fixar os caminhos exatos no script.
local Mapping = false

-- Copia robusta: tenta TODOS os metodos de clipboard dos executors
local function tryCopy(text)
    local fns = {}
    pcall(function()
        local envs = { _G }
        if typeof(getgenv) == "function" then
            table.insert(envs, getgenv())
        end
        for _, e in ipairs(envs) do
            if type(e["setclipboard"]) == "function" then
                table.insert(fns, e["setclipboard"])
            end
            if type(e["toclipboard"]) == "function" then
                table.insert(fns, e["toclipboard"])
            end
            if type(e["set_clipboard"]) == "function" then
                table.insert(fns, e["set_clipboard"])
            end
            local cb = e["Clipboard"]
            if type(cb) == "table" and type(cb.set) == "function" then
                table.insert(fns, function(t)
                    cb.set(t)
                end)
            end
        end
    end)
    for _, fn in ipairs(fns) do
        local ok = pcall(function()
            fn(text)
        end)
        if ok then
            return true
        end
    end
    return false
end

local function trySaveFile(name, text)
    local saved = false
    pcall(function()
        if typeof(writefile) == "function" then
            writefile(name, text)
            saved = true
        end
    end)
    return saved
end

-- Janela do mapa: paginas curtas + copia automatica + salvar txt
local function showCopyWindow(title, text)
    local parent = getGuiParent()
    pcall(function()
        local old = parent:FindFirstChild("__SnakeCopyV3")
        if old then
            old:Destroy()
        end
    end)
    -- quebra em paginas curtas (copia facil no celular)
    local pages = {}
    do
        local PAGE = 2200
        local rest = text or ""
        if #rest == 0 then
            rest = "(vazio - mapeamento falhou)"
        end
        while #rest > 0 do
            if #rest <= PAGE then
                table.insert(pages, rest)
                rest = ""
            else
                local cut = PAGE
                local i = PAGE
                while i > PAGE - 300 and i > 1 do
                    if string.sub(rest, i, i) == "\n" then
                        cut = i
                        break
                    end
                    i = i - 1
                end
                table.insert(pages, string.sub(rest, 1, cut))
                rest = string.sub(rest, cut + 1)
            end
        end
    end
    local page = 1
    local totalChars = #(text or "")

    local g = Instance.new("ScreenGui")
    g.Name = "__SnakeCopyV3"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 470)
    frame.Position = UDim2.new(0.5, -150, 0.5, -235)
    frame.BackgroundColor3 = Color3.fromRGB(18, 20, 24)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame
    local tb = Instance.new("TextLabel")
    tb.Size = UDim2.new(1, 0, 0, 28)
    tb.BackgroundTransparency = 1
    tb.Font = Enum.Font.GothamBold
    tb.TextSize = 13
    tb.TextColor3 = Color3.fromRGB(0, 255, 130)
    tb.Text = title
    tb.Parent = frame
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -16, 0, 262)
    box.Position = UDim2.new(0, 8, 0, 30)
    box.BackgroundColor3 = Color3.fromRGB(8, 10, 12)
    box.Font = Enum.Font.Code
    box.TextSize = 11
    box.TextColor3 = Color3.fromRGB(220, 230, 220)
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.TextYAlignment = Enum.TextYAlignment.Top
    box.MultiLine = true
    box.ClearTextOnFocus = false
    box.TextEditable = true
    box.TextWrapped = false
    box.Text = pages[1]
    box.Parent = frame
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = box
    local pageLbl = Instance.new("TextLabel")
    pageLbl.Size = UDim2.new(1, -16, 0, 16)
    pageLbl.Position = UDim2.new(0, 8, 0, 294)
    pageLbl.BackgroundTransparency = 1
    pageLbl.Font = Enum.Font.GothamBold
    pageLbl.TextSize = 11
    pageLbl.TextColor3 = Color3.fromRGB(255, 220, 100)
    pageLbl.Text = ""
    pageLbl.Parent = frame
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -16, 0, 82)
    status.Position = UDim2.new(0, 8, 0, 384)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 10
    status.TextColor3 = Color3.fromRGB(170, 170, 180)
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Text = "Tentando copia automatica..."
    status.Parent = frame
    local function setStatus(msg, good)
        status.Text = msg
        if good then
            status.TextColor3 = Color3.fromRGB(120, 255, 140)
        else
            status.TextColor3 = Color3.fromRGB(255, 220, 120)
        end
    end
    local function refreshPage()
        pageLbl.Text = "Pagina " .. page .. "/" .. #pages .. " (" .. totalChars .. " letras)"
        box.Text = pages[page]
        pcall(function()
            box.CursorPosition = 1
        end)
    end
    local function mkBtn(x, y, w, txt, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, w, 0, 32)
        b.Position = UDim2.new(0, x, 0, y)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.BackgroundColor3 = color
        b.BorderSizePixel = 0
        b.Text = txt
        b.Parent = frame
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 8)
        cc.Parent = b
        return b
    end
    local bPrev = mkBtn(8, 312, 84, "< ANT", Color3.fromRGB(70, 70, 80))
    local bCopy = mkBtn(96, 312, 104, "COPIAR PAG", Color3.fromRGB(0, 130, 200))
    local bNext = mkBtn(204, 312, 88, "PROX >", Color3.fromRGB(70, 70, 80))
    local bAll = mkBtn(8, 348, 90, "TUDO", Color3.fromRGB(0, 150, 90))
    local bTxt = mkBtn(102, 348, 90, "SALVAR TXT", Color3.fromRGB(130, 70, 180))
    local bClose = mkBtn(196, 348, 96, "FECHAR", Color3.fromRGB(90, 90, 100))
    bPrev.MouseButton1Click:Connect(function()
        if page > 1 then
            page = page - 1
            refreshPage()
        end
    end)
    bNext.MouseButton1Click:Connect(function()
        if page < #pages then
            page = page + 1
            refreshPage()
        end
    end)
    bCopy.MouseButton1Click:Connect(function()
        if tryCopy(pages[page]) then
            setStatus("PAGINA " .. page .. " COPIADA! Cole no chat e volte para copiar a proxima.", true)
        else
            setStatus("Copia bloqueada pelo executor. SEGURE O DEDO no texto > SELECIONAR TUDO > COPIAR.", false)
            pcall(function()
                box:CaptureFocus()
            end)
        end
    end)
    bAll.MouseButton1Click:Connect(function()
        if tryCopy(text) then
            setStatus("TUDO COPIADO! Cole aqui no chat.", true)
        else
            setStatus("Copia total bloqueada. Copie PAGINA POR PAGINA ou segure o dedo no texto.", false)
        end
    end)
    bTxt.MouseButton1Click:Connect(function()
        if trySaveFile("snakehub_mapa.txt", text) then
            setStatus("SALVO em snakehub_mapa.txt (pasta do executor). Abra o arquivo e me envie.", true)
        else
            setStatus("Seu executor nao salva arquivos. Use COPIAR PAG.", false)
        end
    end)
    bClose.MouseButton1Click:Connect(function()
        pcall(function()
            g:Destroy()
        end)
    end)
    pcall(function()
        g.Parent = parent
    end)
    refreshPage()
    -- copia automatica ao abrir
    task.spawn(function()
        task.wait(0.4)
        if tryCopy(text) then
            setStatus("COPIADO AUTOMATICAMENTE! Cole aqui no chat.", true)
            notify("Mapa", "Copiado! Cole o texto aqui no chat.", 4)
        elseif trySaveFile("snakehub_mapa.txt", text) then
            setStatus("Auto-copia indisponivel, mas SALVEI em snakehub_mapa.txt. Ou copie por pagina.", true)
        else
            setStatus("Auto-copia indisponivel: use COPIAR PAG (recomendado) ou segure o dedo no texto.", false)
        end
    end)
end

local function mapExplorer()
    if Mapping then
        notify("Mapeador", "Ja estou mapeando, aguarde.", 2)
        return
    end
    Mapping = true
    notify("Mapeador", "Mapeando o jogo (pode travar 2s)...", 3)
    task.spawn(function()
        local out = {}
        local function line(s)
            table.insert(out, s)
        end
        pcall(function()
            line("== SNAKEHUB MAPA DO JOGO ==")
            line("PlaceId: " .. tostring(game.PlaceId))
            line("")
            line("== REMOTES (ReplicatedStorage) ==")
            local n = 0
            for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction")
                    or d:IsA("UnreliableRemoteEvent") or d:IsA("BindableEvent") then
                    n = n + 1
                    if n <= 150 then
                        line(d.ClassName .. " | " .. d:GetFullName())
                    end
                end
            end
            line("Total remotes: " .. n)
            line("")
            line("== WORKSPACE (filhos diretos) ==")
            local kids = workspace:GetChildren()
            for i = 1, math.min(#kids, 120) do
                local k = kids[i]
                line(k.ClassName .. " | " .. k.Name)
            end
            line("Total filhos: " .. #kids)
            line("")
            line("== CANDIDATOS A BOLA ==")
            local nb = 0
            for _, d in ipairs(workspace:GetDescendants()) do
                if d:IsA("BasePart") and nb < 40 then
                    local par = d.Parent
                    local isChar = par and par:FindFirstChildOfClass("Humanoid")
                    if not isChar then
                        local s = ballNameScore(d.Name)
                        local isBallShape = (d.Shape == Enum.PartType.Ball)
                        local sz = d.Size.Magnitude
                        if s > 0 or isBallShape or (not d.Anchored and sz > 1 and sz < 5) then
                            nb = nb + 1
                            line(d.Name .. " | " .. d:GetFullName()
                                .. " | size=" .. string.format("%.1f", sz)
                                .. " | anc=" .. tostring(d.Anchored))
                        end
                    end
                end
            end
            line("Total candidatos: " .. nb)
            line("")
            line("== GOLS (cache do script) ==")
            for i, g in ipairs(GoalsList) do
                if g.Parent then
                    line(i .. ". " .. g:GetFullName())
                end
            end
            line("")
            line("== PLAYERGUI ==")
            local pgui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pgui then
                for _, k in ipairs(pgui:GetChildren()) do
                    line(k.ClassName .. " | " .. k.Name)
                end
                local stam = pgui:FindFirstChild("Stamina", true)
                if stam then
                    line("Stamina PATH: " .. stam:GetFullName())
                end
            end
            line("")
            line("== FIM ==")
        end)
        Mapping = false
        showCopyWindow("MAPA DO JOGO (copie e envie)", table.concat(out, "\n"))
    end)
end

--[[ ============================ MINI UI (NATIVA) ========================== ]]
-- Interface de ~20 instancias para celular fraco ou se o Rayfield falhar.
local MiniGui, MiniStatus, MiniBtns = nil, nil, {}
function updateMiniStatus()
    if MiniStatus and MiniStatus.Parent then
        MiniStatus.Text = diagString()
    end
end

local function miniToggleBtn(parent, y, label, getFn, setFn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 34)
    b.Position = UDim2.new(0, 8, 0, y)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    local function refresh()
        if getFn() then
            b.Text = label .. ": ON"
            b.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
        else
            b.Text = label .. ": OFF"
            b.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        end
    end
    b.MouseButton1Click:Connect(function()
        setFn(not getFn())
        refresh()
    end)
    refresh()
    b.Parent = parent
    table.insert(MiniBtns, refresh)
    return y + 38
end

local function miniActionBtn(parent, y, label, color, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -16, 0, 34)
    b.Position = UDim2.new(0, 8, 0, y)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 14
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.BackgroundColor3 = color
    b.Text = label
    b.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    b.MouseButton1Click:Connect(function()
        task.spawn(fn)
    end)
    b.Parent = parent
    return y + 38
end

local function setTopGlobal(v)
    Config.TopGlobal = v
    if v then
        Config.AutoShoot = true
        Config.AutoDribble = true
        Config.AutoTackle = true
        Config.AutoBicycle = true
        Config.AutoHeader = true
        Config.AutoVolley = true
        Config.AutoChip = true
        Config.AutoDive = true
        Config.AutoDefense = true
        Config.AutoPassGK = true
        Config.AutoPunch = true
        Config.AutoPowerShot = true
        Config.AimLock = true
        Config.Accuracy = 99
        for _, r in ipairs(MiniBtns) do
            pcall(r)
        end
        pcall(refreshAutoShootBtn)
        notify("TOP 1 GLOBAL", "99% ATIVADO.", 4)
    else
        Config.Accuracy = 99
        for _, r in ipairs(MiniBtns) do
            pcall(r)
        end
        pcall(refreshAutoShootBtn)
    end
end

local function buildMiniUI()
    if MiniGui and MiniGui.Parent then
        MiniGui.Enabled = true
        return
    end
    local parent = getGuiParent()
    local g = Instance.new("ScreenGui")
    g.Name = "__SnakeMiniV3"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 250, 0, 420)
    frame.Position = UDim2.new(0.5, -125, 0.5, -210)
    frame.BackgroundColor3 = Color3.fromRGB(20, 22, 26)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(0, 10)
    fc.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(0, 255, 130)
    title.Text = "SNAKEHUB V3 MINI"
    title.Parent = frame
    MiniStatus = Instance.new("TextLabel")
    MiniStatus.Size = UDim2.new(1, -16, 0, 108)
    MiniStatus.Position = UDim2.new(0, 8, 0, 30)
    MiniStatus.BackgroundTransparency = 1
    MiniStatus.Font = Enum.Font.Gotham
    MiniStatus.TextSize = 11
    MiniStatus.TextColor3 = Color3.fromRGB(220, 220, 220)
    MiniStatus.TextXAlignment = Enum.TextXAlignment.Left
    MiniStatus.TextYAlignment = Enum.TextYAlignment.Top
    MiniStatus.Text = "carregando..."
    MiniStatus.Parent = frame
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -142)
    scroll.Position = UDim2.new(0, 0, 0, 142)
    scroll.BackgroundTransparency = 1
    scroll.ScrollBarThickness = 4
    scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
    scroll.Parent = frame
    local y = 0
    y = miniToggleBtn(scroll, y, "TOP 1 GLOBAL", function()
        return Config.TopGlobal
    end, setTopGlobal)
    y = miniToggleBtn(scroll, y, "Auto Shoot", function()
        return Config.AutoShoot
    end, function(v)
        Config.AutoShoot = v
        pcall(refreshAutoShootBtn)
    end)
    y = miniToggleBtn(scroll, y, "Auto Drible", function()
        return Config.AutoDribble
    end, function(v)
        Config.AutoDribble = v
    end)
    y = miniToggleBtn(scroll, y, "Auto Tackle", function()
        return Config.AutoTackle
    end, function(v)
        Config.AutoTackle = v
    end)
    y = miniToggleBtn(scroll, y, "Auto Actions", function()
        return Config.AutoBicycle
    end, function(v)
        Config.AutoBicycle = v
        Config.AutoHeader = v
        Config.AutoVolley = v
        Config.AutoChip = v
    end)
    y = miniToggleBtn(scroll, y, "Auto Dive GK", function()
        return Config.AutoDive
    end, function(v)
        Config.AutoDive = v
    end)
    y = miniToggleBtn(scroll, y, "Defesa GK", function()
        return Config.AutoDefense
    end, function(v)
        Config.AutoDefense = v
    end)
    y = miniToggleBtn(scroll, y, "Stamina Inf", function()
        return Config.InfiniteStamina
    end, function(v)
        Config.InfiniteStamina = v
    end)
    y = miniToggleBtn(scroll, y, "ESP Bola", function()
        return Config.BallESP
    end, function(v)
        Config.BallESP = v
        if v then
            ensureBallESP()
        end
    end)
    y = miniToggleBtn(scroll, y, "Teclas Reais", function()
        return Config.VimKeys
    end, function(v)
        Config.VimKeys = v
    end)
    y = miniActionBtn(scroll, y, "CALIBRAR CHUTE", Color3.fromRGB(200, 150, 0), calibrateShoot)
    y = miniActionBtn(scroll, y, "TRAVAR BOLA PERTO", Color3.fromRGB(0, 130, 200), function()
        local b = lockNearBall()
        notify("Mini UI", b and ("Bola travada: " .. b.Name) or "Chegue mais perto da bola.", 3)
    end)
    y = miniActionBtn(scroll, y, "ANTI-LAG ULTRA", Color3.fromRGB(150, 0, 200), function()
        applyAntiLag(2)
    end)
    y = miniActionBtn(scroll, y, "CHUTAR AGORA", Color3.fromRGB(200, 40, 40), function()
        doShoot(100, nil, Config.TopGlobal)
    end)
    y = miniActionBtn(scroll, y, "DIAGNOSTICO", Color3.fromRGB(0, 130, 200), function()
        updateMiniStatus()
        notify("Diagnostico", diagString(), 6)
    end)
    y = miniActionBtn(scroll, y, "MAPEAR JOGO", Color3.fromRGB(0, 150, 150), mapExplorer)
    y = miniActionBtn(scroll, y, "FECHAR (motor continua)", Color3.fromRGB(80, 80, 90), function()
        g.Enabled = false
        setUiVisible(false)
    end)
    g.Parent = parent
    MiniGui = g
    updateMiniStatus()
end

local function switchToMiniUI()
    pcall(function()
        if Rayfield then
            Rayfield:Destroy()
        end
    end)
    Rayfield = nil
    buildMiniUI()
    notify("Mini UI", "Interface leve ativada (reentre p/ voltar a completa).", 4)
end

--[[ ================= INICIALIZACAO DO MOTOR (ANTES DA UI) ================= ]]
-- O motor liga PRIMEIRO: mesmo se a interface falhar, as features funcionam.
initialScan()
buildFloatButtons()

--[[ ======================= CARREGADOR DO RAYFIELD ========================= ]]
local RayfieldSources = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua",
}
for _, url in ipairs(RayfieldSources) do
    local ok = pcall(function()
        local src = game:HttpGet(url)
        Rayfield = loadstring(src)()
    end)
    if ok and Rayfield then
        break
    end
    Rayfield = nil
end

if not Rayfield then
    -- FALLBACK: Mini UI nativa (leve e garantida)
    buildMiniUI()
    notify("SnakeHub V3", "Rayfield bloqueado: usando MINI UI leve.", 5)
else
    -- Cada aba em pcall: uma falha nao derruba as outras
    local Window = nil
    local okWin, errWin = pcall(function()
        Window = Rayfield:CreateWindow({
            Name = "SNAKEHUB V3 LITE | Realistic Street Soccer",
            LoadingTitle = "SNAKEHUB V3 LITE...",
            LoadingSubtitle = IS_MOBILE and "Modo: Mobile Leve" or "Modo: PC Leve",
            ConfigurationSaving = { Enabled = false },
            Discord = { Enabled = false },
            KeySystem = false,
            Theme = "Green",
        })
    end)
    if not okWin or not Window then
        Rayfield = nil
        buildMiniUI()
        notify("SnakeHub V3", "Falha na UI completa: usando MINI UI.", 5)
    else
        local Tabs = {}
        pcall(function()
            Tabs.Home = Window:CreateTab("Inicio", 4483362458)
            Tabs.Shoot = Window:CreateTab("Auto Shoot", 4483362458)
            Tabs.Drib = Window:CreateTab("Auto Drible", 4483362458)
            Tabs.Tack = Window:CreateTab("Auto Tackle", 4483362458)
            Tabs.Acts = Window:CreateTab("Auto Actions", 4483362458)
            Tabs.GK = Window:CreateTab("Goleiro GK", 4483362458)
            Tabs.Top = Window:CreateTab("Top 1 Global", 4483362458)
            Tabs.Unlock = Window:CreateTab("Unlock All", 4483362458)
            Tabs.Match = Window:CreateTab("Partida", 4483362458)
            Tabs.Set = Window:CreateTab("Ajustes", 4483362458)
        end)

        -- ABA 1: INICIO ------------------------------------------------
        pcall(function()
            local T = Tabs.Home
            if not T then
                return
            end
            T:CreateSection("Diagnostico (comece aqui)")
            T:CreateParagraph({
                Title = "Status ao vivo",
                Content = "Aperte DIAGNOSTICO para ver bola, remotes, teclas e FPS."
            })
            T:CreateButton({
                Name = "DIAGNOSTICO COMPLETO",
                Callback = function()
                    local s = diagString()
                    notify("Diagnostico", s, 7)
                end,
            })
            T:CreateButton({
                Name = "TRAVAR BOLA (fique perto dela)",
                Callback = function()
                    local b = lockNearBall()
                    notify("Bola", b and ("Travada: " .. b.Name) or "Chegue mais perto da bola.", 3)
                end,
            })
            T:CreateButton({
                Name = "RE-ESCANEAR CAMPO (bola + gols)",
                Callback = function()
                    GoalsList = {}
                    BallPart = nil
                    ManualBallLock = nil
                    task.spawn(initialScan)
                    notify("Campo", "Escaneando bola e gols...", 2)
                end,
            })
            T:CreateButton({
                Name = "MAPEAR EXPLORER DO JOGO",
                Callback = mapExplorer,
            })
            T:CreateSection("Ativacao rapida")
            T:CreateButton({
                Name = "ATIVAR MODO TOP 1 GLOBAL (99%)",
                Callback = function()
                    setTopGlobal(true)
                end,
            })
            T:CreateButton({
                Name = "PARAR TUDO (panico)",
                Callback = function()
                    setTopGlobal(false)
                    Config.AutoShoot = false
                    Config.AutoDribble = false
                    Config.AutoTackle = false
                    Config.AutoBicycle = false
                    Config.AutoHeader = false
                    Config.AutoVolley = false
                    Config.AutoChip = false
                    Config.AutoDive = false
                    Config.AutoDefense = false
                    Config.AutoPassGK = false
                    Config.AutoPunch = false
                    Config.AutoPowerShot = false
                    Config.AutoFaceoff = false
                    Config.AutoPenalty = false
                    pcall(refreshAutoShootBtn)
                    notify("SnakeHub", "Tudo desligado.", 3)
                end,
            })
            T:CreateToggle({
                Name = "Anti-AFK",
                CurrentValue = true,
                Flag = "H_AFK3",
                Callback = function(v)
                    Config.AntiAFK = v
                end,
            })
            T:CreateButton({
                Name = "TROCAR DE SERVIDOR",
                Callback = function()
                    task.spawn(function()
                        local ok = pcall(function()
                            local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
                            local res = game:HttpGet(url)
                            local data = HttpService:JSONDecode(res)
                            for _, s in ipairs(data.data) do
                                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                                    return
                                end
                            end
                            notify("Server Hop", "Nenhum servidor livre.", 3)
                        end)
                        if not ok then
                            notify("Server Hop", "Falha ao trocar.", 3)
                        end
                    end)
                end,
            })
        end)

        -- ABA 2: AUTO SHOOT --------------------------------------------
        pcall(function()
            local T = Tabs.Shoot
            if not T then
                return
            end
            T:CreateSection("Calibracao (faca 1 vez)")
            T:CreateParagraph({
                Title = "Por que calibrar?",
                Content = "A calibracao descobre o formato exato de chute do servidor. Fique PARADO com a bola no pe e aperte o botao."
            })
            T:CreateButton({
                Name = "CALIBRAR CHUTE AGORA",
                Callback = calibrateShoot,
            })
            T:CreateDropdown({
                Name = "Metodo de chute",
                Options = { "Auto", "Remote", "Tecla Real (VIM)" },
                CurrentOption = "Auto",
                Flag = "S_Method3",
                Callback = function(opt)
                    Config.ShootMethod = normOpt(opt, "Auto")
                end,
            })
            T:CreateSection("Chute automatico")
            T:CreateToggle({
                Name = "AUTO SHOOT (99%)",
                CurrentValue = false,
                Flag = "S_Auto3",
                Callback = function(v)
                    Config.AutoShoot = v
                    pcall(refreshAutoShootBtn)
                end,
            })
            T:CreateButton({
                Name = "CHUTAR AGORA (forca max)",
                Callback = function()
                    local ok, reason = doShoot(100, nil, Config.TopGlobal)
                    if not ok and reason == "sem-bola" then
                        notify("Shoot", "Chegue perto da bola.", 2)
                    elseif not ok and reason == "longe" then
                        notify("Shoot", "Aumente o alcance.", 2)
                    end
                end,
            })
            T:CreateToggle({
                Name = "Botao flutuante CHUTE",
                CurrentValue = true,
                Flag = "S_Float3",
                Callback = function(v)
                    Config.FloatShoot = v
                    if ShootBtn then
                        ShootBtn.Visible = v
                    end
                end,
            })
            T:CreateToggle({
                Name = "Botao exclusivo AUTO SHOOT",
                CurrentValue = true,
                Flag = "S_FloatAuto3",
                Callback = function(v)
                    Config.FloatAutoShoot = v
                    pcall(refreshAutoShootBtn)
                end,
            })
            T:CreateDropdown({
                Name = "Local da finalizacao",
                Options = { "Aleatorio PRO", "Gaveta", "Canto Direito", "Canto Esquerdo", "Rasteiro", "Meio" },
                CurrentOption = "Aleatorio PRO",
                Flag = "S_Target3",
                Callback = function(opt)
                    Config.TargetArea = normOpt(opt, "Aleatorio PRO")
                end,
            })
            T:CreateSlider({
                Name = "Alcance do chute",
                Range = { 20, 300 },
                Increment = 5,
                Suffix = " studs",
                CurrentValue = 260,
                Flag = "S_Dist3",
                Callback = function(v)
                    Config.ShootDist = v
                end,
            })
            T:CreateSlider({
                Name = "Forca do chute",
                Range = { 50, 100 },
                Increment = 1,
                Suffix = "%",
                CurrentValue = 100,
                Flag = "S_Power3",
                Callback = function(v)
                    Config.Power = v
                end,
            })
            T:CreateToggle({
                Name = "Curvado/normal aleatorio",
                CurrentValue = true,
                Flag = "S_Rand3",
                Callback = function(v)
                    Config.RandomCurve = v
                end,
            })
            T:CreateToggle({
                Name = "Mira travada no gol",
                CurrentValue = true,
                Flag = "S_Aim3",
                Callback = function(v)
                    Config.AimLock = v
                end,
            })
            T:CreateToggle({
                Name = "Tecla de chute (PC)",
                CurrentValue = true,
                Flag = "S_Key3",
                Callback = function(v)
                    Config.ShootKeyEnabled = v
                end,
            })
            T:CreateSection("Power Shot")
            T:CreateToggle({
                Name = "Power Shot automatico",
                CurrentValue = false,
                Flag = "S_PAuto3",
                Callback = function(v)
                    Config.AutoPowerShot = v
                end,
            })
            T:CreateButton({
                Name = "POWER SHOT AGORA",
                Callback = function()
                    local ok, reason = doPowerShot()
                    if not ok and reason == "recarga" then
                        notify("Power Shot", "Em recarga.", 2)
                    elseif not ok then
                        notify("Power Shot", "Sem bola no pe.", 2)
                    end
                end,
            })
        end)

        -- ABA 3: DRIBLE ------------------------------------------------
        pcall(function()
            local T = Tabs.Drib
            if not T then
                return
            end
            T:CreateSection("Drible perfeito")
            T:CreateParagraph({
                Title = "Metodo V3",
                Content = "Aperta a tecla REAL Q do jogo + remote junto. Funciona em PC e mobile."
            })
            T:CreateToggle({
                Name = "AUTO DRIBLE",
                CurrentValue = false,
                Flag = "D_Auto3",
                Callback = function(v)
                    Config.AutoDribble = v
                    if v and (not VIM_OK) then
                        notify("Drible", "Sem teclas reais: usando so remote.", 3)
                    end
                end,
            })
            T:CreateButton({
                Name = "DRIBLAR AGORA (testar)",
                Callback = function()
                    if doDribble() then
                        notify("Drible", "Drible disparado!", 2)
                    else
                        notify("Drible", "Precisa da bola no pe.", 2)
                    end
                end,
            })
            T:CreateSlider({
                Name = "Distancia de reacao",
                Range = { 6, 20 },
                Increment = 1,
                Suffix = " x0.5",
                CurrentValue = 11,
                Flag = "D_Dist3",
                Callback = function(v)
                    Config.DribbleDist = v * 0.5
                end,
            })
            T:CreateDropdown({
                Name = "Estilo",
                Options = { "Perfeito PRO", "Sombra (seguro)", "Agressivo" },
                CurrentOption = "Perfeito PRO",
                Flag = "D_Style3",
                Callback = function(opt)
                    Config.DribbleStyle = normOpt(opt, "Perfeito PRO")
                end,
            })
        end)

        -- ABA 4: TACKLE ------------------------------------------------
        pcall(function()
            local T = Tabs.Tack
            if not T then
                return
            end
            T:CreateSection("Bote perfeito")
            T:CreateParagraph({
                Title = "Metodo V3",
                Content = "Aperta a tecla REAL E do jogo + remote junto. Bote limpo sem falta."
            })
            T:CreateToggle({
                Name = "AUTO TACKLE",
                CurrentValue = false,
                Flag = "T_Auto3",
                Callback = function(v)
                    Config.AutoTackle = v
                end,
            })
            T:CreateButton({
                Name = "DAR O BOTE AGORA (testar)",
                Callback = function()
                    local enemy = getEnemyWithBall(9)
                    if doTackle(enemy) then
                        notify("Tackle", "Bote disparado!", 2)
                    else
                        notify("Tackle", "Ninguem ao alcance.", 2)
                    end
                end,
            })
            T:CreateSlider({
                Name = "Distancia do bote",
                Range = { 3, 9 },
                Increment = 1,
                Suffix = " studs",
                CurrentValue = 6,
                Flag = "T_Dist3",
                Callback = function(v)
                    Config.TackleDist = v
                end,
            })
            T:CreateToggle({
                Name = "Anti-falta legitimo",
                CurrentValue = true,
                Flag = "T_Legit3",
                Callback = function(v)
                    Config.LegitTackle = v
                end,
            })
            T:CreateToggle({
                Name = "Intercepta passes",
                CurrentValue = true,
                Flag = "T_Inter3",
                Callback = function(v)
                    Config.InterceptPro = v
                end,
            })
        end)

        -- ABA 5: ACTIONS ------------------------------------------------
        pcall(function()
            local T = Tabs.Acts
            if not T then
                return
            end
            T:CreateSection("Acrobacias automaticas")
            T:CreateToggle({
                Name = "Auto BICICLETA",
                CurrentValue = false,
                Flag = "A_Bike3",
                Callback = function(v)
                    Config.AutoBicycle = v
                end,
            })
            T:CreateToggle({
                Name = "Auto CABECEIO",
                CurrentValue = false,
                Flag = "A_Head3",
                Callback = function(v)
                    Config.AutoHeader = v
                end,
            })
            T:CreateToggle({
                Name = "Auto VOLEIO",
                CurrentValue = false,
                Flag = "A_Volley3",
                Callback = function(v)
                    Config.AutoVolley = v
                end,
            })
            T:CreateToggle({
                Name = "Auto CAVADINHA",
                CurrentValue = false,
                Flag = "A_Chip3",
                Callback = function(v)
                    Config.AutoChip = v
                end,
            })
            T:CreateToggle({
                Name = "Cabecear pro gol",
                CurrentValue = true,
                Flag = "A_HS3",
                Callback = function(v)
                    Config.HeaderShoot = v
                end,
            })
            T:CreateSection("Testar agora")
            T:CreateButton({
                Name = "BICICLETA AGORA",
                Callback = function()
                    if not doBicycle() then
                        notify("Actions", "Precisa da bola alta e perto.", 2)
                    end
                end,
            })
            T:CreateButton({
                Name = "CABECEIO AGORA",
                Callback = function()
                    if not doHeader() then
                        notify("Actions", "Precisa da bola alta e perto.", 2)
                    end
                end,
            })
            T:CreateButton({
                Name = "PULAR AGORA (testar pulo)",
                Callback = function()
                    doJump()
                end,
            })
        end)

        -- ABA 6: GK ------------------------------------------------------
        pcall(function()
            local T = Tabs.GK
            if not T then
                return
            end
            T:CreateSection("Goleiro automatico")
            T:CreateParagraph({
                Title = "Metodo V3",
                Content = "Aperta a tecla REAL X do jogo (mergulho) + remote junto."
            })
            T:CreateDropdown({
                Name = "Voce e o goleiro?",
                Options = { "Automatico", "Sou GK", "Nao sou GK" },
                CurrentOption = "Automatico",
                Flag = "G_Mode3",
                Callback = function(opt)
                    Config.GKMode = normOpt(opt, "Automatico")
                end,
            })
            T:CreateToggle({
                Name = "AUTO DIVE",
                CurrentValue = false,
                Flag = "G_Dive3",
                Callback = function(v)
                    Config.AutoDive = v
                end,
            })
            T:CreateToggle({
                Name = "AUTO DEFESA OP",
                CurrentValue = false,
                Flag = "G_Def3",
                Callback = function(v)
                    Config.AutoDefense = v
                end,
            })
            T:CreateToggle({
                Name = "AUTO PASSE (so GK)",
                CurrentValue = false,
                Flag = "G_Pass3",
                Callback = function(v)
                    Config.AutoPassGK = v
                end,
            })
            T:CreateToggle({
                Name = "AUTO SOCO",
                CurrentValue = false,
                Flag = "G_Punch3",
                Callback = function(v)
                    Config.AutoPunch = v
                end,
            })
            T:CreateSlider({
                Name = "Alcance de reacao",
                Range = { 15, 60 },
                Increment = 1,
                Suffix = " studs",
                CurrentValue = 40,
                Flag = "G_Range3",
                Callback = function(v)
                    Config.GKRange = v
                end,
            })
            T:CreateSection("Manual")
            T:CreateButton({
                Name = "MERGULHAR AGORA (testar)",
                Callback = function()
                    doDive()
                end,
            })
            T:CreateButton({
                Name = "EXPANDIR ALCANCE DAS MAOS",
                Callback = function()
                    if Remotes.GKHitbox then
                        fire(Remotes.GKHitbox, Vector3.new(9999, 9999, 9999))
                        notify("GK", "Alcance expandido!", 2)
                    else
                        notify("GK", "Remote GK nao encontrado.", 2)
                    end
                end,
            })
            T:CreateButton({
                Name = "IR PARA O MEU GOL",
                Callback = function()
                    local _, hrp = myChar()
                    local own = getOwnGoal()
                    if hrp and own then
                        pcall(function()
                            hrp.CFrame = CFrame.new(own + Vector3.new(0, 3, 0))
                            hrp.Velocity = Vector3.new(0, 0, 0)
                        end)
                    else
                        notify("GK", "Gol nao localizado.", 2)
                    end
                end,
            })
        end)

        -- ABA 7: TOP GLOBAL ------------------------------------------------
        pcall(function()
            local T = Tabs.Top
            if not T then
                return
            end
            T:CreateSection("Modo maximo 99%")
            T:CreateToggle({
                Name = "TOP 1 GLOBAL (99%)",
                CurrentValue = false,
                Flag = "Top_Master3",
                Callback = setTopGlobal,
            })
            T:CreateDropdown({
                Name = "Estilo de jogo",
                Options = { "Completo", "Atacante", "Meia", "Defensor", "Goleiro" },
                CurrentOption = "Completo",
                Flag = "Top_Style3",
                Callback = function(opt)
                    Config.TopStyle = normOpt(opt, "Completo")
                end,
            })
            T:CreateButton({
                Name = "APLICAR PRESET",
                Callback = function()
                    local s = Config.TopStyle
                    if s == "Atacante" then
                        Config.ShootDist = 280
                        Config.Power = 100
                        Config.DribbleDist = 6
                        Config.TackleDist = 5
                    elseif s == "Meia" then
                        Config.ShootDist = 200
                        Config.DribbleDist = 6
                        Config.TackleDist = 6
                    elseif s == "Defensor" then
                        Config.ShootDist = 120
                        Config.TackleDist = 7
                    elseif s == "Goleiro" then
                        Config.GKMode = "Sou GK"
                        Config.GKRange = 50
                        Config.AutoDive = true
                        Config.AutoDefense = true
                        Config.AutoPassGK = true
                        Config.AutoPunch = true
                    else
                        Config.ShootDist = 260
                        Config.Power = 100
                        Config.DribbleDist = 5.5
                        Config.TackleDist = 6
                        Config.GKRange = 40
                    end
                    notify("Top", "Preset " .. s .. " aplicado.", 3)
                end,
            })
            T:CreateToggle({
                Name = "Movimento PRO",
                CurrentValue = true,
                Flag = "Top_Move3",
                Callback = function(v)
                    Config.ProMovement = v
                end,
            })
            T:CreateToggle({
                Name = "Espelho de movimento",
                CurrentValue = true,
                Flag = "Top_Mirror3",
                Callback = function(v)
                    Config.MoveMirror = v
                end,
            })
            T:CreateSlider({
                Name = "Forca da mira",
                Range = { 0, 100 },
                Increment = 5,
                Suffix = "%",
                CurrentValue = 65,
                Flag = "Top_Steer3",
                Callback = function(v)
                    Config.SteerAssist = v
                end,
            })
            T:CreateToggle({
                Name = "Piloto automatico",
                CurrentValue = false,
                Flag = "Top_Full3",
                Callback = function(v)
                    Config.FullAuto = v
                end,
            })
        end)

        -- ABA 8: UNLOCK ------------------------------------------------------
        pcall(function()
            local T = Tabs.Unlock
            if not T then
                return
            end
            T:CreateSection("Desbloqueio")
            T:CreateButton({
                Name = "DESBLOQUEAR TUDO",
                Callback = function()
                    task.spawn(function()
                        local spinners = { Remotes.SpinCards, Remotes.SpinDrib, Remotes.SpinGoalie, Remotes.SpinShoes }
                        for _, sp in ipairs(spinners) do
                            if sp then
                                local rf = sp:FindFirstChild("RemoteFunction")
                                if rf then
                                    invoke(rf, "GetAll")
                                    task.wait(0.1)
                                    invoke(rf, "UnlockAll")
                                    task.wait(0.1)
                                else
                                    pcall(function()
                                        sp:InvokeServer("UnlockAll")
                                    end)
                                    task.wait(0.1)
                                end
                            end
                        end
                        fire(Remotes.Equip, "UnlockAll")
                        fire(Remotes.Avatar, "UnlockAll")
                        fire(Remotes.Jersey, "UnlockAll")
                        notify("Unlock", "Executado! Confira o inventario.", 4)
                    end)
                end,
            })
            T:CreateButton({
                Name = "TENTAR GAMEPASSES",
                Callback = function()
                    task.spawn(function()
                        fire(Remotes.Equip, "GamepassAll")
                        task.wait(0.15)
                        fire(Remotes.SettingsR, "UnlockAll")
                        task.wait(0.15)
                        fire(Remotes.ShopEvent, "UnlockAll")
                        notify("Unlock", "Tentativa enviada.", 3)
                    end)
                end,
            })
            T:CreateButton({
                Name = "RESGATAR COPA DO MUNDO",
                Callback = function()
                    task.spawn(function()
                        if Remotes.WorldCup then
                            invoke(Remotes.WorldCup)
                            task.wait(0.2)
                        end
                        if Remotes.RedeemWC then
                            for i = 1, 10 do
                                invoke(Remotes.RedeemWC, i)
                                task.wait(0.12)
                            end
                        end
                        notify("Unlock", "Copa resgatada.", 3)
                    end)
                end,
            })
            T:CreateButton({
                Name = "RESGATAR DIARIAS + QUESTS",
                Callback = function()
                    task.spawn(function()
                        fire(Remotes.Daily)
                        task.wait(0.12)
                        fire(Remotes.DailyEv, "ClaimAll")
                        task.wait(0.12)
                        fire(Remotes.WQuest, "ClaimAll")
                        notify("Unlock", "Diarias e quests ok.", 3)
                    end)
                end,
            })
            T:CreateButton({
                Name = "RESGATAR CODIGOS",
                Callback = function()
                    task.spawn(function()
                        local codes = { "RELEASE", "SOCCER", "STREET", "GOAL", "FOOTBALL", "RSS",
                            "UPDATE", "WELCOME", "100K", "500K", "1M", "POWER", "SKILL",
                            "TOP1", "BRAZIL", "SUMMER", "WINTER", "HALLOWEEN", "EASTER" }
                        local n = 0
                        for _, code in ipairs(codes) do
                            if Remotes.RedeemCode then
                                local ok = invoke(Remotes.RedeemCode, code)
                                if ok then
                                    n = n + 1
                                end
                            end
                            task.wait(0.18)
                        end
                        notify("Unlock", n .. " codigos aceitos.", 3)
                    end)
                end,
            })
            T:CreateButton({
                Name = "COLETAR ITENS DO MAPA",
                Callback = function()
                    task.spawn(function()
                        fire(Remotes.ClaimStick)
                        task.wait(0.1)
                        fire(Remotes.Collect)
                        task.wait(0.1)
                        fire(Remotes.TCellLoc)
                        task.wait(0.1)
                        fire(Remotes.Unbox)
                        notify("Unlock", "Coleta enviada.", 3)
                    end)
                end,
            })
        end)

        -- ABA 9: PARTIDA -------------------------------------------------------
        pcall(function()
            local T = Tabs.Match
            if not T then
                return
            end
            T:CreateSection("Fisico e camera")
            T:CreateToggle({
                Name = "Stamina infinita",
                CurrentValue = false,
                Flag = "M_Stam3",
                Callback = function(v)
                    Config.InfiniteStamina = v
                end,
            })
            T:CreateToggle({
                Name = "Velocidade personalizada",
                CurrentValue = false,
                Flag = "M_WalkT3",
                Callback = function(v)
                    Config.WalkEnabled = v
                    if not v then
                        local _, _, hum = myChar()
                        if hum then
                            pcall(function()
                                hum.WalkSpeed = 16
                            end)
                        end
                    end
                end,
            })
            T:CreateSlider({
                Name = "Velocidade",
                Range = { 16, 40 },
                Increment = 1,
                Suffix = " ws",
                CurrentValue = 22,
                Flag = "M_Walk3",
                Callback = function(v)
                    Config.WalkSpeed = v
                end,
            })
            T:CreateToggle({
                Name = "Sem tremor de camera",
                CurrentValue = false,
                Flag = "M_Shake3",
                Callback = function(v)
                    Config.NoShake = v
                end,
            })
            T:CreateToggle({
                Name = "Pular comemoracao",
                CurrentValue = false,
                Flag = "M_Cut3",
                Callback = function(v)
                    Config.SkipCutscene = v
                end,
            })
            T:CreateSection("Automacoes")
            T:CreateToggle({
                Name = "Auto Faceoff",
                CurrentValue = false,
                Flag = "M_Face3",
                Callback = function(v)
                    Config.AutoFaceoff = v
                end,
            })
            T:CreateToggle({
                Name = "Auto Penalti",
                CurrentValue = false,
                Flag = "M_Pen3",
                Callback = function(v)
                    Config.AutoPenalty = v
                end,
            })
            T:CreateToggle({
                Name = "Auto coletar itens",
                CurrentValue = false,
                Flag = "M_Coll3",
                Callback = function(v)
                    Config.AutoCollect = v
                end,
            })
            T:CreateButton({
                Name = "PENALTI ESQUERDA",
                Callback = function()
                    fire(Remotes.Penalty, "Left")
                end,
            })
            T:CreateButton({
                Name = "PENALTI DIREITA",
                Callback = function()
                    fire(Remotes.Penalty, "Right")
                end,
            })
            T:CreateSection("Time")
            T:CreateButton({
                Name = "AUTO TIME",
                Callback = function()
                    task.spawn(function()
                        local counts = {}
                        for _, plr in ipairs(PlayerCache) do
                            local t = plr.Team and plr.Team.Name or "SemTime"
                            counts[t] = (counts[t] or 0) + 1
                        end
                        local bestTeam, bestCount = nil, math.huge
                        for name, c in pairs(counts) do
                            if name ~= "SemTime" and c < bestCount then
                                bestCount = c
                                bestTeam = name
                            end
                        end
                        if bestTeam and Remotes.TeamChange then
                            fire(Remotes.TeamChange, bestTeam)
                            notify("Partida", "Time: " .. bestTeam, 3)
                        elseif Remotes.TeamChange then
                            fire(Remotes.TeamChange, 1)
                            notify("Partida", "Time solicitado.", 2)
                        end
                    end)
                end,
            })
            T:CreateButton({
                Name = "VIRAR GOLEIRO",
                Callback = function()
                    fire(Remotes.Position, "GK")
                    task.wait(0.15)
                    fire(Remotes.Position, "Goalkeeper")
                    Config.GKMode = "Sou GK"
                    notify("Partida", "GK solicitado.", 3)
                end,
            })
            T:CreateSection("Teleportes")
            local function tpTo(pos, label)
                local _, hrp = myChar()
                if hrp and pos then
                    pcall(function()
                        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    end)
                else
                    notify("TP", "Destino: " .. (label or "?") .. " indisponivel.", 2)
                end
            end
            -- (TP na bola removido: sem teleporte na bola)
            T:CreateButton({
                Name = "TP: MEIO",
                Callback = function()
                    tpTo(Vector3.new(0, 5, 0), "meio")
                end,
            })
            T:CreateButton({
                Name = "TP: GOL ADVERSARIO",
                Callback = function()
                    tpTo(getAttackGoal(), "ataque")
                end,
            })
            T:CreateButton({
                Name = "TP: MEU GOL",
                Callback = function()
                    tpTo(getOwnGoal(), "defesa")
                end,
            })
            T:CreateSection("ESP")
            T:CreateToggle({
                Name = "ESP BOLA",
                CurrentValue = false,
                Flag = "M_EspB3",
                Callback = function(v)
                    Config.BallESP = v
                    if v then
                        ensureBallESP()
                    end
                end,
            })
            T:CreateToggle({
                Name = "ESP GOLS",
                CurrentValue = false,
                Flag = "M_EspG3",
                Callback = function(v)
                    Config.GoalESP = v
                    if v then
                        refreshGoalESP()
                    end
                end,
            })
            T:CreateToggle({
                Name = "ESP JOGADORES",
                CurrentValue = false,
                Flag = "M_EspP3",
                Callback = function(v)
                    Config.PlayerESP = v
                    if not v then
                        clearPlayerESP()
                    end
                end,
            })
        end)

        -- ABA 10: AJUSTES + ANTI-LAG -------------------------------------
        pcall(function()
            local T = Tabs.Set
            if not T then
                return
            end
            T:CreateSection("ANTI-LAG (celular fraco)")
            T:CreateParagraph({
                Title = "FPS atual: veja no Diagnostico",
                Content = "Aba Inicio > DIAGNOSTICO mostra seu FPS. Se travar, use os botoes abaixo."
            })
            T:CreateButton({
                Name = "MODO ITEL A70 (tudo leve 1 toque)",
                Callback = function()
                    applyAntiLag(2)
                    applyPotatoMode(true)
                    switchToMiniUI()
                    if SnakeBtn then
                        SnakeBtn.Visible = true
                    end
                    notify("A70", "Modo ultra leve ativado!", 4)
                end,
            })
            T:CreateButton({
                Name = "ANTI-LAG ULTRA",
                Callback = function()
                    applyAntiLag(2)
                end,
            })
            T:CreateButton({
                Name = "ANTI-LAG LEVE",
                Callback = function()
                    applyAntiLag(1)
                end,
            })
            T:CreateToggle({
                Name = "Modo Batata (max FPS)",
                CurrentValue = false,
                Flag = "S_Potato3",
                Callback = function(v)
                    applyPotatoMode(v)
                end,
            })
            T:CreateToggle({
                Name = "Sem chapeus/roupas (outros)",
                CurrentValue = false,
                Flag = "S_Hats3",
                Callback = function(v)
                    applyNoHats(v)
                end,
            })
            T:CreateToggle({
                Name = "FPS adaptativo (auto)",
                CurrentValue = true,
                Flag = "S_Adapt3",
                Callback = function(v)
                    Config.AdaptiveHz = v
                end,
            })
            T:CreateSlider({
                Name = "Velocidade do motor",
                Range = { 6, 20 },
                Increment = 1,
                Suffix = " Hz",
                CurrentValue = 12,
                Flag = "S_Hz3",
                Callback = function(v)
                    Config.CombatHz = v
                    TickInterval = 1 / v
                end,
            })
            T:CreateSection("Metodo de disparo")
            T:CreateToggle({
                Name = "Teclas reais (VIM)",
                CurrentValue = true,
                Flag = "S_Vim3",
                Callback = function(v)
                    Config.VimKeys = v
                    if v and (not VIM_OK) then
                        notify("VIM", "Seu executor bloqueou teclas reais.", 4)
                    end
                end,
            })
            T:CreateToggle({
                Name = "Disparo duplo (tecla+remote)",
                CurrentValue = true,
                Flag = "S_Dbl3",
                Callback = function(v)
                    Config.DoubleFire = v
                end,
            })
            T:CreateToggle({
                Name = "Modo compativel",
                CurrentValue = true,
                Flag = "S_Compat3",
                Callback = function(v)
                    Config.CompatMode = v
                end,
            })
            T:CreateSection("Interface")
            T:CreateButton({
                Name = "USAR MINI UI (super leve)",
                Callback = switchToMiniUI,
            })
            T:CreateButton({
                Name = "ESCONDER UI (motor continua)",
                Callback = function()
                    setUiVisible(false)
                    notify("UI", "Use o botao S para reabrir.", 3)
                end,
            })
            T:CreateDropdown({
                Name = "Tecla do menu (PC)",
                Options = { "RightShift", "LeftControl", "F8", "F9", "M", "P", "Insert" },
                CurrentOption = "RightShift",
                Flag = "S_UIKey3",
                Callback = function(opt)
                    Config.UIKey = normOpt(opt, "RightShift")
                end,
            })
            T:CreateDropdown({
                Name = "Tecla do chute (PC)",
                Options = { "G", "H", "J", "K", "L", "T", "Y", "U", "V", "B", "N" },
                CurrentOption = "G",
                Flag = "S_SKey3",
                Callback = function(opt)
                    Config.ShootKey = normOpt(opt, "G")
                end,
            })
            T:CreateToggle({
                Name = "Botao flutuante menu (S)",
                CurrentValue = true,
                Flag = "S_FUI3",
                Callback = function(v)
                    Config.FloatUI = v
                    if SnakeBtn then
                        SnakeBtn.Visible = v
                    end
                end,
            })
            T:CreateToggle({
                Name = "Botao flutuante chute",
                CurrentValue = true,
                Flag = "S_FS3",
                Callback = function(v)
                    Config.FloatShoot = v
                    if ShootBtn then
                        ShootBtn.Visible = v
                    end
                end,
            })
            T:CreateToggle({
                Name = "Notificacoes",
                CurrentValue = true,
                Flag = "S_Notif3",
                Callback = function(v)
                    Config.NotifyUI = v
                end,
            })
            T:CreateSection("Sistema")
            T:CreateButton({
                Name = "DESLIGAR SNAKEHUB",
                Callback = function()
                    task.spawn(function()
                        Running = false
                        setTopGlobal(false)
                        pcall(clearESP)
                        pcall(function()
                            if FloatGui then
                                FloatGui:Destroy()
                            end
                        end)
                        pcall(function()
                            if MiniGui then
                                MiniGui:Destroy()
                            end
                        end)
                        for _, c in ipairs(Connections) do
                            pcall(function()
                                c:Disconnect()
                            end)
                        end
                        ENV.__SNAKEHUB_V3_ENGINE = nil
                        pcall(function()
                            if Rayfield then
                                Rayfield:Destroy()
                            end
                        end)
                    end)
                end,
            })
        end)

        pcall(function()
            Rayfield:LoadConfiguration()
        end)
        notify("SNAKEHUB V3 LITE pronta!",
            IS_MOBILE and "Toque S p/ menu. Faca o DIAGNOSTICO + CALIBRAR CHUTE." or "RightShift p/ menu. Faca DIAGNOSTICO + CALIBRAR CHUTE.", 6)
    end
end
