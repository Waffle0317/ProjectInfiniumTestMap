@echo off
rem Unpacks the map file. GitHub does not take files over 100 MB, so the map travels zipped.
cd /d "%~dp0maps"
echo Unpacking rp_projectinfinium_roma1939_v1.bsp ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Force -LiteralPath 'rp_projectinfinium_roma1939_v1.bsp.zip' -DestinationPath '.'"
if exist "rp_projectinfinium_roma1939_v1.bsp" (
  echo Done. Restart Garry's Mod.
) else (
  echo FAILED - unpack maps\rp_projectinfinium_roma1939_v1.bsp.zip by hand so that rp_projectinfinium_roma1939_v1.bsp sits in the maps folder.
)
pause
