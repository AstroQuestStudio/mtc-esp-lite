-- MTC ESP Lite v3: focused rewrite of EdgeIY/Infinite Yield's ESP concept.
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

local settings = {enabled = true, through = true, range = 1500, boxes = true,
    distance = true, details = true, vehicleLOS = true, maxMarkers = 24,
    style = "PLEIN", contrast = 2}
local colors = {ally = Color3.fromRGB(65, 156, 255), enemy = Color3.fromRGB(255, 79, 90),
    unknown = Color3.fromRGB(175, 184, 198)}
local contrastStyles = {{thickness = 1.5, fill = 0.96, text = 12},
    {thickness = 2.5, fill = 0.9, text = 13}, {thickness = 3.5, fill = 0.82, text = 14}}
local records, connections = {}, {}
local running = true
local gui = Instance.new("ScreenGui")
gui.Name = "MTC_ESPLite"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
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
    if level == perf.level then return end
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
local palette = {bg = Color3.fromRGB(13, 18, 27), card = Color3.fromRGB(22, 30, 43),
    line = Color3.fromRGB(43, 56, 75), ink = Color3.fromRGB(236, 242, 250),
    muted = Color3.fromRGB(142, 157, 179), accent = Color3.fromRGB(93, 210, 184)}
local function round(obj, radius)
    new("UICorner", {CornerRadius = UDim.new(0, radius or 9)}, obj)
end
local function stroke(obj, color, width)
    return new("UIStroke", {Color = color, Thickness = width or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, obj)
end
local function text(parent, value, height)
    return new("TextLabel", {Size = UDim2.new(1, 0, 0, height or 22), BackgroundTransparency = 1,
        Text = value, TextColor3 = palette.ink, TextSize = 13, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left}, parent)
end
local function button(parent, title, callback)
    local b = new("TextButton", {Name = title, Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = palette.card, BorderSizePixel = 0, Text = title,
        TextColor3 = palette.ink, Font = Enum.Font.GothamMedium, TextSize = 12,
        AutoButtonColor = true}, parent)
    round(b)
    connect(b.Activated, callback)
    return b
end

local panel = new("Frame", {Name = "ControlPanel", Position = UDim2.fromOffset(14, 60),
    Size = UDim2.fromOffset(360, 570), BackgroundColor3 = palette.bg, BorderSizePixel = 0, ZIndex = 50}, gui)
round(panel, 14)
stroke(panel, palette.line)
local scale = new("UIScale", {}, panel)
local title = text(panel, "MTC  /  VOLUMES", 24)
title.Position = UDim2.fromOffset(18, 15)
title.Size = UDim2.new(1, -70, 0, 24)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
local subtitle = text(panel, "OCCUPANTS  ·  ÉQUIPES AUTO", 18)
subtitle.Position = UDim2.fromOffset(18, 41)
subtitle.TextSize = 10
subtitle.TextColor3 = palette.muted
local close = button(panel, "Réduire", function() panel.Visible = false end)
close.Position = UDim2.new(1, -44, 0, 14)
close.Size = UDim2.fromOffset(28, 28)
close.Text = "−"

local summary = text(panel, "Initialisation…", 22)
summary.Position = UDim2.fromOffset(18, 65)
summary.Size = UDim2.new(1, -36, 0, 22)
summary.TextSize = 11
summary.TextColor3 = palette.accent
local tabs = new("Frame", {Position = UDim2.fromOffset(14, 94), Size = UDim2.new(1, -28, 0, 34),
    BackgroundTransparency = 1}, panel)
local pages = {}
local tabButtons = {}
local function selectPage(name)
    for key, page in pairs(pages) do
        page.Visible = key == name
        tabButtons[key].BackgroundColor3 = key == name and palette.accent or palette.card
        tabButtons[key].TextColor3 = key == name and palette.bg or palette.muted
    end
end
for i, name in ipairs({"AFFICHAGE", "PERFORMANCES"}) do
    local page = new("ScrollingFrame", {Name = name, Position = UDim2.fromOffset(14, 140),
        Size = UDim2.new(1, -28, 1, -190), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = palette.accent,
        AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = i == 1}, panel)
    new("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 7),
        PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)}, page)
    pages[name] = page
    local b = button(tabs, name, function() selectPage(name) end)
    b.Position = UDim2.new((i - 1) * 0.5, i == 1 and 0 or 4, 0, 0)
    b.Size = UDim2.new(0.5, -4, 1, 0)
    tabButtons[name] = b
