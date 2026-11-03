# D-035 — VFX 3D e Shaders para Buffs/Debuffs SMT (Tarukaja, Rakunda, Sukunda)

- **Data:** 2026-11-02
- **Área:** Visual / VFX
- **Origem:** Conversa (Grill-Me)

## O que o criador disse (literal)

> [Envio do documento e protótipo de especificação: Crawlmon_SMT_Buffs_VFX_Spec-v2 e protótipo HTML de Tarukaja, Rakunda e Sukunda Amarelo]
>
> Respostas no Grill-Me:
> - Escopo: "Apenas VFX 3D & Shaders: Implementar o shader (smt_stage_vfx.gdshader), as geometrias procedurais e o controlador dos buffs (Tarukaja, Rakunda, Sukunda amarelo) no Godot."
> - Arquitetura: "Criar cena independente SmtStageVfx.tscn instanciada via SmtBuffController separado, desacoplado do fx_impacts.gd."
> - Overlay 2D: "Sim, incluir o popup 2D flutuante ('↗ ATK +1', '↘ DEF -1', '↯ SPD -1') projetado via camera.unproject_position() diretamente em SmtStageVfx."
> - Áudio: "Foco estritamente visual (sem áudio): Focar 100% na fidelidade visual dos shaders, anéis, geometrias orbitais e popup 2D."
> - Duração: "1.00 segundo (alinhado com o tempo padrão atual de pausa de status em battle.gd)."
> - Diretórios: "Diretório dedicado smt_vfx/: Criar pasta dedicada scenes/vfx/smt/ e scripts/vfx/smt/ para todos os recursos dos buffs SMT."
> - Conexão: "continua" (battle_scene instancia SmtBuffController e conecta aos eventos de combate).

## Decisão

1. **Cores e Temática Oficial SMT**:
   - **Tarukaja**: `#D7FD6A` (Verde-Lima), buff de Ataque (+1), movimento ascendente dos anéis e cones/lanças orbitais.
   - **Rakunda**: `#FF624F` (Coral), debuff de Defesa (-1), movimento descendente de esmagamento e cunhas orbitais invertidas.
   - **Sukunda**: `#F7CB78` (Amarelo/Ouro), debuff de Agilidade/Velocidade (-1), anéis amarelos descendentes, cubos de inércia orbitais e duplo anel de estase no solo. (O amarelo foi mantido para não colidir com o roxo do Mago aliado).

2. **Geometria Procedural e Shader Espacial**:
   - Criar `shaders/smt_stage_vfx.gdshader` com `spatial`, `unshaded`, `blend_add`, `cull_disabled`, `depth_draw_never`, fresnel e scanlines sinusoidais animados.
   - Cena `scenes/vfx/smt/smt_stage_vfx.tscn` controlada por `scripts/vfx/smt/smt_stage_vfx.gd`.
   - 3 anéis verticais com `CylinderMesh` vazado (raios correspondentes).
   - Pivô orbital (`Node3D`) com geometria temática (lanças para Tarukaja, cunhas para Rakunda, cubos de inércia para Sukunda).

3. **Overlay 2D Flutuante**:
   - Popup projetado na tela via `camera.unproject_position()` exibindo:
     - Tarukaja: `↗ ATK +1` (Verde-Lima)
     - Rakunda: `↘ DEF -1` (Coral)
     - Sukunda: `↯ SPD -1` (Amarelo)
   - Transição com tween de subida e fade out.

4. **Duração**:
   - Duração da sequência visual de 1.00 segundo, perfeitamente sincronizada com a pausa do motor de status da D-031.
   - Autodestruição (`queue_free()`) ao final da animação.

5. **Organização e Desacoplamento**:
   - Estrutura em pastas dedicadas: `scenes/vfx/smt/` e `scripts/vfx/smt/`.
   - `SmtBuffController` desacoplado de `fx_impacts.gd`, instanciado na cena de batalha (`battle_scene.gd`) ouvindo o sinal `battle.hit_resolved`.

## Ambiguidades em aberto

- Nenhuma pendência; todas as etapas alinhadas no Grill-Me.

## Estado no código

- Em implementação.
