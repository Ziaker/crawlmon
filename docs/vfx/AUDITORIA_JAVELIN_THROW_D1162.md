# Auditoria refeita â€” Javelin Throw VFX (D-1162)

> **Superada no visual por D-1171 / `AUDITORIA_JAVELIN_THROW_HTML_C.md`.** Este documento registra a auditoria do perfil numÃ©rico do prompt e os conflitos promptÃ—HTML. O perfil oficial atual Ã© o **HTML Card C**.

- **Data:** 2026-11-11.
- **MÃ©todo:** auditoria independente em quatro frentes (HTML/Card C, prompt numÃ©rico, script/API original e crÃ­tica da auditoria anterior), seguida de verificaÃ§Ã£o no cÃ³digo e em quadros renderizados. NÃ£o usei a auditoria anterior como prova.
- **Fontes:** prompt original (`docs/vfx/JAVELIN_THROW_PROMPT_REFERENCE.md`), HTML anexado (`javelin_throw_3d_vfx_prototype.html`, Card C) e script autocontido da mesma mensagem.
- **Veredito curto:** a auditoria anterior era **invÃ¡lida em vÃ¡rios pontos**. AlÃ©m disso, **o prompt e o HTML nÃ£o descrevem o mesmo efeito**: hÃ¡ conflitos numÃ©ricos que impedem uma implementaÃ§Ã£o Ãºnica ser 1:1 com os dois. A escolha da fonte Ã© uma decisÃ£o do criador, nÃ£o minha.

## 1. Erros reais encontrados e corrigidos nesta rodada

| # | Erro | EvidÃªncia antes | CorreÃ§Ã£o | Prova |
|---|---|---|---|---|
| 1 | **Casca do flash menor que o nÃºcleo** | `_flash_outer_mesh = _mesh_octahedron(1.0)` tem raio 0,5; com escala 0,62Ã—S o raio era **0,31Ã—S**, dentro do nÃºcleo de 0,38Ã—S | `_mesh_octahedron(2.0)` (raio 1); escala 0,62Ã—S passa a ser 0,62Ã—S | `test_javelin_vfx.gd` â€œcasca externa do flash fica fora do nÃºcleoâ€ |
| 2 | **Estrela sem o terceiro eixo** | As rotaÃ§Ãµes faziam X/X/Y; nÃ£o havia eixo Z | Mesma malha alongada em Z, escala `(0.055,0.055,0.42)` e rotaÃ§Ãµes Y/X para obter X/Y/Z | teste â€œestrela tem os trÃªs eixos X/Y/Zâ€ |
| 3 | **Flare da coroa invertido** | `bb.rotated(bb.x, -(flare))` inclinava a cauda para dentro; o HTML abre para fora | Sinal trocado para `+flare`; cauda abre para fora | captura `test_captures/javelin_fix_check/javelin_oblique_a_t00.90.png` |
| 4 | **Colar dourado em vez de obsidiana** | `collar_mat` usava `COL_SOLAR_GOLD` | `COL_OBSIDIAN` com emissÃ£o dourada; torus continua ouro | teste â€œcolar em aÃ§o obsidianaâ€ |
| 5 | **Ã‚mbar sem `#FBBF24`** | EmissÃ£o usava `COL_SOLAR_GOLD` | Constante `COL_AMBER_GLOW #FBBF24` no pulso, solo, espinhos e detritos | cÃ³digo; inspeÃ§Ã£o visual |
| 6 | **Gravidade dos detritos 2g** | `-9.8*tÂ²` = aceleraÃ§Ã£o 19,6 m/sÂ² | `-4.9*tÂ²` (9,8 m/sÂ²) | cÃ³digo |
| 7 | **Tamanho dos detritos** | 0,065/0,09/0,115 | 0,06/0,095/0,13 | cÃ³digo |
| 8 | **Raio das faÃ­scas** | escala X/Y 0,022 = diÃ¢metro, raio 0,011 | 0,044 = diÃ¢metro, raio 0,022 | cÃ³digo |
| 9 | **Tubos dos anÃ©is variÃ¡veis** | O tubo escalava com o raio (0,0039â€“0,0407 no atrasado; 0,0099 no solo) | Malha de toro reconstruÃ­da por quadro com tubo constante `0.022*S` / `0.065*S` | cÃ³digo; captura 1,20 s |
| 10 | **RetÃ­culo atÃ© 0,78** | `windup_t <= 0.78` | `<= 0.75` (prompt) | teste â€œretÃ­culo desliga no releaseâ€ |
| 11 | **Socket de mÃ£o/peito nÃ£o existia** | SÃ³ osso/AABB | `_socket_named()` procura `HandSocket`/`WeaponSocket`/`RightHand`/`Hand` e `ChestSocket`/`TorsoSocket`/`ImpactSocket`/`Chest` antes do fallback | cÃ³digo `fx_javelin_throw.gd` |
| 12 | **Alvo nulo derrubava `_anchors`** | SÃ³ checava `attacker == null` | Checa `target == null` e encerra o efeito | cÃ³digo |
| 13 | **Miss com altura fixa +1,0** | `inc.aim + Vector3(0,1,0)` | Usa a altura do chest real do alvo | cÃ³digo |
| 14 | **Energias fora da paleta** | Ouro 4,6; carmesim 1,8â€“3,6; Ã¢mbar 0,8â€“3,6 | Ouro 2,8â€“4,5; carmesim 3,2; Ã¢mbar 2,5 | cÃ³digo |

