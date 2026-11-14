<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-073 — R43-Q2 (2A): Devolver custo do contra-ataque cancelado por morte do alvo

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Se o alvo morrer antes da execução do contra-ataque extra, o custo deve ser devolvido?
- **Escolha recomendada:** **2A — Devolver integralmente o recurso pago pelo Move extra.**

## Regra consolidada

Se o alvo do contra-ataque extra morrer antes de sua execução, cancelar o golpe extra sem redirecionar o alvo (D-065) e **devolver integralmente o recurso debitado na seleção**.

## Referências e limitações

- **Decisões relacionadas:** D-062, D-063, D-065, D-072.
- **Pendência:** Preservar as regras de limite de recursos sem inventar comportamento para caso de medidor já cheio.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
