<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-097 — R46-Q1 (1B): Implementação em sistemas completos e testados

- **Data:** 2026-11-03
- **Área:** Combate / Rodada 46
- **Estado:** decisão de design e sequenciamento aprovada por aceitação das recomendações; implementação não afirmada.
- **Proveniência:** o usuário aceitou expressamente as recomendações 1B, 2A e 3A; o conteúdo da alternativa foi recomendado pelo assistente, não digitado individualmente pelo criador.

## Declaração literal do criador

> Crawlmon — Rodada 46: sigo suas recomendações 1B, 2A e 3A. Registre imediatamente no GitHub conforme D-061, preserve as decisões anteriores, não modifique código, valide a publicação e inclua as perguntas importantes da próxima rodada na MESMA resposta.

## Pergunta e alternativa recomendada aceita

- **Pergunta:** Qual deve ser a próxima entrega do combate?
- **Alternativa:** **1B — Implementar por sistemas completos e testados: ATB/Evade/contra-ataque, depois AoE, depois animações e câmera.**

## Regra aprovada

Adotar **implementação sequencial por sistemas completos e testados**, na ordem: **(1) ATB, Evade e contra-ataque; (2) AoE; (3) animações e câmera**. Concluir e validar cada sistema antes de avançar ao seguinte; preservar as regras já aprovadas nas Rodadas 39–45. Esta decisão **aprova o sequenciamento**, não autoriza editar código nesta atividade de registro.

## Referências e limitações

- **Referências:** D-003, D-019, D-021, D-023, D-031 a D-096.
- **Questões em aberto:** A ordem não significa que testes exclusivos do sistema dispensam testes de integração; não aprova refatorações, novos frameworks ou implementações adicionais não solicitadas. A autorização deste turno é exclusivamente documental.
- **Escopo desta entrega:** criar somente documentação. Nenhum código de jogo, FX, teste ou configuração foi alterado.
