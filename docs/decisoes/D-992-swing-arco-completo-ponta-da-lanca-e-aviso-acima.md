<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-992 — Swing: arco completo, lança com ponta brilhante, rastro largo como a arma; aviso acima de quem não tem braços

- **Data:** 2026-11-08.

## Frase literal do criador

> quanto ao orc, ele não precisa do rastro, mas se possível, eu deixaria a ponta da lança brilhante, se for capaz disso, então coloque
> quanto ao pancham, o rastro inicia mas não finaliza (como um moicano, um arco completamente fechado), além disso investique pq os tackles dele são absurdamente mais rápidos que os outros.
> quanto ao slime, eu deixaria a notificação do dodge mais encima dele e menos pra esquerda, para ele

## Decisão (regras genéricas, D-235)

1. **Arco completo:** o rastro do membro fica desenhado durante o Swing inteiro (não só os últimos 0,16 s) e some depois do contato. Vale para todos (inclui o Abra).
2. **Arma fina e longa (lança):** sem rastro; a **ponta** brilha (estrela quente) durante o Swing.
3. **Arma grossa (clava):** o rastro tem a **largura da própria arma** (pedido anterior: "grande como a marreta").
4. **Sem mãos nem arma (golpe com o corpo, como o Slime):** o aviso de Evade fica **acima** do corpo, sem deslocamento para o lado.

## Investigação (Pancham)

O tempo do Tackle no combate é igual ao do Abra (fase de golpe 0,88 s, contato aos 0,8 s; clipes de ataque 1,77 s × 1,97 s). A corrida até o alvo foi um pouco mais curta só pela distância (0,93 s × 1,11 s). A diferença percebida vem do **conteúdo da animação** do Pancham (o soco acontece cedo no clipe), não de uma regra de tempo. Não alterado: aguarda decisão.

## Estado

Implementado para revisão.
