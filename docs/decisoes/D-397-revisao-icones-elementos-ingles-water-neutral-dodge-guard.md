<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-397 — Revisão de Elementos (Water e Neutral), Nomes em Inglês, Ícones de Magia, Guard e Dodge

- **Data:** 2026-11-07
- **Área:** UI / Moves / Elementos / Combate
- **Origem:** decisão direta do criador, na conversa.
- **Estado:** regra registrada; protótipos visuais atualizados; pendente de migração no motor Godot.

## Declaração literal do criador

> os icones ainda estão péssimos, inclusive outra mudança nas regras
> 
> ao invés de gelo, vamos com água, water, sem ter ambos
> 
> quanto aos icones das setas, estão ótimos e não precisam de review. O icone magico poderia ser um Sparkle, estrela de 4 pontas, purpurina
> 
> o Escudo ao invés de ter um + dentro podia só ser mesmo um escudo por completo, preenchido
> 
> O dodge é irreconhecivel, pense em um pé pontudo inclinado a 30 graus ou algo assim
> 
> Terra está ótimo, o Som anterior estava bom já
> Nature ok
> Fogo ok
> Raio OK
> vento PÉSSIMO
> Psíquico, ruinzinho, podia ser um pouquinho diferente
> Gelo PÉSSIMO
> 
> luz e trevas estão péssimos, não estão contrastantes.
> 
> Neutro (neutral) (não fisico) também está péssimo, eu faria o neutro ser apenas um circulo completamente preenchido
> 
> NÃO USE nomes em portugûes pra cada elemento.
> quanto a cor do dodge, podia ser amarela ao invés de roxa, já a cor do guard podia seguir a mesma cor do Neutro

## Regras aprovadas

1. **Nomes dos Elementos Obrigatoriamente em Inglês:**
   - Nenhum nome em português para elementos.
   - Lista fechada dos 11 elementos oficiais do Crawlmon:
     1. **Neutral** (substitui o antigo *Physical/Físico* nos elementos)
     2. **Fire**
     3. **Water** (substitui em definitivo *Ice/Gelo*; apenas Water, sem ter ambos)
     4. **Electric**
     5. **Wind**
     6. **Psychic**
     7. **Light**
     8. **Dark**
     9. **Nature** (D-396)
     10. **Sound**
     11. **Earth**

2. **Re-design dos Glifos dos Elementos:**
   - **Neutral:** apenas um **círculo completamente preenchido (`●`)**. Cor base: Slate/Prata (`#cbd5e1`).
   - **Water:** gota d'água fluida e nítida com reflexo/onda interna (substitui o floco de gelo).
   - **Wind:** lâminas curvas aerodinâmicas de vento cortante em rajada (*gust/swoosh*).
   - **Psychic:** terceiro olho arcano com anéis de ressonância psicocinética refinados.
   - **Light e Dark com Alto Contraste:**
     - **Light:** sol sagrado brilhante com estrela de múltiplos raios radiantes dourado/branco em alto contraste positivo.
     - **Dark:** lua crescente pontiaguda abissal envolvendo um eclipse de trevas profundo em alto contraste negativo.
   - **Earth, Sound, Nature, Fire, Electric:** mantidos nos modelos aprovados.

3. **Ajustes nos Tipos de Move (Ícone 1):**
   - **Magical:** ícone de **Sparkle** (estrela de 4 pontas geométrica / purpurina / centelha).
   - **Guard:** **escudo completamente preenchido** (sólido, sem o `+` interno). Sua cor passa a ser **a mesma cor do elemento Neutral** (`#cbd5e1`).
   - **Dodge:** **pé pontudo inclinado a 30 graus** (silhueta de arranque/esquiva rápida). Sua cor passa a ser **amarela** (`#facc15`).
   - **Physical:** mantém *Starburst* de impacto (vermelho).
   - **Status:** sem ícone (preservado).

4. **Ícone 2 (Alcance):**
   - Aprovado sem necessidade de review: setas e traço pretos sobre **fundo branco sólido** (`[ ↑ ]`, `[ — ]`, `[ ↓ ]`).

## Relação com decisões anteriores

- Altera **D-118** e **`scripts/data/element.gd`**: o elemento `AGUA_GELO` passa a ser exclusivamente `WATER`, e o elemento `FISICO` passa a ser denominado `NEUTRAL`.
- Altera **D-395** e **D-396**: aplica as cores amarelo para Dodge, cor de Neutral para Guard, Sparkle para Magical, e fixa nomes em inglês.

## Estado no código

- Protótipos atualizados: `prototypes/icones_moves_lab.html` e `prototypes/hud_post_combat.html`.
- Migração no motor Godot pendente de autorização.
