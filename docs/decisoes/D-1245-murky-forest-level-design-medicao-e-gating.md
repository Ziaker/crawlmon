<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1245 — Murky Forest: medição de portas, descanso pendente, gating suave e áudio fora

- **Data:** 2026-11-16
- **Área:** overworld 3D / level design / exploração / processo
- **Relacionadas:** D-1181, D-1208, D-1133, D-1151, D-1023, D-1028, D-316, D-317, D-235, D-1204, GDD §7.20 (R29-Q2/R29-Q3), §7.21 (R30-Q2/R30-Q4), §7.24 (R33-Q3/R33-Q4), §7.27 (R36-Q2/R36-Q3).
- **Estado:** decisões parciais registradas. A direção de revisitas foi aprovada depois em D-1246.

## Frases literais do criador

> "Medir e alargar se necessário (Recomendado)"

> "Fica pendente (Recomendado)"

> "Confirmar gating suave (Recomendado)"

> "Áudio fica integralmente fora do escopo por ora."

## Decisão

1. **Portas (D2):** medir primeiro a largura livre necessária para o triângulo de seguidores (D-1023) contra as portas de 2 m da D-1151; **alargar se a medição mostrar que não cabe**. O número final não foi escolhido — vem da medição (Task 1 do plano).
2. **Pontos de descanso (D3):** **ficam pendentes**. A D-316 nunca foi implementada no 3D; não colocar pontos de descanso neste andar sem decisão nova. O GDD R31-Q5/R32-Q2 (descanso seguro, MP integral, HP pendente) continua valendo como requisito, não como implementação.
3. **Gating (D4):** **suave** — visibilidade, ameaça e recompensa guiam o jogador. Não existe sistema de chave/habilidade decidido; não inventar.
4. **Áudio:** **fora do escopo por ora**. Nenhuma camada de áudio de ambiente entra neste trabalho.

## Proposta histórica de revisitas

A direção foi aprovada posteriormente e registrada em [D-1246](D-1246-murky-forest-destino-recorrente.md), com seus detalhes em aberto.

Na discussão do item D1, a proposta do Codex intitulada "Murky Forest como destino recorrente" descreveu a floresta como expedição conhecida que o jogador tem motivos para revisitar. O ciclo proposto era **ver no Hub que algo aconteceu → entrar com intenção → encontrar situação nova em lugar conhecido → voltar com descoberta que dê assunto à próxima**. O primeiro recorte previa **duas expedições ligadas pelo Hub**, usando corredor, abrigo da Super Poção e arco acima dele, com prioridade a eventos que **mudam o que o jogador faz ali**.

O texto termina literalmente:

> "Gatilhos, ordem dos eventos, recompensas e o que persiste entre expedições ficam em aberto para sua decisão. A proposta foi redigida no Codex e ainda precisa ser testada em jogo."

Portanto **não** é registrada como regra: gatilhos, ordem dos eventos, recompensas, persistência entre expedições e a geometria nova (arco de pedra, passagem soterrada/nível inferior, posto de vigia) continuam **pendentes**. O que o GDD já aprova é: eventos especiais com consequências para a exploração (R29-Q2), novas expedições a dungeons concluídas (R29-Q3), incentivo para repetir (R30-Q4), prioridade de encontros/eventos narrativos (R34-Q2), eventos opcionais para o chefe (R36-Q2) e estado persistente **na mesma expedição** (R36-Q3). A persistência **entre** expedições é explicitamente pendente em R30-Q2 e R36-Q3.

## Ambiguidades

- A D-1246 registra a aprovação da direção de revisitas. Os detalhes de implementação continuam em aberto.
- Geometria nova (arco, passagem inferior, posto de vigia) não existe no lab (D-1151/D-1133) e interage com a câmera de 6,2 m / 22° e a navmesh manual de D-1023 — precisa de medição antes de virar blockout.
- "Encontro raro ou candidato a recrutamento" esbarra em R32-Q5 (candidato especial exige tarefa) e na rodada de Employ/Summon (D-1229+); não decidido.
- Nenhum valor de intensidade, cor, tempo ou quantidade foi escolhido nesta decisão.

## Estado

Documento criado para registrar as respostas D2/D3/D4 e o escopo de áudio. Plano em `docs/plans/2026-11-16-murky-forest-level-design.md`. Nada publicado; nenhum commit/push.
