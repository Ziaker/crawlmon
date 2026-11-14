<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-082 — R44-Q1 (1A): Crédito de restituição quando o medidor está cheio

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 44
- **Estado:** decisão de design documentada por recomendação aceita; não representa implementação no Godot.
- **Proveniência:** o usuário respondeu literalmente **“Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também”**. As alternativas foram recomendadas pelo assistente e aceitas nessa delegação; **não** constituem respostas individuais redigidas pelo usuário.

## Declaração literal do usuário

> Sigo suas recomendações e já faça as próximas perguntas na próxima mensagem também

## Pergunta e alternativa recomendada pelo assistente

- **Pergunta:** Como devolver integralmente um recurso se a barra já estiver cheia?
- **Escolha:** **1A — Guardar o excedente em um crédito separado, consumido antes do recurso normal.**

## Regra aprovada por delegação

Se a restituição integral de Burst ou ATB decorrente do cancelamento de um contra-ataque extra exceder o limite normal do medidor (5), guardar a parcela excedente como **crédito separado daquele recurso**, sem elevar o valor mostrado da barra acima do limite. O crédito é **consumido antes do recurso normal correspondente** no pagamento de ações. Não descartar o excedente.

## Referências, conflitos e limites

- **Decisões relacionadas:** D-033; D-062; D-063; D-072; D-073; D-074.
- **Pendência:** Persistência do crédito após o combate, combinação/prioridade entre créditos de Burst e de ATB e representação na HUD não estão definidos por esta resposta. Prioridade de Burst da D-063 permanece.
- **Escopo:** registrar decisão de design; nenhuma alteração de código, arte, VFX, testes ou dados de Moves autorizada.
