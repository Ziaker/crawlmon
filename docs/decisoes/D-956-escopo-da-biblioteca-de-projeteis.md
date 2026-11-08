# D-956 — Escopo da biblioteca de projéteis: fases, Start, Post-impact, múltiplos alvos e Neutral

- **Data:** 2026-11-07.
- **Área:** VFX / Biblioteca de projéteis.
- **Origem:** respostas do criador às perguntas de escopo do dossiê (D-955).
- **Estado:** registrada; nenhum código.

## Respostas literais do criador

> 1 - sim, mas como esse protótipo é pra efeitos de projétil, então no caso de serem projéteis, então sim
> 2 - start é o efeito que triggera o wind-up, post-impact é o efeito que ocorre na dissipação do impacto, ou a própria dissipação do impacto
> 3 - não ainda
> 4 - dispara vários de uma vez
> 5 - ?
> 6 - sim
> 7 - sem problemas, quanto a neutral, pense em algo genérico

## Decisão

1. **Fases:** para VFX de **projétil**, as seis fases (Start → Wind-up → Release → Trajectory → Impact → Post-impact) substituem as quatro da D-308. Para os outros tipos de VFX, a D-308 continua igual.
2. **Start** é o efeito que dispara o wind-up. **Post-impact** é o efeito da dissipação do impacto, ou a própria dissipação.
3. **Área sem projétil** (tipo Mabufula): **ainda não** entra na biblioteca.
4. **Múltiplos alvos:** o efeito dispara **vários projéteis de uma vez**, um por alvo.
5. **Referências:** aprovadas pelo criador ("sem problemas"). **Neutral:** algo **genérico**, a propor pelo assistente.

## Perguntas refeitas (2026-11-07)

- **Pausa do VFX (D-953):** "Sim, pausa encerrada". O assistente propõe o primeiro elemento e só constrói depois da aprovação, um por vez.
- **Papel do Motion Composer:** "D-954: principal à mão". A cabeça do projétil, o trajeto e o impacto são feitos à mão, com malhas, flipbooks e shaders. O Composer faz o secundário (poeira, brasas, rastros) e o timing. Para esta biblioteca, isso prevalece sobre a regra-mãe do protocolo D-308 ("tudo sobre o Composer"); falta atualizar o protocolo.

## Em aberto (histórico)

- **Item 5 (pausa do VFX da D-953):** o criador não entendeu a pergunta ("?"); será refeita.
- **Item 6 ("sim"):** a pergunta oferecia duas opções (D-954 x protocolo D-308), então "sim" não diz qual vale; será refeita.
- Duração do Start e do Post-impact.

## Relações

D-955, D-308, D-953, D-954, D-009, D-235.
