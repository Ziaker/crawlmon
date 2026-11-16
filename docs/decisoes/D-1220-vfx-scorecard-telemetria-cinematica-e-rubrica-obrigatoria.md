<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1220 — Scorecard automático de VFX, telemetria cinemática genérica (`vfx_frame`) e ciclo obrigatório de melhoria

- **Data:** 2026-11-15.
- **Área:** VFX de Move / Movimento / Debug / Telemetria / Processo.
- **Relacionadas:** D-1218, D-1204, D-1154, D-1044, D-1042, D-308, D-235, D-274.
- **Status:** aprovada pelo criador; em implementação (DeepSeek via `ds-run.mjs` + auditoria e correção pelo Antigravity).

## O que o criador disse (literal)

> "ache um jeito de melhorar a revisão e analise de criação de VFX de moves que FUNCIONE e que faça a IA melhorar"
> "eu quero que faça mais uma checagem por melhorias e me diga se realmente elas resolvem os problemas, especialmente quanto a criação de movimento de moves"
> "quero ambas propostas implementadas e obrigatoriamente levadas em conta nas regras"
> "use o deepseek pra cada etapa e auditorie seus resultados, corrija o que ele fez errado ou esqueceu"

## Decisão

1. **Etapa 1 — Correção de `vfx_room_analysis.gd` e telemetria genérica `vfx_frame`:**
   - Corrigir `_audit_vfx_leaks()` (bug do `GPUParticles3D` sempre marcando `is_leaking = true`), `_sample_envelope()` (monitoramento por nó cobrindo `MeshInstance3D`, `CPUParticles3D`, `Sprite3D`, `OmniLight3D`, `visible` e `scale`, exportado no `SUMMARY_JSON`) e `_run_test_d235()` (validar `vfx_spawns`, `leaks == 0`, `pops == 0` e paridade normal × espelhado em vez de apenas `_fired`).
   - Adicionar evento opt-in `vfx_frame` em `BattleTrace` / `vfx_room.gd` (sob `--stdout-trace` / `--vfx-trace`, sem custo no jogo normal) registrando por quadro para cada nó condutor/filho de `BattleFx`: `node`, `stage`, `pos` `[x,y,z]`, `vel` `[vx,vy,vz]`, `speed`, `progress` (`0..1` no eixo atacante→alvo), `lateral_offset`, `height_y`, `dist_to_target`, `screen_px` `[w,h]`, `alpha`, `scale`, `visible`.
2. **Etapa 2 — `tools/vfx/score_vfx.py`, arquétipos de movimento, specs por Move e banco de regressões:**
   - Script único `tools/vfx/score_vfx.py --move="<Nome>"` (meta < 15 s em headless) que roda Normal + Espelhado e emite boletim objetivo PASS/FAIL.
   - Validação dos 4 arquétipos de movimento (`melee_strike`, `projectile_travel`, `aoe_wave`, `status_aura`) com checagens cinemáticas (pico de velocidade sincronizado com `hit`/contato, ausência de *stall* ou teleporte, *follow-through*, progressão monotônica ou passagem contínua).
   - Gráfico automático combinado (velocidade/progresso/envelope no topo + trajetória normalizada Normal × Espelhado sobreposta embaixo).
   - Suporte a contratos literais por Move em `tests/vfx/specs/<move_id>.json` e banco de regressões em `tests/vfx/regressions.json` + rubrica em `docs/vfx/VFX_RUBRICA_E_ERROS.md`.
   - Reaproveitamento da análise de silhueta claro/escuro (`--bg=black` / `--bg=white`) na `vfx_room` quando executado com janela.
3. **Etapa 3 — Obrigatoriedade nas regras:**
   - Atualizar `AGENTS.md`, `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md` e `docs/TELEMETRIA.md` tornando o `score_vfx.py`, a telemetria `vfx_frame` e o registro de specs/regressões obrigatórios antes de qualquer entrega visual de VFX ou movimento de Move.

## Ambiguidades

- Limiares padrão de `screen_px` mínimo (ex.: 24–40 px a 37 m), tolerância de sincronia de contato (±2 quadros / ±0,05 s) e parâmetros dos arquétipos ficam como escolhas técnicas documentadas e ajustáveis nos arquivos de spec/regressão.
