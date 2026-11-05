# D-271 — Nature em valores flat (de −3 a +3), só atributos e formas de agir em combate

- **Data:** 2026-11-04
- **Área:** Personagens / atributos / Natures
- **Origem:** decisão direta do criador, na conversa, ao receber a sugestão de Nature em percentual.
- **Estado:** regra registrada; **sem implementação**. **Natures adiadas por decisão do criador:** implementar só depois de mais planejamento; nada de Nature entra no código por ora.

## Declaração literal do criador

> nao quero porcentagens quero valores flat

> ate +3 e ate -3, pode ter alguns que tem +1 e +1 e +1 em 3 atributos diferentes e -3 em um so por exemplo

> 2 - so atributos e formas de agir em combate como dita no gdd

> (Sobre quantos atributos uma Nature altera:) pode alterar 2, pode alterar so 1, pode alterar 6 atributos, depende

> (Sobre a soma dos modificadores de uma Nature:) devem sim somar 0

> (À pergunta sobre a contradição entre "soma 0" e "alterar só 1 atributo", opção 1 = mínimo de 2 atributos:) 1

> vamos deixar as natures pra implementar outra hora, precisa de mais planejamentp

## Regra aprovada

- Os modificadores de **Nature** são **valores flat somados** aos atributos, **não porcentagens**. A sugestão anterior do assistente (`+X%` / `−X%`) não vale.
- Cada modificador de atributo de uma Nature vai de **−3 a +3**.
- Uma Nature pode ter **formatos diferentes**: por exemplo `+1, +1, +1` em três atributos diferentes e `−3` em um só.
- A Nature afeta **somente** (a) os **atributos** e (b) as **formas de agir em combate** (a tendência tática da IA, como o GDD descreve). **Não** inclina o crescimento por nível (a menção a "crescimento" nas rodadas R14-Q5/R15-Q4 do GDD fica como histórico, superada por esta resposta quanto ao crescimento).
- Uma Nature pode alterar **de 2 a 6 atributos**, conforme a Nature ("depende"). Como a soma é 0, nenhuma Nature altera só 1 atributo (o criador escolheu "mínimo de 2" ao resolver a contradição; a fala anterior sobre "só 1" fica como histórico).
- Os modificadores de cada Nature **somam 0** (o que ela dá em um atributo, tira em outros).
- Preservados: variação individual de pontos inteiros (D-132, D-144, D-147), ausência de teto (D-139), buffs separados (D-129, D-158) e a regra de que a Tactic escolhida prevalece sobre a Nature (R16-Q5).

## Ambiguidades em aberto (perguntar antes de agir)

- Se pode haver Natures neutras (nenhum atributo alterado); o criador falou de 1 a 6 atributos alterados, não de zero.
- Como as Natures são definidas: lista escrita à mão com nomes, ou combinações geradas dentro desses limites.
- Como cada Nature se liga às "formas de agir em combate" (qual tendência tática sai de qual Nature); o GDD cita o vínculo mas não define a tabela.

## Estado no código

Nenhuma alteração.

> **Renumeração (2026-11-05):** este registro foi criado localmente com outro número (D-19x) que colidia com as decisões das Rodadas 68-82 do GitHub (D-192 a D-268). Por escolha do criador passou a ser **D-271**; texto e regras não mudaram.
