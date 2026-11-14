<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-280 — O atacante persegue o alvo desenhado; STRIKE com trajetória fixa (restaura D-054)

- **Data:** 2026-11-05
- **Área:** Combate / trajeto / visual
- **Origem:** Conversa (pedido de auditoria do trajeto + respostas às perguntas)

## O que o criador disse (literal)

> "corrija o movimento não estar perseguindo o oponente mas sim indo até seu ponto original, mesmo com ele fora do lugar."

Respostas às perguntas:

- Onde viu o erro: **"Só no visual"**.
- Quais deslocamentos acompanhar: **"TUDO, o visual deve acompanhar o mecânico, é a regra maior desse jogo ambos tem que conversar perfeitamente entre si"**.
- Conflito com D-045/D-019: **"Só o ponto de mira"**.
- STRIKE fixo: **"Sim, restaurar D-054"**.

## Decisão

1. A corrida (TRAVEL) persegue o alvo por todo o trajeto (D-044). O **ponto de mira** passa a ser o ponto onde o **modelo do alvo está desenhado** (desvio lateral, recuo de hit, pulo de volta, tudo), e não só a posição lógica de origem. A posição lógica do alvo **não muda** por isso (D-045 e D-019 preservadas).
2. O visual e o mecânico têm de conversar perfeitamente: nenhum deslocamento do alvo pode deixar o atacante correndo para um ponto em que o alvo não está.
3. **Restaurar D-044/D-054:** durante o STRIKE a trajetória do atacante fica fixa (sem perseguição contínua); o contato exato é corrigido **só no instante do impacto**.
4. Por D-235: por `move_id`, para qualquer personagem, time e lado.

## Ambiguidades em aberto

- A frase "o visual deve acompanhar o mecânico" pode também pedir que o modelo do alvo nunca fique em ponto diferente da posição lógica; aqui foi mantido "só o ponto de mira" (resposta expressa). Confirmar se resta algum caso em que isso não basta.
- Como o ponto de mira entra na regra de contato "exato" (D-046) quando o modelo do alvo ainda está se movendo no instante do impacto.
- Nos testes de regras (sem modelos) o atacante já persegue a posição lógica viva do alvo (corrida ou retorno): a divergência relatada só aparece com os deslocamentos desenhados pelos FX (`fx_dodge`, `knock`, tweens).

## Estado no código

**Item 3 implementado** (2026-11-05): `AttackMotion.update` não chama mais `_track` no STRIKE; só `arrive()` corrige o contato no impacto. Medido: deriva do par em dois STRIKE simultâneos 0,49 un (antes ~8 un, 31–36 u/s). **Itens 1–2 (mirar o ponto desenhado do alvo) não implementados**; teste: `tests/battle/test_d280_d281_strike_fixed_and_hold.gd`.
