<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1014 — Drain Spear: passo curto, 8 luzes em correntes, impacto mais seco

- **Data:** 2026-11-09.

## Frase literal do criador

> 1 - moves de mid-range ainda tem os delays e preludios dos moves melee, só que em mid-range
> 2 - O efeito visual das luzes indo até o personagem precisam de um overhaul completo de animação
> 3 - o game feeling do impacto não é mt bom e talvez seja o timing

Respostas: "Do lugar" → "Passo curto"; luzes "2 Correntes"; impacto: aplicar a proposta ("Sim"). Feito nesta sessão ("Aqui").

## Decisão

1. **Mid-range (Drain Spear):** sem a corrida de corpo a corpo; um passo curto de 0,35 s até a distância de alcance; sem agachamento de antecipação; espera após o contato 0,75 → 0,15 s.
2. **8 luzes (correntes):** oito fios finos e ondulados saem do alvo até o atacante (0,18 s); depois se recolhem para o atacante puxando cada luz pelo fio; o anel se fecha num estalo. Viagem 0,30 → 0,75 s.
3. **Impacto:** flash branco curto no alvo; hitstop de 0,1 s **só nos corpos** (o relógio do combate e o leque continuam); empurrão do alvo e da câmera (D-1012).

## Ambiguidade

- "Passo curto" ainda cobre ~13,7 u (de 30 até o alcance de 16,3): é um deslize rápido de 0,35 s, não um passo literal.

## Estado

Implementado para revisão.
