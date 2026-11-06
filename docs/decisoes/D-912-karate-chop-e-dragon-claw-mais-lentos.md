# D-912 — Karate Chop e Dragon Claw correm mais devagar

> **Renumerada em 2026-11-06:** D-169 → D-912. O ID D-169 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-03
- **Área:** Combate / Animação
- **Origem:** Conversa

## O que o criador disse (literal)

> Não, deixe mais lentos

Resposta à pergunta "Karate Chop e Dragon Claw devem seguir correndo nessa velocidade?", feita depois de o sync check apontar 120–186 u/s nesses golpes.

## Decisão

O tempo-base de corrida de Karate Chop e Dragon Claw passa de 0,22 s para 0,45 s. Os ajustes de posição de D-018 continuam valendo.

## Escolhas do agente, para o criador conferir

O criador não deu um número. 0,45 s é o menor valor redondo que fica abaixo do limite de 110 u/s do detector na distância normal da arena (cerca de 103 u/s no pico, em 29,4 m), mantendo os dois golpes mais rápidos que a corrida comum (0,6 a 1,1 s). A chegada ao alvo atrasa 0,23 s.

## Ambiguidades em aberto

Os outros golpes de corrida curta (Mach Punch e Hassou Tobi 0,18 s, Brick Break e Titanomachia 0,24 s, Investida Escavadora 0,26 s) não foram pedidos e não mudaram. Com passos à frente, o tempo cai 0,10 s por passo (D-018), e o pico pode voltar a passar de 110 u/s.

## Estado no código

Implementado (`attack_planner.gd`).
