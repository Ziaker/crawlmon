<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1229 — EMPLOY: recrutamento de inimigos em combate; BOOST no fracasso

**Data:** 2026-11-15  
**Área:** combate, UI/HUD, recrutamento  
**Estado:** **Fases 5 (fluxo), 6 (chance real e rolagem) e 7 (BOOST) implementadas; diálogo, minigame e cutscene e a Fase 8 (Summon) não.**  
**Origem:** briefing "IMPLEMENTAÇÃO FASEADA DE EMPLOY, SUMMON E RESPEITO" colado pelo criador.  
**Relacionadas:** D-1230 (fórmula), D-1231 (Respeito), D-1232 (Summon), D-033 (Burst paga a ação), D-235, D-240, D-984, D-1026, D-1146/D-1147/D-1159 (pausa), D-105, D-391, D-413, D-1085, D-1214; auditoria em `docs/AUDITORIA_EMPLOY_SUMMON_RESPEITO_FASE0.md`.

## Texto literal do briefing do criador

> "Employ é uma ação de recrutamento durante o combate. Custo: 5 ATB e 0 MP. O custo deve ser efetivamente descontado em ATB; não utilizar Burst automaticamente para substituí-lo."

> "O jogador acessa Employ movendo a seleção para a direita quando estiver sobre `TACTICS`, abrindo uma aba alternativa que também contém `SUMMON`."

> "1. Seleciona um inimigo elegível. 2. O combate pausa. 3. O adversário inicia um diálogo relacionado à sua personalidade. 4. O adversário questiona se a equipe possui força suficiente para merecer sua companhia. 5. Começa um minigame rítmico de demonstração de força. 6. O sistema calcula a chance de recrutamento. 7. O jogador recebe uma cutscene de sucesso ou fracasso."

> "Existem duas formas de recrutamento, destinadas a categorias distintas: Interação voluntária durante a exploração. Employ durante o combate. As categorias exatas ainda precisam ser homologadas. Não criar regras automáticas de elegibilidade."

> "Protagonista sozinho: 1 nota. Protagonista com um companheiro: 2 notas. Equipe de três integrantes: 3 notas. Cada nota: `GOOD`: +5 pontos percentuais. `PERFECT`: +10 pontos percentuais."

> "Os ataques apresentados durante a sequência são demonstrações visuais, não causam dano e não executam efeitos mecânicos de Moves convencionais."

> "Após um fracasso: O combate é retomado. O inimigo recebe BOOST. Novas tentativas de Employ ficam bloqueadas durante o restante do combate. SUMMON continua disponível."

> "BOOST — Duração: 10 segundos. Efeitos: +1 STR. +1 MAG. +1 VIT. +1 SPI. +1 AGI. +1 LUK. +1 Burst. +2 ATB. Efeito visual: badge `BOOST` no card do inimigo e chamas mágicas de baixa opacidade percorrendo o cartão, sem obstruir informações."

## Decisão (somente o que está no briefing)

1. Employ custa **5 ATB e 0 MP**, pagos em ATB de verdade (Burst não substitui).
2. Fica numa **aba alternativa aberta com "direita" sobre TACTICS**, junto com SUMMON.
3. Fluxo de 7 passos acima; a demonstração de força **não causa dano**.
4. Notas: 1, 2 ou 3 conforme a equipe; GOOD +5 pp, PERFECT +10 pp.
5. Fracasso: combate retoma, alvo recebe **BOOST** por 10 s, Employ fica bloqueado até o fim do combate, SUMMON continua.

## Pendências declaradas pelo criador (não implementar)

- Categorias elegíveis para Employ × recrutamento na exploração. **Resposta provisória do criador (2026-11-16):** à pergunta "Qualquer inimigo vivo pode ser alvo de Employ por enquanto?" ele respondeu > "Sim, qualquer um". Vale "por enquanto"; as categorias definitivas continuam pendentes.
- Janelas de timing, consequência de MISS, teclas do minigame, possibilidade de interromper a sequência.
- Limite de Burst e comportamento com o medidor cheio no BOOST.
- Quem participa quando há aliados nocauteados; instante exato do pagamento dos 5 ATB; contrato de RNG. **Pagamento respondido (2026-11-16):** à pergunta "Os 5 ATB do Employ são cobrados ao confirmar o alvo?" o criador respondeu > "Sim, ao confirmar". Cancelar na escolha de alvo não gasta nada.

## Conflitos e pendências achados na auditoria (perguntar)

