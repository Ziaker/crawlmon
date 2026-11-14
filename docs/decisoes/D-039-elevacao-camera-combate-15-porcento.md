<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-039 — Elevação da Câmera de Combate em 15% (Opção 1)

- **Área:** Câmera / Visual
- **Data:** 2026-11-03
- **Estado:** Implementado
- **Frase literal do criador:**
  > "opcao 1" (em resposta a: "Qual das opções você prefere aplicar? 1. Opção 1 (Elevação de Altura com Foco no Campo): A câmera sobe para y = 2.875, mas a mira continua focada no piso (y = 0.0)...")

---

## 1. Contexto
A câmera principal de combate (`CINEMA_POS`) ficava posicionada na coordenada `Vector3(3.8, 2.5, 7.0)`. O criador solicitou elevar a câmera do jogo em combate 15% mais para cima.

---

## 2. Decisão
O criador escolheu a **Opção 1**:
- A altura da câmera de combate sobe 15%, passando de `y = 2.5` para `y = 2.875` (+0.375 unidades), ficando em `CINEMA_POS := Vector3(3.8, 2.875, 7.0)`.
- O ponto de mira da câmera no modo Cinema continua inalterado em `CINEMA_LOOK := Vector3(-2.0, 0.0, -20.0)`.
- Isso confere um ângulo de visão ligeiramente mais superior/aéreo sobre o campo de batalha, destacando a profundidade da arena, os selos arcanos da D-037 no chão e proporcionando maior respiro entre as cabeças dos combatentes e a interface de usuário no topo da tela.
- A posição base da câmera em `scenes/battle.tscn` (nó `Camera3D`) também é sincronizada para refletir a nova altura `y = 2.875` inicial.

---

## 3. Ambiguidades resolvidas
- Nenhuma regra de combate, ATB, movimento ou framing dinâmico (D-015) foi alterada.
- O campo de visão (`FOV = 80.0`) e a inclinação holandesa fixa (`TILT_DEG = 4.0`) são rigorosamente preservados conforme a D-020.
