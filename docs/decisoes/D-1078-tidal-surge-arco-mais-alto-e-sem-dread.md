<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1078 — Tidal Surge: arco 1,5× mais alto; sem Dread no Tidal Surge e no Bubble Shot

- **Data:** 2026-11-09.
- **Área:** VFX / Tidal Surge (D-1021, D-1077) / aviso Dread da janela de Evade (D-986, D-1016, D-1029).
- **Origem:** pedido do criador na conversa, depois do vídeo v18.
- **Estado:** implementado para revisão em vídeo.

## Frases literais do criador

> faça realizarem um arco mais amplo, maior pra cima. Além disso remova o dread do move, seguindo a lógica das regras novas sobre ele só aparecer se for explicitamente pedido em moves long range (como foi em fire bullet)

Respostas às duas perguntas feitas antes de codar:

> 1,5× mais alto

(pergunta: quanto mais alto deve ficar o pico do arco, hoje distância × 0,24 entre 2,2 m e 7,0 m, no golpe principal e nos bounces)

> por ora, tire no tidal surge e no bubble shot, deixe no electric beam

(pergunta: o código mostra o Dread em todo ataque inimigo, menos no Drain Spear; removo em todos os long range ou só no Tidal Surge?)

## Decisão

1. **Arco:** o pico do arco do Tidal Surge fica **1,5× mais alto**: `distância × 0,36`, entre **3,3 m e 10,5 m** (antes `× 0,24`, 2,2–7,0 m). Vale para o **golpe principal e para os bounces**. Só o desenho muda: tempo de viagem, acerto e dano continuam os da D-1025 (D-019).
2. **Regra do Dread em long range:** o aviso Dread só aparece em Move long range quando for **explicitamente pedido** na confecção do Move, como foi no Fire Bullet (D-1029).
3. **Por ora**, o Dread é removido do **Tidal Surge** e do **Bubble Shot**. O **Electric Beam continua** mostrando o Dread.
4. Os demais projéteis não foram citados e **ficam como estão** no código até decisão do criador (ver divergência abaixo).
5. A janela de Evade em si não muda: só o aviso visual deixa de ser desenhado nesses dois Moves.

## Divergência registrada (não corrigida)

`FxEvadeFlash.update` mostra o Dread em **todo** ataque de inimigo, exceto no Drain Spear (D-1016). Com isso, projéteis sem pedido explícito além do Tidal Surge e do Bubble Shot ainda mostram o Dread, o que contradiz o item 2. O criador limitou a correção a esses dois Moves "por ora"; o Electric Beam fica com o Dread por escolha dele.

## Relações

D-986, D-1016 (Drain Spear), D-1029, D-1039, D-1052, D-1021, D-1025, D-1077, D-235, D-019, D-061.

## Estado no código

- `tidal_surge_vfx.gd`: `ARC_PEAK_RATIO = 0.36`, `ARC_PEAK_MIN = 3.3`, `ARC_PEAK_MAX = 10.5`.
- `fx_evade_flash.gd`: `NO_DREAD_MOVES` (Tidal Surge e Bubble Shot) é pulado no aviso Dread.
- Nada commitado ou publicado (D-022).
