# Efeitos dos elementos — receitas de referência V1 (D-274)

Quatro receitas reutilizáveis, uma por elemento. **Não substituem nenhum efeito existente** (inclusive o Fire Bullet, D-236) e **não estão ligadas a nenhum Move**; ligar exige decisão própria.

| Elemento | Classe | Receita | Camadas |
|---|---|---|---|
| Fogo | `ElFireStream` | chama projetada | corpo em gota, núcleo quente, línguas que se soltam, brasas, espalhamento no chão, flash, fumaça, cinzas |
| Água | `ElWaterJet` | jato com respingo | jato curvo contínuo com ondulação e espuma, gotas balísticas, anel no chão, lâminas de água, coroa de gotas, névoa; retrai pela cauda |
| Terra | `ElEarthEruption` | erupção de fragmentos | 5 pontos de erupção em sequência até o alvo, rachaduras, espetos de pedra, pedaços arremessados com giro, poeira |
| Ar | `ElAirGust` | rajada curva | 5 fitas afiladas em curvas torcidas com falhas que correm, partículas que giram em torno do fluxo, anel de poeira no destino |

Código: `scripts/vfx/elements/` (`element_effect.gd` base, `element_shapes.gd` fitas/espetos/pedras, `element_particles.gd` partículas por função do tempo). Shaders: `shaders/el_*.gdshader` (+ `el_common.gdshaderinc`). Estilo cel-shading chapado, como o do jogo; funciona em GL Compatibility (sem GPUParticles, sem decals).

## Como usar

```gdscript
ElFireStream.new().setup({"parent": node, "origin": a, "dest": b, "target_height": 1.4, "target_radius": 0.4, "seed": 7})
```

Tudo vem do contexto (origem, destino, tamanho do alvo, semente), nunca de personagem, time ou lado (D-235). O tempo é explícito: `set_time(t)` (rebobinar, pausar, câmera lenta) ou `autoplay` (padrão, libera sozinho). Mesma semente = mesmo efeito (partículas são função do tempo, sem GPU).

## Avaliar

`PERCEPTION_SET=fire|water|earth|air` em `tests/fx_lab/perception/run_perception.gd` (ver `PERCEPTION_TOOLS.md`): 4 layouts + alvos de 0,8 / 1,4 / 2,4 + repetibilidade.

## Verificado (2026-11-05) e não verificado

Verificado: as quatro rodam sem erro de script/shader em GL Compatibility, em 6 variantes cada (4 layouts, alvo pequeno espelhado e alvo grande), sem aviso de cobertura/transparência, **repetição idêntica (0,0)** e dissipação completa em ≤ 2 s.
**Não verificado:** dentro de uma batalha real (câmera, HUD, iluminação do jogo); custo de CPU/GPU (só contagem: ~7,3–7,6 mil primitivas e 10–21 draw calls no pior instante); aprovação visual do criador; GPUParticles/Forward+; integração com o Motion Composer. **Pontos fracos conhecidos:** a rajada de ar lê como traços de velocidade, mais do que como curva envolvente; a chama pode ganhar mais lambidas nas bordas; todas as cores são escolha do assistente.
