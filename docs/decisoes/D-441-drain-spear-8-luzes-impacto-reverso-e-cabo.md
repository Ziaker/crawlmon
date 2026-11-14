<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-441 — Drain Spear no jogo: impacto reverso, 8 luzes azuis no lugar da coroa e cabo 20% mais fino

- **Data:** 2026-11-08.
- **Área:** VFX / Motion Composer / combate real.
- **Origem:** pedido do criador depois de assistir à versão restaurada.
- **Estado:** implementado; aguardando aprovação visual.
- **Escopo:** o Move no combate real (DQT), não o laboratório.

## Frases literais do criador

> "O efeito visual do impacto com badge steal ainda devia acontecer, só que virado para o personagem ao invés"

> "Junto do impacto, na fase pós-impacto do badge steal, deviam surgir do inimigo, imediatamente após o impacto, 8 luzinhas azuis de direções diferentes que voam até o jogador e o rodeiam (substituindo a coroa que fica acima dele) e depois somem lentamente com a opacidade"

> "O cabo da lança está mt largo, deixe 20% menos largo (não mude a ponta nem a lamina)"

> "implemente o move no jogo e pare de usar esse laboratorio, eu preciso ver ele funcionando no próprio jogo com as animações e etc..."

Respostas de ambiguidade:

> "Só o Orc do DQT" (dono do Move).

> "Só as 8 luzes, sem coroa e sem órbita".

> "Saem do ponto de impacto, não ao redor do inimigo".

> "Manter como debug, não usar na entrega" (laboratório).

## Decisão

1. **Impacto reverso.** O mesmo leque de impacto do Badge Steal continua sendo desenhado, mas com o eixo invertido: do contato para o atacante, não do contato para longe. O ponto de contato permanece no alvo.
2. **Oito luzes azuis.** Imediatamente após o impacto, 8 luzes azuis saem do ponto de contato em 8 arcos diferentes, voam até o atacante e formam um anel horizontal acima do corpo dele, na altura onde ficava a coroa. O anel acompanha o corpo desenhado enquanto ele volta; depois fica parado e some por opacidade.
3. **Sem coroa/órbita no jogo.** A camada `stolen_orbit` (coroa/órbita) não é desenhada na batalha. Os streaks reversos e os orbes do sifão do Badge Steal continuam (D-379); só a coroa/órbita foi substituída pelas 8 luzes.
4. **Cabo 20% mais fino.** A espessura do cabo (`spear_part` "shaft") recebe fator 0,8. A lâmina e a ponta não mudam.
5. **Move no jogo.** O Orc do DQT é o líder controlável e tem a Drain Spear no menu Fight; custo de 3 MP conforme a tabela atual. O laboratório permanece como depuração, fora da entrega.

## Onde vive

- `scripts/combat/fx/fx_drain_spear.gd`: fase de impacto reverso, chamada do sifão sem coroa e spawn das 8 luzes.
- `scripts/vfx/drain_spear_badge_lights.gd`: as 8 luzes (arco, anel, acompanhamento do corpo e fade).
- `scripts/vfx/drain_spear_vfx.gd`: `crown = false` na batalha.
- `scripts/motion_composer/runtime/motion_presets.gd`: opção `crown` (padrão `true`; o teste antigo da V1.10 continua vendo a coroa).
- `scripts/motion_composer/representations/motion_rep.gd`: `thick_s * 0.8` só no cabo.
- `scripts/combat/battle_fx.gd`: leitura pública da posição desenhada do corpo (`drawn_body_center`).
- `scripts/combat/dqt_test_party.gd`: Orc líder, com a Drain Spear e MP.

## Relações

D-235, D-308, D-377, D-378, D-379, D-383, D-061. O laboratório continua como depuração, conforme resposta do criador.
