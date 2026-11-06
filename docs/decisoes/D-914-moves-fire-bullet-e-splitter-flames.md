# D-914 — Moves de Fogo: Fire Bullet e Splitter Flames (fichas, escopo visual)

> **Renumerada em 2026-11-06:** D-236 → D-914. O ID D-236 já pertence a outra decisão no `origin/main`; o conteúdo local foi preservado com o novo ID.


- **Data:** 2026-11-04
- **Área:** Combate (dados de Move) / Visual / VFX
- **Origem:** Conversa. O criador colou as duas fichas (em pt-BR, preparadas fora do repositório) e pediu: "Crie estes 2 moves usando suas skills e capacidades com shaders do Godot". As fichas **não** são a frase literal do criador; são o texto que ele colou.

## As fichas (resumo fiel do que foi colado)

### Fire Bullet
Fire · Magical · Projectile · Single Target. MP 10 · ATB 2 · Cast 0,50 s · Voo-base 0,30 s.
Em combate: bala de fogo, `10 + MAG` de dano mágico; se o impacto **interromper uma ação do alvo**, aplica **Burn por 4 s, 2 de dano por segundo**.
Visual:
- **Windup:** mão feita só de fogo (independente da anatomia do usuário), em gesto de arma apontada (👉).
- **Release:** bala flamejante pequena em alta velocidade + **três anéis de fogo** que acompanham a bala e, nos primeiros **0,25 s** do trajeto, desaceleram enquanto se expandem. Rastro de fogo; as chamas residuais viram cinzas.
- **Impacto normal:** pequena explosão de chamas; depois a bala **ricocheteia girando em direção ao chão**, num arco lento de subida e descida, velocidade de ricochete fixa e gravidade alta.
- **Impacto especial (interrompeu a ação do alvo):** a bala **não ricocheteia**; a explosão **envolve o corpo do alvo em chamas por 0,35 s**. Esse 0,35 s é só visual e não substitui os 4 s mecânicos do Burn.

### Splitter Flames
Fire · Magical · Projectile · Single/Dual Target. MP 20 · ATB 2 · Cast 0,70 s · Voo-base pendente.
Em combate: duas bolas de fogo contra um ou dois inimigos.
- **Alvo único:** as duas bolas convergem no mesmo inimigo, `20 + MAG`, `20% + LUCK` de Burn de 4 s.
- **Dois alvos:** uma bola por inimigo, metade do dano do modo único em cada, `10% + LUCK` de Burn em cada.
- Se um alvo morre antes do disparo ou no voo, a bola dele passa a perseguir o outro alvo selecionado, se vivo; se ambos morrem, erram. (Exceção própria deste Move à regra D-109.)
Visual:
- **Windup (0,70 s):** duas esferas de fogo, uma em cada mão, crescendo até o disparo.
- **Release:** disparo simultâneo; **dois vórtices de fogo estacionários** nas origens, expandindo por **0,30 s** e sumindo suave. Cada bola faz um arco curvo (uma pela esquerda, outra pela direita).
- **Impacto, alvo único:** as trajetórias se cruzam no alvo; **explosão em forma de pilar** que se dissipa em cinzas.
- **Impacto, dois alvos:** explosão individual de chamas em cada alvo, que se dissipa em cinzas.
- Redirecionamento: a bola do alvo morto muda a trajetória para o outro alvo vivo.

## Respostas do criador nesta rodada (2026-11-04, escolhas expressas)

1. **Escopo mecânico:** "Só visual + Skill básico". Os 2 Skills são criados com o que o jogo já tem (elemento Fogo, tipo projétil, custo em ATB, windup) e os VFX completos em shaders. **MP, Burn, a fórmula `10 + MAG` / `20 + MAG` e as chances de Burn ficam para depois** (não implementados agora).
2. **Dois alvos:** "Incluir dois alvos" no Splitter Flames (seleção de até 2 inimigos, modo dual e redirecionamento quando um alvo morre).
3. **Quem usa:** "Só a sala de VFX". Nenhum personagem da party recebe os Moves ainda; eles aparecem na sala de VFX (`scenes/debug/vfx_room.tscn`) para qualquer atacante, nos dois lados (D-235).
4. **Pendências da ficha:** "Decido depois, registre como pendentes". Nada abaixo foi preenchido por mim.

## Ordens do criador durante a implementação do Fire Bullet (2026-11-04, frases do criador)

