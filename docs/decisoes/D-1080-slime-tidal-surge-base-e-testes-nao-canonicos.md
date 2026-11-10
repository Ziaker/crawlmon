# D-1080 — Slime: Tidal Surge no leque base; diferenças da party de teste não são canônicas

- **Data:** 2026-11-09
- **Área:** Personagens / Moves / Dados / Testes
- **Origem:** resposta do criador à ambiguidade registrada na proposta de arquitetura.

## Frases literais do criador

> "quanto ao slime, não, é pra tidal surge estar no leque base de moves dele seja inimigo ou aliado"

Sobre as diferenças de HP/ataque/velocidade entre `enemy_factory` e `dqt_test_party`:

> "era apenas pra testes"

## Decisão

1. **Tidal Surge pertence ao leque base do DQT Slime.** O Move aparece tanto no Slime inimigo quanto no Slime aliado, com a mesma ficha (2 ATB, 5 MP, 0,8 s, 100%/75%/50%).
2. **As diferenças de HP, ataque, velocidade e MP entre `enemy_factory` e `dqt_test_party` são apenas de teste.** Elas não são a ficha canônica do personagem.
3. **A ficha canônica do personagem** usa os valores do jogo normal. A `DqtTestParty` pode manter overrides locais (por exemplo, `max_hp`, `attack`, `speed`, `max_mp`) para preservar os cenários de teste, mas esses valores não podem virar a definição do personagem.
4. **A centralização em `CharacterData`** deve ler os valores canônicos do jogo normal e deixar os overrides de teste explícitos no helper de teste, nunca escondidos na fábrica de inimigos.
5. **Nenhuma regra de combate muda** além do item 1 (Tidal Surge no Slime inimigo, pedido expresso do criador).

## Ambiguidades em aberto

Nenhuma.

## Estado no código

**Implementado na Etapa 1 da D-1079:**
- `content/characters/dqt_slime/loadout.tres` inclui `tidal_surge`; o Slime inimigo e o Slime da `DqtTestParty` recebem o Move.
- A `DqtTestParty` usa `"test_bare": true` e overrides explícitos de HP/ataque/velocidade/MP; a ficha canônica continua com os valores do jogo normal.
- `tests/combat/test_content_catalog.gd` valida o Tidal Surge nos dois lados e os overrides de teste.

Nenhum push.
