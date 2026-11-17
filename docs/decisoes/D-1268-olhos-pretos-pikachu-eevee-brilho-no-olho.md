> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Nenhum teste passa de 1 minuto: ver `--view=npc_eyes` abaixo (~5 s).

# D-1268 — Olhos pretos do Pikachu e do Eevee: brilho no olho

## Frase literal do criador
> "PIKACHU E EEVEE TÃO COM OS OLHOS PRETOS, EU MANDEI AJEITAR ESSA MERDA TAMBÉM"

## Causa (medida)
Os GLBs `pikachu.glb` e `eevee.glb` trazem a textura de olho (`*_eye_alb_l/r_eye_base.png`) **chapada em (15,15,15)**, sem nenhum detalhe: o brilho (catchlight) do jogo original vive numa máscara/camada de especular que não foi exportada, e os materiais não têm emissão nem textura extra. Material com `roughness 0.8` e sem reflexo → vazio preto. Charmander, Bulbasaur e Gible têm olho pintado na textura, por isso aparecem certos. Não é problema do toon (`_apply_toon_to_actor` só troca modo difuso/especular) nem de import.
Diagnóstico: `tests/overworld/diag_eye_materials.gd`, `diag_eye_uv.gd`.

## Decisão técnica (detalhe técnico, não regra de jogo)
`scripts/common/eye_shine.gd` (`EyeShine.apply(glb)`), genérico e por dado, não por espécie (D-235): todo material `*_eye` cuja textura de albedo é uniforme ganha a mesma cor-base escura mais um brilho branco grande (alto-direita) e um pequeno (baixo-esquerda) pintados no UV do olho. Olhos já pintados não são tocados. Chamado nos três carregadores de GLB: `third_person_3d_lab.gd::_make_model` (hub, Murky Forest), `character_model_loader.gd` (combate) e `model_3d_view.gd`.
**Posição, tamanho e número dos brilhos são escolha minha (pendente de aprovação do criador).**

## Verificação
- `tests/overworld/diag_eye_shine.gd`: patched=2 só em pikachu e eevee; 0 em todas as outras espécies (olhos delas inalterados).
- `--view=npc_eyes` / `--view=npc_eyes_close` `--npc=<id>` em `scenes/debug/hub_3d_prototype.tscn` (câmera de jogo e aproximada); capturas em `docs/capturas_olhos/`.
- Combate: `tests/overworld/diag_combat_model_eyes.gd` (usa `CharacterModelLoader`) mostra brilho em Pikachu e Eevee e Charmander igual (`docs/capturas_olhos/combate_pikachu_eevee_charmander.png`).
- Não verificado: batalha completa na sala de debug (a sala só carrega Abra/Pancham/DQT; `--units=` documentado não está implementado) e Murky Forest com captura própria (mesmo `_make_model`); piscar do Pikachu/Eevee não existe no GLB e não foi mexido.

## Piscar automático (implementado)
- Os GLBs não trazem piscar: as pálpebras só se mexem em ataque/dano/queda/vitória, a abertura mínima varia por espécie (Charmander 17%, Eevee 72%, Pikachu ~100%) e os ossos de pálpebra de Pikachu/Eevee não cobrem o olho (testados: rotação por geometria e achatar o olho; a pele tem um buraco atrás do olho).
- Solução (`scripts/common/eye_blink.gd`, ligada por `EyeShine.apply`, então vale nos 3 carregadores): as pálpebras são desenhadas na própria superfície do olho por shader. Cor de pele cobre de cima e de baixo até se encontrarem, com linha de cílios escura; a cor da pele é MEDIDA em cada modelo (média do albedo dos 14 vértices de corpo mais próximos do olho) e o eixo vertical vem do UV da superfície do olho (faixa de v, compatível com atlas). Nada por espécie: vale para todo `*_eye` de qualquer modelo novo (Pikachu, Eevee, Charmander, Bulbasaur, Gible testados).
- Ritmo (valores padrão escolhidos por mim, o criador pode mudar): intervalo aleatório 2,4–5,2 s; fecha em 0,06 s, segura 0,05 s, abre em 0,09 s. Cada boneco pisca independente.
- Verificação: `tests/overworld/diag_blink_solver.gd` (aberto/fechado por espécie), `diag_blink_timing.gd` (2 piscadas em 8 s, pico 1,0), hub `--view=npc_eyes_close --npc=<id> --blink=1|0`, combate via `diag_combat_model_eyes.gd` (olho aberto inalterado). Capturas em `docs/capturas_olhos/piscar_*.png`.
- Clipes: `tests/overworld/diag_blink_clips.gd` (olho forçado fechado durante damage/attack/victory, câmera seguindo o osso `head`): a pálpebra acompanha a cabeça em Pikachu e Eevee (`docs/capturas_olhos/piscar_durante_clipes_dano_ataque_vitoria.png`).
- Testes de combate (`run_agent_combat_tests.py`): 124/126. As 2 falhas (Employ D-1239 "returning" e Javelin Throw D-235) emitem `material_get_instance_shader_parameters: Parameter "material" is null` (renderer dummy do headless); o erro aparece IGUAL com o piscar desligado, então não vem do piscar; causa não investigada.
- Cor da pele: multiplicador 0,89 sobre a média medida; em Eevee/Charmander o remendo ainda difere levemente da pele ao redor.
- Não verificado: Murky Forest e batalha real com captura própria (usam `_make_model`/`CharacterModelLoader` já testados); câmera de jogo do hub mostra o olho com poucos pixels, então o piscar ali é pouco legível; modelos DQT (olhos próprios, D-340) não usam este código.
