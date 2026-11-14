<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-411 — Wind: Acabamento Sólido, Denso e Monolítico (Estilo Water e Fire)

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** diagnóstico definitivo do criador sobre a causa-raiz da rejeição dos glifos de Wind.
- **Estado:** regra registrada; documentação atualizada; produção visual orientada exclusivamente por este princípio de peso e densidade.

## Declaração literal do criador

> "O problema é o peso/traço: precisa do mesmo acabamento sólido e denso de Water (gota) e Fire (chama), não linhas soltas"

## Regras aprovadas

1. **Proibição Estrita de Linhas Soltas ou Arame:**
   - Ficam terminantemente proibidos traços finos soltos, vetores tipo "arame", contornos abertos ou formas esqueletais com muito espaço vazio.

2. **Padrão de Construção Visual Monolítico (Padrão Water & Fire):**
   - **Massa Sólida Principal:** O glifo deve possuir uma silhueta maciça e espessa que preencha entre 65% e 75% da caixa do ícone, com o mesmo peso gráfico, presença e densidade dos ícones oficiais de Fire (labareda com núcleo) e Water (gota volumosa).
   - **Recorte Negativo Interno (Carve-out):** A dinâmica e o movimento (seja de furacão, vórtice ou rajada) devem ser esculpidos através de **entalhes negativos limpos e vazados dentro da massa sólida**, exatamente como o núcleo interno de Fire e o reflexo curvo de Water.
   - **Contraste no Fundo `#4ff7ba`:** A silhueta preta encorpada deve saltar aos olhos com força gráfica de alto impacto neo-brutalista em 64px, 32px e 16px.

## Relação com decisões anteriores

- Soluciona a causa-raiz identificada nas iterações de **D-406**, **D-407**, **D-408**, **D-409** e **D-410**, alinhando a linguagem visual de Wind aos padrões já ratificados em **D-397**.
