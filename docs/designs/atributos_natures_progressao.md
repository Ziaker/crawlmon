# Sistema de Natures, Atributos-Base e Progressão por Nível

*   **Author:** Criador & Assistente
*   **Status:** In Review (Stage 9 Resolved — Ready for Implementation)
*   **Date:** 2026-11-07

--------------------------------------------------------------------------------

## Overview

Este documento estabelece a especificação técnica formal para a camada de atributos, cálculo de HP/MP, sistema de 8 Natures táticas e progressão por nível no Crawlmon. O objetivo é substituir os valores fixos do protótipo por um modelo determinístico de conversão proporcional a partir dos status originais das espécies (Pokémon e Dragon Quest Tact), aplicando uma curva de HP escalonada para mitigar mortes em um golpe (*one-hit kills*) desde o nível 1.

## Problem Statement

O protótipo atual de combate opera com valores de atributos definidos pontualmente no código (ex.: HP 32 para Abra, 38 para Gible, 45 para Pancham) sem uma fórmula unificada de conversão a partir dos status oficiais das espécies. Propostas anteriores de escalas de 1–100 ou limites rígidos de nível 1 (como o teto de 10) foram explicitamente rejeitadas pelo criador ([D-269](../../docs/decisoes/D-269-sem-escala-1-100-e-niveis-baixos-sem-valores-altos.md)). Além disso:
1. Não havia uma fórmula de HP que mantivesse o combate cadenciado e resistente a dano explosivo em níveis altos;
2. As Natures haviam sido adiadas ([D-271](../../docs/decisoes/D-271-sem-porcentagens-valores-flat-e-adiar-natures.md)) por falta de planejamento formal de seus modificadores inteiros (*flat*) de soma zero e de seu impacto na inteligência artificial de combate;
3. Ausência de especificação para a progressão dos aliados sem alocação manual direta, preservando sua autonomia tática ([D-001](../../docs/decisoes/D-001-foco-no-combate-e-regras-do-jogo.md) / [REGRAS_DO_JOGO §3.1](../../docs/REGRAS_DO_JOGO.md#31-filosofia)). Como a propriedade `is_player: bool` em `Combatant` define estritamente a facção do time (`true` = aliados, `false` = inimigos), a posição `party[0]` é adotada como identificador do líder para separar a alocação manual da progressão automática dos aliados por proficiência.

A solução aprovada em [D-390](../../docs/decisoes/D-390-orcamento-15-pontos-base-nivel-1.md) a [D-394](../../docs/decisoes/D-394-progressao-pontos-nivel-jogador-e-aliados.md) resolve esses pontos com:
* Orçamento total de 15 pontos distribuídos proporcionalmente aos status originais no nível 1 via algoritmo determinístico de maiores restos.
* Curva de HP com +10 por nível, saltos de marco de +25 a cada 10 níveis e +2 por ponto de VIT.
* Renomeação do atributo defensivo mágico de SPI (*Spirit*) para WIS (*Wisdom*) com dado de MP na ficha de atributos (+2 MP por WIS).
* 8 Natures iniciais com modificadores *flat* (−3 a +3 somando 0) e impacto direto no comportamento de combate da IA, com precedência da Tactic sobre a Nature.
* Progressão diferenciada: alocação manual para o líder (`party[0]`) e crescimento por proficiência de ações em combate para os aliados.

## Goals

*   **G1 (Fidelidade Biológica com 15 Pontos):** Converter os status oficiais das espécies em 15 pontos inteiros de atributos no nível 1 ([D-390](../../docs/decisoes/D-390-orcamento-15-pontos-base-nivel-1.md), [D-270](../../docs/decisoes/D-270-status-base-e-progressao-por-nivel.md), [D-120](../../docs/decisoes/D-120-regras-de-atributos.md)) utilizando o método determinístico dos maiores restos (Hare-Niemeyer).
*   **G2 (Combate Anti-Hitkill e Marcos de HP):** Implementar a fórmula de HP garantindo 39–43 HP como referência típica no nível 1 (VIT 2–4) e saltos de marco de +25 HP a cada 10 níveis ([D-392](../../docs/decisoes/D-392-escala-hp-anti-hitkill-e-marcos.md)), evitando mortes em 1 golpe.
*   **G3 (Wisdom e MP na Ficha):** Renomear SPI para WIS e estruturar o cálculo de MP máximo vinculado a WIS e nível ([D-391](../../docs/decisoes/D-391-renomeacao-spi-para-wis-e-scaling-mp.md)) como dado numérico estático de ficha.
*   **G4 (Catálogo Canônico de 8 Natures de Soma Zero):** Implementar as 8 Natures iniciais (Hardy, Docile, Brave, Timid, Modest, Calm, Jolly, Adamant) atuando nos atributos e nos pesos de IA ([D-393](../../docs/decisoes/D-393-escopo-8-natures-iniciais-e-tatica-ia.md), [D-271](../../docs/decisoes/D-271-sem-porcentagens-valores-flat-e-adiar-natures.md)).
*   **G5 (Consolidação de Piso Inato):** Garantir que o piso 1 seja consolidado na base inata do nível 1, assegurando que todo ponto de progressão futuro produza monotonicamente +1 de status real.
*   **G6 (Progressão Diferenciada por Papel):** Habilitar ganho de 1 ponto/nível (3 nos marcos) para o líder da equipe (`party[0]`) e progressão automática baseada em proficiência acumulada de ações em combate para os aliados ([D-394](../../docs/decisoes/D-394-progressao-pontos-nivel-jogador-e-aliados.md)), onde a postura do menu Tactics possui precedência sobre a Nature.
*   **G7 (Atualização de Recursos):** Assegurar que alterações no HP máximo atualizem o valor corrente por $\Delta = \text{NovoMáx} - \text{AntigoMáx}$, preservando o estado de K.O. ($\text{HP} = 0 \implies \text{permanece } 0$).

## Non-Goals

*   **NG1:** Não alterar a linha do tempo única de combate, o cálculo de acerto ou as regras de física e trajeto existentes ([D-019](../../docs/decisoes/D-019-combate-em-tempo-real-com-atb.md)).
*   **NG2:** Natures não afetam sob nenhuma hipótese as taxas de crescimento por nível ([D-271](../../docs/decisoes/D-271-sem-porcentagens-valores-flat-e-adiar-natures.md)).
*   **NG3:** Não impor teto máximo artificial de 100 permanente para atributos ([D-139](../../docs/decisoes/D-139-sem-teto-maximo-artificial.md)).
*   **NG4:** Não alterar a velocidade base de enchimento do ATB dos personagens iniciais, adotando fórmula afim universal sem fatores multiplicativos por espécie.
*   **NG5:** Não alterar a UI de combate (`battle_hud.gd`) com barras de MP neste momento (o combate opera estritamente por blocos de ATB).
*   **NG6:** Não definir fórmulas de mitigação percentual de dano por defesa sem aprovação prévia do criador ([D-125](../../docs/decisoes/D-125-calculo-de-dano.md), [D-138](../../docs/decisoes/D-138-mitigacao-de-dano.md)).

## Open Questions

*   **Fórmula de Mitigação de Dano por Defesa (VIT e WIS):** A fórmula matemática exata e a ordem de resolução entre defesas, fraquezas elementais e acertos críticos permanecem em aberto conforme [D-125](../../docs/decisoes/D-125-calculo-de-dano.md) e [D-138](../../docs/decisoes/D-138-mitigacao-de-dano.md). Com a implementação da curva de HP proposta (39–43 HP de referência no nível 1), o combate mitiga mortes em um golpe independentemente da fórmula de atenuação por defesa; a fórmula exata de atenuação de dano por defesas será apresentada para decisão do criador em rodada de balanceamento dedicada.

## Critical User Journeys (CUJs)

### CUJ 1: Instanciação de Monstro no Nível 1
*   **Given**: O jogo gera um monstro (ex.: Pancham) no nível 1 para uma batalha ou recrutamento.
*   **When**: O sistema inicializa a ficha de atributos através do conversor biológico de 15 pontos.
*   **Then**: 
    1. Os 15 pontos base são distribuídos proporcionalmente aos status originais de Pancham via método dos maiores restos (soma base = exatamente 15).
    2. A variação triangular independente de −3 a +3 ([D-144](../../docs/decisoes/D-144-variacao-individual-triangular.md)) gerada por 16 bilhetes inteiros (pesos 1:2:3:4:3:2:1) e o modificador da Nature ([D-393](../../docs/decisoes/D-393-escopo-8-natures-iniciais-e-tatica-ia.md)) são somados algebricamente.
    3. O piso mínimo de 1 é aplicado para consolidar o **Atributo Inato** ($\text{innate\_stat} = \max(1, \dots)$).
    4. O HP máximo é calculado: valores com VIT típica (2–4) resultam em 39–43 HP; casos de borda com alta variação e Nature (ex.: VIT 1 = 37 HP; VIT 8 = 51 HP) são avaliados e suportados.

### CUJ 2: Subida de Nível e Marco do Protagonista Líder
*   **Given**: O personagem controlado pelo jogador (`party[0]`) alcança a experiência necessária para subir do nível 9 para o nível 10 (nível de marco).
*   **When**: O evento de subida de nível é processado pela UI.
*   **Then**: 
    1. O sistema identifica através da guarda segura (`is_player and not GameState.party.is_empty() and self == GameState.party[0]`) que se trata do líder e concede 3 pontos de atributo para distribuição manual.
    2. Cada ponto alocado soma diretamente ao atributo efetivo: $\text{effective\_stat} = \text{innate\_stat} + \text{pontos\_alocados}$, sem risco de absorção por penalidades prévias de Nature.
    3. O HP máximo aumenta em $\Delta = 10 + 25 = +35$ HP (ou $+35 + 2\Delta\text{VIT}$ se o jogador investir pontos em VIT no mesmo momento).
    4. A barra de vida atual no HUD é incrementada na mesma proporção ($\Delta$) imediatamente ([D-347](../../docs/decisoes/D-347-feedback-visual-ao-subir-de-nivel.md)).

### CUJ 3: Acúmulo de Ações e Evolução de Aliados em Combate
*   **Given**: Um aliado (ex.: Pancham na posição `party[1]` com Nature Brave) participa de um combate com postura tática *Fight* ([D-001](../../docs/decisoes/D-001-foco-no-combate-e-regras-do-jogo.md) / [REGRAS_DO_JOGO §3.1](../../docs/REGRAS_DO_JOGO.md#31-filosofia)).
*   **When**: O combate ocorre e encerra com vitória.
*   **Then**: 
    1. A entidade `Combatant` registra contadores inteiros de categorias de ação observadas durante a luta (`PHYSICAL`, `MAGIC`, `GUARD`, `EVADE`).
    2. Ao subir de nível no metagame, a categoria mais praticada determina o atributo incrementado (modulado pelo viés da Nature, subordinado à postura tática).
    3. O HP e MP máximos são recalculados e os valores atuais incrementados por $\Delta$. Se o aliado estiver derrotado (HP = 0), seu HP atual permanece 0.

--------------------------------------------------------------------------------

## Proposed Architecture

### 1. Diagrama de Fluxo de Dados e Ciclo de Vida dos Atributos

```mermaid
flowchart TD
    subgraph Ingestao ["1. Definição da Espécie"]
        OrigStats["Status Originais da Espécie\n(Pokémon / DQT)"] --> Converter["Conversor Determinístico 15 Pts\n(Método Hare-Niemeyer)"]
        Converter --> BaseStats["Atributos Base (Soma = 15)\nSTR, MAG, VIT, WIS, AGI, LUK"]
    end

    subgraph Individualidade ["2. Composição Individual Inata"]
        BaseStats --> SumNode["Soma Algébrica Inata"]
        TriangularOffset["Variação Individual Triangular\n(-3..+3 por atributo, D-144)"] --> SumNode
        NatureMod["Modificador da Nature\n(-3..+3, Soma = 0, D-393)"] --> SumNode
        SumNode --> Clamping["Piso Mínimo Inato:\nmaxi(1, Atributo)"]
        Clamping --> InnateStats["Atributos Inatos Consolidados\n(innate_stats)"]
    end

    subgraph Progressao ["3. Camada de Progressão Linear"]
        InnateStats --> EffNode["Soma Linear de Atributos"]
        ProgressionPoints["Pontos de Progressão\n(progression_points)"] --> EffNode
        EffNode --> EffectiveStats["Atributos Efetivos\n(get_effective_stat)"]
    end

    subgraph Recursos ["4. Derivação de Combate e Recursos"]
        EffectiveStats --> CalcHP["HP Máximo:\n25 + 10*L + 25*floor(L/10) + 2*VIT"]
        EffectiveStats --> CalcMP["MP Máximo na Ficha:\n10 + 2*WIS + L"]
        EffectiveStats --> CalcATB["Taxa ATB Afim:\n0.35 + (max(AGI, 1) * 0.0375) blocos/s"]
        EffectiveStats --> CalcProb["Crítico & Evasão LUK\n(D-150 / D-152)"]
    end

    subgraph Combate ["5. Batalha & Metagame"]
        Actions["Contadores de Ações no Combatant\n(PHYSICAL, MAGIC, GUARD, EVADE)"] --> PostBattle["Sinais de Fim de Batalha\n(GameState / Metagame)"]
        Tactics["Menu Tactics (Precedência)"] --> Bias["Pesos de Decisão da IA"]
        NatureAI["Nature (Viés Tático)"] --> Bias
        Bias --> Actions
        PostBattle --> LevelUpCheck{"Subiu de Nível?"}
        LevelUpCheck -->|Líder: party[0]| ManualAlloc["Alocação Manual UI\n(1 pt regular / 3 pts marco)"]
        LevelUpCheck -->|Aliado: party[1..N]| AutoProfAlloc["Alocação Automática\npor Categoria Dominante"]
        ManualAlloc --> ProgressionPoints
        AutoProfAlloc --> ProgressionPoints
    end
```

### 2. Algoritmo Determinístico de Conversão para 15 Pontos (Hare-Niemeyer)

Para converter qualquer conjunto de status oficiais mantendo a proporcionalidade biológica ([D-120](../../docs/decisoes/D-120-regras-de-atributos.md), [D-270](../../docs/decisoes/D-270-status-base-e-progressao-por-nivel.md)) de forma determinística:

1. **Mapeamento de Fontes:**
   * **Pokémon:** `STR ← Attack`, `MAG ← Sp. Atk`, `VIT ← Defense`, `WIS ← Sp. Def`, `AGI ← Speed`. Para `LUK`, adota-se a média aritmética arredondada dos outros 5 atributos originais da espécie:
     $$\text{RefLUK} = \text{round}\left(\frac{\text{Attack} + \text{SpAtk} + \text{Defense} + \text{SpDef} + \text{Speed}}{5}\right)$$
   * **Dragon Quest Tact:** `STR ← Attack`, `MAG ← Wisdom/Magic`, `VIT ← Defense`, `WIS ← round(Max MP / 10)`, `AGI ← Agility`. `LUK` recebe a média aritmética arredondada dos 5 status.
2. **Distribuição Proporcional com Cota Inteira:**
   $$\text{Quota}_i = 15 \times \frac{\text{StatOriginal}_i}{\sum_{j=1}^{6} \text{StatOriginal}_j}$$
   * Atribui-se o piso inteiro: $\text{Base}_i = \lfloor \text{Quota}_i \rfloor$.
   * Calcula-se o resto fracionário: $R_i = \text{Quota}_i - \text{Base}_i$.
3. **Distribuição dos Pontos Restantes:**
   * Seja $K = 15 - \sum_{i=1}^6 \text{Base}_i$.
   * Os $K$ pontos remanescentes são distribuídos, 1 a 1, para os atributos com os maiores restos $R_i$. Em caso de empate exato, a prioridade segue a ordem biológica canônica: `STR, MAG, VIT, WIS, AGI, LUK`.
   * **Invariante:** $\sum_{i=1}^6 \text{Base}_i = 15$ exatamente.

#### Tabela de Conversão Aplicada (Espécies Iniciais de Referência)

| Espécie | Status Originais (Atk, SpA, Def, SpD, Spe, RefLUK) | STR | MAG | VIT | WIS | AGI | LUK | Soma |
|---|---|---|---|---|---|---|---|---|
| **Abra** | 20, 105, 15, 55, 90, 57 (Total: 342) | 1 | 5 | 1 | 2 | 4 | 2 | **15** |
| **Pancham** | 82, 46, 62, 48, 43, 56 (Total: 337) | 4 | 2 | 3 | 2 | 2 | 2 | **15** |
| **Gible** | 70, 40, 45, 45, 42, 48 (Total: 290) | 4 | 2 | 2 | 2 | 2 | 3 | **15** |
| **Orc (DQT)** | 95, 30, 85, 35, 60, 61 (Total: 366) | 4 | 1 | 4 | 1 | 3 | 2 | **15** |
| **Cyclops (DQT)** | 110, 20, 75, 25, 40, 54 (Total: 324) | 5 | 1 | 4 | 1 | 2 | 2 | **15** |

### 3. Fórmulas Matemáticas Fechadas

#### A. HP e MP Máximos ([D-391](../../docs/decisoes/D-391-renomeacao-spi-para-wis-e-scaling-mp.md), [D-392](../../docs/decisoes/D-392-escala-hp-anti-hitkill-e-marcos.md))
*   **HP Máximo:**
    $$\text{max\_hp} = 25 + 10 \times \text{level} + 25 \times \lfloor\frac{\text{level}}{10}\rfloor + 2 \times \text{vit}$$
    *(Nota de calibração: a constante inicial 25 representa a incorporação direta da bonificação de marco do nível 1, pois $\lfloor 1/10 \rfloor = 0$).*
    *Calibração Nível 1:*
    * Abra (VIT 1): $25 + 10 + 0 + 2(1) = 37$ HP.
    * Gible / Pancham (VIT 2–3): $25 + 10 + 0 + 2(2..3) = 39..41$ HP.
    * Cyclops (VIT 4): $25 + 10 + 0 + 2(4) = 43$ HP.
*   **MP Máximo (Ficha de Atributos):**
    $$\text{max\_mp} = 10 + 2 \times \text{wis} + \text{level}$$
    *Calibração Nível 1:*
    * Abra (WIS 2): $10 + 4 + 1 = 15$ MP.
    * Conjuradores focados com Nature/Offset (WIS 4): $10 + 8 + 1 = 19$ MP.
    *(Permanece estritamente na ficha de dados; nenhuma barra de MP é inserida no HUD de batalha).*

#### B. Proteção Anti-Hitkill no Nível 1
A mitigação de mortes em 1 golpe decorre da relação entre o patamar de HP calibrado de nível 1 (39–43 HP típico) e os valores de dano inicial:
* Ataques fortes comuns desferidos no início do jogo possuem dano base entre 8 e 12 pontos.
* Mesmo no pior cenário de fraqueza elemental (1,5×) combinado com acerto crítico (2,0×), um dano de 10 passa para $10 \times 1.5 \times 2.0 = 30$ pontos, insuficiente para derrubar os 39–43 HP do monstro.
* São necessários no mínimo 2 acertos extremos ou 3 a 4 ataques comuns para nocautear um combatente.

#### C. Ritmo de ATB Universal por Função Afim ([D-126](../../docs/decisoes/D-126-tempo-e-ritmo-do-atb.md), [D-145](../../docs/decisoes/D-145-novo-calculo-de-atb.md))
Para preservar com precisão os 0,50 blocos/s de Abra e os 0,42–0,45 blocos/s de Pancham/Gible sem recorrer a multiplicadores por espécie, adota-se a função afim com piso linear:
$$\Delta\text{ATB} = \text{delta} \times \left(0.35 + \max(\text{agi}, 1.0) \times 0.0375\right)$$
* **Pancham e Gible (AGI 2):** $0.35 + 2 \times 0.0375 = \mathbf{0.425}$ blocos/s.
* **Abra (AGI 4):** $0.35 + 4 \times 0.0375 = \mathbf{0.500}$ blocos/s.
* **Monstros Ultra-Ágeis (AGI 6):** $0.35 + 6 \times 0.0375 = \mathbf{0.575}$ blocos/s.

#### D. Catálogo Canônico das 8 Natures ([D-393](../../docs/decisoes/D-393-escopo-8-natures-iniciais-e-tatica-ia.md))

Todas as 8 Natures iniciais possuem modificadores inteiros *flat* com soma estrita igual a zero, além de moduladores paramétricos de IA:

| Nature | Perfil Conceitual | STR | MAG | VIT | WIS | AGI | LUK | Soma | ATB Reserve Bias | Aggression Mult |
|---|---|---|---|---|---|---|---|---|---|---|
| **Hardy** | Neutra Equilibrada | 0 | 0 | 0 | 0 | 0 | 0 | **0** | `0.0` | `1.0` |
| **Docile** | Neutra Pacífica / Cautelosa | 0 | 0 | 0 | 0 | 0 | 0 | **0** | `+0.5` | `0.8` |
| **Brave** | Foco Físico / Ofensiva Pesada | +2 | 0 | +1 | −1 | −2 | 0 | **0** | `−1.0` | `1.3` |
| **Timid** | Evasiva / Ágil de Longa Distância | −2 | 0 | −1 | 0 | +2 | +1 | **0** | `+1.0` | `0.7` |
| **Modest** | Foco Mágico / Conjuradora | −2 | +3 | 0 | 0 | −1 | 0 | **0** | `0.0` | `1.0` |
| **Calm** | Suporte Resistente Mágico | −2 | 0 | +1 | +2 | 0 | −1 | **0** | `+0.5` | `0.8` |
| **Jolly** | Ágil / Foco em Iniciativa | 0 | −3 | 0 | 0 | +2 | +1 | **0** | `0.0` | `1.1` |
| **Adamant** | Ataque Físico Máximo | +3 | −3 | 0 | 0 | 0 | 0 | **0** | `−0.5` | `1.4` |

*Regra de Precedência:* As diretrizes do menu **Tactics** (`act_policy` e `react_policy`) sobrepõem-se hierarquicamente ao viés da Nature ([D-001](../../docs/decisoes/D-001-foco-no-combate-e-regras-do-jogo.md)).

### 4. Sistema de Ações e Proficiência de Aliados ([D-394](../../docs/decisoes/D-394-progressao-pontos-nivel-jogador-e-aliados.md))

Para manter a simplicidade arquitetural e evitar complexidade prematura (YAGNI):
1. **Contadores na Entidade:** `Combatant` mantém contadores inteiros discretos para registrar ações executadas durante a luta:
   * `PHYSICAL`: ataques físicos normais e técnicas de impacto desferidas.
   * `MAGIC`: habilidades mágicas e curas conjuradas.
   * `GUARD`: golpes bloqueados ou absorvidos em postura defensiva.
   * `EVADE`: esquivas e manobras de reposicionamento tático.
2. **Desacoplamento de Metagame:** O motor de combate não processa subidas de nível nem rateios complexos em tempo de execução. Ao final da batalha, os contadores são preservados no estado da equipe; quando o ciclo formal de experiência (XP) for implementado no metagame, a categoria dominante orientará a distribuição automática de pontos de progressão.

--------------------------------------------------------------------------------

## Risks & Mitigations

### 1. Desvio por Clamping Inato no Nível 1
*   **Risco:** Em espécies focadas (ex.: Abra com STR Base 1), rolagens triangulares negativas (−3) combinadas com Natures redutoras (−2) resultam em somas brutas inferiores a 1 ($1 - 3 - 2 = -4$). O piso $\max(1, x)$ eleva o valor a 1, perdoando 5 pontos negativos enquanto preserva bônus em outros atributos, gerando combatentes com soma inata superior a 15 pontos nominais.
*   **Mitigação:** O piso 1 atua como garantia intencional de viabilidade biológica para que nenhum monstro instanciado seja injogável com status nulo ou negativo. A soma inata consolidada no nível 1 possui piso garantido de 15 pontos nominais. O impacto no balanceamento é nulo, pois os pontos perdoados ocorrem em atributos secundários não utilizados pelo combatente (ex.: STR em Abra).

### 2. Inanição de Ações em Batalhas Curtas
*   **Risco:** Lutas vencidas em 1 turno pelo líder podem terminar com zero ações executadas pelos aliados, deixando os contadores de ações zerados.
*   **Mitigação:** O sistema preserva os contadores cumulativos até que um evento formal de subida de nível ocorra. Caso o aliado suba de nível sem registros de ação, a escolha recai deterministicamente sobre a afinidade principal da espécie (maior atributo base) ou da Nature.

### 3. Falha de Execução em Arrays Vazios de Equipe
*   **Risco:** Avaliar liderança via `GameState.party[0]` em testes unitários ou instâncias isoladas sem equipe ativa dispara exceção de índice fora dos limites.
*   **Mitigação:** Toda checagem de liderança implementa guarda de validade estrita:
    `is_player and is_instance_valid(GameState) and not GameState.party.is_empty() and self == GameState.party[0]`.

### 4. Escalabilidade de ATB e HP em Níveis Altos
*   **Risco:** Conforme os combatentes acumulam pontos em AGI e VIT, o ATB poderia acelerar excessivamente e o HP inflacionar a barra.
*   **Mitigação:** O multiplicador afim de AGI ($0.0375$ blocos/s por ponto) garante que mesmo em AGI 10 o ritmo atinja apenas $0.725$ blocos/s, mantendo o combate legível. A curva de HP escala de forma linear controlada (+10/nível), evitando descompassos na barra de vida.

--------------------------------------------------------------------------------

## Alternatives Considered

### Alternative A: Escala Rígida 1–100 ou Teto de 10 no Nível 1
*   **Pros**: Representação convencional em JRPGs com números inteiros intuitivos.
*   **Cons**: Introduz compressão artificial de atributos nos níveis iniciais e achata a identidade biológica das espécies.
*   **Reason for Rejection**: Rejeitada formalmente pelo criador em [D-269](../../docs/decisoes/D-269-sem-escala-1-100-e-niveis-baixos-sem-valores-altos.md): *"essa regra de 1-100 e idiota e ja mandei remover ela de tudo"*. Substituída pelo orçamento fixo de 15 pontos distribuídos proporcionalmente aos status originais.

### Alternative B: Natures com Modificadores Percentuais (+X% / −X%)
*   **Pros**: Escala de forma proporcional em níveis altos.
*   **Cons**: Em atributos baixos (1 a 5), modificadores de 10% geram frações que arredondam para zero, anulando o efeito da Nature.
*   **Reason for Rejection**: Rejeitada formalmente pelo criador em [D-271](../../docs/decisoes/D-271-sem-porcentagens-valores-flat-e-adiar-natures.md): *"nao quero porcentagens quero valores flat"*. Modificadores inteiros *flat* (−3 a +3) garantem impacto perceptível desde o nível 1.

### Alternative C: Alocação Manual de Pontos para Todos os Aliados na UI
*   **Pros**: Concede controle absoluto ao jogador sobre a evolução de cada companheiro.
*   **Cons**: Fere a autonomia e inteligência dos companheiros ([D-001](../../docs/decisoes/D-001-foco-no-combate-e-regras-do-jogo.md) / [REGRAS_DO_JOGO §3.1](../../docs/REGRAS_DO_JOGO.md#31-filosofia)) e sobrepõe a identidade de IA das Natures.
*   **Reason for Rejection**: Rejeitada formalmente pelo criador em [D-394](../../docs/decisoes/D-394-progressao-pontos-nivel-jogador-e-aliados.md): *"pontos manuais para o caso do jogador, pontos equivalentes a ações e natures dos aliados baseado em seus desempenhos no combate"*.

### Alternative D: Crescimento de HP Linear Estrito (Sem Marcos)
*   **Pros**: Curva perfeitamente homogênea em todos os níveis.
*   **Cons**: Não oferece o sentimento de conquista e salto de poder a cada 10 níveis.
*   **Reason for Rejection**: Rejeitada formalmente pelo criador em [D-392](../../docs/decisoes/D-392-escala-hp-anti-hitkill-e-marcos.md): *"+25 para cada décimo nivel (1, 10, 20) + 20 para cada 10 pontos de VIT... a ideia é que não aja tanto dano explosivo a ponto de causar hitkill"*.

--------------------------------------------------------------------------------

## Detailed Implementation Plan

### Target Files to Create/Modify

#### 1. `scripts/combat/crawlmon_attribute_math.gd` (Modify)
*   **Type / Scope**: GDScript RefCounted (Módulo Estático de Matemática de Atributos).
*   **Proposed Changes**:
    1. Atualizar a constante `ATTRIBUTES` de `["STR", "MAG", "VIT", "SPI", "AGI", "LUK"]` para `["STR", "MAG", "VIT", "WIS", "AGI", "LUK"]` ([D-391](../../docs/decisoes/D-391-renomeacao-spi-para-wis-e-scaling-mp.md)).
    2. Implementar `convert_species_stats_to_15_points(species_stats: Dictionary) -> Dictionary` com método Hare-Niemeyer garantindo soma inteira = 15 exata ([D-390](../../docs/decisoes/D-390-orcamento-15-pontos-base-nivel-1.md)):
       * `RefLUK` arredondado via `round()`.
       * Desempate de restos na ordem canônica: `STR, MAG, VIT, WIS, AGI, LUK`.
    3. Implementar `calculate_max_hp(level: int, vit: int) -> int`:
       $$25 + 10 \times \text{level} + 25 \times \lfloor\text{level} / 10\rfloor + 2 \times \text{vit}$$ ([D-392](../../docs/decisoes/D-392-escala-hp-anti-hitkill-e-marcos.md)).
    4. Implementar `calculate_max_mp(level: int, wis: int) -> int`:
       $$10 + 2 \times \text{wis} + \text{level}$$ ([D-391](../../docs/decisoes/D-391-renomeacao-spi-para-wis-e-scaling-mp.md)).
    5. Substituir a assinatura anterior de `natural_atb_increment` pela fórmula afim direta de 2 parâmetros ([D-126](../../docs/decisoes/D-126-tempo-e-ritmo-do-atb.md), [D-145](../../docs/decisoes/D-145-novo-calculo-de-atb.md)):
       ```gdscript
       static func natural_atb_increment(delta: float, effective_agi: float) -> float:
           assert(delta >= 0.0, "Delta must be nonnegative")
           return delta * (0.35 + maxf(effective_agi, 1.0) * 0.0375)
       ```
    6. Implementar `consolidate_innate_attributes(base_15: Dictionary, offsets: Dictionary, nature_mod: Dictionary) -> Dictionary` (substituindo `apply_individual_offsets`):
       Consolida $\max(1, \text{base} + \text{offset} + \text{nature})$ no nível 1 uma única vez.

#### 2. `scripts/data/nature_data.gd` (Create)
*   **Type / Scope**: Catálogo de Recursos / Dados de Natures (GDScript RefCounted).
*   **Proposed Implementation**:
    ```gdscript
    class_name NatureData
    extends RefCounted

    const NATURES: Dictionary = {
        "hardy": {
            "name": "Hardy",
            "mods": {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0},
            "atb_reserve_bias": 0.0,
            "aggression_mult": 1.0,
        },
        "docile": {
            "name": "Docile",
            "mods": {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0},
            "atb_reserve_bias": 0.5,
            "aggression_mult": 0.8,
        },
        "brave": {
            "name": "Brave",
            "mods": {"STR": 2, "MAG": 0, "VIT": 1, "WIS": -1, "AGI": -2, "LUK": 0},
            "atb_reserve_bias": -1.0,
            "aggression_mult": 1.3,
        },
        "timid": {
            "name": "Timid",
            "mods": {"STR": -2, "MAG": 0, "VIT": -1, "WIS": 0, "AGI": 2, "LUK": 1},
            "atb_reserve_bias": 1.0,
            "aggression_mult": 0.7,
        },
        "modest": {
            "name": "Modest",
            "mods": {"STR": -2, "MAG": 3, "VIT": 0, "WIS": 0, "AGI": -1, "LUK": 0},
            "atb_reserve_bias": 0.0,
            "aggression_mult": 1.0,
        },
        "calm": {
            "name": "Calm",
            "mods": {"STR": -2, "MAG": 0, "VIT": 1, "WIS": 2, "AGI": 0, "LUK": -1},
            "atb_reserve_bias": 0.5,
            "aggression_mult": 0.8,
        },
        "jolly": {
            "name": "Jolly",
            "mods": {"STR": 0, "MAG": -3, "VIT": 0, "WIS": 0, "AGI": 2, "LUK": 1},
            "atb_reserve_bias": 0.0,
            "aggression_mult": 1.1,
        },
        "adamant": {
            "name": "Adamant",
            "mods": {"STR": 3, "MAG": -3, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0},
            "atb_reserve_bias": -0.5,
            "aggression_mult": 1.4,
        },
    }

    static func get_nature(id: String) -> Dictionary:
        return NATURES.get(id, NATURES["hardy"])
    ```

#### 3. `scripts/combat/combatant.gd` (Modify)
*   **Type / Scope**: Modelo de Entidade de Batalha (GDScript RefCounted).
*   **Proposed Changes**:
    1. Preservar `var is_player: bool = false` (indica time aliado vs inimigo).
    2. Renomear o campo `spi: int` para `wis: int` ([D-391](../../docs/decisoes/D-391-renomeacao-spi-para-wis-e-scaling-mp.md)).
    3. Adicionar novas propriedades de dados:
       ```gdscript
       var nature_id: String = "hardy"
       var innate_stats: Dictionary = {"STR": 1, "MAG": 1, "VIT": 1, "WIS": 1, "AGI": 1, "LUK": 1}
       var progression_points: Dictionary = {"STR": 0, "MAG": 0, "VIT": 0, "WIS": 0, "AGI": 0, "LUK": 0}
       var action_counts: Dictionary = {"PHYSICAL": 0, "MAGIC": 0, "GUARD": 0, "EVADE": 0}
       ```
    4. Implementar método `get_effective_stat(stat: String) -> int`:
       Retorna `innate_stats.get(stat, 1) + progression_points.get(stat, 0)`.
    5. Implementar verificação segura de liderança:
       ```gdscript
       func is_party_leader() -> bool:
           return is_player and is_instance_valid(GameState) and not GameState.party.is_empty() and self == GameState.party[0]
       ```
    6. Atualizar `Combatant.base_speed` no cálculo de `tick()` para derivar da fórmula afim com base em `get_effective_stat("AGI")`.
    7. Implementar `update_resource_maximums()` com deltas explícitos e preservação de K.O.:
       ```gdscript
       func update_resource_maximums() -> void:
           var old_max_hp := max_hp
           var old_max_mp := max_mp
           max_hp = CrawlmonAttributeMath.calculate_max_hp(level, vit)
           max_mp = CrawlmonAttributeMath.calculate_max_mp(level, wis)
           if hp > 0:
               hp = clampi(hp + (max_hp - old_max_hp), 1, max_hp)
           if mp > 0:
               mp = clampi(mp + (max_mp - old_max_mp), 0, max_mp)
       ```

#### 4. `scripts/autoload/game_state.gd` (Modify)
*   **Type / Scope**: Autoload Singleton (Estado Global da Sessão).
*   **Proposed Changes**:
    1. Atualizar a inicialização dos monstros da equipe inicial real (`Abra` e `Pancham`) em `_build_party()` utilizando `CrawlmonAttributeMath.convert_species_stats_to_15_points`.
    2. Sortear variação triangular individual de −3 a +3 ([D-144](../../docs/decisoes/D-144-variacao-individual-triangular.md)) para cada atributo.
    3. Atribuir Nature inicial (`"modest"` para Abra e `"brave"` para Pancham).
    4. Consolidar os inatos com `CrawlmonAttributeMath.consolidate_innate_attributes` e chamar `update_resource_maximums()`.

#### 5. `scripts/combat/battle_ai.gd` (Modify)
*   **Type / Scope**: Controlador de IA de Aliados e Inimigos.
*   **Proposed Changes**:
    1. Em `_reserve(c: Combatant) -> float`: modular a reserva base de ATB em `React.EVADE` com o viés da Nature:
       ```gdscript
       if c.react_policy == Combatant.React.EVADE:
           var nature_bias := float(NatureData.get_nature(c.nature_id).get("atb_reserve_bias", 0.0))
           return clampf(base_res + nature_bias, 0.0, Combatant.BLOCKS)
       ```
    2. Em `_may_spend(c: Combatant, ...)`: subordinar a `act_policy` e aplicar `aggression_mult` da Nature sobre a margem de gasto sob postura `Act.SKILL`.

#### 6. `scripts/combat/battle_scene.gd` (Modify)
*   **Type / Scope**: Controlador da Cena 3D de Batalha.
*   **Proposed Changes**:
    1. Atualizar a função geradora do inimigo de teste `_new_gible() -> Combatant` ([D-319](../../docs/decisoes/D-319-gible-fixo-no-combate.md)) para utilizar o conversor de 15 pontos com os status oficiais de Gible (70, 40, 45, 45, 42, 48), aplicar variação triangular, definir `nature_id = "adamant"` e chamar `update_resource_maximums()`.

#### 7. `tests/combat/test_attribute_math_and_natures.gd` (Create)
*   **Type / Scope**: Suíte de Testes Unitários Automatizados Headless (Godot 4.7).
*   **Proposed Structure**:
    *   Classe estende `SceneTree`.
    *   Executa rotinas de asserção no `_init()` e finaliza com `quit(0)` em caso de sucesso ou `quit(1)` em falha.
    *   Valida:
        1. Conservação exata de 15 pontos em 100 espécies com valores aleatórios via Hare-Niemeyer.
        2. Soma zero nominal em todas as 8 Natures iterativamente (`sum(mods) == 0`).
        3. Linearidade da progressão (nenhuma absorção por clamping prévio).
        4. Saltos de marco de +35 HP nos níveis 10, 20, 30 e calibração de MP (+2 por WIS).
        5. Pacing de ATB exato via função afim (0,500 blocos/s para Abra e 0,425 para Pancham).
        6. Preservação estrita de K.O. (`hp == 0` permanece `0` em `update_resource_maximums()`).

### Verification Plan

*   **Testes Headless Automatizados:**
    Executar suíte dedicada de matemática via Godot headless:
    ```powershell
    godot --headless --path . -s tests/combat/test_attribute_math_and_natures.gd
    ```
    *Critério de Sucesso:* 0 falhas, 0 warnings de assert, 100% de passagem nos testes de conservação de soma, fórmulas de marcos, linearidade de progressão e pacing de ATB (0,500 blocos/s para Abra e 0,425 blocos/s para Pancham).
