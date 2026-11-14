<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-337 — Auditoria extrema e implementação fiel no jogo dos 6 Moves já codados do Atelier HTML (deixando Psychic Cannon e Psycho Orb por último para brainstorm)

- **Data:** 2026-11-05
- **Área:** Visual / VFX / Motion Composer / Combate
- **Origem:** Conversa (envio do arquivo `brawlmon_3d_atb_vfx_atelier_8_moves_media_mabufula_dig_sand_attack_dragon_ra o_orb.html` e respostas às perguntas da auditoria)

> **Nota D-1030 (2026-11-09):** o Motion Composer é **auxiliar e opcional**. A menção a "construídos sobre o Motion Composer" no item 4 é histórica; não é gate.

## O que o criador disse (literal)

> "faz uma auditoria extrema desses efeitos visuais e os implemente no jogo, quanto aos moves que ja nao estao codados, vamos fazer um brainstorm sobre eles depois, entao deixe eles por ultimo, splitter fire tem todo um doc so pra ele no repositorio ddo gitbhub, veja o agaents md e os documentos do repositorio antes fazer a auditoria e faca a auditoria logo apos, e preciso que sejam o mais fieis possiveis, perfeitamente fieis todos"

Respostas às perguntas da auditoria:
- Mabufula e Dig (Fidelidade): **"100% fiel ao HTML (Recommended)"**
- Pilares e Cilindros (D-036): **"Incluir cilindros do HTML (Recommended)"**
- Tempos das Fases (D-019): **"Sincronizar com Battle (D-019) (Recommended)"**
- Ordem de implementação: não restringida (os 6 Moves já codados entram primeiro; os 2 não codados ficam por último para brainstorm).

## Decisão

1. **Separação de escopo:**
   - **6 Moves já codados a implementar com fidelidade perfeita ao HTML:** `Splitter Flames` (`splitter_flames`, conforme ficha completa da D-236: modo 1 alvo com convergência em pilar, modo 2 alvos com explosões individuais e redirecionamento especial em voo quando um alvo morre), `Media` (`media`), `Mabufula` (`mabufula`), `Dig` (`investida_escavadora` / `dig`), `Sand Attack` (`tiro_areia` / `sand_attack`) e `Dragon Rage` (`furia_dragao` / `dragon_rage`).
   - **2 Moves ainda não codados reservados por último para brainstorm:** `Psychic Cannon` e `Psycho Orb`.
2. **Fidelidade visual 100% ao HTML:**
   - **Mabufula:** substitui o projétil de pingente único antigo pela coreografia completa do HTML (decalque criogênico no chão com veios cristalinos, cone de nevasca com 120 flocos de neve, onda sequencial de 5 clusters de 5 geleiras piramidais com shader Fresnel + animação `easeOutBack` + vibração pré-ruptura + cacos quicando no chão, tintura/tremor de congelamento nos alvos e estilhaçamento simultâneo das 5 geleiras em 240 cacos quicando no chão).
   - **Dig:** substitui a corrida simples pela coreografia completa do HTML (pulo-broca giratório em alta velocidade mergulhando no chão + cratera sísmica com rachaduras de magma e 8 rochas 3D na borda + jato de pedras quicando e poeira; 6 montes cônicos 3D brotando com pedras no trajeto subterrâneo; erupção geotérmica no alvo com cratera maior, coroa de 6 espirais de basalto/magma, fonte de 75 rochas quicando, 65 fagulhas geotérmicas, uppercut giratório com salto mortal de retorno do atacante e knock-up vertical visual do alvo).
   - **Media:** círculo sagrado rúnico central da equipe + círculo sagrado individual sob cada aliado + pilar volumétrico translúcido com listras e Fresnel + hélice de 90 brilhos + 34 cruzes médicas luminosas + 60 sparkles contra-rotativos + pulso de 50 sparkles no peito ao curar.
   - **Sand Attack:** onda crescente de areia viajando pelo chão + jato cônico triplo (95 nuvens densas de poeira, 110 micro-cristais de sílica e 45 pedras de cascalho quicando no chão) + funil cônico giratório (`DustDevilFunnel`) no alvo + hélice de 75 nuvens de poeira + 18 marcadores holográficos `'X'` (`xmark`) orbitando o alvo.
   - **Dragon Rage:** mandíbula 3D espectral de dragão com 2 chifres, 2 olhos amarelos e 8 presas abrindo no wind-up + decalque de fissuras dracônicas sob o lançador + 95 chamas convergentes + 28 rochas levitando + bola de fogo dracônica monstruosa (núcleo branco-ouro, casca com deslocamento de espinhos no vértice, coroa de 12 línguas/espinhos 3D girando e 5 raios bio-elétricos 3D) + rastro de fumaça abissal e labaredas no voo + cataclismo no impacto (cratera de fissuras dracônicas de 4,4 m, 10 espirais 3D de chamas dracônicas em 2 anéis, 8 raios dracônicos 3D, pluma de 70 fumaças abissais, inferno de 145 chamas e 65 rochas de magma quicando).
   - **Splitter Flames:** corrigir a fidelidade ao HTML (mãos simétricas em `±0,95 m`, 35 chamas convergentes por mão no wind-up, 2 vórtices estacionários de `0,30 s` com 26 chamas orbitais que viram cinza no release, rastro de chamas deixadas no mundo que caem com gravidade e esfriam para carvão no voo, pilar de fogo que vira cinza + 90 chamas sem estouro branco + 75 flocos poligonais de cinza `ash` caindo), e implementar na Sala de VFX e no motor os modos **Dois Alvos (`dual`)** e **Redirecionamento Especial (`retarget`)** da ficha `D-236`.
