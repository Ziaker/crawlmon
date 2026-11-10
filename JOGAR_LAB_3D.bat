@echo off
setlocal
cd /d "%~dp0"
if exist "Godot_v4.7.2-stable_win64.exe" (
    start "" "Godot_v4.7.2-stable_win64.exe" --path "%CD%" "res://scenes/debug/murky_forest_3d_lab.tscn"
) else if exist "Godot_v4.7.2-stable_win64_console.exe" (
    start "" "Godot_v4.7.2-stable_win64_console.exe" --path "%CD%" "res://scenes/debug/murky_forest_3d_lab.tscn"
) else (
    echo Godot nao encontrado na pasta do projeto.
    pause
)
endlocal
