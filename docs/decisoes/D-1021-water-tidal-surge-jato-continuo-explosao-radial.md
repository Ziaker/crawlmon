# D-1021 — Water: Tidal Surge, onda viajante com explosão radial

- **Data:** 2026-11-08.
- **Área:** VFX / Biblioteca de projéteis (D-955, D-956).
- **Origem:** respostas do criador à proposta das seis fases do Water, na conversa.
- **Estado:** Wind-up é o vórtice no chão à frente; a **onda larga viajante** (W) está implementada (desliza, descola no pico e voa); **Impacto radial ainda pendente**; aguardando aprovação.

## Frases literais do criador

> Water

> Jato de água

> Explosão radial de água

> Azul, ciano e branco

> Tidal Surge

> Jato contínuo

> Base nami league of legends W ability em qualquer skin, pesquise também sobre as skins water song e curtindo o verão para melhores resultados e referencias

> quero que o start comece com um vortex de água no chão, e apartir dele começar a surgir a onda (wind-up) que vai se disparar (release), do chão, bem alto assim como a habilidade da nami, melhorando a desc e o efeito, continue

## Decisão

1. O próximo elemento da biblioteca é **Water**.
2. **Forma:** **jato de água contínuo**, ligado ao lançador, com base na **W da Nami (Ebb and Flow)** em qualquer skin.
3. **Impacto:** **explosão radial de água**.
4. **Paleta:** **azul, ciano e branco**, sem dourado (o dourado continua sendo a identidade do Electric).
5. **Nome do Move de debug:** **Tidal Surge**.
6. **Referências a pesquisar:** a W da Nami e as skins **“Water Song”** e **“Curtindo o Verão”**.

## O que a pesquisa achou (2026-11-08)

- **W da Nami (Ebb and Flow):** é um fluxo de água que viaja até o alvo e ricocheteia. Na skin **Sunken Shadows** (SkinSpotlights, `_BJnAp9FOjo`, ~2:35), o fluxo aparece como uma **fita curva** de núcleo **branco-ciano**, borda **azul-esverdeada**, gotas em volta e um **respingo** no alvo. Não é uma mangueira parada: o fluxo existe durante o golpe e salta para o próximo alvo.
- **“Water Song”:** não é uma skin da Nami. O nome mais próximo é **Ocean Song** (Canção do Oceano), linha com Yone, Nidalee, Zeri, Ashe e Seraphine; **não existe Nami Ocean Song**. A água da linha é turquesa/ciano com acentos **rosa/magenta** e notas musicais.
- **“Curtindo o Verão”:** é **Pool Party**. **Não existe Nami Pool Party oficial**; há apenas conceito de fã e skin customizada. As skins oficiais da linha usam água **turquesa clara** e espuma branca.
- Consequência: a **Nami W** é a base da forma; Ocean Song/Pool Party só podem entrar como **referência de matéria/paleta**, não como skin da Nami.

## Nova direção do Start/Wind-up (2026-11-09)

1. **Start:** um **vórtice de água no chão em volta do personagem**, do tamanho do corpo (medido por `FxBubbleShield.body_envelope`, como o Bubble Shield), com anéis e **folhas de onda largas e entrelaçadas** em volta (sem hélice/parafuso), em **giro rápido**, e gotas.
2. **Wind-up:** do chão **à frente** sobe a **onda alta** (Nami R); o vórtice fica em volta do personagem e a onda à frente, com o vórtice numa **camada de render acima da onda**, para os dois aparecerem.
3. **Release:** a onda **se dispara**. Interpretação registrada: a onda é a **carga** e o release a converte no **jato contínuo já aprovado**; se o criador quiser a onda viajando como projétil em vez do jato, isso é uma decisão nova.
4. A âncora alta do topo do corpo (D-1021 anterior) fica **substituída** pelo vórtice no chão em volta do corpo; a câmera e o corpo largo do Slime não escondem o vórtice.

## Seis fases (Start/Wind-up aprovados; Release implementado, aguardando aprovação)

