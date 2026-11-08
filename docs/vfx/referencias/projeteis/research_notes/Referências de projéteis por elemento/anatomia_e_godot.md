# Anatomia transversal de projéteis de VFX e construção em Godot 4.7 (GL Compatibility)

> Notas de pesquisa para D-955 (fase de pesquisa e referência). Não autorizam construir nada e não propõem mudança de regra de jogo. Pesquisa feita em 2026-11-07.
>
> **Convenção de fontes:** link sem marca = página aberta por mim. **(busca)** = só vi o resumo do resultado de busca, não abri a página; a atribuição é menos segura. Fontes bloqueadas estão listadas no fim, na última seção.
>
> **Versões:** "docs 4.7" = docs.godotengine.org/en/stable, que hoje se identifica como 4.7. O projeto usa 4.7.2; não encontrei diferença documentada entre 4.7 e 4.7.2, mas também não comparei os dois. O código-fonte lido foi a tag `4.7-stable`.

## Como profissionais decompõem um projétil, e que tempos e proporções são publicados?

### Conclusão
A decomposição em peças é consistente entre as fontes: disparo (muzzle), cabeça, cauda, impacto, resíduo, e por cima disso um arco de intensidade (preparo, clímax, queda). **Não encontrei nenhuma fonte confiável com proporções por fase** (tipo "x% de wind-up"). Só há durações pontuais de exemplos e tutoriais, que servem de ordem de grandeza e não de regra.

