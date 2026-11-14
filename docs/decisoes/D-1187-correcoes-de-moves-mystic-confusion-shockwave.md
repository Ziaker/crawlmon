# D-1187 — Correções de Moves: Kaja/Kunda e Heal são Mystic, Confusion confunde, Shock Wave é desviável, Psybeam quebra-escudo como ideia

- **Data:** 2026-11-12.
- **Área:** Moves / elementos / textos / conteúdo.
- **Relacionadas:** D-1144 (Megido é Mystic), D-398 (Mystic = Almighty), D-1185 rodada 11 (inspeção), D-1186 (wind-up do combate), D-420 (fichas).
- **Status:** elementos e texto do Shock Wave **aplicados**; Confusion e Psybeam **registrados, sem código**.

## O que o criador disse (literal)

> o que tá escrito na maioria dos textos na esquerda sobre efeito está falso, porém tem umas coisas que quero corrigir
>
> 1 - psybeam destruir escudos pode ser feature
> 2 - Confuse tem 20% + LK de chance de causar Confusão (vamos definir o efeito de status outra hora)
> 3 - Em NENHUM MOMENTO é dito que shock wave é indisviável, vc não tá usando os textos já presentes no jogo (se isso é apenas pro mock-up então ok, mas se for pra ser entregue assim então tá errado)
> 4 - sukunda é Mystic assim como seus semelhantes de SMT
> 5 - Heal é mystic

Pergunta: "Tarukaja (hoje Fire) e Rakunda (hoje Dark) também viram Mystic?"

> sim, os tres, alem disso, no Taunt do pancham, o fundo não tem cor semelhante a cor do elemento

## Decisão

1. **Mystic:** **Sukunda, Tarukaja, Rakunda e Heal** passam a ser **Mystic** (`element = 11`), como o Megido (D-1144). Aplicado nos `content/moves/*/move.tres` e nas listas de reserva de `scripts/data/skill.gd`.
2. **Shock Wave não é indesviável.** O código já deixa desviar (`scripts/combat/battle_fx.gd:390`: no erro só o impacto visual aparece). As frases "Undodgeable … bypassing evasion" saíram dos textos (`description_text`, `mechanics_text`, `tactical_text` e a reserva em `scripts/data/skill_legacy_data.gd`); o resto da frase ficou igual.
3. **Confusion:** **20% + LUK** de chance de causar o status **Confusão**. O efeito do status será definido depois → **sem código e sem texto** até lá (o texto não pode prometer o que o jogo não faz).
4. **Psybeam destruir escudos:** **ideia de feature**, não aprovada como regra; nada muda. O texto atual ("pierces barriers") continua e fica marcado como não verdadeiro hoje.
5. **Textos "falsos":** a maioria dos `mechanics_text`/`tactical_text` não descreve o que o jogo faz. Na inspeção do protótipo, o lado mecânico passa a usar só **dados do jogo**: o `effect_line_text` (a linha que o próprio combate mostra), os números e as tags. Reescrever os textos de todos os Moves é trabalho separado, a pedir.
6. **Taunt:** o fundo do card no protótipo estava na cor de Dark porque o protótipo tinha o elemento errado; o Taunt é Neutral no jogo. O protótipo passa a ler elemento, poder e custos direto dos `.tres` (havia outros valores errados: Brick Break, Hassou Tobi, Tarukaja).

## O que não foi verificado

- Efeito de afinidade: inimigos com Weak/Resist a Mystic passam a reagir a esses quatro Moves; não houve teste de balanceamento.
- VFX/ícones dos quatro Moves continuam os mesmos (só a cor/ícone do elemento muda onde a UI lê o elemento).
