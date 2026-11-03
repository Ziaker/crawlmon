# D-049 — Impacto de K.O.: Lançamento Balístico do Inimigo, Shake Épico e VFX de Derrota

- **Data:** 2026-11-03
- **Área:** Combate / Visual / Game Feel / Câmera
- **Origem:** Conversa

## O que o criador disse (literal)

> "veja no gdd o documento que fala sobre hits finais lançarem o inimigo pra longe e me diga como fará isso no jogo, além disso, use suas skills novas pra criar um efeito de impacto com shake bem épico pra quando um inimigo é derrotado."
> "(Recommended) Arco Balístico Anime (Smash Bros / Fighting Game): O inimigo é arremessado para cima e para trás em parábola balística com leve rotação/spin, deixando rastro de fumaça e caindo longe do campo antes de sumir."
> "(Recommended) Trauma Shake Direcional + Micro FOV-Kick (Tremor seco e enérgico de ~0.35s com decaimento rápido na direção do golpe, acompanhado de leve soco de FOV e flash de alto contraste)."
> "(Recommended) Hit-Stop Dramático de K.O. (~0.18s): Congela o atacante no auge do golpe e o alvo deformado por 180ms com pico de brilho antes de soltar a explosão e o arremesso para trás."
> "(Recommended) Pacote Completo Anime de K.O.: Anel de choque expansivo (shockwave) + explosão de faíscas + rastro de fumaça cinemática durante o voo + nuvem de impacto no pouso final com dissolução."

## Decisão

1. **Gatilho de Execução:**
   - Disparado exclusivamente quando um inimigo sofre dano fatal (`hp == 0` após o impacto de um ataque ou projétil).
   - Inimigos derrotados não desabam mais passivamente no mesmo lugar; eles recebem o tratamento cinemático de K.O. decisivo.

2. **Hit-Stop Dramático de K.O. (~180ms):**
   - O impacto fatal congela o atacante no ápice do movimento e o alvo em deformação de squash por ~0.18s com pico de flash cinemático antes da liberação do movimento.

3. **Lançamento Balístico do Inimigo (Arco Parábola 3D):**
   - Ao término do hit-stop, o modelo do inimigo é lançado na direção oposta ao impacto do golpe (vetor horizontal) somado a um impulso vertical Y, descrevendo uma trajetória parabólica balística de arremesso.
   - Durante o voo no ar, o modelo realiza leve rotação angular (spin/tumble) e emite rastro de fumaça/poeira cinemática.
   - Ao tocar o solo longe da arena de combate, emite uma nuvem de impacto e desvanece suavemente (`scale -> Vector3.ZERO` com alpha fade).

4. **Screen Shake e Resposta de Câmera (Game Feel Épico):**
   - **Trauma Shake Direcional:** Tremor na direção do vetor do golpe com decaimento exponencial rápido (`~0.35s` de duração, frequência alta, retorno suave à posição normal).
   - **Micro FOV-Kick:** Um leve recuo/soco de FOV (~3-5 graus) no impacto, recuperando com interpolação elástica (sem desorientação visual).
   - **Flash de Alto Contraste:** Pulso sutil no pós-processamento da câmera destacando o momento do nocaute.
   - *Nota de compatibilidade:* D-020 proibia tremores constantes e aleatórios na câmera comum; esta decisão autoriza expressamente o Screen Shake cinematográfico exclusivo do golpe final de K.O.

5. **Camadas Visuais (VFX):**
   - Anel de choque expansivo planar (`shockwave`) no ponto do impacto fatal.
   - Explosão radial de faíscas e partículas direcionais de impacto.
   - Rastro de partículas de fumaça contínuas acompanhando o corpo do inimigo durante o voo balístico.
   - Nuvem de poeira e impacto no ponto de aterrissagem final.

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma (todas as ramificações alinhadas via /grill-me).

## Estado no código

Implementado e validado por testes automatizados (`tests/battle/test_d049_ko_launch.gd`).
