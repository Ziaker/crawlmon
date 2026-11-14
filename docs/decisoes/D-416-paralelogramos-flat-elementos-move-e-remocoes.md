<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-416 — Paralelogramos Flat, Marca d'Água de Elemento, Blocos ATB/MP/Power e Destaque da Hotbar

- **Data:** 2026-11-07
- **Área:** UI / Status Screen / Ícones / Moves / Ficha Tática
- **Origem:** instruções diretas do criador via prompts sucessivos com anexos visuais.
- **Estado:** aprovado em definitivo; em implementação.

## Declarações literais do criador

> "ainda está péssimo, além da qualidade dos ícones também ter piorado. remova estas bordas, é preciso que sejam flat, inclusive ao invés de serem quadrados, poderiam ser paralellogramas pra direita (nos icones de skill e nos icones a frente do nome na região direita. Não mexa na esquerda, inclusive o ícone do elemento deve sempre estar atrás do nome do move, no mesmo tamanho e alinhamento da fonte.
> 
> A cor do nome do move deve ser colorida da cor do fundo do elemento do move também. Remova a parte da imagem que tirei, ela é desnecessária."

> "a parte da elevação não funciona, após corrigir, deixe as outras abilidades não selecionadas 20% mais escuras só pra destacar mais.
> 
> como o elemento está como marca d'gua, não é necessário ter o ícone novamente ao lado dos outros dois, mas obviamente ainda deve existir o icone em huds que não utilizam o mesmo formato
> 
> Inclusive nestes blocos que mostra o atb mp e o poder, faça eles também serem paralelogramas pra direita com fundo flat da cor referente"

## Regras aprovadas

1. **Remoção de Bordas e Estilo 100% Flat:**
   - Eliminar todas as linhas de contorno (strokes, outlines, borders) nos blocos e slots. Todos os blocos visuais passam a ser puramente flat, com preenchimento sólido sem contorno.

2. **Forma em Paralelogramo Inclinado à Direita (`/ /`):**
   - **Slots de Skill (Hotbar inferior):** Em vez de quadrados, cada slot passa a ser um paralelogramo com inclinação/skew voltada para a direita (`/ /`).
   - **Ícones de Elemento à Frente do Nome (Região Direita):** Os blocos elementais que acompanham o nome do protagonista/aliado no painel direito (ex.: `ABRA` e `PANCHAM`) passam a ser paralelogramos inclinados para a direita.
   - **Blocos de ATB, MP e Poder (Ficha de Move):** No canto superior direito da ficha de move, os blocos de ATB, MP e POWER passam a ser paralelogramos inclinados à direita (`/ /`) com fundo flat da cor referente (ATB: ciano/teal `#138cb5`, MP: azul `#3b82f6`, POWER: dourado/âmbar `#f59e0b` / `#fde047`).
   - **Não mexer na esquerda:** O painel de equipe (roster) à esquerda permanece inalterado.

3. **Destaque do Slot Selecionado na Hotbar (Elevação + 20% Escurecimento):**
   - O slot selecionado é elevado verticalmente (deslocado ~8px para cima) e exibe sua cor canônica vibrante plena.
   - Todas as outras habilidades não selecionadas ficam **20% mais escuras** (`col.darkened(0.20)`), garantindo leitura imediata da seleção sem necessidade de bordas.

4. **Ficha do Move com Fundo do Elemento e Marca d'Água:**
   - O card do move selecionado assume a cor oficial do elemento em fundo flat (ou painel temático de alta saturação).
   - O glifo do elemento é desenhado como uma grande marca d'água translúcida posicionada em segundo plano atrás do nome e da área de texto.
   - O nome do move aparece grande em tipografia de alto contraste.
   - Na linha superior da ficha, permanecem apenas os badges de **Tipo** (Physical, Magical, Dodge, Guard) e **Alcance** (Melee, Mid, Long, Area). O terceiro ícone do elemento é removido dali para evitar redundância com a marca d'água de fundo (mas permanece em HUDs onde o formato de card com marca d'água não é utilizado).

5. **Remoção do Banner Central Desnecessário:**
   - Remoção definitiva da tarja `◆ PLAYER // LEADER` / `◆ ALLY // AI CONTROLLED` posicionada abaixo do recorte de arte dos monstros.

6. **Qualidade dos Ícones SVG:**
   - Reimportação dos arquivos SVG com escala vetorial ampliada (`svg/scale=4.0`) e filtragem linear para assegurar nitidez absoluta nos traços, sem blur nem perda de qualidade.
