<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-419 — Reposicionamento da Ficha de Move: Nome no Topo, Ícones em Linha e Expansão de Informações

- **Data:** 2026-11-08
- **Área:** UI / Status Screen / Ficha de Move
- **Origem:** instrução direta do criador via prompt com anexo visual.
- **Estado:** aprovado em definitivo; em implementação.

## Declaração literal do criador

> "reposicione ambos o texto e os icones, deixe os icones ao lado direito do texto e aumente a quantiade de informação sobre o move, sem ser a versão expandida, mova o nome do move mais para cima com o espaço livre e deixe os icones do mesmo tamanho que o tamanho da fonte, inclusive dos ícones de atb mp e power"

## Regras aprovadas

1. **Nome do Move no Topo e Ícones ao Lado Direito:**
   - O nome do move (ex.: `CONFUSION`, `KARATE CHOP`) é movido para o topo do card, aproveitando o espaço superior livre.
   - Os ícones de Tipo (Physical/Magical/Dodge/Guard) e Alcance (Melee/Mid/Long/Area) deixam de ficar acima do texto e passam a ficar **ao lado direito do nome do move**, na mesma linha horizontal.

2. **Ícones com a Mesma Altura da Fonte:**
   - O tamanho dos ícones ao lado do nome (`ic_sz`) deve corresponder exatamente à altura da fonte do título do move (ex.: 22–24px).
   - Os blocos de estatísticas de ATB, MP e POWER no topo direito também devem ter altura e proporção equivalentes à escala da fonte, mantendo o formato de paralelogramo flat inclinado à direita (`/ /`).

3. **Aumento de Informação na Versão Padrão (Sem ser a Expandida Z):**
   - Com o nome e ícones consolidados no topo da ficha, o espaço vertical inferior é ampliado para exibir mais informações técnicas do move em linhas organizadas:
     - **Linha de Efeito & Propriedades:** Tipo de entrega, dano relativo, se perfura barreira ou cura, e tempo de windup.
     - **Linha de Descrição & Tática:** Descrição completa da habilidade e utilidade tática.
     - **Métricas de Recarga / Escala:** Atributo de escala principal (MAG/STR) e consumo de MP/ATB em relação à regeneração.
