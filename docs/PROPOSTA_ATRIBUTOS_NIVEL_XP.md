> **INVÁLIDA (2026-11-04):** esta proposta tratou "10" como limite do nível 1 e o criador disse que isso **não é regra**. Não usar os números abaixo; será refeita quando ele esclarecer a ideia (D-269).

# Proposta: atributos, nível, XP, AGI/ATB e LUK (para aprovação) — revisão 2

> **Estado:** PROPOSTA do assistente. Substitui a versão anterior (escala 1–100, valores de 25 a 60), que contrariava a vontade do criador. **Nada aqui é decisão aprovada nem foi implementado.**
> **Base:** D-269 (sem escala 1–100; nível 1 com valor-base de no máximo 10), D-270 (conversão dos valores originais, criada pelo assistente), D-120 (referência biológica com balanceamento próprio), D-126 (preservar o ritmo do ATB de hoje).
> **Números de hoje:** Abra HP 32 / ataque 12 / velocidade 0,50; Pancham 45 / 10 / 0,45; Gible 38 / 9 / 0,42.

## 1. Conversão dos valores originais (D-270)

Valores originais das espécies (valores oficiais conhecidos; **não há ficha de estatísticas no repositório**, então não foram conferidos contra uma fonte do projeto):

| | HP | Attack | Defense | Sp. Atk | Sp. Def | Speed |
|---|---:|---:|---:|---:|---:|---:|
| Abra | 25 | 20 | 15 | 105 | 55 | 90 |
| Pancham | 67 | 82 | 62 | 46 | 48 | 43 |
| Gible | 58 | 70 | 45 | 40 | 45 | 42 |

**Regra da conversão (atributo-base no nível 1):**
- STR ← Attack, MAG ← Sp. Atk, VIT ← Defense, SPI ← Sp. Def, cada um como `round(original ÷ 10,5)`, com **piso 3** e máximo 10 (o piso evita um Move inteiro virar quase zero).
- AGI ← **não usa a Speed original**: é escolhida para manter o ritmo do ATB de hoje (D-126), na seção 4.
- LUK ← sem equivalente original: 5 para todos (neutro).
- **HP** (D-269: também ≤ 10 no nível 1): `round(HP original ÷ 6,7)`, o que dá Abra 4, Pancham 10, Gible 9. Ele sai da VIT por um coeficiente da espécie (D-124): `coef = HP do nível 1 ÷ VIT` (Abra 1,33; Pancham 1,67; Gible 2,25).
- **MP** não tem valor original: sai da Magia e do nível (seção 3).

**Resultado no nível 1:**

| | STR | MAG | VIT | SPI | AGI | LUK |
|---|---:|---:|---:|---:|---:|---:|
| Abra | 3 | 10 | 3 | 5 | 10 | 5 |
| Pancham | 8 | 4 | 6 | 5 | 9 | 5 |
| Gible | 7 | 4 | 4 | 4 | 8 | 5 |

Nenhum valor passa de 10. A variação individual de ±3 (D-132/D-144/D-147) fica como está até você decidir se entra no limite de 10 (pergunta aberta da D-269).

## 2. Nível, pontos e XP

- Nível 1 a 100. Todos começam no nível 1.
- 1 ponto de atributo por nível: o protagonista distribui na hora (R13-Q4, R14-Q4); aliados e inimigos recebem 1 ponto por nível distribuído automaticamente pela proporção dos atributos-base da espécie (fracionários acumulam).
- XP para o próximo nível: `30 × nível`. XP por inimigo derrotado: `12 × nível do inimigo`, para cada ativo participante da batalha vencida (R26-Q3, R31-Q3).
- Como os atributos crescem só 1 ponto por nível no total, os valores ficam baixos nos primeiros níveis, que é o que a D-269 pede (nível 10 = 9 pontos a mais no total).

## 3. Fórmulas (nível L, `E = (L + 9) / 10`)

