# D-1015 — Drain Spear: lança deita na chegada, disparo sincronizado, antecipação e espera mantidas, coroa se separa

- **Data:** 2026-11-09.

## Frase literal do criador

> 1 - a lança está deitando mt cedo, é pra ela deitar só quando o personagem chegar no local-alvo
> 2 - os efeitos de disparo não estão sincronizados com a animação e os intervalos para o ataque ser realizado, disparando ANTES mesmo do personagem atacar, ainda no prelude
> 3 - ", sem antecipação nem a espera de 0,75 s," está incorreto, deve haver ambos para teste primeiro
> 4 - o efeito visual no disparo, a coroa giratória, ela não se dissipa se separando cada uma, mais parece um guarda chuva, mude o efeito e reduza sua opacidade em 25%

## Decisão

1. A lança fica **vertical durante o deslocamento** e só deita em direção ao alvo quando o atacante chega ao local (0,2 s).
2. Durante o prelúdio a lança fica empunhada e apontada; o **disparo (estocada + coroa)** começa só nos últimos 0,25 s do golpe e termina exatamente no contato.
3. **Volta** a antecipação e a espera de 0,75 s depois do contato (corrige D-1014 item 1). O passo curto de 0,35 s continua.
4. **Coroa giratória:** sem os cones sólidos (o "guarda-chuva"); ao se dissipar, cada faixa se afasta para fora separadamente; opacidade −25% (0,55 → 0,41).

## Estado

Implementado para revisão.
