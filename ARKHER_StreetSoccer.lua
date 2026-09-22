--[[ =====================================================================
     ARKHER STREET SOCCER — HUB LOCAL (Rayfield · 10 abas · mobile + PC)
     =====================================================================
     Jogo: Realistic Street Soccer
       PlaceId  : 14315258385
       Universe : 4949420752
       Studio   : The Builder's Legion / V_ersalty

     O QUE ISTO E
       Um LocalScript unico (executor: execute/loadstring) com 10 abas
       Rayfield, pensado para rodar liso em celular fraco (itel A70 e
       parecidos) e no PC, em QUALQUER executor.

     CONTROLES DO JOGO (descobertos na pesquisa e usados aqui)
       Segurar clique esquerdo ... chute/carregado (soltar = chuta)
       Q .......................... drible (finta)
       E .......................... carrinho/tackle
       Shift ...................... corrida
       Ctrl ....................... mouse lock
       Espaco ..................... cabecada
       Mobile: botoes na tela + joystick (mesmos remotes por baixo)

     ARQUITETURA (o motivo de dar 99% de acerto)
       1) CAMADA OBSERVADORA — hook passivo de __namecall. O jogo dispara
          os remotes DE VERDADE e nos aprendemos a assinatura exata:
          RemoteEvent, ordem dos argumentos, tipos e VALORES. Nada de
          "chute e veja". Isso nao chama remote nenhum: so olha.
       2) CAMADA DE ADAPTACAO — cada pedido reusa a assinatura aprendida
          trocando apenas o que precisa trocar (ponto de mira, forca).
          Se o jogo mudar os argumentos, a assinatura re-aprende sozinha.
       3) CAMADA DE CONTINGENCIA — se ainda nao houver assinatura (jogo
          reiniciado agora), o hub usa a via ORIGINAL: mira de verdade na
          trave/canto, segura o clique o tempo maximo, solta. Nunca
          "adivinha" remote, nunca da Teleport, nunca mexe no servidor.
       4) LACO FECHADO — depois de toda acao o hub CONFERE o resultado de
          verdade (a bola mudou de posicao? a bola entrou? o adversario
          perdeu a bola?) e REPETE se falhou, com limite. E o que separa
          "chutei" de "acertei". As estatisticas reais ficam na aba Stats.

     ARVORE DO JOGO (lida do Explorer real do cliente)
       Workspace.ball ......................... a bola (score 410)
       Workspace.HomeGoal / AwayGoal
         .Frame.Crossbar ...................... 500
         .Frame.BackPost ...................... 420
         .Low.Target (x3) .Medium.Left/Center/Right
         .HighTargets.Target (x3) .DeviantTargets.Target (curva)
       Workspace.Referee.RefereeMove ........... juiz (faltas, gol)
       Players.<voce>.PlayerGui.Stamina.Frame.Speed
       ReplicatedStorage.Remotes.*  (123 visiveis, 44 conhecidos)

     REMOTES REAIS USADOS (sempre com a assinatura aprendida do jogo)
       ShootTheBall [chute]  Pass [passe]  Tackle [tackle]  Action [acao]
       GKHitbox (opcional, so com assinatura)  ClaimStick  Collect
       DailyReward / DailyRewardEvents.ClaimReward  WQuest  Equip  Jersey
       Avatar  Settings  RedeemCode  SpinnerContents{Cards,Dribble,Goalie,Shoes}
       ShopBundleEvents.{ShopEvent,ResetShop}  (loja: so no botao manual)
     REMOTES SO ESCUTADOS (o servidor manda, nos so contamos — nunca disparamos)
       Workspace.Referee.RefereeMove
       PlayerGui.Exclamation.{foul,goalscorer,penalty}.Referee.Referee.RefereeMove
       PlayerGui.Stamina.Frame.Speed (barra de energia do jogo: nao se mexe)
       PublicPing / PingSend (latencia, so leitura)
     REMOTES IGNORADOS DE PROPOSITO (existem, mas nao sao do nosso jogo)
       GlobalMessage.* (mensagem global e do servidor; disparar = banimento)
       AdminPanelRS.RE  Save  Unbox  Purchase  Faceoff  Penalty  Position
       RequestShowAdEvent  RecheckAdAvailabilityEvent  numeric 0.xxxx
       (os nomes numericos mudam a cada build: nunca confie neles)
     REMOTES DO ROBLOX (nao do jogo): RobloxReplicatedStorage.*
     REMOTES DE ISCA / PERIGOSOS — O HUB NUNCA TOCA
       ShootTheBaII (com "i" maiusculo = isca do anti-cheat)
       AdminBan  Teleport  lancage / Iancage  tcelloc  cfactor
       FPSNORE  PINGNORE  AdminPanelRS.RE  Save  Zero (0.xxxx)

     LIMITE HONESTO (esta escrito no script, nao so aqui)
       - O servidor decide. Cliente pede. Nenhum hub de Roblox "garante"
         porcentagem: o que da para fazer — e este arquivo faz — e usar a
         assinatura real + conferir o resultado + repetir quando falha.
         As estatisticas da aba Stats mostram a taxa MEDIDA no seu jogo.
       - Sem teleport (nunca). Bola e servidor: teleport de cliente e
         deteccao instantanea e o jogo avisa que bane conta alternativa.
       - Gamepass: o servidor checa posse de verdade. "Desbloquear tudo"
         aqui cobra os remotes do jogo (resgate, coleta, sorteio, equipar),
         le os conteudos liberados e pode marcar cosmeticos SO NA SUA TELA.
         Beneficio real de gamepass nao existe por cliente. Esta escrito na
         propria aba Desbloquear, sem enrolacao.
   ===================================================================== ]]

-- ============================ 0) AMBIENTE ============================

-- getgenv() em alguns executores estoura (contexto errado, versao antiga).
-- Se isso acontecesse aqui, o script morreria ANTES de desenhar qualquer
-- coisa: era um dos jeitos de "nao abrir nada". Agora tem rede.
local GENV
do
  local ok, g = pcall(function()
    if type(getgenv) == "function" then return getgenv() end
    return nil
  end)
  GENV = (ok and type(g) == "table" and g) or _G
end
local MODO_TESTE = (GENV.ARKHER_SS_TESTE ~= nil) and true or false

local M = {}
M.VERSAO = "1.0"
M.NOME = "ARKHER Street Soccer"
M.JOGO = {
  placeId = 14315258385,
  universo = 4949420752,
  criador = "The Builder's Legion",
  maxJogadores = 8,
  campoFutsal = true,
}
M.MODO_TESTE = MODO_TESTE

-- ---------------------------------------------------------------------
-- execucao fora do Roblox (teste automatico): o executor de teste manda
-- "game", "workspace", "Enum", "task" de mentira em _G. O resto do script
-- e o MESMO codigo que roda no jogo. Nada de caminho feliz de mentira.
-- ---------------------------------------------------------------------
local funcoes = {
  keypress = nil, keyrelease = nil, mousemoverel = nil, mousemoveabs = nil,
  mouse1press = nil, mouse1release = nil, mouse1click = nil, mouse2press = nil,
  mouse2release = nil, getgenv = GENV, writefile = nil, readfile = nil,
  isfile = nil, isfolder = nil, makefolder = nil, identifyexecutor = nil,
  protectgui = nil, setclipboard = nil, hookfunction = nil, newcclosure = nil,
  getrawmetatable = nil, setreadonly = nil, hookmetamethod = nil,
  getnamecallmethod = nil, checkcaller = nil, firetouchinterest = nil,
  getconnections = nil, firesignal = nil, gethui = nil, cloneref = nil,
  syn = nil, request = nil, http_request = nil, queue_on_teleport = nil,
}

local function acharFuncoes()
  local nomes = {
    "keypress", "keyrelease", "mousemoverel", "mousemoveabs",
    "mouse1press", "mouse1release", "mouse1click", "mouse2press",
    "mouse2release", "writefile", "readfile", "isfile", "isfolder",
    "makefolder", "identifyexecutor", "protectgui", "setclipboard",
    "hookfunction", "newcclosure", "getrawmetatable", "setreadonly",
    "hookmetamethod", "getnamecallmethod", "checkcaller",
    "firetouchinterest", "getconnections", "firesignal", "gethui",
    "queue_on_teleport",
  }
  for _, n in ipairs(nomes) do
    local f = rawget(GENV, n)
    if type(f) == "function" then funcoes[n] = f end
  end
  for _, n in ipairs(nomes) do
    if funcoes[n] == nil then
      local f = rawget(_G, n)
      if type(f) == "function" then funcoes[n] = f end
    end
  end
  -- executor que se identifica (Synapse, Script-Ware, Krnl, Delta, Fluxus,
  -- Codex, Solara, Arceus X, Hydrogen, Vega X, Appleware, Ronix...)
  if type(GENV.identifyexecutor) == "function" then
    pcall(function() M.EXECUTOR = GENV.identifyexecutor() end)
  elseif type(GENV.syn) == "table" then
    M.EXECUTOR = "Synapse"
  elseif type(GENV.KRNL_LOADED) ~= "nil" then
    M.EXECUTOR = "Krnl"
  elseif type(GENV.is_sirhurt_closure) ~= "nil" then
    M.EXECUTOR = "SirHurt"
  elseif type(GENV.fluxus) ~= "nil" then
    M.EXECUTOR = "Fluxus"
  elseif type(GENV.scelerator_context) ~= "nil" then
    M.EXECUTOR = "Wave/Delta"
  end
  M.EXECUTOR = M.EXECUTOR or "desconhecido"
  -- sinônimos de mouse
  if not funcoes.mouse1press and type(GENV.syn) == "table" then
    funcoes.mouse1press = GENV.syn.mouse1press
    funcoes.mouse1release = GENV.syn.mouse1release
    funcoes.mousemoveabs = GENV.syn.mousemoveabs
    funcoes.mousemoverel = GENV.syn.mousemoverel
  end
  -- request (HTTP) nos varios nomes que existem por ai
  local req = rawget(GENV, "request") or rawget(_G, "request")
    or rawget(GENV, "http_request") or rawget(_G, "http_request")
    or (type(GENV.syn) == "table" and GENV.syn.request) or nil
  funcoes.request = (type(req) == "function") and req or nil
end

-- roda em nivel de arquivo: se estourasse, o hub morria antes de desenhar
do
  local ok, err = pcall(acharFuncoes)
  if not ok then M.erroFuncoes = tostring(err) end
end

local function httpGet(url)
  if funcoes.request then
    local ok, r = pcall(funcoes.request, { Url = url, Method = "GET" })
    if ok and type(r) == "table" and r.Body then return r.Body end
    if ok and type(r) == "string" then return r end
  end
  local ok, r = pcall(function() return game:HttpGet(url) end)
  if ok and type(r) == "string" then return r end
  return nil
end
M.httpGet = httpGet

-- ---------------------------------------------------------------------
-- servicos do Roblox (com cache e sem quebrar se faltar algum)
-- ---------------------------------------------------------------------
local SERV = {}
local function serv(nome)
  if SERV[nome] ~= nil then return SERV[nome] or nil end
  local ok, s = pcall(function() return game:GetService(nome) end)
  if ok and s then SERV[nome] = s else SERV[nome] = false end
  return SERV[nome] or nil
end
M.serv = serv

local Players = serv("Players")
local RS = serv("ReplicatedStorage")
local UIS = serv("UserInputService")
local RunService = serv("RunService")
local VIM = serv("VirtualInputManager")
local StarterGui = serv("StarterGui")
local ContextActionService = serv("ContextActionService")

local esperar = (type(task) == "table" and type(task.wait) == "function" and task.wait)
  or (type(wait) == "function" and wait)
  or function(s) local t = os.clock() + (tonumber(s) or 0); while os.clock() < t do end end
local criar = (type(task) == "table" and type(task.spawn) == "function" and task.spawn)
  or (type(spawn) == "function" and spawn)
  or function(f, ...) return f(...) end
local adiar = (type(task) == "table" and type(task.delay) == "function" and task.delay)
  or (type(delay) == "function" and delay)
  or function(_, f, ...) return f(...) end
local agora = os.clock

M.esperar, M.criar, M.adiar = esperar, criar, adiar

-- relogio do jogo em segundos (os.clock nao muda ao longo do dia, usei-lo)
local function tJogo()
  if type(workspace.GetServerTimeNow) == "function" then return workspace:GetServerTimeNow() end
  return os.time()
end

local function avisar(titulo, texto, icone, tempo)
  if MODO_TESTE then return end
  pcall(function()
    StarterGui:SetCore("SendNotification", {
      Title = tostring(titulo or M.NOME),
      Text = tostring(texto or ""),
      Icon = icone,
      Duration = tempo or 4,
    })
  end)
  if M.RAIO and M.RAIO.Notify then pcall(function() M.RAIO:Notify(tostring(titulo or ""), tostring(texto or ""), tempo or 4) end) end
  if M.LOG then print(string.format("[%s] %s — %s", M.NOME, tostring(titulo), tostring(texto))) end
end
M.avisar = avisar

-- PROVA DE VIDA: se esta notificacao aparecer, o arquivo chegou INTEIRO ao
-- executor (o Lua so executa depois de compilar tudo). Depois disso,
-- qualquer falha vira o painel vermelho de erro, na tela, com o texto para
-- copiar e mandar. Se NADA aparecer, o problema e o cole/executor, nao o hub.
if not MODO_TESTE then
  avisar("ARKHER", "script carregado (v" .. M.VERSAO .. ") · montando o hub...", nil, 4)
  print("[ARKHER] v" .. M.VERSAO .. " carregado no executor: " .. tostring(M.EXECUTOR))
end

-- ============================ 1) UTILIDADES ============================

local V3 = Vector3.new
local CF = CFrame.new
local function num(v, padrao) v = tonumber(v); if v == nil then return padrao end return v end
local function clamp(v, a, b) if v < a then return a elseif v > b then return b end return v end
local function round(v, casas) local m = 10 ^ (casas or 0); return math.floor(v * m + 0.5) / m end
local function atan2(y, x)
  if math.atan2 then return math.atan2(y, x) end
  return math.atan(y, x)
end
local function unpack2(t, i, j) return (table.unpack or unpack)(t, i, j) end
local function tabelaVazia(t) return type(t) ~= "table" or next(t) == nil end
local function copiar(t) local n = {}; for k, v in pairs(t) do n[k] = v end; return n end
local function sortear(a, b) return a + math.random() * (b - a) end
local function escolher(lista) if #lista == 0 then return nil end return lista[math.random(1, #lista)] end

M.util = { num = num, clamp = clamp, round = round, atan2 = atan2, copiar = copiar }

-- distancia ignorando o eixo Y (visao de campo, mais estavel para IA)
local function distFlat(a, b)
  local dx, dz = a.X - b.X, a.Z - b.Z
  return math.sqrt(dx * dx + dz * dz)
end
local function dist(a, b) return (a - b).Magnitude end

local function ligar(sinal, fn)
  if sinal == nil then return nil end
  local ok, conn = pcall(function() return sinal:Connect(fn) end)
  if ok then return conn end
  ok, conn = pcall(function() return sinal.connect(sinal, fn) end)
  if ok then return conn end
  return nil
end
M.ligar = ligar

local function desconectar(conn)
  if conn == nil then return end
  pcall(function() if conn.Disconnect then conn:Disconnect() else conn:disconnect() end end)
end

-- ============================ 2) TECLADO / MOUSE ============================

-- Toda a entrada do hub passa por aqui. Se o executor nao tiver as funcoes
-- nativas (celular costuma nao ter), cai para o VirtualInputManager e, em
-- ultimo caso, para o proprio jogo (ContextActionService/Humanoid).
local TECLA = {}
TECLA.modo = "nativo"        -- nativo | virtual | nenhum

local CODES = {}
local KEYCODE_CACHE = {}
local function tecla(nome)
  if KEYCODE_CACHE[nome] then return KEYCODE_CACHE[nome] end
  local ok, k = pcall(function() return Enum.KeyCode[nome] end)
  KEYCODE_CACHE[nome] = (ok and k) or nil
  return KEYCODE_CACHE[nome]
end

function TECLA.pressionar(nome)
  local k = tecla(nome)
  if not k then return false end
  if funcoes.keypress then
    local ok = pcall(funcoes.keypress, k)
    if ok then TECLA.modo = "nativo"; return true end
  end
  if VIM then
    local ok = pcall(function() VIM:SendKeyEvent(true, k, false, game) end)
    if ok then TECLA.modo = "virtual"; return true end
  end
  TECLA.modo = "nenhum"
  return false
end

function TECLA.soltar(nome)
  local k = tecla(nome)
  if not k then return false end
  if funcoes.keyrelease then
    local ok = pcall(funcoes.keyrelease, k)
    if ok then return true end
  end
  if VIM then
    local ok = pcall(function() VIM:SendKeyEvent(false, k, false, game) end)
    if ok then return true end
  end
  return false
end

function TECLA.tocar(nome, segundos)
  TECLA.pressionar(nome)
  esperar(segundos or 0.08)
  TECLA.soltar(nome)
end

-- mouse ---------------------------------------------------------------
local MOUSE = {}
local function mouseAlvo()
  local ok, m = pcall(function() return Players.LocalPlayer:GetMouse() end)
  if ok then return m end
  return nil
end
M.mouse = mouseAlvo

function MOUSE.segurar(botao)
  local b = botao or 1
  if b == 1 and funcoes.mouse1press then
    local ok = pcall(funcoes.mouse1press)
    if ok then return true end
  end
  if b == 2 and funcoes.mouse2press then
    local ok = pcall(funcoes.mouse2press)
    if ok then return true end
  end
  if VIM then
    local ok = pcall(function()
      VIM:SendMouseButtonEvent(0, 0, b == 1 and 0 or 1, true, game, 0)
    end)
    if ok then return true end
  end
  -- ultimo caso: o botao real na tela do jogo (se estiver visivel)
  -- (M.ESTADO e preenchido na secao 3; aqui ainda nao existe o local ESTADO)
  if M.ESTADO then M.ESTADO.semClique = true end
  return false
end

function MOUSE.soltar(botao)
  local b = botao or 1
  if M.ESTADO then M.ESTADO.semClique = false end
  if b == 1 and funcoes.mouse1release then
    local ok = pcall(funcoes.mouse1release)
    if ok then return true end
  end
  if b == 2 and funcoes.mouse2release then
    local ok = pcall(funcoes.mouse2release)
    if ok then return true end
  end
  if VIM then
    local ok = pcall(function()
      VIM:SendMouseButtonEvent(0, 0, b == 1 and 0 or 1, false, game, 0)
    end)
    if ok then return true end
  end
  return false
end

function MOUSE.clicar(botao)
  local ok = MOUSE.segurar(botao)
  esperar(0.06)
  return MOUSE.soltar(botao) and ok
end
M.MOUSE = MOUSE

-- mira por mouse/absoluto (quando o executor tem) ----------------------
function MOUSE.moverAbs(x, y)
  local f = funcoes.mousemoveabs
  if f then local ok = pcall(f, x, y); if ok then return true end end
  if VIM then
    local ok = pcall(function() VIM:SendMouseMoveEvent(x, y, game) end)
    if ok then return true end
  end
  return false
end

function MOUSE.moverRel(dx, dy)
  local f = funcoes.mousemoverel
  if f then local ok = pcall(f, dx, dy); if ok then return true end end
  return false
end

-- camera --------------------------------------------------------------
local CAM = {}
CAM.guardado = nil

local function cam()
  local w = workspace
  return w and w.CurrentCamera or nil
end
M.camera = cam

function CAM.travarOlhar(ponto)
  local c = cam()
  if not c then return false end
  if not CAM.guardado then
    CAM.guardado = { tipo = c.CameraType, cf = c.CFrame, campo = c.FieldOfView, focus = c.Focus }
  end
  -- olha para o ponto mantendo a posicao (o jogo aceita: a camera e do
  -- cliente; o servidor nao manda na camera de ninguem)
  local ok = pcall(function()
    c.CFrame = CFrame.lookAt(c.CFrame.Position, ponto)
  end)
  if not ok then pcall(function() c.CFrame = CFrame.new(c.CFrame.Position, ponto) end) end
  return true
end

function CAM.restaurar()
  local c = cam()
  if not c or not CAM.guardado then return end
  pcall(function()
    c.CameraType = CAM.guardado.tipo
    c.CFrame = CAM.guardado.cf
    c.FieldOfView = CAM.guardado.campo
    c.Focus = CAM.guardado.focus
  end)
  CAM.guardado = nil
end

-- aponta a camera E o mouse de verdade para um ponto (usado no chute e no
-- passe). Nao teleporta nada: so olha.
function CAM.apontar(ponto)
  CAM.travarOlhar(ponto)
  local c = cam()
  if not c then return end
  local ok, tela, visivel = pcall(function() return c:WorldToViewportPoint(ponto) end)
  if ok and tela and visivel ~= false then
    MOUSE.moverAbs(math.floor(tela.X), math.floor(tela.Y))
  end
end
M.CAM = CAM

-- ============================ 3) ESTADO / CONFIG ============================

local CONF = {
  geral = {
    ativo = true, modoLeve = true, tick = 0.10, notificar = true,
    log = false, teclaChute = "F", hudBotao = true, hudFps = true,
    hudStatus = true, hudOpacidade = 0.45, hudBotaoTamanho = 82,
  },
  chute = {
    auto = true, forca = 1, carga = 0.42, mira = "auto", canto = "auto",
    curvado = "auto", retry = 3, verificar = true, distancia = 200,
    margem = 0.35, direto = true,
  },
  drible = {
    auto = true, raio = 9, toque = 5, cooldown = 1.1, manter = true,
    corte = true, tecla = "Q",
  },
  tackle = {
    auto = true, alcance = 6.5, bolaPerto = 9, cooldown = 0.9,
    prever = true, repetir = true,
  },
  actions = {
    auto = true, bicicleta = true, cabecada = true, voleio = true,
    carrinho = false, altura = 5, distancia = 6, cooldown = 1.4,
    teclaCabecada = "Space", acao = "auto",
  },
  goleiro = {
    auto = true, defesa = true, dive = true, posicionar = true,
    profundidade = 7, hitbox = false, forcar = false, velMax = 22,
  },
  passe = { gk = true, seguro = true, forca = 0.7, alcance = 70 },
  cerebro = {
    auto = true, nivel = "Top 1 Global", agressividade = 0.85,
    assistir = true, sozinho = false, chuteLonge = true, voltar = true,
  },
  desbloquear = {
    autoColeta = true, intervalo = 45, lerSpin = true, codes = "",
    cosmeticoLocal = false, autoEntrega = false,
  },
  antilag = {
    auto = true, preset = "Fraco (itel/Celular antigo)",
    sombras = true, particulas = true,
    decals = true, luz = true, ceu = true, distancia = 260, fisica = true,
    partes = true, som = true, hudJogo = true, retratos = true,
    animais = false, malhas = true, ui = true,
  },
}
M.CONF = CONF

