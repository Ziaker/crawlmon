# D-1196 — Dig e Sand Attack: integrar a opção A do HTML "dust shaders unificados", com o visual idêntico

- **Data:** 2026-11-12.
- **Área:** VFX de Move / combate.
- **Relacionadas:** D-235, D-308, D-335, D-337, D-1030, D-1154, D-032.
- **Status:** registrado; implementação a seguir, com auditoria do código do DeepSeek.

## O que o criador disse (literal)

> vamos integrar perfeitamente os efeitos de dig e sand attack de ambas opcoes A de um html que vou lhe enviar adqui a pouco, apenas se prepare junto do deepseek, vc deve auditoriar o codigo dele e o resultado pra fazer questao de que vai ficar perfeitamente igual ao html visualmente

Arquivo: `brawlmon_crawlmon_3d_atb_babylon_js_vfx_atelier_dig_sand_attack_unified_dust_shaders.html` (Dig `tectonic` = "OPÇÃO A • ANEL DE POEIRA VOLUMÉTRICA & 6 PEDRINHAS SUTIS"; Sand Attack `sirocco` = "OPÇÃO A • JATO DE NUVENS VOLUMÉTRICAS FBM & VÉU SIROCCO (ACC ↓)").

Respostas às perguntas:
- Corpo de quem cava no Dig: **"Também o corpo do HTML"** (giro e salto ao entrar no chão, sumiço, saída com giro no alvo, retorno com cambalhota).
- Extras de tela do HTML (flash, vinheta elemental, luz pontual): **"Não entram"**.
- Reações do alvo: **"tremor sim e knock up"**.

## Decisão

1. Entram só as **opções A** (Dig `tectonic`, Sand Attack `sirocco`); B e C do HTML ficam fora.
2. Visual **idêntico ao HTML**: mesmas formas, camadas, cores e tempos, com os shaders de poeira (`digDustCloud`, `digDustVeil`, `crownShell`, `digCrater`) portados ao Godot.
3. Corpo de quem cava segue a coreografia do HTML.
4. Sem flash de tela, sem vinheta e sem luz pontual.
5. Reação do alvo: tremor e knock-up entram.

## Segunda rodada (2026-11-12, após a auditoria)

- Dig, onde quem cava reaparece no alvo: **"Em cima do alvo"** (sem o +0,95 m do HTML).
- Dig, tempos: **"Altere pra ter os tempos do HTML"** (2,48 s, sem wind-up de 1,0 s).
- Tamanho: **"Metros fixos do HTML"**.
- Sand Attack, reação do alvo (opções "Só tremor" / "Tremor e knock-up"): **"Nenhum dos dois"**; esclarecido: **"Sem tremor e sem knock-up"** (só a poeira; cegueira como o jogo já faz).
- Opacidade e suavização: **"0,85 e 0,22 do HTML"**, fixos no jogo.
- Dig, mecânica (terceira rodada): os tempos do HTML valem **também na mecânica do combate** ("Fica exatamente como o do HTML então muda sim"). Wind-up e release, literal: "O wind up é o pulinho que ele dá e o release é quando ele entra embaixo do chão ficando intangível". Wind-up termina e release/intangibilidade começam em **0,229 s**; intangível **até a erupção (1,38 s)**; dano e reaparição em 1,38 s; volta ao ponto inicial até 2,48 s. Custo (ATB/MP) e dano x1,5 não foram mexidos.
- Dig mantém tremor e knock-up no alvo (1ª rodada).

## Pendente (não foi dito pelo criador; não implementar)

- Tinta de areia, pílula ACC e popups do HTML (continuam como o jogo já faz).

- Tinta de areia no alvo (`sandTint`), pílula ACC e popups do HTML: continuam como o jogo já faz; só mudam se ele pedir.
- Tamanho em metros fixo vs. escala por tela a ~37 m (D-335/D-334 dizem fixo no mundo; confirmar na verificação).

## Estado da implementação (2026-11-12)

- **Dig A: implementado, aguardando a aprovação do criador.** Mecânica: `plan_profile = &"dig"` (`attack_planner.gd`), wind-up 0,229 s, trajeto 1,151 s, golpe de 0 s, retorno 1,10 s. Visual: `scripts/vfx/combat/fx_dig.gd` (corpo, tremores, erupção, reação do alvo) sobre a biblioteca `scripts/vfx/combat/dust/` (shaders `shaders/dust_*.gdshader`).
- Consequências aplicadas para ficar igual ao HTML (a confirmar com o criador): `visual_push = 0` no Dig (o alvo não é empurrado, só treme e sobe), o impacto antigo de basalto e a nuvem de pouso do Dig foram removidos (o HTML não os tem).
- **Sand Attack A: ainda não feito.**

## Ajuste do trajeto do Dig (2026-11-13)

> "tem mais efeito no impacto do que no trajeto, o impacto tá exagerado de tanto efeito e o trajeto tá pobre" / "o problema é o trajeto só ter efeito de dust e mais nada" / "me surpreenda, sigo qualquer recomendação sua"

- Impacto: `targetScale = 1` (metros fixos do HTML); a escala do corpo no jogo (~1,5-1,64x) deixou de inflar o impacto.
- Trajeto (recomendação da IA, aprovada por delegação do criador): em cada um dos 6 tremores entram uma placa de terra que se ergue (HTML opção C, `ridgeWedge`) em escala 2,5x e 3 pedras saltando, além do anel de nuvens; o monte pequeno da opção A saiu. A escala 2,5x é escolha da IA para ser legível a ~30 m: o criador pode mudar.

## Trajeto do Dig, 2ª tentativa (2026-11-13)

> "colocar uma mesh de pedra igual repetida não é o tipo de coisa impressionante que eu tava esperando"

- As placas e pedras repetidas saíram. No trajeto entra um cume de terra contínuo que acompanha o Dig escondido (shader `shaders/dust_burrow_ridge.gdshader`, `DustFx.burrow_ridge`): sobe como um monte, abre uma vala atrás de si e deixa solo revirado, com fissuras. Não vem do HTML: criação da IA por delegação do criador; largura 4,4 m e altura 1,8 m (escolha da IA, o criador pode mudar). Os 6 anéis de poeira do HTML continuam.

## Volta do Dig: arco e parada no chão (2026-11-13)

> "está mas a volta, o pulo, não é um arco, está bugado" / "depois de aterrisar (no uppercut) ele tem que ficar no minimo 1 segundo pra pular depois" / "1 segundo no chão depois de finalizar"

- O HTML tem um defeito: o uppercut sobe a 2,65 m e na volta o corpo estala para 0 antes do arco. Agora o uppercut sobe e aterrissa (0,38 s, 3 voltas inteiras, de frente), o Dig fica parado **1,0 s** no chão e só então pula de volta em arco contínuo.
- A altura do arco é proporcional à distância (0,214 × distância; no HTML 2,45 m para 11,45 m), no mínimo 2,45 m.
- Mecânica: `hold = 1.38` (0,38 + 1,0) e `plan_return = 2.1` em `investida_escavadora/move.tres`. "No mínimo 1 s" foi lido como exatamente 1,0 s (a confirmar).

## Hit FX do Dig (2026-11-13)

> "faça com que o dig tenha o hitFX do tackle"

- O contato do Dig usa o hit FX do Tackle (`_tackle_impact`, via `move_vfx_registry.gd`), além da erupção de poeira do HTML.
