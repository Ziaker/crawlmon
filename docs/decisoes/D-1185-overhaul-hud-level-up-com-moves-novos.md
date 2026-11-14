# D-1185 — Overhaul do HUD de level up, já com o ganho de Moves novos (proposta em protótipo)

- **Data:** 2026-11-12.
- **Área:** Combate / pós-combate / UI / progressão.
- **Relacionadas:** D-1184 (VictoryPanel simples volta), D-433 (Level Up HUD; port rejeitado, §5), D-400, D-401, D-402, D-399, R27-Q4 (nível é a fonte principal de Moves), R38-Q5 (até 8 Moves, 4 em atalho), D-417 (fichas de Move), D-1079 (`learnset` no `CharacterLoadout`).
- **Status:** **pedido registrado; protótipo HTML (`prototypes/level_up_overhaul.html`) para aprovação; nenhum código do jogo alterado.** A mecânica de aprender Move está como **proposta do assistente**, não como regra.

## O que o criador disse (literal)

> sim e vamos começar a fazer o overhaul do hud de Level-up, inclusive já levando em conta a mecânica de ganho de moves novos

Perguntado se queria responder perguntas de design antes:

> pule

## Decisão

1. O overhaul parte do `VictoryPanel` simples (D-1184) e cobre o pós-combate inteiro: XP, level up, pontos e **Move novo**.
2. O primeiro passo é um **protótipo HTML em 1280×720** para o criador aprovar. Só depois vem o Godot.
3. **Restrição técnica por causa da D-433 §5:** o protótipo só usa o que o Godot reproduz igual — paralelogramos **só como fundo** (polígono desenhado), **texto sempre reto**, sem `skew` em texto, fontes legíveis em 1280×720.

## Propostas do assistente (NÃO aprovadas; o criador pulou as perguntas)

- **Ordem:** XP de todos ao mesmo tempo → level up de cada um → pontos do líder (D-401, obrigatório) e pontos automáticos do aliado com o motivo → Move novo → voltar ao mapa.
- **Move novo com vaga livre (menos de 8):** aprende sozinho e entra na próxima vaga.
- **Move novo com as 8 vagas cheias:** escolher um Move para esquecer, ou recusar o novo (com confirmação).
- **Aliados:** aprendem do mesmo jeito; a escolha de esquecer também é do jogador.
- **Fonte:** `learnset` (nível → Moves) do `CharacterLoadout`, hoje vazio; os Moves e níveis do protótipo são exemplos.

## Em aberto

Tudo da lista de propostas; se Moves aprendidos entram nos 4 atalhos; se dá para reaprender um Move esquecido; quais Moves cada espécie aprende e em que nível.

## Rodada 2 — animações de entrada (2026-11-12)

> eu adicionaria animações de entrada nos blocos

- O criador não disse o estilo; o protótipo ganhou **3 opções selecionáveis** para ele escolher (Deslizar, Pop, Cair) e "Nenhuma" para comparar. Cada bloco entra em sequência (atraso escalonado); a barra de XP só começa a encher depois que os cards entram.
- Todas usam só posição, escala e opacidade, que viram `Tween` no Godot.
- **Em aberto:** qual estilo; se vale para todas as etapas ou só para algumas.

## Rodada 3 — visual mais estilizado (2026-11-12)

> queria que o visual fosse mais estilizado, com angulos tortos e com os icones dos moves presentes nos cards dos moves, como é no jogo, servindo de marca d'gua

- **Ângulos tortos:** cada bloco ganha uma rotação pequena própria (como a Status Screen e a D-1097/D-1178), com sombra dura deslocada. Girar o bloco inteiro (texto junto) é nativo no Godot (`Control.rotation`); continua proibido inclinar só o texto (D-433 §5).
- **Ícones nos cards de Move, como no jogo:** glifo do elemento (`assets/ui/icons/elements/*.svg`) como **marca d'água** translúcida (D-416/D-417), tile do elemento à esquerda nos cards pequenos (como a faixa de skills da Status Screen), badges de tipo (`move_types`) e alcance (`range`), e ATB/MP/POWER em paralelogramos.
- Referência visual: `docs/referencias/exploracao/3d/d1165_status_hud_abra_megido.png`.

## Rodada 4 — cor própria para cada stat (2026-11-12)

> dê cores diferentes para cada stat

- O jogo não tem cores de stat definidas (procurei em `scripts/ui/`); as cores do protótipo são **escolha do assistente**, tiradas da paleta do jogo: STR coral `#ff746c`, MAG lilás `#b5a5fe`, VIT verde `#7ee081`, WIS aqua `#63d9ec`, AGI dourado `#f0c57e`, LUK lima `#d6fa66`; HP MÁX e MP MÁX usam as cores das barras de HP `#e96159` e MP `#38bdf8` do HUD.
- A cor vai no nome do stat e numa faixa paralelogramo à esquerda da linha.
- **Em aberto:** aprovação das cores; se elas passam a valer também na Status Screen.