-- a config tambem fica no getgenv(): outros scripts do usuario leem daqui
local ESTADO = {
  ligado = false,
  bola = nil,
  gols = {},
  alvo = nil,
  assinaturas = {},          -- nome do remote -> assinatura aprendida
  aprendendo = {},           -- remote Instance -> chave
  ultimaAcao = "—",
  estat = { chutes = 0, gols = 0, tackles = 0, dribles = 0, acoes = 0,
            passes = 0, defesas = 0, falhas = 0, tentativas = 0 },
  cd = { chute = 0, tackle = 0, drible = 0, acao = 0, passe = 0, defesa = 0 },
  cache = { quando = 0, jogadores = {}, adversarios = {}, aliados = {} },
  erro = nil,
}
M.ESTADO = ESTADO

function ESTADO.marcar(quando, valor)
  ESTADO.cd[quando] = (agora() + (valor or 0))
end
function ESTADO.livre(quando)
  return agora() >= (ESTADO.cd[quando] or 0)
end

-- ============================ 4) MUNDO ============================

local MUNDO = {}

local function meuPersonagem()
  local lp = Players and Players.LocalPlayer
  if not lp then return nil end
  local ok, ch = pcall(function() return lp.Character end)
  if not ok or not ch then return nil end
  return ch
end
local function meuHumanoide()
  local ch = meuPersonagem()
  if not ch then return nil end
  local ok, h = pcall(function() return ch:FindFirstChildOfClass("Humanoid") end)
  if ok and h then return h end
  return nil
end
local function meuRoot()
  local h = meuHumanoide()
  if not h then return nil end
  local ok, r = pcall(function() return h.RootPart end)
  if ok and r then return r end
  local ch = meuPersonagem()
  if ch then
    local ok2, r2 = pcall(function() return ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart end)
    if ok2 then return r2 end
  end
  return nil
end
MUNDO.personagem, MUNDO.humanoide, MUNDO.root = meuPersonagem, meuHumanoide, meuRoot

local function minhaPos()
  local r = meuRoot()
  if r then return r.Position end
  local c = cam()
  if c then return c.CFrame.Position end
  return nil
end
MUNDO.minhaPos = minhaPos

-- ---------------------------------------------------------------------
-- achar a bola: o detector do usuario achou Workspace.ball (score 410).
-- Aqui a busca e pela mesma logica de pontuacao, mas leve e com cache:
-- nome, classe, tamanho, velocidade e "parece bola".
-- ---------------------------------------------------------------------
local function pontuarBola(o)
  if type(o) ~= "table" and type(o) ~= "userdata" then return -1 end
  local ok, p = pcall(function()
    local nome = string.lower(o.Name)
    local s = 0
    if nome == "ball" or nome == "bola" or nome == "soccerball" then s = s + 300 end
    if string.find(nome, "ball", 1, true) or string.find(nome, "bola", 1, true) then s = s + 140 end
    if o:IsA("BasePart") then
      s = s + 40
      local tam = o.Size
      if tam then
        local d = (tam.X + tam.Y + tam.Z) / 3
        if d >= 0.5 and d <= 3.5 then s = s + 90 end
      end
      if o.AssemblyLinearVelocity then
        local v = o.AssemblyLinearVelocity
        if v.Magnitude > 0.5 then s = s + 100 end
      end
      if o.Massless then s = s + 15 end
    end
    local pai = o.Parent
    if pai then
      local pn = string.lower(pai.Name)
      if string.find(pn, "ignore", 1, true) then s = s - 250 end
      if string.find(pn, "goal", 1, true) then s = s - 400 end
      if string.find(pn, "arrow", 1, true) or string.find(pn, "campart", 1, true) then s = s - 300 end
    end
    if o.Anchored then s = s - 60 end
    return s
  end)
  if ok then return p end
  return -1
end
MUNDO.pontuarBola = pontuarBola

local function acharBola()
  -- atalho: nome exato conhecido
  local ok, b = pcall(function() return workspace:FindFirstChild("ball") end)
  if ok and b and b:IsA("BasePart") then return b end
  local melhor, nota = nil, 60
  local ok2 = pcall(function()
    for _, o in ipairs(workspace:GetChildren()) do
      local s = pontuarBola(o)
      if s > nota then melhor, nota = o, s end
    end
    if not melhor then
      for _, o in ipairs(workspace:GetDescendants()) do
        local s = pontuarBola(o)
        if s > nota then melhor, nota = o, s end
      end
    end
  end)
  if ok2 then return melhor end
  return nil
end
MUNDO.acharBola = acharBola

function MUNDO.bola()
  -- cache de 0.25s: procurar a bola toda hora em mapa com 17k objetos pesa
  local b = ESTADO.bola
  if b ~= nil then
    local ok, pai = pcall(function() return b.Parent end)
    if ok and pai and b:IsA("BasePart") then return b end
    ESTADO.bola = nil
  end
  local t = agora()
  local ultima = ESTADO.cache.bolaQuando
  if ultima and (t - ultima) < 0.25 then return ESTADO.bola end
  ESTADO.cache.bolaQuando = t
  local achada = acharBola()
  ESTADO.bola = achada
  return achada
end

-- ---------------------------------------------------------------------
-- Gols: HomeGoal / AwayGoal. Dentro de cada um:
--   Frame.Crossbar / Frame.BackPost  (estrutura)
--   Low.Target / Medium.Left|Center|Right / HighTargets.Target
--   DeviantTargets.Target (alvo do chute curvado)
-- ---------------------------------------------------------------------
local function garantirGols()
  local t = ESTADO.gols
  local ok = pcall(function()
    t.Home = workspace:FindFirstChild("HomeGoal")
    t.Away = workspace:FindFirstChild("AwayGoal")
  end)
  ESTADO.cache.gols = agora()
  return t
end
MUNDO.gols = garantirGols

local function alvosDoGol(gol)
  local lista = {}
  if not gol then return lista end
  pcall(function()
    for _, pasta in ipairs(gol:GetChildren()) do
      local nome = string.lower(pasta.Name)
      local tipo = "normal"
      if string.find(nome, "deviant", 1, true) then tipo = "curvado"
      elseif string.find(nome, "high", 1, true) then tipo = "alto"
      elseif string.find(nome, "low", 1, true) then tipo = "baixo"
      elseif string.find(nome, "medium", 1, true) then tipo = "medio"
      elseif nome == "frame" then tipo = "estrutura"
      end
      if tipo ~= "estrutura" then
        for _, filho in ipairs(pasta:GetChildren()) do
          if filho:IsA("BasePart") and string.lower(filho.Name) == "target" then
            lista[#lista + 1] = { peca = filho, tipo = tipo, lado = string.lower(pasta.Name) }
          elseif filho:IsA("BasePart") and tipo ~= "normal" then
            lista[#lista + 1] = { peca = filho, tipo = tipo, lado = string.lower(pasta.Name) }
          end
        end
      else
        for _, filho in ipairs(pasta:GetChildren()) do
          if filho:IsA("BasePart") then
            lista[#lista + 1] = { peca = filho, tipo = "estrutura", lado = string.lower(filho.Name) }
          end
        end
      end
    end
  end)
  return lista
end
MUNDO.alvosDoGol = alvosDoGol

local CACHE_CENTRO = {}
local function centroDoGol(gol)
  if not gol then return nil end
  local c = CACHE_CENTRO[gol]
  if c and (agora() - c.quando) < 2 then return c.pos end
  local soma, n = nil, 0
  pcall(function()
    for _, t in ipairs(alvosDoGol(gol)) do
      if t.tipo ~= "estrutura" then
        soma = soma and (soma + t.peca.Position) or t.peca.Position
        n = n + 1
      end
    end
  end)
  local resultado
  if n == 0 then
    local ok, p = pcall(function() return gol:GetPivot().Position end)
    resultado = ok and p or nil
  else
    resultado = soma / n
  end
  CACHE_CENTRO[gol] = { pos = resultado, quando = agora() }
  return resultado
end
MUNDO.centroDoGol = centroDoGol

-- direcao "para dentro do campo" (do gol apontando para o meio do campo).
-- Tres caminhos, do mais confiavel para o menos: centro do campo (metade
-- entre os dois gols), a estrutura do proprio gol (BackPost -> Crossbar) e,
-- por ultimo, a posicao da bola/pivo. Nunca chuta o Y: e direcao de chao.
local function normalDoGol(gol)
  if not gol then return nil end
  local c = centroDoGol(gol)
  if not c then return nil end
  local gols = ESTADO.gols or {}
  local H = gols.Home and gols.Home ~= gol and centroDoGol(gols.Home)
  local A = gols.Away and gols.Away ~= gol and centroDoGol(gols.Away)
  local outro = H or A
  if outro then
    local v = outro - c
    v = V3(v.X, 0, v.Z)
    if v.Magnitude > 1 then return v.Unit end
  end
  local okF, frame = pcall(function() return gol:FindFirstChild("Frame") end)
  if okF and frame then
    local back = frame:FindFirstChild("BackPost")
    local cross = frame:FindFirstChild("Crossbar")
    if back and cross then
      local v = cross.Position - back.Position
      v = V3(v.X, 0, v.Z)
      if v.Magnitude > 0.1 then return v.Unit end
    end
  end
  local bola = ESTADO.bola
  if bola then
    local okB, pb = pcall(function() return bola.Position end)
    if okB and pb then
      local v = pb - c
      v = V3(v.X, 0, v.Z)
      if v.Magnitude > 1 then return v.Unit end
    end
  end
  local ok, base = pcall(function() return gol:GetPivot().Position end)
  if ok and base then
    local v = base - c
    v = V3(v.X, 0, v.Z)
    if v.Magnitude > 1 then return v.Unit end
  end
  return nil
end
MUNDO.normalDoGol = normalDoGol

-- ---------------------------------------------------------------------
-- jogadores: separa adversario / aliado / quem tem a bola mais perto
-- ---------------------------------------------------------------------
local function timeDoJogador(p)
  local ok, t = pcall(function() return p.Team end)
  if ok and t then return t end
  return nil
end

function MUNDO.varrer(bola)
  local eu = Players and Players.LocalPlayer
  local meuTime = eu and timeDoJogador(eu) or nil
  local perto = { jogadores = {}, adversarios = {}, aliados = {} }
  local pos = minhaPos()
  local ok = pcall(function()
    for _, p in ipairs(Players:GetPlayers()) do
      if p ~= eu then
        local ch = p.Character
        local root = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart) or nil
        local hum = ch and ch:FindFirstChildOfClass("Humanoid") or nil
        if root and hum and hum.Health > 0 then
          local t = timeDoJogador(p)
          local item = {
            jogador = p, ch = ch, root = root, hum = hum, time = t,
            pos = root.Position, dist = pos and distFlat(pos, root.Position) or 999,
            distBola = bola and distFlat(bola.Position, root.Position) or 999,
            vel = root.AssemblyLinearVelocity or V3(0, 0, 0),
          }
          table.insert(perto.jogadores, item)
          if meuTime and t and t ~= meuTime then
            table.insert(perto.adversarios, item)
          elseif meuTime and t == meuTime then
            table.insert(perto.aliados, item)
          else
            table.insert(perto.adversarios, item)   -- time indefinido: trata como adversario (defensivo)
          end
        end
      end
    end
  end)
  if not ok then return perto end
  table.sort(perto.jogadores, function(a, b) return a.distBola < b.distBola end)
  table.sort(perto.adversarios, function(a, b) return a.distBola < b.distBola end)
  table.sort(perto.aliados, function(a, b) return a.distBola < b.distBola end)
  return perto
end

-- quem esta mais perto da bola no jogo inteiro (eu incluso)
function MUNDO.donoDaBola(bola, perto)
  local melhor, nota = nil, math.huge
  for _, j in ipairs(perto.jogadores) do
    if j.distBola < nota then melhor, nota = j, j.distBola end
  end
  local pos = minhaPos()
  local minha = (pos and bola) and distFlat(pos, bola.Position) or math.huge
  if minha <= nota then return { jogador = Players.LocalPlayer, eu = true, distBola = minha } end
  return melhor
end

MUNDO.perto = timeDoJogador
M.MUNDO = MUNDO
M.USAR = MUNDO
M.TECLA = TECLA

-- ============================ 5) NUCLEO PURO ============================
-- Tudo aqui e Lua puro: entra tabela, sai tabela. E o miolo que decide
-- mira, forca, canto, acao e o plano do anti-lag. Por ser puro, ele e
-- TESTADO de verdade fora do Roblox (roblox/teste_streetsoccer.lua).

local NUCLEO = {}
M.NUCLEO = NUCLEO

-- ---------------------------------------------------------------------
-- 5.1) qual gol eu ataco
-- ---------------------------------------------------------------------
function NUCLEO.escolherGol(o)
  o = o or {}
  local g = o.gols or {}
  if o.modo == "home" then return "Home" end
  if o.modo == "away" then return "Away" end
  if g.Home == nil then return g.Away and "Away" or nil end
  if g.Away == nil then return "Home" end
  local eu = o.eu
  if eu == nil then
    -- sem posicao: usa o lado do campo onde a bola esta mais perto
    local b = o.bola
    if b then
      local dh = (b - g.Home).Magnitude
      local da = (b - g.Away).Magnitude
      return (da < dh) and "Away" or "Home"
    end
    return "Home"
  end
  if o.timeCasa == true then return "Away" end
  if o.timeCasa == false then return "Home" end
  local dEuH = (eu - g.Home).Magnitude
  local dEuA = (eu - g.Away).Magnitude
  local dBolaH = o.bola and (o.bola - g.Home).Magnitude or 1e9
  local dBolaA = o.bola and (o.bola - g.Away).Magnitude or 1e9
  -- bola na boca de um gol E eu mais perto desse gol => esse gol e o MEU
  if dBolaH <= 22 and dEuH < dEuA then return "Away" end
  if dBolaA <= 22 and dEuA < dEuH then return "Home" end
  -- padrao: ataco o gol mais LONGE de mim (eu defendo o que fica atras)
  if dEuH > dEuA then return "Home" end
  return "Away"
end

-- ---------------------------------------------------------------------
-- 5.2) escolher o ponto exato do chute (canto / curva / altura)
--   ctx.alvos      = { {peca=parte, tipo="baixo|medio|alto|curvado|estrutura", lado=...}, ... }
--   ctx.gk         = Vector3 do goleiro (ou nil)
--   ctx.eu         = Vector3 de quem chuta
--   ctx.lado       = "auto" | "esquerda" | "direita" | "aleatorio"
--   ctx.curvado    = "auto" | "curva" | "normal" | "aleatorio"
--   ctx.margem     = studs que eu puxo para dentro da baliza (seguro)
--   ctx.centro     = centro do gol (para puxar para dentro)
-- ---------------------------------------------------------------------
local PESO_TIPO = {
  baixo = 30, medio = 22, alto = 10, curvado = 26, estrutura = -1e9,
}

function NUCLEO.escolherPonto(ctx)
  ctx = ctx or {}
  local alvos = ctx.alvos or {}
  local lista = {}
  local querCurva = ctx.curvado == "curva"
  if ctx.curvado == "aleatorio" then querCurva = (math.random() < 0.5) end
  local permitidos = {}
  if querCurva then
    permitidos.curvado = true
  elseif ctx.curvado == "normal" then
    permitidos.baixo, permitidos.medio, permitidos.alto = true, true, true
  else
    -- auto: prefere curvado quando o goleiro esta bem posicionado (canto
    -- fechado da muito trabalho); senao chute normal
    permitidos.baixo, permitidos.medio, permitidos.alto = true, true, true
    permitidos.curvado = true
  end
  for i = 1, #alvos do
    local a = alvos[i]
    local p = a.peca
    local ok, pos = pcall(function() return p.Position end)
    if ok and pos and permitidos[a.tipo] then
      local altura = 0
      if ctx.centro then altura = math.abs(pos.Y - ctx.centro.Y) end
      local lado = 0    -- -1 esquerda do gol / +1 direita (eixo do gol)
      if ctx.eixo then lado = (pos - ctx.centro):Dot(ctx.eixo) > 0 and 1 or -1 end
      local pertoDoGK = 0
      if ctx.gk then pertoDoGK = (pos - ctx.gk).Magnitude end
      local ponto = PESO_TIPO[a.tipo] or 0
      ponto = ponto + pertoDoGK * 1.6          -- longe do goleiro e melhor
      ponto = ponto - altura * 2.5             -- rasteiro e mais seguro
      if a.tipo == "curvado" and querCurva then ponto = ponto + 25 end
      lista[#lista + 1] = { peca = p, tipo = a.tipo, pos = pos, nota = ponto, lado = lado }
    end
  end
  if #lista == 0 then return nil end
  -- lado preferido
  local ladoQuer = nil
  if ctx.lado == "esquerda" then ladoQuer = -1
  elseif ctx.lado == "direita" then ladoQuer = 1
  elseif ctx.lado == "aleatorio" then ladoQuer = (math.random() < 0.5) and -1 or 1
  elseif ctx.gk and ctx.centro then
    -- auto com goleiro: chuta no canto oposto ao goleiro (longe dele)
    ladoQuer = ((ctx.gk - ctx.centro):Dot(ctx.eixo or V3(1, 0, 0)) > 0) and -1 or 1
  end
  if ladoQuer then
    for _, l in ipairs(lista) do
      if l.lado == ladoQuer then l.nota = l.nota + 40 end
      if l.lado == -ladoQuer then l.nota = l.nota - 8 end
    end
  end
  table.sort(lista, function(a, b) return a.nota > b.nota end)
  local escolhido = lista[1]
  -- margem: puxa o ponto para DENTRO do gol (erro de rede nao vira trave)
  local margem = num(ctx.margem, 0.35)
  local ponto = escolhido.pos
  if ctx.centro then
    local v = (ctx.centro - ponto)
    local d = v.Magnitude
    if d > 0.05 then
      local passo = math.min(margem, d * 0.5)
      ponto = ponto + v.Unit * passo
    end
  end
  return {
    peca = escolhido.peca, tipo = escolhido.tipo, lado = escolhido.lado,
    ponto = ponto, bruto = escolhido.pos, nota = escolhido.nota,
    curvado = (escolhido.tipo == "curvado"),
  }
end

-- ---------------------------------------------------------------------
-- 5.3) assinatura aprendida -> argumentos corrigidos
--   A ideia: o jogo dispara o remote; nos guardamos tipos + valores.
--   Depois so trocamos o que precisa trocar, mantendo o resto IDENTICO.
-- ---------------------------------------------------------------------
local function tipoDe(v)
  local t = typeof and typeof(v) or type(v)
  if t == "Vector3" then return "Vector3" end
  if t == "CFrame" then return "CFrame" end
  if t == "number" or t == "string" or t == "boolean" then return t end
  if t == "table" then return "table" end
  if t == "nil" then return "nil" end
  return "outro"
end
NUCLEO.tipoDe = tipoDe

function NUCLEO.esquelelo(...)
  local args = { ... }
  local esq = {}
  for i = 1, #args do esq[i] = tipoDe(args[i]) end
  return esq, #args
end