| Fase | O que aparece | Tempo |
|---|---|---|
| **Start** | Um **vórtice de água no chão à frente do personagem** (no eixo atirador→alvo): anéis, **folhas de onda largas e entrelaçadas** girando **rápido** e gotas. Não há onda alta. | 0,15 s, dentro do wind-up |
| **Wind-up** | O **vórtice fica no chão à frente**, girando e soltando gotas, até o release. **Sem onda alta** (removida pelo criador). | 0,8 s (o wind-up real do Move), até o release |
| **Release** | O vórtice vira o **arco de água** contínuo. Uma **coroa 3D de 16 pontas** de água + um **anel 3D de gotas do Motion Composer** abre ao redor do vórtice, expande e some por opacidade. | 0,55 s (coroa); o arco segue no Trajectory |
| **Trajectory** | O **arco de água** viaja no arco balístico completo (pico `distância × 0,24`). Depois do pico a **cauda solta do chão** e segue o corpo (`JET_TAIL_SPAN = 0,55`); o Composer deixa gotas atrás da cabeça. Ao chocar, o jato **salta** para o próximo alvo (bounce D-1025). | 0,53 s (relógio real do combate) |
| **Impact** | **Explosão radial de água** (decidida; a implementar): clarão de espuma, lençóis e gotas em 360°, anel no chão; raio pelo corpo real do alvo. | 0,25 s |
| **Post-impact** | Os lençóis caem em gotas, a névoa evapora e o anel do chão some; **nada fica** (sem poça/decal) e a tela limpa. | 0,45 s |

**Medidas implementadas do arco:** corpo de 8 lados com raio **0,55 m** e bojo no meio, duas fitas de água de 0,16 m entrelaçadas, 26 gotas e ondulação lateral de 0,25 m; o **arco** tem pico `distância × 0,24` (entre 2,2 m e 7,0 m); tudo em metros fixos, igual nas duas vistas (D-308).

## Ambiguidades em aberto (perguntar antes de codar)

1. **Curva:** a W da Nami é uma fita **curva**; o “jato contínuo” pode ser **reto** (pressão) ou **levemente curvo** (como a W). O criador ainda não escolheu.
2. **Acento do Ocean Song:** a linha Ocean Song tem **rosa/magenta**; a paleta escolhida é azul/ciano/branco. O acento rosa entra ou fica de fora?
3. **Uso das linhas Ocean Song/Pool Party:** como não há Nami nessas linhas, confirmar se elas entram só como **matéria/paleta** ou se o criador quer outra referência.
4. **Aprovação das seis fases:** a descrição acima ainda não foi aprovada; a implementação começa só depois do OK, uma fase por vez.

## O que não muda

- Nenhum Move aprovado (Electric Beam, Flame Stream, Bubble Shot etc.) é alterado.
- Nada de gelo/cristais (D-397), poça/decal (GL Compatibility), glow de cena ou clarão de tela inteira (D-337/D-418).
- Tempo, dano, acerto e regras do combate continuam intocados (D-019).
- Nada depende de personagem, time ou lado (D-235).
- D-1020 (ferramentas de VFX) é uma frente separada e continua só proposta; nada dela é implementado por esta decisão.

## Relações

D-955, D-956, D-954, D-308, D-235, D-019, D-957 a D-976 (lições do Electric), D-1017 (frente separada, não esta), D-1020 (frente separada), D-061.

## Implementação da fase Start (2026-11-08)