| Valor | Fórmula | Nível 1 |
|---|---|---|
| HP máximo | `round(coef × VIT × E)`; coef = HP do nível 1 ÷ VIT | Abra 4, Pancham 10, Gible 9 (hoje 32 / 45 / 38) |
| Dano base | `STAT × 0,3 × potência × E`, STAT = STR (físico) ou MAG (mágico) | Abra mágico 3,0 · Pancham 2,4 · Gible 2,1 por unidade de potência (mesma proporção dano/HP de hoje: cerca de 3 acertos para derrubar) |
| Resistência | `× clamp(1 + 0,05 × (5 − VIT ou SPI), 0,25, 2,0)`; físico usa VIT, mágico usa SPI | VIT 5 = neutro; cada ponto acima reduz 5% |
| Estágios de Defense | mantidos (±25% por estágio), nos dois danos (D-138) | igual a hoje |
| MP máximo | `ceil((MAG + L) ÷ 2)` | Abra 6, Pancham 3, Gible 3 |
| Custo de MP | 2 por Move mágico; +25% do máximo a cada 3 s com ATB 5/5 (para baixo); total no descanso | Abra lança 3 Moves mágicos |
| Cura | Poção: `30 × 0,3` = 9 de HP; Media: 40% do HP máximo, mínimo 4 (hoje 30 e mínimo 12) | — |

Categoria de dano por Move (D-122): **mágicos** Confusion, Psybeam, Shock Wave, Megido, Mabufula; **físicos** todos os outros com dano.

## 4. AGI e ATB

- **Conversão verificável (D-190):** `AGI = velocidade de hoje ÷ 0,05`, arredondado: Abra 10, Pancham 9, Gible 8.
- **Referência:** AGI 20 = 1,0 bloco/s (os 5 s do GDD, R7-Q2). Incremento por tick: `delta × max(AGI efetiva, 1) / 20`.
- **Previsão (sem medição):** Abra 0,50 bloco/s (4,0 s de 3 a 5; 10,0 s de 0 a 5); Pancham 0,45 (4,4 s; 11,1 s); Gible 0,40 (5,0 s; 12,5 s). Gible fica 5% mais lento que hoje (0,42) porque o AGI é inteiro.
- A D-169/D-175/D-185 ainda exigem medir (3→5 e 0→5, cinco rodadas por perfil, seis medianas) e você aprovar o valor antes de implementar.
- **Trajetos (D-162, D-178): continua bloqueado** (lista de espécies jogáveis e AGI no nível 50). Os tempos de trajeto ficam como hoje.

## 5. LUK

- Crítico, esquiva automática e status usam as contas já aprovadas (D-150 a D-153, D-146). Chances de status declaradas na ficha: Karate Chop 30%, Bite 30%, falha do Sand Attack cego 35%; o resto garantido.
- Com LUK igual (5 para todos), crítico e esquiva ficam em 10%, como hoje.

## 6. Consequências que mudam o jogo (precisam de aprovação explícita)

1. **Abra física muito mais fraca:** com STR 3, Teleport e Tackle causam cerca de 3,75 × potência (hoje 12 × potência), ou seja, 69% menos.
2. **Gible mágico mais fraco:** Mabufula com MAG 4 causa 5 × potência (hoje 9), ou seja, 44% menos.
3. **AGI foge da biologia:** a Speed original (Abra 90, Pancham 43, Gible 42) faria Abra mais de 2 vezes mais rápida que Pancham e Gible. A conversão por ritmo mantém Abra só 11% mais rápida (D-126 sobre D-120).
4. **±3 é grande demais nesta escala:** em valores de 3 a 10, a variação individual é de 30% a 100% do valor.
5. **LUK pesa pouco no começo:** 1 ponto percentual por ponto de LUK, com LUK em torno de 5, desloca crítico e esquiva só alguns pontos percentuais.
6. **HP muito baixo:** Abra com 4 HP (hoje 32) cai em 1 ou 2 acertos; a conversão do HP original torna Abra bem mais frágil em relação a Pancham.
7. **Números pequenos perdem resolução:** com HP de 4 a 10 e dano de 2 a 5, os +10% por passo (D-018) e os ±25% dos estágios de buff arredondam para o mesmo inteiro. Seria preciso guardar HP e dano fracionários por dentro, mostrando inteiros.
8. **Cura e MP:** a Poção cai de 30 para 9 e a Media passa a curar menos. A recuperação de MP de 25% a cada 3 s, arredondada para baixo, dá 0 para Pancham e Gible (25% de 3 MP = 0,75).
9. **MP é fórmula minha:** `ceil((MAG + L) ÷ 2)` e custo 2 não vêm de nenhuma decisão.

## 7. Pendente

Mediana de AGI dos trajetos (D-162), Natures, influência de tática e ações no crescimento, evolução, nível máximo por dungeon, nível dos inimigos por andar e os conflitos D-062×D-161, D-079×D-160 e IDs duplicados.
