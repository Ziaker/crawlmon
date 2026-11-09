# D-1084 — Orc/DQT: idle com `idle_full` toca uma vez e segura, sem repetir

- **Data:** 2026-11-09.
- **Área:** Exploração / lab / animação de aliados DQT.
- **Relacionadas:** D-1023 (lab), D-340/D-341 (DQT), D-1063 (NPCs).
- **Status:** **teste implementado e verificado** no lab isolado; batalha, 2D, HUD/status, cards e regras não mudam; commit local; **sem push**.

## O que o criador disse (literal)

> tem como ajeitar a animação do orc que fica repetindo toda hora ao invés de estar no idle quando parado?

## Causa

O perfil `dqt_orc` usa `idle_source = "32"` (Ready/parado) e `idle_full = true`. O `apply_anim_aliases` cria o alias `idle` com `LOOP_NONE`, mas o `_make_model` do lab força depois:

```gdscript
for anim_name in ["idle", "walk", "run"]:
    ap.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
```

Isso sobrescreve o `LOOP_NONE` do Orc e faz o clipe inteiro do Ready repetir em loop. O mesmo acontece com `dqt_cyclops` e `dqt_slime`, que também têm `idle_full`.

Depois de preservar o `LOOP_NONE`, a auditoria mostrou `idle loop=0`, mas a posição ainda reiniciava a cada ~1,93 s. A segunda causa: quando um clipe `LOOP_NONE` termina, o `current_animation` fica vazio; o `_play` então chamava `ap.play("idle", 0.15)` de novo, reiniciando o Ready. Ou seja, não era o clipe loopando, e sim o lab re-tocando o idle quando ele terminava.

## Decisão

1. No `_make_model`, forçar `LOOP_LINEAR` em `walk`/`run` como antes.
2. Para `idle`, **preservar o loop definido pelo perfil**: se o perfil DQT tem `idle_full = true`, não sobrescrever `LOOP_NONE`; o clipe toca uma vez e segura o último quadro.
3. No `_play`, **não reiniciar** um `idle` que já terminou: usar o marcador `idle_held` no `AnimationPlayer`; quando o idle `LOOP_NONE` chega ao fim e o `current_animation` fica vazio, o lab mantém o último quadro. Andar/zigue-zague limpa o marcador e permite o próximo idle tocar uma vez.
4. Perfis sem `idle_full` (Pokémon e NPCs DQT) continuam com idle em loop.
5. Batalha, `CharacterModelLoader`, 2D, HUD/status, cards e regras não mudam.

## Teste implementado (2026-11-09)

Auditoria no lab isolado (`scratch/third_person_lab/audit_orc_idle.tscn`), física rodando, com três fases: parado → andando (`ui_up`) → parado.

- `idle loop=0`, `length=1,933`; `walk_loop=1`; `run_loop=1`.
- Parado desde o início: o idle toca de `0` a `1,93` e então fica em `pos=1,93`, `playing=false`, `current_animation=""` — sem reiniciar, por mais de 150 quadros.
- Andando: `anim=walk`, velocidade ~3,3, `playing=true`.
- Ao parar: o idle toca **uma vez** (`idle_start_after_stop`) e segura em `1,93`; `idle_restarts=0` até o fim da auditoria (331 quadros).
- Sem `SCRIPT ERROR`; saída `exit=0`.
- O mesmo vale para `dqt_cyclops` e `dqt_slime` por usarem `idle_full`.
- Provas regravadas com o Orc em idle segurado: `murky_forest_status_party.mp4/.gif`, `murky_forest_status_contato.png`, `murky_forest_hud_sugimori.png`, `murky_forest_hud_sugimori_cards.png` e `murky_forest_status_hidden.png`.
- A gravação solo **não** foi regravada porque não tem Orc; os arquivos solo continuam os de D-1083.

## O que não foi verificado

- Se o último quadro do Ready do Orc é a pose desejada para “parado”; ele deixa de repetir, mas continua tocando o clipe uma vez ao parar.
- O mesmo teste com a câmera/formação sob colisão, escada ou paredes (a auditoria foi no corredor livre).
- A cena principal em headless continua bloqueada pelos erros de VFX de outra sessão; teste no lab isolado.
- Batalha não foi aberta; a mudança é só no lab.

## Estado

Teste implementado e verificado no lab isolado: o Orc não repete mais o idle quando parado. Commit local; **sem push**. Nada de combate/2D/HUD mudou.