## Rodada 5 — botão de confirmar e animação de texto (2026-11-12)

> o botão de confirmar não fica claro após a alocação de pontos

> acho que animações de texto seriam legais também, na entrada

- **Botão:** era um erro do protótipo — a cor lima de "pronto" era sobrescrita pelo fundo escuro do painel de atributos (regra CSS mais forte), deixando texto escuro em fundo escuro. Corrigido; com todos os pontos distribuídos o botão fica lima e pulsa de leve.
- **Texto (escolha do assistente, o criador não definiu o estilo):** títulos e nomes entram **letra a letra** (cada letra cai e assenta, em sequência); descrições e mensagens entram como **máquina de escrever**. Seletor "TEXTO" na barra para ligar/desligar. No Godot: letra a letra = `draw_char` por glifo com Tween; máquina de escrever = `visible_characters`.
- **Em aberto:** aprovação dos dois estilos de texto.

## Rodada 6 — inspeção do Move novo (2026-11-12)

> tem que ter a inspeção de move pra quando ele chega

- **Leitura do assistente:** quando o Move novo chega, a **inspeção (visão expandida, D-420 §4)** abre sozinha antes da tela de aprender; fecha com Z/X e reabre com **C**. Com as 8 vagas cheias, **C** inspeciona o Move selecionado na grade (para decidir qual esquecer).
- **Conteúdo:** os textos reais de cada Move (`mechanics_text`, `visual_text`, `motion_text`, `windup_text`, `tactical_text` dos `content/moves/*/move.tres`), sem citar IDs de decisão; cabeçalho com fundo do elemento, glifo em marca d'água, badges de tipo/alcance e ATB/MP/POWER; **dois blocos** (como o criador pediu no HTML anterior): Mecânica + Tática, e Visual + Deslocamento + Wind-up.
- **Em aberto:** abrir sozinha ou só com tecla; a tecla.

## Rodada 7 — inspecionar qualquer Move com clique (2026-11-12)

> clicando em qualquer move, não só o novo

- Clicar em **qualquer** card de Move (os 8 da grade e a ficha do Move novo) abre a inspeção daquele Move. **C** continua inspecionando o selecionado no teclado.
- A abertura automática na chegada (rodada 6) continua como está; o criador não respondeu se ela fica.

## Rodada 8 — destaque do Move novo, inspeção só no clique, ícone de status (2026-11-12)

> o move novo tem que aparecer com uma borda brilhante e um texto "NEW!" no canto torto
>
> além de que ainda abre sozinha e também não possui os respectivos ícones (vou criar icones para efeitos de status)

- **Destaque:** o Move novo aparece com **borda brilhante** (paralelogramo maior atrás do card, pulsando) e o selo **"NEW!"** girado no canto superior direito — na ficha grande, no card da grade quando ele entra, e no cabeçalho da inspeção desse Move.
- **A inspeção NÃO abre sozinha** (resposta à pergunta da rodada 6/7): abre só com clique no Move ou **C**. Revoga a abertura automática da rodada 6.
- **Ícones de status:** Moves de status (Heal, Media, Sukunda, Taunt, Tarukaja, War Cry) não têm ícone de tipo nem de alcance. **O criador vai criar ícones para efeitos de status.** Até lá o protótipo mostra um badge cinza "?" no lugar, marcado como pendente.

## Rodada 9 — navegação por teclado, animação de seleção, animações corrigidas, só "NEW!" (2026-11-12)

> não é pra só poder selecionar com o mouse mas também com as setas e o botão Z, além de dar uma animaçãozinha pra saber qual move vc vai selecionar
>
> alem disso as animações estão quebradas nessa aba de new move, corrija-as
>
> além disso ao invés de uma borda, deixa só o New com uma animação do move surgindo depois dos outros

- **Teclado:** setas andam entre a ficha do Move novo, os 8 Moves da grade, "Não aprender" (com 8 cheias) e o botão de continuar; **Z** no Move abre a inspeção dele (como o clique). Mouse: passar por cima seleciona, clicar = Z.
- **Esquecer com 8 cheias (escolha do assistente):** como Z agora inspeciona, a inspeção de um Move da grade ganha **[Z] ESQUECER ESTE / [X] VOLTAR**; Z ali troca na hora (a inspeção já serve de confirmação). "Não aprender" mantém a confirmação.
- **Animação de seleção:** o Move selecionado sobe e cresce com mola, ganha uma barra coral que se estende embaixo e uma seta ▶ pulsando ao lado.
- **Animações corrigidas (causa):** a grade era redesenhada a cada tecla, o que reiniciava a queda do card novo e cortava as entradas; e a animação do card novo brigava com a de entrada. Agora a grade é montada uma vez e a seleção só troca classe.
- **Sem borda brilhante:** só o selo "NEW!". O card do Move novo **surge depois dos outros**, com animação própria, e o "NEW!" estoura em seguida.

## Rodada 10 — chegada mais épica do Move novo (2026-11-12)

