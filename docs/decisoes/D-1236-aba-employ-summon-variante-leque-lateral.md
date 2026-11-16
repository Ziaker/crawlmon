<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1236 — Aba EMPLOY/SUMMON: variante "Leque lateral"

**Data:** 2026-11-16  
**Área:** UI/HUD de combate  
**Estado:** **implementado no HUD real e aprovado pelo criador em 2026-11-16** ("Sim, aprovado", sobre as capturas do jogo). Confirmar EMPLOY funciona desde a Fase 5; SUMMON ainda não faz nada (Fase 8). Código: `scripts/ui/fan_menu.gd` (leque lateral), `scripts/combat/battle_scene.gd` (`_command_entries`), `Battle.EMPLOY_BLOCKS`/`SUMMON_BLOCKS`; debug `--command-tab=<atb>[:subs][:down]`.  
**Relacionadas:** D-1229, D-1232, D-272 (Evade ↔ Guard), D-1011 (menu fixo), D-413 (texto em inglês). Protótipo: `prototypes/employ_summon_tab/index.html`.

## Frase literal do criador

> "Leque lateral, mas corrija os problemas de espaçamento e colisão de texto"

(escolha entre as variantes A · Leque lateral, B · Gaveta e C · Troca de página do protótipo; veio com um recorte em que "NO RESERVES" ficava em cima de "SUMMON")

## Decisão

1. A aba alternativa de TACTICS usa a variante **Leque lateral**: um segundo leque à direita do bloco TACTICS, com EMPLOY e SUMMON, e o leque principal visível e esmaecido.
2. O texto de detalhe **não pode colidir** com o título do bloco, e o espaçamento tem de ser corrigido.

## Como o protótipo passou a cumprir o item 2

- A largura do leque lateral é calculada pelo texto mais longo (título + folga + detalhe) e vale para os dois blocos; folga mínima medida de 18 px em todos os estados (`5 ATB`, `NEED 5 ATB`, `REFUSED`, `NO RESERVES`).
- Distância entre o leque principal e o lateral aumentada.

## Pendências (não implementar sem o sim do criador)

- A dica `›` no bloco TACTICS.
- Os textos de motivo: `NEED 5 ATB`, `REFUSED`, `NO RESERVES`.
- Se abrir a aba pausa o jogo (TACTICS hoje pausa).
