<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1019 — Trajeto no chão: auditoria, correção (ao vivo, sem sobreposição) e 3 opções visuais

- **Data:** 2026-11-08.
- **Origem:** Conversa.

## Frase literal do criador

> apos isso eu quero 3 opções visuais /scenario-godot-vfx /scenario-godot-ui para escolher que vai ser o efeito visual deste trajeto que trouxemos devolta, quero ambição nas 3, PORÉM
> antes de iniciar, é necessário que faça uma auditoria e review sobre, levando em conta as regras mais recentes quanto a movimento, colisões, dobras (1 atacante se movendo na direção de outro atacante que já está se movendo) e outras coisas e já imediatamente corrigir elas, fazendo com que o trajeto reconheça estas coisas também.

## Auditoria da versão da D-1013 (regras: D-019, D-044/D-054, D-108, D-110, D-279, D-280, D-282, D-286, D-999)

| # | Caso | Problema da D-1013 | Correção |
|---|---|---|---|
| 1 | Alvo se move durante o wind-up (passo, desvio, knock, pulo de volta, "dobra": alvo já correndo em outro) | A faixa era desenhada uma vez, com os pontos do início do wind-up; ficava onde o alvo estava | Cada quadro lê onde atacante e alvo estão **desenhados** agora (D-280: o visual segue o mecânico) |
| 2 | Atacante se move (passo, empurrão) | Idem | Idem |
| 3 | Preenchimento | Um tween de relógio real; pausa/câmera lenta/pausa de status não o seguiam | Dirigido pelo relógio do `Battle`: `1 − time_left / total_windup` (D-019) |
| 4 | Choque frente a frente (D-279) e vários atacantes no mesmo alvo | Faixas empilhadas no mesmo lugar, ilegíveis | Faixas que se sobrepõem são separadas lado a lado, em ordem fixa, sem depender de direção, lado ou personagem |
| 5 | Troca de alvo no wind-up (D-108) | A faixa ficava no alvo antigo | Lê `inc.target` a cada quadro |
| 6 | Alvo desviado, ataque interrompido/cancelado, atacante ou alvo morto | Só sumia ao liberar o telegraph | Esconde na hora; libera com o telegraph como antes |
| 7 | Atacante e alvo no mesmo ponto | Já tratado | Mantido (não desenha) |
| 8 | Interceptação (D-110) e AoE | Alvo vem da declaração | Cada `Incoming` tem a sua faixa; sem regra nova |

Nada foi mudado em regra de combate (D-003); só o desenho.

## Decisão

1. A faixa é um desenho ao vivo do trajeto (`scripts/combat/fx/fx_lane.gd`), com as correções acima.
2. Entram 4 estilos, escolhidos por `--lane=N`: **0** faixa + bordas + preenchimento (atual); **1** fluxo de energia (chevrons); **2** células segmentadas (estilo ATB do HUD); **3** fenda de energia com faíscas. O criador escolhe um; os outros saem.

## Escolha do criador

> Opção 1: fluxo

Fica o estilo **1 (fluxo de energia: chevrons correndo ao alvo)**; os estilos 0, 2 e 3 e o parâmetro `--lane` foram removidos.

## Ambiguidades em aberto

- Largura da faixa (hoje 1,45 inimigo / 0,95 aliado) e se o trajeto deve continuar visível durante a corrida (hoje some quando o wind-up acaba).

## Estado

Implementado para revisão. Verificado em quadros (`scratch/lane/`): choque frente a frente, 3 corredores, aliados no mesmo alvo, alvo correndo em outro (normal e espelhada). Não verificado: estilo 3 de perto, cruzamento com alvos distintos e golpes à distância.
