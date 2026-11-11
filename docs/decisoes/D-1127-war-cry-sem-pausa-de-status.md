# D-1127 — War Cry sem pausa de status (teste do criador)

- **Data:** 2026-11-10
- **Área:** Combate / War Cry / pausa de status (D-031)
- **Origem:** pedido do criador depois de ver os vídeos do War Cry.
- **Status:** **implementado; experimental** — o criador quer ver o Move sem a pausa do motor. Não é uma regra permanente até ele confirmar.

## O que o criador disse (literal)

> "O move tá ocorrendo antes do que devia, o efeito está estranho por conta da regra de pausar as coisas, remova esta pausa APENAS NESTE MOVE pra eu ver uma coisa"

## Decisão

1. **Só o War Cry** deixa de pausar o motor. Todos os outros Moves de status continuam com a pausa da D-031.
2. A pausa removida é a **pausa global do motor** (D-031): ATB, preparos, ataques, IA e movimento dos outros personagens **continuam correndo** durante o War Cry.
3. O que **não** muda no War Cry:
   - custo **3 ATB / 3 MP** (D-1102);
   - wind-up **0,3 s** e o valor registrado de `status_pause = 1,3 s` no `.tres` (a pausa é ignorada, não o dado);
   - interrupção apenas de quem está em **WINDUP**;
   - **+1 Burst** uma vez por execução se interromper ao menos um;
   - sem dano, STUN ou empurrão;
   - VFX do D-1106 (cone branco/creme, anéis, pulsos brancos de 0,35 s).
4. A faixa com o nome do Move e o início/fim do VFX continuam acontecendo; o fim da faixa passa a ser emitido quando o War Cry termina (ou é cancelado), já que não existe mais a pausa para fechá-la.

## Ambiguidades em aberto

- Se o criador aprovar o resultado, decidir se esta exceção vira regra permanente do War Cry ou se a pausa volta.
- O tempo total do Move sem a pausa (wind-up + fases) não foi alterado por esta decisão; só a pausa global foi removida.

## Estado no código

- `scripts/combat/battle.gd`: War Cry não entra em `_status_pause`; o sinal `status_pause_started` continua sendo emitido para o VFX/faixa, e `status_pause_ended` é emitido quando o Move termina ou é cancelado (`_finish_war_cry_if_done`).
- `scripts/combat/battle_fx.gd`: o War Cry inicia o VFX antes do congelamento dos outros animadores, então não congela ninguém.
- `scripts/ui/battle_hud.gd`: o token de Burst passa a mirar o **centro real do slot** no cartão e na tag do inimigo (antes parava ~25 px à esquerda, sobre HP/MP).
- `tests/battle/test_d1102_war_cry.gd`: atualizado para a D-1127; mede **1,21 s** de Move sem pausa e confirma `_status_pause == null`.
- Nenhum outro Move de status foi alterado.
- Vídeos: `test_captures/vfx_tools/war_cry_final7_nopause_normal.mp4`, `_mirrored.mp4`, `_dqt_normal.mp4` e `_dqt_mirrored.mp4`.

## Complemento D-1147 (2026-11-11)

O criador confirmou que **o congelamento visual das animações dos outros durante o War Cry é feature**, não bug. O que a D-1127 removeu foi só a pausa do **motor** (`_status_pause`); a animação dos personagens em ataque/retorno continua congelando durante o grito. O War Cry também perde a aura genérica da D-031 e o cone não nasce em cast cancelado. Detalhes em `docs/decisoes/D-1147-war-cry-congelamento-visual-feature.md`.

## Verificado

- Teste D-1102 atualizado passa (ficha, dois wind-ups cancelados, +1 Burst, sem dano/empurrão, ataque fora do WINDUP não é cancelado).
- `--audit-leaks` = `leaks=0`; `envelope_pops` vazio.
- As duas vistas (normal/espelhada) e o par DQT foram gravados; token de Burst pousando no slot do cartão.

## Não verificado

- Aprovação visual do criador para o War Cry sem pausa.
- Se a animação do caster (`attack_special`, 2,2 s em Abra) deve ser acelerada; esta rodada **não** alterou a velocidade de animação.
