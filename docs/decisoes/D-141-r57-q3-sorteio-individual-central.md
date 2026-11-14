<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-141 — Rodada 57 Q3 (B): Distribuição do sorteio individual favorece valores perto de zero

- **Data:** 2026-11-03
- **Área:** Personagens / atributos / combate / Rodada 57.
- **Origem:** escolha enviada expressamente pelo criador; as alternativas das questões 2–4 haviam sido recomendadas pelo assistente.
- **Estado:** regra aprovada e registrada em documentação; não implementada nesta atividade.

## Declaração literal do criador

> 3B — Como distribuir os sete resultados possíveis da variação individual? Valores próximos de zero são mais comuns, com −3 e +3 mais raros. (recomendação aceita)

## Regra aprovada

- Preservar os sete valores inteiros de D-132: **−3, −2, −1, 0, +1, +2, +3**, sorteados uma vez por atributo e indivíduo e persistidos.
- **Valores próximos de zero** devem ocorrer mais frequentemente, enquanto os extremos **−3 e +3** devem ser raros. **Nenhum peso exato, distribuição triangular/binomial ou simetria de probabilidades foi aprovado**.
- Com D-139, a soma do modificador a um atributo-base 99 pode resultar em 102, sem truncamento pelo antigo teto superior. A aleatoriedade não altera a identidade-base da espécie.

## Limitações

- Detalhes quantitativos não contidos na declaração literal continuam pendentes. Sem alterações de código, dados, testes, VFX ou assets.

## Complemento posterior — Rodada 58 (2026-11-03)

**D-144 (R58-Q3A):** a distribuição do sorteio individual de −3 a +3 foi agora definida como **triangular discreta**, com pesos **1:2:3:4:3:2:1** na ordem −3, −2, −1, 0, +1, +2, +3. A soma de pesos é 16; a decisão mantém o sorteio individual persistente da D-132 e não muda a permissão de atributos superiores a 100 da D-139.
