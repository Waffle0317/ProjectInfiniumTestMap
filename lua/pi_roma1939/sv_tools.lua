-- Roma 1939 builders' tools, server side.
-- Props: spawn from the Q menu, place, FREEZE (physgun right click), then  roma_props_save <area>  - your own frozen props are
--   saved as that area (saving the same area again replaces it). Saved areas come back by themselves after a server restart.
-- Removal: marks made with the removal tool (client) are kept here and shown to everyone.
-- Files (server): garrysmod/data/roma_tools/props/<area>.json, garrysmod/data/roma_tools/remove.json
local DIR, PDIR = "roma_tools", "roma_tools/props"
local MAX_AREA, MAX_RESPAWN, MAX_MARKS, PIECE = 2000, 3000, 20000, 48000
file.CreateDir(DIR)
file.CreateDir(PDIR)
util.AddNetworkString("pi_roma_rm")          -- one removal mark set / cleared (both ways)
util.AddNetworkString("pi_roma_blob")        -- larger data to one client, in pieces: every mark on join, the pull

local function say(ply, msg)
    if IsValid(ply) then ply:ChatPrint("[roma] " .. msg) end
    print("[roma] " .. msg)
end

local function clean(name)
    name = string.lower(string.Trim(name or ""))
    name = string.gsub(name, "[^a-z0-9_]", "_")
    name = string.sub(name, 1, 40)
    return name ~= "" and name or nil
end

local function boss(ply) return not IsValid(ply) or ply:IsSuperAdmin() end        -- (the server console counts)
local function sid(ply) return IsValid(ply) and ply:SteamID64() or "console" end
local function nick(ply) return IsValid(ply) and ply:Nick() or "console" end

