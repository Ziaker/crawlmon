# D-1040 — D-019 renovada: lógica e visual na mesma linha do tempo

- **Data:** 2026-11-09
- **Área:** Arquitetura / Combate / VFX / Processo
- **Origem:** resposta do criador à pergunta 4 da rodada de 2026-11-09.

## Frase literal do criador

> "4 renova"

## Decisão

1. A **D-019 volta a valer**: a lógica (`battle.gd`) é a única dona do estado e do relógio de cada ataque; o visual (`battle_fx.gd`, `fx/*`) só desenha. É proibido o visual ter temporizador/tween próprio que decida **quando** algo acontece; pausa e câmera lenta valem para os dois.
2. A divergência registrada na `AUDITORIA_PROIBICOES.md` A2 (arquivo apagado/redação do agente) fica **resolvida pelo criador**: o arquivo e a regra são renovados; o histórico da auditoria permanece como registro.
3. As ferramentas de VFX continuam apenas lendo fases/tempos reais do `Battle`; não criam timeline de combate.
4. Nenhum código de jogo foi alterado por esta decisão.

## Ambiguidades em aberto

Nenhuma.

## Estado

Regra renovada; documentação atualizada. Sem commit/push.
