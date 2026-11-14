# D-1199 — WHIFF novo (letras separadas) aprovado; o teste do D-1166 é que se atualiza

- **Data:** 2026-11-12
- **Área:** Combate (VFX do dodge errado)
- **Origem:** Conversa, depois de ver o vídeo de comparação `prototypes/whiff_comparacao/whiff_head_vs_nova.mp4` (HEAD x nova, vistas normal e espelhada)
- **Estado:** aprovada pelo criador. O jogo (`scripts/vfx/combat/fx_dodge.gd`, redesenho D-322, ainda não commitado) já tem a versão nova. Atualização do teste `tests/battle/test_d1166_mistimed_visual.gd` em andamento (diff do deepseek-code, a aplicar após auditoria).

## O que o criador disse (literal)

> "Eu prefiro a nova, aprovo"

## Decisão

1. O WHIFF do dodge errado passa a ser o novo: letras W-H-I-F-F separadas (Node3D com 5 Label3D) em vez do texto único `float_text`.
2. O teste do D-1166 estava desatualizado: ele conta Label3D "WHIFF" filhos diretos de `fx` (asserção `test_d1166_mistimed_visual.gd:70`). O teste se atualiza ao formato novo; o jogo não é alterado.

## Ambiguidades em aberto

- O vídeo comparou o HEAD com a working tree inteira (que tem outras mudanças de VFX não commitadas); a aprovação é do WHIFF visto no vídeo.
- O criador não disse nada sobre commitar o redesenho D-322.
