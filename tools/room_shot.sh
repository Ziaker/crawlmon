#!/bin/sh
# Foto da sala de debug num instante de um cenario, em ~10 s (D-1204). Uso:
#   tools/room_shot.sh <cenario> <fase: windup|release|travel|strike|impact|return> <atraso_s> <saida.png> [flags extras da sala]
# Ex.: tools/room_shot.sh dig impact 0.45 /tmp/dig.png --card-style=trapdoor_slam
# Os flags da sala vao DEPOIS do "--" (sem ele o Godot quita no primeiro quadro e nao ha foto).
SC="$1"; PH="$2"; DL="$3"; OUT="$4"; shift 4
./Godot_v4.7.2-stable_win64_console.exe --path . res://scenes/debug/vfx_room.tscn -- --scenario="$SC" --pause-at="$PH" --pause-delay="$DL" --shot="$OUT" --quit "$@"
