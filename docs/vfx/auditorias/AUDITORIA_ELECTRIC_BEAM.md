# Auditoria completa — Electric Beam (biblioteca de projéteis, elemento Electric)

- **Data:** 2026-11-08.
- **Escopo:** todo o ciclo do move, da pesquisa (D-955) até o visual aprovado (D-976), a mecânica (D-977) e os efeitos ligados a ele (impacto alternativo com STUN, D-978; visual do STUN, D-979/D-980).
- **Objetivo:** servir de aprendizado para os próximos moves da biblioteca. É uma auditoria: aponta problemas e lições, **não muda código nem regra**.
- **Pedido literal:** "voltaremos ao move que criamos para vc o auditoriar por completo para servir de aprendizado para os próximos moves, leve em conta todo o contexto da conversa sobre o mesmo".

---

## 1. Resumo

O move chegou a um resultado aprovado pelo criador ("eu considero esse move perfeitamente feito visualmente"), mas o caminho custou **mais de 20 versões de vídeo** (v1 a v23) e várias voltas que poderiam ter sido evitadas. As causas se repetem:

1. **Leitura literal de palavras visuais** ("pilar", "leque", "escalonar") sem conferir a referência antes de construir.
2. **Mudanças imperceptíveis** entregues como mudança (escalonamento de 0,09 s).
3. **Ferramenta de gravação frágil**, que travou ou mirou errado (MP 0, alvo por índice fixo).
4. **Tamanho fixo em metros** (D-308) sem plano para a vista distante (~37 m): pedidos repetidos de "não dá pra ver".
5. **Dívida técnica** deixada para trás: constantes mortas, três buscas diferentes de "modelo mais próximo", o Motion Composer construído e desligado.

O que funcionou bem: decisões registradas antes do código (D-955 a D-985), vídeo das duas vistas a cada entrega, perguntas fechadas nos pontos ambíguos (tamanho "25%", duração "35%"), e conferir a referência quadro a quadro quando o criador pediu (Zio, P5R).

---

## 2. Linha do tempo (o que foi pedido e o que deu errado)

| Fase | Pedido do criador | O que aconteceu | Lição |
|---|---|---|---|
| Pesquisa (D-955) | Referências de jogos recentes, LoL, P5, SMT V | Primeira rodada com vídeos velhos e prints ruins; o criador pediu foco em jogos recentes | Planejar a pesquisa por fonte e por fase antes de capturar |
| Wind-up (D-958, D-960, D-963–D-965) | "criar na frente do personagem" | Carga nasceu **dentro** do corpo; depois **de lado** (deslocamento lateral pela câmera); só na terceira tentativa ficou à frente no eixo | Derivar a posição do corpo real no eixo atacante→alvo e conferir em **ângulos de câmera extras** antes de entregar |
| Cores e leitura (D-960–D-967) | "difícil de ver", "mais claro", "o que é esse overlay mostarda?" | Várias rodadas de cor; um halo translúcido virou "mostarda"; borda escura deixou raios cinza de longe | Testar cor em quadro **real**, na **vista distante**, antes de propor; nunca adicionar camada translúcida sem checar como ela soma |
| Release (D-959, D-968, D-974) | Coroa, estouro de 0,2 s, esfera que cresce e pulsa | Funcionou bem quando o pedido tinha número (0,2 s; 0,6 s; 2× até 1,4 m) | Quando houver número, seguir; quando não houver, perguntar o número |
| Flipbooks (D-969) | "o que adicionaria com flipbook?" | Faíscas do Composer desligadas sem o criador conseguir ver a diferença | Não trocar uma camada por outra sem mostrar as duas lado a lado |
| Impacto (D-970–D-975) | "pilar de choque" | Primeiro: raios girando como pós-impacto. Depois: **cilindro amarelo sólido** ("retângulo"). Só depois de ver o Zio e perguntar: coroas de raios | Antes de construir, **descrever em uma frase o que vai aparecer** e confirmar; palavras como "pilar" têm várias leituras |
| Escalonamento (D-971) | "1 e 4" (cabeça e impacto escalonado) | 0,03–0,09 s: o criador disse "não parece que nada mudou" | Uma mudança precisa ser **perceptível a 30 fps** (≥ 3–4 quadros) ou não é entrega |
| Tamanho no alvo (D-974) | "grande demais pro Gible, parece acertar o aliado" | Medidas fixas em metros não levavam em conta o tamanho do alvo | Efeito no alvo deve ser **proporcional ao corpo do alvo** desde o início |
| Mecânica (D-977) | Ficha, 8 MP, STUN 20% + LUK | Implementado com teste estatístico; ficha teve redundância ("não faz X") e lista onde era parágrafo | Fichas: não descrever o que o move não faz; seguir o formato pedido |
| Slime (D-978 contexto) | "dê o move pro slime" e vídeo | Gravação travou 10 min (Slime DQT com 0 MP); depois mirou num **aliado** (alvo por índice fixo) | Ferramenta de vídeo deve **falhar rápido** e escolher alvo pelo lado, nunca por índice |

