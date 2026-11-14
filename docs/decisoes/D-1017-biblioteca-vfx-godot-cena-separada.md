<!-- DEBUG-OBRIGATORIO-D1204 -->
> **DEBUG = OBRIGAÇÃO EXTREMA (D-1204).** O debug existe para testar QUALQUER milésimo do jogo: combate, Moves, VFX, overworld, UI, itens, IA, save, áudio.
> **NENHUM teste pode levar mais de 1 minuto** do pedido ao resultado; mire em menos de 10 s (`--scenario=<id> --stdout-trace --quit`).
> Sem caminho pronto no debug? **CRIE o cenário/controle** antes de testar. Nunca peça ao criador para clicar, ajustar slider ou montar nada.
> Teste SEMPRE no debug (`vfx_room`, `BattleDebug`), com dados (`--summary-json`, `--strict-asserts`), nas duas vistas (D-235); não improvise com o jogo real.
> Passou de 1 minuto = o debug está incompleto: melhore a ferramenta primeiro. Ver `docs/decisoes/D-1204-*.md` e `docs/TELEMETRIA.md`.
<!-- /DEBUG-OBRIGATORIO-D1204 -->

# D-1017 — Biblioteca VFX em cena Godot separada, sem HTML; Slash Arc descartado

- **Data:** 2026-11-08
- **Área:** VFX / Processo / Godot
- **Origem:** conversa; pedido direto do criador depois da passada cel do Slash Arc no protótipo HTML.
- **Estado:** **pesquisa inicial concluída; aguardando aprovação; nenhum código novo**. A cena, os 4 efeitos e os addons só serão implementados depois da pesquisa aprovada.

## Frase literal do criador

> "eu acho melhor usar o godot pra isso, uma cena diferente, sem que seja no jogo principal, ao invés de um html, usando flipbook e outros addons, além de suas skills de vfx do godot, ignore o slash arc, não usaremos ele mais, foque no restante"

## Decisão

1. A biblioteca de VFX de referência passa a ser feita em **Godot**, em uma **cena separada**, **fora do jogo principal** — não mais no protótipo HTML.
2. Usar **flipbooks**, os **addons** adequados e as skills de VFX do Godot (`scenario-godot-vfx`, `scenario-godot-shaders`; `scenario-godot-expert` para rodar, capturar e verificar).
3. O **Slash Arc está descartado**: não será portado, não será usado na cena nova e não recebe mais ajustes. O `LIB-VFX-20` e a DEMO-05 (Stylized Slash, que é a composição do Slash) ficam fora do novo escopo; a DEMO-05 só volta se o criador pedir.
4. O foco é o **restante** da biblioteca.
5. O protótipo HTML fica apenas como **referência histórica**; nada dele será apagado sem autorização.
6. Nada muda no jogo principal, no combate ou nas regras existentes.

## Respostas do criador (2026-11-08)

> "pesquisas, preciso que faça ainda mais pesquisas sobre efeitos visuais antes de realmente iniciar, vamos com um escopo pequeno de efeitos, apenas 4 da lista dos 19, pode escolher aleatoriamente quais dos 4 vai utilizar. Por ora, quero apenas que faça pesquisa, veja videos (persona 5, league of legends, shin megami tensei V, boku no hero arena fighters, naruto ultimate ninja storm, granblue relink, outros"

- **Escopo:** **4 dos 19** componentes restantes, escolhidos por mim.
- **Agora:** **somente pesquisa**. Nenhuma cena, nenhum código, nenhum shader antes da pesquisa ser aprovada.
- **Fontes de pesquisa:** Persona 5, League of Legends, Shin Megami Tensei V, Boku no Hero Academia: Arena Fighters, Naruto Ultimate Ninja Storm, Granblue Fantasy: Relink e outras que ajudem.
- **Cena:** "o que achar melhor" — organização delegada a mim.
- **Construção:** **refazer do zero**, não portar o HTML.
- **Addons:** **TrailRenderer + flipbooks + previews** (`vfx_animation_player` / Brackeys Particle Controls).

