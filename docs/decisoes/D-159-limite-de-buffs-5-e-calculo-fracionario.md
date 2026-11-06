# D-159 — Limite de Buffs/Debuffs Ampliado para ±5, Acumulação Aditiva Unificada, Cálculo Fracionário e Teto Visual em 3 Stacks

- **Data:** 2026-11-03
- **Área:** Combate / Atributos / Balanceamento / Visual
- **Origem:** Conversa (/grill-me)

## O que o criador disse (literal)

> "reduções e aumentos de efeitos negativos / positivos que stackam devem ter limite de até +5 / -5, não só 2, além disso, quando tem atk -3 e ganha um efeito de atk +1, então o personagem fica com atk -2 ao invés de atk +1 /grill-me me diz se entendeu"
> "A1: opção 2, além disso, a referência visual no modelo dos pokemons não passa dos 3 stacks, no caso, após o terceiro stack de atk + o personagem não cresce mais que isso, o mesmo para o restante" (sobre fórmula de cálculo fracionária e teto visual)
> "A1: (Recommended) Popup mostra a variação imediata ('↗ ATK +1') e a tag/badge no HUD e sobre o personagem exibe o saldo acumulado ('ATK -2')." (sobre feedback de popup)
> "A1: (Recommended) Permanece travado no limite (+5 ou -5) e o log de combate avisa que o atributo já atingiu o patamar máximo/mínimo (ex: 'O ataque de Gible já está no máximo!')." (sobre tentativa além dos limites)

## Decisão

1. **Limite de Stacks Ampliado para ±5:**
   - O intervalo de estágios acumuláveis de buffs positivos e debuffs negativos é expandido de `[-2, +2]` para `[-5, +5]`.
   - Aplica-se uniformemente a Ataque (`atk_buff`), Defesa (`def_buff`) e Velocidade (`speed_buff`).

2. **Acumulação Aditiva Unificada (Mesma Escala Relativa):**
   - Buffs positivos e debuffs negativos atuam no mesmo acumulador numérico e se anulam diretamente:
     - Exemplo: se o combatente possui `ATK -3` e recebe um buff de `ATK +1`, o novo valor é `ATK -2` (e não uma substituição por +1).
   - Se um combatente já estiver em `+5` (máximo) ou `-5` (mínimo) e receber outro efeito na mesma direção:
     - O valor permanece travado em `+5` ou `-5`.
     - O log de combate informa que o atributo já está no patamar máximo/mínimo.

3. **Cálculo de Combate — Fórmula Relativa Fracionária:**
   - Para evitar divisões por zero, danos negativos ou imunidade absoluta de dano em `+4` e `+5`, adota-se fórmula relativa fracionária com passo de `25%` ($0.25$):
     - **Ataque (ATK):**
       - Para $s \ge 0$: $\text{mult} = 1.0 + s \times 0.25$ (de $\times 1.00$ a $\times 2.25$).
       - Para $s < 0$: $\text{mult} = \frac{1.0}{1.0 + |s| \times 0.25}$ (de $\times 0.80$ em $-1$ até $\times 0.44$ em $-5$).
       - $\text{ataque} = \max(1, \text{round}(\text{base\_attack} \times \text{mult}))$.
     - **Velocidade (SPD):**
       - Para $s \ge 0$: $\text{mult} = 1.0 + s \times 0.25$ (de $\times 1.00$ a $\times 2.25$).
       - Para $s < 0$: $\text{mult} = \frac{1.0}{1.0 + |s| \times 0.25}$ (de $\times 0.80$ em $-1$ até $\times 0.44$ em $-5$).
       - $\text{speed} = \max(0.1, \text{base\_speed} \times \text{mult})$.
     - **Defesa (DEF):**
       - Para $s \ge 0$: o dano recebido é mitigado dividindo por $(1.0 + s \times 0.25)$ (em $+5$, divide por $2.25 \to \sim 44.4\%$ do dano recebido, mitigação de $55.6\%$).
       - Para $s < 0$: o dano recebido é amplificado multiplicando por $(1.0 + |s| \times 0.25)$ (em $-5$, multiplica por $2.25 \to 225\%$ do dano recebido).

4. **Teto Visual nos Modelos 3D Travado em 3 Stacks:**
   - Conforme D-158, porém com clampeamento estrito em `[-3, +3]` para a representação gráfica do modelo:
     - **Escala de Porte (ATK):** varia em $\pm 15\%$ por stack até o limite de $\pm 3$ (máximo de $+45\%$ em $+3, +4, +5$; mínimo de $-45\%$ em $-3, -4, -5$).
     - **Velocidade de Animação (SPD):** varia em $\pm 15\%$ por stack até o limite de $\pm 3$ (máximo de $1.45x$ em $+3, +4, +5$; mínimo de $0.55x$ em $-3, -4, -5$).
     - **Contorno e Brilho de Armadura (DEF):** espessura e reflexos metálicos variam até o limite de $\pm 3$ stacks.

5. **Interface e Popups:**
   - O popup 2D flutuante (`SmtStageVfx`) exibe a alteração pontual sofrida pela ação (ex: `↗ ATK +1`, `↘ DEF -1`).
   - As badges flutuantes no HUD e acima dos alvos exibem o saldo líquido total acumulado (ex: `ATK -2`, `DEF +4`).
   - O painel de status reflete a porcentagem real correspondente ao multiplicador fracionário.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma (todas as decisões e detalhes alinhados e validados no /grill-me).

## Estado no código

Implementado (`combatant.gd`, `battle.gd`, `battle_fx.gd`, `status_panel.gd`, `tests/battle/test_d159_buff_stacks_limit5.gd`).
