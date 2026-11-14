<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# Ataque — 3 overhauls de game feel

Protótipo isolado do ataque do overworld. O lab real é congelado; cada opção
executa uma sequência própria de input, avanço, hit-stop, impacto, câmera e
recuperação, **sem iniciar batalha**. Nenhuma regra de combate foi alterada.

## As 3 opções

| # | Nome | Input → impacto | Hit-stop | Recuperação | Leitura |
|---|------|-----------------|----------|-------------|---------|
| 1 | **Snap & Impact** | **150 ms** | 70 ms | 180 ms | resposta imediata, avanço curto, pancada seca, estrela |
| 2 | **Duelista** | **250 ms** | 60 ms | 300 ms | antecipação curta, passo mais legível, recuperação maior |
| 3 | **Comic Crash** | **240 ms** | 130 ms | 380 ms | exagero, puxada maior, POW, knockback e shake fortes |

Todas usam o mesmo boneco e o mesmo Slime. O impacto acontece no contato; o
alvo faz squash, recua e volta. A câmera fecha o FOV e treme no impacto.

## Como abrir

```powershell
.\Godot_v4.7.2-stable_win64_console.exe --path . --resolution 1280x720 `
  --position -4000,0 res://scenes/debug/attack_overhaul_lab.tscn
```

Controles: **1/2/3** escolhe · **Z / Espaço** ataca · **Esc** sai.

## Arquivos

- `scripts/debug/attack_overhaul_lab.gd` — linha do tempo, movimento, câmera e input.
- `scripts/ui/attack_impact_fx.gd` — estrela, faíscas, POW e flash.
- `scenes/debug/attack_overhaul_lab.tscn` — lab.
- `tests/ui/test_attack_overhaul.gd` — 7 checks (perfis, teclas Z/1/2/3, retorno ao idle).
- `tests/ui/capture_attack_overhaul.gd` — stills de windup/impacto/recuperação.
- `tests/ui/record_attack_overhaul.gd` — gravação.

## Impacto real do Tackle (VFX original)

A opção **3 (Comic Crash)** foi aplicada ao ataque real do overworld:

- wind-up **0,14 s**, avanço **0,10 s**, recuperação **0,38 s**;
- a animação de ataque roda a **~3,17×** para preencher os 0,62 s;
- o impacto dá um **slow motion** de 0,14 s (0,35×) e empurra o atingido por **0,5 s**;
- o hitbox do jogador continua ativo por **0,30 s** depois do avanço;
- depois do empurrão, a transição começa (hold de **0,5 s**) e dura **1,0 s**;
- o alvo só é adquirido se o avanço de 2,4 m realmente alcança; longe, Z faz
  ataque livre e **não** entrega a vantagem ao inimigo;
- o inimigo continua com o timing dele (D-1142).

O pacote visual de impacto do Tackle foi mantido; só a apresentação foi corrigida:

- o ponto do impacto agora é a **superfície do alvo voltada para o jogador**, na
  altura do corpo, e não o centro/ground;
- o VFX é escalado pela **distância da câmera** (o fator já existia, mas não era
  aplicado);
- o flash branco de tela cheia (primeira malha do pacote, autorada para a câmera
  de batalha de 12 m) foi suprimido no overworld; o resto do pacote — cone,
  arcos, flipbooks, poeira e anel — continua;
- o `BubbleShieldFX` que vinha junto do host foi removido.

Prova: `tackle_impact_fixed.png`.

## Mídia

- `attack_overhaul.mp4` — os 3 em tempo real (60 fps).
- `attack_overhaul_slow.mp4` — os mesmos 3 em câmera lenta (2×).
- `comparison_impacts.png` — os 3 impactos empilhados.
- `snap_impact.png` / `duelist_*` / `comic_*` — stills.

## O que não foi verificado

- Dano, batalha e regras de alcance não foram alterados além do timing/impacto.
- Áudio, gamepad e o alvo em movimento (o Slime do lab está congelado).
- A câmera do jogo em espaços apertados; o lab usa uma câmera lateral de leitura.
- A sensação final com o Slime se movendo/fugindo no overworld real.
