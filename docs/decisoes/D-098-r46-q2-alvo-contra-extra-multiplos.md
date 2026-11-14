<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-098 — R46-Q2 (2A): Seleção manual do atacante-alvo e seleção pela IA

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 46
- **Estado:** decisão de design e sequenciamento aprovada por aceitação das recomendações; implementação não afirmada.
- **Proveniência:** o usuário aceitou expressamente as recomendações 1B, 2A e 3A; o conteúdo da alternativa foi recomendado pelo assistente, não digitado individualmente pelo criador.

## Declaração literal do criador

> Crawlmon — Rodada 46: sigo suas recomendações 1B, 2A e 3A. Registre imediatamente no GitHub conforme D-061, preserve as decisões anteriores, não modifique código, valide a publicação e inclua as perguntas importantes da próxima rodada na MESMA resposta.

## Pergunta e alternativa recomendada aceita

- **Pergunta:** Quem escolhe o alvo após Evade perfeito contra vários atacantes?
- **Alternativa:** **2A — O jogador escolhe manualmente um dos atacantes; a IA escolhe quando estiver controlando o personagem.**

## Regra aprovada

Quando um personagem obtém **um único contra-ataque extra** ao evitar perfeitamente ataques de vários agressores (D-093), **o jogador escolhe manualmente um dos atacantes como alvo** se controlar o personagem; **a IA escolhe um dos atacantes** se controlar o personagem. Preservar escolha manual do Move, pagamento e enfileiramento já aprovados.

## Referências e limitações

- **Referências:** D-021, D-043, D-051, D-052, D-053, D-062, D-063, D-093.
- **Questões em aberto:** A política concreta com que a IA escolhe entre atacantes não foi definida. Ainda não está decidido se a seleção de alvo precisa ocorrer dentro dos mesmos dois segundos da seleção do Move; não presumir essas regras.
- **Escopo desta entrega:** criar somente documentação. Nenhum código de jogo, FX, teste ou configuração foi alterado.
