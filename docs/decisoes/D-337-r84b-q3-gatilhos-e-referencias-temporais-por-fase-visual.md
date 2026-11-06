# D-337 — Rodada 84B Q3 (3A): gatilhos e referências temporais nas fases visuais de cada Move

- **Data:** 2026-11-06.
- **Área:** Fichas de Moves / documentação de fases visuais / tempo e gatilhos.
- **Origem:** aprovação expressa (“Sigo suas recomendações”) da alternativa A da questão 3 da Rodada 84B.
- **Estado:** campos documentais aprovados; especificações individuais e integração pendentes.

## Pergunta e alternativa A aprovadas

**Pergunta:** “Como documentar os gatilhos e tempos das diferentes fases visuais de um Move?”

> A — Em cada fase visual aplicável, documentar gatilhos, referências temporais e durações somente quando definidos, mantendo tempos ainda desconhecidos explicitamente pendentes.

**Resposta literal do criador:**

> Sigo suas recomendações

## Regra documental aprovada

- Na **ficha fora de combate**, em **cada fase visual aplicável** (preparação, movimento/emissão, impacto, dissipação, conforme D-248), registrar **gatilho de início**, **referências temporais** e **duração**, **somente se esses dados estiverem definidos**.
- **Marcar explicitamente como pendentes** os gatilhos, marcos e durações não homologados; não preencher com suposições ou converter instantes do motor atual em tempos oficiais do Move.
- **Exemplo sem aprovação de VFX novos:** se um Move possui emissão e impacto, a ficha pode associar a emissão ao disparo e o impacto ao contato **quando essa relação estiver expressamente definida**, registrando como “pendente” quaisquer tempos desconhecidos.
- Preservar D-245 (windup, deslocamento e velocidade de projétil em campos distintos), D-248 (descrição por fases fora do combate), D-333 (blocos de variantes só quando existirem) e D-229/D-230/D-259 (tooltip numérica; sem prévia de dano ao selecionar alvo).
- Preservar D-235: gatilhos/referências visuais não dependem de espécie, equipe, lado ou coordenada fixa.

## Pendências e limites

- Nenhum tempo novo, gatilho concreto, protocolo de animação, API de eventos, editor, integração runtime ou mudança de Motion Composer foi aprovado.
- Somente documentação; não modificar código, Moves, VFX, animações, assets, cenas ou testes.
