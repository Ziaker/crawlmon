<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1146 — Fila de Moves e pausa de status: correções de cancelamento, substituição e ações permitidas

- **Data:** 2026-11-11.
- **Área:** Combate / Fila D-161 / Pausa de status D-031 / HUD.
- **Origem:** pedido do criador após investigação com agentes.
- **Status:** regra registrada; implementado e testado headless.

## O que o criador pediu (literal)

> "use seus agentes para fazer uma investigação em busca de corrigir bugs relacionados ao Queue de moves e de cancelamento imediato de ações durante e após moves de status e relacionados que pausam o combate"

Respostas da rodada:

- **Lote A:** "opção 1, war cry congelar a animação faz sentido com o move, não é bug, é feature".
- **Ações na pausa de status:** "Permitir só Evade e Guard".
- **Fila no Guard:** "Desabilitar a UI (Recomendado)".
- **War Cry visual:** "tira a aura e corrige o vfx, NÃO MUDE a mecanica da pausa, é feature do move".

## Decisão

### 1. Fila de Moves (D-161)

1. **Substituição imediata:** se o jogador confirma um Move no exato instante em que a ação atual termina e ainda existe uma vaga preenchida, o Move novo **substitui** a vaga. Não pode sobrar o Move antigo para executar depois (evita duas ações por uma escolha).
2. **Cancelamento só em interrupção real:** a vaga é descartada quando a ação atual do dono é **de fato interrompida** (hit que cancela wind-up/trajeto/retorno, War Cry/status ou cancelamento equivalente). Um hit no lançador enquanto o **projétil dele já está em voo** não apaga a vaga, porque o ataque original continua e vai acertar (D-094/D-064).
3. **Snapshot/rollback:** `Combatant.save_state()` / `restore_state()` e `Battle.save_state()` / `restore_state()` passam a preservar `queued_skill` e `queued_target` (D-1042/D-1044). Restaurar um snapshot sem fila limpa a fila atual; restaurar um snapshot com fila a devolve.
4. Continua valendo D-161: uma vaga só, pagamento ao executar, Move começa depois do retorno completo, item não entra na vaga, alvo ofensivo morto/ator atordoado descarta a vaga.

### 2. Pausa de status (D-031)

1. **Permitidos durante a pausa:** **Evade** e **Guard** manuais. O Evade continua respeitando a janela D-1014/D-988; se for apertado fora dela, gasta o ATB e erra como já acontece fora da pausa.
2. **Bloqueados durante a pausa:** **Itens** e **Passos**. O motor está pausado; essas ações não podem furar a pausa.
3. **Fila de Move:** continua permitida e continua esperando a pausa acabar (D-161 item 2). Nada é pago ao escolher.
4. **Guard durante a pausa:** um personagem livre (sem ataque próprio em curso) pode entrar em Guard. Quem está no meio de um ataque congelado continua bloqueado pela regra normal de Guard (D-272/D-282).
5. **UI do Guard:** com o líder em Guard, **Fight** e **Itens** ficam desabilitados e mostram o motivo (`GUARD`), em vez de habilitar e recusar a ação em silêncio.
6. **Não muda a mecânica da pausa:** `_status_pause`, `_status_total`, `_status_tail`, `_status_elapsed`, tempos de wind-up/cauda e o congelamento visual não são alterados por esta decisão.

## Ambiguidades em aberto (não resolvidas por esta rodada)

- Item usado **durante a própria ação** (não na pausa) continua sem decisão; esta rodada só bloqueia durante a pausa.
- Move amigável guardado cujo alvo morreu: D-161 (escolha do agente) diz descartar, mas o código redireciona ao conjurador. Não alterado por esta rodada.
- Lista de Fight atualizar quando o MP regenera: não incluído no Lote A.
- ATB/MP regenerando durante o RETORNO: não incluído no Lote A.

## Relação com decisões existentes

- **D-161:** preservado; as correções só fecham lacunas de substituição e cancelamento.
- **D-031:** preservado; Evade/Guard são exceções expressas; Itens/Passos continuam proibidos.
- **D-064/D-094:** a fila não é cancelada por hit que não interrompe o ataque original.
- **D-272/D-282:** Guard continua bloqueado para quem está atacando; a UI passa a refletir a regra.
- **D-1042/D-1044:** snapshot/rollback passa a incluir a fila.
- **D-019/D-1040:** nenhuma mudança de relógio; a pausa continua no motor.

## Estado no código

Implementado e testado headless (2026-11-11):

- `scripts/combat/battle.gd`: substituição da vaga no início imediato; fila só cai em interrupção real; Item/Passo bloqueados na pausa; Guard permitido para quem está livre; `is_status_paused()` para a HUD.
- `scripts/combat/combatant.gd`: `save_state`/`restore_state` incluem `queued_skill`/`queued_target`.
- `scripts/combat/battle_scene.gd`: Fight/Itens desabilitados no Guard com motivo `GUARD`; Itens bloqueados na pausa; assinatura da lista inclui Guard/pausa.
- `tests/battle/test_d1146_queue_and_status_pause.gd` — **passa** (substituição, projétil, snapshot, Item/Passo/Guard na pausa).
- Regressões: `test_d160_d164_combat_fixes.gd`, `test_d1102_war_cry.gd`, `test_d282_prison.gd`, `test_d047_decision_slowmo.gd` (com `--fixed-fps 60`) e `test_d1129_interruption_feel.gd` passam.
- **Falha pré-existente:** `test_d272_guard.gd` falha em “Brick Break causa o dano normal” (espera 10; a fórmula atual de dano físico com STR não devolve 10). Não é causada por esta decisão; o jogo não foi alterado para o teste passar.
- **Não verificado:** vídeo in-game, HUD real dos menus em todas as combinações e o caso de dois Moves de status reais sobrepostos.
