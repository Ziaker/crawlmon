# D-239 — HUD do Burn no jogo (fundo do cartão chamuscado)

- **Data:** 2026-11-05
- **Área:** HUD / combate
- **Origem:** Conversa. Depois das regras do Burn (D-238), o criador respondeu à pergunta "HUD do Burn" (colocar o visual aprovado na D-237 no jogo).

## Decisão

Implementar no HUD real (`scripts/ui/battle_hud.gd`) o visual aprovado na D-237, para o cartão do jogador, o do aliado e a etiqueta do inimigo, enquanto o personagem estiver queimando (`Combatant.is_burning()`):

1. **Fundo** do cartão (branco do jogador, azul/roxo do aliado, escuro/claro do inimigo) vira laranja escuro em degradê que pulsa, com borda chamuscada (carbonizada com linha de brasa), fogo lambendo de baixo, halo quente e brasas subindo. O retrato, a placa do número de ordem e os textos (nome, HP, rótulos) passam a tons quentes/creme para manter a leitura. O fogo é desenhado **antes** do texto e das células de ATB: nada é coberto.
2. **Barra de vida mantém as cores originais.** Mostra o trecho hachurado do dano que ainda vai chegar (ticks restantes × 2 HP), um clarão curto no tick e o "-2" ao lado do texto de HP.
3. **Etiqueta** "🔥 BURN x.xs" no mesmo estilo das outras (STUN, CEGO etc.), com o tempo restante.
4. A transição entra/sai em ~0,35 s (a cor original volta quando o Burn acaba ou o personagem morre).

## Ajustes pedidos pelo criador depois do primeiro vídeo (2026-11-05)

- "não é necessário ter fogo no modelo 3D": o fogo/contorno no modelo 3D **não será feito**.
- "eu só mudaria a posição do bloquinho do burn": escolha expressa **"Ao lado do nome"**. O bloquinho "🔥 BURN x.xs" fica ao lado do nome do personagem (nos cartões); na etiqueta do inimigo, estreita, vai compacto ("🔥 x.xs"). Enquanto ele aparece, o rótulo "JOGADOR / ALIADO · IA" sobe um pouco para não colidir.
- Números de dano do Burn (escolha expressa **"Só no cartão"**): "saíssem números de dano … como se elas tivessem pulando". Primeiro pediu em vermelho e pequenos; depois corrigiu: "o texto tem que ter a fonte e o tamanho do texto normal de dano, só que laranja ao invés de branco". Aplicado: **a mesma fonte, tamanho (62), contorno, sombra e entrada do número de dano normal** (`_draw_pops`), **laranja**, saindo da barra de vida e pulando (dois quiques) para cima e para fora do cartão; um por tick. O "-2" ao lado do texto de HP foi removido. Como o tamanho é o do número normal, ele passa por cima da linha de título do cartão por um instante.

## Limites e escolhas do agente (não decididas pelo criador)

- O HUD **não** usa o Motion Composer: ele é isolado do combate (D-230, D-233) e integrá-lo ao jogo não foi autorizado. A animação é feita no próprio HUD (senos determinísticos, sem aleatoriedade), parecida com o vídeo da D-237.
- Fica fora desta entrega: contorno e chamas no modelo 3D do personagem queimando, e a tela de Status (`status_panel.gd`).
- Fire Bullet continua sendo o único Move que aplica Burn.

## Estado

Implementado e visto rodando na sala de VFX (inimigo, aliado e jogador). Sem commit.
