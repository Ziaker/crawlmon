# D-401 — Modal obrigatório de alocação de pontos do líder ao subir de nível

- **Data:** 2026-11-07
- **Área:** UI / Progressão / Personagens
- **Origem:** Recomendações técnicas formuladas no Concepts Brief e aprovadas pelo criador na conversa (conforme D-135 e D-394).
- **Estado:** regra registrada; sem código.

## Declaração literal do criador

> "eu não tenho ideia de como mexer com estes valores, sigo suas recomendações"

## Regra aprovada

1. **Momento da Alocação:**
   Em estrito cumprimento a D-135 (*"o protagonista é obrigado a distribuí-lo na hora"*), se o líder da equipe (`party[0]`) subir de nível após a tela de vitória, abre-se imediatamente um **Modal de Alocação de Atributos** antes de retornar à exploração 2D.
2. **Interface do Modal:**
   - Exibe os 6 atributos canônicos (**STR, MAG, VIT, WIS, AGI, LUK**), seus valores atuais e o saldo de pontos a distribuir.
   - Fornece controles de incremento `+` (e decremento temporário `-` de pontos recém-alocados).
   - O saldo de pontos a alocar é de **1 ponto** para níveis normais e de **3 pontos** nos marcos a cada 10 níveis (níveis 10, 20, 30...), conforme D-394.
3. **Bloqueio de Saída sem Alocação:**
   - É proibido sair da tela ou retornar para a exploração enquanto restarem pontos livres do líder pendentes de alocação.
   - O botão de confirmação e avanço só é ativado quando todos os pontos concedidos tiverem sido distribuídos.

## Ambiguidades em aberto (perguntar antes de agir)

- Se múltiplos níveis forem ganhos de uma só vez (ex.: 2 subidas de nível em um combate único com XP abundante), o modal acumula todos os pontos gerados em um único saldo para alocação sequencial contínua.

## Estado no código

Nenhuma alteração.
