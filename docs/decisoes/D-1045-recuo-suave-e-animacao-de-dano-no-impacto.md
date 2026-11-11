# D-1045 — Recuo do alvo: empurrão e retorno suave; animação de dano no impacto

- **Data:** 2026-11-09
- **Área:** Combate / Animação / Game Feel
- **Origem:** Conversa
- **Estado:** **implementado e aprovado pelo criador** em 2026-11-09 (encerramento da sessão). Testado nas duas vistas e em alvos de tamanhos diferentes; ver "Estado no código".

## Frase literal do criador

> poderia investigar o caso dos personagens, ao levar hit, estarem sendo empurrados pra trás mas sendo imediatamente reposicionados depois? é pra eles serem empurrados pra trás e voltarem suavemente pro ponto que estavam visualmente. Além disso, investigue também o motivo da animação estar trocando pra animação de levar dano no PÓS-IMPACTO ao invés do IMPACTO em sí de um ataque que leva.

## Respostas do criador (2026-11-09)

> 1 - a opção melhor para o game feeling
> 2 -ao invés de congelado, um slow motion sutil rápido
> 3 - no impacto
> 4 sim

## Decisão (pedido do criador + respostas)

1. **Recuo visual:** todo hit recebido empurra o alvo para trás e o traz de volta **suavemente** ao ponto em que ele estava **visualmente**, sem reposicionamento imediato/seco. O recuo continua sendo só de apresentação: a posição lógica não muda (D-019, D-045, D-055).
2. **Animação de dano:** o clipe de levar dano (`damage`) começa **no impacto**, não no pós-impacto. Em vez de ficar congelado no primeiro quadro, roda em **slow motion sutil e rápido** durante o hit-stop e volta ao normal depois.
3. **Empurrão:** começa **no impacto** (não na saída do hit-stop). Isto altera o item 5 da D-1012.
4. **Ponto de retorno (escolha do assistente, delegada em "a opção melhor para o game feeling"):** o alvo volta ao **ponto desenhado no primeiro hit da sequência**, não ao `home` lógico. Assim ele não termina atrás de onde o jogador o viu e depois desliza para frente. Hits consecutivos mantêm esse ponto como âncora e acumulam o recuo (D-055).


## Achados da investigação (sem alterar o jogo)

1. **Reposicionamento imediato — dois tweens disputando a mesma posição do alvo:**
   - `scripts/combat/fx/fx_motion.gd`, `_hit_stop()` (linhas ~622–630): ao sair do hit-stop, empurra o alvo e cria um tween próprio com `mt.create_tween()` — esse tween **não** fica registrado em `BattleFx._tweens`.
   - `scripts/combat/fx/fx_motion.gd`, `knock()` (linhas ~762–782): cria outro tween em `fx._move(target)`, que só mata o tween registrado em `_tweens`; não mata o tween do `_hit_stop`.
   - Resultado medido no combate real (Gible levando Tackle): o alvo vai a um deslocamento de (+0,426, −1,148) em impacto+0,234 s e **salta para (+0,049, +0,197) no quadro seguinte** (impacto+0,248 s), antes de terminar de voltar. É o "reposicionamento imediato" relatado.
   - O empurrão do `_hit_stop` também é redundante com o `knock()`: os dois fazem o mesmo recuo visual ao mesmo tempo.
2. **Animação de dano no pós-impacto:**
   - `scripts/combat/battle_fx.gd`, `play_hit()`: o código faz `await _hit_stop(...)` (linha ~396) e só **depois** chama `knock()` e `_hit_react()` (linhas ~403–406).
   - `_hit_stop()` congela todos os `AnimationPlayer` (`speed_scale = 0`) durante 0,06–0,20 s.
   - Resultado medido: durante o impacto o alvo fica **congelado no `battle_idle`** (impacto+0,003 s a +0,123 s); o clipe `damage` só começa em **impacto+0,127 s**, quando o hit-stop termina. É exatamente o "troca no pós-impacto" relatado.

## Escolhas de implementação (delegadas / decididas)

- **Ponto de retorno:** o ponto desenhado no **primeiro hit da sequência** (âncora), não o `home` lógico. Hits seguidos mantêm a âncora e acumulam o recuo; a âncora é limpa quando o retorno termina ou quando o alvo é reposicionado por desvio/`settle`.
- **Slow motion do clipe `damage`:** começa no impacto a **0,30×** da velocidade normal durante o hit-stop e volta à velocidade normal depois. O resto do mundo continua congelado como no hit-stop atual (D-1012 item 4), para não alterar o relógio de regras (D-019).
- **Empurrão:** começa no impacto, com o mesmo tempo de subida de 0,11 s, **hold de 0,50 s** na posição empurrada (D-1049; antes 0,04 s) e uma volta suave de **0,34 s** (antes 0,24 s). O empurrão normal é **4,0 un** (D-1051; antes 2,0) e a volta toca o clipe `run` (D-1050).
- **Remoção da duplicata:** o empurrão/tween criado no fim de `_hit_stop()` foi removido; `knock()` é o único dono da posição do alvo.


## Relações

- **D-019 / D-045 / D-055:** o recuo é visual, acumula entre hits e não muda a posição lógica.
- **D-272:** hit stun global de +0,30 s; quem está em Guard não sofre recuo.
- **D-1012 item 5:** o alvo era empurrado na saída do hit-stop e voltava suave; **D-1045 altera**: o empurrão começa no impacto e o clipe de dano roda em slow motion durante o hit-stop.
- **D-235:** vale para qualquer personagem, lado e alvo; testar nas duas vistas.
- **D-1042 / AGENTS §9:** suíte de debug e cenários de dano.
- **D-1044:** ferramentas de análise visual; não foram necessárias para esta correção (não é VFX de Move), mas a suíte de combate foi usada.

## Estado no código

- `scripts/combat/fx/fx_motion.gd`: `_hit_stop()` não move mais o alvo (só squash/stretch e shake dos VFX) e aceita `slow_target`; `_hit_react(c, slow_time)` inicia o `damage` no impacto e o roda a `HIT_REACT_SLOWMO` (0,30×) durante o hit-stop; `knock()` tem âncora (`fx._knock_home`) e volta em 0,34 s.
- `scripts/combat/battle_fx.gd`: `play_hit()` inicia `knock()` e `_hit_react()` no impacto, antes do `await _hit_stop()`; `_knock_home` é limpo no `unregister`.
- `scripts/combat/fx/fx_dodge.gd`: `settle()` limpa a âncora.
- **Testes:** diagnóstico quadro a quadro no combate real, normal e `--mirror`, com Abra atacando Cyclops, Gible, Pancham e Orc: o clipe `damage` começa no quadro do impacto, roda a ~0,30× durante o hit-stop, o retorno chega exatamente à âncora no quadro 35 e não há salto de posição (maior passo ~0,42 un em 60 fps, compatível com o empurrão de 1,5 un em 0,11 s). A suíte D-1042 anterior à atualização D-1044 passou **13/13**.
- **Nota de validação:** a suíte nova D-1044 (`--summary-json`) ficou presa no `--quit` da sala de debug durante esta rodada; o resultado 13/13 é da suíte D-1042 anterior. O diagnóstico no combate real (`battle.tscn`) é a validação principal desta correção.
- **Não verificado:** hits consecutivos (acúmulo D-055) e projéteis no diagnóstico visual; Guard/ARMOR e K.O. só pela suíte.