- **SPI × WIS (resolvido em 2026-11-16):** a D-391 renomeou Spirit para **WIS**; o briefing escreve SPI; no código `spi` é alias de `wis` (`combatant.gd:39-43`). O criador disse: "isso já devia ser irrelevante, spi é WIS e WIS é o nome certo". Não é mais conflito.
- **Burst:** `Combatant.pay()` gasta 1 Burst no lugar do custo inteiro (D-033, `combatant.gd:661-670`). Employ/Summon terão de usar `spend()` direto, como Guard/Evade/Passos.
- **BOOST por atributo não existe no código:** só há estágios `atk_buff/def_buff/speed_buff` (−5..+5, sem duração, D-159). Um buff temporário de seis atributos é mecânica nova; a D-1026 exige que a duração pause junto com as pausas.
- **Burst cheio:** `BURST_MAX = 5`; hoje o ganho é bloqueado ("Burst já cheio").
- **Último inimigo recrutado:** a D-105 define vitória por derrotar o último inimigo; `_check_end` (`battle.gd:1371`) não tem saída de inimigo sem K.O. **Respondido em 2026-11-16:** à pergunta "O último inimigo recrutado fica só como cenário de teste por enquanto?" o criador respondeu > "Sim, só teste". Vitória, XP e loot desse caso continuam sem decisão.
- **Pausa (respondido em 2026-11-16):** à pergunta "O Employ congela a batalha inteira, sem Evade nem Guard?" o criador respondeu > "Sim, congela tudo". Não é a pausa de status D-1146 (que permite Evade/Guard e wind-up parado, D-1159); a D-1147 ("NÃO MUDE a mecanica da pausa") continua intocada porque a pausa de status não muda.
- **Idioma do diálogo:** D-413 (todo texto em inglês) × D-1085 (falas de NPC em português).
- **Posição do badge:** D-240 (acima da barra de vida) e D-984 (positivos à direita) já definem onde o badge BOOST fica.
- **Diálogo por Nature:** `AllyDialogue.REACTIONS` tem 2 falas por Nature; não há fala de recrutamento.

## Estado no código

**Fase 5 (2026-11-16): só o fluxo mecânico, com resultado forçado por debug.** Não existe minigame rítmico, cutscene, diálogo por Nature, rolagem da chance nem BOOST.

- `Battle` (`scripts/combat/battle.gd`): `employ_refusal()`, `begin_employ()` (cobra 5 ATB com `spend()`; Burst intocado), `finish_employ()`, `is_employ_active()`, sinal `employ_changed`. Enquanto a tentativa existe, `_process` não avança e Move, item, Guard, passo e Evade são recusados.
- Cena (`scripts/combat/battle_scene.gd`): EMPLOY no leque lateral abre o seletor de alvo (sempre aberto, mesmo com um inimigo só, para existir confirmação a cancelar); confirmar cobra e pausa a árvore (estado `S.EMPLOY`); o marcador provisório `scripts/ui/employ_marker.gd` força sucesso (confirmar) ou fracasso (cancelar).
- Fracasso: `ExpeditionRoster.mark_employ_failed()` bloqueia novas tentativas até a próxima batalha; SUMMON não é afetado.
- Sucesso: o inimigo sai da lista de inimigos sem K.O. e é registrado no elenco uma vez (substituto se houver vaga, senão estacionado); não entra em campo.
- Telemetria: evento `employ` e atalho `--employ=<modo>` (`docs/TELEMETRIA.md`).

**Recomendações da IA adotadas por delegação do criador (2026-11-16).** Ao receber a lista de perguntas que restavam, o criador respondeu:

> "eu sigo suas recomendações para o resto das perguntas que faria, prossiga e finalize"

Com isso valem, como recomendação da IA aceita em bloco (não são frase literal do criador sobre cada ponto):

1. **Modelo e cartão do recrutado:** no sucesso o recrutado sai do campo; o modelo some (escondido na hora, liberado 3 s depois) e o cartão sai da HUD, como já ocorre com os inimigos de teste do debug.
2. **Último inimigo vivo:** no jogo real o Employ é recusado (`reason: last_enemy`, entrada desabilitada), porque o criador disse "Sim, só teste" e a vitória/XP/loot desse caso não existem. Só a sala de debug liga `Battle.employ_allow_last` (`--employ=last`).
3. **Vaga do recrutado:** substituto se houver vaga, senão estacionado (leitura da D-1233).
4. **Seletor de alvo:** sempre aberto no Employ, mesmo com um inimigo só, para existir uma confirmação a cancelar.
5. **Marcador provisório:** confirmar força sucesso e cancelar força fracasso; é só debug da Fase 5.

Continuam **pendentes** (não decididos, não implementados): textos de motivo no menu, contrato de RNG e rolagem da chance, quem participa quando há aliados nocauteados, diálogo/minigame/cutscenes (Fase 6), BOOST (Fase 7), entrada por Summon (Fase 8).

**Pendências que a Fase 5 deixou sem regra (o código não decide), antes das respostas acima:**

- Ataques em voo no instante do congelamento: hoje ficam parados e continuam ao retomar (leitura literal de "congela tudo"). No sucesso, um ataque do recrutado ou contra ele **não é tratado** (continua como estava).
- Modelo e cartão do recrutado: não são tocados (ele continua de pé no lugar).
- Último inimigo recrutado: a batalha **não termina** (sem vitória, XP ou loot) e fica sem inimigos; em jogo real isso prende o jogador.
- Vaga do recrutado (substituto, senão estacionado) é leitura da D-1233, não frase do criador.
- Seletor sempre aberto no Employ e as teclas do marcador provisório são escolhas técnicas de debug.

- **Fase 6 (recorte, D-1240):** `Battle.employ_chance()` e `resolve_employ()` ligam o `EmployMath` ao Employ; o marcador provisório confirma = rolagem real, cancela = fracasso forçado. Cenários `--employ=chance`, `roll`, `roll:win`, `roll:zero`. Diálogo, minigame e cutscene seguem pendentes.

- **Fase 7 (recorte mecânico, D-1242):** no fracasso o alvo recebe o BOOST (`Combatant.start_boost`, `Battle.BOOST_SECONDS`); o visual é a D-1241, em outra sessão.
