# D-1265 — Abertura do jogo v2

- **Data:** 2026-11-16
- **Área:** pré-jogo, tela de título e menu, UI/3D
- **Estado:** **aprovada e ligada como padrão** (criador: "Aprovo, ligar" / "Substituir já"); a antiga fica em `--title=v1`
- **Relacionadas:** D-1237 (círculo/pilar do hub), D-1226 (menu), D-235 (derivado do líder real), D-1204 (captura <10 s)

## Frase literal do criador

> "Essa abertura do jogo tá mt básica e feia, use generative UI pra criar uma diferente pra mim aprovar"
> "Aprovo, ligar" · "Substituir já"

## O que existe

- Mundo 3D: `scripts/ui/pre_game/pre_game_title_world.gd` (SubViewportContainer atrás da `PreGameViewBoot`): líder real em idle sobre o círculo do hub (`HubSummonFx`), luz/sombra reais, espiras, lajes de luz, partículas, câmera com deriva lenta. Líder = personagem escolhido (`_char_index`); tamanhos derivados da altura medida (D-235).
- Camada 2D: `pre_game_title_v2_draw.gd` (título como arte, placas inclinadas, aviso de Enter), usada por `PreGameViewBoot` em título e menu. Gaveta PLAY, cartão de contexto, rodapé e modal de sair continuam, com a gaveta reposicionada ao lado das placas.
- Tela de carregamento, escolha de personagem, Settings e Credits não mudaram.
- `--title=v1` restaura a abertura antiga. `--shot=` pula a animação de entrada.
- Debug: `scenes/debug/title_v2.tscn -- --shot=arq.png --at=3.0 [--leader=N] [--mirror]`. Capturas em `tests/title_v2/`.

## Pendente (recomendações da IA, o criador decide)

- Tipografia, cores novas, animações e textos das placas são recomendação, aprovados em bloco só pela frase acima.
- Modal de sair e tela de loading não foram redesenhados.

## Ajustes pedidos depois da aprovação (criador, 2026-11-16/17)

- Logo CRAWLMON junta, 20% menor, texto flat: CRAWL branco, MON vermelho; sem laje coral, sem barras, sem placa kicker.
- "deixe o fundo no mínimo 45% mais escuro": só o FUNDO (céu, neblina, chão, torres, lajes de luz) em 50%; líder e efeitos intactos. (Difere do ~35–40% da D-1238 para o hub; o pedido é do título.)
- Menu mais alto e espaçado (passo de 76 px); gaveta PLAY ao lado das placas.
- Cartão de save (só com save), canto superior direito: papel amarelo claro com grão, ícone do líder estampado, e: nível do líder, respeito, cascos (saldo único, D-1253), duração de gameplay. Cascos (`shell_balance`) e duração (`play_seconds`) ainda não existem no GameState: aparecem 0 / 00:00 até serem criados. Debug: `--fake-save=<espécie>`.
- "coloca o altar então": altar de pedra cinza da D-1266 (`HubAltar`) sob o líder, na escala do círculo (estrela do altar = estrela do círculo); o líder e o círculo ficam sobre o topo.
- No título o círculo do hub (D-1237) foi adaptado: anéis acima do corpo, anel do chão e cometa ocultos, luz e pilar mais fracos. Só no título; o hub não muda.

## Pendente / não verificado

- 1080p, outros líderes, modal de sair e loading com a v2; leitura das decisões dos lotes D-100..105, D-1050..1108 e D-313..410 (a leitura automática falhou neles).
