-- MTC ESP Lite: focused rewrite of EdgeIY/Infinite Yield's ESP concept.
-- Upstream MIT attribution: see LICENSE-InfiniteYield.txt.
-- Client only. Team/seat detection uses generic Roblox data, not MTC internals.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local me = Players.LocalPlayer
assert(me, "MTC ESP Lite must run on the client")
local playerGui = me:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("MTC_ESPLite")
if previous then
    local stop = previous:FindFirstChild("Stop")
    if stop and stop:IsA("BindableEvent") then stop:Fire() end
    previous:Destroy()
end

local settings = {enabled = true, allies = true, enemies = true, unknown = true,
    through = true, silhouettes = false, seat = true, range = 1500}
local colors = {ally = Color3.fromRGB(65, 156, 255), enemy = Color3.fromRGB(255, 79, 90),
    unknown = Color3.fromRGB(175, 184, 198)}
local records, connections = {}, {}
local running = true
local gui = Instance.new("ScreenGui")
gui.Name = "MTC_ESPLite"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
local stop = Instance.new("BindableEvent")
stop.Name = "Stop"
stop.Parent = gui
local marks = Instance.new("Folder")
marks.Name = "Markers"
marks.Parent = gui

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(connections, c)
    return c
end
local function text(parent, value, size)
    return new("TextLabel", {Size = UDim2.new(1, 0, 0, size or 24), BackgroundTransparency = 1,
        Text = value, TextColor3 = Color3.fromRGB(220, 228, 240), TextSize = 14,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left}, parent)
