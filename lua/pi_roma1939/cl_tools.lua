-- Roma 1939 builders' tools, client side: the prop removal tool.
--   bind a key:          bind n roma_remove
--   roma_remove_mode     turns the tool on / off (pressing the bound key also turns it on)
--   With the tool on, the map prop under your crosshair gets a yellow outline and its name shows under the crosshair.
--   Press the key: it turns red (marked for removal at the next map build). Press again on a red one to keep it after all.
--   Parts of the buildings and landmarks are only picked when you aim right at them, and need two presses.
-- Marks are kept on the server and shown to everyone. The prop list ships with the map (data_static/pi_roma1939/).
local CELL, FAR = 512, 6000
local grid, marked, live, bounds = {}, {}, {}, {}
local loaded, mode, sel, armed, nextScan = false, false, nil, nil, 0

local function p3(s)
    local a, b, c = string.match(s or "", "(%S+)%s+(%S+)%s+(%S+)")
    return tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0
end

local function getBounds(model)
    local b = bounds[model]
    if b ~= nil then return b end
    local cm = ClientsideModel(model, RENDERGROUP_OTHER)
    if not IsValid(cm) then bounds[model] = false return false end
    local mn, mx = cm:GetModelBounds()
    cm:Remove()
    b = { mn, mx, math.max(mn:Length(), mx:Length()), (mx.x - mn.x) * (mx.y - mn.y) * (mx.z - mn.z) }
    bounds[model] = b
    return b
end

local function addProp(model, origin, angles)
    local x, y, z = p3(origin)
    local pa, ya, ra = p3(angles)
    local arch = string.StartWith(model, "models/pi_roma/") or string.StartWith(model, "models/pi_roma_tn/") or string.find(model, "/fontana_mose", 1, true) ~= nil
    if string.StartWith(model, "models/pi_roma/park/") or string.StartWith(model, "models/pi_roma/bust/") or string.StartWith(model, "models/pi_roma/statue/") then arch = false end
    local e = { model = model, origin = origin, angles = angles, pos = Vector(x, y, z), ang = Angle(pa, ya, ra), key = model .. "@" .. origin,
                arch = arch }                   -- the map's architecture (house blocks, facades, landmarks): only by aiming right at it
    local k = math.floor(x / CELL) .. ":" .. math.floor(y / CELL)
    grid[k] = grid[k] or {}
    table.insert(grid[k], e)
    live[e.key] = e
end

local function load()
    grid, live, loaded = {}, {}, false
    -- (read through the game path: a data_static folder of an addon FOLDER is not offered under "DATA" - tested 2026-11-21)
    local t = util.JSONToTable(file.Read("data_static/pi_roma1939/static_props.json", "GAME") or file.Read("pi_roma1939/static_props.json", "DATA") or "")
    if not t or t.map ~= game.GetMap() then return end
    for _, p in ipairs(t.props or {}) do addProp(p[1], p[2], p[3]) end
    loaded = true
end

hook.Add("InitPostEntity", "pi_roma_tools_load", load)

