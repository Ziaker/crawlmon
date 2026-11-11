# Catálogo — Biblioteca VFX 3D (HTML)

Protótipo isolado. **Nada aqui foi integrado ao jogo.** Estado de todos os itens:
**Protótipo funcional** — executa e foi capturado; **aprovação visual pendente**.

- 20 componentes (`LIB-VFX-01`…`20`) + 5 demonstrações (`DEMO-01`…`05`) + 1 extra do projeto.
- Renderer do laboratório: Three.js 0.169 (WebGL2), bloom Unreal + ACES.
- Palco: atacante na origem, alvo no eixo, distância 2,5–8 m, espelhável.
- Tempo: scrub determinístico (reconstrói do zero com RNG semeado).

## Visão geral

| ID | Nome | Família | Estado | Parâmetros principais |
|---|---|---|---|---|
| LIB-VFX-01 | Vortex Mesh | A — vórtices | Protótipo funcional | boca, altura, giro, partículas |
| LIB-VFX-02 | Tornado / Funnel | A — vórtices | Protótipo funcional | altura, abertura, torção, opacidade |
| LIB-VFX-03 | Spiral Ribbon | A — vórtices | Protótipo funcional | raio, altura, voltas, largura, fluxo |
| LIB-VFX-04 | Helix Cylinder | A — vórtices | Protótipo funcional | raio, comprimento, voltas, espessura, velocidade |
| LIB-VFX-05 | Spiral Erosion | A — vórtices | Protótipo funcional | borda, peso da espiral, brilho |
| LIB-VFX-06 | Thrust Cone | B — dash | Protótipo funcional | comprimento, abertura, intensidade |
| LIB-VFX-07 | Speed Lines | B — dash | Protótipo funcional | quantidade, comprimento, velocidade |
| LIB-VFX-08 | Motion Trail | B — dash | Protótipo funcional | largura, persistência |
| LIB-VFX-09 | Aura Burst | B — dash | Protótipo funcional | alcance, altura, traços |
| LIB-VFX-10 | Dust Trail | C — solo | Protótipo funcional | tamanho, densidade, subida |
| LIB-VFX-11 | Brake Dust | C — solo | Protótipo funcional | abertura, impulso, tamanho |
| LIB-VFX-12 | Ground Scratch | C — solo | Protótipo funcional | comprimento, largura, fragmentos |
| LIB-VFX-13 | Shockwave Ring | D — impacto | Protótipo funcional | raio máximo |
| LIB-VFX-14 | Impact Crown | D — impacto | Protótipo funcional | pontas, altura, raio |
| LIB-VFX-15 | Blast Cone | D — impacto | Protótipo funcional | comprimento, abertura, intensidade |
| LIB-VFX-16 | Ground Fracture | D — impacto | Protótipo funcional | raio, ramos |
| LIB-VFX-17 | Anime Impact Flipbook | E — complementos | Protótipo funcional | tamanho, quadros/s, intensidade |
| LIB-VFX-18 | Kinetic Sparks | E — complementos | Protótipo funcional | quantidade, velocidade, gravidade |
| LIB-VFX-19 | Directional Debris | E — complementos | Protótipo funcional | quantidade, tamanho, gravidade |
| LIB-VFX-20 | Slash Arc | E — complementos | Protótipo funcional | ângulo, raio, espessura |
| DEMO-01 | Anime Dash | Composição | Protótipo funcional | palco (direção/distância) |
| DEMO-02 | Punchy Anime Impact | Composição | Protótipo funcional | palco |
| DEMO-03 | Energy Helix | Composição | Protótipo funcional | palco |
| DEMO-04 | Vortex / Tornado Study | Composição | Protótipo funcional | palco |
| DEMO-05 | Stylized Slash | Composição | Protótipo funcional | palco |
| EXTRA | Attack Prelude / Hit-windup | Extra do projeto | Protótipo funcional | palco |

## Construção por componente

### LIB-VFX-01 — Vortex Mesh
- **Geometria:** duas cascas de funil (`funnelGeometry`, twist oposto) + disco plano em coordenadas polares + 640 pontos.
- **Material:** shader com bandas helicoidais, streaks e ondulação radial no vertex; disco com espiral logarítmica.
- **Animação:** rotação contínua, partículas sobem e convergem; `uTime` controla o fluxo.
- **Referencial:** mundo (estudo de forma), sem personagem.
- **Godot:** equivalente com `ArrayMesh` + shader `spatial`/`unshaded`, sem partículas GPU obrigatórias.
- **Limite:** o disco ainda lê como anéis concêntricos em alguns ângulos.

