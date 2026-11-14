<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1166 — UI de afinidades: grade na base da arte e texto nos outros painéis

- **Data:** 2026-11-11
- **Área:** UI / StatusScreen / StatusPanel / Menus / afinidades.
- **Origem:** o criador pediu a migração de `weaknesses` para `affinities` com um protótipo visual para aprovação.
- **Estado:** implementado e aprovado pelo criador ("perfeito assim"); capturas finais em `test_captures/aff_final.png` e `aff_final_none.png`.

## Declaração literal do criador

> "faça isso mas com um prototipo visual bom pra eu checar, encontre uma posição boa para isso e sem colidir com nenhum outro bloco, talvez um bloco vertical com os icones e - (N) W e R"

## Regra aprovada

1. As três telas deixam de ler `weaknesses` e passam a ler `affinities`, mostrando **WEAK e RESIST juntos**.
2. `Combatant` ganhou `affinity_entries()` (lista de elementos não neutros) e `affinity_text()` (texto compacto `W: … · R: …`).
3. **Referência visual:** SMT IV / Persona 5 — todos os elementos em **células iguais, na ordem fixa**, cada uma com o ícone do elemento e **uma letra** abaixo (`W` fraco, `R` resiste, `–` neutro). Sem nomes de elemento, sem texto corrido, sem blocos gigantes.
4. **StatusScreen — desenho escolhido (opção 3, melhor formatada):** a grade fica na **base da arte**, sobre uma cunha escura com lados inclinados (mesma linguagem do parallelogram da arte) e fade para cima — sem barra retangular. Células de 36 px, chip de 24×22 com ícone de 16 px e letra de 11 px centralizada embaixo.
5. Células neutras ficam esmaecidas com `–`; W e R ficam coloridos (coral/azul). A grade ocupa 424 px, centralizada nos 488 px da arte.
6. **StatusPanel:** a linha “WEAKNESSES” virou “AFFINITIES” com o texto completo.
7. **Menus:** “Fraquezas:” virou “Afinidades:” com o texto completo.
8. **Seletor de alvo em batalha:** o selo “WEAK” agora vem de `affinity_entries()`, não de `weakness_text()`.
9. Nenhuma regra de dano, fila, status ou VFX foi alterada.

## Posição e colisão

- A posição vertical anterior (y=372) foi descartada: era exatamente onde a descrição da nature aparece.
- A faixa fica em y=486..572, dentro da área da arte (336..824, 68..572), acima das Skills (y=574).
- Não encosta na descrição da nature (376..520) porque a arte e a coluna direita são separadas em x (824 vs 848).
- O degradê não tem borda superior dura; as laterais inclinadas seguem o desenho da arte.

## Evidência

- Capturas: `test_captures/aff_opt_1.png`, `aff_opt_2.png`, `aff_opt_3.png`, `aff_opt_1_nature_open.png`, `aff_opt_none.png` e a folha `aff_options_sheet.png`.
- Script do protótipo: `tests/ui/capture_affinity_block.gd`.
- `test_d1157_affinity_schema.gd`: **D1157_PASS** (a mudança é aditiva no `Combatant`).
- Import do projeto sem erro de script.

## O que não foi feito

- StatusPanel e Menus não foram capturados em tela; só a StatusScreen tem protótipo visual.
- Nada de commit/push (D-022).
