<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1244 — Summon, Fase 8: respostas do criador às pendências da D-1232

**Data:** 2026-11-16
**Área:** combate, Summon
**Estado:** respondida; implementação da Fase 8 depois da auditoria das Fases 1 a 7.
**Relacionadas:** D-1232, D-1233, D-1229, D-1239, D-021, D-161.

## Respostas literais do criador

- Protagonista substituível: "Pode sair".
- Protagonista nocauteado comanda o Summon: "Sim, mesmo nocauteado".
- Se está nocauteado, de onde sai o ATB: "Do ATB que ele tinha ao cair (Recomendado)" (precisa de 2 blocos de ATB dele; sem Burst, sem outro aliado pagando).
- Moves de quem sai: "Cancelam e devolvem custos (Recomendado)" (igual à D-1239: ATB, MP, timer de MP e Burst voltam; a fila dele e a apontada a ele é limpa).
- ATB de quem entra: "Entra com ATB 0 (Recomendado)".
- Posição: "Na vaga de quem saiu (Recomendado)".
- Ordens aos aliados com o protagonista fora: "as ordens pros aliaados ainda devem ser permitidas de serem realizadas mesmo com o lider fora, é uma mudança na mecanica por completo"; esclarecida com: "Menu passa ao 1º ativo vivo (Recomendado)" (se o protagonista sai ou cai, o menu passa a comandar o primeiro ativo vivo; os demais seguem por IA).

## Pendências que continuam sem regra

- Quem paga os 2 ATB quando o protagonista já saiu da equipe ativa (ele não está nocauteado, está fora).
- Efeitos temporários (buffs, status, Guard, Burn) de quem sai ou entra.
- Texto e visual do seletor de Summon; textos de motivo.
- A mudança do controle (D-021, allies por IA) é nova: o menu migra para o primeiro ativo vivo; não foi decidido o que acontece com a fila e o ATB mostrado.

## Respostas adicionais (2026-11-16, depois da auditoria das Fases 1 a 7)

- BOOST ativo no fim da batalha: "Acaba junto, atributos voltam (Recomendado)" (implementado em `Battle._check_end`).
- Quem paga os 2 ATB com o protagonista fora da equipe ativa: "O ativo que o menu comanda (Recomendado)" (o 1º ativo vivo, com o ATB dele, sem Burst).
- Efeitos temporários de quem sai e entra: "Quem sai perde tudo; quem entra começa limpo (Recomendado)" (HP e MP ficam como estavam).

**Fase 8, lógica (2026-11-16):** `Battle.summon()`/`summon_refusal()`/`menu_owner()`/`summon_payer()` implementados (DeepSeek escreveu a parte A, aplicada por `--recount`; eu escrevi os cenários `--summon=<modo>` porque o DeepSeek não entregou patch da parte B). Falta a cena: seletor, modelos, cartões e o menu seguindo `menu_owner()`.
