-- MTC ESP Lite v2: focused rewrite of EdgeIY/Infinite Yield's ESP concept.
-- Upstream MIT attribution: see LICENSE-InfiniteYield.txt.
-- Client only. Team/seat detection uses generic Roblox data, not MTC internals.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
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
    through = true, silhouettes = false, seat = true, range = 1500,
    boxes = true, visibleOnly = false, maxMarkers = 24}
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

-- Reversible graphics reductions. Incremental tree walk, no GetDescendants sweep.
local perf = {level = 0, changed = {}, queue = {}, head = 1, tail = 0,
    seen = setmetatable({}, {__mode = "k"}), count = 0}
local function enqueue(obj)
    if perf.level == 0 or perf.seen[obj] then return end
    perf.seen[obj] = true
    perf.tail = perf.tail + 1
    perf.queue[perf.tail] = obj
end
local function change(obj, key, value)
    pcall(function()
        local original = obj[key]
        if original == value then return end
        local entry = perf.changed[obj]
        if not entry then
            entry = {values = {}}
            perf.changed[obj] = entry
            -- Explosions create short-lived emitters: do not retain them for a whole session.
            entry.connection = obj.Destroying:Connect(function()
                for _ in pairs(entry.values) do perf.count = perf.count - 1 end
                perf.changed[obj] = nil
                entry.connection:Disconnect()
            end)
        end
        local saved = entry.values
        if not saved[key] then
            saved[key] = {original = original, applied = value}
            perf.count = perf.count + 1
        end
        obj[key] = value
    end)
end
local function restoreGraphics()
    for obj, entry in pairs(perf.changed) do
        entry.connection:Disconnect()
        for key, saved in pairs(entry.values) do
            pcall(function()
                -- Do not overwrite a later change made by the game itself.
                if obj[key] == saved.applied then obj[key] = saved.original end
            end)
        end
    end
    perf.changed = {}
    perf.count = 0
    perf.queue = {}; perf.head = 1; perf.tail = 0
    perf.seen = setmetatable({}, {__mode = "k"})
end
local function setPerformance(level)
    restoreGraphics()
    perf.level = level
    if level > 0 then
        change(Lighting, "GlobalShadows", false)
        enqueue(Lighting)
        enqueue(workspace)
    end
end
local function processGraphics()
    if perf.level == 0 then return end
    local started, processed = os.clock(), 0
    while perf.head <= perf.tail and processed < 80 and os.clock() - started < 0.0015 do
        local obj = perf.queue[perf.head]
        perf.queue[perf.head] = nil
        perf.head = perf.head + 1
        processed = processed + 1
        if obj then
            pcall(function()
                if obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("DepthOfFieldEffect")
                    or obj:IsA("SunRaysEffect") then change(obj, "Enabled", false) end
                if perf.level == 2 then
                    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
                        or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                        change(obj, "Enabled", false)
                    end
                    if obj:IsA("Light") then change(obj, "Shadows", false) end
                end
                for _, child in ipairs(obj:GetChildren()) do enqueue(child) end
            end)
        end
    end
    if perf.head > perf.tail then perf.queue = {}; perf.head = 1; perf.tail = 0 end
