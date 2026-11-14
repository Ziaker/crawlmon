<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Documentação do Crawlmon

Esta pasta reúne a documentação de arquitetura, dados e recursos do projeto Crawlmon.

## Documentos Disponíveis

- [**Biblioteca de Personagens (`personagens.md`)**](personagens.md): Documentação detalhada sobre as 11.185 imagens organizadas na pasta `res://personagens/` (ícones, retratos de Conquest, sprites de caminhada 2D overworld, fontes como SpriteCollab e exemplos de código GDScript).
- [**Manifesto da Pokédex (`pokedex_manifest.json`)**](pokedex_manifest.json): Catálogo estruturado em JSON com todos os 722 Pokémon, nomes oficiais, IDs numéricos e disponibilidade de sprites por categoria.