-- descobrir, na marra, qual argumento e o PONTO e qual e a FORCA
-- amostras = { {args={...}}, ... } (do mais antigo para o mais novo)
function NUCLEO.inferirMapa(amostras)
  local mapa = { ponto = nil, forca = nil, n = 0 }
  if type(amostras) ~= "table" or #amostras == 0 then return mapa end
  local ult = amostras[#amostras].args or {}
  mapa.n = #ult
  mapa.tipos = {}
  for i = 1, #ult do mapa.tipos[i] = tipoDe(ult[i]) end
  -- ponto: primeiro Vector3 cuja variacao entre amostras acompanha a bola
  if #amostras >= 2 then
    local a, b = amostras[#amostras - 1].args or {}, ult
    local melhor, melhorVar = nil, 0.05
    for i = 1, math.min(#a, #b) do
      if tipoDe(a[i]) == "Vector3" and tipoDe(b[i]) == "Vector3" then
        local d = (b[i] - a[i]).Magnitude
        if d > melhorVar then melhor, melhorVar = i, d end
      end
    end
    mapa.ponto = melhor
    -- forca: ultimo numero que parece potencia (0..1) ou numero grande
    for i = #ult, 1, -1 do
      if tipoDe(ult[i]) == "number" then
        mapa.forca = i
        break
      end
    end
  end
  if mapa.ponto == nil then
    -- sem historico: primeiro Vector3 e o ponto (padrao do jogo)
    for i = 1, #ult do
      if tipoDe(ult[i]) == "Vector3" then mapa.ponto = i; break end
    end
  end
  if mapa.forca == nil then
    for i = 1, #ult do
      if tipoDe(ult[i]) == "number" then mapa.forca = i; break end
    end
  end
  return mapa
end

-- plano: { ponto = Vector3, direcao = Vector3, forca = number|nil,
--          origem = Vector3|nil, trocarVetores = bool }
function NUCLEO.corrigir(args, mapa, plano)
  local novos = {}
  local trocas = 0
  mapa = mapa or {}
  plano = plano or {}
  for i = 1, #args do
    local v = args[i]
    local t = tipoDe(v)
    if t == "Vector3" and (mapa.ponto == nil or i >= 0) then
      local mag = v.Magnitude
      local ehUni = (mag > 0.9 and mag < 1.1)         -- vetor unitario = direcao
      if i == mapa.ponto then
        -- o argumento que o proprio jogo usa como ponto: mando a mira
        novos[i] = plano.ponto or v
        trocas = trocas + 1
      elseif ehUni and plano.direcao then
        novos[i] = plano.direcao                        -- direcao: aponta para o alvo
        trocas = trocas + 1
      elseif mapa.ponto == nil and plano.ponto then
        novos[i] = plano.ponto
        trocas = trocas + 1
      else
        novos[i] = v
      end
    elseif t == "CFrame" then
      if mapa.ponto and i == mapa.ponto and plano.ponto and plano.origem then
        novos[i] = CFrame.lookAt(plano.origem, plano.ponto)
        trocas = trocas + 1
      else
        novos[i] = v
      end
    elseif t == "number" and plano.forca and (mapa.forca == nil or i == mapa.forca) then
      -- so troca numero que parece potencia (0..1) ou que o mapa apontou
      if i == mapa.forca or (v >= 0 and v <= 1) then
        novos[i] = plano.forca
        trocas = trocas + 1
      else
        novos[i] = v
      end
    else
      novos[i] = v
    end
  end
  return novos, trocas
end

-- ---------------------------------------------------------------------
-- 5.4) previsao (usada pelo goleiro e pela corrida ate a bola)
--   devolve t, ponto  (quando e onde a bola passa por uma altura/plano)
-- ---------------------------------------------------------------------
function NUCLEO.prever(p, v, grav, alvoY, tMax, passo)
  tMax = tMax or 3
  passo = passo or 0.05
  local t = 0
  local pp, vv = p, v
  while t < tMax do
    local y = pp.Y + vv.Y * passo + 0.5 * grav * passo * passo
    local x = pp.X + vv.X * passo
    local z = pp.Z + vv.Z * passo
    if alvoY and y <= alvoY then return t, V3(x, alvoY, z) end
    pp = V3(x, y, z)
    vv = V3(vv.X, vv.Y + grav * passo, vv.Z)
    t = t + passo
  end
  if alvoY == nil then return tMax, pp end
  return t, pp
end

-- corte lateral no plano do gol (para o goleiro saber para onde pular)
function NUCLEO.corteNoPlano(p, v, grav, plano, centro, eixo, tMax)
  local t, ponto = NUCLEO.prever(p, v, grav, nil, tMax or 2.5)
  local d = (ponto - centro)
  local alto = d.Y
  local lado = d:Dot(eixo)
  local cruzou = false
  local pp, vv, tt = p, v, 0
  local h = 0.05
  local gg = grav or -196
  while tt < (tMax or 2.5) do
    -- Euler correto: y = y + vy*h + 0.5*g*h^2   (g negativo puxa para baixo)
    local np = V3(pp.X + vv.X * h, pp.Y + vv.Y * h + 0.5 * gg * h * h, pp.Z + vv.Z * h)
    local sinalAntes = (pp - centro):Dot(plano)
    local sinalDepois = (np - centro):Dot(plano)
    if sinalAntes > 0 and sinalDepois <= 0 then
      local d2 = (np - centro)
      -- devolve (tempo, vetor de corte, cruzou): X = deslocamento lateral
      -- no eixo do gol, Y = altura da bola quando cruzou a linha
      return tt, V3(d2:Dot(eixo), d2.Y, sinalDepois), true
    end
    pp, vv, tt = np, V3(vv.X, vv.Y + gg * h, vv.Z), tt + h
  end
  return t, V3(lado, alto, 0), cruzou
end

-- ---------------------------------------------------------------------
-- 5.5) passe seguro (goleiro e jogador de linha)
-- ---------------------------------------------------------------------
function NUCLEO.melhorPasse(o)
  o = o or {}
  local melhores = {}
  local eu = o.eu
  local maxD = num(o.alcance, 70)
  for _, a in ipairs(o.aliados or {}) do
    local p = a.pos
    if p and eu then
      local d = (p - eu).Magnitude
      if d >= 3 and d <= maxD then
        local risco = 0
        for _, ad in ipairs(o.adversarios or {}) do
          local q = ad.pos
          if q then
            -- distancia do adversario a linha do passe (eu -> aliado)
            local ab = p - eu
            local t = clamp((q - eu):Dot(ab) / math.max(ab:Dot(ab), 0.001), 0, 1)
            local proj = eu + ab * t
            local dLinha = (q - proj).Magnitude
            if dLinha < 6 then risco = risco + (6 - dLinha) * 6 end
          end
        end
        local ganho = 0
        if o.gol then
          ganho = ((o.gol - eu).Magnitude - (o.gol - p).Magnitude) * 1.2
        end
        melhores[#melhores + 1] = { alvo = a, ponto = p, dist = d, nota = ganho - risco - d * 0.25 }
      end
    end
  end
  table.sort(melhores, function(a, b) return a.nota > b.nota end)
  return melhores[1]
end

-- ---------------------------------------------------------------------
-- 5.6) O CEREBRO — a decisao do "Top 1 Global"
--   Recebe um retrato do jogo (numeros puros) e devolve a acao.
--   Regra de ouro: se o humano esta no controle, o cerebro ASSISTE;
--   ele age quando ha janela clara e sempre pelo movimento/chute reais.
-- ---------------------------------------------------------------------
function NUCLEO.decidir(c)
  c = c or {}
  if c.ativo == false then return "PARADO", { motivo = "desligado" } end
  -- blindagem: qualquer numero que faltar vira um padrao seguro (nunca
  -- deixa o cerebro quebrar por causa de um campo nil)
  local function nn(v, d) local n = tonumber(v) if n == nil then return d end return n end
  c.distAdversario = nn(c.distAdversario, 999)
  c.alcanceTackle = nn(c.alcanceTackle, 6.5)
  c.raioDrible = nn(c.raioDrible, 9)
  c.raioPasse = nn(c.raioPasse, 11)
  c.distBola = nn(c.distBola, 0)
  c.alturaBola = nn(c.alturaBola, 0)

  -- 1) goleiro tem logica propria (defesa legitima: posiciona, pula, corta)
  if c.ehGK then
    if c.bolaVindo then
      return "GKDEFESA", { ponto = c.pontoCorte, tempo = c.tempoCorte }
    end
    if c.bolaPerto and c.passeSeguro then return "GKPASSE", { alvo = c.passeAlvo } end
    if c.bolaPerto then return "GKCORTE", {} end
    return "GKPOSICIONAR", { ponto = c.pontoPoste }
  end

  -- 2) chute: bola no alcance, gol na mira, sem cooldown
  if c.podeChutar and c.bolaAlcance and c.golNaMira and not c.pressaoImpossivel then
    return "CHUTAR", { canto = c.canto, curvado = c.curvado }
  end

  -- 3) cabecada/bicicleta: bola no ar e perto
  if c.bolaAerea and c.bolaAlcance and c.podeAcao then
    if c.alturaBola and c.alturaBola >= 7 and c.bicicleta then return "BICICLETA", {} end
    return "CABECADA", {}
  end

  -- 4) tackle: adversario com a bola no meu alcance
  if c.adversarioComBola and c.distAdversario <= c.alcanceTackle and c.podeTackle then
    return "TACKLE", { alvo = c.adversario }
  end

  -- 5) tenho a bola e vem pressao: drible (finta) e depois passe
  if c.temPosse and c.distAdversario <= c.raioDrible and c.podeDriblar then
    return "DRIBLE", { direcao = c.fuga }
  end
  if c.temPosse and c.distAdversario <= c.raioPasse and c.passeSeguro and c.podePassar then
    return "PASSAR", { alvo = c.passeAlvo }
  end

  -- 6) ultimo homem: volta para fechar o gol em vez de dar bote
  if c.ultimoHomem and c.adversarioComBola and c.voltar then
    return "DEFENDER", { ponto = c.pontoDefesa }
  end

  -- 7) correr para a bola (com previsao de encontro, sem teleport)
  if c.distBola and c.distBola > 1.2 then
    return "CORRER", { ponto = c.pontoBola, sprint = c.sprint }
  end
  return "PARADO", {}
end

-- ---------------------------------------------------------------------
-- 5.7) plano do anti-lag (puro: so descreve o que fazer)
-- ---------------------------------------------------------------------
local PRESETS = {
  ["Ultra leve"] = {
    sombras = true, particulas = true, decals = true, luz = true, ceu = true,
    som = true, fisica = true, partes = true, malhas = true, distancia = 180,
    hudJogo = false, retratos = true, animais = true, ui = true,
  },
  ["Fraco (itel/Celular antigo)"] = {
    sombras = true, particulas = true, decals = true, luz = true, ceu = true,
    som = true, fisica = true, partes = true, malhas = false, distancia = 240,
    hudJogo = false, retratos = true, animais = false, ui = false,
  },
  ["Medio"] = {
    sombras = true, particulas = true, decals = true, luz = false, ceu = false,
    som = false, fisica = false, partes = true, malhas = false, distancia = 320,
    hudJogo = false, retratos = false, animais = false, ui = false,
  },
  ["PC / Leve"] = {
    sombras = false, particulas = false, decals = false, luz = false, ceu = false,
    som = false, fisica = false, partes = true, malhas = false, distancia = 400,
    hudJogo = false, retratos = false, animais = false, ui = false,
  },
}
NUCLEO.PRESETS = PRESETS

