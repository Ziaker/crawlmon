<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1226 — Move Sketch: gadgets flutuantes, formas avançadas, câmera lenta e histórico

- **Data:** 2026-11-15
- **Relacionadas:** D-1221 (Move Sketch), D-308 (fases), D-418 (sem piscadas), D-1218 (dados antes de imagens).

## Frase literal do criador

> "ainda precisa de muitas melhorias, uma visão em câmera lenta, formas abertas, coroas,  separação de formas em multiplas partes, deslocamento horizontal ou vertical delas, formas que seguem o movimento da linha, um sistema mais bem feito de desfazer, um reprodutor de velocidade reduzida e mais algumas outras, use o deepseek pra te auxiliar a criar mais melhorias pro aplicativo que usaremos apartir de agora. Eu quero que também certas coisas como as definições de formas e outros sejam gadgets flutuantes ao invés de tomarem espaço da tela, me surpreenda"

## Decisão

O Move Sketch é o aplicativo que será usado a partir de agora. Entram:

1. Visão e reprodutor em **câmera lenta** / velocidade reduzida.
2. **Formas abertas** e **coroas**.
3. **Separação de uma forma em várias partes**, com **deslocamento horizontal ou vertical** das partes.
4. **Formas que seguem o movimento da linha** (traço).
5. **Sistema de desfazer** mais completo.
6. "Mais algumas outras" (escolha da IA, ver abaixo).
7. Definições de formas e outros painéis viram **gadgets flutuantes**, em vez de ocupar a tela.
8. O DeepSeek ajuda a criar as melhorias: lógica não visual por `ds-run.mjs` em módulos separados (`prototypes/move_sketch/modules/`); a camada visual e a integração são do Claude.

## Escolhas da IA (sem "sim" do criador; ajustáveis)

- "Mais algumas outras" interpretadas como: rastro/onion-skin, espelhar o lado (D-235), gráfico de velocidade por trilha, câmera extra (picture-in-picture), atalhos.
- Velocidades de referência, nomes dos gadgets, layout padrão e as formas abertas/coroas específicas são propostas da IA.

## Divisão do trabalho (2026-11-15)

- **DeepSeek (via `ds-run.mjs`, módulos novos em `prototypes/move_sketch/modules/`, cada um com teste em node):** `history.js` (desfazer/refazer com coalescência), `playback.js` (relógio com velocidade reduzida, laço, trecho A–B, quadro a quadro), `parts.js` (fatias radiais e paralelas, afastamento e deslocamento H/V das partes), `shapes_extra.js` (formas abertas, coroas e linhas), `pathfollow.js` (trajetória e orientação ao seguir a linha).
- **Claude:** os gadgets flutuantes (janelas arrastáveis, magnéticas, recolhíveis, lembradas), o visual, a integração dos módulos, rastro, câmera que segue a ação, câmera 2, gráfico de velocidade e espelhar o lado.
- Houve uma colisão ao rodar 5 chamadas do DeepSeek em paralelo (`config.json` do Command Code, EPERM): duas foram relançadas em fila.

## Estado

Registrada. Implementada no protótipo `prototypes/move_sketch/move_sketch.html`; nada no Godot. Os testes dos módulos passam em node; o conjunto foi verificado no navegador por dados, sem uso prolongado com mouse real.
