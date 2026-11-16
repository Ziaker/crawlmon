<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1233 — Equipe: 3 ativos, 2 substitutos acompanhantes, estacionados na dungeon e retorno à guilda

**Data:** 2026-11-15  
**Área:** exploração, hub, party  
**Estado:** **registrada; nada implementado.** Só documento (D-061).  
**Origem:** briefing "IMPLEMENTAÇÃO FASEADA DE EMPLOY, SUMMON E RESPEITO" colado pelo criador.  
**Relacionadas:** D-316, D-1207, D-1208, D-1232, D-1234, D-1022.

## Texto literal do briefing do criador

> "Máximo durante a expedição: 3 personagens ativos, incluindo o protagonista. 2 substitutos acompanhantes. Total: até 5 acompanhantes. Recrutas excedentes podem permanecer na dungeon."

> "Personagens deixados na dungeon: Permanecem seguros. Podem ser contatados. Podem ser recuperados presencialmente. Não retornam automaticamente ao grupo por comunicação remota. Sua identidade e seus dados individuais precisam permanecer íntegros."

> "Não criar ataque automático contra personagens estacionados. Não inventar capacidade máxima total da guilda ou descartar recrutas excedentes."

> "Todos os personagens recrutados retornam à guilda após: Vitória. Retirada voluntária. Derrota definitiva."

> "A regra D-316 descreve uma nova expedição iniciada pela escada do quinto andar. Verificar sua compatibilidade com o retorno à guilda antes de implementar a transição definitiva."

## Decisão

1. Na expedição: até **3 ativos** (com o protagonista) + até **2 substitutos acompanhantes**.
2. Excedentes ficam **estacionados na dungeon**: seguros, contatáveis, recuperados só presencialmente.
3. Ao fim da expedição (vitória, retirada voluntária, derrota definitiva) todos os recrutados voltam à guilda.

## Conflitos e pendências achados na auditoria (perguntar)

- **D-316 × retorno à guilda:** pela D-316 a escada do 5º andar inicia "nova expedição completa" e "mantém a equipe, os itens e o HP". Não está definido se isso é a "Vitória" que devolve todos à guilda (o criador mandou verificar antes de implementar).
- **Derrota definitiva hoje:** `end_battle(false)` apaga a Nature do líder e revive a party no Hub (`game_state.gd:312-333`); a D-1219 prende a Nature ao personagem "até ele ser perdido". O que acontece com recrutas e suas Natures na derrota não está dito.
- **Identidade:** personagens são chaveados por espécie (`species_key`, `game_state.gd:44`; `character_natures` usa essa chave), então dois recrutas da mesma espécie colidem. Não há identificador individual.
- **Código:** não existe reserva (o "Standby Roster" da Guild Hall é demo sem dados, `hub_3d_lab.gd:100-104`), nem estacionamento, nem a expedição real de 5 andares (`game_state.gd:81`). Não há save em disco.
- **"Contatados":** o que o contato faz não foi definido.
- **Cura do descanso (D-316):** cura a "equipe ativa"; o efeito sobre substitutos continua em aberto.

## Estado no código

Nada implementado. `GameState.party` é uma lista única, sem tamanho máximo declarado.
