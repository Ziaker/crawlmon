# D-951 — Heal Gain na frente, visível desde o começo, e o atraso correto do ganho

> **Renumerada em 2026-11-06:** D-348 → D-951. O ID D-348 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-06
- **Área:** HUD / VFX / Combate
- **Origem:** Conversa. O criador corrigiu a animação do número e esclareceu que os pilares do Media não eram o problema real.

## O que o criador disse (literal)

> "1 - o texto esta saindo de dentro e nao ta do jeito que te mandei na imagem, e pra ele tar na frente, visivel desde a concecao"

> "2 - os efeitos de pilar nao eram o real problema na verdade"

## Decisão

1. As **cruzes verdes continuam no personagem**; só o número vai para a ficha (D-949).
2. O número fica **na frente da ficha, fora dela, deslocado mas perto**, e **visível desde o primeiro quadro** da animação. Nada de nascer escondido dentro da ficha ou atrás dela.
3. O número **não tem fade-in escondido**: ele aparece visível, sobe em diagonal no sentido da inclinação e some suavemente no fim dos 1,4 s. O deslocamento horizontal é para o lado de dentro do campo (perto do HP), e a inclinação é a de D-949 (direita no inimigo, esquerda no aliado).
4. Os **pilares do Media não são o problema**: a mudança de timing deles foi revertida; o ritual volta ao comportamento aprovado em D-939.
5. O problema real é a ordem: o HP/barra têm de aparecer primeiro, e o **Heal Gain (número + cruzes)** espera **0,10 s** depois do sinal `healed` para começar. Assim o efeito nunca aparece antes do ganho real.
6. Nada de cura, dano, tempos de combate, ATB ou regras muda além do atraso visual do item 5.

## Implementação escolhida (ajustável)

- O número nasce **acima da ficha**, a 4 px dela, deslocado 26 px para o lado de dentro (direita no card da esquerda, esquerda no card da direita), com alfa 1 desde o primeiro quadro.
- Movimento: 12 px no sentido da inclinação e 16 px para cima ao longo de 1,4 s; fade-out entre 1,05 s e 1,4 s.
- A camada do número fica **acima** dos cards/tags e abaixo do menu/status.
- O atraso de 0,10 s vale para o número (HUD) e para as cruzes/anel do `HealGainFx` (3D), mantendo-os juntos.
- Os pilares do Media voltaram a `start = 0,35 + 0,08 por aliado` na fase de wind-up; a cerimônia voltou a viver 2,45 s.

## Estado

Implementado no código; aguardando aprovação visual. Vídeos a regerar após esta correção.
