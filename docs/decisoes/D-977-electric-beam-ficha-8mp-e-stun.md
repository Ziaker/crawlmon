<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-977 — Electric Beam: ficha, 8 MP e STUN de 4 s com 20% + LUK

- **Data:** 2026-11-08.

## Frase literal do criador

> redundante, se não tem então não precisa estar no texto.
>
> é pra tudo isso estar em um texto só, não separado em lista
>
> mudança, 8MP
>
> para efeito mecânico, vamos adicionar este (em inglês) Ao contato com sucesso, tem 20% + LUK de causar STUN de 4 segundos no alvo.
>
> de resto está ok

## Decisão

1. **Custo:** 8 MP (antes 4, o padrão de move fora da tabela).
2. **Efeito:** num contato com sucesso, chance de **STUN de 4 s** no alvo. A chance segue a regra de status já existente (D-143/D-146, `status_application_chance`): **20% + 1 ponto percentual por ponto de diferença de LUK (aplicador − alvo)**, limitada a 0–100%. O STUN é o atordoamento já existente (`stun_timer`: ATB pausado, ações bloqueadas).
3. **Ficha:** a seção VISUALS é um parágrafo único; textos que dizem o que o move *não* faz são removidos. O resto da ficha proposta foi aprovado.

## Ambiguidades

- "20% + LUK" foi lido como a fórmula de status existente (diferença de LUK). Se o criador quis outra coisa (ex.: só o LUK do atacante), corrigir.

## Estado

Ficha aprovada. Implementado: 8 MP, STUN em `battle.gd` (`_hit`), textos da ficha em `skill.gd`; teste `tests/battle/test_d977_electric_beam.gd`. Tipo Magical, elemento Electric e alcance Long (o criador escolheu Long para "ranged") já vinham da derivação por elemento e tipo projétil.
