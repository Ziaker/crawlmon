<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-404 — Aprovação de Dodge (Opção 1), Mystic (Opção 3), Revisão de Wind, Área e Electric

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Alcance / Combate / Regras
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; protótipos visuais atualizados; documentação oficial atualizada; aguarda seleção da nova opção de Wind.

## Declaração literal do criador

> ok, opção 1 do dodge, mystic opção 3 e wind refaz do zero as 3 opções, todas péssimas, além disso aumente o tamanho do círculo do icone da área. deixe o fundo do eletric um pouco mais claro

## Regras aprovadas

1. **Aprovação Definitiva de Glifos:**
   - **Dodge:** Oficializado o glifo da **Opção 1 (Sidestep Swerve / Duplo Chevron `<<`)** com fundo `#fcb900`.
   - **Mystic (Almighty):** Oficializado o glifo da **Opção 3 (Sigilo Transcendental de 8 Pontas / Bannō Sigil)** com fundo `#65B5B3`.

2. **Ajuste de Cor de Electric:**
   - O fundo de **Electric** é clareado de `#facc15` para **`#fde047`** (amarelo elétrico luminoso/limão), mantendo distinção imediata contra o âmbar dourado de Dodge (`#fcb900`) e a tonalidade suave/pastel de Light (`#fef08a`).

3. **Ampliação do Glifo de Área (`○`):**
   - O diâmetro do círculo aberto sem preenchimento central no badge de Alcance de Área é substancialmente ampliado (raio de 7.5 para 9.2 em viewBox 24x24), preenchendo o espaço útil do badge com traço marcante e legibilidade em qualquer resolução.

4. **Três Novas Opções do Zero para Wind (Fundo `#4ff7ba`):**
   - As opções anteriores foram descartadas e 3 novas abordagens visuais foram desenvolvidas no laboratório:
     - **Opção A (Kaze Streams / Lufadas Eólicas em Espiral):** Correntes de ar horizontais dinâmicas com arremate em caracóis/espirais aerodinâmicos clássicos de mangá/anime e RPGs japoneses.
     - **Opção B (Eye of the Storm / Tufão em Vórtice Único):** Espiral contínua centralizada e espessa em vórtice circular com extremidade em corte cortante.
     - **Opção C (Air Slash / Lâmina de Vácuo Eólica):** Foice de vento aerodinâmica arqueada com aletas duplas de descompressão sônica.

## Relação com decisões anteriores

- Consolida escolhas abertas em **D-403**.
- Atualiza a paleta de cores definida em **D-397**.
