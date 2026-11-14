<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1077 — Tidal Surge: overhaul visual completo com texturas

- **Data:** 2026-11-09.
- **Área:** VFX / Biblioteca de projéteis (D-955, D-956) / Tidal Surge (D-1021, D-1025).
- **Origem:** pedido do criador na conversa, depois de ver o bounce desenhado (v15).
- **Estado:** em implementação; aguardando aprovação visual em vídeo (normal + espelhado).

## Frase literal do criador

> Preciso de um video e um overhaul visual completo com texturas pro move

Respostas às três perguntas feitas antes de codar:

> Procedurais no Godot

(pergunta: de onde vêm as texturas, já que o projeto não tem textura de água em `assets/vfx`)

> V9 fixa, malhas refinadas

(pergunta: o overhaul pode mudar as formas ou a silhueta V9 continua fixa)

> Línguas de água arredondadas

(pergunta: o que fazer com as pontas da coroa do release e do impacto, que leem como espinhos de gelo)

## Decisão

1. O Tidal Surge recebe um **overhaul visual completo com texturas**, entregue em **vídeo** (normal + espelhado, D-308).
2. **Texturas:** **procedurais, geradas no Godot** (ruído celular/espuma/cáusticas sem emenda) e salvas como PNG em `assets/vfx/water/`; o fluxo vem de rolagem de UV no shader. Nada gerado por IA nem fornecido por arquivo externo.
3. **Limite de forma:** a **V9 continua sendo a identidade** (arco de água em tubo + duas fitas + cabeça, coroa 3D de 16 pontas, vórtice no chão à frente, cauda que descola e é consumida, bounce como nova onda). As **malhas podem ser refinadas**: arredondar pontas, variar espessura, trocar a cabeça e redesenhar as malhas do impacto. Trocar a silhueta do corpo (onda larga de folhas, fita UV Panning, tubo liso) continua **proibido** (D-1021).
4. **Pontas da coroa (release e impacto):** viram **línguas de água arredondadas** — as mesmas 16 pontas 3D, em forma de gota/língua curva, com ponta de espuma e alfa texturizado. Sem cones pontudos (leitura de gelo, D-397).
5. **Nada de mecânica muda** (D-019, D-1025): dano, tempos, ATB, MP, bounces, esquiva, hit-stop e câmera ficam intocados. D-1073 continua: o projétil não empurra o alvo.
6. O shader `shaders/lib_water_ribbon.gdshader` (UV Panning) continua guardado e **fora** do Tidal.

## Rastro de gotas do trajeto removido (2026-11-09)

> remove isso

(com o recorte do vídeo v18 mostrando a fileira de discos claros atrás da cabeça do arco)

7. O **rastro de gotas do Motion Composer no trajeto** (`tidal_wake`, M24 + `drops`) foi **removido** do Tidal Surge, no golpe principal e nos bounces. Ele lia como uma fileira de discos claros chapados e ficava ao lado do alvo depois do impacto. As gotas feitas à mão que caem do arco e o anel de gotas do Composer na coroa do release **continuam**.

## Ambiguidades em aberto

- **Wind-up escondido na vista normal:** o vórtice fica à frente do atacante (decisão do criador em D-1021), então, com o atacante perto da câmera, o corpo dele cobre boa parte do vórtice. Não foi pedido mudar a posição; fica como está até decisão.
- **Bounce na vista espelhada:** a sala `--dqt-mirror` monta um só aliado como alvo, então a cadeia não acontece nessa vista. Testar exige uma opção nova na sala de debug, não pedida.

## Relações

D-1021, D-1025, D-1073, D-308, D-235, D-954, D-1030, D-974, D-1033, D-397, D-337, D-418, D-019, D-022, D-061.

## Estado no código

**Primeira passada implementada (v17), aguardando aprovação visual.** Nada commitado ou publicado (D-022).

- **Textura:** `tools/bake_water_textures.gd` gera `assets/vfx/water/water_flow.png` (256×256, sem emenda; R = teia de cáusticas, G = ruído suave, B = quebra de espuma), importada com mipmaps.
- **Shaders novos:** `shaders/lib_water_tex.gdshader` (corpo, línguas e folhas: duas cópias roladas da teia, crista de espuma quebrada, dissolução por erosão, cauda esfiapada), `shaders/lib_water_disc.gdshader` (disco polar no chão: vórtice em espiral e anéis de espuma) e `shaders/lib_water_mist.gdshader` (névoa em billboard). `lib_water_wave.gdshader` deixou de ser usado pelo Tidal e foi mantido no disco; `lib_water_surface.gdshader` continua nas gotas, no núcleo e na cabeça.
- **Malhas (`tidal_surge_vfx.gd`):** vórtice = disco texturizado em espiral + aro de espuma (no lugar dos dois toros) + as 10 folhas com altura irregular; coroa e impacto = 16 **línguas arredondadas** (ponta em cúpula, curva para fora, alternando altas/baixas) que sobem, tombam, afundam e erodem; corpo = tubo de 12 lados com UV em metros, cauda fina → frente arredondada mais pesada, espessura ondulando; impacto = línguas + espuma curta + anel de espuma no chão + 24 gotas em arco balístico + 6 névoas.
- **Bounce desenhado:** `fx_motion.gd` cria/encerra o corpo do bounce (o `Incoming` do bounce chegava com `data` vazio e nunca era desenhado); `fx_impacts.gd` marca o impacto no corpo do bounce.
- **Verificado:** `test_d1025_tidal_surge` PASS; `test_contract` 0 falhas; `--audit-leaks` com `leaks=0` nas duas vistas; nenhum `[POP_DETECTED]` com `--envelope-graph`; quadros em tamanho real das duas vistas. Vídeo: `test_captures/tidal_surge_overhaul_slime_v17.mp4` (trio na vista normal: principal + 2 bounces).
- **Não verificado:** bounce na vista espelhada; outros atacantes (Abra) e alvos grandes (Cyclops); `--overdraw`, `--scale-overlay`, `--bg`, `--proof-sheet`; as auditorias rodaram com encontro sorteado, sem garantia de bounce.
- **Fraco:** de perto, o corpo sendo consumido pela cauda ainda fica claro demais; no fim da coroa as línguas ainda aparecem como ovais claros no chão por ~0,1 s; o bounce a ~37 m é pequeno e pálido.
