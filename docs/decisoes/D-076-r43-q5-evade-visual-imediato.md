<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-076 — R43-Q5 (5A): Evade visual imediato e registro para impacto posterior

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 43
- **Estado:** decisão de design registrada após delegação às recomendações; implementação não afirmada.
- **Proveniência:** o usuário não informou letras individualmente. Ele respondeu literalmente **“Sigo suas recomendações”**. As alternativas abaixo foram **selecionadas e recomendadas pelo assistente**, com essa autorização geral. Não atribuir ao usuário a redação das alternativas.

## Autorização literal do usuário

> Sigo suas recomendações

## Pergunta e alternativa recomendada pelo assistente (não são citação do usuário)

- **Pergunta:** Quando o personagem realiza Evade durante a janela compartilhada da onda, quando ocorre a esquiva visual?
- **Escolha recomendada:** **5A — A esquiva visual acontece imediatamente ao apertar o botão; o motor registra a esquiva para o impacto posterior.**

## Regra consolidada

Na onda AoE, quando um personagem aciona um Evade válido, **a esquiva visual acontece imediatamente ao apertar o botão**. O motor **registra o resultado desse Evade para a resolução do impacto posterior da mesma onda**, mesmo que a frente ainda não tenha alcançado o personagem. A resolução continua individual, sem cancelar danos dos outros alvos.

## Referências e limitações

- **Decisões relacionadas:** D-007, D-059, D-066, D-075.
- **Pendência:** O registro vale para a onda pertinente, sem conceder invulnerabilidade genérica contra outras ações ou por duração não aprovada.
- **Escopo:** documentação somente, sem mudança de código, FX, configurações ou testes.
