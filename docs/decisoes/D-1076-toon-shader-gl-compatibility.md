<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1076 — Tentativa de shader toon no `gl_compatibility` (revertida)

- **Data:** 2026-11-09.
- **Área:** Exploração / visual 3D / shaders.
- **Relacionadas:** D-1028 (toon no overworld), D-1023 (lab), D-1063 (NPCs), D-1075 (status).
- **Status:** **REVERTIDA em 2026-11-09**; o shader customizado foi removido e o lab voltou ao estado anterior (`DIFFUSE_TOON` nativo); renderer global mantido em `gl_compatibility`; batalha, 2D, status/menus e regras não mudam; **sem push**.

## O que o criador disse (literal)

> inclusive cade o filtro toon que tinha:

> está completamente quebrado, pq não volta a ser como tava antes, quando o toon não estava desligado?

## Diagnóstico

O `project.godot` está em **`renderer/rendering_method="gl_compatibility"`**. Nesse renderer, `BaseMaterial3D.DIFFUSE_TOON`/`SPECULAR_TOON` (o filtro usado por D-1028) **não é aplicado**; por isso os modelos/cenário ficam com sombreamento liso. O código do lab continua chamando `_apply_toon`, mas o efeito nativo é ignorado. O estado anterior que o criador tinha era esse visual liso — o filtro existia no código, mas não aparecia no Compatibility.

## Tentativa (histórico)

Foi criado `shaders/toon_overworld.gdshader` (3 bandas + rim, texturas/emissão preservadas) e o `murky_forest_3d_lab.gd` passou a converter os materiais para `ShaderMaterial`. A tentativa deixou o visual **quebrado/neon** e perdeu a leitura anterior; o criador pediu para voltar ao estado anterior.

## Reversão (2026-11-09)

1. **Shader removido:** `shaders/toon_overworld.gdshader` foi apagado.
2. **Lab restaurado:** `murky_forest_3d_lab.gd` voltou ao estado de `7ab8aad9`, com `_toon_mat` e `_apply_toon` em `StandardMaterial3D`/`DIFFUSE_TOON`; nenhuma conversão para `ShaderMaterial`.
3. **Visual anterior de volta:** como o renderer é `gl_compatibility`, o toon nativo continua não aparecendo — o resultado é o **liso anterior**, que era o estado aprovado antes da tentativa.
4. **Renderer global não mudou.**
5. **D-1075 continua:** os cards escondidos/5 s/Tab seguem implementados; as provas e vídeos foram regravados com o visual anterior.
6. **Se o criador quiser toon visível de verdade:** é uma decisão nova — trocar o renderer para Forward+ ou tentar outro shader; nenhuma das duas foi aplicada.

## O que não foi verificado

- O toon nativo no `gl_compatibility` (ele não é aplicado; não há como “ligar” sem trocar renderer/sombreamento).
- O shader customizado foi removido; performance/qualidade dele não são mais relevantes.
- A cena principal em headless/janela continua bloqueada pelos erros de VFX de outra sessão; provas/vídeos são do lab isolado.

## Estado

Tentativa revertida. O lab voltou ao visual anterior; a D-1075 (status) permanece. `murky_forest_hud_sugimori.png`, `murky_forest_status_hidden.png`, os vídeos party/solo e a folha de contato foram regravados com o visual anterior. Documentação registrada; commit local; **sem push**. Batalha/2D intactos.
