# VFX Library 3D — laboratório HTML

Catálogo executável de **20 componentes de VFX + 5 demonstrações**, feito para analisar
forma, fluxo e tempo com câmera 3D livre. **Não é o jogo e não altera o jogo.**

## Abrir

O projeto usa ES modules + import map; precisa de um servidor local (não abra o `index.html` direto).

```powershell
# na raiz do repositório
python prototypes/vfx_library/serve_nocache.py .
# abra http://127.0.0.1:8126/prototypes/vfx_library/index.html
```

`serve_nocache.py` envia `Cache-Control: no-store` para o navegador não servir módulos velhos.
Também funciona com `python -m http.server` a partir da raiz, mas o cache pode esconder edições.

## Controles

| Onde | O que faz |
|---|---|
| Catálogo (esquerda) | busca por nome/técnica, filtro por família, 20 componentes + 5 demos + extra |
| Inspector (direita) | o que é, construção, dependências, limites, parâmetros ao vivo e camadas isoláveis |
| Barra superior | câmera (3/4, lado, frente, topo, impacto), **espelhar palco**, distância 2,5–8 m, bloom, grid, dummy, wireframe, “só efeito”, fundo claro |
| Rodapé | play/pause, reiniciar, scrub, loop, velocidade (0,25×–2×) |
| Teclado | espaço = play/pause, ←/→ = passo de 0,05 s, R = resetar câmera |

**Espelhar** inverte atacante/alvo e reconstrói o efeito a partir do eixo — é o teste de D-235.
**Camadas** lista as peças do efeito (nas demos, cada componente vira uma camada).

## Estrutura

```
prototypes/vfx_library/
  index.html, style.css, main.js     # UI, cena, câmera, tempo, inspector, hook de captura
  src/helpers.js                     # geometria, RNG, palco, materiais, partículas
  src/effects/forms.js               # LIB 01–05
  src/effects/motion.js              # LIB 06–12
  src/effects/impacts.js             # LIB 13–20
  src/effects/composites.js          # demos + extra (instanciam os componentes)
  src/effects/index.js               # catálogo: metadados, parâmetros, estados
  serve_nocache.py, capture_server.py
  make_sheet.py, build_evidence.py   # contatos e evidências
  CATALOGO.md, RELATORIO.md
  evidence/                          # 1 tira de 3 instantes por item
  captures/                          # PNGs brutos do canvas
```

## Determinismo

- Todo `Math.random` dos efeitos passou a usar um RNG semeado (`resetRandom(1337)`).
- O scrub **reconstrói o efeito do zero** e simula até o instante pedido: rastros, poeira e
  partículas têm histórico, em vez de aparecerem vazios.
- Reconstruções usam `ctx.fast` para pular trabalho visual pesado (ex.: fita do rastro) e
  fazem uma última atualização com o estado final.

## Evidências

- `evidence/` — uma imagem por item com **3 instantes (15% / 50% / 85%)** e identificação.
- `captures/mirror-blastcone.png`, `mirror-animeDash.png` — palco espelhado.
- `captures/dist7-thrust.png` — palco a 7 m.
- `captures/final-1..4.png` — contatos com os 26 itens.

## Estado

Todos os itens estão **Protótipo funcional**. Aprovação visual **pendente**.
Não houve validação no Godot nem medição em GPU real; ver `CATALOGO.md` e `RELATORIO.md`.