- **Classe:** `scripts/combat/fx/projectile_lib/tidal_surge_vfx.gd` (`TidalSurgeVfx`, `IDS = ["tidal_surge"]`).
- **Move de debug:** `Skill.library_skills()` ganhou **Tidal Surge** (2 ATB, wind-up 0,5 s, `Element.Type.AGUA_GELO`); listado só na sala de VFX.
- **Integração:** `fx_telegraph.gd` cria a carga e a segura; `fx_projectiles.gd` faz o release/trajeto; `fx_impacts.gd` chama o `hit` (o impacto ainda não é desenhado); `_spawn_move` devolve um nó vazio.
- **Atacante/alvo reais:** `TidalSurgeVfx.begin` recebe os `Combatant` de atacante e alvo; `front_of_model`/`body_of_model` medem o modelo real, sem procurar o “mais próximo” (auditoria 4.2). `front_of`/`body_of` continuam como fallback e o Electric passa pelo mesmo caminho de antes.
- **Start/Wind-up:** vórtice de água **no chão em volta do personagem**, com raio/altura medidos por `FxBubbleShield.body_envelope` (a mesma referência do Bubble Shield): dois anéis, **10 folhas de onda largas** (3,6× na largura) em **dois raios alternados** que se entrelaçam, em **giro rápido** (~1,3 volta/s) e balanço rápido, mais gotas; a **onda crescente de 5,2 m** sobe do chão à frente, com corpo azul e crista de espuma (`lib_water_wave.gdshader`), perfil crescente e base no chão. O vórtice/as folhas usam `render_priority = 2` e a onda `1`, então os dois aparecem. O Start dura 0,15 s e o Wind-up 0,8 s. No release o vórtice/onda são escondidos; o jato, o impacto e o pós-impacto ainda não são desenhados.
- **Motion Composer:** o Start é **100% principal, feito à mão**. Não há camada secundária nesta fase, então o Composer não é usado; as gotas e o fio são parte da leitura principal. O secundário das próximas fases (spray/névoa/gotas do trajeto e impacto) **pode** usar o Composer ou ser feito à mão; não é obrigatório (D-1030).
- **Verificado:** `tests/vfx/projectile_lib/test_contract.gd` com 0 falhas; vídeo `test_captures/tidal_surge_start_v5.mp4` (normal + espelhado, `--clean`, 0,8 s); quadros em tamanho real f_02–f_04; Electric Beam regravado e conferido em quadros (carga, disparo, impacto) sem regressão visível.
- **Não verificado:** legibilidade do Start na vista espelhada a ~37 m (o atacante é o inimigo distante); outros atacantes e alvos; desempenho/overdraw; aprovação artística.
- **Slime (2026-11-09):** o vórtice agora é **no chão em volta do personagem**, medido pelo corpo (`FxBubbleShield.body_envelope`, como o Bubble Shield), com **camada de render acima da onda**; a hélice/parafuso foi trocada por **10 folhas de onda largas e entrelaçadas** em volta, em **giro rápido**; a onda sobe no chão à frente. Os dois aparecem no Slime e no Abra. Vídeos: `test_captures/tidal_surge_wave_slime_v10.mp4` e `test_captures/tidal_surge_wave_abra_v8.mp4` (0,8 s, antes do release). A âncora `front_of_model_high` foi removida; o Water usa `front_of_ground_model` para a onda.

## Correção do Release: arco completo de água (2026-11-09)

> esta pessimo parece mais um cano se alongando do que realmente agua, alem do movimento nao ser aquatico em um arco completo como na linha desenhada em verde

- O Release **não** é um tubo reto com platô. O disparo segue um **arco balístico completo**: sobe do lançador, culmina no meio do trajeto e desce no alvo, como a linha verde desenhada pelo criador.
- A água precisa **ler como água**, não como cano: corpo com raio irregular (não constante), UV vertical com **crista de espuma branca em cima**, corpo azul e base profunda, dois fios de água entrelaçados, ondulação lateral e gotas caindo do arco.
- O arco é derivado apenas do atacante e do alvo reais (D-235); a altura do cume é proporcional à distância (proposta: `distância × 0,24`, entre 2,2 m e 7,0 m), igual nas duas vistas (D-308).
- A transição suave do Release (onda inclina/estica/desfaz + jato nasce da base) continua valendo; só o **formato do jato** muda.

## Nova direção: a onda W viajante (2026-11-09) — REVERTIDA

> nao tem nada haver com o R DA NAMI, esse move e basicamente o W dela

> 1 desloca do chao no pico e voa ate cair no alvo
> 2 explosao radial
> 3 - deixe como esta

> VOLTE ATRAS ISSO TA UM LIXO NAO E MAIS O QUE ERA PRA SER

> eu so quero que a onda volte, leve isso aqui em conta
>
> 7. Fluxo Sinuoso por UV Panning (Corrente de Energia com Núcleo Quente) — uma fita sinuosa conecta o alvo ao usuário com fluxo contínuo de textura (UV Panning) no sentido da drenagem, mantendo um núcleo branco superexposto (Core) envolvido por uma aura azul-ciano de bordas suaves; as bordas se desfazem em gotas/faíscas.

- **Revertido:** a onda larga (3,2 m × 2,8 m, três folhas) foi **descartada** por ordem do criador. O código voltou ao **arco de água + coroa 3D + Motion Composer** (versão v9). Nada da onda larga ficou no código.
- **Referência registrada, não aplicada:** a fita sinuosa com **UV Panning**, núcleo branco superexposto e aura azul-ciano de bordas suaves é o próximo caminho para o corpo do arco — mas é uma mudança nova e **não** foi feita neste revert.
- A referência é a **Nami W**, não a R.
- **Impacto radial:** decidido; ainda **não implementado** (o arco chega ao alvo e some por opacidade; a explosão radial é a próxima entrega).
- **Motion Composer:** o rastro de gotas do trajeto sai da **cabeça do arco**; a coroa usa o anel de gotas do Composer.

