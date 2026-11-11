# War Cry — referências e direções visuais (D-308)

- **Data:** 2026-11-10.
- **Move:** `war_cry` (Orc, STATUS, Neutral, AoE inimiga, 3 ATB / 3 MP, wind-up 0,3 s, pausa 1,3 s).
- **Efeito de jogo:** interrompe inimigos em WINDUP; +1 Burst se interromper ao menos um; sem dano/STUN/empurrão.
- **Estado:** pesquisa de direção; **nada implementado**. Nenhuma direção aprovada.

## O que a ficha do Move pede (literal do projeto)

> "Expanding translucent red shock rings radiating from the caster's mouth with arena dust kickback."

> "Stationary shout. Caster plants feet firmly on the ground."

> "0.30s wind-up. Deep chest expansion."

Checklist visual:
1. Anéis de choque **vermelhos translúcidos**, saindo da **boca** do lançador.
2. Anéis **expansivos** (não um projétil fino).
3. **Poeira** levantada no chão (kickback), sem sujeira residual.
4. Corpo **parado**, pés plantados, peito expandindo no wind-up.
5. Sem dano, sem número de dano, sem flash de tela inteira, sem tremor de câmera.
6. Quatro fases D-308 com transição contínua.
7. Independente de personagem/time/lado (D-235): âncora na cabeça/boca real, eixo e escala derivados do corpo.

## Referências internas

| Referência | O que aproveitar |
|---|---|
| `docs/vfx/referencias/03_impacto.md` — LIB-VFX-13 Shockwave Ring | Frente fina (~0,02), halo largo (~0,12), poeira 0,05 s depois; escalas separadas; timing 0,35/0,5/0,8 s. É a base técnica mais próxima. |
| `shaders/ring.gdshader` | Anel que cresce e some; quad plano; serve para o anel rasteiro. |
| `shaders/mc_shock_ring.gdshader` | Anel tracejado com ruído angular; útil para a frente quebrada, não para o corpo do grito. |
| `shaders/fire_ring.gdshader` + `floor_ring` do Composer | Anel contínuo no chão (`solid=1`) e cores por uniform; base para o anel de poeira. |
| `fx_impacts._shock` / `_ring_cam` | Como o jogo desenha anéis de status hoje (Tarukaja/Rakunda). |
| `fx_impacts._tarukaja_impact` | Paleta vermelho/laranja e glow curto; referência de cor. |
| D-035/D-037 (VFX SMT) | Auras/selos vermelhos e laranja; linguagem de energia do projeto. |
| `SwingTrail._head_bone` | Busca do osso de cabeça (`j_kao` no Orc) para ancorar a boca. |

## Referências externas