end
local appearance, performance = pages.AFFICHAGE, pages.PERFORMANCES
local sequence = 0
local function ordered(obj)
    sequence = sequence + 1
    obj.LayoutOrder = sequence
    return obj
end
local function section(parent, label)
    local t = ordered(text(parent, label, 20))
    t.TextColor3 = palette.muted
    t.TextSize = 10
    t.Font = Enum.Font.GothamBold
    return t
end
local function row(parent, label, help, callback)
    local b = ordered(button(parent, label, callback))
    b.Text = ""
    b.Size = UDim2.new(1, 0, 0, 56)
    local heading = text(b, label, 20)
    heading.Position = UDim2.fromOffset(12, 8)
    heading.Size = UDim2.new(1, -103, 0, 20)
    heading.Font = Enum.Font.GothamMedium
    local note = text(b, help, 16)
    note.Position = UDim2.fromOffset(12, 30)
    note.Size = UDim2.new(1, -100, 0, 16)
    note.TextSize = 10
    note.TextColor3 = palette.muted
    local value = text(b, "", 24)
    value.Position = UDim2.new(1, -88, 0, 16)
    value.Size = UDim2.fromOffset(76, 24)
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Font = Enum.Font.GothamBold
    value.TextSize = 11
    return b, value
end
local refreshers = {}
local function toggle(parent, key, label, help)
    local value, b
    local function refresh()
        value.Text = settings[key] and "ON  ●" or "OFF  ○"
        value.TextColor3 = settings[key] and palette.accent or palette.muted
    end
    b, value = row(parent, label, help, function() settings[key] = not settings[key]; refresh() end)
    refreshers[key] = refresh
    refresh()
    return b
end
section(appearance, "L’ESSENTIEL")
toggle(appearance, "enabled", "ESP actif", "Raccourci F8")
toggle(appearance, "boxes", "Cadres des occupants", "Un cadre par personne, même en char")
toggle(appearance, "distance", "Distance", "Studs uniquement · aucun nom")
section(appearance, "RENDU DES VOLUMES")
local styleValue
local _, styleDisplay = row(appearance, "Style des cadres", "Contours complets ou angles", function()
    settings.style = settings.style == "PLEIN" and "ANGLES" or "PLEIN"
    styleValue.Text = settings.style
end)
styleValue = styleDisplay; styleValue.Text = settings.style
local contrastNames = {"FIN", "NET", "FORT"}
local contrastValue
local _, contrastDisplay = row(appearance, "Contraste", "Épaisseur + intensité du remplissage", function()
    settings.contrast = settings.contrast % 3 + 1
    contrastValue.Text = contrastNames[settings.contrast]
end)
contrastValue = contrastDisplay; contrastValue.Text = contrastNames[settings.contrast]
toggle(appearance, "details", "Détails à proximité", "Volumes des membres à moins de 180 st")
toggle(appearance, "through", "Voir à travers", "Affiche aussi les occupants masqués")
section(appearance, "PORTÉE")
local ranges, rangeIndex = {500, 1500, 3000, math.huge}, 2
local rangeValue
local _, rangeDisplay = row(appearance, "Portée", "Distance depuis votre personnage", function()
    rangeIndex = rangeIndex % #ranges + 1
    settings.range = ranges[rangeIndex]
    rangeValue.Text = settings.range == math.huge and "∞" or tostring(settings.range) .. " st"
end)
rangeValue = rangeDisplay; rangeValue.Text = "1500 st"
local limitValue
local _, limitDisplay = row(appearance, "Maximum à l’écran", "Priorité aux occupants les plus proches", function()
    settings.maxMarkers = settings.maxMarkers == 24 and 48 or (settings.maxMarkers == 48 and 12 or 24)
    limitValue.Text = tostring(settings.maxMarkers)
end)
limitValue = limitDisplay; limitValue.Text = tostring(settings.maxMarkers)
local legend = ordered(text(appearance, "Bleu allié · rouge ennemi · gris inconnu", 24))
legend.TextColor3 = palette.muted; legend.TextSize = 10