3. **Cilindros translúcidos autorizados:** os cilindros abertos do HTML (`Media`, `Sand Attack` e `Splitter Flames`) entram exatamente como no HTML (exceção expressa à D-036 para reproduzir fielmente o HTML).
4. **Sincronia e regras:** os efeitos são sincronizados com o relógio real do `Battle`, independentes de personagem, time e lado (`D-235`) e com tamanho fixo no mundo (`D-334`). O Motion Composer é **auxiliar e opcional** (`D-1030`); o efeito pode ser feito à mão.

## Ambiguidades em aberto

- `Psychic Cannon` e `Psycho Orb` ficam aguardando a rodada de brainstorm após a entrega dos 6 Moves já codados.

## Estado no código

- **Media — primeira entrega para aprovação (2026-11-05):** implementado sobre o Motion Composer
  (`MotionPresets.media_effect`, `MotionAtelierMeshes.draw_heal_circle`/`draw_heal_pillar`,
  `shaders/mc_heal_circle.gdshader`/`mc_heal_pillar.gdshader`, kind `atelier` do `MotionRep` e a cerimônia do
  `ElementMoveVfx`), com âncoras nos aliados reais do atacante (partido ou inimigos, D-235).
  - O círculo central da equipe (raio 5,2 m) e os círculos individuais (2,2 m) são desenhados no chão; os pilares
    translúcidos (1,85 s, atraso 0,35 s + 0,08 s por aliado), a hélice de 90 brilhos, as 34 cruzes, os 60 sparkles
    contra-rotativos e o pulso de 50 sparkles seguem os mesmos tempos, raios, cores, tamanhos e contagens do HTML.
  - O pulso de cura é ancorado no primeiro `Battle.healed` do conjurador (D-019), com 1,4 s como fallback.
  - Foram removidos os legados que apareciam por cima do Media: o estouro da pausa de status (`on_status_pause_started`),
    os anéis/estouro do `heal_fx` antigo e os anéis/flash de impacto de status. Permanece apenas o número `+HP`.
  - **Cura (decisão do criador, 2026-11-05):** Media cura **`10 + MAG`** em cada aliado (mesma fórmula da ficha de
    fogo da D-236), em vez dos `40% do HP máximo` provisórios. Cada aliado recebe o valor do MAG do **conjurador**.
    Como o atributo MAG ainda não está ligado ao `Combatant` (D-120/D-131), foi criado o campo `mag` e, por enquanto,
    ele **espelha o ataque base** do personagem (Abra 12 → cura 22; Pancham 10 → 20; Gible 9 → 19). Quando a tabela
    real de atributos existir, basta preencher `mag` no construtor — a fórmula não muda.
  - O valor do `+HP` passou a usar a variação de `target_hp` (vida rolante), então mostra a cura real em vez de `+0`.
  - Tamanho das partículas ajustado para as unidades do mundo do HTML (antes ficavam ~2,6× menores).
  - **Sigilo ritual torto (corrigido):** `Basis.scaled()` escala nos eixos **globais** da cena, não nos eixos locais
    da malha. Aplicado depois da rotação de 90°, ele comprimia o eixo Z do plano para 1 m e transformava o círculo num
    "elipse/faixa" esticada. Todas as transformações de malha do Atelier passaram a usar
    `basis * Basis.from_scale(...)` (escala local antes da rotação): círculo central, círculos individuais, decalques,
    crateras, fissuras, espirais e presas/chifres do dragão.
  - **Diferença de pipeline assumida:** o HTML usa `UnrealBloomPass`; o jogo não tem glow/bloom em nenhum
    `WorldEnvironment`. A versão Godot compensa com espessura, halo e intensidade maiores, mas o "neon" do HTML é
    mais brilhante. Se o criador quiser bloom, é uma decisão de cena inteira (afeta todos os VFX), não só o Media.
  - **Vídeo normal + espelhado:** `test_captures/Media_normal_espelhado.mp4` (gerado por
    `tests/fx_lab/record_move_video.py`, com `--hp 55`). No lado espelhado da Sala de VFX o time do Gible tem um
    único aliado, por isso o ritual aparece com um círculo/pilar individual; no lado normal aparecem os dois aliados.
  - Aprovado pelo criador: **não** (aguardando).
- Os outros 5 Moves permanecem em implementação.

