<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1157 — Aliado coleta item: “!” acima da cabeça e notificação azul acima dele

- **Data:** 2026-11-11.
- **Área:** Overworld 3D / aliados / coleta de item / notificação / IA.
- **Relacionadas:** D-1156 (notificação Paper Tag), D-1151 (itens), D-1072/D-1074 (HUD aprovado), D-1037 (HUD antigo), D-235 (nada depende de personagem/time/lado), D-1154 (telemetria; isto é overworld, fora do `BattleTrace`).
- **Status:** **implementado/provado no lab; aguardando aprovação**; código na árvore de trabalho; **sem push**.

## O que o criador disse (literal)

> ok, deixe que sopreponha a hud do jogador do GIF 1, mas também ocorra com aliados, aparecendo encima deles quando eles coletam um item, inclusive com a cor de fundo azul escura pra eles também.

> faça o teste com um aliado indo pegar um ítem ele mesmo com uma notificaçãozinha enquanto ele estiver caminhando com você de "!" ao lado do modelo deles acima da cabeça e indo correndo em direção a um item, obviamente com raycasting e um alcance mínimo, sigo suas recomendações quanto a isso

## Decisão

1. **Card do jogador:** fica no **canto superior esquerdo** `(20, 96)` e **sobrepõe o HUD** aprovado (escolha do GIF 1). Nada muda no card do jogador.
2. **Card do aliado:** mesma etiqueta Paper Tag, mas **fundo azul-escuro** (`#17283b`), texto creme (`#eceada`) e acento lilás (`#b5a5fe`); aparece **acima da cabeça do aliado**, segue o modelo e é gerado no impacto do orbe. Tamanho visual **234×67** (o card 300×86 em escala 0,78) para ser uma “notificaçãozinha”.
3. **Coleta pelo aliado:** qualquer nó do grupo `item_collector` (jogador e aliados) pode recolher; o pickup emite `collected(item_id, collector)`, registra o coletor e usa o mesmo inventário. O card do jogador ou o card azul do aliado é escolhido pelo coletor.
4. **“!” de percepção:** ao ver um item, o aliado mostra o ícone `state_alert` amarelo acima da cabeça (ao lado do modelo), enquanto ainda caminha; ele some quando o item é coletado/abandonado.
5. **IA do aliado (recomendações, porque o criador delegou):** estado `FOLLOW → ALERT (0,4 s) → RUN → COLLECT → FOLLOW`; **detecção 6 m**; **leash 8 m** do jogador; **raycast** do peito até o item, só paredes (layer 1, sem atores); ignora item a menos de `1,25 + 0,2 m` (já seria coletado) e item dentro do raio de coleta do jogador; **corrida 5,2 m/s**; coleta a **1,25 m**; depois volta a seguir o jogador. Um aliado por teste (Pancham).
6. **Teste:** Pancham caminhando/entrando na formação com o jogador, vê uma super poção no corredor, mostra “!”, corre, coleta e recebe o card azul acima da cabeça; o jogador e o HUD aprovado ficam visíveis.
7. **O que não muda:** coleta do jogador, posição do card do jogador, HUD aprovado (D-1072/D-1074), salas/itens da D-1151, combate, câmera e regras.

## Ambiguidades

- **“Alcance mínimo”:** interpretado como um alcance de percepção **curto** (6 m) somado ao raio de coleta; não é uma distância mínima para ignorar itens próximos.
- **“Aparecendo encima deles”:** card de tela ancorado acima da cabeça, seguindo o aliado, não um card fixo no HUD.
- **“Notificaçãozinha”:** 234×67 (0,78 do card do jogador).
- **“Sigo suas recomendações”:** os números acima são recomendação do assistente, não uma regra nova do criador; ele pode trocar.

## Provas

- `docs/referencias/exploracao/3d/d1157_ally_notification.gif` — 50 quadros (2,5 s, 20 fps): Pancham caminhando, “!”, corrida, coleta, orbe e card azul.
- `d1157_ally_notification_sheet.png` — 24 quadros de contato.
- `d1157_ally_notification.png` — still final com o card azul acima do Pancham e o HUD aprovado.
- Log: `ALERT item=super_potion dist=3.49`, `RUN ... dist=2.88`, `collected=super_potion by=PanchamFollower card=ally`, `COLLECTED`, `FOLLOW`, `super_potion=1`, `card_visible=true card_alpha=1.0`; cena `exit=0`.
- Teste: item em `(0; 0,8; -10)`, Pancham em `(2,5; 0; -7,5)`, jogador em `(3,5; 0; -10)`, câmera fixa `(7; 3,2; -7,2)`.

## O que foi verificado

- O Pancham **caminha/entra na formação**, percebe o item a **3,49 m** (dentro de 6 m) e mostra o “!” acima da cabeça.
- O raycast/LOS passou (o ALERT só ocorre depois de `_has_los`); o jogador está a 3,5 m do item e não o coleta.
- O Pancham **corre**, coleta (`super_potion=1`, coletor `PanchamFollower`) e recebe o **card azul** acima da cabeça; o card do jogador continua em `(20, 96)` sobre o HUD.
- O HUD aprovado (D-1072/D-1074) fica visível durante o teste; o “!” some na coleta.

## O que não foi verificado

- Oclusão por parede: o raycast existe, mas o teste tem LOS limpo; falta um teste com parede no meio.
- Todos os aliados ao mesmo tempo; o teste usa só o Pancham (o Orc fica oculto).
- O retorno do aliado depois do card e o card seguindo um aliado em movimento longo (o teste termina por volta de 2,5 s).
- O HUD real lendo `GameState.party`; o lab usa os quatro cards demo.
- Outras resoluções/aspectos (a projeção do card/orbe foi validada em 1280×720).
- O tamanho/arte do “!”: usei o ícone 3D `state_alert` existente; ele é blocado de propósito.
- A IA de produção; o `ally_item_runner.gd` é um controlador de teste do lab.

## Estado

Teste implementado/provado no lab; **sem push**. O card do jogador continua sobre o HUD (escolha do GIF 1); o card azul do aliado e o “!” são novos. Aguardando aprovação visual e dos parâmetros recomendados.