| Referência | Link | O que aproveitar | O que não copiar |
|---|---|---|---|
| **Elden Ring — War Cry (Ash of War)** | [Wiki](https://eldenring.fandom.com/wiki/Ash_of_War:_War_Cry) · [All Ashes animations](https://www.youtube.com/watch?v=pE3EBsG7R0o) | Peso do grito, corpo plantado, burst curto vermelho/laranja; o grito parece "caro". | Arma erguida e buff de arma; o Orc não precisa levantar a lança. |
| **Diablo IV — War Cry (Barbarian)** | [Wiki](https://diablo.fandom.com/wiki/War_Cry_(Diablo_IV)) · [Skills showcase](https://www.youtube.com/watch?v=CtrUF7zzjlo) | Anéis concêntricos vermelhos, leitura radial clara, silhueta de "comando". | Aura de grupo e UI da Blizzard. |
| **WoW — Battle Shout** | [Spell](https://www.wowhead.com/spell=6673/battle-shout) · [WoD animations](https://www.youtube.com/watch?v=EV5oC0KBtZc) | Expansão rápida em anéis vermelho/laranja; timing curto e legível. | Armas/armadura e o exagero de partículas. |
| **Monster Hunter — rugidos** | [Rise roars compilation](https://www.youtube.com/watch?v=Jd58MqlbGvk) | Anéis de pressão de ar em 3D, poeira e escalas separadas; o rugido tem volume, não é um decal. | Tremor de câmera e distorção de tela fortes (D-1027). |
| **Dragon Quest — War Cry** | [Wiki](https://dragonquest.fandom.com/wiki/War_Cry) | Fantasia de grito que **amedronta/interrompe** o inimigo; é a origem do Orc DQT. | Não há visual canônico claro; não copiar um efeito inexistente. |
| **Dragon Ball — kiai/grito** | referência de anime (sem link único) | Explosão radial de energia, linhas de ação e leitura anime. | Excesso de aura/brilho e câmera dramática. |

## Três direções

### A — Grito pesado (Elden Ring / Dark Souls)

- **Wind-up:** agacha, peito abre, poeira sobe nos pés; brilho vermelho baixo na boca.
- **Release:** anel rasteiro curto + cone de poeira; sem clarão grande.
- **Trajeto:** 2 anéis no chão se abrem; ar acima com linhas finas.
- **Impacto:** poeira e anel curto em cada inimigo; flinch + cartão quebrado.
- **Leitura:** peso físico, menos anime. Risco: parecer um soco no chão, não um grito.

### B — Anéis de comando (Diablo / WoW + LIB-VFX-13)

- **Wind-up:** energia vermelha comprime na boca/peito; 2 anéis finos contraem; poeira nos pés.
- **Release:** núcleo branco-quente na boca + 3 anéis concêntricos vermelhos: frente fina branca/vermelha, halo largo translúcido, anel de poeira atrasado.
- **Trajeto:** os anéis se abrem pelo campo; a frente é fina e brilhante; o halo é largo e translúcido; poeira acompanha o chão.
- **Impacto:** em cada inimigo, anel vermelho + estrela curta; flinch + cartão quebrado; poeira.
- **Leitura:** é a mais próxima da ficha ("red shock rings" + dust). Menos risco de exagero.

### C — Pressão sônica (Monster Hunter / Dragon Ball)

**Escolhida e corrigida pelo criador (D-1106):** um **cone/megafone largo** com a ponta na boca e a boca larga na direção dos oponentes, **cobrindo todos os inimigos**; **7 anéis rápidos** viajam dentro dele, com raio crescendo e opacidade caindo até sumir. Não são anéis radiais ao redor do lançador.

**Segunda correção (Elden Ring + textura + blur):** a casca usa a textura `assets/vfx/war_cry_wave_tex.png` (**branca/cinza, semi-transparente**, bandas irregulares e poeira, gerada por `tools/generate_war_cry_texture.py`); o release adiciona **blur gaussiano radial + distorção** de ~0,32 s na vista 3D, com a HUD nítida. Referência: o rugido largo e empoeirado de **Elden Ring — War Cry / roar ashes**, não anéis neon limpos.

**Terceira correção:** sem vermelho. Anéis **brancos/creme**, mais rápidos (**0,38 s**) e mais grossos (tubo de 10% do raio); **pulsos brancos de 0,35 s** ao redor do interrompido (2 anéis de tela, 1 de chão e 2 toros), exclusivos do War Cry. Vídeos normal e espelhado sempre em arquivos separados.

**Sexta correção (final7):** volta ao **final4** (7 anéis em voleio escalonado de 0,03 s, deslocamento linear), mas os anéis **começam a 35% de opacidade** e perdem muita opacidade com a distância (`0,35 × (1 − progresso)^2,5`). A pausa global do motor foi removida **só no War Cry** (D-1127, experimental) para o criador avaliar o timing.

- **Wind-up:** distorção de ar ao redor da boca, detritos flutuando; peito abre.
- **Release:** cone de ar comprimido com a ponta na boca; anéis começam pequenos na ponta e correm para os oponentes.
- **Trajeto:** anéis perpendiculares ao eixo, raio crescendo, opacidade caindo; casca de megafone fraca; linhas de velocidade; poeira e detritos; distorção de tela leve (sem tremor).
- **Impacto:** os anéis chegam sumindo e o impacto por inimigo estoura em arcos vermelhos/brancos; flinch + cartão quebrado.
- **Leitura:** mais épica e anime; risco de cobrir o corpo e pesar no GL Compatibility.

## Plano técnico (para a direção escolhida)

- **Classe própria** `WarCryVfx` (hand-built; Composer só no secundário se ajudar, D-1030).
- **Âncora:** osso de cabeça (`j_kao` no Orc; fallback `head`/altura do corpo), ponto da boca deslocado para frente/baixo; eixo atacante→alvo; escala do corpo real.
- **Camadas:** núcleo na boca; 3 anéis (frente fina, halo, poeira); cone de ar/linhas; poeira no chão; impacto por inimigo.
- **Fases:** 0–0,30 s wind-up; 0,30 s release; 0,30–1,10 s expansão; 1,10–1,20 s impacto; 1,20–1,30 s dissipação.
- **Regra de sincronia:** a lógica interrompe todos no instante do status (1,167 s). O anel expande rápido (0,25–0,35 s) para não dessincronizar; o flinch/cartão quebrado continuam no instante da lógica.
- **GL Compatibility:** sem GPUParticles, sem decals, sem sub-emitters; malhas/torus, flipbooks, CPUParticles3D, shaders.
- **Câmera:** sem tremor/dolly; no máximo abrir FOV se o corpo obstruir (D-1027).
- **Teste:** sala de VFX, normal + espelhado, alvos de tamanhos diferentes; `--audit-leaks` (leaks=0), `--envelope-graph` (sem pop), `--proof-sheet`, vídeo único com as duas vistas; checklist acima.

## O que falta decidir

- **Direção:** A, B ou C.
- **Número de anéis:** 3 (proposta) ou 2.
- **Cor:** vermelho coral da ficha ou vermelho mais escuro; o projeto usa `#ff4d6d`/`#ff624f` em status.
- **Poeira:** quanto de arena deve levantar (leve/média).
