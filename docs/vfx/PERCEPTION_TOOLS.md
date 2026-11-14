<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Ferramentas de percepção de VFX (D-274, item 6)

Servem para **avaliar um efeito visual sem alguém olhando**: renderizam o mesmo efeito, com a mesma semente e passo fixo, e devolvem imagens e números. **Só observam**: não mudam dano, alcance, duração nem nenhum efeito existente.

## Como rodar (janela, não headless: headless não desenha)

```bash
godot --path . --fixed-fps 30 --resolution 1280x720 --script res://tests/fx_lab/perception/run_perception.gd
```

Variáveis: `PERCEPTION_OUT` (pasta de saída) e `PERCEPTION_SET` = `small` | `repeat` | (vazio = completo: 4 layouts + 2 tamanhos de alvo, com checagem de repetibilidade).

## O que sai

- `contact_sheet.png`: por variante, 3 linhas (beauty no palco / close no efeito / silhueta); colunas = instantes (`TIMES`).
- Silhueta: **branco** = visível nos dois fundos; **ciano** = só no fundo escuro (brilho/aditivo); **laranja** = só no claro (fumaça/escuro).
- `perception.json`: por instante, cobertura, caixa, brilho de pico e médio, primitivas, draw calls, nós (malhas, partículas, transparentes); `warnings`; `repeat_mismatch` (0 = o efeito se repete idêntico com a mesma semente).
- Avisos: não aparece em nenhum instante; cobre mais de 45% do quadro; mais de 24 nós transparentes; ainda visível no último instante (dissipação não termina na janela).

## Como usar com um efeito novo

`VfxPerception.run(tree, spec)` recebe variantes `{name, factory, layout, target_height, target_radius, attacker_height}`. A `factory(ctx)` constrói o efeito a partir de `ctx` (`parent`, `origin`, `dest`, `dir`, `target_height`, `target_radius`, `layout`, `seed`) e **nunca** de personagem, time ou lado (D-235). Layouts: `side_lr`, `side_rl`, `near_to_far`, `far_to_near`.

Código: `scripts/vfx/perception/vfx_perception.gd`; receitas de teste: `tests/fx_lab/perception/perception_recipes.gd` (usam `VfxLib`).

## Verificado e não verificado

Verificado (2026-11-05, GL Compatibility, RTX 2050): 8 variantes (projétil nos 4 layouts, burst e slash em dois tamanhos de alvo), repetibilidade 0,0 em todas.
Verificado também (2026-11-05): o **escudo real do Guard** (`FxGuard`), com `PERCEPTION_SET=guard`: expirar, contato e Brick Break, nos 4 layouts e alturas de alvo 0,8 / 1,4 / 2,4, sem erro de script. Achados: letras GUARD cortadas no topo do quadro com alvo alto perto da câmera (2,4 em `far_to_near`) e letras minúsculas com alvo pequeno longe (0,8 em `near_to_far`); o aviso de 26 nós transparentes aparece só na montagem do escudo (~0,4 s), é esperado.
**Não verificado:** os Moves do Abra pelo kit; GPUParticles3D (só CPUParticles3D e malhas foram usados); resultados com o Motion Composer; custo em tempo de CPU/GPU (só contagens de primitivas e draw calls).
