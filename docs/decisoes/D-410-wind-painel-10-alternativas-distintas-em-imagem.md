<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-410 — Wind: Painel Comparativo de 10 Alternativas Radicais em Imagem Única

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate / Regras
- **Origem:** decisão direta do criador solicitando abertura de leque com 10 alternativas completamente distintas entre si, apresentadas em imagem gerada única sem mexer no código HTML.
- **Estado:** regra registrada; documentação atualizada; exploração visual conduzida exclusivamente via geração de imagem comparativa com 10 arquétipos visuais.

## Declaração literal do criador

> "é eu simplesmente não consigo decidir nada, não tem uma opção boa, me vê 10 alternativas, todas diferentes em uma imagem gerada"

## Regras aprovadas

1. **Abertura do Leque Conceitual (10 Arquétipos Diferentes):**
   - Apresentar 10 interpretações visuais radicalmente distintas do elemento Wind, evitando repetições da mesma fórmula:
     1. *Lufada de Vento Dinâmica / Rajada de Brisa* (Wind Gust clássico).
     2. *Tornado Cônico em Vórtice* (Funil vertical estilizado).
     3. *Pena Eólica / Pluma de Vendaval* (Símbolo sutil de leveza e velocidade).
     4. *Foice de Vento / Kamaitachi* (Corte duplo cortante de ar).
     5. *Asa de Anemo / Voo Eólico* (Asa estilizada aerodinâmica).
     6. *Olho do Furacão Minimalista* (Ciclone 🌀 limpo).
     7. *Tríscele de Espirais Avatar* (Air Nomad triskele).
     8. *Catavento em Perspectiva 3D* (Pinwheel inclinado a 20°).
     9. *Chicote de Vento em Caracol* (Monolítico em rajada contínua).
     10. *Rosa dos Ventos / Bússola Eólica* (Cruz cardeal aerodinâmica).

2. **Entrega Exclusiva por Imagem:**
   - Todo o painel de 10 alternativas é renderizado em uma folha de contato PNG em alta resolução no fundo `#4ff7ba`, preservando o código HTML de 700+ linhas intacto até a definição final pelo criador.

## Relação com decisões anteriores

- Estende **D-403**, **D-404**, **D-407**, **D-408** e **D-409**, expandindo o escopo para além de uma única família de glifos.
