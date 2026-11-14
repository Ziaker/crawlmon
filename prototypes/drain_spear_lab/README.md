<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Drain Spear · laboratório visual isolado

Fonte documental consultada: `Ziaker/crawlmon` `main` em `ee2b8845457d34d0988792ce421b76e02c420e4b` (06/11/2026). Base local `9b1772e6d4f9ff43cdae333f8b3ec172e09c5e17`. O laboratório não altera o jogo.

## Abrir

Abra `drain_spear.html` no navegador. O arquivo incorpora JavaScript, CSS e as duas dependências, sem CDN. Para desenvolvimento, `npm install` e `npm run serve` neste diretório. Para reconstruir o HTML, `npm run build`.

## Dependências

- `@babylonjs/core` 9.34.0
- `babylon.quarks` 0.30.0
- `esbuild` 0.25.5, apenas para empacotar

Os três tratamentos de contato são **alternativas visuais experimentais**, pois a extensão exata da estocada a 16,3 unidades não foi homologada. Modelos são substitutos geométricos. Tempos de wind-up, execução e recuperação são provisórios. O laboratório demonstra os eventos de roubo, mas não calcula MAG/SPI, ATB/MP nem imunidades gerais do jogo.

## Limite de validação

O build executou; o navegador integrado do ambiente não conseguiu acessar `127.0.0.1:5173` (`ERR_CONNECTION_TIMED_OUT`). Portanto, a aparência, shaders compilados pela GPU e os controles ainda precisam ser verificados em um navegador local acessível.
