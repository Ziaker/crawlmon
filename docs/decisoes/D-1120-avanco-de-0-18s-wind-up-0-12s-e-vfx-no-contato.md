<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1120 — Avanço de 0,18 s, wind-up de 0,12 s e VFX que termina no contato

- **Data:** 2026-11-10
- **Área:** Overworld 3D / lab / ataque / VFX
- **Origem:** o criador reprovou o visual do dash e respondeu às perguntas de timing.
- **Status:** **implementado e testado** (66/66 controlador; 100/100 VFX; ponta a ponta PASS); demo em slow motion regravada.
- **Nota D-1135 (2026-11-10):** o wind-up de 0,12 s foi removido **só para o Z do jogador**; o inimigo mantém telegraph de 0,4 s + pré-avanço de 0,12 s. As distâncias máximas passaram a **2,0 m para os dois**.
- **Relacionadas:** D-1100, D-1106, D-1112, D-1114 (substituída), D-1115, D-1119, D-1125.

## O que o criador disse (literal)

> o visual e vfx ainda tá péssimo, não estão animadas é uma coisa rápida imediata de duração pequena, não texturas grudadas na posição do boneco, é como um efeito de dash, tá péssimo
>
> alias, o avanço também tem que ser mais rápido (em sua duração), faça durar no máximo 1 segundo, inclusive reduca o wind-up dele pra .12 ao invés de .2

Respostas às perguntas de timing:

> faça durar só 0,18
>
> Não, terminar no contato

## Decisão

1. O **wind-up** (pré-avanço) passa de 0,2 s para **0,12 s**; o clipe `attack` continua rodando nesse intervalo, a 2,0× (D-1112).
2. O **avanço** (movimento do dash) dura **até 0,18 s**, para o jogador e para o inimigo; no caso normal (alvo a ~3 m) são 0,18 s. A velocidade vem da distância real, com **mínimo de 8 m/s**: um alvo já colado não vira um crawl e o dash termina no contato (mínimo de 0,06 s). A **distância máxima** cai **30%** (D-1127): jogador 3,5→2,45 m; inimigo 3,4→2,38 m; o alcance de 4,5 m e a regra de erro continuam.
3. O **impacto do Tackle de 0,5 s** no contato continua (D-1115); o tempo do avanço não muda o impacto.
4. O **VFX do dash termina no contato**: speedlines, rastro no chão e poeira não continuam durante a janela de impacto. O impacto do Tackle é um VFX separado.
5. As **speedlines são de espaço de mundo**, não presas ao ator: nascem ao longo do caminho, ficam para trás e o ator atravessa; a direção e a altura vêm do ator/alvo reais (D-235). O mesmo vale para qualquer ator, lado e tamanho.
6. **D-1114 fica substituída** na parte do intervalo de 0,2 s; o restante (clipe `attack` a 2,0×, sem congelar, VFX começando no dash) continua.
7. **D-1119** é atualizada: além de deslizar/alongar/girar, as linhas precisam estar no mundo e o efeito termina no contato.

## Implementação

- `overworld_attack_controller.gd`: `PRE_DASH_TIME = 0.12`; `DASH_TIME = 0.18` (máximo); `MIN_DASH_SPEED = 8.0`; `MIN_DASH_TIME = 0.06`; `_dash_plan(travel)` calcula velocidade e duração; o contato encerra o dash antes se o alvo já estiver ao alcance.
- `overworld_dash_speedlines.gd`: nó `top_level`, origem global fixa, emissor acompanha o ator só para **novos** spawns; linhas já nascidas ficam no mundo.
- `overworld_dash_vfx.gd`: `finish()` limpa speedlines/rastro/poeira no contato, sem fade durante o impacto.
- Testes: esperas de 0,2 s → 0,12 s; ataque total medido em **50 frames (~0,80 s: 0,12 + 0,18 + 0,5)**; **66/66** controlador; **100/100** VFX; ponta a ponta PASS. Vídeos `overworld_attack_player/enemy/contact` e o combinado em **60 fps**.

## Estado

Implementado e testado; demo em slow motion regravada; pendente aprovação visual. Sem commit e sem push.

