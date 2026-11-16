---
name: deepseek-command-code
description: >-
  Workflow and quality barriers for collaborating with DeepSeek V4.1 Flash via Command Code CLI
  (ds-decisions.mjs, ds-run.mjs, ds-compliance.mjs). Use when scanning all D-*.md decisions via
  DeepSeek, delegating non-visual GDScript/logic/tests to DeepSeek, or verifying a generated patch
  before applying it.
---

# DeepSeek V4.1 Flash (Command Code CLI) Workflow

Use this workflow to collaborate with DeepSeek V4.1 Flash (`cmdc`) safely, without blowing context and without introducing rule regressions.

## 1. Read All Decisions Without Context Bloat
Write the creator's task (verbatim) to a scratch file (e.g. `$env:TEMP\ds_task.txt`) and run:
```powershell
node "$env:USERPROFILE\.claude\tools\ds-decisions.mjs" "$env:TEMP\ds_task.txt"
```
- Reads every `docs/decisoes/D-*.md` in batches via DeepSeek and prints a compact digest with literal quotes.
- If any batch says `LOTE n FALHOU`, re-run before proceeding.
- Open the decisive `D-xxx-*.md` files directly when you need full context.

## 2. Strict Role Split & Delegate Implementation (Non-Visual Work)
- **DeepSeek V4.1 Flash (ALWAYS via `ds-run.mjs`, NEVER raw `cmdc`):** executes all non-visual implementation (GDScript, combat rules, Move data, debug scenarios, tests, logic fixes).
- **Antigravity (exclusive role):** orchestrate/review the `.patch` (`ds-compliance.mjs` + debug tests), run **visual audit** (full-size frames in both D-235 views, `--audit-leaks`, `--envelope-graph`, `--scale-overlay`), and perform **visual polish/improvements** (VFX, shaders, UI/HUD, lighting, camera, animation).
- **Explicit ban:** NEVER claim you delegated to DeepSeek without having executed `ds-run.mjs` and returning real `proof=...` / `patch=...` from `[deepseek handoff]` / `[deepseek usage]`.

Write the prompt to `$env:TEMP\ds_prompt.txt` (never `/tmp/...` on Windows) containing:
- Exact goal and **exact files in scope** (with line ranges/symbols when known).
- Required reads: `AGENTS.md`, `docs/decisoes/README.md`, every relevant `D-xxx` file, and `docs/TELEMETRIA.md` if combat/damage/queue/status is touched.
- Explicit constraints:
  - Godot 4.7, GDScript, keep existing style.
  - Respect **D-235** symmetry (attacker/target on either side, any size).
  - Do not invent unapproved rules/values/visuals (AGENTS.md §2 — list ambiguities in `NOTES:` instead).
  - Do not touch `project.godot`, `.import`, `addons/`, `assets/`, or files outside scope.
  - Output **ONLY** a complete unified diff (`diff --git ...`) against current files, no placeholders (`...`), followed by `NOTES:`.

Run from the repo root (read-only; writes stay blocked):
```powershell
# Optional: enforce exact file scope automatically
$env:DS_SCOPE = "scripts/combat/example.gd,tests/battle/test_example.gd"

node "$env:USERPROFILE\.claude\tools\ds-run.mjs" "$env:TEMP\ds_prompt.txt" 15 low    # simple/medium
node "$env:USERPROFILE\.claude\tools\ds_run.mjs" "$env:TEMP\ds_prompt.txt" 25 high   # multi-file / complex
```
- Valid efforts: `off`, `low`, `high`, `max` (do NOT use `medium`).
- Pass 4th arg `neutral` only for self-contained tasks where all context is inlined; default `repo` lets DeepSeek read repo files.
- Never exceed 25 turns or pass `--yolo` without explicit creator authorization.
- `ds-run.mjs` automatically rejects lazy edits, forbidden paths (`project.godot`, `.import`, `addons/`, `assets/`), out-of-scope files (`DS_SCOPE`), and patches that fail `git apply --check`, retrying once with the exact error.

## 3. Compliance Pass Against Area Decisions
Before applying any non-trivial patch, verify it against every decision in the task's area (`docs/decisoes/_por_area/*.md` — e.g. `combate`, `dados-moves`, `overworld`, `ui-hud`, `vfx-animacao`, `processo`, `prototipos-ferramentas`):
```powershell
node "$env:USERPROFILE\.claude\tools\ds-compliance.mjs" "<patch-path>" "combate,dados-moves"
```
Fix or reject any reported `VIOLATION` before applying.

## 4. Mandatory Barriers Before Applying
Never apply a patch unless ALL 5 pass:
1. `[deepseek handoff]` shows `status=COMPLETE` and `apply_check=OK (applies cleanly)`.
2. `ds-compliance.mjs` reports `COMPLIANCE: OK` (when applicable to an area).
3. You read the `.patch` hunk by hunk and verify it matches the creator's request and nothing extra (AGENTS.md §3).
4. Apply with `git apply --ignore-whitespace "<patch-path>"` and run real verification (`python tests/battle/run_agent_combat_tests.py --test-d235`, `vfx_room --scenario=... --stdout-trace --strict-asserts --quit` in normal + `--mirror`).
5. Report clearly what DeepSeek did, what you verified, and what was **not** verified. If DeepSeek fails twice on the same task, stop retrying and implement it yourself.
