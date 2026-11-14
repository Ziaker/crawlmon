# D-1198 — Move Sukukaja (speed up, inspirado no SMT)

- **Data:** 2026-11-12
- **Área:** Combate (Moves)
- **Origem:** Conversa
- **Estado:** criado no código (diff do deepseek-code, conferido e aplicado: `content/moves/sukukaja/move.tres`, catálogo, `skill.gd`, `skill_legacy_data.gd`, `move_behaviors.gd` classe `Sukukaja`, registro, `move_inspect_info.gd`); sem VFX no jogo; não testado em batalha

## O que o criador disse (literal)

> "adicione o move de speed up inspirado em o de SMT"
>
> "Um aliado" (alvo)
>
> "tudo igual aos outros dois exceto efeito visual e efeito mecanico, simples assim"
>
> "faca todos custarem 7mp e 1atb" (ver D-1197)
>
> "Pera é sukukaja e não o equivalente de 1 alvo só, tá certo ser no grupo inteiro, aumente o custo também pra 10MP e 2atb de custo" (**substitui** o "Um aliado")

## Decisão

1. Move STATUS "Sukukaja": buff de velocidade (`speed_buff`, +1 estágio, até +5, dura a batalha) em **todos os aliados** (grupo), oposto do Sukunda. Custo **10 MP e 2 ATB** (D-1197). Versão anterior (um aliado, 7 MP, 1 ATB) está no código até o diff novo ser aplicado.
2. Demais campos (wind-up, stand_gap, hold, plan_profile, elemento, tags) copiados do Sukunda.
3. O protótipo visual aprovado pelo criador ("perfeito") está em `prototypes/sukukaja/sukukaja.html` (branch `claude/adoring-hodgkin-c704e2`, D-1196 daquela branch). VFX **não** está ligado ao jogo.

## Pendente / em aberto

- **Seleção do alvo:** o jogo não tem escolha de aliado. Para a IA o alvo de um Move friendly não-AoE é o próprio lançador (`battle_ai.gd:126`); para o jogador, o líder (`battle_scene.gd:1114-1118`, `:1350`). "Um aliado escolhido" não existe hoje.
- **Textos visuais** (`visual_text`, `motion_text`, `windup_text`, `visual_motion_text`, `phase_visuals` e os dicionários de `skill_legacy_data.gd`) estão **copiados do Sukunda** (engrenagens amarelo-verdes, "slowing spectral sludge"), errados para um buff. A palavra "hastening blessing" em `mechanics_text` foi escolha do DeepSeek, não do criador.
- `smt_buff_controller` não conhece "sukukaja": sem VFX nem popup no jogo até ser ligado.
- `ai_status_value` do Sukukaja (base 24.0, direção de buff) é escolha do DeepSeek.
- Numeração: o D-1196 da branch `claude/adoring-hodgkin-c704e2` (VFX do Sukukaja) colide com o D-1196 deste checkout (Dig e Sand Attack).
