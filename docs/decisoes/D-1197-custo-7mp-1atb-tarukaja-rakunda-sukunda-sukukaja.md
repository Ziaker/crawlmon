# D-1197 — Tarukaja, Rakunda, Sukunda e Sukukaja custam 7 MP e 1 ATB

- **Data:** 2026-11-12
- **Área:** Combate (custos de Move)
- **Origem:** Conversa
- **Estado:** aplicada no código (diff gerado pelo deepseek-code, conferido e aplicado; testes de combate 27/28, mesma falha de antes, D-1166)

## O que o criador disse (literal)

> "faca todos custarem 7mp e 1atb"

(resposta à pergunta do custo do Sukukaja; antes ele havia dito "tudo igual aos outros dois exceto efeito visual e efeito mecanico".)

> "Pera é sukukaja e não o equivalente de 1 alvo só, tá certo ser no grupo inteiro, aumente o custo também pra 10MP e 2atb de custo" (depois, só sobre o Sukukaja)

## Decisão

> "Eu digo fazer o tarukaja ter os mesmos custos" (esclarecimento ao "Faça o mesmo para o rakukaja do pancham": o Tarukaja, que o Pancham tem, acompanha o custo do Sukukaja; **nenhum Rakukaja é criado**)

0. **Atualização:** o **Sukukaja** e o **Tarukaja** passam a custar **10 MP e 2 ATB** (ambos em grupo). Rakunda e Sukunda continuam em 7 MP e 1 ATB. O diff do Tarukaja ainda será gerado e aplicado (após o do Sukukaja). Isto desfaz a parte do D-1197 original que baixou o Tarukaja a 1 ATB (voltando a 2 ATB, como no D-031).
1. Tarukaja, Rakunda, Sukunda e Sukukaja custavam **7 MP e 1 ATB** cada (valor original desta decisão).
2. Arquivos alterados: `content/moves/{tarukaja,rakunda,sukunda}/move.tres`, `scripts/data/skill.gd` (custo ATB do Tarukaja 2 → 1), `scripts/data/skill_legacy_data.gd` (`mp_costs()` e texto do Tarukaja).
3. **Altera D-031**, que fixava Media/Tarukaja em 2 ATB, para o Tarukaja. A Media continua em 2 ATB.

## Ambiguidades em aberto

- "todos" foi aplicado aos três moves de buff/debuff de estágio e ao Sukukaja; **não** a todos os Moves do jogo. Confirmar.
- Personagens com MP máximo abaixo de 7 não conseguem lançar esses moves. Não verificado.
