<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Relatório — Biblioteca VFX 3D (HTML)

Data: 2026-11-06 · Branch: `wip/checkpoint-2026-11-06` · **Nada commitado, nada enviado.**

## 1. O que foi pedido

Protótipo HTML isolado, com as melhores técnicas de JS, para reproduzir os efeitos do
glossário e analisá-los com câmera 3D de qualquer ângulo; depois, o prompt detalhado
"Biblioteca de referências e recursos VFX 3D" (20 componentes, 5 demos, inspector,
qualidade, compatibilidade, evidências). **Sem alterar o jogo nem o Motion Composer.**

## 2. O que foi entregue

- `prototypes/vfx_library/` — laboratório navegável, 26 cartões:
  **20 componentes** (`LIB-VFX-01`…`20`) + **5 demos** (`DEMO-01`…`05`) + **1 extra** (prelude do projeto).
- Inspector com **descrição, construção, dependências, limites, parâmetros ao vivo e camadas isoláveis**.
- Palco **espelhável** e com distância ajustável (2,5–8 m) — teste de D-235 dentro do protótipo.
- Scrub determinístico (reconstrói do zero, RNG semeado) — rastros/poeira/partículas têm histórico.
- Câmera orbital + 5 presets; bloom/ACES; grid, dummy, wireframe, “só efeito”, fundo claro.
- Evidências: `evidence/` (26 tiras com 3 instantes e identificação), contatos em `captures/final-1..4.png`,
  espelhado e distância 7 m.
- Documentação: `README.md`, `CATALOGO.md` (metadados + desempenho + avaliação Godot) e este relatório.
- Decisão `docs/decisoes/D-955-biblioteca-vfx-html-isolada.md` + índice atualizado.

## 3. Inventário e reaproveitamento

| Recurso | Situação |
|---|---|
| `assets/vfx/flipbook_impact.png` | **reaproveitado** — atlas 4×4 (16 quadros), RGBA com alpha; usado em `LIB-VFX-17` |
| `shaders/flipbook.gdshader` | referência de leitura do atlas (mesma divisão 4×4) |
| `shaders/ring.gdshader`, `streak.gdshader`, `mesh_slash.gdshader` | referência de técnica; não carregados |
| `assets/vfx/shock_cone.glb`, `ribbon_trail.glb`, `slash_arc.glb` | avaliados como **referência de forma**; a versão HTML é procedural (o GLB não foi importado) |
| `assets/vfx/slash_trail_tex.png` | não usado |
| `scripts/combat/fx/*`, `scripts/vfx/*` | **não tocados** |
| `tests/fx_lab/*` | **não tocados** |

Classificação: o atlas é **reutilizável**; os GLBs são **parcialmente reutilizáveis** (forma),
mas não foram integrados nesta rodada; os shaders são **referência**, não dependência.

**D-307**: citada dentro de D-308, mas **não existe** em `docs/decisoes/`. Não inventei o
conteúdo; registrei a ausência em D-955.

## 4. O que foi testado (e como)

- **Carga da página**: 0 erros de console no Chrome/WebKit do app (servidor `serve_nocache.py`, porta 8126).
- **Os 26 cartões**: todos criados, `setTime` em 15%/50%/85% da duração, **78 capturas** sem exceção.
- **Varredura funcional**: 26/26 OK; parâmetros do inspector alteram o efeito; camadas isolam;
  palco espelhado e distância 7 m sem exceção.
- **Espelhado (D-235)**: `mirror-blastcone.png` e `mirror-animeDash.png` — o cone sai do alvo para
  longe do atacante e a poeira/linhas acompanham o eixo invertido.
- **Distância**: `dist7-thrust.png` — o cone continua no eixo, sem coordenada fixa.
- **Flipbook**: textura carregada e quadros avançando (atlas real do projeto).
- **Determinismo**: o mesmo instante reconstruído produz a mesma composição (RNG semeado).

## 5. Defeitos encontrados e corrigidos durante a verificação

1. **Shader não compilava** no vortex (`uTime * 4` — int literal em GLSL). Corrigido para `4.0`.
2. **Dummy andava para trás**: `placeDummy` invertia o sinal do eixo; poeira, rastro e linhas
   apareciam no lado oposto ao alvo. Corrigido; agora tudo deriva de `stage.dir`.
3. **Demos quebradas**: sub-componentes recebiam `ctx.p` vazio. Cada componente ganhou defaults
   próprios (`FORM_DEFAULTS`, `MOTION_DEFAULTS`, `IMPACT_DEFAULTS`); as demos instanciam com eles.
4. **Cones liam como mola**: bandas transversais. Trocado por listras longitudinais + fresnel.
5. **Shockwave parecia domo de vidro**: casca esférica removida; ficaram os anéis com atraso.
6. **Coroa estourava em branco**: material aditivo trocado por sólido; pontas mais largas/altas.
7. **Speed lines cobriam a cena**: foram trazidas para um tubo em volta do emissor.
8. **Rastro invisível**: a fita estava de perfil e com o gradiente invertido; `up` vertical e
   largura maior.
9. **Flipbook durava 2 s com o atlas vazio**: duração reduzida para 1,4 s.
10. **Câmera longe demais**: presets aproximados; anéis de impacto afinados.

## 6. O que NÃO foi verificado

- **Aprovação artística** — nenhum item está aprovado; todos são “protótipo funcional”.
- **Godot 4.7 / GL Compatibility** — a coluna do catálogo é avaliação técnica, não teste executado.
- **GPU real** — os números de draw calls/triângulos saíram do WebGL do app, com pós-processamento;
  não há orçamento aprovado.
- **Cenas de 1/4/8 instâncias** — não executadas.
- **Comparação lado a lado** (item 6.10 do prompt) — não implementada.
- **Modo “só material em geometria neutra”** (item 6.2) — não implementado; existem wireframe,
  “só efeito” e isolamento por camada.
- **Presets salvos** (seção 12) — só “Restaurar” os defaults; não há persistência.
- **Reuso dos GLBs** — `shock_cone`, `ribbon_trail` e `slash_arc` serviram de referência, mas não
  foram carregados. O `slash` é procedural.
- **Licenças** — nenhum asset externo foi adicionado; o único recurso do projeto é o flipbook interno.

## 7. Arquivos

Criados/alterados **somente** em:
`prototypes/vfx_library/` (novo) e `docs/decisoes/D-955-*.md`, `docs/decisoes/README.md`.

Nenhum arquivo do jogo, do Motion Composer, de `assets/` ou de `shaders/` foi modificado.

## 8. Como abrir

```powershell
python prototypes/vfx_library/serve_nocache.py .
# http://127.0.0.1:8126/prototypes/vfx_library/index.html
```

O servidor de captura (`capture_server.py`, porta 8124) é opcional, só para gerar as imagens.

## 9. Próximo passo sugerido

Escolher **um** item para aprovação/polimento (recomendo `LIB-VFX-03 Spiral Ribbon` ou
`LIB-VFX-14 Impact Crown`, que ainda não convenceram) e iterar só nele, com o checklist do
protocolo de VFX. Sem tocar no jogo até a biblioteca estar aprovada.
