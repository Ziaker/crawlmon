# D-347 — Heal Gain acima da ficha, torto por lado e odômetro guardado

- **Data:** 2026-11-06
- **Área:** HUD / VFX / Combate / Processo
- **Origem:** Conversa. O criador aprovou o efeito visual do Heal Gain (D-343), mas rejeitou a posição e pediu a remoção do odômetro de HP.

## O que o criador disse (literal)

> "aprovo o efeito visual mas sua posicao nao, acho melhor ele aparecer acima da ficha (fora dela, nao dentro, perto dos pontos de vida, surgindo suavemente em movimento e sumindo suavemente tambem em um intervalo de 1.4 segundos) da vida um pouco torto pra direita (esquerda no caso do aliado)"

> "alem disso remova e guarde o sistema do odometro ele sera usado outro hora, usaremos o sistema normal de reducao e aumento de pontos de vida imediato"

## Respostas do criador (2026-11-06)

- **Escopo:** só o **número** vai para cima da ficha; as **cruzes continuam no personagem**.
- **Torto:** é **rotação do desenho**; o deslocamento é **diagonal para cima na mesma direção da rotação**. No aliado é o mesmo, com o movimento oposto.
- **Ficha do inimigo:** o **`EnemyTag`** (nome + HP flutuando sobre o inimigo).
- **Odômetro:** arquivar em `legacy` com o teste antigo, remover o toggle do menu e deixar o HP e a barra **imediatos**.

## Decisão

1. O **número** do Heal Gain deixa de aparecer sobre o personagem e passa a aparecer **acima da ficha de HP do alvo**, fora dela, perto dos pontos de vida. As cruzes verdes continuam no personagem, como VFX 3D do Motion Composer.
2. A ficha é o **`UnitCard`** do aliado/jogador e o **`EnemyTag`** do inimigo.
3. O número surge suavemente, em movimento, e some suavemente; a duração total é **1,4 s**.
4. A rotação é para a **direita no inimigo** e para a **esquerda no aliado**; o deslocamento é diagonal para cima nessa mesma direção (inimigo: sobe para a direita; aliado: sobe para a esquerda).
5. O **odômetro de HP (D-048)** sai do fluxo ativo e fica guardado em `scripts/legacy/rolling_hp_odometer.gd`, com o teste em `tests/legacy/test_d048_rolling_hp.gd`. O toggle do menu de configurações foi removido. O HP e a barra voltam ao sistema normal, com redução e aumento **imediatos**.
6. Nada de cura, dano, tempos de combate, ATB ou outras regras muda além do item 5.

## Implementação escolhida (ajustável pelo criador)

- Inclinação final do desenho: **+6°** no inimigo, **−6°** no aliado. O desenho já traz o `skewX(-4°)` do HTML; a rotação aplicada ao conjunto é **+10° / −2°** para o resultado final ficar simétrico.
- Movimento diagonal: 32 px na horizontal e 24 px na vertical ao longo dos 1,4 s, com desaceleração suave.
- Fade: entra em 0,18 s, mantém e sai entre 1,05 s e 1,4 s.
- Tamanho: 11% da altura da tela (cerca de 79 px em 720p), logo acima da ficha.

## Estado

Implementado no código; aguardando aprovação visual. Vídeo de verificação em `test_captures/HealGain_option2_normal_espelhado.mp4` (normal e espelhado) e teste do inimigo em `test_captures/HealGain_enemy_tag.mp4`.
