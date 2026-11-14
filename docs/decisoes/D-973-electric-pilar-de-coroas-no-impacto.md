<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-973 — Electric: pilar de coroas de raios no impacto (corrige D-972)

- **Data:** 2026-11-08.

## Frase literal do criador

> pq os pilares rotativos de eletricidade ficaram como pós impacto? é pra serem acionadas no impacto, inclusive com pilar de eletricidade eu digo, de meshes elétricas que se movimentam em zigzag para 360 direções diferentes se afastando do oponente, como coroas, não um retanculo amarelo completo. PLaneje melhor o que irá fazer

Respostas: as coroas se afastam **para fora e para cima**; "ambos devem acontecer no impacto, esse move não tem pós-impacto além da resolução final dos efeitos já acionados no impacto".

## Decisão

1. **Sai** o cilindro sólido, o núcleo, o disco e os anéis grossos no chão da D-972.
2. **Pilar = coroas de raios em zigue-zague** empilhadas do pé até um pouco acima da cabeça, nascendo no contato (0 s) em volta do corpo (0,3 m fora dele), girando em sentidos alternados.
3. As coroas **se abrem para fora e sobem**, partindo-se em pedaços que se afastam do oponente em 360°.
4. Raios verticais curtos ligam as coroas nos primeiros instantes (a leitura de "pilar") e se soltam junto.
5. Faíscas laterais sutis; anel, estrela, fagulhas, clarão e luz continuam.
6. **Tudo é acionado no impacto.** Este move não tem pós-impacto próprio: o fim é só a resolução dos efeitos já disparados. O teste de contrato passa a aceitar que o nó viva até esses efeitos acabarem.

Medido do modelo real do alvo (D-235); reaproveita a lógica das coroas do disparo (D-958/D-960).

## Estado

Implementado para revisão em vídeo nas duas vistas.
