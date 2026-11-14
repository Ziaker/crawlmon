<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-399 — Curva de XP quadrática e recompensa por inimigo derrotado

- **Data:** 2026-11-07
- **Área:** Progressão / Experiência / Combate
- **Origem:** Recomendações técnicas formuladas no Concepts Brief e aprovadas pelo criador na conversa.
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> "eu não tenho ideia de como mexer com estes valores, sigo suas recomendações"

## Regra aprovada

1. **Curva de Experiência por Nível:**
   A experiência necessária para alcançar o nível $L$ a partir do nível $L-1$ segue a curva quadrática:
   $$\text{XP\_Necessário}(L) = 50 \times L^2$$
   - Nível 1 → 2: 50 XP (1 a 2 combates no 1º andar).
   - Nível 2 → 3: 200 XP (~3 combates).
   - Nível 3 → 4: 450 XP.
   - Nível 9 → 10 (Marco): 4.050 XP (alcançado próximo aos andares finais de uma masmorra padrão de 5 andares, D-316).

2. **Recompensa de Experiência por Inimigo (Drop de XP):**
   A experiência concedida por um inimigo abatido é calculada por:
   $$\text{XP\_Drop} = \text{base\_exp} \times \text{level}$$
   - Inimigos comuns iniciais (ex.: Gible) possuem $\text{base\_exp} = 30$.
   - O XP total conquistado na batalha é creditado integralmente a cada combatente ativo da equipe que encerrou a luta vivo (sem divisão punitiva pelo tamanho do grupo).

## Ambiguidades em aberto (perguntar antes de agir)

- Tabela completa de `base_exp` para futuras espécies quando forem adicionadas ao jogo.

## Estado no código

Nenhuma alteração.
