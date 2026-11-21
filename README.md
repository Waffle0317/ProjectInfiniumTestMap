# Roma 1939 - Project Infinium - test map (V1)

Map: `rp_projectinfinium_roma1939_v1` - Garry's Mod, Helix RP. Test build for play-testing, feedback and prop placing.

**Needs:** Garry's Mod, up to date. Nothing else - no Workshop addon, no mounted game. Everything the map uses is in this
repository (see `CREDITS.txt`); the Counter-Strike: Source and Half-Life 2 episode content it uses ships inside Garry's Mod.

The repository **is** the addon folder: `maps/`, `materials/`, `models/`, `sound/`, `lua/`, `data_static/`.
The map file is over GitHub's 100 MB limit, so it travels zipped: `maps/rp_projectinfinium_roma1939_v1.bsp.zip` (about 85 MB).
**It has to be unpacked once after every download or update** - one double-click for testers, one click in the server panel.

## Testers - installing

1. Get the files - either way works:
   - **Download ZIP** (the green *Code* button on GitHub) and unpack it, or
   - clone with [GitHub Desktop](https://desktop.github.com/) or `git clone https://github.com/Waffle0317/ProjectInfiniumTestMap.git rp_projectinfinium_roma1939_v1`.
2. Put the folder into `...\steamapps\common\GarrysMod\garrysmod\addons` and make sure it is named exactly
   `rp_projectinfinium_roma1939_v1` (all lower case; a downloaded ZIP unpacks as `ProjectInfiniumTestMap-main` - rename it).
3. Double-click **`install_map.bat`** in that folder. It unpacks the map into `maps/` (about 230 MB).
   By hand instead: unpack `maps/rp_projectinfinium_roma1939_v1.bsp.zip` so that `maps/rp_projectinfinium_roma1939_v1.bsp` sits next to it.
4. Restart Garry's Mod (addon folders are only picked up when the game starts), then join the server - or `map rp_projectinfinium_roma1939_v1`.

**Updating:** download again (or *Pull*), then run `install_map.bat` again. If the game says your map differs from the
server's, the map was not unpacked after the update.

## Server (Physgun panel)

1. File Manager > open `/garrysmod/addons` > **Git** (top right) > **Clone** > paste the repository link, branch `main`.
   The repository is private: open **Git > Deploy Key** in the panel, add that key to this repository on GitHub
   (*Settings > Deploy keys > Add deploy key*, read-only is enough) and clone with the SSH link `git@github.com:Waffle0317/ProjectInfiniumTestMap.git`.
2. Make sure the cloned folder is named `rp_projectinfinium_roma1939_v1` (all lower case - a Linux server ignores addon folders with capitals).
3. Open that folder's `maps` folder, select `rp_projectinfinium_roma1939_v1.bsp.zip` and choose **Unarchive / Extract** (right-click or the `...` menu).
   `rp_projectinfinium_roma1939_v1.bsp` must appear beside it, about 230 MB. If the panel cannot unpack it, upload the `.bsp` by hand instead.
4. Check that `sourceengine/content_cstrike_dir.vpk` exists in the server's Garry's Mod install (it ships with the game).
5. Set the start map to `rp_projectinfinium_roma1939_v1` and restart the server.

**Updating the server:** **Git > Pull** in that folder, unpack the zip again (overwrite), restart.
The unpacked `.bsp` is not part of the repository (`.gitignore`), so a pull never collides with it.

Why zipped and not Git LFS: the panel's Git does not fetch LFS files - the server got a three-line text file instead of the
map ("is not a valid BSP file").

## Builders' tools - for everyone on the server

Console commands (`roma_help` lists them in game).

**Placing props** - spawn props from the Q menu, put them where they belong and **freeze** them (physgun, right click), then:

| command | what it does |
| --- | --- |
| `roma_props_save <area>` | saves **your** frozen props as that area (letters, digits, `_`); saving the same area again replaces it |
| `roma_props_list` | who saved what |
| `roma_props_edit <area>` | puts a saved area back so it can be changed (its owner or a superadmin) |
| `roma_props_delete <area>` | forgets an area (its owner or a superadmin) |

- Only frozen props are saved. Colour, material and size changes do not carry over.
- An area name belongs to whoever saved it first.
- Saved areas come back by themselves after a server restart, and are baked into the map at its next build.

**Marking map props for removal** - `bind n roma_remove`. The first press turns the tool on; aim at a prop of the map (yellow
outline) and press to mark it red; press again on a red one to keep it. Parts of buildings need two presses.
`roma_remove_mode` turns the tool off. Marks are shared - everyone sees them, each records who made it.

**Map owner:** join as superadmin and run `roma_pull` - it copies every saved area and removal mark to your PC.
On the server they live in `garrysmod/data/roma_tools/`.

## Known in this build

- Lighting is the fast pass; cubemaps are not built (reflections are plain).
- A broken stove / fridge / door shows no debris (those pieces never existed in their source packs).
- Props placed with models from an addon that is not in this repository only show for people who have that addon.
