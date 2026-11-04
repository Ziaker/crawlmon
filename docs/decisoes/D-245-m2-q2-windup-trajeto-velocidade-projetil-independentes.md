# D-245 — Fichas de Moves M2-Q2: windup, tempo de deslocamento e velocidade de projétil separados

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M2 / questão 2.
- **Origem:** escolha **2A** expressamente enviada pelo criador, sem observações próprias.
- **Estado:** regra de design documental aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 2A — Manter windup, tempo-base de deslocamento e velocidade de projétil como parâmetros separados, aplicando apenas modificadores já aprovados.

> Observações e regras próprias: Nenhuma.

## Regra aprovada, exemplos e limites

- Na **ficha técnica**, manter parâmetros **separados** para **windup**, **tempo-base de deslocamento do personagem** e **velocidade de projétil**, **quando pertinentes** ao Move. Não fundir windup, corrida, voo ou propagação em um tempo único de ataque.
- Para o deslocamento do **combatente**, preservar **D-119/D-133/D-136/D-140/D-148**: tempo individual do Move, redução de AGI efetiva/buffs conforme decisões aplicáveis, depois ajuste de passos com mínimo já aprovado; nenhum coeficiente novo é homologado.
- Para **ondas AoE de projéteis**, preservar **D-057/D-067/D-077/D-078**: velocidade espacial constante individual por Move, comportamento geométrico por Move e posição atual dos alvos. Esta escolha **não determina que AGI afeta velocidade de projétil**, nem fixa unidades ou valores numéricos ausentes.
- **Exemplo hipotético de ficha:** `windup: [valor verificado]`, `deslocamento-base: [valor individual ou não aplicável]`, `velocidade de projétil: [valor individual ou não aplicável]`. Um Move sem deslocamento próprio não recebe duração inventada, e o lançamento do projétil não é confundido com windup.
- **Pendências:** tempos/velocidades individuais não verificados, unidade de velocidade, interações entre AGI e voo, efeitos de mudanças de alvo, prévia dinâmica e fases adicionais específicas. Preservar a independência de personagem/lado da D-235.

## Relações e escopo

- **Decisões relacionadas:** D-018/D-057/D-067/D-077/D-078/D-119/D-133/D-136/D-148/D-229/D-235.
- **Processo:** registrar conforme D-061, preservar histórico, conflitos e descrições anteriores; não interpretar autorização documental como implementação.
- **Somente documentação:** nenhum código, Move/ficha operacional, IA, HUD, teste, cena, animação, VFX, asset ou dependência alterado por este registro.
