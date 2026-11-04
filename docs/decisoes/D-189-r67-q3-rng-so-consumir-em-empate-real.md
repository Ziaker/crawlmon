# D-189 — Rodada 67 Q3 (3A): consumir RNG de retarget somente quando há empate real

- **Data:** 2026-11-03.
- **Área:** Combate / retarget / consumo de RNG.
- **Origem:** aprovação expressa do criador, Rodada 67.
- **Estado:** regra aprovada, não implementada.

## Declaração literal do criador

> 3A — Consumir RNG exclusivo somente quando houver pelo menos dois candidatos empatados elegíveis.

## Regra aprovada

- O fluxo pseudoaleatório **exclusivo do retarget** (D-186), inicializado pela seed própria do combate (D-187), **só deve ser consumido quando houver no mínimo dois candidatos vivos e elegíveis empatados pela regra de proximidade** (D-171/D-181).
- **Nenhuma rolagem** desse fluxo é consumida se o retarget tiver **um único candidato elegível**, **nenhum candidato** ou **nenhum empate de proximidade**. Nesses casos, preservar as demais regras de redirecionamento e encerramento de combate, sem inventar alvo ou ação adicional.
- **Exemplo ilustrativo:** a morte de um alvo em WINDUP deixa apenas Abra como novo candidato vivo. Abra é selecionado pela regra de retarget sem avançar o RNG. Em evento posterior, dois candidatos vivos estão empatados dentro de 0,01 unidade: **nesse momento** o RNG exclusivo é consumido para sorteio.
- Os candidatos empatados devem estar **ordenados por identificador estável** antes do sorteio (D-188); o resultado segue pseudoaleatório, não por ID fixo.
- Esta decisão não define quantas operações internas um algoritmo específico usa por sorteio, algoritmo de uniformidade, seed nem política de eventos concorrentes. A intenção aprovada é **não consumir o fluxo se não existir escolha entre pelo menos dois empatados elegíveis**.

## Pendências e escopo

- Especificar em momento futuro algoritmo e ordem temporal de sorteios simultâneos; garantir reprodutibilidade em replay.
- Somente documentação; nenhum código, cena, teste ou RNG implementado.