### LIB-VFX-02 — Tornado / Funnel
- **Geometria:** três funis com raios/twists distintos.
- **Material:** vertex shader com ondulação radial (silhueta irregular) + listras longitudinais.
- **Animação:** camadas giram em sentidos diferentes; poeira na base.
- **Godot:** mesma malha procedural + shader; poeira por `CPUParticles3D`/flipbook.

### LIB-VFX-03 — Spiral Ribbon
- **Geometria:** fita (2 vértices por ponto) sobre hélice paramétrica, `up` radial por ponto.
- **Material:** pulso viajando pela fita, núcleo fino separado.
- **Animação:** rotação lenta do conjunto.
- **Limite:** a fita é fina; de perto pede mais segmentos.

### LIB-VFX-04 — Helix Cylinder
- **Geometria:** `TubeGeometry` sobre `CatmullRomCurve3` × 3 correntes + cilindro central.
- **Material:** bandas de energia no tubo; halo por segunda malha; núcleo com borda suave.
- **Animação:** rotação do grupo + bandas correndo.
- **Godot:** `ImmediateMesh`/`MeshDataTool` ou GLB `ribbon_trail` adaptado.

### LIB-VFX-05 — Spiral Erosion
- **Geometria:** `TorusKnotGeometry` (superfície de teste).
- **Material:** noise 3D + campo espiral + limiar progressivo com `discard`; borda incandescente.
- **Animação:** progresso em loop + brasas.
- **Godot:** shader com textura de ruído; `discard` é compatível com GL Compatibility.
- **Limite:** máscara procedural, não textura autoral.

### LIB-VFX-06 — Thrust Cone
- **Geometria:** cilindro aberto (cone) + anel de bocal + sprite.
- **Material:** `coneMaterial` — listras longitudinais e fresnel de silhueta (não é “mola” de anéis).
- **Animação:** acompanha o deslocamento real do palco; poeira no rastro.
- **Godot:** malha `shock_cone.glb` como base + shader equivalente; sem refração.

### LIB-VFX-07 — Speed Lines
- **Geometria:** `InstancedMesh` de caixas finas (com espessura, ao contrário de `LineSegments`).
- **Animação:** fluxo relativo ao eixo do palco, em volta do emissor.
- **Godot:** `MultiMeshInstance3D` com quads alongados.

### LIB-VFX-08 — Motion Trail
- **Geometria:** anel de 120 amostras reconstruído em fita a cada frame.
- **Material:** gradiente ao longo do histórico, pulso correndo.
- **Animação:** histórico real de posição; preserva a curva anterior.
- **Godot:** `ImmediateMesh`/`ArrayMesh` com orçamento de segmentos.
- **Limite:** reconstrução por frame é caro para muitas instâncias.

### LIB-VFX-09 — Aura Burst
- **Geometria:** `InstancedMesh` de traços orientados por vetor + anel + flash.
- **Animação:** expansão com `easeOut`, fade global; evento de impulso, não aura contínua.

### LIB-VFX-10 — Dust Trail
- **Geometria:** `Points` com textura radial + anel rasteiro.
- **Animação:** emissão contínua no ponto de origem de cada frame; poeira permanece no percurso.
- **Godot:** `GPUParticles` não existe no renderer; usar `CPUParticles3D` ou flipbook em quads.

### LIB-VFX-11 — Brake Dust
- **Geometria:** leque em plano horizontal + jato de partículas.
- **Animação:** direção derivada do movimento anterior; partículas com velocidades diferentes.

### LIB-VFX-12 — Ground Scratch
- **Geometria:** plano com shader de três sulcos + `InstancedMesh` de pedras.
- **Animação:** revelação por progresso.
- **Godot:** plano com shader; sem `Decal3D`.

### LIB-VFX-13 — Shockwave Ring
- **Geometria:** três anéis finos com atraso.
- **Material:** anel aditivo com fade quadrático.
- **Animação:** expansão contínua até o raio máximo.
- **Obs.:** a casca esférica foi removida — lia como domo de vidro.

### LIB-VFX-14 — Impact Crown
- **Geometria:** `InstancedMesh` de cones + cunhas de base, altura/largura/inclinação variadas.
- **Material:** sólido (NormalBlending) para não estourar em branco.
- **Animação:** abre, expande e dissipa.
- **Limite:** ainda lembra fogo em ângulos baixos; silhueta radial é o ponto forte.

