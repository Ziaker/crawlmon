<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1140 — Dano mágico usa MAG na mesma fórmula do dano físico

- **Data:** 2026-11-10
- **Área:** Combate / dano / atributos / Moves.
- **Origem:** resposta direta do criador na conversa, depois da auditoria do dano do Abra.
- **Estado:** implementado no motor e testado; fichas de Move alinhadas ao novo campo.
## Declaração literal do criador

> "a formula de dano mágico é pra ser igual a de dano físico obviamente"

> "Todos moves de dano do abra até o momento causam dano mágico e são do tipo mágico, além de escalar com MAG"

> "vc está certo sobre makakaja, retiro o que eu disse sobre os buffs"

> "foque em criar a formula e corrigir os problemas relacionados aos moves, vamos 1 por 1 dos moves do abra e depois veremos se o slime também é afetado"

## Regra aprovada

1. **Fórmula única.** O dano mágico ofensivo usa a mesma fórmula do dano físico, trocando apenas o atributo-base:
   - físico: `round(STR × potência × fraqueza × crítico × passos)`, mínimo 1;
   - mágico: `round(MAG × potência × fraqueza × crítico × passos)`, mínimo 1.
   - Depois da fórmula, o alvo aplica a defesa exatamente como hoje (estágios de defesa, Guard, ARMOR etc.).
2. **Classificação por Move, não pela forma geométrica.** Cada Move declara se causa dano físico ou mágico na própria ficha. MELEE, PROJECTILE, CAST e STATUS não decidem, por si, qual atributo escala (D-122).
3. **Moves do Abra nesta rodada.** Os cinco Moves de dano equipados pelo Abra são mágicos e escalam com MAG:
   - Confusion;
   - Psybeam;
   - Shock Wave;
   - Teleport;
   - Megido.
4. **Moves de status do Abra.** Media e Sukunda continuam sem dano. Media mantém a cura `10 + MAG` (D-337).
5. **Buffs de ATK não afetam MAG.** Tarukaja/`atk_buff` continua exclusivo do dano físico. Makakaja (buff de magia) não existe nesta rodada e não foi autorizado.
6. **Escopo desta rodada.** Só os Moves do Abra. O Slime (e as demais espécies) será avaliado depois, em rodada própria.

## Ambiguidades em aberto (perguntar antes de agir)

- **Mitigação mágica por WIS:** D-130/D-138 dizem que WIS (antigo SPI) mitiga dano mágico, mas a fórmula nunca foi aprovada. Esta rodada **não** implementa essa mitigação; mantém os estágios de defesa atuais. Perguntar a fórmula antes de mexer.
- **Outros Moves mágicos do jogo:** quais Moves de outras espécies são mágicos (Slime, Orc, Cyclops, Gible etc.) fica para a rodada seguinte, como o criador pediu.
- **Megido:** a ficha diz "Almighty/Mystic", mas o `.tres` usa o elemento Light (9). Não foi alterado nesta rodada; é uma decisão separada.
- **Buffs de MAG:** não criar `mag_buff` nem Makakaja sem decisão expressa.

## Complementos posteriores

- **D-1142:** o dano mágico agora sofre mitigação natural por WIS (`max(1, round(dano × 10 / (10 + WIS)))`).
- **D-1143:** o dano físico agora acompanha a STR efetiva, inclusive pontos alocados no level-up.
- **D-1144:** Megido passou a Mystic; os textos da ficha usam Mystic/MAG.

## Estado no código

- `MoveData.damage_type` (novo campo) declara Physical/Magical por Move.
- `Skill` carrega a classificação e expõe o atributo-base correto.
- `Battle._hit` e `Battle.estimate_damage` usam MAG quando o Move é mágico.
- Os cinco Moves de dano do Abra estão marcados como mágicos.
- Fichas/UI (`status_screen`, `skill_info_panel`, `move_card`, `move_inspection_modal`) usam `is_magical()` e a fórmula real, em vez da heurística por `kind`/elemento.
- Teste dedicado `tests/battle/test_d1140_magic_damage.gd`: passa (`D1140_PASS`), cobrindo os cinco Moves no caminho real de `_hit`, Tackle físico, Media sem dano e Tarukaja sem efeito no dano mágico.
- Testes de regressão executados: D-032, D-1005, Drain Spear, D-1073, attribute math, D-1025, D-977, D-159, D-1062, status screen, HUD badges, move icons e LevelUpHUD — todos passaram. `test_d272_guard.gd` não terminou em headless nesta rodada (não é falha registrada; ficou sem resultado).
- Nada de commit/push sem autorização (D-022).