---

## 3. Conformidade com as decisões obrigatórias

| Regra | Situação | Observação |
|---|---|---|
| **D-235 / AGENTS §7** (independente de personagem e lado) | **Parcial** | Nada usa nome, espécie ou `is_player`. Testado com Abra e Slime como atacantes, nos dois lados. **Não testado**: atacante grande, alvo grande, vários alvos reais. As três buscas por "modelo mais próximo" (seção 4.2) podem pegar o modelo errado com corpos próximos. |
| **D-308** (sobre o Motion Composer) | **Resolvido por D-1030** | O Composer V1.11 ganhou o preset `electric_beam_effect`, mas o efeito final **não desenha nada com ele** (`USE_COMPOSER_SPARKS = false`). Isso deixou de ser violação: D-1030 torna o Composer **auxiliar e opcional**; D-954 já permitia o principal à mão. O preset e o painter sem uso continuam dívida técnica, não regra. |
| **D-956** (seis fases) | **Ok, com ressalva** | Start, Wind-up, Release, Trajeto, Impacto existem. Pós-impacto virou "resolução do impacto" por decisão do criador (D-973); a classe base ainda tem `POST_LEN` próprio, o que é confuso. |
| **D-957** (sem Glow) | **Ok** | Brilho falso por sprites aditivos. |
| **D-019** (efeito não mexe no tempo do combate) | **Ok** | O efeito só lê os tempos. A pausa/tremor de impacto foi proposta e não feita. |
| **Vídeo das duas vistas** | **Ok** | Toda entrega teve as duas vistas. |
| **Um ajuste por vez** | **Violada algumas vezes** | Entregas com 3 mudanças juntas (ex.: v19: pilar, anel no chão e esfera), o que dificulta saber qual mudança agradou. |
| **AGENTS §2** (ambiguidade = perguntar) | **Parcial** | Perguntas boas em D-974 e D-978. Falhas: "pilar" (D-972) e "trocar faíscas" (D-969) foram decididos por conta própria. |
| **AGENTS §5** (Git) | **Ok** | Nada commitado sem pedido. |

---

## 4. Auditoria do código

Arquivos principais: `scripts/vfx/combat/projectile_lib/electric_beam_vfx.gd` (869 linhas), `projectile_lib_vfx.gd` (base), `fx_impacts.gd`, `fx_projectiles.gd`, `fx_telegraph.gd`, `battle.gd` (STUN), `skill.gd` (ficha).

### 4.1 Código morto e restos

- Constantes sem uso: `JAG`, `PILLAR_BOLTS`, `PILLAR_SIDE`, `COL_SLAM`, `COL_HOLD`, `COL_BREAK` (sobras do cilindro da D-972, que foi substituído).
- `_cyl_node()` e `_circle()` só existiam para o cilindro e os anéis grossos que saíram.
- `USE_COMPOSER_SPARKS = false` com o `MotionPainter` e o `MotionEffect` ainda criados a cada disparo: custo sem efeito.
- Comentários de constantes com duas decisões coladas ("D-968 ... D-965 ..."), o que dificulta ler qual vale.

### 4.2 Fragilidades

1. **Três buscas diferentes de "modelo mais próximo"**: `front_of()` (atacante, raio 3 m), `body_of()` (alvo, raio 3 m) e `_hit_flash()` (alvo, raio 4 m). O combate **sabe** quem é o atacante e o alvo; o efeito adivinha pela posição. Com dois corpos a menos de 3 m, pode medir o corpo errado. Para os próximos moves: passar o `Combatant` (ou o modelo) ao efeito.
2. **STUN lido por efeito colateral**: `set_stun()` depende de `fx.last_hit_info` ter sido gravado antes de `_impact()` no mesmo quadro. Funciona hoje, mas uma mudança de ordem quebra o impacto alternativo sem erro.
3. **Pilar em malha compartilhada**: o rastro, o anel no chão e o pilar são desenhados na mesma `ImmediateMesh`; a opacidade gradual sem STUN apaga os três juntos (efeito colateral registrado na entrega v23).
4. **Tempos do combate não decididos para este move**: a carga segurada de 0,8 s e a viagem de 0,63 s vêm do plano genérico de projéteis. O visual foi afinado em cima desses números; se a mecânica mudar os tempos, o visual precisa ser revisto.
5. **Vários alvos**: o efeito suporta (um feixe por alvo), mas o combate só tem um alvo (conflito com D-007/D-009). Os índices de feixe por alvo nunca rodaram numa batalha real.

### 4.3 Custo

