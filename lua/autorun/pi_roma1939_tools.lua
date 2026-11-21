-- Roma 1939 - builders' tools (ships with the map addon).
--   roma_props_save <area> | roma_props_list | roma_props_edit <area> | roma_props_delete <area>
--   roma_remove_mode | roma_remove (bind a key: bind n roma_remove) | roma_remove_count
--   roma_pull (superadmin: copies everyone's saved props and removal marks from the server to your own PC)
--   roma_help
-- Everyone on the server may save props and mark props for removal; every entry records who made it.
-- On the map owner's own PC the owner's private tools (garrysmod/lua/autorun/.../pi_roma_*.lua) take over in single player.
if not (string.find(game.GetMap(), "rp_projectinfinium", 1, true) or string.find(game.GetMap(), "pi_roma", 1, true)) then return end

local ownTools = file.Exists("autorun/server/pi_roma_props.lua", "LUA") or file.Exists("autorun/client/pi_roma_remove.lua", "LUA")
if ownTools and game.SinglePlayer() then return end

if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("pi_roma1939/cl_tools.lua")
    include("pi_roma1939/sv_tools.lua")
else
    include("pi_roma1939/cl_tools.lua")
end