5. Visual: "eu não estou vendo fogo, apenas magma, quero estilização e um laranja amarelado notável"; a bala "devia subir ainda mais ao contato"; o anel do release "é pra ser mais faísca que fogo em um vermelho e laranja só"; "falta brilho e shaders". Aplicado: fogo estilizado em faixas amarelo‑laranja (`fire_orb`, `fire_flame`), halo dourado (`fire_glow`), anéis de faíscas vermelho/laranja (`fire_ring`) que freiam rápido em vez de acompanhar a bala, ricochete mais alto (valores provisórios).
6. Mão: "caça um modelo genérico de mão ou luva e baixa e usa com shaders". Baixado **"Low poly hands"** de Anastasiia Ku (**CC BY 3.0**, https://poly.pizza/m/cGaYRuiPCMe); o criador escolheu esse modelo e disse "preciso q seja só 4 dedos" = **4 no total (3 dedos + polegar)**, resposta expressa. Mindinho removido, médio e anelar curvados, indicador esticado e polegar para cima; em `assets/vfx/fire_hand.glb`, crédito em `assets/vfx/CREDITS_fire_hand.md` (obrigatório pela licença; ainda **não** aparece nos créditos do jogo).
7. A mão "deve rotacionar pra cima junto com o indicador ao disparar e depois sumir" (feito) e "é pra ela tá relativamente reta" (apontando direto para o alvo, sem virar para o lado da tela).
8. Sala de VFX: nova opção **"Alvo canalizando"** (e `--channel`), que faz o alvo começar um ataque de wind‑up longo antes do disparo, para ver o impacto especial de interrupção do Fire Bullet.

9. Impacto de interrupção: o envoltório de chamas "não gostei": "tem como ser um estouro em argolas com um shake? Além de empurrar visualmente o inimigo pra trás?". Perguntado qual shake, o criador respondeu "Tremor do inimigo" e depois escreveu "Hitshake". Aplicado: estouro de argolas de faíscas ao redor do alvo (substitui as chamas), **Hit Shake do jogo (D-900) forte** (o golpe conta como "pesado": câmera, hit‑stop com vibração do inimigo) e empurrão **só visual** do inimigo para trás (2,7 unidades). Nada de regra mudou; o motor só passa a informar se o golpe interrompeu uma ação (`info["interrupted"]`). Aberto: se o "shake" também deve ser mais forte que o hit shake pesado normal.

## Aplicação

- **D-235/AGENTS.md §7:** comportamento por `move_id`, nunca por personagem, time ou lado; origens das mãos/esferas derivadas do atacante real (a "mão de fogo" não depende de anatomia).
- **D-019:** o visual só desenha; o resultado (acerto, interrupção, morte do alvo) vem do motor.
- **D-109:** projétil de alvo único cujo alvo morre termina sem dano; o redirecionamento do Splitter Flames é a exceção declarada na ficha.
- **D-913 (itens 19–21):** "igual" é visual; usar flipbooks, partículas, malhas e shaders do jogo.
- Regra do criador para VFX: depois de cada mudança, abrir o jogo, mostrar funcionando e **esperar a aprovação** antes de continuar.

## Ambiguidades / pendências (não decididas; não preenchidas)

1. A ficha cita "D-229/D-230" como formato; no repositório D-230 é do Motion Composer e **D-229 não existe**.
2. Fire Bullet: instante do primeiro tick de Burn; reaplicação de Burn sobre alvo já queimando; valores numéricos do ricochete (altura, duração, gravidade, velocidade).
3. Splitter Flames: dano por alvo no modo duplo é exatamente `(20 + MAG) / 2`?; `20% + LUCK` e `10% + LUCK` usam a diferença de LUK (D-146) ou um acréscimo?; tempo-base de voo; distribuição do dano entre as duas bolas (único e redirecionado); Burn quando as duas bolas acertam o mesmo alvo após redirecionar; origem das duas esferas em personagens sem duas mãos; se "ambos os alvos morrem" prevalece sobre o retarget padrão (D-108) durante o windup.
4. **Seleção de dois alvos no menu real:** como nenhum personagem da party recebe o Move agora, a seleção de 2 alvos só é exercitável na sala de VFX; a navegação no menu de batalha fica para quando o Move for dado a um personagem (a confirmar).
5. Se o Move deve substituir ou somar-se a Fire do Tarukaja/outros: não aplicável; nenhum Move existente de Fogo é alterado.

## Estado

Registrada. Implementação em etapas, cada uma mostrada rodando antes da seguinte: (1) Fire Bullet; (2) Splitter Flames alvo único; (3) Splitter Flames dois alvos e redirecionamento.
