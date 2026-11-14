# Relatório de feitos — dodge, interrupção, Dread e câmera

- **Data:** 2026-11-12.
- **Autor:** agente de IA (sessão OpenCode).
- **Branch/worktree:** `wip/checkpoint-2026-11-06` em `crawlmon`.
- **Escopo:** correções de combate/feedback (Evade/WHIFF, interrupção, Dread), um ajuste de câmera do lab 3D e a auditoria em cenários de debug.
- **Publicação:** nada foi commitado nem enviado; não houve `push` (D-022).

## 1. Pausa de status e wind-up (D-1150/D-1159)

- A pausa de status passou a começar no quadro da declaração e não deixa um ataque resolver depois dela no mesmo quadro (D-1150).
- Um Move **não-status** escolhido durante a pausa inicia o wind-up imediatamente, paga ATB/MP e fica **congelado** até a pausa terminar (D-1159). Move de status continua indo para a vaga D-161 para não aninhar pausas.
- A animação do novo wind-up também é congelada/descongelada junto.
- Teste: `tests/battle/test_d1159_windup_during_status_pause.gd` — **10/10 PASS**.
- Documentos: `docs/decisoes/D-1150-...`, `D-1159-...`; suíte de debug inclui o cenário `windup_pausa_com_ataque`.

## 2. Interrupção visual só para interrupção real (D-1160)

- O HUD deixou de quebrar o cartão por `interrupted`, `dodged` ou `auto_dodged` inferidos. Criado `Incoming.interruption_feedback`, marcado apenas em interrupção real:
  - War Cry/status que cancela wind-up;
  - golpe que cancela wind-up;
  - golpe que para o trajeto antes do impacto;
  - choque que para a corrida.
- Evade manual, desvio automático, golpe durante o retorno, fim de batalha, morte/limpeza e restauração de estado **não** quebram o cartão; usam `leave()`.
- O efeito D-1104 (9 estilhaços + `INTERRUPTED`, 0,55 s) continua igual.
- Teste: `tests/ui/test_d1160_interruption_feedback.gd` — **18/18 PASS**; `test_d1104_attack_tag_shatter.gd` passa.
- Documento: `docs/decisoes/D-1160-interrupcao-visual-so-real.md` (o ID antigo D-1104 foi preservado).

## 3. Dodge errado: WHIFF + queda + poeira (D-1166/D-1167)

- Apertar Evade fora da janela mostra `WHIFF`, levanta poeira e derruba o corpo.
- O clipe `down` continua sendo usado quando ele realmente derruba o corpo (modelos DQT).
- Nos Pokémon, o `down` não derruba (o próprio `down01_start` exportado é sutil). O fallback usa o **`damage` do próprio Pokémon**, nunca clipes de Cogumelo/Wookada/Vigoroth.
- A queda assistida inclina o corpo quando o clipe não cai e o devolve ao idle.
- Investigação em `E:\arenamon`:
  - `chars\mosh\Cogumelo.glb` e `chars\wookada\wookada.glb` têm `Falling Back Death`, `Falling Down`, `fall_hitground`, `stay dead` etc.;
  - esses clipes pertencem a rigs diferentes e não foram aplicados aos Pokémon;
  - o dump Pokémon tem `down01_start/loop/end`; o export já usa `down01_start` como `down`.
- Teste: `tests/battle/test_d1166_mistimed_visual.gd` — **9/9 PASS**.
- Documentos: `D-1166-dodge-errado-queda-whiff-poeira.md`, `D-1167-fallback-damage-quando-down-nao-cai.md`.

## 4. Dread escolhe o ataque certo (D-1168)

- `find_evadable` prioriza o ataque que está na **janela do Dread** (`can_evade_now`), em vez de um wind-up anterior na lista.
- O Dread só acende em ataque inimigo que mira o **líder** do jogador (ou área que também o atinge); ataque mirando só um aliado não acende.
- Cenários de debug:
  - `dodge_errado_pokemon` — manual, sem ação automática;
  - `dodge_errado_pokemon_auto` — AUTO, WHIFF esperado para auditoria;
  - `dodge_dread_valido` — AUTO, Evade válido sem WHIFF;
  - `dodge_manual` — sem ação automática para testar o input no Dread.
- `SUMMARY_JSON` da sala expõe `evade_ok_count`, `evade_mistimed_count`, ator/Move e `whiff_visual`.
- Teste: `tests/battle/test_d1168_dread_target.gd` — **8/8 PASS**.
- Documento: `D-1168-dread-escolhe-o-ataque-certo.md`.

