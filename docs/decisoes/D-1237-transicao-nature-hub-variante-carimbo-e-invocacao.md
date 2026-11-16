<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1237 — Transição Nature → Hub: variante "Carimbo recortado" com invocação

**Data:** 2026-11-16  
**Área:** UI de pré-jogo, cutscene e VFX de overworld (não é Move)  
**Estado:** **aprovada e ligada no jogo: o Enter da roleta leva ao Hub com esta transição.**  
**Relacionadas:** D-1214 (faixas pretas e catálogo de ângulos), D-1219 (roleta de Nature), D-1207, D-1208 (roleta do portão → floresta), D-1040 (um dono do relógio), D-1060 (câmera não esconde o personagem), D-418 (sem clarão de tela cheia), D-235, D-413, D-1028, D-1204.

## Frases literais do criador

> "use o deepseek pra me criar 3 protótipos de transição do jogo pós ganho de nature (que converse com o visual e transicione perfeitamente entre ela até o jogo) com um loading sutil imperceptível até a entrada no Hub, com o personagem caindo do centro, lá de cima, com uma cutscene legal"

> "eu quero a opção C mas mais detalhada
> inclusive no centro do círculo ter um pentagrama neon e ao invés do personagem simplesmente ter seu modelo surgindo e caindo, ser um efeito visual epico de invoocação, cace por referencias"

> "não precisa gravar video, eu já gostei do resultado"

> "está perfeito"

(resposta à pergunta "Você aprova o visual da invocação como está?", em 2026-11-16)

> "está tudo bom eu aprovo"

(dito depois da lista de pendências; cada pendência foi então perguntada em separado, ver itens 13 a 15)

## Escolhas do criador em perguntas de múltipla opção

O texto abaixo é o rótulo da opção que ele marcou, não uma frase dele.

1. Conceitos dos 3 protótipos: **Fenda das faixas** (a), **Rolo vira poço** (b), **Carimbo recortado** (c).
2. Onde o personagem cai: **Centro do Hub**.
3. Carregamento: **Indicador discreto** (sem texto e sem barra).
4. Lado do Hub: **Passar para Godot** (sobre a roleta e o Hub reais, não em HTML).
5. Quem cai: **Modelo real do líder**.
6. Faixas de cutscene: **Com faixas pretas** (D-1214).
7. Tremor de câmera no pouso: **Manter o tremor**.
8. Variante escolhida depois dos vídeos: **C**, mais detalhada (frase literal acima).
9. Onde fica o círculo com o pentagrama: **No chão da praça**.
10. Como o líder chega: **Desce do céu num raio** (o corpo só aparece no impacto).
11. Cor do neon: **Verde-limão da roleta**.
12. Linha de referência da invocação: **Círculo, anéis e pilar**.
13. Valores atuais do protótipo (tempos, tamanhos, faixas pretas, tremor, câmera, 5 lâmpadas de carregamento, pentagrama em x=0 z=0): **Sim, como estão**.
14. A transição entra no jogo de verdade, com o Enter da roleta levando ao Hub em vez da floresta: **Sim, ligar no jogo**.
15. Variantes a (Fenda) e b (Poço): **Remover do código**.

## Decisão

1. A transição depois de travar a Nature segue a variante **C, "Carimbo recortado"**: o selo se desenha, espera o carregamento e é recortado para revelar o Hub.
2. No chão do centro da praça há um **círculo de invocação com um pentagrama neon** na cor verde-limão da roleta.
3. O líder **não aparece caindo como modelo**: ele desce do céu num raio de luz e só surge no impacto, numa invocação na linha círculo, anéis e pilar.
4. A cutscene usa faixas pretas, o modelo real do líder e tremor de câmera no pouso.
5. O carregamento é discreto, sem texto e sem barra.
6. O visual da invocação do protótipo está **aprovado como está** ("está perfeito").
7. Os valores dos blocos `TUNING` estão **aprovados como estão**, incluindo as 5 lâmpadas de carregamento e o pentagrama em x=0, z=0.
8. O **Enter da roleta de Nature leva ao Hub** com esta transição, em vez da floresta. Isto muda a D-1208 neste ponto (a D-1208 fica preservada; vale esta, mais recente).
9. As variantes a e b saem do código.

## Estado

- Arquivos: `scripts/ui/transitions/nature_hub_transition.gd`, `scripts/hub/hub_arrival_cutscene.gd`, `scripts/hub/hub_summon_fx.gd`; ganchos em `scripts/ui/pre_game/pre_game_controller.gd` e `scripts/hub/hub_3d_lab.gd`.
- Ligada no fluxo real: o Enter da roleta chama a transição e abre o Hub.
- Teste com dados: `python prototypes/nature_hub_transition/run_nht.py abra 1300` (linhas `NHT_SUMMARY` e `NHT_HUB`); opções de debug `--nht-auto`, `--nht-load-min=`, `--nht-quit`, `--nht-shots=`, `--nht-summary`.

## Ambiguidades e pendências (não implementar sem o sim do criador)

- **Quem pula a roleta:** personagem que já tem Nature (D-1219) e o atalho de debug `--instant-roulette` não passam pela roleta e continuam indo à floresta; o criador só decidiu o Enter da roleta.
- **Cor:** o verde-limão aparece amarelo-dourado sobre o chão quente da praça (aprovado como está).
- **Outro líder:** dados conferidos com Abra e Pancham; quadros só com Abra.
