# D-1034 — D-1013 (1,2 m) vale também para o DQT

- **Data:** 2026-11-09
- **Área:** Visual / Modelos / DQT / D-1013
- **Origem:** resposta do criador à pergunta 5 da auditoria.
- **Atualização:** **superada para o DQT por D-1043** depois do teste visual (2026-11-09). O "todos 1,2 m" do DQT foi rejeitado; o DQT usa os perfis relativos, com teto de 2,5 m. A D-1013 continua para os Pokémon comuns.

## Frase literal do criador

> "5 - sim"

## Decisão

1. A altura-alvo de **1,2 m** da D-1013 vale para **todos os modelos de batalha, inclusive o trio DQT** (Orc, Slime e Cyclops).
2. Os perfis DQT que hoje apontam `target_height` 2,1 m (Orc), 1,4 m (Slime) e 3,22 m (Cyclops) **não podem** ser usados como justificativa para passar de 1,2 m. Se o perfil precisar de outro valor para a animação, a escala final do modelo deve continuar em 1,2 m.
   - **Evidência de código (2026-11-09):** `battle_scene._fit_height` já tenta `TARGET_HEIGHT = 1.2`, mas usa `_posed_height` (span de ossos × 0,56). No DQT o resultado medido continua 3,17 m (Orc), 3,52 m (Slime) e 2,76 m (Cyclops); o fit não está atingindo 1,2 m. A correção precisa medir a malha visível/skinned, não o span de ossos, ou calibrar por modelo.
3. A ferramenta 4 deve continuar reportando a altura real e a divergência; não deve corrigir a escala sozinha.
4. A correção dos modelos DQT para 1,2 m é uma **rodada de implementação separada**, com teste visual nas duas vistas; não foi feita nesta auditoria.
5. **Resposta de 2026-11-09 ("por ora sim"):** a rodada de escala DQT está **autorizada por ora**. A implementação não foi feita nesta resposta; ela precisa de plano, ajuste dos perfis e teste visual. Se a intenção era apenas registrar a regra, corrigir antes de codar.
6. **Teste visual (histórico):** o vídeo `test_captures/scale_test/scale_before_after.mp4` mostra o antes (3,17/3,52/2,76 m) e o depois forçado a 1,20 m na sala de VFX. Esse "depois" foi **rejeitado** pelo criador; a correção real é D-1043.

## Ambiguidades em aberto

Nenhuma.

## Estado

**Superada para o DQT por D-1043** após o teste visual. A D-1013 continua para os Pokémon comuns. Código de jogo alterado por D-1043; sem commit/push.
