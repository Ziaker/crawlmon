#!/usr/bin/env python3
"""Insere (idempotente) o bloco DEBUG-OBRIGATORIO-D1204 no topo de todos os .md do projeto."""
import subprocess, sys, os
MARK = "<!-- DEBUG-OBRIGATORIO-D1204 -->"
END = "<!-- /DEBUG-OBRIGATORIO-D1204 -->"
BLOCK = f"""{MARK}
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
{END}
"""
EXCL = ("addons/", "assets/", "skills/", ".claude/", ".agents/", "docs/vfx/referencias/")
os.chdir(subprocess.check_output(["git","rev-parse","--show-toplevel"]).decode("utf-8").strip())
out = subprocess.check_output(["git","-c","core.quotepath=off","ls-files","*.md"]).decode("utf-8")
n=0
for p in out.splitlines():
    if p.startswith(EXCL) or not os.path.isfile(p): continue
    raw = open(p,"rb").read()
    txt = raw.decode("utf-8")
    nl = "\r\n" if "\r\n" in txt else "\n"
    if MARK in txt: continue
    blk = BLOCK.replace("\n", nl)
    bom = txt.startswith("\ufeff")
    if bom: txt = txt[1:]
    if txt.startswith("---"+nl) or txt.startswith("---\n"):
        i = txt.find("\n---", 3)
        j = txt.find("\n", i+1)
        j = len(txt) if j<0 else j+1
        txt = txt[:j] + blk + nl + txt[j:]
    else:
        txt = blk + nl + txt
    open(p,"wb").write((("\ufeff" if bom else "")+txt).encode("utf-8")); n+=1
print("inseridos:", n)