## Os 4 efeitos escolhidos

Escolha minha, para cobrir quatro famílias diferentes e validar o pipeline:

| # | Componente | Família | Por que entrou |
|---|---|---|---|
| 1 | **LIB-VFX-01 — Vortex Mesh** | Formas | portal/vórtice; testa malha 3D + shader + leitura de volume |
| 2 | **LIB-VFX-08 — Motion Trail** | Movimento | rastro de investida; testa `TrailRenderer`, fita e timing |
| 3 | **LIB-VFX-13 — Shockwave Ring** | Impacto | anel de choque; testa flipbook/shader, escala e leitura à distância |
| 4 | **LIB-VFX-17 — Anime Impact Flipbook** | Impacto | impacto 2D/3D; testa flipbook, atlas e sincronia com o golpe |

## O que a pesquisa precisa responder (por efeito)

1. **Referências reais em vídeo** (2–3 por efeito), com jogo, vídeo e timestamp; quadros extraídos, não banners.
2. **Camadas** que compõem o efeito (flash, corpo, núcleo, borda, faíscas, fumaça, distorção, etc.).
3. **Tempos**: wind-up, release, trajeto/expansão, pico, dissipação; quando o efeito nasce e quando some.
4. **Cores e contraste**: bandas, contorno, saturação, brilho; como lê em fundo claro/escuro.
5. **Silhueta e leitura à distância**: o que continua legível a ~8–37 m.
6. **Como fazer no Godot 4.7 GL Compatibility**: flipbook, shader, malha, `CPUParticles3D`, `TrailRenderer`, `AnimationPlayer`; o que **não** funciona (GPUParticles, decals, sub-emitters).
7. **O que evitar**: fitas finas, pontinhos, formas chapadas, excesso de camadas, restos que ficam na tela.

## Relações

- **D-235** (independente de personagem, time, lado e posição) continua obrigatória.
- **D-308** (fases, vídeo normal/espelhado, qualidade real do Godot) vale para VFX de Move/elemento em combate; a cena-laboratório usa as mesmas lições.
- **D-322/D-323** (cel-shading em bandas duras, estilo do jogo) e **D-332** (fogo por shader/flipbook) orientam a linguagem visual.
- **D-003** (só o pedido; ambiguidade = perguntar) e **D-061** (registro documental) continuam valendo.
- **D-022**: nada de commit/push sem autorização.

## Pesquisa inicial (2026-11-08)

Dossiê: `docs/vfx/referencias/pesquisa_4_efeitos/PESQUISA_4_EFEITOS.md`.
Quadros: `VORTEX.png`, `MOTION_TRAIL.png`, `SHOCKWAVE.png`, `ANIME_IMPACT.png` na mesma pasta.

- P5R, SMT V, Naruto Storm, Granblue Relink, LoL e MHA foram vistos em trechos com timestamp; os quadros mostram camadas, timing e cores.
- O que mais se repete: **3–5 camadas** por efeito, **núcleo branco/escuro + borda colorida**, **poeira/partículas na base** e **mudança de fundo/texto** no impacto anime.
- O que o projeto já tem: `mc_vortex_drill`, `mc_vortex_disc`, `mc_shock_ring`, `flipbook`, `mc_sprite`, `streak`, `TrailRenderer` e os flipbooks de impacto/fumaça.
- A pesquisa ainda tem lacunas (4K, vortex vertical, dome com câmera de jogo, trail de arma em gameplay, breakdowns técnicos). Nada foi implementado.

## O que não foi decidido

- A aprovação da pesquisa e o primeiro efeito a implementar.
- A organização final da cena (uma cena com seletor é a proposta, mas ainda não implementada).
- Não foi decidido apagar o protótipo HTML, o `prototypes/vfx_library/` ou os arquivos do Slash Arc. Eles ficam como referência.
