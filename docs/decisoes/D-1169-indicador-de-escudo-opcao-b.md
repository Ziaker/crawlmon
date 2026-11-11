# D-1169 — Indicador de escudo: opção B (anel) com número estilizado e diagonal

- **Data:** 2026-11-11
- **Área:** HUD / Combate / Visual
- **Origem:** Conversa (protótipo 3D do indicador de valor de escudo, depois de A/B/C).

## O que o criador disse (literal)

> "opção B só que com o texto mais estilizado como o texto de dano, com mais animação e um angulo das letras e icone mais diagonal do que reto, além de um pouco menor"

## Decisão

1. A direção visual escolhida para o indicador de valor de escudo é a **opção B**: anel 3D **ao lado do modelo do oponente, abaixo do retrato da etiqueta**, com o arco preenchido pela fração reserva/máximo e o número dentro. No protótipo, o jogador usa o mesmo critério acima do **cartão do líder** e os aliados não-líderes acima do cartão deles (a confirmar).
2. O número e o ícone de escudo ficam **na diagonal** (letras inclinadas e ícone inclinado), não alinhados na horizontal. O ícone fica **fora do anel**, encostado no canto superior esquerdo e um pouco mais para cima, com inclinação maior que a do número.
3. O número usa o tratamento do **texto de dano**: branco, contorno escuro grosso, entrada com pop/overshoot e leitura forte.
4. O indicador tem **mais animação**: pulso no valor, flash, giro/assentamento do texto, onda expansiva no anel e brilho que percorre o arco.
5. O conjunto fica **25% menor** que a versão de ≈78 px (≈58,5 px); o aliado não-líder ancora pela **esquerda** do cartão. Isto substitui os ajustes de tamanho anteriores.
6. Vale para o jogador e para o oponente, em qualquer personagem e lado (D-235). O valor é a **reserva atual** (`shield_hp`) com o máximo ao lado; a duração não aparece.
7. Com **3 oponentes**, cada anel fica **abaixo do retrato da sua etiqueta, ao lado do modelo**; testado no espelho DQT (1 jogador + Orc/Slime/Cyclops) e as três leituras continuam separadas.
8. O protótipo é um laboratório: **nada foi ligado ao HUD do jogo** e nenhuma regra de combate mudou.

## Revisão 2 (2026-11-11) — combate real

> "quero ver essa hud funcionando em combate, grave um video de 30 segundos que tenha combate, use o debug alem disso mova o escudo um pouco mais pra cima e o deixe 15% maior"

- Anel de 68 → ≈78 px (+15%); âncora da etiqueta/cartão de −54 → −66 px (mais para cima).
- Validação em **combate real de debug**: 2 aliados × 3 oponentes, IA atacando, escudo aplicado em todos; o overlay lê `shield_hp`/`shield_max` a cada quadro.
- Vídeo: `test_captures/shield_hud_combat_30s.mp4` (30 s) e folha `test_captures/shield_hud_combat_sheet.png`.
- **Achado:** o banner grande do nome do Move (ex.: SUKUNDA) passa por cima do topo dos anéis por ~1 s; decidir se move o banner ou os anéis.
- O badge antigo do HUD continua aparecendo abaixo de cada anel (duplicado).

## Revisão 3 (2026-11-11) — tamanho e lado do aliado

> "reduza a hud do escudo de tamanho em 25%, nao alinhe a do aliado na direita, deixa na esquerda"

- Anel de ≈78 px → ≈58,5 px (−25%); número 30 → 23 e ícone 0,161 → 0,121.
- O jogador (cartão do líder) e os inimigos (etiquetas) continuam ancorados na **direita** do elemento; os **aliados não-líder** usam a **esquerda** do cartão.
- Vídeo de combate regravado em `test_captures/shield_hud_combat_30s.mp4`; nesta rodada o encontro sorteou 2 aliados × 2 oponentes.
- Com o anel menor, o banner grande do Move deixa de cobrir os anéis; etiquetas de ataque ainda podem cruzar a borda do anel.

