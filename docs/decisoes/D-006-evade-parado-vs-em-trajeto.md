# D-006 — Evade parado custa 3 ATB; Evade em trajeto (no próprio ataque) custa 2 ATB

- **Data:** 2026-11-02
- **Área:** Combate
- **Origem:** Conversa

## O que o criador disse (literal)

> A ideia sempre foi poder desviar durante o trajeto do próprio ataque ao custo de 2atb, eu fiz essa regra... / só gasta 2atb se for durante um ataque do usuário contra um inimigo, se não estiver realizando uma ação que envolva deslocamento em trajeto, é 3atb / Eu não consigo entender pq é tão difícil de vc compreender e diferenciar um evade parado de um evade em trajeto

## Decisão

Há **dois Evades**: **parado** (o personagem não está em ação com deslocamento em trajeto) = **3 ATB**; **em trajeto** (durante o trajeto do próprio ataque contra um inimigo) = **2 ATB**. É permitido desviar durante o trajeto do próprio ataque. Substitui o "2 ATB (não 3)" geral do `PROMPT`.

## Ambiguidades em aberto (perguntar antes de agir)

O que acontece com o próprio ataque quando o personagem desvia no meio dele (cancela ou continua)? Pergunta enviada; sem resposta ainda.

## Estado no código

**Não implementado.** O código cobra 2 sempre e bloqueia desviar enquanto ataca.
