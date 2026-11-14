<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-038 — Calibração da Iluminação da Batalha e Sombreamento Anime dos Pokémon

- **Área:** Visual / Iluminação / Shaders / VFX
- **Data:** 2026-11-03
- **Estado:** Implementado
- **Frase literal do criador:**
  > "sim" (em aprovação a: "Remover o nó Sun de scenes/battle.tscn: Deixar a iluminação exclusivamente a cargo da arena cinematográfica (BattleArena). Desativar o billboard gigante de 2.4m em scripts/combat/fx/fx_telegraph.gd: Manter apenas a aura no piso e partículas ascendentes sutis no preparo, para não encobrir o rosto dos personagens. Calibrar o sombreamento dos Pokémon em scripts/combat/battle_scene.gd: Configurar specular_mode = SPECULAR_TOON com baixa intensidade especular (estilo anime fosco), preservando as cores ricas das texturas originais. Remover a sobreposição branca de flash() nos buffs/debuffs da D-037: Deixar os selos rúnicos no chão e a ruptura de escudo brilharem sem precisar pintar o corpo do personagem de branco.")

---

## 1. Contexto
Durante a execução das batalhas 3D, os modelos dos Pokémon (Abra, Pancham, Gible) apresentavam um aspecto visual excessivamente lavado e "branco de tão brilhante", dificultando a leitura de suas cores e silhuetas e encobrindo suas cabeças durante animações de preparo e impacto.

Após auditoria técnica e rasterização visual de GPU, identificaram-se 4 causas principais:
1. Conflito de luz direcional: o nó base `Sun` em `scenes/battle.tscn` (energia 1.0) somava-se à iluminação direcional da arena em `scripts/combat/battle_arena.gd` (`key`, energia 0.45 + rims coloridos), superiluminando o cenário.
2. Flare de concentração desproporcional: em `scripts/combat/fx/fx_telegraph.gd`, a chamada `flash_star` instanciava um billboard não-sombreado de 2.4m com `no_depth_test = true` bem na cabeça do combatente durante o wind-up, cegando o modelo.
3. Reflexo especular fotorrealista GGX: as malhas importadas do GLB usavam `SPECULAR_SCHLICK_GGX` com `metallic_specular = 0.5`. Em superfícies orgânicas curvas, esse modo gerava pontos de brilho especular tipo "esmalte" que estouravam o limiar HDR do Glow/Bloom.
4. Flash branco sobreposto em buffs/debuffs: `battle_fx.gd` acionava `flash(target)` pintando o modelo todo de branco aditivo via `flash.gdshader` ao resolver status da D-037.

---

## 2. Decisão
O criador aprovou expressamente as 4 medidas de calibração:

1. **Remoção do `Sun` redundante:** Em `scenes/battle.tscn`, o nó `DirectionalLight3D` denominado `Sun` é removido, permitindo que a iluminação da arena em `BattleArena` (`key` com tom ciano suave `#c9e2ea`, sombra projetada nítida e rim lights atmosféricas) dite com exclusividade o contraste cinematográfico do combate.
2. **Remoção do billboard gigante no wind-up:** Em `scripts/combat/fx/fx_telegraph.gd`, a chamada `flash_star` de 2.4m sobre a cabeça do atacante é removida de `_charge_aura`. A concentração mantém os anéis de energia concêntricos no piso e as partículas ascendentes, sem ofuscar o modelo 3D.
3. **Sombreamento Toon / Anime para os modelos 3D:** Em `scripts/combat/battle_scene.gd` (na função `_make_model()`), as malhas dos modelos 3D dos Pokémon têm seus materiais configurados com `specular_mode = BaseMaterial3D.SPECULAR_TOON`, `roughness = 0.9` e `metallic_specular = 0.1` (ou equivalente fosco estilizado), garantindo fidelidade total às texturas coloridas originais.
4. **Preservação visual dos modelos nos buffs/debuffs da D-037:** Em `scripts/combat/battle_fx.gd`, a resolução de habilidades de status SMT (`tarukaja`, `rakunda`, `sukunda`) deixa de chamar o `flash(target)` branco aditivo sobre o corpo do modelo, permitindo que os selos arcanos no piso, os estilhaços de escudo e as faixas de estase sejam lidos com clareza.

---

## 3. Ambiguidades resolvidas
- Nenhuma das regras de combate (ATB, dano, esquiva, status) foi alterada.
- O efeito de `flash()` continua disponível e ativo onde for pertinente (ex.: hit flash de dano físico/pesado), sendo removido apenas da ativação de buffs/debuffs rúnicos da D-037 e do windup de habilidades.
