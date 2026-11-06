# D-332 — Fogo por shader, flipbook e Composer; referências: Persona, Genshin Impact, Pokémon

- **Data:** 2026-11-05
- **Área:** VFX / Motion Composer
- **Origem:** o criador, depois de eu ter feito vários modelos 3D de fogo no Blender que ele reprovou ("vamos ficar nisso pra sempre vc nao consegue fazer um modelo de fogo bom").
- **Estado:** registrada; implementação em andamento.

## Frase literal do criador

> vamos ficar nisso pra sempre vc nao consegue fazer um modelo de fogo bom

Perguntado qual referência usar como alvo (imagem, jogo, IA ou shader+flipbook), respondeu:

> fogo de persona, genshin impact, pokemon, por shader e flipbook e o MC

## Decisão

1. O **fogo deixa de ser modelo 3D** (a D-327 continua valendo para pedra, vento e água): fogo é **shader + flipbook + Motion Composer**.
2. **Referências de estilo:** o fogo de **Persona**, **Genshin Impact** e **Pokémon**.
3. Continuam valendo D-322 (refazer os 4 do zero, um por vez, com aprovação), D-323, D-308, D-235, D-019.

## Ambiguidades em aberto

- O que exatamente de cada referência (as imagens não foram fornecidas): trato como fogo estilizado de contornos nítidos, cores chapadas em bandas e línguas pontudas, até o criador corrigir.
- Se o `EL_fire_flame.glb` e o `EL_fire_ember.glb` (D-327) devem ser descartados (presumo que sim, por serem reprovados).

## Estado no código (2026-11-05)

Implementado no Composer V1.3 (`docs/vfx/MOTION_COMPOSER_V1.md`, seção 27): shader `mc_fire_cel` (chama de contorno nítido em 3 camadas chapadas), flipbook `fire_cel` assado do mesmo shader, sprite de mistura alfa `mc_sprite`, representações `cel_flame` e `sprite`, e uma demonstração conduzida pelo Composer. **Ainda não está ligado ao Flame Stream nem a nenhum Move**; aguarda a aprovação do criador. Os GLB de fogo da D-327 (`EL_fire_flame`, `EL_fire_ember`) ficam sem uso (decisão de descartar pendente do criador).

## Reprovação das chamas estilizadas e nova direção (2026-11-05)

Criador: "nao gostei estao todos iguais, eu quero um fogo que nao seja modelo, que seja efeito visual, sabe tipo fogo real, com faisca, com rastro, com altra disparidade de opacidade, com um visual flat decent pras cores , com mistura de laranja vermelho amarelo, cores queimadas e preto".
Reprovado o `mc_fire_cel` (chamas em gota idênticas). **Nova versão:** `mc_fire_flow` (campo de calor turbulento em degraus chapados, com preto de fuligem e opacidade muito variável), faíscas com rastro, fumaça de fuligem e halo, tudo pelo Composer (V1.4, seção 28). Demonstração e vídeo: `tests/vfx/fire_real.gd`, `test_captures/fogo_efeito_v1.mp4`. **Ainda não ligado ao Flame Stream.**

## Pesquisa em tutoriais e chamas todas diferentes (2026-11-05)

Criador: "eles estao todos iguais e pra serem diferentes com movimentos diferentes cace por tutoriais na internet e aprenda com eles, fogo nao e tudo igual, cada flame tem que ser completamente diferente uma da outra". Pesquisei (vfxapprentice, Mirza Beig, godotshaders, realtimevfx) e apliquei: forma por semente com curva em S, mordidas em C e gancho; tempo quantizado por chama; ciclo de vida por chama com semente nova a cada ciclo; cor pela idade. Composer V1.5 (seção 29): `mc_flame_one` e `flame_life`; vídeo `test_captures/fogo_efeito_v2.mp4`. **Ainda não ligado ao Flame Stream.**

## Cobrança por não usar o Composer e correção (2026-11-05)

Criador: "ESTAO TODOS IGUAIS AINDA VC NAO ME OBEDECE, VC NEM TA USANDO O MC ... E OBRIGAÇAO SUA USAR OS METODOS OS SKILLS AS COISAS QUE CRIOU". Procedente: a forma e o movimento das chamas estavam sorteados dentro de um shader meu; o efeito vivia em scripts de teste e não no preset nem na batalha real. **Correção (Composer V1.6, seção 30):** cada chama é uma composição do Composer (`MotionPresets.flame_comp`: M03, M09, M24, M12, M17, M18, parâmetros próprios), com ciclo de vida por camada no `MotionEffect`; o fogo agora é `MotionPresets.fire_effect`, usado pelo `ElementMoveVfx` do Flame Stream; verificado na batalha real, nas duas vistas (`test_captures/flame_stream_v3.mp4`). Skills `scenario-godot-vfx` e `scenario-godot-shaders` recarregadas e aplicadas (partículas sem estado, tempo explícito, audit de uniformes).
