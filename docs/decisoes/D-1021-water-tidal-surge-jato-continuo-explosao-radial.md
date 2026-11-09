# D-1021 — Water: Tidal Surge, jato contínuo com explosão radial

- **Data:** 2026-11-08.
- **Área:** VFX / Biblioteca de projéteis (D-955, D-956).
- **Origem:** respostas do criador à proposta das seis fases do Water, na conversa.
- **Estado:** decisões de forma registradas; as seis fases continuam **propostas**, aguardando aprovação; **nenhum código, nenhum vídeo**.

## Frases literais do criador

> Water

> Jato de água

> Explosão radial de água

> Azul, ciano e branco

> Tidal Surge

> Jato contínuo

> Base nami league of legends W ability em qualquer skin, pesquise também sobre as skins water song e curtindo o verão para melhores resultados e referencias

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

## Seis fases propostas (NÃO aprovadas)

| Fase | O que aparece | Tempo |
|---|---|---|
| **Start** | Um estalo de pressão no ponto de carga à frente do corpo: um anel fino de gotas e um fio de água que se recolhe para dentro da ogiva; sem clarão de tela. | 0,15 s, dentro do wind-up |
| **Wind-up** | Uma ogiva de água azul-escura com núcleo branco-ciano gira no ponto à frente do corpo, no eixo do disparo; a superfície tem um redemoinho na frente, gotas orbitam e a ogiva se comprime e afina como se a pressão subisse. Ela **não some: vira o jato**. | 0,5 s + 0,8 s de carga segurada |
| **Release** | A ogiva se estica e vira o jato: núcleo branco-ciano, bainha azul e uma fita de água em hélice; um anel de respingo e um cone de névoa explodem para trás no bico; o jato sai do mesmo ponto, sem corte. | 0,08 s |
| **Trajectory** | O jato viaja reto no eixo atacante→alvo, ligado ao lançador, com núcleo branco-ciano, bainha azul, hélice de água e cauda de gotas/névoa; a ponta é uma ogiva afilada com um anel de névoa à frente. Sem zigue-zague; legível a ~37 m pelo núcleo claro e pela hélice. | 0,63 s (relógio real do combate) |
| **Impact** | Explosão radial de água: clarão de espuma no contato, estouro esférico de lençóis de água e gotas que abre em 360° e para, mais um anel de água no chão. O raio é medido pelo corpo real do alvo (proposta: `altura × 0,55`, entre 0,9 m e 2,2 m), para não parecer que atinge o aliado ao lado. | 0,25 s |
| **Post-impact** | Os lençóis caem em gotas, a névoa evapora e o anel do chão some; **nada fica** (sem poça/decal) e a tela limpa. | 0,45 s |

**Medidas propostas do jato:** núcleo de 0,36 m de diâmetro, bainha de 0,8 m, ogiva de 0,55 m; tudo em metros fixos, igual nas duas vistas (D-308).

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
- **Start:** 0,15 s; anel de pressão perpendicular ao tiro (raio 0,10 → 0,55 m), anel interno que fecha, núcleo de água (0,04 → 0,16 m), 12 gotas em anel e um fio curvo de água; dissolve no fim. Cores azul/ciano/branco; sem dourado.
- **Motion Composer:** o Start é **100% principal, feito à mão**. Não há camada secundária nesta fase, então o Composer não é usado; as gotas e o fio são parte da leitura principal. O secundário das próximas fases (spray/névoa/gotas do trajeto e impacto) usará o Composer ou uma decisão registrará o contrário **antes** da entrega.
- **Verificado:** `tests/vfx/projectile_lib/test_contract.gd` com 0 falhas; vídeo `test_captures/tidal_surge_start_v5.mp4` (normal + espelhado, `--clean`, 0,8 s); quadros em tamanho real f_02–f_04; Electric Beam regravado e conferido em quadros (carga, disparo, impacto) sem regressão visível.
- **Não verificado:** legibilidade do Start na vista espelhada a ~37 m (o atacante é o inimigo distante); outros atacantes e alvos; desempenho/overdraw; aprovação artística.
- **Slime (2026-11-09):** a carga real fica **3,19 m à frente** do modelo do Slime, com **raio de corpo 2,09 m**, na **altura do centro**. A câmera do jogo fica atrás do atacante e o corpo largo do Slime **oculta o Start**. O mesmo Start no Abra era visível porque o corpo é estreito. **Proposta em aberto:** subir a carga para o **topo da frente do corpo** (mesmo eixo do disparo, sem desvio lateral, D-964), para ela aparecer por cima da silhueta; aguardando aprovação. Nada alterado ainda.

## Estado no código

**Fase Start implementada; as outras cinco não desenhadas.** O vídeo da entrega é `test_captures/tidal_surge_start_v5.mp4`. Nada commitado ou publicado (D-022).
