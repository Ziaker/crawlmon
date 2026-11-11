# D-1025 — Tidal Surge será do Slime; mecânicas antes do VFX

- **Data:** 2026-11-09.
- **Área:** Combate / VFX / Slime / Biblioteca de projéteis.
- **Origem:** resposta do criador depois da entrega da fase Start do Tidal Surge (D-1021).
- **Estado:** direção registrada; **mecânicas ainda não definidas**; a fase Start fica **em espera, não aprovada**; nenhuma fase nova começa até a ficha mecânica existir.

## Frase literal do criador

> usaremos o slime para esse move, será dele, primeiro vamos definir as mecânicas.

## Decisão

1. O Move **Tidal Surge** será do **Slime**; o Slime é o dono/primeiro usuário.
2. As **mecânicas vêm antes** de continuar o VFX. O Start entregue em `test_captures/tidal_surge_start_v5.mp4` fica em espera e **não está aprovado**; Wind-up, Release, Trajectory, Impact e Post-impact não começam até a ficha mecânica ser fechada.
3. A **D-235 continua**: o Move é identificado por `move_id` e continua utilizável por qualquer personagem. “Será dele” = o Slime é o dono, **não** uma exclusividade, salvo decisão expressa em contrário (perguntar antes).
4. Nada de código novo de combate ou VFX por esta decisão; ela só registra a direção e as perguntas.

## Contexto do Slime no código atual

- **DQT Slime:** `Combatant.new("Slime", 34, 9, 0.55, is_player)`, espécie `dqt_slime`, fraqueza **Fire**, **20 MP** no grupo DQT (`scripts/combat/dqt_test_party.gd`).
- **Skills atuais:** Tackle (Physical melee), **Bubble Shot** (Water projectile, 1.3 de poder, 2 ATB, 3 MP, wind-up 1,1 s), Heal (Light status) e **Electric Beam** (Electric projectile, 1.0, 2 ATB, 6 MP).
- **Bubble Shot** já é o projétil de Water do Slime. Tidal Surge **sobrepõe** esse nicho; é preciso decidir se substitui o Bubble Shot, convive com ele no quarto slot ou é a assinatura do Slime.
- O Slime **não tem mão**: o VFX mede o corpo real. O Start foi feito com o Abra; quando a ficha fechar, o primeiro vídeo do Slime precisa testar o corpo dele (D-235).

## Respostas do criador (2026-11-09)

> Dano + ricochete

> refaremos o bubble shot do zero por sinal após finalizar este, convive com bubble shot

> Dono, mas genérico

**Decisão parcial:**

1. **Efeito:** dano de Water no alvo principal e **ricochete** para outro inimigo com dano reduzido (o outro lado da W da Nami). Não é cura.
2. **Slot:** o Tidal Surge **convive** com o Bubble Shot no kit do Slime. O Bubble Shot **será refeito do zero depois** que o Tidal Surge terminar; agora ele não muda.
3. **Dono:** o Slime é o dono/primeiro usuário, mas o Move continua **genérico** (D-235 preservada).
4. **Saltos:** até **2** saltos (alvo principal + 2), conforme os inimigos vivos. Com um só inimigo, é um golpe único.
5. **Dano:** **100% / 75% / 50%** no principal, no 1º salto e no 2º salto.
6. **Custo e ficha:** **2 ATB + 5 MP**, wind-up **0,8 s**, **long range**, elemento **Water**, tipo **mágico**.
7. **Alvo do salto:** o **inimigo vivo mais próximo**, **esquivável**; o salto **não dá ATB/Burst extra**.
8. **Poder base:** **1.0 (100%)**; o principal causa 100%, o 1º salto 75% e o 2º salto 50% desse poder.
9. **Salto esquivado:** **para a corrente**; não continua para o próximo inimigo.
10. **Alcance do salto:** **qualquer inimigo vivo**, sem limite de distância.
11. **Viagem do salto:** **0,3 s** no 1º salto e **0,6 s** no 2º salto.
12. **“Mais próximo”:** medido do **último alvo atingido** (o 1º salto sai do alvo principal; o 2º sai do 1º alvo do salto).
13. **Salto é golpe normal:** cada salto rola **fraqueza, crítico e evasão** (manual e automática) como qualquer golpe; o dano cai para 75%/50%.
14. **Alvo principal esquivado:** **não há salto**; o Move termina no erro.
15. **Sequência:** o 2º salto só sai **depois** que o 1º salto bate; a corrente espera cada impacto. Viagens: 0,3 s no 1º salto e 0,6 s no 2º.
16. **Morte antes do acerto:** se o alvo morrer **antes** de o jato chegar, o salto não acontece e a corrente para.
17. **Morte pelo próprio Move:** se o alvo morrer **em decorrência deste Move**, a corrente **continua** e ainda salta para o próximo inimigo vivo.
18. **Um alvo só:** não há salto; o Move é um golpe único.

## Ficha proposta (aguardando aprovação)

