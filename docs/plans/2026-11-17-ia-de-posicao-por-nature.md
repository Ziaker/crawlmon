# Conceito: posição estratégica da IA guiada pela Nature (proposta, nada implementado)

Pedido do criador (2026-11-17): "um planejamento mt melhor na questão destas estratégias, um conceito que leva em conta principalmente a própria nature mas também o contexto do combate atual".

Base atual (já no código, `battle_positioning.gd`): cada posição de −2 a +2 recebe uma nota = valor do meu golpe ali − custo dos golpes que levo ali − preço por passo. Hoje todo mundo pesa os termos do mesmo jeito. O conceito abaixo faz a **Nature mudar o jeito de pesar** e o **contexto mudar os números que entram**.

## 1. Ideia central

- **Nature = personalidade:** o que a IA quer, quanto arrisca, quanto se mexe, o que lê do inimigo.
- **Contexto = estado:** ATB, vida, o que está em voo, quem está atordoado, o rumo da luta.
- A nota de cada posição continua sendo uma conta (para ser testável nos dados), mas a conta é *temperada* pela Nature. Sem "if Nature == X" espalhado: a Nature vira 5 eixos numéricos lidos dos campos que **já existem** (`mods` e os dois campos de IA).

## 2. Eixos derivados da Nature (sem inventar campo novo)

| Eixo | Lê de | Efeito na nota |
|---|---|---|
| Audácia | `aggression_mult` (0,7–1,4) | multiplica o ganho de ataque; divide o medo de apanhar |
| Cautela | `atb_reserve_bias` (−1 a +1) | peso do risco de morrer e do desvio por passo; quem reserva ATB para Evade combina passo + Evade |
| Mobilidade | mod de AGI (+LUK) | preço do passo: ágil (Jolly, Hasty) paga pouco e troca o tempo todo; pesado (Brave, Relaxed) paga muito e fica plantado |
| Estilo | STR contra MAG | físico quer contato (frente); mágico/à distância tem preferência leve por trás, vence só com nocaute ou ameaça baixa |
| Leitura | mod de WIS | WIS alto antecipa: considera o que o inimigo *vai* poder lançar no horizonte e a rodada seguinte; WIS baixo (Naive, Rash) só reage ao que já foi declarado e erra o tempo |

## 3. As 8 Natures iniciais lidas por esses eixos

| Nature | Como se comporta na posição |
|---|---|
| Hardy | solucionador neutro: faz a conta pura, sem inclinação |
| Docile | suporte: mantém distância, só avança para nocaute; passo a favor de aliado ferido (curar de longe) |
| Brave | planta na frente cedo (gasta ATB logo, pesado para andar), aceita apanhar; só recua com risco real de morrer |
| Timid | recua cedo, bate-e-corre curto; guarda ATB para Evade e usa o passo para a janela perfeita |
| Modest | conjurador: ancora atrás, avança só no instante do golpe se vale nocaute |
| Calm | reativo: espera a ameaça aparecer, recua no que está em voo, volta ao centro; foco em Guard |
| Jolly | flanqueador: custo de passo mínimo, aproveita janela do inimigo (ATB vazio, em wind-up) para avançar e some antes do contra |
| Adamant | implacável: avança e fica; empurra para nocaute; ignora ameaça que não mata |

As outras 10 Natures usam a mesma regra pelos eixos, sem tabela própria.

## 4. Contexto (o que entra na conta)

1. **Janela do inimigo:** quem acabou de atacar (ATB vazio, retornando) e quem está em wind-up é alvo fácil: ameaça baixa agora, então avançar custa pouco. Sinal lido do estado real, não chutado.
2. **Quem eu sou na fila de alvos:** alvo aleatório entre vivos (1/N). Se o inimigo provoca (Taunt) em mim, ameaça sobe para 100 %; se um aliado provoca, a ameaça sobre mim cai e posso avançar.
3. **Rumo da luta:** vantagem de vida do time (somando HP). À frente: jogar seguro (recua se quase morto). Atrás: reação por Nature (Brave/Adamant dobram a aposta e avançam; Timid/Calm fecham a defesa).
4. **Foco em equipe:** se um aliado está a um golpe de nocaute no mesmo inimigo, avançar para somar o +10 % por passo que decide o abate; se o inimigo é quase morto, não gasta passo defensivo.
5. **Estados:** Guard/ARMOR ativos reduzem ameaça (avança); STUN/BLIND no inimigo zera a ameaça dele; Burst disponível libera o golpe imediato (posição para o golpe agora).
6. **Leitura do adversário:** a Nature do inimigo estima o ritmo dele (Timid reserva ATB, ataca menos; Brave/Rash gastam tudo): o ritmo esperado de ataques do inimigo usa o `aggression_mult` dele em vez de supor o mesmo para todos.

## 5. O que fica em aberto (preciso do criador, uma pergunta por vez)

1. **Preferência de posição por Nature como puxão leve** (ex.: Modest quer ficar entre 0 e −1 mesmo sem ameaça)? Recomendação: sim, do tamanho de um passo de preço, para não cravar a posição.
2. **A escolha de alvo também considera a posição do inimigo e a Nature?** Hoje é aleatório (regra antiga da IA). Recomendação: sim, com peso por Nature, mas isso muda uma regra anterior, então só com o seu "sim".
3. **Reação à desvantagem por Nature** (item 4.3): dobrar a aposta ou fechar a defesa. Recomendação: a divisão acima (ofensivas dobram, evasivas/defensivas fecham).
4. **Mostrar ao jogador por que a IA se moveu** (linha de log curta, ex.: "recua: golpe em voo")? Recomendação: só no debug/telemetria, não na HUD.
5. **Mecânica nova de formação** (quem fica à frente protege atrás)? Hoje ficar à frente não aumenta o dano que se leva, então não existe "tanque" por posição. Recomendação: não criar mecânica nova agora; a escolha é do criador.

## 6. Plano de execução (depois do seu sim)

1. Calcular os 5 eixos a partir de `NatureData` (função única, testável).
2. Aplicar os eixos em `BattlePositioning`: pesos dos termos, preço do passo, horizonte, puxão de preferência.
3. Adicionar os sinais de contexto 4.1 a 4.6 um por vez, cada um com um teste de cenário nos dois lados (sala de debug, <10 s) e a tabela de notas impressa.
4. Telemetria: evento `pos_decision` (posição escolhida, tabela de notas, eixos usados) em `docs/TELEMETRIA.md` e na `BattleTrace`.
5. Verificação por números (quanto tempo cada Nature passa em cada posição, em IA contra IA, 120 s), nunca por impressão. O visual do passo (andar, pose) continua com o criador julgar.
