# D-433 — Redefinição da Tela Pós-Combate para Level Up HUD e Regra de Transição na Vitória

**Status:** Aprovada e Em Implementação  
**Data:** 2026-11-08  
**Autor:** Criador  
**Decisões Relacionadas:** D-135 (Alocação Manual de Pontos), D-394 (Progressão de Pontos e Proficiências), D-400 (Tela de Vitória e Pausa Pós-Combate), D-401 (Modal Obrigatório de Alocação de Pontos do Líder), D-416 (Paralelogramos Flat), D-417 (Padrão Visual Fichas de Moves), D-418 (VFX de Celebração de Nível Sem Flash), D-420 (Inspeção Técnica de Move em Tela Cheia)

---

## 1. Frase Literal do Criador

> *"uma coisa, mudança de planos em apenas uma transição*
> 
> *o post combat hud agora se chama Level up hud, ele aparece quando upa de nivel, substituindo o hud de post-combat atual (que iremos recriar outra hora)*
> 
> *de resto implemente"*

---

## 2. Decisão

1. **Renomeação de Componentes:**
   - A tela unificada de 3 colunas desenvolvida com estilo SMT III, modelo 3D, alocação de pontos, fichas de moves e celebração Dragon Ball passa a se chamar oficialmente **Level Up HUD** (`LevelUpHUD`), nos arquivos `scenes/ui/level_up_hud.tscn`, `scripts/ui/level_up_hud.gd`, `scenes/debug/level_up_hud_lab.tscn` e `scripts/debug/level_up_hud_lab.gd`.
2. **Substituição da HUD Pós-Combate Atual:**
   - O `LevelUpHUD` substitui a interface atual de pós-combate (`VictoryPanel` e `LevelUpModal`) exclusivamente quando ocorre subida de nível de pelo menos um combatente da equipe (`any_leveled_up`).
   - Se **nenhum** combatente subir de nível, o jogo não abre HUD e retorna diretamente para a exploração de masmorra (`GameState.end_battle(true)`), até que a nova HUD geral de pós-combate seja recriada em outra rodada futura pelo criador.
3. **Escopo de Implementação:**
   - Todos os componentes aprovados no documento de design (`CharacterModelLoader`, shaders `skew_panel.gdshader`, `dragonball_aura.gdshader`, `ground_shock_ring.gdshader`, componentes `SlantedButton`, `StatPipsStrip`, `MoveCard`, `MoveInspectionModal` e laboratório de debug) devem ser implementados integralmente conforme a especificação aprovada.

---

## 3. Ambiguidades e Esclarecimentos

1. **Gatilho de Nível:** A tela ativa se qualquer combatente da equipe subir de nível (`levels_gained > 0`), mantendo o foco inicial na aba do Líder e a trava D-401 se houver pontos pendentes.
2. **Vitória sem Level Up:** Confirmado pelo criador: retorna diretamente para a masmorra sem abrir painéis, aguardando a recriação da pós-combate geral.

---

## 4. Estado

Registrada em `docs/decisoes/` e incorporada ao pipeline de implementação.
