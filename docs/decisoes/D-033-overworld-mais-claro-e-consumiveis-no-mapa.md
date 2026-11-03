# D-033 — Overworld mais claro, já visitado 100% iluminado e consumíveis no mapa

- **Data:** 2026-11-02
- **Área:** Exploração
- **Origem:** Conversa

## O que o criador disse (literal)

> o overworld 2D do jogo tá mt escuro, faca com que a escuridao não distraia tanto assim, alem de locais que você ja passou estarem completamente iluminados, além disso adicione consumíveis no mapa

## Respostas do criador (perguntas)

- Escuridão: **"Claro, mas atmosférico"** — ambiente bem mais claro, névoa só no que nunca foi visitado; o já visitado fica 100% iluminado.
- Consumíveis: **"Só Poção"** (o único consumível que existe hoje, cura 30 HP).
- Coleta: **"Automático ao pisar"**.
- Quantidade por andar: **"2 a 4"**.
- Onde aparecem: **"Salas aleatórias, longe do spawn"**.
- Persistência: **"Não volta"** depois de coletado, mesmo saindo para batalha e retornando ao mapa.

## Decisão

1. **Luz do overworld:** o `CanvasModulate` do mapa fica bem mais claro, mas ainda atmosférico. A névoa continua cobrindo **apenas** tiles nunca visitados (preto). Tiles já explorados ficam com **alpha 0** (completamente iluminados), inclusive fora da linha de visão atual.
2. **Consumíveis no mapa:** cada andar gerado recebe **2 a 4 Poções** em tiles de chão livres de salas aleatórias, a uma distância mínima do ponto de spawn. A posição é determinística pela seed do andar.
3. **Coleta:** encostar no item recolhe automaticamente e soma `potion` ao inventário (`GameState.add_item`).
4. **Persistência:** o item coletado é registrado no `GameState` (como inimigos derrotados e a névoa) e **não reaparece** ao voltar de uma batalha. Um novo andar (`new_dungeon`) limpa a lista de coletados.
5. O item é desenhado com o ícone `assets/items/potion.png` e fica sob a névoa, como inimigos e NPCs.

## Ambiguidades em aberto

Nenhuma. Os valores exatos de luminosidade são a implementação da resposta "claro, mas atmosférico".

## Estado no código

Implementado nesta sessão.