section(performance, "PRÉRÉGLAGES GRAPHIQUES")
local perfButtons = {}
local perfNames = {[0] = "NORMAL", [1] = "LÉGER", [2] = "FORT"}
local help = {[0] = "Graphismes du jeu · charge ESP normale", [1] = "Réduit ombres + effets d’image",
    [2] = "Coupe aussi fumées / explosions / traînées"}
for level = 0, 2 do
    local b, value
    b, value = row(performance, "Mode " .. perfNames[level], help[level], function()
        setPerformance(level)
        for index, item in pairs(perfButtons) do
            item.value.Text = index == level and "ACTIF" or "CHOISIR"
            item.value.TextColor3 = index == level and palette.accent or palette.muted
            item.stroke.Color = index == level and palette.accent or palette.line
        end
    end)
    perfButtons[level] = {value = value, stroke = stroke(b, level == 0 and palette.accent or palette.line)}
    value.Text = level == 0 and "ACTIF" or "CHOISIR"
    value.TextColor3 = level == 0 and palette.accent or palette.muted
end
section(performance, "MESURE SUR ENVIRON 2 SECONDES")
local diagnostics = ordered(text(performance, "Mesure des images…", 44))
diagnostics.TextWrapped = true
diagnostics.TextSize = 13
local perfStatus = ordered(text(performance, "Graphismes d’origine", 38))
perfStatus.TextWrapped = true; perfStatus.TextColor3 = palette.muted; perfStatus.TextSize = 11
local hint = ordered(text(performance, "LÉGER / FORT : 12 repères max, détail sur 6 occupants.\nL’arrêt restaure les réglages modifiés.", 42))
hint.TextWrapped = true; hint.TextColor3 = palette.muted; hint.TextSize = 11
local footer = text(panel, "INSERT · MENU     F8 · ESP", 20)
footer.Position = UDim2.new(0, 18, 1, -33)
footer.Size = UDim2.new(1, -120, 0, 20)
footer.TextSize = 10; footer.TextColor3 = palette.muted
local quit = button(panel, "Arrêter", function() stop:Fire() end)
quit.Position = UDim2.new(1, -92, 1, -38); quit.Size = UDim2.fromOffset(76, 28)
quit.TextColor3 = Color3.fromRGB(250, 136, 143)
local reopen = button(gui, "MTC / MENU", function() panel.Visible = not panel.Visible end)
reopen.Position = UDim2.fromOffset(14, 14); reopen.Size = UDim2.fromOffset(130, 32)
reopen.ZIndex = 60
stroke(reopen, palette.line)
selectPage("AFFICHAGE")

local function cleanup()
    if not running then return end
    running = false
    restoreGraphics()
    for _, c in ipairs(connections) do c:Disconnect() end
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

local function add(p)
    if p == me or records[p] then return end
    local r = {id = p.UserId, boxes = {}, los = nil, checkedAt = -math.huge}
    records[p] = r
    r.frame = new("Frame", {Name = tostring(p.UserId), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false}, marks)
    r.back = new("Frame", {Name = "Back", Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0}, r.frame)
    r.backStroke = stroke(r.back, Color3.fromRGB(3, 6, 10), 5)
    r.fill = new("Frame", {Name = "Volume", Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 0.9, BorderSizePixel = 0}, r.frame)
    r.outline = stroke(r.fill, colors.unknown, 3)
    r.cornersUI = {}
    for i = 1, 8 do
        local edge = new("Frame", {Name = "Corner" .. i, BorderSizePixel = 0, Visible = false}, r.frame)
        stroke(edge, Color3.fromRGB(3, 6, 10), 1)
        table.insert(r.cornersUI, edge)
    end
    r.label = text(r.frame, "", 22)
    r.label.Name = "Distance"
    r.label.Size = UDim2.fromOffset(64, 22)
    r.label.TextXAlignment = Enum.TextXAlignment.Center
    r.label.Font = Enum.Font.GothamBold
    r.label.TextSize = 13
    r.label.BackgroundColor3 = Color3.fromRGB(8, 13, 21)
    r.label.BackgroundTransparency = 0.12
    round(r.label, 5)
    r.labelStroke = stroke(r.label, colors.unknown, 1)
end
local function remove(p)
    local r = records[p]
    if not r then return end
    r.draw, r.corners = false, nil
    for _, box in ipairs(r.boxes) do box:Destroy() end
    r.frame:Destroy()
    records[p] = nil
