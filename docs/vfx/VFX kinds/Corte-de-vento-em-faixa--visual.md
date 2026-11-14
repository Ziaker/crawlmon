<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Corte de vento em faixa (Wind Slash Band) — descrição visual

- **Nome do efeito:** Corte de vento em faixa (inglês: Wind Slash Band).
- **Move onde aparece:** Sand Attack (`tiro_areia`), no release. Decisão do criador: D-1214.
- **Par técnico:** `Corte-de-vento-em-faixa--codigo.md` (como reproduzir em código).
- **Em uma frase:** uma faixa larga amarela, como um golpe de vento, que gira horizontalmente em volta do corpo de quem lança, inclinada na diagonal, dando uma volta e meia em um instante e depois se desfazendo em grãos que escorrem para a frente.

## O que a pessoa vê, em ordem

1. **O gatilho.** O wind-up termina e, **sem pausa**, a faixa nasce. Ela surge no mesmo instante do giro do personagem e do disparo da areia.
2. **A varredura (0,35 s).** A faixa é desenhada como se uma lâmina de vento fosse passando: a "cabeça" corre pelo arco enquanto a "cauda" ainda não saiu. Ela **começa pela ponta de baixo** (a ponta que fica mais baixa por causa da inclinação) e termina na de cima.
3. **A forma.** É uma **faixa**, não uma linha: larga no meio e afinando nas duas pontas (como uma pincelada de espada). O corpo do arco é **horizontal**, em volta do personagem, na altura do peito (cerca de 60% da altura do corpo), e **inclinado 20° na diagonal** (como se o plano do golpe estivesse tombado, um lado mais alto que o outro). Ela dá **540°, uma volta e meia**, então as duas voltas se cruzam e se sobrepõem na mesma altura. Não sobe em espiral.
4. **A cor.** Amarelo vivo: miolo quase amarelo-limão claro (1,0 / 0,95 / 0,2) e borda amarelo-ouro (1,0 / 0,82 / 0,05). Opacidade máxima de 80,75% (0,95 reduzido em 15% a pedido do criador). Sem preto, sem marrom: é vento claro, não terra.
5. **A dissipação (0,7 s por trecho).** Cada ponto da faixa, depois de nascer, **vai ficando transparente** e **se desfaz em grãos** (pontinhos que vão furando a faixa, os grossos primeiro perto do fim). O trecho que nasceu primeiro some primeiro, então a faixa parece "evaporar" na ordem em que foi desenhada. Enquanto se desfaz, o que sobra **escorre para a frente**, na direção do alvo (até 1,5 alturas do corpo), junto com a areia. A borda também encolhe um pouco ao sumir.
6. **O fim.** Cerca de 1,05 s depois do início (0,35 s de varredura + 0,7 s de dissipação) não resta nada.

## O personagem

Durante os mesmos 0,35 s da varredura, o atacante **dá um giro completo (360°)** sobre o próprio eixo, junto com a faixa. Ao fim volta exatamente para a posição de repouso.

## Tamanho (em proporção ao corpo)

| Medida | Valor |
|---|---|
| Raio do arco (horizontal) | 1,05 × altura do corpo |
| Largura máxima da faixa (vertical) | 0,49 × altura do corpo |
| Altura do centro do arco | 0,6 × altura do corpo |
| Avanço da dissipação para a frente | 1,5 × altura do corpo |

Todos os tamanhos saem da altura **medida do modelo** do atacante (D-235), nunca de um personagem fixo.

## O que NÃO é (o criador rejeitou)

- Não é um cone parado grande no ponto do release (foi o que ela substituiu).
- Não é um laço fino em arco em pé, nem uma hélice que sobe do chão, nem uma faixa vertical: o criador disse "horizontal semi-diagonal de arco, como um corte".
- Não começa por cima (começa por baixo).
- Não é marrom nem alaranjada ("deixe a cor mais amarela").
- Não fica parada no lugar do release: o que se desfaz escorre para a frente.

## Orientação nas duas vistas

O arco é desenhado em torno do atacante e o eixo "para a frente" vem da direção atacante → alvo, então funciona igual com o atacante perto ou longe da câmera e com o alvo em qualquer lado (D-235). O sentido do giro do personagem e da varredura é o mesmo em ambas as vistas; não foi conferido se parece idêntico espelhado.

## Como aparece no tempo (relógio do move)

| Tempo desde o fim do wind-up | O que acontece |
|---|---|
| 0,00 s | corte nasce (cabeça na ponta de baixo); atacante começa o giro |
| 0,06 s | jato de areia, estações e pedras saem |
| 0,00 → 0,35 s | cabeça varre os 540°; atacante completa os 360° |
| 0,35 → 1,05 s | cada trecho vai sumindo em grãos e escorrendo para a frente |
| ~1,05 s | fim do efeito |

## Elementos acompanhantes do mesmo release (não fazem parte da faixa)

Cone que viaja com a areia, anel de nuvens e véu viajando do atacante ao alvo, poeira solta emitida ao longo do caminho, rastro escuro no chão (outro tipo de VFX: faixa de rastro no chão, descrita no código como `dust_wind_strip`) e o jato de areia. Eles têm suas próprias descrições em D-1196 e D-1214.

## Quadros de referência

Capturas reais (locais, ~1 GB, não versionadas no Git) em `docs/vfx/sand_attack_ref/`: `slash8` (varredura e dissipação), `spin1` (giro do personagem), `nodelay1` (release sem atraso), `wide1` (faixa larga, volta e meia).
