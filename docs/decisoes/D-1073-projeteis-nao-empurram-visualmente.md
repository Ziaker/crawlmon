<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1073 — Projéteis não empurram visualmente no contato

- **Data:** 2026-11-09.
- **Área:** Combate / regra visual de impacto.
- **Altera:** o recuo visual padrão de todo Move (D-1045/D-1051 e a regra geral de D-045/R40-Q5); não altera dano, ATB, acerto, esquiva, Guard, ARMOR nem o lançamento de K.O.

## Frase literal do criador

> mude uma regra do jogo, nao permita que projeteis empurrem o personagem visualmente ao contato, apenas moves mid-range e melee exceto se dito o contrario durante a confeccao de um move

## Decisão

1. **Projétil** (`Skill.Kind.PROJECTILE`) **não empurra** o alvo visualmente ao contato: nenhum deslocamento de recuo (`knock`). O flash, o hit-stop, a animação de dano no lugar e o texto continuam.
2. **Melee** (`Kind.MELEE`) e **mid-range/ranged** (`Kind.CAST`) continuam empurrando como antes.
3. **Exceção por Move:** cada `Skill` pode declarar `visual_push` na confecção:
   - `-1` (padrão): segue o `kind` (projétil não; melee/CAST sim);
   - `0`: nunca empurra;
   - `1`: sempre empurra, inclusive projétil.
4. **K.O.** continua com o lançamento balístico, que não é o recuo comum e não é afetado por esta regra.
5. O `Fire Bullet` mantém o empurrão maior quando interrompe um wind-up (D-236/D-1051): é uma exceção explícita de Move (`visual_push = 1`).

## Ambiguidades

- “Mid-range” foi lido como `Skill.Kind.CAST` (o `kind_name` do projeto chama CAST de “ranged”); se o criador quiser outro conjunto, é uma decisão nova.
- O recuo do **atacante** que é atingido no caminho (`AttackMotion.begin_hit_return`) é uma regra separada e não foi alterado; esta decisão trata do alvo empurrado pelo contato.
- A animação de dano (`_hit_react`) continua; só o deslocamento visual (`knock`) é removido.

## Estado

Implementado (2026-11-09). Teste: `tests/battle/test_d1073_visual_push.gd` (PASS). Vídeo do Tidal Surge na câmera do jogo: `test_captures/tidal_surge_gamecam.mp4` (4,5 s, `--cam=0`).