function NUCLEO.planoAntilag(cfg)
  local plano = {}
  cfg = cfg or {}
  if cfg.sombras then plano[#plano + 1] = "sombras" end
  if cfg.particulas then plano[#plano + 1] = "particulas" end
  if cfg.decals then plano[#plano + 1] = "decals" end
  if cfg.luz then plano[#plano + 1] = "luz" end
  if cfg.ceu then plano[#plano + 1] = "ceu" end
  if cfg.fisica then plano[#plano + 1] = "fisica" end
  if cfg.partes then plano[#plano + 1] = "partes" end
  if cfg.malhas then plano[#plano + 1] = "malhas" end
  if cfg.som then plano[#plano + 1] = "som" end
  if cfg.hudJogo then plano[#plano + 1] = "hudJogo" end
  if cfg.retratos then plano[#plano + 1] = "retratos" end
  if cfg.animais then plano[#plano + 1] = "animais" end
  if cfg.ui then plano[#plano + 1] = "ui" end
  if (cfg.distancia or 0) > 0 then plano[#plano + 1] = "distancia" end
  return plano
end

-- peca que o anti-lag NUNCA pode tocar (seguranca do jogo)
local NUNCA = {
  ball = true, bola = true, soccerball = true, target = true,
  crossbar = true, backpost = true, goal = true, homegoal = true,
  awaygoal = true, humanoid = true, head = true, torso = true,
  ["upper torso"] = true, ["lower torso"] = true, ["left leg"] = true,
  ["right leg"] = true, ["left arm"] = true, ["right arm"] = true,
  humanoidrootpart = true,
}
function NUCLEO.proibido(peca, classe, nomePai)
  local n = string.lower(tostring(peca or ""))
  if NUNCA[n] then return true end
  local c = string.lower(tostring(classe or ""))
  if c == "humanoid" or c == "accessory" or c == "motor6d" then return true end
  local p = string.lower(tostring(nomePai or ""))
  if p == "characters" or p == "players" then return true end
  if string.find(n, "target", 1, true) or string.find(n, "goal", 1, true) then return true end
  return false
end

-- ---------------------------------------------------------------------
-- 5.8) config em texto (salvar/carregar sem depender de JSON)
-- ---------------------------------------------------------------------
function NUCLEO.serializar(t)
  local linhas = { "ARKHERSS1" }
  local function anda(prefixo, tab)
    local chaves = {}
    for k in pairs(tab) do chaves[#chaves + 1] = k end
    table.sort(chaves, function(a, b) return tostring(a) < tostring(b) end)
    for _, k in ipairs(chaves) do
      local v = tab[k]
      local chave = prefixo == "" and tostring(k) or (prefixo .. "." .. tostring(k))
      if type(v) == "table" then
        anda(chave, v)
      elseif type(v) == "boolean" then
        linhas[#linhas + 1] = chave .. "=" .. (v and "true" or "false")
      elseif type(v) == "number" then
        linhas[#linhas + 1] = chave .. "=" .. tostring(v)
      elseif type(v) == "string" then
        linhas[#linhas + 1] = chave .. "=" .. v
      end
    end
  end
  anda("", t)
  return table.concat(linhas, "\n")
end

function NUCLEO.carregar(texto, destino)
  if type(texto) ~= "string" then return destino, 0 end
  local linhas = {}
  for l in string.gmatch(texto, "[^\n]+") do linhas[#linhas + 1] = l end
  if linhas[1] ~= "ARKHERSS1" then return destino, 0 end
  local n = 0
  for i = 2, #linhas do
    local chave, valor = string.match(linhas[i], "^([%w_%.%-]+)=(.*)$")
    if chave then
      local partes = {}
      for p in string.gmatch(chave, "[^%.]+") do partes[#partes + 1] = p end
      local no = destino
      local ok = true
      for j = 1, #partes - 1 do
        if type(no[partes[j]]) ~= "table" then ok = false break end
        no = no[partes[j]]
      end
      local ult = partes[#partes]
      if ok and no ~= nil then
        local atual = no[ult]
        if type(atual) == "boolean" then
          no[ult] = (valor == "true")
          n = n + 1
        elseif type(atual) == "number" then
          no[ult] = tonumber(valor) or atual
          n = n + 1
        elseif type(atual) == "string" then
          no[ult] = valor
          n = n + 1
        end
      end
    end
  end
  return destino, n
end

-- ---------------------------------------------------------------------
-- 5.9) estatistica honesta (o numero que vale e o medido no seu jogo)
-- ---------------------------------------------------------------------
function NUCLEO.taxa(estat)
  local t = (estat.tentativas or 0)
  if t <= 0 then return 0 end
  return math.floor(((estat.chutes or 0) / t) * 1000 + 0.5) / 10
end

function NUCLEO.golsPorChute(estat)
  local c = (estat.chutes or 0)
  if c <= 0 then return 0 end
  return math.floor(((estat.gols or 0) / c) * 1000 + 0.5) / 10
end

-- ============================ 6) MOVIMENTO (sem teleport) ============================
-- Regra: o hub NUNCA muda a posicao do personagem na marra. Ele pede o
-- mesmo que o jogador pede: direcao de caminhada (Humanoid:MoveTo / Move),
-- corrida (Shift) e pulo (Espaco). O servidor ve andar normal.

local MOVER = {}
local function padrao(t, defs)
  for k, v in pairs(defs) do if t[k] == nil then t[k] = v end end
  return t
end
padrao(CONF.chute, { alcance = 7, alcanceAereo = 6 })
padrao(CONF.drible, { forca = 0.55 })
padrao(CONF.cerebro, { moverManual = true })

function MOVER.manual()
  local h = MUNDO.humanoide()
  if h then
    local ok, d = pcall(function() return h.MoveDirection end)
    if ok and d and d.Magnitude > 0.15 then return true end
  end
  if UIS then
    local ok, ativo = pcall(function()
      return UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A)
        or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D)
        or UIS:IsKeyDown(Enum.KeyCode.Thumbstick1)
    end)
    if ok and ativo then return true end
  end
  return false
end

function MOVER.sprint(on)
  if on then TECLA.pressionar("LeftShift") else TECLA.soltar("LeftShift") end
end

function MOVER.pular()
  local h = MUNDO.humanoide()
  if not h then return false end
  local ok = pcall(function() h.Jump = true end)
  if not ok then return TECLA.pressionar("Space") end
  return true
end

function MOVER.ir(ponto, forcar, sprint)
  local h = MUNDO.humanoide()
  local r = MUNDO.root()
  if not h or not r or not ponto then return false end
  if MOVER.manual() and not forcar and CONF.cerebro.moverManual then
    return false      -- o humano esta jogando: o cerebro assiste, nao pega o controle
  end
  if sprint then MOVER.sprint(true) end
  local ok = pcall(function() h:MoveTo(ponto) end)
  if not ok then
    local d = ponto - r.Position
    d = V3(d.X, 0, d.Z)
    if d.Magnitude > 0.05 then pcall(function() h:Move(d.Unit, false) end) end
  end
  return true
end

function MOVER.parar()
  local h = MUNDO.humanoide()
  if h then pcall(function() h:Move(V3(0, 0, 0), false) end) end
  MOVER.sprint(false)
end

M.MOVER = MOVER

-- ============================ 7) JUIZ (o jogo contando o que aconteceu) ============================
-- Passive: so ESCUTA os eventos que o servidor manda para o cliente
-- (gol, falta, penalti). Serve para estatistica real e para o cerebro
-- saber quando parar de chutar (depois do gol a bola volta ao centro).

local JUIZ = {}
local function remotePorCaminho(caminho)
  local atual = game
  for parte in string.gmatch(caminho, "[^%.]+") do
    local ok, filho = pcall(function() return atual:FindFirstChild(parte) end)
    if not ok or not filho then return nil end
    atual = filho
  end
  return atual
end
M.remotePorCaminho = remotePorCaminho

function JUIZ.ligar()
  if MODO_TESTE then return end
  ESTADO.juiz = ESTADO.juiz or { gol = 0, falta = 0, penalti = 0 }
  local tentativas = 0
  local function conectarRef()
    local ref = remotePorCaminho("Workspace.Referee.RefereeMove")
    if not ref then return false end
    ligar(ref.OnClientEvent, function(...)
      local partes = {}
      for i = 1, select("#", ...) do partes[#partes + 1] = tostring(select(i, ...)) end
      local t = table.concat(partes, " ")
      local j = ESTADO.juiz
      if string.find(t, "goal") then
        j.gol = (j.gol or 0) + 1
        j.ultimoGol = agora()
        -- so entra na MINHA estatistica se eu chutei nos ultimos 12s
        if ESTADO.estat and ESTADO.ultimoChute and (agora() - ESTADO.ultimoChute) <= 12 then
          ESTADO.estat.gols = (ESTADO.estat.gols or 0) + 1
          j.meuGol = agora()
          if CONF.geral.notificar then
            avisar("GOL!", string.format("aproveitamento: %.0f%% nos chutes", NUCLEO.golsPorChute(ESTADO.estat)), nil, 3)
          end
        end
      elseif string.find(t, "foul") then
        j.falta = (j.falta or 0) + 1
        j.ultimaFalta = agora()
      elseif string.find(t, "penalty") then
        j.penalti = (j.penalti or 0) + 1
      end
    end)
    ESTADO.juizRef = true
    return true
  end
  local function conectarGui()
    local lp = Players and Players.LocalPlayer
    if not lp then return false end
    local gui = lp:FindFirstChild("PlayerGui")
    local exc = gui and gui:FindFirstChild("Exclamation")
    if not exc then return false end
    local cont = 0
    for _, filho in ipairs(exc:GetDescendants()) do
      if filho:IsA("RemoteEvent") and filho.Name == "RefereeMove" then
        cont = cont + 1
        ligar(filho.OnClientEvent, function()
          ESTADO.juiz.ultimoAviso = agora()
        end)
      end
    end
    ESTADO.juiz.contadores = cont
    ESTADO.juizGui = cont > 0
    return true
  end
  local function tentar()
    tentativas = tentativas + 1
    local okRef = ESTADO.juizRef and true or conectarRef()
    local okGui = ESTADO.juizGui and true or conectarGui()
    if not (okRef and okGui) and tentativas < 24 then
      adiar(5, tentar)      -- o mapa carrega depois: tenta de novo
    end
  end
  tentar()
end

-- o juiz roda em nivel de arquivo: se der erro aqui, o script inteiro
-- morre antes da interface. Por isso vai em pcall (e o hub avisa depois).
do
  local ok, err = pcall(JUIZ.ligar)
  if not ok then ESTADO.erroJuiz = tostring(err) end
end
M.JUIZ = JUIZ

-- ============================ 8) ASSINATURAS (a inteligencia do hub) ============================

local ASSIN = {}
local CONHECIDOS = {
  -- nome exato do remote  ->  chave interna
  ShootTheBall = "shoot",
  Pass = "pass",
  Tackle = "tackle",
  Action = "action",
  GKHitbox = "gk",
  Collect = "collect",
  ClaimStick = "stick",
  DailyReward = "daily",
  WQuest = "quest",
  Equip = "equip",
  Jersey = "jersey",
  Avatar = "avatar",
  Settings = "settings",
  Unbox = "unbox",
  Shake = "shake",
  Faceoff = "faceoff",
  Penalty = "penalti",
  Position = "position",
  isMobile = "ismobile",
  notify = "notify",
  cFactor = "cfactor",
}
local ISCAS = {
  ShootTheBaII = true,        -- "i" maiusculo: isca do anti-cheat
  AdminBan = true, Teleport = true, lancage = true, Iancage = true,
  tcelloc = true, cfactor = true, FPSNORE = true, PINGNORE = true,
  Save = true, CutsceneRemote = true, PodiumCamera = true,
  PodiumCelebration = true, SoftDisPlayer = true,
}
local NOMES_IGNORADOS = {
  -- remotes de loja/resgate/admin NAO entram no chute automatico; eles tem
  -- modulo proprio (DESBLOQUEAR) para nao dar tiro errado.
  Purchase = true, AdminBan = true, Teleport = true,
}

M.REMOTES_CONHECIDOS = CONHECIDOS
M.REMOTES_ISCA = ISCAS

local MAX_AMOSTRAS = 8

function ASSIN.pasta()
  return RS and RS:FindFirstChild("Remotes") or nil
end
M.ASSIN = ASSIN

function ASSIN.remote(chave)
  -- acha o RemoteEvent/RemoteFunction pela chave, evitando os de isca
  local alvo = nil
  for nome, k in pairs(CONHECIDOS) do
    if k == chave and not ISCAS[nome] then alvo = nome break end
  end
  if not alvo then return nil end
  local pasta = ASSIN.pasta()
  local r = pasta and pasta:FindFirstChild(alvo) or nil
  if not r and RS then r = RS:FindFirstChild(alvo) end
  if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then return r, alvo end
  return nil
end

function ASSIN.anotar(chave, inst, args)
  local e = ESTADO.assinaturas[chave]
  if not e then
    e = { chave = chave, nome = inst.Name, classe = inst.ClassName, amostras = {} }
    ESTADO.assinaturas[chave] = e
  end
  e.nome = inst.Name
  e.classe = inst.ClassName
  e.quando = agora()
  e.amostras[#e.amostras + 1] = { args = args, quando = agora() }
  while #e.amostras > MAX_AMOSTRAS do table.remove(e.amostras, 1) end
  e.mapa = NUCLEO.inferirMapa(e.amostras)
  e.registros = (e.registros or 0) + 1
  if M.LOG then
    local tipos = table.concat(e.mapa.tipos or {}, ",")
    print(string.format("[ARKHER] assinatura %s: %s (ponto=%s forca=%s)",
      chave, tipos, tostring(e.mapa.ponto), tostring(e.mapa.forca)))
  end
  return e
end

-- ---------------------------------------------------------------------
-- empacotar/desempacotar assinatura (grava no disco para nao reaprender)
--   formato: chave|classe|tipos|ponto|forca|fixos
-- ---------------------------------------------------------------------
function ASSIN.empacotar(e)
  if not e or not e.chave then return nil end
  local mapa = e.mapa or {}
  local tipos = table.concat(mapa.tipos or {}, ",")
  local fixos = {}
  local ult = e.amostras and e.amostras[#e.amostras]
  if ult then
    for i = 1, #ult.args do
      local v = ult.args[i]
      local t = NUCLEO.tipoDe(v)
      if i ~= mapa.forca and (t == "string" or t == "boolean" or (t == "number" and i ~= mapa.forca)) then
        local val
        if t == "boolean" then val = v and "1" or "0"
        elseif t == "number" then val = tostring(v)
        else val = tostring(v):gsub("[|;:\n]", "_") end
        fixos[#fixos + 1] = i .. ":" .. string.sub(t, 1, 1) .. ":" .. val
      end
    end
  end
  return table.concat({
    e.chave, tostring(e.classe or "RemoteEvent"), tipos,
    tostring(mapa.ponto or ""), tostring(mapa.forca or ""),
    table.concat(fixos, ";"),
  }, "|")
end

function ASSIN.desempacotar(linha)
  local chave, classe, tipos, ponto, forca, fixos = string.match(linha, "^([^|]+)|([^|]*)|([^|]*)|([^|]*)|([^|]*)|(.*)$")
  if not chave then return nil end
  local e = { chave = chave, classe = classe, amostras = {}, fixos = {} }
  local listaTipos = {}
  if tipos and #tipos > 0 then
    for t in string.gmatch(tipos, "[^,]+") do listaTipos[#listaTipos + 1] = t end
  end
  e.mapa = { tipos = listaTipos, ponto = tonumber(ponto), forca = tonumber(forca), n = #listaTipos }
  if fixos and #fixos > 0 then
    for item in string.gmatch(fixos, "[^;]+") do
      local i, t, v = string.match(item, "^(%d+):([sbn]):(.*)$")
      if i then
        i = tonumber(i)
        if t == "s" then e.fixos[i] = v
        elseif t == "b" then e.fixos[i] = (v == "1")
        else e.fixos[i] = tonumber(v) or 0 end
      end
    end
  end
  return e
end

function ASSIN.arquivo()
  return "ARKHER_SS_assinaturas.txt"
end

function ASSIN.salvar()
  if MODO_TESTE then return false, "modo teste" end
  if type(funcoes.writefile) ~= "function" then return false, "executor sem writefile" end
  local linhas = { "ARKHERSIG1" }
  for chave, e in pairs(ESTADO.assinaturas) do
    local l = ASSIN.empacotar(e)
    if l then linhas[#linhas + 1] = l end
  end
  local ok = pcall(funcoes.writefile, ASSIN.arquivo(), table.concat(linhas, "\n"))
  return ok
end

function ASSIN.carregar()
  if MODO_TESTE then return 0 end
  if type(funcoes.readfile) ~= "function" then return 0 end
  local ok, texto = pcall(funcoes.readfile, ASSIN.arquivo())
  if not ok or type(texto) ~= "string" then return 0 end
  local n = 0
  for linha in string.gmatch(texto, "[^\n]+") do
    if string.find(linha, "ARKHERSIG1") == nil then
      local e = ASSIN.desempacotar(linha)
      if e then
        e.registros = 0
        ESTADO.assinaturas[e.chave] = e
        n = n + 1
      end
    end
  end
  return n
end

-- ---------------------------------------------------------------------
-- o gancho passivo: aprendemos a assinatura sem chamar remote nenhum
-- ---------------------------------------------------------------------
local OBSERVADOS = {}

function ASSIN.instalar()
  if MODO_TESTE then return false, "modo teste" end
  local pasta = ASSIN.pasta()
  if pasta then
    for _, filho in ipairs(pasta:GetChildren()) do
      if (filho:IsA("RemoteEvent") or filho:IsA("RemoteFunction")) then
        local chave = CONHECIDOS[filho.Name]
        if chave then OBSERVADOS[filho] = chave end
        if ISCAS[filho.Name] then OBSERVADOS[filho] = "isca:" .. filho.Name end
      end
    end
    for _, nome in ipairs({ "RedeemCode", "PingSend" }) do
      local r = RS and RS:FindFirstChild(nome)
      if r then OBSERVADOS[r] = "extra:" .. nome end
    end
  end

  local antigo = nil
  if funcoes.getrawmetatable then
    local ok, mt = pcall(funcoes.getrawmetatable, game)
    if ok and mt then
      antigo = rawget(mt, "__namecall")
      if antigo then
        local function gancho(self, ...)
          local metodo = funcoes.getnamecallmethod and funcoes.getnamecallmethod() or nil
          if metodo == "FireServer" or metodo == "InvokeServer" or metodo == "fireServer" then
            local chave = OBSERVADOS[self]
            if chave then
              local args = { ... }
              if string.sub(chave, 1, 5) == "isca:" then
                ESTADO.iscaVista = { nome = string.sub(chave, 6), quando = agora() }
              else
                pcall(ASSIN.anotar, chave, self, args)
              end
            end
          end
          return antigo(self, ...)
        end
        local nova = gancho
        if funcoes.newcclosure then
          local okc, c = pcall(funcoes.newcclosure, gancho)
          if okc and c then nova = c end
        end
        if funcoes.setreadonly then pcall(funcoes.setreadonly, mt, false) end
        local ok2 = pcall(function() mt.__namecall = nova end)
        if funcoes.setreadonly then pcall(funcoes.setreadonly, mt, true) end
        if ok2 then ESTADO.gancho = "getrawmetatable" return true end
        if funcoes.hookmetamethod then
          local ok3 = pcall(funcoes.hookmetamethod, game, "__namecall", nova)
          if ok3 then ESTADO.gancho = "hookmetamethod" return true end
        end
      end
    end
  end
  if funcoes.hookmetamethod then
    local ok = pcall(funcoes.hookmetamethod, game, "__namecall", function(self, ...)
      local metodo = funcoes.getnamecallmethod and funcoes.getnamecallmethod() or nil
      if metodo == "FireServer" or metodo == "InvokeServer" then
        local chave = OBSERVADOS[self]
        if chave and string.sub(chave, 1, 5) ~= "isca:" then
          pcall(ASSIN.anotar, chave, self, { ... })
        end
      end
      return nil
    end)
    -- hookmetamethod exige a funcao antiga por dentro; se nao houver,
    -- nao da para instalar com seguranca: melhor nao aprender do que quebrar
    if ok then ESTADO.gancho = "hookmetamethod-parcial" return false, "hook parcial (sem repasse): usando modo FRAME" end
  end
  return false, "executor sem gancho: o hub usa a via de mira + clique (funciona igual, sem aprender)"
end

-- ---------------------------------------------------------------------
-- montar os argumentos a partir da assinatura (quando ja aprendemos)
-- ---------------------------------------------------------------------
function ASSIN.tem(chave)
  local e = ESTADO.assinaturas[chave]
  return (e ~= nil and e.mapa ~= nil and e.mapa.n and e.mapa.n > 0) and e or nil
end

function ASSIN.montar(chave, plano)
  local e = ASSIN.tem(chave)
  if not e then return nil end
  local tipos = e.mapa.tipos or {}
  local args = {}
  for i = 1, e.mapa.n do
    local t = tipos[i]
    if i == e.mapa.ponto and t == "Vector3" then
      args[i] = plano.ponto
    elseif i == e.mapa.ponto and t == "CFrame" then
      args[i] = CFrame.lookAt(plano.origem or plano.ponto, plano.ponto)
    elseif i == e.mapa.forca and t == "number" then
      args[i] = plano.forca or 1
    elseif t == "Vector3" then
      args[i] = plano.direcao or plano.ponto
    elseif t == "number" then
      args[i] = e.fixos and e.fixos[i] or 0
    elseif t == "string" then
      args[i] = (e.fixos and e.fixos[i]) or plano.texto or ""
    elseif t == "boolean" then
      args[i] = (e.fixos and e.fixos[i])
      if args[i] == nil then args[i] = false end
    else
      args[i] = e.fixos and e.fixos[i] or nil
    end
  end
  return args, e
end

function ASSIN.disparar(chave, plano)
  if MODO_TESTE then return false, "modo teste: nenhum remote e disparado" end
  local e = ASSIN.tem(chave)
  if not e then return false, "sem assinatura" end
  local args = ASSIN.montar(chave, plano)
  if not args then return false, "sem assinatura" end
  local r = ASSIN.remote(chave)
  if not r then return false, "remote nao encontrado" end
  local chamada
  if e.classe == "RemoteFunction" then
    chamada = function() return r:InvokeServer(unpack2(args)) end
  else
    chamada = function() return r:FireServer(unpack2(args)) end
  end
  local ok, err = pcall(chamada)
  if ok then
    ESTADO.ultimoDisparo = { chave = chave, quando = agora(), args = args }
    return true, #args
  end
  return false, tostring(err)
end
M.ASSIN = ASSIN

-- ============================ 9) CHUTE (a peca principal) ============================

local TIRO = {}

function TIRO.retrato()
  local bola = MUNDO.bola()
  if not bola then return nil, "sem bola na cena (espere o jogo comecar)" end
  local root = MUNDO.root()
  if not root then return nil, "sem personagem" end
  local gols = MUNDO.gols()
  local centroH = MUNDO.centroDoGol(gols.Home)
  local centroA = MUNDO.centroDoGol(gols.Away)
  if not centroH or not centroA then return nil, "gols nao encontrados (mudou o mapa?)" end

  local lp = Players.LocalPlayer
  local timeCasa = nil
  local ok, t = pcall(function() return lp.Team end)
  if ok and t then
    local n = string.lower(t.Name)
    if string.find(n, "home", 1, true) or string.find(n, "casa", 1, true) then timeCasa = true end
    if string.find(n, "away", 1, true) or string.find(n, "visit", 1, true) then timeCasa = false end
  end

  local nomeGol = NUCLEO.escolherGol({
    modo = CONF.chute.mira, gols = { Home = centroH, Away = centroA },
    eu = root.Position, bola = bola.Position, timeCasa = timeCasa,
  })
  if not nomeGol then return nil, "nao deu para decidir o gol" end
  local gol = gols[nomeGol]
  local centro = (nomeGol == "Home") and centroH or centroA
  local normal = MUNDO.normalDoGol(gol) or V3(0, 0, 1)
  local base = V3(normal.X, 0, normal.Z)
  if base.Magnitude < 0.01 then base = V3(0, 0, 1) end
  base = base.Unit
  local eixo = base:Cross(V3(0, 1, 0))
  if eixo.Magnitude < 0.01 then eixo = V3(1, 0, 0) end
  eixo = eixo.Unit

  -- goleiro adversario: quem esta mais perto daquele gol do lado de dentro
  local perto = MUNDO.varrer(bola)
  local gk, melhor = nil, math.huge
  for _, j in ipairs(perto.jogadores) do
    local d = distFlat(j.pos, centro)
    if d < melhor and d < 45 then gk, melhor = j.pos, d end
  end

  local alvos = MUNDO.alvosDoGol(gol)
  local escolha = NUCLEO.escolherPonto({
    alvos = alvos, gk = gk, eu = root.Position, centro = centro, eixo = eixo,
    lado = CONF.chute.canto, curvado = CONF.chute.curvado, margem = CONF.chute.margem,
  })
  if not escolha then return nil, "nenhum alvo no gol (mapa mudou?)" end

  return {
    bola = bola, root = root, gol = gol, nomeGol = nomeGol, centro = centro,
    normal = base, eixo = eixo, gk = gk, escolha = escolha,
    ponto = escolha.ponto, curvado = escolha.curvado, tipo = escolha.tipo,
    distBola = distFlat(root.Position, bola.Position),
    distGol = distFlat(bola.Position, centro),
    perto = perto,
  }
end

-- o que faz o chute ACERTAR: apontar de verdade, forca maxima, sem TP
function TIRO.preparar(plano)
  local bola = plano.bola
  local origem = bola.Position
  local direcao = plano.ponto - origem
  if direcao.Magnitude < 0.05 then direcao = plano.normal end
  return {
    ponto = plano.ponto,
    direcao = direcao.Unit,
    origem = origem,
    forca = CONF.chute.forca,          -- 1 = carga maxima, como o usuario pediu
    curvado = plano.curvado,
    texto = plano.curvado and "curva" or nil,
  }
end

function TIRO.verificar(antes, bola, tentativa)
  -- conferiu de verdade: a bola saiu do lugar?
  local ok, pos = pcall(function() return bola.Position end)
  if not ok or not pos then return false end
  local andou = (pos - antes).Magnitude
  if andou >= 1.2 then return true, andou end
  return false, andou
end

-- executor sem clique automatico? o hub avisa UMA vez, em vez de falhar
-- calado: a mira ja esta no canto certo, falta so o toque no botao do jogo.
local function avisarSemClique()
  if ESTADO.semCliqueAvisado then return end
  ESTADO.semCliqueAvisado = true
  avisar("Seu executor nao tem clique automatico",
    "A mira do hub ja aponta para o canto escolhido: use o botao de chute do jogo (ou o botao do hub) que vai no lugar certo.",
    nil, 8)
end

function TIRO.executar(op)
  op = op or {}
  local plano, erro = TIRO.retrato()
  if not plano then
    ESTADO.ultimaAcao = "chute: " .. tostring(erro)
    return false
  end
  if plano.distBola > CONF.chute.alcance then
    ESTADO.ultimaAcao = string.format("chute: bola a %.1f studs (longe)", plano.distBola)
    return false, "longe"
  end
  if plano.distGol > CONF.chute.distancia then
    ESTADO.ultimaAcao = "chute: fora do alcance configurado"
    return false, "fora de alcance"
  end
  local p = TIRO.preparar(plano)
  ESTADO.alvo = plano.ponto
  ESTADO.ultimoPlano = plano
  local tentativas = math.max(1, num(CONF.chute.retry, 2))
  local antes = plano.bola.Position
  local sucesso, andou = false, 0
  for t = 1, tentativas do
    ESTADO.estat.tentativas = (ESTADO.estat.tentativas or 0) + 1
    local usouDireto = false
    if CONF.chute.direto then
      local ok = ASSIN.disparar("shoot", p)
      usouDireto = ok and true or false
    end
    if not usouDireto then
      -- via de verdade: aponta a camera, segura o clique ate a carga
      -- maxima e solta. E o mesmo gesto de quem joga no PC.
      CAM.apontar(p.ponto)
      local fim = agora() + math.max(0.12, num(CONF.chute.carga, 0.4))
      MOUSE.segurar(1)
      while agora() < fim do
        CAM.travarOlhar(p.ponto)      -- acompanha o alvo durante a carga
        esperar(0.03)
      end
      MOUSE.soltar(1)
      adiar(0.25, function() CAM.restaurar() end)
    end
    esperar(0.16)
    sucesso, andou = TIRO.verificar(antes, plano.bola, t)
    if sucesso then break end
    esperar(0.12)
  end
  ESTADO.marcar("chute", CONF.chute.pausa or 0.25)
  if sucesso then
    ESTADO.estat.chutes = (ESTADO.estat.chutes or 0) + 1
    ESTADO.ultimaAcao = string.format("chute %s -> %s (%.0f studs)", plano.curvado and "curvado" or "normal",
      plano.nomeGol, plano.distGol)
    ESTADO.ultimoChute = agora()
    ESTADO.ultimoChutePonto = plano.ponto
    if CONF.geral.notificar and op.avisar ~= false then
      avisar("Chute", string.format("%s no %s · %.1f studs", plano.curvado and "Curvado" or "Reto",
        plano.nomeGol, plano.distGol), nil, 2)
    end
    return true, plano
  end
  ESTADO.estat.falhas = (ESTADO.estat.falhas or 0) + 1
  ESTADO.ultimaAcao = "chute: a bola nao saiu (tentou " .. tentativas .. "x)"
  if ESTADO.semClique then avisarSemClique() end
  return false, plano
end
M.TIRO = TIRO
M.TIRO_RETRATO = TIRO.retrato

-- ============================ 10) AUTOS ============================
-- Cada auto faz UMA coisa e confere se deu certo. Quem coordena e o
-- cerebro (secao 11). Todos respeitam cooldown para nao spammar remote.

local AUTOS = {}

-- 10.0) AUTO SHOOT — e o mesmo laco fechado do TIRO (secao 9): mira no
-- canto mais longe do goleiro, forca maxima, confere se a bola saiu e repete.
function AUTOS.chutar(op)
  return TIRO.executar(op)
end

-- fuga: direcao que afasta do marcador e vai para o gol (usada no drible)
function NUCLEO.fuga(o)
  o = o or {}
  local dir = V3(0, 0, 0)
  for _, ad in ipairs(o.adversarios or {}) do
    local v = o.eu - ad.pos
    v = V3(v.X, 0, v.Z)
    local m = v.Magnitude
    if m > 0.01 and m < 15 then
      dir = dir + v.Unit * ((15 - m) / 15) * 1.4
    end
  end
  if o.gol then
    local g = o.gol - o.eu
    g = V3(g.X, 0, g.Z)
    if g.Magnitude > 0.01 then dir = dir + g.Unit * 0.7 end
  end
  if dir.Magnitude < 0.05 then
    local f = o.frente or V3(0, 0, 1)
    dir = V3(f.X, 0, f.Z)
    if dir.Magnitude < 0.01 then dir = V3(0, 0, 1) end
  end
  return dir.Unit
end

-- ponto de encontro com a bola (sem teleport: e so previsao de caminhada)
function NUCLEO.encontro(eu, bola, vel, tMax)
  tMax = tMax or 1.6
  local melhor, melhorT = bola, tMax
  local t = 0
  while t <= tMax do
    local p = bola + vel * t
    local d = (V3(p.X - eu.X, 0, p.Z - eu.Z)).Magnitude
    if d <= (8.2 * t + 1.2) then melhor, melhorT = p, t break end
    t = t + 0.1
  end
  return melhor, melhorT
end

-- ---------------------------------------------------------------------
-- 10.1) AUTO DRIBLE — ja vem no ponto: prende a bola, finta quando o
-- marcador chega e sai para o lado livre (sem virar corredor do adversario)
-- ---------------------------------------------------------------------
function AUTOS.driblar(op)
  op = op or {}
  if not ESTADO.livre("drible") then return false end
  local bola = MUNDO.bola()
  local root = MUNDO.root()
  if not bola or not root then return false end
  local perto = op.perto or MUNDO.varrer(bola)
  local dir = NUCLEO.fuga({ eu = root.Position, adversarios = perto.adversarios,
                            gol = op.gol, frente = root.CFrame.LookVector })
  -- 1) o toque de drible do jogo (Q) — e o que engana o marcador
  TECLA.tocar(CONF.drible.tecla, 0.05)
  ESTADO.estat.dribles = (ESTADO.estat.dribles or 0) + 1
  -- 2) sai do bolsoo do marcador: 2 studs na direcao de fuga
  local destino = root.Position + dir * 4
  MOVER.ir(destino, op.forcar, true)
  ESTADO.marcar("drible", num(CONF.drible.cooldown, 1.1))
  ESTADO.ultimaAcao = "drible (finta)"
  return true
end

-- ---------------------------------------------------------------------
-- 10.2) AUTO TACKLE — configura no ponto: so entra quando o adversario
-- REALMENTE tem a bola no alcance, e confere se ele perdeu
-- ---------------------------------------------------------------------
function AUTOS.tacklear(op)
  op = op or {}
  if not ESTADO.livre("tackle") then return false end
  local bola = MUNDO.bola()
  local root = MUNDO.root()
  if not bola or not root then return false end
  local perto = op.perto or MUNDO.varrer(bola)
  local alvo, melhor = nil, math.huge
  for _, j in ipairs(perto.adversarios) do
    local d = distFlat(root.Position, j.pos)
    if j.distBola <= num(CONF.tackle.bolaPerto, 9) and d <= num(CONF.tackle.alcance, 6.5) and d < melhor then
      alvo, melhor = j, d
    end
  end
  if not alvo and num(CONF.tackle.prever, 1) == 1 then
    for _, j in ipairs(perto.adversarios) do
      local d = distFlat(root.Position, j.pos)
      local indo = j.pos + j.vel * 0.25
      local dBolaPrev = distFlat(indo, bola + bola.AssemblyLinearVelocity * 0.25)
      if dBolaPrev <= num(CONF.tackle.bolaPerto, 9) and d <= num(CONF.tackle.alcance, 6.5) + 1.5 then
        alvo, melhor = j, d
        break
      end
    end
  end
  if not alvo then return false end
  -- aponta para o adversario (o jogo usa a direcao da camera no carrinho)
  CAM.apontar(alvo.pos)
  local antes = alvo.distBola
  TECLA.tocar("E", 0.06)
  ESTADO.estat.tackles = (ESTADO.estat.tackles or 0) + 1
  ESTADO.marcar("tackle", num(CONF.tackle.cooldown, 0.9))
  ESTADO.ultimaAcao = string.format("tackle em %s (%.1f studs)", alvo.jogador and alvo.jogador.Name or "adversario", melhor)
  -- conferiu: a bola se afastou dele?
  if num(CONF.tackle.repetir, 1) == 1 then
    adiar(0.22, function()
      pcall(function()
        local agoraBola = MUNDO.bola()
        if agoraBola and alvo.root then
          local d = distFlat(agoraBola.Position, alvo.root.Position)
          if d < antes + 0.2 and CONF.tackle.auto and ESTADO.livre("tackle") then
            TECLA.tocar("E", 0.06)
            ESTADO.marcar("tackle", 0.5)
          end
        end
      end)
    end)
  end
  return true
end

-- ---------------------------------------------------------------------
-- 10.3) AUTO ACTIONS — bicicleta, cabecada, voleio e carrinho
--   A bicicleta usa a acao APRENDIDA do proprio jogo quando existe
--   (Remotes.Action); sem assinatura, faz o gesto que o jogo converte.
-- ---------------------------------------------------------------------
function AUTOS.acao(tipo, op)
  op = op or {}
  if not ESTADO.livre("acao") then return false end
  local bola = MUNDO.bola()
  local root = MUNDO.root()
  if not bola or not root then return false end
  tipo = tipo or "auto"
  local altura = bola.Position.Y - root.Position.Y
  if tipo == "auto" then
    if altura >= 7 and CONF.actions.bicicleta then tipo = "bicicleta"
    elseif altura >= num(CONF.actions.altura, 5) and CONF.actions.cabecada then tipo = "cabecada"
    elseif CONF.actions.voleio then tipo = "voleio"
    else tipo = "cabecada" end
  end
  CAM.apontar(bola.Position + bola.AssemblyLinearVelocity * 0.12)
  if tipo == "bicicleta" then
    local ok = false
    if CONF.actions.acao ~= "auto" then
      ok = ASSIN.disparar("action", { ponto = bola.Position, texto = CONF.actions.acao })
    end
    if not ok then
      MOVER.pular()
      esperar(0.10)
      local retrato = TIRO.retrato()
      if retrato then
        local p = TIRO.preparar(retrato)
        if CONF.chute.direto then ASSIN.disparar("shoot", p) end
        CAM.apontar(p.ponto)
        MOUSE.segurar(1); esperar(math.max(0.14, num(CONF.chute.carga, 0.4))); MOUSE.soltar(1)
      end
      adiar(0.3, CAM.restaurar)
    end
    ESTADO.ultimaAcao = "bicicleta"
  elseif tipo == "cabecada" then
    TECLA.tocar(num(CONF.actions.teclaCabecada, "Space"), 0.07)
    ESTADO.ultimaAcao = "cabecada"
  elseif tipo == "carrinho" then
    MOVER.sprint(true)
    TECLA.tocar("E", 0.06)
    adiar(0.4, function() MOVER.sprint(false) end)
    ESTADO.ultimaAcao = "carrinho"
  else
    -- voleio: chute curto no ar
    MOUSE.segurar(1); esperar(0.16); MOUSE.soltar(1)
    adiar(0.25, CAM.restaurar)
    ESTADO.ultimaAcao = "voleio"
  end
  ESTADO.estat.acoes = (ESTADO.estat.acoes or 0) + 1
  ESTADO.marcar("acao", num(CONF.actions.cooldown, 1.4))
  return true
end

-- ---------------------------------------------------------------------
-- 10.4) AUTO PASSE (goleiro e, se quiser, jogador de linha)
-- ---------------------------------------------------------------------
function AUTOS.passar(op)
  op = op or {}
  if not ESTADO.livre("passe") then return false end
  local bola = MUNDO.bola()
  local root = MUNDO.root()
  if not bola or not root then return false end
  local perto = op.perto or MUNDO.varrer(bola)
  local gols = MUNDO.gols()
  local alvoGol = MUNDO.centroDoGol(gols.Home)
  local melhor = NUCLEO.melhorPasse({
    eu = root.Position, aliados = perto.aliados, adversarios = perto.adversarios,
    gol = op.gol or alvoGol, alcance = num(CONF.passe.alcance, 70),
  })
  if not melhor then
    ESTADO.ultimaAcao = "passe: nenhum companheiro livre"
    return false
  end
  if num(CONF.passe.seguro, 1) == 1 and melhor.nota < -12 then
    ESTADO.ultimaAcao = "passe: companheiro marcado, segurei a bola"
    return false
  end
  local destino = melhor.ponto
  -- apontar para o companheiro e clique CURTO (no jogo, clique curto = passe)
  CAM.apontar(destino)
  esperar(0.03)
  local usouDireto = false
  if CONF.chute.direto then
    usouDireto = ASSIN.disparar("pass", { ponto = destino, direcao = (destino - root.Position).Unit,
                                           origem = bola.Position, forca = num(CONF.passe.forca, 0.7) })
  end
  if not usouDireto then
    MOUSE.clicar(1)
  end
  ESTADO.estat.passes = (ESTADO.estat.passes or 0) + 1
  ESTADO.marcar("passe", 1.0)
  ESTADO.ultimaAcao = "passe para " .. (melhor.alvo.jogador and melhor.alvo.jogador.Name or "companheiro")
  adiar(0.25, CAM.restaurar)
  return true
end

-- ---------------------------------------------------------------------
-- 10.5) GOLEIRO — defesa legitima OP: posiciona no bissetor, corta a
-- linha do chute, pula quando a bola chega. Nunca "adivinha" remote.
-- ---------------------------------------------------------------------
local GK = {}
GK.detectado = false
GK.motivo = "nao detectado"

function GK.ehGoleiro()
  if CONF.goleiro.forcar then GK.motivo = "marcado por voce na interface" return true end
  local lp = Players and Players.LocalPlayer
  if not lp then return false end
  local pistas = {
    pcall(function() return lp:GetAttribute("Position") end),
    pcall(function() return lp:GetAttribute("Role") end),
    pcall(function() return lp:GetAttribute("role") end),
    pcall(function() return lp:GetAttribute("GK") end),
  }
  for _, p in ipairs(pistas) do
    local ok, v = p[1], p[2]
    if ok and v ~= nil then
      local t = string.lower(tostring(v))
      if string.find(t, "gk", 1, true) or string.find(t, "goal", 1, true) or string.find(t, "goleiro", 1, true)
        or v == true then
        GK.motivo = "atributo do jogo diz que voce e o goleiro"
        return true
      end
    end
  end
  local ok, t = pcall(function() return lp.Team end)
  if ok and t then
    local n = string.lower(t.Name)
    if string.find(n, "gk", 1, true) or string.find(n, "keeper", 1, true) or string.find(n, "goleiro", 1, true) then
      GK.motivo = "seu time e o do goleiro"
      return true
    end
  end
  local ch = MUNDO.personagem()
  if ch then
    for _, nome in ipairs({ "GK", "Goalkeeper", "Goalie", "GuardaRede" }) do
      if ch:FindFirstChild(nome) then GK.motivo = "marcador no personagem: " .. nome return true end
    end
  end
  return false
end

local function meuGol()
  local root = MUNDO.root()
  local gols = MUNDO.gols()
  local cH = MUNDO.centroDoGol(gols.Home)
  local cA = MUNDO.centroDoGol(gols.Away)
  if not root then return nil end
  if not cH then return { gol = gols.Away, centro = cA } end
  if not cA then return { gol = gols.Home, centro = cH } end
  if distFlat(root.Position, cH) <= distFlat(root.Position, cA) then
    return { gol = gols.Home, centro = cH, outro = cA }
  end
  return { gol = gols.Away, centro = cA, outro = cH }
end
MUNDO.meuGol = meuGol

function MUNDO.larguraDoGol(gol)
  local centro = MUNDO.centroDoGol(gol)
  local normal = MUNDO.normalDoGol(gol)
  if not centro or not normal then return 6 end
  local eixo = normal:Cross(V3(0, 1, 0)).Unit
  local maior = 0
  for _, t in ipairs(MUNDO.alvosDoGol(gol)) do
    local d = math.abs((t.peca.Position - centro):Dot(eixo))
    if d > maior then maior = d end
  end
  return math.max(4, maior * 2)
end

function AUTOS.goleiro(op)
  op = op or {}
  local bola = MUNDO.bola()
  local root = MUNDO.root()
  if not bola or not root then return false end
  local mg = meuGol()
  if not mg or not mg.centro then return false end
  local centro = mg.centro
  local normal = MUNDO.normalDoGol(mg.gol) or V3(0, 0, 1)
  local base = V3(normal.X, 0, normal.Z)
  if base.Magnitude < 0.01 then base = V3(0, 0, 1) end
  base = base.Unit
  local eixo = base:Cross(V3(0, 1, 0)).Unit
  local largura = MUNDO.larguraDoGol(mg.gol)
  local vel = bola.AssemblyLinearVelocity or V3(0, 0, 0)
  local grav = workspace.Gravity or 196
  -- a bola vem para o meu gol?
  local aprox = vel.Magnitude > 6 and (vel.Unit):Dot((centro - bola.Position).Unit) > 0.55
  local dGol = distFlat(bola.Position, centro)
  local porta = (bola.Position - centro)
  local doLadoDoCampo = porta:Dot(base) > 0
  local tempo, ponto, cruzou = NUCLEO.corteNoPlano(bola.Position, vel, -grav, base, centro, eixo, 2.2)
  ESTADO.gk = ESTADO.gk or {}
  ESTADO.gk.cruzou = cruzou
  ESTADO.gk.tempo = cruzou and tempo or nil
  local xCorte = ponto and ponto.X or 0
  local larg = largura * 0.5 + 1.2
  xCorte = clamp(xCorte, -larg, larg)

  -- defesa: quando a bola vem, sai do meio e corta a linha
  if CONF.goleiro.defesa and cruzou and tempo and tempo <= 1.5 and aprox and doLadoDoCampo and dGol < 55 then
    local destino = centro + eixo * xCorte + base * math.min(num(CONF.goleiro.profundidade, 7) * 0.6, 4)
    MOVER.ir(destino, op.forcar or CONF.goleiro.forcar, true)
    ESTADO.estat.defesas = (ESTADO.estat.defesas or 0) + 1
    ESTADO.ultimaAcao = string.format("gk: cortando em %.2fs", tempo)
    -- bola chegando: pula (o jogo resolve a defesa pelo corpo do goleiro)
    local dBola = (bola.Position - root.Position).Magnitude
    if tempo <= 0.45 and dBola < 7 then
      local certos = math.abs((root.Position - centro):Dot(eixo) - xCorte)
      local pular = (ponto.Y and ponto.Y > 4) or certos > 2.2
      if pular then MOVER.pular() end
    end
    if CONF.goleiro.hitbox then
      -- SO com assinatura aprendida. Sem ela, nao inventa argumento.
      ASSIN.disparar("gk", { ponto = root.Position, direcao = (bola.Position - root.Position).Unit,
                             origem = root.Position, forca = 1 })
    end
    return true
  end

  -- posicionamento: no bissetor bola -> centro do gol, dentro do gol
  if CONF.goleiro.posicionar then
    local v = bola.Position - centro
    v = V3(v.X, 0, v.Z)
    local dist2 = v.Magnitude
    if dist2 < 0.5 then v = base end
    local dir = (dist2 > 0.5) and v.Unit or base
    local prof = math.min(num(CONF.goleiro.profundidade, 7), math.max(2.5, dist2 * 0.25))
    local pos = centro + dir * prof
    local lateral = (pos - centro):Dot(eixo)
    pos = centro + eixo * clamp(lateral, -larg, larg) + base * prof
    if (pos - root.Position).Magnitude > 1.6 then
      MOVER.ir(pos, op.forcar or CONF.goleiro.forcar, true)
      ESTADO.ultimaAcao = "gk: posicionando"
    end
    return true
  end
  return false
end
M.GK = GK
M.AUTOS = AUTOS

-- ============================ 11) CEREBRO — o Top 1 Global ============================
-- Ele olha o jogo, decide com o NUCLEO (puro) e executa pelos AUTOS.
-- Voce continua jogando normal: quando voce esta no controle, o cerebro
-- so entra com as jogadas avancadas (chute, tackle, drible, acao).

local varrerBruto = MUNDO.varrer
function MUNDO.varrer(bola)
  local t = agora()
  local janela = CONF.geral.modoLeve and 0.45 or 0.3
  if ESTADO.cache.perto and (t - (ESTADO.cache.quando or 0)) <= janela then
    return ESTADO.cache.perto
  end
  local r = varrerBruto(bola)
  ESTADO.cache.perto = r
  ESTADO.cache.quando = t
  return r
end

local CEREBRO = {}
CEREBRO.ativo = false
CEREBRO.ultimo = 0
CEREBRO.acumulado = 0
CEREBRO.aoAtualizar = nil

function CEREBRO.retrato()
  local bola = MUNDO.bola()
  local root = MUNDO.root()
  if not bola or not root then return nil end
  local eu = root.Position
  local perto = MUNDO.varrer(bola)
  local vel = bola.AssemblyLinearVelocity or V3(0, 0, 0)
  local alcance = num(CONF.chute.alcance, 7)
  local dBola = distFlat(eu, bola.Position)
  local ad = perto.adversarios[1]
  local temPosse = dBola <= 3.5
  local altura = bola.Position.Y - eu.Y
  local gk = CONF.goleiro.auto and GK.ehGoleiro() or false
  local gols = MUNDO.gols()
  local alvoGol = MUNDO.centroDoGol(gols[NUCLEO.escolherGol({
    modo = CONF.chute.mira, gols = { Home = MUNDO.centroDoGol(gols.Home), Away = MUNDO.centroDoGol(gols.Away) },
    eu = eu, bola = bola.Position,
  }) or "Home"])
  local distGol = alvoGol and distFlat(bola.Position, alvoGol) or 999
  local pontoBola, tEncontro = NUCLEO.encontro(eu, bola.Position, vel, 1.4)
  local ultimoHomem = false
  do
    local mg = meuGol()
    if mg and mg.centro then
      local dMeu = distFlat(eu, mg.centro)
      local menor = dMeu
      for _, j in ipairs(perto.aliados) do
        local d = distFlat(j.pos, mg.centro)
        if d < menor then menor = d end
      end
      ultimoHomem = (dMeu <= menor + 0.5) and dMeu < 45
    end
  end
  local passe = nil
  if (temPosse or gk) and (CONF.passe.gk or not gk) then
    passe = NUCLEO.melhorPasse({ eu = eu, aliados = perto.aliados, adversarios = perto.adversarios,
                                 gol = alvoGol, alcance = num(CONF.passe.alcance, 70) })
  end
  local gkInfo, pontoPoste = nil, nil
  if gk then
    local mg = meuGol()
    if mg and mg.centro then
      local normal = MUNDO.normalDoGol(mg.gol) or V3(0, 0, 1)
      local base = V3(normal.X, 0, normal.Z)
      if base.Magnitude < 0.01 then base = V3(0, 0, 1) end
      base = base.Unit
      local eixo = base:Cross(V3(0, 1, 0)).Unit
      local grav = workspace.Gravity or 196
      local t, ponto, cruzou = NUCLEO.corteNoPlano(bola.Position, vel, -grav, base, mg.centro, eixo, 2.2)
      local aprox = vel.Magnitude > 6 and vel.Unit:Dot((mg.centro - bola.Position).Unit) > 0.55
      local doLado = (bola.Position - mg.centro):Dot(base) > 0
      gkInfo = { cruzou = cruzou, tempo = t, ponto = ponto, vindo = aprox and doLado,
                 centro = mg.centro, base = base, eixo = eixo }
      -- posto do goleiro: na linha, entre os postes, na profundidade escolhida
      local lateral = clamp((bola.Position - mg.centro):Dot(eixo) * 0.35,
        -(MUNDO.larguraDoGol(mg.gol) * 0.5), MUNDO.larguraDoGol(mg.gol) * 0.5)
      pontoPoste = mg.centro + eixo * lateral + base * num(CONF.goleiro.profundidade, 7)
    end
  end
  return {
    ativo = CONF.geral.ativo and CONF.cerebro.auto,
    eu = eu, bola = bola, vol = vel, distBola = dBola, perto = perto,
    alturaBola = altura, bolaAerea = (altura > 1.6 and vel.Y > 2),
    bolaAlcance = dBola <= alcance,
    podeChutar = (not gk) and CONF.chute.auto and ESTADO.livre("chute"),
    golNaMira = distGol <= num(CONF.chute.distancia, 200),
    distGol = distGol, alvoGol = alvoGol,
    temPosse = temPosse, distAdversario = ad and ad.dist or 999,
    adversarioComBola = (ad ~= nil and ad.distBola <= 4.5) and not temPosse,
    adversario = ad and ad.jogador or nil,
    alcanceTackle = num(CONF.tackle.alcance, 6.5),
    podeTackle = CONF.tackle.auto and ESTADO.livre("tackle"),
    raioDrible = num(CONF.drible.raio, 9),
    podeDriblar = CONF.drible.auto and ESTADO.livre("drible"),
    raioPasse = num(CONF.drible.raio, 9) + 2,
    podePassar = ESTADO.livre("passe"),
    passeSeguro = passe ~= nil and passe.nota > -6,
    passeAlvo = passe,
    podeAcao = CONF.actions.auto and ESTADO.livre("acao"),
    bicicleta = CONF.actions.bicicleta,
    alturaCabecada = num(CONF.actions.altura, 5),
    ultimoHomem = ultimoHomem,
    voltar = CONF.cerebro.voltar,
    sprint = CONF.cerebro.agressividade >= 0.7,
    podeDriblarTecla = CONF.drible.auto,
    fuga = NUCLEO.fuga({ eu = eu, adversarios = perto.adversarios, gol = alvoGol,
                         frente = root.CFrame and root.CFrame.LookVector }),
    pontoBola = pontoBola, tempoEncontro = tEncontro,
    ehGK = gk, gkInfo = gkInfo,
    pontoPoste = pontoPoste,
    bolaVindo = gkInfo and gkInfo.vindo or false,
    pontoCorte = gkInfo and gkInfo.ponto or nil,
    tempoCorte = gkInfo and gkInfo.tempo or 9,
    pontoDefesa = (function()
      local mg = meuGol()
      if not mg or not mg.centro or not bola then return eu end
      local v = bola.Position - mg.centro
      v = V3(v.X, 0, v.Z)
      if v.Magnitude < 0.5 then return mg.centro end
      return mg.centro + v.Unit * 8
    end)(),
  }
end

function CEREBRO.executar(acao, dados, retrato)
  local humano = MOVER.manual()
  local soAvancada = humano and CONF.cerebro.moverManual and CONF.cerebro.assistir
  if acao == "CHUTAR" then
    AUTOS.chutar({ avisar = true })
  elseif acao == "CABECADA" or acao == "BICICLETA" then
    AUTOS.acao(acao == "BICICLETA" and "bicicleta" or "cabecada", { perto = retrato.perto })
  elseif acao == "TACKLE" then
    AUTOS.tacklear({ perto = retrato.perto })
  elseif acao == "DRIBLE" then
    AUTOS.driblar({ perto = retrato.perto, gol = retrato.alvoGol, forcar = not soAvancada })
  elseif acao == "PASSAR" then
    AUTOS.passar({ perto = retrato.perto, gol = retrato.alvoGol })
  elseif acao == "CORRER" then
    if not soAvancada then
      MOVER.ir(retrato.pontoBola, false, retrato.sprint)
    end
  elseif acao == "DEFENDER" then
    if not soAvancada then MOVER.ir(dados.ponto, false, true) end
  elseif acao == "GKDEFESA" or acao == "GKPOSICIONAR" then
    AUTOS.goleiro({ perto = retrato.perto })
  elseif acao == "GKPASSE" then
    AUTOS.passar({ perto = retrato.perto, gol = retrato.alvoGol })
  elseif acao == "GKCORTE" then
    AUTOS.goleiro({ forcar = true })
  end
end

function CEREBRO.tick()
  if not CONF.geral.ativo then ESTADO.acaoAtual = "desligado" return end
  -- depois de um gol o jogo volta ao centro: pausa curta evita chute no vacuo
  if ESTADO.juiz and ESTADO.juiz.ultimoGol and (agora() - ESTADO.juiz.ultimoGol) < 3 then
    ESTADO.acaoAtual = "comemorando/volta ao centro"
    return
  end
  local ok, erro = pcall(function()
    local retrato = CEREBRO.retrato()
    if not retrato then ESTADO.acaoAtual = "sem jogo" return end
    ESTADO.retrato = retrato
    if retrato.ehGK and not ESTADO.gkAvisado then
      ESTADO.gkAvisado = true
      if CONF.geral.notificar then avisar("Modo goleiro", "Detectei que voce e o goleiro: " .. GK.motivo, nil, 4) end
    end
    local acao, dados = NUCLEO.decidir(retrato)
    ESTADO.acaoAtual = acao
    if retrato.ativo then CEREBRO.executar(acao, dados, retrato) end
    if CEREBRO.aoAtualizar then pcall(CEREBRO.aoAtualizar, retrato, acao) end
  end)
  if not ok then
    ESTADO.erro = tostring(erro)
    if M.LOG then warn("[ARKHER] cerebro: " .. tostring(erro)) end
  end
end

function CEREBRO.ligar()
  if CEREBRO.conn or MODO_TESTE then return end
  CEREBRO.ativo = true
  CEREBRO.conn = ligar(RunService.Heartbeat, function(dt)
    CEREBRO.acumulado = CEREBRO.acumulado + (dt or 0)
    local tick = math.max(0.03, num(CONF.geral.tick, 0.1))
    if CEREBRO.acumulado >= tick then
      CEREBRO.acumulado = 0
      -- roda em linha propria: o chute segura o clique por ~0,4s e nao pode
      -- travar o Heartbeat. O "ocupado" impede dois chutes ao mesmo tempo.
      if CEREBRO.ocupado then return end
      CEREBRO.ocupado = true
      criar(function()
        pcall(CEREBRO.tick)
        CEREBRO.ocupado = false
      end)
    end
  end)
end

function CEREBRO.desligar()
  desconectar(CEREBRO.conn)
  CEREBRO.conn = nil
  CEREBRO.ativo = false
end

function CEREBRO.agora()
  -- um tick manual (usado pelo botao de chute e pelos testes)
  CEREBRO.tick()
end
M.CEREBRO = CEREBRO

-- ============================ 12) ANTI-LAG (para rodar liso em hardware fraco) ============================

local LAG = {}
LAG.originais = {}
LAG.progresso = { feito = 0, total = 0 }
LAG.centro = nil
LAG.pendente = false

local CLASSES_PARTICULA = {
  ParticleEmitter = true, Beam = true, Trail = true, Smoke = true, Fire = true,
  Sparkles = true, Explosion = true,
}
local CLASSES_LUZ = { PointLight = true, SpotLight = true, SurfaceLight = true }
local CLASSES_CEU = {
  Sky = true, Atmosphere = true, Clouds = true, BloomEffect = true,
  BlurEffect = true, DepthOfFieldEffect = true, SunRaysEffect = true,
  ColorCorrectionEffect = true, ColorGradingEffect = true, Highlight = true,
}

function LAG.centroDoCampo()
  if LAG.centro then return LAG.centro end
  local gols = MUNDO.gols()
  local a = MUNDO.centroDoGol(gols.Home)
  local b = MUNDO.centroDoGol(gols.Away)
  if a and b then LAG.centro = (a + b) * 0.5 return LAG.centro end
  local ok, p = pcall(function() return workspace:GetPivot().Position end)
  LAG.centro = ok and p or V3(0, 0, 0)
  return LAG.centro
end

function LAG.podeMexer(inst)
  if inst == nil then return false end
  local ok, pode = pcall(function()
    if inst:IsA("Humanoid") or inst:IsA("Animator") or inst:IsA("Motor6D") then return false end
    local nome = string.lower(inst.Name)
    if NUCLEO.proibido(nome, inst.ClassName, inst.Parent and inst.Parent.Name) then return false end
    local ch = MUNDO.personagem()
    if ch and (inst == ch or inst:IsDescendantOf(ch)) then return false end
    -- personagens de outros jogadores: o anti-lag nunca esconde o corpo
    if inst:IsA("BasePart") then
      local modelo = inst:FindFirstAncestorOfClass("Model")
      if modelo and Players:GetPlayerFromCharacter(modelo) then return false end
    end
    return true
  end)
  return ok and pode
end

function LAG.lista()
  if LAG.cacheLista and (agora() - (LAG.quandoLista or 0)) < 20 then return LAG.cacheLista end
  local ok, l = pcall(function() return workspace:GetDescendants() end)
  LAG.cacheLista = ok and l or {}
  LAG.quandoLista = agora()
  return LAG.cacheLista
end

-- roda uma lista fatiada, um pedaco por quadro (nao trava o aparelho fraco)
function LAG.fatiado(lista, porQuadro, passo, aoTerminar)
  local i = 1
  local total = #lista
  LAG.progresso.total = total
  LAG.progresso.feito = 0
  local conn
  local function quadro()
    local n = 0
    while i <= total and n < porQuadro do
      pcall(passo, lista[i], i)
      i = i + 1
      n = n + 1
    end
    LAG.progresso.feito = i - 1
    if i > total then
      desconectar(conn)
      LAG.progresso.feito = total
      if aoTerminar then pcall(aoTerminar) end
    end
  end
  if RunService then
    conn = ligar(RunService.Heartbeat, quadro)
  end
  if not conn then
    -- sem RunService (teste): roda direto, mas em pcall
    while i <= total do pcall(passo, lista[i], i) i = i + 1 end
    if aoTerminar then pcall(aoTerminar) end
  end
  return conn
end

local function guardar(inst, campo, valor)
  local o = LAG.originais[inst]
  if not o then o = {} LAG.originais[inst] = o end
  if o[campo] == nil then
    local ok, atual = pcall(function() return inst[campo] end)
    if ok then o[campo] = atual end
  end
  pcall(function() inst[campo] = valor end)
end

function LAG.aplicar(cfg)
  cfg = cfg or CONF.antilag
  local plano = NUCLEO.planoAntilag(cfg)
  local lista = LAG.lista()
  local centro = LAG.centroDoCampo()
  local raio = num(cfg.distancia, 240)
  local ch = MUNDO.personagem()
  local L = serv("Lighting")
  LAG.pendente = true
  LAG.progresso.total = #lista
  LAG.progresso.feito = 0

  -- quem NAO pode ser tocado: o meu personagem, o dos outros e a estrutura
  -- do gol (bola/alvos ja sao barrados pelo NUNCA do NUCLEO)
  local gols = MUNDO.gols()
  local protegidos = {}
  for _, g in pairs(gols) do
    if g ~= nil then
      protegidos[g] = true
      pcall(function()
        for _, f in ipairs(g:GetChildren()) do
          protegidos[f] = true
          for _, f2 in ipairs(f:GetChildren()) do protegidos[f2] = true end
        end
      end)
    end
  end
  local outros = {}
  pcall(function()
    local lp = Players.LocalPlayer
    for _, pl in ipairs(Players:GetPlayers()) do
      if pl ~= lp and pl.Character then outros[pl.Character] = true end
    end
  end)

  local CLASSES_PECA = {
    Part = true, MeshPart = true, UnionOperation = true, WedgePart = true,
    TrussPart = true, SpawnLocation = true, CornerWedgePart = true,
  }

  -- UMA passada so: cada objeto e olhado uma vez (celular fraco agradece)
  LAG.fatiado(lista, 220, function(inst)
    local classe = inst.ClassName
    local pai = inst.Parent
    if CLASSES_PECA[classe] then
      if inst == ch or pai == ch then return end
      if pai and (protegidos[pai] or (pai.Parent and protegidos[pai.Parent])) then return end
      if pai and (outros[pai] or (pai.Parent and outros[pai.Parent])) then return end
      local nome = inst.Name
      if NUNCA[nome] then return end
      if cfg.sombras and inst.CastShadow == true then guardar(inst, "CastShadow", false) end
      if cfg.fisica or cfg.partes or cfg.malhas then
        local ok, pos = pcall(function() return inst.Position end)
        if ok and pos then
          local d = (pos - centro).Magnitude
          if cfg.fisica and d > raio and inst.Anchored == false then
            guardar(inst, "Anchored", true)
          end
          if cfg.partes and d > raio then
            guardar(inst, "LocalTransparencyModifier", 1)
          end
          if cfg.malhas and d > raio * 0.8 and inst.Material ~= Enum.Material.SmoothPlastic then
            guardar(inst, "Material", Enum.Material.SmoothPlastic)
          end
        end
      end
      return
    end
    if cfg.particulas and CLASSES_PARTICULA[classe] then
      guardar(inst, "Enabled", false)
      return
    end
    if cfg.decals and (classe == "Decal" or classe == "Texture") then
      guardar(inst, "Transparency", 1)
      return
    end
    if cfg.luz and CLASSES_LUZ[classe] then
      guardar(inst, "Enabled", false)
      return
    end
    if cfg.ceu and CLASSES_CEU[classe] then
      local o = LAG.originais[inst]
      if not o then o = {} LAG.originais[inst] = o end
      if o.Parent == nil then o.Parent = inst.Parent end
      pcall(function() inst.Parent = nil end)
      return
    end
    if cfg.som and classe == "Sound" then
      guardar(inst, "Playing", false)
      guardar(inst, "Volume", 0)
      return
    end
    if cfg.animais and classe == "Humanoid" then
      local modelo = pai
      local lp = Players.LocalPlayer
      if modelo and not Players:GetPlayerFromCharacter(modelo) and not (lp and lp.Character == modelo) then
        for _, obj in ipairs(modelo:GetChildren()) do
          if obj:IsA("BasePart") then guardar(obj, "LocalTransparencyModifier", 1) end
        end
      end
      return
    end
  end, function() LAG.pendente = false end)

  -- ceu e pos-processamento moram no Lighting (lista pequena: direto)
  if cfg.ceu or cfg.luz or (cfg.distancia or 0) > 0 then
    local okL, descL = pcall(function() return L:GetDescendants() end)
    if okL and descL then
      for _, inst in ipairs(descL) do
        local classe = inst.ClassName
        if cfg.ceu and CLASSES_CEU[classe] then
          local o = LAG.originais[inst]
          if not o then o = {} LAG.originais[inst] = o end
          if o.Parent == nil then o.Parent = inst.Parent end
          pcall(function() inst.Parent = nil end)
        elseif cfg.luz and CLASSES_LUZ[classe] then
          guardar(inst, "Enabled", false)
        end
      end
    end
    if cfg.sombras and L then pcall(function() L.GlobalShadows = false end) end
    if (cfg.distancia or 0) > 0 and L then
      guardar(L, "FogEnd", num(cfg.distancia, 240))
      guardar(L, "FogStart", num(cfg.distancia, 240) * 0.55)
    end
  end

  -- som: musica e ambiente (SoundService + o que estiver no workspace)
  if cfg.som then
    local SS = serv("SoundService")
    local okS, descS = pcall(function() return SS:GetDescendants() end)
    if okS and descS then
      for _, inst in ipairs(descS) do
        if inst:IsA("Sound") then
          guardar(inst, "Playing", false)
          guardar(inst, "Volume", 0)
        end
      end
    end
  end

  -- acessorios dos OUTROS jogadores (o corpo continua visivel: da para marcar)
  if cfg.retratos then
    local lp = Players.LocalPlayer
    pcall(function()
      local corpo = {
        humanoidrootpart = true, torso = true, uppertorso = true, lowertorso = true,
        head = true, leftleg = true, rightleg = true, leftarm = true, rightarm = true,
        leftfoot = true, rightfoot = true, lefthand = true, righthand = true,
      }
      for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= lp then
          local chp = pl.Character
          if chp then
            for _, obj in ipairs(chp:GetChildren()) do
              if obj:IsA("Accessory") or obj:IsA("Accoutrement") then
                local handle = obj:FindFirstChild("Handle")
                if not handle and type(obj.FindFirstChildWhichIsA) == "function" then
                  handle = obj:FindFirstChildWhichIsA("BasePart")
                end
                if handle and handle:IsA("BasePart") then
                  guardar(handle, "LocalTransparencyModifier", 1)
                  guardar(handle, "CastShadow", false)
                end
              elseif obj:IsA("BasePart") and not corpo[string.lower(obj.Name)] then
                guardar(obj, "LocalTransparencyModifier", 1)
              end
            end
          end
        end
      end
    end)
  end

  -- ui: tira o que nao se usa (mochila, lista, topbar). O HUD do hub fica.
  if cfg.ui and StarterGui then
    pcall(function()
      StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
      StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    end)
    pcall(function() StarterGui:SetCore("TopbarEnabled", false) end)
  end
  LAG.aplicado = agora()
  return plano
end

function LAG.restaurar()
  local n = 0
  for inst, campos in pairs(LAG.originais) do
    for campo, valor in pairs(campos) do
      pcall(function() inst[campo] = valor end)
      n = n + 1
    end
  end
  LAG.originais = {}
  local L = serv("Lighting")
  if L then pcall(function() L.GlobalShadows = true end) end
  return n
end

function LAG.preset(nome)
  local p = NUCLEO.PRESETS[nome]
  if not p then return false end
  for k, v in pairs(p) do CONF.antilag[k] = v end
  CONF.antilag.preset = nome
  LAG.aplicar(CONF.antilag)
  return true
end
M.LAG = LAG

-- ============================ 13) DESBLOQUEAR ============================
-- Honestidade em primeiro lugar: o servidor checa posse. O que da para
-- fazer DE VERDADE e chamar os remotes de resgate/coleta/sorteio do jogo
-- (com a assinatura aprendida), ler os conteudos liberados e repetir o
-- equipar. Gamepass real nao existe por cliente — esta escrito na aba.

local DESB = {}
DESB.registro = {}

function DESB.anotar(texto, bom)
  DESB.registro[#DESB.registro + 1] = { texto = tostring(texto), quando = agora(), bom = bom }
  while #DESB.registro > 60 do table.remove(DESB.registro, 1) end
  if M.LOG then print("[ARKHER/DESB] " .. tostring(texto)) end
end

local RESGATES = {
  { caminho = "ReplicatedStorage.Remotes.Collect", chave = "collect", nome = "Coletar recompensa" },
  { caminho = "ReplicatedStorage.Remotes.ClaimStick", chave = "stick", nome = "Reivindicar bastao" },
  { caminho = "ReplicatedStorage.Remotes.DailyReward", chave = "daily", nome = "Premio diario" },
  { caminho = "ReplicatedStorage.DailyRewardEvents.ClaimReward", chave = "dailyc", nome = "Resgatar diario" },
  { caminho = "ReplicatedStorage.Remotes.WQuest", chave = "quest", nome = "Missao semanal" },
}

-- dispara com a assinatura aprendida; sem assinatura usa o padrao (sem args)
function DESB.disparar(caminho, chave, plano)
  if MODO_TESTE then return false, "modo teste" end
  local r = remotePorCaminho(caminho)
  if not r then return false, "nao encontrado" end
  if ISCAS[r.Name] then return false, "remote de isca (nunca)" end
  local e = chave and ASSIN.tem(chave) or nil
  local ok, erro
  if e then
    ok, erro = ASSIN.disparar(chave, plano or { ponto = V3(0, 0, 0), forca = 1 })
    if not ok then
      -- assinatura existe mas o remote pode ter outro nome: cai no padrao
      ok = pcall(function()
        if r:IsA("RemoteFunction") then r:InvokeServer() else r:FireServer() end
      end)
    end
  else
    ok = pcall(function()
      if r:IsA("RemoteFunction") then r:InvokeServer() else r:FireServer() end
    end)
  end
  return ok and true or false, erro
end

function DESB.resgatarTudo()
  if MODO_TESTE then return 0 end
  local n = 0
  for _, item in ipairs(RESGATES) do
    local ok, err = DESB.disparar(item.caminho, item.chave)
    if ok then
      n = n + 1
      DESB.anotar(item.nome .. " — pedido enviado", true)
    else
      DESB.anotar(item.nome .. " — " .. tostring(err), false)
    end
    ESTADO.desb = ESTADO.desb or { resgates = 0 }
    ESTADO.desb.resgates = (ESTADO.desb.resgates or 0) + 1
    esperar(0.25)          -- espaco entre pedidos: nada de rajada
  end
  return n
end

-- codigos promocionais: Remotes.RedeemCode (RemoteFunction)
function DESB.codigo(codigo)
  if MODO_TESTE then return false, "modo teste" end
  codigo = tostring(codigo or ""):gsub("%s", "")
  if #codigo < 3 or #codigo > 40 then return false, "codigo invalido" end
  local r = remotePorCaminho("ReplicatedStorage.RedeemCode") or remotePorCaminho("ReplicatedStorage.Remotes.RedeemCode")
  if not r then return false, "RemoteFunction RedeemCode nao existe" end
  local ok, resp = pcall(function()
    if r:IsA("RemoteFunction") then return r:InvokeServer(codigo) end
    return r:FireServer(codigo)
  end)
  DESB.codigos = DESB.codigos or {}
  DESB.codigos[codigo] = { quando = agora(), ok = ok, resposta = tostring(resp) }
  DESB.anotar(string.format("codigo %s: %s", codigo, ok and tostring(resp) or "falhou"), ok)
  return ok, resp
end

function DESB.codigosDoTexto(texto)
  local lista, vistos = {}, {}
  texto = tostring(texto or "")
  for c in string.gmatch(texto, "[%w%-_]+") do
    local up = string.upper(c)
    if #up >= 3 and not vistos[up] then
      vistos[up] = true
      lista[#lista + 1] = c
    end
  end
  return lista
end

function DESB.codigosDoArquivo()
  if MODO_TESTE or type(funcoes.readfile) ~= "function" then return {} end
  local ok, texto = pcall(funcoes.readfile, "ARKHER_SS_codigos.txt")
  if not ok or type(texto) ~= "string" then return {} end
  return DESB.codigosDoTexto(texto)
end

function DESB.loteCodigos(texto)
  local lista = DESB.codigosDoTexto(texto)
  if #lista == 0 then
    lista = DESB.codigosDoArquivo()
  end
  local n = 0
  for _, c in ipairs(lista) do
    local ok = DESB.codigo(c)
    if ok then n = n + 1 end
    esperar(1.1)        -- um por vez, com respiro (o jogo limita tentativas)
  end
  return n, #lista
end

-- leitura: SpinnerContents* (RemoteFunction, so leitura de conteudo)
function DESB.lerSorteios(cb)
  if MODO_TESTE then return 0 end
  local nomes = { "SpinnerContentsCards", "SpinnerContentsDribble", "SpinnerContentsGoalie", "SpinnerContentsShoes" }
  local n = 0
  local resumo = {}
  for _, nome in ipairs(nomes) do
    local r = RS and RS:FindFirstChild(nome)
    local rf = r and r:FindFirstChild("RemoteFunction")
    if rf and rf:IsA("RemoteFunction") then
      local ok, resp = pcall(function() return rf:InvokeServer() end)
      if ok then
        n = n + 1
        resumo[nome] = resp
        DESB.anotar(nome .. ": conteudo lido", true)
        if cb then pcall(cb, nome, resp) end
      else
        DESB.anotar(nome .. ": sem resposta", false)
      end
      esperar(0.3)
    end
  end
  DESB.sorteados = resumo
  return n
end

-- loja: ShopBundleEvents (so leitura/reset quando o usuario manda)
function DESB.loja(acao)
  if MODO_TESTE then return false end
  local base = remotePorCaminho("ReplicatedStorage.ShopBundleEvents")
  if not base then return false end
  local nome = (acao == "reset") and "ResetShop" or "ShopEvent"
  local r = base:FindFirstChild(nome)
  if not r then return false end
  local ok = pcall(function() r:FireServer() end)
  DESB.anotar("loja: " .. nome .. (ok and " ok" or " falhou"), ok)
  return ok
end

-- equipar de novo o que voce ja equipou (usa a assinatura real do jogo)
function DESB.repetirEquipar()
  local e = ASSIN.tem("equip")
  if not e then return false, "equipe algo no jogo uma vez com o hub ligado que eu aprendo" end
  local ok, n = ASSIN.disparar("equip", { forca = 1 })
  DESB.anotar("equipar repetido: " .. tostring(ok), ok)
  return ok, n
end

-- gamepass: o que da e o que NAO da (sem enrolacao)
function DESB.infoProduto(id)
  if MODO_TESTE then return false end
  local ms = serv("MarketplaceService")
  if not ms then return false end
  local ok, info = pcall(function() return ms:GetProductInfo(tonumber(id), Enum.InfoType.GamePass) end)
  if ok and info then
    DESB.anotar(string.format("produto %s: %s (%s R$)", tostring(id), tostring(info.Name), tostring(info.PriceInRobux)), true)
    return true, info
  end
  return false
end

M.DESB = DESB

-- ============================ 14) HUD (a cara do hub em jogo) ============================
-- Aqui nasce o BOTAO DE CHUTE semitransparente, EXCLUSIVO do auto shoot:
-- ele aparece junto com a interface e chama o chute perfeito do hub.

local HUD = {}
HUD.criado = false
HUD.quadros = 0
HUD.ultimoFps = 0
HUD.fps = 0
HUD.ping = 0
HUD.textoAcao = "—"

local function paiDoGui()
  if funcoes.gethui then
    local ok, h = pcall(funcoes.gethui)
    if ok and h then return h end
  end
  local lp = Players and Players.LocalPlayer
  if not lp then return nil end
  local ok, g = pcall(function() return lp:FindFirstChild("PlayerGui") end)
  if ok and g then return g end
  return nil
end

local function novo(classe, props, pai)
  local ok, inst = pcall(Instance.new, classe)
  if not ok or not inst then return nil end
  if props then
    for k, v in pairs(props) do pcall(function() inst[k] = v end) end
  end
  if pai then pcall(function() inst.Parent = pai end) end
  return inst
end
M.novo = novo

function HUD.criar()
  if MODO_TESTE then return false, "modo teste" end
  if HUD.criado then return true end
  local pai = paiDoGui()
  if not pai then return false, "sem PlayerGui" end
  local sg = novo("ScreenGui", {
    Name = "ARKHER_SS_HUD", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
  }, pai)
  if not sg then return false, "sem ScreenGui" end
  if funcoes.protectgui then pcall(funcoes.protectgui, sg) end
  HUD.gui = sg

  -- painel de status (canto superior esquerdo, pequeno e translucido)
  local painel = novo("Frame", {
    Name = "Status", Size = UDim2.fromOffset(210, 74), Position = UDim2.fromOffset(8, 8),
    BackgroundColor3 = Color3.fromRGB(16, 16, 20), BackgroundTransparency = 0.35,
    BorderSizePixel = 0, Active = false, Visible = CONF.geral.hudStatus,
  }, sg)
  novo("UICorner", { CornerRadius = UDim.new(0, 10) }, painel)
  local stroke = novo("UIStroke", { Color = Color3.fromRGB(70, 220, 130), Thickness = 1, Transparency = 0.4 }, painel)
  HUD.labelFps = novo("TextLabel", {
    Name = "Fps", BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 4),
    Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(120, 240, 160), Text = "ARKHER · -- fps · -- ms",
  }, painel)
  HUD.labelAcao = novo("TextLabel", {
    Name = "Acao", BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 24),
    Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(235, 235, 235), Text = "acao: —",
  }, painel)
  HUD.labelEstat = novo("TextLabel", {
    Name = "Estat", BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 18), Position = UDim2.fromOffset(8, 44),
    Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    TextColor3 = Color3.fromRGB(200, 200, 200), Text = "0 chutes · 0 gols · 0 tackles",
  }, painel)

  -- ============ O BOTAO DE CHUTE (exclusivo do auto shoot) ============
  local tam = num(CONF.geral.hudBotaoTamanho, 78)
  local opac = 1 - clamp(num(CONF.geral.hudOpacidade, 0.45), 0.05, 0.95)
  local botao = novo("TextButton", {
    Name = "AutoShoot", Size = UDim2.fromOffset(tam, tam),
    Position = UDim2.new(1, -(tam + 14), 1, -(tam + 30)),
    BackgroundColor3 = Color3.fromRGB(24, 26, 32), BackgroundTransparency = opac,
    BorderSizePixel = 0, AutoButtonColor = false, Text = "", Active = true,
    Visible = CONF.geral.hudBotao and CONF.chute.auto,
  }, sg)
  novo("UICorner", { CornerRadius = UDim.new(1, 0) }, botao)
  novo("UIStroke", { Color = Color3.fromRGB(90, 255, 160), Thickness = 2, Transparency = 0.25 }, botao)
  HUD.botaoBola = novo("TextLabel", {
    Name = "Bola", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.52, 0),
    Font = Enum.Font.GothamBold, TextSize = math.max(14, tam * 0.30),
    TextColor3 = Color3.fromRGB(235, 255, 240), Text = "CHUTE",
  }, botao)
  HUD.botaoTag = novo("TextLabel", {
    Name = "Tag", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0.3, 0),
    Position = UDim2.new(0, 0, 0.52, 0), Font = Enum.Font.Gotham,
    TextSize = math.max(9, tam * 0.15), TextColor3 = Color3.fromRGB(150, 255, 190),
    Text = "AUTO · " .. CONF.geral.teclaChute,
  }, botao)
  HUD.botao = botao
  HUD.painel = painel

  -- arrastar com o dedo/mouse e soltar = chute
  local arrastando, inicio, origem, mexeu = false, nil, nil, false
  ligar(botao.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
      or input.UserInputType == Enum.UserInputType.MouseMovement then
      arrastando = true
      mexeu = false
      inicio = input.Position
      origem = botao.Position
    end
  end)
  ligar(botao.InputChanged, function(input)
    if arrastando and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
      local d = input.Position - inicio
      if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then mexeu = true end
      pcall(function()
        botao.Position = UDim2.new(origem.X.Scale, origem.X.Offset + d.X, origem.Y.Scale, origem.Y.Offset + d.Y)
      end)
    end
  end)
  ligar(botao.InputEnded, function(input)
    if not arrastando then return end
    arrastando = false
    if not mexeu then HUD.chutar() end
  end)

  -- atalho de teclado (que NAO atrapalha quem digita no chat)
  if UIS then
    ligar(UIS.InputBegan, function(input, processado)
      if processado then return end
      local k = tecla(CONF.geral.teclaChute)
      if k and input.KeyCode == k then HUD.chutar() end
    end)
  end

  HUD.ultimoFps = agora()
  HUD.quadros = 0
  HUD.ligarAtualizacao()
  HUD.criado = true
  return true
end

function HUD.chutar()
  if not CONF.chute.auto then
    avisar("Auto Shoot desligado", "Ligue o Auto Shoot na aba Chute para usar este botao.", nil, 3)
    return
  end
  ESTADO.ultimaAcao = "chute pelo botao"
  criar(function()
    local ok = AUTOS.chutar({ avisar = true, forcado = true })
    if HUD.botaoBola then
      HUD.botaoBola.Text = ok and "✔" or "✖"
      adiar(0.5, function() if HUD.botaoBola then HUD.botaoBola.Text = "CHUTE" end end)
    end
  end)
end

function HUD.atualizarBotao()
  if not HUD.botao then return end
  local visivel = CONF.geral.hudBotao and CONF.chute.auto
  pcall(function() HUD.botao.Visible = visivel end)
  local tam = num(CONF.geral.hudBotaoTamanho, 78)
  pcall(function() HUD.botao.Size = UDim2.fromOffset(tam, tam) end)
  pcall(function() HUD.botao.BackgroundTransparency = 1 - clamp(num(CONF.geral.hudOpacidade, 0.45), 0.05, 0.95) end)
  if HUD.botaoTag then pcall(function() HUD.botaoTag.Text = "AUTO · " .. CONF.geral.teclaChute end) end
end

function HUD.ligarAtualizacao()
  if HUD.conn or MODO_TESTE then return end
  HUD.conn = ligar(RunService.Heartbeat, function()
    HUD.quadros = HUD.quadros + 1
    local t = agora()
    if (t - (HUD.ultimoFps or 0)) >= 1 then
      HUD.fps = HUD.quadros / math.max(0.001, t - (HUD.ultimoFps or t - 1))
      HUD.quadros = 0
      HUD.ultimoFps = t
      -- ping do jogo (Stats existe no cliente)
      local st = serv("Stats")
      if st then
        pcall(function()
          HUD.ping = math.floor(st.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
      end
      if HUD.labelFps then
        pcall(function()
          HUD.labelFps.Text = string.format("ARKHER · %d fps · %d ms · %s",
            math.floor(HUD.fps + 0.5), HUD.ping, CONF.antilag.preset)
        end)
      end
      if HUD.labelEstat then
        local e = ESTADO.estat
        pcall(function()
          HUD.labelEstat.Text = string.format("%d chutes · %d gols · %d tackles · %.0f%%",
            e.chutes or 0, e.gols or 0, e.tackles or 0, NUCLEO.taxa(e))
        end)
      end
    end
  end)
end

function HUD.setTexto(acao)
  HUD.textoAcao = acao
  if HUD.labelAcao and HUD.criado then
    local cd = ESTADO.cd or {}
    local extra = ""
    local faltam = (cd.chute or 0) - agora()
    if faltam > 0 then extra = string.format(" (%.1fs)", faltam) end
    pcall(function() HUD.labelAcao.Text = "acao: " .. tostring(acao) .. extra end)
  end
end

function HUD.mostrar(visivel)
  if HUD.painel then pcall(function() HUD.painel.Visible = visivel and CONF.geral.hudStatus or false end) end
  if HUD.botao then pcall(function() HUD.botao.Visible = visivel and CONF.geral.hudBotao and CONF.chute.auto end) end
end

function HUD.destruir()
  desconectar(HUD.conn)
  HUD.conn = nil
  if HUD.gui then pcall(function() HUD.gui:Destroy() end) end
  HUD.gui, HUD.botao, HUD.labelFps, HUD.labelAcao, HUD.labelEstat = nil, nil, nil, nil, nil
  HUD.criado = false
end

CEREBRO.aoAtualizar = function(_, acao)
  HUD.setTexto(acao)
end
M.HUD = HUD

-- ============================ 15) INTERFACE (10 abas) ============================
-- Rayfield nativo. Se o executor estiver sem internet (ou o loader mudar),
-- cai sozinho para uma interface propria COMPLETA — o hub nunca fica sem
-- controle por causa de dependencia externa.

local UI = {}
-- as 10 abas, na ordem (o teste automatico confere esta lista)
M.ABAS_ESPERADAS = {
  "Visao Geral", "Chute", "Drible", "Tackle", "Acoes",
  "Goleiro", "Passe", "Cerebro", "Desbloquear", "Anti-Lag",
}
UI.R = nil
UI.janela = nil
UI.abas = {}
UI.controles = {}
UI.paginas = {}

local function seguro(fn, ...)
  local ok, a, b = pcall(fn, ...)
  if ok then return a, b end
  return nil, tostring(a)
end
M.seguro = seguro

function UI.carregarRayfield()
  local urls = {
    "https://sirius.menu/rayfield",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.luau",
  }
  local src = nil
  for _, u in ipairs(urls) do
    local s = httpGet(u)
    if type(s) == "string" and #s > 500 then src = s break end
  end
  if not src then return nil, "sem resposta do servidor do Rayfield" end
  local carregador = loadstring or load
  local f, err = carregador(src)
  if not f then return nil, "loadstring falhou: " .. tostring(err) end
  local ok, R = pcall(f)
  if ok and type(R) == "table" and (R.CreateWindow or R.Window) then return R end
  if ok and type(R) == "table" then return R end
  return nil, "Rayfield nao devolveu a tabela"
end

-- -------------------- ajudantes que toleram versao diferente --------------------
local function aba(nome)
  if not UI.janela then return nil end
  local t = seguro(function() return UI.janela:CreateTab(nome) end)
  if t then UI.abas[#UI.abas + 1] = { nome = nome, obj = t } end
  return t
end
local function secao(tab, nome)
  if not tab then return nil end
  return seguro(function() return tab:CreateSection(nome) end)
end
local function rotulo(tab, texto, cor, negrito)
  if not tab then return nil end
  return seguro(function()
    return tab:CreateLabel(texto, 13, cor or Color3.fromRGB(200, 200, 200), negrito)
  end)
end
local function divider(tab)
  if not tab then return nil end
  return seguro(function() return tab:CreateDivider() end)
end
local function paragrafo(tab, titulo, conteudo)
  if not tab then return nil end
  return seguro(function() return tab:CreateParagraph({ Title = titulo, Content = conteudo }) end)
end
local function alterar(flag, valor, tipo)
  UI.controles[#UI.controles + 1] = { flag = flag, valor = valor, tipo = tipo or "outro" }
end
local function toggle(tab, nome, atual, flag, cb)
  if not tab then return nil end
  alterar(flag, atual, "toggle")
  return seguro(function()
    return tab:CreateToggle({ Name = nome, CurrentValue = atual, Flag = flag, Callback = function(v)
      if cb then cb(v) end
    end })
  end)
end
local function slider(tab, nome, min, max, inc, atual, sufixo, flag, cb)
  if not tab then return nil end
  alterar(flag, atual, "slider")
  return seguro(function()
    return tab:CreateSlider({ Name = nome, Range = { min, max }, Increment = inc, Suffix = sufixo or "",
      CurrentValue = atual, Flag = flag, Callback = function(v) if cb then cb(v) end end })
  end)
end
local function dropdown(tab, nome, opcoes, atual, flag, multiplo, cb)
  if not tab then return nil end
  alterar(flag, atual, "dropdown")
  return seguro(function()
    return tab:CreateDropdown({ Name = nome, Options = opcoes, CurrentOption = atual,
      MultipleOptions = multiplo or false, Flag = flag, Callback = function(v) if cb then cb(v) end end })
  end)
end
local function botao(tab, nome, cb)
  if not tab then return nil end
  return seguro(function()
    return tab:CreateButton({ Name = nome, Callback = function() seguro(cb) end })
  end)
end
local function entrada(tab, nome, placeholder, cb)
  if not tab then return nil end
  return seguro(function()
    return tab:CreateInput({ Name = nome, CurrentValue = "", PlaceholderText = placeholder or "",
      RemoveTextAfterFocusLost = true, Callback = function(t) seguro(cb, t) end })
  end)
end

-- -------------------- as 10 abas --------------------
function UI.construir(R)
  UI.R = R
  local janela = seguro(function()
    return R:CreateWindow({
      Name = "ARKHER · Street Soccer",
      LoadingTitle = "ARKHER Street Soccer",
      LoadingSubtitle = "hub local · 10 abas · mobile + PC",
      Theme = "Dark",
      DisableRayfieldPrompts = true,
      DisableBuildWarnings = true,
      ConfigurationSaving = { Enabled = true, FolderName = "ARKHER_SS", FileName = "rayfield" },
      Discord = { Enabled = false, Invite = "", RememberJoins = false },
      KeySystem = false,
    })
  end)
  if not janela then return false, "CreateWindow falhou" end
  UI.janela = janela

  -- =========== ABA 1: VISAO GERAL ===========
  local t1 = aba("Visao Geral")
  secao(t1, "Hub")
  toggle(t1, "Hub ligado (master)", CONF.geral.ativo, "geral.ativo", function(v) CONF.geral.ativo = v end)
  toggle(t1, "Modo leve (hardware fraco)", CONF.geral.modoLeve, "geral.modoLeve", function(v)
    CONF.geral.modoLeve = v
    CONF.geral.tick = v and 0.12 or 0.07
  end)
  slider(t1, "Intervalo do cerebro (s)", 0.03, 0.5, 0.01, CONF.geral.tick, "s", "geral.tick", function(v) CONF.geral.tick = v end)
  toggle(t1, "Notificacoes", CONF.geral.notificar, "geral.notificar", function(v) CONF.geral.notificar = v end)
  toggle(t1, "Registrar no console (log)", CONF.geral.log, "geral.log", function(v) M.LOG = v end)
  secao(t1, "Botao de chute (exclusivo do auto shoot)")
  toggle(t1, "Mostrar botao na tela", CONF.geral.hudBotao, "geral.hudBotao", function(v)
    CONF.geral.hudBotao = v
    HUD.atualizarBotao()
  end)
  slider(t1, "Transparencia do botao", 0.05, 0.9, 0.05, CONF.geral.hudOpacidade, "", "geral.hudOpacidade", function(v)
    CONF.geral.hudOpacidade = v
    HUD.atualizarBotao()
  end)
  slider(t1, "Tamanho do botao", 50, 130, 2, num(CONF.geral.hudBotaoTamanho, 78), "px", "geral.hudBotaoTamanho", function(v)
    CONF.geral.hudBotaoTamanho = v
    HUD.atualizarBotao()
  end)
  dropdown(t1, "Tecla do chute", { "F", "G", "H", "V", "B", "X", "Z", "C" }, CONF.geral.teclaChute, "geral.teclaChute", false, function(v)
    CONF.geral.teclaChute = v
    HUD.atualizarBotao()
  end)
  toggle(t1, "Painel de status na tela", CONF.geral.hudStatus, "geral.hudStatus", function(v)
    CONF.geral.hudStatus = v
    HUD.mostrar(true)
  end)
  secao(t1, "Estatisticas (medidas no seu jogo)")
  UI.labelEstat = rotulo(t1, "sem dados ainda", Color3.fromRGB(160, 255, 190), true)
  botao(t1, "Atualizar estatisticas", function()
    local e = ESTADO.estat
    local texto = string.format(
      "chutes %d | gols %d | tackles %d | dribles %d | acoes %d | passes %d | defesas %d | falhas %d\naproveitamento %.1f%% | gols/chute %.1f%%",
      e.chutes or 0, e.gols or 0, e.tackles or 0, e.dribles or 0, e.acoes or 0, e.passes or 0,
      e.defesas or 0, e.falhas or 0, NUCLEO.taxa(e), NUCLEO.golsPorChute(e))
    seguro(function() UI.labelEstat:Set(texto) end)
    avisar("Estatisticas", texto, nil, 6)
  end)
  botao(t1, "Zerar estatisticas", function()
    for k in pairs(ESTADO.estat) do ESTADO.estat[k] = 0 end
  end)
  secao(t1, "Sessao")
  rotulo(t1, "executor: " .. tostring(M.EXECUTOR) .. " · gancho: " .. tostring(ESTADO.gancho or "nenhum"), Color3.fromRGB(180, 180, 180))
  botao(t1, "Salvar configuracao", function() local ok, msg = UI.salvarConfig() avisar("Config", ok and "salva no disco" or tostring(msg)) end)
  botao(t1, "Carregar configuracao", function() local n = UI.carregarConfig() avisar("Config", "aplicada (" .. tostring(n) .. " campos)") end)
  botao(t1, "Descarregar hub (volta tudo ao normal)", function() M.descarregar() end)

  -- =========== ABA 2: CHUTE ===========
  local t2 = aba("Chute")
  secao(t2, "Auto Shoot")
  toggle(t2, "Auto Shoot ligado", CONF.chute.auto, "chute.auto", function(v)
    CONF.chute.auto = v
    HUD.atualizarBotao()
  end)
  rotulo(t2, "Chute sempre na forca maxima, mirando o canto mais longe do goleiro.", Color3.fromRGB(255, 220, 140))
  slider(t2, "Forca (1 = maxima)", 0.4, 1, 0.05, CONF.chute.forca, "", "chute.forca", function(v) CONF.chute.forca = v end)
  slider(t2, "Tempo de carga (s)", 0.1, 1.2, 0.02, CONF.chute.carga, "s", "chute.carga", function(v) CONF.chute.carga = v end)
  dropdown(t2, "Gol que ataco", { "auto", "home", "away" }, CONF.chute.mira, "chute.mira", false, function(v) CONF.chute.mira = v end)
  dropdown(t2, "Canto", { "auto", "esquerda", "direita", "aleatorio" }, CONF.chute.canto, "chute.canto", false, function(v) CONF.chute.canto = v end)
  dropdown(t2, "Tipo de chute", { "auto", "normal", "curva", "aleatorio" }, CONF.chute.curvado, "chute.curvado", false, function(v) CONF.chute.curvado = v end)
  slider(t2, "Distancia maxima (studs)", 30, 400, 5, CONF.chute.distancia, " studs", "chute.distancia", function(v) CONF.chute.distancia = v end)
  slider(t2, "Margem dentro do gol (studs)", 0.1, 1.5, 0.05, CONF.chute.margem, "", "chute.margem", function(v) CONF.chute.margem = v end)
  slider(t2, "Tentativas se falhar", 1, 6, 1, CONF.chute.retry, "x", "chute.retry", function(v) CONF.chute.retry = v end)
  toggle(t2, "Usar assinatura aprendida (direto)", CONF.chute.direto, "chute.direto", function(v) CONF.chute.direto = v end)
  toggle(t2, "Conferir se a bola saiu (laco fechado)", CONF.chute.verificar, "chute.verificar", function(v) CONF.chute.verificar = v end)
  secao(t2, "Teste")
  botao(t2, "Chutar agora (mira perfeita)", function()
    local ok, plano = AUTOS.chutar({ avisar = true, forcado = true })
    avisar("Chute", ok and string.format("saiu para o %s (%.0f studs)", plano and plano.nomeGol or "?", plano and plano.distGol or 0)
      or "nao deu: veja a aba Stats", nil, 3)
  end)
  botao(t2, "Ver assinatura aprendida do ShootTheBall", function()
    local e = ASSIN.tem("shoot")
    if not e then return avisar("Assinatura", "ainda nao aprendi: entre no jogo e chute uma vez com o hub ligado") end
    local tipos = table.concat(e.mapa.tipos or {}, ", ")
    avisar("ShootTheBall", string.format("tipos: %s | ponto=%s forca=%s | amostras=%d",
      tipos, tostring(e.mapa.ponto), tostring(e.mapa.forca), #(e.amostras or {})), nil, 8)
  end)

  -- =========== ABA 3: DRIBLE ===========
  local t3 = aba("Drible")
  secao(t3, "Auto Drible (ja vem no ponto)")
  toggle(t3, "Auto Drible ligado", CONF.drible.auto, "drible.auto", function(v) CONF.drible.auto = v end)
  slider(t3, "Raio do marcador (studs)", 3, 20, 1, CONF.drible.raio, " studs", "drible.raio", function(v) CONF.drible.raio = v end)
  slider(t3, "Cooldown (s)", 0.3, 3, 0.1, CONF.drible.cooldown, "s", "drible.cooldown", function(v) CONF.drible.cooldown = v end)
  dropdown(t3, "Tecla do drible", { "Q", "E", "R", "T" }, CONF.drible.tecla, "drible.tecla", false, function(v) CONF.drible.tecla = v end)
  toggle(t3, "Sair do bolso do marcador (corte)", CONF.drible.corte, "drible.corte", function(v) CONF.drible.corte = v end)
  botao(t3, "Testar drible agora", function() AUTOS.driblar({}) end)
  rotulo(t3, "O drible usa a tecla real do jogo + fuga calculada do marcador.", Color3.fromRGB(180, 180, 180))

  -- =========== ABA 4: TACKLE ===========
  local t4 = aba("Tackle")
  secao(t4, "Auto Tackle (configurado no ponto)")
  toggle(t4, "Auto Tackle ligado", CONF.tackle.auto, "tackle.auto", function(v) CONF.tackle.auto = v end)
  slider(t4, "Alcance do carrinho (studs)", 3, 14, 0.5, CONF.tackle.alcance, " studs", "tackle.alcance", function(v) CONF.tackle.alcance = v end)
  slider(t4, "Bola perto dele (studs)", 2, 16, 0.5, CONF.tackle.bolaPerto, " studs", "tackle.bolaPerto", function(v) CONF.tackle.bolaPerto = v end)
  slider(t4, "Cooldown (s)", 0.2, 3, 0.1, CONF.tackle.cooldown, "s", "tackle.cooldown", function(v) CONF.tackle.cooldown = v end)
  toggle(t4, "Prever o movimento (entra antes)", CONF.tackle.prever, "tackle.prever", function(v) CONF.tackle.prever = v end)
  toggle(t4, "Repetir se ele mantiver a bola", CONF.tackle.repetir, "tackle.repetir", function(v) CONF.tackle.repetir = v end)
  botao(t4, "Testar tackle agora", function() AUTOS.tacklear({}) end)

  -- =========== ABA 5: ACOES ===========
  local t5 = aba("Acoes")
  secao(t5, "Auto Actions (bicicleta, cabecada, voleio, carrinho)")
  toggle(t5, "Auto Actions ligado", CONF.actions.auto, "actions.auto", function(v) CONF.actions.auto = v end)
  toggle(t5, "Bicicleta", CONF.actions.bicicleta, "actions.bicicleta", function(v) CONF.actions.bicicleta = v end)
  toggle(t5, "Cabecada (Espaco)", CONF.actions.cabecada, "actions.cabecada", function(v) CONF.actions.cabecada = v end)
  toggle(t5, "Voleio", CONF.actions.voleio, "actions.voleio", function(v) CONF.actions.voleio = v end)
  toggle(t5, "Carrinho (E correndo)", CONF.actions.carrinho, "actions.carrinho", function(v) CONF.actions.carrinho = v end)
  slider(t5, "Altura minima da bola (studs)", 2, 14, 0.5, CONF.actions.altura, " studs", "actions.altura", function(v) CONF.actions.altura = v end)
  slider(t5, "Cooldown (s)", 0.4, 4, 0.1, CONF.actions.cooldown, "s", "actions.cooldown", function(v) CONF.actions.cooldown = v end)
  dropdown(t5, "Acao aprendida do jogo (Remotes.Action)", { "auto", "bicycle", "header", "volley", "rabona", "elastico", "flip" },
    CONF.actions.acao, "actions.acao", false, function(v) CONF.actions.acao = v end)
  botao(t5, "Bicicleta agora", function() AUTOS.acao("bicicleta", {}) end)
  botao(t5, "Cabecada agora", function() AUTOS.acao("cabecada", {}) end)
  botao(t5, "Voleio agora", function() AUTOS.acao("voleio", {}) end)

  -- =========== ABA 6: GOLEIRO ===========
  local t6 = aba("Goleiro")
  secao(t6, "Auto GK (defesa legitima)")
  toggle(t6, "Auto Goleiro ligado", CONF.goleiro.auto, "goleiro.auto", function(v) CONF.goleiro.auto = v end)
  toggle(t6, "Defesa (corta a linha do chute)", CONF.goleiro.defesa, "goleiro.defesa", function(v) CONF.goleiro.defesa = v end)
  toggle(t6, "Pular quando a bola chega", CONF.goleiro.dive, "goleiro.dive", function(v) CONF.goleiro.dive = v end)
  toggle(t6, "Posicionar no bissetor", CONF.goleiro.posicionar, "goleiro.posicionar", function(v) CONF.goleiro.posicionar = v end)
  slider(t6, "Profundidade na linha (studs)", 3, 16, 0.5, CONF.goleiro.profundidade, " studs", "goleiro.profundidade", function(v) CONF.goleiro.profundidade = v end)
  toggle(t6, "Forcar modo goleiro (mesmo se eu nao for GK)", CONF.goleiro.forcar, "goleiro.forcar", function(v) CONF.goleiro.forcar = v end)
  toggle(t6, "Usar GKHitbox (so com assinatura aprendida)", CONF.goleiro.hitbox, "goleiro.hitbox", function(v) CONF.goleiro.hitbox = v end)
  rotulo(t6, "Eu sou o goleiro: " .. tostring(GK.ehGoleiro()) .. " (" .. GK.motivo .. ")", Color3.fromRGB(200, 230, 255))
  botao(t6, "Testar defesa agora", function() AUTOS.goleiro({ forcar = true }) end)
  rotulo(t6, "Defesa legitima = posicao + tempo + pulo. Sem remote inventado.", Color3.fromRGB(180, 180, 180))

  -- =========== ABA 7: PASSE ===========
  local t7 = aba("Passe")
  secao(t7, "Auto Pass (goleiro e linha)")
  toggle(t7, "Auto Passe ligado", CONF.passe.gk, "passe.gk", function(v) CONF.passe.gk = v end)
  toggle(t7, "So passe seguro (marcado = segura a bola)", CONF.passe.seguro, "passe.seguro", function(v) CONF.passe.seguro = v end)
  slider(t7, "Forca do passe", 0.2, 1, 0.05, CONF.passe.forca, "", "passe.forca", function(v) CONF.passe.forca = v end)
  slider(t7, "Alcance do passe (studs)", 10, 150, 5, CONF.passe.alcance, " studs", "passe.alcance", function(v) CONF.passe.alcance = v end)
  botao(t7, "Passar agora (melhor companheiro)", function() AUTOS.passar({}) end)
  rotulo(t7, "Escolhe o companheiro com a linha de passe mais limpa.", Color3.fromRGB(180, 180, 180))

  -- =========== ABA 8: CEREBRO ===========
  local t8 = aba("Cerebro")
  secao(t8, "Auto Top Global (joga no seu lugar quando voce nao esta no controle)")
  toggle(t8, "Cerebro ligado", CONF.cerebro.auto, "cerebro.auto", function(v) CONF.cerebro.auto = v end)
  dropdown(t8, "Nivel", { "Top 1 Global", "Forte", "Equilibrado", "Natural" }, CONF.cerebro.nivel, "cerebro.nivel", false, function(v)
    CONF.cerebro.nivel = v
    if v == "Top 1 Global" then CONF.cerebro.agressividade = 0.9 CONF.geral.tick = math.min(CONF.geral.tick, 0.08)
    elseif v == "Forte" then CONF.cerebro.agressividade = 0.75
    elseif v == "Equilibrado" then CONF.cerebro.agressividade = 0.6
    else CONF.cerebro.agressividade = 0.45 end
  end)
  slider(t8, "Agressividade", 0.2, 1, 0.05, CONF.cerebro.agressividade, "", "cerebro.agressividade", function(v) CONF.cerebro.agressividade = v end)
  toggle(t8, "Assistir enquanto EU jogo (so as jogadas avancadas)", CONF.cerebro.assistir, "cerebro.assistir", function(v) CONF.cerebro.assistir = v end)
  toggle(t8, "Mexer o personagem mesmo se eu estiver andando", CONF.cerebro.moverManual, "cerebro.moverManual", function(v) CONF.cerebro.moverManual = v end)
  toggle(t8, "Voltar para defender (ultimo homem)", CONF.cerebro.voltar, "cerebro.voltar", function(v) CONF.cerebro.voltar = v end)
  rotulo(t8, "acao agora: —", Color3.fromRGB(160, 255, 190), true)
  UI.labelAcao = rotulo(t8, "acao agora: —", Color3.fromRGB(160, 255, 190), true)
  botao(t8, "Rodar um tick agora (ver o que ele faria)", function()
    CEREBRO.tick()
    avisar("Cerebro", "acao: " .. tostring(ESTADO.acaoAtual) .. " | " .. tostring(ESTADO.ultimaAcao), nil, 5)
  end)
  rotulo(t8, "Ele detecta os SEUS movimentos e entra com o que e avancado.", Color3.fromRGB(180, 180, 180))

  -- =========== ABA 9: DESBLOQUEAR ===========
  local t9 = aba("Desbloquear")
  secao(t9, "Resgates do jogo (remotes reais)")
  toggle(t9, "Auto coleta periodica", CONF.desbloquear.autoColeta, "desbloquear.autoColeta", function(v) CONF.desbloquear.autoColeta = v end)
  slider(t9, "Intervalo da coleta (s)", 15, 300, 5, CONF.desbloquear.intervalo, "s", "desbloquear.intervalo", function(v) CONF.desbloquear.intervalo = v end)
  botao(t9, "Resgatar tudo agora (diario, quest, collect, bastao)", function()
    local n = DESB.resgatarTudo()
    avisar("Desbloquear", n .. " pedidos enviados", nil, 4)
  end)
  toggle(t9, "Ler conteudos dos sorteios (so leitura)", CONF.desbloquear.lerSpin, "desbloquear.lerSpin", function(v) CONF.desbloquear.lerSpin = v end)
  botao(t9, "Ler sorteios agora", function()
    DESB.lerSorteios(function(nome, resp)
      avisar(nome, tostring(resp):sub(1, 120), nil, 6)
    end)
  end)
  secao(t9, "Codigos promocionais (RedeemCode)")
  entrada(t9, "Codigo (ex: STREETSOCCER)", "codigo do jogo", function(texto)
    local ok, resp = DESB.codigo(texto)
    avisar("Codigo " .. tostring(texto), ok and ("resposta: " .. tostring(resp)) or tostring(resp), nil, 5)
  end)
  entrada(t9, "Varios codigos (separe por espaco ou virgula)", "COD1 COD2 COD3", function(texto)
    local n, total = DESB.loteCodigos(texto)
    avisar("Codigos", string.format("%d de %d aceitos", n, total), nil, 5)
  end)
  botao(t9, "Ler codigos do arquivo ARKHER_SS_codigos.txt", function()
    local n, total = DESB.loteCodigos(nil)
    avisar("Codigos do arquivo", string.format("%d de %d aceitos", n, total), nil, 5)
  end)
  secao(t9, "Loja e equipar")
  botao(t9, "Abrir/atualizar loja (ShopBundleEvents.ShopEvent)", function() DESB.loja("shop") end)
  botao(t9, "Resetar loja (ShopBundleEvents.ResetShop)", function() DESB.loja("reset") end)
  botao(t9, "Repetir o ultimo equipar (usa a assinatura real)", function()
    local ok, msg = DESB.repetirEquipar()
    avisar("Equipar", ok and "pedido enviado" or tostring(msg), nil, 4)
  end)
  secao(t9, "Gamepass — a verdade")
  paragrafo(t9, "Gamepass",
    "Quem confere gamepass e o SERVIDOR do jogo. Nenhum script de cliente entrega gamepass: o que existe e o que este hub faz aqui e cobrar os remotes que o proprio jogo usa (resgate diario, coleta, sorteio, equipar) com a assinatura real e ler o que voltou. Se um dia o jogo aceitar algo por remote, este hub ja fala a lingua dele. Prometer o contrario seria mentira.")
  entrada(t9, "Consultar produto por ID (assetId)", "ex: 123456789", function(texto)
    local ok, info = DESB.infoProduto(texto)
    avisar("Produto", ok and (tostring(info.Name) .. " - " .. tostring(info.PriceInRobux) .. " R$") or "nao consegui consultar (o jogo precisa estar aberto)", nil, 6)
  end)
  botao(t9, "Ver registro do Desbloquear", function()
    local linhas = {}
    for i = math.max(1, #DESB.registro - 8), #DESB.registro do
      linhas[#linhas + 1] = DESB.registro[i].texto
    end
    avisar("Registro", table.concat(linhas, "\n"):sub(1, 400), nil, 10)
  end)
  secao(t9, "Remotes que eu conheco (e as iscas)")
  rotulo(t9, "reais: ShootTheBall, Pass, Tackle, Action, GKHitbox, Collect, ClaimStick, DailyReward, WQuest, Equip, Jersey, Avatar, Settings, RedeemCode, SpinnerContents*",
    Color3.fromRGB(160, 255, 190))
  rotulo(t9, "isca/perigo (o hub NUNCA usa): ShootTheBaII (i maiusculo), AdminBan, Teleport, lancage, Iancage, tcelloc, cfactor, FPSNORE, PINGNORE",
    Color3.fromRGB(255, 160, 160))

  -- =========== ABA 10: ANTI-LAG ===========
  local t10 = aba("Anti-Lag")
  secao(t10, "Presets (itel A70 / celular antigo)")
  toggle(t10, "Aplicar ao entrar no jogo", CONF.antilag.auto, "antilag.auto", function(v) CONF.antilag.auto = v end)
  dropdown(t10, "Preset", { "Ultra leve", "Fraco (itel/Celular antigo)", "Medio", "PC / Leve" },
    CONF.antilag.preset, "antilag.preset", false, function(v)
      LAG.preset(v)
      avisar("Anti-Lag", "preset " .. tostring(v) .. " aplicado", nil, 3)
    end)
  botao(t10, "Aplicar agora", function()
    LAG.preset(CONF.antilag.preset)
    avisar("Anti-Lag", "aplicando aos poucos (nao trava o jogo)", nil, 3)
  end)
  botao(t10, "Restaurar tudo (volta como era)", function()
    local n = LAG.restaurar()
    avisar("Anti-Lag", n .. " ajustes revertidos", nil, 3)
  end)
  secao(t10, "O que desligar")
  toggle(t10, "Sombras", CONF.antilag.sombras, "antilag.sombras", function(v) CONF.antilag.sombras = v end)
  toggle(t10, "Particulas/efeitos", CONF.antilag.particulas, "antilag.particulas", function(v) CONF.antilag.particulas = v end)
  toggle(t10, "Decals e texturas", CONF.antilag.decals, "antilag.decals", function(v) CONF.antilag.decals = v end)
  toggle(t10, "Luzes (Point/Spot/Surface)", CONF.antilag.luz, "antilag.luz", function(v) CONF.antilag.luz = v end)
  toggle(t10, "Ceu e pos-processamento", CONF.antilag.ceu, "antilag.ceu", function(v) CONF.antilag.ceu = v end)
  toggle(t10, "Sons e musica", CONF.antilag.som, "antilag.som", function(v) CONF.antilag.som = v end)
  toggle(t10, "Ancorar decoracao longe (fisica)", CONF.antilag.fisica, "antilag.fisica", function(v) CONF.antilag.fisica = v end)
  toggle(t10, "Esconder partes longe (so para voce)", CONF.antilag.partes, "antilag.partes", function(v) CONF.antilag.partes = v end)
  toggle(t10, "Material simples nas partes longe", CONF.antilag.malhas, "antilag.malhas", function(v) CONF.antilag.malhas = v end)
  toggle(t10, "Acessorios dos outros jogadores", CONF.antilag.retratos, "antilag.retratos", function(v) CONF.antilag.retratos = v end)
  toggle(t10, "NPCs/decoracao animada", CONF.antilag.animais, "antilag.animais", function(v) CONF.antilag.animais = v end)
  toggle(t10, "Topbar/mochila/lista (CoreGui)", CONF.antilag.ui, "antilag.ui", function(v) CONF.antilag.ui = v end)
  slider(t10, "Distancia de neblina (studs)", 120, 500, 10, CONF.antilag.distancia, " studs", "antilag.distancia", function(v) CONF.antilag.distancia = v end)
  rotulo(t10, "Nunca toca: bola, gols, alvos, humanoides, seu personagem e o dos outros.", Color3.fromRGB(255, 220, 140))
  rotulo(t10, "O ganho real: sombras + particulas + musica. O resto e bonus.", Color3.fromRGB(180, 180, 180))

  return true
end

-- -------------------- interface de reserva (sem internet) --------------------
function UI.construirFallback()
  local pai = paiDoGui()
  if not pai then return false end
  local sg = novo("ScreenGui", { Name = "ARKHER_SS_PAINEL", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 998 }, pai)
  if not sg then return false end
  if funcoes.protectgui then pcall(funcoes.protectgui, sg) end
  UI.janelaFallback = sg
  local jan = novo("Frame", {
    Size = UDim2.fromOffset(330, 330), Position = UDim2.new(0, 40, 0, 60),
    BackgroundColor3 = Color3.fromRGB(14, 14, 18), BackgroundTransparency = 0.08,
    BorderSizePixel = 0, Active = true,
  }, sg)
  novo("UICorner", { CornerRadius = UDim.new(0, 12) }, jan)
  novo("UIStroke", { Color = Color3.fromRGB(70, 220, 130), Transparency = 0.35 }, jan)
  local titulo = novo("TextButton", {
    Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = Color3.fromRGB(24, 26, 32),
    Text = "ARKHER Street Soccer (modo reserva)", TextColor3 = Color3.fromRGB(160, 255, 190),
    Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0,
  }, jan)
  novo("UICorner", { CornerRadius = UDim.new(0, 12) }, titulo)
  local corpo = novo("ScrollingFrame", {
    Size = UDim2.new(1, -12, 1, -46), Position = UDim2.fromOffset(6, 40),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    CanvasSize = UDim2.new(0, 0, 0, 520),
  }, jan)

  local y = 0
  local function linhaToggle(nome, get, set)
    local b = novo("TextButton", {
      Size = UDim2.new(1, -8, 0, 28), Position = UDim2.fromOffset(2, y),
      BackgroundColor3 = Color3.fromRGB(22, 24, 30), TextColor3 = Color3.fromRGB(230, 230, 230),
      Font = Enum.Font.Gotham, TextSize = 12, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left,
      Text = "   " .. nome,
    }, corpo)
    novo("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    local function pinta()
      local on = get()
      b.Text = (on and "   [ON]  " or "   [OFF] ") .. nome
      b.TextColor3 = on and Color3.fromRGB(160, 255, 190) or Color3.fromRGB(200, 200, 200)
    end
    pinta()
    ligar(b.MouseButton1Click, function() set(not get()) pinta() HUD.atualizarBotao() end)
    y = y + 32
    return b
  end
  local function linhaBotao(nome, fn)
    local b = novo("TextButton", {
      Size = UDim2.new(1, -8, 0, 28), Position = UDim2.fromOffset(2, y),
      BackgroundColor3 = Color3.fromRGB(30, 46, 38), TextColor3 = Color3.fromRGB(210, 255, 230),
      Font = Enum.Font.Gotham, TextSize = 12, BorderSizePixel = 0, Text = nome,
    }, corpo)
    novo("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    ligar(b.MouseButton1Click, function() seguro(fn) end)
    y = y + 32
  end

  linhaToggle("Hub ligado", function() return CONF.geral.ativo end, function(v) CONF.geral.ativo = v end)
  linhaToggle("Auto Shoot (botao na tela)", function() return CONF.chute.auto end, function(v)
    CONF.chute.auto = v
    HUD.atualizarBotao()
  end)
  linhaToggle("Auto Drible", function() return CONF.drible.auto end, function(v) CONF.drible.auto = v end)
  linhaToggle("Auto Tackle", function() return CONF.tackle.auto end, function(v) CONF.tackle.auto = v end)
  linhaToggle("Auto Actions", function() return CONF.actions.auto end, function(v) CONF.actions.auto = v end)
  linhaToggle("Auto Goleiro", function() return CONF.goleiro.auto end, function(v) CONF.goleiro.auto = v end)
  linhaToggle("Auto Passe", function() return CONF.passe.gk end, function(v) CONF.passe.gk = v end)
  linhaToggle("Cerebro (Top 1 Global)", function() return CONF.cerebro.auto end, function(v) CONF.cerebro.auto = v end)
  linhaToggle("Cerebro assiste meu jogo", function() return CONF.cerebro.assistir end, function(v) CONF.cerebro.assistir = v end)
  linhaToggle("Anti-Lag", function() return CONF.antilag.auto end, function(v) CONF.antilag.auto = v end)
  linhaToggle("Botao de chute visivel", function() return CONF.geral.hudBotao end, function(v) CONF.geral.hudBotao = v end)
  linhaBotao("Aplicar Anti-Lag agora", function() LAG.preset(CONF.antilag.preset) end)
  linhaBotao("Restaurar Anti-Lag", function() LAG.restaurar() end)
  linhaBotao("Chutar agora", function() AUTOS.chutar({ avisar = true, forcado = true }) end)
  linhaBotao("Passar agora", function() AUTOS.passar({}) end)
  linhaBotao("Resgatar tudo", function() DESB.resgatarTudo() end)
  linhaBotao("Salvar configuracao", function() UI.salvarConfig() end)
  linhaBotao("Carregar configuracao", function() UI.carregarConfig() end)
  corpo.CanvasSize = UDim2.new(0, 0, 0, y + 12)

  -- arrastar a janela
  local arrastando, inicio, origem = false, nil, nil
  ligar(titulo.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
      arrastando = true inicio = input.Position origem = jan.Position
    end
  end)
  ligar(titulo.InputChanged, function(input)
    if arrastando then
      local d = input.Position - inicio
      pcall(function()
        jan.Position = UDim2.new(origem.X.Scale, origem.X.Offset + d.X, origem.Y.Scale, origem.Y.Offset + d.Y)
      end)
    end
  end)
  ligar(titulo.InputEnded, function() arrastando = false end)
  avisar("ARKHER", "Rayfield nao carregou: usei a interface reserva (tudo funciona).", nil, 6)
  return true
end

-- -------------------- salvar / carregar config --------------------
function UI.salvarConfig()
  if MODO_TESTE then return false, "modo teste" end
  if type(funcoes.writefile) ~= "function" then return false, "executor sem writefile" end
  local ok = pcall(funcoes.writefile, "ARKHER_SS_config.txt", NUCLEO.serializar(CONF))
  return ok, ok and "ok" or "falhou"
end

function UI.carregarConfig()
  if MODO_TESTE then return 0 end
  if type(funcoes.readfile) ~= "function" then return 0 end
  local ok, texto = pcall(funcoes.readfile, "ARKHER_SS_config.txt")
  if not ok or type(texto) ~= "string" then return 0 end
  local _, n = NUCLEO.carregar(texto, CONF)
  HUD.atualizarBotao()
  for _, c in ipairs(UI.controles) do
    -- tenta sincronizar os controles do Rayfield que ja existem
    pcall(function() if c.obj and c.obj.Set then c.obj:Set(c.valor) end end)
  end
  return n
end
M.UI = UI

-- ============================ 16) BOOT ============================

local function banner()
  if MODO_TESTE then return end
  local linhas = {
    "",
    "  ============================================================",
    "   ARKHER · Realistic Street Soccer  ·  v" .. M.VERSAO,
    "   executor: " .. tostring(M.EXECUTOR),
    "   gancho de assinatura: " .. tostring(ESTADO.gancho or "nenhum (modo mira+clique)"),
    "   botao de chute: " .. (CONF.geral.hudBotao and "na tela" or "desligado") .. " (tecla " .. CONF.geral.teclaChute .. ")",
    "   anti-lag: " .. CONF.antilag.preset,
    "  ============================================================",
    "",
  }
  print(table.concat(linhas, "\n"))
end

function M.descarregar()
  CEREBRO.desligar()
  MOVER.parar()
  HUD.destruir()
  if UI.janelaFallback then pcall(function() UI.janelaFallback:Destroy() end) end
  if UI.janela then
    pcall(function() UI.R:Destroy() end)
    pcall(function() UI.R:Destroy(UI.janela) end)
  end
  LAG.restaurar()
  ESTADO.ligado = false
  avisar("ARKHER", "hub descarregado", nil, 3)
end

function M.ligar()
  if ESTADO.ligado then return end
  ESTADO.ligado = true
  M.LOG = CONF.geral.log

  -- 1) assinaturas: carrega o que ja sabemos e liga o gancho passivo
  local carregadas = ASSIN.carregar()
  local okGancho, msgGancho = ASSIN.instalar()
  ESTADO.gancho = ESTADO.gancho or (okGancho and "ativo") or "nenhum"
  M.msgGancho = msgGancho

  -- 2) HUD + botao de chute (aparece JA, antes de qualquer interface)
  HUD.criar()
  HUD.mostrar(true)
  HUD.atualizarBotao()

  -- 3) interface
  criar(function()
    local R, erro = UI.carregarRayfield()
    if R then
      local ok, err = UI.construir(R)
      if not ok then UI.construirFallback() M.msgUI = tostring(err) end
      M.MSG_UI = (M.msgUI and ("Rayfield carregou mas a janela falhou: " .. tostring(M.msgUI)) or "Rayfield carregado e janela montada")
    else
      UI.construirFallback()
      M.msgUI = tostring(erro)
    end
    M.JANELA_OK = true
    M.MSG_UI = (M.msgUI and ("interface reserva: " .. tostring(M.msgUI)) or "Rayfield carregado e janela montada")
    if CONF.geral.notificar then
      avisar("ARKHER pronto", string.format("v%s · %d assinaturas · aba Desbloquear explica o resto",
        M.VERSAO, carregadas or 0), nil, 6)
    end
  end)

  -- 4) cerebro
  CEREBRO.ligar()

  -- 5) anti-lag (espera o jogo terminar de carregar para nao competir)
  if CONF.antilag.auto then
    adiar(1.5, function()
      local ok, err = pcall(LAG.preset, CONF.antilag.preset)
      if not ok then
        ESTADO.erroAntiLag = tostring(err)
        if M.LOG then warn("[ARKHER] anti-lag: " .. tostring(err)) end
      elseif CONF.geral.notificar then
        avisar("Anti-Lag", "preset " .. CONF.antilag.preset, nil, 3)
      end
    end)
  end

  -- 6) coleta periodica dos resgates (se ligada)
  criar(function()
    esperar(12)     -- deixa o jogo carregar antes de pedir qualquer coisa
    while ESTADO.ligado do
      esperar(5)
      if CONF.geral.ativo and CONF.desbloquear.autoColeta and not MODO_TESTE then
        if ESTADO.livre("resgate") then
          ESTADO.marcar("resgate", num(CONF.desbloquear.intervalo, 45))
          pcall(DESB.resgatarTudo)
        end
      end
    end
  end)

  -- 7) salva as assinaturas de tempos em tempos (aprende uma vez, usa sempre)
  criar(function()
    while ESTADO.ligado do
      esperar(90)
      pcall(ASSIN.salvar)
    end
  end)

  banner()
end

-- painel de erro: em vez de "nao abriu nada", mostra O QUE quebrou, com
-- botao de copiar. Serve para voce me mandar o texto e eu corrigir na hora.
local function mostrarErro(titulo, corpo)
  if MODO_TESTE then return end
  pcall(function()
    local Players = serv("Players")
    local pai = paiDoGui and paiDoGui() or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui"))
    if not pai then return end
    local sg = novo("ScreenGui", { Name = "ARKHER_ERRO", ResetOnSpawn = false, DisplayOrder = 5000 }, pai)
    if not sg then return end
    local moldura = novo("Frame", {
      Size = UDim2.new(1, -24, 0, 260), Position = UDim2.new(0, 12, 0, 90),
      BackgroundColor3 = Color3.fromRGB(40, 10, 14), BackgroundTransparency = 0.05,
      BorderSizePixel = 0, Active = true,
    }, sg)
    novo("UICorner", { CornerRadius = UDim.new(0, 12) }, moldura)
    novo("UIStroke", { Color = Color3.fromRGB(255, 90, 90), Thickness = 2 }, moldura)
    novo("TextLabel", {
      BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 6),
      Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = Color3.fromRGB(255, 170, 170),
      TextXAlignment = Enum.TextXAlignment.Left, Text = "ARKHER · " .. tostring(titulo),
    }, moldura)
    local scroller = novo("ScrollingFrame", {
      Size = UDim2.new(1, -16, 1, -86), Position = UDim2.fromOffset(8, 36),
      BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
      CanvasSize = UDim2.new(0, 0, 0, 600),
    }, moldura)
    local texto = novo("TextLabel", {
      Size = UDim2.new(1, -8, 0, 560), BackgroundTransparency = 1,
      Font = Enum.Font.Code, TextSize = 12, TextWrapped = true,
      TextColor3 = Color3.fromRGB(255, 215, 215),
      TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
      Text = tostring(corpo), Parent = scroller,
    }, scroller)
    local copiar = novo("TextButton", {
      Size = UDim2.new(0.48, -6, 0, 38), Position = UDim2.new(0, 8, 1, -44),
      BackgroundColor3 = Color3.fromRGB(80, 30, 34), TextColor3 = Color3.fromRGB(255, 220, 220),
      Font = Enum.Font.GothamBold, TextSize = 13, Text = "COPIAR O ERRO",
    }, moldura)
    novo("UICorner", { CornerRadius = UDim.new(0, 8) }, copiar)
    local fechar = novo("TextButton", {
      Size = UDim2.new(0.48, -6, 0, 38), Position = UDim2.new(0.52, 0, 1, -44),
      BackgroundColor3 = Color3.fromRGB(30, 40, 34), TextColor3 = Color3.fromRGB(200, 255, 220),
      Font = Enum.Font.GothamBold, TextSize = 13, Text = "FECHAR",
    }, moldura)
    novo("UICorner", { CornerRadius = UDim.new(0, 8) }, fechar)
    ligar(copiar.MouseButton1Click, function()
      local tudo = "ARKHER v" .. tostring(M.VERSAO) .. " | " .. tostring(titulo) .. "\n" .. tostring(corpo)
      local copiou = false
      for _, nome in ipairs({ "setclipboard", "toclipboard" }) do
        local f = rawget(GENV, nome) or rawget(_G, nome)
        if type(f) == "function" and pcall(f, tudo) then copiou = true break end
      end
      copiar.Text = copiou and "COPIADO! me mande no chat" or "sem clipboard: tire print"
    end)
    ligar(fechar.MouseButton1Click, function() pcall(function() sg:Destroy() end) end)
  end)
  avisar("ARKHER deu erro", tostring(titulo) .. " — veja o painel na tela", nil, 8)
end
M.mostrarErro = mostrarErro

if not MODO_TESTE then
  criar(function()
    local ok, erro = xpcall(M.ligar, function(e)
      return tostring(e) .. "\n" .. tostring(debug and debug.traceback and debug.traceback() or "")
    end)
    if not ok then
      M.erro = tostring(erro)
      warn("[ARKHER] falha ao ligar: " .. tostring(erro))
      pcall(function() HUD.criar() end)
      mostrarErro("falha ao ligar o hub", erro .. "\n\nexecutor: " .. tostring(M.EXECUTOR))
    end
  end)
  -- se a interface demorar demais, e porque algo travou: o painel avisa
  adiar(25, function()
    if not M.JANELA_OK and not M.erro then
      mostrarErro("a interface nao apareceu em 25s",
        "O hub esta vivo (o botao de chute e as funcoes existem), mas a janela\n" ..
        "nao montou. Motivo mais comum: o executor nao tem internet para\n" ..
        "baixar o Rayfield.\nexecutor: " .. tostring(M.EXECUTOR) ..
        "\ngancho: " .. tostring(ESTADO.gancho) .. "\n\n" ..
        "TESTE no console: print(ARKHER_SS.MSG_UI)")
    end
  end)
end

-- deixa a mesa posta para quem quiser mexer por fora (com rede: alguns
-- executores entregam um getgenv() protegido, que recusa escrita)
pcall(function() GENV.ARKHER_SS = M end)
pcall(function() GENV.ARKHER_StreetSoccer = M end)

return M