-- ---- what the server tells us
local parts = {}
net.Receive("pi_roma_blob", function()
    local kind, id, i, n = net.ReadString(), net.ReadUInt(32), net.ReadUInt(16), net.ReadUInt(16)
    local len = net.ReadUInt(16)
    local data = len > 0 and net.ReadData(len) or ""
    local k = kind .. id
    parts[k] = parts[k] or {}
    parts[k][i] = data
    for j = 1, n do
        if not parts[k][j] then return end
    end
    local z = table.concat(parts[k])
    parts[k] = nil
    local text = (#z > 0 and util.Decompress(z)) or ""
    if kind == "marks" then
        marked = {}
        for key in string.gmatch(text, "[^\n]+") do marked[key] = true end
    elseif kind == "pull" then
        file.CreateDir("roma_pull")
        file.Write("roma_pull/pull.json", text)
        local t = util.JSONToTable(text) or {}
        chat.AddText(Color(120, 220, 120), string.format("[roma] pulled: %d prop areas and %d removal marks -> garrysmod/data/roma_pull/pull.json", #(t.areas or {}), #(t.marks or {})))
    end
end)

net.Receive("pi_roma_rm", function()
    local on, key, who = net.ReadBool(), net.ReadString(), net.ReadString()
    marked[key] = on and true or nil
    if mode and IsValid(LocalPlayer()) and who ~= LocalPlayer():Nick() then
        local e = live[key]
        chat.AddText(Color(200, 200, 200), "[roma] " .. who .. (on and " marked " or " kept ") .. (e and string.gsub(string.gsub(e.model, "^models/", ""), "%.mdl$", "") or "a prop"))
    end
end)

local function inBox(e, b, p, pad)
    local l = WorldToLocal(p, angle_zero, e.pos, e.ang)
    return l.x >= b[1].x - pad and l.x <= b[2].x + pad and l.y >= b[1].y - pad and l.y <= b[2].y + pad and l.z >= b[1].z - pad and l.z <= b[2].z + pad
end

local function scan()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local eye, dir = ply:EyePos(), ply:GetAimVector()
    local tr = util.TraceLine({ start = eye, endpos = eye + dir * FAR, filter = ply })
    local maxd = eye:Distance(tr.HitPos) + 24
    local p2 = eye + dir * maxd
    local budget = 40
    local inside, insideVol, ray, rayVol = nil, math.huge, nil, math.huge
    for cx = math.floor((math.min(eye.x, p2.x) - 600) / CELL), math.floor((math.max(eye.x, p2.x) + 600) / CELL) do
        for cy = math.floor((math.min(eye.y, p2.y) - 600) / CELL), math.floor((math.max(eye.y, p2.y) + 600) / CELL) do
            for _, e in ipairs(grid[cx .. ":" .. cy] or {}) do
                local b = bounds[e.model]
                if b == nil and budget > 0 then budget = budget - 1 b = getBounds(e.model) end
                if b then
                    local to = e.pos - eye
                    local t = to:Dot(dir)
                    if t > -b[3] and t < maxd + b[3] and (to - dir * t):Length() < b[3] then
                        if tr.HitTexture == "**studio**" and inBox(e, b, tr.HitPos, 2) then
                            if b[4] < insideVol then inside, insideVol = e, b[4] end          -- the smallest box round the spot the crosshair is on
                        elseif not e.arch and b[4] < rayVol and util.IntersectRayWithOBB(eye, dir * maxd, e.pos, e.ang, b[1], b[2]) then
                            ray, rayVol = e, b[4]                      -- else the smallest box the line of sight passes through before it
                        end                                            -- hits something (non-solid trees)
                    end
                end
            end
        end
    end
    sel = inside or ray
    if not sel and IsValid(tr.Entity) and tr.Entity:CreatedByMap() and tr.Entity:GetModel() then     -- a real entity the map placed (door, dynamic prop)
        local o = tr.Entity:GetPos()
        local e = live[string.lower(tr.Entity:GetModel()) .. "@" .. string.format("%.1f %.1f %.1f", o.x, o.y, o.z)]
        if e and getBounds(e.model) then sel = e end
    end
end

hook.Add("Think", "pi_roma_tools_scan", function()
    if not mode or not loaded or CurTime() < nextScan then return end
    nextScan = CurTime() + 0.1
    scan()
end)

local function short(m) return string.gsub(string.gsub(m, "^models/", ""), "%.mdl$", "") end

concommand.Add("roma_remove_mode", function()
    if not loaded then load() end
    mode = not mode
    sel = nil
    chat.AddText(Color(220, 200, 120), "[roma] prop removal tool " .. (mode and "ON" or "off") .. (loaded and "" or " (no prop list for this map file)"))
end)

concommand.Add("roma_remove", function()
    if not mode then RunConsoleCommand("roma_remove_mode") return end
    if not sel then return end
    local b = getBounds(sel.model)
    if not b then return end
    if marked[sel.key] then
        net.Start("pi_roma_rm") net.WriteBool(false) net.WriteString(sel.key) net.SendToServer()
        chat.AddText(Color(120, 220, 120), "[roma] kept: " .. short(sel.model))
    else
        if (sel.arch or b[3] > 1500) and armed ~= sel.key then                -- part of a building or a landmark: press twice
            armed = sel.key
            chat.AddText(Color(255, 160, 80), "[roma] that's part of a building (" .. short(sel.model) .. ") - press again to mark it")
            return
        end
        armed = nil
        net.Start("pi_roma_rm")
        net.WriteBool(true) net.WriteString(sel.key) net.WriteString(sel.model) net.WriteString(sel.origin) net.WriteString(sel.angles)
        net.WriteFloat(b[1].x) net.WriteFloat(b[1].y) net.WriteFloat(b[1].z) net.WriteFloat(b[2].x) net.WriteFloat(b[2].y) net.WriteFloat(b[2].z)
        net.SendToServer()
        chat.AddText(Color(255, 110, 110), "[roma] marked for removal: " .. short(sel.model))
    end
end)

concommand.Add("roma_remove_count", function()
    chat.AddText(Color(220, 200, 120), "[roma] " .. table.Count(marked) .. " props marked for removal on this server")
end)

local YELLOW, RED, PINK = Color(255, 225, 60), Color(255, 60, 60), Color(255, 150, 150)
hook.Add("PostDrawTranslucentRenderables", "pi_roma_tools_draw", function(_, sky)
    if not mode or not loaded or sky then return end
    local eye = EyePos()
    for k in pairs(marked) do
        local e = live[k]
        if e and e.pos:DistToSqr(eye) < 2500 * 2500 then
            local b = getBounds(e.model)
            if b then render.DrawWireframeBox(e.pos, e.ang, b[1], b[2], RED, true) end
        end
    end
    if sel then
        local b = getBounds(sel.model)
        if b then render.DrawWireframeBox(sel.pos, sel.ang, b[1], b[2], marked[sel.key] and PINK or YELLOW, false) end
    end
end)

hook.Add("HUDPaint", "pi_roma_tools_hud", function()
    if not mode then return end
    local txt, col = "removal tool on - aim at a map prop", color_white
    if sel then
        if marked[sel.key] then txt, col = short(sel.model) .. "  -  MARKED: press to keep it", RED
        else txt, col = short(sel.model) .. "  -  press to mark for removal", YELLOW end
    end
    draw.SimpleTextOutlined(txt, "DermaDefaultBold", ScrW() / 2, ScrH() / 2 + 36, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)
end)
