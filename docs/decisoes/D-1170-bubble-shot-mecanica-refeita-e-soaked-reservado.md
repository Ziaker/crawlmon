<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1170 — Bubble Shot: mecânica refeita (opção A, 0,7 s, 100%) e Soaked reservado

- **Data:** 2026-11-11.
- **Área:** Combate / Moves / Slime.
- **Origem:** resposta do criador à rodada de quatro propostas de mecânica do Bubble Shot (A tiro puro, B −1 SPD, C bolha lenta, D Soaked), depois de liberar o refazer do Move (D-1025).
- **Estado:** regra registrada; **não implementada**; um ponto em aberto (tipo de dano).

## Frase literal do criador

> guarde soaked para uma implementação futura
>
> Opção A com wind-up de .7s e 100% de poder

## A opção A como foi apresentada

> **A — Tiro puro e barato:** poder 130%, 3 MP, wind-up 1,0 s, efeito nenhum.

Base comum apresentada junto: alvo único, long range, 2 ATB, elemento Water (sem gelo, D-397), desviável nos últimos 0,25 s do voo (D-1014), sem Dread (D-1078), alvo morto em voo = sem dano (D-109), Move genérico (D-235), quique no chão só visual.

## Decisão

1. **Bubble Shot** é um projétil de **dano direto, sem efeito extra**: sem status, sem debuff, sem ricochete.
2. **Poder:** **100%** (era 130%).
3. **Wind-up:** **0,7 s** (era 1,0 s no dado; a ficha dizia 1,10 s).
4. **Custo:** **2 ATB / 3 MP** — os valores da opção A, que o criador não alterou.
5. **Alvo único, long range, elemento Water.** Os textos da ficha deixam de citar gelo (D-397).
6. **Quique no chão:** só visual; não é regra de combate.
7. **Soaked:** fica **reservado para uma implementação futura**. Nada de status, badge, dado ou telemetria agora. A ideia apresentada era: o alvo fica "Soaked" por alguns segundos e o próximo golpe Electric nele conta como fraqueza. Isso é **registro da proposta, não regra aprovada**; duração, efeito e qual Move aplica ficam para a rodada futura.
8. **Nada mais muda:** esquiva, fraqueza, crítico, recompensa de ATB, Dread desligado (D-1078) e o kit do Slime continuam como estão.

## Segunda resposta do criador (2026-11-11)

> É mágico que escala com MAG, comece a implementação e melhore os efeitos visuais usando shaders e referências a genshin impact

9. **Tipo de dano:** **mágico**, escala com **MAG** (D-1140) e sofre a mitigação por WIS do alvo (D-1142). Ícone de tipo Magical (D-395).
10. **Implementação autorizada**, mecânica primeiro.
11. **VFX:** melhorar os efeitos visuais do protótipo usando **shaders** e **referências a Genshin Impact**. Segue o protocolo D-308; o que exatamente "melhorar" e quais referências de Genshin entram no checklist literal antes do código do efeito.

## Respostas do criador sobre o VFX (2026-11-11, rótulos escolhidos)

> Só batalha real
>
> À frente do corpo (Recomendado)
>
> Mesma coreografia, material novo (Recomendado)
>
> Hydro do Genshin

12. **Escopo:** o efeito vai **só na batalha real**; **sem cena de laboratório**. Verificação na sala de VFX (`scenes/debug/vfx_room.tscn`). Em combate o efeito segue as **fases reais do `Battle`** (D-019/D-1040); o relógio fixo de 1,85 s do prompt não é usado.
13. **Origem:** a bolha infla **à frente do corpo** do atacante (D-958), medida pelo modelo real; não usa mão/socket.
14. **Melhorar = material, não coreografia:** as peças e a ordem do protótipo ficam (bolha oca, micro-bolhas convergentes, guia até o quique, coroa de 14 bolhas no disparo, um quique com mini-gêiser e anéis, esteira, estouro com cruz de jatos, anel atrasado, mini-bolhas e gotas que quicam). Os materiais passam a ser shaders no estilo **Hydro do Genshin**: água toon em faixas, borda brilhante, cáusticas e espuma.
15. **Paleta:** **Hydro do Genshin** — azul Hydro saturado com branco e ciano claro, **sem ouro e sem magenta**. A paleta iridescente do protótipo não é usada.

