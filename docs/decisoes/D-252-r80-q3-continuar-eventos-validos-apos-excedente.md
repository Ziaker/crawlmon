# D-252 — Rodada 80 Q3 (3A): após excedente rejeitado, continuar eventos posteriores válidos do plano

- **Data:** 2026-11-04.
- **Área:** Combate / plano determinístico / ocorrências condicionais excedentes.
- **Origem:** escolha 3A expressa do criador na Rodada 80.
- **Estado:** regra de continuidade aprovada; não implementada nesta atividade.

## Declaração literal do criador

> 3A — Rejeitar e registrar somente a ocorrência excedente; continuar a resolver os eventos posteriores que já estejam validamente previstos no plano, preservando os anteriores.

## Regra aprovada

- Quando for solicitada uma **ocorrência condicional que exceda o máximo explícito do Move**, **rejeitar essa ocorrência específica e registrar a violação do plano** (D-242).
- **Continuar a resolver eventos posteriores que já estejam validamente previstos no plano determinístico**, desde que respeitem **suas condições e regras próprias de elegibilidade/execução**, sem interromper todo o Move apenas pela ocorrência excedente.
- **Preservar os eventos válidos já resolvidos**, sem desfazer seus efeitos. A rejeição **não adiciona índice** nem permite reutilização/renumeração; manter D-218/D-222/D-226/D-233 e o bloqueio de planos sem máximo D-238.
- **Exemplo hipotético:** o plano contém ocorrências válidas `#1`, `#2` e `#3` e limite máximo hipotético de três. Uma solicitação extra `#4` é **rejeitada e registrada**. A ocorrência `#3`, se ainda pendente e válida, **pode ser resolvida depois**; `#1` e `#2` permanecem como já resolvidas. Nenhum máximo de três foi aprovado para um Move real.
- Preservar D-095 quanto a resultados de KO simultâneo, e D-235 quanto a neutralidade de personagem/lado. **Não criar** consumo de RNG por ocorrência rejeitada nem transformar ausência de evento em acerto.

## Pendências e escopo

- **Não foi decidido** o canal/formato de registro da violação, estrutura do plano, limites numéricos por Move, como o erro foi produzido ou política de recuperação para outros tipos de falha. Continuar eventos válidos não força a execução de eventos que seriam cancelados por regras de morte, interrupção ou inelegibilidade já aprovadas.
- Não alterar retrospectivamente danos/status ou a ordem lógica de eventos anteriores; não inferir outros motivos de interrupção.
- Somente documentação; nenhum código, teste, Move, ficha, cena, asset ou VFX modificado.
