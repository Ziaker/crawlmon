<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1176 — Javelin Throw: Dread na ponta da javelin e passagem perfurante no impacto

- **Data:** 2026-11-11.
- **Área:** VFX / Javelin Throw / Dread.
- **Origem:** ordem direta do criador no chat.

## O que o criador pediu (literal)

> "quero que esse move tenha o dread mas na javelin, na ponta, seguindo-a. alem disso no contato e impacto, ao inves da javelin travar no inimigo ela passa por ele, perfurando"

## Decisão

1. **Dread na ponta da javelin:** o Javelin Throw passa a ser uma exceção de Dread como o Fire Bullet (D-1029). O aviso de evade (`FxEvadeFlash`) aparece **na ponta real da javelin**, seguindo a posição da ponta quadro a quadro, em vez de no corpo/mão do atacante. Vale para qualquer atacante, time, lado e câmera (D-235).
2. **Não trava no impacto:** no contato, a javelin **não fica fincada** no chest. Ela continua no mesmo eixo do voo, atravessa o alvo e só desaparece depois que a cauda passa. O impacto (cruz, flash, anéis, solo) continua no ponto de contato.
3. **Regras intactas:** dano, crítico, custo, ATB/MP, janela de evade e a decisão de acerto continuam sendo do combate (D-019/D-1040, D-1103). O visual só lê o estado real.

## Primeira passada implementada (para revisão em vídeo)

- **Dread:** usa o mesmo `FxEvadeFlash` (aro/estrela/raio atuais), ancorado em `javelin_tip()`. Tamanho normal derivado do corpo (sem o 1,2× do Fire Bullet, que é específico da D-1052) e timing padrão do Dread (janela de evade + fade). Só aparece em ataque inimigo mirando o líder, como D-1168.
- **Passagem:** após o contato, a javelin avança no eixo por **2,6 m** (escalado pelo `view_scale`) ao longo de **0,45 s**, com o tremor de impacto nos primeiros 0,15 s; depois é ocultada. A cauda (2,279 m atrás do chest no contato) termina além do alvo, então a passagem é visível de ponta a cauda.
- **Impacto:** a cruz/flash/anel continuam no chest congelado; a javelin atravessa por cima/por dentro, sem parar.

## Ambiguidades em aberto

1. O Dread deve usar o timing padrão (janela + fade) ou terminar **antes do impacto** como o Fire Bullet (D-1039)? Nesta primeira passada usei o padrão.
2. O tamanho do Dread na javelin deve ser o normal ou maior (o Fire Bullet usa 1,2× por D-1052)?
3. A passagem de 2,6 m / 0,45 s é a primeira passada; o criador pode pedir mais rápida/lenta/curta/longa.

## Estado no código

**Primeira passada implementada; aguardando revisão em vídeo.** `JavelinThrowVfxHtml.javelin_tip()` entrega a ponta real; `fx_javelin_throw.gd` guarda o nó no `Incoming.data`; `fx_evade_flash.gd` trata Javelin como o Fire Bullet; `_update_release` continua a javelin no impacto em vez de fixá-la.

## Evidência

- **Dread:** no vídeo de câmera do jogo (`javelin_throw_orc_both_sides.mp4`), a linha espelhada mostra o anel/estrela do Dread na **ponta da javelin do Orc inimigo** em ~1,50 s; a linha normal (jogador atacando) não mostra Dread, só a estrela da própria javelin.
- **Passagem:** no vídeo de alvo próximo (`javelin_throw_target_view.mp4`), o IMPACTO/RETURN mostra a javelin **atravessando** o alvo na horizontal, com a cauda passando; ela não fica fincada.
- **Testes:** `test_javelin_vfx.gd` → `RESULT: PASS`; D-235 → `PASS`; `leaks=0`; suíte **27/27**.
- **Vídeos:** `test_captures/javelin_throw_orc_both_sides.mp4`, `javelin_throw_side_view.mp4`, `javelin_throw_target_view.mp4`; frames `dread_check_150.png`, `pass_side_230.png`, `pass_side_250.png`.
