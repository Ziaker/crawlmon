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
