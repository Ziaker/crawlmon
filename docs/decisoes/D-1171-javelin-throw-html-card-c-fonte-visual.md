<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1171 — Javelin Throw: o HTML Card C é a fonte visual oficial

- **Data:** 2026-11-11.
- **Área:** VFX / Processo.
- **Origem:** pergunta direta após a auditoria refeita: "Qual fonte deve valer para o efeito oficial do Javelin Throw?" Resposta do criador: **"HTML Card C (Recomendado)"**.

## O que o criador respondeu (literal)

> "HTML Card C (Recomendado)"

## Decisão

1. **O perfil visual oficial do Javelin Throw é o HTML Card C** (`javelin_throw_3d_vfx_prototype.html`, Card 3 — "Lança do Ponto Fraco"): ~2,245 m assimétrico, ápice em 1,30, haste 1,85, 14 lâminas (7 internas + 7 externas no código), ouro/branco/carmesim, estrela de 2 espinhos + núcleo, montagem/voo/impacto do HTML.
2. **O perfil numérico do prompt** (2,15 m, 7 lâminas 4+3, obsidiana/carmesim, 3 octaedros, recuo 0,68/0,38 etc.) fica preservado em `scripts/vfx/combat/javelin_throw_vfx.gd` **apenas para comparação**. A batalha, o laboratório e o teste usam `scripts/vfx/combat/javelin_throw_vfx_html.gd` (`JavelinThrowVfxHtml`).
3. **O HTML tem uma contradição interna:** o texto do Card C fala em "7 lâminas", mas `buildFusionACVFX` instancia **7 internas + 7 externas = 14**. A implementação segue o **código** (14), como a opção escolhida declarou. Se o criador quiser o texto (7), é um ajuste posterior.
4. **Nada de regra de combate muda:** D-1103 (0,75 s, 2 ATB / 5 MP, 1,2×ATK, crítico por vida) e D-235 continuam. O visual não é dono do relógio (D-019/D-1040); na batalha ele segue `Incoming`, no laboratório o relógio local 0–1,85 s.
5. **A escolha de 14 lâminas, 2,245 m, ouro/branco e cruz de 5,94 m substitui os itens correspondentes da D-1162** (que dizia "números do prompt"). Os demais itens da D-1162 (batalha + laboratório, fases reais, D-235) continuam.

## Ambiguidades em aberto

- O texto do Card C diz 7 lâminas; o código cria 14. A implementação atual segue o código. Se a intenção era 7, o criador deve dizer.

## Estado no código

**Porte literal + A/B implementado; aguardando aprovação visual.** O perfil HTML está em `scripts/vfx/combat/javelin_throw_vfx_html.gd`; a biblioteca de malhas está em `scripts/vfx/combat/html_mesh_lib.gd`; o laboratório de paridade está em `scenes/debug/javelin_html_parity_lab.tscn`; a captura do HTML está em `tests/fx_lab/capture_html_reference.py`. Driver, laboratório de jogo e teste apontam para a classe HTML. A ficha do Move foi atualizada para 14 lâminas/cruz 5,94/8 faíscas. A auditoria e as folhas A/B estão em `docs/vfx/AUDITORIA_JAVELIN_THROW_HTML_C.md` e `test_captures/html_ab_sheets/`.