end
connect(workspace.DescendantAdded, enqueue)
connect(Lighting.DescendantAdded, enqueue)
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
ordered(text(body, "Bleu allié · rouge ennemi · gris inconnu", 22))
local summary = ordered(text(body, "Initialisation…", 22))
local diagnostics = ordered(text(body, "Mesure des images…", 22))
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
toggle("boxes", "Boîtes des parties du corps")
toggle("visibleOnly", "Ligne de vue dégagée uniquement")
toggle("silhouettes", "Silhouettes des personnages")
toggle("seat", "Ancrer au siège si assis")
ordered(text(body, "Clair = tête ou torse visible depuis la caméra", 22))
ordered(text(body, "Sombre = ligne bloquée ou test en attente", 22))
local perfNames = {[0] = "NORMAL", [1] = "LÉGER", [2] = "FORT"}
local perfButton
perfButton = ordered(button(body, "Performances : NORMAL", function()
    setPerformance((perf.level + 1) % 3)
    perfButton.Text = "Performances : " .. perfNames[perf.level]
end))
ordered(text(body, "Fort : coupe aussi fumée / explosions / traînées", 22))
local perfStatus = ordered(text(body, "Graphismes d’origine", 22))
local limitButton
limitButton = ordered(button(body, "Repères max : 24 (les plus proches)", function()
    settings.maxMarkers = settings.maxMarkers == 24 and 48 or (settings.maxMarkers == 48 and 12 or 24)
    limitButton.Text = "Repères max : " .. settings.maxMarkers .. " (les plus proches)"
end))
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
    restoreGraphics()
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
    local r = {mode = "auto", boxes = {}, los = nil, checkedAt = -math.huge}
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
    for _, box in ipairs(r.boxes) do box:Destroy() end
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
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false
local elapsed, clock, losCursor = 0, 0, 0
local frameTime, frameCount, worstFrame, spikes = 0, 0, 0, 0
connect(RunService.RenderStepped, function(dt)
    frameTime = frameTime + dt
    frameCount = frameCount + 1
    worstFrame = math.max(worstFrame, dt)
    if dt >= 0.05 then spikes = spikes + 1 end
    if frameTime >= 2 then
        diagnostics.Text = string.format("%.0f FPS · pic %.0f ms · %d images ≥50 ms", frameCount / frameTime, worstFrame * 1000, spikes)
        frameTime, frameCount, worstFrame, spikes = 0, 0, 0, 0
    end
end)

local function clearBoxes(r)
    for _, box in ipairs(r.boxes) do box:Destroy() end
    r.boxes = {}
    r.boxCharacter = nil
