<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-313 — Overworld: tiles podem ser refeitos e efeitos visuais autorizados

- **Data:** 2026-11-05
- **Área:** Exploração / visual
- **Origem:** Conversa (resposta à P1 do plano do overworld)

## O que o criador disse (literal)

> mude os tiles pra ficarem mais bem feitos e menos quebrados entre sí também, eu não lembro de ter proibido a mudança, Poeira/partículas, Tochas cintilando, NPC olha para você, Sprites de Pokémon

## Decisão

1. A restrição “somente a paleta” da **D-278** fica **relaxada** para o overworld: os tiles podem ser refeitos/melhorados para encaixar melhor entre si. O overworld continua **2D** e a estrutura/colisão original é preservada.
2. Ficam autorizados:
   - poeira/partículas no ambiente;
   - tochas cintilando;
   - NPC virando o sprite para o jogador quando ele se aproxima;
   - sprites de Pokémon **em inimigos e aliados**.
3. **Sombra elíptica sob as entidades não foi escolhida**; não implementar sem nova autorização.
4. **Não importar novos modelos por ora**: usar os sprites overworld já existentes no projeto.
5. A direção visual continua a da arena 3D (D-275), sem transformar o overworld em 3D.

## Ambiguidades em aberto

- Quais tiles exatamente serão refeitos e com que paleta? (implementação)
- Formato das opções de tamanho/ícone de ameaça: PNG fora do jogo ou mockup dentro do jogo? (perguntar)

## Estado no código

Não implementado.
