<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1243 — BOOST no cartão: aura por shader, opção B (Chakra), com 80% menos opacidade

**Data:** 2026-11-16
**Área:** HUD de combate (visual)
**Estado:** escolhida; só visual (a mecânica é a D-1242).
**Relacionadas:** D-1229, D-1241, D-984, D-235.

## Frase literal do criador

> "opção C com menos 80% de opacidade"

> "não essa, eu digo a B,"

> "aumente a opacidade pra .45"

> "esta perfeito, aprovo"

> "guarde as outras pra talvez outro uso futuro, além disso deixe roxo claro ao invés de amarelo"

> "deixe azul ao invés de roxo, mude a cor do badge também"

> "faça a opacidade reduzir quanto mais se separa do cartão, a ideia não é que vá até o ceu mas a animação vai em momentos aleatorios, como brasas"

## Decisão

Entre as 3 variações por shader (A Saiyajin, B Chakra, C Nen/Reiatsu), vale a **B (Chakra, manto do Kurama)**: manto laranja ondulando em faixas de opacidade, subindo do cartão até o alto da tela, com bolhas e bolhas de chama que se soltam devagar. Ele disse "C" e corrigiu para "B" (A = Saiyajin, B = Chakra, C = Nen/Reiatsu). Opacidade: 80% a menos que a mostrada na comparação (`opacity` 1.0 → 0.2); depois ele pediu "aumente a opacidade pra .45": vale **0.45**.

## Ambiguidade e estado

"Menos 80% de opacidade" foi lido como 80% **a menos** (0.2), depois substituído pelo valor dele, 0.45. Se ele quis dizer 80% do valor anterior, é só trocar `BoostFx.OPACITY` (0.8). Paleta, ritmo e pulso seguem os da comparação; ele pode pedir ajuste.

Código: `shaders/boost_card_aura.gdshader`, classe `BoostFx` em `scripts/ui/battle_hud.gd`, atalho `--boost=2` (`--boost-seq=N`, `--boost-hold=N`) em `scripts/debug/vfx_room.gd`. As variações A e B continuam no shader até ele mandar remover.

## Aprovação (2026-11-16)

Aura B (Chakra) a 0.45, sem faixas duras nem máscaras, subindo do cartão até o alto da tela, nos inimigos e no cartão do jogador (preview `--boost-player`): **aprovada pelo criador**. A mecânica continua na D-1242; ligar o visual ao estado real de BOOST ainda não foi feito.

## Roxo claro e variações guardadas

A aura B passa a **roxo claro** (cores do shader, só no estilo 2). As variações A (Saiyajin) e C (Nen/Reiatsu) ficam guardadas no shader, em âmbar, para uso futuro. O badge BOOST continua âmbar até ele pedir outra cor.

## Azul claro (substitui o roxo)

A aura B e o badge BOOST ficam em **azul claro** (aura: `vec3(0.3, 0.62, 1.0)` -> `vec3(0.8, 0.93, 1.0)`; badge: fundo `1d5fa8`, texto `d6ecff`). Os tons exatos são palpite meu: ele pode ajustar.

## Alcance curto e momentos aleatórios

A aura perde opacidade quanto mais longe do cartão e alcança só ~100 px acima dele (não vai até o céu). As chamas e brasas acendem em momentos aleatórios (por coluna e por ciclo), como brasas pegando. Os números são palpite meu: ele pode ajustar.

## Aprovação final (2026-11-16)

> "aprovo"

Versão final aprovada: aura B (Chakra) em azul claro, opacidade 0.45, alcance curto com queda por distância, brasas em momentos aleatórios, badge azul; nos cartões de inimigo e do jogador (preview). Ligar ao BOOST real continua pendente (D-1242).

**Ligação ao estado real (2026-11-16):** `BattleHud.boost_state(c)` devolve o preview de debug ou, se `c.is_boosted()`, a aura Chakra (estilo 2) com o badge contando `boost_timer`. Verificado por dados em `--employ=boost`; não visto em janela.
