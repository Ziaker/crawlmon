<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste pode levar mais de 1 minuto; crie o cenário/controle antes de testar; teste no debug, nas duas vistas (D-235). Ver `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1254 — Summon: animação de invocação e de translocação em raio

**Data:** 2026-11-16
**Área:** combate, VFX, Summon
**Relacionadas:** D-1232, D-1244, D-1249.

## Frases literais do criador

- "deve haver uma animacao de invocacao que tem duracao de 4 segundos ate o aliado chegar no ambiente, alem de uma animacao de translocacao em raio que cai no chao (quando e invocado) e raio que sai do chao como um teleporte (quando e trocado), tendo um intervalo de 1 segundo"
- "o prototipo de seletor de cartoes, na ideia de ter um X no cartao e ele aparecer mais escuro, nao estao presentes no video, e proposital"

## Decisão (só o que ele disse)

Há uma animação de invocação de 4 s até o aliado chegar ao ambiente; uma translocação em raio que cai no chão quando o aliado é invocado e um raio que sai do chão, como teleporte, quando é trocado; entre as duas há um intervalo de 1 s.

## Respostas do criador (2026-11-16, mesma data)

- Ordem do raio e dos 4 s: "o raio cai DEPOIS destes 4 segundos, pq no chao fica criando um pentagrama cuja animacao tem a exata mesma duracao, quando fica completo ele chega, semelhante a cutscene de entrada no hub".
- Congelamento: "Não congela" (a batalha segue durante a animação).
- X no cartão e mais escuro: "Sim, para o jogo" (cartão do aliado nocauteado fica mais escuro e com um X no seletor do Summon).

## Respostas adicionais (2026-11-16)

- Intervalo de 1 s: "sim" (a leitura confirmada: é o intervalo entre o raio que sai do chão, de quem sai, e o início do pentagrama, de quem entra).
- ATB e ação de quem entra durante o pentagrama: "obvio que nao ele so pode agir depois que entrar no jogo, depois que for invocado apos estes 4s".

- Mudar a lógica de `Battle` para o estado "chegando" (pergunta: "Posso mudar a lógica de `Battle` para esse estado chegando?"): "obrigatoriamente".

## Respostas finais (2026-11-16)

Perguntas minhas: "O que fica na vaga durante os 4 s? Os 2 ATB são pagos ao confirmar ou quando o aliado chega? Dá para cancelar a invocação, e o custo volta?"
- Custo: "remova o custo de atb, o intervalo de 4s e o bastante, nao e mais necessario este custo para invocacao". (O Summon não custa mais ATB; os 4 s bastam como "custo".)
- Cancelar: "nao nao da pra cancelar".
- Vaga: "NADA fica na vaga alem do cartao do personagem sendo proceduralmente magicamente gerado no local onde ele fica".

## Visual (2026-11-16)

- "teoricamente ambos afinal ambos se complimentam" (pentagrama e raio são definidos juntos).
- Pergunta: reutilizar o efeito de chegada do hub (`HubSummonFx`: círculo neon, pentagrama, anéis, pilar de luz)? Resposta: "Sim, reutilizar o do hub (Recomendado)". Tamanho derivado do personagem (D-235) e duração do pentagrama de 4 s.

- Raio de saída: "Sim, o mesmo pilar, invertido (Recomendado)" (sai do chão levando quem é trocado), duração "0,95 s, espelho da queda (Recomendado)".
- Queda do raio: "Queda 0,95 s; age ao impacto (Recomendado)"; o criador acrescentou "apos o impacto" e escolheu "Assim que o raio toca o chão (4,95 s)": o aliado entra em `party` e age no instante em que o raio toca o chão; o clarão do impacto (0,95 s, como o LAND do hub) toca depois.
- Linha do tempo (confirmada por soma): saída 0,95 s + intervalo 1 s + pentagrama 4 s + queda 0,95 s = **6,9 s** até agir. Constantes `Battle.SUMMON_*_SECONDS`.

## Aprovação (2026-11-16)

Sobre os vídeos `prototypes/summon_selector/summon_anim_normal.mp4` e `summon_anim_mirror.mp4` (linha do tempo de 6,9 s com o efeito do hub): "Perfeito, aprovo". Vale para a animação (raio de saída, 1 s, pentagrama 4 s, queda, impacto) e para a cor do neon do hub. Não decidido: forma do cartão "gerado", cartão KO com X, sons.

## Cartão gerado (2026-11-16)

Criador: "O cartão deve ser gerado proceduralmente da esquerda pra direita com efeito visual de pixel por pixel na mesma coloração do raio." Implementado: shader `CARD_GEN_SHADER` em `battle_hud.gd`, blocos de 6 px aparecem da esquerda com borda irregular, os da frente brilham no neon do raio. **Escolha técnica minha, não dita:** a geração acompanha o pentagrama (de 1,95 s a 5,95 s; antes disso nada do cartão aparece). O criador pode mudar.

## Cartão de quem sai (2026-11-16)

Criador: "Além disso o cartão do personagem que sai deve se dissipar em luz, se fechando em ambos lados esquerdo e direito até virar um retangulo como um feixe". Implementado no mesmo shader: durante o raio de saída (0,95 s) o cartão fecha pelos dois lados até um retângulo fino que brilha no neon e some; só depois a vaga recebe o cartão do que entra (gerado). **Leituras minhas, não ditas:** o feixe é uma faixa vertical fina no centro do cartão; o tempo é o do raio de saída; o cartão do que sai não muda de lugar enquanto se dissolve (a ordem do dono do menu só é aplicada depois).

## Ajuste do tempo do cartão (2026-11-16)

Criador, sobre os vídeos: "a única coisa q precisa ajustar é que a duração do surgimento do cartão com o efeito é um pouco mais lento q a duração de tempo q leva pro personagem chegar, dd resto aprovo". Pergunta minha: em que momento o cartão deve terminar de surgir? Resposta: "Quando o raio começa a cair, mas 20% mais rápido (Recomendado)". O cartão passa de 4 s para **3,2 s** (de 1,95 s a 5,15 s). Constante `SUMMON_CARD_GEN_SECONDS` em `battle_scene.gd`. O resto fica aprovado (animação, raios, cartão que sai).

## Segundo ajuste do tempo do cartão (2026-11-16)

Criador: "Agora o cartão surge mais rápido do que o personagem". Pergunta: quantos segundos? Resposta: "3,8 s". O cartão passa de 3,2 s para **3,8 s** (de 1,95 s a 5,75 s); substitui os 3,2 s acima.

## Pentagrama da saída (2026-11-16)

Criador: "O pentagrama da saída do personagem surge de imediato ao invés de se formar, o que me propõe". Escolha dele: "Se traça nos primeiros 45%, depois o raio sobe (Recomendado)": círculo e pentagrama se desenham de 0 a 0,43 s, o raio e o personagem sobem a partir de 0,3 s, o desenho se apaga no fim.

## Aprovação final (2026-11-16)

Criador, sobre os vídeos com o cartão em 3,8 s e o pentagrama da saída se formando: "Perfeito, aprovo ambos, podemos finalizar isso". Animação do Summon concluída. Pendente (não decidido): cartão KO escuro com X no seletor, sons, textos e teclas, `save_state`/`restore_state` e trace por quadro.

## Decisão consolidada

Invocação: um pentagrama se forma no chão durante 4 s; ao completar, o raio cai e o aliado chega (como a entrada do hub). Troca: um raio sai do chão como teleporte para quem sai. A batalha não congela. O cartão do aliado nocauteado no seletor fica mais escuro e com um X.

## Pendente (não decidido)

Resolvidos acima: vaga, custo (removido) e cancelamento (impossível). Em aberto: se o "cartão sendo gerado" é o cartão do que entra se formando durante os 4 s (leitura minha) e como ele aparece; **mudança na lógica de `Battle` AUTORIZADA ("obrigatoriamente")**, que hoje troca na hora (quem entra já está em `party` com ATB 0): precisa de um estado "chegando" de 4 s em que ele não age; visual exato do pentagrama e do raio, cor, som; `save_state/restore_state`.

## Estado

**Lógica implementada (2026-11-16, autorizada):** `Battle.summon()` sem custo de ATB, quem sai vai na hora, a vaga fica vazia `SUMMON_ARRIVAL_SECONDS` (4 s) e só então quem entra chega em `party` com ATB 0 (`Battle.arriving()`, estágios `started`/`done`); o cartão de quem entra aparece na vaga (escurecido: visual PLACEHOLDER, não decidido). Testes `--summon=basic|ko|free|moves|protagonist|notsub|arrive` e `--summon-ui=basic|cancel|lowatb|protagonist|ko`. Detalhe técnico que escolhi (o criador pode mudar): só uma chegada por substituto (`entering_invalid` se já está chegando); várias invocações em paralelo em vagas diferentes são permitidas.
**Visual implementado (2026-11-16, reutiliza `HubSummonFx`, novo estado `EXIT`):** raio que sobe levando quem sai (0,95 s), 1 s, pentagrama 4 s, queda 0,95 s, aliado age ao tocar o chão (6,9 s), clarão LAND 0,95 s depois. Código: `battle_scene.gd` (`_summon_fx_*`, `_process`), `Battle.SUMMON_*_SECONDS`. Debug: `--summon-ui=shot:2:t=SEGUNDOS --shot=arq.png`. Capturas em `prototypes/summon_selector/shots/`. **Ainda pendente:** forma final do cartão "gerado" (hoje escurecido), cartão KO escuro com X no seletor, sons, cor (hoje o neon do hub), vídeo para você avaliar. Hoje quem sai some na hora, sem raio, e quem entra aparece sem efeito. `save_state/restore_state` não cobrem as chegadas em curso.
