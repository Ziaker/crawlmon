> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** Teste em <10 s: `--scenario=st_blind_olhos --stdout-trace --quit` (evento `eyes`).

# D-1271 — Pálpebras fechadas enquanto o personagem está CEGO

## Frase literal do criador
> "faça com que as palpebras dos personagens que podem piscar fiquem fechadas quando estão com o efeito negativo de cegueira"

## Decisão
Enquanto um combatente está BLIND (`Combatant.is_blind()`) e vivo, o modelo dele, se tiver olhos piscáveis (`EyeBlink`, D-1268: Pikachu, Eevee, Charmander, Bulbasaur, Gible, Squirtle, Pancham e qualquer modelo novo com superfície `*_eye`), mantém as pálpebras fechadas; ao acabar a cegueira (ou morrer) elas abrem. Vale para qualquer personagem, aliado ou inimigo, em qualquer lado (D-235): `BattleFx._sync_blind_eyes` roda por combatente. Não altera a regra de 35% de erro, a duração nem o dano da cegueira (D-032/D-158).
- Fecha em 0,12 s e abre em 0,22 s (valores técnicos meus, mudáveis); o piscar aleatório continua por baixo (vale o mais fechado).
- Modelos DQT (Orc, Cyclops, Slime...) não têm olhos piscáveis por este código e não mudam.

## Implementação
`scripts/common/eye_blink.gd` (`hold_closed`), `scripts/combat/battle_fx.gd` (`_sync_blind_eyes`, sinal `eyes_hold_changed`), `scripts/combat/battle_trace.gd` (evento `eyes`, documentado em `docs/TELEMETRIA.md`), cenário `st_blind_olhos` em `vfx_room_scenarios.gd`.

## Verificação
- `--scenario=st_blind_olhos --stdout-trace`: Pancham (aliado) `eyes closed=true` quando o BLIND entra e `closed=false` 3,0 s depois, quando expira; com `--mirror` o mesmo no Gible (lado do inimigo).
- `tests/overworld/diag_blind_eyes_shot.gd`: capturas aberto/fechado de Pancham, Eevee e Pikachu (`docs/capturas_olhos/cego_palpebras_fechadas.png`).
- Não verificado: aprovação do criador sobre os tempos; cegueira em batalha real com câmera de jogo (o olho tem poucos pixels); modelos DQT.
- Suíte `run_agent_combat_tests.py`: 126/127. A única falha é "Javelin Throw D-235" (`D235_RESULT: FAIL attacker_a/attacker_b/mirrored_scaled=false`); reproduzida IDÊNTICA com `EyeShine`/`EyeBlink` e `_sync_blind_eyes` desligados, então não vem desta mudança (causa não investigada; o erro `material is null` do renderer dummy também aparece sem ela).

## Aprovação do criador (2026-11-17)

Frase literal: "aprovo tudo" (resposta ao relatório final com os valores técnicos pendentes: ritmo do piscar 2,4-5,2 s com 0,06/0,05/0,09 s, 0,5 s ao levar dano/impacto, rampas 0,12 s e 0,22 s, posição e tamanho dos brilhos, e a interpretação de "dano" e "impacto" = reação de hit). Os valores deixam de estar pendentes. O visual em si continua sujeito ao julgamento do criador; a recomendação para os monstros DQT (auditoria Tact) NÃO foi decidida por esta frase.
