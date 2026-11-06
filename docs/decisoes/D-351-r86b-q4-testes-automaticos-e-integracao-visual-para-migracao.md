# D-351 — Rodada 86B Q4 (4A): testes de contrato, eventos, tempos e integração visual obrigatórios

- **Data:** 2026-11-06.
- **Área:** Engine de Moves / testes / aceitação de migração.
- **Origem:** aprovação expressa na Rodada 86B, questão 4.
- **Estado:** cobertura de validação obrigatória aprovada; nenhum teste novo implementado ou executado.

## Declaração literal do criador

> 4A — Exigir testes automatizados de identidade, eventos, ordem e tempos, além de testes de integração visual com interrupções, variantes, lados espelhados e anatomias distintas.

## Regra aprovada

- Para aceitar a migração de um Move à nova engine, exigir **testes automatizados** que verifiquem **identidade e integridade dos recursos, eventos/gatilhos, ordem de ocorrência e tempos** contra os contratos e valores aprovados.
- Exigir também **testes de integração visual e mecânica** cobrindo **interrupções**, **variantes quando existentes**, **atacantes e alvos em lados espelhados** e **anatomias diferentes**. Não considerar suficiente a verificação exclusiva de um Move piloto para todos os demais.
- A bateria deve aferir as regras **D-235** (mesmo Move para qualquer atacante/lado), **D-342** (equivalência antes de substituir legado) e **D-348–D-350** (autoridade mecânica, vínculo de ID/variantes/gatilhos e bloqueio de migração por falta de integridade).
- **Exemplo hipotético:** comparar o gatilho mecânico de impacto e o visual de um Move com uso normal, interrupção e atacante inimigo distante, repetindo para alvos de dimensões diferentes; o exemplo não fixa tolerâncias de milissegundos nem escolhe Move piloto.
- A **evidência concreta da execução dos testes deve ser examinada** antes de declarar o Move migrado/conforme. A aprovação desta regra **não equivale a testes aprovados por passagem presumida**.

## Pendências e escopo

- **Ainda não foram definidos** tolerâncias numéricas de sincronização, ferramenta de teste, matriz exata de casos, fixtures/personagens, método de inspeção visual automatizada, orçamento de tempo ou critérios de rollback. Exigir testes não implica que eles já existam ou tenham sido executados.
- A `main` inspecionada possui testes de combate, VFX e Motion Composer (e `BattleTrace` com inspeção parcial de sincronização), mas **nenhuma bateria específica de contratos dos pares de Resources da nova engine foi identificada** no commit `28816628d8a96489329369dd6740c0ffec88e877`.
- Somente documentação: nenhum código, teste, Resource, Move, cena ou VFX modificado, nenhuma execução Godot efetuada.