## 2. Conflitos prompt Ã— HTML (decisÃ£o do criador necessÃ¡ria)

Estes nÃ£o sÃ£o bugs: sÃ£o **duas especificaÃ§Ãµes diferentes**. O prompt diz â€œ1:1 com o HTMLâ€, mas os nÃºmeros nÃ£o sÃ£o os mesmos.

| Item | Prompt (referÃªncia) | HTML Card C | Impacto visual |
|---|---|---|---|
| LanÃ§a | 2,15 m simÃ©trica; Ã¡pice 1,075; haste 1,45 em âˆ’0,15; ponta base 0,58 | Ã¡pice 1,30; haste 1,85 em âˆ’0,02; ponta base 0,78; cauda âˆ’0,945 (**2,245 m assimÃ©trica**) | Comprimento, alavanca e onde a coroa nasce |
| Cores | haste/colar obsidiana; grip carmesim; penas carmesim | haste `#FEF9C3`, grip `#451A03`, colar `#FF5555`, penas brancas | AparÃªncia completamente diferente |
| Coroa â€” peÃ§as | **7** lÃ¢minas (4 internas + 3 externas) | **14** malhas (7 internas + 7 externas) no cÃ³digo; o texto do card diz 7 | Metade da geometria e silhueta |
| Coroa â€” tamanho | 0,58 / 0,46; base 0,048 | 1,08 / 0,80 (Ã—0,96); base 0,115 / 0,095 (Ã—0,94) | Coroa ~1,8Ã— maior |
| Coroa â€” gap | 0,025 â†’ 0,25 â†’ 0,46 | 0,015â†’0,752 (interna); 0,055â†’0,987 (externa) | Coroa muito mais aberta no HTML |
| Coroa â€” recuo | 0,68 e depois +0,38 | 1,22 e depois +1,15 | No HTML a coroa varre o grip/mÃ£o |
| Estrela | 3 octaedros 0,42 | 2 espinhos 0,853 + nÃºcleo 0,11; escala atÃ© 2,1 | Forma e tamanho |
| PÃ³s-imagens | `uâˆ’kÂ·0,095`, alpha `(1âˆ’k/7,5)Â·0,55` | fraÃ§Ãµes fixas `(i+1)/8`, alpha por idade 0,72, giro `fracÂ·3Ï€` | Rastro colado vs marcadores fixos |
| Voo | `u^0,88`, arco 0,035, spin `3,5Ï€` | `u^0,58`, arco 0,024, spin `2,5Ï€` | Curva e giro |
| Montagem | janelas 0,22â€“0,68, cubic, drawback 0,28 | janelas 0,16â€“0,58 Ã—1,15, easeOutBack, drawback 0,36 | Ritmo e â€œsnapâ€ |
| RetÃ­culo | torus octogonal + 4 cunhas, 0,55â†’0,18, 180Â° | octaedro duplo, 1,85â†’0,78 Ã— raio, rotaÃ§Ã£o livre | Geometria e leitura |
| Flash | 2 poliedros, colapsa | 1 octaedro, expande | Movimento oposto |
| AnÃ©is | atrasado 0,18â†’1,85; solo 0,22â†’1,45 | atrasado 0,35â†’2,60; solo 0,48+2,35 | Tamanho |
| Cruz | 2 lÃ¢minas X + 1 longitudinal, brancoâ†’carmesim | 3 lÃ¢minas em X/Y/Z, vermelho fixo, escala 1,28 | Forma/cor |
| FaÃ­scas | 12, frontais (+axis) | 8, radiais no plano | Contagem/direÃ§Ã£o |
| Pulse | torus + cilindro | octaedro + luva cÃ´nica | Geometria |
| Espinhos de solo | nÃ£o listados | 8 cones, inclinados 0,52 rad | Camada extra |

**ConsequÃªncia:** a implementaÃ§Ã£o atual segue o **prompt** (7 lÃ¢minas, 2,15 m, obsidiana, 3 octaedros etc.). Por isso ela **nÃ£o fica igual ao HTML** â€” e, se eu trocar para o HTML, ela deixa de seguir os nÃºmeros do prompt. NÃ£o existe uma Ãºnica configuraÃ§Ã£o que satisfaÃ§a os dois.