## 5. Dodge tardio válido e WHIFF limpo (D-1180)

- A janela do Dread ganhou **0,15 s de margem tardia**: o Evade continua válido até **0,10 s antes do contato**, e o Dread fica aceso nesse tempo. A janela base de 0,25 s (D-988) continua.
- Um Evade válido **limpa o `WHIFF`/queda de uma tentativa anterior**, restaura a rotação do corpo e invalida a rotina antiga por token; ela não deita o personagem de novo.
- O `WHIFF` também some quando a queda termina, para não ficar na tela durante o impacto.
- Fora da nova janela continua sendo erro intencional (D-1014): gasta ATB, mostra WHIFF/queda e o golpe acerta.
- Teste: `tests/battle/test_d1180_evade_feedback.gd` — **9/9 PASS**.
- Documento: `D-1180-dodge-tardio-valido-e-whiff-limpo.md`.

## 6. Câmera do lab 3D: movimento relativo à câmera real (D-1186)

- O controle continua relativo à câmera (D-1107) e A/D continuam só câmera (D-1130).
- Quando uma parede empurra a câmera para o lado, o movimento passa a usar a **frente real da câmera** (`-camera.basis.z` projetada no chão), não o `_cam_yaw` antigo da órbita. A direita também vem da câmera real.
- O personagem continua virando para a direção do movimento (D-1107); a câmera não gira sozinha e não vira o boneco parado.
- Teste: `tests/overworld/test_d1186_camera_relative.gd` — **6/6 PASS**.
- Documento: `D-1186-movimento-relativo-a-camera-real.md` (renumerado de D-1179 por colisão com outra decisão D-1179 da matriz).

## 7. Auditoria e testes

- Suíte de combate/cenários/VFX: `python tests/battle/run_agent_combat_tests.py` — **28/28 PASS**.
- D-1159: 10/10.
- D-1160: 18/18.
- D-1166: 9/9.
- D-1168: 8/8.
- D-1180: 9/9.
- D-1186 (overworld): 6/6.
- Auditoria de cenário:
  - `dodge_errado_pokemon_auto`: `evade_mistimed_count=1`, `whiff_visual.clip="damage"`, `fall_assist=true`;
  - `dodge_dread_valido`: `evade_ok_count=1`, `evade_mistimed_count=0`, `whiff_visual={}`.
- Nenhuma captura de vídeo foi gravada nesta sessão; a verificação foi headless (testes e `SUMMARY_JSON`).

## 8. Limites / não verificado

- Vídeo final do WHIFF/queda nas duas vistas (normal e espelhada) e do dodge tardio.
- Gamepad/analógico e todos os cantos de parede da câmera.
- Vários personagens errando/dodando no mesmo quadro.
- A janela de 0,15 s pode ser ajustada se ainda parecer curta ou fácil demais.
- O `evade_tried` continua impedindo uma segunda tentativa no **mesmo** ataque; um Evade válido em outro ataque não é bloqueado.
- Nada foi commitado nem enviado; o documento é apenas registro.
- **IDs duplicados:** existem dois `D-1166` (combate e UI de afinidades) e dois `D-1167` (combate e ficha de personagem). O criador decidiu em 2026-11-12 **deixar como está**; o índice separa por título e nada foi renumerado.

## 9. Arquivos principais tocados

- `scripts/combat/battle.gd`, `scripts/combat/incoming.gd`, `scripts/combat/battle_evade.gd`
- `scripts/combat/battle_trace.gd`, `scripts/combat/battle_fx.gd`
- `scripts/vfx/combat/fx_dodge.gd`, `scripts/vfx/combat/fx_evade_flash.gd`, `scripts/vfx/combat/fx_text.gd`
- `scripts/ui/battle_hud.gd`, `scripts/ui/attack_tag_shatter.gd`
- `scripts/debug/third_person_3d_lab.gd`, `scripts/debug/vfx_room.gd`, `scripts/debug/vfx_room_scenarios.gd`
- Testes: `tests/battle/test_d1159...`, `test_d1160...` (ui), `test_d1166...`, `test_d1168...`, `test_d1180...`, `test_d1186...` (overworld), `tests/battle/run_agent_combat_tests.py`
- Documentos oficiais: D-1150, D-1159, D-1160, D-1166, D-1167, D-1168, D-1180, D-1186; `docs/TELEMETRIA.md`; `docs/REGRAS_DO_JOGO.md`.
