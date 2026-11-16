<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1247 — Murky Forest revisitada: arco como marco, sem persistência entre expedições

- **Data:** 2026-11-16
- **Área:** overworld 3D / level design / revisitas / exploração
- **Relacionadas:** D-1245, D-1246 (direção e frase literal do criador), D-1181, D-1208, D-1133, D-1151, D-1023, D-1028, D-1082/1083, D-235, D-1204, GDD R29-Q2/Q3, R30-Q2/Q4, R32-Q4, R33-Q3/Q4, R34-Q2, R36-Q2/Q3.
- **Estado:** aprovada; pendências E1 (gatilhos) e E2 (ordem) em aberto; nenhuma implementação.

## Frases literais do criador

> "Aprovar como direção (Recomendado)"

> "Só o arco como marco (Recomendado)"

> "Nada ainda — fica pendente (Recomendado)"

> "Nenhuma nova — só descoberta (Recomendado)"

## Decisão

> Para o mapa novo, a [D-1256](D-1256-murky-forest-mapa-autoral-tres-referencias.md) substitui a restrição de manter a planta física do primeiro recorte.

1. **Direção aprovada:** "Murky Forest como destino recorrente" passa a orientar o planejamento. É **direção**, não spec fechada: a proposta original dizia que ainda precisava ser testada em jogo.
2. **Primeiro recorte — geometria:** manter o espaço físico existente (D-1133/D-1151) e acrescentar **só o arco de pedra como marco visual**. A passagem de nível inferior e o posto de vigia ficam para **fase 2**, após medição de câmera (D-1023: 6,2 m / 22°, raycast) e navmesh.
3. **Persistência entre expedições:** **nada — fica pendente**, conforme GDD R30-Q2/R36-Q3. Vale somente o estado persistente **dentro da mesma expedição** (R36-Q3: itens coletados e eventos concluídos não reaparecem ao revisitar andar).
4. **Recompensa da volta:** **nenhuma nova — só descoberta** (chegar a um lugar antes inacessível). Não entrar com novo sistema de itens ou recrutamento neste recorte; candidato a recrutamento esbarra em R32-Q5 e no fluxo Employ/Summon (D-1229+).
5. **D-1245 continua valendo:** medir e alargar portas se necessário; descanso pendente; gating suave; áudio fora do escopo.
6. **Eventos são opcionais para o chefe** (R36-Q2) e não criam pré-requisito de progressão.

## Ambiguidades em aberto

- **E1 — gatilhos:** o que dispara cada evento de revisita (fala no Hub, quadro de expedições, marca no cenário, NPC).
- **E2 — ordem:** sequência das visitas e se algum arco tem continuidade exigida entre expedições.
- Intensidade, cor, tempo e quantidade não foram escolhidos.

## Estado

Documento criado antes de qualquer código. Plano atualizado em `docs/plans/2026-11-16-murky-forest-level-design.md`. Nada publicado; nenhum commit/push.