### LIB-VFX-15 — Blast Cone
- **Geometria:** cone externo + lâmina interna.
- **Material:** `coneMaterial`; ponta no contato, boca para longe do atacante.
- **Animação:** abre rápido e dissipa.
- **Referencial:** eixo atacante→alvo (D-235).

### LIB-VFX-16 — Ground Fracture
- **Geometria:** plano com shader de rachaduras radiais ramificadas + pedras.
- **Material:** ruído 2D + ramos radiais + frente de revelação.
- **Animação:** progresso de 0,55 s; pedras sobem e desaparecem.

### LIB-VFX-17 — Anime Impact Flipbook
- **Recurso:** `assets/vfx/flipbook_impact.png` — atlas 4×4, 16 quadros, RGBA (recurso **real** do projeto; o mesmo de `shaders/flipbook.gdshader`).
- **Geometria:** plano billboard (enfrenta a câmera).
- **Animação:** célula escolhida por progresso; 22 quadros/s.
- **Limite:** o atlas esvazia nos últimos quadros; a duração foi encurtada para 1,4 s.

### LIB-VFX-18 — Kinetic Sparks
- **Geometria:** `InstancedMesh` de caixas orientadas pela velocidade.
- **Material:** cor por instância (`instanceColor`) para apagar sem sumir de golpe.
- **Animação:** gravidade + vida própria.

### LIB-VFX-19 — Directional Debris
- **Geometria:** `InstancedMesh` de dodecaedros.
- **Animação:** balística com gravidade e quique visual (sem colisão de gameplay).

### LIB-VFX-20 — Slash Arc
- **Geometria:** fita sobre arco paramétrico inclinado 48°, largura em sino.
- **Material:** revelação por cabeça + fade + núcleo.
- **Animação:** varre o arco em 0,55 s.
- **Referência:** `slash_arc.glb` + `slash_trail_tex.png` (não carregados; forma procedural).

## Demonstrações

| ID | Compõe | Sequência |
|---|---|---|
| DEMO-01 | 06, 07, 08, 09, 10, 11 | aura → propulsão/linhas/rastro/poeira → frenagem |
| DEMO-02 | 13, 14, 15, 17, 18, 19 | flipbook + coroa + onda + cone + faíscas + fragmentos |
| DEMO-03 | 03, 04, 05 | fita + feixe + erosão |
| DEMO-04 | 01, 02, 05 | vórtice + tornado + erosão |
| DEMO-05 | 08, 18, 20 | aproximação + arco + faíscas |

As demos **instanciam** os componentes (nenhuma cópia de implementação) e cada peça aparece na lista de camadas do inspector.

## Desempenho medido (laboratório)

Janela 1001×700, WebGL2 via SwiftShader/WebKit, 1 instância, pós-processamento ligado.
Valores de `renderer.info` após um frame (inclui passes de pós):

| Item | Draw calls | Triângulos |
|---|---|---|
| vortex | 40 | 56.746 |
| funnel | 40 | 63.656 |
| helix | 46 | 45.832 |
| energyHelix | 50 | 59.824 |
| vortexStudy | 48 | 124.746 |
| punchyImpact | 59 | 15.418 |
| demais | 35–46 | 8.000–20.000 |

Não foi medido em GPU real nem no Godot. Sem orçamento aprovado.

## Compatibilidade com Godot 4.7 / GL Compatibility

| Técnica | Situação |
|---|---|
| Malhas procedurais + `ArrayMesh` | direto |
| Shaders `spatial`/`unshaded` com `discard`, UV e tempo | direto |
| Fita por histórico (`ImmediateMesh`) | viável com orçamento |
| `MultiMeshInstance3D` para linhas/faíscas/fragmentos | direto |
| Poeira em `CPUParticles3D`/flipbook | direto (sem GPUParticles) |
| Flipbook 4×4 | shader existente `flipbook.gdshader` |
| Decal de rachadura | **não** — plano com shader (já é o caminho) |
| Refração/volumétrico/bloom HDR | **não** no renderer atual |

## O que não foi verificado

- Aprovação artística de qualquer item.
- Execução dentro do Godot (o catálogo é HTML; a coluna Godot é avaliação técnica, não teste).
- Desempenho em GPU real e em jogo.
- Comparação lado a lado (item 6.10 do prompt) — não implementada.
- Licenças de terceiros: nenhum asset externo foi adicionado; o único recurso do projeto é o flipbook interno.
