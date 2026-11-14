<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-355 — Polimento dos tilesets: golden, máscaras, occluder, decals e Wall Alt

- **Data:** 2026-11-06
- **Área:** Exploração / visual / tiles / ferramentas
- **Origem:** Depois de o início do jogo (Temporal Tower) ser aprovado, o criador pediu mais polimento e autorizou as cinco frentes.

## O que o criador disse (literal)

> acho que mais polimento é bom o bastante, me diz 5 coisas que faria

E, depois da lista:

> possiga com todos

## Decisão

As cinco frentes passam a existir:

1. **Golden room diff:** a sala do laboratório é capturada sem título/luz (`--golden`) e o `check_golden_room.py` compara o perfil vertical **topo da parede → face → chão** com o preview da folha. É um teste de regressão, não um diff pixel-perfect.
2. **Laboratório de máscaras 8-vizinhos:** o laboratório desenha uma grade 3×3 por papel de parede (núcleo, strip, island, tips, cross e alt centres), com o centro no papel e os vizinhos em parede/chão. A captura `_masks.png` mostra todos; a tecla **M** alterna a câmera.
3. **Occluder ciente da face:** cada tile bloqueia luz só no lado da **massa de parede**; a face voltada para o chão fica livre. O occluder de tile inteiro em todas as paredes tinha escurecido a sala e foi rejeitado. Medição: o centro do piso ficou igual (±1 nível); a massa de parede ficou um pouco mais escura, que é o efeito desejado.
4. **Espaçamento dos decals de piso:** dois `Ground Alt` nunca ficam lado a lado. O candidato é 13% (7% alt2 + 6% alt1) e a regra de desempate por célula reduz para **~8,7% reais** (4,3% + 4,4%), sem pares adjacentes. A média visual de D-347 (4%+4%) é preservada; a probabilidade nominal não é 8%, e sim o candidato que, após o espaçamento, resulta em ~8%.
5. **Variação da massa de parede com Wall Alt. 1/2:** os **centros** C7R1 e C10R1 entram no atlas como `wall_alt_1/2` e são usados em **10%** das células de parede **totalmente interiores** (8 vizinhos em parede), 5% cada. Nunca em borda, canto, strip, tip ou cross.

## Exceção explícita ao “mesmo componente”

Wall Alt. 1/2 são **estilos alternativos** da categoria parede, não o bloco principal. Até esta decisão, a regra era usar só células do mesmo componente. O criador autorizou a mistura como **variação rara de interior**; por isso:

- só os **centros** C7R1/C10R1 são usados;
- só em células com os 8 vizinhos em parede;
- 10% no total;
- a costura medida é comparável à do centro principal (main→alt1 L/R 10,6 / T/B 21,2; main→alt2 14,6 / 9,3, contra main→main 10,7 / 21,2);
- se o resultado visual for rejeitado, a variação volta a 0% sem tocar no resto.

## Estado

Implementado: 30 tiles no atlas ativo (18 núcleo + 2 Ground Alt + 8 peças de parede + 2 centros Wall Alt), golden OK (correlação 0,60; topo 137,8 > face 83,4; chão 48,2), máscaras com 19 papéis, occluder por face, decals em 8,7% sem adjacentes, alt em 9,25% dos interiores. D-356 depois fixou os decals em 4%+4% exatos (8,1% medidos) e fez o fallback dos 12 perfis. O gate do Temporal foi **aprovado** em 2026-11-06 (30 tiles, 5+5% Wall Alt); o build não avisa mais. Nada foi publicado.