### Achados citados
**Estrutura**
- Um tutorial de Unity divide o projétil em cabeça (núcleo do corpo que voa) e cauda (rastro que a segue); o muzzle é montado com cone, flash e faíscas — [Kodeco, p. 3](https://www.kodeco.com/23120977-vfx-in-unity-getting-started?page=3); [Kodeco, p. 2 (busca)](https://www.kodeco.com/23120977-vfx-in-unity-getting-started?page=2).
- O impacto é prefab separado, gerado quando a colisão acontece, e não uma parte que viaja com o projétil — [Kodeco, p. 3](https://www.kodeco.com/23120977-vfx-in-unity-getting-started?page=3).
- Um guia da comunidade Unreal separa muzzle, tracer opcional (fita), impacto (HIT, DUST, DEBRIS num único sistema) e aftermath (marca na superfície). A página é marcada como Legacy (era Cascade) — [Unreal Community Wiki](https://unrealcommunity.wiki/projectile-visual-effects-900bey6t).
- A VFX Apprentice descreve o arco como wind-up (sinaliza o que vem), clímax (o estouro) e fall-off (a queda depois do evento). Efeitos instantâneos pulam o wind-up, mas ainda podem dissipar com graça — [VFX Apprentice, Timing](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx).
- O curso FX Timing Principles (Dan Elder) trata número de quadros, easing, antecipação, impulso e ritmo, follow-through, arcos, stretch e smear. Não cita projétil nem define fases — [VFX Apprentice, curso](https://www.vfxapprentice.com/courses/fx-timing-principles).
- Estudo de caso de um efeito no estilo World of Warcraft (concurso de estudantes): buildup, voo e impacto foram trabalhados separadamente, e a crítica pediu partículas que permanecem para ligar as fases; o tempo de vida de algumas foi aumentado para que as fases se sobrepusessem — [RealtimeVFX, Trevor McTavish](https://realtimevfx.com/t/trevor-mctavish-wow-student-art-contest/3843).

**Durações publicadas (exemplos, não regras)**

| Peça | Valor | Fonte |
|---|---|---|
| Cone do muzzle | vida de 0,2 s; some logo após surgir | [Kodeco p. 2 (busca)](https://www.kodeco.com/23120977-vfx-in-unity-getting-started?page=2) |
| Cauda do projétil | vida de 0,1–0,6 s; 200 partículas/s | [Kodeco p. 3](https://www.kodeco.com/23120977-vfx-in-unity-getting-started?page=3) |
| Cauda da bola de fogo | vida de 0,1–0,3 s; 50 partículas/s | [Kodeco p. 3](https://www.kodeco.com/23120977-vfx-in-unity-getting-started?page=3) |
| HIT (flash do impacto) | 0,075–0,125 s; cresce de um ponto até 5x | [Unreal Wiki](https://unrealcommunity.wiki/projectile-visual-effects-900bey6t) |
| DUST (poeira do impacto) | 0,125–0,25 s; 10–20 partículas | [Unreal Wiki](https://unrealcommunity.wiki/projectile-visual-effects-900bey6t) |
| DEBRIS (cacos) | 1–2 s, com gravidade e colisão | [Unreal Wiki](https://unrealcommunity.wiki/projectile-visual-effects-900bey6t) |
| Conjuração no WoW | 4 s foi julgado longo demais para o jogo | [RealtimeVFX](https://realtimevfx.com/t/trevor-mctavish-wow-student-art-contest/3843) |

- O gráfico de exemplo da VFX Apprentice vai de 0 a 48 quadros, mas o artigo **não dá** contagem recomendada nem proporção. Ele cita o princípio "Big, Medium, Small" só em termos de intensidade — [VFX Apprentice](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx).
- Em jogos competitivos o tempo do efeito pode estar preso ao momento do dano, limitando wind-up e fall-off — [VFX Apprentice](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx).
- Ritmo tem leitura emocional: mais rápido que cerca de 60 BPM lê como agressivo, mais lento combina com cura e efeitos positivos — [VFX Apprentice](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx).
- Contexto do projeto: o protocolo registra que o tiro cruza o campo em cerca de 0,3 s — `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md` §6.

**Fonte descartada:** listagens de "skills" de IA (por exemplo [playbooks.com](https://playbooks.com/skills/dylantarre/animation-principles/timing-mastery), busca) trazem números como "2 quadros de contato, 12+ de acomodação" e "80% do impacto é antes do contato". Não têm origem citada; **não usar como evidência**.

### Inferências
- Mapa provisório entre as fases de D-955 e a anatomia profissional (Start segue ambíguo em D-955 e precisa da resposta do criador):

| Fase D-955 | Equivalente nas fontes | Arco de intensidade |
|---|---|---|
| Start | sem equivalente direto; talvez o primeiro sinal do wind-up | preparo |
| Wind-up | antecipação, buildup | preparo |
| Release | muzzle, flash | primeiro pico |
| Trajectory | cabeça + cauda | sustentação |
| Impact | HIT + DUST + DEBRIS | pico principal |
| Post-impact | aftermath, resíduo | queda |

- O padrão das durações sugere uma assimetria dentro do impacto: flash muito curto, poeira curta, detritos longos. Isso é leitura minha de poucos exemplos, de jogos diferentes, um deles com bala realista.
- Os tempos da biblioteca não devem vir destas tabelas: D-019 põe a lógica como dona da linha do tempo e o protocolo manda medir a duração real de cada fase no jogo.
- A sobreposição entre fases no caso WoW é compatível com a "transição contínua" que o protocolo já exige.

### Lacunas
- Nenhuma proporção por fase de Riot, Blizzard, miHoYo, Atlus ou outro estúdio foi encontrada em texto. A palestra GDC 2017 pode tratá-lo ("Timing & Threat Level" aparece como tópico em [notas de terceiros (busca)](https://3dreference.notion.site/Visual-Effects-Bootcamp-Artistic-Principles-of-VFX-GDC-2017-fcd0698c31cf4621a70ed8a7621e17da)), mas não assisti ao vídeo.

## O que é compartilhado entre elementos e o que é por elemento? Existe template mestre com módulos trocados?

### Conclusão
A troca modular está **publicamente documentada em packs comerciais e em engines**, não em relatos de estúdios. Não achei nenhum caso publicado de "template mestre de projétil por elemento" em Riot, Blizzard, miHoYo ou Atlus. A divisão compartilhado/por elemento abaixo é inferência minha, apoiada nesse padrão modular.

### Achados citados
- **ImpactFX (Fab):** cada sistema Niagara é modular, com emissores que podem ser ligados, desligados, trocados ou alterados; cada superfície tem seu pacote (sistema, materiais) — [Fab, ImpactFX](https://www.fab.com/listings/bb998011-83bf-41d2-aac1-2445830bfaad). O autor afirma que Emitters e Systems são separados, de modo que mudar o comportamento das faíscas exige editar um único emissor — [fórum Unreal (busca)](https://forums.unrealengine.com/t/bklleb-digital-store-impactfx-ballistic-vfx/2732749).
- **Muzzle Master:** 16 muzzle flashes Niagara cujos módulos podem ser trocados para criar novos — [Unreal Marketplace (busca)](https://www.unrealengine.com/marketplace/en-US/product/muzzle-master-modular-muzzleflashes).
- **Niagara:** criar um sistema a partir de um emissor existente herda dele; a partir de um template, não herda. Um sistema reúne vários emissores — [UE 4.27 docs (busca)](https://docs.unrealengine.com/4.27/RenderingAndGraphics/Niagara/Overview). É doc de 4.27, não verifiquei a versão atual.
- **Módulos ligados:** o guia Cascade recomenda ligar módulos idênticos entre emissores, mantendo valores em sincronia, e reaproveitar o mesmo módulo de forma de spawn em DUST e DEBRIS — [Unreal Wiki](https://unrealcommunity.wiki/projectile-visual-effects-900bey6t).
- **Custo de editor:** thread sobre impactos alternados por booleanos indica que muitos emissores num sistema deixam o editor mais lento — [RealtimeVFX (busca)](https://realtimevfx.com/t/does-the-number-of-emitters-in-a-niagara-system-affect-performance/22447).
- **Separação de comportamento e partículas:** um integrador de terceiros extraiu Hit e Flash dos prefabs do Hovl para objetos próprios, reutilizáveis entre projéteis, removendo também os scripts de movimento; o comportamento passa a ser de outro sistema — [Infinity PBR](https://infinitypbr.gitbook.io/infinity-pbr/projectile-factory/3rd-party-particle-integrations-16/hovl-studio-4/toon-projectiles-2).
- **Riot:** o guia de estilo diz que VFX deve comunicar espaço de jogo, poder e função, sem distrair — [Riot, resumo da busca](https://nexus.leagueoflegends.com/en-us/2017/10/dev-leagues-vfx-style-guide/) (a página agora redireciona para a home; não consegui ler o texto).
- **Palestra Riot/Blizzard:** cobre fundamentos adaptáveis a qualquer gênero ou estilo, com casos de League of Legends e Hearthstone — [GDC Vault](https://www.gdcvault.com/play/1024439/Visual-Effects-Bootcamp-Artistic-Principles). Não encontrei confirmação de que trate de templates.
- **Pixel Dreamer (Godot):** cada efeito é uma `.tscn`; há um helper para instanciar, escalar, inclinar e mirar, e `set_intensity()` — [fórum Godot](https://forum.godotengine.org/t/1-187-vfx-for-godot-4-drag-and-drop-presets-effect-browser-free-web-demo/146113). Afirmação do vendedor.
- **Contexto do projeto:** D-954 põe o Composer só no secundário; o protocolo D-308 diz que todo VFX de Move é sobre o Composer. D-955 registra esse conflito como aberto.

### Inferências
Hipótese de estrutura única, para o criador avaliar:

| Compartilhado (o "esqueleto") | Por elemento (a "pele e o gesto") |
|---|---|
| Lista de fases e os eventos que as ligam | Silhueta da cabeça |
| Entradas: atacante, alvo, eixo, câmera, relógios (D-235, D-019) | Linguagem de movimento (flui, estala, pesa, ondula) |
| Slots por fase: flash, cabeça, cauda, hit, resíduo | Textura, flipbook e malha de cada slot |
| Regra de escala na tela e os tiers | Paleta e contraste de valor |
| Regras de limpeza (nada sobra) e orçamento | Fim do resíduo: sobe, cai, fica, some |
| Ponto de entrada para múltiplos alvos | Curvas de tempo próprias dentro da fase |

- **O risco principal é a homogeneização.** Trocar apenas cor sobre o mesmo movimento produz o "genérico" que o projeto já reprovou (`PLANO_PIPELINE_VFX.md` §2). Movimento e silhueta deveriam ficar na coluna por elemento, e não apenas material.
- Faz sentido permitir que um elemento deixe um slot vazio: slot obrigatório levaria a camadas sem função, o erro da V1 melee de 31 camadas.
- A separação do Hovl/Infinity PBR (partículas num lado, comportamento noutro) é análoga à regra do protocolo de que a classe do Move só entrega posições e relógios.

### Lacunas
- Atlus e miHoYo: duas buscas não retornaram material técnico sobre VFX. A de miHoYo só retornou conteúdo de gameplay.
- Currículo da VFX Apprentice específico de projéteis: não verifiquei; o curso de timing aberto não trata do tema.
- **Conteúdo a assistir depois** (listado em [RealtimeVFX](https://realtimevfx.com/t/useful-free-gdc-talks/219), não assisti): [Artistic Principles of VFX](https://youtu.be/-L2JvngkkWw), [The VFX of Diablo III](https://www.youtube.com/watch?v=YPy2hytwDLM), [inFAMOUS: Second Son](http://www.gdcvault.com/play/1020751/The-Visual-Effects-of-inFAMOUS). Também [análise JangaFX dos métodos do Diablo 3 (busca)](https://jangafx.com/insights/diablo-3-vfx-experiments) e [Attention Overload (Suicide Squad), GDC (busca)](https://gdcvault.com/play/1034360/Attention-Overload-Creating-Readable-VFX).

## Como packs comerciais se organizam, e quais as licenças?

### Conclusão
O padrão de mercado é a tríade **muzzle/flash + projétil + hit/impact**, às vezes com nomes diferentes. As licenças de loja permitem embutir em jogo, mas não redistribuir o asset isolado; para Crawlmon, o uso prudente é **material de estudo**, já que quase tudo é Unity/Unreal e depende de sistemas que o projeto não usa.

### Achados citados

| Pack | Organização observada | Formato e licença | Fonte |
|---|---|---|---|
| **Toon Projectiles 2** (Hovl Studio) | peças Hit e Flash + projétil, segundo um integrador; a descrição veio vazia na página da loja | Unity; Standard EULA, Extension Asset; US$ 25; v2.1.0; exige pacote de suporte de US$ 5 | [Asset Store](https://assetstore-fallback.unity.com/packages/vfx/particles/spells/toon-projectiles-2-184946); [Infinity PBR](https://infinitypbr.gitbook.io/infinity-pbr/projectile-factory/3rd-party-particle-integrations-16/hovl-studio-4/toon-projectiles-2) |
| **Stylized Toon Projectiles & Hits Vol. 3** (Piloto Studio) | 31 projéteis, cada um com muzzle flash e impacto próprios, em pastas por tipo (busca); palavras-chave muzzle/projectile/hit (aberta) | Unity; Standard EULA, Extension Asset; US$ 15 | [Asset Store](https://assetstore.unity.com/packages/vfx/particles/spells/stylized-toon-projectiles-hits-volume-3-242500) |
| **Epic Toon FX** (Archanor VFX) | 1.323 efeitos (busca); uma resenha cita três categorias, Combat, Environment, Interactive ([80.lv, busca](https://80.lv/articles/5-vfx-packs-for-stylized-unity-projects), atribuição incerta) | Unity; Standard EULA; US$ 40; v1.82; sem HDRP | [Marketplace Unity](https://marketplace.unity.com/packages/vfx/particles/epic-toon-fx-57772) |
| **Niagara Ray VFX Pack** (Fateloom) | 5 conjuntos, 15 efeitos; cada conjunto tem Energy, Ray, Hit (o título ainda cita "Muzzle, Projectile, Hit") | Unreal; termos da licença não aparecem na listagem | [Fab](https://www.fab.com/listings/d9832f0c-e428-4447-b24e-97eae0a13a9a) |
| **ImpactFX** (Bklleb) | só impactos, por superfície; 46 sistemas e emissores; 12 materiais mestres, 70 instâncias | Unreal; termos não aparecem na listagem | [Fab](https://www.fab.com/listings/bb998011-83bf-41d2-aac1-2445830bfaad) |
| **Pixel Dreamer VFX** | 1.187 efeitos em 39 packs, entre eles projectiles, arcane, holy, dark, water; `.tscn` com `play()` | Godot 4.7; vendedor afirma testes em Forward+, Mobile e Compatibility (web); **licença não citada no post** | [fórum Godot](https://forum.godotengine.org/t/1-187-vfx-for-godot-4-drag-and-drop-presets-effect-browser-free-web-demo/146113) |

- A contagem do Pixel Dreamer varia entre listagens (566, 944, 1.187) — [resultado de busca (566)](https://forum.godotengine.org/t/566-vfx-for-godot-4-drag-and-drop-presets-effect-browser-free-web-demo/146113).
- **Licença Unity:** um Extension Asset pode ser embutido em um produto se não for parte substancial dele; não pode ser redistribuído isolado; o assento é limitado a 2 computadores. O trecho lido **não diz nada** sobre uso em outras engines — [Unity Asset Store EULA](https://unity.com/legal/as-terms).
- **Licença Fab:** permite uso com "compatible tools", sem limitação ao Unreal, e proíbe revenda ou redistribuição isolada; "compatible tools" não é definido; há também a opção Reference-Only — [Fab EULA](https://www.fab.com/eula).
- O `FERRAMENTAS_INSTALADAS.md` registra Vefects e FULGUR como "Forward+ recommended" e o Pixel Dreamer como pago.

### Inferências
- Packs Unity/Unreal têm pouco valor técnico direto aqui: dependem de Shuriken, VFX Graph ou Niagara e de pós-processamento. O valor é ver o **vídeo** quadro a quadro: silhueta, timing, peças. Isso é consistente com a regra do projeto de testar à parte e não instalar pago sem decisão.
- "Muzzle, projétil, hit" como três assets independentes permitem misturar impacto de um com projétil de outro. A biblioteca poderia herdar essa propriedade se cada fase for peça independente; pack nenhum que vi trata Start, Wind-up ou Post-impact como peça nomeada, então **as seis fases de D-955 vão além do padrão de mercado** (observação limitada às páginas lidas).
- Nomes de arquivo por fase e elemento seriam fáceis de procurar, mas não encontrei convenção publicada de nomes que valha copiar.

### Lacunas
- **Vefects:** a busca não retornou nenhuma listagem dele; organização e licença não verificadas nesta pesquisa.
- As páginas de Hovl e Epic Toon FX vieram sem a seção de conteúdo; lista exata de prefabs e nomes não confirmados. Só comprando ou por vídeo.
- Termos individuais de Fateloom e Bklleb: não aparecem na página, apesar da EULA geral do Fab.
- Licença do Pixel Dreamer: verificar na página de venda ou no arquivo do pacote antes de qualquer decisão.

## Múltiplos alvos: como reutilizar um projétil, e com que custo como placeholder?

### Conclusão
As fontes encontradas descrevem as **regras** de chain, split e fork; o lado visual quase não está documentado. Antes de escolher forma é preciso a resposta do criador: as decisões do projeto já definem AoE de projétil como **onda única** (D-009), e D-955 mantém a forma em aberto.

### Achados citados
- **Chain:** um projétil não salta para alvo já atingido, e isso vale para todos os projéteis de um mesmo uso — [PoE Wiki, Chain (busca)](https://www.poewiki.net/wiki/Chain).
- **Prioridade:** split, pierce e fork vêm antes de chain, pois só um comportamento acontece por colisão — [PoE Wiki, Chain (busca)](https://www.poewiki.net/wiki/Chain).
- **Implementação em toolset:** chain lightning estilo Baldur's Gate = projétil de alvo único + subfeitiço de área que ignora quem tem uma marca de estado, repetido até 11 vezes — [Beamdog (busca)](https://forums.beamdog.com/discussion/comment/1117142).
- **Divisão de área:** bola de fogo que cria um objeto invisível, e este dispara projéteis em alvos próximos — [Neverwinter Vault (busca)](https://forum.neverwintervault.org/t/fireball-script-split-into-small-projectiles/7824).
- **SMT (referência de D-118):** o prefixo Mara- marca a variante em todos os inimigos: Agi/Agilao/Agidyne contra Maragi/Maragion/Maragidyne — [Samurai Gamers, Nocturne (busca)](https://samurai-gamers.com/shin-megami-tensei-iii-nocturne-hd-remaster/magic-skills/); [Game8, SMT V (busca)](https://game8.co/games/Shin-Megami-Tensei-V/archives/351183). Isso mostra a família de skills, **não** como o VFX é feito.
- **Projeto:** D-009 (onda única, cada alvo atingido no seu tempo), D-057 (velocidade espacial constante), D-077 (geometria por Move), D-059/D-075 (janela de Evade compartilhada) — índice `docs/decisoes/README.md`.

### Inferências
Comparação das formas para uso como placeholder (raciocínio meu, sem fonte):

| Forma | Reaproveita | Ganho | Custo ou risco |
|---|---|---|---|
| **N cópias (fan/volley)** | tudo, uma instância por alvo | barato de fazer; cada cópia leva a um alvo | custo x N; ruído na tela; pode ler como vários golpes, o que pode destoar de D-009 |
| **Split** | cabeça única + filhas | uma origem clara | exige ponto de divisão, e isso é coreografia nova |
| **Chain** | N segmentos em sequência | leitura forte em raio | **implica ordem entre alvos**; destoa de "ao mesmo tempo" (D-007), usar só com decisão explícita |
| **Onda** | impacto por alvo + frente nova | casa com D-009 e D-057 | a frente é peça nova, não existe no projétil simples |

- **Para qualquer forma:** como o impacto é peça separada (padrão visto nos packs), ele pode ser disparado por alvo no tempo de cada um. É a parte mais reaproveitável, com qualquer das formas.
- **Risco de placeholder:** forma que comunica outra regra. Um placeholder em chain, por exemplo, faria o jogo parecer ter regra que ele não tem. Vale escolher pelo que combina com D-009 **e registrar a resposta do criador**; aqui não faço essa escolha.
- Custo multiplicado por N num jogo com CPU e malhas sugere, ao menos para o placeholder, um tier reduzido por cópia, mas isso depende de medição.

### Lacunas
- Não encontrei fonte sobre o lado visual: atraso escalonado, arcos entre alvos, reciclagem de objetos.
- Comportamento de Pokémon em golpes de área: Bulbapedia bloqueou (403), então não foi verificado.

## Leitura à distância e tiers: como fazer pequeno, médio e grande sem reconstruir?

### Conclusão
Há bom apoio para o princípio (silhueta e contraste antes de detalhe, intensidade como eixo), mas não encontrei um método publicado de tiers. Na câmera do projeto, o mesmo objeto em metros varia cerca de **4,6x na tela** entre 8 m e 37 m; é um fator que precisa de regra própria, separada do tier. Essa regra depende de um conflito aberto em D-955 (D-308 item 6 / D-334).

### Achados citados
- Malha de projétil abandonada por silhueta ruim: rápida demais para ser reconhecida. Sugestões da crítica: brilho de borda, formar a malha no buildup, movimento que leve o olho à cabeça — [RealtimeVFX](https://realtimevfx.com/t/trevor-mctavish-wow-student-art-contest/3843).
- **Popcorning:** partículas soltas pelo projétil se separam e ficam visíveis uma a uma; corrigir exigiria muitas partículas, com overdraw excessivo, e o trabalho passou a focar em fita e em cortes de ponta — [RealtimeVFX](https://realtimevfx.com/t/trevor-mctavish-wow-student-art-contest/3843).
- Tópicos da palestra GDC 2017: Shape & Area of Effect, Contrast & Focal Point, Color & Identity, Timing & Threat Level — [notas de terceiros (busca)](https://3dreference.notion.site/Visual-Effects-Bootcamp-Artistic-Principles-of-VFX-GDC-2017-fcd0698c31cf4621a70ed8a7621e17da).
- "Big, Medium, Small" tratado como intensidade; picos podem ser quadros claros, ou muitos emissores juntos — [VFX Apprentice](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx).
- Mais elementos permitem timing mais rico, mas aumentam o risco de dissonância — [VFX Apprentice](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx).
- Pixel Dreamer expõe `set_intensity()` e diz que seu helper corrige o fato de partículas do Godot ignorarem a escala do nó por padrão (afirmação do vendedor; não verifiquei) — [fórum Godot](https://forum.godotengine.org/t/1-187-vfx-for-godot-4-drag-and-drop-presets-effect-browser-free-web-demo/146113).
- SMT dá nomes a tiers (leve, médio, pesado) e os valores variam por jogo: no SMT original, Agi 23, Agilao 64, Maragi 19, Maragion 50 — [Almar's Guides (busca)](https://almarsguides.com/retro/walkthroughs/snes/games/shinmegamitensei/misc/lists/spells/).
- Godot 4.7: `instance uniform` existe em `spatial` e `canvas_item`, é definido por `GeometryInstance3D`, aceita só escalares e vetores, com máximo prático de 16 por shader. Em GLSL 3.3 ou inferior (caso do Compatibility) um array de texturas não pode ser indexado por uniform por instância; a doc sugere `switch` — [Shading language, docs 4.7](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/shading_language.html).
- O protocolo já registra: "tamanho em metros fixo fica invisível" a cerca de 37 m; e fitas viradas para a câmera somem quando o tiro vai direto para longe — `PROTOCOLO_VFX_OBRIGATORIO.md` §6.

### Inferências
- 37 m / 8 m ≈ 4,6: em perspectiva, o tamanho aparente é inversamente proporcional à distância. Portanto **tier** (quanto poder) e **compensação de distância** (quanto ocupa a tela) deveriam ser dois parâmetros independentes. Misturá-los faria um tiro grande distante parecer um pequeno próximo. Se a compensação for permitida depende da resposta sobre D-308 item 6 / D-334.
- Eixos que parecem escalar sem reconstruir, em ordem de custo crescente: tempo do pico e duração; escala; opacidade e brilho; contagem por slot; ativar slots extras só nos tiers maiores (por exemplo anel de choque). A silhueta deve se manter para o elemento continuar reconhecível.
- Evitar tier = "mais partículas" apenas: popcorning e overdraw pioram, e detalhes se perdem a 37 m de qualquer modo. Uma malha ou flipbook grande tende a ler melhor à distância que muitas partículas pequenas (hipótese a medir na batalha real).
- A definição de "Move poderoso" está pendente (D-308 item 7); tier é hipótese de biblioteca, não regra.

### Lacunas
- Não há dado público de tamanho mínimo em pixels ou porcentagem de tela para leitura de projéteis. Teria de ser medido no próprio jogo.
- Medium (Mighty Bear, sobre UX e VFX) estava bloqueado.

## Godot 4.7 gl_compatibility: o que existe, o que falta, e que técnicas sustentam VFX cel-shaded?

### Conclusão
**Atenção a uma imprecisão nos documentos do projeto:** GPUParticles3D **funciona** em Compatibility na 4.7. Os indisponíveis no motor são trails de partícula, sub-emitters, `emit_particle()`, decals e colisão SDF 3D. Não usar GPUParticles é decisão do projeto (D-308/protocolo), não limite do motor. **Glow também existe** em Compatibility desde a 4.3; sua ausência no jogo é decisão de direção (`PLANO_PIPELINE_VFX.md` cita D-337), e não incapacidade. Malhas, flipbooks, shaders com textura e CPUParticles cobrem bem o estilo pedido.

### Achados citados

| Recurso | Compatibility | Versão | Fonte |
|---|---|---|---|
| GPUParticles3D (simulação) | funciona, por transform feedback | 4.7-stable | [código gles3](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/drivers/gles3/storage/particles_storage.cpp) |
| Trails de partícula | **não**; apenas aviso, sem dado de trail | docs 4.7 + 4.7-stable | [Trails](https://docs.godotengine.org/en/stable/tutorials/3d/particles/trails.html); [código](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/drivers/gles3/storage/particles_storage.cpp) |
| Sub-emitters | **não**; no-op com aviso. A página de sub-emitters **não** menciona esse limite | 4.7-stable | [código](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/drivers/gles3/storage/particles_storage.cpp); [Sub-emitters](https://docs.godotengine.org/en/stable/tutorials/3d/particles/subemitters.html) |
| `emit_particle()` | **não** | docs 4.7 | [GPUParticles3D](https://docs.godotengine.org/en/stable/classes/class_gpuparticles3d.html) |
| Colisão SDF 3D, atratores vector field | **não**; esfera, caixa e um heightfield funcionam | docs 4.7 + 4.7-stable | [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html); [código](https://raw.githubusercontent.com/godotengine/godot/4.7-stable/drivers/gles3/storage/particles_storage.cpp) |
| CPUParticles3D | existe; aceita malha por partícula; lê cor por `COLOR` em shader | docs 4.7 | [CPUParticles3D](https://docs.godotengine.org/en/stable/classes/class_cpuparticles3d.html) |
| Decals | **não** na 4.7; **sim em 4.8 dev 4** (teto suave de 64, 8 por superfície) | 4.7 / 4.8-dev | [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html); [4.8 dev 4](https://godotengine.org/article/dev-snapshot-godot-4-8-dev-4/) |
| Screen texture, depth texture | sim | docs 4.7 | [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) |
| Normal-roughness texture | **não** (só Forward+) | docs 4.7 | [Screen-reading](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html) |
| Glow | sim, implementação própria: Levels, Normalized, Strength, Blend Mode, Mix, Map, Map Strength ocultos | desde 4.3; docs 4.7 | [PR #87360](https://github.com/godotengine/godot/pull/87360); [Env e pós](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html); [4.3](https://godotengine.org/releases/4.3/) |
| Tonemapping, MSAA 3D, SSAO simplificado | sim (SSAO simplificado desde 4.6) | docs 4.7 | [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html); [Env e pós](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html) |
| HDR output, 2D HDR Viewport | **não** | docs 4.7 | [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) |
| Luzes | 8 omni e 8 spot por malha (pode aumentar) | docs 4.7 | [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html) |

- **Screen texture em 3D:** é capturada uma vez, depois do pass opaco e antes do transparente. Transparentes não aparecem nela; material que a usa é tratado como transparente. Depth precisa de conversão pela matriz inversa de projeção — [Screen-reading, docs 4.7](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html).
- **Refração:** efeito de tela, força transparência; não refrata sobre si nem sobre outros transparentes; não vê fora da tela — [StandardMaterial3D, docs 4.7](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).
- **Billboard Particle e Particles Anim** são a via do material para flipbook; Proximity Fade dá soft particles (mas com alpha blending caro e possíveis problemas de ordenação); a página não lista limite de Compatibility nesses itens — [StandardMaterial3D, docs 4.7](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).
- **Stencil:** existe desde a 4.5 (Outline, X-Ray, Custom); a escrita ocorre no pass transparente — [StandardMaterial3D, docs 4.7](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html).
- **Trail3D:** nó nativo anunciado em 4.8 dev 4 (26 ago 2026); o anúncio **não diz** quais renderers suporta; é snapshot de desenvolvimento, não 4.7 — [Godot blog](https://godotengine.org/article/dev-snapshot-godot-4-8-dev-4/).
- **Notas 4.7:** o texto da versão fala de ajuste de escala e rotação de partículas 3D e HDR output; não cita trails nem decals para Compatibility — [Godot 4.7](https://godotengine.org/releases/4.7/).
- **Como o glow funciona:** dual filtering, aplicado ao final por blend simples; aceita bloom e HDR threshold; sem HDR o buffer é RGB10A2 com multiplicador de luminância em sRGB; depois o cálculo voltou a `max(r,g,b)` (#88612) — [PR #87360](https://github.com/godotengine/godot/pull/87360).

**Fontes que divergem (não resolvi):**
- Formato de cor: a tabela de renderers de 4.7 diz RGBA8 LDR; o PR de 2024 fala em RGB10A2 sem HDR. Pode ser mudança ou diferença de descrição.
- 2D HDR: o PR de 4.3 descreve RGBA16F em Compatibility com essa opção; a tabela de 4.7 diz "não suportado".
- `FERRAMENTAS_INSTALADAS.md` diz "não contar com GPUParticles", formulação de prudência; o motor os roda na 4.7, com os limites acima.

**Referências Godot abertas e licenças**

| Referência | Licença | Observação | Fonte |
|---|---|---|---|
| TrailRenderer (Hyrdaboo) | MIT | já instalado; asset lista Godot 4.2 | [Asset Library (busca)](https://godotengine.org/asset-library/asset/2615) |
| GPUTrail (celyk) | MIT | feito sobre GPUParticles3D, fora do pipeline atual | [resultado de busca](https://gh.r-mj.com/celyk/GPUTrail) |
| GDQuest godot-4-VFX-assets | **código MIT; arte CC-BY-NC-SA 4.0 (não comercial)** | a arte não pode ir para produto comercial | [GitHub](https://www.github.com/gdquest-demos/godot-4-VFX-assets) |
| GDQuest godot-shaders | MIT (código), CC-BY 4.0 (arte) segundo busca; a página aberta não nomeia licença, ver LICENSE | em porte para Godot 4: dissolve, shockwave, stylized fire, force field; verificar | [GitHub](https://github.com/GDQuest/godot-shaders) |
| Stylized fire (3D), godotshaders | MIT | ruído panorâmico + máscara + emissivo, sem depth nem screen; usa built-ins de Godot 3, e há um porte para 4.0.1 nos comentários | [Godot Shaders](https://godotshaders.com/shader/stylized-fire-3d/) |
| Stylized 2D VFX Lite (REEBO Labs) | MIT | hit_spark, slash_arc, explosion_small; declara Compatibility; **2D** | [Asset Library](https://godotengine.org/asset-library/asset/5564) |
| Godot Shaders em geral | CC0, MIT ou GPLv3, **escolhida por shader**; cobre só o código, não imagens nem vídeos | checar cada um; evitar misturar GPLv3 sem pensar | [Licença](https://godotshaders.com/license/) |
| Binbun Fire VFX | listada como CC0, pago | outro pack do autor é declarado para Forward+/Mobile; verificar | [itch.io (busca)](https://binbun3d.itch.io/fire); [Effects Vol. 1 (busca)](https://binbun3d.itch.io/effects-collection-vol1) |

### Inferências
Técnicas que parecem sustentar VFX estilizado com esses limites:

- **Malhas com shader de textura panorâmica** para cabeça, cone, anel, coroa: silhueta forte, sem depender de partícula; o caso do `stylized fire` mostra que a técnica não exige depth nem screen.
- **Rampa de cor e corte duro** (threshold em ruído) para formas de bordas limpas, afinadas ao cel-shading, em vez de gradiente suave.
- **Flipbooks** em quads para explosão, fumaça e flash; independem do renderer (o `FERRAMENTAS_INSTALADAS.md` já observa isso).
- **Rastro por malha gerada** (TrailRenderer, `MotionMesh.tube` do projeto), como substituto de trail de partícula. Trail3D de 4.8 é só para acompanhar, não planejar.
- **Marca no chão por quad ou malha plana** (`mark`), já que decal só chega em 4.8-dev.
- **Burst na fase de impacto por gatilho de código**, trocando sub-emitters e `emit_particle()` por vários emissores `one_shot` ou por representações do Composer.
- **"Bloom falso" local:** quads aditivos ou halo por trás da cabeça; dá leitura sem glow de cena inteira, que o plano do projeto só admite como decisão de cena inteira.
- **Distorção por screen texture é viável com ressalvas:** só vê opacos, então uma onda de choque não distorce outro VFX transparente. Custo em GL Compatibility precisa ser medido.
- **Variação por instância:** uniforms por instância para intensidade, fase e cor; **texturas não**, que exigem material próprio ou `switch`. Medir como isso interage com CPUParticles (não documentado no trecho lido).
- Com 8 luzes por malha, pulso de luz por impacto em muitos alvos simultâneos exige orçamento.

### Lacunas
- **Não testei nada em Godot** (a pesquisa não autorizava). Proximity Fade, stencil, distorção e instance uniform em CPUParticles sob Compatibility, inclusive custo, seguem sem verificação prática.
- A doc da página de CPUParticles3D não confirma colisão, atratores nem trails; não usei isso como prova de ausência.
- Flipbook em CPUParticles3D: a ligação de `PARAM_ANIM_*` com folha de sprites é inferência; a página não a descreve.
- Estado final da 4.8: só vi o dev 4. Não sei se Trail3D funcionará em Compatibility.

### Fontes bloqueadas ou incompletas (toda a pesquisa)
- **Riot "VFX Style Guide"** (nexus.leagueoflegends.com): redireciona para a home; só tenho o resumo de busca.
- **web.archive.org:** a ferramenta não consegue acessar; tentativa de rever o texto da Riot falhou.
- **Notion com notas da GDC 2017:** retornou página vazia ("Notion"); só tenho o resumo de busca.
- **GDC Vault:** vídeo restrito a membros; só li a descrição.
- **YouTube:** links citados a partir de listagem; **não assisti a nenhum vídeo**.
- **Bulbapedia** (403), **Medium/Mighty Bear** (403), **docs.unrealengine.com/marketplace, Magic Projectiles Mega Pack** (403).
- **Asset Store / Marketplace Unity:** as páginas de Hovl, Piloto e Epic Toon vieram sem a descrição completa.
- **Fab:** listagens abertas, com "License terms" vazio; usei a EULA geral.
- Regra do projeto citada a partir do índice ou dos resumos dos documentos pedidos; **não reli todos os `D-*.md`** um a um nesta tarefa de pesquisa, apenas D-955 e o índice (parcial, até a linha 233 de 300). As menções a D-308 item 6/7, D-334 e D-337 vêm de D-955 e do plano.
