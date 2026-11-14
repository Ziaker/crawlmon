<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-348 — Heal Gain na frente, visível desde o começo, e o atraso correto do ganho

- **Data:** 2026-11-06
- **Área:** HUD / VFX / Combate
- **Origem:** Conversa. O criador corrigiu a animação do número e esclareceu que os pilares do Media não eram o problema real.

## O que o criador disse (literal)

> "1 - o texto esta saindo de dentro e nao ta do jeito que te mandei na imagem, e pra ele tar na frente, visivel desde a concecao"

> "2 - os efeitos de pilar nao eram o real problema na verdade"

## Decisão

1. As **cruzes verdes continuam no personagem**; só o número vai para a ficha (D-347).
2. O número fica **na frente da ficha, fora dela, deslocado mas perto**, e **visível desde o primeiro quadro** da animação. Nada de nascer escondido dentro da ficha ou atrás dela.
3. O número **não tem fade-in escondido**: ele aparece visível, sobe em diagonal no sentido da inclinação e some suavemente no fim dos 1,4 s. O deslocamento horizontal é para o lado de dentro do campo (perto do HP), e a inclinação é a de D-347 (direita no inimigo, esquerda no aliado).
4. Os **pilares do Media não são o problema**: a mudança de timing deles foi revertida; o ritual volta ao comportamento aprovado em D-337.
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
