# D-025 — Reverter a Fase 2, mantendo só o que o criador aprovou

- **Data:** 2026-11-02
- **Área:** Processo / Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> REVERTE TUDO, VOLTA TUDO PRA FASE 1, REVERTE ABSOLUTAMENTE TUDO QUE FEZ NA FASE 2 EXCETO O QUE EU DISSE QUE ERA OK MANTER

## Decisão

Voltar ao estado da **Fase 1** (commit `e59015fb`). Mantido da Fase 2 **somente** o que o criador marcou como OK (D-024):
1. Hit-stop que congela o relógio da batalha e todas as animações.
7. Corpos de quem morre ficam onde caíram.
8. Vencedor pego no meio de um ataque volta pulando antes da pose de vitória.
10. Golpes amigáveis não são esquiváveis.
12. Correção do fogo amigo do AoE (a equipe atingida é a do oponente do atacante).

Revertido: todo o resto da Fase 2 (posições autoritativas no motor, `AttackPlanner`, `AttackMotion`, `BattleSpace`, investida até o contato, perseguição no golpe, recuo do atingido, interceptação na declaração, snap de contato, retarget do AoE, correção de VFX `reparent`, testes `tests/battle`, `docs/COMBATE_ARQUITETURA.md`, flags `--drive/--seed` do trace).

Preservado (não é da Fase 2): o trabalho dos movimentos SMT/AoE/status e as correções de VFX do criador (escala de VFX por distância, buffs/debuffs, textos de status, etc.).

## Ambiguidades em aberto

Os itens 7 e 8 foram **reimplementados sobre o código da Fase 1** (antes dependiam das posições do motor); o comportamento é o mesmo na intenção, mas o código é novo e **não foi visto na tela**.

## Estado no código

Revertido na branch `feat/smt-moves`. **Fato a registrar:** o commit `451e59c1` (já na `main` do GitHub) trazia, junto com as correções de VFX, os arquivos da Fase 2 (`attack_planner.gd`, `attack_motion.gd`, `battle_space.gd`). A `main` do GitHub, portanto, **ainda contém a Fase 2**; só a branch `feat/smt-moves` foi revertida. Nada foi enviado ao GitHub.