- A cada quadro, as `ImmediateMesh` (feixe, arcos, coroa, estouro, rastro e pilar) são **refeitas do zero**.
- Por alvo: ~38 nós de flipbook (anel, estrela, 10 faíscas de impacto, 12 de rastro, 14 laterais), cada um com material próprio, mais 6 do wind-up. Com 3 alvos, mais de 120 nós com material único.
- **Nunca medido**: tempo de GPU, overdraw, quadros por segundo. A skill de VFX pede essa medição (driver Vulkan).

### 4.4 Testes

- `tests/vfx/projectile_lib/test_contract.gd`: ordem das fases, um feixe por alvo, vida do nó. **Alterado** em D-973 para aceitar que o nó viva até o pilar acabar.
- `tests/motion_composer/test_v111_electric.gd`: testa o preset do Composer que o efeito final não usa.
- `tests/battle/test_d977_electric_beam.gd`: 8 MP, STUN com LUK +100/−100 e ~20% (400/2000).
- **Faltam**: Evade/erro no meio do voo em combate; morte do alvo no meio do voo; vários alvos; teste do impacto alternativo (com e sem STUN) ligado ao combate.

### 4.5 Ferramentas de debug criadas no caminho

Sala de VFX (`vfx_room.gd`): `--clean`, `--cam`, `--stun=always|never`, `--target=opponent`, MP completado até 20 antes do disparo, cenários "Status", painel "STATUS EM VÁRIOS", linha `[vfx_room]` no terminal. São úteis, mas o **completar MP** esconde um problema real: o Slime do grupo DQT tem 0 MP fora da sala.

---

## 5. Problemas em aberto

1. Slime aliado do grupo DQT com **0 MP** em batalha `--dqt`: não paga o Electric Beam (8 MP) nem o Bubble Shot (5 MP).
2. Vista normal com o alvo a ~37 m: pilar, anel, estrelas e texto ficam pequenos. A regra de metros fixos (D-308) e o pedido de legibilidade estão em tensão; falta uma decisão (ex.: a câmera de impacto enquadrar o contato, ou escala mínima na tela).
3. **Resolvido por D-1030:** o Composer é auxiliar; o secundário pode ficar à mão. Não é mais uma decisão pendente.
4. Tempos do move (carga segurada e viagem) a decidir na mecânica.
5. Vários alvos no combate (D-007/D-009).
6. Sincronia visual × mecânica: o criador disse que faria "depois de finalizar a parte mecânica".

---

## 6. Lições para os próximos moves (checklist)

**Antes de construir**
1. Ler a referência quadro a quadro **antes** da primeira versão, e descrever ao criador, em uma frase por fase, o que vai aparecer.
2. Para palavras com mais de uma leitura visual ("pilar", "leque", "onda", "explosão"), perguntar com opções desenhadas em texto.
3. Definir desde o início: posição da carga (à frente, no eixo), tamanho proporcional ao **corpo do alvo** no impacto, e como o efeito se lê a ~37 m.
4. Pedir números quando faltarem (duração, tamanho, quantidade).

**Ao construir**
5. Receber atacante e alvo do combate; nunca adivinhar pelo "modelo mais próximo".
6. Se usar o Motion Composer no secundário, registrar; se não usar, o caminho à mão é válido (D-1030).
7. Uma mudança visível por entrega (≥ 3–4 quadros a 30 fps).
8. Remover o que foi substituído na mesma entrega (constantes, funções, nós).

**Ao entregar**
9. Gravar sempre normal + espelhado, com HUD e cenário limpos quando o pedido for visual.
10. Conferir quadros em tamanho real nas duas vistas, procurando também o que **não** deveria aparecer.
11. A ferramenta de vídeo deve falhar em segundos (checagem de 1 s antes de gravar), escolher alvo pelo lado e avisar se o combate recusou o golpe.
12. Testar com: outro atacante, lado espelhado, alvo pequeno e grande, Evade, morte no meio do voo.
13. Medir custo (GPU, overdraw) pelo menos uma vez antes de dar o move por pronto.
14. Dizer sempre o que não foi verificado.

---

## 7. Mapa das decisões do move

D-955 (biblioteca), D-956 (fases), D-957 (Electric, Zeri), D-958 (carga à frente), D-959 (coroa, estouro, log removido), D-960 a D-968 (posição, cores, zigue-zague, brilho, esfera), D-969 (flipbooks), D-970 (pilar e rastro), D-971 (cabeça, escalonamento), D-972 (cilindro — corrigido), D-973 (coroas no impacto), D-974 (proporcional, anel no chão, esfera pulsa), D-975 (sai do inimigo; anel do fim do wind-up removido), D-976 (visual aprovado), D-977 (ficha, 8 MP, STUN), D-978 (impacto alternativo com STUN), D-979/D-980 (visual do STUN).
