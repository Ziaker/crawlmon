<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-156 — Rodada 61 Q5 (5A): consultar LUK no instante da resolução do evento probabilístico

- **Data:** 2026-11-03.
- **Área:** Combate / timing de probabilidades / LUK.
- **Origem:** escolha literal do criador na Rodada 61.
- **Estado:** decisão aprovada e registrada documentalmente; não implementada.

## Declaração literal do criador

> 5A — consultar LUK no instante da resolução de cada evento probabilístico.

## Regra aprovada

- Para as probabilidades de **crítico normal, esquiva automática e aplicação de status probabilístico**, consultar a **LUK efetiva atual das partes envolvidas no instante da resolução da respectiva rolagem**, e aplicar a fórmula específica desse evento.
- Não congelar LUK pela seleção do Move, pela declaração do ataque, pela entrada em WINDUP ou pela transição para TRAVEL.
- Se buffs/debuffs de LUK válidos modificarem o atributo antes de um evento, aplicar a LUK efetiva correspondente ao **evento**, não a um valor anterior congelado.
- Exemplo ilustrativo para **crítico probabilístico**: LUK atacante = **40** na declaração, **50** no início de TRAVEL, **60** na resolução do impacto; LUK alvo = **40** na resolução → **10 + (60 − 40) = 30%** pela D-150/D-151. O exemplo não estabelece uma nova ordem de rolagens.
- Para **esquiva automática**, usar diferença **LUK defensor − LUK atacante** com a curva D-152/D-153; para **status probabilístico**, usar diferença **LUK aplicador − LUK alvo** e fórmula D-146/D-143.

## Limites e preservações

- A regra só determina **qual LUK usar**, não cria rolagens para críticos garantidos ou efeitos de status garantidos (D-134).
- Não altera a LUK já utilizada em eventos resolvidos anteriormente; não há recálculo retroativo de eventos.
- Não modifica a captura de **AGI para o tempo do trajeto**, regulada separadamente pelas D-148/D-154/D-155.
- A ordem de resolução de eventos simultâneos e efeitos aplicados exatamente no mesmo instante lógico continua assunto distinto.

## Escopo

Registro documental somente. Nenhuma alteração de código, fichas de Moves, cena, VFX, assets ou testes.
