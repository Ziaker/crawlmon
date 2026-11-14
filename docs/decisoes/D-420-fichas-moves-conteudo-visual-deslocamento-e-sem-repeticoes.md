<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-420 — Fichas de Moves: Descrição Visual, Deslocamento, Wind-up e Eliminação de Redundâncias Visuais

- **Data:** 2026-11-08
- **Área:** UI / Status Screen / Fichas de Moves / Combate
- **Origem:** instrução direta do criador via prompts sucessivos.
- **Estado:** aprovado em definitivo; em implementação.

## Declarações literais do criador

> "tá mas cade a descrição do move? cade os textos falando o que o move faz e seu visual? a visão expandida devia explicar também seu visual, seu deslocamento, wind-up, e outras coisas"
> "além de também ter menções constantes a informações já visiveis para o jogador, não precisa omitir informação, só não repita a mesma mais do que uma vez se já estiver visivel o suficiente"

## Regras aprovadas

1. **Eliminação Estrita de Informações Redundantes:**
   - Não repetir em textos ou descrições valores que já estão evidentes na interface:
     - O custo de ATB (já presente no chip `[ N ATB ]`).
     - O custo de MP (já presente no chip `[ N MP ]`).
     - O multiplicador de poder (já presente no chip `[ POWER ×N ]`).
     - O nome do elemento e tipo (já presentes na cor do fundo, marca d'água e badges).
   - O espaço de texto deve ser dedicado 100% a dados qualitativos e técnicos reais que enriquecem a compreensão do jogador.

2. **Pilares de Conteúdo de Qualquer Move:**
   Toda ficha de habilidade deve cobrir quatro eixos essenciais:
   - **O que faz (Mecânica & Efeito):** O efeito tático concreto do golpe (dano direto, quebra de guarda, roubo de escudos/buffs, debuff temporal, área de efeito, interrupção).
   - **Visual (VFX):** Como o golpe se manifesta esteticamente em 3D (auras, anéis de choque, relâmpagos, distorções telecinéticas, partículas e cores).
   - **Deslocamento (Cinemática):** O comportamento espacial do atacante e do golpe (estacionário, corrida corpo a corpo, recuo, teleporte, projétil parabólico, feixe direto ou rente ao solo).
   - **Wind-up & Timing:** O tempo exato de preparo (em segundos), postura de canalização e risco de sofrer interrupção por dano pesado.

3. **Ficha Padrão (Card Inferior da Status Screen):**
   - **Linha 1 (Mecânica & Alvo):** Ação tática principal e entrega espacial (ex.: "Disruptive telekinetic pressure. Single Target burst.").
   - **Linha 2 (Visual & Deslocamento):** Descrição condensada do efeito visual e movimentação (ex.: "Stationary channel; launches swirling violet distortion orbs that detonate on contact.").
   - **Linha 3 (Escala & Timing):** Atributo de escala e wind-up (ex.: "Wind-up: 1.50s (interruptible) · Scales with MAG · +4 MP / 8s cycle").
   - **Shift Mode:** Mantém a quebra matemática analítica com fórmulas base, bônus de Nature e cronômetro de recarga de MP.

4. **Visão Expandida (Modal Z):**
   - Um painel técnico aprofundado em estilo flat neo-brutalista dividido em blocos estruturados:
     - **Header:** Nome do Move, Badges de Tipo/Alcance e Chips de Custo (`ATB`, `MP`, `POWER`).
     - **Section 1: MECHANICS & EFFECT:** Detalhamento profundo de regras, dano, debuffs e interações.
     - **Section 2: VISUALS & VFX:** Descrição visual estética completa de todas as fases (preparo, lançamento, impacto).
     - **Section 3: MOTION & DISPLACEMENT:** Cinemática espacial do usuário e do projétil/ataque.
     - **Section 4: WIND-UP & TIMING:** Tempo exato em segundos, fases de canalização e suscetibilidade a interrupções.
     - **Section 5: TACTICAL & SCALING:** Escala de atributos (STR/MAG), sinergia com Natures e fraquezas elementais (dano 1.5×).

5. **Independência de Personagem (D-235):**
   - Nenhuma descrição pode associar o golpe a uma espécie específica (proibido dizer "lançado pelo Orc", "chute do Pancham", etc.). Todo move pertence ao ecossistema geral e funciona igualmente com qualquer combatente.
