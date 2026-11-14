# D-1195 — AGI deixa de reger o ATB diretamente; o efeito vira status EXHAUST (pendente)

- **Data:** 2026-11-12
- **Área:** Combate
- **Origem:** Conversa
- **Estado:** aprovada, não implementada — regra incompleta de propósito (gatilho, duração e efeito pendentes)

## O que o criador disse (literal)

> "nao mais o atb, o que afeta o atb vai ser uma condicao de status chamada de EXHAUST"
>
> "6 - ignore por ora" (resposta sobre gatilho, duração e efeito do EXHAUST)

## Decisão

0. **ATUALIZAÇÃO (2026-11-13), palavras do criador:** "Quanto ao atb usar AGI ainda está correto". **O ATB continua usando AGI como hoje** (`combatant.gd:152-162`, `natural_atb_increment`); o item 1 abaixo **não vale** como "AGI sai do ATB". O EXHAUST (que o criador descreveu como o que afeta o ATB, sem definição) segue pendente, e a fórmula do ATB não muda. Falta o criador dizer como o EXHAUST convive com o ATB por AGI.
1. (Superado pela atualização acima) AGI deixa de influenciar diretamente o preenchimento do ATB. Revoga a parte de ATB da D-117; a parte de trajeto continua (D-1194).
2. A perda de ATB que a AGI dava passa a ser representada pelo status EXHAUST.
3. Gatilho, duração e efeito do EXHAUST estão PENDENTES. Não implementar antes de aprovados.
4. **Pendente (não foi dito pelo criador):** o que fazer com o ATB por AGI e com o `speed_buff` enquanto o EXHAUST não existir. Hoje o código continua como antes (ATB por AGI e `speed_buff`).
5. Complementa D-1193/D-1194.

## Divergência com o código atual (registrar, não corrigir)

- Hoje a AGI governa o ATB: `combatant.gd:328` (`natural_atb_increment(1.0, agi)`) e `combatant.gd:159-161` (getter `speed`).
- `t.speed` como chance de esquiva da IA (`battle.gd:~798`) também depende da AGI; a D-1193 troca essa fórmula.

## Ambiguidades em aberto

- Gatilho do EXHAUST.
- Duração do EXHAUST.
- Efeito do EXHAUST (quanto de ATB reduz; acúmulo por estágio?).
- Se substitui ou convive com algum resíduo de AGI no ATB.
- Interação com pausa de status (D-031) e fila (D-161).
