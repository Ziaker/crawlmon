<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-396 — Elemento Nature, Tipos Guard e Dodge, e Setas de Alcance com Fundo Branco

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; protótipos visuais atualizados; pendente de migração no motor Godot.

## Declaração literal do criador

> A variante A está boa mas os ícones dos elementos está péssimo e sem apoio visual nenhum, não da pra saber que elemento é o que além das cores, refaça elas, além disso, grande mudança (altere os documentos sobre também), o elemento Poison, chame-o de Nature, já engloba a ideia de veneno por automático e mantenha a cor. Além disso adicione mais 2 tipos, o equivalente ao Dodge e o equivalente ao guard para moves que usam seus conceitos. Quanta as setas, deixe todas com o fundo branco

## Regras aprovadas

1. **Ícone 1 — Tipo de Dano / Categoria do Golpe:**
   - A **Variante A** está oficialmente aprovada para dano:
     - **Físico:** *Starburst* / explosão angular pontiaguda de impacto cinético (fundo vermelho).
     - **Mágico:** Anéis concêntricos / ondas de pulso de aura expandindo (fundo azul).
   - Adicionadas **duas novas categorias de Tipo de Move**:
     - **Guard (Guarda / Defensivo):** ícone de escudo chanfrado de proteção para golpes baseados no conceito de guarda, barreira ou bloqueio (ex.: Guard).
     - **Dodge (Esquiva / Evasivo):** ícone de asas velozes / rastro cinético de evasão para golpes baseados no conceito de esquiva, reposicionamento ou teleporte evasivo (ex.: Teleport, Evade).
   - **Nenhum (Status puro / Buffs / Debuffs):** continua sem ícone presente de tipo de dano (D-395).

2. **Ícone 2 — Alcance (Range):**
   - As setas e o traço de alcance passam a ter obrigatoriamente **fundo branco sólido**:
     - **Melee (Corpo a corpo):** seta para cima (`↑`) ou chevron ascendente preto sobre **fundo branco**.
     - **Mid Range (Médio alcance):** traço reto horizontal (`—`) preto sobre **fundo branco**.
     - **Long Range (Longo alcance):** seta para baixo (`↓`) ou chevron descendente preto sobre **fundo branco**.
     - **Status / Pessoal:** sem ícone presente (nada).

3. **Ícone 3 — Elemento Nature (Substituição de Poison) e Apoio Visual:**
   - O elemento anteriormente denominado **Poison** passa a se chamar **Nature (Natureza)**.
   - Nature já engloba veneno, toxinas naturais, flora, esporos e ácidos vegetais automaticamente.
   - A cor do elemento permanece a mesma: **verde-ácido / tóxico (`#84cc16`)**.
   - Os 12 elementos recebem **re-design vetorial completo com apoio visual imediato** (silhueta legível em preto e branco sem depender exclusivamente de cor) (atualizado: D-398):
     1. **Neutral:** Diamond Core — losango facetado chanfrado com anel geométrico e núcleo sólido central (atualizado: D-440).
     2. **Fire:** Labareda com chamas internas e labaredas menores destacadas.
     3. **Water:** Gota d'água fluida e nítida com reflexo/onda interna (atualizado: D-397).
     4. **Electric:** Relâmpago em zigue-zague com farpas de alta voltagem.
     5. **Wind:** Ciclone triplo espiral com linhas aerodinâmicas de rajada.
     6. **Psychic:** Olho místico do terceiro olho com pupila e anéis concêntricos de telecinese.
     7. **Light:** Cruz estelar sagrada de 8 pontas radiante com halo solar.
     8. **Dark:** Lua mística chanfrada envolvendo crânio espectral/vórtice de sombras.
     9. **Nature:** Folha estilizada fundida com gota tóxica ácida de veneno no núcleo.
     10. **Sound:** Diapasão de frequência acústica emitindo 3 ondas sonoras concêntricas.
     11. **Earth:** Pico de montanha triplo e blocos de rocha facetados.
     12. **Mystic:** Esfera cósmica facetada radiante com flares estelares e anel orbital místico (atualizado: D-398).

## Relação com decisões anteriores

- Altera **D-118** e **`scripts/data/element.gd`**: a categoria `VENENO` é renomeada conceitual e documentalmente para `NATURE` (mantendo `#84cc16`).
- Estende **D-395**: detalha os glifos da Variante A, adiciona os Tipos Guard e Dodge, e fixa o fundo branco das setas de alcance.

## Estado no código

- Protótipos visuais atualizados: `prototypes/icones_moves_lab.html` e `prototypes/hud_post_combat.html`.
- Migração no motor Godot (`scripts/data/element.gd`, `scripts/data/skill.gd`, etc.): aguarda comando específico.
