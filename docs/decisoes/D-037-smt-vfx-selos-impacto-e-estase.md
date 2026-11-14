<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-037 — VFX SMT Avançado: Selos Rúnicos, Ruptura de Escudo e Estase Temporal

- **Data:** 2026-11-03
- **Área:** Visual / VFX
- **Origem:** Conversa (Opção 1 aprovada após pesquisa de referências de Shin Megami Tensei V e Persona 5)

## O que o criador disse (literal)

> EU MANDEI VC SER AMBICIOSO EU MANDEI VC FAZER EFEITOS DE VERDADE NÁO SÓ COLOCAR RETANGULOS IDIOTAS OU CIRCULOS IDIOTAS EU MANDEI VC FAZER ALGO BONITO E DIFERENTE, NÃO SÓ FAZER ALGO PORCAMENTE, CACE POR REFERENCIAS E REMOVA ESSES TUBOS INUTEIS Q VC FEZ
>
> Opção 1

## Decisão

1. **Remoção Definitiva de Tubos/Cilindros Opacos (D-036 revogado)**:
   - Nenhum cilindro ou tubo de luz volumétrico lavando a tela será utilizado. Os combatentes, animações e HUD permanecem nítidos e desobstruídos.

2. **Tarukaja (Potencializador de Ataque // Verde-Lima `#D7FD6A` + Ouro `#F7CB78`)**:
   - **Selo Rúnico no Solo (Ground Sigil):** Projeção de círculo mágico estilizado com geometria rúnica e glifos no chão aos pés do alvo, girando e pulsando em verde-lima e dourado.
   - **Labaredas e Feixes Angulares Ascendentes:** Feixes pontiagudos de alta velocidade (*slash spikes / burst ribbons*) explodindo para cima em aceleração súbita com aceleração inicial e snap (*ease-in*).
   - **Centelhas Ascendentes:** Partículas incandescentes subindo com turbulência.

3. **Rakunda (Quebra de Defesa // Coral `#FF624F`)**:
   - **Ruptura de Escudo (Shield Shatter):** Projeção de um brasão/escudo de energia na frente do alvo que racha e se estilhaça em cacos triangulares pontiagudos que caem e se dissolvem.
   - **Estacas de Maldição / Gravidade:** Estacas pontiagudas despencando do alto e se cravando no chão ao redor do alvo, emitindo uma onda de choque no solo.
   - **Impacto Físico no Alvo:** Deformação procedural transitória no modelo 3D do alvo (`squash & jitter` no eixo Y), transmitindo perda de equilíbrio e peso gravitacional esmagador.

4. **Sukunda (Estase Temporal e Redução de Agilidade // Amarelo/Ouro `#F7CB78`)**:
   - **Mostrador / Engrenagem de Estase no Solo:** Mostrador rúnico com ponteiros/engrenagens estilizadas no chão sob o inimigo que gira rápido e **trava bruscamente**, simulando desaceleração temporal forçada.
   - **Arcos / Correntes de Estase:** Feixes e anéis horizontais em zigue-zague elétrico travando a base e pernas do alvo.
   - **Retícula Temporal Emperrada:** Retícula angular no torso com desaceleração visível.

5. **Duração e Integração**:
   - Duração sincronizada com a pausa de status de 1.00s (D-031).
   - Tipografia do popup (`↗ ATK +1`, `↘ DEF -1`, `↯ SPD -1`) mantida com contraste alto.

## Ambiguidades em aberto

- Nenhuma pendência; Opção 1 aprovada textualmente pelo criador.

## Estado no código

- **Concluído.**
- Implementado em:
  - `shaders/smt_sigil.gdshader`: Shader matemático procedural para selos mágicos e relógios de estase no solo.
  - `scripts/vfx/smt/smt_stage_vfx.gd`: Integração do `GroundSigil`, estacas de maldição, ruptura de escudo em cacos triangulares, lanças/spikes ascendentes e arcos de estase nos tornozelos, além de squash & jitter no modelo do alvo e restauração ao fim do ciclo de vida.
- Verificado em GPU real via `tests/vfx/record_smt_upgraded.gd` e testes automatizados em `tests/vfx/test_smt_stage_vfx.gd` (100% PASS).
