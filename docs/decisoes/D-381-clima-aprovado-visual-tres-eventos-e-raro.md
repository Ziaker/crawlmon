# D-381 — Clima aprovado: só visual, os três eventos, raro e distorção temporal

- **Data:** 2026-11-06
- **Área:** Exploração / visual / clima / VFX
- **Origem:** respostas do criador às quatro perguntas da proposta D-362.
- **Status:** escopo aprovado; nada implementado. A cadência exata de "raramente" e a duração ainda estão em aberto.

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
7. **D-308 continua valendo.** Todo efeito é construído sobre o Motion Composer; se ele não tiver representação de clima (véu de tela, gotas, respingo), o Composer é atualizado primeiro, com teste e versão. O clima é ambiente, não Move/shot; a pausa de VFX de combate de D-953/D-954 é do pipeline de shot. Se o criador quiser que ela valha para clima também, é só dizer.
8. **GL Compatibility:** o projeto usa `gl_compatibility`; chuva/neve usa **CPUParticles2D** (ou shader), não `GPUParticles2D`, proibido pelo protocolo. Isso corrige o detalhe técnico da proposta D-362.
9. **Mapeamento por bioma:** a lista de D-362 é o ponto de partida (calor em barren/dark wasteland/deep boulder/deep limestone/limestone; chuva em 4th/murky/spacial/temporal spire; neve nos gelos; cinza no dark wasteland; neblina em murky/spacial/7th/icicle/vast/temporal). Ainda não é regra fechada; confirmar antes de cada efeito.

## Ambiguidades em aberto

- **"Raramente":** qual cadência? (chance por andar, intervalo em andares ou intervalo em segundos)
- **Duração:** quanto tempo cada evento fica ativo? (D-362 sugeriu 12–20 s para o calor; não foi confirmado)
- **Mapeamento por bioma:** manter a lista de D-362?
- **"Sim" da pergunta 2:** foi lido como "os três"; confirmar se era isso ou "começar pela neblina".

## Estado

Nada implementado. Nenhum código, shader, partícula, cena ou asset alterado. D-362 continua como proposta detalhada; esta decisão registra o escopo aprovado. Nada publicado.
