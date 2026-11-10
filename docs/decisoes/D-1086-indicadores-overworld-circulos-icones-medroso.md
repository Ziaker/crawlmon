# D-1086 — Indicadores do overworld: círculos, ícones de estado, nomes de aliados e protótipo Medroso

- **Data:** 2026-11-09.
- **Área:** Exploração / overworld / UI 3D / IA.
- **Relacionadas:** D-1063 (NPCs), D-1075 (prompt/diálogo), D-310/D-315 (níveis de ameaça), D-1023 (lab), D-1071 (Slime 0,35×).
- **Status:** **protótipo implementado e verificado** no lab isolado; batalha, 2D, HUD/status, cards e regras não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> 3 - Efeitos visuais que demonstram quem é NPC e quem é Inimigo, talvez um circulo no chão indicando cada, emojis 💢(inimigo indo até vc) 💦(inimigo fugindo de vc) ,❗(inimigo te percebendo)❔(NPC com algo pra falar, amarelo se ele tiver missão)❓(inimigo notando vc)💬(NPC que vc já conversou), encima dos nomes deles

> 5 - tá no gdd uma coisa sobre inimigo que tem medo de vc por ser mt mais fraco

> de resto vamos com suas recomendações

## Decisão

1. **Círculo no chão:** NPC = verde-claro/branco; inimigo = vermelho; aliado = azul. Anel *flat* com shader, segue o personagem, sem colisão, com fade por distância e oclusão normal por paredes.
2. **Nomes:** NPCs e Slime já têm; adicionar `PANCHAM` e `ORC` acima dos aliados. Gible continua só card do HUD.
3. **Ícones:** desenhados no estilo do jogo (não dependem de fonte de emoji), brancos com contorno escuro e tingidos por estado; balançam e dão um “pop” ao mudar de estado; são ocultados por paredes.
4. **NPC:** ❔ branco = fala nova; ❔ amarelo = `has_quest`; 💬 = já conversou. `has_quest` é uma flag de demonstração (Bulbasaur) e `talked` é por sessão.
5. **Inimigo:** 💢 = `CHASE`; 💦 = `FLEE`; ❗ = alerta de 0,6 s ao perceber; ❓ = `SEARCH`; sem ícone em `PATROL`/`RETURN`.
6. **Medroso (D-310/D-315):** protótipo no lab. O Slime é marcado com `threat_level = 0` (Medroso) e foge devagar quando o grupo chega a **3 tiles** (9 m na escala do lab, 1 tile = 3 m). A fórmula final de D-315, os ícones/tamanhos de ameaça e as velocidades em px/s continuam **pendentes**; o protótipo usa 1,0 m/s e não é regra final.
7. **Toque:** D-315 diz que o Medroso tocado inicia batalha normal; o lab não tem transição de batalha, então isso não é implementado aqui.
8. **Não muda:** batalha, 2D, HUD/status, cards, regras. O ícone de nível de ameaça de D-310 fica para quando os desenhos forem escolhidos.

## Ambiguidades

- Fórmula final do nível de ameaça, ícones e tamanhos (D-310/D-315 em aberto).
- Velocidade de fuga no 3D (o lab usa m/s; D-315 usa px/s no 2D).
- O amarelo de missão some após conversar ou permanece até completar a missão? Neste protótipo, vira 💬 após conversar.

## Teste implementado (2026-11-09)

- **Círculos:** anel *flat* com shader; NPC verde-menta, inimigo vermelho, aliado azul; segue o personagem, sem colisão, com fade por distância e oclusão. O anel de aliado fica oculto quando o aliado está diretamente atrás do jogador (para não parecer o anel do jogador) e reaparece quando a câmera/formação abre.
- **Nomes:** `PANCHAM` e `ORC` adicionados acima dos aliados; NPCs e Slime já tinham. Os nomes e ícones encolhem com a distância para não cobrir a tela de perto.
- **NPC:** Bulbasaur com `has_quest=true` mostra ❔ amarelo; outros NPCs mostram ❔ branco; após conversar, 💬. O estado `talked` é por sessão.
- **Inimigo:** 💢 em `CHASE`, 💦 em `FLEE`, ❗ por 0,6 s ao perceber, ❓ em `SEARCH`; sem ícone em `PATROL`/`RETURN`.
- **Medroso:** Slime com `threat_level=0`; ao chegar a 9 m (3 tiles de 3 m) ele entra em `FLEE` e foge devagar. A auditoria viu `state=4 (FLEE)`, `threat=0`, `alert=0,57` com ícone `alert` e, 45 quadros depois, `alert=0` com ícone `sweat`. `rings=6`, `icons=4`.
- **Provas:** `murky_forest_prompt_z_talk.png`, `murky_forest_indicators_medroso.png`, `murky_forest_chase_burst.png` e `overworld_icons_states.png`.
- **Nota D-1090:** o antigo ícone de fúria virou um **estouro**; todos os ícones ficaram 25% maiores (`pixel_size 0,004375`); enquanto o NPC fala, o ícone de estado é substituído por reticências animadas.

## O que não foi verificado

- A fórmula final de D-315, os ícones/tamanhos de ameaça de D-310 e a velocidade em px/s do 2D; o protótipo usa 9 m e 1,0 m/s.
- Combate por toque, transição de batalha, 60 fps, mobile e outras resoluções.
- O amarelo de missão vira 💬 após a primeira conversa; não há sistema de missão/quest.
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.

## Estado

Protótipo implementado e verificado no lab isolado. Círculos, ícones, nomes de aliados e Medroso funcionando. Commit local; **sem push**.