end
local function updateBoxes(r, enabled, color, clear)
    if not enabled then
        if #r.boxes > 0 then clearBoxes(r) end
        return
    end
    if r.boxCharacter ~= r.character then
        clearBoxes(r)
        r.boxCharacter = r.character
        -- Direct body parts only, excluding accessories and the invisible root.
        for _, part in ipairs(r.character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and #r.boxes < 16 then
                table.insert(r.boxes, new("BoxHandleAdornment", {Name = "BodyBox", Adornee = part,
                    Size = part.Size, Color3 = color, Transparency = 0.72,
                    AlwaysOnTop = settings.through, ZIndex = 5}, marks))
            end
        end
    end
    for _, box in ipairs(r.boxes) do
        if box.Adornee and box.Adornee.Parent then
            box.Size = box.Adornee.Size
            box.Color3 = color
            box.AlwaysOnTop = settings.through
            box.Transparency = clear and 0.72 or 0.88
        end
    end
end

local function testLOS(r, camera)
    -- Camera LOS only: no cannon origin, penetration, projectile arc or damage prediction.
    local from = camera.CFrame.Position
    local function reaches(part)
        if not part then return false end
        local result = workspace:Raycast(from, part.Position - from, rayParams)
        return not result or result.Instance:IsDescendantOf(r.character)
    end
    return reaches(r.head) or reaches(r.root)
end

connect(RunService.Heartbeat, function(dt)
    clock = clock + dt
    processGraphics()
    elapsed = elapsed + dt
    if elapsed < (perf.level > 0 and 0.2 or 0.1) then return end
    elapsed = 0
    local camera = workspace.CurrentCamera
    if camera then
        scale.Scale = math.clamp(math.min((camera.ViewportSize.X - 28) / 350,
            (camera.ViewportSize.Y - 74) / 540, 1), 0.25, 1)
    end
    local ownRoot = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
    local origin = ownRoot and ownRoot.Position
    local candidates = {}
    local shown, missing, total = 0, 0, 0
    local query = string.lower(search.Text)
    for p, r in pairs(records) do
        total = total + 1
        r.kind = relation(p, r.mode)
        local color = colors[r.kind]
        local rowText = "@" .. p.Name .. "  ·  " .. modeNames[r.mode]
        if r.row.Text ~= rowText then r.row.Text = rowText end
        r.row.TextColor3 = r.mode == "hidden" and Color3.fromRGB(110, 120, 135) or color
        r.row.Visible = query == "" or string.find(string.lower(p.Name .. " " .. p.DisplayName), query, 1, true) ~= nil
        local character = p.Character
        if r.character ~= character then
            if r.highlight then r.highlight:Destroy(); r.highlight = nil end
            clearBoxes(r)
            r.character, r.los, r.checkedAt = character, nil, -math.huge
        end
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        r.root = character and character:FindFirstChild("HumanoidRootPart")
        r.head = character and character:FindFirstChild("Head")
        local seat = humanoid and humanoid.SeatPart
        r.anchor = settings.seat and seat or r.head or r.root
        local positionPart = settings.seat and seat or r.root
        r.distance = origin and positionPart and (origin - positionPart.Position).Magnitude
        if not r.root then missing = missing + 1 end
        local categoryEnabled = (r.kind == "ally" and settings.allies)
            or (r.kind == "enemy" and settings.enemies) or (r.kind == "unknown" and settings.unknown)
        local onScreen = false
        if camera and r.root then
            local _, inViewport = camera:WorldToViewportPoint(r.root.Position)
            onScreen = inViewport
        end
        r.selected = false
        if settings.enabled and r.mode ~= "hidden" and categoryEnabled and onScreen
            and humanoid and humanoid.Health > 0 and r.anchor and r.distance and r.distance <= settings.range then
            table.insert(candidates, r)
        else
            r.los, r.checkedAt = nil, -math.huge
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local limit = math.min(#candidates, settings.maxMarkers, perf.level > 0 and 12 or 48)
    for i = 1, limit do candidates[i].selected = true end
    -- At most 24 raycasts/update (12 when a performance mode is active).
    -- Round robin prevents permanently starving players beyond the first batch.
    rayParams.FilterDescendantsInstances = me.Character and {me.Character, camera} or {camera}
    local checks = math.min(limit, perf.level > 0 and 6 or 12)
    for _ = 1, checks do
        losCursor = losCursor % limit + 1
        local r = candidates[losCursor]
        r.los = testLOS(r, camera)
        r.checkedAt = clock
    end
    local boxCount = 0
    for _, r in ipairs(candidates) do
        r.useBoxes = false
        if r.selected and settings.boxes and boxCount < (perf.level > 0 and 6 or 12) then
            r.useBoxes = true
            boxCount = boxCount + 1
        end
    end
    for _, r in pairs(records) do
        local clear = r.los == true and clock - r.checkedAt <= 0.9
        local visible = r.selected and (not settings.visibleOnly or clear)
        local baseColor = colors[r.kind]
        local color = clear and baseColor or baseColor:Lerp(Color3.fromRGB(80, 85, 95), 0.8)
        r.billboard.Enabled = visible
        r.billboard.Adornee = r.anchor
        r.billboard.AlwaysOnTop = settings.through
        if visible then
            shown = shown + 1
            r.label.Text = tostring(math.floor(r.distance + 0.5)) .. " st"
            r.label.TextColor3 = color
        end
        updateBoxes(r, visible and r.useBoxes, color, clear)
        if visible and settings.silhouettes and r.character and not r.highlight then
            r.highlight = new("Highlight", {Name = "MTC_LocalHighlight", Adornee = r.character,
                FillTransparency = 0.85, OutlineTransparency = 0.1}, r.character)
        end
        if r.highlight then
            if not visible or not settings.silhouettes then
                r.highlight:Destroy(); r.highlight = nil
            else
                r.highlight.FillColor = color
                r.highlight.OutlineColor = color
                r.highlight.DepthMode = settings.through and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        end
    end
    summary.Text = string.format("%d repères / %d joueurs · %d sans personnage", shown, total, missing)
    perfStatus.Text = perf.level == 0 and "Graphismes d’origine" or string.format("%d réglages réduits · %d objets en attente", perf.count, math.max(0, perf.tail - perf.head + 1))
end)