> queria que fosse mais épico o surgimento do move novo

- **Sequência (escolha do assistente):** o resto da tela escurece (holofote); o card do Move novo **cai do alto, grande e girado**, bate na vaga com um repique de mola; no impacto saem um **anel duplo** que se expande, **14 raios** e **18 faíscas** na cor do elemento, o **glifo do elemento gigante** se abrindo e sumindo atrás, e a grade **treme** de leve; por fim o **"NEW!" bate girando** no canto. ~1,1 s no total.
- **Sem flash/estrobo de tela:** o criador já tinha recusado piscada por risco de epilepsia (conversa do HUD pós-combate de 2026-11-08); o brilho vem dos efeitos, não de piscar a tela.
- Vale também quando o Move novo entra no lugar de um esquecido. No Godot: Tween de posição/escala/rotação, `CPUParticles2D`/`Line2D` e `TextureRect` com `modulate`.

## Rodada 11 — inspeção: lado mecânico × lado visual, valores coloridos (2026-11-12)

> o texto poderia ser mais rico, não tem as informações necessárias do move, a parte visual não devia compartilhar a parte mecanica do wind up, um lado é mecanico e um outro lado é visual. Deve haver os valores e cores diferentes.

- **Esquerda = MECHANICS (lima):** grade de valores do jogo (alvo, wind-up em segundos, pausa do motor nos Moves de status, efeitos especiais por tag: STUN, quebra Guard, intocável, ignora defesa) + EFFECT + TACTICAL & SCALING + risco do wind-up (a parte mecânica do texto de wind-up).
- **Direita = VISUALS (rosa):** LOOK, MOTION & DISPLACEMENT e WIND-UP POSTURE (só a parte visual do texto de wind-up).
- **Valores coloridos no texto:** segundos em aqua, porcentagens/multiplicadores em dourado, stats nas cores da rodada 4, HP/MP nas cores das barras, STUN/Guard/Burst em coral.
- **D-420 respeitada:** tipo, elemento, alcance, custo e poder ficam só no cabeçalho, sem repetir na grade.
- **Fonte dos valores:** `content/moves/*/move.tres`; wind-up efetivo = `windup` do Move ou o padrão do combate (0,5 s status / 1,5 s demais, `scripts/combat/battle.gd:91,98`).
- **Divergência encontrada nos dados do jogo (não corrigida):** o `windup_text` de 12 Moves diz um tempo diferente do que o combate usa — Psybeam 1,80 s × 1,50 s; Shock Wave 1,20 × 1,50; Teleport 0,90 × 0,50; Media 1,30 × 0,50; Sukunda 0,90 × 0,50; Megido 2,20 × 1,50; Heal 1,10 × 0,50; Mach Punch 0,35 × 0,20; Brick Break 1,40 × 1,50; Taunt 0,70 × 0,50; Tarukaja 1,10 × 0,50; Hassou Tobi 1,75 × 1,50. O protótipo mostra o valor do combate. **Em aberto:** qual vale (texto ou dado) e se os textos dos Moves devem ganhar números (ex.: quanto cura) — isso é editar conteúdo do jogo.

## Rodada 12 — mecânicas reais no lado esquerdo e pop-up dos ícones (2026-11-12)

> vc está esquecendo de colocar as mecanicas dos moves no lado esquerdo...
>
> alias permita clicar nos icones para mostrar um pop-up que explica o icone

- **Lado esquerdo = mecânicas tiradas do código do combate** (não dos textos, ver D-1187): **EFFECT** (o que só aquele Move faz, ex.: Karate Chop 30% de -1 SPD; Electric Beam 20% + diferença de LUK de STUN 4 s; Taunt redireciona; War Cry interrompe e dá Burst; Heal "ainda não faz nada"), **COMBAT RULES** (interrupção ao levar golpe no wind-up — projétil já disparado não para; Evade manual nos últimos 0,25 s; 10% de esquiva automática; 10% de crítico ×2; Weak ×1,5 / Resist ×0,5; Guard ×0,5; WIS reduz o mágico ×10/(10+WIS); status não se desvia e pausa o combate) e **WITH <personagem>** (a conta com os atributos reais). Confusion mostra a regra da D-1187 como **planejada**, em cinza.
- **Pop-up dos ícones:** clicar em qualquer ícone (tipo, alcance, elemento, "?" de status) abre um cartão creme torto explicando o ícone; some em **5 s** (barra coral diminuindo) ou no **X**. Clicar no ícone não abre a inspeção do Move. (Mesmo comportamento que o criador pediu no HTML de 2026-11-08.)

## Nota (2026-11-12) — ícone de Status aplicado (D-1190)

O badge cinza "?" dos Moves de status deu lugar ao ícone ± da D-1190 (badge laranja `#fb923c`, **cor provisória**). O tipo Field está disponível no protótipo, mas nenhum Move o usa.

Atualização: o criador escolheu badge **branco** para Status (D-1190); o laranja provisório saiu.
