# D-1202 — Dread de projétil aparece no jogador, na diagonal acima dele

- **Data:** 2026-11-12.
- **Área:** Combate / Evade / Dread (visual).
- **Origem:** conversa com o criador.
- **Status:** regra registrada; implementação em andamento. Altera a D-1078 (itens 2 a 4).

## Frase literal do criador

> quero voltar com a ideia do dread existir em moves que são projéteis (não toque nos que já têm ele porque são coisas à parte que fazem sentido), porém o dread aparece NO jogador, na região diagonal acima dele ao invés do oponente/projétil do oponente; não encoste nos moves que já possuem uma regra diferente pro Dread.

Respostas às perguntas:

- Fora da mudança: **Fire Bullet** (D-1029/D-1039/D-1052) e **Javelin Throw** (D-1176).
- Posição: **"Acima e do lado do atacante"**.
- Timing: **"A janela de Evade (últimos 0,25 s antes do acerto)"**.

## Decisão

1. Todo Move do tipo **projétil** (`Skill.Kind.PROJECTILE`) mostra o Dread **no jogador (o líder)**, e não no atacante nem no projétil.
2. **Exceções (regra própria, não mudam):** Fire Bullet (Dread na ponta do projétil, D-1029) e Javelin Throw (Dread na ponta da javelin, D-1176). O Drain Spear continua sem Dread (D-1016).
3. **Posição (ajustada em 2026-11-12):** colada ao personagem, do lado de onde vem o ataque, na região da orelha (um pouco acima do topo do corpo), 20% menor que o tamanho derivado do corpo. O alcance lateral é medido no corpo real, limitado a 0,12–0,32 da altura, e o raio nunca passa de 1,0 m (adaptação a modelos grandes). Primeira versão: acima da cabeça.
4. **Janela e fade:** a janela de Evade do projétil (últimos 0,25 s antes do acerto) e o fade padrão do Dread (D-986/D-987).
5. **Só o líder:** como na D-1168, o Dread só acende para ataque que o líder pode desviar.
6. **Corpo a corpo não muda:** continua no atacante (D-986/D-989/D-991/D-992).
7. **Tidal Surge e Bubble Shot** deixam de ser exceção "sem Dread" da D-1078: recebem o novo Dread no jogador. O **Electric Beam** deixa de mostrar o Dread no atacante e passa a mostrá-lo no jogador.
8. Só visual (D-019): dano, janela, acerto e tempo não mudam.

## Ambiguidades em aberto

- `Skill.Kind.PROJECTILE` também inclui Megido, Mabufula, Confusion, Psybeam, Sand Attack, Dragon Rage, Rock Throw, Flame Stream e Splitter Flames; todos entram pela regra acima.
- Se a distância entre Dread e cabeça (deslocamento lateral e altura) ficar boa ou precisar de ajuste depende de revisão em vídeo.

## Estado

Implementação em `scripts/vfx/combat/fx_evade_flash.gd`.
