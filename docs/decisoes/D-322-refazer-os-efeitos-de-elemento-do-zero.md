# D-322 — Refazer do zero os efeitos de elemento (fogo, água, terra, ar) com qualidade visual extrema

- **Data:** 2026-11-05
- **Área:** VFX / Motion Composer / Processo
- **Origem:** pedido direto do criador, ao ser perguntado o que fazer com o texto colado (protocolo VFX + proposta D-274).
- **Estado:** registrada; **nenhum código escrito**; ambiguidades abaixo em aberto.

## Frase literal do criador

> refazz todos do zero, use as skills, shaders do godot, o MC, quero qualidade visual extrema, se não conseguir me dar uma qualidade visual digna, então melhore o MC até conseguir

## Decisão

1. Refazer **do zero** os efeitos dos quatro elementos da D-274 (fogo, água, terra, ar), sem partir do que existe.
2. Usar as skills `scenario-godot-vfx` e `scenario-godot-shaders`, os shaders do Godot e o Motion Composer.
3. Meta: **qualidade visual extrema**. Se o Motion Composer não der conta, **melhorá-lo até conseguir** (D-308 item 4, protocolo seção 0).
4. Continuam valendo, sem mudança: `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md`, D-235, D-308 (quatro fases, carga que vira o tiro, tamanho fixo, vídeo normal + espelhado) e D-019.

## Respostas do criador (2026-11-05, em seguida)

- **Escopo:** "Sim, os 4 do zero" — o fogo (Flame Stream) também é refeito do zero.
- **Ordem:** "Um por vez, com aprovação" — um vídeo (normal + espelhado) por elemento; só avanço ao próximo com o OK do criador. O criador **não disse a ordem**; começo pelo fogo por ser o único que já tem Move na sala de VFX (corrigir se não for isso).
- **Moves:** água, terra e ar têm a **mesma forma do Flame Stream**: projétil de alvo único com as 4 fases; só o visual muda (jato com respingo, erupção de fragmentos, rajada curva, conforme a tabela da D-274).

## Ambiguidades em aberto (perguntar antes de agir)

- Referências visuais por elemento além do estilo do jogo e da tabela da D-274 (nenhuma foi dada).
- As regras específicas do Flame Stream da D-308 (cone de fogo e brasas no impacto, vórtices 0,2 s + 0,5 s, tamanho fixo, impacto reduzido) valem para o fogo refeito? (Presumo que sim, por serem frases do criador sobre o fogo; as análogas para água/terra/ar não existem.)

## Estado no código (2026-11-05)

**Fogo (Flame Stream) refeito do zero, 1º elemento; aguardando a aprovação do criador.** Motion Composer **V1.1** (`docs/vfx/MOTION_COMPOSER_V1.md`, seção 25): tubo 3D (`MotionMesh`), esfera de chama, flipbook e anel como representações; shader `mc_flame_body`. Preset novo `MotionPresets.fire_effect`; `ElementMoveVfx` só entrega posições e relógios (sem aparência). Tamanho **fixo em metros** (`WORLD_SCALE = 1.0`), igual nas duas vistas, conforme a frase literal da D-308.

**Consequência visível (a decidir pelo criador):** com tamanho fixo em metros, na vista normal o alvo está a ~37 m e o voo/impacto ficam pequenos na tela; na espelhada é o wind-up (atacante longe) que fica pequeno. Se o criador quiser o mesmo tamanho **na tela**, é um parâmetro (`ElementMoveVfx._scale_at`).

Água, terra e ar: **não iniciados** (um por vez, com aprovação; D-322).
Verificado: 5 suítes do MC sem falhas; batalha real nas duas vistas, quadros 1280x720; nada sobra na tela no fim (quadro 4,47 s). Não verificado: desempenho, outros atacantes/alvos além de Abra→Gible, a aprovação artística.
