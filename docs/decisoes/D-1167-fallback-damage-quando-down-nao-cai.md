# D-1167 — Fallback do dodge errado: usar `damage` quando o `down` não derruba

- **Data:** 2026-11-11.
- **Área:** Combate / Evade / Animação de fallback.
- **Origem:** o criador pediu para investigar clipes de morte/queda e, se não houvesse um utilizável, usar a animação de levar dano nos casos em que o `down` não cai.
- **Status:** investigação concluída; fallback implementado e testado headless. Complementa a D-1166.

## O que o criador disse

> "tem como investigar a procura de clipes que funcionam como death ou caida? se não achar use o de levar dano mesmo para o caso deles, procure no E/arenamon"

## O que foi encontrado em `E:\arenamon`

- **Clipes reais de queda/morte** existem em:
  - `chars\mosh\Cogumelo.glb`: `Dying Backwards`, `Falling Back Death`, `Falling Down`, `Falling`, `Fall A Loop`, `Standing Up`, `Mutant Dying`, etc.;
  - `chars\wookada\wookada.glb`: `falling`, `fall_hitground`, `stay dead`, `dead recovery`, `ground crash`, `lying still post ground crash`, etc.;
  - FBXs equivalentes em `chars\mosh`, `chars\vigor` e `chars\wookada`.
- **Porém** esses clipes pertencem aos rigs de **Cogumelo**, **Vigoroth** e **Wookada** — esqueletos diferentes dos Pokémon `pm0063`/`pm0443`/`pm0752`. O Crawlmon não tem pipeline de retarget entre esses rigs; aplicar o FBX direto no Pokémon não funciona.
- No dump Pokémon (`LegendsZAPkmnModelDumpWithDLC`), cada Pokémon tem `down01_start`, `down01_loop` e `down01_end`. O `tools/export_pokemon.py` **já exporta `down01_start` como `down`**. A inspeção no Blender mostrou que o próprio `down01_start` do Abra não derruba o corpo: só move braços, cabeça, tronco e um pouco o waist. Não há outro clipe de morte/queda no rig Pokémon.
- Conclusão: **não existe clipe de queda utilizável nos modelos Pokémon atuais.** O fallback autorizado é usar o `damage`.

## Decisão

1. **Quando o `down` derruba o corpo** (DQT): toca `down`, sem inclinação extra.
2. **Quando o `down` não derruba** (Pokémon) e existe `damage`: toca **`damage`** como clipe principal, mantendo a queda assistida por código, o `WHIFF` e a poeira da D-1166.
3. **Sem `down` e sem `damage`:** mantém `WHIFF` + poeira + queda assistida; nenhum clipe é inventado.
4. **Sem `down`, mas com `damage`:** toca `damage` + queda assistida + `WHIFF` + poeira.
5. **Regras intactas (D-1014):** o ATB é gasto e o golpe acerta. Nada muda em dano, janela, crítico ou IA.
6. **Simetria D-235:** vale para qualquer personagem/time/lado; a escolha do clipe depende só do rig/modelo, nunca do nome do personagem.
7. **Não foi feito retarget** dos clipes de Cogumelo/Wookada para os Pokémon. Se o criador quiser isso, é um trabalho separado de rig/retarget e precisa de decisão própria.

## Relação com decisões

- **D-1166:** mantém `WHIFF`, poeira e queda assistida; muda só o clipe base quando o `down` não cai.
- **D-1015:** continua valendo para o `down`; a exceção “sem clipe, nada toca” fica coberta por D-1166/D-1167.
- **D-019/D-1040:** a animação é só visual; a lógica não muda.
- **D-235:** nada depende de personagem, time, lado ou coordenada fixa.

## Ambiguidades em aberto

- **Retarget dos clipes de `E:\arenamon`:** possível em teoria, mas exigiria um pipeline de retarget e ajuste por rig; não implementado.
- **Timing do `damage`:** 0,667 s no Abra; a queda assistida acompanha essa duração. Pode ser ajustado depois de vídeo.
- **Vídeo nas duas vistas:** não verificado.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/vfx/combat/fx_dodge.gd`: escolhe `down` quando ele cai; senão `damage`; senão queda assistida sem clipe. Mantém `WHIFF`, poeira e a volta ao idle.
- `tests/battle/test_d1163_mistimed_visual.gd`: **9/9 PASS** (agora verifica `damage` como fallback).
- Suíte: **27/27 PASS**.
