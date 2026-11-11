# D-1162 â€” Javelin Throw VFX 3D (OpÃ§Ã£o C): escopo, fonte e relÃ³gio

> **AtualizaÃ§Ã£o 2026-11-11 (D-1171):** o item 2 (nÃºmeros do prompt) foi **superado**: a fonte visual oficial passou a ser o **HTML Card C**. O item 1 (batalha + laboratÃ³rio) e o item 3 (fases reais) continuam.

- **Data:** 2026-11-11.
- **Ãrea:** VFX / Combate / Processo.
- **Origem:** prompt de implementaÃ§Ã£o do VFX "Javelin Throw" (OpÃ§Ã£o C â€” "LanÃ§a do Ponto Fraco") e respostas do criador Ã s trÃªs ambiguidades apontadas antes do cÃ³digo.

## O que o criador respondeu (literal)

> "Batalha real + laboratÃ³rio (Recomendado)"

> "NÃºmeros do prompt (Recomendado)"

> "Fases reais do Battle (Recomendado)"

## DecisÃ£o

1. **Escopo:** o efeito vale na **batalha real** (ligado ao `javelin_throw`) e tambÃ©m numa **cena de laboratÃ³rio** com vistas Normal/Espelhada/OblÃ­qua, troca de lado e scrub. A entrega nÃ£o Ã© sÃ³ um protÃ³tipo isolado.
2. **Fonte da geometria:** quando o prompt e o HTML anexado divergem, valem os **nÃºmeros explÃ­citos do prompt** (lanÃ§a de 2,15 m, ponta de 0,495 m, coroa de 0,58/0,46 m, 7 pÃ³s-imagens, estrela de 3 octaedros). O HTML serve de referÃªncia de paleta, material e leitura, nÃ£o de medida.
3. **RelÃ³gio em combate:** o efeito Ã© desenhado pelas **fases reais do `Battle`/`Incoming`** (D-019/D-1040). O relÃ³gio fixo de 0,75 s / 1,05 s / 1,85 s fica **somente no laboratÃ³rio**. Nenhuma duraÃ§Ã£o, dano, crÃ­tico ou custo de gameplay muda (D-1103).
4. **Fases:** Wind-up (montagem em 5 peÃ§as, pulso, estrela e retÃ­culo), Release (coroa prismÃ¡tica de 7 lÃ¢minas), Trajeto (voo balÃ­stico, 7 pÃ³s-imagens 3D e feixe) e Impacto (cruz 3D, flash crÃ­tico, anel atrasado, anel rasteiro, detritos e faÃ­scas), com transiÃ§Ã£o contÃ­nua entre elas (D-308).
5. **Agnosticismo:** tudo deriva do atacante e do alvo reais (osso/socket da mÃ£o quando existir, AABB real do corpo como fallback), da cÃ¢mera ativa e do eixo atacanteâ†’alvo; nenhum `is_player`, nome de personagem, time, lado ou coordenada fixa no efeito (D-235).

## Ambiguidades em aberto

Nenhuma apÃ³s as trÃªs respostas. A divergÃªncia entre o tempo real de voo (0,25â€“0,70 s no `Battle`) e os 0,30 s do protÃ³tipo fica resolvida pelo item 3: o laboratÃ³rio usa 0,30 s; a batalha usa o tempo real.

## Estado no cÃ³digo

**Implementado em 2026-11-11; aguardando aprovaÃ§Ã£o visual do criador.**

- Efeito visual: `scripts/vfx/combat/javelin_throw_vfx.gd` (5 peÃ§as, coroa de 7 lÃ¢minas, 7 pÃ³s-imagens, cruz 3D, flash, anel atrasado, anel rasteiro, detritos e faÃ­scas; shaders PBR/emissivo/x-ray).
- Driver de batalha: `scripts/vfx/combat/fx_javelin_throw.gd`, ligado ao `BattleFx` (telegraph, `_process`, hit e cancelamento). O `vfx_key` do Move passou a `&"javelin_throw"`; o projÃ©til genÃ©rico e o retÃ­culo/aura genÃ©ricos sÃ£o suprimidos sÃ³ para este Move.
- LaboratÃ³rio: `scripts/debug/javelin_vfx_lab.gd` + `scenes/debug/javelin_vfx_lab.tscn` (Normal/Espelhada/OblÃ­qua, troca A/B, pausa, quadros 0,75/0,90/1,05/1,07 s e scrub 0â€“1,85 s).
- Teste: `tests/battle/test_javelin_vfx.gd` (`RESULT: PASS`, ampliado na auditoria).
- Auditoria completa: `docs/vfx/AUDITORIA_JAVELIN_THROW_D1162.md` (prompt + HTML + script; correÃ§Ãµes e adaptaÃ§Ãµes).
- Prova de combate: suÃ­te `tests/battle/run_agent_combat_tests.py` **24/24**; `--test-d235` **PASS** para Javelin Throw; `--audit-leaks` **leaks=0 nodes=[]**; `--envelope-graph` sem pops.
- VÃ­deo D-308: `test_captures/javelin_throw_orc_both_sides.mp4` (Orc atacando dos dois lados, normal + espelhado, 135 quadros por vista) e folha de prova `test_captures/javelin_audit/proof_sheet_full.png`.

**NÃ£o verificado:** todos os personagens/tamanhos do jogo (testado com Abra, Gible, Pancham e Cyclops); leitura fina das 5 peÃ§as no fundo do campo (a montagem foi verificada no laboratÃ³rio); o enquadramento â€œalvo pertoâ€ do vÃ­deo espelhado ficou no laboratÃ³rio, porque a cÃ¢mera automÃ¡tica do gravador ficou do lado do atacante; Ã¡udio nÃ£o faz parte deste Move.

Nenhuma regra de combate foi alterada; `docs/REGRAS_DO_JOGO.md` nÃ£o foi tocado.


