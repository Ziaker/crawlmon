# D-433 — Redefinição da Tela Pós-Combate para Level Up HUD e Regra de Transição na Vitória

**Status:** Regra aprovada; **implementação no Godot REJEITADA pelo criador em 2026-11-08** (ver §5). O código continua ligado à batalha, sem aprovação visual.  
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

---

## 5. Implementação rejeitada (registro de 2026-11-11)

Fonte: conversa do Antigravity "Post-Combat HUD Prompt Design" (`46602981-5c4d-4b7f-bad5-df456d718436`), mensagens do criador depois do port para o Godot. Registro pedido pelo criador em 2026-11-11 ("Sim, registrar").

### Frases literais do criador

> "não está nem PERTO de como é o html... ainda não está igual, além da maioria dos textos estarem fora de seus respectivos blocos, não estarem no angulo correto dos blocos paralelogramas e a maioria das coisas estarem quebradas ou mal posicionadas"

> "todo esse tempo e agora ficou ainda pior, que que adiantou?"

> "pq vc não corrige os textos vazando?? vc sabe que eles estão vazando, sabe que não corrigiu, e eles CONTINUAM VAZANDO"

> "já entendi q vc não quer ajeitar isso, vc não consegue mesmo replicar o html? responde e não mexa em nada"

### Estado

1. **A regra da §2 continua valendo** (nome Level Up HUD; abre só com level up; sem level up volta direto à exploração).
2. **A implementação Godot não foi aprovada.** O requisito do criador é a fidelidade total ao `prototypes/hud_post_combat.html` ("seguir exatamente tudo que tá no html perfeitamente, sem diferenças"), e o resultado não atingiu isso.
3. **O código continua no jogo:** `scripts/combat/battle_scene.gd` abre `scenes/ui/level_up_hud.tscn` quando alguém sobe de nível. Nada foi removido nem alterado por este registro.
4. **Causa técnica identificada (investigação de 2026-11-11, sem mudar código):** o HTML monta o layout reto e inclina com `transform: skewX(-9deg)` (com 42 `.unskew` nos filhos); no Godot o port desenha só o fundo em paralelogramo (`scripts/ui/components/slanted_panel.gd`) e os textos ficam retos em caixas retangulares, por isso vazam e saem do ângulo. Também pesam o espaço (HTML para até 1800 px; jogo em 1280×720) e a verificação por recortes em vez da tela inteira.

### Em aberto (decisão do criador)

- Refazer o port, manter o código atual sem aprovação ou desligar o Level Up HUD até ser refeito.
- Se refeito: como tratar texto inclinado no Godot (texto reto dentro de blocos inclinados, fonte itálica, ou render do bloco inteiro inclinado) e qual resolução usar como referência.
