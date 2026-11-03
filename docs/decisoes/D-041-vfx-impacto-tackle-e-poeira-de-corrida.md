# D-041 — Efeitos Visuais Aprimorados: Impacto de Tackle e Poeira de Corrida Física

- **Data:** 2026-11-03
- **Área:** Visual / VFX / Game Feel
- **Origem:** Conversa

## O que o criador disse (literal)

> "e imediatamente ja quero que teste criando um efeito visual melhor pro efeito visual de sofrer um Hit de tackle e pras dusts de corrida deixadas pelo trajeto que correm pra atacar um inimigo com ataques melee e outros ataques fisicos, seja ambicioso e me diga o que ira fazer"

## Decisão

1. **Poeira de Corrida (Run Dust Trail) para Deslocamentos Físicos/Melee:**
   - Remover a supressão de poeira para Tackle/Investida em `_should_emit_travel_dust` e `_on_travel_move` em `scripts/combat/fx/fx_motion.gd`.
   - Implementar três fases de poeira física durante a aproximação:
     - **Arranque (Takeoff Burst):** Estouro de poeira e pedregulhos no ponto inicial (`from`) quando o personagem acelera.
     - **Esteira de Corrida (Ground Wake):** Plumas de poeira volumétrica e partículas no solo acompanhando o modelo durante todo o trajeto.
     - **Frenagem (Arrival Skid):** Poeira direcional de derrapagem ao atingir a posição de ataque (`stand`).

2. **Impacto de Tackle (Punchy Anime Impact VFX):**
   - Substituir malhas geométricas primitivas (cilindros rígidos e toros simples) por composição multicamada anime:
     - **Cone de Pressão de Ar / Choque Sônico:** Malha 3D `shock_cone.glb` com `mesh_slash.gdshader`, projetando onda de choque na direção do golpe (`strike_dir`).
     - **Flipbook de Impacto Anime:** Explosão de impacto com `flipbook_impact.png` de 16 frames com núcleo brilhante.
     - **Estilhaços Cinéticos e Faíscas Direcionais:** Faíscas esticadas em alta velocidade e cascalho espirrando para trás do ponto de colisão.
     - **Onda de Poeira Radial no Solo:** Anel de choque e poeira rasteira expandindo sob os pés do alvo.
     - **Squash & Stretch do Alvo:** Deformação física proporcional no modelo do alvo durante o hit-stop (compressão no eixo do impacto e expansão lateral), recuperando com mola elástica.

3. **Restrições e Preservação:**
   - Zero tremor de câmera ou zoom (preservando estritamente D-020).
   - O visual apenas desenha; sem timers próprios que alterem a linha do tempo ou o relógio do combate (preservando D-019).
   - Nenhuma regra de dano, ATB ou combate é alterada (D-001, D-003).

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma.

## Estado no código

Em implementação.