end
local function button(parent, value, callback)
    local b = new("TextButton", {Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Color3.fromRGB(36, 47, 65),
        BorderSizePixel = 0, Text = value, TextColor3 = Color3.fromRGB(235, 240, 250),
        Font = Enum.Font.Gotham, TextSize = 13, AutoButtonColor = true}, parent)
    new("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
    local click = connect(b.Activated, callback)
    return b, click
end

local panel = new("Frame", {Position = UDim2.new(0, 14, 0, 60), Size = UDim2.fromOffset(350, 540),
    BackgroundColor3 = Color3.fromRGB(19, 25, 36), BorderSizePixel = 0}, gui)
new("UICorner", {CornerRadius = UDim.new(0, 10)}, panel)
local scale = new("UIScale", {}, panel)
local body = new("ScrollingFrame", {Position = UDim2.fromOffset(12, 10), Size = UDim2.new(1, -24, 1, -20),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, panel)
new("UIListLayout", {Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder}, body)
local order = 0
local function ordered(obj)
    order = order + 1
    obj.LayoutOrder = order
    return obj
end
ordered(text(body, "MTC / ESP LITE", 28)).Font = Enum.Font.GothamBold
ordered(text(body, "Distance seule · bleu allié · rouge ennemi", 22))
local summary = ordered(text(body, "Initialisation…", 22))
local refreshers = {}
local function toggle(key, label)
    local b
    local function refresh() b.Text = label .. (settings[key] and " : OUI" or " : NON") end
    b = ordered(button(body, "", function() settings[key] = not settings[key]; refresh() end))
    refreshers[key] = refresh
    refresh()
end
toggle("enabled", "ESP actif")
toggle("enemies", "Ennemis")
toggle("allies", "Alliés")
toggle("unknown", "Équipe inconnue (gris)")
toggle("through", "Voir à travers les obstacles")
toggle("silhouettes", "Silhouettes des personnages")
toggle("seat", "Ancrer au siège si assis")
local ranges = {500, 1500, 3000, math.huge}
local rangeIndex = 2
local rangeButton
rangeButton = ordered(button(body, "Portée : 1500 studs", function()
    rangeIndex = rangeIndex % #ranges + 1
    settings.range = ranges[rangeIndex]
    rangeButton.Text = "Portée : " .. (settings.range == math.huge and "illimitée" or tostring(settings.range) .. " studs")
end))
local search = ordered(new("TextBox", {Size = UDim2.new(1, 0, 0, 32), Text = "",
    PlaceholderText = "Filtrer la liste des joueurs…", ClearTextOnFocus = false,
    BackgroundColor3 = Color3.fromRGB(30, 40, 56), TextColor3 = Color3.new(1, 1, 1),
    PlaceholderColor3 = Color3.fromRGB(155, 165, 180), Font = Enum.Font.Gotham, TextSize = 13}, body))
ordered(text(body, "Joueurs : auto → allié → ennemi → masqué", 24))
local list = ordered(new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1}, body))
new("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.Name}, list)
ordered(button(body, "Réinitialiser les choix individuels", function()
    for _, r in pairs(records) do r.mode = "auto" end
end))
ordered(text(body, "Insert : panneau · F8 : ESP · réglages de session", 24))
ordered(button(body, "Arrêter et supprimer l’interface", function() stop:Fire() end))
local reopen = button(gui, "ESP / MENU", function() panel.Visible = not panel.Visible end)
reopen.Position = UDim2.fromOffset(14, 14)
reopen.Size = UDim2.fromOffset(140, 34)

local function cleanup()
    if not running then return end
    running = false
    for _, c in ipairs(connections) do c:Disconnect() end
    for _, r in pairs(records) do
        if r.highlight then r.highlight:Destroy() end
    end
    gui:Destroy()
end
connect(stop.Event, cleanup)
connect(gui.Destroying, cleanup)
connect(UIS.InputBegan, function(input, processed)
    if processed or UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.Insert then panel.Visible = not panel.Visible end
    if input.KeyCode == Enum.KeyCode.F8 then
        settings.enabled = not settings.enabled
        refreshers.enabled()
    end
end)

local modes = {auto = "ally", ally = "enemy", enemy = "hidden", hidden = "auto"}
local modeNames = {auto = "AUTO", ally = "ALLIÉ", enemy = "ENNEMI", hidden = "MASQUÉ"}
local function add(p)
    if p == me or records[p] then return end
    local r = {mode = "auto"}
    records[p] = r
    r.billboard = new("BillboardGui", {Name = tostring(p.UserId), Size = UDim2.fromOffset(105, 26),
        StudsOffsetWorldSpace = Vector3.new(0, 3, 0), AlwaysOnTop = true, Enabled = false}, marks)
    r.label = text(r.billboard, "", 26)
    r.label.TextXAlignment = Enum.TextXAlignment.Center
    r.label.Font = Enum.Font.GothamBold
    r.label.TextSize = 16
    r.label.TextStrokeTransparency = 0.2
    r.row, r.click = button(list, "", function() r.mode = modes[r.mode] end)
    r.row.Name = string.lower(p.Name) .. "_" .. tostring(p.UserId)
end
local function remove(p)
    local r = records[p]
    if not r then return end
    if r.highlight then r.highlight:Destroy() end
    r.click:Disconnect()
    local index = table.find(connections, r.click)
    if index then table.remove(connections, index) end
    r.billboard:Destroy()
    r.row:Destroy()
    records[p] = nil
end
connect(Players.PlayerAdded, add)
connect(Players.PlayerRemoving, remove)
for _, p in ipairs(Players:GetPlayers()) do add(p) end

local function relation(p, mode)
    if mode == "ally" or mode == "enemy" then return mode end
    if me.Neutral or p.Neutral or not me.Team or not p.Team then return "unknown" end
    return p.Team == me.Team and "ally" or "enemy"
end
local elapsed = 0
connect(RunService.Heartbeat, function(dt)
    elapsed = elapsed + dt
    if elapsed < 0.1 then return end
    elapsed = 0
    local camera = workspace.CurrentCamera
    if camera then
        scale.Scale = math.clamp(math.min((camera.ViewportSize.X - 28) / 350,
            (camera.ViewportSize.Y - 74) / 540, 1), 0.25, 1)
    end
    local ownRoot = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
    local origin = ownRoot and ownRoot.Position
    local shown, missing, total = 0, 0, 0
    local query = string.lower(search.Text)
    for p, r in pairs(records) do
        total = total + 1
        local kind = relation(p, r.mode)
        local color = colors[kind]
        r.row.Text = "@" .. p.Name .. "  ·  " .. modeNames[r.mode]
        r.row.TextColor3 = r.mode == "hidden" and Color3.fromRGB(110, 120, 135) or color
        r.row.Visible = query == "" or string.find(string.lower(p.Name .. " " .. p.DisplayName), query, 1, true) ~= nil
        local character = p.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")
        local seat = humanoid and humanoid.SeatPart
        local anchor = settings.seat and seat or head or root
        local positionPart = settings.seat and seat or root
        local distance = origin and positionPart and (origin - positionPart.Position).Magnitude
        if not root then missing = missing + 1 end
        local categoryEnabled = (kind == "ally" and settings.allies)
            or (kind == "enemy" and settings.enemies) or (kind == "unknown" and settings.unknown)
        local visible = settings.enabled and r.mode ~= "hidden" and categoryEnabled
            and humanoid ~= nil and humanoid.Health > 0 and anchor ~= nil
            and distance ~= nil and distance <= settings.range
        r.billboard.Enabled = visible
        r.billboard.Adornee = anchor
        r.billboard.AlwaysOnTop = settings.through
        -- Range is measured from the local player, not BillboardGui's camera distance.
        if visible then
            shown = shown + 1
            r.label.Text = tostring(math.floor(distance + 0.5)) .. " st"
            r.label.TextColor3 = color
        end
        if r.character ~= character then
            if r.highlight then r.highlight:Destroy(); r.highlight = nil end
            r.character = character
        end
        if visible and settings.silhouettes and character and not r.highlight then
            r.highlight = new("Highlight", {Name = "MTC_LocalHighlight", Adornee = character,
                FillTransparency = 0.85, OutlineTransparency = 0.1}, character)
        end
        if r.highlight then
            if not visible or not settings.silhouettes then
                r.highlight:Destroy()
                r.highlight = nil
            else
                r.highlight.FillColor = color
                r.highlight.OutlineColor = color
                r.highlight.DepthMode = settings.through and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        end
    end
    summary.Text = string.format("%d repères / %d joueurs · %d sans personnage", shown, total, missing)
end)
