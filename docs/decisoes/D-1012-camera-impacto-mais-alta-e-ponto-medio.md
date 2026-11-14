<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1012 — Câmera de ação (IMPACTO) mais alta, mirando o meio, com área segura (teste)

- **Data:** 2026-11-08.
- **Origem:** Conversa.

## Frases literais do criador

> o que me propõe pra melhorar a visão do personagem quando está indo até o oponente? não acha que mover a camera mais pra cima  (assim como acontece quando clica no fight ou escolhe um item)?
> vamos testar com suas recomendações

## Recomendações aprovadas para teste

1. No IMPACTO (golpe do líder, ou golpe no líder), a câmera sobe só durante a corrida e o golpe, para uma altura intermediária (y = 4,5, entre os 2,875 do CINEMA e os 6 da TATICA), e depois volta ao CINEMA.
2. Mira o ponto médio entre atacante e alvo (não só o alvo).
3. A área segura (D-1010) vale também no IMPACTO, com atacante e alvo obrigatórios no quadro; a aproximação nesse modo é limitada a 4 m.

## Ambiguidades (perguntas feitas, não respondidas; usada a leitura mínima)

- Altura fixa (4,5), sem crescer com a distância.
- Gatilho continua o de hoje: só quando o líder é atacante ou alvo; moves à distância e golpes sem o líder não mudam.
- É um **teste**: o criador ainda decide se fica.

## Estado

Implementado para teste (`battle_camera.gd`, `fx_telegraph.gd`, `battle_scene.gd`).
