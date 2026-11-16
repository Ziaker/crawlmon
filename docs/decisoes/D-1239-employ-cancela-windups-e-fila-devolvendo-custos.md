<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1239 — Employ: ninguém em wind-up; Moves iniciados e a iniciar são cancelados, com os custos devolvidos

**Data:** 2026-11-16  
**Área:** combate, recrutamento  
**Estado:** **implementada na Fase 5 (revista: congelar e retomar; só os Moves do recrutado são cancelados no sucesso).** Todas as ambiguidades da D-1239 foram respondidas; o que continua é a dúvida sobre "nenhum em wind-up" (acima).  
**Relacionadas:** D-1229 (Employ, Fase 5), D-161 (fila), D-033/D-063 (Burst paga a ação), D-100/D-103/D-1150 (ataques em voo), D-1146/D-1147/D-1159 (pausa de status, que não muda).

## Frase literal do criador

> "pro employ ocorrer, nenhum personagem deve estar em wind-up pra isso, cancelando todos moves que iriam ser iniciados e já foram iniciados, recuperando os custos usados"

## Decisão

1. Para o Employ ocorrer, nenhum personagem pode estar em wind-up.
2. Os Moves que iriam ser iniciados e os que já foram iniciados são cancelados.
3. Os custos usados nesses Moves são recuperados.

## Revisão (2026-11-16): congelar e retomar em vez de cancelar tudo

O criador pediu uma solução melhor que cancelar tudo ("acha uma solução melhor pra isso do que apenas cancelar tudo, estou aberto as suas recomendações"). A IA recomendou **congelar e retomar** (cancelar tudo vira botão de pânico contra golpes inimigos) e o criador respondeu:

> "ok siga com as mudanças ao invés de cancelamento"

Efeito: o Employ congela a batalha e ela retoma de onde parou. Fracasso: nada é cancelado nem devolvido. Sucesso: só são cancelados, com o custo devolvido, os Moves que envolvem o recrutado (como atacante ou alvo) e as filas dele ou apontadas a ele; o resto retoma. As respostas abaixo (alcance, 5 ATB antes, instante, Burst, timer de MP) valem para os Moves **cancelados**, que agora são só os do recrutado. A letra de "nenhum personagem deve estar em wind-up" **não** vale mais para os demais: os wind-ups ficam parados durante o diálogo (como na pausa de status, D-1159). À pergunta "O que acontece com um Move do recrutado que já acertou e só falta o retorno?" o criador respondeu:

> "Some junto com ele"

À pergunta "Um Move de status em curso que envolve o recrutado é cancelado e a pausa fecha?" o criador respondeu:

> "Sim, cancela"

Dúvida aberta: se "nenhum em wind-up" ainda é desejado por outro motivo (ex.: o visual do diálogo).

## Resposta do criador (2026-11-16)

À pergunta "'Já foram iniciados' cancela só quem está em wind-up, ou também ataques já em corrida ou em voo?" o criador respondeu:

> "Tudo, até em voo"

À pergunta "Para pedir Employ, o ATB mínimo de 5 pode contar o reembolso dos Moves cancelados?" o criador respondeu:

> "Não, 5 antes"

Os 5 ATB têm de existir **antes** do cancelamento; o reembolso não conta para pedir o Employ.

À pergunta "O cancelamento acontece ao confirmar o alvo ou já ao abrir o seletor de alvo?" o criador respondeu:

> "Ao confirmar o alvo"

Abrir ou cancelar o seletor não toca em nenhum Move.

À pergunta "Quando o Burst pagou o Move cancelado, o Burst volta?" o criador respondeu:

> "Sim, volta"

À pergunta "O timer de regeneração de MP e a proficiência registrada voltam ao que eram?" o criador respondeu:

> "Sim, voltam"

O timer volta ao valor que tinha antes de o Move zerá-lo (D-413). A proficiência só é registrada no impacto (`_strike`) e o Employ só cancela Moves que ainda não impactaram: nada foi registrado, então não há o que desfazer.

## Ambiguidades que continuam abertas (perguntar, uma por vez)

1. ~~Alcance de "já foram iniciados"~~ respondido acima (inclui corrida e projétil em voo). Fica aberto: Moves que já acertaram e só têm o retorno por fazer.
2. ~~Instante~~ respondido acima (ao confirmar o alvo).
3. ~~Burst devolvido~~ respondido acima (volta).
4. ~~Timer de MP e proficiência~~ respondido acima (voltam).
5. **Pausa de status em curso (D-031/D-1150):** um Move de status que já pausou o motor também é cancelado e devolvido?
6. **Leitura de "nenhum personagem deve estar em wind-up":** o Employ força esse estado cancelando os Moves (leitura adotada como hipótese), e não fica indisponível enquanto alguém prepara um Move.

## Estado no código (Fase 5)

Implementado em `Battle._employ_cancel_moves(who)` / `_employ_refund()`, chamado por `finish_employ()` só no sucesso e só para o recrutado `who`; `begin_employ()` não cancela nada. Hipóteses técnicas, ainda a confirmar: o corredor de outro atacante que ia ao recrutado volta andando para casa; (Todas as hipóteses técnicas foram respondidas.) Debug: `--employ=moves[:flight][:burst][:mp][:win]` , `--employ=returning` (Move que já acertou some com o recrutado) e `--employ=status` (Armored Bulk do recrutado cancelado, pausa de status fechada uma vez).

(Antes da implementação:)

Nada implementado. Hoje (Fase 5) os ataques em voo ficam parados durante a tentativa e continuam ao retomar; a fila D-161 só é limpa para o inimigo recrutado.
