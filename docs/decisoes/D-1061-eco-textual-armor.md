<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1061 — "Eco textual" e o eco "ARMOR!"

- **Data:** 2026-11-09.
- **Área:** Visual / VFX / tipografia.

## Frase literal do criador

> dê um eco textual (é como chamaremos as coisas que invocam onomatopeias) "ARMOR!", me diz como faria a animação da tipografia, inclusive, não esqueça que assim como os outros ecos texturais, deve ser bem saturado e sem bordas, flat

(Sobre os brilhos da ARMOR:)

> Os sparkles tem que surgirem em locais aleatórios do corpo, nunca só no chão, principalmente onde ficam os ombros e região do meio do corpo, não sejam tão constantes, além de serem um pouco maiores

## Decisão

1. **Eco textual** = qualquer texto/onomatopeia que um Move invoca (MISS, GUARD, CRÍTICO!, FRAQUEZA!, "ARMOR!"...).
2. Todo eco textual: **bem saturado, sem bordas, flat**.
3. O Armored Bulk ganha o eco **"ARMOR!"**. A animação da tipografia foi pedida como **proposta** ao assistente, a aprovar antes de implementar.
4. Brilhos da ARMOR: surgem em pontos aleatórios do corpo (ombros e meio do corpo em especial), nunca só no chão, esporádicos e um pouco maiores. **Implementado** (`armor_aura_effect`).

## Ambiguidades em aberto

- Cor do "ARMOR!" (saturada, flat). O GUARD usa branco com Impact; a cor do ARMOR! não foi dita.
- Animação da tipografia (proposta enviada, aguardando escolha).
- Os ecos antigos com borda (`float_text`: "CRÍTICO!", "FRAQUEZA!") ficam como estão; mudá-los é outra decisão.

## Segunda rodada (2026-11-09)

> os sparkles podiam ser mais dispersados, estão mt perto do personagem
> prossiga com a animação para eu ver se aprovo

5. **Brilhos mais dispersos** (raio 3,6; deriva maior). Implementado.
6. **Animação do "ARMOR!" implementada para aprovação** (`scripts/combat/fx/armor_echo.gd`): carimbo letra a letra (2,4x, achata em 1,1 x 0,78, assenta; o "!" dá um pulo extra), clarão branco chato da esquerda para a direita, saída com cada letra cortada em duas placas que voam e caem, sumindo nos últimos 0,2 s. Impact, plano, sem borda, desenhada sobre tudo.
7. **Cor:** criador: "ao invés de amarelo, seja cinza claro". O eco usa cinza claro (`ArmorEcho.COLOR` = 0.60, 0.62, 0.66, com o reforço de brilho 1,7 do GUARD). Nota: cinza não é "bem saturado"; vale a escolha do criador pela cor.

## Estado

Brilhos e eco "ARMOR!" **implementados, aguardando aprovação do criador** (cor e animação). Verificado em vídeo nas duas vistas (Abra e Orc). **Não verificado:** Cyclops, tamanho do eco num inimigo muito distante em outra câmera, e o eco coberto pela etiqueta "ARMORED BULK" do HUD na vista normal.