## Ambiguidades em aberto (perguntar antes de agir)

- **MP:** 3 MP foi lido como parte da "Opção A". Se o criador quis outro valor, corrigir.

## Relações

D-1025 (Bubble Shot refeito do zero depois do Tidal Surge), D-1078 (sem Dread), D-1140/D-1142 (tipo de dano e WIS), D-1145 (auditoria move a move), D-397 (Water), D-413 (faixas de MP), D-420 (textos da ficha), D-235, D-061.

## Aprovação visual (2026-11-11)

> Perfeito

O criador aprovou o Bubble Shot como entregue em `test_captures/bubble_shot_d1170_v3.mp4` (mecânica e VFX, incluindo a proporção pela altura do corpo). As verificações listadas em "Não verificado" continuam não feitas.

## Estado no código

**Mecânica implementada e testada; VFX implementado e aprovado visualmente pelo criador (2026-11-11).** Nada commitado.

- **Mecânica:** `content/moves/bubble_shot/move.tres` (poder 1,0, wind-up 0,7 s, 3 MP, 2 ATB, `damage_type` mágico, textos sem gelo), `scripts/data/skill_legacy_data.gd` e a entrada de fallback em `scripts/data/skill.gd`. Teste `tests/battle/test_d1170_bubble_shot.gd`: **D1170_PASS**. Regressões D-1152, D-1140 e D-1025 passam.
- **VFX:** `scripts/vfx/combat/bubble_shot_vfx.gd` (desenho), `scripts/vfx/combat/fx_bubble_shot.gd` (driver pelas fases reais do `Battle`), shaders `shaders/bubble_shot_bubble.gdshader` e `shaders/bubble_shot_water.gdshader`. Ganchos em `battle_fx.gd`, `fx_projectiles.gd` e `fx_telegraph.gd`: o projétil, a aura e o impacto genéricos são suprimidos só para este Move; a faixa de trajeto no chão (D-1013) continua.
- **Tamanho:** os metros do protótipo foram proporcionados à altura real do corpo (`altura / 1,95`, limitado a 1,0–2,2) além da escala de distância da câmera, porque com 0,34 m fixos a bolha ficava ilegível ao lado dos modelos da batalha. É adaptação do assistente, sujeita à aprovação.
- **Telemetria (D-1154), sala de VFX, `--stdout-trace`:** `telegraphed` t=1,967 → `phase STRIKE` t=2,662 (wind-up 0,695 s) → `phase TRAVEL` t=3,461 → `hit` t=4,108 com `power: 1.0`.
- **Restos:** `--audit-leaks` com acerto na vista normal: `leaks=0`. Na espelhada sobra 1 `Label3D` (o efeito não cria `Label3D`). No desvio a auditoria acusa 15 nós, o mesmo número e tipo do Javelin Throw no mesmo cenário; não são nós do Bubble Shot. `--envelope-graph`: sem `POP_DETECTED`.
- **Vídeo (normal + espelhado):** `test_captures/bubble_shot_d1170_v3.mp4`; quadros em tamanho real em `test_captures/bubble_shot_d1170_v3_normal_frames.png` e `..._mirrored_frames.png`.

**Não verificado:** o Slime como atacante (as gravações usaram o Abra); alvos de outros tamanhos além de Orc/Cyclops/Gible; o caso de desvio em vídeo; o impacto sobre o Bubble Shield; `--overdraw`, `--scale-overlay`, `--proof-sheet` e fundos neutros; teste automático do próprio VFX; a suíte `run_agent_combat_tests.py` completa. Dois testes antigos (`test_content_catalog`, `test_enemy_encounter_generation`) já falhavam por mudanças de outras sessões (textos do Javelin e fraqueza do Slime), sem relação com este Move.