> **Tidal Surge** — Water, magical projectile, long range. Custa **2 ATB + 5 MP**, wind-up **0,8 s**, poder **1,0**. O Slime dispara um jato contínuo em um inimigo e causa **100% de dano mágico de Water** no contato. Se o golpe acerta e há outro inimigo vivo, o jato **ricocheteia** para o inimigo vivo mais próximo do último alvo atingido, causando **75%** do dano depois de **0,3 s**; se esse salto acerta, ricocheteia mais uma vez para o próximo inimigo vivo mais próximo, causando **50%** do dano depois de **0,6 s**. Cada salto é um golpe normal, com fraqueza, crítico e evasão manual e automática; se um salto for esquivado, a corrente para. Se o alvo morrer antes de o jato chegar, a corrente para; se morrer em decorrência deste Move, a corrente continua. Cada inimigo é atingido uma vez, com no máximo dois saltos; com um só inimigo vivo não há salto. Os saltos não concedem ATB nem Burst extra: a corrente inteira é um único Move de 2 ATB + 5 MP.

## O que falta

1. **Aprovação da ficha** acima antes de implementar.
2. **Implementação do combate:** a corrente de saltos não existe hoje; o combate tem um alvo por `Incoming` e a D-007/D-009 (múltiplos alvos) ainda não está implementada. É uma mecânica nova, com evasão por salto, morte antes/depois do acerto e recompensa única.
3. **Visual:** depois da mecânica, retomar o VFX; o Start precisa ser re-testado no corpo do Slime e os saltos precisam de um jato que sai do último alvo, não do Slime.
4. **Bubble Shot:** refazer do zero **depois** que o Tidal Surge terminar; agora não muda.

## Relações

D-1021 (Tidal Surge, seis fases e Start em espera), D-955/D-956 (biblioteca de projéteis), D-235 (independência de personagem), D-019 (tempo do combate), D-977 (formato de ficha do Electric), D-061 (registro).

## Implementação da mecânica (2026-11-09)

- **Corrente de saltos:** `Battle._spawn_tidal_bounce` e `Battle._nearest_tidal_foe`; `Incoming` ganhou `bounce_root`, `bounce_index`, `bounce_from_target`, `bounce_no_reward` e `bounce_targets`.
- **Regras:** o salto é um `Incoming` próprio, sem custo de ATB/MP, com viagem de 0,3 s (1º) e 0,6 s (2º), `impact_phase = TRAVEL` (janela de Evade na última 0,25 s), evasão manual/automática e dano 75%/50%. O `_hit` recebe `no_gain`/`bounce`; o `_strike` só cria o próximo salto se o anterior acertou; morte antes do acerto para a corrente, morte pelo golpe continua; o alvo é o inimigo vivo mais próximo do último alvo, sem repetir ninguém.
- **Ficha:** `Skill` com poder 1.0, 2 ATB, 5 MP, wind-up 0,8 s, Water, projétil, long range; textos em `skill.gd`; **Tidal Surge entra no kit do Slime DQT**.
- **VFX:** o Start continua no código, mas **em espera e não aprovado**. O salto não é desenhado ainda: `fx_projectiles`/`fx_impacts` ignoram o salto para não criar uma nova carga nem marcar o feixe principal; o jato de salto é trabalho da fase de VFX.
- **Teste:** `tests/battle/test_d1025_tidal_surge.gd` — **28/28 PASS**: 3 inimigos, 1 inimigo, Evade no principal, Evade manual no salto, morte antes/depois do acerto, ordem do mais próximo, 100/75/50, 0,3/0,6 s, sem ATB/Burst extra.
- **Regressões rodadas:** `test_d032_mechanics` imprime PASS (com acessos `incoming[0]` fora do array, fragilidade do próprio teste); `test_d977_electric_beam` falha porque espera **8 MP** e o código tem **6 MP** desde D-438 (-30%) — divergência anterior, não corrigida; `test_d282_prison`, `test_d238_burn` e `test_d1007_ai_dodge` falham em caminhos de Evade/interrupção/IA que **não passam pelo branch do Tidal Surge** — não corrigidos, precisam de decisão à parte.
- **Correção de integração (2026-11-09):** o `attack_resolved` do salto chamava `FxTelegraph.resolve_attack`, que **replanejava** o salto e mexia na câmera como um ataque novo; o travamento do DQT com Tidal Surge vinha daí. O `resolve_attack` agora **ignora** `inc.bounce_root != null`. O run DQT de 1 inimigo completou; um run com 2+ inimigos (para o salto real) ainda não foi reproduzido porque o encontro DQT é aleatório.
- **Não verificado:** o salto desenhado na sala real com 2+ inimigos, o desenho dos saltos, o Start no corpo do Slime (a carga está 3,19 m à frente, mas o corpo largo a oculta; proposta de subir para o topo da frente em D-1021, aguardando aprovação), outros atacantes e desempenho.

## Tidal Surge finalizado; Bubble Shot liberado (2026-11-11)

Frase literal do criador:

> o tidal surge ta finalizado ja
>
> ainda tem que redefinir as mecanicas do bubble shot

- O criador declara o Tidal Surge **finalizado**. A condição do item 2 da decisão parcial ("refeito do zero depois que o Tidal Surge terminar") está cumprida: o **Bubble Shot pode ser refeito**.
- A ordem é a mesma do Tidal Surge: **mecânica primeiro**, VFX depois. As mecânicas novas do Bubble Shot **ainda não foram definidas**; propostas em rodada na conversa, nada aprovado.
- Esta nota **não** altera código, VFX nem a ficha do Tidal Surge. O texto abaixo ("VFX em espera") é o registro anterior do código e não foi reverificado nesta data.

## Estado no código

**Mecânica do Tidal Surge implementada e testada; VFX em espera.** A fase Start continua no código, mas **não aprovada**; os saltos ainda não são desenhados. Nada commitado ou publicado (D-022).
