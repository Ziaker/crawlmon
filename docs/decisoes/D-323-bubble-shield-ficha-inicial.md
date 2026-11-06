# D-323 — Bubble Shield: ficha inicial do Move e mecânica introduzida

- **Data:** 2026-11-05.
- **Área:** Fichas de Moves / combate / escudos.
- **Origem:** especificação direta do criador na conversa sobre Bubble Shield.
- **Estado:** requisitos de design expressamente definidos; ficha incompleta para implementação.

## Declaração literal do criador

> quero criar um move novo pra crawlmon, ele vai trazer junto com sigo uma mecânica nova, a mecânica de escudos, similar a league of legends e outros jogos, é uma "vida extra" que tem duração e detona ou some ao ser completamente reduzida ou ter sua duração finalizada
>
> é um move de custo 3 de ATB de alvo ALL ALLIES, de elemento água e tipo status com .7 de wind-up e o nome do move é Bubble Shield. o Escudo bloqueia 25+MAG do usuário para todos aliados por 8 segundos

## Parâmetros definidos

| Campo | Valor |
|---|---|
| Nome | Bubble Shield |
| Elemento | Água (Water) |
| Tipo de Move | Status |
| Seleção/facção | ALL ALLIES |
| ATB | 3 |
| Wind-up | 0,7 s |
| Proteção | 25 + MAG **do usuário** por aliado |
| Duração | 8 segundos |
| Natureza | Reserva de escudo temporário, independente do HP; acaba ao esgotar sua resistência ou terminar sua duração |

- Aplica-se a regra aprovada D-012: Moves amigáveis ALL incluem o próprio lançador. Não converter o valor 25 + MAG em um valor compartilhado entre aliados.
- A ficha não concede por si só imunidade a interrupção ou status. Ver D-325.
- Qualquer personagem de qualquer lado pode utilizar esse Move conforme D-235.

## Pendências — não completar por suposição

- **MP individual não definido:** D-263 determina MP para todo Move diferente de Tackle, salvo pagamento por Burst conforme D-270; esta decisão não aprova número.
- **Tipagem da reserva defensiva:** o **elemento Água do Move** não determina, por si, se o escudo absorve apenas dano Water, se é sem tipo ou se pertence a outra categoria defensiva; confirmação pendente.
- As animações de wind-up/release, membrana persistente, dano, ruptura e expiração foram **propostas pelo assistente, não expressamente aprovadas** como arte definitiva.
- A semântica precisa de "reset" de resistência e de prazo na reaplicação e as interações com camadas de escudo constam das pendências da D-324.
- É necessária integração com sistema de escudos ainda não existente no código; não há implementação, testes ou arquivos VFX nesta decisão.

## Relações

D-012, D-019, D-031, D-061, D-235, D-246, D-247, D-260, D-263, D-270, D-324, D-325, D-326.
