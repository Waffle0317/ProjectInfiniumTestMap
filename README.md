# Roma 1939 - Project Infinium - test map (V1)

Map: `rp_projectinfinium_roma1939_v1` - Garry's Mod, Helix RP. Test build for play-testing, feedback and prop placing.

**Needs:** Garry's Mod, up to date. Nothing else - no Workshop addon, no mounted game. Everything the map uses is in this
repository (see `CREDITS.txt`); the Counter-Strike: Source and Half-Life 2 episode content it uses ships inside Garry's Mod.

The repository **is** the addon folder: `maps/`, `materials/`, `models/`, `sound/`, `lua/`, `data_static/`.
The map file (`maps/rp_projectinfinium_roma1939_v1.bsp`, about 230 MB) is stored with **Git LFS** because GitHub refuses files over 100 MB.

## Testers - installing

1. Install [GitHub Desktop](https://desktop.github.com/) (it brings Git LFS) or Git + Git LFS.
2. Clone this repository **into your addons folder, under this exact lower-case name**:

   ```
   cd "C:\Program Files (x86)\Steam\steamapps\common\GarrysMod\garrysmod\addons"
   git clone https://github.com/Waffle0317/ProjectInfiniumTestMap.git rp_projectinfinium_roma1939_v1
   ```

   In GitHub Desktop: *File > Clone repository*, and set the local path to `...\garrysmod\addons\rp_projectinfinium_roma1939_v1`.
3. Check that `maps/rp_projectinfinium_roma1939_v1.bsp` is about 230 MB. If it is under 1 KB, Git LFS did not run: run `git lfs pull` in the folder.
4. Restart Garry's Mod (addon folders are only picked up when the game starts), then join the server - or `map rp_projectinfinium_roma1939_v1`.

To update later: *Fetch / Pull* in GitHub Desktop, or `git pull` in the folder.

*Download ZIP* only gives the real map file if the repository owner has ticked **Settings > General > Archives > Include Git LFS
objects in archives**. After unpacking a ZIP, rename the folder to `rp_projectinfinium_roma1939_v1`.

## Server (Physgun panel)

1. File Manager > open `/garrysmod/addons` > **Git** (top right) > **Clone** > paste the repository link, branch `main`.
   The repository is private: open **Git > Deploy Key** in the panel, add that key to this repository on GitHub
   (*Settings > Deploy keys > Add deploy key*, read-only is enough) and clone with the SSH link `git@github.com:Waffle0317/ProjectInfiniumTestMap.git`.
2. Make sure the cloned folder is named `rp_projectinfinium_roma1939_v1` (all lower case - a Linux server ignores addon folders with capitals).
3. Check `maps/rp_projectinfinium_roma1939_v1.bsp` in that folder: about 230 MB. If it is a tiny text file, the panel's Git has no LFS - upload the
   `.bsp` by hand into the same `maps` folder (SFTP or the File Manager).
4. Check that `sourceengine/content_cstrike_dir.vpk` exists in the server's Garry's Mod install (it ships with the game).
5. Set the start map to `rp_projectinfinium_roma1939_v1` and restart the server. Later updates: **Git > Pull** in that folder, then restart.

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
