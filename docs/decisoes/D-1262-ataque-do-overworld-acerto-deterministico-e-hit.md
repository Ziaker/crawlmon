> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
> **MOVE = 3D, NUNCA 2D (D-1222).** Todo Move, efeito, mão, trajetória e protótipo é visualmente 3D de verdade (curvas em x, y e z, rotação de pulso/lâmina, volume, luz). É PROIBIDO tratá-lo como 2D (plano único, peça rígida deslizando, câmera 3D com movimento 2D) a não ser que o criador mande EXPLICITAMENTE, Move a Move. Referência de movimento: trajetória 3D real dos ossos dos ataques do Abra/Pancham.

# D-1262 — Ataque do jogador no overworld: acerto determinístico, alcance por arma e texto HIT

## Frase literal do criador (2026-11-16, repassada pela sessão que pediu a tarefa)

Queixa: a mecânica do ataque no overworld das dungeons "parece quebrada" mecânica e visualmente; não dá para saber se acertou até encostar; mesmo atacando primeiro e acertando parece aleatório; o sistema parece feito só para o Abra, e personagens grandes (Orc, Cyclops) quebram visual, lógica e tudo.

Decisões do criador (conforme o relato da sessão que repassou o pedido; as palavras exatas dele não foram coladas):

1. Acerto **determinístico**: se o avanço chega à borda do corpo do alvo (raio medido do modelo real, nunca por espécie, D-235), é acerto. Vale para qualquer tamanho; deixa de depender de alcance fixo (`HIT_REACH`, `PLAYER_DASH_MAX`) ou de sorte. O avanço pára na borda do corpo: Orc e Cyclops não atravessam o alvo.
2. Armas que estendem o alcance dão vantagem: o Orc usa uma lança; quem tem arma que estende o alcance no modelo ganha alcance maior no ataque do overworld, igual ao spear thrust do combate.
3. Aviso de acerto: texto "HIT" no instante do impacto, antes da transição para a batalha. Sem hit-stop nem flash, a menos que o criador peça depois.

## Implementação (`overworld_attack_controller.gd`, lab da Murky Forest)

- Raio do corpo = o maior entre a cápsula de colisão e o raio medido no modelo (mediana da distância horizontal dos vértices da malha do corpo, faixa de 15–65% da altura, na pose atual). Antes todos os inimigos do lab tinham cápsula 0,38, então Orc/Cyclops eram tratados como corpos pequenos.
- Alcance medido de borda a borda: `ATTACK_GAP` 3,8 m (= os 4,5 m centro a centro de antes entre dois corpos de 0,35 m) + bônus da arma. Alvo adquirido ⇒ o avanço sempre chega e acerta; não há mais teto de 4,4 m nem folga de 0,55 m no lado do jogador (tolerância de 0,12 m: o impacto dispara no primeiro toque, sem esperar a cauda de frenagem da D-1189).
- O avanço nunca ultrapassa a borda do alvo (velocidade limitada por `restante / delta`).
- Bônus da arma: o mesmo dado do combate. `CharacterData.skill_ids()` → `MoveData.stand_gap` dos Moves corpo a corpo (`kind` Melee) maiores que `BattleSpace.STAND_GAP` (2,6): bônus = `stand_gap − 2,6`. Spear Thrust (7,0) dá +4,4 m (alcance 8,2 m). O Drain Spear (`badge_steal`) não conta. Por `move_id`/loadout, via a meta `species_id` do ator, nunca por nome.
- Texto "HIT": reaproveita o estilo dos textos flutuantes do combate (`FxText.float_text`, como o "CRÍTICO!"): amarelo (1,0 / 0,9 / 0,2), tamanho 48, contorno, sobe e some, sobre o ponto de impacto, no sinal `impact_requested`. O criador **não** definiu fonte, cor, tamanho nem animação: é escolha provisória e pendente.

## Pendente (perguntar ao criador)

1. ~~Visual do "HIT"~~ **RESPONDIDO (2026-11-16)**: o criador aprovou, item a item, o que já estava implementado: amarelo (o do CRÍTICO!), tamanho 48, sobe e some, e aparece em todo impacto (também quando o inimigo acerta o jogador).
2. Lado do inimigo: ele continua com teto de 2,0 m e folga de 0,55 m (não alterado). Ele também deveria ter acerto por borda e bônus de arma (um Orc inimigo com lança)?
3. `ATTACK_GAP` 3,8 m e o alcance de aquisição (HUD ainda mostra 4,5 m centro a centro).
4. O raio medido no modelo é uma aproximação (pose atual do corpo, sem a arma).

## Teste (D-1204, < 12 s)

`Godot_v4.7.2-stable_win64_console.exe --headless --fixed-fps 60 --path . --script res://tests/overworld/attack_reach_scenario.gd -- --strict` (padrão: Abra e Orc atacando Cyclops e Gible, dois lados, 5 folgas). `--species=all --targets=all` cobre os 6 personagens e 4 alvos. Cada linha `ATTACK_JSON` traz distância, raio, alcance usado, adquirido, acerto, quadro, deslocamento e se o "HIT" apareceu.

## Teste no jogo real (D-1204) e correção achada nele

- `python tests/overworld/run_attack_real_matrix.py` (~30 s, lab REAL: IA, câmera, paredes, tecla Z; 16 casos: Abra/Orc × Cyclops/Orc × 2 distâncias × 2 esperas). `attack_real_scenario.gd` roda um caso e pode salvar quadros (`--out=`).
- Achado: com o alcance da lança (8,2 m) o Z do Orc travava no Slime de OUTRA sala, atravessando parede. A aquisição agora exige linha de visão (`_line_clear`, o mesmo raio do teste de acerto).
- `attack_reach_scenario.gd` (céu aberto, lab congelado) só vale para a geometria do alcance; o comportamento real é o da matriz acima.