## Cauda solta + salto do bounce (2026-11-09)

> ok, agora faca a cauda se desprender do chao e seguir o restante ate se chocar e depois pular

- **Corpo:** é o **V9** (arco/tubo de água, duas fitas, cabeça esférica, coroa 3D, Composer). Nada do corpo foi refeito.
- **Cauda:** `JET_TAIL_SPAN = 0,55`. O corpo visível vai da **cauda** (p − 0,55) até a cabeça (p); depois do pico a cauda **descola do chão** e segue o mesmo arco. Antes do pico ela ainda toca a base, como no V9.
- **Pulo:** o bounce da D-1025 agora é desenhado. `TidalSurgeVfx.bounce` cria o mesmo corpo de água do último alvo ao próximo, **sem vortex/coroa**; `FxProjectiles.spawn` usa isso quando `inc.bounce_root != null`. O jato salta para o próximo alvo e continua a cadeia.
- **UV Panning:** o shader `shaders/lib_water_ribbon.gdshader` foi **mantido** para outro move, mas não é usado no Tidal atual.
- **Vídeos:** `test_captures/tidal_surge_release_slime_v12.mp4` (Slime, normal + espelhado); `test_captures/tidal_surge_release_abra_v8.mp4` (Abra, regressão); `test_captures/tidal_surge_release_slime_lateral_v6.mp4` (lateral); `test_captures/tidal_surge_gamecam_tail.mp4` (câmera do jogo).
- **Não verificado:** explosão radial (a implementar); desempenho/overdraw; aprovação artística.

## Primeira versão do Release (substituída)

- **Transição sem corte (D-308 item 5):** no release a onda **não é escondida**. Ela se **inclina para frente** (`rotation.x` até 0,62 rad), **estica no eixo do disparo** (1,0 → 1,55) e **se achata** (1,0 → 0,55) durante **0,34 s**, com a opacidade caindo por `smoothstep`; o vórtice/folhas dissipam em **0,40 s**. O jato nasce do **mesmo ponto** (base da onda) com alfa em `smoothstep` de **0,22 s** e um **respingo de base** (esfera que cresce e some em 0,40 s). Nenhum `visible = false` acontece antes do alfa chegar a zero.
- **Jato:** `_jet` (ImmediateMesh) desenha um tubo de 6 lados com raio **0,42 m na base → 0,22 m na ponta** e uma hélice de água (raio 0,075 m, amplitude 0,30 m) que gira com o tempo; a ponta tem uma cabeça esférica. O caminho sobe rápido do chão para **~2,6 m** (`smoothstep` nos primeiros 16%), cruza acima do piso e desce no alvo — sem isso o piso ocluía quase todo o jato na câmera baixa de combate.
- **Release real:** o relógio do combate dispara o release visual em **1,633 s** (TRAVEL), não em 0,833 s (fim do wind-up); o `_release_t` do VFX é marcado no `release()` chamado pelo `FxProjectiles.spawn`.
- **Vídeos:** par normal+espelhado `test_captures/tidal_surge_release_slime_v5.mp4` (Slime, 2,3 s, com impacto); regressão do Abra `test_captures/tidal_surge_release_abra_v3.mp4`; câmera lateral de verificação `test_captures/tidal_surge_release_slime_lateral_v2.mp4` (mostra a onda inclinando e o jato saindo contínuo).
- **Sem pop medido:** a diferença média entre quadros consecutivos na janela do release fica em ~0,5–1,3 (sem pico); o único pico é o impacto (~2,5), esperado.
- **Não verificado:** Impact e Post-impact desenhados; salto (bounce) desenhado; desempenho/overdraw; aprovação artística do Release.

## Implementação do Release em arco (2026-11-09)