local function sendBlob(ply, kind, data)
    local z = util.Compress(data) or ""
    local n = math.max(1, math.ceil(#z / PIECE))
    local id = math.random(1, 2000000000)
    for i = 1, n do
        local part = string.sub(z, (i - 1) * PIECE + 1, i * PIECE)
        timer.Simple((i - 1) * 0.15, function()
            if not IsValid(ply) then return end
            net.Start("pi_roma_blob")
            net.WriteString(kind) net.WriteUInt(id, 32) net.WriteUInt(i, 16) net.WriteUInt(n, 16)
            net.WriteUInt(#part, 16) net.WriteData(part, #part)
            net.Send(ply)
        end)
    end
end

-- ---------------------------------------------------------------------------------------------------------------- props
local function own(ply, _model, ent)
    if IsValid(ent) and IsValid(ply) then ent.romaBy, ent.romaName = ply:SteamID64(), ply:Nick() end
end
hook.Add("PlayerSpawnedProp", "pi_roma_tools_own", own)
hook.Add("PlayerSpawnedEffect", "pi_roma_tools_own", own)

local srcCache = {}
local function sourceOf(mdl)                       -- which Workshop addon a model comes from (it has to be bundled before it is baked in)
    if srcCache[mdl] then return srcCache[mdl] end
    local s = "game"
    for _, a in ipairs(engine.GetAddons()) do
        if a.mounted and a.title and file.Exists(mdl, a.title) then
            s = "workshop:" .. tostring(a.wsid) .. " " .. a.title
            break
        end
    end
    srcCache[mdl] = s
    return s
end

local function placed()
    local out = {}
    for _, e in ipairs(ents.GetAll()) do
        local cls = e:GetClass()
        if (cls == "prop_physics" or cls == "prop_physics_multiplayer" or cls == "prop_effect") and not e:CreatedByMap() then
            local m = e
            if cls == "prop_effect" and IsValid(e.AttachedEntity) then m = e.AttachedEntity end
            out[#out + 1] = { ent = e, mdl = m, cls = cls }
        end
    end
    return out
end

local function readArea(area)
    return util.JSONToTable(file.Read(PDIR .. "/" .. area .. ".json", "DATA") or "")
end

local baked = util.JSONToTable(file.Read("data_static/pi_roma1939/baked.json", "GAME") or file.Read("pi_roma1939/baked.json", "DATA") or "") or {}
-- (areas already built into this map file; read through the game path - an addon folder's data_static is not offered under "DATA")

concommand.Add("roma_props_save", function(ply, _, args)
    local area = clean(args[1])
    if not area then say(ply, "usage: roma_props_save <area name>   (letters, digits and _)") return end
    local me = sid(ply)
    local old = readArea(area)
    if old and old.by and old.by ~= me and not boss(ply) then
        say(ply, "area '" .. area .. "' belongs to " .. tostring(old.name or "someone else") .. " - pick another name")
        return
    end
    local list, loose, other, overrides, over = {}, 0, 0, 0, 0
    for _, p in ipairs(placed()) do
        local e, m = p.ent, p.mdl
        local mine = (e.romaArea == area) or (e.romaArea == nil and (e.romaBy == me or (e.romaBy == nil and boss(ply))))
        if e.romaArea and e.romaArea ~= area and e.romaBy == me then other = other + 1 end
        if mine then
            local phys = e:GetPhysicsObject()
            if p.cls ~= "prop_effect" and IsValid(phys) and phys:IsMotionEnabled() then
                loose = loose + 1                  -- not frozen: left out
            elseif #list >= MAX_AREA then
                over = over + 1
            else
                local pos, ang = m:GetPos(), m:GetAngles()
                local c = m:GetColor()
                if (c.r ~= 255 or c.g ~= 255 or c.b ~= 255 or c.a ~= 255) or m:GetMaterial() ~= "" or m:GetModelScale() ~= 1 then
                    overrides = overrides + 1
                end
                list[#list + 1] = {
                    model = string.lower(m:GetModel() or ""), skin = m:GetSkin() or 0,
                    pos = { math.Round(pos.x, 2), math.Round(pos.y, 2), math.Round(pos.z, 2) },
                    ang = { math.Round(ang.p, 2), math.Round(ang.y, 2), math.Round(ang.r, 2) },
                    radius = math.Round(m:BoundingRadius(), 1), src = sourceOf(m:GetModel() or ""),
                }
                e.romaArea = area
            end
        end
    end
    if #list == 0 and not old then
        say(ply, "nothing to save: no frozen props of yours that aren't already in an area" .. (loose > 0 and (" (" .. loose .. " are not frozen)") or ""))
        return
    end
    local by, name = me, nick(ply)
    if old and old.by and old.by ~= me then by, name = old.by, old.name end          -- a superadmin tidying someone's area: it stays theirs
    file.Write(PDIR .. "/" .. area .. ".json", util.TableToJSON({ area = area, map = game.GetMap(), saved = os.date("%Y-%m-%d %H:%M:%S"),
        by = by, name = name, props = list }, true))
    local msg = string.format("area '%s' saved: %d props", area, #list)
    if loose > 0 then msg = msg .. string.format(" | %d not frozen (left out)", loose) end
    if other > 0 then msg = msg .. string.format(" | %d of yours are in other areas", other) end
    if over > 0 then msg = msg .. string.format(" | %d over the limit of %d per area (left out - start another area)", over, MAX_AREA) end
    if overrides > 0 then msg = msg .. string.format(" | %d have colour/material/size changes (they won't carry over)", overrides) end
    say(ply, msg)
end)

concommand.Add("roma_props_list", function(ply)
    local files = file.Find(PDIR .. "/*.json", "DATA")
    if #files == 0 then say(ply, "no areas saved yet") return end
    for _, f in ipairs(files) do
        local t = util.JSONToTable(file.Read(PDIR .. "/" .. f, "DATA") or "") or {}
        say(ply, string.format("%s: %d props, by %s (saved %s)", string.gsub(f, "%.json$", ""), #(t.props or {}), tostring(t.name or "?"), t.saved or "?"))
    end
end)

local function spawnArea(t, area, ply, budget)
    local n, bad = 0, 0
    for _, p in ipairs(t.props or {}) do
        if budget and budget.left <= 0 then break end
        if not util.IsValidModel(p.model) then
            bad = bad + 1
        else
            local e = ents.Create("prop_physics")
            if IsValid(e) then
                e:SetModel(p.model)
                e:SetPos(Vector(p.pos[1], p.pos[2], p.pos[3]))
                e:SetAngles(Angle(p.ang[1], p.ang[2], p.ang[3]))
                e:SetSkin(p.skin or 0)
                e:Spawn()
                local phys = e:GetPhysicsObject()
                if IsValid(phys) then phys:EnableMotion(false) end
                if IsValid(ply) then
                    e:SetCreator(ply)
                    undo.Create("roma prop") undo.AddEntity(e) undo.SetPlayer(ply) undo.Finish()
                end
                e.romaArea, e.romaBy, e.romaName = area, t.by, t.name
                n = n + 1
                if budget then budget.left = budget.left - 1 end
            end
        end
    end
    return n, bad
end

local function areaLive(area)
    for _, p in ipairs(placed()) do
        if p.ent.romaArea == area then return true end
    end
    return false
end

concommand.Add("roma_props_edit", function(ply, _, args)
    local area = clean(args[1])
    local t = area and readArea(area)
    if not t then say(ply, "no saved area called '" .. tostring(args[1]) .. "'") return end
    if t.by and t.by ~= sid(ply) and not boss(ply) then say(ply, "area '" .. area .. "' belongs to " .. tostring(t.name or "someone else")) return end
    if areaLive(area) then say(ply, "area '" .. area .. "' is already on the map - move its props, then save it again") return end
    if baked[area] then say(ply, "area '" .. area .. "' is built into this map file already - ask for it to be left out of the next build first") return end
    local n, bad = spawnArea(t, area, ply)
    say(ply, string.format("area '%s': %d props spawned for editing%s", area, n, bad > 0 and (" | " .. bad .. " models are not on this server") or ""))
end)

concommand.Add("roma_props_delete", function(ply, _, args)
    local area = clean(args[1])
    local t = area and readArea(area)
    if not t then say(ply, "no saved area called '" .. tostring(args[1]) .. "'") return end
    if t.by and t.by ~= sid(ply) and not boss(ply) then say(ply, "area '" .. area .. "' belongs to " .. tostring(t.name or "someone else") .. " - only they or a superadmin can delete it") return end
    file.Delete(PDIR .. "/" .. area .. ".json")
    local n = 0
    for _, p in ipairs(placed()) do
        if p.ent.romaArea == area then p.ent.romaArea = nil n = n + 1 end
    end
    say(ply, "area '" .. area .. "' deleted (its " .. n .. " props stay on the map, unsaved, until removed or the server restarts)")
end)

-- saved areas come back after a restart (they are only built into the map file at the next build)
hook.Add("InitPostEntity", "pi_roma_tools_respawn", function()
    timer.Simple(8, function()
        local budget, areas, total, skipped, bad = { left = MAX_RESPAWN }, 0, 0, 0, 0
        for _, f in ipairs(file.Find(PDIR .. "/*.json", "DATA")) do
            local area = string.gsub(f, "%.json$", "")
            local t = readArea(area)
            if t and t.map == game.GetMap() and not areaLive(area) then
                if baked[area] and baked[area] == t.saved then
                    skipped = skipped + 1          -- unchanged since it was built into the map
                else
                    local n, b = spawnArea(t, area, nil, budget)
                    areas, total, bad = areas + 1, total + n, bad + b
                end
            end
        end
        print(string.format("[roma] saved prop areas put back: %d areas, %d props (%d areas already in the map file, %d models not on this server%s)",
            areas, total, skipped, bad, budget.left <= 0 and (", STOPPED at the limit of " .. MAX_RESPAWN .. " props") or ""))
    end)
end)

-- -------------------------------------------------------------------------------------------------------------- removal
local marks = {}
do
    local t = util.JSONToTable(file.Read(DIR .. "/remove.json", "DATA") or "")
    for _, r in ipairs(t or {}) do
        if r.key then marks[r.key] = r end
    end
end

local dirty = false
local function saveMarks()
    if dirty then return end
    dirty = true
    timer.Simple(2, function()
        dirty = false
        local list = {}
        for _, r in pairs(marks) do list[#list + 1] = r end
        table.sort(list, function(a, b) return a.key < b.key end)
        file.Write(DIR .. "/remove.json", util.TableToJSON(list, true))
    end)
end

local last = {}
net.Receive("pi_roma_rm", function(_, ply)
    if not IsValid(ply) then return end
    local now = CurTime()
    if (last[ply] or 0) > now - 0.12 then return end
    last[ply] = now
    local on, key = net.ReadBool(), net.ReadString()
    if #key < 10 or #key > 240 or not string.find(key, "@", 1, true) then return end
    if on then
        if table.Count(marks) >= MAX_MARKS then say(ply, "the removal list is full - tell the map owner") return end
        local model, origin, angles = net.ReadString(), net.ReadString(), net.ReadString()
        local v = {}
        for i = 1, 6 do v[i] = math.Round(net.ReadFloat(), 2) end
        if #model > 200 or #origin > 60 or #angles > 60 or key ~= model .. "@" .. origin then return end
        marks[key] = { key = key, model = model, origin = origin, angles = angles, mins = { v[1], v[2], v[3] }, maxs = { v[4], v[5], v[6] },
                       by = ply:SteamID64(), name = ply:Nick(), at = os.date("%Y-%m-%d %H:%M:%S") }
    else
        if not marks[key] then return end
        marks[key] = nil
    end
    saveMarks()
    net.Start("pi_roma_rm")
    net.WriteBool(on) net.WriteString(key) net.WriteString(ply:Nick())
    net.Broadcast()
end)

hook.Add("PlayerInitialSpawn", "pi_roma_tools_marks", function(ply)
    timer.Simple(6, function()
        if not IsValid(ply) then return end
        local keys = {}
        for k in pairs(marks) do keys[#keys + 1] = k end
        sendBlob(ply, "marks", table.concat(keys, "\n"))
    end)
end)

-- ----------------------------------------------------------------------------------------------------------------- pull
concommand.Add("roma_pull", function(ply)
    if not IsValid(ply) then print("[roma] roma_pull is run by a superadmin from inside the game") return end
    if not ply:IsSuperAdmin() then say(ply, "roma_pull is for superadmins") return end
    local areas = {}
    for _, f in ipairs(file.Find(PDIR .. "/*.json", "DATA")) do
        local t = util.JSONToTable(file.Read(PDIR .. "/" .. f, "DATA") or "")
        if t then areas[#areas + 1] = t end
    end
    local list = {}
    for _, r in pairs(marks) do list[#list + 1] = r end
    table.sort(list, function(a, b) return a.key < b.key end)
    local np = 0
    for _, a in ipairs(areas) do np = np + #(a.props or {}) end
    sendBlob(ply, "pull", util.TableToJSON({ map = game.GetMap(), pulled = os.date("%Y-%m-%d %H:%M:%S"), server = GetHostName(), areas = areas, marks = list }))
    say(ply, string.format("sending %d prop areas (%d props) and %d removal marks to your PC...", #areas, np, #list))
end)

concommand.Add("roma_help", function(ply)
    for _, l in ipairs({
        "PROPS: spawn, place and FREEZE them (physgun right click), then: roma_props_save <area>",
        "   roma_props_list | roma_props_edit <area> | roma_props_delete <area>   - saving the same area again replaces it",
        "REMOVAL: bind n roma_remove  - press it to turn the tool on, aim at a map prop, press again to mark it (again to keep it)",
        "   roma_remove_mode turns it off | roma_remove_count",
        "Saved props and marks stay on the server; they go into the map at its next build." }) do
        say(ply, l)
    end
end)
