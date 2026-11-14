<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1136 — Corrida monstruosa da coruja

> agora vamos fazer a animação de corrida seguindo a ideia do walk mas sendo mais monstruoso

> vire o rosto dele mais pra cima ele parece q ta olhando pro chão

A corrida parte da caminhada v20 aprovada, com o mesmo encadeamento de apoio, impulso e suspensão. A corrida é uma Action separada, em um arquivo do Blender só com a coruja. A primeira versão explora uma cadência mais rápida, o tronco inclinado à frente e a alternância das garras. Aprovação visual da corrida pendente.

Salvo em `assets/modelos/owl/blender/owl_run_monster_v1.blend` com a Action `Run 1 Monster Charge` ativa, quatro passadas em 29 quadros a 24 fps e apenas o rig da coruja. Conferido de perfil e em três quartos, com Motion Lens e amostras de chão entre quadros. Ainda não integrado ao jogo.

Na v2, o rosto foi levantado em 15° ao longo da corrida. Salvo em `assets/modelos/owl/blender/owl_run_monster_v2.blend` com a Action `Run 2 Monster Charge Head Up` ativa. Conferido de perfil e em três quartos no Blender.

O criador aprovou a v2: “perfeito, salve e me dê a checklist novamente”. Arquivo salvo, com uma cena e apenas o rig da coruja.
