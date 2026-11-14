<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1091 — Cores dos anéis no chão: NPC branco; inimigo amarelo/vermelho/azul

- **Data:** 2026-11-09.
- **Área:** Exploração / indicadores de mundo / IA.
- **Relacionadas:** D-1086 (anéis/ícones), D-310/D-315 (ameaça/Medroso), D-1063 (NPCs).
- **Status:** **teste implementado e verificado** no lab isolado; batalha, 2D, HUD/status, cards e regras não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> NPCS usam aneis brancos, inimigos usam aneis amarelos e vermelhos, amarelos para quando ficam em alerta (!) e vermelhos para quando estão indo atrás de vc. Azuis para quando estão correndo de vc ou querendo conversar ao invés de lutar

## Decisão

1. **NPC:** anel **branco**.
2. **Inimigo:**
   - **amarelo** enquanto o alerta `!` está ativo (0,6 s) e enquanto procura (`SEARCH`);
   - **vermelho** quando está indo atrás de você (`CHASE`);
   - **azul** quando está fugindo (`FLEE`) ou quando quer conversar em vez de lutar (`wants_to_talk`);
   - **âmbar** em patrulha/retorno (inimigo ainda não atacando).
3. **Prioridade:** o alerta `!` vence a cor de fuga durante os 0,6 s; depois o anel fica azul. O `CHASE` fica vermelho após o alerta.
4. **Aliado:** continua **azul** (D-1086), e some quando está diretamente atrás do jogador.
5. **“Quer conversar”:** o inimigo pode ser marcado com `wants_to_talk=true` no corpo; não há inimigo atual nesse estado, é o gancho para recrutamento/conversa futura.
6. **Não muda:** dano, combate, detectar/perseguir, batalha por toque, 2D, HUD/status, cards e regras.

## Teste implementado (2026-11-09)

Auditoria no lab isolado:

- **Alerta `!`:** `state=4`, `alert=0,57`, `icon=alert`, `ring=(1.0, 0.82, 0.15, 0.85)` — amarelo.
- **Fuga:** `state=4`, `alert=0,0`, `icon=sweat`, `ring=(0.22, 0.48, 1.0, 0.78)` — azul.
- **Perseguição:** `state=1`, `icon=anger`, `ring=(0.95, 0.15, 0.15, 0.80)` — vermelho.
- **NPC:** anel branco em `murky_forest_prompt_z_talk.png`.
- **Provas visuais:** `murky_forest_prompt_z_talk.png` (NPC branco), `murky_forest_indicators_medroso.png` (fuga azul), `murky_forest_chase_burst.png` (perseguição vermelha/estouro).
- **Amarelo:** validado pela auditoria; a captura do alerta não ficou legível porque o Slime estava atrás do jogador no instante dos 0,6 s.

## O que não foi verificado

- Um inimigo real em `wants_to_talk` (o gancho existe, mas nenhum inimigo o usa ainda).
- A leitura das cores em daltonismo; a cor pode ser reforçada pelo ícone (já existe).
- 60 fps/mobile, outras resoluções e a cena principal completa (VFX de outra sessão).

## Estado

Teste implementado e verificado no lab isolado. Anéis de NPC/inimigo/aliado com as cores pedidas. Commit local; **sem push**.
