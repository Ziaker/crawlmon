<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-381 — Clima aprovado: só visual, os três eventos, raro e distorção temporal

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima / VFX
- **Origem:** respostas do criador às quatro perguntas da proposta D-362.
- **Status:** escopo aprovado; cadência e duração definidas em D-382; clima fora do Motion Composer (D-383); neblina (D-384), chuva (D-386) e calor (D-387) implementados; neve/cinza/distorção pendentes.

## O que o criador disse (literal)

> 1 - so visual

> 2 - sim

> 3 - raramente

> 4 - acho que sim

## Decisão

1. **Clima só visual.** Nenhum evento altera movimento, escorregar, combate, colisão, câmera, geração, raio de visão 7,5, LOS ou explorado permanente (D-235, D-344/D-329). É camada de apresentação.
2. **Os três eventos entram:** neblina maior, calor ondulado e chuva/neve com respingo no chão. A resposta "sim" à pergunta "quer os três ou começamos pela neblina?" foi lida como "os três"; se a intenção era começar só pela neblina, o criador corrige.
3. **"Neblina maior" é véu visual mais denso/alto na tela.** Não aumenta o raio de visão, a área revelada nem a LOS; o raio 7,5 e o explorado permanente continuam iguais (D-344/D-329).
4. **Frequência rara.** Não é clima constante nem em todo andar. A cadência exata (chance por andar, intervalo em andares ou intervalo em segundos) fica pendente; não escolho um número sem o criador.
5. **Distorção temporal entra** em Temporal Tower/Spire ("acho que sim"), como camada visual sutil e sem regra. Se o criador mudar de ideia, sai sem afetar os outros três.
6. **Ordem de trabalho:** neblina → calor ondulado → chuva/neve → distorção temporal, como em D-362. Um efeito por vez, com aprovação visual antes do próximo (D-308).
7. **Clima fora do Motion Composer (D-383).** Névoa, calor, chuva/neve e distorção temporal são camadas 2D de ambiente e não usam o Composer nem o protocolo de 4 fases. D-308 fica restrito ao VFX de Move/elemento em combate; a pausa de D-953/D-954 continua para o combate e o clima não a reabre.
8. **GL Compatibility:** o projeto usa `gl_compatibility`; chuva/neve usa **CPUParticles2D** (ou shader), não `GPUParticles2D`, proibido pelo protocolo. Isso corrige o detalhe técnico da proposta D-362.
9. **Mapeamento por bioma:** a lista de D-362 é o ponto de partida (calor em barren/dark wasteland/deep boulder/deep limestone/limestone; chuva em 4th/murky/spacial/temporal spire; neve nos gelos; cinza no dark wasteland; neblina em murky/spacial/7th/icicle/vast/temporal). Ainda não é regra fechada; confirmar antes de cada efeito.

## Ambiguidades

- Resolvidas em D-382: cadência de 20% por andar, duração de 20–40 s e mapa de biomas de D-362 mantido.
- Nenhuma pendente para o escopo. Intensidade, gotas e respingo serão calibrados visualmente.

## Estado

Nada implementado. Nenhum código, shader, partícula, cena ou asset alterado. D-362 continua como proposta detalhada; esta decisão registra o escopo aprovado. Nada publicado.
