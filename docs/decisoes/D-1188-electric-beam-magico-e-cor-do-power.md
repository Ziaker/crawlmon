# D-1188 — Electric Beam escala com MAG; cor do POWER segue o stat que o Move usa

- **Data:** 2026-11-12.
- **Área:** Moves / dano / UI (protótipo D-1185).
- **Relacionadas:** D-1140 (dano mágico usa MAG), D-977/D-1081 (Electric Beam), D-1185 rodada 4 (cores dos stats), D-1187.
- **Status:** **aplicado**.

## O que o criador disse (literal)

> mude a cor do power pra ser igual a cor do status que ele escala com, no caso se for um move magico, ele tem uma cor diferente, quando move é fisico ele tem a cor que já usamos
>
> alem disso electric beam tá escalando com STR ao inves de MAG, corrija

## Decisão

1. **Electric Beam é mágico:** escala com **MAG** (D-1140). O `content/moves/electric_beam/move.tres` não declarava `damage_type`, então caía no padrão físico (STR). Agora declara `damage_type = 1` (Magical). Poder, custo, wind-up e STUN não mudam.
2. A linha de efeito dele dizia "Electric damage x1.0 ATK"; passa a "100% MAG electric damage | Projectile | 2 ATB" (mesmo formato dos outros Moves mágicos), e a curta "100% electric".
3. **Cor do POWER (protótipo D-1185):** Move **mágico** → chip POWER na **cor do MAG** (lilás `#b5a5fe`, da rodada 4); Move **físico** → continua o **dourado/laranja** atual (`#f59e0b`).

## Em aberto

- Se a cor do POWER por stat também vale na Status Screen do jogo (lá o chip continua laranja para todos).

## Aplicação no jogo (2026-11-12)

- Resposta literal do criador à pergunta "A cor do POWER por stat também vale na Status Screen do jogo?":
  > Sim, no jogo também
- Aplicado em `scripts/ui/status_screen.gd`: nova função `_power_chip_color(skill)` retorna lilás `#b5a5fe` (MAG) quando o Move é mágico e não é de status; caso contrário âmbar `#f59e0b` (Moves físicos e de status mantêm âmbar, porque status não tem stat de escala). Manter âmbar nos Moves de status é escolha do assistente, não pedida pelo criador.
- Usada nos dois chips POWER (o card no fim da Status Screen e a ficha expandida).
- Verificado com captura real da Status Screen usando Moves do catálogo: Electric Beam mostra `POWER ×1,0` em lilás e "Scales with MAG"; Karate Chop mostra `POWER ×1,5` em âmbar e "Scales with STR".
- Não alterado / não verificado: outras telas não têm chip POWER (`skill_info_panel.gd` usa âmbar só na tag WEAK, sem mudança); a ficha expandida (Z) não foi capturada.

O item em aberto acima foi respondido: vale no jogo.