- **Formato:** o disparo segue um **arco balístico completo** (`_arc_point`: `a.lerp(b,u) + UP * pico * 4u(1-u)`), com o pico em `distância × 0,24` (2,2–7,0 m). A cabeça segue o arco, não a reta: no meio do trajeto ela está no ponto mais alto e desce no alvo.
- **Água, não cano:** corpo de 8 lados com raio **0,55 m**, perfil 0,62–1,0× (bojo no meio), rugosidade senoidal no raio e ondulação lateral de 0,25 m; **UV vertical** no `lib_water_wave.gdshader` (topo = espuma branca, corpo azul, base profunda). Duas **fitas de água** de 0,16 m entrelaçadas em volta do corpo e **26 gotas** caindo do arco.
- **Transição:** a mesma da primeira versão — a onda inclina/estica/se desfaz em 0,34 s, o vórtice dissipa em 0,40 s, o jato nasce da base com rampa de 0,22 s e respingo de 0,40 s; sem corte e sem `visible = false` antes do alfa zerar.
- **Vídeos:** `test_captures/tidal_surge_release_slime_v6.mp4` (Slime, normal + espelhado); `test_captures/tidal_surge_release_abra_v4.mp4` (Abra, regressão); `test_captures/tidal_surge_release_slime_lateral_v3.mp4` (lateral, mostra o arco inteiro).
- **Sem pop medido:** a diferença média entre quadros consecutivos na janela do release fica em ~0,5–1,3 (sem pico); o único pico é o impacto (~2,5), esperado.
- **Não verificado:** Impact e Post-impact desenhados; salto (bounce) desenhado; desempenho/overdraw; aprovação artística do Release em arco.

## Vortex na frente, sem onda + coroa 3D + Motion Composer (2026-11-09)

> faz assim, tira essa onda do wind up e coloque o vortex na frente ao inves do redor do personagem

> o efeito do wind up esta verticalmente acima do chao e nao no chao mais, inclusive no release crie um efeito de splash aquatico em forma de coroa de varias pontas aberta, como um sol geometricamente que se expande e some com opacidade reduzindo gradualmente, inclusive use as bibliotecas o flipbook e as skills de godot vfx para melhorar estes efeitos visuais e fazerem eles serem mais aquaticos e menos tubos

> o efeito de coroa que pedi deve ser 3D e nao 2D e pra ser ao redor do vortex quando ocorre o release. @scenario-godot-vfx , use o motion composer tambem para o trajeto e o visual da onda

- **Wind-up:** a onda alta foi **removida**. O vórtice fica **no chão à frente** do personagem, no ponto onde a onda nascia (`charge_pos` com `y = 0`), e é a única carga até o release.
- **Piso:** a carga usa o **piso real** (`y = 0`, como o Bubble Shield), não a base do AABB do modelo (que flutuava acima do chão).
- **Coroa 3D (sem 2D):** no release, **16 pontas de água 3D** (malha de 6 lados, `lib_water_wave`, ponta de espuma) abrem ao redor do vórtice, mais um **anel 3D de gotas** do Motion Composer (M01, `drops` de água). A coroa expande e some por opacidade em **0,55 s**. Nenhum flipbook 2D é usado na coroa.
- **Motion Composer:** o **trajeto** ganhou um rastro de gotas de água do Composer (M24 + `drops`, atrás da cabeça real do arco) e a **coroa** usa o anel de gotas do Composer; o corpo do arco continua à mão (D-954), com o Composer no secundário (D-1030).
- **Arco:** mantém o arco balístico completo e o corpo de água do Release em arco (seção anterior).
- **Vídeos:** `test_captures/tidal_surge_release_slime_v9.mp4` (Slime, normal + espelhado); `test_captures/tidal_surge_release_abra_v6.mp4` (Abra, regressão); `test_captures/tidal_surge_release_slime_lateral_v4.mp4` (lateral); `test_captures/tidal_surge_gamecam.mp4` (câmera do jogo, move completo, com a regra D-1073).
- **Auditoria:** `[vfx_audit] leaks=0 nodes=[]` com `--audit-leaks`; nenhum `[POP_DETECTED]` com `--envelope-graph`.
- **Não verificado:** impacto radial (a implementar); salto (bounce) desenhado; desempenho/overdraw; aprovação artística do arco.

## Estado no código

**Arco de água + coroa 3D + Motion Composer (v9) com a cauda solta depois do pico e o bounce desenhado; Impacto radial e Post-impact ainda não desenhados.** O Wind-up é o vórtice no chão à frente; o Release faz a coroa 3D e o arco. Vídeos da entrega: `test_captures/tidal_surge_release_slime_v12.mp4` (Slime, normal + espelhado), `test_captures/tidal_surge_release_abra_v8.mp4` (Abra, regressão), `test_captures/tidal_surge_release_slime_lateral_v6.mp4` (lateral) e `test_captures/tidal_surge_gamecam_tail.mp4` (câmera do jogo). O shader de **UV Panning** fica em `shaders/lib_water_ribbon.gdshader` para outro move, não aplicado aqui. O arco ainda **não está aprovado** pelo criador. Nada commitado ou publicado (D-022).
