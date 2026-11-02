# D-024 — Revisão das mudanças da Fase 2 feitas sem pedido

- **Data:** 2026-11-02
- **Área:** Processo / Combate
- **Origem:** Conversa (resposta do criador à lista numerada de mudanças da Fase 2)

## O que o criador disse (literal)

> 1 - OK deixa assim / 2 - vou checar / 3 - vou checar / 4 ?? Como assim? / 5 vou checar / 6 vou checar / 7 ok / 8 ok / 9 vou checar / 10 ok / 11 como assim MIRAR? NÃO TEM MIRA EM AOE A GENTE FALOU SOBRE ISSO AGORA / 12 OK

## Decisão (por item da lista; a numeração é a da lista enviada)

| Item | Mudança | Resposta |
|---|---|---|
| 1 | Hit-stop congela o relógio da batalha e todas as animações | **Mantido** ("OK deixa assim") |
| 2 | Investida do golpe termina no frame de contato | **O criador vai conferir** |
| 3 | Atacante persegue o alvo também durante o golpe | **O criador vai conferir** |
| 4 | Início da corrida a partir do ponto de repouso do motor, com suavização visual | **Pediu explicação** (dada na conversa); sem decisão ainda |
| 5 | Recuo de quem é atingido no meio do próprio ataque (motor, 0,15 s + pulo) | **O criador vai conferir** |
| 6 | Interceptação de projétil decidida na declaração do ataque | **O criador vai conferir** |
| 7 | Corpos de quem morre ficam onde caíram | **Mantido** ("ok") |
| 8 | Vencedor pego no meio de um ataque volta pulando antes da pose de vitória | **Mantido** ("ok") |
| 9 | No frame do dano, golpeador/projétil vão exatamente ao ponto de contato | **O criador vai conferir** |
| 10 | Golpes amigáveis não são esquiváveis | **Mantido** ("ok") |
| 11 | AoE com alvo morto "mira" o próximo oponente | **REJEITADO na fala**: "NÃO TEM MIRA EM AOE" (coerente com D-007: não existe alvo principal). **Remoção ainda não executada** — aguardando a implementação correta do AoE (D-007 a D-013). |
| 12 | Correção do fogo amigo do AoE (equipe errada) | **Mantido** ("OK") |

## Ambiguidades em aberto

- Itens 2, 3, 5, 6, 9: aguardam a conferência do criador; **não alterar nem reverter** antes da resposta.
- Item 11: o que vale é D-007; a pergunta aberta para implementá-lo é D-011 ("quem tava vivo": na declaração ou no impacto?).

## Estado no código

Superado por D-025: o criador mandou reverter tudo, exceto os itens aprovados.