## 3. API e integraÃ§Ã£o â€” lacunas reais

| Item do script original | Estado | Onde/observaÃ§Ã£o |
|---|---|---|
| `play_move(attacker,target,camera)` | **AUSENTE** | A batalha usa `FxJavelinThrow.start(inc)`; o lab nÃ£o aceita nÃ³s externos |
| `set_scrub_time(t)` no VFX | **AUSENTE** | Existe sÃ³ no lab (`javelin_vfx_lab.gd:68`) |
| `auto_spawn_sandbox`, `loop_playback`, `attacker_node`, `target_node`, `active_camera`, `ground_y` | **AUSENTE/PARCIAL** | Sem `@export`; lab tem rigs/cÃ¢mera fixos |
| Sinais `move_windup_completed`, `move_hit_triggered`, `move_finished` | **AUSENTE** | Equivale a `Battle.attack_resolved`/`hit_resolved`/`phase(DONE)`, com payload diferente |
| `--stdout-trace`/`--summary-json` no lab/VFX | **AUSENTE** | SÃ³ no `BattleTrace`/`vfx_room`; o lab sÃ³ tem `--lab-*` |
| Nome `JavelinThrowVFX` | **ADAPTADO** | Atual `JavelinThrowVfx` (caixa diferente) |

A ausÃªncia de `set_scrub_time`/relÃ³gio no VFX de combate Ã© D-019/D-1040; a ausÃªncia de `play_move` com nÃ³s arbitrÃ¡rios, exports e sinais **nÃ£o Ã© explicada por D-019** â€” Ã© lacuna de contrato.

## 4. Regras e driver â€” pendÃªncias

- **D-094:** o driver nÃ£o para por morte do atacante, mas a batalha cancela o `Incoming` ao morto (`battle.gd:_drop_returns_of`) e chama `fx.on_attack_cancelled` â†’ `fx_javelin.cancel` â†’ `queue_free`. O projÃ©til visual para. **NÃ£o corrigi** porque Ã© regra de combate; precisa de decisÃ£o.
- **D-235 automatizado:** o `--test-d235` sÃ³ verifica `_fired`; o teste dedicado usa Ã¢ncoras sintÃ©ticas; o laboratÃ³rio usa posiÃ§Ãµes fixas. Ã‰ uma **amostra**, nÃ£o prova universal.
- **Chest/feet:** socket agora tem prioridade; sem socket, chest = 62% do AABB e feet = fundo do AABB. Ã‰ heurÃ­stica documentada, nÃ£o osso real.
- **target_height** Ã© lido e nÃ£o usado.
- **Flash â€œcrÃ­ticoâ€:** aparece em crÃ­tico e nÃ£o crÃ­tico; `crit` sÃ³ multiplica a escala. Se o nome for â€œflash crÃ­ticoâ€, o comportamento nÃ£o corresponde.

## 5. EvidÃªncias apÃ³s as correÃ§Ãµes

- Teste dedicado: `RESULT: PASS` (inclui eixos da estrela, casca do flash, colar, retÃ­culo, espinhos, arestas, zero sobras).
- D-235: `D235_RESULT: PASS`.
- Vazamentos: `[vfx_audit] leaks=0 nodes=[]`.
- Envelope: `envelope_pops: []`.
- Capturas de verificaÃ§Ã£o: `test_captures/javelin_fix_check/` (0,75/0,90/1,13/1,20).
- **SuÃ­te completa nÃ£o foi rerodada depois de todas as correÃ§Ãµes**; a Ãºltima rodada antes destas mudanÃ§as foi 24/24.

## 6. O que falta decidir

1. **Fonte da verdade visual:** HTML Card C ou prompt numÃ©rico? (Ou dois perfis.)
2. **D-094:** o projÃ©til visual deve continuar apÃ³s a morte do lanÃ§ador? Isso exige mudar o caminho da batalha ou aceitar que ele para.
3. **API do script original:** criar o wrapper `play_move`/exports/sinais, ou assumir a integraÃ§Ã£o `BattleFx` como definitiva?
4. **Flash crÃ­tico:** deve existir sÃ³ em crÃ­tico ou em todo impacto?

## 7. O que nÃ£o foi verificado

- Todos os personagens/tamanhos; a matriz real Ã© uma amostra.
- A leitura das 5 peÃ§as a 37 m em quadro real.
- Custo de GPU/overdraw e Mobile/Forward+.
- O caso de morte do lanÃ§ador, escudo, miss, interrupÃ§Ã£o e dois Javelins simultÃ¢neos.
- A comparaÃ§Ã£o visual pixel a pixel com o HTML (o HTML tem 3 cards e cÃ¢mera prÃ³pria; nÃ£o Ã© o mesmo enquadramento do jogo).

