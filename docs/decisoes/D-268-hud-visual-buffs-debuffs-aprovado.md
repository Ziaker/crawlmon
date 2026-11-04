# D-268 — HUD visual aprovado: buffs e debuffs diagonais, cartões brancos

- **Data:** 2026-11-04.
- **Área:** Interface / HUD de combate — apresentação visual.
- **Origem:** iterações do protótipo HTML e aprovação expressa do criador nesta conversa.
- **Estado:** referência visual aprovada; **não implementado no jogo Godot**.

## Declarações literais do criador

> “além disso deixe o aliado branco tambem ao inves de roxo, usaremos roxo pra outra coisa”

> “acho que eles deviam estar estilizados e com angulos diagonais tambem”

> “Está perfeito”

> “Salve tudo no GitHub e adicione um docx sobre no GitHub também”

## Escopo visual aprovado

- O artefato visual aprovado é **`prototypes/crawlmon-hud-buffs-debuffs-aprovado.html`**, preservado sem mudanças arbitrárias após a aprovação.
- Buffs/debuffs nos cartões de jogador e aliado: pequenas peças **flat coloridas por inteiro**, angulares/diagonais, com ícones, nomes legíveis e sem grandes placas opacas cobrindo a arena.
- Cartões de Abra (jogador) e Pancham (aliado) **brancos**, com HP e ATB, preservando o menu principal em leque, a arena e a legibilidade do inimigo.
- Manter a tarja diagonal da habilidade em preparação, as abas de câmera e a apresentação atual do BattleLog até que outra decisão seja aprovada.
- O uso da cor roxa para outro propósito não foi especificado; **não atribuir nova função à cor sem aprovação**.
- Os nomes, valores e efeitos mostrados são **dados demonstrativos**; a aprovação não define novas regras de status, combate, Move, IA, câmera ou sincronização.

## Artefatos da referência

- HTML: [protótipo aprovado](../../prototypes/crawlmon-hud-buffs-debuffs-aprovado.html).
- Captura: [referência PNG](../hud/crawlmon-hud-buffs-debuffs-preview.png).
- DOCX: [documentação visual](../hud/Crawlmon_HUD_Visual_Aprovado_2026-11-04.docx).

## Limites, integração e pendências

- Esta publicação é **documental e de protótipo estático/interativo**, não altera `battle_hud.gd`, cenas ou scripts de combate.
- O protótipo ilustra uma situação com Abra, Pancham e Gible; não é uma implementação de Move nem altera a regra **D-235** de independência por personagem, lado e posição para o jogo real.
- **Overhaul do BattleLog:** reservado para uma discussão posterior; nenhuma mudança de comportamento, estrutura ou estética foi aprovada nesta publicação.
- Aplicam-se D-003 (preservação de escopo), D-015 (visibilidade do inimigo), D-022 (publicação autorizada), D-061 (registro) e D-235 (independência de Moves/VFX).
