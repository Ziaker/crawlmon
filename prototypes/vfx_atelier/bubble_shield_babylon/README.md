<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Bubble Shield — Babylon Lab (D)

Laboratório isolado de look-dev em **Babylon.js 9** para o wind-up e a formação
da bolha da opção **D — Aegis aquática**. Não altera o protótipo three.js nem o jogo Godot.

## Abrir

`bubble_shield_babylon.html` é autossuficiente (Babylon, GLB do Slime e texturas
embutidos). Também pode ser servido por HTTP:

```powershell
python -m http.server 8768
# http://127.0.0.1:8768/bubble_shield_babylon.html
```

## O que está implementado

- Cena de arena, slimes reais (GLB), luzes, bloom, aberração cromática e grão.
- Coroa baixa de pétalas/lâminas de água com montagem escalonada, rotação,
  crista de espuma e gotas.
- Vórtice volumétrico (raymarch) atrás do grupo, em intensidade baixa.
- Formação da bolha: cada orbe infla a partir de uma semente, com overshoot,
  shader de refração da cena + iridescência, e assinatura de núcleo.
- HUD com replay, pause, slow motion (0.25×), fase e tempo.

## Timeline

| Tempo | Fase |
|---|---|
| 0,0–1,0 s | wind-up: coroa sobe e gira; vórtice/partículas crescem |
| 1,0–2,25 s | formação: a coroa afunda; as bolhas inflam com overshoot |
| 2,25–5,0 s | ativo: bolhas estáveis, shimmer |

## Limite conhecido

O wind-up ainda é **procedural** (geometria + shader). A formação da bolha já está
no caminho; a coroa ainda lê como água estilizada/vidro, não no nível das
referências Genshin/HSR. O próximo salto exige **flipbook/flow map assado**
(EmberGen/Houdini/Blender) ou um pack de texturas de água/espuma; só shader
procedural não fecha a diferença.

## Arquivos

- `main.js` — cena, shaders, timeline.
- `shell.html`, `style.css` — HUD.
- `build.mjs` — bundle + GLB + texturas base64.
- `assets/caustics.png`, `assets/foam.png` — texturas geradas offline.
- `contact_sheet.py` (no three) — folha comparativa fora deste lab.
