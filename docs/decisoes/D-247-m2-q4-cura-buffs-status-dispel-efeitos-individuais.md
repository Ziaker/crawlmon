# D-247 — Fichas de Moves M2-Q4: efeitos individuais de cura, buffs, debuffs, status e Dispel

- **Data:** 2026-11-04.
- **Área:** Fichas de Moves / Rodada M2 / questão 4.
- **Origem:** escolha **4A** expressamente enviada pelo criador, sem observações próprias.
- **Estado:** regra de design documental aprovada; **não implementada** nesta atividade.

## Declaração literal do criador

> 4A — Registrar cura, buffs/debuffs, status e Dispel como efeitos individuais com magnitude, condição, chance, duração e ordem quando aplicáveis.

> Observações e regras próprias: Nenhuma.

## Regra aprovada, exemplos e limites

- Na **ficha técnica**, cada efeito aplicável de **cura**, **buff/debuff**, **status** ou **Dispel** deve possuir seu **registro individual** com **magnitude**, **condições**, **chance**, **duração** e **ordem** **quando cada parâmetro for aplicável** àquele efeito. Não obrigar chance ou duração fictícia para efeitos cuja regra não depende desses campos.
- Preservar **D-210** (máximo de uma tentativa por status distinto, por alvo e execução), **D-213** (ordem explícita das tentativas na ficha) e **D-215/D-217/D-221/D-225** (prioridade expressa quando status declarados incompatíveis, com bloqueio de ficha incompleta antes de consumir ação ou recursos). Preservar D-239/D-243 sobre matriz de incompatibilidades entre Moves distintos ainda não preenchida.
- Preservar **D-134/D-137/D-143/D-199/D-202/D-207/D-211/D-227/D-234** quanto à chance, LUK, elegibilidade, sobrevivência e RNG de status. Não transformar um efeito garantido em chance aleatória nem criar novo cálculo.
- Preservar **D-123**: escala de MAG em cura, duração ou intensidade de status só existe se **expressamente definida no efeito** da ficha. Não converter efeitos em dano nem assumir fórmula de cura.
- **Exemplos, não novas regras:** para Bite, Stun contém `chance: 30%` e `duração: 2 s` já documentadas, sujeitas às condições de acerto; para Media, o efeito de cura usa os parâmetros que o código atual efetivamente contém. Não presumir que Media possua Dispel nem modificar nenhum Move.
- **Pendências:** estrutura interna/formatos, operações matemáticas exatas de magnitude, curas definitivas, efeitos reais de Dispel e eventuais conflitos entre efeitos de natureza diferente. A tooltip segue **D-229/D-230**, com os efeitos narrados no texto, não expostos como painéis técnicos.

## Relações e escopo

- **Decisões relacionadas:** D-123/D-134/D-137/D-143/D-199/D-202/D-207/D-210/D-211/D-213/D-215/D-217/D-221/D-225/D-227/D-229/D-230/D-234/D-239/D-243.
- **Processo:** registrar conforme D-061, preservar histórico, conflitos e descrições anteriores; não interpretar autorização documental como implementação.
- **Somente documentação:** nenhum código, Move/ficha operacional, IA, HUD, teste, cena, animação, VFX, asset ou dependência alterado por este registro.
