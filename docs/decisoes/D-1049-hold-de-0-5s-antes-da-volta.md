# D-1049 — Alvo preso por 0,5 s na posição empurrada antes da volta

- **Data:** 2026-11-09
- **Área:** Combate / Game Feel / Animação
- **Origem:** Conversa
- **Estado:** **implementado e aprovado pelo criador** em 2026-11-09 (encerramento da sessão).

## Frase literal do criador

> o tempo que leva pra ele comecar a voltar pro ponto apos ser empurrado e pequeno demais, deixe ele preso por .5 segundos apos ser empurrado e depois execute a volta

## Decisão

- Depois que o empurrão atinge o pico, o alvo fica **preso por 0,5 s** na posição empurrada.
- Só depois desse hold começa a volta suave ao ponto desenhado.
- O empurrão continua começando no impacto (D-1045); a volta continua com 0,34 s; o clipe `damage` e o slow motion do hit-stop não mudam.
- Altera o `KNOCK_HOLD_TIME` de **0,04 s** para **0,50 s**.

## Relações

- **D-1045:** recuo no impacto, âncora no ponto desenhado e volta suave. D-1049 só alonga o hold.
- **D-1050:** aumenta o empurrão e troca a volta deslizante pela corrida (`run`); o hold de 0,5 s continua.
- **D-055:** hits consecutivos renovam o hold e mantêm a mesma âncora; o alvo só volta depois do último hold.
- **D-019 / D-045:** o hold é visual; a posição lógica não muda.

## Estado no código

- `scripts/combat/fx/fx_motion.gd`: `KNOCK_HOLD_TIME = 0.50`; `knock()` (push de 0,11 s → hold de 0,50 s → volta de 0,34 s).
- O `_busy_for` do `knock()` já cobre push + hold + volta.
