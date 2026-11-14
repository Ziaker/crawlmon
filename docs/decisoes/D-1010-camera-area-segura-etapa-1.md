<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1010 — Câmera: enquadramento pela área segura (etapa 1)

- **Data:** 2026-11-08.
- **Origem:** Conversa (aprovação do relatório da auditoria, `scratch/cam_audit/RELATORIO.md`, e respostas às perguntas).
- **Complementa:** D-1008 (zoom liberado se nada sair de quadro), D-015 (todos os inimigos visíveis).

## Frases literais do criador

> Aprovado

Respostas às perguntas:

- Blocos que contam como área coberta: **"Fixos + etiquetas"** (cartão do líder, menu, cartões dos aliados, painéis do topo direito **e** as etiquetas dos inimigos).
- Aproximação: **"Avançar a posição, mas se começar a obstruir visão e informação, o aumente"**; ao esclarecer o que aumenta: **"O FOV"**.
- Modos: **"Só CINEMA"**.
- Quem precisa estar na área segura: **"Inimigos + todos aliados; só provar"**.

## Decisão

1. Na etapa 1 só o modo **CINEMA** usa a área segura (TATICA, IMPACTO e STATUS ficam como hoje).
2. A câmera mira pelo **retângulo livre da HUD**: cartão do líder, menu, cartões dos aliados, painéis do topo direito e etiquetas dos inimigos contam como área coberta.
3. Todos os **inimigos vivos e todos os aliados vivos** têm de ficar dentro da área segura.
4. A câmera pode **avançar a posição** (aproximar) de forma suave; se a aproximação começar a obstruir visão ou informação (algo sai de quadro ou fica atrás da HUD/etiquetas), o **FOV aumenta** (abre) até voltar a caber.
5. As etiquetas e o cartão de ação **não são movidos** nesta etapa: só se prova, em quadros, que nenhuma etiqueta cobre o próprio inimigo e que todos aparecem (D-1008).
6. Sem tremor novo (D-049), sem mudar regra de combate.

## Ambiguidades em aberto

- Limite mínimo de distância da câmera: não foi pedido; a decidir/perguntar na implementação se necessário.
- Margens exatas em px da área segura: a medir da HUD real, sem número do criador.

## Estado

Implementado para revisão (não commitado): `BattleCamera._safe_area_step/_sa_solve/_sa_eval`, `BattleHud.free_rect/tag_pad`, `BattleScene._safe_area_units`. Retângulo livre medido da HUD (≈ x 368–962, y 88–676 em 1280×720); aproxima até caber (limite 12 m e 5 m de qualquer unidade), abre o FOV (até +25°) se nem a pose base cabe; glide 2,5/s. Vídeos: `scratch/cam_s1b/video_normal_espelhada.mp4` e `video_dqt_espelhada.mp4`.

Limites conhecidos: o líder correndo perto da câmera (volta do golpe) passa atrás do menu por instantes (`scratch/cam_s1b/acao/f_044`); o cartão de ação do wind-up não entra na conta; a largura do corpo é estimada (0,45 × altura).
