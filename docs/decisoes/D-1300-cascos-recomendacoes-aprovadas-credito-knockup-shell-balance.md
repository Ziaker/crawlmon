<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1300 — Cascos: recomendações aprovadas (crédito, knock-up, `shell_balance`, kit gratuito)

- **Data** — 2026-11-18
- **Área** — Economia / drops / combate
- **Estado** — Aprovado em chat. Só documentação; nenhuma integração ao combate foi feita.
- **Relacionadas** — [D-1285](D-1285-cascos-economia-moedas-separadas-e-chances-de-drop.md), [D-1286](D-1286-cascos-bronze-drop-simultaneo-e-knock-up-visivel.md), [D-1253](D-1253-saldo-comum-e-balanceamento-dos-cascos.md).

## Frase literal do criador

> sigo suas recomendações, inclusive envie as perguntas para finalizar as questões pendentes

(Resposta à lista de pendências numeradas 1 a 7, em que eu havia dado recomendação nos itens 1, 2, 4 e 5. Os itens 3, 6 e 7 não tinham recomendação e foram reenviados como perguntas.)

## Decisão (somente os itens com recomendação)

1. **Instante do crédito:** os Cascos entram no saldo quando a vitória é confirmada.
2. **Knock-up:** todo inimigo derrotado dispara a apresentação dos Cascos voando e caindo (a D-1286 item 4), não só o lançamento balístico de K.O.
3. **`GameState.shell_balance`:** migra para o saldo Bronze. A migração ainda **não foi feita**; exige código e cuidado com o save existente.
4. **Kit gratuito:** é gasto antes das compras (a compra não usada chega à expedição seguinte).

## Respostas às perguntas reenviadas (palavras do criador, opções escolhidas)

- Cascos no chão não coletados: "Entram no saldo ao fim da batalha".
- Derrota ou retirada: "perde todos mas eles permanecem no ambiente pra serem coletados novamente, uma mecanica souls like tibia".
- Chefes e líder: "Mesma fórmula, LUK do líder atual".
- Preços de potion e super_potion: "Sim, vou passar os valores" (valores ainda não informados).

Decisão: (5) os Cascos não coletados entram no saldo ao fim da batalha; (6) chefe dropa pela mesma fórmula e usa o LUK do líder atual; (7) em derrota ou retirada o jogador perde os Cascos da expedição, e eles permanecem no ambiente para serem coletados de novo (mecânica estilo Souls/Tibia).

## Recuperação dos Cascos perdidos (respostas do criador, na ordem das perguntas)

1. Onde ficam: "no lugar onde caiu".
2. Limite de tempo para recuperar: "não" (sem limite).
3. Se cair de novo antes de recuperar: "continuam" (os Cascos antigos continuam no ambiente).
4. Vale para os três tipos de Cascos: "sim".
5. Saldos já consolidados continuam protegidos (D-1285): "sim".
6. Preços de potion e super_potion: "sigo suas recomendações" e, depois, "JÁ FALEI RECOMENDAÇÃO S UA, PARA DE ENCHER O O SACO SOBRE ISSO COMEÇA LOGO". A recomendação da IA, aprovada por essas palavras:
   - `potion` (30 HP): **10 Bronze**, 1 unidade por compra, sempre disponível no Hub.
   - `super_potion` (60 HP): **25 Bronze**, 1 unidade por compra, sempre disponível no Hub.
   - Proporção 10 para 25 (o efeito dobra, o preço sobe 2,5x). Com Bronze a 50% por inimigo, uma potion custa em média 20 inimigos. Os valores podem ser mudados pelo criador a qualquer momento.

## Pendências

- Preços e disponibilidade dos demais itens e contrato mecânico deles (revive, sitrus_berry, lum_berry, elixir, amulet, charm).
- Detalhes não perguntados da recuperação: como a coleta funciona na prática (tocar nas moedas, mesma física da D-1259) e se as pilhas de quedas diferentes se somam ou ficam separadas.
