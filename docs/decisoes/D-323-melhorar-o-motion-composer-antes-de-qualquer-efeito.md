# D-323 — Melhorar a capacidade do Motion Composer ANTES de fazer qualquer efeito

- **Data:** 2026-11-05
- **Área:** VFX / Motion Composer / Processo
- **Origem:** pedido direto do criador, depois de eu ter começado a **trocar** peças antigas do fogo por shaders novos (pedido interrompido por ele).
- **Estado:** registrada; **nenhum código escrito depois dela**; escopo das melhorias em aberto (ver abaixo).

> **Nota D-1030 (2026-11-09):** o Motion Composer é **auxiliar e opcional**. A ordem "melhorar o Composer antes de qualquer efeito" **deixou de ser gate**; o efeito pode ser feito à mão. O histórico abaixo fica preservado.

## Frase literal do criador

> ao invés de trocar, eu quero que vc melhore a capacidade do composer pra conseguir fazer elementos direito, estilizados, semi-realistas se possível, melhore o composer antes de fazer qualquer coisa

Antes, sobre o fogo: "eu mandei vc refazer do zero o efeito da bola de fogo, estamos no terceiro prompt e vc JÁ NÃO ME OBEDECE MAIS???"

## Decisão

1. **Primeiro** melhorar o Motion Composer (capacidade de produzir fogo, água, terra e ar de forma **estilizada**). **Só depois** retomar os efeitos (D-322).
2. **Não** trocar peças do fogo atual por peças novas agora: nenhum efeito é mexido até o Composer estar melhor.
3. Continuam valendo D-322 (refazer os 4 do zero, um por vez, com aprovação), D-308, D-235, D-019 e o protocolo VFX.

## Respostas do criador (2026-11-05, em seguida)

- **Melhorias, todas as quatro:** (1) geometria + materiais, (2) campos de movimento, (3) partículas e resíduos, (4) ferramentas de avaliação.
- **Estilo:** primeiro respondeu "Bandas duras, mais volume" (cel-shaded, com mais profundidade, detalhe de silhueta, translucidez e gradientes por idade). Depois: "na verdade risca semi-realista, deixa estilizado". **Vale: estilizado** (cel-shading em bandas duras, o estilo do jogo, D-038); semi-realista está descartado.

## Ambiguidades em aberto

- Ordem dentro das quatro áreas (presumo: geometria + materiais, campos, partículas e resíduos, avaliação; dependências técnicas, não preferência do criador).
- Nenhum efeito (fogo, água, terra, ar) é mexido até o Composer estar melhor (D-323 item 2).

## Estado no código (2026-11-05)

**Motion Composer V1.2 implementado** (ver `docs/vfx/MOTION_COMPOSER_V1.md`, seção 26): campos M21–M25, geradores de forma (fita, lâmina, arco, casca, fragmentos), material estilizado `mc_surface` (bandas duras com volume), representações de partículas e resíduos (spark, puff, drops, halo, mark, surface), acabamentos por elemento (`MotionLooks`) e laboratório de avaliação (`tests/vfx/mc_lab.gd`). 8 suítes sem falhas; laboratório nos quatro elementos, fundo escuro e claro, vistas normal e espelhada, A/B repetível, nada sobra aos 4 s.
Nenhum efeito existente foi alterado (o fogo da D-322 segue como estava). **Próximo passo é do criador:** aprovar a capacidade e então retomar o fogo (D-322); desempenho (D-274 item 7) não foi pedido.
