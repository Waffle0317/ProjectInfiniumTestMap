-- Roma 1939: players who join download the map and its content from the Steam Workshop (item 3843798845).
-- Written by tools/release_pack.py from build/release/workshop_id.txt. Server side only.
if string.find(game.GetMap(), "rp_projectinfinium_roma1939", 1, true) then
    resource.AddWorkshop("3843798845")
end
