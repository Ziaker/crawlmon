# D-1129 — Interrupção: câmera lenta breve, shake e limite de 6 s para multi-alvo

- **Data:** 2026-11-10.
- **Área:** Combate / Câmera / Game Feel / Tempo.
- **Origem:** Conversa.
- **Status:** regra registrada; implementado e testado headless; aguardando teste in-game.

## O que o criador disse (literal)

> "Faça com que interrupções causem uma breve camera lenta (se ocorrer com muitos alvos, faça só acontecer uma vez a cada 6 segundos) também causar um shaking na camera e etc"

Respostas às perguntas da rodada:

- **Quais interrupções:** "Todas as interrupções reais (Recomendado)" — hit que cancela wind-up/trajeto, War Cry e interrupção por status. **Evade fica fora** (D-104/D-106: Evade é golpe errado, não interrupção) e mantém a câmera lenta própria de 2 s (D-027/D-047).
- **Câmera lenta:** "0,35x por 0,45 s (Recomendado)".
- **Limite de 6 s:** "Só multi-alvo tem cooldown".
- **Shake:** "Só onde ainda não há shake (Recomendado)".
- **"E etc":** "Nada além disso (Recomendado)" — só câmera lenta e shake; sem speed lines, tinta de impacto ou hit-stop extra.

## Decisão

1. **Gatilho:** toda interrupção real de ação dispara o efeito:
   - hit que cancela o wind-up ou o trajeto de quem ia agir;
   - War Cry e qualquer cancelamento de wind-up sem dano;
   - interrupção causada por status.
   Evade não dispara e não é contado.
2. **Câmera lenta:** o jogo inteiro desacelera para **0,35×** por **0,45 s em tempo real** e volta suavemente a **1,0×** em **0,12 s** reais. Vale para lógica e animações juntas (D-019), como a câmera lenta do Evade e dos menus.
3. **Multi-alvo:** quando **2 ou mais alvos** são interrompidos na mesma resolução (mesmo quadro), o efeito acontece **uma única vez** para o grupo. Depois disso, novos eventos multi-alvo ficam bloqueados por **6 s**.
4. **Alvo único:** interrupção de um só alvo dispara sempre, inclusive durante o cooldown de multi-alvo.
5. **Shake:** interrupções que **já têm** hit shake (D-157) não ganham outro shake; o hit que interrompe continua usando o shake normal, sem dobrar. War Cry/status, que não tinham shake, ganham **um** shake de interrupção com trauma **0,35** (`hit_shake`), na direção lançador→alvo interrompido.
6. **Nada além:** sem speed lines, sem tinta/pós-processamento de impacto e sem hit-stop extra. O hit-stop normal de D-1012 continua, apenas desacelerado junto com o relógio global.
7. **Sem empilhar:** o efeito não começa se outra câmera lenta (menu/Evade) já estiver ativa e não reinicia enquanto ele mesmo está ativo. Nesse caso, a interrupção não consome o cooldown de 6 s.
8. **Simetria (D-235):** vale para qualquer personagem, time, lado e vista; a direção do shake vem das posições reais do lançador e do alvo.

## Ambiguidades em aberto

- **"Mesma resolução":** interpretado como o mesmo quadro de jogo. No AoE e no War Cry, todos os `apply_hit`/cancelamentos acontecem no mesmo quadro, então contam como um evento multi-alvo. Se o criador quiser outra janela (por exemplo, toda a duração de uma onda AoE), é ajuste novo.
- **Duração real:** 0,45 s + 0,12 s de volta são os valores escolhidos nesta rodada; o criador ainda pode pedir ajuste depois do teste in-game.

## Relação com decisões existentes

- **D-019:** um só relógio; a câmera lenta usa `Engine.time_scale` e afeta lógica e animações juntas.
- **D-047/D-162:** a câmera lenta de decisão dos menus continua com seus valores; esta decisão não os altera.
- **D-049/D-157:** shakes de K.O. e de acerto continuam; o shake de interrupção só cobre o que não tinha shake.
- **D-104/D-106:** Evade não é interrupção e fica fora.
- **D-1060:** nenhum movimento de câmera novo que obstrua a visão; o shake existente é preservado.
- **D-1102/D-1104/D-1105:** o War Cry e os interrupts sem dano continuam com seus avisos e reações; esta decisão só acrescenta tempo e shake.
- **D-235:** simetria total.
- **D-1042/D-1044:** a suíte de debug e os cenários de interrupção devem ser usados para o teste.

## Estado no código

Em implementação (2026-11-10):

- `scripts/combat/battle.gd`: novo sinal `windup_interrupted(actor, source)` para o War Cry/status e `windup_hit_interrupted(actor, source)` para o hit que cancela o wind-up; o `action_interrupted` e o `attack_interrupted` existentes continuam.
- `scripts/combat/battle_scene.gd`: agrupamento por quadro, cooldown de 6 s só para multi-alvo, câmera lenta global de 0,35×/0,45 s e shake de 0,35 do War Cry.
- `scripts/combat/battle_camera.gd`: reutiliza `hit_shake` (D-157); nenhuma mudança de enquadramento.
- Teste: `tests/battle/test_d1129_interruption_feel.gd` — **passa** (multi-alvo, cooldown, alvo único, hit sem shake duplicado e simetria normal/espelhada).
- Verificado também: `test_d047_decision_slowmo.gd` e `test_d157_hitshake_and_launch.gd` continuam passando.
- **Não verificado:** vídeo in-game das duas vistas, sensação final dos valores (0,35×/0,45 s) e interrupção de um Move de status em combate real.
