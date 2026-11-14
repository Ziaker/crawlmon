<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-072 — R43-Q1 (1A): Devolver custo do contra-ataque cancelado por interrupção

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Se o ataque original for interrompido, o custo do contra-ataque extra deve ser devolvido?
- **Escolha recomendada:** **1A — Devolver integralmente o Burst ou ATB utilizado no contra-ataque extra.**

## Regra consolidada

Quando o contra-ataque extra já foi selecionado e pago, mas o ataque original é interrompido antes da execução, cancelar o extra (D-064) e **devolver integralmente o Burst ou o ATB que foi descontado por esse extra**.

## Referências e limitações

- **Decisões relacionadas:** D-062, D-063, D-064, D-033.
- **Pendência:** Os limites de capacidade máxima (5 ATB/Burst) durante eventuais restituições, se o recurso recuperou naturalmente entre o pagamento e o cancelamento, exigem tratamento consistente ainda não decidido. Não criar regra de perda parcial.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
