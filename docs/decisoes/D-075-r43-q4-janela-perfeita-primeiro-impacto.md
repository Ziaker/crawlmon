<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-075 — R43-Q4 (4A): Janela perfeita única antes do primeiro impacto da onda AoE

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Qual é a referência temporal da janela perfeita compartilhada de uma onda AoE?
- **Escolha recomendada:** **4A — Uma janela de 0,22 s imediatamente anterior ao primeiro impacto da onda.**

## Regra consolidada

Para a onda de projéteis AoE, a **única janela compartilhada de Evade perfeito dura 0,22 segundos e termina imediatamente antes do primeiro impacto da onda**. Todos os alvos participantes podem tentar o Evade perfeito nessa mesma janela, inclusive os que receberiam impacto depois. Preservar o Evade comum durante a janela geral de voo.

## Referências e limitações

- **Decisões relacionadas:** D-030, D-059, D-066, D-057.
- **Pendência:** A regra especial da onda usa o primeiro impacto como referência; a regra individual de D-030 permanece para ataques comuns. Eventos em que o primeiro impacto previsto deixa de ocorrer exigem definição futura, não presumir marco substituto.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