## Revisão 4 (2026-11-11) — todos mais baixos; inimigos ao lado do modelo

> "deixe todos escudos um pouco mais pra baixo e no caso dos inimigos, deixe o escudo ao lado do modelo deles, abaixo dos retratos"

- **Todos** os anéis desceram: os de partido/cartão 10 px; os de inimigo saíram de cima da etiqueta para **abaixo do retrato**, ao lado do modelo, na altura do ombro/cabeça.
- O anel do aliado não-líder continua na **esquerda** do cartão; o do líder na direita; os de inimigo abaixo do retrato.
- Vídeo de combate de 30 s regravado (`test_captures/shield_hud_combat_30s.mp4`), 2 aliados × 2 oponentes nesta rodada; o estático de 3 oponentes também foi regravado.
- Na captura, os Moves **MYSTIC** foram retirados do cenário por causa do erro de cor conhecido no VFX do jogo (não é o HUD do escudo).

## Revisão 5 (2026-11-11) — solução “arco no retrato” implementada no protótipo

> "se for pra fazer uma revisao e um prototipo de revisao com solucao ao menos faca ele direito"

- **Implementado de verdade, não mockup**: `tests/vfx/shield_portrait_overlay.gd` desenha o arco no retrato real do cartão/etiqueta; o anel 3D não é criado nesse modo.
- **Badge antigo removido**: `BattleHud.hide_shield_badges` (padrão `false`, só o laboratório liga) suprime `S %d | %.1fs` e `SHIELD %d | %.1fs`; o arco é a única leitura de escudo.
- **Hierarquia**: jogador e alvo atual recebem arco cheio, número maior, ícone e halo de pulso; aliados e demais inimigos recebem arco fino + número pequeno. A animação só aparece quando o valor muda.
- **Evidência**:
  - Antes (4 anéis 3D + 4 badges): `test_captures/shield_hud_combat_30s.mp4`.
  - Depois (4 arcos, 0 badges): `test_captures/shield_hud_combat_30s_portrait.mp4` (30 s, combate real, 2 aliados × 3 oponentes).
  - Revisão antes/depois com os mesmos 4 combatentes DQT: `test_captures/shield_hud_review.png`.
- **Testes**: UI `test_qol_batch` e `test_status_screen_content` verdes; suíte de combate **27/27**.
- **Limites**: o alvo é `hud._target` ou o primeiro inimigo vivo (sem troca de alvo testada); quebra/renovação de escudo não testadas; o timer saiu do combate (se precisar, linha fina); o arco do aliado compacto usa número de 11 px.

## Ambiguidades em aberto (perguntar antes de implementar no jogo)

- O anel também deve inclinar ou só as letras e o ícone?
- O jogador fica acima do **cartão do líder** (como no protótipo) ou volta ao lado da cabeça?
- O que dispara a animação no jogo: perda de escudo, hit absorvido, início do escudo ou toda mudança de valor?
- O badge atual do HUD (`S 34 | 8.0s` na etiqueta e `SHIELD 34 | 8.0s` no cartão) some, vira o novo indicador ou continua?
- Tamanho final em px/percentual da tela e se o indicador aparece para todos os aliados/inimigos ao mesmo tempo.
- Fonte final: a mesma do texto de dano ou a Kanit Black Italic usada no protótipo para dar a diagonal?

## Estado

Protótipo em `tests/vfx/shield_value_lab.gd` (flags `--b-only`, `--dqt-mirror`, `--combat`, `--portrait`, `--no-shield`), `tests/vfx/shield_portrait_overlay.gd` (solução do arco no retrato) e `shaders/proto/shield_ring.gdshader` (anel 3D do modo antigo). Vídeo antes: `test_captures/shield_hud_combat_30s.mp4`; vídeo depois: `test_captures/shield_hud_combat_30s_portrait.mp4`; revisão antes/depois: `test_captures/shield_hud_review.png`. Testes: UI 2/2 e combate 27/27. Implementação no HUD do jogo **pendente de aprovação**.
