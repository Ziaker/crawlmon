# D-185 — Rodada 66 Q4 (4B): cinco medições ATB por intervalo e combatente, mediana dos tempos

- **Data:** 2026-11-03.
- **Área:** Combate / ATB / protocolo de repetição.
- **Origem:** aprovação expressa do criador, Rodada 66.
- **Estado:** protocolo aprovado; nenhuma medição realizada.

## Declaração literal do criador

> 4B — Realizar cinco medições por intervalo e combatente e utilizar a mediana dos tempos observados.

## Regra aprovada

- Para **cada combatente representativo** escolhido na calibração (D-184), realizar **cinco medições por intervalo** de regeneração natural de ATB: cinco para **3→5 blocos** e cinco para **0→5 blocos** (D-175).
- Para cada par **combatente × intervalo**, ordenar os **cinco tempos observados** e adotar a **mediana dos cinco tempos** como resultado consolidado daquele par. Não substituir pela média aritmética, escolher apenas uma execução ou unir intervalos sem decisão.
- Manter as **condições controladas de D-180** em todas as repetições e preservar rastreabilidade dos resultados observados; uma medição só pode ser chamada medida após execução real.
- **Exemplo puramente hipotético:** cinco tempos `2,00 s; 2,01 s; 2,00 s; 2,18 s; 2,01 s` → ordenados `2,00; 2,00; 2,01; 2,01; 2,18` → mediana **2,01 s**. Esses tempos não vêm do jogo.
- A decisão **não determina ainda como combinar** os resultados das faixas baixa/intermediária/alta em **uma única referência numérica ATB**, nem coeficientes, precisão temporal ou critério de tolerância; essas questões permanecem pendentes conforme D-169.

## Pendências e escopo

- Definir método operacional para coletar tempos, candidatos reais e regras para falha de medição; executar e registrar as observações, e submeter referência derivada à aprovação do criador antes de implementar.
- Somente documentação; nenhum script, código, teste ou medição executado.
