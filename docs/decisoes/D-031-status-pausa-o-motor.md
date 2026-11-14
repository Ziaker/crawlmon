<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-031 — Golpes de status: preparo de 0,5 s e motor pausado desde o preparo

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> personagens tão conseguindo desviar de moves de status...
>
> além disso eles deviam pausar o motor (não a animação dos personagens e efeitos visuais) ao serem realizados, a maioria deve custar 1ATB apenas

Respostas: "Media fica 2, Tarukaja fica 2" / "moves de status tem preparo de .5 segundos, devem ocorrer desde o preparo" / "Para no lugar".

> na verdade, para animações de ataque, não de idle, não deve parar a animação do usuário executando o move, alem de ter um efeito visual notável pra execução do move

Respostas: "Ataques congelam" / "Aura no lançador, Faixa com o nome".

## Decisão

1. Golpes de status **não** podem ser desviados (reforça D-012).
2. Golpes de status têm **preparo de 0,5 s**.
3. **Desde o preparo** até o fim do efeito visual do golpe, o **motor fica pausado**: ATB, preparos, ataques, IA e movimento param; quem estava correndo ou com projétil no ar **para no lugar**. As **animações dos personagens e os efeitos visuais continuam**.
5. **Animações na pausa:** quem estava em animação de **ataque** (correndo, golpeando) **congela**; animações de **idle continuam**; quem usa o golpe de status **anima o próprio ataque**.
6. **Efeito notável:** uma **aura** na cor do elemento em volta de quem usa o golpe e uma **faixa na tela com o nome do golpe** e de quem usou, durante a pausa.
4. Custos: **Media e Tarukaja = 2 ATB**; os demais golpes de status = **1 ATB**.

Detalha D-014.

## Ambiguidades em aberto

- "Fim do efeito visual": o motor guarda um tempo fixo de **1,0 s** depois da aplicação do efeito (os efeitos de status duram cerca de 0,7–1,0 s). Confirmar se o tempo serve.
- Enquanto o motor está pausado, nenhum outro golpe pode ser iniciado (nem pelo jogador).

## Estado no código

Implementado (`battle.gd`: `STATUS_WINDUP`, `_status_pause`).
