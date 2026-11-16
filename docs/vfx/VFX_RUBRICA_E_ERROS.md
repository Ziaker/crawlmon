<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Rubrica de VFX, Movimento de Moves e Banco de Regressões (D-1220)

## 1. Fluxo obrigatório antes e depois de editar qualquer VFX/movimento

1. **Antes de codar:** traduza o pedido literal do criador em um contrato JSON `tests/vfx/specs/<move_slug>.json` (ex.: `karate_chop.json`, `fire_bullet.json`) com `archetype`, `min_screen_px`, `max_pops`, `max_leaks`, `forbid_nodes`, `require_phases`.
2. **Durante a iteração:** rode **sempre** o scorecard único antes de capturar imagens:
   ```powershell
   python tools/vfx/score_vfx.py --move="<Nome do Move>"
   ```
3. **Se `VFX_SCORECARD: FAIL`:** **proibido** enviar vídeo ou ajustar por chute. Leia a linha `[FAIL]`, corrija a causa raiz no código e rode o scorecard novamente até `PASS (100/100)`.
4. **Quando o criador reprovar qualquer detalhe:** registre a nova restrição no `specs/<move_slug>.json` (e em `tests/vfx/regressions.json` se for erro recorrente) antes de corrigir.

## 2. Os 4 Arquétipos de Movimento

| Arquétipo | Quando usar | O que o scorecard exige |
|---|---|---|
| `melee_strike` | Golpes físicos com avanço/corte/mão/arma | Pico de velocidade `>= 2.0 m/s` sincronizado com o contato (`|contact_delta_s| <= 0.25 s`) |
| `projectile_travel` | Feixes, projéteis e lanças lançadas | Progressão até o alvo (`progress >= 0.70` ou `dist <= 2.5 m`), sem teleporte reverso e sem *stall* no voo |
| `aoe_wave` | Ondas de área no campo | Nós visíveis ativos durante `travel`/`strike`/`impact` |
| `status_aura` | Buffs/debuffs SMT, Heal, Guard | Ancoragem próxima ao alvo e dissolução sem *pops* |
