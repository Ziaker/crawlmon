# D-326 — Ordem dos assets, tilesets e 24 px por ora

> **Atualização (D-329):** o 24 px foi cancelado; o jogo voltou a 48 px. A ordem dos assets e o uso dos tilesets continuam; tiles do PMD de ~24 px precisarão de escala 2× ou tratamento próprio quando forem importados.

- **Data:** 2026-11-05
- **Área:** Visual / assets / exploração
- **Origem:** Conversa (respostas às três perguntas do plano de assets)

## O que o criador disse (literal)

> 1 - Usaremos a primeira antes

> 2 - usaremos os tilesets

> 3 - vamos pra 24px por ora

## Decisão

1. **Ordem:** usar primeiro os assets de **Explorers of Time/Darkness**; os de **Explorers of Sky** vêm depois.
2. **Dungeons:** usar os **tilesets modulares** (Sky "Dungeon Tiles") como skin da geração procedural; **não** substituir os andares procedurais por mapas completos.
3. **Escala:** adotar **24 px por tile por ora**, em vez dos 48 px atuais, para casar com os tiles do PMD.

## Conversão 24 px (proposta técnica, preserva o comportamento em tiles)

| Item | Hoje (48 px) | 24 px |
|---|---:|---:|
| TILE | 48 | 24 |
| Velocidade do jogador | 180 px/s | 90 px/s |
| Zoom da câmera | 1.5 | 3.0 |
| Colisão do jogador | raio 14 | raio 7 |
| Colisão de NPC | 28×28 | 14×14 |
| Interação de NPC | 36 px | 18 px |
| Velocidade de inimigo | 42/105 px/s | 21/52,5 px/s |
| Contato de inimigo | 26 px | 13 px |
| Raio da névoa | 7,5 tiles | 7,5 tiles (não muda) |
| Tiles do andar | 40×26 | 40×26 (não muda) |
| Escala dos sprites | 1.2 | 1.2 (testar) |

## Ambiguidades em aberto

- O 24 px vale só para a cena nova do hub ou para o jogo inteiro? A proposta é começar pelo hub/teste e migrar a dungeon depois.
- A escala dos sprites (1.2) e o tamanho visual dos personagens precisam de teste.
- Quais assets exatos da primeira leva (hub/itens/UI) entram antes.
- Quais tilesets do Sky entram primeiro (floresta, fortaleza, caverna).
- A cena de teste do hub é autorizada? (sim/não)

## Estado no código

Nada importado; nenhum código alterado. D-326 complementa D-325.
