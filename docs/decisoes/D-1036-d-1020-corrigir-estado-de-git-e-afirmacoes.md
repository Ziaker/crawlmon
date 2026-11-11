# D-1036 — D-1020: corrigir o estado de Git e as afirmações da entrega

- **Data:** 2026-11-09
- **Área:** Processo / Documentação / Git
- **Origem:** resposta do criador à pergunta 7 da auditoria.

## Frase literal do criador

> "7 sim"

## Decisão

1. Corrigir a D-1020 e `docs/vfx/FERRAMENTAS_VFX.md` para o estado real:
   - D-1020, `FERRAMENTAS_VFX.md` e `docs/vfx/referencias/capturas/...` já estão no HEAD (commit `dd614628`); não é verdade que "nada foi commitado".
   - As ferramentas 1, 4 e 6 têm ressalvas da auditoria; a ferramenta 4 está reprovada por `pose_height` não reproduzível.
   - `--dqt-mirror` grava o par DQT; o atacante padrão é Orc; Slime exige `--attacker=Slime` (D-1031).
   - "Ferramentas 2–6 não iniciadas" vira "2, 3 e 5 não iniciadas".
   - Remover "mundo e tela" da descrição da ferramenta 4; ela mede mundo, não tela.
2. Não commitar nem fazer push sem autorização expressa (D-022).
3. A correção é documental; não altera regra de jogo nem código de VFX.

## Ambiguidades em aberto

Nenhuma.

## Estado

Documentação atualizada. Sem commit/push.
