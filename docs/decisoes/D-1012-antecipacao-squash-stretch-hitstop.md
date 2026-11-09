# D-1012 — Ataques físicos: antecipação, squash & stretch e hitstop por peso

- **Data:** 2026-11-08.

## Frase literal do criador

> depois quero ver como vai me propor uma mudança na animação de todos personagens, usando um principio de animação de antecipação e de squash e stretch apenas durante seus ataques físicos e uma aplicação melhor de hitstop. O feeling até o momento não está mt bom
> prossiga com sua opção de animação, quero ver o resultado

## Decisão (só visual; contato e dano não mudam, D-019)

1. **Antecipação:** nos primeiros 20% do golpe o atacante abaixa e alarga (0,85 alto / 1,1 largo), com ease-in.
2. **Stretch:** do fim da antecipação ao contato estica no sentido do golpe (1,15) e afina (0,9).
3. **Contato:** squash de 2 quadros (1,15 / 0,85) e volta com leve oscilação.
4. **Hitstop por peso:** leve 0,06 s, normal 0,09 s, pesado/crítico 0,14 s, K.O. 0,20 s.
5. **Saída do hitstop:** o alvo é empurrado para trás no sentido do golpe e volta suave (antes voltava de uma vez).
6. **Câmera:** empurrão curto de ~3–5% a cada acerto (D-1008).

## Ambiguidade

- Proposta original era congelar só atacante e alvo; mantido o congelamento de todos, porque o relógio de regras pára inteiro no hitstop (congelar só dois faria os outros andarem fora do tempo).

## Estado

Implementado para revisão.
