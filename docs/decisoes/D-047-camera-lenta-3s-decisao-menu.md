# D-047 — Câmera Lenta de 3 Segundos para Decisão nos Menus Fight e Itens

- **Data:** 2026-11-03
- **Área:** Combate / UI / Game Feel
- **Origem:** Conversa

## O que o criador disse (literal)

> "quero que implemente uma coisa que vai ser um teste, quando o jogador clicar em itens/fight, deve ocorrer uma câmera lenta por 3 segundos para fazer uma decisão, se passar estes 3 segundos o jogo volta ao normal"
> "a camera lenta ocorre UMA vez por ação, abrir, esperar 3 segundos depois sair e abrir dnv não vai ativar a camera lenta uma segunda vez até realizar uma ação"
> "A ativação é de uso único: ao abrir Fight ou Itens uma vez, o timer corre até o fim e nunca mais ativa antes da próxima ação, mesmo se sair antes"

## Decisão

1. **Ativação e Velocidade:**
   - Ao entrar nos submenus **Fight** ou **Itens**, a velocidade do jogo é reduzida para **0.2x (20% da velocidade normal)** durante **3 segundos em tempo real (wall-clock)**.
   - A ativação é de **uso único por turno de ação**: ao abrir Fight ou Itens uma vez, a permissão de câmera lenta é consumida. Sair com X e reabrir não ativará a câmera lenta novamente até que o jogador efetivamente execute uma ação (habilidade ou item).

2. **Cancelamento e Término Antecipado:**
   - Se o jogador confirmar uma habilidade/item antes dos 3 segundos, a velocidade do jogo retorna imediatamente para **1.0x (normal)** para executar a ação.
   - Se o jogador cancelar voltando com X para o menu principal, a velocidade retorna imediatamente para **1.0x (normal)**.

3. **Expiração do Tempo:**
   - Se os 3 segundos se esgotarem sem que o jogador confirme uma ação, o submenu de Fight ou Itens **permanece aberto**, mas a velocidade do jogo retorna automaticamente para **1.0x (tempo real)**.

4. **Feedback Visual:**
   - Cronômetro / barra regressiva discreta de 3s no cabeçalho do menu e leve tonalidade cinemática na tela enquanto a câmera lenta estiver ativa.

5. **Regras e Arquitetura:**
   - Sincronia total (D-019): o fator 0.2x desacelera igualmente o motor lógico de combate (`Battle`) e as animações visuais (`AnimationPlayer`), mantendo lógica e visual na mesma linha do tempo.
   - Zero tremor ou zoom de câmera (D-020).
   - Nenhuma regra de dano, custo de ATB ou balanceamento é alterada (D-001, D-003, D-040).

## Ambiguidades em aberto (perguntar antes de agir)

Nenhuma (alinhadas detalhadamente via /grill-me).

## Estado no código

Implementado e validado por testes automatizados (`tests/battle/test_d047_decision_slowmo.gd`).
