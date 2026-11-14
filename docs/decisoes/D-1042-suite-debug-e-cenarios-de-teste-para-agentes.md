<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1042 — Suíte de debug de combate, cenários de dano e inspeção de fases de Move para agentes de IA

- **Data:** 2026-11-09
- **Área:** Combate / Debug / Testes Automatizados / IA / VFX
- **Origem:** Conversa (solicitação e aprovação do criador).
- **Status:** **Decisão aprovada e implementada**. Documentada em `AGENTS.md` e integrada à sala de combate e debug (`scripts/debug/vfx_room.gd` e `scripts/combat/battle_debug.gd`).

## O que o criador disse (literal)

> "me diz 10 coisas que faria no debug de combate do jogo pra deixar ainda mais fácil para testes dos agentes de IA"
> "prossiga com tudo e atualize os documentos do jogo e agends md para fazer com que usem quando necessário"
> "inclusive também adicione cenários onde o personagem leva dano, onde apenas podemos ver as fases de algum move, definidas pela sua ficha de visual em sua descrição e mais outras features assim"

## Decisão

1. **Obrigatoriedade de uso por agentes de IA (`AGENTS.md` §9):** qualquer agente que trabalhe em combate, Moves, dano, animações, regras ou efeitos visuais deve utilizar a suíte de testes e cenários automatizados em vez de criar testes manuais ad-hoc ou depender de inspeção com janelas interativas.
2. **Cenários de Dano e Reação:** inclusão de cenários específicos no catálogo da sala de combate (`vfx_room.gd`) para validação de impacto e perda de vida:
   - `dano_direto`: dano puro sem esquiva (exibe reação de hit, animação `damage`, número flutuante e decremento de HP).
   - `dano_critico`: dano com multiplicador crítico forçado, tremor de tela reforçado e texto "CRIT!".
   - `dano_weak`: dano de fraqueza elementar ("WEAK!") validando afinidades e cores de elemento.
   - `dano_armor`: dano absorvido por ARMOR (D-1026), quebrando o badge sem interrupção de golpe ou knockback.
   - `dano_stun`: dano aplicado a combatente sob STUN (D-980), com estrelas na cabeça e reação.
   - `dano_guard`: dano mitigado por Guard (D-272), exibindo escudo azul protetor.
   - `dano_ko`: dano letal com lançamento balístico de K.O. (D-049, D-160, D-166) encolhendo e sumindo no ar.
3. **Cenários de Fases de Move (Inspeção por Ficha Visual e D-308):**
   - Suporte a inspeção isolada de cada fase do Move conforme as 4 fases de D-308 (mais retorno):
     - `fase_windup`: Move entra em preparo e pausa no loop contínuo de carga (D-163), permitindo checar postura, aura e rastro prévio.
     - `fase_release`: Congelamento no momento exato de partida/disparo (quando a carga se converte no projétil ou corrida).
     - `fase_trajeto`: Pausa durante o deslocamento/voo contínuo.
     - `fase_impacto`: Congelamento no ponto zero do impacto no alvo parado.
     - `fase_retorno`: Recuo à base e restauração de pose neutra.
   - Parâmetros CLI `--phase=windup|release|travel|strike|impact|return` e `--pause-at=...` para congelamento automático e captura em modo headless.
4. **Atalhos no Debug de Combate Interativo (`BattleDebug`):**
   - Tecla `F9`: aplica dano direto de teste no alvo selecionado (`take_damage(10)`).
   - Tecla `F10`: aplica dano letal / teste de K.O. launch instantâneo.
5. **Runner Headless para Agentes (`run_agent_combat_tests.py`):**
   - Script Python padronizado para execução headless de testes de dano, fases e espelhamento (D-235), emitindo códigos de saída 0/1 e relatórios estruturados.

## Ambiguidades em aberto

Nenhuma. As categorias foram aprovadas diretamente pelo criador e expandem as ferramentas já existentes sem alterar regras de balanceamento.

## Estado no código

Implementado e auditado/completado conforme D-1044 em `scripts/debug/vfx_room.gd`, `scripts/combat/battle_debug.gd`, `scripts/combat/battle_trace.gd`, `scripts/combat/battle.gd`, `scripts/combat/combatant.gd`, `scripts/data/skill.gd` e `tests/battle/run_agent_combat_tests.py`, e registrado em `AGENTS.md`, `docs/REGRAS_DO_JOGO.md`, `docs/vfx/PROTOCOLO_VFX_OBRIGATORIO.md` e `docs/vfx/FERRAMENTAS_VFX.md`.

> **Complemento D-1154 (2026-11-11):** a fonte canônica dos eventos e campos de telemetria é **`docs/TELEMETRIA.md`**. Leia antes de usar a suíte; em especial `queue.started` (o Move começou) vs. `queue.lost` (vaga descartada).