end
connect(Players.PlayerAdded, add)
connect(Players.PlayerRemoving, remove)
for _, p in ipairs(Players:GetPlayers()) do add(p) end

local function relation(p)
    if me.Neutral or p.Neutral or not me.Team or not p.Team then return "unknown" end
    return p.Team == me.Team and "ally" or "enemy"
end
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false
local elapsed, clock, losCursor = 0, 0, 0
local drawList = {}
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
    if r.boxCharacter ~= r.character or clock >= (r.nextDetailCheck or 0) then
        r.nextDetailCheck = clock + 0.75
        local parts = {}
        for _, part in ipairs(r.character:GetChildren()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and #parts < 16 then
                table.insert(parts, part)
            end
        end
        local changed = r.boxCharacter ~= r.character or #parts ~= #r.boxes
        for i, part in ipairs(parts) do
            if not r.boxes[i] or r.boxes[i].Adornee ~= part then changed = true; break end
        end
        if changed then
            clearBoxes(r)
            r.boxCharacter = r.character
            for _, part in ipairs(parts) do
                table.insert(r.boxes, new("BoxHandleAdornment", {Name = "BodyBox", Adornee = part,
                    Size = part.Size, Color3 = color, Transparency = 0.65,
                    AlwaysOnTop = settings.through, ZIndex = 5}, marks))
            end
        end
    end
    for _, box in ipairs(r.boxes) do
        if box.Adornee and box.Adornee.Parent then
            box.Size = box.Adornee.Size
            box.Color3 = color
            box.AlwaysOnTop = settings.through
            box.Transparency = clear and 0.65 or 0.82
        end
    end
end

-- Root-relative bounds of direct body parts: accessories and vehicle parts never
-- contribute. Refresh the pose at a bounded rate; project the cached corners at
-- render rate so camera motion stays smooth without per-frame scene traversal.
local function updateBounds(r)
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    local count = 0
    for _, part in ipairs(r.character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and count < 32 then
            local cf = r.root.CFrame:ToObjectSpace(part.CFrame)
            local p, size = cf.Position, part.Size
            local right, up, look = cf.RightVector, cf.UpVector, cf.LookVector
            local hx = (math.abs(right.X) * size.X + math.abs(up.X) * size.Y + math.abs(look.X) * size.Z) * 0.5
            local hy = (math.abs(right.Y) * size.X + math.abs(up.Y) * size.Y + math.abs(look.Y) * size.Z) * 0.5
            local hz = (math.abs(right.Z) * size.X + math.abs(up.Z) * size.Y + math.abs(look.Z) * size.Z) * 0.5
            minX, minY, minZ = math.min(minX, p.X - hx), math.min(minY, p.Y - hy), math.min(minZ, p.Z - hz)
            maxX, maxY, maxZ = math.max(maxX, p.X + hx), math.max(maxY, p.Y + hy), math.max(maxZ, p.Z + hz)
            count = count + 1
        end
    end
    r.corners = nil
    if count > 0 then
        r.corners = {}
        for _, x in ipairs({minX, maxX}) do
            for _, y in ipairs({minY, maxY}) do
                for _, z in ipairs({minZ, maxZ}) do table.insert(r.corners, Vector3.new(x, y, z)) end
            end
        end
    end
    r.boundsRoot = r.root
    r.nextBoundsAt = clock + (perf.level > 0 and 0.5 or 0.25)
end

local function projectBounds(r, camera)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    if not r.root or not r.root.Parent or not r.corners then return nil end
    local cf = r.root.CFrame
    for _, corner in ipairs(r.corners) do
        local point = camera:WorldToViewportPoint(cf:PointToWorldSpace(corner))
        -- Avoid giant/inverted boxes when the camera intersects a character.
        if point.Z <= 0.05 then return nil end
        minX, minY = math.min(minX, point.X), math.min(minY, point.Y)
        maxX, maxY = math.max(maxX, point.X), math.max(maxY, point.Y)
    end
    local width, height = camera.ViewportSize.X, camera.ViewportSize.Y
    if maxX < 0 or maxY < 0 or minX > width or minY > height then return nil end
    if maxX - minX > width * 2 or maxY - minY > height * 2 then return nil end
    local midX, midY = (minX + maxX) * 0.5, (minY + maxY) * 0.5
    local w, h = math.max(6, maxX - minX), math.max(12, maxY - minY)
    return math.max(0, midX - w * 0.5), math.max(0, midY - h * 0.5),
        math.min(width, midX + w * 0.5), math.min(height, midY + h * 0.5)
end

local occupiedLabels = {}
connect(RunService.RenderStepped, function()
    local camera = workspace.CurrentCamera
    local labelCount = 0
    local style = contrastStyles[settings.contrast]
    for _, r in ipairs(drawList) do
        r.frame.Visible = false
        if camera and settings.enabled and r.draw and r.character == nil then r.draw = false end
        if camera and settings.enabled and r.draw then
            local x1, y1, x2, y2 = projectBounds(r, camera)
            if x1 and x2 > x1 and y2 > y1 then
                local w, h = x2 - x1, y2 - y1
                r.frame.Visible = settings.boxes or settings.distance
                r.frame.Position = UDim2.fromOffset(x1, y1)
                r.frame.Size = UDim2.fromOffset(w, h)
                local thickness = style.thickness
                local full = settings.boxes and settings.style == "PLEIN"
                r.fill.BackgroundColor3 = r.color
                r.fill.BackgroundTransparency = settings.boxes and math.min(1, style.fill + (r.clear and 0 or 0.05)) or 1
                r.outline.Color = r.color
                r.outline.Thickness = thickness
                r.outline.Enabled = full
                r.backStroke.Thickness = thickness + 2
                r.backStroke.Enabled = full
                local length = math.max(3, math.min(18, w * 0.3, h * 0.25))
                for i, edge in ipairs(r.cornersUI) do
                    local corner = math.floor((i - 1) / 2)
                    local right = corner % 2 == 1
                    local bottom = corner >= 2
                    local horizontal = i % 2 == 1
                    local ew, eh = horizontal and length or thickness, horizontal and thickness or length
                    edge.Visible = settings.boxes and not full
                    edge.BackgroundColor3 = r.color
                    edge.Position = UDim2.fromOffset(right and w - ew or 0, bottom and h - eh or 0)
                    edge.Size = UDim2.fromOffset(ew, eh)
                end
                r.label.Visible = settings.distance
                r.label.TextSize = style.text
                if settings.distance then
                    local lx = math.clamp((x1 + x2) * 0.5 - 32, 2, math.max(2, camera.ViewportSize.X - 66))
                    local ly = math.min(camera.ViewportSize.Y - 24, y2 + 5)
                    -- Keep occupants separate; only nudge colliding distance badges.
                    for attempt = 0, 5 do
                        local candidateY = y2 + 5 + attempt * 24
                        if candidateY > camera.ViewportSize.Y - 24 then candidateY = y1 - 27 - attempt * 24 end
                        candidateY = math.clamp(candidateY, 2, math.max(2, camera.ViewportSize.Y - 24))
                        local overlaps = false
                        for j = 1, labelCount do
                            local placed = occupiedLabels[j]
                            if lx < placed.x + 66 and lx + 66 > placed.x and candidateY < placed.y + 24 and candidateY + 24 > placed.y then
                                overlaps = true; break
                            end
                        end
                        ly = candidateY
                        if not overlaps then break end
                    end
                    labelCount = labelCount + 1
                    local placed = occupiedLabels[labelCount]
                    if not placed then placed = {}; occupiedLabels[labelCount] = placed end
                    placed.x, placed.y = lx, ly
                    r.label.Position = UDim2.fromOffset(lx - x1, ly - y1)
                end
            end
        end
    end
end)

local function vehicleModel(seat, assemblyRoot, character)
    -- Infer only a small common model of physically related parts.
    -- Never accept Workspace, a map-sized model, or the occupant's character.
    if not assemblyRoot or assemblyRoot == seat then return nil end
    local ancestor = seat.Parent
    for _ = 1, 8 do
        if not ancestor or ancestor == workspace then return nil end
        if ancestor:IsA("Model") and assemblyRoot:IsDescendantOf(ancestor) then
            if ancestor == character or ancestor:FindFirstChildOfClass("Humanoid") then return nil end
            local ok, size = pcall(function() return ancestor:GetExtentsSize() end)
            if ok and size.Magnitude <= 250 then return ancestor end
            return nil
        end
        ancestor = ancestor.Parent
    end
end
local function testLOS(r, camera)
    -- Camera LOS only: no cannon origin, penetration, projectile arc or damage prediction.
    local from = camera.CFrame.Position
    local function reaches(part)
        if not part then return false end
        local result = workspace:Raycast(from, part.Position - from, rayParams)
        if not result or result.Instance:IsDescendantOf(r.character) then return true end
        if settings.vehicleLOS and r.seat then
            local hit = result.Instance
            if hit == r.seat then return true end
            if hit:IsA("BasePart") and r.vehicleRoot and hit.AssemblyRootPart == r.vehicleRoot then return true end
            if r.vehicleModel and hit:IsDescendantOf(r.vehicleModel) then return true end
        end
        return false
    end
    if settings.vehicleLOS and r.seat then
        return reaches(r.seat) or reaches(r.vehicleRoot or r.root)
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
        scale.Scale = math.clamp((camera.ViewportSize.X - 28) / 360, 0.4, 1)
        panel.Size = UDim2.fromOffset(360, math.min(570, math.max(220, (camera.ViewportSize.Y - 80) / scale.Scale)))
    end
    local ownRoot = me.Character and me.Character:FindFirstChild("HumanoidRootPart")
    local origin = ownRoot and ownRoot.Position
    local candidates = {}
    local shown, missing, total = 0, 0, 0
    for p, r in pairs(records) do
        total = total + 1
        r.kind = relation(p)
        local character = p.Character
        if r.character ~= character then
            clearBoxes(r)
            r.character, r.los, r.checkedAt = character, nil, -math.huge
            r.corners, r.boundsRoot = nil, nil
        end
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        r.root = character and character:FindFirstChild("HumanoidRootPart")
        r.head = character and character:FindFirstChild("Head")
        local seat = humanoid and humanoid.SeatPart
        local assemblyRoot = seat and seat.AssemblyRootPart
        if r.seat ~= seat or r.vehicleRoot ~= assemblyRoot then
            r.seat, r.vehicleRoot = seat, assemblyRoot
            r.vehicleModel = seat and vehicleModel(seat, assemblyRoot, character) or nil
            r.los, r.checkedAt = nil, -math.huge
        end
        local positionPart = r.root
        r.distance = origin and positionPart and (origin - positionPart.Position).Magnitude
        if not r.root then missing = missing + 1 end
        local onScreen = false
        if camera and r.root then
            local _, inViewport = camera:WorldToViewportPoint(r.root.Position)
            onScreen = inViewport
        end
        r.selected = false
        if settings.enabled and onScreen and humanoid and humanoid.Health > 0
            and r.root and r.distance and r.distance <= settings.range then
            table.insert(candidates, r)
        else
            r.los, r.checkedAt = nil, -math.huge
        end
    end
    table.sort(candidates, function(a, b)
        return a.distance < b.distance or (a.distance == b.distance and a.id < b.id)
    end)
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
        if r.selected and settings.boxes and settings.details and r.distance <= 180 and boxCount < (perf.level > 0 and 6 or 12) then
            r.useBoxes = true
            boxCount = boxCount + 1
        end
    end
    drawList = {}
    for _, r in ipairs(candidates) do
        if r.selected then table.insert(drawList, r) end
    end
    for _, r in pairs(records) do
        local clear = r.los == true and clock - r.checkedAt <= 0.9
        r.draw = r.selected and (settings.through or clear)
        if not r.draw then r.frame.Visible = false end
        local baseColor = colors[r.kind]
        r.color = clear and baseColor or baseColor:Lerp(Color3.fromRGB(80, 85, 95), 0.8)
        r.clear = clear
        if r.draw then
            shown = shown + 1
            r.label.Text = tostring(math.floor(r.distance + 0.5)) .. " st"
            r.label.TextColor3 = palette.ink
            r.labelStroke.Color = r.color
            if r.boundsRoot ~= r.root or clock >= (r.nextBoundsAt or 0) then updateBounds(r) end
        end
        updateBoxes(r, r.draw and r.useBoxes, r.color, clear)
    end
    summary.Text = string.format("%d OCCUPANTS À L’ÉCRAN  /  %d", shown, total)
    perfStatus.Text = perf.level == 0 and "Graphismes d’origine" or string.format("%d réglages réduits · %d objets en attente", perf.count, math.max(0, perf.tail - perf.head + 1))
end)
