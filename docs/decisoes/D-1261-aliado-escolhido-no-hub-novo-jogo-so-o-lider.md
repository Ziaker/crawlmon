> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
> **MOVE = 3D, NUNCA 2D (D-1222).** Todo Move, efeito, mão, trajetória e protótipo é visualmente 3D de verdade (curvas em x, y e z, rotação de pulso/lâmina, volume, luz). É PROIBIDO tratá-lo como 2D (plano único, peça rígida deslizando, câmera 3D com movimento 2D) a não ser que o criador mande EXPLICITAMENTE, Move a Move. Referência de movimento: trajetória 3D real dos ossos dos ataques do Abra/Pancham.

# D-1261 — Novo jogo começa só com o líder; o aliado é escolhido no Hub entre 3 sorteados

## Frase literal do criador

(Registrada a partir do relato da sessão que repassou o pedido; o criador disse que o jogador começar com um aliado "não era para acontecer".)

- Novo jogo começa **só** com o líder (party = [líder]).
- Depois da cutscene de chegada no hub, aparece uma tela com **3 aliados sorteados** entre os outros jogáveis (Abra, Pancham, Gible, Slime, Orc, Cyclops, menos o líder). O jogador escolhe 1; ele passa a acompanhar o líder nos mundos pelo hub (vira o aliado da party e seguidor no hub).
- A tela abre **uma vez só**, na primeira vez no hub de uma campanha nova (não reabre ao reentrar no hub depois de escolhido).

## Nova frase literal do criador (2026-11-16, depois da lógica pronta) — CONFLITA com a tela de 3 sorteados; qual vale está PENDENTE

> "os aliados são escolhidos no hud de expedição onde decidimos que mundo vamos entrar, com 3 badges, duas vazias e uma o lider na esquerda e na direita a lista de personagens recrutados com seu nível estampado no lado superior direito de suas badges, onde clicamos e arrastamos as badges de um ou mais aliados até as badges vazias pra incluir eles na expedição, com eles vindo até o jogador (presentes no mapa da hud)"

Perguntas abertas ao criador: (1) isto substitui a tela de 3 sorteados pós-cutscene? (2) como o jogador "recruta" personagens e quais existem no novo jogo? (3) o aliado some do hub fora da expedição? Nada disto foi implementado.

### Respostas do criador (2026-11-16)

1. Sobre substituir a tela de 3 sorteados: > "hud de expedição e também interagir com eles no mapa, falar com eles aparece uma opção de recrutar eles pra equipe de expedição"
2. Sobre quem são os recrutados: > "recrutados através do employ" (D-1229: Employ em combate; a outra forma de recrutar é a interação voluntária na exploração/hub, que ele descreveu acima).
3. Sobre o aliado fora da expedição: > "ele volta pro ponto de origem"

4. Sobre recrutar falando com o NPC: > "mas é obvio que é direto, só os npcs com ficha e move prontos no caso abras orcs panchams e etc"

**Valendo agora (2026-11-16):** a tela de 3 sorteados foi **substituída** e o código dela removido. Novo jogo = só o líder e elenco vazio. Recrutar = Employ em combate (D-1229) **ou** conversar com NPC do hub (direto, sem chance/minigame; só espécies com ficha pronta no `CharacterCatalog`, nunca o líder, uma vez por espécie). Equipe da expedição = líder + 2 vagas (`MAX_ACTIVE` 3, D-1233), montada no HUD do Gate; ao sair da equipe o aliado volta ao ponto de origem.

**Implementado (lógica):** `GameState.recruit_character`, `recruited_available`, `team_assign`, `team_unassign`; hub: opção Z "RECRUIT" no diálogo do NPC, seguidor nasce no ponto do NPC e o NPC some enquanto está na equipe. Cenário `HUB_ALLY_CHOICE`.

**Pendente (visual do HUD do Gate):** 3 badges (líder à esquerda + 2 vagas), lista à direita com nível no canto superior direito, arrastar badges, aliados andando até o jogador no mapa do HUD. Proposta de layout/cores/animação a aprovar antes de codar.

## Decisão (da primeira rodada; ver conflito acima)

1. `GameState.start_new_campaign(líder)` cria só o líder e sorteia 3 candidatos distintos (nunca o líder) em `ally_choice_candidates`; `ally_choice_pending = true`.
2. `GameState.choose_ally(species)` só aceita um dos 3 oferecidos, enquanto pendente; cria o aliado (`SKILL` + `EVADE`, D-168), adiciona à party e fecha a oferta para sempre (`ally_choice_pending = false`).
3. O Hub (`hub_3d_lab.gd`) espelha `party[1..]` nos seguidores (`_sync_followers_to_party`), visíveis em campanha real; sem campanha (party padrão do debug) os seguidores de demonstração ficam como estavam.
4. Gancho: `_end_arrival()` (fim da cutscene) e, sem cutscene, o fim do `_ready`, chamam `_maybe_open_ally_choice()`. `apply_ally_choice(species)` é a entrada única que a tela vai chamar.
5. Funciona para qualquer personagem, sem nomes fixos (D-235).

## Conflito com decisões antigas (preservadas, não apagadas)

- **D-1207 C1 / D-1208 (linha 33):** diziam que a party nova tinha "1 aliado inicial complementar" (Pancham, ou Abra se o líder fosse Pancham). **Esta decisão vale a partir de agora** (o criador pediu o contrário). As antigas ficam como histórico.

## Pendências (NÃO decididas; a IA recomenda, o criador decide)

1. **Visual da tela de escolha** (layout, cores, animação): não implementada. Proposta a aprovar antes de codar.
2. **Trocar o aliado depois na Guild Hall:** recomendação = fixo por enquanto.
3. **O que acontece se o jogador fechar/pular a tela:** sem tela ainda; hoje a oferta continua pendente.

## Estado

- Lógica (GameState + Hub + gancho) feita e testada: `--scenario=HUB_ALLY_CHOICE` (6 líderes, ~1,2 s).
- Tela visual: pendente de aprovação.
