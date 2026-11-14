<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1104 — Coruja: caminhada pesada e ameaçadora com referência no Eggo

- Data: 2026-11-10
- Estado: autoria autorizada no Blender; validação visual pendente.

## Frases literais

> vamos fazer caminhada

> aqui obviamente, use o motion lens, leia todos documentos e referencias sobre na pasta do arenamon no disco E

> pesado e ameacador, use como referencia o walk do eggo, cace pelo arquivo

## Decisão

Criar a caminhada da coruja no Blender, com caráter pesado e ameaçador, usando o walk do Eggo como referência e o Motion Lens para análise. Preservar o idle existente e criar uma nova Action e um novo arquivo de trabalho. Não há autorização de integração ou mudança de regras do jogo.

## Referência localizada

`E:/Arenamon/chars/Eggo/eggo walk autoik v2 6 passos.blend`, Action `Walk Forward 7 AutoIK 6 Passos`.

## Ambiguidades

Detalhes da primeira versão serão avaliados visualmente pelo criador; a referência não autoriza modificar o rig ou a malha.
